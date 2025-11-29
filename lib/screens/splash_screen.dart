import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/encryption_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Initialize encryption service
    _initializeServices();

    // Navigate to home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    });
  }

  Future<void> _initializeServices() async {
    try {
      await EncryptionService.instance.initialize();
      print('Encryption service initialized successfully');
    } catch (e) {
      print('Error initializing encryption service: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emergency,
                size: 120,
                color: AppColors.white,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              Text(
                'Emergency Comm',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Text(
                'Offline Communication System',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppSizes.paddingXLarge),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

