import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/peer_model.dart';

class PeerTile extends StatelessWidget {
  final Peer peer;
  final VoidCallback onTap;

  const PeerTile({
    super.key,
    required this.peer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: peer.isConnected
                  ? AppColors.success
                  : AppColors.grey,
              child: Icon(
                Icons.phone_android,
                color: AppColors.white,
              ),
            ),
            // Connection status indicator
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: peer.isConnected ? AppColors.success : AppColors.grey,
                  border: Border.all(
                    color: AppColors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          peer.deviceName,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  peer.connectionType == ConnectionType.BLUETOOTH
                      ? Icons.bluetooth
                      : Icons.wifi,
                  size: 14,
                  color: AppColors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  peer.connectionType == ConnectionType.BLUETOOTH
                      ? 'Bluetooth'
                      : 'WiFi Direct',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _getLastSeenText(peer.lastSeen),
              style: AppTextStyles.caption.copyWith(
                color: peer.isConnected ? AppColors.success : AppColors.grey,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: peer.isConnected
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Text(
                peer.isConnected ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: peer.isConnected ? AppColors.success : AppColors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLastSeenText(int timestamp) {
    final now = DateTime.now();
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Active now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Last seen $minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Last seen $hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      return 'Last seen $days ${days == 1 ? 'day' : 'days'} ago';
    }
  }
}



