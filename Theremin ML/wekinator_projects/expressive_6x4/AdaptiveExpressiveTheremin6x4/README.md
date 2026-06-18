# Adaptive Expressive Theremin 6x4

This is a ready-to-open Wekinator project scaffold for the expressive profile.

## Configuration

```text
Inputs: 6
Outputs: 4
Input OSC: /wek/inputs
Input port: 6448
Output OSC: /wek/outputs
Output host: localhost
Output port: 12000
Output type: All continuous
```

## Inputs

```text
1. pitch_proximity
2. volume_distance
3. movement_speed
4. movement_acceleration
5. tracking_confidence
6. sensor_noise
```

## Outputs

```text
1. stabilized_pitch
2. stabilized_volume
3. vibrato_amount
4. timbre_brightness
```

## Bootstrap Training

The script below can send a small synthetic training set to the currently open Wekinator project:

```bash
python tools/train_wekinator_demo.py --delete-existing
python tools/probe_wekinator_outputs.py
```

This creates a quick demo model, but it should be described as a bootstrap model, not as the final human-trained model. For the final presentation, test the model in Processing and add a few real examples if time allows.

Before running the script, Wekinator must be listening on port `6448` and must be on the main training screen. If the setup screen says `Not listening`, click `Start listening`, then `Next`.

## Training Notes

```text
Date:
Input mode:
Number of examples:
Labels/gestures:
What worked:
What did not work:
```
