import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'router/intent_router.dart';
import 'device/device_profile.dart';
import 'processing/processing_strategy.dart';
import 'calculator/calculator_service.dart';
import 'math/math_service.dart';
import 'rag/rag_service.dart';
import 'gemma/gemma_service.dart';

enum NiraLanguage {
  english,
  telugu,
}

class NiraLanguageSettings {
  static final ValueNotifier<NiraLanguage> selected =
      ValueNotifier<NiraLanguage>(NiraLanguage.english);

  static String get displayName {
    switch (selected.value) {
      case NiraLanguage.english:
        return 'English';

      case NiraLanguage.telugu:
        return 'తెలుగు';
    }
  }

  static String instructionFor(
    NiraLanguage language,
  ) {
    switch (language) {
      case NiraLanguage.english:
        return '''
Respond only in English.
Do not use Greek, Telugu, Hindi, or any other language.
''';

      case NiraLanguage.telugu:
        return '''
Respond ONLY in Telugu (తెలుగు).
Use natural, simple Telugu.
Do NOT respond in Greek, Hindi, English, or any other language.
Keep numbers, formulas, and mathematical expressions unchanged.
''';
    }
  }
}
void main() {
  runApp(const NiraApp());
}

// ============================================================
// NIRA COLORS
// ============================================================

const Color niraNavy = Color(0xFF202C63);
const Color niraPurple = Color(0xFF5A58D6);
const Color niraLightPurple = Color(0xFFEEEEFF);
const Color niraBackground = Color(0xFFF8F8FC);
const Color niraText = Color(0xFF292B3A);
const Color niraGrey = Color(0xFF9295A8);




// ============================================================
// APP
// ============================================================

class NiraApp extends StatelessWidget {
  const NiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NIRA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: niraBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: niraPurple,
        ),
      ),
      home: const NiraHomePage(),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class NiraHomePage extends StatefulWidget {
  const NiraHomePage({super.key});

  @override
  State<NiraHomePage> createState() => _NiraHomePageState();
}

