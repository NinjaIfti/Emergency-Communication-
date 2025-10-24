import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isGettingLocation = false;
  String? _locationInfo;

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

  void _sendSOS() async {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    setState(() {
      _isGettingLocation = true;
    });

    // Simulate getting location and sending SOS
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isGettingLocation = false;
      _locationInfo = 'SOS sent at 23.8103°N, 90.4125°E';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.white),
              const SizedBox(width: AppSizes.paddingSmall),
              const Text('SOS Alert sent successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
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

              // Location Info
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

