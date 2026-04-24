# ─────────────────────────────────────────────────────────────────────────────
# routes/sensors.py
#
# IoT Sensor data endpoints.
# Currently returns DEMO/SIMULATED data.
#
# HOW TO INTEGRATE YOUR REAL SENSORS:
#   When you have actual IoT hardware (Arduino, ESP32, Raspberry Pi, etc.),
#   replace the _simulate_sensor_data() function with real readings.
#   Common approaches:
#     Option A: Your MCU POSTs readings to /api/sensors/update → store in DB
#     Option B: Your MCU serves a local HTTP endpoint → we fetch it here
#     Option C: Use MQTT broker → subscribe to topics here
#
# ENDPOINTS:
#   GET  /api/sensors            → latest readings from all sensors
#   GET  /api/sensors/history    → last 24 hours (simulated trend data)
#   POST /api/sensors/update     → endpoint for your IoT device to push data
# ─────────────────────────────────────────────────────────────────────────────

import datetime
import random
import math
from flask import Blueprint, jsonify, request

sensors_bp = Blueprint('sensors', __name__)

# ── In-memory storage for the latest sensor reading ──────────────────────────
# In a real app, replace this with a database (SQLite / PostgreSQL / MongoDB)
_latest_reading = {}


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 1: Get latest sensor readings
# GET /api/sensors
# ─────────────────────────────────────────────────────────────────────────────
@sensors_bp.route('/sensors', methods=['GET'])
def get_sensors():
    """
    Returns the latest sensor readings from your farm IoT setup.
    Currently simulates realistic data. Replace with real hardware integration.

    Example response:
    {
        "timestamp": "2024-04-06T10:30:00",
        "farm_status": "normal",
        "status_message": "All systems normal",
        "sensors": {
            "temperature":   { "value": 28.5, "unit": "°C",   "status": "normal",   "min": 15, "max": 45 },
            "soil_moisture": { "value": 65,   "unit": "%",    "status": "good",     "min": 0,  "max": 100 },
            "humidity":      { "value": 72,   "unit": "%",    "status": "moderate", "min": 0,  "max": 100 },
            "light":         { "value": 800,  "unit": "lux",  "status": "high",     "min": 0,  "max": 1200 },
            "soil_ph":       { "value": 6.5,  "unit": "pH",   "status": "ideal",    "min": 0,  "max": 14 },
            "water_level":   { "value": 40,   "unit": "%",    "status": "low",      "min": 0,  "max": 100 }
        },
        "controls": {
            "irrigation_on": false,
            "auto_mode": true
        },
        "_note": "Simulated data — connect real sensors via POST /api/sensors/update"
    }
    """
    global _latest_reading

    # If we have a recent real reading (less than 5 minutes old), return it
    if _latest_reading and _is_recent(_latest_reading.get('timestamp')):
        return jsonify(_latest_reading), 200

    # Otherwise return simulated data
    reading = _simulate_sensor_data()
    return jsonify(reading), 200


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 2: Receive data FROM your IoT device
# POST /api/sensors/update
#
# Your Arduino/ESP32/Raspberry Pi sends a POST request here with sensor values.
# Example from ESP32 (using HTTPClient library):
#   HTTPClient http;
#   http.begin("http://YOUR_SERVER_IP:5000/api/sensors/update");
#   http.addHeader("Content-Type", "application/json");
#   http.addHeader("X-Device-Token", "kisan_device_001");
#   String body = "{\"temperature\":28.5,\"soil_moisture\":65,\"humidity\":72}";
#   http.POST(body);
# ─────────────────────────────────────────────────────────────────────────────
@sensors_bp.route('/sensors/update', methods=['POST'])
def update_sensors():
    """
    Receives sensor data from IoT devices.
    Your hardware POSTs JSON to this endpoint.

    Expected JSON body:
    {
        "temperature": 28.5,
        "soil_moisture": 65,
        "humidity": 72,
        "light": 800,
        "soil_ph": 6.5,
        "water_level": 40,
        "device_id": "farm_sensor_01"   (optional)
    }
    """
    global _latest_reading

    # Optional: check a simple token for security
    token = request.headers.get('X-Device-Token', '')
    # TODO: Validate token against known device list

    data = request.get_json(silent=True)
    if not data:
        return jsonify({'error': 'No JSON body provided'}), 400

    # Build and store the reading
    reading = _build_reading_from_device(data)
    _latest_reading = reading

    return jsonify({
        'status': 'ok',
        'message': 'Sensor data received',
        'timestamp': reading['timestamp'],
    }), 200


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 3: Simulated 24-hour trend history
# GET /api/sensors/history
# ─────────────────────────────────────────────────────────────────────────────
@sensors_bp.route('/sensors/history', methods=['GET'])
def sensor_history():
    """
    Returns simulated 24-hour historical data for trend charts.
    Replace with real DB queries when you have actual sensor hardware.

    Example response:
    {
        "hours": ["00:00", "01:00", ..., "23:00"],
        "temperature":   [24, 23, 22, ..., 28],
        "soil_moisture": [60, 62, 63, ..., 65],
        "humidity":      [70, 72, 74, ..., 68]
    }
    """
    now = datetime.datetime.now()
    hours = []
    temps = []
    moisture = []
    humidity = []

    # Simulate 24 hourly readings using a sine wave (realistic day/night pattern)
    for i in range(24):
        hour_dt = now - datetime.timedelta(hours=(23 - i))
        hours.append(hour_dt.strftime('%H:%M'))

        # Temperature follows a natural day/night curve
        hour_of_day = hour_dt.hour
        base_temp = 24 + 8 * math.sin(math.pi * (hour_of_day - 6) / 12)
        temps.append(round(base_temp + random.uniform(-1, 1), 1))

        # Soil moisture slowly decreases through the day, spikes after irrigation
        moist = 68 - (hour_of_day * 0.15) + random.uniform(-2, 2)
        if hour_of_day == 6:  # Morning irrigation
            moist += 10
        moisture.append(round(max(45, min(95, moist)), 1))

        # Humidity inversely related to temperature
        humid = 80 - (hour_of_day * 0.3) + random.uniform(-3, 3)
        humidity.append(round(max(40, min(95, humid)), 1))

    return jsonify({
        'hours':         hours,
        'temperature':   temps,
        'soil_moisture': moisture,
        'humidity':      humidity,
        'generated':     now.isoformat(),
    }), 200


