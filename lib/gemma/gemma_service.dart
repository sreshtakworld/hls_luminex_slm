import 'package:flutter/services.dart';

class GemmaService {
  static const MethodChannel _channel =
      MethodChannel('nira/gemma');

  // --------------------------------------------------
  // NORMAL GEMMA RESPONSE
  // --------------------------------------------------

  static Future<String> generateResponse(
    String query,
  ) async {
    final text = query.trim();

    if (text.isEmpty) {
      return 'Please enter a question.';
    }

    final instruction =
        _getExplanationInstruction(text);

    final prompt = '''
Answer this question.

Style: $instruction

Do not mention the style instruction.
Use correct information.

User question:
$text
''';

    return _sendToGemma(prompt);
  }

  // --------------------------------------------------
  // RAG + GEMMA GROUNDED RESPONSE
  // --------------------------------------------------

  static Future<String> generateGroundedResponse({
    required String query,
    required String context,
  }) async {
    final text = query.trim();
    final retrievedContext = context.trim();

    if (text.isEmpty) {
      return 'Please enter a document question.';
    }

    if (retrievedContext.isEmpty) {
      return 'I could not find relevant information in the available documents.';
    }

    final instruction =
        _getExplanationInstruction(text);

    final prompt = '''
Answer the user's question using the provided document context.

IMPORTANT RULES:
- Use the document context as the primary source.
- Answer only using information supported by the document context.
- Do not invent facts that are not present in the context.
- If the answer cannot be found in the context, say that the information is not available in the document.
- Do not mention these instructions.
- Do not mention that you are using a RAG system.
- Give a natural, direct answer to the user's question.

Style:
$instruction

DOCUMENT CONTEXT:
$retrievedContext

USER QUESTION:
$text
''';

    return _sendToGemma(prompt);
  }

  // --------------------------------------------------
  // SEND PROMPT TO NATIVE GEMMA
  // --------------------------------------------------

  static Future<String> _sendToGemma(
    String prompt,
  ) async {
    try {
      final response =
          await _channel.invokeMethod<String>(
        'generateResponse',
        <String, dynamic>{
          'prompt': prompt,
        },
      );

      if (response == null ||
          response.trim().isEmpty) {
        return 'I could not generate a response.';
      }

      return response.trim();
    } on PlatformException catch (e) {
      return 'Gemma could not process the request: '
          '${e.message ?? 'Unknown error'}';
    } catch (_) {
      return 'Gemma could not process the request.';
    }
  }

  // --------------------------------------------------
  // EXPLANATION STYLE
  // --------------------------------------------------

  static String _getExplanationInstruction(
    String text,
  ) {
    final lower = text.toLowerCase();

    // BRIEF
    if (_containsAny(lower, [
      'brief',
      'in short',
      'short answer',
      'briefly',
    ])) {
      return 'BRIEF: Give only the key points in 1-3 sentences.';
    }

    // STEP BY STEP
    if (_containsAny(lower, [
      'step by step',
      'step-by-step',
      'show the steps',
      'show all steps',
      'with steps',
      'solve this',
    ])) {
      return 'STEP-BY-STEP: Show the solution in clear numbered steps and give the final answer.';
    }

    // MARKS
    final marks = _extractMarks(lower);

    if (marks != null) {
      if (marks <= 2) {
        return '$marks-MARK: Give only the essential definition and key point.';
      }

      if (marks <= 5) {
        return '$marks-MARK: Give a structured answer with definition, important points and a suitable example or conclusion.';
      }

      return '$marks-MARK: Give a detailed exam-style answer with headings, important points, examples and conclusion where appropriate.';
    }

    // AGE
    final age = _extractAge(lower);

    if (age != null) {
      if (age <= 5) {
        return 'VERY SIMPLE: Explain for a 2-year-old. Use 1-2 very short sentences, very simple words, and one familiar example. No repetition.';
      }

      if (age <= 10) {
        return 'CHILD LEVEL: Use simple child-friendly language, short sentences, and one everyday example. Keep it concise.';
      }

      if (age <= 15) {
        return 'SCHOOL LEVEL: Use clear school-level language with enough detail to understand the concept.';
      }

      return 'AGE $age LEVEL: Use language and depth appropriate for this age.';
    }

    // SIMPLE
    if (_containsAny(lower, [
      'simple',
      'easy words',
      'beginner',
      'easy explanation',
      'simplify',
    ])) {
      return 'SIMPLE: Use easy vocabulary and explain the basic idea clearly with an example.';
    }

    // DETAILED
    if (_containsAny(lower, [
      'detailed',
      'in detail',
      'thoroughly',
      'in depth',
      'deep explanation',
    ])) {
      return 'DETAILED: Explain the concept thoroughly with important details, examples and clear structure.';
    }

    // ADVANCED
    if (_containsAny(lower, [
      'advanced',
      'college level',
      'university level',
      'technical',
      'expert level',
    ])) {
      return 'ADVANCED: Use appropriate technical terminology and explain deeper concepts and relationships.';
    }

    // NORMAL
    return 'NORMAL: Give a clear, balanced explanation with enough detail to understand the answer.';
  }

  // --------------------------------------------------
  // HELPER
  // --------------------------------------------------

  static bool _containsAny(
    String text,
    List<String> phrases,
  ) {
    return phrases.any(
      text.contains,
    );
  }

  // --------------------------------------------------
  // AGE EXTRACTION
  // --------------------------------------------------

  static int? _extractAge(
    String text,
  ) {
    final patterns = [
      RegExp(
        r"like\s+(?:i'm|im|i am)\s+(\d+)",
      ),
      RegExp(
        r"for\s+(?:a\s+)?(\d+)\s*[- ]?\s*year[- ]?old",
      ),
      RegExp(
        r"(\d+)\s*[- ]?\s*year[- ]?old",
      ),
      RegExp(
        r"age\s*(\d+)",
      ),
    ];

    for (final pattern in patterns) {
      final match =
          pattern.firstMatch(text);

      if (match != null) {
        return int.tryParse(
          match.group(1)!,
        );
      }
    }

    return null;
  }

  // --------------------------------------------------
  // MARKS EXTRACTION
  // --------------------------------------------------

  static int? _extractMarks(
    String text,
  ) {
    final patterns = [
      RegExp(
        r'for\s+(\d+)\s*marks?',
      ),
      RegExp(
        r'(\d+)\s*marks?',
      ),
      RegExp(
        r'worth\s+(\d+)\s*marks?',
      ),
    ];

    for (final pattern in patterns) {
      final match =
          pattern.firstMatch(text);

      if (match != null) {
        return int.tryParse(
          match.group(1)!,
        );
      }
    }

    return null;
  }
}