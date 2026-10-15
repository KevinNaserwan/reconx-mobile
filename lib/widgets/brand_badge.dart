import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandBadgeData {
  final String label;
  final Widget logoWidget;
  final Color bgColor;
  final Color borderColor;

  const BrandBadgeData({
    required this.label,
    required this.logoWidget,
    required this.bgColor,
    required this.borderColor,
  });
}

class BrandBadgeHelper {
  static BrandBadgeData getBadge(String appName, String merchant, {String? channel, double size = 40}) {
    final text = '${appName.toLowerCase()} ${merchant.toLowerCase()} ${(channel ?? "").toLowerCase()}';

    // 1. QRIS (Official Indonesian National Standard Red & Geometric QR)
    if (text.contains('qris')) {
      return BrandBadgeData(
        label: 'QRIS',
        bgColor: const Color(0xFFED1C24),
        borderColor: const Color(0xFFB91C1C),
        logoWidget: SvgPicture.asset('assets/logos/qris.svg', width: size, height: size),
      );
    }

    // 2. GoPay (Official Cyan-Mint #00AED6 & Concentric Circle)
    if (text.contains('gopay') || text.contains('gojek')) {
      return BrandBadgeData(
        label: 'GoPay',
        bgColor: const Color(0xFF00AED6),
        borderColor: const Color(0xFF0284C7),
        logoWidget: SvgPicture.asset('assets/logos/gopay.svg', width: size, height: size),
      );
    }

    // 3. OVO (Official Royal Purple #4C2A86 & Inner Ring)
    if (text.contains('ovo')) {
      return BrandBadgeData(
        label: 'OVO',
        bgColor: const Color(0xFF4C2A86),
        borderColor: const Color(0xFF3B1D6D),
        logoWidget: SvgPicture.asset('assets/logos/ovo.svg', width: size, height: size),
      );
    }

    // 4. DANA (Official Vivid Blue #118EEA & Geometric D)
    if (text.contains('dana')) {
      return BrandBadgeData(
        label: 'DANA',
        bgColor: const Color(0xFF118EEA),
        borderColor: const Color(0xFF0D72BC),
        logoWidget: SvgPicture.asset('assets/logos/dana.svg', width: size, height: size),
      );
    }

    // 5. ShopeePay (Official Coral Orange #EE4D2D & Shopping Silhouette)
    if (text.contains('shopee') || text.contains('spay')) {
      return BrandBadgeData(
        label: 'ShopeePay',
        bgColor: const Color(0xFFEE4D2D),
        borderColor: const Color(0xFFC2381E),
        logoWidget: SvgPicture.asset('assets/logos/shopeepay.svg', width: size, height: size),
      );
    }

    // 6. BCA / blu (Official Deep Blue #005EAD & Shield Diamond)
    if (text.contains('bca') || text.contains('blu')) {
      return BrandBadgeData(
        label: 'BCA',
        bgColor: const Color(0xFF005EAD),
        borderColor: const Color(0xFF00407A),
        logoWidget: SvgPicture.asset('assets/logos/bca.svg', width: size, height: size),
      );
    }

    // 7. Mandiri / Livin (Official Deep Navy #002D62 & Golden Ribbon)
    if (text.contains('mandiri') || text.contains('livin')) {
      return BrandBadgeData(
        label: 'Mandiri',
        bgColor: const Color(0xFF002D62),
        borderColor: const Color(0xFF001B3B),
        logoWidget: SvgPicture.asset('assets/logos/mandiri.svg', width: size, height: size),
      );
    }

    // 8. BRI / BRImo (Official Oceanic Blue #00529C & Globe Double-Curve)
    if (text.contains('bri') || text.contains('brimo')) {
      return BrandBadgeData(
        label: 'BRImo',
        bgColor: const Color(0xFF00529C),
        borderColor: const Color(0xFF00386C),
        logoWidget: SvgPicture.asset('assets/logos/bri.svg', width: size, height: size),
      );
    }

    // 9. BNI (Official Teal #005E6A & 46 Angular Motif)
    if (text.contains('bni')) {
      return BrandBadgeData(
        label: 'BNI',
        bgColor: const Color(0xFF005E6A),
        borderColor: const Color(0xFF00444D),
        logoWidget: SvgPicture.asset('assets/logos/bni.svg', width: size, height: size),
      );
    }

    // 10. SeaBank (Official Vivid Orange #FF5722 & Digital Wave)
    if (text.contains('seabank') || text.contains('searpm')) {
      return BrandBadgeData(
        label: 'SeaBank',
        bgColor: const Color(0xFFFF5722),
        borderColor: const Color(0xFFD84315),
        logoWidget: SvgPicture.asset('assets/logos/seabank.svg', width: size, height: size),
      );
    }

    // 11. Superbank (Official Rich Violet #7F00FF & Lime Star)
    if (text.contains('superbank')) {
      return BrandBadgeData(
        label: 'Superbank',
        bgColor: const Color(0xFF7F00FF),
        borderColor: const Color(0xFF6200EA),
        logoWidget: SvgPicture.asset('assets/logos/superbank.svg', width: size, height: size),
      );
    }

    // 12. Struk / Nota Kasir (Dark Slate #1E293B & Emerald Ticket)
    if (text.contains('nota') || text.contains('receipt') || text.contains('ocr') || text.contains('kasir')) {
      return BrandBadgeData(
        label: 'Nota Kasir',
        bgColor: const Color(0xFF1E293B),
        borderColor: const Color(0xFF334155),
        logoWidget: Icon(Icons.receipt_long_rounded, color: const Color(0xFF10B981), size: size * 0.55),
      );
    }

    // 13. Tunai / Cash (Emerald #059669 & Cash Note)
    if (text.contains('tunai') || text.contains('cash')) {
      return BrandBadgeData(
        label: 'Tunai',
        bgColor: const Color(0xFF059669),
        borderColor: const Color(0xFF047857),
        logoWidget: Icon(Icons.payments_rounded, color: Colors.white, size: size * 0.55),
      );
    }

    // Default Bank / Card
    return BrandBadgeData(
      label: 'Bank / E-Wallet',
      bgColor: const Color(0xFF334155),
      borderColor: const Color(0xFF475569),
      logoWidget: Icon(Icons.account_balance_rounded, color: Colors.white, size: size * 0.55),
    );
  }

