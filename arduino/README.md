# Arduino Sensor Layer

This folder contains optional Arduino sketches for turning the project into a physical sensor instrument.

## Recommended Sensor

Use a `VL53L1X` Time-of-Flight distance sensor for the first physical prototype.

Why this sensor is useful:

- it measures real hand distance
- it is more precise than a cheap ultrasonic sensor
- it fits the theremin metaphor well
- it can provide a physical reference for Wekinator sensor fusion

## Current Sketch

Open this file in Arduino IDE:

```text
arduino/tof_single_sensor/tof_single_sensor.ino
```

Install these Arduino libraries from Library Manager:

- `Adafruit VL53L1X`
- `Adafruit BusIO`

The sketch sends serial lines at `115200` baud:

```text
A,pitch_mm,volume_mm,confidence
```

For the one-sensor prototype:

```text
A,320,-1,1.00
```

`-1` means that the second distance sensor is not connected yet.

## Wiring

Typical VL53L1X breakout wiring:

| VL53L1X | Arduino Uno/Nano |
| --- | --- |
| VIN | 5V or 3.3V, depending on breakout |
| GND | GND |
| SDA | A4 |
| SCL | A5 |
| XSHUT | D3 |
| IRQ | D2 |

Some breakouts only require VIN, GND, SDA, and SCL. Keep XSHUT/IRQ connected if using the provided sketch.

## Processing Integration

Processing scans for serial ports containing:

```text
usbmodem
usbserial
wchusbserial
```

When the Arduino is detected, the HUD shows:

```text
arduino: <pitch_mm>mm/<volume_mm>mm
```

Press `C` until the input mode says:

```text
Input: arduino sensor
```

Press `X` until the Wekinator profile says:

```text
fusion OSC: 10 inputs / 4 outputs
```

## Wekinator Fusion Profile

Use this Wekinator project setup:

```text
Inputs: 10
Outputs: 4
Output type: All continuous
Input OSC: /wek/inputs
Input port: 6448
Output OSC: /wek/outputs
Output port: 12000
```

Fusion inputs:

```text
1. pitch proximity from Processing
2. volume control from Processing
3. movement speed
4. movement acceleration
5. tracking confidence
6. camera/tracking noise
7. Arduino pitch distance mapped to 0..1
8. Arduino volume distance mapped to 0..1
9. Arduino sensor speed
10. Arduino sensor confidence
```

Fusion outputs:

```text
1. corrected pitch
2. corrected volume
3. vibrato amount
4. timbre brightness
```

## Two-Sensor Upgrade

The project already accepts a second distance value:

```text
A,pitch_mm,volume_mm,confidence
```

The recommended future physical build is:

- right-side VL53L1X for pitch distance
- left-side VL53L1X for volume distance

Two VL53L1X sensors require handling their I2C addresses with XSHUT pins, because they normally start with the same default address.

