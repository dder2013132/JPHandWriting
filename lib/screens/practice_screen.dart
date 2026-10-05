import 'dart:math';

import 'package:flutter/material.dart';

import '../data/kana_data.dart';
import '../data/kana_stroke_order_assets.dart';
import '../models/drawing_stroke.dart';
import '../models/kana.dart';
import '../widgets/mode_controls.dart';
import '../widgets/character_card.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/bottom_controls.dart';

enum PracticeCategory {
  basic,
  dakuten,
  handakuten,
  youon,
}

class PracticeScreen extends StatefulWidget {
  final bool initialHiragana;
  final PracticeCategory category;

  const PracticeScreen({
    super.key,
    this.initialHiragana = true,
    this.category = PracticeCategory.basic,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class PracticeHistory {
  final int index;

  const PracticeHistory({
    required this.index,
  });
}

class _PracticeScreenState extends State<PracticeScreen> {
  final List<DrawingStroke> strokes = [];

  bool get isHiragana => widget.initialHiragana;

  List<Kana> get characters {
    switch (widget.category) {
      case PracticeCategory.basic:
        return isHiragana ? hiraganaList : katakanaList;

      case PracticeCategory.dakuten:
        return isHiragana ? hiraganaDakutenList : katakanaDakutenList;

      case PracticeCategory.handakuten:
        return isHiragana ? hiraganaHandakutenList : katakanaHandakutenList;

      case PracticeCategory.youon:
        return isHiragana ? hiraganaYouonList : katakanaYouonList;
    }
  }

  int currentIndex = 0;
  bool showGuide = true;
  bool showCharacter = true;
  bool randomMode = false;
  bool historyMode = true;
  static const int maxHistory = 100;
  final Random random = Random();
  final List<PracticeHistory> history = [];
  int historyPosition = -1;
  int strokeOrderPlaybackRequest = 0;

  @override
  void initState() {
    super.initState();

    history.add(
      PracticeHistory(
        index: currentIndex,
      ),
    );

    historyPosition = 0;
  }

  void clearCanvas() {
    setState(() {
      strokes.clear();
    });
  }

  DrawingPoint createDrawingPoint(Offset position) {
    return DrawingPoint(
      position: position,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void startStroke(Offset position) {
    setState(() {
      // 드래그 시작마다 새 객체를 만들기 때문에 null 없이도 획 경계가 보존된다.
      strokes.add(
        DrawingStroke(
          points: [createDrawingPoint(position)],
        ),
      );
    });
  }

  void updateStroke(Offset position) {
    setState(() {
      if (strokes.isEmpty) {
        return;
      }

      strokes.last.points.add(createDrawingPoint(position));
    });
  }

  void previousCharacter() {
    setState(() {
      if (historyPosition > 0) {
        historyPosition--;
        applyHistoryState(history[historyPosition]);
      } else {
        // 히스토리 시작점 이전으로는 가지 않음
        strokes.clear();
      }
    });
  }

  void saveCurrentState() {
    history.add(
      PracticeHistory(
        index: currentIndex,
      ),
    );

    if (history.length > maxHistory) {
      history.removeAt(0);
    }

    historyPosition = history.length - 1;
  }

  void applyHistoryState(PracticeHistory item) {
    currentIndex = item.index;
    strokes.clear();
  }

  void removeFutureHistory() {
    if (historyPosition < history.length - 1) {
      history.removeRange(
        historyPosition + 1,
        history.length,
      );
    }
  }

  void nextCharacter() {
    setState(() {
      // 기록모드 ON:
      // 미래 기록이 남아 있다면 먼저 기존 기록을 읽는다.
      if (historyMode &&
          historyPosition >= 0 &&
          historyPosition < history.length - 1) {
        historyPosition++;
        applyHistoryState(history[historyPosition]);
        return;
      }

      // 기록모드 OFF:
      // 현재 위치 뒤의 미래 기록을 전부 삭제한다.
      if (!historyMode) {
        removeFutureHistory();
      }

      // 여기까지 왔다는 것은
      // 새 문자를 만들어야 한다는 뜻.

      if (randomMode) {
        int nextIndex;

        do {
          nextIndex = random.nextInt(characters.length);
        } while (nextIndex == currentIndex && characters.length > 1);

        currentIndex = nextIndex;
      } else {
        currentIndex++;

        if (currentIndex >= characters.length) {
          currentIndex = 0;
        }
      }

      saveCurrentState();
      strokes.clear();
    });
  }

  void _showCharacterPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '글자 선택',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == currentIndex;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (!historyMode) {
                              removeFutureHistory();
                            }

                            currentIndex = index;

                            saveCurrentState();
                            strokes.clear();
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15)
                                : Colors.grey.withOpacity(0.1),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                characters[index].character,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontFamily: 'KleeOne',
                                  fontSize:
                                      characters[index].character.length > 1
                                          ? 20
                                          : 24,
                                  height: 1,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get practiceTitle {
    final kanaName = isHiragana ? '히라가나' : '가타카나';

    switch (widget.category) {
      case PracticeCategory.basic:
        return '$kanaName 연습';

      case PracticeCategory.dakuten:
        return '$kanaName 탁음 연습';

      case PracticeCategory.handakuten:
        return '$kanaName 반탁음 연습';

      case PracticeCategory.youon:
        return '$kanaName 요음 연습';
    }
  }

  List<String>? get strokeOrderAssetPaths {
    return KanaStrokeOrderAssets.pathsFor(characters[currentIndex].character);
  }

  void playStrokeOrder() {
    setState(() {
      showGuide = true;
      strokeOrderPlaybackRequest++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          practiceTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ModeControls(
              randomMode: randomMode,
              historyMode: historyMode,
              showCharacter: showCharacter,
              showGuide: showGuide,
              onRandomToggle: () {
                setState(() {
                  randomMode = !randomMode;
                });
              },
              onHistoryToggle: () {
                setState(() {
                  historyMode = !historyMode;
                });
              },
              onCharacterToggle: () {
                setState(() {
                  showCharacter = !showCharacter;
                });
              },
              onGuideToggle: () {
                setState(() {
                  showGuide = !showGuide;
                });
              },
              onStrokeOrderPlay: playStrokeOrder,
            ),
            const SizedBox(height: 18),
            CharacterCard(
              character: characters[currentIndex].character,
              korean: characters[currentIndex].korean,
              showCharacter: showCharacter,
              onTap: _showCharacterPicker,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: DrawingCanvas(
                character: characters[currentIndex].character,
                showGuide: showGuide,
                strokes: strokes,
                strokeOrderAssetPaths: strokeOrderAssetPaths,
                strokeOrderPlaybackRequest: strokeOrderPlaybackRequest,
                onPanStartPoint: startStroke,
                onPanUpdatePoint: updateStroke,
              ),
            ),
            const SizedBox(height: 10),
            BottomControls(
              currentIndex: currentIndex,
              totalCount: characters.length,
              onPrevious: previousCharacter,
              onClear: clearCanvas,
              onNext: nextCharacter,
            ),
          ],
        ),
      ),
    );
  }
}
