import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import '../services/location_service.dart';
import '../providers/message_provider.dart';
import '../models/message_model.dart';
import 'dart:math';
import '../utils/permissions_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final LocationService _locationService = LocationService.instance;
  bool _isGettingLocation = false;
  String? _locationInfo;
  String? _errorMessage;

  void _onSOSPressed() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.primary),
            const SizedBox(width: AppSizes.paddingSmall),
            const Text('Send SOS Alert?'),
          ],
        ),
        content: const Text(
          'This will send an emergency alert with your location to all nearby devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSOS();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    setState(() {
      _isGettingLocation = true;
      _locationInfo = null;
      _errorMessage = null;
    });

    try {
      // Request location permissions
      bool hasPermission = await PermissionsHelper.requestLocationPermissions();
      if (!hasPermission) {
        setState(() {
          _isGettingLocation = false;
          _errorMessage = 'Location permission denied. Please enable location access in settings.';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Get current location
      Position? position = await _locationService.getCurrentLocation();
      
      // Fallback to last known location if current location unavailable
      if (position == null) {
        position = await _locationService.getLastKnownLocation();
        if (position == null) {
          setState(() {
            _isGettingLocation = false;
            _errorMessage = 'Unable to get location. Please ensure GPS is enabled.';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage!),
                backgroundColor: AppColors.danger,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Get username from preferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Unknown User';
      
      // Get device ID from message provider
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final deviceId = messageProvider.myDeviceId;

      // Format location info
      final locationInfo = _locationService.formatPosition(position);
      final accuracyInfo = _locationService.getAccuracyDescription(position.accuracy);

      // Create SOS message
      final sosMessage = Message(
        id: 'sos-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
        content: '🚨 SOS ALERT: Emergency assistance needed! Location: $locationInfo',
        senderId: deviceId,
        recipientId: 'broadcast', // Broadcast to all devices
        timestamp: DateTime.now().millisecondsSinceEpoch,
        messageType: MessageType.SOS,
        latitude: position.latitude,
        longitude: position.longitude,
        hopCount: 0,
        isDelivered: false,
      );

      // Send SOS message 3 times for reliability (as per requirements)
      int successCount = 0;
      for (int i = 0; i < 3; i++) {
        bool sent = await messageProvider.sendMessage(sosMessage);
        if (sent) {
          successCount++;
        }
        // Small delay between sends
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      setState(() {
        _isGettingLocation = false;
        _locationInfo = 'SOS sent at $locationInfo ($accuracyInfo)';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: AppSizes.paddingSmall),
                Expanded(
                  child: Text(
                    successCount > 0
                        ? 'SOS Alert sent successfully! ($successCount/3 broadcasts)'
                        : 'SOS Alert queued. Will be sent when devices are connected.',
                  ),
                ),
              ],
            ),
            backgroundColor: successCount > 0 ? AppColors.success : AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
        _errorMessage = 'Error sending SOS: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alert'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon
              Icon(
                Icons.emergency_outlined,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSizes.paddingLarge),

              // Title
              Text(
                'Emergency SOS',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Description
              Text(
                'Long press the button below to send an emergency alert with your location to all nearby devices.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingXLarge),

              // SOS Button
              if (_isGettingLocation)
                Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Text(
                      'Getting location...',
                      style: AppTextStyles.caption,
                    ),
                  ],
                )
              else
                SOSButton(
                  onPressed: _onSOSPressed,
                ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Location Info or Error Message
              if (_locationInfo != null)
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    border: Border.all(
                      color: AppColors.success,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: Text(
                          _locationInfo!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    border: Border.all(
                      color: AppColors.danger,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Info Card
              Card(
                color: AppColors.lightGrey,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Text(
                            'How it works',
                            style: AppTextStyles.heading3,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        '• Long press for 2 seconds to activate\n'
                        '• Your GPS location will be included\n'
                        '• Alert will broadcast to all nearby devices\n'
                        '• Message will hop through the mesh network\n'
                        '• Sent 3 times for maximum reliability',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


