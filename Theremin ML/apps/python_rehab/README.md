# Python Rehab App

This folder contains a Python companion app for the Adaptive Expressive Theremin project.

It focuses on trajectory-based practice:

```text
camera hand tracking -> normalized path -> gesture features -> DTW score -> repetitions/progress
```

The goal is to provide a cleaner path toward a future product-style rehab or education app while keeping the Processing + Wekinator sketch as the main course demo.

## Install

From the `Theremin ML` folder:

```bash
python3 -m venv apps/python_rehab/.venv
source apps/python_rehab/.venv/bin/activate
pip install -r apps/python_rehab/requirements.txt
```

## Run

```bash
python apps/python_rehab/run_app.py
```

Use:

```text
q or Esc: quit
r: reset score and repetitions
n: next trajectory exercise
```

The app loads `trajectory_match` exercises from:

```text
config/exercises.json
```

## Test

The core DTW/exercise logic has no external dependency:

```bash
python3 -m unittest discover -s apps/python_rehab/tests
```

## Scope

This is a prototype companion app, not a medical device. It can support demo discussions about movement quality, motivation, accessibility, and future rehabilitation-style exercises, but it does not diagnose, prescribe, or replace professional therapy.
