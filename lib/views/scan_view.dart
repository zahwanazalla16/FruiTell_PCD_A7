import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/scan_controller.dart';
import 'scan_result_view.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> with SingleTickerProviderStateMixin {
  late final ScanController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _laserAnimation;
  bool _showSliders = false;

  ColorFilter _buildPreviewFilter() {
    if (!_controller.contrastEnhancementEnabled) {
      return const ColorFilter.matrix(<double>[
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }

    final contrast = _controller.contrastLevel.clamp(0.5, 2.0);
    final brightness =
        _controller.brightnessLevel +
        (contrast >= 1.0
            ? (contrast - 1.0) * 18.0
            : -((1.0 - contrast) * 14.0));

    return ColorFilter.matrix(<double>[
      contrast,
      0,
      0,
      0,
      (1 - contrast) * 128 + brightness,
      0,
      contrast,
      0,
      0,
      (1 - contrast) * 128 + brightness,
      0,
      0,
      contrast,
      0,
      (1 - contrast) * 128 + brightness,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  @override
  void initState() {
    super.initState();
    _controller = ScanController();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmAndOpenResult() async {
    _controller.pauseDetection();
    final enriched = await _controller.confirmAndCapture();
    if (!mounted || enriched == null) {
      _controller.resumeDetection();
      return;
    }

    final imagePath = _controller.lastImagePath;
    if (imagePath == null) {
      _controller.resumeDetection();
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultView(
          result: enriched,
          imageFile: File(imagePath),
          onSave: () async {
            await _controller.saveDetectionResult(
              label: enriched.label,
              confidence: enriched.confidence,
              imagePath: imagePath,
            );
          },
        ),
      ),
    );

    if (mounted) {
      _controller.resumeDetection();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.controller == null || !_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double scanSize = width * 0.70;
        final double topOffset = (height - scanSize) / 2;
        final double leftOffset = (width - scanSize) / 2;

        return Stack(
          children: [
            // Preview Kamera
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: _buildPreviewFilter(),
                child: CameraPreview(_controller.controller!),
              ),
            ),

            // Kustom Overlay Painter (lubang transparan di tengah + siku siku pink)
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(scanAreaPercent: 0.70),
              ),
            ),

            // Animasi Garis Laser
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                final double y = topOffset + (scanSize * _laserAnimation.value);
                return Positioned(
                  left: leftOffset + 12,
                  width: scanSize - 24,
                  top: y,
                  child: Container(
                    height: 3.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE93E9D),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE93E9D).withValues(alpha: 0.60),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Petunjuk di atas kotak scan
            Positioned(
              left: 16,
              right: 16,
              top: topOffset - 36,
              child: const Center(
                child: Text(
                  'Arahkan kamera ke buah di dalam kotak',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(0, 1.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Panel Pengaturan Kontras / Brightness / Flashlight
            Positioned(
              left: 16,
              right: 16,
              top: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                       children: [
                         if (widget.onBack != null) ...[
                           IconButton(
                             onPressed: widget.onBack,
                             icon: const Icon(
                               Icons.arrow_back_ios_new_rounded,
                               color: Colors.white,
                               size: 20,
                             ),
                             tooltip: 'Kembali',
                           ),
                           const SizedBox(width: 4),
                         ],
                         Expanded(
                           child: Row(
                             children: [
                               const Text(
                                 'Enhance Kontras',
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontWeight: FontWeight.w600,
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Switch(
                                 value: _controller.contrastEnhancementEnabled,
                                 onChanged: (val) {
                                   _controller.setContrastEnhancementEnabled(val);
                                   setState(() {
                                     _showSliders = val;
                                   });
                                 },
                                 activeThumbColor: const Color(0xFFE93E9D),
                               ),
                             ],
                           ),
                         ),
                         if (_controller.contrastEnhancementEnabled) ...[
                           IconButton(
                             onPressed: () {
                               setState(() {
                                 _showSliders = !_showSliders;
                               });
                             },
                             icon: Icon(
                               _showSliders
                                   ? Icons.expand_less_rounded
                                   : Icons.tune_rounded,
                               color: _showSliders
                                   ? const Color(0xFFE93E9D)
                                   : Colors.white,
                             ),
                             tooltip: 'Atur Kontras & Brightness',
                           ),
                         ],
                         IconButton(
                           onPressed: _controller.toggleFlashlight,
                           icon: Icon(
                             _controller.isFlashOn
                                 ? Icons.flashlight_on
                                 : Icons.flashlight_off,
                             color: _controller.isFlashOn
                                 ? Colors.amber
                                 : Colors.white,
                           ),
                           tooltip: 'Flashlight',
                         ),
                       ],
                     ),
                    if (_controller.contrastEnhancementEnabled && _showSliders) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Level Kontras: ${_controller.contrastLevel.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Slider(
                        min: 0.8,
                        max: 1.6,
                        divisions: 8,
                        value: _controller.contrastLevel,
                        activeColor: const Color(0xFFE93E9D),
                        onChanged: _controller.setContrastLevel,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level Brightness: ${_controller.brightnessLevel.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Slider(
                        min: -30.0,
                        max: 30.0,
                        divisions: 12,
                        value: _controller.brightnessLevel,
                        activeColor: const Color(0xFFE93E9D),
                        onChanged: _controller.setBrightnessLevel,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Informasi Deteksi Buah Dominan
            Positioned(
              left: 16,
              right: 16,
              bottom: 116,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _controller.latestDetection == null
                    ? const Text(
                        'Mencari buah dominan...',
                        style: TextStyle(color: Colors.white),
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFE93E9D),
                            ),
                            child: Text(
                              _controller.latestDetection!.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(_controller.latestDetection!.confidence * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Tombol Konfirmasi Tindakan
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: ElevatedButton.icon(
                onPressed: (_controller.latestDetection == null || _controller.isProcessing)
                    ? null
                    : _confirmAndOpenResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE93E9D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _controller.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_controller.isProcessing
                    ? 'Memproses...'
                    : 'Konfirmasi & Lihat Hasil'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaPercent;
  ScannerOverlayPainter({this.scanAreaPercent = 0.70});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;

    // Hitung ukuran kotak scan
    final double scanSize = size.width * scanAreaPercent;
    final double left = (size.width - scanSize) / 2;
    final double top = (size.height - scanSize) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);
    final RRect scanRRect = RRect.fromRectAndRadius(scanRect, const Radius.circular(16));

    // Gambar background hitam semi-transparan berlubang di tengah
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(scanRRect),
      ),
      backgroundPaint,
    );

    // Konfigurasi siku kotak pemindaian
    final borderPaint = Paint()
      ..color = const Color(0xFFE93E9D) // Main theme pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final double cornerLength = 20.0;

    // Siku Kiri Atas
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );

    // Siku Kanan Atas
    canvas.drawPath(
      Path()
        ..moveTo(left + scanSize - cornerLength, top)
        ..lineTo(left + scanSize, top)
        ..lineTo(left + scanSize, top + cornerLength),
      borderPaint,
    );

    // Siku Kiri Bawah
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanSize - cornerLength)
        ..lineTo(left, top + scanSize)
        ..lineTo(left + cornerLength, top + scanSize),
      borderPaint,
    );

    // Siku Kanan Bawah
    canvas.drawPath(
      Path()
        ..moveTo(left + scanSize - cornerLength, top + scanSize)
        ..lineTo(left + scanSize, top + scanSize)
        ..lineTo(left + scanSize, top + scanSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
