import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  static final LocationService instance = LocationService._init();
  
  LocationService._init();

  // Stream controller for location updates
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  StreamSubscription<Position>? _positionStreamSubscription;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
  }

  // Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      print('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      print('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  // Get current location (one-time)
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Get last known location
  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  // Start listening to location updates
  Future<void> startLocationUpdates() async {
    try {
      // Check permissions first
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission not granted');
        return;
      }

      // Start listening
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _locationController.add(position);
        },
        onError: (error) {
          print('Error in location stream: $error');
        },
      );
    } catch (e) {
      print('Error starting location updates: $e');
    }
  }

  // Stop listening to location updates
  Future<void> stopLocationUpdates() async {
    try {
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    } catch (e) {
      print('Error stopping location updates: $e');
    }
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      print('Error opening location settings: $e');
      return false;
    }
  }

  // Format position to readable string
  String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}°N, ${position.longitude.toStringAsFixed(6)}°E';
  }

  // Get accuracy description
  String getAccuracyDescription(double accuracy) {
    if (accuracy < 10) {
      return 'Excellent (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy < 50) {
      return 'Good (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy < 100) {
      return 'Fair (${accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Poor (${accuracy.toStringAsFixed(1)}m)';
    }
  }

  // Dispose
  void dispose() {
    stopLocationUpdates();
    _locationController.close();
  }
}

