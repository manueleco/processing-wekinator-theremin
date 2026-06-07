# Formal Project Framing

## Working Title

**Adaptive Expressive Theremin**

The project is a machine-learning musical interface that turns body, camera, or gaze-inspired movement into sound. It uses Processing for sensing, sound synthesis, visualization, and OSC communication, and Wekinator for supervised real-time learning.

## Core Idea

The system behaves like a virtual theremin, but with an important difference:

```text
traditional theremin: distance -> pitch and volume
adaptive theremin: noisy movement features -> learned musical intention -> sound
```

Processing can already map movement directly to pitch and volume. Wekinator makes the project more meaningful because it learns a personalized mapping from imperfect human movement to stable and expressive musical control.

## Why Wekinator Is Actually Useful

Wekinator is not being used only as a decorative AI element. Its role can be justified in three practical ways.

### 1. Noise Reduction and Stabilization

Camera and eye-inspired tracking are noisy. Small lighting changes, body movement, and webcam limitations can produce unstable coordinates.

Wekinator can be trained to transform noisy input features into more stable musical outputs:

```text
raw pitch proximity, volume distance, speed, confidence, noise
-> Wekinator
-> stabilized pitch and volume
```

This is useful because the musical output can remain controlled even when the raw sensor values fluctuate.

### 2. Personalized Calibration

Different users move differently. A fixed rule such as `x position = pitch` assumes that everyone has the same range of motion and precision.

Wekinator allows the performer to train examples that match their own body, camera setup, or movement limits.

Example:

| User movement | Desired output |
| --- | --- |
| comfortable left position | low pitch |
| comfortable center position | medium pitch |
| comfortable right position | high pitch |
| still gesture | sustained stable tone |
| fast gesture | expressive tone |

This makes the instrument adaptive rather than rigid.

### 3. Expressive Musical Control

The expressive mode sends more features to Wekinator:

```text
pitch proximity
volume loop distance
movement speed
movement acceleration
tracking confidence
estimated sensor noise
```

Wekinator can then output:

```text
pitch
volume
vibrato amount
timbre brightness
```

This means the model is not only controlling "which note" or "how loud." It can learn how energetic, unstable, smooth, or intentional a gesture feels.

## Implemented Profiles

### Basic Wekinator Profile

Use this when you want the simplest setup.

```text
Inputs: 2
Outputs: 2
```

Inputs:

```text
1. pitch antenna proximity
2. volume loop distance
```

Outputs:

```text
1. pitch
2. volume
```

### Expressive Wekinator Profile

Use this when you want the project to feel more like a formal AI musical interface.

```text
Inputs: 6
Outputs: 4
```

Inputs:

```text
1. pitch antenna proximity
2. volume loop distance
3. movement speed
4. movement acceleration
5. tracking confidence
6. estimated sensor noise / instability
```

Outputs:

```text
1. stabilized pitch or melody position
2. stabilized volume
3. vibrato amount
4. timbre brightness
```

In Processing, press `X` to switch between the basic and expressive OSC profiles.

### Sensor-Fusion Wekinator Profile

Use this when Arduino distance sensing is connected.

```text
Inputs: 10
Outputs: 4
```

Inputs:

```text
1. pitch antenna proximity
2. volume loop distance
3. movement speed
4. movement acceleration
5. tracking confidence
6. camera/tracking noise
7. Arduino pitch distance mapped to 0..1
8. Arduino volume distance mapped to 0..1
9. Arduino sensor speed
10. Arduino sensor confidence
```

Outputs:

```text
1. corrected pitch
2. corrected volume
3. vibrato amount
4. timbre brightness
```

This profile makes Wekinator useful as a real sensor-fusion model. It learns how to match camera/movement estimates with physical distance sensing and output a more stable musical control signal.

## Suggested Expressive Training Examples

Record examples in Wekinator where the desired outputs reflect musical intention, not only physical position.

| Gesture example | Pitch | Volume | Vibrato | Brightness |
| --- | ---: | ---: | ---: | ---: |
| still, relaxed, low position | 0.15 | 0.45 | 0.00 | 0.10 |
| still, relaxed, high position | 0.85 | 0.55 | 0.00 | 0.20 |
| slow controlled movement | 0.45 | 0.60 | 0.10 | 0.25 |
| fast energetic movement | 0.65 | 0.80 | 0.65 | 0.85 |
| shaky or noisy movement | 0.50 | 0.35 | 0.20 | 0.15 |
| intentional circular/expressive motion | 0.70 | 0.75 | 0.80 | 0.70 |
| close to volume loop / silence area | 0.50 | 0.00 | 0.00 | 0.00 |

This creates a useful distinction:

```text
raw movement = what the camera sees
Wekinator output = what the instrument understands musically
```

## Melody Trainer Variant

The `Ode to Joy` mode gives the instrument an educational task.

