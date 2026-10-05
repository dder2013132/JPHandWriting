import '../models/drawing_stroke.dart';

/// 필기 인식 엔진이 반환한 문자 후보 하나다.
class HandwritingCandidate {
  final String text;
  final double? score;

  const HandwritingCandidate({
    required this.text,
    this.score,
  });
}

/// 인식 엔진의 후보 목록이다. 앞에 있을수록 우선순위가 높다.
class HandwritingRecognitionResult {
  final List<HandwritingCandidate> candidates;

  HandwritingRecognitionResult({
    required Iterable<HandwritingCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  String? get bestCandidate =>
      candidates.isEmpty ? null : candidates.first.text;

  bool containsCandidate(
    String expected, {
    int? withinTop,
  }) {
    if (withinTop != null && withinTop <= 0) {
      return false;
    }

    final candidateLimit = withinTop == null
        ? candidates.length
        : withinTop.clamp(0, candidates.length);

    return candidates
        .take(candidateLimit)
        .any((candidate) => candidate.text == expected);
  }
}

/// 퀴즈 화면과 실제 인식 구현체 사이의 계약이다.
abstract interface class HandwritingRecognizer {
  Future<void> prepare();

  Future<HandwritingRecognitionResult> recognize({
    required List<DrawingStroke> strokes,
  });

  Future<void> close();
}
