enum QuizKanaType {
  hiragana,
  katakana,
}

enum QuizCategory {
  basic,
  dakuten,
  handakuten,
  youon,
}

class QuizSettings {
  final QuizKanaType kanaType;
  final QuizCategory category;
  final int questionCount;

  const QuizSettings({
    required this.kanaType,
    required this.category,
    required this.questionCount,
  });
}
