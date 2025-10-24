class Peer {
  final String peerId;
  final String deviceName;
  final int lastSeen;
  final bool isConnected;
  final ConnectionType? connectionType;

  Peer({
    required this.peerId,
    required this.deviceName,
    required this.lastSeen,
    this.isConnected = false,
    this.connectionType,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'deviceName': deviceName,
      'lastSeen': lastSeen,
      'isConnected': isConnected,
      'connectionType': connectionType?.toString().split('.').last,
    };
  }

  // Create from JSON
  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      peerId: json['peerId'],
      deviceName: json['deviceName'],
      lastSeen: json['lastSeen'],
      isConnected: json['isConnected'] ?? false,
      connectionType: json['connectionType'] != null
          ? _connectionTypeFromString(json['connectionType'])
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'peer_id': peerId,
      'device_name': deviceName,
      'last_seen': lastSeen,
      'is_connected': isConnected ? 1 : 0,
      'connection_type': connectionType?.toString().split('.').last,
    };
  }

  // Create from database map
  factory Peer.fromMap(Map<String, dynamic> map) {
    return Peer(
      peerId: map['peer_id'],
      deviceName: map['device_name'],
      lastSeen: map['last_seen'],
      isConnected: map['is_connected'] == 1,
      connectionType: map['connection_type'] != null
          ? _connectionTypeFromString(map['connection_type'])
          : null,
    );
  }

  static ConnectionType _connectionTypeFromString(String type) {
    switch (type.toUpperCase()) {
      case 'BLUETOOTH':
        return ConnectionType.BLUETOOTH;
      case 'WIFI':
        return ConnectionType.WIFI;
      default:
        return ConnectionType.BLUETOOTH;
    }
  }

  Peer copyWith({
    String? peerId,
    String? deviceName,
    int? lastSeen,
    bool? isConnected,
    ConnectionType? connectionType,
  }) {
    return Peer(
      peerId: peerId ?? this.peerId,
      deviceName: deviceName ?? this.deviceName,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

enum ConnectionType {
  BLUETOOTH,
  WIFI,
}


