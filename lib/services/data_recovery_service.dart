import '../utils/app_logger.dart';
import '../database/message_dao.dart';
import '../models/message_model.dart';
import '../services/message_queue_service.dart';
import '../services/mesh_network_service.dart';

class DataRecoveryService {
  static final DataRecoveryService instance = DataRecoveryService._init();
  
  DataRecoveryService._init();

  final MessageDao _messageDao = MessageDao();
  final MessageQueueService _queueService = MessageQueueService.instance;
  final MeshNetworkService _meshService = MeshNetworkService.instance;

  // Recover undelivered messages
  Future<int> recoverUndeliveredMessages() async {
    try {
      AppLogger.instance.info('Starting data recovery: checking for undelivered messages', tag: 'DataRecovery');
      
      final undelivered = await _messageDao.getUndeliveredMessages();
      final count = undelivered.length;
      
      if (count > 0) {
        AppLogger.instance.info('Found $count undelivered messages to recover', tag: 'DataRecovery');
        
        // Queue service will handle retrying these messages
        // Just log the recovery
        for (var message in undelivered) {
          AppLogger.instance.debug(
            'Recovering message: ${message.id} (type: ${message.messageType})',
            tag: 'DataRecovery',
          );
        }
      } else {
        AppLogger.instance.info('No undelivered messages found', tag: 'DataRecovery');
      }
      
      return count;
    } catch (e) {
      AppLogger.instance.error(
        'Error during data recovery',
        tag: 'DataRecovery',
        error: e,
      );
      return 0;
    }
  }

  // Verify message integrity (check for missing data)
  Future<Map<String, dynamic>> verifyDataIntegrity() async {
    try {
      AppLogger.instance.info('Verifying data integrity', tag: 'DataRecovery');
      
      final allMessages = await _messageDao.getAllMessages();
      final issues = <String>[];
      
      // Check for messages with missing content
      final emptyContent = allMessages.where((m) => m.content.isEmpty).toList();
      if (emptyContent.isNotEmpty) {
        issues.add('${emptyContent.length} messages with empty content');
        AppLogger.instance.warning(
          'Found ${emptyContent.length} messages with empty content',
          tag: 'DataRecovery',
        );
      }
      
      // Check for messages with invalid IDs
      final invalidIds = allMessages.where((m) => m.id.isEmpty).toList();
      if (invalidIds.isNotEmpty) {
        issues.add('${invalidIds.length} messages with invalid IDs');
        AppLogger.instance.warning(
          'Found ${invalidIds.length} messages with invalid IDs',
          tag: 'DataRecovery',
        );
      }
      
      // Check for duplicate message IDs
      final ids = allMessages.map((m) => m.id).toList();
      final duplicates = ids.toSet().length != ids.length;
      if (duplicates) {
        issues.add('Duplicate message IDs detected');
        AppLogger.instance.warning('Duplicate message IDs detected', tag: 'DataRecovery');
      }
      
      return {
        'totalMessages': allMessages.length,
        'issues': issues,
        'isHealthy': issues.isEmpty,
      };
    } catch (e) {
      AppLogger.instance.error(
        'Error verifying data integrity',
        tag: 'DataRecovery',
        error: e,
      );
      return {
        'totalMessages': 0,
        'issues': ['Error during verification: $e'],
        'isHealthy': false,
      };
    }
  }

  // Clean up orphaned messages (messages that can never be delivered)
  Future<int> cleanupOrphanedMessages({Duration maxAge = const Duration(days: 7)}) async {
    try {
      AppLogger.instance.info('Cleaning up orphaned messages', tag: 'DataRecovery');
      
      final allMessages = await _messageDao.getAllMessages();
      final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
      
      final orphaned = allMessages.where((m) => 
        !m.isDelivered && 
        m.timestamp < cutoffTime &&
        m.messageType != MessageType.SOS // Never delete SOS messages
      ).toList();
      
      int deleted = 0;
      for (var message in orphaned) {
        try {
          await _messageDao.deleteMessage(message.id);
          deleted++;
          AppLogger.instance.debug('Deleted orphaned message: ${message.id}', tag: 'DataRecovery');
        } catch (e) {
          AppLogger.instance.warning(
            'Failed to delete orphaned message: ${message.id}',
            tag: 'DataRecovery',
            error: e,
          );
        }
      }
      
      if (deleted > 0) {
        AppLogger.instance.info('Cleaned up $deleted orphaned messages', tag: 'DataRecovery');
      }
      
      return deleted;
    } catch (e) {
      AppLogger.instance.error(
        'Error cleaning up orphaned messages',
        tag: 'DataRecovery',
        error: e,
      );
      return 0;
    }
  }

  // Get recovery statistics
  Future<Map<String, dynamic>> getRecoveryStats() async {
    try {
      final undelivered = await _messageDao.getUndeliveredMessages();
      final integrity = await verifyDataIntegrity();
      
      return {
        'undeliveredCount': undelivered.length,
        'dataIntegrity': integrity,
        'pendingInQueue': _queueService.getPendingMessagesCount(),
      };
    } catch (e) {
      AppLogger.instance.error(
        'Error getting recovery stats',
        tag: 'DataRecovery',
        error: e,
      );
      return {};
    }
  }
}

