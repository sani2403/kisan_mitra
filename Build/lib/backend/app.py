# ─────────────────────────────────────────────────────────────────────────────
# KisanMitra Backend — app.py
# Flask server that provides all API endpoints for the Flutter app.
#
# HOW TO RUN:
#   1. pip install -r requirements.txt
#   2. cp .env.example .env   (then add your OpenWeatherMap API key)
#   3. python app.py
#
# The server will start at http://localhost:5000
# ─────────────────────────────────────────────────────────────────────────────

import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv

# Import our route blueprints (separate files for each feature)
from routes.weather import weather_bp
from routes.market  import market_bp
from routes.sensors import sensors_bp
from routes.schemes import schemes_bp

# ── Load environment variables from .env file ─────────────────────────────────
load_dotenv()

# ── Create Flask app ──────────────────────────────────────────────────────────
app = Flask(__name__)

# Allow requests from Flutter app (any origin during development)
# In production: replace "*" with your actual domain
CORS(app, origins="*")

# ── Register route blueprints ─────────────────────────────────────────────────
# Each blueprint handles a group of related endpoints
app.register_blueprint(weather_bp,  url_prefix='/api')
app.register_blueprint(market_bp,   url_prefix='/api')
app.register_blueprint(sensors_bp,  url_prefix='/api')
app.register_blueprint(schemes_bp,  url_prefix='/api')

# ── Root health-check endpoint ────────────────────────────────────────────────
@app.route('/')
def home():
    """Simple health check — confirms the server is running."""
    return jsonify({
        'status': 'ok',
        'message': 'KisanMitra API is running 🌾',
        'version': '1.0.0',
        'endpoints': {
            'weather':  '/api/weather?city=Raipur',
            'forecast': '/api/forecast?city=Raipur',
            'mandi':    '/api/mandi',
            'mandi_city': '/api/mandi?city=Raipur',
            'sensors':  '/api/sensors',
            'schemes':  '/api/schemes',
        }
    })

# ── Error handlers ────────────────────────────────────────────────────────────
@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Endpoint not found', 'code': 404}), 404

@app.errorhandler(500)
def server_error(e):
    return jsonify({'error': 'Internal server error', 'code': 500}), 500

# ── Start server ──────────────────────────────────────────────────────────────
if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'
    print(f"\n🌾 KisanMitra API starting on http://localhost:{port}")
    print(f"   Debug mode: {debug}\n")
    app.run(host='0.0.0.0', port=port, debug=debug)