# ─────────────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────────────
def _simulate_sensor_data() -> dict:
    """
    Returns realistic simulated sensor readings.
    These values gently fluctuate each time they're called.

    TO REPLACE WITH REAL DATA: swap this function's body with actual
    DB queries or direct hardware reads.
    """
    # Add small random variation to make it look "live"
    temp     = round(28.0 + random.uniform(-2, 3), 1)
    moisture = round(65   + random.uniform(-5, 5))
    humid    = round(72   + random.uniform(-4, 6))
    light    = round(800  + random.uniform(-100, 200))
    ph       = round(6.5  + random.uniform(-0.3, 0.3), 1)
    water    = round(40   + random.uniform(-3, 3))

    # Determine overall farm status
    status_flags = []
    if water < 30:      status_flags.append('low_water')
    if moisture < 40:   status_flags.append('dry_soil')
    if temp > 40:       status_flags.append('high_temp')

    farm_status = 'critical' if len(status_flags) > 1 else \
                  'warning'  if status_flags else 'normal'
    status_msg  = 'Attention needed — check alerts' if status_flags else \
                  'All systems normal'

    return {
        'timestamp':      datetime.datetime.now().isoformat(),
        'farm_status':    farm_status,
        'status_message': status_msg,
        'sensors': {
            'temperature':   _make_sensor(temp,     '°C',  _temp_status(temp)),
            'soil_moisture': _make_sensor(moisture, '%',   _moisture_status(moisture)),
            'humidity':      _make_sensor(humid,    '%',   _humid_status(humid)),
            'light':         _make_sensor(light,    'lux', _light_status(light)),
            'soil_ph':       _make_sensor(ph,       'pH',  _ph_status(ph)),
            'water_level':   _make_sensor(water,    '%',   _water_status(water)),
        },
        'controls': {
            'irrigation_on': False,
            'auto_mode':     True,
        },
        '_note': 'Simulated data — connect real sensors via POST /api/sensors/update',
    }


def _build_reading_from_device(data: dict) -> dict:
    """Converts raw device POST data into structured sensor reading."""
    temp     = float(data.get('temperature',   28))
    moisture = float(data.get('soil_moisture', 65))
    humid    = float(data.get('humidity',      72))
    light    = float(data.get('light',        800))
    ph       = float(data.get('soil_ph',      6.5))
    water    = float(data.get('water_level',   40))

    return {
        'timestamp':      datetime.datetime.now().isoformat(),
        'farm_status':    'normal',
        'status_message': 'Live data from device',
        'device_id':      data.get('device_id', 'unknown'),
        'sensors': {
            'temperature':   _make_sensor(temp,     '°C',  _temp_status(temp)),
            'soil_moisture': _make_sensor(moisture, '%',   _moisture_status(moisture)),
            'humidity':      _make_sensor(humid,    '%',   _humid_status(humid)),
            'light':         _make_sensor(light,    'lux', _light_status(light)),
            'soil_ph':       _make_sensor(ph,       'pH',  _ph_status(ph)),
            'water_level':   _make_sensor(water,    '%',   _water_status(water)),
        },
        'controls': {
            'irrigation_on': data.get('irrigation_on', False),
            'auto_mode':     data.get('auto_mode', True),
        },
    }


def _make_sensor(value, unit: str, status: str) -> dict:
    return {'value': value, 'unit': unit, 'status': status}


def _is_recent(ts_str: str | None, max_seconds: int = 300) -> bool:
    """Check if a timestamp string is within the last N seconds."""
    if not ts_str:
        return False
    try:
        ts  = datetime.datetime.fromisoformat(ts_str)
        age = (datetime.datetime.now() - ts).total_seconds()
        return age < max_seconds
    except Exception:
        return False


# ── Status classifiers ────────────────────────────────────────────────────────
def _temp_status(v):
    if v < 15 or v > 40: return 'critical'
    if v < 20 or v > 35: return 'warning'
    return 'normal'

def _moisture_status(v):
    if v < 30: return 'critical'
    if v < 45: return 'low'
    if v > 85: return 'high'
    return 'good'

def _humid_status(v):
    if v > 90: return 'high'
    if v > 75: return 'moderate'
    if v < 30: return 'low'
    return 'normal'

def _light_status(v):
    if v > 1000: return 'high'
    if v > 600:  return 'good'
    if v < 200:  return 'low'
    return 'moderate'

def _ph_status(v):
    if 6.0 <= v <= 7.0: return 'ideal'
    if 5.5 <= v <= 7.5: return 'moderate'
    return 'critical'

def _water_status(v):
    if v < 20: return 'critical'
    if v < 35: return 'low'
    if v > 90: return 'high'
    return 'normal'
