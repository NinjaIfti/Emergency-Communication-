import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  final int peerCount;

  const ConnectionIndicator({
    super.key,
    required this.isConnected,
    required this.peerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.success.withOpacity(0.1)
            : AppColors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: isConnected ? AppColors.success : AppColors.grey,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.success : AppColors.grey,
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          
          // Connection icon
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: isConnected ? AppColors.success : AppColors.grey,
            size: 20,
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          
          // Status text
          Text(
            isConnected
                ? '$peerCount ${peerCount == 1 ? 'device' : 'devices'} connected'
                : 'Offline',
            style: AppTextStyles.body.copyWith(
              color: isConnected ? AppColors.success : AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

