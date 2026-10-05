import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = Colors.black;

    for (final stroke in strokes) {
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first.position,
          paint.strokeWidth / 2,
          paint,
        );
        continue;
      }

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          stroke.points[i].position,
          stroke.points[i + 1].position,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}
