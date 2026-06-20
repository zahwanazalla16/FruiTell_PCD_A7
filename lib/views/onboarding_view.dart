import 'package:flutter/material.dart';
import 'login_view.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFFFD1E6), // Stronger Rose Pink
              Color(0xFFFFF9E6), // Cream Middle
              Color(0xFFFFF6B8), // Stronger Warm Yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top spacing
                const SizedBox(height: 20),

                // Fruit Overlapping Cards (Pineapple & Apple)
                Center(
                  child: SizedBox(
                    height: 240,
                    width: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: const [
                        // Card 1: Pineapple (Behind, rotated left)
                        FruitCard(
                          imageUrl: 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&q=80&w=400',
                          size: 135,
                          angle: -0.15,
                          offset: Offset(-25, -15),
                          fallbackEmoji: '🍍',
                        ),
                        // Card 2: Apple (Front, rotated right)
                        FruitCard(
                          imageUrl: 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&q=80&w=400',
                          size: 140,
                          angle: 0.12,
                          offset: Offset(25, 20),
                          borderWidth: 4.5,
                          fallbackEmoji: '🍎',
                        ),
                      ],
                    ),
                  ),
                ),

                // Brand Logo & Title
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Custom Fruit Silhouette Icon
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF7D2F54),
                              width: 3.5,
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: -8,
                                right: -4,
                                child: Transform.rotate(
                                  angle: 0.5,
                                  child: const Icon(
                                    Icons.eco,
                                    size: 14,
                                    color: Color(0xFF7D2F54),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'FruiTell',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7D2F54),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Temukan jalan tersegar menuju dirimu yang lebih sehat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6A5A62),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // Status Indicator
                Column(
                  children: [
                    const Text(
                      'MENGANALISIS KESEGARAN...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7D2F54),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 260,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D2F54),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                // Get Started Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7D2F54).withOpacity(0.08),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginView(),
                            ),
                          );
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.rocket_launch,
                                color: Color(0xFF7D2F54),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Mulai Sekarang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7D2F54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Copyright footer
                const Text(
                  '© 2024 FruiTell. Semua hak dilindungi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FruitCard extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double angle;
  final Offset offset;
  final double borderWidth;
  final String fallbackEmoji;

  const FruitCard({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.angle,
    required this.offset,
    this.borderWidth = 0.0,
    required this.fallbackEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFDEAE2), // Soft peach background
            borderRadius: BorderRadius.circular(28),
            border: borderWidth > 0
                ? Border.all(color: Colors.white, width: borderWidth)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28 - borderWidth),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: const Color(0xFFE93E9D),
                      strokeWidth: 2.5,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    fallbackEmoji,
                    style: TextStyle(fontSize: size * 0.45),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
