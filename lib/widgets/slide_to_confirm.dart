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
    this.text = 'Geser untuk Konfirmasi >>>',
    this.isLoading = false,
    this.height = 58.0,
    this.trackColor,
    this.sliderColor,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _resetAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      });
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
    final effectiveTrackColor = widget.trackColor ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final thumbSize = widget.height - 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - widget.height;

        return Container(
          width: constraints.maxWidth,
          height: widget.height,
          decoration: BoxDecoration(
            color: effectiveTrackColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Filled Progress Track Behind Thumb
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + (widget.height / 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryEmerald.withOpacity(0.3),
                        AppTheme.primaryCyan.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              ),

              // Centered Shimmer / Hint Text
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.height * 0.7),
                  child: Opacity(
                    opacity: (1.0 - (_dragPosition / maxDrag).clamp(0.0, 1.0) * 1.5).clamp(0.0, 1.0),
                    child: Text(
                      widget.isLoading ? 'Menyimpan...' : widget.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),

              // Draggable Thumb Slider
              Positioned(
                left: 4 + _dragPosition,
                top: 4,
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
                          if (_dragPosition >= maxDrag * 0.85) {
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
                          AppTheme.primaryEmerald,
                          AppTheme.primaryCyan,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isConfirmed ? Icons.check_rounded : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
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
