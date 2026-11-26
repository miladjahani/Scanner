import 'dart:math' as math;

import 'package:flutter/material.dart';

/// miliscanner mark: the neon "M" orb from the brand image, inspected by a
/// magnifying glass — the scanner metaphor built directly into the logo.
class MiliLogo extends StatelessWidget {
  final double size;
  final bool showBackplate;

  const MiliLogo({super.key, this.size = 56, this.showBackplate = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiliLogoPainter(showBackplate: showBackplate),
      ),
    );
  }
}

class _MiliLogoPainter extends CustomPainter {
  final bool showBackplate;

  _MiliLogoPainter({required this.showBackplate});

  static const Color _neon = Color(0xFF00E676);
  static const Color _neonSoft = Color(0xFF6BFFB0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (showBackplate) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFF05070A),
      );
    }

    // Outer glow ring
    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06
        ..color = _neon.withValues(alpha: 0.18),
    );

    // Orbital ellipse, echoing the rings in the brand artwork.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.42);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 1.72,
        height: radius * 0.82,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.055
        ..color = _neon.withValues(alpha: 0.75),
    );
    canvas.restore();

    // Angular "M" built from thick neon strokes.
    final mPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.2
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_neonSoft, _neon],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final m = Path()
      ..moveTo(center.dx - radius * 0.42, center.dy + radius * 0.34)
      ..lineTo(center.dx - radius * 0.34, center.dy - radius * 0.34)
      ..lineTo(center.dx, center.dy + radius * 0.16)
      ..lineTo(center.dx + radius * 0.34, center.dy - radius * 0.34)
      ..lineTo(center.dx + radius * 0.42, center.dy + radius * 0.34);
    canvas.drawPath(m, mPaint);

    // Magnifier: lens ring roughly over the M's right shoulder.
    final lensCenter = Offset(
      center.dx + radius * 0.44,
      center.dy + radius * 0.46,
    );
    final lensRadius = radius * 0.34;
    canvas.drawCircle(
      lensCenter,
      lensRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.11
        ..color = _neonSoft,
    );
    canvas.drawCircle(
      lensCenter,
      lensRadius,
      Paint()..color = _neon.withValues(alpha: 0.16),
    );

    // Handle of the magnifier.
    final handleStart = Offset(
      lensCenter.dx + lensRadius * math.cos(math.pi / 4),
      lensCenter.dy + lensRadius * math.sin(math.pi / 4),
    );
    final handleEnd = Offset(
      center.dx + radius * 0.95,
      center.dy + radius * 0.95,
    );
    canvas.drawLine(
      handleStart,
      handleEnd,
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.13
        ..color = _neonSoft,
    );

    // Glass highlight inside the lens.
    canvas.drawLine(
      Offset(lensCenter.dx - lensRadius * 0.4, lensCenter.dy - lensRadius * 0.15),
      Offset(lensCenter.dx - lensRadius * 0.1, lensCenter.dy - lensRadius * 0.45),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.05
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _MiliLogoPainter oldDelegate) =>
      oldDelegate.showBackplate != showBackplate;
}
