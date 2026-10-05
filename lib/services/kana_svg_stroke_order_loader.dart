import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

import '../models/kana_svg_stroke_order.dart';

class KanaSvgStrokeOrderLoader {
  const KanaSvgStrokeOrderLoader();

  static final Map<String, KanaSvgStrokeOrderGuide> _cache = {};

  Future<KanaSvgStrokeOrderGuide> load({
    required String character,
    required List<String> assetPaths,
  }) async {
    final cacheKey = '$character|${assetPaths.join('|')}';
    final cachedGuide = _cache[cacheKey];

    if (cachedGuide != null) {
      return cachedGuide;
    }

    final strokes = <KanaSvgLogicalStroke>[];

    for (int partIndex = 0; partIndex < assetPaths.length; partIndex++) {
      final svgText = await rootBundle.loadString(assetPaths[partIndex]);
      final document = XmlDocument.parse(svgText);
      final strokesGroup = _findStrokesGroup(
        document,
        assetPaths[partIndex],
      );

      for (final strokeElement in strokesGroup.childElements) {
        final sections = <KanaSvgStrokeSection>[];

        for (final pathElement in _findCenterPaths(strokeElement)) {
          final pathData = pathElement.getAttribute('d');
          final clipPath = _findClipPath(document, pathElement);

          if (pathData == null || clipPath == null) {
            continue;
          }

          final shift = Offset(partIndex * 1024.0, 0);
          final path = _parsePath(pathData).shift(shift);
          final shiftedClipPath = clipPath.shift(shift);
          final metric = path.computeMetrics().firstOrNull;

          if (metric == null) {
            continue;
          }

          final visibleRange = _findVisibleRange(metric, shiftedClipPath);
          sections.add(
            KanaSvgStrokeSection(
              path: path,
              metric: metric,
              clipPath: shiftedClipPath,
              visibleStartOffset: visibleRange.start,
              visibleEndOffset: visibleRange.end,
            ),
          );
        }

        if (sections.isNotEmpty) {
          strokes.add(
            KanaSvgLogicalStroke(
              order: strokes.length + 1,
              sections: sections,
            ),
          );
        }
      }
    }

    if (strokes.isEmpty) {
      throw FormatException('$character SVG에서 원형 획 경로를 찾지 못했어.');
    }

    final guide = KanaSvgStrokeOrderGuide(
      character: character,
      sourceSize: Size((assetPaths.length * 1024).toDouble(), 1024),
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
    return strokeElement.findAllElements('path').toList();
  }

  Path? _findClipPath(XmlDocument document, XmlElement centerPath) {
    final clipValue = centerPath.getAttribute('clip-path');
    final clipId = RegExp(
      r'url\(#([^\)]+)\)',
    ).firstMatch(clipValue ?? '')?.group(1);

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

  _VisibleRange _findVisibleRange(PathMetric metric, Path clipPath) {
    double? firstVisible;
    double? lastVisible;

    for (double offset = 0; offset <= metric.length; offset += 2) {
      final position = metric.getTangentForOffset(offset)?.position;

      if (position != null && clipPath.contains(position)) {
        firstVisible ??= offset;
        lastVisible = offset;
      }
    }

    return _VisibleRange(
      firstVisible ?? 0.0,
      lastVisible ?? metric.length,
    );
  }

  Path _parsePath(String pathData) {
    final proxy = _FlutterPathProxy();
    writeSvgPathDataToPath(pathData, proxy);
    return proxy.path;
  }
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
