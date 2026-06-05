import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/history_model.dart';
import '../services/inference_service.dart';

class HistoryController extends ChangeNotifier {
  final InferenceService _inferenceService = InferenceService();
  bool _isRetrying = false;

  // Getters
  bool get isRetrying => _isRetrying;

  /// Ambil semua history dari Hive
  List<HistoryModel> getHistory() {
    try {
      final box = Hive.box<HistoryModel>('historyBox');
      return box.values.toList().reversed.toList();
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
          (item.maturity ?? '').toLowerCase() != maturity.toLowerCase())
        return false;
      return true;
    }).toList();
  }

  /// Helper: daftar buah unik yang ada di history (exclude unknown dan dragon fruit)
  List<String> getAvailableFruits() {
    final fruits = getHistory()
        .map((item) => _fruitFromLabel(item.label))
        .toSet()
        .where((f) => f != 'unknown' && f != 'dragon fruit')
        .toList();
    fruits.sort();
    return fruits;
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
      if (fruitKey != 'unknown' && fruitKey != 'dragon fruit') {
        byFruit[fruitKey] = (byFruit[fruitKey] ?? 0) + 1;
      }

      // Only include valid maturity levels
      final mat = (it.maturity ?? '').toLowerCase().trim();
      if (mat.isNotEmpty && mat != 'unknown') {
        byMaturity[mat] = (byMaturity[mat] ?? 0) + 1;
      }
    }

    return {'total': total, 'byFruit': byFruit, 'byMaturity': byMaturity};
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

  /// Hitung item yang pending sync
  int getPendingCount() {
    final history = getHistory();
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
