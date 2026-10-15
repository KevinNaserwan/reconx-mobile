import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/api_sync_service.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for dates and currencies safely
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('DateFormatting fallback: $e');
  }

  // Set up custom error widget to prevent blank grey screens
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppTheme.darkBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.primaryEmerald, size: 48),
              const SizedBox(height: 16),
              Text(
                'Reconx Sedang Menyiapkan Data',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan buka kembali menu ini dalam beberapa saat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  await ThemeService().init();
  await AuthService().init();
  await BiometricService().init();
  await ApiSyncService().init();

  runApp(const ReconxApp());
}

class ReconxApp extends StatelessWidget {
  const ReconxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthService(), ThemeService()]),
      builder: (context, _) {
        final authService = AuthService();
        final bioService = BiometricService();
        final themeService = ThemeService();

        Widget initialScreen;
        if (!authService.isAuthenticated) {
          initialScreen = const LoginScreen();
        } else if (bioService.isBiometricEnabled) {
          initialScreen = const BiometricLockScreen();
        } else {
          initialScreen = const MainNavigationScreen();
        }

        return MaterialApp(
          title: 'Reconx',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: initialScreen,
        );
      },
    );
  }
}
