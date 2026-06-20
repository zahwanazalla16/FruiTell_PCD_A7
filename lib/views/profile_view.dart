import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/auth_service.dart';
import '../services/supabase_fruit_service.dart';
import '../models/history_model.dart';
import 'login_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final historyBox = Hive.box<HistoryModel>('historyBox');
    final totalScans = historyBox.length;
    final pendingSync = historyBox.values.where((item) => !item.isSynced).length;

    // Onboarding Palette
    const Color brandDark = Color(0xFF7D2F54); // Deep Berry
    const Color brandSub = Color(0xFF6A5A62); // Slate Mauve
    const Color peachBg = Color(0xFFFDEAE2); // Soft Peach
    const Color pastelPink = Color(0xFFFFD1E6); // Rose Pink
    const Color pastelCream = Color(0xFFFFF9E6); // Cream
    const Color pastelYellow = Color(0xFFFFF6B8); // Warm Yellow

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              pastelPink,
              pastelCream,
              pastelYellow,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── HEADER SECTION ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: brandDark, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Profil Pengguna',
                        style: TextStyle(
                          color: brandDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar and User info
                Column(
                  children: [
                    // Double ring Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: brandDark.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: peachBg,
                          child: const Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: brandDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User Email
                    Text(
                      user?.email ?? 'Pengguna Tamu',
                      style: const TextStyle(
                        color: brandDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Member Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: brandDark.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: brandDark.withOpacity(0.15), width: 1),
                      ),
                      child: const Text(
                        'FruityCheck Member',
                        style: TextStyle(
                          color: brandDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── BODY CARDS ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // CARD 1: ACCOUNT INFORMATION
                      _buildSectionCard(
                        title: 'Informasi Akun',
                        brandDark: brandDark,
                        brandSub: brandSub,
                        peachBg: peachBg,
                        items: [
                          _buildInfoTile(
                            icon: Icons.alternate_email_rounded,
                            title: 'Email Terdaftar',
                            subtitle: user?.email ?? '-',
                            brandDark: brandDark,
                            brandSub: brandSub,
                            peachBg: peachBg,
                          ),
                          _buildInfoTile(
                            icon: Icons.fingerprint_rounded,
                            title: 'ID Pengguna',
                            subtitle: user?.id ?? '-',
                            brandDark: brandDark,
                            brandSub: brandSub,
                            peachBg: peachBg,
                            trailing: IconButton(
                              icon: const Icon(Icons.copy_rounded, color: brandDark, size: 20),
                              onPressed: () {
                                final uid = user?.id;
                                if (uid != null) {
                                  Clipboard.setData(ClipboardData(text: uid));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ID Pengguna disalin ke papan klip'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // CARD 2: APP & STORAGE SETTINGS
                      _buildSectionCard(
                        title: 'Aplikasi & Penyimpanan',
                        brandDark: brandDark,
                        brandSub: brandSub,
                        peachBg: peachBg,
                        items: [
                          _buildInfoTile(
                            icon: Icons.analytics_outlined,
                            title: 'Total Deteksi Buah',
                            subtitle: '$totalScans kali pemindaian',
                            brandDark: brandDark,
                            brandSub: brandSub,
                            peachBg: peachBg,
                          ),
                          _buildInfoTile(
                            icon: pendingSync > 0 ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
                            title: 'Status Sinkronisasi',
                            subtitle: pendingSync > 0
                                ? '$pendingSync data menunggu sinkronisasi'
                                : 'Semua data telah dicadangkan ke awan',
                            brandDark: brandDark,
                            brandSub: brandSub,
                            peachBg: peachBg,
                            iconColor: pendingSync > 0 ? Colors.amber[800] : const Color(0xFF2E7D32),
                          ),
                          _buildInfoTile(
                            icon: Icons.delete_sweep_outlined,
                            title: 'Bersihkan Cache Buah',
                            subtitle: 'Hapus data offline yang tersimpan di cache',
                            brandDark: brandDark,
                            brandSub: brandSub,
                            peachBg: peachBg,
                            trailing: const Icon(Icons.chevron_right_rounded, color: brandSub),
                            onTap: () {
                              SupabaseFruitService.clearCache();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cache data buah berhasil dibersihkan!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // LOGOUT BUTTON (Styled like onboarding button)
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: brandDark.withOpacity(0.15), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: brandDark.withOpacity(0.06),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () => _showLogoutConfirmation(context, brandDark, brandSub),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: brandDark,
                                    size: 22,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Keluar dari Akun',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: brandDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build a glassmorphic styled card container
  Widget _buildSectionCard({
    required String title,
    required Color brandDark,
    required Color brandSub,
    required Color peachBg,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82), // Glassmorphism background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: brandDark.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              title,
              style: TextStyle(
                color: brandDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  // Helper widget to build individual list tiles
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color brandDark,
    required Color brandSub,
    required Color peachBg,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? brandDark).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? brandDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: brandDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: brandSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  // Dialog confirmation before logout
  void _showLogoutConfirmation(BuildContext context, Color brandDark, Color brandSub) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Text(
            'Konfirmasi Keluar',
            style: TextStyle(fontWeight: FontWeight.w800, color: brandDark),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari akun FruityCheck?',
            style: TextStyle(fontSize: 14, color: brandSub),
          ),
          actions: [
            TextButton(
              child: const Text('Batal', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: Text(
                'Keluar',
                style: TextStyle(color: brandDark, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                await AuthService().signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
