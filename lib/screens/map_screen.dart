import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/message_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock SOS locations for demonstration
    final List<Message> sosMessages = [
      Message(
        id: '1',
        content: 'Help! Trapped in building',
        senderId: 'user1',
        recipientId: 'broadcast',
        timestamp: DateTime.now().millisecondsSinceEpoch - (10 * 60 * 1000),
        messageType: MessageType.SOS,
        latitude: 23.8103,
        longitude: 90.4125,
      ),
      Message(
        id: '2',
        content: 'Need medical assistance',
        senderId: 'user2',
        recipientId: 'broadcast',
        timestamp: DateTime.now().millisecondsSinceEpoch - (25 * 60 * 1000),
        messageType: MessageType.SOS,
        latitude: 23.8150,
        longitude: 90.4200,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Locations'),
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            color: AppColors.warning.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                Expanded(
                  child: Text(
                    'Showing ${sosMessages.length} emergency locations',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),

          // Map Placeholder
          Expanded(
            child: Container(
              color: AppColors.lightGrey,
              child: Stack(
                children: [
                  // Map placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 100,
                          color: AppColors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          'Interactive Map View',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          '(Map integration coming soon)',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  // Location markers visualization
                  Positioned(
                    top: 50,
                    left: 100,
                    child: _LocationMarker(isActive: true),
                  ),
                  Positioned(
                    top: 150,
                    right: 80,
                    child: _LocationMarker(isActive: false),
                  ),
                ],
              ),
            ),
          ),

          // Location List
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: sosMessages.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final message = sosMessages[index];
                final timeAgo = _getTimeAgo(message.timestamp);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.emergency,
                      color: AppColors.white,
                    ),
                  ),
                  title: Text(
                    message.content,
                    style: AppTextStyles.body,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${message.latitude?.toStringAsFixed(4)}°N, ${message.longitude?.toStringAsFixed(4)}°E',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  onTap: () {
                    _showLocationDetails(context, message);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(int timestamp) {
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _showLocationDetails(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: AppSizes.paddingMedium),
                Expanded(
                  child: Text(
                    'SOS Location Details',
                    style: AppTextStyles.heading2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            _DetailRow(
              icon: Icons.message,
              label: 'Message',
              value: message.content,
            ),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Coordinates',
              value:
                  '${message.latitude?.toStringAsFixed(6)}°N, ${message.longitude?.toStringAsFixed(6)}°E',
            ),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Time',
              value: _getTimeAgo(message.timestamp),
            ),
            _DetailRow(
              icon: Icons.person,
              label: 'Sender',
              value: message.senderId,
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMarker extends StatelessWidget {
  final bool isActive;

  const _LocationMarker({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.emergency,
        color: AppColors.white,
        size: 20,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
                Text(
                  value,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


