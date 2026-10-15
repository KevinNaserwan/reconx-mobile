import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SlideToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback onConfirmed;
  final bool isLoading;
  final double height;
  final Color? trackColor;
  final Color? sliderColor;

  const SlideToConfirm({
    super.key,
    required this.onConfirmed,
    this.text = 'Geser untuk Simpan Mutasi',
    this.isLoading = false,
    this.height = 62.0,
    this.trackColor,
    this.sliderColor,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with TickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _resetAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && _isConfirmed) {
      _resetSlider();
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _resetSlider() {
    setState(() {
      _isConfirmed = false;
    });
    _resetAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final effectiveTrackColor = widget.trackColor ?? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9));
    final thumbSize = widget.height - 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - widget.height;
        final dragPercent = (maxDrag > 0) ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          width: constraints.maxWidth,
          height: widget.height,
          decoration: BoxDecoration(
            color: effectiveTrackColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: isDark ? AppTheme.primaryEmerald.withOpacity(0.35) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (isDark)
                BoxShadow(
                  color: AppTheme.primaryEmerald.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Dynamic Progress Glow Track Behind Thumb
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + (widget.height / 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryEmerald.withOpacity(0.45),
                        AppTheme.primaryCyan.withOpacity(0.55),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              ),

              // 2. Centered Animated Text & Chevrons
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.height * 0.8),
                    child: Opacity(
                      opacity: (1.0 - (dragPercent * 1.6)).clamp(0.0, 1.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.isLoading ? 'Menyimpan Mutasi...' : widget.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (!widget.isLoading) ...[
                            const SizedBox(width: 6),
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, _) => Opacity(
                                opacity: _pulseAnimation.value,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: isDark ? AppTheme.primaryEmerald : const Color(0xFF0F766E),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: isDark ? AppTheme.primaryCyan : const Color(0xFF0D9488),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Draggable Jewel Knob (Thumb)
              Positioned(
                left: 5 + _dragPosition,
                top: 5,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.isLoading || _isConfirmed
                      ? null
                      : (details) {
                          setState(() {
                            _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                          });
                        },
                  onHorizontalDragEnd: widget.isLoading || _isConfirmed
                      ? null
                      : (details) {
                          if (_dragPosition >= maxDrag * 0.72) {
                            // Completed!
                            HapticFeedback.heavyImpact();
                            setState(() {
                              _dragPosition = maxDrag;
                              _isConfirmed = true;
                            });
                            widget.onConfirmed();
                          } else {
                            // Reset back
                            HapticFeedback.lightImpact();
                            _resetSlider();
                          }
                        },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF06B6D4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.55),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isConfirmed ? Icons.check_rounded : Icons.keyboard_double_arrow_right_rounded,
                                key: ValueKey(_isConfirmed),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
