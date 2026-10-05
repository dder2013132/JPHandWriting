import 'dart:math';

import 'package:flutter/material.dart';

import '../data/kana_data.dart';
import '../data/kana_stroke_order_assets.dart';
import '../models/drawing_stroke.dart';
import '../models/kana.dart';
import '../models/quiz_settings.dart';
import '../services/handwriting_recognizer.dart';
import '../services/ml_kit_handwriting_recognizer.dart';
import '../widgets/drawing_canvas.dart';

class QuizScreen extends StatefulWidget {
  final QuizSettings settings;
  final HandwritingRecognizer? recognizer;

  const QuizScreen({
    super.key,
    required this.settings,
    this.recognizer,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<DrawingStroke> strokes = [];
  late final List<Kana> questions;
  late final List<_QuizAttempt?> attempts;
  late final HandwritingRecognizer _recognizer;
  late final bool _ownsRecognizer;

  int currentIndex = 0;
  int strokeOrderPlaybackRequest = 0;
  bool showAnswer = false;
  bool showGuide = false;
  bool isChecking = false;
  bool isPreparingModel = true;
  bool? isCorrect;
  Object? modelError;
  HandwritingRecognitionResult? recognitionResult;
  String? selectedRecognition;

  Kana get currentQuestion => questions[currentIndex];

  @override
  void initState() {
    super.initState();
    final candidates = List<Kana>.of(_quizCandidates())..shuffle(Random());
    questions = candidates
        .take(min(widget.settings.questionCount, candidates.length))
        .toList(growable: false);
    attempts = List<_QuizAttempt?>.filled(questions.length, null);
    _ownsRecognizer = widget.recognizer == null;
    _recognizer = widget.recognizer ?? MlKitHandwritingRecognizer();
    _prepareRecognizer();
  }

  Future<void> _prepareRecognizer() async {
    setState(() {
      isPreparingModel = true;
      modelError = null;
    });

    try {
      await _recognizer.prepare();
      if (!mounted) {
        return;
      }
      setState(() {
        isPreparingModel = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        isPreparingModel = false;
        modelError = error;
      });
    }
  }

  List<Kana> _quizCandidates() {
    final isHiragana = widget.settings.kanaType == QuizKanaType.hiragana;

    switch (widget.settings.category) {
      case QuizCategory.basic:
        return isHiragana ? hiraganaList : katakanaList;
      case QuizCategory.dakuten:
        return isHiragana ? hiraganaDakutenList : katakanaDakutenList;
      case QuizCategory.handakuten:
        return isHiragana ? hiraganaHandakutenList : katakanaHandakutenList;
      case QuizCategory.youon:
        return isHiragana ? hiraganaYouonList : katakanaYouonList;
    }
  }

  DrawingPoint _point(Offset position) {
    return DrawingPoint(
      position: position,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _startStroke(Offset position) {
    if (showAnswer || isChecking) {
      return;
    }

    setState(() {
      strokes.add(DrawingStroke(points: [_point(position)]));
    });
  }

  void _updateStroke(Offset position) {
    if (showAnswer || isChecking || strokes.isEmpty) {
      return;
    }
    setState(() {
      strokes.last.points.add(_point(position));
    });
  }

  void _clear() {
    setState(strokes.clear);
  }

  void _showHint() {
    setState(() {
      showGuide = true;
    });
  }

  void _playStrokeOrder() {
    setState(() {
      showGuide = true;
      strokeOrderPlaybackRequest++;
    });
  }

  Future<void> _checkAnswer() async {
    if (strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 노트에 글자를 써줘!')),
      );
      return;
    }

    final expected = currentQuestion.character;
    setState(() {
      isChecking = true;
      isCorrect = null;
      recognitionResult = null;
      selectedRecognition = null;
    });

    try {
      final result = await _recognizer.recognize(strokes: strokes);

      if (!mounted || currentQuestion.character != expected) {
        return;
      }

      setState(() {
        final topCandidates = result.candidates.take(5).toList(growable: false);
        recognitionResult = result;
        selectedRecognition =
            topCandidates.isEmpty ? null : topCandidates.first.text;
        isCorrect = selectedRecognition == expected;
        attempts[currentIndex] = _QuizAttempt(
          question: currentQuestion,
          candidates: topCandidates,
          recognizedText: selectedRecognition,
          isCorrect: isCorrect!,
        );
        isChecking = false;
        showAnswer = true;
        showGuide = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isChecking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('필기를 인식하지 못했어. 다시 시도해줘! ($error)')),
      );
    }
  }

  void _selectRecognitionCandidate(HandwritingCandidate candidate) {
    if (!showAnswer) {
      return;
    }

    final topCandidates =
        recognitionResult?.candidates.take(5).toList(growable: false) ??
            const <HandwritingCandidate>[];

    setState(() {
      selectedRecognition = candidate.text;
      isCorrect = candidate.text == currentQuestion.character;
      attempts[currentIndex] = _QuizAttempt(
        question: currentQuestion,
        candidates: topCandidates,
        recognizedText: selectedRecognition,
        isCorrect: isCorrect!,
      );
    });
  }

  void _retry() {
    setState(() {
      strokes.clear();
      showAnswer = false;
      showGuide = false;
      isCorrect = null;
      recognitionResult = null;
      selectedRecognition = null;
      attempts[currentIndex] = null;
    });
  }

  void _next() {
    if (currentIndex >= questions.length - 1) {
      final completedAttempts = attempts.whereType<_QuizAttempt>().toList();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _QuizResultScreen(
            settings: widget.settings,
            attempts: completedAttempts,
          ),
        ),
      );
      return;
    }

    setState(() {
      currentIndex++;
      strokes.clear();
      showAnswer = false;
      showGuide = false;
      isCorrect = null;
      recognitionResult = null;
      selectedRecognition = null;
    });
  }

  @override
  void dispose() {
    if (_ownsRecognizer) {
      _recognizer.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetPaths =
        KanaStrokeOrderAssets.pathsFor(currentQuestion.character);

    return Scaffold(
      appBar: AppBar(
        title: const Text('필기 퀴즈'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${currentIndex + 1} / ${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF766A57),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showHint,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: const Text('힌트'),
                  ),
                  IconButton(
                    tooltip: '획순 재생',
                    onPressed: _playStrokeOrder,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                  ),
                ],
              ),
              if (isPreparingModel || modelError != null) ...[
                const SizedBox(height: 8),
                _ModelStatusBanner(
                  isPreparing: isPreparingModel,
                  error: modelError,
                  onRetry: _prepareRecognizer,
                ),
              ],
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 220,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7DE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7D6AE)),
                ),
                child: Column(
                  children: [
                    Text(
                      '‘${currentQuestion.korean}’를 써보세요',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3C3426),
                      ),
                    ),
                    if (!showAnswer)
                      const Expanded(
                        child: Center(
                          child: Text(
                            '제출하면 인식 후보 5개가 표시돼요',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9A8D77),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 8),
                      _RecognitionCandidates(
                        candidates: recognitionResult?.candidates
                                .take(5)
                                .toList(growable: false) ??
                            const [],
                        expected: currentQuestion.character,
                        selectedText: selectedRecognition,
                        onSelected: _selectRecognitionCandidate,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentQuestion.character,
                        style: const TextStyle(
                          fontFamily: 'KleeOne',
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCorrect == true
                            ? '정답이에요! 인식 결과: $selectedRecognition'
                            : '오답이에요 · 인식 결과: ${selectedRecognition ?? '없음'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCorrect == true
                              ? const Color(0xFF47824C)
                              : const Color(0xFFB45145),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: DrawingCanvas(
                  key: const ValueKey('quiz-drawing-canvas'),
                  character: currentQuestion.character,
                  showGuide: showGuide,
                  strokes: strokes,
                  strokeOrderAssetPaths: assetPaths,
                  strokeOrderPlaybackRequest: strokeOrderPlaybackRequest,
                  onPanStartPoint: _startStroke,
                  onPanUpdatePoint: _updateStroke,
                ),
              ),
              const SizedBox(height: 12),
              if (!showAnswer)
                Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.cleaning_services_rounded),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isChecking || isPreparingModel || modelError != null
                                ? null
                                : _checkAnswer,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: isChecking
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('제출'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _retry,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: const Text('다시 쓰기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: Text(
                          currentIndex == questions.length - 1 ? '끝내기' : '다음',
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizAttempt {
  final Kana question;
  final List<HandwritingCandidate> candidates;
  final String? recognizedText;
  final bool isCorrect;

  const _QuizAttempt({
    required this.question,
    required this.candidates,
    required this.recognizedText,
    required this.isCorrect,
  });
}

class _RecognitionCandidates extends StatelessWidget {
  final List<HandwritingCandidate> candidates;
  final String expected;
  final String? selectedText;
  final ValueChanged<HandwritingCandidate> onSelected;

  const _RecognitionCandidates({
    required this.candidates,
    required this.expected,
    required this.selectedText,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const Text(
        '인식 후보가 없어요',
        style: TextStyle(fontSize: 13, color: Color(0xFF8C806E)),
      );
    }

    return Column(
      children: [
        const Text(
          '인식 후보',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8C806E),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in candidates.indexed)
              InkWell(
                onTap: () => onSelected(entry.$2),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: entry.$2.text == expected
                        ? const Color(0xFFDDEEDC)
                        : entry.$2.text == selectedText
                            ? const Color(0xFFFFEDC2)
                            : Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      width: entry.$2.text == selectedText ? 2 : 1,
                      color: entry.$2.text == expected
                          ? const Color(0xFF78A77A)
                          : entry.$2.text == selectedText
                              ? const Color(0xFFD29A21)
                              : const Color(0xFFE2D7C2),
                    ),
                  ),
                  child: Text(
                    '${entry.$1 + 1}. ${entry.$2.text}',
                    style: TextStyle(
                      fontFamily: 'KleeOne',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: entry.$2.text == expected
                          ? const Color(0xFF39713E)
                          : const Color(0xFF5F5547),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuizResultScreen extends StatelessWidget {
  final QuizSettings settings;
  final List<_QuizAttempt> attempts;

  const _QuizResultScreen({
    required this.settings,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    final correctCount = attempts.where((attempt) => attempt.isCorrect).length;
    final accuracy =
        attempts.isEmpty ? 0 : ((correctCount / attempts.length) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈 결과'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7DE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7D6AE)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '연습 끝! 수고했어 🎉',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${attempts.length}문제 중 $correctCount개 정답',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5F5547),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '정답률 $accuracy%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB77700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '문제별 결과',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: attempts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final attempt = attempts[index];
                    final candidateText = attempt.candidates.isEmpty
                        ? '없음'
                        : attempt.candidates
                            .map((candidate) => candidate.text)
                            .join(', ');

                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: attempt.isCorrect
                              ? const Color(0xFFDDEEDC)
                              : const Color(0xFFF7DFDA),
                          foregroundColor: attempt.isCorrect
                              ? const Color(0xFF39713E)
                              : const Color(0xFFA3473D),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          '${attempt.question.korean}  →  ${attempt.question.character}',
                          style: const TextStyle(
                            fontFamily: 'KleeOne',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '선택한 인식: ${attempt.recognizedText ?? '없음'}\n'
                          '인식 후보: $candidateText',
                        ),
                        trailing: Icon(
                          attempt.isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: attempt.isCorrect
                              ? const Color(0xFF47824C)
                              : const Color(0xFFB45145),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('퀴즈 메뉴로'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => QuizScreen(settings: settings),
                          ),
                        );
                      },
                      child: const Text('다시 풀기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelStatusBanner extends StatelessWidget {
  final bool isPreparing;
  final Object? error;
  final VoidCallback onRetry;

  const _ModelStatusBanner({
    required this.isPreparing,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7D6AE)),
      ),
      child: Row(
        children: [
          if (isPreparing) ...[
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('일본어 필기 인식 모델을 준비하고 있어요')),
          ] else ...[
            const Icon(Icons.error_outline_rounded, size: 19),
            const SizedBox(width: 8),
            const Expanded(child: Text('인식 모델을 준비하지 못했어요')),
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
