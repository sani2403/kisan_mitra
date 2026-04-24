# KisanMitra AI — Complete Setup Guide

## Project Structure
```
agri_app/
├── lib/
│   ├── core/
│   │   └── app_constants.dart        ← API keys, thresholds, config
│   ├── models/
│   │   └── iot_sensor_model.dart     ← IoT + Chat message models
│   ├── services/
│   │   ├── gemini_service.dart       ← Gemini AI calls + prompt engineering
│   │   ├── firebase_service.dart     ← Firebase Realtime DB + Firestore
│   │   ├── voice_service.dart        ← STT (mic) + TTS (speaker)
│   │   └── smart_advisory_service.dart ← Rule-based + AI crop advisory
│   └── screens/
│       └── chatbot_screen.dart       ← Main AI chat UI
│
kisanmitra_iot/
└── kisan_sensor_node.ino             ← ESP32 Arduino code
```

---

## Step 1 — Get Gemini API Key (FREE)

1. Go to **https://aistudio.google.com/app/apikey**
2. Sign in with Google
3. Click **"Create API Key"**
4. Copy it and paste in `lib/core/app_constants.dart`:
```dart
static const String geminiApiKey = 'AIza...YOUR_KEY...';
```

**Free tier limits:** 60 requests/minute, 1M tokens/day — more than enough.

---

## Step 2 — Firebase Setup

### 2a. Create Firebase Project
1. Go to **https://console.firebase.google.com**
2. Click "Add project" → name it "kisanmitra"
3. Enable Google Analytics (optional)

### 2b. Add Android App
1. Click the Android icon (⚙️ → Project Settings → Your Apps)
2. Android package name: `com.example.agri_app` (check your AndroidManifest.xml)
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`

### 2c. Enable Firebase Services
In Firebase Console, enable:
- **Realtime Database** → Create database → Start in test mode
- **Firestore Database** → Create database → Start in test mode
- **Authentication** → Sign-in method → Anonymous → Enable

### 2d. Run FlutterFire CLI
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (run from your Flutter project root)
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```
This auto-creates `lib/firebase_options.dart`.

### 2e. Uncomment in main.dart
```dart
import 'firebase_options.dart';

// In main():
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 2f. Firebase Database Rules
In Firebase Console → Realtime Database → Rules:
```json
{
  "rules": {
    "sensors": {
      "$farmId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

---

## Step 3 — Add Android Permissions

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

For Android 9+, also add inside `<application>`:
```xml
android:usesCleartextTraffic="true"
```

---

## Step 4 — Flutter Dependencies

In `android/build.gradle`, inside `buildscript → dependencies`:
```groovy
classpath 'com.google.gms:google-services:4.4.0'
```

In `android/app/build.gradle`, at the bottom:
```groovy
apply plugin: 'com.google.gms.google-services'
```

Then run:
```bash
flutter pub get
flutter run
```

---

## Step 5 — IoT Setup (ESP32)

### Hardware
| Component | GPIO Pin |
|---|---|
| DHT11 DATA | GPIO 4 |
| Soil Sensor OUT | GPIO 34 |
| Both VCC | 3.3V |
| Both GND | GND |

### Arduino Setup
1. Install Arduino IDE: https://www.arduino.cc/en/software
2. Add ESP32 board URL in Preferences:
   `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Install board: Tools → Board Manager → search "esp32" → install
4. Install libraries:
   - "Firebase Arduino Client Library for ESP8266 and ESP32"
   - "DHT sensor library" by Adafruit
   - "ArduinoJson" by Benoit Blanchon
5. Open `kisanmitra_iot/kisan_sensor_node.ino`
6. Fill in WiFi + Firebase credentials
7. Upload to ESP32

### Data Frequency Guide
| Scenario | Interval |
|---|---|
| Normal monitoring | 30 seconds |
| Critical crop stage | 10 seconds |
| Battery powered | 5 minutes |
| Over cellular (SIM) | 5 minutes |

---

## Firebase Data Structure

```json
{
  "sensors": {
    "farm_001": {
      "latest": {
        "soil_moisture": 45.2,
        "temperature": 32.5,
        "humidity": 68.0,
        "timestamp": 1712400000000,
        "device_id": "ESP32_FARM_001"
      },
      "data": {
        "-NxAbCdef123": {
          "soil_moisture": 42.1,
          "temperature": 31.8,
          "humidity": 65.2,
          "timestamp": 1712399700000,
          "device_id": "ESP32_FARM_001"
        }
      }
    }
  }
}
```

---

## How the AI Advisory Works

```
ESP32 Sensors
    │ (every 30s via WiFi)
    ▼
Firebase Realtime Database
    │ (Firebase Listener in Flutter)
    ▼
FirebaseService.startSensorListener()
    │ (new data arrives)
    ▼
SmartAdvisoryService.generateFullAdvisory()
    │
    ├── Rule-based alerts (instant, no API)
    │   ├── "Moisture < 30% → IRRIGATE NOW"
    │   ├── "Temp > 38°C → HEAT STRESS"
    │   └── "Humidity > 85% → FUNGAL RISK"
    │
    └── GeminiService.sendMessage()
        │ (structured prompt)
        ▼
        Gemini 1.5 Flash API
        │
        ▼
        Farmer-friendly advice
        │
        └── VoiceService.speak()
            (spoken aloud in Hindi/English)
```

---

## Example Gemini Prompt

```
📊 LIVE FARM SENSOR DATA (from IoT device):
• Soil Moisture: 20.0% → Status: 🔴 LOW
• Temperature: 35.5°C → Status: 🟠 HIGH
• Humidity: 70.0% → Status: 🟢 NORMAL
• Data recorded at: 2 min ago

📏 OPTIMAL RANGES FOR REFERENCE:
• Soil moisture for most crops: 40–70%
• Optimal temperature: 15–35°C
• Optimal humidity: 40–80%

🌾 CROP TYPE: Wheat

👨‍🌾 FARMER'S QUESTION: What should I do now?

FORMAT YOUR RESPONSE AS:
🔍 Analysis: ...
💡 Recommendations: ...
⚡ DO THIS NOW: ...
```

---

## Gemini Response Example

```
🔍 Analysis: Your wheat field is under heat and drought stress.
Soil moisture is critically low at 20%, and temperature is high.

💡 Recommendations:
• 💧 Irrigate immediately — do it before 7 AM tomorrow morning
• 🌡️ High temperature increases water loss — water more frequently
• 🦠 Humidity is normal — no immediate disease risk
• 🌾 At this stage, wheat needs consistent moisture for grain filling
• ⏰ Irrigate for 45–60 minutes using drip or furrow method

⚡ DO THIS NOW: Go to the field and start irrigation before sunrise.
Dry soil + high temperature is damaging your wheat crop every hour.
```

---

## Troubleshooting

| Issue | Solution |
|---|---|
| "Gemini API key invalid" | Check key in app_constants.dart, no spaces |
| "Firebase not configured" | Follow Step 2, run flutterfire configure |
| "Microphone not working" | Add RECORD_AUDIO permission in AndroidManifest |
| "No sensor data" | Check ESP32 is running, WiFi connected, Firebase path matches |
| "TTS not speaking" | Check volume, try en-US if hi-IN not available |
| Build error: firebase_core | Run: flutter pub get, check google-services.json location |
