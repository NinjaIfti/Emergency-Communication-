import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('emergency_comm.db');
    return _database!;
  }

  // Ensure columns exist in messages table
  Future<void> _ensureColumnsExist(Database db) async {
    try {
      // Get table info to check existing columns
      final tableInfo = await db.rawQuery('PRAGMA table_info(messages)');
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      
      // Add latitude column if it doesn't exist
      if (!columnNames.contains('latitude')) {
        await db.execute('ALTER TABLE messages ADD COLUMN latitude REAL');
        print('Added latitude column to messages table');
      }
      
      // Add longitude column if it doesn't exist
      if (!columnNames.contains('longitude')) {
        await db.execute('ALTER TABLE messages ADD COLUMN longitude REAL');
        print('Added longitude column to messages table');
      }
      
      // Add is_encrypted column if it doesn't exist
      if (!columnNames.contains('is_encrypted')) {
        await db.execute('ALTER TABLE messages ADD COLUMN is_encrypted INTEGER DEFAULT 0');
        print('Added is_encrypted column to messages table');
      }
    } catch (e) {
      print('Error ensuring columns exist: $e');
      // If table doesn't exist yet, onCreate will handle it
    }
  }

  Future<Database> _initDB(String filePath) async {
    final Directory dbPath = await getApplicationDocumentsDirectory();
    final String path = join(dbPath.path, filePath);

    final db = await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    
    // Ensure columns exist immediately after opening (in case migration didn't run)
    await _ensureColumnsExist(db);
    
    return db;
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
        message_type TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        is_encrypted INTEGER DEFAULT 0
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

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        // Check if columns already exist by trying to query them
        // If they don't exist, this will help us know
        await db.rawQuery('SELECT latitude, longitude FROM messages LIMIT 1');
        print('Database already has latitude/longitude columns');
      } catch (e) {
        // Columns don't exist, add them
        try {
          await db.execute('''
            ALTER TABLE messages 
            ADD COLUMN latitude REAL
          ''');
          await db.execute('''
            ALTER TABLE messages 
            ADD COLUMN longitude REAL
          ''');
          print('Database upgraded to version 2: Added latitude/longitude columns');
        } catch (alterError) {
          // If ALTER fails, try to check if columns exist another way
          print('Error adding columns: $alterError');
          // Try to get table info to check columns
          final tableInfo = await db.rawQuery('PRAGMA table_info(messages)');
          final columnNames = tableInfo.map((row) => row['name'] as String).toList();
          
          if (!columnNames.contains('latitude')) {
            await db.execute('ALTER TABLE messages ADD COLUMN latitude REAL');
          }
          if (!columnNames.contains('longitude')) {
            await db.execute('ALTER TABLE messages ADD COLUMN longitude REAL');
          }
          print('Database upgraded to version 2: Added latitude/longitude columns (via PRAGMA check)');
        }
      }
    }
    
    if (oldVersion < 3) {
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(messages)');
        final columnNames = tableInfo.map((row) => row['name'] as String).toList();
        
        if (!columnNames.contains('is_encrypted')) {
          await db.execute('ALTER TABLE messages ADD COLUMN is_encrypted INTEGER DEFAULT 0');
          print('Database upgraded to version 3: Added is_encrypted column');
        }
      } catch (e) {
        print('Error adding is_encrypted column: $e');
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}


