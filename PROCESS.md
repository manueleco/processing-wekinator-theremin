# Process

## Current Architecture

```text
mouse / camera / eye-inspired tracking / Arduino sensor
-> Processing feature extraction
-> OSC to Wekinator
-> Wekinator prediction
-> Processing sound synthesis and practice UI
```

## Processing Roles

Processing currently handles:

- visual theremin interface
- camera motion tracking
- experimental gaze-inspired tracking
- optional Arduino serial input
- OSC communication with Wekinator
- sine/saw oscillator sound synthesis
- chromatic, pentatonic, continuous, and melody pitch modes
- CSV data logging for future TensorFlow training
- a first practice/game mode for note-hold exercises

## Wekinator Roles

Wekinator can be used in three profiles.

### Basic

```text
2 inputs -> 2 outputs
```

Use for quick demos:

```text
pitch proximity, volume distance -> pitch, volume
```

### Expressive

```text
6 inputs -> 4 outputs
```

Use for musical expression:

```text
pitch, volume, speed, acceleration, confidence, noise
-> pitch, volume, vibrato, brightness
```

### Sensor Fusion

```text
10 inputs -> 4 outputs
```

Use when Arduino is connected:

```text
camera/gesture features + physical distance sensor features
-> stable pitch, stable volume, vibrato, brightness
```

This is the strongest justification for Wekinator: it learns how to combine noisy camera tracking with physical sensor data.

## Arduino Process

1. Connect a VL53L1X distance sensor to Arduino.
2. Upload `arduino/tof_single_sensor/tof_single_sensor.ino`.
3. Run the Processing sketch.
4. Press `C` until `Input: arduino sensor`.
5. Press `X` until `fusion OSC: 10 inputs / 4 outputs`.
6. Train Wekinator with examples of stable positions and expressive movements.

## Data Collection Process

1. Run the Processing sketch.
2. Press `L` to start CSV logging.
3. Use labels with number keys:

```text
0 free
1 low
2 middle
3 high
4 stable
5 expressive
6 noisy
7 left
8 right
9 hold
```

4. Perform examples with mouse, camera, eye mode, or Arduino.
5. Press `L` again to stop logging.
6. Train the TensorFlow starter model:

```bash
python ml/train_sensor_fusion.py processing_wekinator_theremin/data_logs/session-*.csv
```

## Practice/Game Process

Press `P` to enter practice mode.

The first implemented exercise asks the user to hit notes from `Ode to Joy` in chromatic pitch mode and hold each target note briefly.

This is the base for future configurable exercises:

- note holding
- position targets
- range-of-motion exercises
- stability training
- expressive vibrato training

Draft configuration lives in:

```text
config/exercises.json
```

The Processing sketch does not load this JSON yet. It documents the planned configurable structure.

