import 'dart:async';
import '../models/message_model.dart';
import '../database/message_dao.dart';
import '../services/bluetooth_service.dart';
import '../services/mesh_network_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'dart:convert';

class MessageQueueService {
  static final MessageQueueService instance = MessageQueueService._init();
  
  MessageQueueService._init();

  final MessageDao _messageDao = MessageDao();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final MeshNetworkService _meshService = MeshNetworkService.instance;
  
  Timer? _retryTimer;
  bool _isProcessing = false;
  
  // Track pending messages with their send timestamps for timeout checking
  final Map<String, int> _pendingMessages = {};
  
  static const int _deliveryTimeoutSeconds = 30;

  // Start queue processing with retry logic
  void startQueueProcessing({Duration interval = const Duration(seconds: 10)}) {
    if (_retryTimer != null && _retryTimer!.isActive) {
      print('Queue processing already running');
      return;
    }

    print('Starting message queue processing');
    
    _retryTimer = Timer.periodic(interval, (timer) async {
      await processQueue();
    });
  }

  // Stop queue processing
  void stopQueueProcessing() {
    _retryTimer?.cancel();
    _retryTimer = null;
    print('Queue processing stopped');
  }

  // Process the queue (send undelivered messages)
  Future<void> processQueue() async {
    if (_isProcessing) {
      print('Already processing queue, skipping...');
      return;
    }

    _isProcessing = true;

    try {
      // Get undelivered messages
      final undeliveredMessages = await _messageDao.getUndeliveredMessages();
      
      if (undeliveredMessages.isEmpty) {
        print('No messages in queue');
        _isProcessing = false;
        return;
      }

      print('Processing ${undeliveredMessages.length} queued messages');

      // Get connected devices
      final connectedDevices = await _bluetoothService.getConnectedDevices();
      
      if (connectedDevices.isEmpty) {
        print('No connected devices, cannot send queued messages');
        _isProcessing = false;
        return;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Try to send each undelivered message
      for (var message in undeliveredMessages) {
        // Skip ACK messages - they don't need confirmation
        if (message.messageType == MessageType.ACK) {
          continue;
        }
        
        // Check if message has timed out (no ACK received)
        if (_pendingMessages.containsKey(message.id)) {
          final sentTime = _pendingMessages[message.id]!;
          final elapsedSeconds = (currentTime - sentTime) ~/ 1000;
          
          if (elapsedSeconds > _deliveryTimeoutSeconds) {
            print('Message ${message.id} timed out, will retry');
            _pendingMessages.remove(message.id);
          } else {
            // Still waiting for ACK, skip retry
            continue;
          }
        }
        
        // Try to send via mesh network
        bool sent = await _meshService.sendMessage(message);
        
        if (sent) {
          print('Queued message sent: ${message.id}');
          // Track sent time to wait for ACK
          _pendingMessages[message.id] = currentTime;
        }
      }
      
      // Clean up old pending messages (older than timeout)
      _pendingMessages.removeWhere((id, sentTime) {
        final elapsedSeconds = (currentTime - sentTime) ~/ 1000;
        return elapsedSeconds > _deliveryTimeoutSeconds * 2;
      });
    } catch (e) {
      print('Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Mark message as delivered (called when ACK is received)
  Future<void> markMessageDelivered(String messageId) async {
    try {
      _pendingMessages.remove(messageId);
      await _messageDao.updateMessageStatus(messageId, true);
      print('Message marked as delivered: $messageId');
    } catch (e) {
      print('Error marking message as delivered: $e');
    }
  }

  // Add message to queue (already handled by database insert)
  Future<void> queueMessage(Message message) async {
    try {
      await _messageDao.insertMessage(message);
      print('Message queued: ${message.id}');
    } catch (e) {
      print('Error queuing message: $e');
    }
  }

  // Get queue size (undelivered messages)
  Future<int> getQueueSize() async {
    try {
      final undelivered = await _messageDao.getUndeliveredMessages();
      return undelivered.where((m) => m.messageType != MessageType.ACK).length;
    } catch (e) {
      print('Error getting queue size: $e');
      return 0;
    }
  }
  
  // Get pending messages count (waiting for ACK)
  int getPendingMessagesCount() {
    return _pendingMessages.length;
  }
  
  // Clear pending messages tracking
  void clearPendingMessages() {
    _pendingMessages.clear();
  }

  // Clear all queued messages (for testing)
  Future<void> clearQueue() async {
    try {
      final undelivered = await _messageDao.getUndeliveredMessages();
      for (var message in undelivered) {
        await _messageDao.deleteMessage(message.id);
      }
      print('Queue cleared');
    } catch (e) {
      print('Error clearing queue: $e');
    }
  }

  // Dispose
  void dispose() {
    stopQueueProcessing();
  }
}

