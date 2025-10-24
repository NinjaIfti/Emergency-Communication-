class LocationData {
  final int? id;
  final String messageId;
  final double latitude;
  final double longitude;
  final double? accuracy;

  LocationData({
    this.id,
    required this.messageId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message_id': messageId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }

  // Create from database map
  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      id: map['id'],
      messageId: map['message_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      accuracy: map['accuracy'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }

  // Create from JSON
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      messageId: json['messageId'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      accuracy: json['accuracy'],
    );
  }
}


