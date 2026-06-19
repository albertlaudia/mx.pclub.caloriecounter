import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/animation/app_motion.dart';
import '../../core/theme/app_colors.dart';

/// Multi-action FAB — opens a small menu with: snap, search, barcode.
class SnapMenu extends StatefulWidget {
  const SnapMenu({super.key});

  @override
  State<SnapMenu> createState() => _SnapMenuState();
}

class _SnapMenuState extends State<SnapMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: AppMotion.standard),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: AppMotion.standard),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Sub-actions
        if (_open) ...[
          Positioned(
            bottom: 100,
            child: _SubAction(
              label: 'Search food',
              emoji: '🔍',
              color: AppColors.sky,
              onTap: () {
                _toggle();
                context.push('/manual/search');
              },
            ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.3, end: 0, duration: 220.ms),
          ),
          const SizedBox(height: 8),
          Positioned(
            bottom: 170,
            child: _SubAction(
              label: 'Scan barcode',
              emoji: '📷',
              color: AppColors.lavender,
              onTap: () {
                _toggle();
                context.push('/barcode');
              },
            ).animate().fadeIn(duration: 220.ms, delay: 60.ms).slideY(begin: 0.3, end: 0),
          ),
        ],

        // Backdrop
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(color: Colors.black.withOpacity(0.4)),
            ).animate().fadeIn(duration: 200.ms),
          ),

        // Main FAB
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return GestureDetector(
              onTap: () {
                if (_open) {
                  _toggle();
                } else {
                  context.push('/camera');
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!_open)
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withOpacity(_glowAnim.value),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  Transform.scale(
                    scale: _open ? 1.0 : _scaleAnim.value,
                    child: AnimatedContainer(
                      duration: AppMotion.normal,
                      curve: AppMotion.emphasized,
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: _open ? 0.125 : 0,
                        duration: AppMotion.normal,
                        curve: AppMotion.emphasized,
                        child: Icon(
                          _open ? Icons.close_rounded : Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SubAction extends StatelessWidget {
  const _SubAction({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: AppColors.textTertiary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}