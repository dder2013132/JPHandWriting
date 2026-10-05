import 'dart:ui';

/// SVG에서 하나의 논리적 획을 구성하는 개별 경로와 표시 영역이다.
class KanaStrokeSegment {
  final Path path;
  final PathMetric metric;
  final double startOffset;
  final double endOffset;

  KanaStrokeSegment({
    required this.path,
    required this.metric,
    required this.startOffset,
    required this.endOffset,
  });
}

/// 번호 하나로 취급하고 한 중심선에서만 재생되는 한 획이다.
class KanaReferenceStroke {
  final int order;
  final KanaStrokeSegment segment;
  final Offset labelOffset;
  final double markerOffset;

  KanaReferenceStroke({
    required this.order,
    required this.segment,
    this.labelOffset = Offset.zero,
    this.markerOffset = 0,
  });
}

class KanaStrokeOrderGuide {
  final String character;
  final Size sourceSize;
  final List<KanaReferenceStroke> strokes;
  final double visualScale;
  final double labelScale;

  const KanaStrokeOrderGuide({
    required this.character,
    required this.strokes,
    this.sourceSize = const Size(1024, 1024),
    this.visualScale = 1,
    this.labelScale = 1,
  });
}
