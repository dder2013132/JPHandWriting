import 'dart:ui';

/// SVG에서 얻을 수 없는 화면용 보정값만 관리한다.
/// 획 경로와 획수는 자동 로더가 SVG에서 직접 읽는다.
abstract final class KanaStrokeOrderData {
  static const Map<String, List<Offset>> _labelOffsets = {
    'あ': [
      Offset(-5, -90),
      Offset(-92, -42),
      Offset(108, 28),
    ],
    'ア': [
      Offset(-10, -92),
      Offset(-112, 58),
    ],
    'きゃ': [
      Offset(-120, -120),
      Offset(-120, -100),
      Offset(-125, 55),
      Offset(-125, 45),
      Offset(-120, 100),
      Offset(-120, -95),
      Offset(-125, 40),
    ],
    'キャ': [
      Offset(-120, -105),
      Offset(-125, 80),
      Offset(-130, 50),
      Offset(-120, 95),
      Offset(-120, 55),
    ],
  };

  static Offset? customLabelOffsetFor({
    required String character,
    required int strokeIndex,
  }) {
    final offsets = _labelOffsets[character];

    if (offsets != null && strokeIndex < offsets.length) {
      return offsets[strokeIndex];
    }
    return null;
  }
}
