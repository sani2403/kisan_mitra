// ─────────────────────────────────────────────────────────────────────────────
// lib/services/firebase_service.dart
//
// Handles ALL Firebase operations:
//   1. Read IoT sensor data from Realtime Database (ESP32 pushes here)
//   2. Listen to real-time sensor updates
//   3. Save/load chat history in Firestore
//   4. Store AI advisories
//
// HOW IT WORKS:
//   ESP32 → pushes to Firebase Realtime DB every 30s
//   This service → listens and forwards data to the UI + Gemini
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../models/iot_sensor_model.dart';
// Replace 'kisan_mitra' with the 'name' found at the top of your pubspec.yaml
//import 'package:agri_app/core/app_constants.dart';

class FirebaseService {
  // Singleton pattern — only one instance throughout the app
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ── Firebase references ───────────────────────────────────────────────────
  final FirebaseDatabase    _realtimeDb = FirebaseDatabase.instance;
  final FirebaseFirestore   _firestore  = FirebaseFirestore.instance;

  // ── Stream controller for sensor data ────────────────────────────────────
  // The UI subscribes to this stream to get live sensor updates
  final _sensorController = StreamController<IoTSensorReading>.broadcast();
  Stream<IoTSensorReading> get sensorStream => _sensorController.stream;

  StreamSubscription? _sensorSubscription;

  // ── REALTIME DATABASE: Listen to sensor updates ───────────────────────────
  //
  // This is the KEY method. It creates a live listener on Firebase.
  // When ESP32 sends new data → Firebase updates → this fires → UI updates
  // → Gemini gets triggered with new context.
  //
  // Call this once at app startup (in main.dart or IoT screen).
  void startSensorListener({
    required void Function(IoTSensorReading) onData,
    void Function(String)? onError,
  }) {
    // Path: /sensors/farm_001/latest
    final ref = _realtimeDb.ref(AppConstants.sensorLatestPath);

    _sensorSubscription = ref.onValue.listen(
      (DatabaseEvent event) {
        final snapshot = event.snapshot;
        if (snapshot.value == null) return;

        try {
          // Firebase returns dynamic Map — cast it safely
          final raw = Map<dynamic, dynamic>.from(
              snapshot.value as Map<dynamic, dynamic>);
          final reading = IoTSensorReading.fromMap(raw);

          // Push to our broadcast stream (UI + AI both listen to this)
          _sensorController.add(reading);

          // Also call the direct callback
          onData(reading);
        } catch (e) {
          onError?.call('Sensor parse error: $e');
        }
      },
      onError: (error) {
        onError?.call('Firebase listener error: $error');
      },
    );
  }

  // ── Stop listening (call on screen dispose) ───────────────────────────────
  void stopSensorListener() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  // ── Fetch latest sensor reading ONCE (no live listener) ──────────────────
  Future<IoTSensorReading?> fetchLatestSensorData() async {
    try {
      final ref      = _realtimeDb.ref(AppConstants.sensorLatestPath);
      final snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value == null) return null;

      final raw = Map<dynamic, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>);
      return IoTSensorReading.fromMap(raw);
    } catch (e) {
      print('FirebaseService.fetchLatestSensorData error: $e');
      return null;
    }
  }

  // ── Fetch sensor history (last N readings) ────────────────────────────────
  Future<List<IoTSensorReading>> fetchSensorHistory({int limit = 48}) async {
    try {
      final ref = _realtimeDb
          .ref(AppConstants.sensorDataPath)
          .orderByChild('timestamp')
          .limitToLast(limit);

      final snapshot = await ref.get();
      if (!snapshot.exists) return [];

      final readings = <IoTSensorReading>[];
      final raw = Map<dynamic, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>);

      for (final entry in raw.values) {
        try {
          readings.add(IoTSensorReading.fromMap(
              Map<dynamic, dynamic>.from(entry as Map)));
        } catch (_) {}
      }

      // Sort by timestamp ascending
      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return readings;
    } catch (e) {
      print('FirebaseService.fetchSensorHistory error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIRESTORE: Chat History
  // ─────────────────────────────────────────────────────────────────────────

  // ── Save a chat message to Firestore ─────────────────────────────────────
  Future<void> saveChatMessage({
    required String userId,
    required ChatMessage message,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.chatHistoryCollection)
          .doc(userId)
          .collection('messages')
          .add(message.toFirestore());
    } catch (e) {
      print('FirebaseService.saveChatMessage error: $e');
    }
  }

  // ── Load chat history ─────────────────────────────────────────────────────
  Future<List<ChatMessage>> loadChatHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.chatHistoryCollection)
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id:        doc.id,
          text:      data['text'] as String,
          role:      MessageRole.values.firstWhere(
              (r) => r.name == data['role'], orElse: () => MessageRole.user),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              data['timestamp'] as int),
          isVoice:   data['is_voice'] as bool? ?? false,
        );
      }).toList().reversed.toList(); // Reverse to get oldest first
    } catch (e) {
      print('FirebaseService.loadChatHistory error: $e');
      return [];
    }
  }

  // ── Clear chat history ────────────────────────────────────────────────────
  Future<void> clearChatHistory(String userId) async {
    try {
      final batch     = _firestore.batch();
      final snapshots = await _firestore
          .collection(AppConstants.chatHistoryCollection)
          .doc(userId)
          .collection('messages')
          .get();

      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('FirebaseService.clearChatHistory error: $e');
    }
  }

  // ── Save AI Advisory to Firestore (for history/notification) ─────────────
  Future<void> saveAdvisory({
    required String userId,
    required String advisory,
    required IoTSensorReading sensorData,
    required String cropType,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.advisoryCollection)
          .add({
        'user_id':    userId,
        'advisory':   advisory,
        'crop_type':  cropType,
        'sensor':     sensorData.toMap(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseService.saveAdvisory error: $e');
    }
  }

  // ── Listen to advisories in real-time ─────────────────────────────────────
  Stream<QuerySnapshot> advisoryStream(String userId) =>
      _firestore
          .collection(AppConstants.advisoryCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .snapshots();

  // ── Clean up ──────────────────────────────────────────────────────────────
  void dispose() {
    stopSensorListener();
    _sensorController.close();
  }
}
