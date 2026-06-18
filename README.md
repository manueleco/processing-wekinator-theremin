# Adaptive Expressive Theremin

Adaptive Expressive Theremin is a university creative-technology project about turning movement into sound. It starts from the idea of a virtual theremin, where hand position controls pitch and volume, and extends it with machine-learning mappings, musical practice modes, and movement exercises that can be used for education or rehabilitation-style demonstrations.

The main demo is built in Processing and communicates with Wekinator through OSC. Processing handles the interface, sensing, sound, visual feedback, note quantization, CSV logging, and exercise modes. Wekinator learns a supervised real-time mapping from movement features to musical controls, so the project can compare a fixed rule-based theremin against a more adaptive, personalized instrument.

The project also includes a Python companion app for trajectory exercises, a TensorFlow training base for future offline models, and a prepared Arduino sensor path that is intentionally kept optional. The current presentation-ready version works without Arduino.

This is an educational prototype. It can support discussion around accessibility, music learning, bodily interaction, and movement feedback, but it is not a medical device.

## What the Project Shows

- A Processing theremin controlled by mouse, keyboard trainer, camera motion, or experimental gaze-inspired tracking.
- Direct sound mapping for explaining the baseline instrument.
- Wekinator integration for learned pitch, volume, vibrato, and brightness control.
- Chromatic pitch quantization, so the output can play exact musical notes instead of arbitrary frequencies.
- An `Ode to Joy` practice mode for a simple musical target.
- A trajectory exercise mode scored with Dynamic Time Warping for rehabilitation-style movement feedback.
- CSV logging and TensorFlow scripts for future model training and evaluation.
- A macOS launcher and a clean project structure for demonstration and delivery.

## Repository Structure

```text
.
|-- README.md
|-- .gitignore
`-- Theremin ML/
    |-- README.md
    |-- Adaptive Expressive Theremin.command
    |-- apps/
    |-- arduino/
    |-- config/
    |-- ml/
    |-- scripts/
    |-- tools/
    `-- wekinator_projects/
```

## Main Project Folder

Most of the actual project lives inside `Theremin ML/`.

```text
Theremin ML/
```

This folder contains the runnable demo, supporting apps, ML utilities, Wekinator projects, and the detailed project README. If you only read one technical document after this root overview, read:

```text
Theremin ML/README.md
```

## Folder Guide

```text
Theremin ML/apps/
```

Contains the application code.

- `apps/processing_wekinator/` is the main Processing and Wekinator demo.
- `apps/python_rehab/` is a Python companion app for hand tracking, gesture/trajectory scoring, and DTW-based exercises.

```text
Theremin ML/arduino/
```

Contains the optional Arduino sensor prototype. This is prepared for future sensor-fusion tests, but the current demo does not depend on physical hardware.

```text
Theremin ML/config/
```

Contains shared configuration for exercises, including the melody practice task and trajectory paths used by the Processing and Python demos.

```text
Theremin ML/ml/
```

Contains the TensorFlow-oriented training base: dataset checking, CSV training wrappers, model training scripts, and model/dataset card templates. This is the path for turning recorded sessions into evaluated offline models.

```text
Theremin ML/scripts/
```

Contains double-clickable macOS helper scripts for launching the Processing demo and running training utilities.

```text
Theremin ML/tools/
```

Contains project support tools, including the macOS launcher builder and Wekinator helper scripts for bootstrap training and OSC output probing.

```text
Theremin ML/wekinator_projects/
```

Contains Wekinator project files. The saved `thereminwekinator` project is the quickest path for showing the expressive `6 inputs / 4 outputs` mapping during a live demo.

## Running the Demo

The simplest macOS path is:

```text
Theremin ML/Adaptive Expressive Theremin.command
```

You can also open the Processing sketch directly:

```text
Theremin ML/apps/processing_wekinator/processing_wekinator_theremin/processing_wekinator_theremin.pde
```

Recommended demo flow:

1. Start with mouse or keyboard trainer input.
2. Press `M` to enable sound.
3. Press `U` for a larger presentation window.
4. Use `Q` to switch between continuous, chromatic, pentatonic, and `Ode to Joy` pitch modes.
5. Use `P` to switch into melody practice or trajectory exercise mode.
6. Open the saved Wekinator project and use `W` in Processing to compare direct control with the learned mapping.

Processing libraries required:

- `oscP5`
- `Sound`
- `Video Library for Processing 4`

## Wekinator Profile

The main machine-learning demo uses:

```text
Inputs: 6
Outputs: 4
Input OSC: /wek/inputs on port 6448
Output OSC: /wek/outputs to localhost:12000
```

The inputs describe movement and tracking quality:

```text
pitch proximity, volume distance, movement speed, acceleration, confidence, estimated noise
```

The outputs control musical behavior:

```text
corrected pitch, corrected volume, vibrato amount, timbre brightness
```

The point is not to use machine learning as decoration. Wekinator acts as a personalized mapping layer: it can learn how a specific performer moves and translate imperfect, noisy movement into more stable or expressive musical control.

## Generated and Local Folders

Some local folders are intentionally ignored by Git:

- `Theremin ML/.project_internal/` for private planning notes.
- `Theremin ML/dist/` for generated app exports.
- `Theremin ML/submission_package/` for local ZIP/package deliverables.
- `Theremin ML/processing_prototypes/` for scratch sketches.
- `Theremin ML/ml/models/` and `Theremin ML/ml/runs/` for generated ML outputs.
- Processing `data_logs/` folders for local CSV recordings.

These are useful while developing or presenting, but they are not part of the public repository snapshot.

## Current Status

The repo is set up for a stable no-Arduino presentation:

- Processing demo ready.
- Wekinator expressive project saved.
- Python rehab base included.
- TensorFlow training path prepared.
- Arduino kept as an optional future extension.

For full controls, training notes, and the detailed demo sequence, continue with:

```text
Theremin ML/README.md
```
