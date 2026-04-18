import 'package:flutter/material.dart';
import 'detection_result.dart';

class DamagePainter extends CustomPainter {
  final List<DetectionResult> results;

  DamagePainter(this.results);

  void _drawStaticCrosshair(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Garis horizontal
    canvas.drawLine(
      Offset(centerX - 50, centerY),
      Offset(centerX + 50, centerY),
      paint,
    );

    // Garis vertikal
    canvas.drawLine(
      Offset(centerX, centerY - 50),
      Offset(centerX, centerY + 50),
      paint,
    );

    // Lingkaran di tengah
    canvas.drawCircle(
      Offset(centerX, centerY),
      30,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawSearchingText(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: "Searching for Road Damage...",
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 16,
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 + 60),
    );
  }

  Color _getColorForDamage(String label) {
    if (label.contains('D40')) return Colors.red; // Pothole — Parah
    if (label.contains('D20')) return Colors.orange; // Alligator Crack — Tinggi
    if (label.contains('D10'))
      return Colors.yellow; // Transverse Crack — Sedang
    return Colors.green; // Longitudinal Crack — Ringan
  }

  void _drawLabel(Canvas canvas, Rect box, String label, double score) {
    final textSpan = TextSpan(
      text: ' $label - ${(score * 100).toInt()}% ',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    double labelY = box.top - 25;
    if (labelY < 0) labelY = box.bottom + 5;

    final shadowPainter = TextPainter(
      text: TextSpan(
        text: ' $label - ${(score * 100).toInt()}% ',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    shadowPainter.layout();
    shadowPainter.paint(
      canvas,
      Offset(box.left + 2, labelY + 2),
    );

    textPainter.paint(
      canvas,
      Offset(box.left, labelY),
    );
  }

  void _drawDetectionBox(Canvas canvas, Size size, DetectionResult result) {
    final box = Rect.fromLTWH(
      result.box.left * size.width,
      result.box.top * size.height,
      result.box.width * size.width,
      result.box.height * size.height,
    );

    final paint = Paint()
      ..color = _getColorForDamage(result.label)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(box, paint);

    _drawLabel(canvas, box, result.label, result.score);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawStaticCrosshair(canvas, size);
    if (results.isEmpty) {
      _drawSearchingText(canvas, size);
    }
    for (var res in results) {
      _drawDetectionBox(canvas, size, res);
    }
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.results != results;
  }
}
