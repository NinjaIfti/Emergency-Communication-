import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
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

  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;

  // Discover services and characteristics
  Future<bool> discoverServicesAndCharacteristics(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Check for writable characteristic
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            print('Found write characteristic: ${characteristic.uuid}');
          }
          
          // Check for readable/notifiable characteristic
          if (characteristic.properties.notify || characteristic.properties.read) {
            _readCharacteristic = characteristic;
            print('Found read characteristic: ${characteristic.uuid}');
          }
        }
      }

      return _writeCharacteristic != null && _readCharacteristic != null;
    } catch (e) {
      print('Error discovering services: $e');
      return false;
    }
  }

  // Send message to device
  Future<bool> sendMessage(BluetoothDevice device, String message) async {
    try {
      // Discover services if not already done
      if (_writeCharacteristic == null) {
        bool discovered = await discoverServicesAndCharacteristics(device);
        if (!discovered) {
          print('Failed to discover characteristics');
          return false;
        }
      }

      // Convert message to bytes
      final bytes = message.codeUnits;
      
      // Write to characteristic
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      print('Message sent successfully: $message');
      
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Listen for messages from device
  Stream<String> listenForMessages(BluetoothDevice device) async* {
    try {
      // Discover services if not already done
      if (_readCharacteristic == null) {
        bool discovered = await discoverServicesAndCharacteristics(device);
        if (!discovered) {
          print('Failed to discover characteristics');
          return;
        }
      }

      // Enable notifications
      await _readCharacteristic!.setNotifyValue(true);

      // Listen to characteristic value changes
      await for (var value in _readCharacteristic!.lastValueStream) {
        if (value.isNotEmpty) {
          final message = String.fromCharCodes(value);
          print('Message received: $message');
          yield message;
        }
      }
    } catch (e) {
      print('Error listening for messages: $e');
    }
  }

  // Dispose
  void dispose() {
    _devicesController.close();
  }
}

