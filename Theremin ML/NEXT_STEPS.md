# Next Steps

This file captures the practical next steps for continuing the Adaptive Expressive Theremin project.

## 1. Validate the Current Processing Demo

Open:

```text
Theremin ML/processing_wekinator_theremin/processing_wekinator_theremin.pde
```

Check:

- `C` cycles input modes without freezing.
- `Q` cycles pitch modes: continuous, chromatic, pentatonic, Ode to Joy.
- `P` starts practice mode.
- `X` cycles Wekinator profiles.
- `W` toggles direct preview / Wekinator.
- `O` only tries Arduino serial when explicitly pressed.

## 2. Train Wekinator Without Arduino

Start with the expressive profile:

```text
Inputs: 6
Outputs: 4
```

Use the detailed checklist in:

```text
TRAINING_PROTOCOL.md
```

Train examples for:

- stable low pitch
- stable middle pitch
- stable high pitch
- soft/slow movement
- fast expressive movement
- noisy movement that should be stabilized

Outputs:

```text
pitch, volume, vibrato, brightness
```

Goal:

```text
show that Wekinator can turn noisy movement features into stable expressive musical control
```

## 3. Keep Arduino Ready, But Optional

Arduino support is prepared in the codebase, but it has not been hardware-tested yet. For the current solid demo, Arduino should remain optional and should not block the Processing/Wekinator flow.

When the device is available, if using the ELEGOO kit, first try the ultrasonic distance sensor if included.

Create or use a sketch that sends:

```text
A,pitch_mm,-1,confidence
```

Processing already understands this format.

Recommended next Arduino file:

```text
Theremin ML/arduino/hc_sr04_distance/hc_sr04_distance.ino
```

## 4. Train Wekinator Sensor Fusion

When Arduino serial works:

1. Press `O` to connect Arduino.
2. Press `C` until `Input: arduino sensor`.
3. Press `X` until `fusion OSC: 10 inputs / 4 outputs`.
4. Create a Wekinator project with:

```text
Inputs: 10
Outputs: 4
```

Train Wekinator to combine:

```text
camera / movement features + Arduino physical distance features
```

into:

```text
corrected pitch, corrected volume, vibrato, brightness
```

## 5. Record Data for TensorFlow

Use `L` in Processing to start/stop CSV logging.

Use labels:

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

Then train the starter model:

```bash
python ml/train_sensor_fusion.py processing_wekinator_theremin/data_logs/session-*.csv
```

TensorFlow should be framed as future scalability:

```text
Wekinator = fast live interactive training
TensorFlow = offline training, evaluation, and possible web/TinyML deployment
```

## 6. Improve Gamification

Current:

- `P` enables a note-hold practice game based on Ode to Joy.

Next:

- load `config/exercises.json` from Processing
- add configurable exercises
- add score history
- add stability/noise scoring
- add range-of-motion tasks
- add exercise duration and repetition count

## 7. Prepare the Final Deliverable

Most realistic final deliverable:

```text
Processing macOS app export + Wekinator companion app
```

Use:

```text
Processing -> File -> Export Application
```

Future web version:

```text
React + WebAudio + Web Serial + TensorFlow.js
```

The web version should come after data collection and TensorFlow/TensorFlow.js work.

## Immediate Priority

The next best task is:

```text
Run the documented demo flow, train Wekinator 6 inputs / 4 outputs, record 2-3 real CSV sessions with L, then train the first TensorFlow model.
```

After that, export the Processing sketch as a macOS app and test it without Arduino connected.
