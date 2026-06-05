import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/scan_controller.dart';
import 'scan_result_view.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  late final ScanController _controller;

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
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.controller == null || !_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: _buildPreviewFilter(),
            child: CameraPreview(_controller.controller!),
          ),
        ),
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
                            onChanged:
                                _controller.setContrastEnhancementEnabled,
                            activeThumbColor: const Color(0xFFE93E9D),
                          ),
                        ],
                      ),
                    ),
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
                const SizedBox(height: 2),
                Text(
                  'Level Kontras: ${_controller.contrastLevel.toStringAsFixed(2)}x',
                  style: TextStyle(
                    color: _controller.contrastEnhancementEnabled
                        ? Colors.white
                        : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Slider(
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  value: _controller.contrastLevel,
                  activeColor: const Color(0xFFE93E9D),
                  onChanged: _controller.contrastEnhancementEnabled
                      ? _controller.setContrastLevel
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  'Level Brightness: ${_controller.brightnessLevel.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: _controller.contrastEnhancementEnabled
                        ? Colors.white
                        : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Slider(
                  min: -30.0,
                  max: 30.0,
                  divisions: 12,
                  value: _controller.brightnessLevel,
                  activeColor: const Color(0xFFE93E9D),
                  onChanged: _controller.contrastEnhancementEnabled
                      ? _controller.setBrightnessLevel
                      : null,
                ),
              ],
            ),
          ),
        ),
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
  }
}
