package com.example.nira.rag

import android.content.Context
import kotlin.math.min

class RagSearch(context: Context) {

    private val database = RagDatabase(context)

    /*
     * Search the stored PDF chunks and return the most relevant ones.
     *
     * Default limit is kept small (3) so that:
     * 1. Retrieval is faster.
     * 2. Less PDF text is sent to Gemma.
     * 3. Gemma generates answers faster.
     */
    fun searchChunks(
        query: String,
        limit: Int = 3
    ): List<String> {

        val cleanedQuery = query
            .trim()
            .lowercase()

        if (cleanedQuery.isEmpty()) {
            return emptyList()
        }

        /*
         * Questions such as:
         *
         * "What is this document about?"
         * "Tell me about this PDF"
         * "Summarize the document"
         *
         * may contain no useful topic keywords.
         *
         * In this case, retrieve only the first 2-3 chunks.
         */
        if (isGeneralDocumentQuestion(cleanedQuery)) {
            return getFirstChunks(limit)
        }

        /*
         * Convert the question into meaningful keywords.
         */
        val queryWords = tokenize(cleanedQuery)
            .filterNot { isStopWord(it) }
            .distinct()

        /*
         * If there are no useful keywords, use the beginning
         * of the document as fallback context.
         */
        if (queryWords.isEmpty()) {
            return getFirstChunks(limit)
        }

        val db = database.readableDatabase

        val scoredChunks =
            mutableListOf<ScoredChunk>()

        /*
         * Read all chunks from the local SQLite database.
         */
        db.query(
            "chunks",
            arrayOf(
                "id",
                "content"
            ),
            null,
            null,
            null,
            null,
            "id ASC"
        ).use { cursor ->

            val idIndex =
                cursor.getColumnIndexOrThrow("id")

            val contentIndex =
                cursor.getColumnIndexOrThrow("content")

            while (cursor.moveToNext()) {

                val id =
                    cursor.getLong(idIndex)

                val content =
                    cursor.getString(contentIndex)

                val score =
                    calculateScore(
                        queryWords,
                        content
                    )

                if (score > 0) {

                    scoredChunks.add(
                        ScoredChunk(
                            id = id,
                            content = content,
                            score = score
                        )
                    )
                }
            }
        }

        /*
         * Highest relevance first.
         *
         * Smaller database id is preferred when scores
         * are equal so that chunks remain in document order.
         */
        scoredChunks.sortWith(
            compareByDescending<ScoredChunk> {
                it.score
            }.thenBy {
                it.id
            }
        )

        val results =
            mutableListOf<String>()

        for (chunk in scoredChunks) {

            if (!results.contains(chunk.content)) {
                results.add(chunk.content)
            }

            if (results.size >= limit) {
                break
            }
        }

        /*
         * If no keyword matched anything, return the first
         * chunks rather than returning an empty context.
         */
        if (results.isEmpty()) {
            return getFirstChunks(limit)
        }

        return results
    }

    /*
     * -------------------------------------------------------------
     * RETRIEVE CONTEXT
     * -------------------------------------------------------------
     */

    fun retrieveContext(
        query: String,
        limit: Int = 3
    ): String {

        val results =
            searchChunks(
                query = query,
                limit = limit
            )

        return results.joinToString(
            "\n\n"
        )
    }

    /*
     * -------------------------------------------------------------
     * GENERAL DOCUMENT QUESTIONS
     * -------------------------------------------------------------
     */

    private fun isGeneralDocumentQuestion(
        query: String
    ): Boolean {

        val phrases = listOf(

            "what is this document about",
            "what does this document talk about",
            "what is the document about",

            "tell me about this document",
            "tell me about the document",

            "what is this pdf about",
            "what does this pdf talk about",
            "tell me about this pdf",

            "what is this file about",
            "tell me about this file",

            "summarize the document",
            "summarise the document",

            "summarize this document",
            "summarise this document",

            "summarize the pdf",
            "summarise the pdf",

            "summarize this pdf",
            "summarise this pdf",

            "give me a summary of the document",
            "give me a summary of this document",

            "give me a summary of the pdf",
            "give me a summary of this pdf"
        )

        return phrases.any {
            query.contains(it)
        }
    }

    /*
     * -------------------------------------------------------------
     * FIRST CHUNKS
     * -------------------------------------------------------------
     *
     * Used for general questions and fallback retrieval.
     */

