import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

import '../models/kana_stroke_order.dart';

class KanaStrokeOrderLoader {
  const KanaStrokeOrderLoader();

  static final Map<String, KanaStrokeOrderGuide> _cache = {};
  static const _labelLayoutVersion = 'compound-kana-anchor-v13';

  Future<KanaStrokeOrderGuide> load({
    required String character,
    required List<String> assetPaths,
  }) async {
    // Hot Reload 뒤에도 이전 번호 좌표가 static 캐시에 남지 않도록
    // 배치 알고리즘 버전을 키에 포함한다.
    final cacheKey = '$_labelLayoutVersion|$character|${assetPaths.join('|')}';
    final cachedGuide = _cache[cacheKey];

    if (cachedGuide != null) {
      return cachedGuide;
    }

    final loadedStrokes = <_LoadedStroke>[];
    final partGlyphMasks = List<Path>.generate(
      assetPaths.length,
      (_) => Path(),
    );

    for (int partIndex = 0; partIndex < assetPaths.length; partIndex++) {
      final svgText = await rootBundle.loadString(assetPaths[partIndex]);
      final document = XmlDocument.parse(svgText);
      final strokesGroup = _findStrokesGroup(document, assetPaths[partIndex]);
      final strokeElements = strokesGroup.childElements.toList();
      final partCharacter = String.fromCharCode(
        character.runes.elementAt(partIndex),
      );

      for (int localStrokeIndex = 0;
          localStrokeIndex < strokeElements.length;
          localStrokeIndex++) {
        final strokeElement = strokeElements[localStrokeIndex];
        final pathElements = _findCenterPaths(strokeElement);

        if (pathElements.isEmpty) {
          continue;
        }

        final pathData = pathElements.first.getAttribute('d');

        if (pathData == null) {
          continue;
        }

        final isLoopMark = _isHandakuten(partCharacter) &&
            localStrokeIndex == strokeElements.length - 1;
        final combinedClipPath = Path();
        var hasClipPath = false;
        for (final pathElement in pathElements) {
          final clipPath = _findClipPath(document, pathElement)?.shift(
            Offset(partIndex * 1024, 0),
          );

          if (clipPath != null) {
            combinedClipPath.addPath(clipPath, Offset.zero);
            partGlyphMasks[partIndex].addPath(clipPath, Offset.zero);
            hasClipPath = true;
          }
        }

        final path = isLoopMark && hasClipPath
            ? _buildHandakutenPath(combinedClipPath.getBounds())
            : _parsePath(pathData).shift(Offset(partIndex * 1024, 0));
        final metric = path.computeMetrics().firstOrNull;

        if (metric == null) {
          continue;
        }

        final isDakutenMark = _isDakuten(partCharacter) &&
            localStrokeIndex >= strokeElements.length - 2;

        final visibleRange = isLoopMark
            ? _VisibleRange(0, metric.length)
            : _findVisibleRange(
                metric,
                hasClipPath ? combinedClipPath : null,
                edgeAllowance:
                    (isDakutenMark ? 52.0 : 24.0) * assetPaths.length,
              );
        final primarySegment = KanaStrokeSegment(
          path: path,
          metric: metric,
          startOffset: visibleRange.start,
          endOffset: visibleRange.end,
        );
        final markerOffset = isDakutenMark && assetPaths.length > 1
            ? _findVisibleRange(
                metric,
                hasClipPath ? combinedClipPath : null,
                edgeAllowance: 0,
              ).start
            : primarySegment.startOffset;
        final start =
            primarySegment.metric.getTangentForOffset(markerOffset)?.position;

        if (start == null) {
          continue;
        }

        loadedStrokes.add(
          _LoadedStroke(
            segment: primarySegment,
            markerOffset: markerOffset,
            start: start,
            partIndex: partIndex,
            isDakutenMark: isDakutenMark,
          ),
        );
      }
    }

    if (loadedStrokes.isEmpty) {
      throw FormatException('$character SVG에서 획 경로를 찾지 못했어.');
    }

    final visualScale = assetPaths.length.toDouble();
    final labelScale = assetPaths.length > 1 ? visualScale * 0.82 : visualScale;
    final sourceSize = Size(assetPaths.length * 1024, 1024);
    final labelCenters = <Offset>[];
    final strokes = <KanaReferenceStroke>[];

    void addStroke(int index, Offset labelOffset) {
      final loaded = loadedStrokes[index];
      labelCenters.add(loaded.start + labelOffset);
      strokes.add(
        KanaReferenceStroke(
          order: index + 1,
          segment: loaded.segment,
          markerOffset: loaded.markerOffset,
          labelOffset: labelOffset,
        ),
      );
    }

    for (int i = 0; i < loadedStrokes.length; i++) {
      final loaded = loadedStrokes[i];
      final hasDakutenPair = assetPaths.length > 1 &&
          loaded.isDakutenMark &&
          i + 1 < loadedStrokes.length &&
          loadedStrokes[i + 1].isDakutenMark &&
          loadedStrokes[i + 1].partIndex == loaded.partIndex;

      if (hasDakutenPair) {
        final pairOffsets = _anchoredDakutenPairOffsets(
          firstStart: loaded.start,
          secondStart: loadedStrokes[i + 1].start,
          partIndex: loaded.partIndex,
          sourceSize: sourceSize,
          labelScale: labelScale,
        );

        addStroke(i, pairOffsets.first);
        addStroke(i + 1, pairOffsets.second);
        i++;
        continue;
      }

      final labelOffset = _automaticLabelOffset(
        start: loaded.start,
        partIndex: loaded.partIndex,
        sourceSize: sourceSize,
        labelScale: labelScale,
        occupiedCenters: labelCenters,
        glyphMask: partGlyphMasks[loaded.partIndex],
        glyphBounds: partGlyphMasks[loaded.partIndex].getBounds(),
      );
      addStroke(i, labelOffset);
    }

    final guide = KanaStrokeOrderGuide(
      character: character,
      sourceSize: sourceSize,
      visualScale: visualScale,
      labelScale: labelScale,
      strokes: strokes,
    );

    _cache[cacheKey] = guide;
    return guide;
  }

