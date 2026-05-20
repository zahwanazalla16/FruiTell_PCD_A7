import 'dart:io';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:hive/hive.dart';
import '../models/history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class DominantDetection {
  DominantDetection({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class InferenceService {
  Interpreter? _interpreter;

  List<String> _labels = [];

  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/fruitell_model_v2.tflite',
      );
      print(" Berhasil memuat model AI");

      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      print("Struktur Input Model: $inputShape");
      print("Struktur Output Model: $outputShape");

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

  List<List<List<List<double>>>> _preProcessPCD(img.Image image) {
    const inputSize = 640;
    final scale = math.min(inputSize / image.width, inputSize / image.height);
    final resizedWidth = (image.width * scale).round();
    final resizedHeight = (image.height * scale).round();

    final resized = img.copyResize(
      image,
      width: resizedWidth,
      height: resizedHeight,
    );

    final canvas = img.Image(width: inputSize, height: inputSize);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    final dx = (inputSize - resizedWidth) ~/ 2;
    final dy = (inputSize - resizedHeight) ~/ 2;
    img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List<double>.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = canvas.getPixel(x, y);

        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    return input;
  }

  Future<DominantDetection?> detectDominantFromFile(File imageFile) async {
    if (_interpreter == null) return null;

    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return null;

    var input = _preProcessPCD(originalImage);

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputSize = outputShape.fold<int>(1, (acc, dim) => acc * dim);
    final output = List.filled(outputSize, 0.0).reshape(outputShape);

    _interpreter!.run(input, output);

    final detection = _extractDominantDetection(
      output: output,
      outputShape: outputShape,
    );

    return detection;
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
    final expectedChannels = 4 + numClasses;

    bool channelFirst;
    int candidateCount;

    if (dim1 == expectedChannels) {
      channelFirst = true;
      candidateCount = dim2;
    } else if (dim2 == expectedChannels) {
      channelFirst = false;
      candidateCount = dim1;
    } else {
      print(
        'Inference: output channels (${outputShape[1]},${outputShape[2]}) do not match expected $expectedChannels',
      );
      return null;
    }

    double bestScore = 0.0;
    double secondBestScore = 0.0;
    int bestClassIdx = -1;

    for (var i = 0; i < candidateCount; i++) {
      for (var c = 0; c < numClasses; c++) {
        final raw = channelFirst ? output[0][c + 4][i] : output[0][i][c + 4];
        final score = (raw as num).toDouble();

        if (score > bestScore) {
          secondBestScore = bestScore;
          bestScore = score;
          bestClassIdx = c;
        } else if (score > secondBestScore) {
          secondBestScore = score;
        }
      }
    }

    final scoreGap = bestScore - secondBestScore;
    print(
      'Inference: bestScore=$bestScore secondBest=$secondBestScore gap=$scoreGap bestClassIdx=$bestClassIdx',
    );

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

    if (scoreGap < minGap && minGap > 0) {
      print('Inference: ambiguous results, gap $scoreGap < minGap $minGap');
      return null;
    }

    print(
      'Inference: selected ${_labels[bestClassIdx]} (@${(bestScore * 100).toStringAsFixed(1)}%)',
    );
    return DominantDetection(
      label: _labels[bestClassIdx],
      confidence: bestScore,
    );
  }

  Future<void> saveResult({
    required String label,
    required double confidence,
    String? imagePath,
    bool syncCloud = false,
  }) async {
    final item = await _saveToHive(label, confidence, imagePath: imagePath);
    if (syncCloud && item != null) {
      await _syncToSupabaseItem(item);
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
