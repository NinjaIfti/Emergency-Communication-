import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../database/message_dao.dart';
import '../services/bluetooth_service.dart';
import '../services/message_queue_service.dart';
import '../services/mesh_network_service.dart';
import '../services/message_routing_service.dart';
import '../services/encryption_service.dart';
import '../utils/app_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:uuid/uuid.dart';

class MessageProvider extends ChangeNotifier {
  final MessageDao _messageDao = MessageDao();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final MessageQueueService _queueService = MessageQueueService.instance;
  final MeshNetworkService _meshService = MeshNetworkService.instance;
  final MessageRoutingService _routingService = MessageRoutingService.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;
  final Uuid _uuid = const Uuid();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  fbp.BluetoothDevice? _connectedDevice;
  StreamSubscription<String>? _messageListener;
  String _myDeviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  String get myDeviceId => _myDeviceId;

  // Initialize mesh service with device ID
  MessageProvider() {
    _meshService.setMyDeviceId(_myDeviceId);
  }

  // Set connected device for messaging
  void setConnectedDevice(fbp.BluetoothDevice? device) {
    _connectedDevice = device;
    
    // Start listening for messages if device is connected
    if (device != null) {
      startListeningForMessages(device);
      // Start queue processing to retry failed messages
      _queueService.startQueueProcessing();
    } else {
      stopListeningForMessages();
      _queueService.stopQueueProcessing();
    }
    
    notifyListeners();
  }

  // Start listening for incoming messages
  void startListeningForMessages(fbp.BluetoothDevice device) {
    // Cancel previous listener if exists
    stopListeningForMessages();

    // Start listening to Bluetooth message stream
    _messageListener = _bluetoothService.listenForMessages(device).listen(
      (messageString) {
        _handleIncomingMessage(messageString);
      },
      onError: (error) {
        print('Error receiving message: $error');
        _error = 'Message receiving error: $error';
        notifyListeners();
      },
    );

    print('Started listening for messages from ${device.name}');
  }

  // Stop listening for messages
  void stopListeningForMessages() {
    _messageListener?.cancel();
    _messageListener = null;
  }

  // Handle incoming message string
  Future<void> _handleIncomingMessage(String messageString) async {
    try {
      print('Raw message received: $messageString');
      
      // Parse JSON string to Message object
      final jsonData = jsonDecode(messageString);
      final message = Message.fromJson(jsonData);
      
      // Check if message should be forwarded (duplicate detection)
      if (!_routingService.shouldForwardMessage(message)) {
        print('Message is duplicate or TTL exceeded: ${message.id}');
        return;
      }
      
      // Process the received message with mesh network service
      await _meshService.processReceivedMessage(message);
      
      // If message is for this device, decrypt and process
      if (message.recipientId == _myDeviceId || message.recipientId == 'broadcast') {
        // Decrypt message if encrypted
        Message decryptedMessage = message;
        if (message.isEncrypted && message.messageType != MessageType.ACK) {
          try {
            await _encryptionService.initialize();
            final decryptedContent = _encryptionService.decrypt(message.content);
            decryptedMessage = message.copyWith(
              content: decryptedContent,
              isEncrypted: false,
            );
          } catch (e) {
            print('Error decrypting message: $e');
            _error = 'Failed to decrypt message: $e';
            notifyListeners();
            return;
          }
        }
        
        // Handle ACK messages for delivery confirmation
        if (message.messageType == MessageType.ACK) {
          await _handleAckMessage(message);
        } else {
          // Send ACK for non-ACK messages
          await _sendAckMessage(message);
          await receiveMessage(decryptedMessage);
        }
      }
      
      print('Message parsed and processed: ${message.id}');
    } catch (e) {
      print('Error parsing incoming message: $e');
      _error = 'Failed to parse message: $e';
      notifyListeners();
    }
  }

