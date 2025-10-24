import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSent;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.grey,
              child: Icon(
                Icons.person,
                size: 18,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: AppSizes.paddingSmall),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: isSent ? AppColors.secondary : AppColors.lightGrey,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSizes.borderRadiusLarge),
                  topRight: const Radius.circular(AppSizes.borderRadiusLarge),
                  bottomLeft: Radius.circular(
                    isSent ? AppSizes.borderRadiusLarge : 4,
                  ),
                  bottomRight: Radius.circular(
                    isSent ? 4 : AppSizes.borderRadiusLarge,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content,
                    style: AppTextStyles.body.copyWith(
                      color: isSent ? AppColors.white : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Timestamp and status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSent
                              ? AppColors.white.withOpacity(0.7)
                              : AppColors.grey,
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isDelivered
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message.isDelivered
                              ? AppColors.success
                              : AppColors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSent) const SizedBox(width: AppSizes.paddingSmall),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      // Today - show time only
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Other day - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

