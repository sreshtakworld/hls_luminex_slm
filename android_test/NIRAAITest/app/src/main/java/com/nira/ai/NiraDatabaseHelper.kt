package com.nira.ai

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class NiraDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, "nira.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {

        db.execSQL(
            """
            CREATE TABLE documents (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                filename TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """.trimIndent()
        )

        db.execSQL(
            """
            CREATE TABLE chunks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                document_id INTEGER NOT NULL,
                chunk_index INTEGER NOT NULL,
                content TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (document_id) REFERENCES documents(id)
            )
            """.trimIndent()
        )

        db.execSQL(
            """
            CREATE TABLE memory (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                memory_key TEXT NOT NULL,
                value TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """.trimIndent()
        )
    }

    override fun onUpgrade(
        db: SQLiteDatabase,
        oldVersion: Int,
        newVersion: Int
    ) {
        // No destructive migration for now.
    }

    fun insertDocument(
        filename: String,
        content: String
    ): Long {
        val values = ContentValues().apply {
            put("filename", filename)
            put("content", content)
        }

        return writableDatabase.insert(
            "documents",
            null,
            values
        )
    }

    fun insertChunk(
        documentId: Long,
        chunkIndex: Int,
        content: String
    ): Long {
        val values = ContentValues().apply {
            put("document_id", documentId)
            put("chunk_index", chunkIndex)
            put("content", content)
        }

        return writableDatabase.insert(
            "chunks",
            null,
            values
        )
    }

    fun saveMemory(
        key: String,
        value: String
    ): Long {
        val values = ContentValues().apply {
            put("memory_key", key)
            put("value", value)
        }

        return writableDatabase.insert(
            "memory",
            null,
            values
        )
    }

    fun getMemory(key: String): String? {

        val cursor = readableDatabase.query(
            "memory",
            arrayOf("value"),
            "memory_key = ?",
            arrayOf(key),
            null,
            null,
            "id DESC",
            "1"
        )

        cursor.use {
            return if (it.moveToFirst()) {
                it.getString(
                    it.getColumnIndexOrThrow("value")
                )
            } else {
                null
            }
        }
    }

    fun deleteMemory(key: String) {
        writableDatabase.delete(
            "memory",
            "memory_key = ?",
            arrayOf(key)
        )
    }

    fun deleteDocument(documentId: Long) {

        writableDatabase.delete(
            "chunks",
            "document_id = ?",
            arrayOf(documentId.toString())
        )

        writableDatabase.delete(
            "documents",
            "id = ?",
            arrayOf(documentId.toString())
        )
    }
}