package com.example.nira

import androidx.lifecycle.lifecycleScope
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "nira/device"

    private var engine: Engine? = null

    // Prevent multiple model requests from running at the same time.
    private val modelLock = Any()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getRamGb" -> {
                    val activityManager =
                        getSystemService(ACTIVITY_SERVICE)
                            as android.app.ActivityManager

                    val memoryInfo =
                        android.app.ActivityManager.MemoryInfo()

                    activityManager.getMemoryInfo(memoryInfo)

                    val ramGb =
                        memoryInfo.totalMem /
                            (1024.0 * 1024.0 * 1024.0)

                    result.success(ramGb)
                }

                "generateResponse" -> {

                    val query =
                        call.argument<String>("query")

                    if (query.isNullOrBlank()) {
                        result.error(
                            "INVALID_QUERY",
                            "Query cannot be empty",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    lifecycleScope.launch {
                        try {

                            val response =
                                withContext(Dispatchers.IO) {
                                    generateResponse(query)
                                }

                            result.success(response)

                        } catch (e: Exception) {

                            android.util.Log.e(
                                "NIRA_BENCHMARK",
                                "Model error",
                                e
                            )

                            result.error(
                                "MODEL_ERROR",
                                e.message ?: "Unknown model error",
                                null
                            )
                        }
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun generateResponse(query: String): String {

        synchronized(modelLock) {

            // Initialize the model only once.
            if (engine == null) {

                val modelFile = File(
                    filesDir,
                    "gemma3-1b-it-int4.litertlm"
                )

                // Copy the model from Android assets if necessary.
                if (!modelFile.exists()) {
                    assets.open(
                        "gemma3-1b-it-int4.litertlm"
                    ).use { input ->

                        modelFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                }

                val engineConfig = EngineConfig(
                    modelPath = modelFile.absolutePath,
                    backend = Backend.CPU(),
                    maxNumTokens = 192,
                    cacheDir = cacheDir.absolutePath
                )

                engine = Engine(engineConfig)

                val initStart =
                    System.currentTimeMillis()

                engine!!.initialize()

                val initTime =
                    System.currentTimeMillis() - initStart

                android.util.Log.d(
                    "NIRA_BENCHMARK",
                    "Model initialization time: ${initTime} ms"
                )
            }

            /*
             * Create a NEW conversation for every independent question.
             *
             * This prevents previous responses from affecting the
             * next question and avoids the empty-response behavior
             * observed during testing.
             */
            val conversation: Conversation =
                engine!!.createConversation(
                    ConversationConfig(
                        systemInstruction = Contents.of(
    "You are NIRA, a helpful offline assistant for everyday users. " +
    "Give accurate, simple, practical, and grammatically correct answers. " +
    "Answer the user's question directly. " +
    "For factual questions, include the key facts needed for a complete answer. " +
    "Do not leave sentences unfinished. " +
    "For science questions, mention the important inputs and outputs when relevant. " +
    "Keep answers concise, usually 1 to 3 short sentences or bullet points. " +
    "Use simple language that is easy for people in villages and small communities to understand. " +
    "Do not add unnecessary background information. " +
    "Do not ask if the user wants more details."
)
                    )
                )

            try {

                val inferenceStart =
                    System.currentTimeMillis()

                val response =
                    conversation.sendMessage(
                        Contents.of(query)
                    )

                val inferenceTime =
                    System.currentTimeMillis() - inferenceStart

                val responseText =
                    response.toString().trim()

                android.util.Log.d(
                    "NIRA_BENCHMARK",
                    "Question: $query"
                )

                android.util.Log.d(
                    "NIRA_BENCHMARK",
                    "Inference time: ${inferenceTime} ms"
                )

                android.util.Log.d(
                    "NIRA_BENCHMARK",
                    "Response: $responseText"
                )

                return responseText

            } finally {

                // Close the conversation after each question.
                conversation.close()
            }
        }
    }

    override fun onDestroy() {

        synchronized(modelLock) {

            engine?.close()
            engine = null
        }

        super.onDestroy()
    }
}