# Model Card Template

Use this file when a trained TensorFlow model is ready to be included in the deliverable.

## Model

```text
Name:
Version:
Training date:
Training script:
Model file:
Training report:
```

## Intended Use

The model predicts stable expressive musical controls from Processing sensor features.

```text
input_pitch, input_volume, movement_speed, movement_acceleration, confidence, noise
-> target_pitch, target_volume, target_vibrato, target_brightness
```

## Not Intended For

- medical diagnosis
- clinical decision-making
- unsupervised therapy without a professional context
- safety-critical control

## Dataset Summary

```text
CSV files:
Rows:
Labels:
Input modes:
Wekinator profile:
```

## Evaluation

```text
Test loss:
Test MAE:
Observed strengths:
Observed failures:
```

## Limitations

- depends on lighting, camera angle, and user movement range
- may not generalize to another user without new data
- should be recalibrated or retrained after changing sensors or input mode

## Ethical / Accessibility Notes

Present this as an educational and wellness prototype. Any rehabilitation framing should be careful, non-clinical, and transparent about limitations.
