from knowledge.retrieval.search import search_chunks


def retrieve_context(query, limit=5):
    results = search_chunks(query, limit)

    if not results:
        return ""

    context_parts = []

    for result in results:
        context_parts.append(result[3])

    return "\n\n".join(context_parts)