  XmlElement _findStrokesGroup(XmlDocument document, String assetPath) {
    for (final group in document.findAllElements('g')) {
      if (group.getAttribute('data-strokesvg') == 'strokes') {
        return group;
      }
    }

    throw FormatException('$assetPath 안에 strokes 그룹이 없어.');
  }

  List<XmlElement> _findCenterPaths(XmlElement strokeElement) {
    if (strokeElement.name.local == 'path') {
      return [strokeElement];
    }

    // 같은 한 획이 여러 클립 구간으로 나뉜 경우 첫 중심선을 대표로 쓴다.
    return strokeElement.findAllElements('path').toList();
  }

  Path? _findClipPath(XmlDocument document, XmlElement centerPath) {
    final clipValue = centerPath.getAttribute('clip-path');
    final clipId =
        RegExp(r'url\(#([^\)]+)\)').firstMatch(clipValue ?? '')?.group(1);

    if (clipId == null) {
      return null;
    }

    final clipElement = _findElementById(document, clipId);
    final useElement = clipElement?.findAllElements('use').firstOrNull;
    final shadowId = useElement?.getAttribute('href')?.replaceFirst('#', '');
    final shadowPathData = shadowId == null
        ? null
        : _findElementById(document, shadowId)?.getAttribute('d');

    return shadowPathData == null ? null : _parsePath(shadowPathData);
  }

  XmlElement? _findElementById(XmlDocument document, String id) {
    return document.descendants
        .whereType<XmlElement>()
        .where((element) => element.getAttribute('id') == id)
        .firstOrNull;
  }

  _VisibleRange _findVisibleRange(
    PathMetric metric,
    Path? clipPath, {
    required double edgeAllowance,
  }) {
    if (clipPath == null) {
      return _VisibleRange(0, metric.length);
    }

    double? firstVisible;
    double? lastVisible;

    for (double offset = 0; offset <= metric.length; offset += 2) {
      final position = metric.getTangentForOffset(offset)?.position;

      if (position != null && clipPath.contains(position)) {
        firstVisible ??= offset;
        lastVisible = offset;
      }
    }

    if (firstVisible == null || lastVisible == null) {
      return _VisibleRange(0, metric.length);
    }

    // clipPath는 경계 탐지에만 쓴다. 실제 Paint를 자르지 않고
    // 앞뒤로 여유를 줘서 둥근 선 끝이 자연스럽게 보이게 한다.
    return _VisibleRange(
      (firstVisible - edgeAllowance).clamp(0.0, metric.length).toDouble(),
      (lastVisible + edgeAllowance).clamp(0.0, metric.length).toDouble(),
    );
  }

