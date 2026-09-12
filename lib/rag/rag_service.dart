import 'package:flutter/services.dart';

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

  static Future<String> answer(String query) async {
    final text = query.trim();

    if (text.isEmpty) {
      return 'Please enter a document question.';
    }

    try {
      final context =
          await _channel.invokeMethod<String>(
        'retrieveContext',
        <String, dynamic>{
          'query': text,
        },
      );

      if (context == null || context.trim().isEmpty) {
        return 'I could not find relevant information '
            'in the available documents.';
      }

      return context.trim();
    } on PlatformException catch (e) {
      return 'RAG could not process the request: '
          '${e.message ?? 'Unknown error'}';
    } catch (_) {
      return 'RAG could not process the request.';
    }
  }
}