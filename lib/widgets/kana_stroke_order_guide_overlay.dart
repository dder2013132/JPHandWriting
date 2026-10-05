import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/kana_stroke_order.dart';
import '../models/kana_svg_stroke_order.dart';
import '../painters/kana_stroke_order_painter.dart';
import '../painters/kana_svg_stroke_order_painter.dart';
import '../services/kana_stroke_order_loader.dart';
import '../services/kana_svg_stroke_order_loader.dart';

/// 노트 위에 완성된 연한 글자와 획 번호를 보여주고, 요청받을 때만 재생한다.
class KanaStrokeOrderGuideOverlay extends StatefulWidget {
  final String character;
  final List<String>? assetPaths;
  final int playbackRequest;
  final bool visible;

  const KanaStrokeOrderGuideOverlay({
    super.key,
    required this.character,
    required this.assetPaths,
    required this.playbackRequest,
    required this.visible,
  });

  @override
  State<KanaStrokeOrderGuideOverlay> createState() =>
      _KanaStrokeOrderGuideOverlayState();
}

class _KanaStrokeOrderGuideOverlayState
    extends State<KanaStrokeOrderGuideOverlay>
    with SingleTickerProviderStateMixin {
  static const double _guideScale = 0.8;
  static const double _noteMarginLineX = 46;

  KanaStrokeOrderGuide? _guide;
  KanaSvgStrokeOrderGuide? _svgGuide;
  late final AnimationController _controller;

  int _activeStrokeIndex = 0;
  bool _isPlaying = false;
  bool _playWhenLoaded = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..addStatusListener(_handleAnimationStatus);
    _loadGuide();
  }

  @override
  void didUpdateWidget(covariant KanaStrokeOrderGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.character != widget.character ||
        !listEquals(oldWidget.assetPaths, widget.assetPaths)) {
      _loadGuide();
    }

    if (oldWidget.playbackRequest != widget.playbackRequest) {
      _startPlayback();
    }

    if (oldWidget.visible && !widget.visible) {
      _controller.stop();
      _isPlaying = false;
      _activeStrokeIndex = 0;
    }
  }

  Future<void> _loadGuide() async {
    final assetPaths = widget.assetPaths;
    final generation = ++_loadGeneration;

    _controller.stop();
    setState(() {
      _guide = null;
      _svgGuide = null;
      _activeStrokeIndex = 0;
      _isPlaying = false;
    });

    if (assetPaths == null) {
      return;
    }

    try {
      final guide = await const KanaStrokeOrderLoader().load(
        character: widget.character,
        assetPaths: assetPaths,
      );
      KanaSvgStrokeOrderGuide? svgGuide;

      try {
        svgGuide = await const KanaSvgStrokeOrderLoader().load(
          character: widget.character,
          assetPaths: assetPaths,
        );
        if (svgGuide.strokes.length != guide.strokes.length) {
          svgGuide = null;
        }
      } catch (error, stackTrace) {
        debugPrint('${widget.character} SVG 원형 렌더러 fallback: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        _guide = guide;
        _svgGuide = svgGuide;
      });

      if (_playWhenLoaded) {
        _playWhenLoaded = false;
        _startPlayback();
      }
    } catch (error, stackTrace) {
      debugPrint('${widget.character} 획순 가이드 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _startPlayback() {
    if (_guide == null) {
      _playWhenLoaded = true;
      return;
    }

    setState(() {
      _isPlaying = true;
      _activeStrokeIndex = 0;
    });
    _updateAnimationDuration();
    _controller.forward(from: 0);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    final guide = _guide;

    if (status != AnimationStatus.completed || !_isPlaying || guide == null) {
      return;
    }

    if (_activeStrokeIndex < guide.strokes.length - 1) {
      setState(() {
        _activeStrokeIndex++;
      });
      _updateAnimationDuration();
      _controller.forward(from: 0);
      return;
    }

    setState(() {
      _isPlaying = false;
      _activeStrokeIndex = 0;
    });
  }

  void _updateAnimationDuration() {
    final svgGuide = _svgGuide;

    if (svgGuide == null) {
      _controller.duration = const Duration(milliseconds: 1350);
      return;
    }

    final stroke = svgGuide.strokes[_activeStrokeIndex];
    final lengthRatio =
        (stroke.visibleLength / KanaSvgLogicalStroke.revealDistance)
            .clamp(0.6, 1.0);
    _controller.duration = Duration(
      milliseconds: (1350 * lengthRatio).round(),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    final guide = _guide;
    final assetPaths = widget.assetPaths;

    if (guide == null || assetPaths == null) {
      return Transform.translate(
        offset: const Offset(_noteMarginLineX / 2, 0),
        child: Center(
          child: Transform.scale(
            scale: _guideScale,
            child: Text(
              widget.character,
              softWrap: false,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'KleeOne',
                fontSize: widget.character.length > 1 ? 140 : 220,
                height: 1,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.095),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Transform.translate(
      offset: const Offset(_noteMarginLineX / 2, 0),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: _guideScale,
          heightFactor: _guideScale,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.095,
                child: Row(
                  children: assetPaths
                      .map(
                        (assetPath) => Expanded(
                          child: SvgPicture.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF2F2A22),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (_isPlaying)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _svgGuide == null
                          ? KanaStrokeOrderPainter(
                              guide: guide,
                              activeStrokeIndex: _activeStrokeIndex,
                              progress: _controller.value,
                            )
                          : KanaSvgStrokeOrderPainter(
                              guide: _svgGuide!,
                              activeStrokeIndex: _activeStrokeIndex,
                              progress: _controller.value,
                            ),
                    );
                  },
                ),
              CustomPaint(
                painter: KanaStrokeOrderLabelsPainter(
                  guide: guide,
                  activeStrokeIndex: _isPlaying ? _activeStrokeIndex : -1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
