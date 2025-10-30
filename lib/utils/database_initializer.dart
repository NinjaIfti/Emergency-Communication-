import '../database/database_helper.dart';
import '../database/message_dao.dart';
import '../database/peer_dao.dart';
import '../models/message_model.dart';
import '../models/peer_model.dart';

class DatabaseInitializer {
  // Initialize and test database
  static Future<bool> initializeAndTest() async {
    try {
      print('Testing database initialization...');

      // Get database instance
      final db = await DatabaseHelper.instance.database;
      print('✓ Database created successfully');

      // Test MessageDao
      final messageDao = MessageDao();
      final testMessage = Message(
        id: 'init-test-${DateTime.now().millisecondsSinceEpoch}',
        content: 'Database initialization test',
        senderId: 'system',
        recipientId: 'system',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        messageType: MessageType.TEXT,
      );
      
      await messageDao.insertMessage(testMessage);
      final retrieved = await messageDao.getMessageById(testMessage.id);
      
      if (retrieved != null) {
        print('✓ Messages table working');
        await messageDao.deleteMessage(testMessage.id);
      } else {
        print('✗ Messages table failed');
        return false;
      }

      // Test PeerDao
      final peerDao = PeerDao();
      final testPeer = Peer(
        peerId: 'init-test-${DateTime.now().millisecondsSinceEpoch}',
        deviceName: 'Test Device',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        isConnected: false,
        connectionType: ConnectionType.BLUETOOTH,
      );
      
      await peerDao.insertPeer(testPeer);
      final retrievedPeer = await peerDao.getPeerById(testPeer.peerId);
      
      if (retrievedPeer != null) {
        print('✓ Peers table working');
        await peerDao.deletePeer(testPeer.peerId);
      } else {
        print('✗ Peers table failed');
        return false;
      }

      print('✓ Database initialization successful!');
      return true;
    } catch (e) {
      print('✗ Database initialization failed: $e');
      return false;
    }
  }

  // Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    try {
      final messageDao = MessageDao();
      final peerDao = PeerDao();

      return {
        'totalMessages': await messageDao.getMessageCount(),
        'totalPeers': await peerDao.getPeerCount(),
        'connectedPeers': await peerDao.getConnectedPeerCount(),
      };
    } catch (e) {
      print('Error getting database stats: $e');
      return {
        'totalMessages': 0,
        'totalPeers': 0,
        'connectedPeers': 0,
      };
    }
  }

  // Clear all data (for testing/debugging)
  static Future<void> clearAllData() async {
    try {
      final messageDao = MessageDao();
      final peerDao = PeerDao();

      await messageDao.deleteAllMessages();
      await peerDao.deleteAllPeers();
      
      print('✓ All data cleared');
    } catch (e) {
      print('✗ Error clearing data: $e');
    }
  }
}

