/*
 * ─────────────────────────────────────────────────────────────────────────────
 * KisanMitra IoT — ESP32 Sensor Node
 *
 * HARDWARE REQUIRED:
 *   - ESP32 or ESP8266 development board
 *   - DHT11 or DHT22 sensor (Temperature + Humidity)
 *   - Capacitive Soil Moisture Sensor (analog, e.g. v1.2)
 *
 * WIRING:
 *   DHT11 DATA pin  → GPIO 4  (D4)
 *   Soil Sensor OUT → GPIO 34 (Analog Input, ADC1)
 *   Both sensors    → 3.3V and GND
 *
 * LIBRARIES (install via Arduino IDE Library Manager):
 *   - Firebase ESP32 Client: "Firebase Arduino Client Library for ESP8266 and ESP32"
 *   - DHT sensor library: "DHT sensor library" by Adafruit
 *   - ArduinoJson: "ArduinoJson" by Benoit Blanchon
 *
 * HOW TO SETUP:
 *   1. Install Arduino IDE
 *   2. Add ESP32 board: File → Preferences → Board Manager URLs:
 *      https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
 *   3. Install boards: Tools → Board → Board Manager → search "esp32"
 *   4. Install the three libraries above
 *   5. Fill in your WiFi + Firebase credentials below
 *   6. Upload to ESP32
 *
 * DATA FREQUENCY:
 *   - Sends data every 30 seconds (adjustable via SEND_INTERVAL_MS)
 *   - For critical monitoring: reduce to 10 seconds
 *   - For battery-powered: increase to 5 minutes
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>

// WiFi credentials
#define WIFI_SSID "Realme"
#define WIFI_PASSWORD "13291109"

// Firebase credentials
#define FIREBASE_HOST "https://krishi-mitra-raipur-512f8-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define FIREBASE_AUTH "1upW8SDBV2t66BNPx1S7Q64KMiK9tYGOl8iwxqsR"

// DHT sensor setup
#define DHTPIN 4
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);

// Soil Moisture Setup
#define SOIL_PIN A0

// Firebase objects
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
    Serial.begin(9600);
    dht.begin();

    Serial.print("Connecting to WiFi...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nConnected to WiFi");

    config.database_url = FIREBASE_HOST;
    config.signer.tokens.legacy_token = FIREBASE_AUTH;

    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
}

void loop() {
    // 1. Read DHT Sensor
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();

    // 2. Read Soil Moisture (Value is 0 to 1024)
    int soilRaw = analogRead(SOIL_PIN);
    // Convert to Percentage (1024 = Dry, 0 = Wet)
    int soilPercent = map(soilRaw, 1024, 0, 0, 100);

    if (isnan(temperature) || isnan(humidity)) {
        Serial.println("Failed to read from DHT sensor!");
    } else {
        Serial.print("Temp: "); Serial.print(temperature);
        Serial.print(" C | Hum: "); Serial.print(humidity);
        Serial.print(" % | Soil: "); Serial.print(soilPercent);
        Serial.println(" %");

        // 3. Send All Data to Firebase
        Firebase.RTDB.setFloat(&firebaseData, "/sensor/temperature", temperature);
        Firebase.RTDB.setFloat(&firebaseData, "/sensor/humidity", humidity);
        Firebase.RTDB.setInt(&firebaseData, "/sensor/soil_moisture", soilPercent);

        Serial.println("Data synced to Firebase");
    }

    delay(5000);
}
/*
 * ─────────────────────────────────────────────────────────────────────────────
 * FIREBASE DATA STRUCTURE (what this code sends):
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * sensors/
 * └── farm_001/
 *     ├── latest/                      ← Flutter listens here (real-time)
 *     │   ├── soil_moisture: 45.2
 *     │   ├── temperature: 32.5
 *     │   ├── humidity: 68.0
 *     │   ├── timestamp: 1712400000000
 *     │   └── device_id: "ESP32_FARM_001"
 *     └── data/                        ← Historical log
 *         ├── -NxAbCdef.../
 *         │   ├── soil_moisture: 42.1
 *         │   ├── temperature: 31.8
 *         │   └── ...
 *         └── -NxAbCghi.../
 *             └── ...
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * FIREBASE SECURITY RULES (paste in Firebase Console → Realtime DB → Rules):
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * {
 *   "rules": {
 *     "sensors": {
 *       "$farmId": {
 *         ".read": "auth != null",
 *         ".write": "auth != null"
 *       }
 *     }
 *   }
 * }
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * TROUBLESHOOTING:
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * "DHT read failed":
 *   → Check that DATA pin is connected to GPIO 4
 *   → Add a 10kΩ pull-up resistor between DATA and VCC
 *   → Try DHT22 if DHT11 is unreliable
 *
 * "Firebase auth failed":
 *   → Check FIREBASE_API_KEY is your WEB API key (not service account key)
 *   → Enable Anonymous authentication in Firebase Console
 *   → Check DATABASE_URL format (must include https://)
 *
 * "Soil moisture always 0% or 100%":
 *   → Run calibration: print rawSoil value with sensor in dry soil and wet soil
 *   → Update SOIL_DRY_VALUE and SOIL_WET_VALUE with your actual readings
 *
 * ─────────────────────────────────────────────────────────────────────────────
 */
