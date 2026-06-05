import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:hive/hive.dart';
import '../models/history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show compute;

class DominantDetection {
  DominantDetection({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class InferenceService {
  Interpreter? _interpreter;

  List<String> _labels = [];

  static const double _lowLightLumaThreshold = 95.0;
  bool _contrastEnhancementEnabled = true;
  double _contrastBoost = 1.0;
  double _brightnessManual = 0.0;

  void setContrastEnhancementEnabled(bool enabled) {
    _contrastEnhancementEnabled = enabled;
  }

  void setContrastBoost(double value) {
    _contrastBoost = value.clamp(0.5, 2.0);
  }

  void setBrightnessManual(double value) {
    _brightnessManual = value.clamp(-50.0, 50.0);
  }

  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/Fruitell_int8.tflite',
      );
      print(" Berhasil memuat model AI");

      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      print("Struktur Input Model: $inputShape");
      print("Struktur Output Model: $outputShape");
      print("Tipe Input Model: ${_interpreter!.getInputTensor(0).type}");
      print("Tipe Output Model: ${_interpreter!.getOutputTensor(0).type}");

      try {
        final labelsData = await rootBundle.loadString(
          'assets/models/labels.txt',
        );
        _labels = labelsData
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        print('Loaded ${_labels.length} labels from assets/models/labels.txt');
      } catch (e) {
        print('Failed to load labels.txt: $e');
      }
    } catch (e) {
      print(" Gagal memuat model: $e");
    }
  }

  Future<DominantDetection?> detectDominantFromFile(
    File imageFile, {
    bool overwriteOriginal = false,
  }) async {
    if (_interpreter == null) return null;

    try {
      final imageData = await imageFile.readAsBytes();

      // Mengalihkan operasi decoding gambar, resizing, peningkatan kontras/kecerahan (PCD),
      // penyimpanan file, dan konversi tensor ke thread latar belakang (Isolate)
      final input = await compute(
        _preprocessImageJob,
        _PreprocessParams(
          imageBytes: imageData,
          overwriteOriginal: overwriteOriginal,
          imagePath: imageFile.path,
          contrastEnhancementEnabled: _contrastEnhancementEnabled,
          contrastBoost: _contrastBoost,
          brightnessManual: _brightnessManual,
          lowLightLumaThreshold: _lowLightLumaThreshold,
        ),
      );

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputSize = outputShape.fold<int>(1, (acc, dim) => acc * dim);
      final output = List.filled(outputSize, 0.0).reshape(outputShape);

      _interpreter!.run(input, output);

      final detection = _extractDominantDetection(
        output: output,
        outputShape: outputShape,
      );

      return detection;
    } catch (e) {
      print("Error saat memproses gambar atau menjalankan model: $e");
      return null;
    }
  }

  DominantDetection? _extractDominantDetection({
    required dynamic output,
    required List<int> outputShape,
  }) {
    const double minConfidence = 0.50;
    const double minGap = 0.0;
    final numClasses = _labels.length;

    if (outputShape.length != 3 || outputShape[0] != 1) {
      print('Inference: unexpected output shape: $outputShape');
      return null;
    }

    final dim1 = outputShape[1];
    final dim2 = outputShape[2];

    // Model baru memiliki 13 channel (4 box + 9 class)
    // Sedangkan labels.txt kita punya 19 baris.
    // Kita paksa menggunakan struktur model [1, 13, 8400]
    final actualChannels = dim1;
    final candidateCount = dim2;

    double bestScore = 0.0;
    int bestClassIdx = -1;

    for (var i = 0; i < candidateCount; i++) {
      // Channel 0-3 adalah bounding box, channel 4-12 adalah score kelas (total 9 kelas)
      for (var c = 0; c < (actualChannels - 4); c++) {
        final score = (output[0][c + 4][i] as num).toDouble();

        if (score > bestScore) {
          bestScore = score;
          bestClassIdx = c;
        }
      }
    }

    if (bestClassIdx < 0) {
      print('Inference: no class detected');
      return null;
    }

    if (bestScore < minConfidence) {
      print(
        'Inference: bestScore $bestScore below minConfidence $minConfidence',
      );
      return null;
    }

    final detectedLabel = bestClassIdx < _labels.length
        ? _labels[bestClassIdx]
        : 'Unknown Class ($bestClassIdx)';

    print(
      'Inference: selected $detectedLabel (@${(bestScore * 100).toStringAsFixed(1)}%)',
    );

    return DominantDetection(label: detectedLabel, confidence: bestScore);
  }