  _DakutenPairOffsets _anchoredDakutenPairOffsets({
    required Offset firstStart,
    required Offset secondStart,
    required int partIndex,
    required Size sourceSize,
    required double labelScale,
  }) {
    final markerRadius = 43 * labelScale;
    final minimumSpacing = markerRadius * 2 + 32 * labelScale;
    final labelLift = markerRadius + 16 * labelScale;
    final maximumSideShift = 48 * labelScale;
    final partLeft = partIndex * 1024.0;
    final partRight = math.min(partLeft + 1024, sourceSize.width);

    var firstCenter = Offset(
      firstStart.dx,
      (firstStart.dy - labelLift)
          .clamp(markerRadius, sourceSize.height - markerRadius)
          .toDouble(),
    );
    var secondCenter = Offset(
      secondStart.dx,
      (secondStart.dy - labelLift)
          .clamp(markerRadius, sourceSize.height - markerRadius)
          .toDouble(),
    );

    // 두 번호가 겹치면 필요한 거리의 절반씩만 좌우로 벌린다.
    // 시작점과의 연결을 잃지 않도록 각 번호의 이동량에는 상한을 둔다.
    final verticalDistance = (secondCenter.dy - firstCenter.dy).abs();
    final requiredHorizontalDistance = math.sqrt(
      math.max(
          0,
          minimumSpacing * minimumSpacing -
              verticalDistance * verticalDistance),
    );
    final currentHorizontalDistance = (secondCenter.dx - firstCenter.dx).abs();
    final sideShift =
        ((requiredHorizontalDistance - currentHorizontalDistance) / 2)
            .clamp(0.0, maximumSideShift)
            .toDouble();

    if (firstStart.dx <= secondStart.dx) {
      firstCenter = firstCenter.translate(-sideShift, 0);
      secondCenter = secondCenter.translate(sideShift, 0);
    } else {
      firstCenter = firstCenter.translate(sideShift, 0);
      secondCenter = secondCenter.translate(-sideShift, 0);
    }

    firstCenter = Offset(
      firstCenter.dx
          .clamp(partLeft + markerRadius, partRight - markerRadius)
          .toDouble(),
      firstCenter.dy,
    );
    secondCenter = Offset(
      secondCenter.dx
          .clamp(partLeft + markerRadius, partRight - markerRadius)
          .toDouble(),
      secondCenter.dy,
    );

    return _DakutenPairOffsets(
      first: firstCenter - firstStart,
      second: secondCenter - secondStart,
    );
  }

