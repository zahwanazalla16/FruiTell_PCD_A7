import 'package:hive/hive.dart';

// File ini akan otomatis digenerate setelah kamu menjalankan command build_runner
part 'history_model.g.dart';

@HiveType(typeId: 0)
class HistoryModel extends HiveObject {
  @HiveField(0)
  final String label; // Contoh: "Mangga Matang"

  @HiveField(1)
  final double confidence; // Contoh: 0.95 (95%)

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String? imagePath; // Opsional: jika ingin simpan lokasi foto

  HistoryModel({
    required this.label,
    required this.confidence,
    required this.date,
    this.imagePath,
  });
}
