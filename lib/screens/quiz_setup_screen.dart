import 'package:flutter/material.dart';

import '../models/quiz_settings.dart';
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  QuizKanaType kanaType = QuizKanaType.hiragana;
  QuizCategory category = QuizCategory.basic;
  int questionCount = 10;

  void startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          settings: QuizSettings(
            kanaType: kanaType,
            category: category,
            questionCount: questionCount,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('필기 퀴즈'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '어떤 문제를 풀어볼까?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3C3426),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '발음만 보고 가나를 직접 써보는 퀴즈예요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF766A57),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SettingTitle('문자'),
                  const SizedBox(height: 10),
                  SegmentedButton<QuizKanaType>(
                    segments: const [
                      ButtonSegment(
                        value: QuizKanaType.hiragana,
                        label: Text('히라가나'),
                        icon: Text('あ'),
                      ),
                      ButtonSegment(
                        value: QuizKanaType.katakana,
                        label: Text('가타카나'),
                        icon: Text('ア'),
                      ),
                    ],
                    selected: {kanaType},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() {
                        kanaType = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 26),
                  const _SettingTitle('범위'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QuizCategory.values.map((value) {
                      return ChoiceChip(
                        label: Text(_categoryLabel(value)),
                        selected: category == value,
                        onSelected: (_) {
                          setState(() {
                            category = value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),
                  const _SettingTitle('문제 수'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 20].map((value) {
                      return ChoiceChip(
                        label: Text('$value문제'),
                        selected: questionCount == value,
                        onSelected: (_) {
                          setState(() {
                            questionCount = value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: startQuiz,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('퀴즈 시작'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(QuizCategory value) {
    switch (value) {
      case QuizCategory.basic:
        return '기본 문자';
      case QuizCategory.dakuten:
        return '탁음';
      case QuizCategory.handakuten:
        return '반탁음';
      case QuizCategory.youon:
        return '요음';
    }
  }
}

class _SettingTitle extends StatelessWidget {
  final String text;

  const _SettingTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF514737),
      ),
    );
  }
}
