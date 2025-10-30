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

  // Send message to device (placeholder - will implement in Week 5)
  Future<void> sendMessage(BluetoothDevice device, String message) async {
    try {
      // This will be implemented in Week 5 with proper service/characteristic
      print('Sending message to ${device.name}: $message');
      // TODO: Implement actual message sending via GATT characteristics
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Listen for messages (placeholder - will implement in Week 5)
  Stream<String> listenForMessages(BluetoothDevice device) {
    // This will be implemented in Week 5
    return Stream.empty();
  }

  // Dispose
  void dispose() {
    _devicesController.close();
  }
}

