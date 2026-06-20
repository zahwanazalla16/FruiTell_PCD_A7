import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/history_model.dart';
import '../models/detection_result.dart';
import '../services/dummy_content_service.dart';
import 'scan_result_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.onStartScan, required this.onViewHistory});

  final VoidCallback onStartScan;
  final VoidCallback onViewHistory;

  // Daftar tips harian
  static const List<String> _tipsList = [
    'Simpan buah matang di kulkas untuk menjaga kesegaran lebih lama.',
    'Pisahkan pisang dari buah lain agar buah lain tidak cepat matang.',
    'Cuci buah sesaat sebelum dimakan, jangan disimpan dalam keadaan basah.',
    'Buah alpukat cepat matang bila disimpan dalam kantong kertas.',
    'Beri sirkulasi udara pada wadah penyimpanan buah.'
  ];

  @override
  Widget build(BuildContext context) {
    // Ambil tips berdasarkan hari ini
    final tipHariIni = _tipsList[DateTime.now().day % _tipsList.length];

    return ValueListenableBuilder<Box<HistoryModel>>(
      valueListenable: Hive.box<HistoryModel>('historyBox').listenable(),
      builder: (context, box, child) {
        // Filter hanya data milik user yang sedang login
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final history = box.values
            .where((item) => item.userId == currentUserId)
            .toList()
            .reversed
            .toList();
        final totalDetections = history.length;

        // Hitung kesegaran berdasarkan label hasil AI (Ripe/Unripe/Overripe)
        // atau fallback ke condition/maturity
        int segarCount = 0;
        int busukCount = 0;
        for (var item in history) {
          final label = item.label.toLowerCase();
          final kondisi = item.condition?.toLowerCase() ?? '';
          final kematangan = item.maturity?.toLowerCase() ?? '';

          bool isSegar = false;

          // Jika model AI menghasilkan label seperti "Apple Ripe"
          if (label.contains('ripe') && 
              !label.contains('overripe') && 
              !label.contains('unripe')) {
            isSegar = true;
          } 
          // Jika menggunakan input manual/lama
          else if (kondisi == 'segar' || kematangan == 'matang') {
            isSegar = true;
          }

          if (isSegar) {
            segarCount++;
          } else {
            busukCount++;
          }
        }
        final percentKesegaran = totalDetections == 0
            ? 0
            : ((segarCount / totalDetections) * 100).round();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Utama
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD1E6), Color(0xFFFFF9E6), Color(0xFFFFF6B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7D2F54).withValues(alpha: 0.12),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cek Buahmu Sekarang!',
                      style: TextStyle(
                        color: Color(0xFF7D2F54),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pastikan kematangan & kesegaran buah favoritmu hanya dengan satu jepretan.',
                      style: TextStyle(
                        color: Color(0xFF6A5A62),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: onStartScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7D2F54),
                        elevation: 4,
                        shadowColor: const Color(0xFF7D2F54).withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.center_focus_strong, size: 20),
                      label: const Text(
                        'Mulai Scan',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Insight Card (Donut Chart & Rincian)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD1E6), Color(0xFFFFF9E6), Color(0xFFFFF6B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7D2F54).withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Circular Progress
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator(
                              value: totalDetections == 0 ? 0 : percentKesegaran / 100,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFFF1F5F9),
                              color: const Color(0xFF10B981), // Emerald green
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$percentKesegaran%',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7D2F54),
                                ),
                              ),
                              const Text(
                                'Segar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6A5A62),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Rincian
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3D1A2B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LegendItem(
                            icon: Icons.inventory_2_rounded,
                            color: const Color(0xFF3B82F6),
                            label: 'Total Pindaian',
                            value: '$totalDetections',
                          ),
                          const SizedBox(height: 8),
                          _LegendItem(
                            icon: Icons.eco_rounded,
                            color: const Color(0xFF10B981),
                            label: 'Kondisi Segar',
                            value: '$segarCount',
                          ),
                          const SizedBox(height: 8),
                          _LegendItem(
                            icon: Icons.warning_rounded,
                            color: const Color(0xFFEF4444),
                            label: 'Butuh Perhatian',
                            value: '$busukCount',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Riwayat Terakhir Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Riwayat Terakhir',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3D1A2B),
                    ),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: onViewHistory,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: Color(0xFFE93E9D), 
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Daftar Riwayat
              if (history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD1E6), Color(0xFFFFF9E6), Color(0xFFFFF6B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7D2F54).withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat scan.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: history.take(2).map((item) {
                    final label = item.label.split(' ');
                    final scanTime = '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')} ${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}';
                    final isLast = item == history.take(2).last;

                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: isLast ? 0 : 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7E1EA), // Match history view item color!
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              // Gunakan DummyContentService.enrich untuk membuat detail sama persis
                              // dengan saat scan pertama kali.
                              final enrichedResult = DummyContentService.enrich(item.label, item.confidence);
                              
                              // Jika di history ada data maturity/condition manual, kita override sedikit
                              // agar sesuai (opsional, tapi disamakan dengan scan awal lebih baik)
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
                                    onSave: () async {
                                      // Kosong karena sudah tersimpan di riwayat.
                                      // Bisa menambahkan feedback UI.
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: (item.imagePath != null && File(item.imagePath!).existsSync())
                                        ? Image.file(
                                            File(item.imagePath!),
                                            height: 90,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 90,
                                            width: double.infinity,
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.image_rounded,
                                              size: 32,
                                              color: Color(0xFFE93E9D),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    label.take(2).join(' '),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF3D1A2B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF876F7A)),
                                      const SizedBox(width: 4),
                                      Text(
                                        scanTime,
                                        style: const TextStyle(
                                          color: Color(0xFF876F7A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
              const SizedBox(height: 28),
              
              // Tips Hari Ini
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD1E6), Color(0xFFFFF9E6), Color(0xFFFFF6B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7D2F54).withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF7D2F54), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tips Hari Ini',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7D2F54),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tipHariIni,
                            style: const TextStyle(
                              fontSize: 14, 
                              color: Color(0xFF6A5A62),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6A5A62)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3D1A2B),
          ),
        ),
      ],
    );
  }
}

