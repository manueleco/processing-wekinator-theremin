#!/usr/bin/env python3
"""Train a starter TensorFlow regression model for sensor-fusion control.

Usage:
    python ml/train_sensor_fusion.py apps/processing_wekinator/processing_wekinator_theremin/data_logs/session-*.csv
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


BASE_FEATURE_COLUMNS = [
    "input_pitch",
    "input_volume",
    "movement_speed",
    "movement_acceleration",
    "hand_confidence",
    "sensor_noise",
    "arduino_pitch_control",
    "arduino_volume_control",
    "arduino_speed",
    "arduino_confidence",
]

OPTIONAL_FEATURE_COLUMNS = [
    "melody_step_speed",
    "trajectory_score",
    "trajectory_distance",
    "trajectory_reps",
    "trajectory_tolerance",
    "trajectory_smoothness",
    "trajectory_path_length",
    "trajectory_direction_changes",
]

FEATURE_COLUMNS = BASE_FEATURE_COLUMNS + OPTIONAL_FEATURE_COLUMNS

TARGET_COLUMNS = [
    "target_pitch",
    "target_volume",
    "target_vibrato",
    "target_brightness",
]


def import_ml_dependencies():
    try:
        import numpy as np  # type: ignore
        import pandas as pd  # type: ignore
    except ModuleNotFoundError as exc:
        raise SystemExit(
            "Python ML dependencies are not installed in this environment.\n"
            'Run: cd "Theremin ML" && python3 -m venv .venv && '
            "source .venv/bin/activate && pip install -r ml/requirements.txt"
        ) from exc
    return np, pd


def load_dataset(paths: list[Path], np, pd):
    frames = []
    for path in paths:
        frames.append(pd.read_csv(path))

    if not frames:
        raise SystemExit("No CSV files were provided.")

    data = pd.concat(frames, ignore_index=True)
    missing = [column for column in BASE_FEATURE_COLUMNS + TARGET_COLUMNS if column not in data.columns]
    if missing:
        raise SystemExit(f"Dataset is missing required columns: {', '.join(missing)}")

    for column in OPTIONAL_FEATURE_COLUMNS:
        if column not in data.columns:
            data[column] = 0.0

    data = data.replace([np.inf, -np.inf], np.nan)
    data = data.dropna(subset=FEATURE_COLUMNS + TARGET_COLUMNS)
    if len(data) < 50:
        raise SystemExit("Need at least 50 clean rows to train a useful starter model.")

    return data


def import_tensorflow():
    try:
        import tensorflow as tf  # type: ignore
    except ModuleNotFoundError as exc:
        raise SystemExit(
            "TensorFlow is not installed in this Python environment.\n"
            'Run: cd "Theremin ML" && python3 -m venv .venv && '
            "source .venv/bin/activate && pip install -r ml/requirements.txt"
        ) from exc
    return tf


def build_model(tf, normalizer):
    model = tf.keras.Sequential(
        [
            tf.keras.Input(shape=(len(FEATURE_COLUMNS),)),
            normalizer,
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dense(32, activation="relu"),
            tf.keras.layers.Dense(len(TARGET_COLUMNS), activation="sigmoid"),
        ]
    )
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="mse",
        metrics=["mae"],
    )
    return model


def count_column_values(data, column: str) -> dict[str, int]:
    if column not in data.columns:
        return {}
    counts = data[column].fillna("unknown").astype(str).value_counts().to_dict()
    return {key: int(value) for key, value in counts.items()}


def write_training_report(
    report_path: Path,
    args: argparse.Namespace,
    csv_paths: list[Path],
    data,
    train_rows: int,
    test_rows: int,
    loss: float,
    mae: float,
    history,
) -> None:
    report = {
        "schema_version": 1,
        "trained_at_utc": datetime.now(timezone.utc).isoformat(),
        "model_type": "keras_regression",
        "objective": "sensor_features_to_stable_expressive_controls",
        "input_csv_files": [str(path) for path in csv_paths],
        "output_model": str(args.output),
        "rows_clean": int(len(data)),
        "rows_train": int(train_rows),
        "rows_test": int(test_rows),
        "seed": int(args.seed),
        "epochs": int(args.epochs),
        "batch_size": int(args.batch_size),
        "test_split": float(args.test_split),
        "validation_split": float(args.validation_split),
        "feature_columns": FEATURE_COLUMNS,
        "target_columns": TARGET_COLUMNS,
        "label_counts": count_column_values(data, "label"),
        "input_mode_counts": count_column_values(data, "input_mode"),
        "wekinator_profile_counts": count_column_values(data, "wekinator_profile"),
        "metrics": {
            "test_loss_mse": float(loss),
            "test_mae": float(mae),
        },
        "last_epoch": {
            key: float(values[-1])
            for key, values in history.history.items()
            if values
        },
        "known_limitations": [
            "Prototype model for educational use, not a medical device.",
            "Quality depends on labeled CSV coverage and sensor consistency.",
            "Model should be re-trained when camera setup, lighting, or user movement range changes.",
        ],
    }

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", nargs="+", type=Path, help="Processing CSV log files")
    parser.add_argument("--epochs", type=int, default=80)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--test-split", type=float, default=0.2)
    parser.add_argument("--validation-split", type=float, default=0.2)
    parser.add_argument("--output", type=Path, default=Path("ml/models/sensor_fusion_model.keras"))
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    if not 0 < args.test_split < 1:
        raise SystemExit("--test-split must be between 0 and 1.")
    if not 0 <= args.validation_split < 1:
        raise SystemExit("--validation-split must be between 0 and 1.")

    np, pd = import_ml_dependencies()
    tf = import_tensorflow()
    tf.keras.utils.set_random_seed(args.seed)

    data = load_dataset(args.csv, np, pd)
    shuffled = data.sample(frac=1.0, random_state=args.seed).reset_index(drop=True)

    split_index = int(len(shuffled) * (1.0 - args.test_split))
    split_index = max(1, min(split_index, len(shuffled) - 1))
    train = shuffled.iloc[:split_index]
    test = shuffled.iloc[split_index:]

    x_train = train[FEATURE_COLUMNS].to_numpy(dtype=np.float32)
    y_train = train[TARGET_COLUMNS].to_numpy(dtype=np.float32)
    x_test = test[FEATURE_COLUMNS].to_numpy(dtype=np.float32)
    y_test = test[TARGET_COLUMNS].to_numpy(dtype=np.float32)

    normalizer = tf.keras.layers.Normalization()
    normalizer.adapt(x_train)

    model = build_model(tf, normalizer)
    history = model.fit(
        x_train,
        y_train,
        validation_split=args.validation_split,
        epochs=args.epochs,
        batch_size=args.batch_size,
        verbose=2,
    )

    loss, mae = model.evaluate(x_test, y_test, verbose=0)
    print(f"test_loss={loss:.5f}")
    print(f"test_mae={mae:.5f}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    model.save(args.output)
    print(f"saved_model={args.output}")

    metadata_path = args.output.with_suffix(".features.txt")
    metadata_path.write_text(
        "features:\n"
        + "\n".join(FEATURE_COLUMNS)
        + "\n\ntargets:\n"
        + "\n".join(TARGET_COLUMNS)
        + "\n",
        encoding="utf-8",
    )
    print(f"metadata={metadata_path}")

    report_path = args.report if args.report is not None else args.output.with_suffix(".report.json")
    write_training_report(
        report_path=report_path,
        args=args,
        csv_paths=args.csv,
        data=data,
        train_rows=len(train),
        test_rows=len(test),
        loss=loss,
        mae=mae,
        history=history,
    )
    print(f"report={report_path}")


if __name__ == "__main__":
    main()
