\# Member 1 — On-Device SLM / AI Engineer



\## Overview



This module contains the on-device Small Language Model (SLM) implementation for NIRA.



The Android test application demonstrates offline inference using:



\- Gemma 3 1B IT

\- INT4 quantization

\- LiteRT-LM Android SDK

\- CPU backend

\- Android device/emulator

\- No internet connection required during inference



\## Model



Model:



Gemma3-1B-IT



Quantization:



INT4



Model file:



`gemma3-1b-it-int4.litertlm`



Approximate model size:



557 MiB



The model file is intentionally NOT stored in Git because of its large size.



Place the downloaded model at:



`android\_test/NIRAAITest/app/src/main/assets/gemma3-1b-it-int4.litertlm`



\## Runtime



LiteRT-LM Android SDK:



`0.16.1`



Backend:



`CPU`



Maximum output tokens:



`192`



The Android application copies the model from the app assets to internal storage and loads it locally.



\## Android Test Application



Project:



`android\_test/NIRAAITest`



Main inference code:



`android\_test/NIRAAITest/app/src/main/java/com/nira/ai/MainActivity.kt`



The application:



1\. Loads the local `.litertlm` model.

2\. Initializes the LiteRT-LM engine.

3\. Creates an offline conversation.

4\. Sends a question to the local model.

5\. Receives the generated response.

6\. Records initialization and inference time.

7\. Counts response words.

8\. Closes the conversation and engine after inference.



\## System Prompt



NIRA is configured to:



\- Give accurate, simple and practical answers.

\- Answer the question directly.

\- Keep answers concise.

\- Avoid unnecessary background information.

\- Avoid asking unnecessary follow-up questions.



The system prompt is also available at:



`member1/scripts/inference/system\_prompt.txt`



\## Benchmark



A controlled five-question benchmark was performed on the Android emulator.



| Metric | Result |

|---|---:|

| Average model initialization | 1.810 s |

| Median model initialization | 1.768 s |

| Average inference time | 12.196 s |

| Median inference time | 8.529 s |

| Average response length | 22.6 words |



Inference time varies depending on the generated response length.



\### Test topics



1\. Capital of India

2\. Saving water at home

3\. Photosynthesis

4\. Keeping a village clean

5\. RAM vs storage



\## Offline Verification



The model was tested locally on the Android emulator without requiring an internet connection during inference.



The offline test result is documented in:



`member1/results/offline\_test.txt`



\## Device



The Android test environment and device specifications are documented in:



`member1/results/device\_specs.txt`



\## Reproduction



After cloning the repository:



1\. Download the required Gemma3-1B-IT INT4 LiteRT-LM model.

2\. Place the `.litertlm` file in:



&#x20;  `android\_test/NIRAAITest/app/src/main/assets/`



3\. Open `android\_test/NIRAAITest` in Android Studio.

4\. Allow Gradle to download the LiteRT-LM dependency.

5\. Connect an Android device or start an Android emulator.

6\. Build and run the application.

7\. Test the assistant without an internet connection.



\## Notes



The model file, build directories, virtual environments and other generated files are excluded through `.gitignore`.



One benchmark response for the photosynthesis question was incomplete, omitting carbon dioxide and containing a grammatical issue. This is recorded as a current model-quality limitation and should be considered during future prompt/model evaluation.

