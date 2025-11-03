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

void main() {
  runApp(const EmergencyCommApp());
}

class EmergencyCommApp extends StatelessWidget {
  const EmergencyCommApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
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
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          case AppRoutes.home:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
          case AppRoutes.chat:
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                peerName: args?['peerName'] ?? 'Unknown',
                peerId: args?['peerId'] ?? '',
              ),
            );
          case AppRoutes.sos:
            return MaterialPageRoute(
              builder: (_) => const SOSScreen(),
            );
          case AppRoutes.peers:
            return MaterialPageRoute(
              builder: (_) => const PeersScreen(),
            );
          case AppRoutes.map:
            return MaterialPageRoute(
              builder: (_) => const MapScreen(),
            );
          case AppRoutes.settings:
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
        }
      },
      ),
    );
  }
}
