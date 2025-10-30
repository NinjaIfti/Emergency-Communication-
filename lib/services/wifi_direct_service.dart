import 'package:wifi_iot/wifi_iot.dart';
import 'dart:async';
import 'dart:io';

class WiFiDirectService {
  static final WiFiDirectService instance = WiFiDirectService._init();
  
  WiFiDirectService._init();

  // Stream controller for WiFi peer discovery
  final StreamController<List<WifiNetwork>> _peersController =
      StreamController<List<WifiNetwork>>.broadcast();

  Stream<List<WifiNetwork>> get peersStream => _peersController.stream;

  // Check if WiFi Direct is supported (Android only)
  Future<bool> isWiFiDirectSupported() async {
    if (!Platform.isAndroid) {
      print('WiFi Direct is only supported on Android');
      return false;
    }
    
    try {
      return await WiFiForIoTPlugin.isEnabled();
    } catch (e) {
      print('Error checking WiFi Direct support: $e');
      return false;
    }
  }

  // Check if WiFi is enabled
  Future<bool> isWiFiEnabled() async {
    try {
      return await WiFiForIoTPlugin.isEnabled();
    } catch (e) {
      print('Error checking WiFi state: $e');
      return false;
    }
  }

  // Enable WiFi
  Future<bool> enableWiFi() async {
    try {
      return await WiFiForIoTPlugin.setEnabled(true);
    } catch (e) {
      print('Error enabling WiFi: $e');
      return false;
    }
  }

  // Disable WiFi
  Future<bool> disableWiFi() async {
    try {
      return await WiFiForIoTPlugin.setEnabled(false);
    } catch (e) {
      print('Error disabling WiFi: $e');
      return false;
    }
  }

  // Scan for WiFi Direct peers
  Future<List<WifiNetwork>> scanForPeers() async {
    try {
      final networks = await WiFiForIoTPlugin.loadWifiList();
      _peersController.add(networks);
      return networks;
    } catch (e) {
      print('Error scanning for WiFi peers: $e');
      return [];
    }
  }

  // Connect to a WiFi Direct peer
  Future<bool> connectToPeer(
    String ssid,
    String password, {
    bool isWPA = true,
  }) async {
    try {
      return await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: isWPA ? NetworkSecurity.WPA : NetworkSecurity.NONE,
        joinOnce: false,
      );
    } catch (e) {
      print('Error connecting to peer: $e');
      return false;
    }
  }

  // Disconnect from current WiFi network
  Future<bool> disconnect() async {
    try {
      return await WiFiForIoTPlugin.disconnect();
    } catch (e) {
      print('Error disconnecting: $e');
      return false;
    }
  }

  // Get current WiFi connection info
  Future<String?> getSSID() async {
    try {
      return await WiFiForIoTPlugin.getSSID();
    } catch (e) {
      print('Error getting SSID: $e');
      return null;
    }
  }

  // Get WiFi IP address
  Future<String?> getIP() async {
    try {
      return await WiFiForIoTPlugin.getIP();
    } catch (e) {
      print('Error getting IP: $e');
      return null;
    }
  }

  // Check if connected to WiFi
  Future<bool> isConnected() async {
    try {
      return await WiFiForIoTPlugin.isConnected();
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  // Create WiFi hotspot for mesh network (Android only)
  Future<bool> createHotspot(String ssid, String password) async {
    if (!Platform.isAndroid) {
      print('Hotspot creation only supported on Android');
      return false;
    }

    try {
      // This will be implemented more fully in Week 6
      print('Creating hotspot: $ssid');
      // TODO: Implement hotspot creation for mesh networking
      return false;
    } catch (e) {
      print('Error creating hotspot: $e');
      return false;
    }
  }

  // Stop WiFi hotspot
  Future<bool> stopHotspot() async {
    try {
      // This will be implemented in Week 6
      print('Stopping hotspot');
      // TODO: Implement hotspot stopping
      return false;
    } catch (e) {
      print('Error stopping hotspot: $e');
      return false;
    }
  }

  // Send message via WiFi Direct (placeholder - Week 6)
  Future<void> sendMessage(String message) async {
    try {
      print('Sending message via WiFi Direct: $message');
      // TODO: Implement socket communication in Week 6
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Listen for messages (placeholder - Week 6)
  Stream<String> listenForMessages() {
    // TODO: Implement socket listener in Week 6
    return Stream.empty();
  }

  // Dispose
  void dispose() {
    _peersController.close();
  }
}

