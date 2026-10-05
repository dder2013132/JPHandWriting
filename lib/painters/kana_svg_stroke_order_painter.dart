import 'package:flutter/material.dart';

import '../models/kana_svg_stroke_order.dart';

/// StrokeSVG 원본의 128px 중심선과 clipPath를 그대로 재현하는 파일럿 페인터다.
class KanaSvgStrokeOrderPainter extends CustomPainter {
  final KanaSvgStrokeOrderGuide guide;
  final int activeStrokeIndex;
  final double progress;

  KanaSvgStrokeOrderPainter({
    required this.guide,
    required this.activeStrokeIndex,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scaleFor(size);
    final horizontalInset = (size.width - guide.sourceSize.width * scale) / 2;
    final verticalInset = (size.height - guide.sourceSize.height * scale) / 2;

    canvas
      ..save()
      ..translate(horizontalInset, verticalInset)
      ..scale(scale);

    final completedPaint = _strokePaint(const Color(0xFF635B4D));
    final activePaint = _strokePaint(const Color(0xFFC78B18));

    for (int i = 0; i < activeStrokeIndex; i++) {
      _paintStroke(
        canvas: canvas,
        stroke: guide.strokes[i],
        revealDistance: guide.strokes[i].visibleEndOffset,
        paint: completedPaint,
      );
    }

    final activeStroke = guide.strokes[activeStrokeIndex];
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    final revealDistance = activeStroke.visibleStartOffset +
        activeStroke.visibleLength * normalizedProgress;
    _paintStroke(
      canvas: canvas,
      stroke: activeStroke,
      revealDistance: revealDistance,
      paint: activePaint,
    );

    canvas.restore();
  }

  Paint _strokePaint(Color color) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 128
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  void _paintStroke({
    required Canvas canvas,
    required KanaSvgLogicalStroke stroke,
    required double revealDistance,
    required Paint paint,
  }) {
    for (final section in stroke.sections) {
      final visibleEnd =
          revealDistance.clamp(0.0, section.metric.length).toDouble();

      canvas
        ..save()
        ..clipPath(section.clipPath)
        ..drawPath(section.metric.extractPath(0, visibleEnd), paint)
        ..restore();
    }
  }

  double _scaleFor(Size size) {
    final horizontalScale = size.width / guide.sourceSize.width;
    final verticalScale = size.height / guide.sourceSize.height;
    return horizontalScale < verticalScale ? horizontalScale : verticalScale;
  }

  @override
  bool shouldRepaint(covariant KanaSvgStrokeOrderPainter oldDelegate) {
    return oldDelegate.guide != guide ||
        oldDelegate.activeStrokeIndex != activeStrokeIndex ||
        oldDelegate.progress != progress;
  }
}
