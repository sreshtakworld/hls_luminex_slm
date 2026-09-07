class RagService {
  static String answer(String query) {
    final text = query.toLowerCase().trim();

    if (text.contains('summarize') || text.contains('summary')) {
      return 'Document summary will be generated from the available document.';
    }

    if (text.contains('according to') ||
        text.contains('in the document') ||
        text.contains('document')) {
      return 'Relevant information will be retrieved from the document.';
    }

    return 'Document/RAG processing selected for this query.';
  }
}