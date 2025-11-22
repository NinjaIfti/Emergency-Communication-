import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class BluetoothService {
  static final BluetoothService instance = BluetoothService._init();
  
  BluetoothService._init();

  // Stream controllers for device discovery
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();

  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;

  // List of discovered devices
  final List<BluetoothDevice> _discoveredDevices = [];
  
  // Connection pool for multi-peer support
  final Map<String, BluetoothDevice> _connectionPool = {};
  
  // Characteristics cache for each device
  final Map<String, BluetoothCharacteristic> _writeCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _readCharacteristics = {};
  
  // Maximum simultaneous connections
  static const int maxConnections = 7;

  // Check if Bluetooth is supported on this device
  Future<bool> checkBluetoothSupport() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        return false;
      }
      return true;
    } catch (e) {
      print('Error checking Bluetooth support: $e');
      return false;
    }
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      print('Error checking Bluetooth state: $e');
      return false;
    }
  }

  // Turn on Bluetooth (on Android only)
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      print('Error turning on Bluetooth: $e');
    }
  }

  // Start scanning for nearby devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      // Check if Bluetooth is enabled first
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        // Try to turn on Bluetooth
        print('Bluetooth is off. Attempting to turn on...');
        try {
          await turnOnBluetooth();
          // Wait a moment for Bluetooth to turn on
          await Future.delayed(const Duration(seconds: 1));
          // Check again
          final isStillDisabled = !(await isBluetoothEnabled());
          if (isStillDisabled) {
            throw Exception('Bluetooth must be turned on. Please enable Bluetooth in your device settings.');
          }
        } catch (e) {
          throw Exception('Bluetooth must be turned on. Please enable Bluetooth in your device settings. Error: $e');
        }
      }

      _discoveredDevices.clear();

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          if (!_discoveredDevices.contains(result.device)) {
            _discoveredDevices.add(result.device);
            _devicesController.add(List.from(_discoveredDevices));
          }
        }
      });
    } catch (e) {
      print('Error starting Bluetooth scan: $e');
      rethrow; // Re-throw so PeerProvider can handle the error
    }
  }

  // Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error stopping Bluetooth scan: $e');
    }
  }

  // Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      // Check if already connected
      if (_connectionPool.containsKey(device.id.toString())) {
        print('Device already in connection pool: ${device.name}');
        return true;
      }
      
      // Check connection limit
      if (_connectionPool.length >= maxConnections) {
        print('Connection limit reached ($maxConnections). Cannot connect to more devices.');
        return false;
      }
      
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      
      // Add to connection pool
      _connectionPool[device.id.toString()] = device;
      print('Device added to connection pool: ${device.name} (${_connectionPool.length}/$maxConnections)');
      
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  // Disconnect from a device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      
      // Remove from connection pool
      _connectionPool.remove(device.id.toString());
      _writeCharacteristics.remove(device.id.toString());
      _readCharacteristics.remove(device.id.toString());
      
      print('Device removed from connection pool: ${device.name} (${_connectionPool.length}/$maxConnections)');
    } catch (e) {
      print('Error disconnecting device: $e');
    }
  }

  // Get connected devices
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    try {
      return FlutterBluePlus.connectedDevices;
    } catch (e) {
      print('Error getting connected devices: $e');
      return [];
    }
  }

  // Custom service and characteristic UUIDs
  static const String serviceUUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String characteristicUUID = "0000ffe1-0000-1000-8000-00805f9b34fb";

  // Discover services and characteristics for a device
  Future<bool> discoverServicesAndCharacteristics(BluetoothDevice device) async {
    try {
      final deviceId = device.id.toString();
      
      // Check if already discovered
      if (_writeCharacteristics.containsKey(deviceId) && 
          _readCharacteristics.containsKey(deviceId)) {
        print('Characteristics already cached for ${device.name}');
        return true;
      }
      
      // Discover services (returns List<BluetoothService> from flutter_blue_plus)
      final services = await device.discoverServices();
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Check for writable characteristic
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristics[deviceId] = characteristic;
            print('Found write characteristic for ${device.name}: ${characteristic.uuid}');
          }
          
          // Check for readable/notifiable characteristic
          if (characteristic.properties.notify || characteristic.properties.read) {
            _readCharacteristics[deviceId] = characteristic;
            print('Found read characteristic for ${device.name}: ${characteristic.uuid}');
          }
        }
      }

      return _writeCharacteristics.containsKey(deviceId) && 
             _readCharacteristics.containsKey(deviceId);
    } catch (e) {
      print('Error discovering services: $e');
      return false;
    }
  }

  // Send message to device
  Future<bool> sendMessage(BluetoothDevice device, String message) async {
    try {
      final deviceId = device.id.toString();
      
      // Discover services if not already done
      if (!_writeCharacteristics.containsKey(deviceId)) {
        bool discovered = await discoverServicesAndCharacteristics(device);
        if (!discovered) {
          print('Failed to discover characteristics for ${device.name}');
          return false;
        }
      }

      // Get write characteristic for this device
      final writeChar = _writeCharacteristics[deviceId];
      if (writeChar == null) {
        print('Write characteristic not found for ${device.name}');
        return false;
      }

      // Convert message to bytes
      final bytes = message.codeUnits;
      
      // Write to characteristic
      await writeChar.write(bytes, withoutResponse: false);
      print('Message sent to ${device.name}: $message');
      
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Listen for messages from device
  Stream<String> listenForMessages(BluetoothDevice device) async* {
    try {
      final deviceId = device.id.toString();
      
      // Discover services if not already done
      if (!_readCharacteristics.containsKey(deviceId)) {
        bool discovered = await discoverServicesAndCharacteristics(device);
        if (!discovered) {
          print('Failed to discover characteristics for ${device.name}');
          return;
        }
      }

      // Get read characteristic for this device
      final readChar = _readCharacteristics[deviceId];
      if (readChar == null) {
        print('Read characteristic not found for ${device.name}');
        return;
      }

      // Enable notifications
      await readChar.setNotifyValue(true);

      // Listen to characteristic value changes
      await for (var value in readChar.lastValueStream) {
        if (value.isNotEmpty) {
          final message = String.fromCharCodes(value);
          print('Message received from ${device.name}: $message');
          yield message;
        }
      }
    } catch (e) {
      print('Error listening for messages from ${device.name}: $e');
    }
  }

  // Get connection pool size
  int getConnectionPoolSize() {
    return _connectionPool.length;
  }

  // Check if device is in connection pool
  bool isDeviceConnected(String deviceId) {
    return _connectionPool.containsKey(deviceId);
  }

  // Get device from connection pool
  BluetoothDevice? getDeviceFromPool(String deviceId) {
    return _connectionPool[deviceId];
  }

  // Get all devices in connection pool
  List<BluetoothDevice> getConnectionPoolDevices() {
    return _connectionPool.values.toList();
  }

  // Broadcast message to all connected devices
  Future<int> broadcastToAll(String message) async {
    int successCount = 0;
    
    for (var device in _connectionPool.values) {
      bool sent = await sendMessage(device, message);
      if (sent) {
        successCount++;
      }
    }
    
    print('Broadcast to $successCount/${_connectionPool.length} devices');
    return successCount;
  }

  // Clear connection pool (disconnect all)
  Future<void> disconnectAll() async {
    final devices = _connectionPool.values.toList();
    
    for (var device in devices) {
      await disconnectDevice(device);
    }
    
    _connectionPool.clear();
    _writeCharacteristics.clear();
    _readCharacteristics.clear();
    
    print('All devices disconnected from pool');
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'connectedDevices': _connectionPool.length,
      'maxConnections': maxConnections,
      'availableSlots': maxConnections - _connectionPool.length,
      'discoveredDevices': _discoveredDevices.length,
      'devices': _connectionPool.values.map((d) => {
        'id': d.id.toString(),
        'name': d.name.isNotEmpty ? d.name : 'Unknown',
      }).toList(),
    };
  }

  // Get current list of discovered devices
  List<BluetoothDevice> get discoveredDevices {
    return List.from(_discoveredDevices);
  }

  // Dispose
  void dispose() {
    _devicesController.close();
    disconnectAll();
  }
}

