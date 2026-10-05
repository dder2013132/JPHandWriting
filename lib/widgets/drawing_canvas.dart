import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';
import '../painters/drawing_painter.dart';
import 'kana_stroke_order_guide_overlay.dart';

class DrawingCanvas extends StatelessWidget {
  final String character;
  final bool showGuide;
  final List<DrawingStroke> strokes;
  final List<String>? strokeOrderAssetPaths;
  final int strokeOrderPlaybackRequest;

  final ValueChanged<Offset> onPanStartPoint;
  final ValueChanged<Offset> onPanUpdatePoint;
  final VoidCallback? onPanEndStroke;

  const DrawingCanvas({
    super.key,
    required this.character,
    required this.showGuide,
    required this.strokes,
    required this.strokeOrderAssetPaths,
    required this.strokeOrderPlaybackRequest,
    required this.onPanStartPoint,
    required this.onPanUpdatePoint,
    this.onPanEndStroke,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: -10,
          top: 0,
          bottom: 0,
          width: 72,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpiralBackPainter(),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D8),
              border: Border.all(
                color: const Color(0xFFD8C79F),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.055),
                  blurRadius: 14,
                  offset: const Offset(2, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(
                    painter: _PaperTexturePainter(),
                  ),
                ),
                const Positioned.fill(
                  child: CustomPaint(
                    painter: _NotebookLinePainter(),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: KanaStrokeOrderGuideOverlay(
                        character: character,
                        assetPaths: strokeOrderAssetPaths,
                        playbackRequest: strokeOrderPlaybackRequest,
                        visible: showGuide,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      onPanStartPoint(details.localPosition);
                    },
                    onPanUpdate: (details) {
                      onPanUpdatePoint(details.localPosition);
                    },
                    onPanEnd: (_) {
                      onPanEndStroke?.call();
                    },
                    child: CustomPaint(
                      painter: DrawingPainter(strokes),
                    ),
                  ),
                ),
                if (kDebugMode)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F2A22).withOpacity(0.78),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '획수: ${strokes.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: -10,
          top: 0,
          bottom: 0,
          width: 72,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpiralFrontPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 종이 질감
class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF8A7450).withOpacity(0.045);

    final fiberPaint = Paint()
      ..color = const Color(0xFF9A845D).withOpacity(0.035)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    for (double y = 11; y < size.height; y += 18) {
      for (double x = 9; x < size.width; x += 22) {
        final offsetX = ((y * 7).toInt() % 13).toDouble();
        final offsetY = ((x * 5).toInt() % 9).toDouble();

        canvas.drawCircle(
          Offset(
            (x + offsetX) % size.width,
            (y + offsetY) % size.height,
          ),
          0.7,
          dotPaint,
        );
      }
    }

    for (double y = 17; y < size.height; y += 34) {
      for (double x = 14; x < size.width; x += 44) {
        final shift = ((x + y).toInt() % 11).toDouble();

        canvas.drawLine(
          Offset(x + shift, y),
          Offset(x + shift + 6, y + 1.5),
          fiberPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) {
    return false;
  }
}

/// 노트 가로줄 + 왼쪽 여백선
class _NotebookLinePainter extends CustomPainter {
  const _NotebookLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF7E94A8).withOpacity(0.18)
      ..strokeWidth = 1;

    final marginPaint = Paint()
      ..color = const Color(0xFFB96E6E).withOpacity(0.42)
      ..strokeWidth = 1.2;

    const lineSpacing = 34.0;

    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    const marginX = 46.0;

    canvas.drawLine(
      const Offset(marginX, 0),
      Offset(marginX, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NotebookLinePainter oldDelegate) {
    return false;
  }
}

class _SpiralBackPainter extends CustomPainter {
  const _SpiralBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double paperEdgeX = 10.0;
    canvas.save();

    canvas.clipRect(
      Rect.fromLTRB(
        0,
        0,
        paperEdgeX,
        size.height,
      ),
    );
    const double redMarginX = 56.0;
    const double holeX = paperEdgeX + (redMarginX - paperEdgeX) / 3;
    const double holeSpacing = 30.0;

    final backWirePaint = Paint()
      ..color = const Color(0xFF5B5B58)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final backHighlightPaint = Paint()
      ..color = const Color(0xFFD6D4CE).withOpacity(0.75)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 현재 구멍(y)으로 들어오는 스프링의 뒤쪽 half.
    // 첫 번째 구멍은 위에서 들어오는 이전 스프링이 없으므로 제외한다.
    // 즉, 이 파트는 '출발 구멍'이 아니라 '도착 구멍' 기준으로 묶는다.
    for (double y = 18 + holeSpacing; y < size.height - 8; y += holeSpacing) {
      final previousY = y - holeSpacing;

      final backPath = Path()
        ..moveTo(2.5, previousY + 10)
        ..cubicTo(
          2.5,
          previousY + 18,
          7,
          y - 7,
          holeX - 7.5,
          y - 1,
        );

      canvas.drawPath(backPath, backWirePaint);

      final highlightPath = Path()
        ..moveTo(4, previousY + 10)
        ..cubicTo(
          4,
          previousY + 17,
          8,
          y - 8,
          holeX - 8.5,
          y - 1.5,
        );

      canvas.drawPath(highlightPath, backHighlightPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpiralBackPainter oldDelegate) {
    return false;
  }
}

class _SpiralFrontPainter extends CustomPainter {
  const _SpiralFrontPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double paperEdgeX = 10.0;
    const double redMarginX = 56.0;
    const double holeX = paperEdgeX + (redMarginX - paperEdgeX) / 3;
    const double holeSpacing = 30.0;
    const double holeWidth = 16.0;
    const double holeHeight = 11.0;

    final holeShadowPaint = Paint()..color = Colors.black.withOpacity(0.24);

    final holePaint = Paint()..color = const Color(0xFF756E64);

    final holeInnerPaint = Paint()..color = const Color(0xFF292724);

    final frontWirePaint = Paint()
      ..color = const Color(0xFF7A7A76)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final wireHighlightPaint = Paint()
      ..color = const Color(0xFFD7D5CF).withOpacity(0.9)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1) 구멍 먼저
    for (double y = 18; y < size.height - 8; y += holeSpacing) {
      final shadowRect = Rect.fromCenter(
        center: Offset(holeX + 1.3, y + 1.4),
        width: holeWidth + 2,
        height: holeHeight + 2,
      );

      canvas.drawOval(shadowRect, holeShadowPaint);

      final holeRect = Rect.fromCenter(
        center: Offset(holeX, y),
        width: holeWidth,
        height: holeHeight,
      );

      canvas.drawOval(holeRect, holePaint);

      final innerRect = Rect.fromCenter(
        center: Offset(holeX, y),
        width: 11.0,
        height: 7.0,
      );

      canvas.drawOval(innerRect, holeInnerPaint);
    }

    // 2-A) 현재 구멍에서 바깥으로 나오는 front half
    // 이 파트는 '현재 구멍 -> 다음 구멍'으로 이어질 때만 그린다.
    // entryPath와 완전히 분리되어 있다.
    for (double y = 18; y + holeSpacing < size.height - 8; y += holeSpacing) {
      final frontPath = Path()
        ..moveTo(holeX + 1.2, y + 0.4)
        ..cubicTo(
          paperEdgeX + 7,
          y - 2,
          5,
          y + 2,
          2.5,
          y + 10,
        );

      canvas.drawPath(frontPath, frontWirePaint);

      final frontHighlight = Path()
        ..moveTo(holeX + 0.2, y - 0.2)
        ..cubicTo(
          paperEdgeX + 6,
          y - 3,
          6,
          y + 1.5,
          4,
          y + 9,
        );

      canvas.drawPath(frontHighlight, wireHighlightPaint);
    }

    // 2-B) 현재 구멍으로 들어오는 tail + entryPath
    // 첫 번째 구멍을 제외한 모든 실제 구멍을 '도착점'으로 사용한다.
    // _SpiralBackPainter의 spring half도 동일한 y를 도착 구멍으로 사용한다.
    // 그래서 구멍이 존재하면 incoming half와 entryPath가 같은 기준으로 생긴다.
    for (double y = 18 + holeSpacing; y < size.height - 8; y += holeSpacing) {
      canvas.save();

      // 현재 구멍 내부 크기와 거의 동일하게 클리핑
      final entryClip = Rect.fromCenter(
        center: Offset(holeX, y),
        width: 11.5,
        height: 7.2,
      );

      final entryClipPath = Path()..addOval(entryClip);

      canvas.clipPath(entryClipPath);

      final entryPath = Path()
        ..moveTo(
          holeX - 7.0,
          y - 1.2,
        )
        ..quadraticBezierTo(
          holeX - 2.5,
          y - 0.2,
          holeX + 4.0,
          y + 0.5,
        );

      canvas.drawPath(
        entryPath,
        frontWirePaint,
      );

      final entryHighlight = Path()
        ..moveTo(
          holeX - 6.5,
          y - 1.7,
        )
        ..quadraticBezierTo(
          holeX - 2.8,
          y - 0.8,
          holeX + 3.0,
          y,
        );

      canvas.drawPath(
        entryHighlight,
        wireHighlightPaint,
      );

      canvas.restore();
    }

    // 3) 마지막으로 구멍 안쪽을 한 번 더 덮어서
    // 철사가 안으로 들어간 느낌 강화
    final occlusionPaint = Paint()..color = const Color(0xFF292724);

    for (double y = 18; y < size.height - 8; y += holeSpacing) {
      final rect = Rect.fromCenter(
        center: Offset(holeX + 1.4, y),
        width: 8.5,
        height: 6.4,
      );

      canvas.drawOval(rect, occlusionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralFrontPainter oldDelegate) {
    return false;
  }
}
