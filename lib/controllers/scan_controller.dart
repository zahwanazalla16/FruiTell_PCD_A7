import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/detection_result.dart';
import '../services/dummy_content_service.dart';
import '../services/inference_service.dart';
import '../services/isolate_inference_service.dart';

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
  double _brightnessLevel = 0.0;

  // ROI (Region of Interest) untuk deteksi buah hanya di area overlay
  static const double _overlayWidthPercent = 0.75;
  static const double _overlayHeightPercent = 0.40;
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
  double get brightnessLevel => _brightnessLevel;

  /// Initialize camera dan model (di Isolate untuk non-blocking)
  Future<void> initialize() async {
    try {
      print('[ScanController] Initializing...');
      // Inisialisasi inference di Isolate (non-blocking)
      print('[ScanController] Calling IsolateInferenceService.initModel()');
      await IsolateInferenceService.initModel();
      _isModelReady = true;
      print('[ScanController] Model initialized in Isolate');
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
      print('[ScanController] Camera initialized');
      notifyListeners();

      // Mulai deteksi real-time setiap 3 detik (diperlama dari 2s untuk hemat CPU)
      _detectTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _runRealtimeDetection();
      });
      print('[ScanController] Detection timer started');
    } catch (e) {
      _errorMessage = 'Error initialize: $e';
      print('[ScanController] Initialization error: $e');
      notifyListeners();
    }
  }

  /// Jalankan deteksi real-time setiap interval (hanya di area overlay/ROI, di Isolate)
  Future<void> _runRealtimeDetection() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isModelReady ||
        _isFrameBusy) {
      return;
    }

    _isFrameBusy = true;
    try {
      print('[ScanController] Taking picture...');
      final photo = await _controller!.takePicture();
      print('[ScanController] Picture taken: ${photo.path}');

      // Crop ke area overlay sebelum deteksi
      print('[ScanController] Cropping to ROI...');
      final croppedImage = await _cropImageToROI(File(photo.path));
      print('[ScanController] ROI crop complete: ${croppedImage.path}');

      // Jalankan deteksi di Isolate (non-blocking UI)
      print('[ScanController] Calling IsolateInferenceService.detectAsync()');
      final result = await IsolateInferenceService.detectAsync(
        croppedImage,
        fastMode: true,
      );
      print('[ScanController] Detection result from Isolate: $result');

      if (result != null) {
        print('[ScanController] Adding to recent detections');
        _recentDetections.add(result);
        if (_recentDetections.length > _stabilityWindow) {
          _recentDetections.removeAt(0);
        }
      } else {
        print('[ScanController] Result is null, clearing detections');
        _recentDetections.clear();
      }

      final stable = _getStableDetection();
      print('[ScanController] Stable detection: $stable');

      if (stable != null) {
        _latestDetection = DummyContentService.enrich(
          stable.label,
          stable.confidence,
        );
      } else if (result == null) {
        _latestDetection = null;
      }
      notifyListeners();
    } catch (e) {
      // Ignore frame-level errors untuk keep live detection loop running.
      print('[ScanController] Detection error: $e');
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
        _recentDetections.map((item) => item.confidence).reduce((a, b) => a + b) /
            _recentDetections.length;

    return DominantDetection(label: lastLabel, confidence: avgConfidence);
  }

  /// Confirm dan ambil foto final untuk result (hanya dari area overlay/ROI, di Isolate)
  Future<DominantDetection?> confirmAndCapture() async {
    if (_controller == null || _latestDetection == null) return null;

    try {
      print('[ScanController] Capturing final photo...');
      final photo = await _controller!.takePicture();

      // Crop ke area overlay sebelum deteksi
      print('[ScanController] Cropping to ROI for final capture...');
      final croppedImage = await _cropImageToROI(File(photo.path));
      _lastImagePath = croppedImage.path;

      // Jalankan deteksi di Isolate dengan full quality (fastMode=false untuk enhancement)
      print('[ScanController] Running final detection in Isolate...');
      final result = await IsolateInferenceService.detectAsync(
        croppedImage,
        overwriteOriginal: true,
        fastMode: false,
      );
      print('[ScanController] Final capture result: $result');
      return result;
    } catch (e) {
      _errorMessage = 'Error capture: $e';
      print('[ScanController] Capture error: $e');
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

  void setBrightnessLevel(double value) {
    if ((_brightnessLevel - value).abs() < 0.001) return;
    _brightnessLevel = value;
    _inferenceService.setBrightnessManual(_brightnessLevel);
    notifyListeners();
  }

  /// Crop gambar ke area overlay (ROI)
  /// Returns File dengan gambar yang sudah di-crop
  Future<File> _cropImageToROI(File imageFile) async {
    try {
      // Baca gambar original
      final imageData = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageData);

      if (originalImage == null) {
        return imageFile; // Fallback ke original jika decode gagal
      }

      final imgWidth = originalImage.width.toDouble();
      final imgHeight = originalImage.height.toDouble();

      // Hitung ROI berdasarkan overlay dimensions
      final roiWidth = imgWidth * _overlayWidthPercent;
      final roiHeight = imgHeight * _overlayHeightPercent;
      final roiX = (imgWidth - roiWidth) / 2;
      final roiY = (imgHeight - roiHeight) / 2;

      // Crop gambar ke ROI
      final croppedImage = img.copyCrop(
        originalImage,
        x: roiX.toInt(),
        y: roiY.toInt(),
        width: roiWidth.toInt(),
        height: roiHeight.toInt(),
      );

      // Simpan gambar yang sudah di-crop ke temp file
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final croppedFile = File('${tempDir.path}/fruitell_roi_$timestamp.jpg');
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

      return croppedFile;
    } catch (e) {
      print('[ScanController] Error cropping image: $e');
      return imageFile; // Fallback ke original jika error
    }
  }

  void toggleFlashlight() async {
    if (_controller == null) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error flashlight: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Terminate Isolate
    IsolateInferenceService.dispose();

    _detectTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
