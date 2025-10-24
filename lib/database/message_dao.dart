import 'package:sqflite/sqflite.dart';
import '../models/message_model.dart';
import 'database_helper.dart';

class MessageDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a message
  Future<int> insertMessage(Message message) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all messages
  Future<List<Message>> getAllMessages() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('messages');
    
    return List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
  }

  // Get messages by sender and recipient
  Future<List<Message>> getConversation(String userId, String peerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: '(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)',
      whereArgs: [userId, peerId, peerId, userId],
      orderBy: 'timestamp ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
  }

  // Get message by ID
  Future<Message?> getMessageById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Message.fromMap(maps.first);
  }

  // Update message delivery status
  Future<int> updateMessageStatus(String id, bool isDelivered) async {
    final db = await _dbHelper.database;
    return await db.update(
      'messages',
      {'is_delivered': isDelivered ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get undelivered messages
  Future<List<Message>> getUndeliveredMessages() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'is_delivered = ?',
      whereArgs: [0],
    );
    
    return List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
  }

  // Get SOS messages
  Future<List<Message>> getSOSMessages() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'message_type = ?',
      whereArgs: ['SOS'],
      orderBy: 'timestamp DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
  }

  // Delete a message
  Future<int> deleteMessage(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all messages
  Future<int> deleteAllMessages() async {
    final db = await _dbHelper.database;
    return await db.delete('messages');
  }

  // Get message count
  Future<int> getMessageCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM messages');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}


