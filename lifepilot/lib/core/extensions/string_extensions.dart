extension StringEmojiSanitizer on String {
  String toCleanText() {
    return replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{27BF}\u{E000}-\u{F8FF}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}]',
        unicode: true,
      ),
      '',
    );
  }
}
