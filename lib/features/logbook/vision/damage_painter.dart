import 'package:flutter/material.dart';
import 'detection_result.dart';

class DamagePainter extends CustomPainter {
  final List<DetectionResult> results;

  DamagePainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.redAccent,
    );

    for (var res in results) {
      // Scaling koordinat AI (0.0-1.0) ke ukuran layar aktual
      final scaledRect = Rect.fromLTRB(
        res.box.left * size.width,
        res.box.top * size.height,
        res.box.right * size.width,
        res.box.bottom * size.height,
      );

      // Gambar kotak deteksi
      canvas.drawRect(scaledRect, paint);

      // Gambar label
      final textSpan = TextSpan(
        text: " [${res.label}] - ${(res.score * 100).toStringAsFixed(0)}% ",
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(scaledRect.left, scaledRect.top - 25));
    }
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.results != results;
  }
}