  // Load all messages from database
  Future<void> loadMessages() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _messages = await _messageDao.getAllMessages();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load messages: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load conversation between two users
  Future<void> loadConversation(String userId, String peerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _messages = await _messageDao.getConversation(userId, peerId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load conversation: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message with data loss prevention
  Future<bool> sendMessage(Message message) async {
    try {
      // CRITICAL: Save to database first to prevent data loss
      try {
        await _messageDao.insertMessage(message);
        AppLogger.instance.info('Message saved to database: ${message.id}', tag: 'MessageProvider');
      } catch (dbError) {
        AppLogger.instance.error(
          'CRITICAL: Failed to save message to database',
          tag: 'MessageProvider',
          error: dbError,
        );
        _error = 'Failed to save message. Please try again.';
        notifyListeners();
        return false; // Don't proceed if we can't save
      }

      // Add to local list
      _messages.add(message);
      notifyListeners();

      // Send via mesh network service (handles routing, forwarding, and broadcasting)
      bool sent = await _meshService.sendMessage(message);
      
      if (sent) {
        AppLogger.instance.info('Message sent via mesh network: ${message.id}', tag: 'MessageProvider');
        return true;
      } else {
        AppLogger.instance.warning(
          'Failed to send via mesh network, queued for retry: ${message.id}',
          tag: 'MessageProvider',
        );
        // Message is already in database, queue service will retry
        return false;
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to send message: ${message.id}',
        tag: 'MessageProvider',
        error: e,
      );
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  // Receive a message with duplicate prevention
  Future<void> receiveMessage(Message message) async {
    try {
      // Check if message already exists (prevent duplicates)
      final existing = await _messageDao.getMessageById(message.id);
      if (existing != null) {
        AppLogger.instance.debug('Message already exists (duplicate): ${message.id}', tag: 'MessageProvider');
        return;
      }

      // Store decrypted version in database (data persistence)
      final messageToStore = message.copyWith(isEncrypted: false);
      try {
        await _messageDao.insertMessage(messageToStore);
        AppLogger.instance.info('Message received and saved: ${message.id}', tag: 'MessageProvider');
      } catch (dbError) {
        AppLogger.instance.error(
          'CRITICAL: Failed to save received message to database',
          tag: 'MessageProvider',
          error: dbError,
        );
        // Still add to local list even if DB save fails
      }
      
      // Add to local list
      _messages.add(messageToStore);
      notifyListeners();
    } catch (e) {
      AppLogger.instance.error(
        'Failed to receive message: ${message.id}',
        tag: 'MessageProvider',
        error: e,
      );
      _error = 'Failed to receive message: $e';
      notifyListeners();
    }
  }

  // Send ACK message for delivery confirmation
  Future<void> _sendAckMessage(Message originalMessage) async {
    try {
      if (originalMessage.messageType == MessageType.ACK) {
        return; // Don't send ACK for ACK messages
      }

      final ackMessage = Message(
        id: _uuid.v4(),
        content: originalMessage.id,
        senderId: _myDeviceId,
        recipientId: originalMessage.senderId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        messageType: MessageType.ACK,
        isDelivered: false,
      );

      await _meshService.sendMessage(ackMessage);
      print('ACK sent for message: ${originalMessage.id}');
    } catch (e) {
      print('Error sending ACK: $e');
    }
  }

  // Handle received ACK message
  Future<void> _handleAckMessage(Message ackMessage) async {
    try {
      // ACK message content contains the original message ID
      final originalMessageId = ackMessage.content;
      
      // Update delivery status of the original message
      await updateMessageStatus(originalMessageId, true);
      
      // Notify queue service that message was delivered
      await _queueService.markMessageDelivered(originalMessageId);
      
      print('ACK received for message: $originalMessageId');
    } catch (e) {
      print('Error handling ACK: $e');
    }
  }

  // Update message delivery status
  Future<void> updateMessageStatus(String messageId, bool isDelivered) async {
    try {
      await _messageDao.updateMessageStatus(messageId, isDelivered);
      
      // Update in local list
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isDelivered: isDelivered);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update message status: $e';
      notifyListeners();
    }
  }

  // Get undelivered messages
  Future<List<Message>> getUndeliveredMessages() async {
    try {
      return await _messageDao.getUndeliveredMessages();
    } catch (e) {
      print('Failed to get undelivered messages: $e');
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all messages (for testing)
  Future<void> clearAllMessages() async {
    try {
      await _messageDao.deleteAllMessages();
      _messages.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear messages: $e';
      notifyListeners();
    }
  }

  // Get queue size (undelivered messages count)
  Future<int> getQueueSize() async {
    return await _queueService.getQueueSize();
  }

  // Manually process queue (force retry)
  Future<void> processQueue() async {
    await _queueService.processQueue();
  }

  // Dispose
  @override
  void dispose() {
    stopListeningForMessages();
    _queueService.dispose();
    super.dispose();
  }
}

