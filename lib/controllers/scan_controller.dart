import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../services/dummy_content_service.dart';
import '../services/inference_service.dart';

class ScanController extends ChangeNotifier {
  final InferenceService _inferenceService = InferenceService();
  final List<DominantDetection> _recentDetections = [];
  CameraController? _controller;
  Timer? _detectTimer;
  bool _isFrameBusy = false;
  bool _isModelReady = false;
  DetectionResult? _latestDetection;
  String? _errorMessage;
  String? _lastImagePath;
  bool _isFlashOn = false;
  bool _contrastEnhancementEnabled = true;
  double _contrastLevel = 1.0;

  static const int _stabilityWindow = 3;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  DetectionResult? get latestDetection => _latestDetection;
  String? get errorMessage => _errorMessage;
  bool get isModelReady => _isModelReady;
  String? get lastImagePath => _lastImagePath;
  bool get isFlashOn => _isFlashOn;
  bool get contrastEnhancementEnabled => _contrastEnhancementEnabled;
  double get contrastLevel => _contrastLevel;

  /// Initialize camera dan model
  Future<void> initialize() async {
    try {
      await _inferenceService.initModel();
      _isModelReady = true;
      notifyListeners();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'Tidak ada kamera tersedia';
        notifyListeners();
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      _inferenceService.setContrastEnhancementEnabled(
        _contrastEnhancementEnabled,
      );
      _inferenceService.setContrastBoost(_contrastLevel);
      notifyListeners();

      // Mulai deteksi real-time setiap 2 detik
      _detectTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _runRealtimeDetection();
      });
    } catch (e) {
      _errorMessage = 'Error initialize: $e';
      notifyListeners();
    }
  }

  /// Jalankan deteksi real-time setiap interval
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
      if (stable != null) {
        _latestDetection = DummyContentService.enrich(
          stable.label,
          stable.confidence,
        );
      } else if (result == null) {
        _latestDetection = null;
      }
      notifyListeners();
    } catch (_) {
      // Ignore frame-level errors to keep live detection loop running.
    } finally {
      _isFrameBusy = false;
    }
  }

  /// Ambil deteksi stabil (3 frame konsisten)
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

  /// Confirm dan ambil foto final untuk result
  Future<DominantDetection?> confirmAndCapture() async {
    if (_controller == null || _latestDetection == null) return null;

    try {
      final photo = await _controller!.takePicture();
      _lastImagePath = photo.path;
      final result = await _inferenceService.detectDominantFromFile(
        File(photo.path),
      );
      return result;
    } catch (e) {
      _errorMessage = 'Error capture: $e';
      notifyListeners();
      return null;
    }
  }

  /// Simpan hasil ke Hive dan Supabase
  Future<void> saveDetectionResult({
    required String label,
    required double confidence,
    required String imagePath,
  }) async {
    try {
      await _inferenceService.saveResult(
        label: label,
        confidence: confidence,
        imagePath: imagePath,
        syncCloud: true,
      );
    } catch (e) {
      _errorMessage = 'Error save: $e';
      notifyListeners();
    }
  }

  void setContrastEnhancementEnabled(bool enabled) {
    if (_contrastEnhancementEnabled == enabled) return;
    _contrastEnhancementEnabled = enabled;
    _inferenceService.setContrastEnhancementEnabled(enabled);
    notifyListeners();
  }

  void setContrastLevel(double value) {
    final normalized = value.clamp(0.5, 2.0);
    if ((_contrastLevel - normalized).abs() < 0.001) return;
    _contrastLevel = normalized;
    _inferenceService.setContrastBoost(_contrastLevel);
    notifyListeners();
  }

  Future<void> toggleFlashlight() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final target = !_isFlashOn;
      await _controller!.setFlashMode(target ? FlashMode.torch : FlashMode.off);
      _isFlashOn = target;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error flashlight: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _detectTimer?.cancel();
    _controller?.dispose();
    _inferenceService.close();
    super.dispose();
  }
}