  Future<void> saveResult({
    required String label,
    required double confidence,
    String? imagePath,
    bool syncCloud = false,
  }) async {
    final item = await _saveToHive(label, confidence, imagePath: imagePath);

    if (syncCloud && item != null) {
      // Jalankan sinkronisasi awan di background agar User tidak perlu menunggu (langsung).
      _syncToSupabaseItem(item).catchError((e) {
        print("Background sync failed: $e");
      });
    }
  }

  Future<HistoryModel?> _saveToHive(
    String label,
    double confidence, {
    String? imagePath,
  }) async {
    try {
      var box = Hive.box<HistoryModel>('historyBox');
      final newHistory = HistoryModel(
        label: label,
        confidence: confidence,
        date: DateTime.now(),
        imagePath: imagePath,
        isSynced: false, // Mark sebagai pending sync
      );
      await box.add(newHistory);
      print(" Data tersimpan di Hive (pending sync ke Supabase)");
      return newHistory;
    } catch (e) {
      print(" Gagal simpan ke Hive: $e");
      return null;
    }
  }

  Future<void> _syncToSupabaseItem(HistoryModel item) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        print(" User belum login, data Cloud tidak disinkron.");
        return;
      }

      await Supabase.instance.client.from('fruit_history').insert({
        'label': item.label,
        'confidence': item.confidence,
        'user_id': user.id,
        'created_at': item.date.toIso8601String(),
      });

      // Mark item as synced
      item.isSynced = true;
      await item.save();
      print(" Data berhasil sinkron ke Supabase!");
    } catch (e) {
      print(" Gagal sinkron ke Cloud (Mungkin Offline/RLS Policy): $e");
    }
  }

  // Retry sync untuk semua item yang pending
  Future<int> syncPendingResults() async {
    try {
      var box = Hive.box<HistoryModel>('historyBox');
      final pendingItems = box.values.where((item) => !item.isSynced).toList();
      int syncedCount = 0;

      for (final item in pendingItems) {
        await _syncToSupabaseItem(item);
        syncedCount++;
      }

      print(
        ' Sinkron selesai: $syncedCount item dari ${pendingItems.length} pending items',
      );
      return syncedCount;
    } catch (e) {
      print(" Error saat retry sync: $e");
      return 0;
    }
  }

  void close() {
    _interpreter?.close();
  }
}

// Parametrik preprocess di Isolate
class _PreprocessParams {
  final List<int> imageBytes;
  final bool overwriteOriginal;
  final String? imagePath;
  final bool contrastEnhancementEnabled;
  final double contrastBoost;
  final double brightnessManual;
  final double lowLightLumaThreshold;

  _PreprocessParams({
    required this.imageBytes,
    required this.overwriteOriginal,
    this.imagePath,
    required this.contrastEnhancementEnabled,
    required this.contrastBoost,
    required this.brightnessManual,
    required this.lowLightLumaThreshold,
  });
}

// Top-level function untuk compute (dijalankan di background Isolate)
Future<List<List<List<List<double>>>>> _preprocessImageJob(_PreprocessParams params) async {
  final originalImage = img.decodeImage(Uint8List.fromList(params.imageBytes));
  if (originalImage == null) {
    throw Exception("Gagal decode gambar");
  }

  img.Image processedImage;
  if (!params.overwriteOriginal) {
    processedImage = _resizeAndPadStatic(originalImage, 640);
    processedImage = _enhanceForLowLightStatic(processedImage, params);
  } else {
    // Untuk foto final, tetap proses yang agak besar
    processedImage = _resizeAndPadStatic(originalImage, 1024);
    processedImage = _enhanceForLowLightStatic(processedImage, params);

    // Simpan hasil PCD kembali ke file di background thread (aman dari hambatan I/O)
    if (params.imagePath != null) {
      final bytes = img.encodeJpg(processedImage, quality: 85);
      final file = File(params.imagePath!);
      await file.writeAsBytes(bytes);
    }

    // Resize lagi ke 640 untuk input model AI
    processedImage = _resizeAndPadStatic(processedImage, 640);
  }

  return _imageToTensorStatic(processedImage);
}

