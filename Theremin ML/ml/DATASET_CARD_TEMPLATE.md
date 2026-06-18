# Dataset Card Template

Use this file to document CSV logs used for TensorFlow training.

## Dataset

```text
Name:
Date recorded:
Recorder:
Processing sketch version/commit:
Input mode:
Wekinator profile:
```

## Collection Protocol

```text
Number of CSV files:
Approximate duration:
Labels used:
Lighting/camera notes:
Wekinator mode/direct mode:
```

## Label Meaning

| Label | Meaning |
| --- | --- |
| free | unstructured movement |
| low | low pitch target |
| middle | middle pitch target |
| high | high pitch target |
| stable | stable hold |
| expressive | energetic expressive movement |
| noisy | intentionally unstable/noisy movement |

## Quality Checks

Run:

```bash
python ml/check_dataset.py apps/processing_wekinator/processing_wekinator_theremin/data_logs/session-*.csv
```

Record:

```text
Rows:
Labels:
Ready:
Warnings:
```

## Columns

Required model columns:

```text
input_pitch
input_volume
movement_speed
movement_acceleration
hand_confidence
sensor_noise
target_pitch
target_volume
target_vibrato
target_brightness
```

Optional exercise/scoring columns:

```text
melody_step_speed
trajectory_score
trajectory_distance
trajectory_reps
trajectory_tolerance
trajectory_smoothness
trajectory_path_length
trajectory_direction_changes
```

## Privacy / Safety

CSV logs should not include video frames. They should contain numeric features and labels only. Do not publish personal or health-sensitive notes without consent.
