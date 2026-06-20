import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/history_model.dart';
import '../services/inference_service.dart';

class HistoryController extends ChangeNotifier {
  final InferenceService _inferenceService = InferenceService();
  bool _isRetrying = false;

  // Getters
  bool get isRetrying => _isRetrying;

  /// Ambil user_id yang sedang login (null jika belum login)
  String? _currentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Ambil semua history dari Hive — difilter berdasarkan user aktif
  List<HistoryModel> getHistory() {
    try {
      final userId = _currentUserId();
      final box = Hive.box<HistoryModel>('historyBox');
      return box.values
          .where((item) => item.userId == userId)
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('Error fetch history: $e');
      return [];
    }
  }

  /// Ambil history dengan filter opsional: buah dan maturity (level)
  List<HistoryModel> getHistoryFiltered({String? fruit, String? maturity}) {
    final all = getHistory();
    return all.where((item) {
      if (fruit != null && _fruitFromLabel(item.label) != fruit.toLowerCase()) {
        return false;
      }
      if (maturity != null &&
          _maturityForItem(item) != _normalizeMaturity(maturity)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Helper: daftar buah unik yang ada di history (exclude unknown)
  List<String> getAvailableFruits() {
    final fruits = getHistory()
        .map((item) => _fruitFromLabel(item.label))
        .toSet()
        .where((f) => f != 'unknown')
        .toList();
    fruits.sort();
    return fruits;
  }

  /// Helper: daftar tingkat kematangan unik yang ada di history.
  List<String> getAvailableMaturities() {
    const order = ['unripe', 'ripe', 'overripe'];
    final maturities = getHistory()
        .map(_maturityForItem)
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();
    maturities.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return maturities;
  }

  /// Insights berdasarkan filter buah dan kematangan (exclude invalid categories)
  Map<String, dynamic> insightsForFilters({String? fruit, String? maturity}) {
    final items = getHistoryFiltered(fruit: fruit, maturity: maturity);
    final total = items.length;
    final Map<String, int> byFruit = {};
    final Map<String, int> byMaturity = {};

    for (final it in items) {
      final fruitKey = _fruitFromLabel(it.label);
      // Only include valid fruits
      if (fruitKey != 'unknown') {
        byFruit[fruitKey] = (byFruit[fruitKey] ?? 0) + 1;
      }

      // Only include valid maturity levels
      // Gunakan item.maturity jika ada, fallback ke parsing label
      final mat = _maturityForItem(it);
      if (mat.isNotEmpty) {
        byMaturity[mat] = (byMaturity[mat] ?? 0) + 1;
      }
    }

    return {'total': total, 'byFruit': byFruit, 'byMaturity': byMaturity};
  }

  /// Snapshot data untuk fitur "Snapshot Terkini"
  Map<String, dynamic> getSnapshotData() {
    final all = getHistory();
    final totalScan = all.length;

    int matang = 0;
    int mentah = 0;
    int busuk = 0;
    String latestFruit = '';
    String latestMaturity = '';

    // Per buah: {fruitName: {matang, mentah, busuk, total}}
    final Map<String, Map<String, int>> byFruitBreakdown = {};

    for (final item in all) {
      final fruit = _fruitFromLabel(item.label);
      if (fruit == 'unknown') continue;

      // Gunakan item.maturity jika ada, fallback ke parsing label
      final mat = _maturityForItem(item);

      if (latestMaturity.isEmpty && mat.isNotEmpty) {
        latestFruit = fruit;
        latestMaturity = mat;
      }

      byFruitBreakdown.putIfAbsent(
        fruit,
        () => {'matang': 0, 'mentah': 0, 'busuk': 0, 'total': 0},
      );
      byFruitBreakdown[fruit]!['total'] =
          (byFruitBreakdown[fruit]!['total'] ?? 0) + 1;

      if (mat == 'ripe') {
        matang++;
        byFruitBreakdown[fruit]!['matang'] =
            (byFruitBreakdown[fruit]!['matang'] ?? 0) + 1;
      } else if (mat == 'overripe') {
        busuk++;
        byFruitBreakdown[fruit]!['busuk'] =
            (byFruitBreakdown[fruit]!['busuk'] ?? 0) + 1;
      } else if (mat == 'unripe') {
        mentah++;
        byFruitBreakdown[fruit]!['mentah'] =
            (byFruitBreakdown[fruit]!['mentah'] ?? 0) + 1;
      }
    }

    // Buah dengan scan terbanyak
    String topFruit = '';
    int topCount = 0;
    byFruitBreakdown.forEach((fruit, data) {
      if ((data['total'] ?? 0) > topCount) {
        topCount = data['total'] ?? 0;
        topFruit = fruit;
      }
    });

    // Headline dinamis berdasarkan scan valid terbaru.
    String headline;
    if (totalScan == 0) {
      headline = 'Belum ada buah yang discan. Coba scan buah pertamamu!';
    } else if (latestMaturity.isEmpty) {
      headline = 'Scan terbaru belum memiliki tingkat kematangan yang jelas.';
    } else {
      final fruitName = latestFruit.isNotEmpty
          ? latestFruit[0].toUpperCase() + latestFruit.substring(1)
          : 'Buah';

      if (latestMaturity == 'overripe') {
        headline = 'Scan terbaru menunjukkan $fruitName busuk. Segera periksa buah tersebut.';
      } else if (latestMaturity == 'ripe') {
        headline = 'Scan terbaru menunjukkan $fruitName matang dan siap dikonsumsi.';
      } else {
        headline = 'Scan terbaru menunjukkan $fruitName masih mentah. Pantau beberapa hari lagi.';
      }
    }

    return {
      'totalScan': totalScan,
      'matang': matang,
      'mentah': mentah,
      'busuk': busuk,
      'byFruitBreakdown': byFruitBreakdown,
      'topFruit': topFruit,
      'latestFruit': latestFruit,
      'latestMaturity': latestMaturity,
      'headline': headline,
    };
  }

  String _fruitFromLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('apple')) return 'apple';
    if (normalized.contains('banana')) return 'banana';
    if (normalized.contains('mango')) return 'mango';
    if (normalized.contains('orange')) return 'orange';
    if (normalized.contains('papaya')) return 'papaya';
    if (normalized.contains('strawberry')) return 'strawberry';
    if (normalized.contains('dragon')) return 'dragon fruit';
    return 'unknown';
  }

  /// Parse maturity dari label (fallback jika field maturity kosong).
  /// Label contoh: "Apple_Ripe", "Banana Unripe", "Mango_Overripe"
  String _maturityFromLabel(String label) {
    final n = label.toLowerCase();
    if (n.contains('overripe') ||
        n.contains('over ripe') ||
        n.contains('busuk')) {
      return 'overripe';
    }
    if (n.contains('unripe') ||
        n.contains('un ripe') ||
        n.contains('mentah')) {
      return 'unripe';
    }
    if (n.contains('ripe') || n.contains('matang')) return 'ripe';
    return '';
  }

  String _maturityForItem(HistoryModel item) {
    final rawMat = (item.maturity ?? '').toLowerCase().trim();
    final fromField = rawMat.isNotEmpty && rawMat != 'unknown'
        ? _normalizeMaturity(rawMat)
        : '';
    return fromField.isNotEmpty ? fromField : _maturityFromLabel(item.label);
  }

  /// Normalisasi semua varian maturity ke bentuk canonical Inggris.
  /// Menggabungkan 'matang'/'ripe' → 'ripe', 'mentah'/'unripe' → 'unripe',
  /// 'busuk'/'overripe' → 'overripe'. Mencegah duplikat key di byMaturity.
  String _normalizeMaturity(String raw) {
    final n = raw.toLowerCase().trim();
    if (n == 'ripe' || n == 'matang') return 'ripe';
    if (n == 'unripe' || n == 'mentah') return 'unripe';
    if (n == 'overripe' || n == 'busuk') return 'overripe';
    return '';
  }

  /// Hitung item yang pending sync — hanya milik user aktif
  int getPendingCount() {
    final history = getHistory(); // sudah terfilter per userId
    return history.where((item) => !item.isSynced).length;
  }

  /// Retry sync semua pending items
  Future<void> retrySyncPending() async {
    _isRetrying = true;
    notifyListeners();

    try {
      final syncedCount = await _inferenceService.syncPendingResults();
      print('Retry sync: $syncedCount items synced');
    } catch (e) {
      print('Error retry sync: $e');
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }
}
