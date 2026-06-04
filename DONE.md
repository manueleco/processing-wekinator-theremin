# Done

## Core Instrument

- Built a Processing virtual theremin.
- Added OSC communication with Wekinator.
- Added direct preview mode and Wekinator mode.
- Added sound synthesis with sine and saw oscillators.
- Added visual feedback for pitch antenna, volume loop, waveform, and control point.

## Input Modes

- Mouse control.
- Camera motion tracking.
- Experimental gaze-inspired eye-region tracking.
- Optional Arduino serial input mode.

## Musical Modes

- Continuous theremin glissando.
- Chromatic quantization from `C3` to `C6`.
- Pentatonic quantization.
- `Ode to Joy` melody-step mode.

## Wekinator Profiles

- Basic `2 inputs / 2 outputs`.
- Expressive `6 inputs / 4 outputs`.
- Sensor-fusion `10 inputs / 4 outputs`.

## Expressive Features

Processing now computes:

- movement speed
- movement acceleration
- tracking confidence
- estimated noise
- Arduino distance control
- Arduino sensor speed
- Arduino confidence

Wekinator can map these to:

- corrected pitch
- corrected volume
- vibrato
- timbre brightness

## Arduino Base

Added:

```text
arduino/tof_single_sensor/tof_single_sensor.ino
arduino/README.md
```

The Arduino sketch sends:

```text
A,pitch_mm,volume_mm,confidence
```

Processing reads this serial format and can use it as a physical sensor layer.

## TensorFlow Base

Added:

```text
ml/README.md
ml/requirements.txt
ml/train_sensor_fusion.py
```

Processing can log CSV data with `L`. The Python script can train a starter regression model from those logs.

## Gamification Base

- Added practice mode with `P`.
- The first game asks the user to hit and hold target notes from `Ode to Joy`.
- Added a draft exercise config:

```text
config/exercises.json
```

## Documentation

- README setup and controls.
- Formal project framing.
- AI training ideas.
- Arduino sensor notes.
- Process, done, and future-work documents.

