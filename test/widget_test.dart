// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:japanese_handwriting/main.dart';

void main() {
  testWidgets('App start smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JapanesePracticeApp());

    // Verify that our app's title is present.
    expect(find.text('일본어 필기 연습 ✍️'), findsOneWidget);
  });

  testWidgets('필기 퀴즈 설정과 문제 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(const JapanesePracticeApp());

    await tester.tap(find.text('필기 퀴즈'));
    await tester.pumpAndSettle();

    expect(find.text('어떤 문제를 풀어볼까?'), findsOneWidget);
    expect(find.text('퀴즈 시작'), findsOneWidget);

    await tester.tap(find.text('퀴즈 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('써보세요'), findsOneWidget);
    expect(find.text('제출'), findsOneWidget);
  });
}
