# Future Work

## Sensor Fusion Improvements

- Add support for two physical distance sensors:
  - right-hand sensor for pitch
  - left-hand sensor for volume
- Add a calibration screen for Arduino distance min/max.
- Add serial port selection inside Processing instead of automatic detection.
- Compare camera-only control vs Arduino-only control vs Wekinator fusion control.

## TensorFlow Direction

Use TensorFlow after collecting enough CSV logs.

Possible models:

- regression model for stable pitch/volume/vibrato/brightness
- classifier for gesture labels such as `hold`, `swipe`, `circle`, `noisy`, `stable`
- sequence model for trajectory recognition
- TensorFlow Lite model for mobile or embedded experiments
- TensorFlow.js model for a browser version

Useful datasets:

- stable low/middle/high position examples
- noisy vs stable movement examples
- fast vs slow expressive movement
- Arduino distance + camera tracking pairs
- target-note attempts during practice mode
- rehabilitation-style range-of-motion sessions

## Gamification and Therapy Exercises

The practice mode can evolve into configurable games.

Possible games:

- note target game
- melody reproduction game
- hold-stability game
- left/right range-of-motion game
- vertical reach game
- smoothness challenge
- vibrato control challenge

For physiotherapy or rehabilitation framing, each exercise should expose:

- target position
- required hold time
- allowed noise/tremor
- movement range
- number of repetitions
- rest duration
- score or progress feedback

Important note: this should be presented as an educational or wellness prototype, not a medical device.

## App Deliverables

### Option 1: Processing macOS App

This is the most realistic deliverable for the current project.

Use Processing:

```text
File -> Export Application
```

Pros:

- fastest path
- keeps OSC, camera, sound, and serial support
- works well for a course demo
- can be shared as a macOS app bundle

Cons:

- still depends on macOS permissions for camera, microphone/audio, serial, and local network
- Wekinator remains a separate app unless replaced by TensorFlow later

### Option 2: Packaged Desktop App

A future app could wrap the experience in a more polished desktop shell.

Possible technologies:

- Processing exported app
- Java application packaging
- Electron wrapper
- Tauri wrapper

The simplest version is still Processing export.

### Option 3: React Web App

A browser version is possible but would be a partial rebuild.

Possible stack:

```text
React + WebAudio + Canvas/p5.js + Web Serial + TensorFlow.js
```

Pros:

- easier to share
- can run without Processing
- TensorFlow.js can run a trained model in browser
- Web Serial can read Arduino in compatible browsers

Cons:

- Wekinator OSC does not fit naturally in the browser
- camera and serial permissions are browser-dependent
- sound synthesis must be rebuilt with WebAudio or Tone.js
- local network/OSC workflows become more complex

Best web direction:

```text
Processing/Wekinator prototype -> collect data -> train TensorFlow -> port model to TensorFlow.js -> build React/WebAudio app
```

## Recommended Next Milestones

1. Test one VL53L1X Arduino sensor with Processing.
2. Record sensor-fusion CSV data.
3. Train the starter TensorFlow regression model.
4. Compare Wekinator output vs TensorFlow output offline.
5. Improve practice mode using `config/exercises.json`.
6. Export a macOS Processing app for the final deliverable.
7. Treat React/WebAudio as a future version after the course demo.

