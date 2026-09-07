enum IntentType {
  calculator,
  document,
  general,
}

class IntentRouter {
  static IntentType classify(String query) {
    final text = query.toLowerCase().trim();

    // Calculator-related queries
    if (_isCalculatorQuery(text)) {
      return IntentType.calculator;
    }

    // Document-related queries
    if (_isDocumentQuery(text)) {
      return IntentType.document;
    }

    // Everything else goes to the general AI route
    return IntentType.general;
  }

  static bool _isCalculatorQuery(String text) {
    final calculatorWords = [
      'calculate',
      'calculator',
      'add',
      'subtract',
      'multiply',
      'divide',
      'plus',
      'minus',
      'times',
      'percentage',
      'percent',
      'sum',
    ];

    // Check for mathematical symbols
    final hasMathSymbol =
        text.contains('+') ||
        text.contains('-') ||
        text.contains('*') ||
        text.contains('/') ||
        text.contains('%');

    // Check for calculator keywords
    final hasCalculatorWord = calculatorWords.any(
      (word) => text.contains(word),
    );

    // Check whether the query contains digits
    final hasNumber = RegExp(r'\d').hasMatch(text);

    return hasMathSymbol || (hasCalculatorWord && hasNumber);
  }

  static bool _isDocumentQuery(String text) {
    final documentWords = [
      'document',
      'pdf',
      'file',
      'page',
      'chapter',
      'report',
      'notes',
      'according to',
      'in the document',
      'summarize',
      'summary',
    ];

    return documentWords.any(
      (word) => text.contains(word),
    );
  }
}