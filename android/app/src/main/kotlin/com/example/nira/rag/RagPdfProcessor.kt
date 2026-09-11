package com.example.nira.rag

import android.content.Context
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import java.io.File

class RagPdfProcessor(
    context: Context
) {

    init {
        PDFBoxResourceLoader.init(context)
    }

    fun extractText(pdfFile: File): String {

        if (!pdfFile.exists()) {
            throw Exception("PDF file not found.")
        }

        PDDocument.load(pdfFile).use { document ->

            val stripper = PDFTextStripper()

            return stripper.getText(document)
        }
    }
}