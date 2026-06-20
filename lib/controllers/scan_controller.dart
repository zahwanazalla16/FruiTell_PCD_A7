import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../models/ripeness_analysis_input.dart';
import '../services/dummy_content_service.dart';
import '../services/inference_service.dart';
import '../services/ripeness_analyzer_service.dart';
import '../services/supabase_fruit_service.dart';

class ScanController extends ChangeNotifier {
  final InferenceService _inferenceService = InferenceService();
  final List<DominantDetection> _recentDetections = [];
  CameraController? _controller;
  Timer? _detectTimer;
  bool _isFrameBusy = false;
  bool _isModelReady = false;
  bool _isProcessing = false;
  DetectionResult? _latestDetection;
  String? _errorMessage;
  String? _lastImagePath;
  bool _isFlashOn = false;
  bool _contrastEnhancementEnabled = true;
  double _contrastLevel = 1.0;
  double _brightnessLevel = 0.0;

  static const int _stabilityWindow = 2;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isProcessing => _isProcessing;
  DetectionResult? get latestDetection => _latestDetection;
  String? get errorMessage => _errorMessage;
  bool get isModelReady => _isModelReady;
  String? get lastImagePath => _lastImagePath;
  bool get isFlashOn => _isFlashOn;
  bool get contrastEnhancementEnabled => _contrastEnhancementEnabled;
  double get contrastLevel => _contrastLevel;
  double get brightnessLevel => _brightnessLevel;

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
      _inferenceService.setBrightnessManual(_brightnessLevel);
      notifyListeners();

      // Mulai deteksi real-time setiap 1.5 detik (dipercepat karena PCD dipindah ke Isolate)
      _detectTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
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
  Future<DetectionResult?> confirmAndCapture() async {
    if (_controller == null || _latestDetection == null || _isProcessing) return null;

    _isProcessing = true;
    notifyListeners();

    try {
      final photo = await _controller!.takePicture();
      _lastImagePath = photo.path;
      final result = await _inferenceService.detectDominantFromFile(
        File(photo.path),
        overwriteOriginal: true,
      );
      if (result == null) return null;

      final enriched = await enrichWithRipenessAnalysis(result);
      return enriched;
    } catch (e) {
      _errorMessage = 'Error capture: $e';
      notifyListeners();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Enrich detection result dengan AI ripeness analysis dari Supabase
  /// Returns DetectionResult dengan ripeness metadata jika fruit ada di database
  Future<DetectionResult> enrichWithRipenessAnalysis(
    DominantDetection detection,
  ) async {
    try {
      // Fallback ke dummy content dulu
      var result = DummyContentService.enrich(detection.label, detection.confidence);

      // Normalize fruit name dari label
      final fruitName = _normalizeFruitName(detection.label);

      // Query Supabase untuk fruit data
      final fruitData = await SupabaseFruitService.getFruitData(fruitName);

      if (fruitData.characteristics != null && fruitData.levels.isNotEmpty) {
        // Ada data di database, lanjut analyze
        print('[ScanController] Fruit $fruitName ditemukan di database');

        // Prepare input untuk ripeness analyzer
        final input = RipenessAnalysisInput(
          fruitLabel: detection.label,
          confidence: detection.confidence,
          averageLuma: detection.averageLuma,
          captureTime: DateTime.now(),
        );

        // Analyze ripeness
        final ripenessResult = RipenessAnalyzerService.analyzeRipeness(
          input: input,
          fruitChar: fruitData.characteristics!,
          ripenessLevels: fruitData.levels,
        );

        // Merge dengan existing result
        result = DetectionResult(
          label: result.label,
          confidence: result.confidence,
          ripeness: result.ripeness,
          freshness: result.freshness,
          bestBefore: result.bestBefore,
          tips: ripenessResult.preparationTips, // Use AI tips
          // New ripeness fields
          ripenessLevel: ripenessResult.ripenessLevel,
          ripenessScore: ripenessResult.ripenessScore,
          aiConfidence: ripenessResult.aiConfidence,
          bestEatDate: ripenessResult.bestEatDate,
          bestEatRange: ripenessResult.bestEatRange,
          storageMethod: ripenessResult.storageMethod,
          fruitName: fruitName,
        );

        print(
          '[ScanController] Ripeness enriched: ${ripenessResult.levelIndonesian} '
          '(${ripenessResult.ripenessScore}% confidence: ${(ripenessResult.aiConfidence * 100).toStringAsFixed(0)}%)',
        );
      } else {
        print('[ScanController] Fruit $fruitName tidak ada di database, gunakan dummy data');
      }

      return result;
    } catch (e) {
      print('[ScanController] Error enrichWithRipenessAnalysis: $e');
      // Fallback ke dummy content
      return DummyContentService.enrich(detection.label, detection.confidence);
    }
  }

  /// Normalize fruit name dari label
  static String _normalizeFruitName(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('apple')) return 'apple';
    if (normalized.contains('banana')) return 'banana';
    if (normalized.contains('mango')) return 'mango';
    if (normalized.contains('orange')) return 'orange';
    if (normalized.contains('papaya')) return 'papaya';
    if (normalized.contains('strawberry')) return 'strawberry';
    if (normalized.contains('dragon')) return 'dragon_fruit';
    return normalized;
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

  void setBrightnessLevel(double value) {
    if ((_brightnessLevel - value).abs() < 0.001) return;
    _brightnessLevel = value;
    _inferenceService.setBrightnessManual(_brightnessLevel);
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

  /// Hentikan sementara deteksi real-time (misal ketika membuka halaman hasil)
  void pauseDetection() {
    _detectTimer?.cancel();
    _detectTimer = null;
    print("Real-time detection paused.");
  }

  /// Lanjutkan kembali deteksi real-time
  void resumeDetection() {
    if (_detectTimer == null && _isModelReady && (_controller?.value.isInitialized ?? false)) {
      _detectTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        _runRealtimeDetection();
      });
      print("Real-time detection resumed.");
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
