/*
  Adaptive Expressive Theremin - single VL53L1X sensor

  Sends distance data to Processing over USB serial:

    A,pitch_mm,volume_mm,confidence

  For a one-sensor prototype, volume_mm is sent as -1. Processing will keep
  volume at a playable default while using pitch_mm for physical pitch control.

  Arduino Library Manager dependencies:
  - Adafruit VL53L1X
  - Adafruit BusIO
*/

#include <Wire.h>
#include <Adafruit_VL53L1X.h>

#define IRQ_PIN 2
#define XSHUT_PIN 3

Adafruit_VL53L1X distanceSensor = Adafruit_VL53L1X(XSHUT_PIN, IRQ_PIN);

const unsigned long SERIAL_BAUD = 115200;
const int INVALID_DISTANCE_MM = -1;

void setup() {
  Serial.begin(SERIAL_BAUD);
  while (!Serial) {
    delay(10);
  }

  Wire.begin();

  if (!distanceSensor.begin(0x29, &Wire)) {
    Serial.println("ERR,VL53L1X_NOT_FOUND");
    while (true) {
      delay(100);
    }
  }

  distanceSensor.setTimingBudget(50);
  distanceSensor.startRanging();
}

void loop() {
  if (!distanceSensor.dataReady()) {
    return;
  }

  int16_t distanceMm = distanceSensor.distance();
  distanceSensor.clearInterrupt();

  float confidence = 1.0;
  if (distanceMm <= 0) {
    distanceMm = INVALID_DISTANCE_MM;
    confidence = 0.0;
  }

  Serial.print("A,");
  Serial.print(distanceMm);
  Serial.print(",");
  Serial.print(INVALID_DISTANCE_MM);
  Serial.print(",");
  Serial.println(confidence, 2);
}

