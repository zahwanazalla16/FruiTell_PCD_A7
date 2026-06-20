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

  @HiveField(4)
  bool isSynced; // Track apakah sudah sinkron ke Supabase (backward compat)

  @HiveField(5)
  String? remoteId; // id di cloud (Supabase)

  @HiveField(6)
  String? maturity; // contoh: "Matang", "Setengah", "Mentah"

  @HiveField(7)
  String? condition; // contoh: "matang" / "busuk" / "segar"

  @HiveField(8)
  DateTime? localUpdatedAt; // terakhir diupdate lokal

  @HiveField(9)
  DateTime? syncedAt; // terakhir sinkron ke cloud

  @HiveField(10)
  final String id; // lokal unique id

  @HiveField(11)
  String? userId; // Supabase user id pemilik data ini

  HistoryModel({
    required this.label,
    required this.confidence,
    required this.date,
    this.imagePath,
    this.isSynced = false,
    this.remoteId,
    this.maturity,
    this.condition,
    DateTime? localUpdatedAt,
    this.syncedAt,
    String? id,
    this.userId,
  }) : localUpdatedAt = localUpdatedAt ?? DateTime.now(),
       id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
