# KisanMitra Backend — Setup & Run Guide

```
kisanmitra_backend/
├── app.py                  ← Flask entry point
├── requirements.txt        ← Python dependencies
├── .env.example            ← Environment variable template
└── routes/
    ├── __init__.py
    ├── weather.py           ← /api/weather, /api/forecast
    ├── market.py            ← /api/mandi, /api/mandi/top-movers
    ├── sensors.py           ← /api/sensors, /api/sensors/update
    └── schemes.py           ← /api/schemes
```

---

## Step 1 — Prerequisites

- Python 3.9 or higher
- pip (comes with Python)
- Free OpenWeatherMap API key (takes 2 minutes)

---

## Step 2 — Get Your OpenWeatherMap API Key

1. Go to **https://openweathermap.org/api**
2. Click **"Sign Up"** — it's free
3. After signup, go to **API keys** tab
4. Copy your key (it looks like: `a1b2c3d4e5f6...`)

> The free tier allows **60 calls/minute** — more than enough for this app.

---

## Step 3 — Install & Configure

```bash
# 1. Enter the backend folder
cd kisanmitra_backend

# 2. (Recommended) Create a virtual environment
python -m venv venv

# Activate it:
# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create your .env file from the template
cp .env.example .env

# 5. Open .env and paste your API key
# Change:  OPENWEATHER_API_KEY=your_openweathermap_api_key_here
# To:      OPENWEATHER_API_KEY=a1b2c3d4e5f6...   (your real key)
```

---

## Step 4 — Run the Server

```bash
python app.py
```

You will see:
```
🌾 KisanMitra API starting on http://localhost:5000
   Debug mode: True
```

---

## Step 5 — Test the Endpoints

Open your browser or use `curl`:

```bash
# Health check
curl http://localhost:5000/

# Current weather for Raipur
curl http://localhost:5000/api/weather?city=Raipur

# 7-day forecast
curl http://localhost:5000/api/forecast?city=Bhopal

# Mandi prices — all cities
curl http://localhost:5000/api/mandi

# Mandi prices — single city
curl http://localhost:5000/api/mandi?city=Nagpur

# Top price movers today
curl http://localhost:5000/api/mandi/top-movers

# Sensor readings
curl http://localhost:5000/api/sensors

# Government schemes
curl http://localhost:5000/api/schemes

# Filter schemes by category
curl "http://localhost:5000/api/schemes?category=Credit"
```

---

## Step 6 — Connect Flutter App

In `lib/services/api_service.dart`, update `_baseUrl`:

```dart
// Android Emulator  (default)
static const String _baseUrl = 'http://10.0.2.2:5000/api';

// iPhone Simulator
static const String _baseUrl = 'http://localhost:5000/api';

// Real device (replace X with your PC's local IP)
// Find your IP: run `ipconfig` on Windows or `ifconfig` on Mac/Linux
static const String _baseUrl = 'http://192.168.1.X:5000/api';

// Deployed to a server
static const String _baseUrl = 'https://api.yourdomain.com/api';
```

---

## API Response Examples

### GET /api/weather?city=Raipur
```json
{
  "city": "Raipur",
  "country": "IN",
  "temperature": 32,
  "feels_like": 36,
  "temp_min": 26,
  "temp_max": 35,
  "humidity": 65,
  "wind_speed": 14,
  "condition": "Partly Cloudy",
  "condition_id": 802,
  "emoji": "⛅",
  "color": "#1565C0",
  "rain_chance": 20,
  "visibility": 8.0,
  "sunrise": "06:12",
  "sunset": "18:45",
  "is_day": true
}
```

### GET /api/forecast?city=Raipur
```json
{
  "city": "Raipur",
  "forecast": [
    {
      "day": "Today",
      "date": "Apr 6",
      "emoji": "⛅",
      "high": 34,
      "low": 24,
      "desc": "Partly Cloudy",
      "rain": 20,
      "wind": 14,
      "humid": 62,
      "color": "#1565C0"
    }
  ]
}
```

### GET /api/mandi?city=Raipur
```json
{
  "city": "Raipur",
  "state": "Chhattisgarh",
  "last_updated": "2024-04-06 10:30:00",
  "crops": [
    {
      "crop": "Wheat",
      "emoji": "🌾",
      "price": 2275,
      "unit": "₹/quintal",
      "trend": "up",
      "change": 1.8,
      "grade": "Grade A"
    }
  ]
}
```

### GET /api/sensors
```json
{
  "timestamp": "2024-04-06T10:30:00",
  "farm_status": "normal",
  "status_message": "All systems normal",
  "sensors": {
    "temperature":   { "value": 28.5, "unit": "°C",  "status": "normal" },
    "soil_moisture": { "value": 65,   "unit": "%",   "status": "good"   },
    "humidity":      { "value": 72,   "unit": "%",   "status": "moderate"},
    "light":         { "value": 800,  "unit": "lux", "status": "high"   },
    "soil_ph":       { "value": 6.5,  "unit": "pH",  "status": "ideal"  },
    "water_level":   { "value": 40,   "unit": "%",   "status": "low"    }
  },
  "controls": {
    "irrigation_on": false,
    "auto_mode": true
  }
}
```

### POST /api/sensors/update  (from your IoT device)
```json
// Request body from ESP32/Arduino:
{
  "temperature": 28.5,
  "soil_moisture": 65,
  "humidity": 72,
  "light": 800,
  "soil_ph": 6.5,
  "water_level": 40,
  "device_id": "farm_sensor_01"
}

// Response:
{
  "status": "ok",
  "message": "Sensor data received",
  "timestamp": "2024-04-06T10:30:00"
}
```

---

## Deploy to Production (optional)

Using **Railway** (free tier available):
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

Using **Render** (free tier):
1. Push code to GitHub
2. Go to render.com → New Web Service
3. Connect your repo
4. Set build command: `pip install -r requirements.txt`
5. Set start command: `gunicorn app:app`
6. Add environment variable: `OPENWEATHER_API_KEY=your_key`

---

## IoT Integration Guide

When your hardware (ESP32/Arduino/Raspberry Pi) is ready, send sensor data like this:

**ESP32 Arduino code:**
```cpp
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* serverUrl = "http://YOUR_PC_IP:5000/api/sensors/update";

void sendSensorData(float temp, float moisture, float humidity) {
  HTTPClient http;
  http.begin(serverUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Token", "kisan_device_001");

  StaticJsonDocument<200> doc;
  doc["temperature"]   = temp;
  doc["soil_moisture"] = moisture;
  doc["humidity"]      = humidity;
  doc["device_id"]     = "farm_sensor_01";

  String requestBody;
  serializeJson(doc, requestBody);

  int httpCode = http.POST(requestBody);
  http.end();
}
```
