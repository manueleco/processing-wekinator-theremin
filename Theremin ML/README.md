# Adaptive Expressive Theremin

## Abstract

Adaptive Expressive Theremin is a machine-learning musical interface that turns movement into sound, practice feedback, and expressive control. The main application is built in Processing and communicates with Wekinator through OSC so a performer can compare a fixed theremin mapping against a learned, personalized mapping.

The project extends a virtual theremin with chromatic notes, an `Ode to Joy` melody game, camera or mouse control, Wekinator 6-input / 4-output expressive training, CSV logging for TensorFlow experiments, and DTW-scored trajectory exercises that can be framed as educational or rehabilitation-style movement tasks.

This is an educational creative-technology prototype, not a medical device.

## What It Demonstrates

- Musical control: movement controls pitch, volume, vibrato, and brightness.
- Sensor learning: Wekinator maps noisy movement features to stable expressive outputs.
- Precision: chromatic quantization makes notes musically exact instead of random frequencies.
- Gamified practice: `Ode to Joy` note targets and trajectory-following exercises give measurable goals.
- Rehabilitation-style feedback: trajectory score, detected gesture, smoothness, repetitions, and configurable difficulty.
- AI scalability: CSV logs can train an offline TensorFlow regression model for future apps.
- App delivery: the project includes a Processing demo launcher and a Python companion app base.

## Project Structure

```text
Theremin ML/
  Adaptive Expressive Theremin.command
  apps/
    processing_wekinator/      main Processing + Wekinator demo
    python_rehab/              Python hand-tracking + DTW trajectory app
  config/
    exercises.json             shared melody and trajectory exercise config
  ml/
    check_dataset.py           CSV readiness checker
    train_csvs.py              one-command TensorFlow training wrapper
    train_sensor_fusion.py     Keras regression trainer
  scripts/
    run_demo.command           macOS double-click launcher for Processing
    train_csvs.command         macOS double-click TensorFlow trainer
    train_wekinator_demo.command
  tools/
    build_macos_launcher.py    local macOS launcher app generator
    train_wekinator_demo.py    bootstrap Wekinator trainer
    probe_wekinator_outputs.py
  wekinator_projects/
    thereminwekinator/         saved bootstrap-trained Wekinator project
```

## Project Phases

### Phase 1: Stable Live Demo

Goal:

```text
prove the instrument works without Arduino
```

Deliverables:

- Processing sketch launches from the root executable.
- Mouse and keyboard trainer control are reliable.
- Chromatic, `Ode to Joy`, melody game, and trajectory rehab modes can be demonstrated.
- Wekinator expressive `6 inputs / 4 outputs` project can run as the live ML layer.

### Phase 2: Data Collection and First Model

Goal:

```text
turn the demo into a measurable ML experiment
```

Deliverables:

- Record 2-3 real CSV sessions with `L`.
- Include stable, expressive, noisy, melody, and trajectory examples.
- Run dataset validation.
- Train the first TensorFlow/Keras regression model.
- Save a model report and document limitations.

### Phase 3: ML Orchestrator

Goal:

```text
make training and evaluation easier to repeat
```

Deliverables:

- Add a Python orchestrator that checks CSV quality, runs training, compares metrics, and writes model/dataset cards.
- Optionally add a workflow helper to recommend the next data collection step.
- Keep agent decisions outside the real-time audio loop.

### Phase 4: Product-Style App

Goal:

```text
package the experience as a cleaner application
```

Deliverables:

- Export the Processing macOS app or ship the launcher for the course demo.
- Mature the Python rehab app into a more complete hand-tracking interface.
- Add session history, exercise configuration, and clearer user-facing settings.

### Phase 5: Future Deployment Paths

Goal:

```text
explore scalable versions after the presentation
```

Deliverables:

- TensorFlow.js or TFLite export.
- Web app prototype with React/WebAudio if needed.
- Optional Arduino/sensor-fusion layer when hardware is available.

## Main Demo

Open this sketch in Processing:

```text
apps/processing_wekinator/processing_wekinator_theremin/processing_wekinator_theremin.pde
```

Or double-click on macOS:

```text
Adaptive Expressive Theremin.command
```

