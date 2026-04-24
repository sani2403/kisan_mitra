# ─────────────────────────────────────────────────────────────────────────────
# routes/weather.py
#
# Handles all weather-related API endpoints.
# Uses OpenWeatherMap API (free tier) to fetch real-time data.
#
# ENDPOINTS:
#   GET /api/weather?city=Raipur        → current weather
#   GET /api/forecast?city=Raipur       → 7-day forecast
# ─────────────────────────────────────────────────────────────────────────────

import os
import requests
from flask import Blueprint, jsonify, request

# Create a Blueprint — a group of related routes
weather_bp = Blueprint('weather', __name__)

# OpenWeatherMap base URLs
CURRENT_URL  = "https://api.openweathermap.org/data/2.5/weather"
FORECAST_URL = "https://api.openweathermap.org/data/2.5/forecast"   # 5-day / 3-hour
UV_URL       = "https://api.openweathermap.org/data/2.5/uvi"

# Default city if none provided
DEFAULT_CITY = "Raipur"

# ── Helper: get API key ───────────────────────────────────────────────────────
def get_api_key():
    key = os.getenv('OPENWEATHER_API_KEY', '')
    if not key or key == 'your_openweathermap_api_key_here':
        return None
    return key

# ── Helper: map OWM weather code → emoji ─────────────────────────────────────
def weather_emoji(condition_id: int, is_day: bool = True) -> str:
    """
    OpenWeatherMap returns a numeric condition ID.
    Docs: https://openweathermap.org/weather-conditions
    """
    if   condition_id < 300: return '⛈️'   # Thunderstorm
    elif condition_id < 400: return '🌦️'   # Drizzle
    elif condition_id < 600: return '🌧️'   # Rain
    elif condition_id < 700: return '❄️'   # Snow
    elif condition_id < 800: return '🌫️'   # Atmosphere (fog/haze)
    elif condition_id == 800:
        return '☀️' if is_day else '🌙'    # Clear sky
    elif condition_id == 801: return '🌤️'  # Few clouds
    elif condition_id == 802: return '⛅'   # Scattered clouds
    else:                     return '☁️'   # Broken/overcast clouds

# ── Helper: map condition to color hex ───────────────────────────────────────
def weather_color(condition_id: int) -> str:
    if   condition_id < 300: return '#4527A0'   # Purple – thunderstorm
    elif condition_id < 600: return '#0277BD'   # Dark blue – rain
    elif condition_id < 700: return '#546E7A'   # Blue-grey – snow
    elif condition_id < 800: return '#607D8B'   # Grey – fog
    elif condition_id == 800: return '#E65100'  # Orange – clear/sunny
    elif condition_id <= 802: return '#1565C0'  # Blue – partly cloudy
    else:                     return '#455A64'  # Dark grey – overcast

# ── Helper: map OWM description → short label ────────────────────────────────
def short_desc(description: str) -> str:
    mapping = {
        'clear sky':           'Clear & Sunny',
        'few clouds':          'Mostly Sunny',
        'scattered clouds':    'Partly Cloudy',
        'broken clouds':       'Mostly Cloudy',
        'overcast clouds':     'Overcast',
        'light rain':          'Light Rain',
        'moderate rain':       'Moderate Rain',
        'heavy intensity rain':'Heavy Rain',
        'thunderstorm':        'Thunderstorm',
        'light snow':          'Light Snow',
        'mist':                'Misty',
        'haze':                'Hazy',
        'fog':                 'Foggy',
        'drizzle':             'Drizzle',
    }
    return mapping.get(description.lower(), description.title())

# ── Day-of-week helper ────────────────────────────────────────────────────────
import datetime
DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

def day_name(dt_txt: str, index: int) -> str:
    """Return 'Today', 'Tomorrow', or day abbreviation."""
    if index == 0: return 'Today'
    if index == 1: return 'Tomorrow'
    try:
        dt = datetime.datetime.strptime(dt_txt, '%Y-%m-%d %H:%M:%S')
        return DAYS[dt.weekday()]
    except Exception:
        return dt_txt[:3]

# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 1: Current Weather
# GET /api/weather?city=Raipur
# ─────────────────────────────────────────────────────────────────────────────
@weather_bp.route('/weather', methods=['GET'])
def current_weather():
    """
    Returns current weather for the requested city.

    Query params:
      city (str): City name. Default = Raipur

    Example response:
    {
        "city": "Raipur",
        "country": "IN",
        "temperature": 32,
        "feels_like": 36,
        "temp_min": 28,
        "temp_max": 34,
        "humidity": 65,
        "wind_speed": 14,
        "condition": "Partly Cloudy",
        "condition_id": 802,
        "emoji": "⛅",
        "color": "#1565C0",
        "rain_chance": 20,
        "uv_index": 7,
        "visibility": 8,
        "sunrise": "06:12",
        "sunset": "18:45",
        "is_day": true
    }
    """
    city    = request.args.get('city', DEFAULT_CITY)
    api_key = "712710a401f6f59945acc9a7ad3d7841"

    # ── If no API key, return realistic demo data ─────────────────────────────
    if not api_key:
        return jsonify(_demo_current_weather(city)), 200

    try:
        # Call OpenWeatherMap current weather API
        response = requests.get(
            CURRENT_URL,
            params={
                'q':     city + ',IN',   # Restrict to India
                'appid': api_key,
                'units': 'metric',       # Celsius
                'lang':  'en',
            },
            timeout=10   # seconds
        )

        # If OWM returns an error (e.g. city not found)
        if response.status_code != 200:
            owm_error = response.json().get('message', 'Unknown error')
            return jsonify({
                'error': f'OpenWeatherMap error: {owm_error}',
                'city': city,
                'fallback': _demo_current_weather(city)
            }), response.status_code

        data = response.json()

        # ── Parse the response ────────────────────────────────────────────────
        condition_id = data['weather'][0]['id']
        description  = data['weather'][0]['description']
        sunrise_ts   = data['sys']['sunrise']
        sunset_ts    = data['sys']['sunset']
        now_ts       = data['dt']
        is_day       = sunrise_ts < now_ts < sunset_ts

        # Convert Unix timestamps to readable time
        sunrise = datetime.datetime.utcfromtimestamp(sunrise_ts + data['timezone']) \
                            .strftime('%H:%M')
        sunset  = datetime.datetime.utcfromtimestamp(sunset_ts  + data['timezone']) \
                            .strftime('%H:%M')

        return jsonify({
            'city':         data['name'],
            'country':      data['sys']['country'],
            'temperature':  round(data['main']['temp']),
            'feels_like':   round(data['main']['feels_like']),
            'temp_min':     round(data['main']['temp_min']),
            'temp_max':     round(data['main']['temp_max']),
            'humidity':     data['main']['humidity'],
            'wind_speed':   round(data['wind']['speed'] * 3.6),  # m/s → km/h
            'condition':    short_desc(description),
            'condition_id': condition_id,
            'emoji':        weather_emoji(condition_id, is_day),
            'color':        weather_color(condition_id),
            'rain_chance':  round(data.get('clouds', {}).get('all', 0) * 0.8),
            'visibility':   round(data.get('visibility', 10000) / 1000, 1),
            'sunrise':      sunrise,
            'sunset':       sunset,
            'is_day':       is_day,
        }), 200

    except requests.exceptions.Timeout:
        return jsonify({'error': 'Weather service timed out. Try again.',
                        'fallback': _demo_current_weather(city)}), 504
    except requests.exceptions.ConnectionError:
        return jsonify({'error': 'No internet connection.',
                        'fallback': _demo_current_weather(city)}), 503
    except Exception as e:
        return jsonify({'error': str(e),
                        'fallback': _demo_current_weather(city)}), 500


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT 2: 7-Day Forecast
# GET /api/forecast?city=Raipur
# ─────────────────────────────────────────────────────────────────────────────
@weather_bp.route('/forecast', methods=['GET'])
def forecast():
    """
    Returns 7-day weather forecast.
    OWM free tier only provides 5-day/3-hour data, so we
    group by day and pick the midday reading for each day.

    Example response:
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
            },
            ...
        ]
    }
    """
    city    = request.args.get('city', DEFAULT_CITY)
    api_key = get_api_key()

    if not api_key:
        return jsonify(_demo_forecast(city)), 200

    try:
        response = requests.get(
            FORECAST_URL,
            params={
                'q':     city + ',IN',
                'appid': api_key,
                'units': 'metric',
                'cnt':   40,   # 5 days × 8 readings/day
            },
            timeout=10
        )

        if response.status_code != 200:
            return jsonify({'error': response.json().get('message'),
                            'fallback': _demo_forecast(city)}), response.status_code

        data = response.json()

        # ── Group 3-hour slots by calendar date ───────────────────────────────
        daily = {}   # { 'YYYY-MM-DD': [slot, slot, ...] }
        for item in data['list']:
            date_str = item['dt_txt'][:10]   # '2024-04-06'
            daily.setdefault(date_str, []).append(item)

        result = []
        for day_index, (date_str, slots) in enumerate(list(daily.items())[:7]):
            # Pick the slot closest to noon (12:00)
            midday = min(slots,
                key=lambda s: abs(int(s['dt_txt'][11:13]) - 12))

            cid  = midday['weather'][0]['id']
            desc = midday['weather'][0]['description']

            high = round(max(s['main']['temp_max'] for s in slots))
            low  = round(min(s['main']['temp_min'] for s in slots))

            # Parse date for label
            dt  = datetime.datetime.strptime(date_str, '%Y-%m-%d')
            fmt = dt.strftime('%b %-d')    # e.g. "Apr 6"

            result.append({
                'day':   day_name(midday['dt_txt'], day_index),
                'date':  fmt,
                'emoji': weather_emoji(cid),
                'high':  high,
                'low':   low,
                'desc':  short_desc(desc),
                'rain':  round(midday.get('pop', 0) * 100),   # probability of precipitation
                'wind':  round(midday['wind']['speed'] * 3.6),
                'humid': midday['main']['humidity'],
                'color': weather_color(cid),
            })

        return jsonify({'city': data['city']['name'], 'forecast': result}), 200

    except Exception as e:
        return jsonify({'error': str(e),
                        'fallback': _demo_forecast(city)}), 500


