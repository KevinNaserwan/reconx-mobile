import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  int _activeTab = 0; // 0 = Login, 1 = Register

  final _emailController = TextEditingController(text: 'kevin.naserwan@gmail.com');
  final _nameController = TextEditingController(text: 'Kevin Naserwan');
  final _familyNameController = TextEditingController(text: 'Keluarga Kevin & Istri');
  final _inviteCodeController = TextEditingController(text: 'FAM-KVN-8821');
  bool _isJoiningFamily = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final success = await AuthService().signInWithGoogle();
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _handleSubmitForm() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan email Anda.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : email.split('@')[0];

    final familyName = _isJoiningFamily ? null : _familyNameController.text.trim();
    final inviteCode = _isJoiningFamily ? _inviteCodeController.text.trim() : null;

    final success = await AuthService().registerOrLogin(
      name: name,
      email: email,
      familyName: familyName,
      inviteCode: inviteCode,
      role: _isJoiningFamily ? 'Anggota Keluarga' : 'Head of Household (Kepala Keluarga)',
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Brand Icon & Titles
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryEmerald,
                      AppTheme.primaryTeal,
                      AppTheme.primaryCyan,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryEmerald.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(36, 36),
                    painter: _LogoNodePainter(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  children: const [
                    TextSpan(text: 'Recon'),
                    TextSpan(
                      text: 'X',
                      style: TextStyle(color: AppTheme.primaryEmerald),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  'MULTI-TENANT HOUSEHOLD AGENT',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryEmerald,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Auto-sync mutasi bank & e-wallet ke ReconX Household Ledger secara real-time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.darkTextSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Tab Switcher
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkCardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? AppTheme.primaryEmerald : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Text(
                              'Masuk (Login)',
                              style: GoogleFonts.plusJakartaSans(
                                color: _activeTab == 0 ? Colors.white : AppTheme.darkTextSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? AppTheme.primaryEmerald : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Text(
                              'Daftar Baru (Register)',
                              style: GoogleFonts.plusJakartaSans(
                                color: _activeTab == 1 ? Colors.white : AppTheme.darkTextSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Fast Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata_rounded, size: 26, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Masuk Cepat dengan Google',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.darkCardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'atau dengan akun',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.darkCardBorder)),
                ],
              ),
              const SizedBox(height: 16),

              // Email & Custom Form
              if (_activeTab == 1) ...[
                _buildTextField(
                  label: 'Nama Lengkap',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  hint: 'Budi Pratama',
                ),
                const SizedBox(height: 12),
              ],

              _buildTextField(
                label: 'Email Pengguna',
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: 'user@reconx.io',
                keyboardType: TextInputType.emailAddress,
              ),

              if (_activeTab == 1) ...[
                const SizedBox(height: 14),

                // Household Multi-Tenant Options
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Buat Keluarga'),
                        selected: !_isJoiningFamily,
                        onSelected: (val) => setState(() => _isJoiningFamily = false),
                        selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          color: !_isJoiningFamily ? AppTheme.primaryEmerald : AppTheme.darkTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Gabung via PIN'),
                        selected: _isJoiningFamily,
                        onSelected: (val) => setState(() => _isJoiningFamily = true),
                        selectedColor: AppTheme.primaryCyan.withOpacity(0.2),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          color: _isJoiningFamily ? AppTheme.primaryCyan : AppTheme.darkTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (!_isJoiningFamily)
                  _buildTextField(
                    label: 'Nama Cluster Keluarga',
                    controller: _familyNameController,
                    icon: Icons.family_restroom,
                    hint: 'Keluarga Pratama & Istri',
                  )
                else
                  _buildTextField(
                    label: 'PIN Undangan Keluarga',
                    controller: _inviteCodeController,
                    icon: Icons.vpn_key_outlined,
                    hint: 'FAM-KVN-8821',
                  ),
              ],

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _activeTab == 0 ? 'Masuk ke Companion' : 'Daftar Akun & Sync Tenant',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Security Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security,
                    size: 13,
                    color: AppTheme.primaryEmerald,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Multi-Tenant SaaS • TLS 256-bit Encrypted',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.darkTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkCardBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
              prefixIcon: Icon(icon, size: 18, color: AppTheme.darkTextSecondary),
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoNodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint1,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      paint1,
    );

    final nodePaint = Paint()
      ..color = const Color(0xFF022C22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 5.5, nodePaint);

    final centerDotPaint = Paint()
      ..color = AppTheme.primaryEmerald
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 2.5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