  Offset _automaticLabelOffset({
    required Offset start,
    required int partIndex,
    required Size sourceSize,
    required double labelScale,
    required List<Offset> occupiedCenters,
    required Path glyphMask,
    required Rect glyphBounds,
  }) {
    final markerRadius = 43 * labelScale;
    final isFollowingCompoundPart = sourceSize.width > 1024 && partIndex > 0;
    final labelSpacing =
        markerRadius * 2 + (isFollowingCompoundPart ? 16 : 64) * labelScale;
    final compactLabelSpacing =
        markerRadius * 2 + (isFollowingCompoundPart ? 0 : 16) * labelScale;
    final glyphPadding = markerRadius + 12 * labelScale;
    final partLeft = partIndex * 1024.0;
    final partRight = math.min(partLeft + 1024, sourceSize.width);
    final preferredAngle = isFollowingCompoundPart ? math.pi : -math.pi / 2;
    final candidates = <Offset>[];

    // 단일 글자는 시작점 위쪽을 우선한다. 합성 요음의 작은 글자는
    // 글자 사이의 왼쪽 여백부터 찾아 번호와 획의 위아래 순서를 지킨다.
    for (final distanceMultiplier in [1.0, 1.3, 1.65, 2.05, 2.5, 3.0]) {
      final distance = 92 * labelScale * distanceMultiplier;
      for (int step = 0; step < 16; step++) {
        final alternatingStep = step.isEven ? step ~/ 2 : -(step + 1) ~/ 2;
        final angle = preferredAngle + alternatingStep * math.pi / 8;
        candidates.add(
          Offset(math.cos(angle), math.sin(angle)) * distance,
        );
      }
    }

    // 주변이 모두 막혔을 때만 해당 글자 칸 안쪽을 촘촘히 훑는다.
    final gridStep = 48 * labelScale;
    for (double y = markerRadius; y <= 1024 - markerRadius; y += gridStep) {
      for (double x = partLeft + markerRadius;
          x <= partRight - markerRadius;
          x += gridStep) {
        candidates.add(Offset(x, y) - start);
      }
    }

    bool isInsidePart(Offset center) {
      return center.dx >= partLeft + markerRadius &&
          center.dx <= partRight - markerRadius &&
          center.dy >= markerRadius &&
          center.dy <= sourceSize.height - markerRadius;
    }

    bool overlapsLabel(Offset center) {
      return occupiedCenters.any(
        (other) => (other - center).distance < labelSpacing,
      );
    }

    final insideCandidates = candidates
        .where((candidate) => isInsidePart(start + candidate))
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    // 글자 전체 경계 상자 안쪽도 실제 붓글씨 선과 겹치지 않으면 허용한다.
    // 그래야 가로획처럼 글자 안쪽에서 시작하는 획 번호가 다른 획 옆으로
    // 멀리 밀려나지 않고 자기 시작점 근처에 남는다.
    for (final candidate in insideCandidates) {
      final center = start + candidate;
      if (!overlapsLabel(center) &&
          !_circleOverlapsPath(glyphMask, center, glyphPadding)) {
        return candidate;
      }
    }

    // 번호 간격을 조금 양보하더라도 글자 전체 외곽 안쪽에는 넣지 않는다.
    // 획 사이의 구멍도 사람 눈에는 글자 중앙으로 보이기 때문이다.
    final outsideGlyphCandidates = insideCandidates
        .where(
          (candidate) =>
              !glyphBounds.contains(start + candidate) &&
              !_circleOverlapsPath(
                glyphMask,
                start + candidate,
                glyphPadding,
              ),
        )
        .toList();
    if (outsideGlyphCandidates.isNotEmpty) {
      for (final candidate in outsideGlyphCandidates) {
        final center = start + candidate;
        final overlapsNearbyLabel = occupiedCenters.any(
          (other) => (other - center).distance < compactLabelSpacing,
        );
        if (!overlapsNearbyLabel) {
          return candidate;
        }
      }

      // 추가 여백을 만들 수 없더라도 번호 원 자체는 겹치지 않게 한다.
      for (final candidate in outsideGlyphCandidates) {
        final center = start + candidate;
        final overlapsLabelCircle = occupiedCenters.any(
          (other) => (other - center).distance < markerRadius * 2,
        );
        if (!overlapsLabelCircle) {
          return candidate;
        }
      }

      return _farthestFromLabels(
        candidates: outsideGlyphCandidates,
        start: start,
        occupiedCenters: occupiedCenters,
      );
    }

    // 바깥 여백을 전부 사용한 뒤에만 획과 겹치지 않는 내부 공간을 쓴다.
    final glyphSafeCandidates = insideCandidates
        .where(
          (candidate) => !_circleOverlapsPath(
            glyphMask,
            start + candidate,
            glyphPadding,
          ),
        )
        .toList();
    if (glyphSafeCandidates.isNotEmpty) {
      return _farthestFromLabels(
        candidates: glyphSafeCandidates,
        start: start,
        occupiedCenters: occupiedCenters,
      );
    }

    // SVG 안에 빈 공간이 정말 없을 때만 번호끼리 겹치지 않는 자리를 쓴다.
    final labelSafeCandidates = insideCandidates
        .where((candidate) => !overlapsLabel(start + candidate))
        .toList();
    if (labelSafeCandidates.isNotEmpty) {
      return labelSafeCandidates.first;
    }

    return insideCandidates.isEmpty ? Offset.zero : insideCandidates.first;
  }