# ─────────────────────────────────────────────────────────────────────────────
# Demo / fallback data (used when no API key is set)
# ─────────────────────────────────────────────────────────────────────────────
def _demo_current_weather(city: str) -> dict:
    """Realistic demo data so the app works without an API key."""
    return {
        'city':         city,
        'country':      'IN',
        'temperature':  32,
        'feels_like':   36,
        'temp_min':     26,
        'temp_max':     35,
        'humidity':     65,
        'wind_speed':   14,
        'condition':    'Partly Cloudy',
        'condition_id': 802,
        'emoji':        '⛅',
        'color':        '#1565C0',
        'rain_chance':  20,
        'visibility':   8.0,
        'sunrise':      '06:12',
        'sunset':       '18:45',
        'is_day':       True,
        '_note':        'Demo data — add OPENWEATHER_API_KEY to .env for live data',
    }

def _demo_forecast(city: str) -> dict:
    import datetime
    today = datetime.date.today()
    days  = ['Today','Tue','Wed','Thu','Fri','Sat','Sun']
    emojis  = ['⛅','🌧️','⛈️','🌤️','☀️','🌦️','⛅']
    descs   = ['Partly Cloudy','Light Rain','Thunderstorm','Mostly Sunny',
               'Clear & Sunny','Scattered Showers','Partly Cloudy']
    highs   = [32, 28, 26, 30, 35, 29, 31]
    lows    = [22, 20, 19, 21, 24, 21, 22]
    rains   = [20, 80, 95, 10,  5, 55, 25]
    colors  = ['#1565C0','#0277BD','#4527A0','#2E7D32',
               '#E65100','#00695C','#1565C0']
    forecast = []
    for i in range(7):
        dt  = today + datetime.timedelta(days=i)
        fmt = dt.strftime('%b %-d')
        forecast.append({
            'day':   days[i],
            'date':  fmt,
            'emoji': emojis[i],
            'high':  highs[i],
            'low':   lows[i],
            'desc':  descs[i],
            'rain':  rains[i],
            'wind':  14 + i * 2,
            'humid': 62 + i * 3,
            'color': colors[i],
        })
    return {
        'city':     city,
        'forecast': forecast,
        '_note':    'Demo data — add OPENWEATHER_API_KEY to .env for live data',
    }
