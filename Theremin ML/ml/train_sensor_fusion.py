#!/usr/bin/env python3
"""Train a starter TensorFlow regression model for sensor-fusion control.

Usage:
    python ml/train_sensor_fusion.py processing_wekinator_theremin/data_logs/session-*.csv
"""

from __future__ import annotations

import argparse
from pathlib import Path


FEATURE_COLUMNS = [
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
    missing = [column for column in FEATURE_COLUMNS + TARGET_COLUMNS if column not in data.columns]
    if missing:
        raise SystemExit(f"Dataset is missing required columns: {', '.join(missing)}")

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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", nargs="+", type=Path, help="Processing CSV log files")
    parser.add_argument("--epochs", type=int, default=80)
    parser.add_argument("--output", type=Path, default=Path("ml/models/sensor_fusion_model.keras"))
    args = parser.parse_args()

    np, pd = import_ml_dependencies()
    tf = import_tensorflow()
    data = load_dataset(args.csv, np, pd)
    shuffled = data.sample(frac=1.0, random_state=42).reset_index(drop=True)

    split_index = int(len(shuffled) * 0.8)
    train = shuffled.iloc[:split_index]
    test = shuffled.iloc[split_index:]

    x_train = train[FEATURE_COLUMNS].to_numpy(dtype=np.float32)
    y_train = train[TARGET_COLUMNS].to_numpy(dtype=np.float32)
    x_test = test[FEATURE_COLUMNS].to_numpy(dtype=np.float32)
    y_test = test[TARGET_COLUMNS].to_numpy(dtype=np.float32)

    normalizer = tf.keras.layers.Normalization()
    normalizer.adapt(x_train)

    model = build_model(tf, normalizer)
    model.fit(
        x_train,
        y_train,
        validation_split=0.2,
        epochs=args.epochs,
        batch_size=64,
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


if __name__ == "__main__":
    main()
