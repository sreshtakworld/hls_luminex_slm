import 'package:advance_math/advance_math.dart';

class MathService {
  // ------------------------------------------------------------
  // MAIN ENTRY POINT
  // ------------------------------------------------------------

  static String? solve(String question) {
    final text = question.trim();

    if (text.isEmpty) {
      return null;
    }

    final lower = text.toLowerCase();

    try {
      // ----------------------------------------------------------
      // DIFFERENTIATION
      // ----------------------------------------------------------

      if (_isDifferentiationQuestion(lower)) {
        return _differentiate(text);
      }

      // ----------------------------------------------------------
      // INTEGRATION
      // ----------------------------------------------------------

      if (_isIntegrationQuestion(lower)) {
        return _integrate(text);
      }

      // ----------------------------------------------------------
      // EQUATION SOLVING
      // ----------------------------------------------------------

      if (_isEquationQuestion(lower)) {
        return _solveEquation(text);
      }

      // ----------------------------------------------------------
      // SIMPLIFICATION
      // ----------------------------------------------------------

      if (_isSimplificationQuestion(lower)) {
        return _simplify(text);
      }

      // ----------------------------------------------------------
      // NORMAL MATHEMATICAL EXPRESSION
      // ----------------------------------------------------------

      if (_looksLikeMathExpression(text)) {
        return _evaluateOrSimplify(text);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  // ============================================================
  // DIFFERENTIATION
  // ============================================================

  static String? _differentiate(String question) {
    final expressionText = _extractExpression(
      question,
      [
        'differentiate',
        'derivative of',
        'derivative',
        'differentiate',
        'find dy/dx of',
        'find derivative of',
      ],
    );

    if (expressionText == null ||
        expressionText.isEmpty) {
      return null;
    }

    final cleaned = _cleanExpression(expressionText);

    final expression = Expression.parse(cleaned);

    final derivative = expression.differentiate();

    return '''
Step 1: Identify the function.

f(x) = $cleaned

Step 2: Differentiate with respect to x.

f'(x) = $derivative

Final Answer:
$derivative
''';
  }

  // ============================================================
  // INTEGRATION
  // ============================================================

  static String? _integrate(String question) {
    var expressionText = _extractExpression(
      question,
      [
        'integrate',
        'integration of',
        'integral of',
      ],
    );

    expressionText ??= question;

    expressionText = expressionText
        .replaceAll('∫', '')
        .replaceAll(RegExp(r'\bdx\b'), '')
        .replaceAll(RegExp(r'\bdy\b'), '')
        .trim();

    final cleaned = _cleanExpression(expressionText);

    if (cleaned.isEmpty) {
      return null;
    }

    final expression = Expression.parse(cleaned);

    final integral =
        SymbolicCalculus.indefiniteIntegral(
      expression,
      'x',
    );

    return '''
Step 1: Identify the function.

f(x) = $cleaned

Step 2: Integrate with respect to x.

∫ $cleaned dx

Step 3: Apply the integration rules.

= $integral + C

Final Answer:
$integral + C
''';
  }

  // ============================================================
  // EQUATION SOLVING
  // ============================================================

  static String? _solveEquation(String question) {
    var equation = question.trim();

    equation = equation
        .replaceFirst(
          RegExp(
            r'^(solve|find\s+the\s+value\s+of|find\s+x)\s*',
            caseSensitive: false,
          ),
          '',
        );

    if (!equation.contains('=')) {
      return null;
    }

    final sides = equation.split('=');

    if (sides.length != 2) {
      return null;
    }

    final leftText = _cleanExpression(sides[0]);
    final rightText = _cleanExpression(sides[1]);

    if (leftText.isEmpty ||
        rightText.isEmpty) {
      return null;
    }

    final left = Expression.parse(leftText);
    final right = Expression.parse(rightText);

    final equationExpression =
        left - right;

    final variableName =
        _findVariableName(equationExpression);

    final variable = Variable(variableName);

    final solutions =
        ExpressionSolver.solve(
      equationExpression,
      variable,
    );

    if (solutions.isEmpty) {
      return '''
No real solution was found.
''';
    }

    return '''
Given equation:

$leftText = $rightText

Step 1: Move everything to one side.

$equationExpression = 0

Step 2: Solve for $variableName.

Solutions:
${solutions.map((solution) => '$variableName = $solution').join('\n')}

Final Answer:
${solutions.map((solution) => '$variableName = $solution').join(', ')}
''';
  }

  // ============================================================
  // SIMPLIFICATION
  // ============================================================

  static String? _simplify(String question) {
    final expressionText = _extractExpression(
      question,
      [
        'simplify',
        'simplify this',
        'simplify the expression',
      ],
    );

    if (expressionText == null ||
        expressionText.isEmpty) {
      return null;
    }

    final cleaned =
        _cleanExpression(expressionText);

    final expression =
        Expression.parse(cleaned);

    final simplified =
        expression.simplify();

    return '''
Given:

$cleaned

Step 1: Simplify the expression.

$cleaned

Step 2: Apply mathematical simplification.

$simplified

Final Answer:

$simplified
''';
  }

  // ============================================================
  // NORMAL MATH EXPRESSION
  // ============================================================

  static String? _evaluateOrSimplify(
    String question,
  ) {
    final cleaned =
        _cleanExpression(question);

    if (cleaned.isEmpty) {
      return null;
    }

    final expression =
        Expression.parse(cleaned);

    final variables =
        expression.getVariables();

    // If variables exist, return simplified symbolic form.
    if (variables.isNotEmpty) {
      return '''
Expression:

$cleaned

Simplified form:

${expression.simplify()}
''';
    }

    final value =
        expression.evaluate();

    return '''
Expression:

$cleaned

Calculation:

$value

Final Answer:

$value
''';
  }

  // ============================================================
  // QUESTION DETECTION
  // ============================================================

  static bool _isDifferentiationQuestion(
    String text,
  ) {
    return text.contains('differentiate') ||
        text.contains('derivative') ||
        text.contains('dy/dx') ||
        text.contains("d/dx");
  }

  static bool _isIntegrationQuestion(
    String text,
  ) {
    return text.contains('integrate') ||
        text.contains('integration') ||
        text.contains('integral') ||
        text.contains('∫');
  }

  static bool _isEquationQuestion(
    String text,
  ) {
    return text.contains('solve') &&
            text.contains('=') ||
        text.contains('find x') &&
            text.contains('=') ||
        text.contains('equation') &&
            text.contains('=');
  }

  static bool _isSimplificationQuestion(
    String text,
  ) {
    return text.contains('simplify');
  }

  static bool _looksLikeMathExpression(
    String text,
  ) {
    final cleaned =
        text.trim();

    if (cleaned.isEmpty) {
      return false;
    }

    // A mathematical expression normally contains
    // operators, numbers, variables, or functions.
    final hasNumber =
        RegExp(r'\d').hasMatch(cleaned);

    final hasOperator =
        RegExp(r'[+\-*/^=()]')
            .hasMatch(cleaned);

    final hasMathFunction =
        RegExp(
          r'\b(sin|cos|tan|log|ln|sqrt)\b',
          caseSensitive: false,
        ).hasMatch(cleaned);

    return hasNumber &&
        (hasOperator || hasMathFunction);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String? _extractExpression(
    String question,
    List<String> prefixes,
  ) {
    var text = question.trim();

    for (final prefix in prefixes) {
      final index =
          text.toLowerCase().indexOf(
                prefix.toLowerCase(),
              );

      if (index != -1) {
        text = text
            .substring(
              index + prefix.length,
            )
            .trim();

        break;
      }
    }

    text = text
        .replaceFirst(
          RegExp(
            r'^(of|the|this|the expression)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static String _cleanExpression(
    String text,
  ) {
    var cleaned = text.trim();

    cleaned = cleaned
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3');

    cleaned = cleaned
        .replaceAll(
          RegExp(
            r'\bplease\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    cleaned = cleaned
        .replaceAll(
          RegExp(
            r'\bfind\s+dy/dx\s+of\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    cleaned = cleaned
        .replaceAll(
          RegExp(
            r'\bdx\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    return cleaned;
  }

  static String _findVariableName(
    Expression expression,
  ) {
    final variables =
        expression.getVariables();

    if (variables.isEmpty) {
      return 'x';
    }

    // Prefer x for normal school/college equations.
    for (final variable in variables) {
      if (variable.identifier.name == 'x') {
        return 'x';
      }
    }

    return variables.first.identifier.name;
  }
}