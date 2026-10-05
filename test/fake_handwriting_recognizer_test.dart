import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_handwriting/models/drawing_stroke.dart';
import 'package:japanese_handwriting/services/fake_handwriting_recognizer.dart';
import 'package:japanese_handwriting/services/handwriting_recognizer.dart';

void main() {
  group('HandwritingRecognitionResult', () {
    test('첫 후보와 상위 후보 범위를 구분한다', () {
      final result = HandwritingRecognitionResult(
        candidates: const [
          HandwritingCandidate(text: 'あ', score: 0.92),
          HandwritingCandidate(text: 'お', score: 0.61),
        ],
      );

      expect(result.bestCandidate, 'あ');
      expect(result.containsCandidate('あ', withinTop: 1), isTrue);
      expect(result.containsCandidate('お', withinTop: 1), isFalse);
      expect(result.containsCandidate('お', withinTop: 2), isTrue);
      expect(result.containsCandidate('め'), isFalse);
      expect(result.containsCandidate('あ', withinTop: 0), isFalse);
    });

    test('후보 목록은 외부에서 변경할 수 없다', () {
      final result = HandwritingRecognitionResult(
        candidates: const [HandwritingCandidate(text: 'あ')],
      );

      expect(
        () => result.candidates.add(const HandwritingCandidate(text: 'い')),
        throwsUnsupportedError,
      );
    });
  });

  group('FakeHandwritingRecognizer', () {
    test('설정한 후보를 반환하고 전달받은 획을 기록한다', () async {
      final recognizer = FakeHandwritingRecognizer(
        candidates: const [
          HandwritingCandidate(text: 'あ'),
          HandwritingCandidate(text: 'お'),
        ],
      );
      final strokes = [
        DrawingStroke(
          points: const [
            DrawingPoint(position: Offset(10, 20), timestamp: 100),
            DrawingPoint(position: Offset(30, 40), timestamp: 120),
          ],
        ),
      ];

      final result = await recognizer.recognize(strokes: strokes);

      expect(result.bestCandidate, 'あ');
      expect(recognizer.callCount, 1);
      expect(recognizer.lastStrokes, orderedEquals(strokes));
    });

    test('설정한 오류를 그대로 전달한다', () async {
      final error = StateError('인식 실패');
      final recognizer = FakeHandwritingRecognizer(
        candidates: const [],
        error: error,
      );

      await expectLater(
        recognizer.recognize(strokes: const []),
        throwsA(same(error)),
      );
      expect(recognizer.callCount, 1);
    });
  });
}
