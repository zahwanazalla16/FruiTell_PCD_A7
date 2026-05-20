import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/history_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.onStartScan});

  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    final history = Hive.box<HistoryModel>(
      'historyBox',
    ).values.toList().reversed.toList();
    final totalDetections = history.length;
    final avgConfidence = history.isEmpty
        ? 0
        : ((history.map((e) => e.confidence).reduce((a, b) => a + b) /
                      history.length) *
                  100)
              .round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8D4E4),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cek Buahmu\nSekarang!',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pastikan kematangan & kesegaran buah favoritmu hanya dengan satu jepretan.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onStartScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE93E9D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text(
                    'Mulai Scan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.bolt,
                  title: 'Terdeteksi',
                  value: '$totalDetections Buah',
                  iconColor: const Color(0xFF7E7A2B),
                  bgColor: const Color(0xFFEFEAA6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.eco,
                  title: 'Kesegaran',
                  value: '$avgConfidence%',
                  iconColor: const Color(0xFF3D6769),
                  bgColor: const Color(0xFFCDE3E4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Riwayat Terakhir',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Belum ada riwayat scan.'),
            )
          else
            Row(
              children: history.take(2).map((item) {
                final label = item.label.split(' ');
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.image,
                          size: 38,
                          color: Color(0xFFE93E9D),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label.take(2).join(' '),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(item.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Color(0xFF8593AF)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFCDE3E4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.lightbulb_outline),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tips Hari Ini\nSimpan buah matang di kulkas untuk menjaga kesegaran lebih lama.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 20, color: Color(0xFF4A5A5A)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
