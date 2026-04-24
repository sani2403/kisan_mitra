import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;
  late AnimationController _typingCtrl;
  late Animation<double> _typingFade;

  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text': 'नमस्ते! 👋 I am your KisanMitra AI Assistant.\n\nI can help you with:\n• Crop disease identification\n• Pest control advice\n• Weather-based farming tips\n• Government scheme eligibility\n• Market price analysis\n\nHow can I assist you today?',
      'time': '10:00 AM',
    },
  ];

  final _quickReplies = [
    {'emoji': '🌱', 'text': 'Best crops for this season?'},
    {'emoji': '🐛', 'text': 'My crop has yellow leaves'},
    {'emoji': '💧', 'text': 'When to irrigate wheat?'},
    {'emoji': '💰', 'text': 'Check PM-KISAN eligibility'},
    {'emoji': '🌡️', 'text': 'Current weather advisory'},
    {'emoji': '📈', 'text': 'Best time to sell soybean?'},
  ];

  final _botResponses = {
    'crops': 'Based on your location (Indore, MP) and current weather forecast, I recommend:\n\n🌾 **Wheat** — Ideal for Rabi season. Current market rate: ₹2,340/quintal.\n\n🫘 **Soybean** — Excellent for Kharif. High demand in Indore mandi.\n\n🌽 **Maize** — Good water efficiency. Price trending up +4.7%.\n\nWould you like detailed cultivation tips for any of these?',
    'yellow': 'Yellow leaves can indicate several issues:\n\n⚠️ **Nitrogen deficiency** — Most common. Apply urea 20 kg/acre.\n\n🦠 **Leaf blight** — Check for brown spots. Use Mancozeb spray.\n\n🐛 **Aphid infestation** — Look for tiny insects. Use Neem oil spray.\n\nCan you share a photo of the affected leaves for a more accurate diagnosis?',
    'irrigate': 'For wheat irrigation in Indore:\n\n💧 **Crown Root Initiation** (21 days) — First critical irrigation\n💧 **Tillering stage** (45 days) — Second irrigation\n💧 **Jointing stage** (65 days) — Third critical stage\n\n🌧️ Rain expected Tuesday may serve as natural irrigation. Skip this week\'s watering.\n\n💡 Tip: Irrigate in early morning to reduce evaporation losses.',
    'scheme': 'For PM-KISAN eligibility, you need:\n\n✅ Must be a cultivator/farmer\n✅ Family must own agricultural land\n✅ Valid Aadhaar card required\n✅ Bank account linked to Aadhaar\n\nYou receive **₹2,000** every 4 months (₹6,000/year).\n\nApply at: pmkisan.gov.in or visit your nearest CSC center.',
    'default': 'Thank you for your question! Let me analyze this for your farm conditions.\n\nBased on your profile:\n• Location: Indore, MP\n• Crop: Soybean\n• Farm size: 2.5 acres\n\nI\'m processing personalized recommendations for you. For detailed analysis, I recommend also checking the Weather and Market screens for real-time data.\n\nIs there anything specific about your crops I can help with?',
  };

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _typingFade = CurvedAnimation(parent: _typingCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _typingCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    final msg = text.trim();
    _msgCtrl.clear();
    setState(() {
      _messages.add({'isBot': false, 'text': msg, 'time': _timeNow()});
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    String response = _botResponses['default']!;
    final lower = msg.toLowerCase();
    if (lower.contains('crop') || lower.contains('season') || lower.contains('sow'))
      response = _botResponses['crops']!;
    else if (lower.contains('yellow') || lower.contains('disease') || lower.contains('leaf'))
      response = _botResponses['yellow']!;
    else if (lower.contains('irrig') || lower.contains('water') || lower.contains('wheat'))
      response = _botResponses['irrigate']!;
    else if (lower.contains('kisan') || lower.contains('scheme') || lower.contains('eligib'))
      response = _botResponses['scheme']!;

    setState(() {
      _isTyping = false;
      _messages.add({'isBot': true, 'text': response, 'time': _timeNow()});
    });
    _scrollToBottom();
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m ${now.hour >= 12 ? 'PM' : 'AM'}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _isTyping) return _buildTypingIndicator();
                final m = _messages[i];
                return _buildMessage(m, i);
              },
            ),
          ),
          _buildQuickReplies(),
          _buildInputBar(),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('AI Assistant 🤖',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        Row(children: [
          Container(width: 7, height: 7,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50))),
          const SizedBox(width: 5),
          Text('Online · Responds instantly',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
        ]),
      ])),
      Material(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() {
            _messages.clear();
            _messages.add({
              'isBot': true,
              'text': 'नमस्ते! 👋 Chat cleared. How can I help you?',
              'time': _timeNow(),
            });
          }),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.refresh_rounded, color: Color(0xFF2E7D32), size: 20),
          ),
        ),
      ),
    ]),
  );

  Widget _buildMessage(Map<String, dynamic> m, int idx) {
    final isBot = m['isBot'] as bool;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(isBot ? -16 * (1 - v) : 16 * (1 - v), 0), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isBot) ...[
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.white : const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isBot ? 4 : 16),
                        bottomRight: Radius.circular(isBot ? 16 : 4),
                      ),
                      boxShadow: [BoxShadow(
                          color: (isBot ? Colors.black : const Color(0xFF2E7D32)).withOpacity(0.08),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Text(
                      m['text'] as String,
                      style: TextStyle(
                        fontSize: 13.5, height: 1.5,
                        color: isBot ? const Color(0xFF1A1A1A) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(m['time'] as String,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[400])),
                ],
              ),
            ),
            if (!isBot) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
          FadeTransition(
            opacity: Tween<double>(begin: 0.2, end: 1.0).animate(
              CurvedAnimation(
                parent: _typingCtrl,
                curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8, height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[400]),
            ),
          ),
        )),
      ),
    ]),
  );

  Widget _buildQuickReplies() {
    if (_messages.length > 2) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Text('Quick questions:', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      ),
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _quickReplies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final q = _quickReplies[i];
            return GestureDetector(
              onTap: () => _sendMessage(q['text'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(q['emoji'] as String, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(q['text'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 6),
    ]);
  }

  Widget _buildInputBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _msgCtrl,
            maxLines: 4,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ask about crops, weather, schemes...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: _sendMessage,
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _sendMessage(_msgCtrl.text),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ]),
  );
}
