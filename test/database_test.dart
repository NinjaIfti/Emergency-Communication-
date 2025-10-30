import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emergenccy_communication/database/database_helper.dart';
import 'package:emergenccy_communication/database/message_dao.dart';
import 'package:emergenccy_communication/database/peer_dao.dart';
import 'package:emergenccy_communication/models/message_model.dart';
import 'package:emergenccy_communication/models/peer_model.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Initialization Tests', () {
    late MessageDao messageDao;
    late PeerDao peerDao;

    setUp(() {
      messageDao = MessageDao();
      peerDao = PeerDao();
    });

    test('Database should be created successfully', () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);
      expect(db.isOpen, true);
    });

    test('Should insert and retrieve a message', () async {
      // Create test message
      final message = Message(
        id: 'test-message-1',
        content: 'Test message content',
        senderId: 'sender-1',
        recipientId: 'recipient-1',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        messageType: MessageType.TEXT,
      );

      // Insert message
      await messageDao.insertMessage(message);

      // Retrieve message
      final retrievedMessage = await messageDao.getMessageById('test-message-1');
      
      expect(retrievedMessage, isNotNull);
      expect(retrievedMessage!.id, 'test-message-1');
      expect(retrievedMessage.content, 'Test message content');
      expect(retrievedMessage.senderId, 'sender-1');
    });

    test('Should insert and retrieve a peer', () async {
      // Create test peer
      final peer = Peer(
        peerId: 'peer-1',
        deviceName: 'Test Device',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        isConnected: true,
        connectionType: ConnectionType.BLUETOOTH,
      );

      // Insert peer
      await peerDao.insertPeer(peer);

      // Retrieve peer
      final retrievedPeer = await peerDao.getPeerById('peer-1');
      
      expect(retrievedPeer, isNotNull);
      expect(retrievedPeer!.peerId, 'peer-1');
      expect(retrievedPeer.deviceName, 'Test Device');
      expect(retrievedPeer.isConnected, true);
    });

    test('Should update message delivery status', () async {
      // Create and insert message
      final message = Message(
        id: 'test-message-2',
        content: 'Another test',
        senderId: 'sender-2',
        recipientId: 'recipient-2',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        messageType: MessageType.TEXT,
        isDelivered: false,
      );

      await messageDao.insertMessage(message);

      // Update delivery status
      await messageDao.updateMessageStatus('test-message-2', true);

      // Retrieve and verify
      final updated = await messageDao.getMessageById('test-message-2');
      expect(updated!.isDelivered, true);
    });

    test('Should get connected peers only', () async {
      // Insert connected peer
      await peerDao.insertPeer(Peer(
        peerId: 'connected-peer',
        deviceName: 'Connected Device',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        isConnected: true,
        connectionType: ConnectionType.BLUETOOTH,
      ));

      // Insert disconnected peer
      await peerDao.insertPeer(Peer(
        peerId: 'disconnected-peer',
        deviceName: 'Disconnected Device',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        isConnected: false,
        connectionType: ConnectionType.WIFI,
      ));

      // Get connected peers
      final connectedPeers = await peerDao.getConnectedPeers();
      
      expect(connectedPeers.length, greaterThanOrEqualTo(1));
      expect(connectedPeers.any((p) => p.peerId == 'connected-peer'), true);
    });

    tearDown(() async {
      // Clean up after each test
      await messageDao.deleteAllMessages();
      await peerDao.deleteAllPeers();
    });
  });
}

