import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/providers.dart';

/// Barcode scanner — uses mobile_scanner + Open Food Facts lookup.
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _processing = false;
  String? _lastBarcode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastBarcode) return;
    _lastBarcode = barcode;
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();
    await _controller.stop();

    final repo = ref.read(foodSearchRepositoryProvider);
    final result = await repo.lookupBarcode(barcode);

    if (!mounted) return;
    if (result == null) {
      _showNotFound(barcode);
      return;
    }
    // Go to portion editor
    context.push('/manual/portion', extra: result);
  }

  void _showNotFound(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Not in our database'),
        content: Text(
          'We couldn\'t find product info for barcode $barcode.\n\n'
          'Try logging this food manually by searching instead.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _lastBarcode = null;
              _controller.start();
              setState(() => _processing = false);
            },
            child: const Text('Scan another'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushReplacement('/manual/search');
            },
            child: const Text('Search manually'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _ScannerError(error: error),
          ),

          // Viewfinder overlay
          _ScannerOverlay(processing: _processing),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _CircleIconBtn(
                      icon: Icons.close_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    _CircleIconBtn(
                      icon: Icons.flash_on,
                      onTap: () => _controller.toggleTorch(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom hint
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _processing ? 'Looking up product…' : 'Align barcode within frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Works with most packaged food items worldwide',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.processing});
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 280,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Corner accents
              ...List.generate(4, (i) {
                final isLeft = i.isEven;
                final isTop = i < 2;
                return Positioned(
                  top: isTop ? 0 : null,
                  bottom: !isTop ? 0 : null,
                  left: isLeft ? 0 : null,
                  right: !isLeft ? 0 : null,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border(
                        top: isTop
                            ? const BorderSide(color: AppColors.brand, width: 4)
                            : BorderSide.none,
                        bottom: !isTop
                            ? const BorderSide(color: AppColors.brand, width: 4)
                            : BorderSide.none,
                        left: isLeft
                            ? const BorderSide(color: AppColors.brand, width: 4)
                            : BorderSide.none,
                        right: !isLeft
                            ? const BorderSide(color: AppColors.brand, width: 4)
                            : BorderSide.none,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
                        topRight: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
                        bottomLeft: !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
                        bottomRight: !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
                      ),
                    ),
                  ),
                );
              }),
              // Animated scan line
              if (!processing)
                AnimatedBuilder(
                  animation: AlwaysStoppedAnimation(0),
                  builder: (context, _) {
                    return _ScanLine();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Align(
          alignment: Alignment(0, _controller.value * 2 - 1),
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brand.withOpacity(0),
                  AppColors.brand,
                  AppColors.brand.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Camera unavailable',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Grant camera permission in your device settings to scan barcodes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}