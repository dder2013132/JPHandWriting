import 'dart:ui';

/// 한 획 안에서 하나의 shadow 영역을 채우는 SVG 중심선 조각이다.
class KanaSvgStrokeSection {
  final Path path;
  final PathMetric metric;
  final Path clipPath;
  final double visibleStartOffset;
  final double visibleEndOffset;

  KanaSvgStrokeSection({
    required this.path,
    required this.metric,
    required this.clipPath,
    required this.visibleStartOffset,
    required this.visibleEndOffset,
  });
}

/// 번호 하나와 재생 시간 하나를 공유하는 실제 SVG 획이다.
class KanaSvgLogicalStroke {
  static const double revealDistance = 3333;

  final int order;
  final List<KanaSvgStrokeSection> sections;

  const KanaSvgLogicalStroke({
    required this.order,
    required this.sections,
  });

  KanaSvgStrokeSection get primarySection => sections.first;

  /// SVG 중심선 중 실제 글자 윤곽 안에 들어오는 첫 지점이다.
  double get visibleStartOffset {
    return sections.fold<double>(
      revealDistance,
      (start, section) => section.visibleStartOffset < start
          ? section.visibleStartOffset
          : start,
    );
  }

  /// SVG 중심선 중 실제 글자 윤곽 안에 들어오는 마지막 지점이다.
  double get visibleEndOffset {
    return sections.fold<double>(
      0,
      (end, section) =>
          section.visibleEndOffset > end ? section.visibleEndOffset : end,
    );
  }

  double get visibleLength => visibleEndOffset - visibleStartOffset;
}

class KanaSvgStrokeOrderGuide {
  final String character;
  final Size sourceSize;
  final List<KanaSvgLogicalStroke> strokes;

  const KanaSvgStrokeOrderGuide({
    required this.character,
    required this.sourceSize,
    required this.strokes,
  });
}
