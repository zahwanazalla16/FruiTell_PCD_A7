import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../services/dummy_content_service.dart';
import '../services/inference_service.dart';
import 'scan_result_page.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final InferenceService _inferenceService = InferenceService();
  final List<DominantDetection> _recentDetections = [];
  CameraController? _controller;
  Timer? _detectTimer;
  bool _isFrameBusy = false;
  bool _isModelReady = false;
  DetectionResult? _latestDetection;

  static const int _stabilityWindow = 3;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _inferenceService.initModel();
    _isModelReady = true;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    _detectTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _runRealtimeDetection();
    });
  }

  Future<void> _runRealtimeDetection() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isModelReady ||
        _isFrameBusy) {
      return;
    }

    _isFrameBusy = true;
    try {
      final photo = await _controller!.takePicture();
      final result = await _inferenceService.detectDominantFromFile(
        File(photo.path),
      );

      if (result != null) {
        _recentDetections.add(result);
        if (_recentDetections.length > _stabilityWindow) {
          _recentDetections.removeAt(0);
        }
      } else {
        _recentDetections.clear();
      }

      final stable = _getStableDetection();
      if (stable != null && mounted) {
        setState(() {
          _latestDetection = DummyContentService.enrich(
            stable.label,
            stable.confidence,
          );
        });
      } else if (mounted && result == null) {
        setState(() {
          _latestDetection = null;
        });
      }
    } catch (_) {
      // Ignore frame-level errors to keep live detection loop running.
    } finally {
      _isFrameBusy = false;
    }
  }

  Future<void> _confirmAndOpenResult() async {
    if (_controller == null || _latestDetection == null) return;

    final photo = await _controller!.takePicture();
    final result = await _inferenceService.detectDominantFromFile(
      File(photo.path),
    );
    if (!mounted || result == null) return;

    final enriched = DummyContentService.enrich(
      result.label,
      result.confidence,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultPage(
          result: enriched,
          imageFile: File(photo.path),
          onSave: () async {
            await _inferenceService.saveResult(
              label: enriched.label,
              confidence: enriched.confidence,
              imagePath: photo.path,
              syncCloud: true,
            );
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _latestDetection = enriched;
    });
  }

  DominantDetection? _getStableDetection() {
    if (_recentDetections.length < _stabilityWindow) {
      return null;
    }

    final lastLabel = _recentDetections.last.label;
    final isStable = _recentDetections.every((item) => item.label == lastLabel);
    if (!isStable) {
      return null;
    }

    final avgConfidence =
        _recentDetections
            .map((item) => item.confidence)
            .reduce((a, b) => a + b) /
        _recentDetections.length;

    return DominantDetection(label: lastLabel, confidence: avgConfidence);
  }

  @override
  void dispose() {
    _detectTimer?.cancel();
    _controller?.dispose();
    _inferenceService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_controller!)),
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
            child: _latestDetection == null
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
                          _latestDetection!.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(_latestDetection!.confidence * 100).toStringAsFixed(1)}%',
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
            onPressed: _latestDetection == null ? null : _confirmAndOpenResult,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE93E9D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Konfirmasi & Lihat Hasil'),
          ),
        ),
      ],
    );
  }
}
