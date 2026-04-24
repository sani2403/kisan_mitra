// ─────────────────────────────────────────────────────────────────────────────
// lib/services/voice_service.dart
//
// Handles both directions of voice:
//   Speech-to-Text (STT): Farmer speaks → text for Gemini
//   Text-to-Speech (TTS): Gemini responds → spoken to farmer
//
// MULTILINGUAL:
//   Supports Hindi (hi-IN) and English (en-IN/en-US)
//   Farmers can switch between languages at any time
//
// NATURAL MODULATION:
//   TTS is tuned for clarity: slower pitch, medium speed
//   so elderly farmers can understand easily
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum VoiceState { idle, listening, speaking, error }

class VoiceService {
  // Singleton
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // ── Speech-to-Text engine ─────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  bool _sttInitialized = false;

  // ── Text-to-Speech engine ─────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;

  // ── State ─────────────────────────────────────────────────────────────────
  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  bool get isSpeaking  => _state == VoiceState.speaking;

  // Callbacks
  void Function(String words)?     onSpeechResult;
  void Function(VoiceState state)? onStateChange;
  void Function(String error)?     onError;

  // ── Initialize STT ────────────────────────────────────────────────────────
  Future<bool> initSTT() async {
    if (_sttInitialized) return true;
    try {
      _sttInitialized = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _setState(VoiceState.idle);
          }
        },
        onError: (error) {
          _setState(VoiceState.error);
          onError?.call(error.errorMsg);
        },
        debugLogging: false,
      );
      return _sttInitialized;
    } catch (e) {
      onError?.call('STT init failed: $e');
      return false;
    }
  }

  // ── Initialize TTS ────────────────────────────────────────────────────────
  // ── Initialize TTS ────────────────────────────────────────────────────────
  Future<void> initTTS({String language = 'en'}) async {
    if (_ttsInitialized) {
      await _setTTSLanguage(language);
      return;
    }

    try {
      // FIX: Use the updated completion handler syntax
      _tts.setCompletionHandler(() {
        _setState(VoiceState.idle);
      });

      // FIX: Modern flutter_tts uses this signature for errors
      _tts.setErrorHandler((dynamic message) {
        _setState(VoiceState.error);
        onError?.call('TTS error: $message');
      });

      // Tune voice for clarity
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      await _setTTSLanguage(language);
      _ttsInitialized = true;
    } catch (e) {
      onError?.call('TTS init failed: $e');
    }
  }

  Future<void> _setTTSLanguage(String language) async {
    // Use Indian English accent or Hindi
    final locale = language == 'hi' ? 'hi-IN' : 'en-IN';
    try {
      final available = await _tts.isLanguageAvailable(locale);
      if (available) {
        await _tts.setLanguage(locale);
      } else {
        // Fallback to standard English
        await _tts.setLanguage('en-US');
      }
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
  }

  // ── START LISTENING (Farmer speaks) ───────────────────────────────────────
  Future<void> startListening({
    required String language,         // 'en' or 'hi'
    required void Function(String) onResult,
    void Function(String)? onPartialResult,
  }) async {
    // Stop any ongoing speech first
    if (isSpeaking) await stopSpeaking();

    final ready = await initSTT();
    if (!ready) {
      onError?.call('Microphone permission denied or STT unavailable');
      return;
    }

    _setState(VoiceState.listening);

    final localeId = language == 'hi' ? 'hi_IN' : 'en_IN';

    await _stt.listen(
      localeId: localeId,
      listenMode: ListenMode.confirmation,
      listenFor: const Duration(seconds: 30),   // Max listen duration
      pauseFor: const Duration(seconds: 3),      // Auto-stop after 3s silence
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;

        if (result.finalResult) {
          // Final result — send to Gemini
          _setState(VoiceState.idle);
          onResult(words);
        } else if (onPartialResult != null) {
          // Partial (live transcription preview)
          onPartialResult(words);
        }
      },
    );
  }

  // ── STOP LISTENING ────────────────────────────────────────────────────────
  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
    _setState(VoiceState.idle);
  }

  // ── SPEAK TEXT (Gemini response read aloud) ───────────────────────────────
  //
  // Cleans markdown formatting before speaking
  // (Gemini uses ** and • which sound bad in TTS)
  Future<void> speak({
    required String text,
    required String language,
  }) async {
    if (text.trim().isEmpty) return;

    await initTTS(language: language);

    // Stop any current speech
    if (isSpeaking) await stopSpeaking();

    // Clean markdown for natural speech
    final cleanText = _cleanForSpeech(text);

    _setState(VoiceState.speaking);
    await _tts.speak(cleanText);
  }

  // ── STOP SPEAKING ─────────────────────────────────────────────────────────
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _setState(VoiceState.idle);
  }

  // ── Check if STT is available on this device ──────────────────────────────
  Future<bool> isSTTAvailable() async {
    if (!_sttInitialized) await initSTT();
    return _sttInitialized;
  }

  // ── Get available locales (for language selection) ────────────────────────
  Future<List<String>> getAvailableSTTLocales() async {
    if (!_sttInitialized) await initSTT();
    final locales = await _stt.locales();
    return locales.map((l) => l.localeId).toList();
  }

  // ── Clean markdown formatting for TTS ────────────────────────────────────
  String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1')  // Bold
        .replaceAll(RegExp(r'\*(.+?)\*'),     r'\1')   // Italic
        .replaceAll('•', '')                            // Bullets → pause
        .replaceAll('#', '')                            // Headers
        .replaceAll('🔍', '')
        .replaceAll('💡', '')
        .replaceAll('⚡', '')
        .replaceAll('📊', '')
        .replaceAll('🌾', '')
        .replaceAll('💧', 'water')
        .replaceAll('⚠️', 'Warning:')
        .replaceAll('✅', '')
        .replaceAll(RegExp(r'\n{2,}'), '. ')           // Multiple newlines → pause
        .replaceAll('\n', '. ')                         // Single newline → short pause
        .trim();
  }

  void _setState(VoiceState state) {
    _state = state;
    onStateChange?.call(state);
  }

  // ── Release resources ─────────────────────────────────────────────────────
  void dispose() {
    _stt.stop();
    _tts.stop();
  }
}