  Offset _farthestFromLabels({
    required List<Offset> candidates,
    required Offset start,
    required List<Offset> occupiedCenters,
  }) {
    if (occupiedCenters.isEmpty) {
      return candidates.first;
    }

    candidates.sort((a, b) {
      double nearestLabelDistance(Offset candidate) {
        final center = start + candidate;
        return occupiedCenters
            .map((other) => (other - center).distance)
            .reduce(math.min);
      }

      final distanceComparison = nearestLabelDistance(
        b,
      ).compareTo(nearestLabelDistance(a));
      return distanceComparison != 0
          ? distanceComparison
          : a.distance.compareTo(b.distance);
    });
    return candidates.first;
  }

  bool _circleOverlapsPath(
    Path path,
    Offset center,
    double radius,
  ) {
    final circleBounds = Rect.fromCircle(center: center, radius: radius);

    if (!path.getBounds().overlaps(circleBounds)) {
      return false;
    }

    try {
      final circlePath = Path()..addOval(circleBounds);
      final intersection = Path.combine(
        PathOperation.intersect,
        path,
        circlePath,
      );

      if (intersection.computeMetrics().isNotEmpty) {
        return true;
      }
    } catch (_) {
      // Path.combine이 특정 SVG 경로에서 실패하면 아래 샘플 검사로 보완한다.
    }

    if (path.contains(center)) {
      return true;
    }

    for (final radiusScale in [0.35, 0.7, 1.0]) {
      for (int step = 0; step < 24; step++) {
        final angle = math.pi * 2 * step / 24;
        final sample = center +
            Offset(math.cos(angle), math.sin(angle)) * radius * radiusScale;

        if (path.contains(sample)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isHandakuten(String character) {
    return const {
      'ぱ',
      'ぴ',
      'ぷ',
      'ぺ',
      'ぽ',
      'パ',
      'ピ',
      'プ',
      'ペ',
      'ポ',
    }.contains(character);
  }

  bool _isDakuten(String character) {
    return const {
      'が',
      'ぎ',
      'ぐ',
      'げ',
      'ご',
      'ざ',
      'じ',
      'ず',
      'ぜ',
      'ぞ',
      'だ',
      'ぢ',
      'づ',
      'で',
      'ど',
      'ば',
      'び',
      'ぶ',
      'べ',
      'ぼ',
      'ゔ',
      'ガ',
      'ギ',
      'グ',
      'ゲ',
      'ゴ',
      'ザ',
      'ジ',
      'ズ',
      'ゼ',
      'ゾ',
      'ダ',
      'ヂ',
      'ヅ',
      'デ',
      'ド',
      'バ',
      'ビ',
      'ブ',
      'ベ',
      'ボ',
      'ヴ',
      'ヷ',
      'ヸ',
      'ヹ',
      'ヺ',
    }.contains(character);
  }

  Path _buildHandakutenPath(Rect outerBounds) {
    final inset = math.min(outerBounds.width, outerBounds.height) * 0.115;
    final centerLineBounds = outerBounds.deflate(inset);

    // 반탁음은 SVG의 실제 외곽 크기를 기준으로 시계 방향 원을 만든다.
    // 원본 선의 두꺼운 끝에 의존하지 않으므로 얇은 안내선도 끊기지 않는다.
    return Path()
      ..addArc(
        centerLineBounds,
        -math.pi * 0.75,
        math.pi * 2,
      )
      ..close();
  }

  Path _parsePath(String pathData) {
    final proxy = _FlutterPathProxy();
    writeSvgPathDataToPath(pathData, proxy);
    return proxy.path;
  }
}

class _LoadedStroke {
  final KanaStrokeSegment segment;
  final double markerOffset;
  final Offset start;
  final int partIndex;
  final bool isDakutenMark;

  const _LoadedStroke({
    required this.segment,
    required this.markerOffset,
    required this.start,
    required this.partIndex,
    required this.isDakutenMark,
  });
}

class _DakutenPairOffsets {
  final Offset first;
  final Offset second;

  const _DakutenPairOffsets({
    required this.first,
    required this.second,
  });
}

class _VisibleRange {
  final double start;
  final double end;

  const _VisibleRange(this.start, this.end);
}

class _FlutterPathProxy extends PathProxy {
  final Path path = Path();

  @override
  void close() => path.close();

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
