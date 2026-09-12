enum IntentType {
  calculator,
  document,
  general,
}

class IntentRouter {
  static IntentType classify(String query) {
    final text = query.trim();
    final lower = text.toLowerCase();

    // ------------------------------------------------------------
    // DOCUMENT / RAG
    // ------------------------------------------------------------

    if (_containsAny(lower, [
      'document',
      'pdf',
      'file',
      'chapter',
      'page',
      'report',
      'notes',
      'according to',
      'in the document',
      'from the document',
      'from the pdf',
      'summarize',
      'summary',
    ])) {
      return IntentType.document;
    }

    // ------------------------------------------------------------
    // MATHEMATICS
    // ------------------------------------------------------------

    if (_isMathQuestion(lower)) {
      return IntentType.calculator;
    }

    // ------------------------------------------------------------
    // GENERAL AI
    // ------------------------------------------------------------

    return IntentType.general;
  }

  static bool _isMathQuestion(
    String text,
  ) {
    // Calculus
    if (_containsAny(text, [
      'differentiate',
      'derivative',
      'dy/dx',
      'd/dx',
      'integrate',
      'integration',
      'integral',
      '∫',
    ])) {
      return true;
    }

    // Algebra / equations
    if (_containsAny(text, [
      'solve',
      'equation',
      'simplify',
      'find x',
    ]) &&
        text.contains('=')) {
      return true;
    }

    // Direct arithmetic expression
    final expression = text
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(',', '')
        .trim();

    final arithmeticPattern = RegExp(
      r'^[-+]?\d+(?:\.\d+)?\s*'
      r'[+\-*/]\s*'
      r'[-+]?\d+(?:\.\d+)?$',
    );

    if (arithmeticPattern.hasMatch(expression)) {
      return true;
    }

    // Mathematical functions / expressions
    if (RegExp(
      r'\b(sin|cos|tan|log|ln|sqrt)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return true;
    }

    return false;
  }

  static bool _containsAny(
    String text,
    List<String> phrases,
  ) {
    return phrases.any(text.contains);
  }
}