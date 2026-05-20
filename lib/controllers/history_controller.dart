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
