package com.nira.ai

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Contents
import com.nira.ai.ui.theme.NIRAAITestTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            NIRAAITestTheme {
                NiraScreen()
            }
        }
    }

    @Composable
    fun NiraScreen() {

        var response by remember {
            mutableStateOf("Loading NIRA...")
        }

        val scope = rememberCoroutineScope()

        LaunchedEffect(Unit) {
            scope.launch(Dispatchers.IO) {

                try {

                    // Copy model from assets to internal storage
                    val modelFile = File(
                        filesDir,
                        "gemma3-1b-it-int4.litertlm"
                    )

                    if (!modelFile.exists()) {
                        assets.open(
                            "gemma3-1b-it-int4.litertlm"
                        ).use { input ->

                            modelFile.outputStream().use { output ->
                                input.copyTo(output)
                            }
                        }
                    }

                    // Configure LiteRT-LM
                    val engineConfig = EngineConfig(
                        modelPath = modelFile.absolutePath,
                        backend = Backend.CPU(),
                        maxNumTokens = 192,
                        cacheDir = cacheDir.absolutePath
                    )

                    // Create engine
                    val engine = Engine(engineConfig)

                    try {

                        // Initialize model
                        val initStart = System.currentTimeMillis()

                        engine.initialize()

                        val initTime = System.currentTimeMillis() - initStart

                        android.util.Log.d(
                            "NIRA_BENCHMARK",
                            "Model initialization time: ${initTime} ms"
                        )

                        // Create conversation
                        val conversation = engine.createConversation(
                            ConversationConfig(
                                systemInstruction = Contents.of(
                                    "You are NIRA, a helpful offline assistant for everyday users. " +
                                            "Give accurate, simple, and practical answers. " +
                                            "Answer the question directly first. " +
                                            "Keep answers concise, usually 1 to 3 short sentences or bullet points. " +
                                            "Do not add unnecessary background information. " +
                                            "Do not ask if the user wants more details."
                                )
                            )
                        )

                        try {

                            val question =
                                "What is the difference between RAM and storage?"

                            val inferenceStart =
                                System.currentTimeMillis()

                            val result = conversation.sendMessage(
                                Contents.of(question)
                            )

                            val inferenceTime =
                                System.currentTimeMillis() - inferenceStart

                            val responseText =
                                result.toString()

                            val wordCount =
                                responseText.trim()
                                    .split("\\s+".toRegex())
                                    .size

                            android.util.Log.d(
                                "NIRA_BENCHMARK",
                                "--------------------------------"
                            )

                            android.util.Log.d(
                                "NIRA_BENCHMARK",
                                "Question: $question"
                            )

                            android.util.Log.d(
                                "NIRA_BENCHMARK",
                                "Inference time: ${inferenceTime} ms"
                            )

                            android.util.Log.d(
                                "NIRA_BENCHMARK",
                                "Response word count: $wordCount"
                            )

                            android.util.Log.d(
                                "NIRA_BENCHMARK",
                                "Response: $responseText"
                            )

                            response = responseText

                        } finally {

                            conversation.close()

                        }

                    } finally {

                        engine.close()

                    }


                } catch (e: Exception) {

                    response = "Error: ${e.message}"
                }
            }
        }

        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {

            if (response == "Loading NIRA...") {
                CircularProgressIndicator()
            }

            Text(text = response)
        }
    }
}