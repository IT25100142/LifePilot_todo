import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/extensions/string_extensions.dart';

void main() {
  group('StringEmojiSanitizer tests', () {
    test('toCleanText removes standard decorative emojis matched by regex', () {
      expect('🌌 LifePilot'.toCleanText(), ' LifePilot');
      expect('🎛️ Settings'.toCleanText(), ' Settings');
      expect('📱 Device'.toCleanText(), ' Device');
      expect('⚙️ Controls'.toCleanText(), ' Controls');
      expect('🛡️ Guard'.toCleanText(), ' Guard');
      expect('🔓 Unlocked'.toCleanText(), ' Unlocked');
      expect('⚔️ Combat'.toCleanText(), ' Combat');
      expect('💾 Save'.toCleanText(), ' Save');
    });

    test('toCleanText preserves text and handles ranges precisely', () {
      expect('Hello World! 123'.toCleanText(), 'Hello World! 123');
      expect(
        'Rates up to date • Just now'.toCleanText(),
        'Rates up to date • Just now',
      );
      // The symbol ➔ (\u2794) is in the \u2600-\u27BF block, so it gets removed by the regex
      expect(
        'Transfer: Account A ➔ Account B'.toCleanText(),
        'Transfer: Account A  Account B',
      );
      // The symbol 🟢 (\u1F7E2) is not in the specified regex range, so it is preserved
      expect('🟢 Status'.toCleanText(), '🟢 Status');
    });

    test('toCleanText handles empty or plain strings', () {
      expect(''.toCleanText(), '');
      expect('Normal String'.toCleanText(), 'Normal String');
    });
  });
}
