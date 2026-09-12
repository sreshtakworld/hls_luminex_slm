package com.example.nira.rag

import android.content.ContentValues
import android.content.Context

class RagRepository(context: Context) {

    private val database = RagDatabase(context)

    fun addDocument(
        filename: String,
        content: String
    ): Int {

        val db = database.writableDatabase

        val documentValues = ContentValues().apply {
            put("filename", filename)
            put("content", content)
        }

        val documentId =
            db.insert(
                "documents",
                null,
                documentValues
            ).toInt()

        if (documentId == -1) {
            throw Exception("Failed to insert document")
        }

        val chunks = chunkText(content)

        for ((index, chunk) in chunks.withIndex()) {

            val chunkValues = ContentValues().apply {
                put("document_id", documentId)
                put("chunk_index", index)
                put("content", chunk)
            }

            db.insert(
                "chunks",
                null,
                chunkValues
            )
        }

        return documentId
    }

    private fun chunkText(
        text: String,
        chunkSize: Int = 500
    ): List<String> {

        val chunks = mutableListOf<String>()

        var start = 0

        while (start < text.length) {

            val end =
                minOf(
                    start + chunkSize,
                    text.length
                )

            val chunk =
                text.substring(start, end).trim()

            if (chunk.isNotEmpty()) {
                chunks.add(chunk)
            }

            start += chunkSize
        }

        return chunks
    }

    fun close() {
        database.close()
    }
}