class _NiraHomePageState extends State<NiraHomePage> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // ==========================================================
  // NETWORK
  // ==========================================================

  bool _isOffline = true;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  // ==========================================================
  // BATTERY
  // ==========================================================

  final Battery _battery = Battery();

  int _batteryLevel = 100;

  StreamSubscription<BatteryState>?
      _batterySubscription;

  // ==========================================================
  // DOCUMENT
  // ==========================================================

  String? _documentName;

  // ==========================================================
  // BOTTOM NAV
  // ==========================================================

  int _bottomIndex = 0;

  // ==========================================================
  // CHAT
  // ==========================================================

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hi! I'm NIRA 👋\n"
          "Your offline AI assistant.\n"
          "How can I help you today?",
      isUser: false,
      showActions: false,
    ),
  ];

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(
      (results) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isOffline =
              results.contains(
            ConnectivityResult.none,
          );
        });
      },
    );

    _checkConnectivity();

    _loadBatteryLevel();

    _batterySubscription =
        _battery.onBatteryStateChanged.listen(
      (_) {
        _loadBatteryLevel();
      },
    );
  }

  // ==========================================================
  // CONNECTIVITY
  // ==========================================================

  Future<void> _checkConnectivity() async {
    final results =
        await Connectivity().checkConnectivity();

    if (!mounted) {
      return;
    }

    setState(() {
      _isOffline =
          results.contains(
        ConnectivityResult.none,
      );
    });
  }

  // ==========================================================
  // BATTERY
  // ==========================================================

  Future<void> _loadBatteryLevel() async {
    try {
      final level =
          await _battery.batteryLevel;

      if (!mounted) {
        return;
      }

      setState(() {
        _batteryLevel = level;
      });
    } catch (_) {
      // Keep previous value.
    }
  }

  // ==========================================================
  // PDF PICKER
  // ==========================================================

  Future<void> _pickAndIngestPdfs() async {
    try {
      final files =
          await FilePicker.pickFiles(
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
                'Loading ${files.length} PDF'
                '${files.length == 1 ? '' : 's'}...',
            isUser: false,
            showActions: false,
          ),
        );
      });

      var successCount = 0;

      final failedFiles =
          <String>[];

      for (final file in files) {
        final path = file.path;

        if (path == null || path.isEmpty) {
          failedFiles.add(
            file.name,
          );
          continue;
        }

        final response =
            await RagService.ingestPdf(
          pdfPath: path,
          filename: file.name,
        );

        if (response.startsWith(
          'PDF loaded successfully.',
        )) {
          successCount++;

          _documentName =
              file.name;
        } else {
          failedFiles.add(
            file.name,
          );
        }
      }

      if (!mounted) {
        return;
      }

      final message =
          StringBuffer();

      if (successCount > 0) {
        message.write(
          'Document ready ✓\n\n',
        );

        message.write(
          _documentName ??
              'PDF loaded successfully.',
        );

        message.write(
          '\n\nYou can now ask NIRA questions about this document.',
        );
      } else {
        message.write(
          'I could not load the PDF.',
        );
      }

      if (failedFiles.isNotEmpty) {
        message.write(
          '\n\nFailed: '
          '${failedFiles.join(', ')}',
        );
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                message.toString(),
            isUser: false,
            showActions: false,
          ),
        );
      });

      _scrollToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _addAssistantMessage(
        'I could not upload the PDF. Please try again.',
        showActions: false,
      );
    }
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> _sendMessage() async {
    final text =
        _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    // Add user message immediately.
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          showActions: false,
        ),
      );
    });

    _messageController.clear();

    _scrollToBottom();

    // --------------------------------------------------------
    // ROUTE THE QUESTION
    // --------------------------------------------------------

    final intent =
        IntentRouter.classify(text);

    final profile =
        await DeviceProfile.getProfile();

    final method =
        ProcessingStrategy.selectMethod(
      profile.level,
      intent,
    );

    final methodText =
        ProcessingStrategy.methodText(
      method,
    );

    String response;

    switch (intent) {
      // ======================================================
      // MATH
      // ======================================================

      case IntentType.calculator:
        final mathResponse =
            MathService.solve(text);

        if (mathResponse != null) {
          response =
              mathResponse;
        } else {
          final result =
              CalculatorService.calculate(
            text,
          );

          if (result == null) {
            response =
                'I could not solve this mathematical expression.';
          } else {
            response =
                'Answer\n\n'
                '${CalculatorService.formatResult(result)}';
          }
        }

        break;

      // ======================================================
      // DOCUMENT / RAG
      // ======================================================

      case IntentType.document:
        response =
            await RagService.answer(
          text,
        );

        break;

      // ======================================================
      // GENERAL / GEMMA
      // ======================================================

      case IntentType.general:
        response =
            await GemmaService.generateResponse(
          '${NiraLanguageSettings.instructionFor(NiraLanguageSettings.selected.value)}\n\n'
          'User question: $text',
        );

        break;
    }

    // Add processing information only when
    // it is useful and not intrusive.
    if (intent == IntentType.calculator) {
      response =
          '$response\n\n'
          'Processing: $methodText';
    }

    _addAssistantMessage(
      response,
    );
  }

  // ==========================================================
  // ADD ASSISTANT MESSAGE
  // ==========================================================

  void _addAssistantMessage(
    String text, {
    bool showActions = true,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          showActions: showActions,
        ),
      );
    });

    _scrollToBottom();
  }

  // ==========================================================
  // SCROLL
  // ==========================================================

  void _scrollToBottom() {
    Future.delayed(
      const Duration(
        milliseconds: 100,
      ),
      () {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
            milliseconds: 300,
          ),
          curve:
              Curves.easeOut,
        );
      },
    );
  }

  // ==========================================================
  // SETTINGS
  // ==========================================================

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NiraSettingsPage(),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _header() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        10,
        13,
        3,
      ),
      child: Row(
        children: [
          // NIRA LOGO
          const NiraLogo(
            size: 45,
          ),

          const SizedBox(
            width: 8,
          ),

          // NIRA TEXT
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'NIRA',
                  style:
                      const TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing:
                        1.7,
                    color:
                        niraNavy,

                    // If a Hobo font is later
                    // added to the project, this
                    // can be changed to:
                    //
                    // fontFamily: 'Hobo',
                  ),
                ),

                const SizedBox(
                  height: 0,
                ),

                const Text(
                  'Your Offline AI Assistant',
                  style:
                      TextStyle(
                    fontSize: 9,
                    color:
                        niraGrey,
                    letterSpacing:
                        0.1,
                  ),
                ),
              ],
            ),
          ),

          // SETTINGS
          IconButton(
            onPressed:
                _openSettings,
            padding:
                EdgeInsets.zero,
            constraints:
                const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            icon:
                const Icon(
              Icons.settings_outlined,
              size: 24,
              color:
                  niraNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  Widget _statusRow() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        47,
        0,
        18,
        7,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(
              color: _isOffline
                  ? const Color(
                      0xFF4D9BFF,
                    )
                  : const Color(
                      0xFF45B96B,
                    ),
              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            _isOffline
                ? 'Offline'
                : 'Online',
            style:
                const TextStyle(
              fontSize: 9,
              color:
                  niraGrey,
            ),
          ),

          const Spacer(),

          Icon(
            _batteryLevel >= 80
                ? Icons
                    .battery_full_rounded
                : _batteryLevel >= 50
                    ? Icons
                        .battery_5_bar_rounded
                    : Icons
                        .battery_2_bar_rounded,
            size: 14,
            color:
                niraGrey,
          ),

          const SizedBox(
            width: 3,
          ),

          Text(
            '$_batteryLevel%',
            style:
                const TextStyle(
              fontSize: 9,
              color:
                  niraGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CHAT AREA
  // ==========================================================

  Widget _chatArea() {
    return Expanded(
      child: ListView.builder(
        controller:
            _scrollController,
        padding:
            const EdgeInsets.fromLTRB(
          16,
          7,
          14,
          8,
        ),
        itemCount:
            _messages.length,
        itemBuilder:
            (context, index) {
          return _ChatBubble(
            message:
                _messages[index],
          );
        },
      ),
    );
  }

  // ==========================================================
  // INPUT AREA
  // ==========================================================

  Widget _inputArea() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        11,
        8,
        11,
        9,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset:
                const Offset(
              0,
              -2,
            ),
            color:
                Colors.black
                    .withValues(
              alpha: 0.04,
            ),
          ),
        ],
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          // ==================================================
          // DOCUMENT BUTTON
          // ==================================================

          GestureDetector(
            onTap:
                _pickAndIngestPdfs,
            child:
                Container(
              width: 45,
              height: 45,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF0F0FF,
                ),
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFE0E0F4,
                  ),
                ),
              ),
              child:
                  const Center(
                child:
                    NiraDocumentIcon(
                  size: 22,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ==================================================
          // TEXT FIELD
          // ==================================================

          Expanded(
            child:
                TextField(
              controller:
                  _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction:
                  TextInputAction.newline,
              decoration:
                  InputDecoration(
                hintText:
                    'Ask NIRA anything...',
                hintStyle:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      niraGrey,
                ),
                filled: true,
                fillColor:
                    const Color(
                  0xFFF1F2F7,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    23,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ==================================================
          // SEND
          // ==================================================

          GestureDetector(
            onTap:
                _sendMessage,
            child:
                Container(
              width: 46,
              height: 46,
              decoration:
                  const BoxDecoration(
                color:
                    niraPurple,
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons.send_rounded,
                color:
                    Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAV
  // ==========================================================

  Widget _bottomNavigation() {
    return Container(
      height: 65,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        border:
            Border(
          top:
              BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),
      ),
      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _bottomItem(
            icon:
                Icons.home_rounded,
            label:
                'Home',
            index:
                0,
          ),

          _bottomItem(
            icon:
                Icons.history_rounded,
            label:
                'History',
            index:
                1,
          ),

          _bottomItem(
            icon:
                Icons.person_outline_rounded,
            label:
                'Profile',
            index:
                2,
          ),
        ],
      ),
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected =
        _bottomIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          _openSettings();
          return;
        }

        setState(() {
          _bottomIndex = index;
        });
      },
      child:
          SizedBox(
        width: 85,
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color:
                  selected
                      ? niraPurple
                      : const Color(
                          0xFF737689,
                        ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              label,
              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                color:
                    selected
                        ? niraPurple
                        : const Color(
                            0xFF737689,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          niraBackground,

      body:
          SafeArea(
        child:
            Column(
          children: [
            // HEADER
            _header(),

            // STATUS
            _statusRow(),

            // CHAT
            _chatArea(),

            // INPUT
            _inputArea(),
          ],
        ),
      ),

      bottomNavigationBar:
          _bottomNavigation(),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _connectivitySubscription
        ?.cancel();

    _batterySubscription
        ?.cancel();

    _messageController
        .dispose();

    _scrollController
        .dispose();

    super.dispose();
  }
}

// ============================================================
// CHAT MESSAGE
// ============================================================

class ChatMessage {
  final String text;
  final bool isUser;
  final bool showActions;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.showActions = true,
  });
}

// ============================================================
// CHAT BUBBLE
// ============================================================

class _ChatBubble
    extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    // ========================================================
    // USER MESSAGE
    // ========================================================

    if (message.isUser) {
      return Align(
        alignment:
            Alignment.centerRight,
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Container(
              constraints:
                  const BoxConstraints(
                maxWidth: 285,
              ),
              margin:
                  const EdgeInsets.only(
                bottom: 3,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 11,
              ),
              decoration:
                  const BoxDecoration(
                color:
                    niraPurple,
                borderRadius:
                    BorderRadius.only(
                  topLeft:
                      Radius.circular(18),
                  topRight:
                      Radius.circular(18),
                  bottomLeft:
                      Radius.circular(18),
                  bottomRight:
                      Radius.circular(5),
                ),
              ),
              child:
                  Text(
                message.text,
                style:
                    const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color:
                      Colors.white,
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.only(
                right: 7,
                bottom: 9,
              ),
              child:
                  Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: const [
                  Text(
                    'Now',
                    style:
                        TextStyle(
                      fontSize: 9,
                      color:
                          niraGrey,
                    ),
                  ),
                  SizedBox(
                    width: 3,
                  ),
                  Icon(
                    Icons.done_rounded,
                    size: 12,
                    color:
                        niraGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ========================================================
    // NIRA MESSAGE
    // ========================================================

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 13,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // NIRA AVATAR
          Container(
            width: 34,
            height: 34,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFF0F1FF),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Center(
              child:
                  NiraLogo(
                size: 23,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // AI CARD
          Flexible(
            child:
                Container(
              constraints:
                  const BoxConstraints(
                maxWidth: 310,
              ),
              padding:
                  const EdgeInsets.fromLTRB(
                13,
                12,
                13,
                10,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    const BorderRadius.only(
                  topLeft:
                      Radius.circular(5),
                  topRight:
                      Radius.circular(18),
                  bottomLeft:
                      Radius.circular(18),
                  bottomRight:
                      Radius.circular(18),
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFE2E3EB,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 7,
                    offset:
                        const Offset(
                      0,
                      2,
                    ),
                    color:
                        Colors.black
                            .withValues(
                      alpha: 0.035,
                    ),
                  ),
                ],
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _formattedText(
                    message.text,
                  ),

                  if (message.showActions)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 11,
                      ),
                      child:
                          Row(
                        children: [
                          _actionButton(
                            Icons
                                .content_copy_outlined,
                          ),
                          _actionButton(
                            Icons
                                .thumb_up_outlined,
                          ),
                          _actionButton(
                            Icons
                                .thumb_down_outlined,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMATTED MESSAGE
  // ==========================================================

  Widget _formattedText(
    String text,
  ) {
    final lines =
        text.split('\n');

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children:
          lines.map(
        (line) {
          final trimmed =
              line.trim();

          final isHeading =
              trimmed ==
                      'Answer' ||
                  trimmed ==
                      'Final Answer:' ||
                  trimmed ==
                      'Main Topics' ||
                  trimmed ==
                      'Key Points' ||
                  trimmed ==
                      'Given equation:' ||
                  trimmed.startsWith(
                    'Step ',
                  );

          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 2,
            ),
            child:
                Text(
              line,
              style:
                  TextStyle(
                fontSize: 13,
                height: 1.45,
                color:
                    isHeading
                        ? niraNavy
                        : niraText,
                fontWeight:
                    isHeading
                        ? FontWeight.w700
                        : FontWeight.w400,
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton(
    IconData icon,
  ) {
    return Container(
      width: 32,
      height: 28,
      margin:
          const EdgeInsets.only(
        right: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF4F4F9),
        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),
      child:
          Icon(
        icon,
        size: 15,
        color:
            const Color(0xFF656879),
      ),
    );
  }
}

// ============================================================
// NIRA LOGO
//
// IMPORTANT:
// This is the geometric N logo from your reference image.
// It is NOT a bird.
// ============================================================

class NiraLogo
    extends StatelessWidget {
  final double size;

  const NiraLogo({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width:
          size,
      height:
          size,
      child:
          CustomPaint(
        painter:
            _NiraLogoPainter(),
      ),
    );
  }
}

// ============================================================
// NIRA LOGO PAINTER
// ============================================================

class _NiraLogoPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final s =
        size.width / 100;

    final navy =
        Paint()
          ..color =
              niraNavy
          ..style =
              PaintingStyle.fill;

    // ========================================================
    // LEFT CURVED STEM
    // ========================================================

    final leftStem =
        Path();

    leftStem.moveTo(
      24 * s,
      22 * s,
    );

    leftStem.cubicTo(
      21 * s,
      31 * s,
      21 * s,
      43 * s,
      22 * s,
      54 * s,
    );

    leftStem.cubicTo(
      23 * s,
      65 * s,
      27 * s,
      74 * s,
      37 * s,
      80 * s,
    );

    leftStem.cubicTo(
      31 * s,
      78 * s,
      25 * s,
      73 * s,
      22 * s,
      67 * s,
    );

    leftStem.cubicTo(
      18 * s,
      59 * s,
      17 * s,
      46 * s,
      18 * s,
      34 * s,
    );

    leftStem.cubicTo(
      19 * s,
      28 * s,
      21 * s,
      24 * s,
      24 * s,
      22 * s,
    );

    leftStem.close();

    canvas.drawPath(
      leftStem,
      navy,
    );

    // ========================================================
    // MAIN DIAGONAL N
    // ========================================================

    final diagonal =
        Path();

    diagonal.moveTo(
      23 * s,
      21 * s,
    );

    diagonal.lineTo(
      34 * s,
      21 * s,
    );

    diagonal.cubicTo(
      43 * s,
      30 * s,
      53 * s,
      41 * s,
      62 * s,
      51 * s,
    );

    diagonal.cubicTo(
      70 * s,
      60 * s,
      77 * s,
      67 * s,
      84 * s,
      72 * s,
    );

    diagonal.lineTo(
      84 * s,
      82 * s,
    );

    diagonal.cubicTo(
      74 * s,
      78 * s,
      65 * s,
      72 * s,
      57 * s,
      64 * s,
    );

    diagonal.cubicTo(
      47 * s,
      54 * s,
      38 * s,
      43 * s,
      30 * s,
      33 * s,
    );

    diagonal.close();

    canvas.drawPath(
      diagonal,
      navy,
    );

    // ========================================================
    // RIGHT VERTICAL STEM
    // ========================================================

    final rightStem =
        Path();

    rightStem.moveTo(
      71 * s,
      28 * s,
    );

    rightStem.lineTo(
      84 * s,
      28 * s,
    );

    rightStem.lineTo(
      84 * s,
      82 * s,
    );

    rightStem.cubicTo(
      79 * s,
      80 * s,
      75 * s,
      77 * s,
      71 * s,
      73 * s,
    );

    rightStem.close();

    canvas.drawPath(
      rightStem,
      navy,
    );

    // ========================================================
    // WHITE NEGATIVE SPACE
    // ========================================================

    final white =
        Paint()
          ..color =
              niraBackground
          ..style =
              PaintingStyle.fill;

    final cut =
        Path();

    cut.moveTo(
      29 * s,
      22 * s,
    );

    cut.lineTo(
      40 * s,
      22 * s,
    );

    cut.cubicTo(
      49 * s,
      32 * s,
      58 * s,
      42 * s,
      68 * s,
      53 * s,
    );

    cut.lineTo(
      71 * s,
      56 * s,
    );

    cut.lineTo(
      71 * s,
      70 * s,
    );

    cut.cubicTo(
      62 * s,
      63 * s,
      54 * s,
      54 * s,
      46 * s,
      45 * s,
    );

    cut.cubicTo(
      39 * s,
      37 * s,
      33 * s,
      29 * s,
      29 * s,
      22 * s,
    );

    cut.close();

    canvas.drawPath(
      cut,
      white,
    );

    // ========================================================
    // SPARKLE
    // ========================================================

    final sparkle =
        Paint()
          ..color =
              niraNavy
          ..style =
              PaintingStyle.fill;

    final cx =
        78 * s;

    final cy =
        12 * s;

    final outerRadius =
        9 * s;

    final innerRadius =
        2.3 * s;

    final star =
        Path();

    for (int i = 0;
        i < 8;
        i++) {
      final angle =
          -math.pi / 2 +
              i * math.pi / 4;

      final radius =
          i.isEven
              ? outerRadius
              : innerRadius;

      final x =
          cx +
              math.cos(angle) *
                  radius;

      final y =
          cy +
              math.sin(angle) *
                  radius;

      if (i == 0) {
        star.moveTo(
          x,
          y,
        );
      } else {
        star.lineTo(
          x,
          y,
        );
      }
    }

    star.close();

    canvas.drawPath(
      star,
      sparkle,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================
// CUTE DOCUMENT ICON
// ============================================================

class NiraDocumentIcon
    extends StatelessWidget {
  final double size;

  const NiraDocumentIcon({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return CustomPaint(
      size:
          Size.square(size),
      painter:
          _NiraDocumentIconPainter(),
    );
  }
}

class _NiraDocumentIconPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final s =
        size.width / 24;

    final paint =
        Paint()
          ..color =
              niraNavy
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              1.8 * s
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round;

    final page =
        Path();

    page.moveTo(
      6 * s,
      3 * s,
    );

    page.lineTo(
      15 * s,
      3 * s,
    );

    page.lineTo(
      19 * s,
      7 * s,
    );

    page.lineTo(
      19 * s,
      21 * s,
    );

    page.lineTo(
      6 * s,
      21 * s,
    );

    page.close();

    canvas.drawPath(
      page,
      paint,
    );

    // Folded corner
    final fold =
        Path();

    fold.moveTo(
      15 * s,
      3 * s,
    );

    fold.lineTo(
      15 * s,
      7 * s,
    );

    fold.lineTo(
      19 * s,
      7 * s,
    );

    canvas.drawPath(
      fold,
      paint,
    );

    // Small document lines
    canvas.drawLine(
      Offset(
        9 * s,
        11 * s,
      ),
      Offset(
        16 * s,
        11 * s,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        9 * s,
        14.5 * s,
      ),
      Offset(
        16 * s,
        14.5 * s,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        9 * s,
        18 * s,
      ),
      Offset(
        14 * s,
        18 * s,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================
// SETTINGS PAGE
// ============================================================

class NiraSettingsPage
    extends StatelessWidget {
  const NiraSettingsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<DeviceProfile>(
      future:
          DeviceProfile.getProfile(),
      builder:
          (context, snapshot) {
        final profile =
            snapshot.data;

        return Scaffold(
          backgroundColor:
              niraBackground,

          appBar:
              AppBar(
            backgroundColor:
                Colors.white,
            surfaceTintColor:
                Colors.white,
            elevation: 0,

            leading:
                IconButton(
              icon:
                  const Icon(
                Icons
                    .arrow_back_rounded,
              ),
              onPressed:
                  () {
                Navigator.pop(
                  context,
                );
              },
            ),

            title:
                const Text(
              'NIRA Settings',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                color:
                    niraNavy,
              ),
            ),
          ),

          body:
              ListView(
            padding:
                const EdgeInsets.all(
              16,
            ),
            children: [
              const _SettingsSectionTitle(
                title:
                    'Device Information',
                icon:
                    Icons
                        .smartphone_rounded,
              ),

              const SizedBox(
                height: 10,
              ),

              _SettingsCard(
                icon:
                    Icons
                        .phone_android_rounded,
                title:
                    'Device',
                value:
                    profile?.deviceName ??
                        'Detecting...',
              ),

              _SettingsCard(
                icon:
                    Icons
                        .android_rounded,
                title:
                    'Platform',
                value:
                    profile?.platform ??
                        'Detecting...',
              ),

              _SettingsCard(
                icon:
                    Icons
                        .memory_rounded,
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

              const SizedBox(
                height: 24,
              ),

              const _SettingsSectionTitle(
                title:
                    'AI & Processing',
                icon:
                    Icons
                        .psychology_rounded,
              ),

              const SizedBox(
                height: 10,
              ),

              const _SettingsCard(
                icon:
                    Icons
                        .smart_toy_rounded,
                title:
                    'AI Assistant',
                value:
                    'NIRA',
              ),

              const _SettingsCard(
                icon:
                    Icons
                        .memory_rounded,
                title:
                    'Processing',
                value:
                    'On-device processing',
              ),

              const _SettingsCard(
                icon:
                    Icons
                        .cloud_off_rounded,
                title:
                    'Network Mode',
                value:
                    'Offline',
              ),


              const SizedBox(
                height: 10,
              ),

              const _SettingsSectionTitle(
                title:
                    'Language',
                icon:
                    Icons
                        .translate_rounded,
              ),

              const SizedBox(
                height: 10,
              ),

              const _LanguageCard(),

              const SizedBox(
                height: 24,
              ),

              const _SettingsSectionTitle(
                title:
                    'System Status',
                icon:
                    Icons
                        .monitor_heart_outlined,
              ),

              const SizedBox(
                height: 10,
              ),

              const _SettingsCard(
                icon:
                    Icons
                        .check_circle_outline_rounded,
                title:
                    'Application',
                value:
                    'Running normally',
              ),

              const _SettingsCard(
                icon:
                    Icons
                        .security_rounded,
                title:
                    'Privacy',
                value:
                    'Data stays on device',
              ),

              const SizedBox(
                height: 30,
              ),

              Center(
                child:
                    Column(
                  children: [
                    const NiraLogo(
                      size: 45,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'NIRA',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing:
                            2,
                        color:
                            niraNavy,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Your Offline AI Assistant',
                      style:
                          TextStyle(
                        fontSize: 10,
                        color:
                            Colors.grey.shade600,
                        letterSpacing:
                            0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// LANGUAGE CARD
// ============================================================

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NiraLanguage>(
      valueListenable: NiraLanguageSettings.selected,
      builder: (context, language, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE5E6EF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: niraPurple,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Response Language',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: niraText,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Choose how NIRA responds',
                      style: TextStyle(
                        fontSize: 12,
                        color: niraGrey,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<NiraLanguage>(
                  value: language,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: niraNavy,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: NiraLanguage.english,
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: NiraLanguage.telugu,
                      child: Text('తెలుగు'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      NiraLanguageSettings.selected.value = value;
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// SETTINGS SECTION TITLE
// ============================================================

class _SettingsSectionTitle
    extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SettingsSectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color:
              niraPurple,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          title,
          style:
              const TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
            color:
                niraNavy,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SETTINGS CARD
// ============================================================

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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE5E6EF,
          ),
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF0F0FF,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  niraPurple,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        niraText,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        niraGrey,
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