class CalculatorService {
  static double? calculate(String expression) {
    try {
      final cleaned = expression
          .replaceAll(' ', '')
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-');

      if (cleaned.isEmpty) {
        return null;
      }

      final tokens = _tokenize(cleaned);

      if (tokens.isEmpty) {
        return null;
      }

      final postfix = _toPostfix(tokens);

      return _evaluatePostfix(postfix);
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

  static List<String> _tokenize(String expression) {
    final tokens = <String>[];

    final regex = RegExp(
      r'\d+(?:\.\d+)?|[+\-*/()]',
    );

    for (final match in regex.allMatches(expression)) {
      tokens.add(match.group(0)!);
    }

    return tokens;
  }

  static List<String> _toPostfix(List<String> tokens) {
    final output = <String>[];
    final operators = <String>[];

    final precedence = {
      '+': 1,
      '-': 1,
      '*': 2,
      '/': 2,
    };

    for (final token in tokens) {
      if (double.tryParse(token) != null) {
        output.add(token);
      } else if (token == '(') {
        operators.add(token);
      } else if (token == ')') {
        while (operators.isNotEmpty &&
            operators.last != '(') {
          output.add(operators.removeLast());
        }

        if (operators.isEmpty) {
          throw Exception('Invalid parentheses');
        }

        operators.removeLast();
      } else {
        while (operators.isNotEmpty &&
            operators.last != '(' &&
            precedence[operators.last]! >= precedence[token]!) {
          output.add(operators.removeLast());
        }

        operators.add(token);
      }
    }

    while (operators.isNotEmpty) {
      if (operators.last == '(') {
        throw Exception('Invalid parentheses');
      }

      output.add(operators.removeLast());
    }

    return output;
  }

  static double _evaluatePostfix(List<String> tokens) {
    final stack = <double>[];

    for (final token in tokens) {
      final number = double.tryParse(token);

      if (number != null) {
        stack.add(number);
        continue;
      }

      if (stack.length < 2) {
        throw Exception('Invalid expression');
      }

      final second = stack.removeLast();
      final first = stack.removeLast();

      double result;

      switch (token) {
        case '+':
          result = first + second;
          break;

        case '-':
          result = first - second;
          break;

        case '*':
          result = first * second;
          break;

        case '/':
          if (second == 0) {
            throw Exception('Cannot divide by zero');
          }

          result = first / second;
          break;

        default:
          throw Exception('Unknown operator');
      }

      stack.add(result);
    }

    if (stack.length != 1) {
      throw Exception('Invalid expression');
    }

    return stack.single;
  }
}