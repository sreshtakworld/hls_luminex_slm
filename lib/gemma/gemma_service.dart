import 'package:flutter/services.dart';

class GemmaService {
  static const MethodChannel _channel = MethodChannel('nira/device');

  static Future<String> generateResponse(String query) async {
    try {
      final response = await _channel.invokeMethod<String>('generateResponse', {
        'query': query,
      });

      return response ?? 'I could not generate a response.';
    } on PlatformException catch (e) {
      return 'Model error: ${e.message ?? 'Unable to generate a response.'}';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
