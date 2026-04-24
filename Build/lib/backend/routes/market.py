# ─────────────────────────────────────────────────────────────────────────────
# routes/market.py
#
# Mandi (agricultural market) price data for 5 major Indian cities.
# Data is manually curated and realistic. You can update the prices
# periodically or hook it up to a paid data source later.
#
# ENDPOINTS:
#   GET /api/mandi              → all cities
#   GET /api/mandi?city=Raipur  → single city
#   GET /api/mandi/crops        → all unique crop names
# ─────────────────────────────────────────────────────────────────────────────

import datetime
import random
from flask import Blueprint, jsonify, request

market_bp = Blueprint('market', __name__)

# ─────────────────────────────────────────────────────────────────────────────
# MANDI DATA
# Prices in ₹ per quintal (100 kg). Updated manually for realism.
# Structure: { city: { crop: { price, unit, trend, change_pct, updated } } }
# ─────────────────────────────────────────────────────────────────────────────
MANDI_DATA = {
    "Raipur": {
        "state": "Chhattisgarh",
        "crops": [
            {"crop": "Paddy (Common)",  "emoji": "🌾", "price": 2183, "unit": "₹/quintal", "trend": "stable", "change": +0.5,  "grade": "FAQ"},
            {"crop": "Wheat",           "emoji": "🌾", "price": 2275, "unit": "₹/quintal", "trend": "up",     "change": +1.8,  "grade": "Grade A"},
            {"crop": "Maize",           "emoji": "🌽", "price": 1980, "unit": "₹/quintal", "trend": "up",     "change": +3.2,  "grade": "Yellow"},
            {"crop": "Soybean",         "emoji": "🫘", "price": 4800, "unit": "₹/quintal", "trend": "down",   "change": -1.5,  "grade": "FAQ"},
            {"crop": "Arhar (Tur Dal)", "emoji": "🟡", "price": 7200, "unit": "₹/quintal", "trend": "up",     "change": +2.1,  "grade": "Bold"},
            {"crop": "Chana (Gram)",    "emoji": "🟤", "price": 5650, "unit": "₹/quintal", "trend": "stable", "change": +0.3,  "grade": "FAQ"},
            {"crop": "Tomato",          "emoji": "🍅", "price": 1800, "unit": "₹/quintal", "trend": "down",   "change": -8.5,  "grade": "A Grade"},
            {"crop": "Onion",           "emoji": "🧅", "price": 1450, "unit": "₹/quintal", "trend": "up",     "change": +5.2,  "grade": "Medium"},
        ]
    },
    "Bhopal": {
        "state": "Madhya Pradesh",
        "crops": [
            {"crop": "Wheat",           "emoji": "🌾", "price": 2340, "unit": "₹/quintal", "trend": "up",     "change": +2.3,  "grade": "Grade A"},
            {"crop": "Soybean",         "emoji": "🫘", "price": 5230, "unit": "₹/quintal", "trend": "up",     "change": +1.2,  "grade": "Yellow"},
            {"crop": "Maize",           "emoji": "🌽", "price": 1890, "unit": "₹/quintal", "trend": "up",     "change": +4.7,  "grade": "Yellow"},
            {"crop": "Chana (Gram)",    "emoji": "🟤", "price": 5820, "unit": "₹/quintal", "trend": "down",   "change": -0.9,  "grade": "Bold"},
            {"crop": "Urad Dal",        "emoji": "⚫", "price": 6900, "unit": "₹/quintal", "trend": "stable", "change": +0.1,  "grade": "FAQ"},
            {"crop": "Mustard",         "emoji": "🌼", "price": 5100, "unit": "₹/quintal", "trend": "up",     "change": +3.8,  "grade": "FAQ"},
            {"crop": "Garlic",          "emoji": "🧄", "price": 7600, "unit": "₹/quintal", "trend": "down",   "change": -3.5,  "grade": "Medium"},
            {"crop": "Potato",          "emoji": "🥔", "price": 1200, "unit": "₹/quintal", "trend": "down",   "change": -2.1,  "grade": "A Grade"},
        ]
    },
    "Nagpur": {
        "state": "Maharashtra",
        "crops": [
            {"crop": "Orange",          "emoji": "🍊", "price": 3200, "unit": "₹/quintal", "trend": "up",     "change": +6.5,  "grade": "Export"},
            {"crop": "Cotton",          "emoji": "🌸", "price": 6780, "unit": "₹/quintal", "trend": "down",   "change": -0.8,  "grade": "MCU-5"},
            {"crop": "Soybean",         "emoji": "🫘", "price": 4950, "unit": "₹/quintal", "trend": "stable", "change": +0.4,  "grade": "FAQ"},
            {"crop": "Wheat",           "emoji": "🌾", "price": 2310, "unit": "₹/quintal", "trend": "up",     "change": +1.5,  "grade": "Grade A"},
            {"crop": "Chana (Gram)",    "emoji": "🟤", "price": 5500, "unit": "₹/quintal", "trend": "down",   "change": -1.2,  "grade": "Bold"},
            {"crop": "Turmeric",        "emoji": "🌿", "price": 8200, "unit": "₹/quintal", "trend": "up",     "change": +1.8,  "grade": "Finger"},
            {"crop": "Onion",           "emoji": "🧅", "price": 1650, "unit": "₹/quintal", "trend": "up",     "change": +4.1,  "grade": "Medium"},
            {"crop": "Tomato",          "emoji": "🍅", "price": 1560, "unit": "₹/quintal", "trend": "down",   "change": -5.2,  "grade": "A Grade"},
        ]
    },
    "Mumbai": {
        "state": "Maharashtra",
        "crops": [
            {"crop": "Rice (Basmati)",  "emoji": "🌾", "price": 4800, "unit": "₹/quintal", "trend": "up",     "change": +2.0,  "grade": "1121"},
            {"crop": "Rice (Common)",   "emoji": "🌾", "price": 3120, "unit": "₹/quintal", "trend": "down",   "change": -1.1,  "grade": "Parmal"},
            {"crop": "Wheat",           "emoji": "🌾", "price": 2290, "unit": "₹/quintal", "trend": "stable", "change": +0.8,  "grade": "Grade A"},
            {"crop": "Onion",           "emoji": "🧅", "price": 2100, "unit": "₹/quintal", "trend": "up",     "change": +8.3,  "grade": "Medium"},
            {"crop": "Potato",          "emoji": "🥔", "price": 1350, "unit": "₹/quintal", "trend": "up",     "change": +3.4,  "grade": "A Grade"},
            {"crop": "Tomato",          "emoji": "🍅", "price": 2400, "unit": "₹/quintal", "trend": "up",     "change": +12.5, "grade": "A Grade"},
            {"crop": "Coconut",         "emoji": "🥥", "price": 2100, "unit": "₹/100 pcs", "trend": "stable", "change": +0.5,  "grade": "Medium"},
            {"crop": "Banana",          "emoji": "🍌", "price": 1800, "unit": "₹/quintal", "trend": "down",   "change": -2.3,  "grade": "Grade A"},
        ]
    },
    "Hyderabad": {
        "state": "Telangana",
        "crops": [
            {"crop": "Rice (Raw)",      "emoji": "🌾", "price": 3450, "unit": "₹/quintal", "trend": "stable", "change": +0.6,  "grade": "BPT"},
            {"crop": "Cotton",          "emoji": "🌸", "price": 6950, "unit": "₹/quintal", "trend": "up",     "change": +1.9,  "grade": "Long Staple"},
            {"crop": "Maize",           "emoji": "🌽", "price": 2050, "unit": "₹/quintal", "trend": "up",     "change": +5.1,  "grade": "Yellow"},
            {"crop": "Chilli (Red)",    "emoji": "🌶️", "price": 9800, "unit": "₹/quintal", "trend": "up",     "change": +3.4,  "grade": "S4 Teja"},
            {"crop": "Turmeric",        "emoji": "🌿", "price": 9200, "unit": "₹/quintal", "trend": "up",     "change": +4.6,  "grade": "Finger"},
            {"crop": "Sunflower",       "emoji": "🌻", "price": 5600, "unit": "₹/quintal", "trend": "down",   "change": -1.4,  "grade": "FAQ"},
            {"crop": "Groundnut",       "emoji": "🥜", "price": 5800, "unit": "₹/quintal", "trend": "stable", "change": +0.2,  "grade": "Bold"},
            {"crop": "Tomato",          "emoji": "🍅", "price": 1900, "unit": "₹/quintal", "trend": "down",   "change": -6.8,  "grade": "A Grade"},
        ]
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 1: Get mandi prices
# GET /api/mandi               → all cities
# GET /api/mandi?city=Raipur   → single city
# ─────────────────────────────────────────────────────────────────────────────
@market_bp.route('/mandi', methods=['GET'])
def get_mandi():
    """
    Returns mandi crop prices.

    Query params:
      city (str, optional): City name — Raipur, Bhopal, Nagpur, Mumbai, Hyderabad

    Example response for single city:
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
            },
            ...
        ]
    }
    """
    city = request.args.get('city', None)
    now  = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # ── Single city ───────────────────────────────────────────────────────────
    if city:
        # Case-insensitive city match
        city_key = _find_city(city)
        if not city_key:
            available = list(MANDI_DATA.keys())
            return jsonify({
                'error': f'City "{city}" not found.',
                'available_cities': available
            }), 404

        city_data = MANDI_DATA[city_key]
        return jsonify({
            'city':         city_key,
            'state':        city_data['state'],
            'last_updated': now,
            'crops':        city_data['crops'],
        }), 200

    # ── All cities ────────────────────────────────────────────────────────────
    result = []
    for city_name, city_data in MANDI_DATA.items():
        result.append({
            'city':         city_name,
            'state':        city_data['state'],
            'last_updated': now,
            'crops':        city_data['crops'],
        })

    return jsonify({
        'total_cities':  len(result),
        'last_updated':  now,
        'markets':       result,
    }), 200


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 2: Get all unique crops (for filtering/search)
# GET /api/mandi/crops
# ─────────────────────────────────────────────────────────────────────────────
@market_bp.route('/mandi/crops', methods=['GET'])
def get_all_crops():
    """Returns a deduplicated list of all crop names across all cities."""
    seen   = set()
    result = []

    for city_data in MANDI_DATA.values():
        for crop in city_data['crops']:
            key = crop['crop']
            if key not in seen:
                seen.add(key)
                result.append({
                    'crop':  key,
                    'emoji': crop['emoji'],
                })

    return jsonify({
        'total': len(result),
        'crops': sorted(result, key=lambda x: x['crop']),
    }), 200


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 3: Get top movers (biggest price changes today)
# GET /api/mandi/top-movers
# ─────────────────────────────────────────────────────────────────────────────
@market_bp.route('/mandi/top-movers', methods=['GET'])
def top_movers():
    """Returns top 5 crops with highest price changes (+ or -)."""
    all_crops = []

    for city_name, city_data in MANDI_DATA.items():
        for crop in city_data['crops']:
            all_crops.append({**crop, 'city': city_name})

    # Sort by absolute % change
    sorted_crops = sorted(all_crops, key=lambda c: abs(c['change']), reverse=True)

    return jsonify({
        'top_movers': sorted_crops[:8],
        'generated':  datetime.datetime.now().strftime('%Y-%m-%d %H:%M'),
    }), 200


# ─────────────────────────────────────────────────────────────────────────────
# Helper
# ─────────────────────────────────────────────────────────────────────────────
def _find_city(city: str) -> str | None:
    """Case-insensitive city lookup. Returns canonical key or None."""
    for key in MANDI_DATA:
        if key.lower() == city.lower():
            return key
    return None
