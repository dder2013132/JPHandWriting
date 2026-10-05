import 'package:flutter/material.dart';

import '../models/kana_stroke_order.dart';

class KanaStrokeOrderPainter extends CustomPainter {
  final KanaStrokeOrderGuide guide;
  final int activeStrokeIndex;
  final double progress;

  KanaStrokeOrderPainter({
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

    final completedPaint = Paint()
      ..color = const Color(0xFF635B4D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34 * guide.visualScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final activePaint = Paint()
      ..color = const Color(0xFFC78B18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 42 * guide.visualScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < activeStrokeIndex; i++) {
      final stroke = guide.strokes[i];
      final segment = stroke.segment;
      _drawSegmentPath(
        canvas: canvas,
        path: segment.metric.extractPath(
          segment.startOffset,
          segment.endOffset,
        ),
        paint: completedPaint,
      );
    }

    final activeStroke = guide.strokes[activeStrokeIndex];
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    final activeSegment = activeStroke.segment;
    final visibleLength = activeSegment.startOffset +
        (activeSegment.endOffset - activeSegment.startOffset) *
            normalizedProgress;
    _drawSegmentPath(
      canvas: canvas,
      path: activeSegment.metric.extractPath(
        activeSegment.startOffset,
        visibleLength,
      ),
      paint: activePaint,
    );

    canvas.restore();
  }

  void _drawSegmentPath({
    required Canvas canvas,
    required Path path,
    required Paint paint,
  }) {
    // clipPath는 로더에서 시작·종료점을 계산할 때만 사용한다.
    // 여기서 Paint를 자르면 밑그림을 벗어난 두께만큼 선이 사라진다.
    canvas.drawPath(path, paint);
  }

  double _scaleFor(Size size) {
    final horizontalScale = size.width / guide.sourceSize.width;
    final verticalScale = size.height / guide.sourceSize.height;
    return horizontalScale < verticalScale ? horizontalScale : verticalScale;
  }

  @override
  bool shouldRepaint(covariant KanaStrokeOrderPainter oldDelegate) {
    return oldDelegate.guide != guide ||
        oldDelegate.activeStrokeIndex != activeStrokeIndex ||
        oldDelegate.progress != progress;
  }
}

class KanaStrokeOrderLabelsPainter extends CustomPainter {
  final KanaStrokeOrderGuide guide;
  final int activeStrokeIndex;

  KanaStrokeOrderLabelsPainter({
    required this.guide,
    required this.activeStrokeIndex,
  });

  int get visibleStrokeCount => activeStrokeIndex < 0
      ? guide.strokes.length
      : (activeStrokeIndex + 1).clamp(0, guide.strokes.length);

  @override
  void paint(Canvas canvas, Size size) {
    final horizontalScale = size.width / guide.sourceSize.width;
    final verticalScale = size.height / guide.sourceSize.height;
    final scale =
        horizontalScale < verticalScale ? horizontalScale : verticalScale;
    final horizontalInset = (size.width - guide.sourceSize.width * scale) / 2;
    final verticalInset = (size.height - guide.sourceSize.height * scale) / 2;

    canvas
      ..save()
      ..translate(horizontalInset, verticalInset)
      ..scale(scale);
    _paintStrokeNumbers(canvas);
    canvas.restore();
  }

  void _paintStrokeNumbers(Canvas canvas) {
    for (int i = 0; i < visibleStrokeCount; i++) {
      final stroke = guide.strokes[i];
      final start = stroke.segment.metric
          .getTangentForOffset(stroke.markerOffset)
          ?.position;

      if (start == null) {
        continue;
      }

      final labelPosition = start + stroke.labelOffset;
      final circleColor = _strokeNumberColor(i);

      canvas.drawCircle(
        labelPosition,
        43 * guide.labelScale,
        Paint()..color = circleColor,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${stroke.order}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48 * guide.labelScale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        labelPosition - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  Color _strokeNumberColor(int strokeIndex) {
    if (strokeIndex == activeStrokeIndex) {
      return const Color(0xFFC78B18);
    }
    return const Color(0xFF635B4D);
  }

  @override
  bool shouldRepaint(covariant KanaStrokeOrderLabelsPainter oldDelegate) {
    return oldDelegate.guide != guide ||
        oldDelegate.activeStrokeIndex != activeStrokeIndex;
  }
}
