import 'dart:async';
import '../models/message_model.dart';
import '../database/message_dao.dart';
import '../services/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'dart:convert';

class MessageQueueService {
  static final MessageQueueService instance = MessageQueueService._init();
  
  MessageQueueService._init();

  final MessageDao _messageDao = MessageDao();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  
  Timer? _retryTimer;
  bool _isProcessing = false;

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

      // Try to send each message
      for (var message in undeliveredMessages) {
        for (var device in connectedDevices) {
          bool sent = await _sendMessageToDevice(message, device);
          
          if (sent) {
            print('Queued message sent: ${message.id}');
            // Mark as delivered
            await _messageDao.updateMessageStatus(message.id, true);
            break; // Move to next message
          }
        }
      }
    } catch (e) {
      print('Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Send a single message to a device
  Future<bool> _sendMessageToDevice(Message message, fbp.BluetoothDevice device) async {
    try {
      // Convert message to JSON
      final jsonMessage = jsonEncode(message.toJson());
      
      // Send via Bluetooth
      bool sent = await _bluetoothService.sendMessage(device, jsonMessage);
      
      return sent;
    } catch (e) {
      print('Error sending message to ${device.name}: $e');
      return false;
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

  // Get queue size
  Future<int> getQueueSize() async {
    try {
      final undelivered = await _messageDao.getUndeliveredMessages();
      return undelivered.length;
    } catch (e) {
      print('Error getting queue size: $e');
      return 0;
    }
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