Instead of mapping pitch to arbitrary frequencies, the pitch axis selects steps from a known melody.

```text
movement -> Wekinator pitch output -> melody step -> note
```

This can be presented as a playful melody-training system. The user tries to control movement well enough to reproduce a recognizable phrase.

## Pitch Precision and Quantization

The project includes different pitch modes for different musical goals.

| Pitch mode | Purpose |
| --- | --- |
| continuous | preserves the free glissando behavior of a traditional theremin |
| chromatic | snaps movement to precise semitone notes from `C3` to `C6` |
| pentatonic | constrains notes to a friendly improvisation scale |
| Ode to Joy | maps movement to the steps of a known melody |

The chromatic mode is important because it makes the instrument more functional as a musical controller. Instead of generating arbitrary frequencies, the pitch output is converted into exact MIDI notes.

```text
Wekinator pitch prediction -> chromatic MIDI note -> precise frequency
```

This makes the system easier to evaluate because the user can aim for recognizable notes rather than uncontrolled pitch values.

## Health, Education, and Accessibility Justification

The project can be framed as more than a music toy.

Potential educational value:

- teaches cause and effect through sound
- supports pitch direction and melody learning
- connects physical movement with auditory feedback
- encourages timing, attention, and motor planning
- allows experimentation with musical expression without needing a traditional instrument

Potential health/accessibility value:

- can adapt to small or limited movements
- can turn rehabilitation-like movement practice into a musical activity
- can support users who cannot easily use keyboards or standard controllers
- can be personalized to each user's movement range
- can make repetitive coordination exercises more motivating

Good explanation:

```text
The project uses machine learning to adapt a musical interface to the user, transforming noisy or limited movement into stable, expressive sound control.
```

## Arduino and Physical Sensor Extension

An Arduino can be integrated, especially with a distance sensor. A first single-sensor sketch is included in:

```text
arduino/tof_single_sensor/tof_single_sensor.ino
```

Possible sensors:

- ultrasonic distance sensor
- infrared distance sensor
- time-of-flight distance sensor
- potentiometer
- flex sensor
- accelerometer / IMU
- light sensor

Recommended architecture:

```text
Arduino sensor
-> Serial data to Processing
-> OSC features to Wekinator
-> Wekinator predictions back to Processing
-> sound synthesis
```

In this architecture, Arduino is the physical sensor layer, Processing is the communication and sound layer, and Wekinator is the machine-learning layer.

The current serial format is:

```text
A,pitch_mm,volume_mm,confidence
```

This supports a one-sensor version immediately and a two-sensor version later.

## Gamification and Rehabilitation-Style Exercises

The project now includes a first practice mode. Press `P` in Processing to start a note-hold game based on `Ode to Joy`.

The purpose is to turn musical control into a measurable task:

```text
target note -> controlled position -> hold stability -> score/progress
```

This can be extended toward physiotherapy-style exercises by configuring:

- target positions
- hold duration
- movement range
- repetition count
- acceptable noise/tremor
- rest intervals
- progress scoring

A draft exercise configuration exists in:

```text
config/exercises.json
```

This should be presented as an educational/wellness prototype, not a medical device.

## Application Deliverable

The most realistic final app deliverable is a Processing macOS export:

```text
Processing -> File -> Export Application
```

This keeps camera, sound, serial, and OSC support together. Wekinator would still run as a separate companion app for the course prototype.

A future web version would require a partial rebuild:

```text
React + WebAudio + Canvas/p5.js + Web Serial + TensorFlow.js
```

The web route becomes more attractive after collecting data and training a TensorFlow/TensorFlow.js model, because Wekinator itself is not naturally browser-native.

## Can the Wekinator Model Run on Arduino?

Not directly.

Wekinator is designed to run on a computer and communicate through OSC. It does not normally export a trained model that can be uploaded directly to Arduino.

Realistic options:

### Option 1: Best for This Course Project

Keep Wekinator running on the MacBook and use Arduino only as an input sensor.

```text
Arduino -> Processing -> Wekinator -> Processing audio
```

This is practical, explainable, and achievable.

### Option 2: Advanced TinyML Version

Train or recreate a smaller model that can run on a microcontroller.

Possible technologies:

- TensorFlow Lite Micro
- Edge Impulse
- Arduino Nano 33 BLE Sense
- ESP32
- hand-coded regression or classification
- small decision tree or k-nearest-neighbor model

This would be a different version of the project, because the Wekinator model itself would need to be replaced or approximated.

## Formal Scope

For the current lab, the strongest scope is:

```text
Build an adaptive expressive theremin where Wekinator learns to stabilize noisy movement data and convert it into pitch, volume, vibrato, and timbre.
```

Optional extension:

```text
Add Arduino distance sensing as another input source, while keeping Wekinator on the MacBook.
```

Future research extension:

```text
Explore TinyML deployment so a simplified trained model can run directly on embedded hardware.
```
