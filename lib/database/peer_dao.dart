import 'package:sqflite/sqflite.dart';
import '../models/peer_model.dart';
import 'database_helper.dart';

class PeerDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert or update a peer
  Future<int> insertPeer(Peer peer) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'peers',
      peer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all peers
  Future<List<Peer>> getAllPeers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peers',
      orderBy: 'last_seen DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Peer.fromMap(maps[i]);
    });
  }

  // Get connected peers
  Future<List<Peer>> getConnectedPeers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peers',
      where: 'is_connected = ?',
      whereArgs: [1],
    );
    
    return List.generate(maps.length, (i) {
      return Peer.fromMap(maps[i]);
    });
  }

  // Get peer by ID
  Future<Peer?> getPeerById(String peerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peers',
      where: 'peer_id = ?',
      whereArgs: [peerId],
    );
    
    if (maps.isEmpty) return null;
    return Peer.fromMap(maps.first);
  }

  // Update peer connection status
  Future<int> updatePeerStatus(String peerId, bool isConnected) async {
    final db = await _dbHelper.database;
    return await db.update(
      'peers',
      {
        'is_connected': isConnected ? 1 : 0,
        'last_seen': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'peer_id = ?',
      whereArgs: [peerId],
    );
  }

  // Update last seen timestamp
  Future<int> updateLastSeen(String peerId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'peers',
      {'last_seen': DateTime.now().millisecondsSinceEpoch},
      where: 'peer_id = ?',
      whereArgs: [peerId],
    );
  }

  // Delete a peer
  Future<int> deletePeer(String peerId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'peers',
      where: 'peer_id = ?',
      whereArgs: [peerId],
    );
  }

  // Delete all peers
  Future<int> deleteAllPeers() async {
    final db = await _dbHelper.database;
    return await db.delete('peers');
  }

  // Get peer count
  Future<int> getPeerCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM peers');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get connected peer count
  Future<int> getConnectedPeerCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM peers WHERE is_connected = 1'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}


