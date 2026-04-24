// ─────────────────────────────────────────────────────────────────────────────
// lib/services/gemini_service.dart
//
// Handles ALL Gemini AI interactions.
//
// KEY FEATURE: Smart Crop Advisory
//   Combines user query + real-time IoT sensor data + crop type
//   → sends structured prompt to Gemini
//   → returns farmer-friendly actionable advice
//
// PROMPT ENGINEERING:
//   We use a carefully crafted system instruction that tells Gemini to
//   behave as an Indian agricultural expert who gives simple, clear,
//   bullet-pointed advice that even an illiterate farmer can understand.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/app_constants.dart';
import '../models/iot_sensor_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Singleton
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // ── Gemini model instance ─────────────────────────────────────────────────
  late final GenerativeModel _model;
  late final ChatSession      _chatSession;
  bool _initialized = false;

  // ── System instruction: defines Gemini's personality & expertise ──────────
  static const String _systemInstruction = '''
You are KisanMitra AI — a friendly, expert agricultural advisor for Indian farmers.

YOUR EXPERTISE:
- Indian crops: Wheat, Rice, Maize, Soybean, Cotton, Vegetables, Fruits, Pulses
- Government schemes: PM-KISAN, PMFBY, KCC, PMKSY, and all major central/state schemes
- Indian mandi (market) prices and crop selling strategies
- Soil health, fertilizers, organic farming, pest control
- IoT sensor interpretation: soil moisture, temperature, humidity
- Indian climate zones and regional farming practices

YOUR RESPONSE STYLE:
- Always respond in the SAME LANGUAGE the user writes in (Hindi or English)
- Use SIMPLE words — imagine explaining to a village farmer with 5th grade education
- Use bullet points (•) for recommendations
- Keep responses SHORT and ACTIONABLE (3–6 bullet points max)
- Use emojis to make it visually clear: 💧 for water, 🌡️ for temperature, ⚠️ for alerts
- Always end with ONE most important action the farmer should take RIGHT NOW
- Never use technical jargon without explaining it
- Be encouraging and positive

WHEN SENSOR DATA IS PROVIDED:
- Analyze the exact numbers, do not generalize
- Give SPECIFIC thresholds: "Moisture is 20% — this is BELOW the 40% minimum for wheat"
- Prioritize the most critical issue first
- Give timing advice: "Water in early morning 5–7 AM to reduce evaporation"

IMPORTANT: Always be accurate about Indian agriculture context.
''';

  // ── Initialize Gemini ─────────────────────────────────────────────────────
  void initialize() {
    if (_initialized) return;

    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: AppConstants.geminiApiKey,
      // System instruction sets Gemini's "personality"
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature:     0.7,   // Balanced: not too creative, not too rigid
        topK:            40,
        topP:            0.95,
        maxOutputTokens: 800,   // Keep responses concise
      ),

    );

    // Start a persistent chat session (maintains conversation history)
    _chatSession  = _model.startChat();
    _initialized  = true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CORE METHOD: Send message to Gemini (with optional sensor context)
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> sendMessage({
    required String userMessage,
    IoTSensorReading? sensorData,
    String? cropType,
    String language = 'en',
  }) async {
    if (!_initialized) initialize();

    try {
      // Build the prompt — this is where the magic happens
      final prompt = _buildPrompt(
        userMessage: userMessage,
        sensorData:  sensorData,
        cropType:    cropType,
        language:    language,
      );

      // Send to Gemini via persistent chat session (maintains context)
      final response = await _chatSession.sendMessage(
        Content.text(prompt),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        return language == 'hi'
            ? 'क्षमा करें, कोई उत्तर नहीं मिला। कृपया फिर से प्रयास करें।'
            : 'Sorry, I could not generate a response. Please try again.';
      }

      return text.trim();

    } on GenerativeAIException catch (e) {
      if (e.message.contains('API_KEY_INVALID')) {
        return '⚠️ Gemini API key is invalid. Please check AppConstants.geminiApiKey';
      }
      return language == 'hi'
          ? 'AI सेवा में त्रुटि: ${e.message}'
          : 'AI service error: ${e.message}';
    } catch (e) {
      return language == 'hi'
          ? 'त्रुटि हुई। कृपया फिर प्रयास करें।'
          : 'An error occurred. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SMART CROP ADVISORY: The MOST IMPORTANT feature
  //
  // This builds a structured prompt combining:
  //   1. User's question
  //   2. Real-time sensor data from ESP32 via Firebase
  //   3. Crop type
  //   4. Preferred language
  //
  // Example final prompt sent to Gemini:
  // "You are analyzing real-time farm data.
  //  SENSOR READINGS (live from IoT device):
  //  - Soil Moisture: 20% (LOW — needs immediate attention)
  //  - Temperature: 35°C (HIGH)
  //  - Humidity: 70% (MODERATE)
  //  CROP: Wheat
  //  FARMER'S QUESTION: What should I do?
  //  Provide specific, actionable advice in Hindi."
  // ─────────────────────────────────────────────────────────────────────────
  String _buildPrompt({
    required String userMessage,
    IoTSensorReading? sensorData,
    String? cropType,
    String language = 'en',
  }) {
    final buffer = StringBuffer();

    // ── Add sensor context if available ───────────────────────────────────
    if (sensorData != null) {
      buffer.writeln('📊 LIVE FARM SENSOR DATA (from IoT device):');
      buffer.writeln('• Soil Moisture: ${sensorData.soilMoisture.toStringAsFixed(1)}%'
          ' → Status: ${_statusEmoji(sensorData.soilMoistureStatus)} ${sensorData.soilMoistureStatus.toUpperCase()}');
      buffer.writeln('• Temperature: ${sensorData.temperature.toStringAsFixed(1)}°C'
          ' → Status: ${_statusEmoji(sensorData.temperatureStatus)} ${sensorData.temperatureStatus.toUpperCase()}');
      buffer.writeln('• Humidity: ${sensorData.humidity.toStringAsFixed(1)}%'
          ' → Status: ${_statusEmoji(sensorData.humidityStatus)} ${sensorData.humidityStatus.toUpperCase()}');
      buffer.writeln('• Data recorded at: ${_formatTimestamp(sensorData.timestamp)}');
      buffer.writeln();

      // Add threshold context so Gemini understands what "low" means
      buffer.writeln('📏 OPTIMAL RANGES FOR REFERENCE:');
      buffer.writeln('• Soil moisture for most crops: 40–70%');
      buffer.writeln('• Optimal temperature: 15–35°C');
      buffer.writeln('• Optimal humidity: 40–80%');
      buffer.writeln();
    }

    // ── Add crop type ─────────────────────────────────────────────────────
    if (cropType != null && cropType.isNotEmpty) {
      buffer.writeln('🌾 CROP TYPE: $cropType');
      buffer.writeln();
    }

    // ── Add the farmer's actual question ─────────────────────────────────
    buffer.writeln("👨‍🌾 FARMER'S QUESTION: $userMessage");
    buffer.writeln();

    // ── Language instruction ──────────────────────────────────────────────
    if (language == 'hi') {
      buffer.writeln('📝 IMPORTANT: Reply in HINDI (हिंदी में जवाब दें). '
          'Use simple Hindi that a village farmer understands.');
    } else {
      buffer.writeln('📝 Reply in simple English.');
    }

    // ── Response format instruction ───────────────────────────────────────
    buffer.writeln('''
FORMAT YOUR RESPONSE AS:
🔍 **Analysis:** (1 line summary of the situation)

💡 **Recommendations:**
• [Most urgent action]
• [Second action]
• [Third action if needed]

⚡ **DO THIS NOW:** [Single most critical immediate action]
''');

    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GENERATE AUTOMATIC ADVISORY (no user question needed)
  //
  // Called automatically when sensor data changes beyond thresholds.
  // This is the "automation layer" — no farmer input needed.
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> generateAutoAdvisory({
    required IoTSensorReading sensorData,
    required String cropType,
    String language = 'en',
  }) async {
    if (!_initialized) initialize();

    final issues = <String>[];

    // Detect issues based on thresholds
    if (sensorData.soilMoisture < AppConstants.soilMoistureLow) {
      issues.add('soil moisture is critically low at ${sensorData.soilMoisture.toStringAsFixed(1)}%');
    }
    if (sensorData.soilMoisture > AppConstants.soilMoistureHigh) {
      issues.add('soil is overwatered at ${sensorData.soilMoisture.toStringAsFixed(1)}%');
    }
    if (sensorData.temperature > AppConstants.temperatureHigh) {
      issues.add('temperature is very high at ${sensorData.temperature.toStringAsFixed(1)}°C');
    }
    if (sensorData.humidity > AppConstants.humidityHigh) {
      issues.add('humidity is dangerously high at ${sensorData.humidity.toStringAsFixed(1)}% — fungal disease risk');
    }

    if (issues.isEmpty) {
      return language == 'hi'
          ? '✅ सभी सेंसर रीडिंग सामान्य हैं। आपकी फसल अच्छी है!'
          : '✅ All sensor readings are normal. Your crop is healthy!';
    }

    final issueText = issues.join(', ');
    final prompt = language == 'hi'
        ? 'किसान की फसल $cropType है। निम्न समस्याएं हैं: $issueText. '
          'सेंसर डेटा: ${sensorData.toPromptFragment()}. '
          'हिंदी में 3 बुलेट पॉइंट में तुरंत करने योग्य सलाह दें।'
        : 'Farmer grows $cropType. Issues detected: $issueText. '
          'Sensor data: ${sensorData.toPromptFragment()}. '
          'Give 3 bullet point immediate actions in simple English.';

    return sendMessage(
      userMessage: prompt,
      sensorData:  sensorData,
      cropType:    cropType,
      language:    language,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STREAMING version (for real-time word-by-word display)
  // ─────────────────────────────────────────────────────────────────────────
  Stream<String> sendMessageStream({
    required String userMessage,
    IoTSensorReading? sensorData,
    String? cropType,
    String language = 'en',
  }) async* {
    if (!_initialized) initialize();

    final prompt = _buildPrompt(
      userMessage: userMessage,
      sensorData:  sensorData,
      cropType:    cropType,
      language:    language,
    );

    try {
      final stream = _chatSession.sendMessageStream(Content.text(prompt));
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } catch (e) {
      yield language == 'hi'
          ? '\n⚠️ त्रुटि: $e'
          : '\n⚠️ Error: $e';
    }
  }

  // ── Reset chat session (clear conversation memory) ────────────────────────
  void resetChat() {
    if (_initialized) {
      _chatSession  = _model.startChat();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _statusEmoji(String status) =>
    status == 'low' ? '🔴' : status == 'high' ? '🟠' : '🟢';

  String _formatTimestamp(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