Alternative launcher:

```text
scripts/run_demo.command
```

Processing libraries required:

- `oscP5`
- `Sound`
- `Video Library for Processing 4`

The safest presentation path works without Arduino. Start with mouse or keyboard trainer input, then use camera only if macOS permissions are already working.

## Wekinator Setup

Use the expressive profile for the main AI demo:

```text
Inputs: 6
Outputs: 4
Input OSC message: /wek/inputs
Input OSC port: 6448
Output OSC message: /wek/outputs
Output host: localhost
Output port: 12000
Output type: All continuous
```

Inputs:

```text
pitch proximity, volume distance, movement speed, acceleration, confidence, noise
```

Outputs:

```text
corrected pitch, corrected volume, vibrato amount, timbre brightness
```

Saved demo project:

```text
wekinator_projects/thereminwekinator/theremin/theremin.wekproj
```

Fast bootstrap training, with Wekinator open and OSC GUI control enabled:

```bash
python tools/train_wekinator_demo.py --delete-existing
python tools/probe_wekinator_outputs.py
```

In Processing, press `X` until the HUD shows `expressive OSC: 6 inputs / 4 outputs`, then press `W` to use Wekinator output.

## Demo Flow

1. Direct theremin: show fixed movement-to-sound mapping.
2. Chromatic mode: show exact musical notes.
3. `Ode to Joy`: show melody-oriented control.
4. Melody game: hold target notes and increase score.
5. Trajectory rehab: follow an arc, vertical reach, or diagonal reach and show DTW score/repetitions.
6. Wekinator: compare direct control with learned expressive stabilization.

This explains the AI scope clearly:

```text
Processing extracts features.
Wekinator learns a supervised real-time mapping.
Processing turns predictions into sound and visual feedback.
TensorFlow is the offline/future path for evaluated models and deployable apps.
```

## Rehabilitation-Style Trajectory Demo

Press `P` until trajectory rehab is active.

Available trajectory exercises are configured in:

```text
config/exercises.json
```

Current examples:

- Guided reach arc
- Shoulder flexion reach
- Diagonal cross-body reach

Controls:

```text
Z: switch trajectory exercise
G: make DTW matching easier
F: make DTW matching stricter
R: reset the current attempt
L: log CSV data
```

The system measures:

```text
DTW score, best score, repetitions, detected gesture, expected gesture, smoothness, path length, direction changes
```

This supports a demo where a participant must perform a controlled movement to reach a target. It should be presented as an educational/wellness prototype, not as clinical assessment.

## Python Rehab App

The Python companion app is a standalone foundation for hand-tracking and movement scoring:

```text
apps/python_rehab/
```

Install:

```bash
python3 -m venv apps/python_rehab/.venv
source apps/python_rehab/.venv/bin/activate
pip install -r apps/python_rehab/requirements.txt
```

Run:

```bash
python apps/python_rehab/run_app.py
```

It loads the shared `trajectory_match` exercises from `config/exercises.json`, tracks the index finger with MediaPipe, classifies simple movement gestures, and scores the movement path with Dynamic Time Warping.

## TensorFlow Training

Record CSV data in Processing with `L`. Files are saved under:

```text
apps/processing_wekinator/processing_wekinator_theremin/data_logs/
```

Check and train:

```bash
python ml/train_csvs.py
```

The trainer uses required movement/sound columns and optional exercise columns such as:

```text
melody_step_speed, trajectory_score, trajectory_distance, trajectory_reps, trajectory_smoothness
```

Model outputs are generated locally under `ml/models/`, which is ignored by Git until a model is intentionally documented and released.

## macOS App Launcher

Create a local launcher app:

```bash
python tools/build_macos_launcher.py
```

Output:

```text
dist/Adaptive Expressive Theremin Launcher.app
```

For a full standalone Processing export, use Processing:

```text
File -> Export Application
```

## Development Notes

- Arduino support is intentionally not part of the current demo path.
- Generated logs, app exports, model outputs, virtual environments, and local prototypes are ignored.
- Wekinator project files under `wekinator_projects/` are part of the deliverable when intentionally saved.
- Keep internal planning notes outside the public deliverable.