    private fun getFirstChunks(
        limit: Int
    ): List<String> {

        val db = database.readableDatabase

        val results =
            mutableListOf<String>()

        db.query(
            "chunks",
            arrayOf(
                "content"
            ),
            null,
            null,
            null,
            null,
            "id ASC",
            limit.toString()
        ).use { cursor ->

            val contentIndex =
                cursor.getColumnIndexOrThrow(
                    "content"
                )

            while (cursor.moveToNext()) {

                val content =
                    cursor.getString(
                        contentIndex
                    )

                if (
                    content.isNotBlank() &&
                    !results.contains(content)
                ) {
                    results.add(content)
                }
            }
        }

        return results
    }

    /*
     * -------------------------------------------------------------
     * TOKENIZATION
     * -------------------------------------------------------------
     */

    private fun tokenize(
        text: String
    ): List<String> {

        return text
            .replace(
                Regex("[^a-z0-9]+"),
                " "
            )
            .split(
                Regex("\\s+")
            )
            .filter {
                it.length >= 2
            }
    }

    /*
     * -------------------------------------------------------------
     * STOP WORDS
     * -------------------------------------------------------------
     */

    private fun isStopWord(
        word: String
    ): Boolean {

        return word in setOf(

            "a",
            "an",
            "the",

            "is",
            "are",
            "was",
            "were",
            "be",
            "been",
            "being",
            "am",

            "do",
            "does",
            "did",

            "what",
            "which",
            "who",
            "whom",
            "whose",

            "when",
            "where",
            "why",
            "how",

            "can",
            "could",
            "would",
            "should",

            "will",
            "shall",
            "may",
            "might",
            "must",

            "and",
            "or",
            "but",
            "if",
            "then",
            "than",
            "so",
            "because",
            "as",

            "of",
            "to",
            "from",
            "for",

            "in",
            "on",
            "at",
            "by",
            "with",

            "about",
            "into",
            "through",
            "during",
            "after",
            "before",
            "between",
            "under",
            "over",

            "this",
            "that",
            "these",
            "those",

            "it",
            "its",

            "they",
            "them",
            "their",

            "there",
            "here",

            "my",
            "your",
            "our",
            "you",
            "we",
            "i",
            "me",

            "he",
            "she",
            "his",
            "her",

            "please",

            "document",
            "pdf",
            "file",
            "page"
        )
    }

    /*
     * -------------------------------------------------------------
     * RELEVANCE SCORING
     * -------------------------------------------------------------
     */

    private fun calculateScore(
        queryWords: List<String>,
        content: String
    ): Int {

        val contentWords =
            tokenize(
                content.lowercase()
            )

        if (contentWords.isEmpty()) {
            return 0
        }

        /*
         * Create a frequency map once.
         *
         * This is much faster than calling
         * contentWords.count { ... } repeatedly.
         */
        val wordFrequency =
            mutableMapOf<String, Int>()

        for (word in contentWords) {
            wordFrequency[word] =
                (wordFrequency[word] ?: 0) + 1
        }

        var score = 0

        for (word in queryWords) {

            val occurrences =
                wordFrequency[word] ?: 0

            /*
             * Exact match.
             */
            if (occurrences > 0) {

                score += 3

                /*
                 * Reward repeated important words,
                 * but cap the bonus.
                 */
                if (occurrences > 1) {

                    score += min(
                        occurrences - 1,
                        3
                    )
                }
            }

            /*
             * Small prefix match bonus.
             *
             * Example:
             *
             * query: network
             * text: networking
             */
            if (
                word.length >= 4 &&
                contentWords.any {
                    it.startsWith(word) &&
                            it != word
                }
            ) {
                score += 1
            }
        }

        /*
         * ---------------------------------------------------------
         * PHRASE BONUS
         * ---------------------------------------------------------
         */

        if (queryWords.size >= 2) {

            val normalizedContent =
                content
                    .lowercase()
                    .replace(
                        Regex("[^a-z0-9]+"),
                        " "
                    )
                    .trim()

            for (
                i in 0 until queryWords.size - 1
            ) {

                val phrase =
                    "${queryWords[i]} ${queryWords[i + 1]}"

                if (
                    normalizedContent.contains(
                        phrase
                    )
                ) {
                    score += 4
                }
            }
        }

        return score
    }

    /*
     * -------------------------------------------------------------
     * DATA CLASS
     * -------------------------------------------------------------
     */

    private data class ScoredChunk(
        val id: Long,
        val content: String,
        val score: Int
    )

    /*
     * -------------------------------------------------------------
     * CLOSE DATABASE
     * -------------------------------------------------------------
     */

    fun close() {
        database.close()
    }
}