import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:hive/hive.dart';
import '../models/history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InferenceService {
  Interpreter? _interpreter;

  // 1. Memuat Model AI
  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/fruitell_model_v2.tflite',
      );
      print(" Berhasil memuat model AI");

      var inputShape = _interpreter!.getInputTensor(0).shape;
      print("Struktur Input Model: $inputShape");
    } catch (e) {
      print(" Gagal memuat model: $e");
    }
  }

  // 2. Pre-processing PCD (Penting untuk Nilai Tugas Akhir)
  List<List<List<List<double>>>> _preProcessPCD(img.Image image) {
    // Resize ke 640x640 sesuai spek YOLOv8
    img.Image resized = img.copyResize(image, width: 640, height: 640);

    // Normalisasi & Konversi ke format [1, 640, 640, 3]
    var input = List.generate(
      1,
      (_) => List.generate(
        640,
        (_) => List.generate(640, (_) => List<double>.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = resized.getPixel(x, y);

        // YOLOv8 menggunakan urutan RGB (Red-Green-Blue)
        input[0][y][x][0] = pixel.r / 255.0; // Normalisasi 0.0 - 1.0
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    return input;
  }

  // 3. Menjalankan Deteksi & Post-processing
  Future<void> runInference(File imageFile) async {
    if (_interpreter == null) return;

    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return;

    var input = _preProcessPCD(originalImage);

    // --- FIX URUTAN LABEL SESUAI ROBOFLOW ---
    final List<String> labels = [
      "Apple Overripe",
      "Apple Ripe",
      "Apple Unripe",
      "Banana Overripe",
      "Banana Ripe",
      "Banana Unripe",
      "Dragon Fruit Ripe",
      "Dragon Fruit Unripe",
      "Mango Overripe",
      "Mango Ripe",
      "Mango Unripe",
      "Orange Overripe",
      "Orange Ripe",
      "Orange Unripe",
      "Papaya Overripe",
      "Papaya Ripe",
      "Papaya Unripe",
      "Strawberry Ripe",
      "Strawberry Unripe",
    ];

    int numClasses = labels.length; // Total 9 kelas
    int outputWidth = 4 + numClasses; // 13 kolom (4 koordinat + 9 kelas)

    // Siapkan wadah output [1, 13, 8400]
    var output = List.filled(
      1 * outputWidth * 8400,
      0.0,
    ).reshape([1, outputWidth, 8400]);

    // Jalankan Proses Deteksi
    _interpreter!.run(input, output);

    double bestScore = 0.0;
    int bestClassIdx = -1;

    // Cari skor tertinggi dari 8400 kemungkinan posisi
    for (var i = 0; i < 8400; i++) {
      for (var c = 0; c < numClasses; c++) {
        // Skor kelas dimulai setelah index ke-4 (0,1,2,3 adalah x,y,w,h)
        double score = output[0][c + 4][i];
        if (score > bestScore) {
          bestScore = score;
          bestClassIdx = c;
        }
      }
    }

    // Hanya tampilkan hasil jika keyakinan di atas 50%
    if (bestScore > 0.5) {
      String resultLabel = labels[bestClassIdx];
      print(
        " HASIL DETEKSI: $resultLabel (${(bestScore * 100).toStringAsFixed(2)}%)",
      );

      // Simpan hasil ke memori lokal
      await _saveToHive(resultLabel, bestScore);

      // Sinkronisasi ke Cloud (Supabase)
      await _syncToSupabase(resultLabel, bestScore);
    } else {
      print(" Tidak ada buah yang terdeteksi dengan jelas.");
    }
  }

  // Fungsi Simpan Lokal (Hive)
  Future<void> _saveToHive(String label, double confidence) async {
    try {
      var box = Hive.box<HistoryModel>('historyBox');
      final newHistory = HistoryModel(
        label: label,
        confidence: confidence,
        date: DateTime.now(),
      );
      await box.add(newHistory);
      print(" Data tersimpan di Hive!");
    } catch (e) {
      print(" Gagal simpan ke Hive: $e");
    }
  }

  // Fungsi Sinkronisasi Cloud (Supabase)
  Future<void> _syncToSupabase(String label, double confidence) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        print(" User belum login, data Cloud tidak disinkron.");
        return;
      }

      await Supabase.instance.client.from('fruit_history').insert({
        'label': label,
        'confidence': confidence,
        'user_id': user.id,
      });
      print(" Data berhasil sinkron ke Supabase!");
    } catch (e) {
      print(" Gagal sinkron ke Cloud (Mungkin Offline/RLS Policy): $e");
    }
  }

  void close() {
    _interpreter?.close();
  }
}
