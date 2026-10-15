import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_sync_service.dart';
import '../services/language_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_notification_banner.dart';
import 'dashboard_screen.dart';
import 'family_screen.dart';
import 'receipt_scanner_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  StreamSubscription? _txSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Listen to real-time notification sync events and display floating banner
    _txSubscription = ApiSyncService().onNewTransactionStream.listen((tx) {
      if (mounted) {
        FloatingNotificationBanner.show(
          context,
          title: 'Mutasi Finansial Terekonsiliasi',
          subtitle: '${tx.appName} • ${tx.merchant}',
          amount: tx.amount,
          brand: tx.appName,
        );
      }
    });

    // Proactively prompt user for Camera, Notification & Interceptor permissions on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService().requestAppPermissions(context);
    });
  }

  @override
  void dispose() {
    _txSubscription?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(onNavigateTab: _onTabTapped);
      case 1:
        return TransactionsScreen(onNavigateToScan: () => _onTabTapped(2));
      case 2:
        return ReceiptScannerScreen(onScanComplete: () => _onTabTapped(1));
      case 3:
        return const FamilyScreen();
      case 4:
        return const SettingsScreen();
      default:
        return DashboardScreen(onNavigateTab: _onTabTapped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      body: _buildBody(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, LanguageService().tr('nav_home')),
                _buildNavItem(1, Icons.receipt_long_rounded, LanguageService().tr('nav_mutasi')),
                _buildCenterScanButton(),
                _buildNavItem(3, Icons.family_restroom_rounded, LanguageService().tr('nav_family')),
                _buildNavItem(4, Icons.person_rounded, LanguageService().tr('nav_account')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryEmerald.withOpacity(isDark ? 0.15 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppTheme.primaryEmerald
                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryEmerald
                    : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScanButton() {
    final isSelected = _currentIndex == 2;

    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppTheme.primaryEmerald,
              AppTheme.primaryTeal,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryEmerald.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
