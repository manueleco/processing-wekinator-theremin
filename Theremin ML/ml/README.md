# TensorFlow ML Base

This folder contains a starter pipeline for training a model from data recorded by the Processing sketch.

## Goal

The TensorFlow model is intended as a future replacement or complement for Wekinator.

Wekinator is still the best tool for live classroom experimentation. TensorFlow is useful when we want to:

- train from saved datasets
- compare model performance
- reproduce experiments
- evaluate noise reduction
- eventually export a smaller model to TensorFlow Lite or TinyML

## Collecting Data

Run the Processing sketch and press:

```text
L
```

to start/stop CSV logging.

CSV files are written under:

```text
processing_wekinator_theremin/data_logs/
```

Use number keys to label the current recording context:

| Key | Label |
| --- | --- |
| `0` | free |
| `1` | low |
| `2` | middle |
| `3` | high |
| `4` | stable |
| `5` | expressive |
| `6` | noisy |
| `7` | left |
| `8` | right |
| `9` | hold |

## Install

From the `Theremin ML` folder:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r ml/requirements.txt
```

## Train

After collecting CSV files, first check whether the dataset is ready:

```bash
python ml/check_dataset.py processing_wekinator_theremin/data_logs/session-*.csv
```

The first real model should have:

```text
3+ CSV files
3000+ rows
4+ labels
clear variation in pitch, volume, movement speed, and noise
```

If the checker says `ready=true`, train:

```bash
python ml/train_sensor_fusion.py processing_wekinator_theremin/data_logs/session-*.csv
```

The script trains a regression model with these targets:

```text
target_pitch
target_volume
target_vibrato
target_brightness
```

Outputs are saved under:

```text
ml/models/
```

If TensorFlow is not installed, the training script will print the virtual-environment install command instead of failing with an unclear import error.

## What the Model Learns

Inputs:

```text
input_pitch
input_volume
movement_speed
movement_acceleration
hand_confidence
sensor_noise
arduino_pitch_control
arduino_volume_control
arduino_speed
arduino_confidence
```

Outputs:

```text
target_pitch
target_volume
target_vibrato
target_brightness
```

This is a supervised regression task:

```text
noisy multimodal sensor features -> stable expressive musical controls
```

## Future TensorFlow.js Path

For a web app, this trained model could later be converted to TensorFlow.js:

```bash
tensorflowjs_converter --input_format=keras ml/models/sensor_fusion_model.keras web/model
```

That would allow a React/WebAudio version to run a similar model in the browser.
