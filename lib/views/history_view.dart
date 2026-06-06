import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui';

import '../controllers/history_controller.dart';
import '../models/history_model.dart';
import '../models/detection_result.dart';
import '../services/dummy_content_service.dart';
import 'scan_result_view.dart';

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
    if (mounted) setState(() {});
  }

  Future<void> _retrySync() async {
    await _controller.retrySyncPending();
  }

  String _maturityLabel(String maturity) {
    switch (maturity) {
      case 'ripe':
        return 'Matang';
      case 'unripe':
        return 'Mentah';
      case 'overripe':
        return 'Busuk';
      default:
        return maturity;
    }
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
    final maturities = _controller.getAvailableMaturities();
    final displayed = history.isEmpty
        ? <HistoryModel>[]
        : _controller.getHistoryFiltered(
            fruit: _selectedFruit,
            maturity: _selectedMaturity,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      children: [
        // ── Page Header ──────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE93E9D), Color(0xFFB5006A)],
              ).createShader(bounds),
              child: const Text(
                'Scan History',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Text(
              'Riwayat deteksi buahmu',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9E7A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Snapshot Terkini (data global, tidak terfilter) ──────────
        if (history.isNotEmpty)
          _SnapshotCard(snapshotData: _controller.getSnapshotData()),
        if (history.isNotEmpty) const SizedBox(height: 20),

        // ── Filter row ───────────────────────────────────────────────
        if (history.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FruiTellDropdown(
                      label: 'Pilih Buah',
                      icon: Icons.local_grocery_store_rounded,
                      value: _selectedFruit,
                      items: [null, ...fruits],
                      itemLabel: (fruit) => fruit == null
                          ? 'Semua Buah'
                          : fruit[0].toUpperCase() + fruit.substring(1),
                      onChanged: (v) => setState(() => _selectedFruit = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FruiTellDropdown(
                      label: 'Kematangan',
                      icon: Icons.thermostat_rounded,
                      value: _selectedMaturity,
                      items: [null, ...maturities],
                      itemLabel: (m) =>
                          m == null ? 'Semua Level' : _maturityLabel(m),
                      onChanged: (v) => setState(() => _selectedMaturity = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),

        // ── Distribusi & Kematangan (mengikuti filter aktif) ─────────
        if (history.isNotEmpty) ...[
          _FilteredInsightPanel(
            insights: _controller.insightsForFilters(
              fruit: _selectedFruit,
              maturity: _selectedMaturity,
            ),
          ),
          const SizedBox(height: 18),
        ],

        // ── Sync status ──────────────────────────────────────────────
        if (pendingCount > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber[200] ?? Colors.amber,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.amber[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.amber[900],
                        ),
                      ),
                      Text(
                        '$pendingCount item menunggu sinkronisasi ke cloud',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
                _controller.isRetrying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber[700]!,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _retrySync,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green[200] ?? Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green[700], size: 20),
                const SizedBox(width: 12),
                Text(
                  'Semua data sudah sinkron ke cloud',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // ── History list ─────────────────────────────────────────────
        if (displayed.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada data scan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mulai scan di tab Scan untuk melihat history',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._buildHistoryItems(displayed),
      ],
    );
  }

  List<Widget> _buildHistoryItems(List<HistoryModel> history) {
    return history.map((item) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final enrichedResult = DummyContentService.enrich(item.label, item.confidence);
            final finalResult = DetectionResult(
              label: enrichedResult.label,
              confidence: enrichedResult.confidence,
              ripeness: item.maturity ?? enrichedResult.ripeness,
              freshness: item.condition ?? enrichedResult.freshness,
              bestBefore: enrichedResult.bestBefore,
              tips: enrichedResult.tips,
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScanResultView(
                  result: finalResult,
                  imageFile: File(item.imagePath ?? ''),
                  onSave: () async {},
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7E1EA),
              borderRadius: BorderRadius.circular(20),
            ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHistoryThumbnail(item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D1A2B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(item.date),
                        style: const TextStyle(
                          color: Color(0xFF876F7A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildConfidencePill(item.confidence),
                      _buildSyncPill(item.isSynced),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // Close Container
      ), // Close InkWell
      ); // Close Material
    }).toList();
  }

  Widget _buildHistoryThumbnail(HistoryModel item) {
    final imagePath = item.imagePath;
    final imageFile = imagePath != null && imagePath.isNotEmpty
        ? File(imagePath)
        : null;
    final hasImage = imageFile?.existsSync() ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        color: Colors.white,
        child: hasImage
            ? Image.file(
                imageFile!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildThumbnailFallback(),
              )
            : _buildThumbnailFallback(),
      ),
    );
  }

  Widget _buildThumbnailFallback() {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFFE93E9D),
        size: 26,
      ),
    );
  }

  Widget _buildConfidencePill(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5B7D4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(confidence * 100).toStringAsFixed(0)}% Confidence',
        style: const TextStyle(
          color: Color(0xFF7E3E5F),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSyncPill(bool isSynced) {
    final bgColor = isSynced
        ? const Color(0xFFC8E6C9)
        : const Color(0xFFFFF3C4);
    final fgColor = isSynced
        ? const Color(0xFF388E3C)
        : const Color(0xFFF57F17);
    final icon = isSynced ? Icons.cloud_done : Icons.cloud_off;
    final label = isSynced ? 'Synced' : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
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

// ═════════════════════════════════════════════════════════════════════════════
// SNAPSHOT CARD — Ringkasan global (tidak terfilter)
// ═════════════════════════════════════════════════════════════════════════════

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshotData});

  final Map<String, dynamic> snapshotData;

  static const _pink = Color(0xFFE93E9D);

  @override
  Widget build(BuildContext context) {
    final matang = snapshotData['matang'] as int? ?? 0;
    final mentah = snapshotData['mentah'] as int? ?? 0;
    final busuk = snapshotData['busuk'] as int? ?? 0;
    final headline = snapshotData['headline'] as String? ?? '';
    final latestMaturity = snapshotData['latestMaturity'] as String? ?? '';

    final headerColors = switch (latestMaturity) {
      'overripe' => [const Color(0xFFE53935), const Color(0xFFEF5350)],
      'unripe' => [const Color(0xFFF9A825), const Color(0xFFFFD54F)],
      'ripe' => [const Color(0xFF43A047), const Color(0xFF66BB6A)],
      _ => [const Color(0xFFE93E9D), const Color(0xFFFF6DBB)],
    };
    final headerIcon = switch (latestMaturity) {
      'overripe' => Icons.warning_amber_rounded,
      'unripe' => Icons.hourglass_top_rounded,
      'ripe' => Icons.check_circle_rounded,
      _ => Icons.auto_awesome_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: headerColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: headerColors.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Snapshot Terkini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Headline
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(headerIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stat chips
            Row(
              children: [
                _SnapshotChip(
                  label: 'Mentah',
                  count: mentah,
                  dotColor: const Color(0xFFFFD740),
                ),
                const SizedBox(width: 8),
                _SnapshotChip(
                  label: 'Matang',
                  count: matang,
                  dotColor: const Color(0xFF69F0AE),
                ),
                const SizedBox(width: 8),
                _SnapshotChip(
                  label: 'Busuk',
                  count: busuk,
                  dotColor: const Color(0xFFFF6E6E),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILTERED INSIGHT PANEL — Distribusi & Kematangan (mengikuti filter)
// ═════════════════════════════════════════════════════════════════════════════

class _FilteredInsightPanel extends StatelessWidget {
  const _FilteredInsightPanel({required this.insights});

  final Map<String, dynamic> insights;

  static const _pink = Color(0xFFE93E9D);

  static const _fruitMeta = {
    'apple': {'color': Color(0xFFE53935)},
    'banana': {'color': Color(0xFFFDD835)},
    'mango': {'color': Color(0xFFFB8C00)},
    'orange': {'color': Color(0xFFFF7043)},
    'papaya': {'color': Color(0xFF43A047)},
    'strawberry': {'color': Color(0xFFE91E63)},
    'dragon fruit': {'color': Color(0xFFAB47BC)},
  };

  static Color _maturityColor(String m) {
    switch (m.toLowerCase()) {
      case 'unripe':
        return const Color(0xFFFFD740);
      case 'ripe':
        return const Color(0xFF43A047);
      case 'overripe':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static String _maturityLabel(String m) {
    switch (m.toLowerCase()) {
      case 'unripe':
        return 'Mentah';
      case 'ripe':
        return 'Matang';
      case 'overripe':
        return 'Busuk';
      default:
        return m[0].toUpperCase() + m.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = insights['total'] as int? ?? 0;
    final byFruit = insights['byFruit'] as Map<String, int>? ?? {};
    final byMaturity = insights['byMaturity'] as Map<String, int>? ?? {};

    if (total == 0) return const SizedBox.shrink();

    final sortedFruits = byFruit.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const maturityOrder = ['unripe', 'ripe', 'overripe'];
    final sortedMaturities = byMaturity.entries.toList()
      ..sort(
        (a, b) => maturityOrder
            .indexOf(a.key)
            .compareTo(maturityOrder.indexOf(b.key)),
      );
    final maxFruit = sortedFruits.isEmpty ? 1 : sortedFruits.first.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _pink.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distribusi Buah
            _SectionTitle(
              icon: Icons.bar_chart_rounded,
              label: 'Distribusi Buah',
            ),
            const SizedBox(height: 12),
            ...sortedFruits.map((e) {
              final meta = _fruitMeta[e.key];
              final color = (meta?['color'] as Color?) ?? _pink;
              final pct = e.value / maxFruit;
              final name = e.key[0].toUpperCase() + e.key.substring(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3D1A2B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${e.value}x',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Divider
            if (sortedFruits.isNotEmpty && sortedMaturities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: _pink.withOpacity(0.1), thickness: 1),
              ),

            // Tingkat Kematangan
            if (sortedMaturities.isNotEmpty) ...[
              _SectionTitle(
                icon: Icons.thermostat_rounded,
                label: 'Tingkat Kematangan',
              ),
              const SizedBox(height: 12),
              Row(
                children: sortedMaturities.map((e) {
                  final color = _maturityColor(e.key);
                  final label = _maturityLabel(e.key);
                  final pctOfTotal = total > 0
                      ? (e.value / total * 100).round()
                      : 0;
                  final isLast = e.key == sortedMaturities.last.key;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$pctOfTotal%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            '${e.value} buah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: color.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Snapshot chip (di dalam header gradient)
// ─────────────────────────────────────────────────────────────────────────────

class _SnapshotChip extends StatelessWidget {
  const _SnapshotChip({
    required this.label,
    required this.count,
    required this.dotColor,
  });

  final String label;
  final int count;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title helper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFF7E1EA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFFE93E9D)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3D1A2B),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Custom FruiTell Dropdown (tidak berubah)
// ═════════════════════════════════════════════════════════════════════════════

class FruiTellDropdown extends StatefulWidget {
  const FruiTellDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String?> items;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onChanged;

  @override
  State<FruiTellDropdown> createState() => _FruiTellDropdownState();
}

class _FruiTellDropdownState extends State<FruiTellDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animController;
  late Animation<double> _arrowAnim;
  late Animation<double> _fadeAnim;

  static const _pink = Color(0xFFE93E9D);
  static const _pinkLight = Color(0xFFF7E1EA);
  static const _pinkMid = Color(0xFFF5B7D4);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _animController.reverse().then((_) => _removeOverlay());
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _DropdownPanel(
                    width: size.width,
                    items: widget.items,
                    selected: widget.value,
                    itemLabel: widget.itemLabel,
                    onSelect: (v) {
                      widget.onChanged(v);
                      _closeDropdown();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.value != null;
    final displayText = widget.itemLabel(widget.value);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFE93E9D), Color(0xFFFF6DBB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFF7E1EA), Color(0xFFFCF0F6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOpen
                  ? _pink
                  : isActive
                  ? _pink.withOpacity(0.6)
                  : _pinkMid,
              width: _isOpen ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(_isOpen ? 0.22 : 0.08),
                blurRadius: _isOpen ? 12 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: isActive ? Colors.white : _pink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white.withOpacity(0.8)
                            : const Color(0xFF876F7A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF3D1A2B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _arrowAnim,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: isActive ? Colors.white : _pink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown Panel (overlay) — tidak berubah
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownPanel extends StatelessWidget {
  const _DropdownPanel({
    required this.width,
    required this.items,
    required this.selected,
    required this.itemLabel,
    required this.onSelect,
  });

  final double width;
  final List<String?> items;
  final String? selected;
  final String Function(String?) itemLabel;
  final ValueChanged<String?> onSelect;

  static const _pink = Color(0xFFE93E9D);
  static const _pinkLight = Color(0xFFF7E1EA);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _pink.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: _pink.withOpacity(0.08),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, i) {
              final item = items[i];
              final isSelected = item == selected;
              final label = itemLabel(item);

              return InkWell(
                onTap: () => onSelect(item),
                borderRadius: BorderRadius.circular(12),
                splashColor: _pink.withOpacity(0.12),
                highlightColor: _pinkLight.withOpacity(0.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFE93E9D), Color(0xFFFF6DBB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : item == null
                              ? Colors.grey.shade300
                              : _pink.withOpacity(0.4),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF3D1A2B),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
