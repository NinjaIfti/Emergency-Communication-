import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../database/message_dao.dart';
import '../services/bluetooth_service.dart';
import '../services/message_queue_service.dart';
import '../services/mesh_network_service.dart';
import '../services/message_routing_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class MessageProvider extends ChangeNotifier {
  final MessageDao _messageDao = MessageDao();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final MessageQueueService _queueService = MessageQueueService.instance;
  final MeshNetworkService _meshService = MeshNetworkService.instance;
  final MessageRoutingService _routingService = MessageRoutingService.instance;
  
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
      
      // If message is for this device, add to local messages
      if (message.recipientId == _myDeviceId || message.recipientId == 'broadcast') {
        await receiveMessage(message);
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

  // Send a message
  Future<bool> sendMessage(Message message) async {
    try {
      // Add to local list
      _messages.add(message);
      notifyListeners();

      // Send via mesh network service (handles routing, forwarding, and broadcasting)
      bool sent = await _meshService.sendMessage(message);
      
      if (sent) {
        print('Message sent via mesh network: ${message.id}');
        return true;
      } else {
        print('Failed to send via mesh network, queued for retry');
        return false;
      }
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  // Receive a message
  Future<void> receiveMessage(Message message) async {
    try {
      // Check if message already exists
      final existing = await _messageDao.getMessageById(message.id);
      if (existing != null) {
        print('Message already exists: ${message.id}');
        return;
      }

      // Insert into database
      await _messageDao.insertMessage(message);
      
      // Add to local list
      _messages.add(message);
      notifyListeners();

      print('Message received: ${message.id}');
    } catch (e) {
      _error = 'Failed to receive message: $e';
      notifyListeners();
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

