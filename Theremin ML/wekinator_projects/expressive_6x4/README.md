# Expressive 6x4 Wekinator Project

This folder should hold the first trained expressive Wekinator project.

The included scaffold lives in:

```text
AdaptiveExpressiveTheremin6x4/AdaptiveExpressiveTheremin6x4.wekproj
```

The saved bootstrap-trained project now lives in:

```text
../thereminwekinator/theremin/theremin.wekproj
```

## Training Setup

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

## Intended Mapping

```text
pitch proximity, volume distance, movement speed, acceleration, confidence, noise
-> stabilized pitch, stabilized volume, vibrato, timbre brightness
```

## Fast Bootstrap Option

Open the scaffold in Wekinator, enable `Actions -> Enable OSC control of GUI`, then run:

```bash
python tools/train_wekinator_demo.py --delete-existing
```

This records synthetic examples and starts the trained model. It is useful for a classroom demo, but real user examples should still be recorded for the final explanation.

## Training Notes

Fill this in after training:

```text
Date:
Input mode:
Number of examples:
Labels/gestures:
What worked:
What did not work:
```
