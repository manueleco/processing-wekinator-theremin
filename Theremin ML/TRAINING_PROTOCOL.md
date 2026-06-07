# Training Protocol

This document defines how to train Wekinator and how to collect data for the first TensorFlow model.

## 1. Wekinator Expressive Training

Use this profile first because it does not require Arduino hardware.

```text
Inputs: 6
Outputs: 4
Output type: All continuous
Input OSC message: /wek/inputs
Input OSC port: 6448
Output OSC message: /wek/outputs
Output host: localhost
Output port: 12000
```

In Processing, press `X` until:

```text
expressive OSC: 6 inputs / 4 outputs
```

## 2. Inputs

| Input | Meaning |
| ---: | --- |
| 1 | pitch antenna proximity |
| 2 | volume loop distance |
| 3 | movement speed |
| 4 | movement acceleration |
| 5 | tracking confidence |
| 6 | estimated sensor noise / instability |

## 3. Outputs

| Output | Meaning |
| ---: | --- |
| 1 | corrected pitch or melody position |
| 2 | corrected volume |
| 3 | vibrato amount |
| 4 | timbre brightness |

## 4. Training Examples

Record each example for about 1-2 seconds.

| Example | Pitch | Volume | Vibrato | Brightness |
| --- | ---: | ---: | ---: | ---: |
| low stable note | 0.15 | 0.55 | 0.00 | 0.10 |
| middle stable note | 0.50 | 0.60 | 0.00 | 0.18 |
| high stable note | 0.85 | 0.60 | 0.00 | 0.25 |
| silent/near volume loop | 0.50 | 0.00 | 0.00 | 0.00 |
| slow expressive movement | 0.45 | 0.60 | 0.18 | 0.30 |
| fast expressive movement | 0.65 | 0.80 | 0.65 | 0.85 |
| shaky/noisy movement, stabilized | 0.50 | 0.35 | 0.15 | 0.15 |
| intentional circular motion | 0.70 | 0.75 | 0.80 | 0.70 |

## 5. Training Order

1. Start Processing.
2. Press `M` to unmute.
3. Press `X` until expressive profile.
4. Create Wekinator project with `6 inputs / 4 outputs`.
5. Press `Start Recording` for each example.
6. Set the Wekinator output sliders to the target values.
7. Record 1-2 seconds per example.
8. Press `Train`.
9. Press `Run`.
10. In Processing, press `W` to enter Wekinator mode.

## 6. Evaluation

Compare:

```text
Direct Preview vs Wekinator
```

Look for:

- more stable pitch
- less unpleasant jitter
- more intentional vibrato
- brighter timbre for energetic movement
- lower volume for silence/near-loop gestures

## 7. Saving the Wekinator Project

Save the trained Wekinator project locally after training.

Recommended local path:

```text
Theremin ML/wekinator_projects/expressive_6x4/
```

Generated Wekinator files should not be committed automatically unless they are intentionally included as part of the final deliverable.

If committed, document:

- date trained
- input mode used
- number of examples
- intended behavior
- limitations

A notes template is available in:

```text
wekinator_projects/expressive_6x4/README.md
```

## 8. CSV Data Collection for TensorFlow

In Processing, press `L` to start/stop logging.

Record at least three sessions:

| Session | Label keys | Purpose |
| --- | --- | --- |
| stable positions | `1`, `2`, `3`, `4` | low/middle/high/stable examples |
| expressive movement | `5` | vibrato and brightness examples |
| noisy movement | `6` | noisy input to stabilize |

Use these labels:

```text
0 free
1 low
2 middle
3 high
4 stable
5 expressive
6 noisy
7 left
8 right
9 hold
```

## 9. Minimum Dataset

For a first real TensorFlow model, collect at least:

```text
3 CSV files
3000+ rows total
at least 4 labels
clear variation in pitch, volume, speed, and noise
```

The current local CSV logs are useful as a smoke test, but they are not a complete final dataset because they are mostly `mouse/free`.

## 10. TensorFlow Training

After collecting data, use the combined validation/training script:

```bash
cd "Theremin ML"
python ml/train_csvs.py
```

This runs `ml/check_dataset.py` first. If the dataset is ready, it then runs `ml/train_sensor_fusion.py`.

On macOS, you can also double-click:

```text
scripts/train_csvs.command
```

Manual version:

```bash
cd "Theremin ML"
python ml/check_dataset.py processing_wekinator_theremin/data_logs/session-*.csv
python ml/train_sensor_fusion.py processing_wekinator_theremin/data_logs/session-*.csv
```

Expected output:

```text
ml/models/sensor_fusion_model.keras
ml/models/sensor_fusion_model.features.txt
ml/models/sensor_fusion_model.report.json
```

Use these templates to document the trained artifact:

```text
ml/MODEL_CARD_TEMPLATE.md
ml/DATASET_CARD_TEMPLATE.md
```

Current environment note:

```text
TensorFlow is not installed in the current default Python environment.
```

Install dependencies before training:

```bash
cd "Theremin ML"
python3 -m venv .venv
source .venv/bin/activate
pip install -r ml/requirements.txt
```
