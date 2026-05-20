import 'package:flutter/material.dart';

import '../models/template.dart';

/// Renders the dashed silhouette overlay used during capture.
/// The shape matches the one chosen during project creation so the user
/// can align their face / torso / plant identically each day.
class TemplateOverlay extends StatelessWidget {
  final TemplateKind kind;
  final Color color;

  const TemplateOverlay({
    super.key,
    required this.kind,
    this.color = const Color(0x80FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _TemplatePainter(kind: kind, color: color),
      ),
    );
  }
}

class _TemplatePainter extends CustomPainter {
  final TemplateKind kind;
  final Color color;

  _TemplatePainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = _pathFor(kind, size);
    _drawDashed(canvas, path, paint);
  }

  Path _pathFor(TemplateKind kind, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();

    switch (kind) {
      case TemplateKind.face:
        // Head + shoulder line
        final headRy = size.height * 0.22;
        final headRx = size.width * 0.28;
        path.addOval(Rect.fromCenter(
          center: Offset(cx, cy - size.height * 0.05),
          width: headRx * 2,
          height: headRy * 2,
        ));
        path.moveTo(cx - size.width * 0.36, cy + size.height * 0.32);
        path.quadraticBezierTo(
          cx,
          cy + size.height * 0.12,
          cx + size.width * 0.36,
          cy + size.height * 0.32,
        );
        return path;

      case TemplateKind.torso:
        // Head circle + torso outline
        final headR = size.width * 0.08;
        path.addOval(Rect.fromCircle(
          center: Offset(cx, cy - size.height * 0.28),
          radius: headR,
        ));
        path.moveTo(cx - size.width * 0.32, cy + size.height * 0.42);
        path.quadraticBezierTo(
          cx - size.width * 0.32,
          cy - size.height * 0.08,
          cx,
          cy - size.height * 0.16,
        );
        path.quadraticBezierTo(
          cx + size.width * 0.32,
          cy - size.height * 0.08,
          cx + size.width * 0.32,
          cy + size.height * 0.42,
        );
        return path;

      case TemplateKind.plant:
        // Pot + stem + leaves
        path.moveTo(cx - size.width * 0.22, cy + size.height * 0.30);
        path.lineTo(cx + size.width * 0.22, cy + size.height * 0.30);
        path.lineTo(cx + size.width * 0.18, cy + size.height * 0.42);
        path.lineTo(cx - size.width * 0.18, cy + size.height * 0.42);
        path.close();
        // stem
        path.moveTo(cx, cy + size.height * 0.30);
        path.lineTo(cx, cy - size.height * 0.10);
        // leaves
        path.moveTo(cx - size.width * 0.20, cy);
        path.quadraticBezierTo(cx, cy - size.height * 0.08, cx + size.width * 0.20, cy);
        return path;

      case TemplateKind.custom:
        // Plain rounded rectangle as placeholder.
        // In the full app, this draws a user-saved path.
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.7,
          height: size.height * 0.7,
        );
        path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
        return path;
    }
  }

  /// Approximates a dashed stroke by sampling the path.
  void _drawDashed(Canvas canvas, Path source, Paint paint) {
    const dash = 6.0;
    const gap = 6.0;
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = (dist + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TemplatePainter old) =>
      old.kind != kind || old.color != color;
}
