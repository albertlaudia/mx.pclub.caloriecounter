import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../core/animation/app_motion.dart';
import '../../core/theme/app_colors.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _isProcessing = false;
  bool _flashOn = false;

  late final AnimationController _shutterController;
  late final Animation<double> _shutterAnim;

  @override
  void initState() {
    super.initState();
    _shutterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shutterAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shutterController, curve: AppMotion.emphasized),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _initFuture = _controller!.initialize();
      await _initFuture;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _shutterController.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    // Shutter animation
    HapticFeedback.mediumImpact();
    _shutterController.forward().then((_) => _shutterController.reverse());

    try {
      final XFile raw = await _controller!.takePicture();
      final compressed = await _compress(File(raw.path));

      if (!mounted) return;
      await context.push('/review', extra: compressed.path);
    } catch (e) {
      _showError('Could not capture photo: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 90,
      );
      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }
      final compressed = await _compress(File(picked.path));
      if (!mounted) return;
      await context.push('/review', extra: compressed.path);
    } catch (e) {
      _showError('Could not pick image: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<File> _compress(File input) async {
    final bytes = await input.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return input;

    // Resize to max 1280px, JPEG quality 80
    final resized = decoded.width > decoded.height
        ? img.copyResize(decoded, width: 1280)
        : img.copyResize(decoded, height: 1280);

    final compressed = img.encodeJpg(resized, quality: 80);
    final outPath = input.path.replaceAll('.jpg', '_c.jpg');
    final outFile = File(outPath);
    await outFile.writeAsBytes(compressed);
    return outFile;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    _flashOn = !_flashOn;
    await _controller!.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_initFuture != null)
            FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return ScaleTransition(
                  scale: _shutterAnim,
                  child: CameraPreview(_controller!),
                );
              },
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

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
                    _CircleIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    _CircleIconButton(
                      icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      'Center your meal in the frame',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery
                        _CircleIconButton(
                          icon: Icons.photo_library_outlined,
                          onTap: _pickFromGallery,
                          size: 52,
                        ),
                        // Shutter
                        _ShutterButton(
                          isProcessing: _isProcessing,
                          onTap: _captureAndProcess,
                        ),
                        // Spacer for symmetry
                        const SizedBox(width: 52, height: 52),
                      ],
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.isProcessing, required this.onTap});
  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isProcessing
                  ? Colors.white.withOpacity(0.5)
                  : AppColors.brand,
            ),
            child: isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      color: AppColors.brand,
                      strokeWidth: 3,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}