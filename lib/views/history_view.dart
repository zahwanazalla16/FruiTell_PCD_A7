import 'package:flutter/material.dart';

import '../controllers/history_controller.dart';
import '../models/history_model.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final HistoryController _controller;
  String? _selectedFruit;
  String? _selectedMaturity;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _retrySync() async {
    await _controller.retrySyncPending();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = _controller.getHistory();
    final pendingCount = _controller.getPendingCount();

    final fruits = _controller.getAvailableFruits();
    final maturities = history
        .map((e) => (e.maturity ?? 'unknown'))
        .toSet()
        .toList();
    final displayed = history.isEmpty
        ? <HistoryModel>[]
        : _controller.getHistoryFiltered(
            fruit: _selectedFruit,
            maturity: _selectedMaturity,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      children: [
        const Text(
          'Scan History',
          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your fresh finds and nutritional insights.',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 18),
        // Filters row
        if (history.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Fruit
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFruit,
                      decoration: const InputDecoration(labelText: 'Buah'),
                      items: [null, ...fruits]
                          .map(
                            (fruit) => DropdownMenuItem(
                              value: fruit,
                              child: Text(
                                fruit == null
                                    ? 'Semua'
                                    : fruit[0].toUpperCase() +
                                          fruit.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedFruit = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Maturity
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMaturity,
                      decoration: const InputDecoration(
                        labelText: 'Kematangan',
                      ),
                      items: [null, ...maturities]
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m ?? 'Semua'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMaturity = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Insights panel for selected filters
              Builder(
                builder: (ctx) {
                  final insights = _controller.insightsForFilters(
                    fruit: _selectedFruit,
                    maturity: _selectedMaturity,
                  );
                  final total = insights['total'] as int? ?? 0;
                  final byFruit =
                      insights['byFruit'] as Map<String, int>? ?? {};
                  final byMaturity =
                      insights['byMaturity'] as Map<String, int>? ?? {};

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insights — Buah & Kematangan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Total: $total buah'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: byFruit.entries.map((e) {
                                  return Chip(
                                    label: Text('${e.key}: ${e.value}'),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: byMaturity.entries.map((e) {
                                  return Chip(
                                    label: Text('${e.key}: ${e.value}'),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // reset filters
                            setState(() {
                              _selectedFruit = null;
                              _selectedMaturity = null;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
            ],
          ),
        // Show sync status and retry button
        if (pendingCount > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Color(0xFFFF9800)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Offline Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$pendingCount item pending sync ke cloud',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _controller.isRetrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton.icon(
                        onPressed: _retrySync,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: const Color(0xFFFF9800),
                        ),
                      ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done, color: Color(0xFF4CAF50)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Semua data sudah sinkron ke cloud',
                    style: TextStyle(color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        if (displayed.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Belum ada data. Mulai scan di tab Scan.'),
          )
        else
          ..._buildHistoryItems(displayed),
      ],
    );
  }

  List<Widget> _buildHistoryItems(List<HistoryModel> history) {
    return history.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7E1EA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_grocery_store,
                color: Color(0xFFE93E9D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.isSynced)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEB3B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 12,
                                color: Color(0xFFF57F17),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF57F17),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8E6C9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 12,
                                color: Color(0xFF388E3C),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5B7D4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${(item.confidence * 100).toStringAsFixed(0)}% Confidence',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(item.date),
              style: const TextStyle(
                color: Color(0xFF876F7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Kemarin';
    return '${date.day}/${date.month}/${date.year}';
  }
}