  static Widget buildBadge(String brand, {double size = 42}) {
    return buildBadgeWidget(brand, brand, size: size);
  }

  static Widget buildBadgeWidget(String appName, String merchant, {String? channel, double size = 42}) {
    final badge = getBadge(appName, merchant, channel: channel, size: size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badge.bgColor,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: badge.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: badge.bgColor.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: badge.logoWidget,
      ),
    );
  }

  // --- Brand Geometric Marks (No Text Inside) ---

  // QRIS: Official Geometric QR Pattern in White on Red
  static Widget _buildQrisMark(double size) {
    final s = size * 0.55;
    return SizedBox(
      width: s,
      height: s,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQrSquare(s * 0.42),
              _buildQrSquare(s * 0.42),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQrSquare(s * 0.42),
              Container(
                width: s * 0.42,
                height: s * 0.42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: Center(
                  child: Container(
                    width: s * 0.20,
                    height: s * 0.20,
                    color: const Color(0xFFED1C24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildQrSquare(double boxSize) {
    return Container(
      width: boxSize,
      height: boxSize,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: Container(
        color: const Color(0xFFED1C24),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }

  // GoPay: Concentric White Outer Circle & Inner Circle Dot
  static Widget _buildGoPayMark(double size) {
    return Container(
      width: size * 0.52,
      height: size * 0.52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.075),
      ),
      child: Center(
        child: Container(
          width: size * 0.20,
          height: size * 0.20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // OVO: Royal Purple Ring
  static Widget _buildOvoMark(double size) {
    return Container(
      width: size * 0.54,
      height: size * 0.54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.08),
      ),
      child: Center(
        child: Container(
          width: size * 0.26,
          height: size * 0.26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4C2A86),
            border: Border.all(color: const Color(0xFF9333EA), width: 1.5),
          ),
        ),
      ),
    );
  }

  // DANA: Vivid Blue & Geometric D-Kite
  static Widget _buildDanaMark(double size) {
    return Icon(
      Icons.diamond_rounded,
      color: Colors.white,
      size: size * 0.54,
    );
  }

  // ShopeePay: Warm Coral Orange & Shopping Bag
  static Widget _buildShopeePayMark(double size) {
    return Icon(
      Icons.shopping_bag_rounded,
      color: Colors.white,
      size: size * 0.54,
    );
  }

  // BCA: Royal Blue & Shield Diamond
  static Widget _buildBcaMark(double size) {
    return Icon(
      Icons.shield_rounded,
      color: Colors.white,
      size: size * 0.56,
    );
  }

  // Mandiri: Navy & Golden Ribbon Accent
  static Widget _buildMandiriMark(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.waves_rounded, color: const Color(0xFFF5B800), size: size * 0.58),
        Icon(Icons.crop_square_rounded, color: Colors.white.withOpacity(0.9), size: size * 0.40),
      ],
    );
  }

  // BRI: Oceanic Blue & Dual Curve
  static Widget _buildBriMark(double size) {
    return Icon(
      Icons.motion_photos_on_rounded,
      color: Colors.white,
      size: size * 0.54,
    );
  }

  // BNI: Turquoise & Angular Motif
  static Widget _buildBniMark(double size) {
    return Icon(
      Icons.change_history_rounded,
      color: Colors.white,
      size: size * 0.54,
    );
  }

  // SeaBank: Orange & Ocean Digital Wave
  static Widget _buildSeaBankMark(double size) {
    return Icon(
      Icons.water_rounded,
      color: Colors.white,
      size: size * 0.54,
    );
  }

  // Superbank: Rich Purple & Neon Star
  static Widget _buildSuperbankMark(double size) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: const Color(0xFFCCFF00),
      size: size * 0.54,
    );
  }
}
