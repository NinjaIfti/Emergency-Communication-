import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/peers_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/message_provider.dart';
import 'providers/peer_provider.dart';

void main() {
  runApp(const EmergencyCommApp());
}

class EmergencyCommApp extends StatelessWidget {
  const EmergencyCommApp({super.key});

  // Helper method to generate routes with smooth transitions
  Widget _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return const SplashScreen();
      case AppRoutes.home:
        return const HomeScreen();
      case AppRoutes.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return ChatScreen(
          peerName: args?['peerName'] ?? 'Unknown',
          peerId: args?['peerId'] ?? '',
        );
      case AppRoutes.sos:
        return const SOSScreen();
      case AppRoutes.peers:
        return const PeersScreen();
      case AppRoutes.map:
        return const MapScreen();
      case AppRoutes.settings:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => PeerProvider()),
      ],
      child: MaterialApp(
      title: 'Emergency Comm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.heading3.copyWith(
            color: AppColors.white,
          ),
      ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        // Smooth page transition with fade effect
        Widget page = _generateRoute(settings);
        
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade transition for smooth navigation
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
      },
      ),
    );
  }
}
