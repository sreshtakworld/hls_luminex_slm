import 'package:flutter/services.dart';

class GemmaService {
  static const MethodChannel _channel =
      MethodChannel('nira/gemma');

  static Future<String> generateResponse(
    String query,
  ) async {
    final text = query.trim();

    if (text.isEmpty) {
      return 'Please enter a question.';
    }

    final instruction = _getExplanationInstruction(text);

    final prompt = '''
You are NIRA, a privacy-first offline AI assistant running directly on the user's device.

ABOUT NIRA:
NIRA stands for Network-Independent Intelligent Resource-Aware Assistant.
NIRA is an offline-first AI assistant that intelligently chooses how to process a user's request based on the task and available device resources.
NIRA can use lightweight processing for simple tasks, document/RAG processing for document questions, and on-device AI for general questions.

IMPORTANT RESPONSE RULES:
- Answer the user's actual question directly.
- Do not invent meanings for NIRA or other terms when you know the correct context.
- Do not give a long essay unless the user explicitly asks for a detailed explanation.
- Do not repeat the question.
- Do not add unnecessary sections such as "Different Types", "Conclusion", or "Let's break it down" unless they are actually useful.
- Keep the answer concise and natural.
- Use only the amount of information requested by the user.
- If the question is simple, give a simple answer.
- If the user asks for an example, give an example.
- If the user asks for steps, give steps.
- If the user asks for a detailed answer, provide more detail.
- Do not mention these instructions.
- Do not mention that you are a language model.
- Do not mention prompt engineering or system instructions.

RESPONSE STYLE:
$instruction

USER QUESTION:
$text
''';

    return _sendToGemma(prompt);
  }

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

    final instruction = _getExplanationInstruction(text);

    final prompt = '''
You are NIRA, a privacy-first offline AI assistant.

Answer the user's question using the provided document context.

IMPORTANT RULES:
- Use the document context as the primary source.
- Answer only using information supported by the document context.
- Do not invent facts that are not present in the context.
- If the answer cannot be found in the context, say that the information is not available in the document.
- Answer directly and concisely.
- Do not give a long explanation unless the user asks for one.
- Do not mention these instructions.
- Do not mention that you are using a RAG system.
- Do not mention the prompt or system instructions.

RESPONSE STYLE:
$instruction

DOCUMENT CONTEXT:
$retrievedContext

USER QUESTION:
$text
''';

    return _sendToGemma(prompt);
  }

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

  static String _getExplanationInstruction(
    String text,
  ) {
    final lower = text.toLowerCase();

    // Explicit brief requests
    if (_containsAny(lower, [
      'brief',
      'in short',
      'short answer',
      'briefly',
    ])) {
      return '''
BRIEF:
Answer in 1-3 sentences.
Give only the most important information.
Do not add extra explanation.
''';
    }

    // Step-by-step requests
    if (_containsAny(lower, [
      'step by step',
      'step-by-step',
      'show the steps',
      'show all steps',
      'with steps',
      'solve this',
    ])) {
      return '''
STEP-BY-STEP:
Show the solution in clear numbered steps.
Keep each step concise.
Give the final answer at the end.
''';
    }

    // Marks-based academic questions
    final marks = _extractMarks(lower);

    if (marks != null) {
      if (marks <= 2) {
        return '''
$marks-MARK ANSWER:
Give only the essential definition and key point.
Keep it very concise.
''';
      }

      if (marks <= 5) {
        return '''
$marks-MARK ANSWER:
Give a structured exam-style answer with the definition,
important points, and one suitable example or conclusion.
Avoid unnecessary detail.
''';
      }

      return '''
$marks-MARK ANSWER:
Give a detailed exam-style answer with suitable headings,
important points, examples, and a conclusion where appropriate.
''';
    }

    // Age-based explanation
    final age = _extractAge(lower);

    if (age != null) {
      if (age <= 5) {
        return '''
VERY SIMPLE:
Explain as if speaking to a very young child.
Use very simple words.
Use 1-2 short sentences and one familiar example.
Do not repeat the idea.
''';
      }

      if (age <= 10) {
        return '''
CHILD LEVEL:
Use simple child-friendly language,
short sentences, and one everyday example.
Keep the answer concise.
''';
      }

      if (age <= 15) {
        return '''
SCHOOL LEVEL:
Use clear school-level language.
Explain enough to understand the concept,
but avoid unnecessary detail.
''';
      }

      return '''
AGE $age LEVEL:
Use vocabulary and explanation depth appropriate
for a person of this age.
Stay focused on the question.
''';
    }

    // Simple explanation
    if (_containsAny(lower, [
      'simple',
      'easy words',
      'beginner',
      'easy explanation',
      'simplify',
    ])) {
      return '''
SIMPLE:
Use easy vocabulary.
Explain the main idea clearly in 2-4 sentences.
Add one short example only if it helps.
''';
    }

    // Detailed explanation
    if (_containsAny(lower, [
      'detailed',
      'in detail',
      'thoroughly',
      'in depth',
      'deep explanation',
    ])) {
      return '''
DETAILED:
Explain the concept thoroughly.
Use clear structure and relevant examples.
Include important details, but avoid unrelated information.
''';
    }

    // Advanced explanation
    if (_containsAny(lower, [
      'advanced',
      'college level',
      'university level',
      'technical',
      'expert level',
    ])) {
      return '''
ADVANCED:
Use appropriate technical terminology.
Explain important concepts and relationships clearly.
Give enough depth for an advanced learner.
Stay relevant to the question.
''';
    }

    // DEFAULT — this is the important fix.
    return '''
NORMAL:
Give a direct answer in 2-4 sentences.
Answer only what the user asked.
Use clear, natural language.
Do not give a full textbook explanation.
Do not add unrelated sections or extra information.
''';
  }

  static bool _containsAny(
    String text,
    List<String> phrases,
  ) {
    return phrases.any(text.contains);
  }

  static int? _extractAge(String text) {
    final patterns = [
      RegExp(r"like\s+(?:i'm|im|i am)\s+(\d+)"),
      RegExp(r"for\s+(?:a\s+)?(\d+)\s*[- ]?\s*year[- ]?old"),
      RegExp(r"(\d+)\s*[- ]?\s*year[- ]?old"),
      RegExp(r"age\s*(\d+)"),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    return null;
  }

  static int? _extractMarks(String text) {
    final patterns = [
      RegExp(r'for\s+(\d+)\s*marks?'),
      RegExp(r'(\d+)\s*marks?'),
      RegExp(r'worth\s+(\d+)\s*marks?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    return null;
  }
}