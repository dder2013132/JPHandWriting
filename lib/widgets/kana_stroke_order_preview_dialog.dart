import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/kana_stroke_order.dart';
import '../models/kana_svg_stroke_order.dart';
import '../painters/kana_stroke_order_painter.dart';
import '../painters/kana_svg_stroke_order_painter.dart';
import '../services/kana_stroke_order_loader.dart';
import '../services/kana_svg_stroke_order_loader.dart';

class KanaStrokeOrderPreviewDialog extends StatefulWidget {
  final String character;
  final List<String> assetPaths;

  const KanaStrokeOrderPreviewDialog({
    super.key,
    required this.character,
    required this.assetPaths,
  });

  @override
  State<KanaStrokeOrderPreviewDialog> createState() =>
      _KanaStrokeOrderPreviewDialogState();
}

class _KanaStrokeOrderPreviewDialogState
    extends State<KanaStrokeOrderPreviewDialog>
    with SingleTickerProviderStateMixin {
  KanaStrokeOrderGuide? guide;
  KanaSvgStrokeOrderGuide? svgGuide;
  late final AnimationController controller;
  String? loadError;

  int activeStrokeIndex = 0;
  bool isAutoPlaying = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..addStatusListener(_handleAnimationStatus);
    _loadGuide();
  }

  Future<void> _loadGuide() async {
    try {
      final loadedGuide = await const KanaStrokeOrderLoader().load(
        character: widget.character,
        assetPaths: widget.assetPaths,
      );
      KanaSvgStrokeOrderGuide? loadedSvgGuide;

      try {
        loadedSvgGuide = await const KanaSvgStrokeOrderLoader().load(
          character: widget.character,
          assetPaths: widget.assetPaths,
        );

        if (loadedSvgGuide.strokes.length != loadedGuide.strokes.length) {
          throw FormatException(
            '${widget.character} SVG 원형 획수와 기존 획수가 달라.',
          );
        }
      } catch (error, stackTrace) {
        // 특정 SVG가 예상과 달라도 획순 창은 기존 렌더러로 계속 동작한다.
        debugPrint('${widget.character} SVG 원형 렌더러 fallback: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        guide = loadedGuide;
        svgGuide = loadedSvgGuide;
      });
      _updateAnimationDuration();
      controller.forward();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    final currentGuide = guide;

    if (currentGuide == null) {
      return;
    }

    if (status != AnimationStatus.completed || !isAutoPlaying) {
      return;
    }

    if (activeStrokeIndex < currentGuide.strokes.length - 1) {
      setState(() {
        activeStrokeIndex++;
      });
      _updateAnimationDuration();
      controller.forward(from: 0);
      return;
    }

    setState(() {
      isAutoPlaying = false;
    });
  }

  void showPreviousStroke() {
    if (activeStrokeIndex == 0) {
      return;
    }

    setState(() {
      isAutoPlaying = false;
      activeStrokeIndex--;
    });
    _updateAnimationDuration();
    controller.forward(from: 0);
  }

  void showNextStroke() {
    final currentGuide = guide;

    if (currentGuide == null ||
        activeStrokeIndex >= currentGuide.strokes.length - 1) {
      return;
    }

    setState(() {
      isAutoPlaying = false;
      activeStrokeIndex++;
    });
    _updateAnimationDuration();
    controller.forward(from: 0);
  }

  void toggleAutoPlay() {
    if (isAutoPlaying) {
      controller.stop();
      setState(() {
        isAutoPlaying = false;
      });
      return;
    }

    setState(() {
      isAutoPlaying = true;
      activeStrokeIndex = 0;
    });
    _updateAnimationDuration();
    controller.forward(from: 0);
  }

  void _updateAnimationDuration() {
    final currentSvgGuide = svgGuide;

    if (currentSvgGuide == null) {
      controller.duration = const Duration(milliseconds: 1350);
      return;
    }

    final stroke = currentSvgGuide.strokes[activeStrokeIndex];
    final lengthRatio =
        (stroke.visibleLength / KanaSvgLogicalStroke.revealDistance)
            .clamp(0.6, 1.0);
    final milliseconds = (1350 * lengthRatio).round();
    controller.duration = Duration(milliseconds: milliseconds);
  }

  @override
  Widget build(BuildContext context) {
    final currentGuide = guide;

    if (currentGuide == null) {
      return AlertDialog(
        title: Text('${widget.character} 획순 안내'),
        content: SizedBox(
          width: 300,
          height: 180,
          child: Center(
            child: loadError == null
                ? const CircularProgressIndicator()
                : Text(
                    'SVG 획 정보를 읽지 못했어.\n$loadError',
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('${widget.character} 획순 안내'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 280,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E9),
                  border: Border.all(color: const Color(0xFFE2D5B7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Row(
                        children: widget.assetPaths
                            .map(
                              (assetPath) => Expanded(
                                child: SvgPicture.asset(
                                  assetPath,
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFD8D1C2),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      AnimatedBuilder(
                        animation: controller,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: svgGuide == null
                                ? KanaStrokeOrderPainter(
                                    guide: currentGuide,
                                    activeStrokeIndex: activeStrokeIndex,
                                    progress: controller.value,
                                  )
                                : KanaSvgStrokeOrderPainter(
                                    guide: svgGuide!,
                                    activeStrokeIndex: activeStrokeIndex,
                                    progress: controller.value,
                                  ),
                          );
                        },
                      ),
                      CustomPaint(
                        painter: KanaStrokeOrderLabelsPainter(
                          guide: currentGuide,
                          activeStrokeIndex: activeStrokeIndex,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${activeStrokeIndex + 1} / ${currentGuide.strokes.length}획',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF635B4D),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: '이전 획',
                  onPressed: activeStrokeIndex > 0 ? showPreviousStroke : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: isAutoPlaying ? '일시정지' : '처음부터 재생',
                  onPressed: toggleAutoPlay,
                  icon: Icon(
                    isAutoPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  tooltip: '다음 획',
                  onPressed: activeStrokeIndex < currentGuide.strokes.length - 1
                      ? showNextStroke
                      : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '번호는 각 획의 시작점을 나타내요',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF776E64),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
