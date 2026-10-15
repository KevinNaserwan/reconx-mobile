import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final trimmed = photoUrl!.trim();

      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        // Sanitize Dicebear SVG urls to PNG to avoid decoding issues on Flutter raster image widgets
        final cleanUrl = trimmed.contains('dicebear.com') && trimmed.contains('/svg?')
            ? trimmed.replaceAll('/svg?', '/png?')
            : trimmed;

        avatarWidget = ClipOval(
          child: Image.network(
            cleanUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(context, initial),
          ),
        );
      } else {
        // Check if it's a local file path
        try {
          final file = File(trimmed);
          if (file.existsSync()) {
            avatarWidget = ClipOval(
              child: Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(context, initial),
              ),
            );
          } else {
            avatarWidget = _buildFallback(context, initial);
          }
        } catch (_) {
          avatarWidget = _buildFallback(context, initial);
        }
      }
    } else {
      avatarWidget = _buildFallback(context, initial);
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallback(BuildContext context, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryEmerald.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3), width: 1.2),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryEmerald,
          ),
        ),
      ),
    );
  }
}
