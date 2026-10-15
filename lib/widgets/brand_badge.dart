import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandBadgeData {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final String? customTag;

  const BrandBadgeData({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    this.customTag,
  });
}

class BrandBadgeHelper {
  static BrandBadgeData getBadge(String appName, String merchant, {String? channel}) {
    final text = '${appName.toLowerCase()} ${merchant.toLowerCase()} ${(channel ?? "").toLowerCase()}';

    // 1. QRIS
    if (text.contains('qris')) {
      return const BrandBadgeData(
        label: 'QRIS',
        icon: Icons.qr_code_2_rounded,
        bgColor: Color(0xFFFEF2F2),
        textColor: Color(0xFFDC2626),
        borderColor: Color(0xFFFCA5A5),
        customTag: 'QRIS',
      );
    }

    // 2. GoPay
    if (text.contains('gopay') || text.contains('gojek')) {
      return const BrandBadgeData(
        label: 'GoPay',
        icon: Icons.account_balance_wallet_rounded,
        bgColor: Color(0xFFECFEFF),
        textColor: Color(0xFF0284C7),
        borderColor: Color(0xFF7DD3FC),
        customTag: 'GoPay',
      );
    }

    // 3. OVO
    if (text.contains('ovo')) {
      return const BrandBadgeData(
        label: 'OVO',
        icon: Icons.wallet_rounded,
        bgColor: Color(0xFFFAF5FF),
        textColor: Color(0xFF7E22CE),
        borderColor: Color(0xFFD8B4FE),
        customTag: 'OVO',
      );
    }

    // 4. DANA
    if (text.contains('dana')) {
      return const BrandBadgeData(
        label: 'DANA',
        icon: Icons.payments_rounded,
        bgColor: Color(0xFFEFF6FF),
        textColor: Color(0xFF1D4ED8),
        borderColor: Color(0xFF93C5FD),
        customTag: 'DANA',
      );
    }

    // 5. ShopeePay / SPayLater
    if (text.contains('shopee') || text.contains('spay')) {
      return const BrandBadgeData(
        label: 'ShopeePay',
        icon: Icons.shopping_bag_rounded,
        bgColor: Color(0xFFFFF7ED),
        textColor: Color(0xFFEA580C),
        borderColor: Color(0xFFFDBA74),
        customTag: 'Shopee',
      );
    }

    // 6. BCA / blu
    if (text.contains('bca') || text.contains('blu')) {
      return const BrandBadgeData(
        label: 'BCA',
        icon: Icons.account_balance_rounded,
        bgColor: Color(0xFFEFF6FF),
        textColor: Color(0xFF003893),
        borderColor: Color(0xFF93C5FD),
        customTag: 'BCA',
      );
    }

    // 7. Mandiri / Livin
    if (text.contains('mandiri') || text.contains('livin')) {
      return const BrandBadgeData(
        label: 'Mandiri',
        icon: Icons.account_balance_rounded,
        bgColor: Color(0xFFFFFBEB),
        textColor: Color(0xFFB45309),
        borderColor: Color(0xFFFDE68A),
        customTag: 'Livin',
      );
    }

    // 8. BRI / BRImo
    if (text.contains('bri') || text.contains('brimo')) {
      return const BrandBadgeData(
        label: 'BRImo',
        icon: Icons.account_balance_rounded,
        bgColor: Color(0xFFF0FDF4),
        textColor: Color(0xFF15803D),
        borderColor: Color(0xFF86EFAC),
        customTag: 'BRI',
      );
    }

    // 9. BNI
    if (text.contains('bni')) {
      return const BrandBadgeData(
        label: 'BNI',
        icon: Icons.account_balance_rounded,
        bgColor: Color(0xFFECFDF5),
        textColor: Color(0xFF0F766E),
        borderColor: Color(0xFF99F6E4),
        customTag: 'BNI',
      );
    }

    // 10. SeaBank
    if (text.contains('seabank') || text.contains('searpm')) {
      return const BrandBadgeData(
        label: 'SeaBank',
        icon: Icons.savings_rounded,
        bgColor: Color(0xFFFFF7ED),
        textColor: Color(0xFFC2410C),
        borderColor: Color(0xFFFED7AA),
        customTag: 'SeaBank',
      );
    }

    // 11. Struk / Nota Fisik
    if (text.contains('nota') || text.contains('receipt') || text.contains('ocr')) {
      return const BrandBadgeData(
        label: 'Nota Kasir',
        icon: Icons.receipt_long_rounded,
        bgColor: Color(0xFFECFDF5),
        textColor: Color(0xFF059669),
        borderColor: Color(0xFF6EE7B7),
        customTag: 'Nota',
      );
    }

    // 12. Tunai / Cash
    if (text.contains('tunai') || text.contains('cash')) {
      return const BrandBadgeData(
        label: 'Tunai',
        icon: Icons.payments_rounded,
        bgColor: Color(0xFFF0FDF4),
        textColor: Color(0xFF16A34A),
        borderColor: Color(0xFF86EFAC),
        customTag: 'Cash',
      );
    }

    // 13. Investasi (Bibit / Pluang)
    if (text.contains('bibit') || text.contains('pluang') || text.contains('reksadana')) {
      return const BrandBadgeData(
        label: 'Investasi',
        icon: Icons.trending_up_rounded,
        bgColor: Color(0xFFF5F3FF),
        textColor: Color(0xFF6D28D9),
        borderColor: Color(0xFFC4B5FD),
        customTag: 'Invest',
      );
    }

    // Default Bank / E-Wallet
    return const BrandBadgeData(
      label: 'Transaksi',
      icon: Icons.credit_card_rounded,
      bgColor: Color(0xFFF8FAFC),
      textColor: Color(0xFF475569),
      borderColor: Color(0xFFCBD5E1),
      customTag: 'Bank',
    );
  }

  static Widget buildBadge(String brand, {double size = 44}) {
    return buildBadgeWidget(brand, brand, size: size);
  }

  static Widget buildBadgeWidget(String appName, String merchant, {String? channel, double size = 44}) {
    final badge = getBadge(appName, merchant, channel: channel);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badge.bgColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: badge.borderColor, width: 1.2),
      ),
      child: Center(
        child: badge.customTag != null && badge.customTag == 'QRIS'
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(badge.icon, size: size * 0.44, color: badge.textColor),
                  Text(
                    'QRIS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: badge.textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(badge.icon, size: size * 0.48, color: badge.textColor),
                  if (badge.customTag != null)
                    Text(
                      badge.customTag!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: badge.textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
