class GemmaService {
  static String generateResponse(String query) {
    final text = query.toLowerCase().trim();

    if (text.contains('hello') || text.contains('hi')) {
      return 'Hello! I am NIRA. How can I help you?';
    }

    if (text.contains('what is nira')) {
      return 'NIRA is a privacy-first AI assistant designed to process requests on the device.';
    }

    return 'Gemma on-device processing selected for this query.';
  }
}