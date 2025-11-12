import 'dart:async';
import '../models/message_model.dart';

// Service to handle message routing and prevent loops
class MessageRoutingService {
  static final MessageRoutingService instance = MessageRoutingService._init();
  
  MessageRoutingService._init() {
    // Start cleanup timer
    _startCleanupTimer();
  }

  // Cache of seen messages to prevent loops (message ID -> timestamp)
  final Map<String, DateTime> _seenMessages = {};

  // Maximum cache size (LRU cache)
  static const int _maxCacheSize = 1000;

  // How long to keep messages in cache (30 minutes)
  static const Duration _cacheExpiry = Duration(minutes: 30);

  Timer? _cleanupTimer;

  // Check if message should be forwarded (not a duplicate)
  bool shouldForwardMessage(Message message) {
    // Check if we've seen this message before
    if (_seenMessages.containsKey(message.id)) {
      print('Duplicate message detected, not forwarding: ${message.id}');
      return false;
    }

    // Check TTL
    if (message.hopCount >= 5) {
      print('Message TTL exceeded, not forwarding: ${message.id}');
      return false;
    }

    // Mark message as seen
    _markMessageAsSeen(message.id);

    return true;
  }

  // Mark a message as seen
  void _markMessageAsSeen(String messageId) {
    _seenMessages[messageId] = DateTime.now();
    print('Message marked as seen: $messageId (cache size: ${_seenMessages.length})');

    // If cache is too large, remove oldest entries
    if (_seenMessages.length > _maxCacheSize) {
      _trimCache();
    }
  }

  // Check if message has been seen
  bool hasSeenMessage(String messageId) {
    return _seenMessages.containsKey(messageId);
  }

  // Get next hop for message (returns null if should broadcast)
  String? getNextHopForMessage(Message message, Map<String, String> routingTable) {
    // If message is broadcast type, return null
    if (message.recipientId == 'broadcast') {
      return null;
    }

    // Look up in routing table
    return routingTable[message.recipientId];
  }

  // Trim cache to max size (remove oldest entries - LRU)
  void _trimCache() {
    if (_seenMessages.length <= _maxCacheSize) {
      return;
    }

    print('Trimming cache from ${_seenMessages.length} to $_maxCacheSize');

    // Sort by timestamp (oldest first)
    final sortedEntries = _seenMessages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest entries
    final entriesToRemove = _seenMessages.length - _maxCacheSize;
    for (int i = 0; i < entriesToRemove; i++) {
      _seenMessages.remove(sortedEntries[i].key);
    }

    print('Cache trimmed to ${_seenMessages.length} entries');
  }

  // Clean up old messages from cache
  void cleanupSeenMessages() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // Find expired entries
    _seenMessages.forEach((messageId, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        expiredKeys.add(messageId);
      }
    });

    // Remove expired entries
    for (var key in expiredKeys) {
      _seenMessages.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      print('Cleaned up ${expiredKeys.length} expired messages from cache');
    }
  }

  // Start periodic cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    
    // Run cleanup every 5 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      cleanupSeenMessages();
    });

    print('Message routing cleanup timer started');
  }

  // Stop cleanup timer
  void stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    print('Message routing cleanup timer stopped');
  }

  // Clear all seen messages (for testing)
  void clearSeenMessages() {
    _seenMessages.clear();
    print('Seen messages cache cleared');
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int recentCount = 0;
    int oldCount = 0;

    _seenMessages.forEach((_, timestamp) {
      if (now.difference(timestamp) < const Duration(minutes: 5)) {
        recentCount++;
      } else {
        oldCount++;
      }
    });

    return {
      'totalCached': _seenMessages.length,
      'maxCacheSize': _maxCacheSize,
      'recentMessages': recentCount,
      'oldMessages': oldCount,
      'cacheExpiryMinutes': _cacheExpiry.inMinutes,
    };
  }

  // Check if message is a duplicate based on content (not just ID)
  bool isDuplicateContent(Message message, List<Message> existingMessages) {
    return existingMessages.any((existing) =>
      existing.content == message.content &&
      existing.senderId == message.senderId &&
      existing.recipientId == message.recipientId &&
      (message.timestamp - existing.timestamp).abs() < 5000 // Within 5 seconds
    );
  }

  // Determine if message should be broadcast or unicast
  bool shouldBroadcast(Message message) {
    // Broadcast if recipient is 'broadcast' or SOS message
    return message.recipientId == 'broadcast' || 
           message.messageType == MessageType.SOS;
  }

  // Calculate priority for message (higher = more important)
  int getMessagePriority(Message message) {
    switch (message.messageType) {
      case MessageType.SOS:
        return 100; // Highest priority
      case MessageType.ACK:
        return 10;
      case MessageType.TEXT:
        return 1;
      default:
        return 0;
    }
  }

  // Get seen messages count
  int get seenMessagesCount => _seenMessages.length;

  // Get all seen message IDs (for debugging)
  List<String> getSeenMessageIds() {
    return _seenMessages.keys.toList();
  }

  // Get message age in cache
  Duration? getMessageAge(String messageId) {
    final timestamp = _seenMessages[messageId];
    if (timestamp == null) return null;
    
    return DateTime.now().difference(timestamp);
  }

  // Dispose and cleanup
  void dispose() {
    stopCleanupTimer();
    clearSeenMessages();
    print('Message routing service disposed');
  }
}

