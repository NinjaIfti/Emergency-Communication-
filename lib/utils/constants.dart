import 'package:flutter/material.dart';

// Color Scheme
class AppColors {
  static const Color primary = Color(0xFFD32F2F); // Emergency red
  static const Color secondary = Color(0xFF1976D2); // Safe blue
  static const Color background = Color(0xFFFAFAFA);
  static const Color dark = Color(0xFF212121);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color danger = Color(0xFFE53935); // Error/alert red
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.dark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.dark,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.dark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.dark,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.grey,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

// Sizes
class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 16.0;

  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;

  static const double sosButtonSize = 200.0;
}

// Network Configuration
class NetworkConfig {
  static const int maxHopCount = 5; // TTL
  static const int maxMessageSize = 512; // bytes
  static const int bluetoothRange = 100; // meters
  static const int wifiDirectRange = 200; // meters
  static const int maxPeersInMesh = 15;
  static const int messageDeliveryTimeout = 10; // seconds
}

// Message Packet Structure
class MessagePacket {
  /* 
   * Standard Message Packet Format (JSON):
   * {
   *   "id": "uuid",
   *   "type": "TEXT|SOS|ACK",
   *   "content": "message text",
   *   "senderId": "uuid",
   *   "recipientId": "uuid",
   *   "timestamp": 1234567890,
   *   "hopCount": 0,
   *   "ttl": 5,
   *   "latitude": 23.8103,
   *   "longitude": 90.4125
   * }
   */

  static Map<String, dynamic> createPacket({
    required String id,
    required String type,
    required String content,
    required String senderId,
    required String recipientId,
    required int timestamp,
    int hopCount = 0,
    int ttl = NetworkConfig.maxHopCount,
    double? latitude,
    double? longitude,
  }) {
    return {
      'id': id,
      'type': type,
      'content': content,
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': timestamp,
      'hopCount': hopCount,
      'ttl': ttl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Routing Table Structure
class RoutingTableEntry {
  final String peerId;
  final String nextHop;
  final int hopCount;
  final int lastUpdated;

  RoutingTableEntry({
    required this.peerId,
    required this.nextHop,
    required this.hopCount,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'nextHop': nextHop,
      'hopCount': hopCount,
      'lastUpdated': lastUpdated,
    };
  }

  factory RoutingTableEntry.fromJson(Map<String, dynamic> json) {
    return RoutingTableEntry(
      peerId: json['peerId'],
      nextHop: json['nextHop'],
      hopCount: json['hopCount'],
      lastUpdated: json['lastUpdated'],
    );
  }
}

// App Routes
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String sos = '/sos';
  static const String peers = '/peers';
  static const String map = '/map';
  static const String settings = '/settings';
}

// Database Tables
class DatabaseTables {
  static const String messages = 'messages';
  static const String peers = 'peers';
  static const String locations = 'locations';
}

// Shared Preferences Keys
class PreferenceKeys {
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String autoConnect = 'auto_connect';
  static const String firstLaunch = 'first_launch';
}


