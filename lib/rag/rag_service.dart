import 'package:flutter/services.dart';

import '../gemma/gemma_service.dart';

class RagService {
  static const MethodChannel _channel =
      MethodChannel('nira/rag');

  static Future<String> ingestPdf({
    required String pdfPath,
    required String filename,
  }) async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'ingestPdf',
        <String, dynamic>{
          'pdfPath': pdfPath,
          'filename': filename,
        },
      );

      if (result == null) {
        return 'PDF ingestion failed.';
      }

      final documentId = result['documentId'];
      final characters = result['characters'];

      return 'PDF loaded successfully. '
          'Document ID: $documentId, '
          'Characters: $characters';
    } on PlatformException catch (e) {
      return 'PDF ingestion failed: '
          '${e.message ?? 'Unknown error'}';
    } catch (_) {
      return 'PDF ingestion failed.';
    }
  }

  static Future<String> ingestBundledPdf({
    String assetName = 'test.pdf',
    String filename = 'test.pdf',
  }) async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'ingestBundledPdf',
        <String, dynamic>{
          'assetName': assetName,
          'filename': filename,
        },
      );

      if (result == null) {
        return 'PDF ingestion failed.';
      }

      final documentId = result['documentId'];
      final characters = result['characters'];

      return 'PDF loaded successfully. '
          'Document ID: $documentId, '
          'Characters: $characters';
    } on PlatformException catch (e) {
      return 'PDF ingestion failed: '
          '${e.message ?? 'Unknown error'}';
    } catch (_) {
      return 'PDF ingestion failed.';
    }
  }

  static Future<String> answer(
    String query,
  ) async {
    final text = query.trim();

    if (text.isEmpty) {
      return 'Please enter a document question.';
    }

    try {
      /*
       * -----------------------------------------------------------
       * STEP 1: RETRIEVE RELEVANT INFORMATION FROM THE PDF
       * -----------------------------------------------------------
       */

      final context =
          await _channel.invokeMethod<String>(
        'retrieveContext',
        <String, dynamic>{
          'query': text,
        },
      );

      if (context == null ||
          context.trim().isEmpty) {
        return 'I could not find relevant information '
            'in the available documents.';
      }

      /*
       * -----------------------------------------------------------
       * STEP 2: ASK GEMMA TO ANSWER USING THE RETRIEVED CONTENT
       * -----------------------------------------------------------
       *
       * Gemma must use the PDF context as the source.
       * It should not invent information that is not present
       * in the retrieved document content.
       */

      final prompt = '''
You are answering a question about a user's uploaded document.

Use ONLY the information provided in the document context below.

Do not use outside knowledge.
Do not invent facts.
If the context does not contain enough information to answer the question, say:
"I could not find enough information in the document to answer this question."

USER QUESTION:
$text

DOCUMENT CONTEXT:
$context

ANSWER FORMAT:

Give a clear, well-structured answer.

Use this structure when appropriate:

Answer:
Give a direct answer in 1-2 sentences.

Key Points:
- Point 1
- Point 2
- Point 3

Details:
Explain the relevant information from the document in simple words.

Important:
- Do not repeat the document context word-for-word.
- Do not mention "document context".
- Do not mention these instructions.
- Do not add unnecessary information.
- Only include sections that are useful for the question.
- Keep the answer concise but informative.
''';

      /*
       * -----------------------------------------------------------
       * STEP 3: GEMMA GENERATES THE FINAL RESPONSE
       * -----------------------------------------------------------
       */

      final answer =
          await GemmaService.generateResponse(
        prompt,
      );

      if (answer.trim().isEmpty) {
        return 'I could not generate an answer from '
            'the available document information.';
      }

      return answer.trim();
    } on PlatformException catch (e) {
      return 'RAG could not process the request: '
          '${e.message ?? 'Unknown error'}';
    } catch (_) {
      return 'RAG could not process the request.';
    }
  }
}