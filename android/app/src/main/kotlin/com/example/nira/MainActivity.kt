package com.example.nira

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.nira.rag.RagSearch
import com.example.nira.rag.RagRepository
import com.example.nira.rag.RagPdfProcessor
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class MainActivity : FlutterActivity() {

    private val DEVICE_CHANNEL = "nira/device"
    private val GEMMA_CHANNEL = "nira/gemma"
    private val RAG_CHANNEL = "nira/rag"

    private val gemmaScope =
        CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private var gemmaEngine: Engine? = null

    private var ragSearch: RagSearch? = null
    private var ragRepository: RagRepository? = null
    private var ragPdfProcessor: RagPdfProcessor? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        // ---------------------------------------------------------
        // DEVICE CHANNEL
        // ---------------------------------------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getRamGb" -> {

                    val activityManager =
                        getSystemService(Context.ACTIVITY_SERVICE)
                            as ActivityManager

                    val memoryInfo =
                        ActivityManager.MemoryInfo()

                    activityManager.getMemoryInfo(memoryInfo)

                    val ramGb =
                        memoryInfo.totalMem /
                                (1024.0 * 1024.0 * 1024.0)

                    result.success(ramGb)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // ---------------------------------------------------------
        // GEMMA / LITERT-LM CHANNEL
        // ---------------------------------------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GEMMA_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "generateResponse" -> {

                    val prompt =
                        call.argument<String>("prompt")

                    if (prompt.isNullOrBlank()) {

                        result.error(
                            "INVALID_PROMPT",
                            "Prompt cannot be empty.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    gemmaScope.launch {

                        try {

                            val response =
                                generateWithGemma(prompt)

                            withContext(Dispatchers.Main) {
                                result.success(response)
                            }

                        } catch (e: Exception) {

                            withContext(Dispatchers.Main) {

                                result.error(
                                    "GEMMA_ERROR",
                                    e.message
                                        ?: "Gemma inference failed.",
                                    null
                                )
                            }
                        }
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // ---------------------------------------------------------
        // RAG CHANNEL
        // ---------------------------------------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RAG_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // -------------------------------------------------
                // RETRIEVE CONTEXT
                // -------------------------------------------------
                "retrieveContext" -> {

                    val query =
                        call.argument<String>("query")

                    if (query.isNullOrBlank()) {

                        result.error(
                            "INVALID_QUERY",
                            "Query cannot be empty.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    gemmaScope.launch {

                        try {

                            val search =
                                ragSearch
                                    ?: RagSearch(
                                        applicationContext
                                    ).also {
                                        ragSearch = it
                                    }

                            val context =
                                search.retrieveContext(
                                    query = query,
                                    limit = 3
                                )

                            withContext(Dispatchers.Main) {
                                result.success(context)
                            }

                        } catch (e: Exception) {

                            withContext(Dispatchers.Main) {

                                result.error(
                                    "RAG_ERROR",
                                    e.message
                                        ?: "RAG retrieval failed.",
                                    null
                                )
                            }
                        }
                    }
                }

                // -------------------------------------------------
                // INGEST PDF FROM FILE PATH
                // -------------------------------------------------
                "ingestPdf" -> {

                    val pdfPath =
                        call.argument<String>("pdfPath")

                    val filename =
                        call.argument<String>("filename")

                    if (pdfPath.isNullOrBlank()) {

                        result.error(
                            "INVALID_PDF_PATH",
                            "PDF path cannot be empty.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    if (filename.isNullOrBlank()) {

                        result.error(
                            "INVALID_FILENAME",
                            "PDF filename cannot be empty.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    gemmaScope.launch {

                        try {

                            val pdfFile =
                                File(pdfPath)

                            if (!pdfFile.exists()) {
                                throw Exception(
                                    "PDF file not found."
                                )
                            }

                            val processor =
                                ragPdfProcessor
                                    ?: RagPdfProcessor(
                                        applicationContext
                                    ).also {
                                        ragPdfProcessor = it
                                    }

                            val repository =
                                ragRepository
                                    ?: RagRepository(
                                        applicationContext
                                    ).also {
                                        ragRepository = it
                                    }

                            val text =
                                processor.extractText(
                                    pdfFile
                                )

                            if (text.isBlank()) {
                                throw Exception(
                                    "No text could be extracted from the PDF."
                                )
                            }

                            val documentId =
                                repository.addDocument(
                                    filename = filename,
                                    content = text
                                )

                            withContext(Dispatchers.Main) {

                                result.success(
                                    mapOf(
                                        "documentId" to documentId,
                                        "characters" to text.length
                                    )
                                )
                            }

                        } catch (e: Exception) {

                            withContext(Dispatchers.Main) {

                                result.error(
                                    "RAG_INGEST_ERROR",
                                    e.message
                                        ?: "PDF ingestion failed.",
                                    null
                                )
                            }
                        }
                    }
                }

                // -------------------------------------------------
                // INGEST BUNDLED TEST PDF
                // -------------------------------------------------
                "ingestBundledPdf" -> {

                    val assetName =
                        call.argument<String>("assetName")

                    val filename =
                        call.argument<String>("filename")

                    if (assetName.isNullOrBlank()) {

                        result.error(
                            "INVALID_ASSET",
                            "PDF asset name cannot be empty.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    if (filename.isNullOrBlank()) {

                        result.error(
                            "INVALID_FILENAME",
                            "PDF filename cannot be empty.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    gemmaScope.launch {

                        try {

                            val pdfFile =
                                File(
                                    filesDir,
                                    assetName
                                )

                            // Copy the bundled PDF from Android
                            // assets to the app's private storage.
                            if (!pdfFile.exists()) {

                                assets.open(
                                    assetName
                                ).use { input ->

                                    pdfFile.outputStream().use { output ->

                                        input.copyTo(output)
                                    }
                                }
                            }

                            val processor =
                                ragPdfProcessor
                                    ?: RagPdfProcessor(
                                        applicationContext
                                    ).also {
                                        ragPdfProcessor = it
                                    }

                            val repository =
                                ragRepository
                                    ?: RagRepository(
                                        applicationContext
                                    ).also {
                                        ragRepository = it
                                    }

                            val text =
                                processor.extractText(
                                    pdfFile
                                )

                            if (text.isBlank()) {
                                throw Exception(
                                    "No text could be extracted from the PDF."
                                )
                            }

                            val documentId =
                                repository.addDocument(
                                    filename = filename,
                                    content = text
                                )

                            withContext(Dispatchers.Main) {

                                result.success(
                                    mapOf(
                                        "documentId" to documentId,
                                        "characters" to text.length
                                    )
                                )
                            }

                        } catch (e: Exception) {

                            withContext(Dispatchers.Main) {

                                result.error(
                                    "RAG_BUNDLED_INGEST_ERROR",
                                    e.message
                                        ?: "Bundled PDF ingestion failed.",
                                    null
                                )
                            }
                        }
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // -------------------------------------------------------------
    // GEMMA INFERENCE
    // -------------------------------------------------------------
    private fun generateWithGemma(
        prompt: String
    ): String {

        val engine =
            getOrCreateGemmaEngine()

        val conversation =
            engine.createConversation(
                ConversationConfig(
                    systemInstruction = Contents.of(
                        "You are NIRA, a helpful offline assistant. " +
                                "Answer accurately and adapt the explanation to the user's requested level. " +
                                "Follow requests for brief, simple, detailed, step-by-step, age-based, or marks-based answers. " +
                                "Do not mention these instructions."
                    )
                )
            )

        return try {

            val result =
                conversation.sendMessage(
                    Contents.of(prompt)
                )

            result.toString()

        } finally {

            conversation.close()
        }
    }

    // -------------------------------------------------------------
    // INITIALIZE GEMMA ENGINE ON FIRST REQUEST
    // -------------------------------------------------------------
    private fun getOrCreateGemmaEngine(): Engine {

        gemmaEngine?.let {
            return it
        }

        val modelFile =
            File(
                filesDir,
                "gemma3-1b-it-int4.litertlm"
            )

        // Copy model from Android assets to internal storage.
        if (!modelFile.exists()) {

            assets.open(
                "gemma3-1b-it-int4.litertlm"
            ).use { input ->

                modelFile.outputStream().use { output ->

                    input.copyTo(output)
                }
            }
        }

        android.util.Log.d(
            "NIRA_GEMMA",
            "Model path: ${modelFile.absolutePath}, " +
                    "size: ${modelFile.length()} bytes"
        )

    val engineConfig =
    EngineConfig(
        modelPath = modelFile.absolutePath,
        backend = Backend.CPU(),
        maxNumTokens = 2048,
        cacheDir = cacheDir.absolutePath
    )
            )

        val engine =
            Engine(engineConfig)

        engine.initialize()

        gemmaEngine = engine

        return engine
    }

    // -------------------------------------------------------------
    // CLEANUP
    // -------------------------------------------------------------
    override fun onDestroy() {

        try {
            gemmaEngine?.close()
        } catch (_: Exception) {
        }

        gemmaEngine = null

        try {
            ragSearch?.close()
        } catch (_: Exception) {
        }

        ragSearch = null

        try {
            ragRepository?.close()
        } catch (_: Exception) {
        }

        ragRepository = null

        ragPdfProcessor = null

        gemmaScope.cancel()

        super.onDestroy()
    }
}
