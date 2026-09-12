package com.example.nira.rag

import android.content.Context

class RagSearch(context: Context) {

    private val database = RagDatabase(context)

    fun searchChunks(
        query: String,
        limit: Int = 5
    ): List<String> {

        val cleanedQuery = query.trim()

        if (cleanedQuery.isEmpty()) {
            return emptyList()
        }

        val db = database.readableDatabase

        val keywords = cleanedQuery
            .lowercase()
            .split(Regex("\\s+"))
            .filter { it.isNotBlank() }

        if (keywords.isEmpty()) {
            return emptyList()
        }

        val conditions =
            mutableListOf<String>()

        val arguments =
            mutableListOf<String>()

        for (keyword in keywords) {
            conditions.add(
                "LOWER(content) LIKE ?"
            )

            arguments.add(
                "%$keyword%"
            )
        }

        val selection =
            conditions.joinToString(" OR ")

        val results =
            mutableListOf<String>()

        /*
         * DISTINCT prevents identical chunks from
         * being returned multiple times when the same
         * document was accidentally ingested more than once.
         */
        db.query(
            true,
            "chunks",
            arrayOf(
                "id",
                "document_id",
                "chunk_index",
                "content"
            ),
            selection,
            arguments.toTypedArray(),
            null,
            null,
            "id DESC",
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

                if (!results.contains(content)) {
                    results.add(content)
                }
            }
        }

        return results
    }

    fun retrieveContext(
        query: String,
        limit: Int = 5
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

    fun close() {
        database.close()
    }
}