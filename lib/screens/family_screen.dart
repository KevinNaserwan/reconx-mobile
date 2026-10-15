import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LanguageService(), AuthService()]),
      builder: (context, _) {
        final user = AuthService().currentUser;
        final familyName = user?.familyName.isNotEmpty == true ? user!.familyName : 'Keluarga Anda';
        final inviteCode = user?.familyInviteCode.isNotEmpty == true ? user!.familyInviteCode : 'FAM-KVN-8821';
        final isDark = AppTheme.isDark(context);

        return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getCard(context),
        elevation: 0,
        title: Text(
          'Household Financial Cluster',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Family Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.getBorder(context)),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppTheme.primaryTeal.withOpacity(0.08),
                          AppTheme.primaryEmerald.withOpacity(0.04),
                        ]
                      : [
                          AppTheme.primaryEmerald.withOpacity(0.06),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      size: 30,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    familyName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Multi-Tenant Household Financial Engine',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Neat & Polished Voucher Style PIN Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryEmerald.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.key_rounded, size: 16, color: AppTheme.primaryEmerald),
                            const SizedBox(width: 8),
                            Text(
                              'PIN Undangan Anggota Keluarga',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryEmerald.withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              inviteCode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: inviteCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppTheme.primaryEmerald,
                                      behavior: SnackBarBehavior.floating,
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                          const SizedBox(width: 10),
                                          Text(
                                            'PIN $inviteCode berhasil disalin!',
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: Text(
                                  'Salin PIN',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryEmerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan PIN ini saat mendaftar di HP Pasangan untuk menghubungkan dompet ke cluster finansial keluarga.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppTheme.getTextSecondary(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Anti-Double Count Feature Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, size: 24, color: AppTheme.primaryCyan),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proteksi Anti-Double Counting',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transfer internal antar rekening keluarga terdeteksi otomatis dan tidak dihitung ganda sebagai pengeluaran bersama.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.getTextSecondary(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Partner & Dompet Bersama',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),

            // Member 1 (Active User Device)
            _buildMemberCard(
              context: context,
              name: user?.name.isNotEmpty == true ? user!.name : 'Pengguna',
              role: user?.role.isNotEmpty == true ? user!.role : 'Kepala Keluarga',
              email: user?.email.isNotEmpty == true ? user!.email : 'Perangkat Terhubung',
              deviceStatus: 'Perangkat Ini (Aktif Syncing)',
              isOnline: true,
              photoUrl: user?.photoUrl,
            ),
            const SizedBox(height: 10),

            // Invitation & Pairing Card for Partner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard.withOpacity(0.6) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryEmerald.withOpacity(0.35),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryEmerald, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hubungkan Perangkat Pasangan / Partner',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Instal ReconX di HP pasangan dan masukkan PIN $inviteCode saat pendaftaran untuk sinkronisasi otomatis.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.getTextSecondary(context),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildMemberCard({
    required BuildContext context,
    required String name,
    required String role,
    required String email,
    required String deviceStatus,
    required bool isOnline,
    String? photoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Row(
        children: [
          AppAvatar(
            photoUrl: photoUrl,
            name: name,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.primaryEmerald : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$role • $email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  deviceStatus,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryCyan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
