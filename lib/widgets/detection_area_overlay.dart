import 'package:flutter/material.dart';

/// Detection Area Overlay Widget
/// Menampilkan visual guide dengan corner brackets dan animated scanning line
/// User hanya bisa deteksi buah di area ini
class DetectionAreaOverlay extends StatefulWidget {
  final double widthPercent;
  final double heightPercent;
  final Color borderColor;
  final double borderWidth;
  final double cornerLineLength;

  const DetectionAreaOverlay({
    super.key,
    this.widthPercent = 0.75,
    this.heightPercent = 0.55,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.cornerLineLength = 30,
  });

  @override
  State<DetectionAreaOverlay> createState() => _DetectionAreaOverlayState();
}

class _DetectionAreaOverlayState extends State<DetectionAreaOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final overlayWidth = screenSize.width * widget.widthPercent;
    final overlayHeight = screenSize.height * widget.heightPercent;
    final overlayX = (screenSize.width - overlayWidth) / 2;
    final overlayY = (screenSize.height - overlayHeight) / 2;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dimming di luar area overlay (minimal)
        CustomPaint(
          painter: OverlayDimmingPainter(
            overlayRect: Rect.fromLTWH(overlayX, overlayY, overlayWidth, overlayHeight),
            dimmingAlpha: 0.15,
          ),
          size: Size.infinite,
        ),
        // Corner guides
        Positioned(
          left: overlayX,
          top: overlayY,
          width: overlayWidth,
          height: overlayHeight,
          child: CustomPaint(
            painter: CornerGuidePainter(
              borderColor: widget.borderColor,
              borderWidth: widget.borderWidth,
              cornerLineLength: widget.cornerLineLength,
            ),
            size: Size.infinite,
          ),
        ),
        // Animated scanning line
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              left: overlayX,
              top: overlayY + (overlayHeight * _animationController.value),
              width: overlayWidth,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0),
                      Colors.red,
                      Colors.red.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// CustomPainter untuk corner brackets
class CornerGuidePainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cornerLineLength;

  CornerGuidePainter({
    required this.borderColor,
    required this.borderWidth,
    required this.cornerLineLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset.zero,
      Offset(cornerLineLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(0, cornerLineLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLineLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLineLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLineLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLineLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLineLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLineLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerGuidePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.cornerLineLength != cornerLineLength;
  }
}

/// CustomPainter untuk dimming area di luar overlay
class OverlayDimmingPainter extends CustomPainter {
  final Rect overlayRect;
  final double dimmingAlpha;

  OverlayDimmingPainter({
    required this.overlayRect,
    required this.dimmingAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(dimmingAlpha)
      ..style = PaintingStyle.fill;

    // Draw dimmed areas
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, overlayRect.top),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, overlayRect.bottom, size.width,
          size.height - overlayRect.bottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, overlayRect.top, overlayRect.left, overlayRect.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(overlayRect.right, overlayRect.top,
          size.width - overlayRect.right, overlayRect.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(OverlayDimmingPainter oldDelegate) {
    return oldDelegate.overlayRect != overlayRect ||
        oldDelegate.dimmingAlpha != dimmingAlpha;
  }
}
