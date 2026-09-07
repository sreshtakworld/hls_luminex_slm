class GemmaService {
  static String generateResponse(String query) {
    final text = query.toLowerCase().trim();

    // Greetings
    if (text == 'hello' ||
        text == 'hi' ||
        text == 'hey' ||
        text == 'hello nira' ||
        text == 'hi nira' ||
        text == 'hey nira') {
      return 'Hello! I am NIRA. How can I help you?';
    }

    // NIRA
    if (text.contains('what is nira')) {
      return 'NIRA is a privacy-first AI assistant designed to process requests on the device.';
    }

    // India
    if (text.contains('where is india')) {
      return 'India is a country in South Asia.';
    }

    // General questions
    if (text.contains('who are you')) {
      return 'I am NIRA, a privacy-first AI assistant designed to work on your device.';
    }

    if (text.contains('what can you do')) {
      return 'I can answer questions, perform calculations, and work with documents while keeping processing on your device.';
    }

    // Fallback
    return 'I am still learning how to answer this question.';
  }
}