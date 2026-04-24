// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/chatbot_screen.dart
//
// The main AI chatbot interface.
// Integrates: Gemini AI + Firebase (IoT data) + Voice (STT/TTS)
//
// FEATURES:
//   ✅ Text input
//   ✅ Voice input (speak in Hindi or English)
//   ✅ Voice output (AI responses spoken aloud)
//   ✅ Real-time IoT sensor context (automatically attached to queries)
//   ✅ Smart crop advisory
//   ✅ Language switching (EN ↔ HI)
//   ✅ Streaming responses (word by word)
//   ✅ Chat history
//   ✅ Quick question chips
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../services/voice_service.dart';
import '../services/smart_advisory_service.dart';
import '../models/iot_sensor_model.dart';
import '../core/app_constants.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {

  // ── Services ───────────────────────────────────────────────────────────────
  final GeminiService         _gemini   = GeminiService();
  final FirebaseService       _firebase = FirebaseService();
  final VoiceService          _voice    = VoiceService();
  final SmartAdvisoryService  _advisory = SmartAdvisoryService();

  // ── State ──────────────────────────────────────────────────────────────────
  final List<ChatMessage>     _messages      = [];
  IoTSensorReading?           _latestSensor;
  String                      _language      = 'en';
  String                      _selectedCrop  = 'Wheat';
  bool                        _isTyping      = false;   // AI thinking
  bool                        _isStreaming   = false;   // AI streaming response
  String                      _streamBuffer  = '';      // Live streaming text
  String                      _partialSpeech = '';      // Live transcription preview
  bool                        _voiceEnabled  = true;
  bool                        _sensorConnected = false;

  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _inputCtrl    = TextEditingController();
  final ScrollController       _scrollCtrl  = ScrollController();
  late AnimationController     _pulseCtrl;
  late Animation<double>       _pulse;
  late AnimationController     _micCtrl;
  late Animation<double>       _micScale;

  // ── Quick question suggestions ─────────────────────────────────────────────
  late List<Map<String, String>> _quickQuestions;

  // ── User ID ────────────────────────────────────────────────────────────────
  static const String _userId = 'farmer_001';   // Replace with Firebase Auth UID

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupQuickQuestions();
    _initialize();
  }

  void _setupAnimations() {
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _micCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _micScale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _micCtrl, curve: Curves.easeInOut));
    _micCtrl.stop();
  }

  void _setupQuickQuestions() {
    _quickQuestions = _language == 'hi'
        ? [
            {'emoji': '💧', 'text': 'आज सिंचाई करनी चाहिए?'},
            {'emoji': '🌾', 'text': 'मेरी फसल के लिए उर्वरक?'},
            {'emoji': '🐛', 'text': 'कीट नियंत्रण कैसे करें?'},
            {'emoji': '🏛️', 'text': 'PM-KISAN योजना की जानकारी'},
            {'emoji': '📈', 'text': 'मंडी में सबसे अच्छा भाव?'},
            {'emoji': '🌡️', 'text': 'गर्मी से फसल बचाएं'},
          ]
        : [
            {'emoji': '💧', 'text': 'Should I irrigate today?'},
            {'emoji': '🌾', 'text': 'Which fertilizer for my crop?'},
            {'emoji': '🐛', 'text': 'How to control pests?'},
            {'emoji': '🏛️', 'text': 'Tell me about PM-KISAN'},
            {'emoji': '📈', 'text': 'Best time to sell in mandi?'},
            {'emoji': '🌡️', 'text': 'Protect crop from heat'},
          ];
  }

  Future<void> _initialize() async {
    // 1. Start Gemini
    _gemini.initialize();

    // 2. Set up voice callbacks
    _voice.onStateChange = (state) {
      if (mounted) setState(() {});
      if (state == VoiceState.listening) {
        _micCtrl.repeat(reverse: true);
      } else {
        _micCtrl.stop();
        _micCtrl.reset();
      }
    };
    _voice.onError = (err) => _showSnack('Voice error: $err');

    // 3. Fetch initial sensor data from Firebase
    final sensorData = await _firebase.fetchLatestSensorData();
    if (mounted && sensorData != null) {
      setState(() {
        _latestSensor    = sensorData;
        _sensorConnected = true;
      });
    }

    // 4. Start listening for real-time sensor updates
    _firebase.startSensorListener(
      onData: (IoTSensorReading reading) {
        if (mounted) {
          setState(() {
            _latestSensor    = reading;
            _sensorConnected = true;
          });
          // Auto-generate advisory if there are critical issues
          if (reading.alertLevel == 'critical') {
            _generateAutoAdvisory(reading);
          }
        }
      },
      onError: (err) {
        if (mounted) setState(() => _sensorConnected = false);
      },
    );

    // 5. Add welcome message
    _addBotMessage(_welcomeMessage());
  }

  String _welcomeMessage() {
    if (_language == 'hi') {
      return '🌾 नमस्ते! मैं KisanMitra AI हूं।\n\n'
             'मैं आपकी मदद कर सकता हूं:\n'
             '• 💧 सिंचाई और फसल प्रबंधन\n'
             '• 🏛️ सरकारी योजनाएं\n'
             '• 📈 मंडी भाव\n'
             '• 🌡️ मौसम आधारित सलाह\n\n'
             '${_latestSensor != null ? "📡 आपके खेत के सेंसर से डेटा मिल रहा है।\n" : ""}'
             'आप हिंदी या English में बात कर सकते हैं। 🎤 बोलकर भी पूछ सकते हैं!';
    }
    return '🌾 Welcome to KisanMitra AI!\n\n'
           'I can help you with:\n'
           '• 💧 Irrigation & crop management\n'
           '• 🏛️ Government schemes\n'
           '• 📈 Mandi prices\n'
           '• 🌡️ Weather-based farming advice\n\n'
           '${_latestSensor != null ? "📡 Your farm sensors are connected and live!\n" : ""}'
           'You can type or 🎤 speak your question in Hindi or English!';
  }

  // ── AUTO ADVISORY on sensor change ────────────────────────────────────────
  Future<void> _generateAutoAdvisory(IoTSensorReading sensor) async {
    // Don't flood with messages — only if significant time has passed
    final alerts = _advisory.generateInstantAlerts(
        sensor: sensor, cropType: _selectedCrop);
    final critical = alerts.where((a) => a.level == AlertLevel.critical);

    if (critical.isNotEmpty) {
      final alertText = critical
          .map((a) => '${a.emoji} **${a.title}**\n${a.description}')
          .join('\n\n');

      _addBotMessage('🚨 **AUTOMATIC FARM ALERT**\n\n$alertText');
    }
  }

  // ── SEND MESSAGE ──────────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    final userMsg = text.trim();
    _inputCtrl.clear();

    // Add user message to chat
    _addUserMessage(userMsg);
    setState(() { _isTyping = true; _isStreaming = false; _streamBuffer = ''; });
    _scrollToBottom();

    // Build placeholder for streaming response
    final streamMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(ChatMessage(
      id:             streamMsgId,
      text:           '',
      role:           MessageRole.assistant,
      timestamp:      DateTime.now(),
      sensorSnapshot: _latestSensor,
    ));

    try {
      setState(() { _isTyping = false; _isStreaming = true; });

      // Stream Gemini response word by word
      await for (final chunk in _gemini.sendMessageStream(
        userMessage: userMsg,
        sensorData:  _latestSensor,
        cropType:    _selectedCrop,
        language:    _language,
      )) {
        _streamBuffer += chunk;
        // Update the streaming message
        final idx = _messages.indexWhere((m) => m.id == streamMsgId);
        if (idx >= 0) {
          _messages[idx] = ChatMessage(
            id:             streamMsgId,
            text:           _streamBuffer,
            role:           MessageRole.assistant,
            timestamp:      DateTime.now(),
            sensorSnapshot: _latestSensor,
          );
        }
        if (mounted) setState(() {});
        _scrollToBottom();
      }

      setState(() { _isStreaming = false; });

      // Speak the response if voice output is enabled
      if (_voiceEnabled && _streamBuffer.isNotEmpty) {
        await _voice.speak(text: _streamBuffer, language: _language);
      }

      // Save to Firebase
      _firebase.saveChatMessage(
        userId:  _userId,
        message: _messages.firstWhere((m) => m.id == streamMsgId),
      );

    } catch (e) {
      setState(() { _isTyping = false; _isStreaming = false; });
      final idx = _messages.indexWhere((m) => m.id == streamMsgId);
      if (idx >= 0) {
        _messages[idx] = ChatMessage(
          id:        streamMsgId,
          text:      '❌ Error: $e',
          role:      MessageRole.assistant,
          timestamp: DateTime.now(),
        );
      }
      if (mounted) setState(() {});
    }
  }

  // ── VOICE INPUT ───────────────────────────────────────────────────────────
  Future<void> _toggleVoiceInput() async {
    if (_voice.isListening) {
      await _voice.stopListening();
      return;
    }

    // Stop TTS if speaking
    if (_voice.isSpeaking) await _voice.stopSpeaking();

    HapticFeedback.mediumImpact();

    await _voice.startListening(
      language:          _language,
      onResult:          (text) {
        if (text.isNotEmpty) {
          setState(() => _partialSpeech = '');
          _sendMessage(text);
        }
      },
      onPartialResult: (partial) {
        if (mounted) setState(() => _partialSpeech = partial);
      },
    );
  }

  // ── ADD MESSAGES ──────────────────────────────────────────────────────────
  void _addUserMessage(String text) {
    _messages.add(ChatMessage(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      text:      text,
      role:      MessageRole.user,
      timestamp: DateTime.now(),
      isVoice:   _voice.isListening,
    ));
    if (mounted) setState(() {});
  }

  void _addBotMessage(String text) {
    _messages.add(ChatMessage(
      id:             DateTime.now().millisecondsSinceEpoch.toString(),
      text:           text,
      role:           MessageRole.assistant,
      timestamp:      DateTime.now(),
      sensorSnapshot: _latestSensor,
    ));
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          if (_latestSensor != null) _buildSensorBanner(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[i]);
                    },
                  ),
          ),
          if (_partialSpeech.isNotEmpty) _buildLiveTranscription(),
          if (_messages.length <= 2) _buildQuickChips(),
          _buildInputBar(),
        ]),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('KisanMitra AI',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A))),
        Row(children: [
          Container(width: 6, height: 6,
              decoration: const BoxDecoration(shape: BoxShape.circle,
                  color: Color(0xFF4CAF50))),
          const SizedBox(width: 5),
          Text(_sensorConnected
              ? 'Live farm data connected'
              : 'Online · Gemini powered',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
        ]),
      ])),

      // Language toggle
      GestureDetector(
        onTap: () {
          setState(() {
            _language = _language == 'en' ? 'hi' : 'en';
            _setupQuickQuestions();
            _voice.initTTS(language: _language);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_language == 'en' ? '🇬🇧 EN' : '🇮🇳 HI',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32))),
        ),
      ),
      const SizedBox(width: 8),

      // Voice output toggle
      GestureDetector(
        onTap: () => setState(() => _voiceEnabled = !_voiceEnabled),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (_voiceEnabled
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceEnabled ? Colors.white : Colors.grey,
              size: 18),
        ),
      ),
      const SizedBox(width: 8),

      // Crop selector
      GestureDetector(
        onTap: _showCropPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🌾', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(_selectedCrop,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
          ]),
        ),
      ),
    ]),
  );

  // ── SENSOR BANNER ──────────────────────────────────────────────────────────
  Widget _buildSensorBanner() {
    final s   = _latestSensor!;
    final lvl = s.alertLevel;
    final color = lvl == 'critical'
        ? const Color(0xFFC62828)
        : lvl == 'warning'
            ? const Color(0xFFF57F17)
            : const Color(0xFF2E7D32);

    return GestureDetector(
      onTap: () => _sendMessage(
          _language == 'hi'
              ? 'मेरे खेत के सेंसर डेटा के अनुसार क्या करूं? फसल: $_selectedCrop'
              : 'Based on my farm sensor data, what should I do? Crop: $_selectedCrop'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          ScaleTransition(
            scale: _pulse,
            child: Container(width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '📡 Live: ${s.summaryText}',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          )),
          Text('Tap for advice →',
              style: TextStyle(fontSize: 10.5, color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🌾', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text(_language == 'hi' ? 'KisanMitra AI से पूछें' : 'Ask KisanMitra AI',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A))),
      const SizedBox(height: 8),
      Text(_language == 'hi'
          ? 'खेती की कोई भी समस्या बताएं'
          : 'Ask anything about your farm',
          style: TextStyle(fontSize: 14, color: Colors.grey[500])),
    ]),
  );

  // ── MESSAGE BUBBLE ─────────────────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(isUser ? 20 * (1 - v) : -20 * (1 - v), 0),
            child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft:     const Radius.circular(16),
                        topRight:    const Radius.circular(16),
                        bottomLeft:  Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      boxShadow: [BoxShadow(
                          color: (isUser
                              ? const Color(0xFF2E7D32) : Colors.black)
                              .withOpacity(0.08),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Text(
                      msg.text.isEmpty && _isStreaming ? '...' : msg.text,
                      style: TextStyle(
                        fontSize: 14, height: 1.55,
                        color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.isVoice)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.mic_rounded, size: 10,
                              color: Colors.grey[400]),
                        ),
                      Text(
                        DateFormat('h:mm a').format(msg.timestamp),
                        style: TextStyle(fontSize: 10.5, color: Colors.grey[400]),
                      ),
                      // Speak button for bot messages
                      if (!isUser) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _voice.speak(
                              text: msg.text, language: _language),
                          child: Icon(Icons.volume_up_rounded, size: 13,
                              color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ── TYPING INDICATOR ───────────────────────────────────────────────────────
  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16),
            bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1.0).animate(
              CurvedAnimation(parent: _pulseCtrl,
                  curve: Interval(i * 0.2, 0.6 + i * 0.2,
                      curve: Curves.easeInOut)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8, height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey[400]),
            ),
          )),
        ),
      ),
    ]),
  );

  // ── LIVE TRANSCRIPTION ─────────────────────────────────────────────────────
  Widget _buildLiveTranscription() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF2E7D32).withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      ScaleTransition(
        scale: _micScale,
        child: const Icon(Icons.mic_rounded,
            color: Color(0xFF2E7D32), size: 16),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(_partialSpeech,
            style: const TextStyle(fontSize: 13,
                color: Color(0xFF2E7D32), fontStyle: FontStyle.italic)),
      ),
    ]),
  );

  // ── QUICK CHIPS ────────────────────────────────────────────────────────────
  Widget _buildQuickChips() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Text(
          _language == 'hi' ? 'जल्दी पूछें:' : 'Quick questions:',
          style: TextStyle(fontSize: 12, color: Colors.grey[500],
              fontWeight: FontWeight.w500),
        ),
      ),
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _quickQuestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final q = _quickQuestions[i];
            return GestureDetector(
              onTap: () => _sendMessage(q['text']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(q['emoji']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(q['text']!, style: TextStyle(fontSize: 12,
                      color: Colors.grey[700], fontWeight: FontWeight.w500)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 6),
    ],
  );

  // ── INPUT BAR ──────────────────────────────────────────────────────────────
  Widget _buildInputBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: Row(children: [
      // Voice input button
      GestureDetector(
        onTap: _toggleVoiceInput,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: _voice.isListening
                ? const Color(0xFFD32F2F)
                : const Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _voice.isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: _voice.isListening
                ? Colors.white : const Color(0xFF2E7D32),
            size: 22,
          ),
        ),
      ),
      const SizedBox(width: 8),

      // Text input field
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _inputCtrl,
            maxLines: 4, minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: _language == 'hi'
                  ? 'कुछ भी पूछें...' : 'Ask anything about farming...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
            onSubmitted: _sendMessage,
          ),
        ),
      ),
      const SizedBox(width: 8),

      // Send button
      GestureDetector(
        onTap: () => _sendMessage(_inputCtrl.text),
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ]),
  );

  // ── CROP PICKER ────────────────────────────────────────────────────────────
  void _showCropPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_language == 'hi' ? 'फसल चुनें' : 'Select Your Crop',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: AppConstants.supportedCrops.map((crop) {
              final sel = _selectedCrop == crop;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCrop = crop);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? const Color(0xFF2E7D32) : Colors.grey.shade300),
                  ),
                  child: Text(crop,
                      style: TextStyle(fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _firebase.stopSensorListener();
    _voice.dispose();
    _pulseCtrl.dispose();
    _micCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
