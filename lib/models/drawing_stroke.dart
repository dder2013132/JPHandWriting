import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset position;
  final int timestamp;

  const DrawingPoint({
    required this.position,
    required this.timestamp,
  });
}

class DrawingStroke {
  final List<DrawingPoint> points;

  DrawingStroke({
    List<DrawingPoint>? points,
  }) : points = points ?? [];
}
