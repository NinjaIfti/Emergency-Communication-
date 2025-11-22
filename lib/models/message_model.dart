class Message {
  final String id;
  final String content;
  final String senderId;
  final String recipientId;
  final int timestamp;
  final bool isDelivered;
  final int hopCount;
  final MessageType messageType;
  final double? latitude;
  final double? longitude;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    this.isDelivered = false,
    this.hopCount = 0,
    required this.messageType,
    this.latitude,
    this.longitude,
  });

  // Convert Message to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': messageType.toString().split('.').last,
      'content': content,
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': timestamp,
      'hopCount': hopCount,
      'ttl': 5,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      timestamp: json['timestamp'],
      hopCount: json['hopCount'] ?? 0,
      messageType: _messageTypeFromString(json['type']),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  // Convert Message to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'timestamp': timestamp,
      'is_delivered': isDelivered ? 1 : 0,
      'hop_count': hopCount,
      'message_type': messageType.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create Message from database map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      senderId: map['sender_id'],
      recipientId: map['recipient_id'],
      timestamp: map['timestamp'],
      isDelivered: map['is_delivered'] == 1,
      hopCount: map['hop_count'] ?? 0,
      messageType: _messageTypeFromString(map['message_type']),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  static MessageType _messageTypeFromString(String type) {
    switch (type.toUpperCase()) {
      case 'SOS':
        return MessageType.SOS;
      case 'ACK':
        return MessageType.ACK;
      case 'TEXT':
      default:
        return MessageType.TEXT;
    }
  }

  Message copyWith({
    String? id,
    String? content,
    String? senderId,
    String? recipientId,
    int? timestamp,
    bool? isDelivered,
    int? hopCount,
    MessageType? messageType,
    double? latitude,
    double? longitude,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      timestamp: timestamp ?? this.timestamp,
      isDelivered: isDelivered ?? this.isDelivered,
      hopCount: hopCount ?? this.hopCount,
      messageType: messageType ?? this.messageType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

enum MessageType {
  TEXT,
  SOS,
  ACK,
}


