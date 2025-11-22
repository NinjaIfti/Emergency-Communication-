import 'dart:async';
import '../models/message_model.dart';
import '../models/peer_model.dart';
import '../services/bluetooth_service.dart';
import '../database/message_dao.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'dart:convert';

// Represents a route to a peer
class PeerRoute {
  final String peerId;
  final String nextHop;
  final int hopCount;
  final DateTime lastUpdated;

  PeerRoute({
    required this.peerId,
    required this.nextHop,
    required this.hopCount,
    required this.lastUpdated,
  });

  PeerRoute copyWith({
    String? peerId,
    String? nextHop,
    int? hopCount,
    DateTime? lastUpdated,
  }) {
    return PeerRoute(
      peerId: peerId ?? this.peerId,
      nextHop: nextHop ?? this.nextHop,
      hopCount: hopCount ?? this.hopCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Routing table for mesh network
class RoutingTable {
  final Map<String, PeerRoute> _routes = {};

  // Add or update a route
  void addRoute(String peerId, String nextHop, int hopCount, {bool silent = false}) {
    final routeExisted = _routes.containsKey(peerId);
    _routes[peerId] = PeerRoute(
      peerId: peerId,
      nextHop: nextHop,
      hopCount: hopCount,
      lastUpdated: DateTime.now(),
    );
    // Only log if route is new and not silent mode
    if (!routeExisted && !silent) {
      print('Route added: $peerId -> $nextHop (hops: $hopCount)');
    }
  }

  // Get next hop for destination
  String? getNextHop(String destinationId) {
    return _routes[destinationId]?.nextHop;
  }

  // Get route for destination
  PeerRoute? getRoute(String destinationId) {
    return _routes[destinationId];
  }

  // Update routes based on connected peers
  void updateRoutes(List<Peer> connectedPeers) {
    // Get list of connected peer IDs
    final connectedPeerIds = connectedPeers
        .where((p) => p.isConnected)
        .map((p) => p.peerId)
        .toSet();
    
    // Get current route peer IDs
    final currentRoutePeerIds = _routes.keys.toSet();
    
    // Quick check: if sets are identical, no changes needed
    if (connectedPeerIds.length == currentRoutePeerIds.length &&
        connectedPeerIds.every((id) => currentRoutePeerIds.contains(id)) &&
        currentRoutePeerIds.every((id) => connectedPeerIds.contains(id))) {
      // No changes, skip update
      return;
    }
    
    final previousRouteCount = _routes.length;
    bool routesChanged = false;
    
    // Remove stale routes (peers not connected anymore)
    final removedRoutes = currentRoutePeerIds
        .where((peerId) => !connectedPeerIds.contains(peerId))
        .toList();
    
    for (var peerId in removedRoutes) {
      _routes.remove(peerId);
      print('Route removed: $peerId (peer disconnected)');
      routesChanged = true;
    }

    // Add direct routes for connected peers (use silent mode to avoid duplicate logs)
    for (var peerId in connectedPeerIds) {
      final routeExisted = _routes.containsKey(peerId);
      // Use silent mode if route already exists
      addRoute(peerId, peerId, 1, silent: routeExisted);
      if (!routeExisted) {
        routesChanged = true;
      }
    }

    // Only print if routes actually changed (to reduce log spam)
    final newRouteCount = _routes.length;
    if (routesChanged || newRouteCount != previousRouteCount) {
      if (newRouteCount > 0 || previousRouteCount > 0) {
        // Only log if there are routes now or there were routes before
        print('Routing table updated: $newRouteCount routes');
      }
    }
  }

  // Get all routes
  Map<String, PeerRoute> getAllRoutes() {
    return Map.unmodifiable(_routes);
  }

  // Clear all routes
  void clear() {
    _routes.clear();
    print('Routing table cleared');
  }

  // Check if route exists
  bool hasRoute(String peerId) {
    return _routes.containsKey(peerId);
  }

  // Get total route count
  int get routeCount => _routes.length;
}

// Mesh network service for multi-hop messaging
class MeshNetworkService {
  static final MeshNetworkService instance = MeshNetworkService._init();
  
  MeshNetworkService._init();

  final RoutingTable _routingTable = RoutingTable();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final MessageDao _messageDao = MessageDao();
  
  String? _myDeviceId;

  // Set this device's ID
  void setMyDeviceId(String deviceId) {
    _myDeviceId = deviceId;
    print('My device ID set: $deviceId');
  }

  // Get routing table
  RoutingTable get routingTable => _routingTable;

  // Update routing table with connected peers
  void updateRoutingTable(List<Peer> connectedPeers) {
    _routingTable.updateRoutes(connectedPeers);
  }

  // Forward a message to its destination
  Future<bool> forwardMessage(Message message, fbp.BluetoothDevice device) async {
    try {
      // Check TTL
      if (message.hopCount >= 5) {
        print('Message TTL exceeded, not forwarding: ${message.id}');
        return false;
      }

      // Get next hop for destination
      String? nextHop = _routingTable.getNextHop(message.recipientId);
      
      if (nextHop == null) {
        print('No route to destination: ${message.recipientId}');
        return false;
      }

      // Increment hop count
      final forwardedMessage = message.copyWith(
        hopCount: message.hopCount + 1,
      );

      // Convert to JSON
      final jsonMessage = jsonEncode(forwardedMessage.toJson());

      // Send to next hop
      bool sent = await _bluetoothService.sendMessage(device, jsonMessage);

      if (sent) {
        print('Message forwarded: ${message.id} -> $nextHop (hop ${forwardedMessage.hopCount})');
      }

      return sent;
    } catch (e) {
      print('Error forwarding message: $e');
      return false;
    }
  }

  // Broadcast message to all connected peers (flooding)
  Future<int> broadcastMessage(Message message) async {
    try {
      // Check TTL
      if (message.hopCount >= 5) {
        print('Message TTL exceeded, not broadcasting: ${message.id}');
        return 0;
      }

      // Get connected devices
      final connectedDevices = await _bluetoothService.getConnectedDevices();
      
      if (connectedDevices.isEmpty) {
        print('No connected devices to broadcast to');
        return 0;
      }

      int successCount = 0;

      // Increment hop count for broadcast
      final broadcastMessage = message.copyWith(
        hopCount: message.hopCount + 1,
      );

      // Convert to JSON
      final jsonMessage = jsonEncode(broadcastMessage.toJson());

      // Send to all connected peers
      for (var device in connectedDevices) {
        bool sent = await _bluetoothService.sendMessage(device, jsonMessage);
        
        if (sent) {
          successCount++;
          print('Message broadcast to ${device.name}: ${message.id}');
        }
      }

      print('Broadcast complete: $successCount/${connectedDevices.length} devices');
      return successCount;
    } catch (e) {
      print('Error broadcasting message: $e');
      return 0;
    }
  }

  // Send message with routing (either direct or multi-hop)
  Future<bool> sendMessage(Message message) async {
    try {
      // Store in database
      await _messageDao.insertMessage(message);

      // Check if destination is directly connected
      final connectedDevices = await _bluetoothService.getConnectedDevices();
      
      // Try direct connection first
      for (var device in connectedDevices) {
        if (device.id.toString() == message.recipientId) {
          final jsonMessage = jsonEncode(message.toJson());
          bool sent = await _bluetoothService.sendMessage(device, jsonMessage);
          
          if (sent) {
            print('Message sent directly: ${message.id}');
            return true;
          }
        }
      }

      // If not directly connected, check routing table
      String? nextHop = _routingTable.getNextHop(message.recipientId);
      
      if (nextHop != null) {
        // Find device with next hop ID
        for (var device in connectedDevices) {
          if (device.id.toString() == nextHop) {
            return await forwardMessage(message, device);
          }
        }
      }

      // If no route found, broadcast (flooding)
      print('No direct route, broadcasting message: ${message.id}');
      int broadcastCount = await broadcastMessage(message);
      return broadcastCount > 0;

    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Process received message (forward if not for this device)
  Future<void> processReceivedMessage(Message message) async {
    try {
      // Check if message is for this device
      if (message.recipientId == _myDeviceId) {
        print('Message is for this device: ${message.id}');
        // Store in database
        await _messageDao.insertMessage(message);
        return;
      }

      // If message is broadcast (no specific recipient), accept it
      if (message.recipientId == 'broadcast') {
        print('Broadcast message received: ${message.id}');
        await _messageDao.insertMessage(message);
        return;
      }

      // Message is for another device, forward it
      print('Message is for ${message.recipientId}, forwarding...');
      
      // Get connected devices
      final connectedDevices = await _bluetoothService.getConnectedDevices();
      
      // Try to forward to next hop
      String? nextHop = _routingTable.getNextHop(message.recipientId);
      
      if (nextHop != null) {
        for (var device in connectedDevices) {
          if (device.id.toString() == nextHop) {
            await forwardMessage(message, device);
            return;
          }
        }
      }

      // If no specific route, broadcast
      await broadcastMessage(message);

    } catch (e) {
      print('Error processing received message: $e');
    }
  }

  // Clear routing table
  void clearRoutingTable() {
    _routingTable.clear();
  }

  // Get routing statistics
  Map<String, dynamic> getRoutingStats() {
    return {
      'totalRoutes': _routingTable.routeCount,
      'myDeviceId': _myDeviceId ?? 'not_set',
      'routes': _routingTable.getAllRoutes().map((key, value) => 
        MapEntry(key, {
          'nextHop': value.nextHop,
          'hopCount': value.hopCount,
          'lastUpdated': value.lastUpdated.toIso8601String(),
        })
      ),
    };
  }
}

