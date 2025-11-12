import 'package:flutter/foundation.dart';
import '../models/peer_model.dart';
import '../database/peer_dao.dart';
import '../services/bluetooth_service.dart';
import '../services/mesh_network_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'dart:async';

class PeerProvider extends ChangeNotifier {
  final PeerDao _peerDao = PeerDao();
  final BluetoothService _bluetoothService = BluetoothService.instance;
  final MeshNetworkService _meshService = MeshNetworkService.instance;

  List<Peer> _peers = [];
  List<Peer> _connectedPeers = [];
  bool _isScanning = false;
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<fbp.BluetoothDevice>>? _devicesSubscription;

  // Getters
  List<Peer> get peers => _peers;
  List<Peer> get connectedPeers => _connectedPeers;
  int get connectedPeerCount => _connectedPeers.length;
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all peers from database
  Future<void> loadPeers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _peers = await _peerDao.getAllPeers();
      
      // Filter connected peers
      _connectedPeers = _peers.where((p) => p.isConnected).toList();
      
      // Update mesh routing table
      _meshService.updateRoutingTable(_connectedPeers);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load peers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new peer
  Future<void> addPeer(Peer peer) async {
    try {
      // Check if peer already exists
      final existing = _peers.firstWhere(
        (p) => p.peerId == peer.peerId,
        orElse: () => Peer(
          peerId: '',
          deviceName: '',
          lastSeen: 0,
          isConnected: false,
          connectionType: null,
        ),
      );

      if (existing.peerId.isEmpty) {
        // New peer
        await _peerDao.insertPeer(peer);
        _peers.add(peer);
        print('Peer added: ${peer.deviceName} (${peer.peerId})');
      } else {
        // Update existing peer
        await updatePeer(peer);
        return;
      }

      if (peer.isConnected) {
        _connectedPeers.add(peer);
        // Update mesh routing table
        _meshService.updateRoutingTable(_connectedPeers);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to add peer: $e';
      notifyListeners();
    }
  }

  // Update an existing peer
  Future<void> updatePeer(Peer peer) async {
    try {
      await _peerDao.updatePeer(peer);
      
      final index = _peers.indexWhere((p) => p.peerId == peer.peerId);
      if (index != -1) {
        _peers[index] = peer;
      }

      // Update connected peers list
      _connectedPeers = _peers.where((p) => p.isConnected).toList();
      
      // Update mesh routing table
      _meshService.updateRoutingTable(_connectedPeers);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update peer: $e';
      notifyListeners();
    }
  }

  // Remove a peer
  Future<void> removePeer(String peerId) async {
    try {
      await _peerDao.deletePeer(peerId);
      
      _peers.removeWhere((p) => p.peerId == peerId);
      _connectedPeers.removeWhere((p) => p.peerId == peerId);
      
      // Update mesh routing table
      _meshService.updateRoutingTable(_connectedPeers);

      print('Peer removed: $peerId');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove peer: $e';
      notifyListeners();
    }
  }

  // Update peer connection status
  Future<void> updatePeerStatus(String peerId, bool connected) async {
    try {
      await _peerDao.updatePeerStatus(peerId, connected);
      
      final index = _peers.indexWhere((p) => p.peerId == peerId);
      if (index != -1) {
        _peers[index] = _peers[index].copyWith(
          isConnected: connected,
          lastSeen: DateTime.now().millisecondsSinceEpoch,
        );
      }

      // Update connected peers list
      _connectedPeers = _peers.where((p) => p.isConnected).toList();
      
      // Update mesh routing table
      _meshService.updateRoutingTable(_connectedPeers);

      print('Peer status updated: $peerId -> ${connected ? "connected" : "disconnected"}');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update peer status: $e';
      notifyListeners();
    }
  }

  // Start scanning for nearby devices
  Future<void> startScanning() async {
    try {
      _isScanning = true;
      _error = null;
      notifyListeners();

      // Start Bluetooth scan
      await _bluetoothService.startScan();

      // Listen to discovered devices stream
      _devicesSubscription = _bluetoothService.devicesStream.listen(
        (devices) {
          _handleDiscoveredDevices(devices);
        },
        onError: (error) {
          print('Error in device stream: $error');
          _error = 'Scan error: $error';
          _isScanning = false;
          notifyListeners();
        },
      );

      print('Started scanning for peers');
    } catch (e) {
      _error = 'Failed to start scanning: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  // Stop scanning
  Future<void> stopScanning() async {
    try {
      await _bluetoothService.stopScan();
      await _devicesSubscription?.cancel();
      _devicesSubscription = null;
      
      _isScanning = false;
      notifyListeners();
      
      print('Stopped scanning for peers');
    } catch (e) {
      _error = 'Failed to stop scanning: $e';
      notifyListeners();
    }
  }

  // Handle discovered devices
  Future<void> _handleDiscoveredDevices(List<fbp.BluetoothDevice> devices) async {
    for (var device in devices) {
      final peerId = device.id.toString();
      final deviceName = device.name.isNotEmpty ? device.name : 'Unknown Device';

      // Check if peer already exists
      final existingIndex = _peers.indexWhere((p) => p.peerId == peerId);

      if (existingIndex == -1) {
        // New peer discovered
        final newPeer = Peer(
          peerId: peerId,
          deviceName: deviceName,
          lastSeen: DateTime.now().millisecondsSinceEpoch,
          isConnected: false,
          connectionType: ConnectionType.BLUETOOTH,
        );

        await addPeer(newPeer);
      } else {
        // Update last seen time
        final updatedPeer = _peers[existingIndex].copyWith(
          lastSeen: DateTime.now().millisecondsSinceEpoch,
        );
        await updatePeer(updatedPeer);
      }
    }
  }

  // Connect to a peer
  Future<bool> connectToPeer(String peerId) async {
    try {
      final peerIndex = _peers.indexWhere((p) => p.peerId == peerId);
      if (peerIndex == -1) {
        _error = 'Peer not found';
        notifyListeners();
        return false;
      }

      // Find Bluetooth device
      final devices = await _bluetoothService.getConnectedDevices();
      fbp.BluetoothDevice? targetDevice;

      for (var device in devices) {
        if (device.id.toString() == peerId) {
          targetDevice = device;
          break;
        }
      }

      if (targetDevice == null) {
        // Device not in connected list, try to get from discovered
        final discovered = _bluetoothService.discoveredDevices;
        for (var device in discovered) {
          if (device.id.toString() == peerId) {
            targetDevice = device;
            break;
          }
        }
      }

      if (targetDevice == null) {
        _error = 'Device not found for connection';
        notifyListeners();
        return false;
      }

      // Connect via Bluetooth service
      bool connected = await _bluetoothService.connectToDevice(targetDevice);

      if (connected) {
        await updatePeerStatus(peerId, true);
        print('Connected to peer: ${_peers[peerIndex].deviceName}');
      }

      return connected;
    } catch (e) {
      _error = 'Failed to connect to peer: $e';
      notifyListeners();
      return false;
    }
  }

  // Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    try {
      await updatePeerStatus(peerId, false);
      print('Disconnected from peer: $peerId');
    } catch (e) {
      _error = 'Failed to disconnect from peer: $e';
      notifyListeners();
    }
  }

  // Get peer by ID
  Peer? getPeerById(String peerId) {
    try {
      return _peers.firstWhere((p) => p.peerId == peerId);
    } catch (e) {
      return null;
    }
  }

  // Get connected peer count
  int getConnectedCount() {
    return _connectedPeers.length;
  }

  // Clear all peers (for testing)
  Future<void> clearAllPeers() async {
    try {
      await _peerDao.deleteAllPeers();
      _peers.clear();
      _connectedPeers.clear();
      
      // Update mesh routing table
      _meshService.updateRoutingTable(_connectedPeers);
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear peers: $e';
      notifyListeners();
    }
  }

  // Get peers statistics
  Map<String, dynamic> getPeerStats() {
    return {
      'totalPeers': _peers.length,
      'connectedPeers': _connectedPeers.length,
      'bluetoothPeers': _peers.where((p) => p.connectionType == 'bluetooth').length,
      'wifiPeers': _peers.where((p) => p.connectionType == 'wifi').length,
      'isScanning': _isScanning,
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _bluetoothService.stopScan();
    super.dispose();
  }
}

