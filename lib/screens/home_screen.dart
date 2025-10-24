import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/connection_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Comm'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            color: AppColors.lightGrey,
            child: Column(
              children: [
                const ConnectionIndicator(
                  isConnected: false,
                  peerCount: 0,
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'No devices connected',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Main Menu Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSizes.paddingMedium,
                crossAxisSpacing: AppSizes.paddingMedium,
                children: [
                  _MenuCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.chat);
                    },
                  ),
                  _MenuCard(
                    icon: Icons.emergency,
                    title: 'SOS Alert',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.sos);
                    },
                  ),
                  _MenuCard(
                    icon: Icons.people_outline,
                    title: 'Nearby Devices',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.peers);
                    },
                  ),
                  _MenuCard(
                    icon: Icons.map_outlined,
                    title: 'Locations',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.map);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.sos);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.emergency),
        label: const Text('SOS'),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 60,
                color: AppColors.white,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

