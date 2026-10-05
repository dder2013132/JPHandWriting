import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_handwriting/models/quiz_settings.dart';
import 'package:japanese_handwriting/screens/quiz_screen.dart';
import 'package:japanese_handwriting/services/fake_handwriting_recognizer.dart';
import 'package:japanese_handwriting/services/handwriting_recognizer.dart';

void main() {
  testWidgets('주입한 가짜 인식기의 오답 결과를 퀴즈 화면에 표시한다', (tester) async {
    final recognizer = FakeHandwritingRecognizer(
      candidates: const [HandwritingCandidate(text: '?')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          settings: const QuizSettings(
            kanaType: QuizKanaType.hiragana,
            category: QuizCategory.handakuten,
            questionCount: 1,
          ),
          recognizer: recognizer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final canvasSizeBeforeSubmit = tester.getSize(
      find.byKey(const ValueKey('quiz-drawing-canvas')),
    );

    await tester.drag(
      find.byKey(const ValueKey('quiz-drawing-canvas')),
      const Offset(40, 40),
    );
    await tester.tap(find.text('제출'));
    await tester.pumpAndSettle();

    expect(find.textContaining('오답이에요'), findsOneWidget);
    expect(find.text('1. ?'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('quiz-drawing-canvas'))),
      canvasSizeBeforeSubmit,
    );
    expect(recognizer.callCount, 1);
  });

  testWidgets('후보를 터치하면 인식 결과와 최종 채점을 보정한다', (tester) async {
    const candidateCharacters = ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'];
    final recognizer = FakeHandwritingRecognizer(
      candidates: const [
        HandwritingCandidate(text: 'ぱ'),
        HandwritingCandidate(text: 'ぴ'),
        HandwritingCandidate(text: 'ぷ'),
        HandwritingCandidate(text: 'ぺ'),
        HandwritingCandidate(text: 'ぽ'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          settings: const QuizSettings(
            kanaType: QuizKanaType.hiragana,
            category: QuizCategory.handakuten,
            questionCount: 1,
          ),
          recognizer: recognizer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('quiz-drawing-canvas')),
      const Offset(40, 40),
    );
    await tester.tap(find.text('제출'));
    await tester.pumpAndSettle();

    expect(find.text('인식 후보'), findsOneWidget);
    expect(find.text('5. ぽ'), findsOneWidget);

    final expected = candidateCharacters.singleWhere(
      (character) => find.text(character).evaluate().isNotEmpty,
    );
    final wrongCandidate = candidateCharacters.firstWhere(
      (character) => character != expected,
    );

    await tester.tap(
      find.text(
          '${candidateCharacters.indexOf(wrongCandidate) + 1}. $wrongCandidate'),
    );
    await tester.pump();
    expect(find.textContaining('오답이에요'), findsOneWidget);

    await tester.tap(
      find.text('${candidateCharacters.indexOf(expected) + 1}. $expected'),
    );
    await tester.pump();
    expect(find.text('정답이에요! 인식 결과: $expected'), findsOneWidget);

    await tester.tap(find.text('끝내기'));
    await tester.pumpAndSettle();

    expect(find.text('퀴즈 결과'), findsOneWidget);
    expect(find.text('1문제 중 1개 정답'), findsOneWidget);
    expect(find.text('정답률 100%'), findsOneWidget);
    expect(find.textContaining('선택한 인식: $expected'), findsOneWidget);
  });
}
