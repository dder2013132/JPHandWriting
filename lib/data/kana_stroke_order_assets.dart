abstract final class KanaStrokeOrderAssets {
  static List<String>? pathsFor(String character) {
    if (character.isEmpty) {
      return null;
    }

    return character.runes
        .map(
          (codePoint) =>
              'assets/stroke_order/${codePoint.toRadixString(16)}.svg',
        )
        .toList();
  }
}
