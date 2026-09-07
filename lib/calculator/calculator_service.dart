class CalculatorService {
  static double? calculate(String expression) {
    try {
      final cleaned = expression
          .replaceAll(' ', '')
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      if (cleaned.isEmpty) {
        return null;
      }

      final match = RegExp(
        r'^(-?\d+(?:\.\d+)?)([+\-*/])(-?\d+(?:\.\d+)?)$',
      ).firstMatch(cleaned);

      if (match == null) {
        return null;
      }

      final first = double.parse(match.group(1)!);
      final operator = match.group(2)!;
      final second = double.parse(match.group(3)!);

      switch (operator) {
        case '+':
          return first + second;

        case '-':
          return first - second;

        case '*':
          return first * second;

        case '/':
          if (second == 0) {
            return null;
          }
          return first / second;

        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  static String formatResult(double result) {
    if (result == result.roundToDouble()) {
      return result.toInt().toString();
    }

    return result.toString();
  }
}