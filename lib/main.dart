import 'package:flutter/material.dart';
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
  final TextEditingController _messageController = TextEditingController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am NIRA 👋\nHow can I help you today?',
      isUser: false,
    ),
  ];

  bool _isOffline = true;

  Future<void> _sendMessage() async {
  final text = _messageController.text.trim();

  if (text.isEmpty) {
    return;
  }

  final intent = IntentRouter.classify(text);

  final profile = await DeviceProfile.getProfile();

  final method = ProcessingStrategy.selectMethod(
    profile.level,
    intent,
  );

  final methodText = ProcessingStrategy.methodText(method);

  String response;

  switch (intent) {
    case IntentType.calculator:
  final result = CalculatorService.calculate(text);

  if (result == null) {
    response =
        'Calculator route selected.\n'
        'Processing: $methodText\n'
        'I could not calculate that expression.';
  } else {
    response =
        'Calculator route selected.\n'
        'Processing: $methodText\n'
        'Result: ${CalculatorService.formatResult(result)}';
  }
  break;

    case IntentType.document:
  final ragResponse = RagService.answer(text);

  response =
      'Document route selected.\n'
      'Processing: $methodText\n'
      '$ragResponse';
  break;

    case IntentType.general:
  final gemmaResponse = GemmaService.generateResponse(text);

  response =
      'General AI route selected.\n'
      'Processing: $methodText\n'
      '$gemmaResponse';
  break;
  }

  setState(() {
    _messages.add(
      ChatMessage(
        text: text,
        isUser: true,
      ),
    );

    _messages.add(
      ChatMessage(
        text: response,
        isUser: false,
      ),
    );
  });

  _messageController.clear();
}

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              _showSettings();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Offline / device status
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _isOffline
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOffline
                      ? Colors.orange.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
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
                  const Icon(
                    Icons.battery_5_bar_rounded,
                    size: 21,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Device ready',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Welcome section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade50,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.indigo.shade100,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

            // Chat area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];

                  return _ChatBubble(
                    message: message,
                  );
                },
              ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.fromLTRB(
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
                    offset: const Offset(0, -3),
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Ask NIRA something...',
                        prefixIcon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F3F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: IconButton(
                      tooltip: 'Send',
                      onPressed: _sendMessage,
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

  void _showSettings() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const NiraSettingsPage(),
    ),
  );
}
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 310,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.indigo
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(
              message.isUser ? 17 : 4,
            ),
            bottomRight: Radius.circular(
              message.isUser ? 4 : 17,
            ),
          ),
          border: message.isUser
              ? null
              : Border.all(
                  color: Colors.grey.shade200,
                ),
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: 0.04),
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
class NiraSettingsPage extends StatelessWidget {
  const NiraSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceProfile>(
      future: DeviceProfile.getProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),

          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'NIRA Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SettingsSectionTitle(
                title: 'Device Information',
                icon: Icons.smartphone_rounded,
              ),

              const SizedBox(height: 10),

              _SettingsCard(
                icon: Icons.phone_android_rounded,
                title: 'Device',
                value: profile?.deviceName ?? 'Detecting...',
              ),

              _SettingsCard(
                icon: Icons.android_rounded,
                title: 'Platform',
                value: profile?.platform ?? 'Detecting...',
              ),

              _SettingsCard(
                icon: Icons.memory_rounded,
                title: 'Architecture',
                value: profile?.architecture ?? 'Detecting...',
              ),

              _SettingsCard(
                icon: Icons.speed_rounded,
                title: 'Device Level',
                value: profile?.levelText ?? 'Detecting...',
              ),

              const SizedBox(height: 24),

              const _SettingsSectionTitle(
                title: 'AI & Processing',
                icon: Icons.psychology_rounded,
              ),

              const SizedBox(height: 10),

              _SettingsCard(
                icon: Icons.smart_toy_rounded,
                title: 'AI Assistant',
                value: 'NIRA',
              ),

              _SettingsCard(
                icon: Icons.memory_rounded,
                title: 'Processing',
                value: 'On-device processing',
              ),

              _SettingsCard(
                icon: Icons.cloud_off_rounded,
                title: 'Network Mode',
                value: 'Offline',
              ),

              const SizedBox(height: 24),

              const _SettingsSectionTitle(
                title: 'System Status',
                icon: Icons.monitor_heart_outlined,
              ),

              const SizedBox(height: 10),

              _SettingsCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'Application',
                value: 'Running normally',
              ),

              _SettingsCard(
                icon: Icons.security_rounded,
                title: 'Privacy',
                value: 'Data stays on device',
              ),

              const SizedBox(height: 30),

              Center(
                child: Text(
                  'NIRA • Offline AI Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

class _SettingsSectionTitle extends StatelessWidget {
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.indigo,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
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