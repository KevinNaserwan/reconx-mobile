import 'package:flutter/material.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/api_sync_service.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().init();
  await BiometricService().init();
  await ApiSyncService().init();
  runApp(const ReconXMobileApp());
}

class ReconXMobileApp extends StatelessWidget {
  const ReconXMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final authService = AuthService();
        final bioService = BiometricService();

        Widget initialScreen;
        if (!authService.isAuthenticated) {
          initialScreen = const LoginScreen();
        } else if (bioService.isBiometricEnabled) {
          initialScreen = const BiometricLockScreen();
        } else {
          initialScreen = const MainNavigationScreen();
        }

        return MaterialApp(
          title: 'ReconX Companion',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Default clean dark SaaS aesthetic
          home: initialScreen,
        );
      },
    );
  }
}
