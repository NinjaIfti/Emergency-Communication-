import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  // Request Bluetooth permissions
  static Future<bool> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    // Check if all permissions are granted
    return statuses.values.every((status) => status.isGranted);
  }

  // Request Location permissions (required for Bluetooth scanning)
  static Future<bool> requestLocationPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Request WiFi permissions
  static Future<bool> requestWifiPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Check all permissions at once
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'bluetooth': await Permission.bluetooth.isGranted,
      'bluetoothScan': await Permission.bluetoothScan.isGranted,
      'bluetoothConnect': await Permission.bluetoothConnect.isGranted,
      'location': await Permission.location.isGranted,
      'wifi': await Permission.nearbyWifiDevices.isGranted,
    };
  }

  // Request all permissions needed for the app
  static Future<bool> requestAllPermissions() async {
    bool bluetoothGranted = await requestBluetoothPermissions();
    bool locationGranted = await requestLocationPermissions();
    bool wifiGranted = await requestWifiPermissions();

    return bluetoothGranted && locationGranted && wifiGranted;
  }

  // Check if critical permissions are granted
  static Future<bool> hasCriticalPermissions() async {
    bool bluetooth = await Permission.bluetoothConnect.isGranted;
    bool location = await Permission.location.isGranted;

    return bluetooth && location;
  }

  // Open app settings if permissions are denied permanently
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

