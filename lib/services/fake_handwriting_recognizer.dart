import 'dart:async';

import '../models/drawing_stroke.dart';
import 'handwriting_recognizer.dart';

/// 실제 플랫폼 인식기 없이 제출 흐름을 검증하기 위한 테스트 구현체다.
class FakeHandwritingRecognizer implements HandwritingRecognizer {
  final HandwritingRecognitionResult result;
  final Duration delay;
  final Object? error;

  int callCount = 0;
  List<DrawingStroke>? lastStrokes;
  bool isPrepared = false;
  bool isClosed = false;

  FakeHandwritingRecognizer({
    required Iterable<HandwritingCandidate> candidates,
    this.delay = Duration.zero,
    this.error,
  }) : result = HandwritingRecognitionResult(candidates: candidates);

  @override
  Future<void> prepare() async {
    isPrepared = true;
  }

  @override
  Future<HandwritingRecognitionResult> recognize({
    required List<DrawingStroke> strokes,
  }) async {
    await prepare();
    callCount++;
    lastStrokes = List.unmodifiable(strokes);

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (error != null) {
      throw error!;
    }

    return result;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}
