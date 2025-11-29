import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._init();
  
  EncryptionService._init();

  static const String _keyPrefsKey = 'encryption_key';
  static const String _ivPrefsKey = 'encryption_iv';
  
  Key? _key;
  IV? _iv;
  Encrypter? _encrypter;
  
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? keyString = prefs.getString(_keyPrefsKey);
      String? ivString = prefs.getString(_ivPrefsKey);

      if (keyString == null || ivString == null) {
        await _generateKeys();
      } else {
        _key = Key.fromBase64(keyString);
        _iv = IV.fromBase64(ivString);
      }

      _encrypter = Encrypter(AES(_key!));
      _initialized = true;
      
      print('Encryption service initialized');
    } catch (e) {
      print('Error initializing encryption service: $e');
      throw Exception('Failed to initialize encryption: $e');
    }
  }

  Future<void> _generateKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final random = Random.secure();
      
      final keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => random.nextInt(256)));
      final ivBytes = Uint8List.fromList(List<int>.generate(16, (i) => random.nextInt(256)));
      
      _key = Key(keyBytes);
      _iv = IV(ivBytes);
      
      await prefs.setString(_keyPrefsKey, _key!.base64);
      await prefs.setString(_ivPrefsKey, _iv!.base64);
      
      print('New encryption keys generated');
    } catch (e) {
      print('Error generating encryption keys: $e');
      throw Exception('Failed to generate encryption keys: $e');
    }
  }

  String encrypt(String plainText) {
    if (!_initialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized. Call initialize() first.');
    }

    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      print('Error encrypting message: $e');
      throw Exception('Encryption failed: $e');
    }
  }

  String decrypt(String encryptedText) {
    if (!_initialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized. Call initialize() first.');
    }

    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
      return decrypted;
    } catch (e) {
      print('Error decrypting message: $e');
      throw Exception('Decryption failed: $e');
    }
  }

  bool isEncrypted(String text) {
    try {
      Encrypted.fromBase64(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> resetKeys() async {
    _initialized = false;
    _key = null;
    _iv = null;
    _encrypter = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefsKey);
    await prefs.remove(_ivPrefsKey);
    
    await initialize();
    print('Encryption keys reset');
  }

  bool get isInitialized => _initialized;
}

