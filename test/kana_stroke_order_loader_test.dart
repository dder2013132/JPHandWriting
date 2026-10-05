import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_handwriting/data/kana_data.dart';
import 'package:japanese_handwriting/data/kana_stroke_order_assets.dart';
import 'package:japanese_handwriting/painters/kana_stroke_order_painter.dart';
import 'package:japanese_handwriting/services/kana_stroke_order_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const loader = KanaStrokeOrderLoader();
  final allPracticeKana = [
    ...hiraganaList,
    ...katakanaList,
    ...hiraganaDakutenList,
    ...katakanaDakutenList,
    ...hiraganaHandakutenList,
    ...katakanaHandakutenList,
    ...hiraganaYouonList,
    ...katakanaYouonList,
  ];

  const cases = {
    'あ': 3,
    'え': 2,
    'お': 3,
    'が': 5,
    'ア': 2,
    'きゃ': 7,
    'キャ': 5,
  };

  for (final entry in cases.entries) {
    test('${entry.key} SVG에서 획을 자동으로 읽는다', () async {
      final guide = await loader.load(
        character: entry.key,
        assetPaths: KanaStrokeOrderAssets.pathsFor(entry.key)!,
      );

      expect(guide.strokes, hasLength(entry.value));
      expect(
        guide.strokes.map((stroke) => stroke.order),
        orderedEquals(
          List<int>.generate(entry.value, (index) => index + 1),
        ),
      );
    });
  }

  test('보조 path가 있는 획도 하나의 중심선으로 재생한다', () async {
    final hiraganaA = await loader.load(
      character: 'あ',
      assetPaths: KanaStrokeOrderAssets.pathsFor('あ')!,
    );
    final hiraganaO = await loader.load(
      character: 'お',
      assetPaths: KanaStrokeOrderAssets.pathsFor('お')!,
    );

    expect(hiraganaA.strokes[2].segment.metric.length, greaterThan(0));
    expect(hiraganaO.strokes[1].segment.metric.length, greaterThan(0));
  });

  test('전체 연습 글자의 자동 배치 획 번호는 서로 겹치지 않는다', () async {
    for (final kana in allPracticeKana) {
      final character = kana.character;
      final guide = await loader.load(
        character: character,
        assetPaths: KanaStrokeOrderAssets.pathsFor(character)!,
      );
      final centers = guide.strokes.map((stroke) {
        final start = stroke.segment.metric
            .getTangentForOffset(stroke.markerOffset)!
            .position;
        return start + stroke.labelOffset;
      }).toList();
      // 요음처럼 좁은 칸에서도 번호 원 자체는 서로 겹치지 않는다.
      final minimumSpacing = 86 * guide.labelScale;

      for (int i = 0; i < centers.length; i++) {
        for (int j = i + 1; j < centers.length; j++) {
          expect(
            (centers[i] - centers[j]).distance,
            greaterThanOrEqualTo(minimumSpacing),
            reason: '$character ${i + 1}번과 ${j + 1}번이 겹치면 안 돼.',
          );
        }
      }
    }
  });

  test('반탁음 마지막 획은 닫힌 원으로 재생한다', () async {
    for (final character in ['ぱ', 'パ']) {
      final guide = await loader.load(
        character: character,
        assetPaths: KanaStrokeOrderAssets.pathsFor(character)!,
      );

      expect(guide.strokes.last.segment.metric.isClosed, isTrue);
    }
  });

  test('획 번호는 현재 재생 중인 획까지만 표시한다', () async {
    final guide = await loader.load(
      character: 'ぱ',
      assetPaths: KanaStrokeOrderAssets.pathsFor('ぱ')!,
    );

    final secondStrokePainter = KanaStrokeOrderLabelsPainter(
      guide: guide,
      activeStrokeIndex: 1,
    );

    expect(secondStrokePainter.visibleStrokeCount, 2);
  });

  test('ぱ의 2번 번호는 2획 시작점 근처에 배치한다', () async {
    final guide = await loader.load(
      character: 'ぱ',
      assetPaths: KanaStrokeOrderAssets.pathsFor('ぱ')!,
    );
    final secondStroke = guide.strokes[1];
    final secondStart = secondStroke.segment.metric
        .getTangentForOffset(secondStroke.markerOffset)!
        .position;
    final secondLabel = secondStart + secondStroke.labelOffset;

    expect(
      (secondLabel - secondStart).distance,
      lessThanOrEqualTo(152 * guide.labelScale),
      reason: '2번이 자기 획 시작점에서 멀어져 1획 옆에 붙으면 안 돼.',
    );
    expect(
      (secondLabel.dx - secondStart.dx).abs(),
      lessThanOrEqualTo(48 * guide.labelScale),
      reason: '2번은 왼쪽 세로획 쪽이 아니라 2획 시작점 위에 있어야 해.',
    );
  });

  test('가타카나 ョ의 세 번호는 위에서 아래 획 순서를 유지한다', () async {
    final yoCombinations =
        katakanaYouonList.where((kana) => kana.character.endsWith('ョ'));

    for (final kana in yoCombinations) {
      final guide = await loader.load(
        character: kana.character,
        assetPaths: KanaStrokeOrderAssets.pathsFor(kana.character)!,
      );
      final yoLabels =
          guide.strokes.skip(guide.strokes.length - 3).map((stroke) {
        final start = stroke.segment.metric
            .getTangentForOffset(stroke.markerOffset)!
            .position;
        return start + stroke.labelOffset;
      }).toList();

      expect(
        yoLabels[0].dy,
        lessThan(yoLabels[1].dy),
        reason: '${kana.character}의 ョ 첫 번호가 둘째 번호보다 위여야 해.',
      );
      expect(
        yoLabels[1].dy,
        lessThan(yoLabels[2].dy),
        reason: '${kana.character}의 ョ 둘째 번호가 셋째 번호보다 위여야 해.',
      );
    }
  });

  test('요음 탁음 번호는 실제 획 시작점의 좌우 순서를 유지한다', () async {
    final guide = await loader.load(
      character: 'びゅ',
      assetPaths: KanaStrokeOrderAssets.pathsFor('びゅ')!,
    );
    final secondStroke = guide.strokes[1];
    final thirdStroke = guide.strokes[2];
    final secondStart = secondStroke.segment.metric
        .getTangentForOffset(secondStroke.markerOffset)!
        .position;
    final thirdStart = thirdStroke.segment.metric
        .getTangentForOffset(thirdStroke.markerOffset)!
        .position;
    final secondLabel = secondStart + secondStroke.labelOffset;
    final thirdLabel = thirdStart + thirdStroke.labelOffset;
    final maximumSideShift = 48 * guide.labelScale;

    expect(thirdStart.dx, greaterThan(secondStart.dx));
    expect(thirdLabel.dx, greaterThan(secondLabel.dx));
    expect(secondLabel.dy, lessThan(secondStart.dy));
    expect(thirdLabel.dy, lessThan(thirdStart.dy));
    expect(
      (secondLabel.dx - secondStart.dx).abs(),
      lessThanOrEqualTo(maximumSideShift),
    );
    expect(
      (thirdLabel.dx - thirdStart.dx).abs(),
      lessThanOrEqualTo(maximumSideShift),
    );
    expect(
      (thirdLabel - secondLabel).distance,
      greaterThanOrEqualTo(118 * guide.labelScale - 0.001),
      reason: '2번과 3번 원 사이에는 눈으로 구분되는 여백이 필요해.',
    );
    expect(
      (thirdLabel.dy - secondLabel.dy).abs(),
      lessThan(140 * guide.labelScale),
      reason: '2번과 3번은 위아래로 멀어지지 않고 한 쌍으로 보여야 해.',
    );
  });
}
