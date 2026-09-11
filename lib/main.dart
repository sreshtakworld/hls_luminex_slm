import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'router/intent_router.dart';
import 'device/device_profile.dart';
import 'processing/processing_strategy.dart';
import 'calculator/calculator_service.dart';
import 'rag/rag_service.dart';
import 'gemma/gemma_service.dart';

void main() {
  runApp(const NiraApp());
}

class NiraApp extends StatelessWidget {
  const NiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NIRA',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const NiraHomePage(),
    );
  }
}

class NiraHomePage extends StatefulWidget {
  const NiraHomePage({super.key});

  @override
  State<NiraHomePage> createState() => _NiraHomePageState();
}

class _NiraHomePageState extends State<NiraHomePage> {
  final TextEditingController _messageController =
      TextEditingController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am NIRA 👋\nHow can I help you today?',
      isUser: false,
    ),
  ];

  // ---------------- NETWORK ----------------

  bool _isOffline = true;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  // ---------------- BATTERY ----------------

  final Battery _battery = Battery();

  int _batteryLevel = 100;

  StreamSubscription<BatteryState>? _batterySubscription;

  // ---------------- INITIALIZATION ----------------

  @override
  void initState() {
    super.initState();

    // Listen for network changes.
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isOffline =
            results.contains(ConnectivityResult.none);
      });
    });

    // Check network when app starts.
    _checkConnectivity();

    // Get current battery level.
    _loadBatteryLevel();

    // Listen for battery state changes.
    _batterySubscription =
        _battery.onBatteryStateChanged.listen((state) {
      _loadBatteryLevel();
    });
  }

  // ---------------- CONNECTIVITY ----------------

  Future<void> _checkConnectivity() async {
    final results =
        await Connectivity().checkConnectivity();

    if (!mounted) {
      return;
    }

    setState(() {
      _isOffline =
          results.contains(ConnectivityResult.none);
    });
  }

  // ---------------- BATTERY ----------------

  Future<void> _loadBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;

      if (!mounted) {
        return;
      }

      setState(() {
        _batteryLevel = level;
      });
    } catch (_) {
      // Keep previous value if unavailable.
    }
  }

  // ---------------- PDF UPLOAD ----------------

  Future<void> _pickAndIngestPdfs() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isEmpty) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Loading ${files.length} PDF${files.length == 1 ? '' : 's'}...',
            isUser: false,
          ),
        );
      });

      var successCount = 0;
      final failedFiles = <String>[];

      for (final file in files) {
        final path = file.path;

        if (path == null || path.isEmpty) {
          failedFiles.add(file.name);
          continue;
        }

        final response = await RagService.ingestPdf(
          pdfPath: path,
          filename: file.name,
        );

        if (response.startsWith('PDF loaded successfully.')) {
          successCount++;
        } else {
          failedFiles.add(file.name);
        }
      }

      if (!mounted) {
        return;
      }

      final message = StringBuffer();
      message.write('PDF upload complete.\n');
      message.write('Loaded: $successCount/${files.length}');

      if (failedFiles.isNotEmpty) {
        message.write('\nFailed: ${failedFiles.join(', ')}');
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: message.toString(),
            isUser: false,
          ),
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: 'I could not upload the PDF. Please try again.',
            isUser: false,
          ),
        );
      });
    }
  }

  // ---------------- DOCUMENTS NAVIGATION ----------------

  void _openDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NiraDocumentsPage(
          onChoosePdf: _pickAndIngestPdfs,
        ),
      ),
    );
  }

  // ---------------- SEND MESSAGE ----------------

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    // Determine what type of request this is.
    final intent = IntentRouter.classify(text);

    // Detect the device's resources.
    final profile = await DeviceProfile.getProfile();

    // Select the appropriate processing method.
    // This happens silently in the background.
    ProcessingStrategy.selectMethod(
      profile.level,
      intent,
    );

    String response;

    switch (intent) {
      // ---------------- CALCULATOR ----------------

      case IntentType.calculator:
        final result =
            CalculatorService.calculate(text);

        if (result == null) {
          response =
              'I could not calculate that expression.';
        } else {
          response =
              CalculatorService.formatResult(result);
        }

        break;

      // ---------------- DOCUMENT / RAG ----------------

      case IntentType.document:
        response = await RagService.answer(text);
        break;

      // ---------------- GENERAL AI ----------------

      case IntentType.general:
        response =
            await GemmaService.generateResponse(text);
        break;
    }

    setState(() {
      // User message.
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );

      // NIRA response.
      _messages.add(
        ChatMessage(
          text: response,
          isUser: false,
        ),
      );
    });

    _messageController.clear();
  }

  // ---------------- DISPOSE ----------------

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _batterySubscription?.cancel();
    _messageController.dispose();

    super.dispose();
  }

  // ---------------- MAIN SCREEN ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),

            const SizedBox(width: 12),

            const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'NIRA',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Offline AI Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Documents',
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
            onPressed: _openDocuments,
          ),

          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
            ),
            onPressed: () {
              _showSettings();
            },
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ---------------- BODY ----------------

      body: SafeArea(
        child: Column(
          children: [

            // ---------------- STATUS BAR ----------------

            Container(
              margin: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _isOffline
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: _isOffline
                      ? Colors.orange.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [

                  // Network icon
                  Icon(
                    _isOffline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    size: 20,
                    color: _isOffline
                        ? Colors.orange.shade800
                        : Colors.green.shade800,
                  ),

                  const SizedBox(width: 9),

                  // Network status
                  Expanded(
                    child: Text(
                      _isOffline
                          ? 'Offline mode • Processing on device'
                          : 'Online mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isOffline
                            ? Colors.orange.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ),

                  // Battery icon
                  Icon(
                    _batteryLevel >= 90
                        ? Icons.battery_full_rounded
                        : _batteryLevel >= 60
                            ? Icons.battery_5_bar_rounded
                            : _batteryLevel >= 30
                                ? Icons.battery_3_bar_rounded
                                : Icons.battery_1_bar_rounded,
                    size: 21,
                    color: _batteryLevel <= 20
                        ? Colors.red
                        : Colors.grey,
                  ),

                  const SizedBox(width: 4),

                  // Battery percentage
                  Text(
                    '$_batteryLevel%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- WELCOME ----------------

            Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade50,
                    Colors.white,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.indigo.shade100,
                ),
              ),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to NIRA 👋',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Your privacy-first AI assistant that works '
                    'directly on your device.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- CHAT ----------------

            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12,
                ),
                itemCount:
                    _messages.length,
                itemBuilder:
                    (context, index) {
                  final message =
                      _messages[index];

                  return _ChatBubble(
                    message: message,
                  );
                },
              ),
            ),

            // ---------------- INPUT AREA ----------------

            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset:
                        const Offset(0, -3),
                    color: Colors.black
                        .withValues(
                      alpha: 0.06,
                    ),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [

                  Expanded(
                    child: TextField(
                      controller:
                          _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                          TextInputAction.newline,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Ask NIRA something...',
                        prefixIcon:
                            const Icon(
                          Icons
                              .chat_bubble_outline_rounded,
                        ),
                        filled: true,
                        fillColor:
                            const Color(
                          0xFFF2F3F7,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(18),
                          borderSide:
                              BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    width: 52,
                    height: 52,
                    decoration:
                        BoxDecoration(
                      color: Colors.indigo,
                      borderRadius:
                          BorderRadius
                              .circular(17),
                    ),
                    child: IconButton(
                      tooltip: 'Send',
                      onPressed:
                          _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SETTINGS NAVIGATION ----------------

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NiraSettingsPage(),
      ),
    );
  }
}

// ======================================================
// CHAT MESSAGE
// ======================================================

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

// ======================================================
// CHAT BUBBLE
// ======================================================

class _ChatBubble
    extends StatelessWidget {

  final ChatMessage message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,

      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 310,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration:
            BoxDecoration(
          color: message.isUser
              ? Colors.indigo
              : Colors.white,

          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(17),

            topRight:
                const Radius.circular(17),

            bottomLeft:
                Radius.circular(
              message.isUser ? 17 : 4,
            ),

            bottomRight:
                Radius.circular(
              message.isUser ? 4 : 17,
            ),
          ),

          border: message.isUser
              ? null
              : Border.all(
                  color:
                      Colors.grey.shade200,
                ),

          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              offset:
                  const Offset(0, 2),
              color: Colors.black
                  .withValues(
                alpha: 0.04,
              ),
            ),
          ],
        ),

        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: message.isUser
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ======================================================
// DOCUMENTS PAGE
// ======================================================

class NiraDocumentsPage extends StatelessWidget {
  final Future<void> Function() onChoosePdf;

  const NiraDocumentsPage({
    super.key,
    required this.onChoosePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          tooltip: 'Back to NIRA',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'NIRA Documents',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(18),

                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),

              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.indigo.shade50,

                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 34,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Add a PDF to NIRA',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose a PDF from your device. '
                    'After selecting it, you will return '
                    'to this page. Use the back arrow '
                    'to return to the NIRA chat.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,

                    child: FilledButton.icon(
                      onPressed: onChoosePdf,

                      icon: const Icon(
                        Icons.upload_file_rounded,
                      ),

                      label: const Text(
                        'Choose PDF',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.indigo,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Once the PDF is loaded, go back '
                      'to the NIRA chat and ask questions '
                      'about the document. Document questions '
                      'are handled through local retrieval '
                      'and Gemma.',

                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// SETTINGS PAGE
// ======================================================

class NiraSettingsPage
    extends StatelessWidget {

  const NiraSettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceProfile>(
      future:
          DeviceProfile.getProfile(),
      builder:
          (context, snapshot) {

        final profile =
            snapshot.data;

        return Scaffold(
          backgroundColor:
              const Color(0xFFF7F8FC),

          appBar: AppBar(
            backgroundColor:
                Colors.white,
            surfaceTintColor:
                Colors.white,
            elevation: 0,

            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            title: const Text(
              'NIRA Settings',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          body: ListView(
            padding:
                const EdgeInsets.all(16),
            children: [

              const _SettingsSectionTitle(
                title:
                    'Device Information',
                icon:
                    Icons.smartphone_rounded,
              ),

              const SizedBox(height: 10),

              _SettingsCard(
                icon:
                    Icons.phone_android_rounded,
                title:
                    'Device',
                value:
                    profile?.deviceName ??
                        'Detecting...',
              ),

              _SettingsCard(
                icon:
                    Icons.android_rounded,
                title:
                    'Platform',
                value:
                    profile?.platform ??
                        'Detecting...',
              ),

              _SettingsCard(
                icon:
                    Icons.memory_rounded,
                title:
                    'Architecture',
                value:
                    profile?.architecture ??
                        'Detecting...',
              ),

              _SettingsCard(
                icon:
                    Icons.speed_rounded,
                title:
                    'Device Level',
                value:
                    profile?.levelText ??
                        'Detecting...',
              ),

              const SizedBox(height: 24),

              const _SettingsSectionTitle(
                title:
                    'AI & Processing',
                icon:
                    Icons.psychology_rounded,
              ),

              const SizedBox(height: 10),

              _SettingsCard(
                icon:
                    Icons.smart_toy_rounded,
                title:
                    'AI Assistant',
                value:
                    'NIRA',
              ),

              _SettingsCard(
                icon:
                    Icons.memory_rounded,
                title:
                    'Processing',
                value:
                    'On-device processing',
              ),

              _SettingsCard(
                icon:
                    Icons.cloud_off_rounded,
                title:
                    'Network Mode',
                value:
                    'Offline',
              ),

              const SizedBox(height: 24),

              const _SettingsSectionTitle(
                title:
                    'System Status',
                icon:
                    Icons
                        .monitor_heart_outlined,
              ),

              const SizedBox(height: 10),

              _SettingsCard(
                icon:
                    Icons
                        .check_circle_outline_rounded,
                title:
                    'Application',
                value:
                    'Running normally',
              ),

              _SettingsCard(
                icon:
                    Icons.security_rounded,
                title:
                    'Privacy',
                value:
                    'Data stays on device',
              ),

              const SizedBox(height: 30),

              Center(
                child: Text(
                  'NIRA • Offline AI Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================
// SETTINGS SECTION TITLE
// ======================================================

class _SettingsSectionTitle
    extends StatelessWidget {

  final String title;
  final IconData icon;

  const _SettingsSectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Icon(
          icon,
          size: 21,
          color: Colors.indigo,
        ),

        const SizedBox(width: 9),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ======================================================
// SETTINGS CARD
// ======================================================

class _SettingsCard
    extends StatelessWidget {

  final IconData icon;
  final String title;
  final String value;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  Colors.indigo.shade50,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.indigo,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}