img.Image _resizeAndPadStatic(img.Image image, int targetSize) {
  final scale = math.min(targetSize / image.width, targetSize / image.height);
  final resizedWidth = (image.width * scale).round();
  final resizedHeight = (image.height * scale).round();

  final resized = img.copyResize(
    image,
    width: resizedWidth,
    height: resizedHeight,
    interpolation: img.Interpolation.linear,
  );

  final canvas = img.Image(width: targetSize, height: targetSize);
  img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
  final dx = (targetSize - resizedWidth) ~/ 2;
  final dy = (targetSize - resizedHeight) ~/ 2;
  img.compositeImage(canvas, resized, dstX: dx, dstY: dy);
  return canvas;
}

img.Image _enhanceForLowLightStatic(img.Image source, _PreprocessParams params) {
  final avgLuma = _computeAverageLumaStatic(source);

  // Kurangi sensor noise terlebih dahulu
  img.Image processed = img.gaussianBlur(source, radius: 1);

  if (!params.contrastEnhancementEnabled) {
    return processed;
  }

  if (avgLuma < params.lowLightLumaThreshold) {
    processed = _equalizeLuminanceStatic(processed);
    processed = _applyBrightnessContrastStatic(
      processed,
      brightnessOffset: (18 + params.brightnessManual).round(),
      contrastFactor: 1.12 * params.contrastBoost,
    );
    print(
      'Preprocess Isolate: low-light mode enabled (avgLuma=${avgLuma.toStringAsFixed(1)})',
    );
  } else {
    processed = _applyBrightnessContrastStatic(
      processed,
      brightnessOffset: (4 + params.brightnessManual).round(),
      contrastFactor: 1.04 * params.contrastBoost,
    );
  }

  return processed;
}

double _computeAverageLumaStatic(img.Image image) {
  var total = 0.0;
  final pixelCount = image.width * image.height;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      total += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
    }
  }

  return pixelCount == 0 ? 0.0 : total / pixelCount;
}

img.Image _applyBrightnessContrastStatic(
  img.Image image, {
  required int brightnessOffset,
  required double contrastFactor,
}) {
  final out = img.Image.from(image);

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);

      int remap(int value) {
        final contrasted = ((value - 128) * contrastFactor + 128).round();
        final withOffset = contrasted + brightnessOffset;
        if (withOffset < 0) return 0;
        if (withOffset > 255) return 255;
        return withOffset;
      }

      out.setPixelRgba(
        x,
        y,
        remap(p.r.toInt()),
        remap(p.g.toInt()),
        remap(p.b.toInt()),
        p.a.toInt(),
      );
    }
  }

  return out;
}

img.Image _equalizeLuminanceStatic(img.Image image) {
  final out = img.Image.from(image);
  final histogram = List<int>.filled(256, 0);

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);
      final yLuma = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
      histogram[yLuma]++;
    }
  }

  final cdf = List<int>.filled(256, 0);
  cdf[0] = histogram[0];
  for (int i = 1; i < 256; i++) {
    cdf[i] = cdf[i - 1] + histogram[i];
  }

  final total = out.width * out.height;
  final cdfMin = cdf.firstWhere((v) => v > 0, orElse: () => 0);
  if (total <= cdfMin) {
    return out;
  }

  final lut = List<int>.filled(256, 0);
  for (int i = 0; i < 256; i++) {
    lut[i] = (((cdf[i] - cdfMin) / (total - cdfMin)) * 255)
        .round()
        .toInt()
        .clamp(0, 255)
        .toInt();
  }

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);
      final oldY = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
      final newY = lut[oldY];
      final scale = oldY <= 0 ? 1.0 : newY / oldY;

      int remap(int channel) {
        final scaled = (channel * scale).round();
        final blended = ((scaled * 0.7) + (channel * 0.3)).round();
        if (blended < 0) return 0;
        if (blended > 255) return 255;
        return blended;
      }

      out.setPixelRgba(
        x,
        y,
        remap(p.r.toInt()),
        remap(p.g.toInt()),
        remap(p.b.toInt()),
        p.a.toInt(),
      );
    }
  }

  return out;
}

List<List<List<List<double>>>> _imageToTensorStatic(img.Image image) {
  final inputSize = image.width;
  var input = List.generate(
    1,
    (_) => List.generate(
      inputSize,
      (_) => List.generate(inputSize, (_) => List<double>.filled(3, 0.0)),
    ),
  );

  for (int y = 0; y < inputSize; y++) {
    for (int x = 0; x < inputSize; x++) {
      final pixel = image.getPixel(x, y);
      input[0][y][x][0] = pixel.r / 255.0;
      input[0][y][x][1] = pixel.g / 255.0;
      input[0][y][x][2] = pixel.b / 255.0;
    }
  }
  return input;
}
