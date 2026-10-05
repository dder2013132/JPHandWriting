import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_handwriting/data/kana_data.dart';
import 'package:japanese_handwriting/data/kana_stroke_order_assets.dart';
import 'package:japanese_handwriting/services/kana_stroke_order_loader.dart';
import 'package:japanese_handwriting/services/kana_svg_stroke_order_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const svgLoader = KanaSvgStrokeOrderLoader();
  const legacyLoader = KanaStrokeOrderLoader();

  const referenceCases = {
    'あ': 3,
    'が': 5,
    'ぱ': 4,
    'きゃ': 7,
    'ぎゃ': 9,
    'ぴゃ': 5,
  };

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

  test('연습 데이터 208개를 모두 SVG 원형 획으로 읽는다', () async {
    expect(allPracticeKana, hasLength(208));

    for (final kana in allPracticeKana) {
      final assetPaths = KanaStrokeOrderAssets.pathsFor(kana.character)!;
      final svgGuide = await svgLoader.load(
        character: kana.character,
        assetPaths: assetPaths,
      );
      final legacyGuide = await legacyLoader.load(
        character: kana.character,
        assetPaths: assetPaths,
      );

      expect(
        svgGuide.strokes.length,
        legacyGuide.strokes.length,
        reason: '${kana.character}의 신규·기존 획수가 같아야 해.',
      );

      for (final stroke in svgGuide.strokes) {
        expect(
          stroke.sections,
          isNotEmpty,
          reason: '${kana.character} ${stroke.order}획 경로가 필요해.',
        );
        expect(
          stroke.visibleLength,
          greaterThan(0),
          reason: '${kana.character} ${stroke.order}획 표시 길이가 필요해.',
        );

        for (final section in stroke.sections) {
          expect(
            section.clipPath.getBounds().isEmpty,
            isFalse,
            reason: '${kana.character} ${stroke.order}획 clipPath가 필요해.',
          );
        }
      }
    }
  });

  for (final entry in referenceCases.entries) {
    test('${entry.key} SVG의 논리적 획과 clipPath를 전부 읽는다', () async {
      final assetPaths = KanaStrokeOrderAssets.pathsFor(entry.key)!;
      final svgGuide = await svgLoader.load(
        character: entry.key,
        assetPaths: assetPaths,
      );
      final legacyGuide = await legacyLoader.load(
        character: entry.key,
        assetPaths: assetPaths,
      );

      expect(svgGuide.strokes, hasLength(entry.value));
      expect(svgGuide.strokes.length, legacyGuide.strokes.length);
      expect(
        svgGuide.strokes.map((stroke) => stroke.order),
        orderedEquals(
          List<int>.generate(entry.value, (index) => index + 1),
        ),
      );

      for (final stroke in svgGuide.strokes) {
        expect(stroke.sections, isNotEmpty);
        for (final section in stroke.sections) {
          expect(section.metric.length, greaterThan(0));
          expect(section.clipPath.getBounds().isEmpty, isFalse);
          expect(
            section.visibleEndOffset,
            greaterThanOrEqualTo(section.visibleStartOffset),
          );
        }
        expect(stroke.visibleLength, greaterThan(0));
      }
    });
  }

  test('여러 중심선으로 보강된 あ의 3획도 하나의 획으로 묶는다', () async {
    final guide = await svgLoader.load(
      character: 'あ',
      assetPaths: KanaStrokeOrderAssets.pathsFor('あ')!,
    );

    expect(guide.strokes[2].sections, hasLength(2));
    expect(guide.strokes[2].order, 3);
  });

  test('반탁음 원의 보강 경로도 하나의 논리적 획으로 묶는다', () async {
    final guide = await svgLoader.load(
      character: 'ぱ',
      assetPaths: KanaStrokeOrderAssets.pathsFor('ぱ')!,
    );

    expect(guide.strokes[2].sections, hasLength(2));
    expect(guide.strokes.last.order, 4);
  });
}
