class ExpressionResult {
  const ExpressionResult({
    required this.value,
    required this.isComplete,
    required this.isValid,
  });

  final double? value;
  final bool isComplete;
  final bool isValid;
}

ExpressionResult evaluateExpression(String input, {bool strict = true}) {
  final parser = _ExpressionParser(input);
  final value = parser.parseExpression();
  if (value == null) {
    return const ExpressionResult(
      value: null,
      isComplete: false,
      isValid: false,
    );
  }

  if (strict && !parser.isAtEnd) {
    return const ExpressionResult(
      value: null,
      isComplete: false,
      isValid: false,
    );
  }

  return ExpressionResult(
    value: value,
    isComplete: parser.isAtEnd,
    isValid: true,
  );
}

class _ExpressionParser {
  _ExpressionParser(String input)
    : _chars = input.replaceAll(' ', '').split('');

  final List<String> _chars;
  int _index = 0;

  bool get isAtEnd => _index >= _chars.length;

  double? parseExpression() {
    var value = parseTerm();
    if (value == null) return null;

    while (!isAtEnd) {
      final op = _peek();
      if (op != '+' && op != '-') break;
      _index++;
      final right = parseTerm();
      if (right == null) return null;
      final left = value;
      if (left == null) return null;
      value = op == '+' ? left + right : left - right;
    }
    return value;
  }

  double? parseTerm() {
    var value = parseFactor();
    if (value == null) return null;

    while (!isAtEnd) {
      final op = _peek();
      if (op != '*' && op != '/') break;
      _index++;
      final right = parseFactor();
      if (right == null) return null;
      if (op == '/' && right == 0) return null;
      final left = value;
      if (left == null) return null;
      value = op == '*' ? left * right : left / right;
    }
    return value;
  }

  double? parseFactor() {
    if (isAtEnd) return null;
    if (_peek() == '(') {
      _index++;
      final nested = parseExpression();
      if (nested == null || isAtEnd || _peek() != ')') return null;
      _index++;
      return nested;
    }

    if (_peek() == '+') {
      _index++;
      return parseFactor();
    }
    if (_peek() == '-') {
      _index++;
      final value = parseFactor();
      return value == null ? null : -value;
    }
    return parseNumber();
  }

  double? parseNumber() {
    final start = _index;
    var hasDecimal = false;

    while (!isAtEnd) {
      final c = _peek();
      if (c == '.') {
        if (hasDecimal) break;
        hasDecimal = true;
      } else if (int.tryParse(c) == null) {
        break;
      }
      _index++;
    }

    if (start == _index) return null;
    final number = _chars.sublist(start, _index).join();
    return double.tryParse(number);
  }

  String _peek() => _chars[_index];
}
