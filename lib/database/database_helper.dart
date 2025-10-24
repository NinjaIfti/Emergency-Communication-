import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emergency_comm.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory dbPath = await getApplicationDocumentsDirectory();
    final String path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        recipient_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_delivered INTEGER DEFAULT 0,
        hop_count INTEGER DEFAULT 0,
        message_type TEXT NOT NULL
      )
    ''');

    // Peers table
    await db.execute('''
      CREATE TABLE peers (
        peer_id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        last_seen INTEGER NOT NULL,
        is_connected INTEGER DEFAULT 0,
        connection_type TEXT
      )
    ''');

    // Locations table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        FOREIGN KEY (message_id) REFERENCES messages(id)
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}


