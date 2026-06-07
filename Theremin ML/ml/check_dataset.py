#!/usr/bin/env python3
"""Check Processing CSV logs before training the TensorFlow model.

This script intentionally uses only the Python standard library so it can run
before the TensorFlow environment is installed.
"""

from __future__ import annotations

import argparse
import csv
from collections import Counter
from dataclasses import dataclass
from math import sqrt
from pathlib import Path
from typing import Optional


REQUIRED_COLUMNS = [
    "input_pitch",
    "input_volume",
    "movement_speed",
    "movement_acceleration",
    "hand_confidence",
    "sensor_noise",
    "target_pitch",
    "target_volume",
    "target_vibrato",
    "target_brightness",
]

VARIATION_COLUMNS = [
    "input_pitch",
    "input_volume",
    "movement_speed",
    "sensor_noise",
    "target_pitch",
    "target_volume",
]


@dataclass
class NumericSummary:
    count: int = 0
    total: float = 0.0
    total_sq: float = 0.0
    minimum: Optional[float] = None
    maximum: Optional[float] = None

    def add(self, value: float) -> None:
        self.count += 1
        self.total += value
        self.total_sq += value * value
        self.minimum = value if self.minimum is None else min(self.minimum, value)
        self.maximum = value if self.maximum is None else max(self.maximum, value)

    @property
    def mean(self) -> float:
        return self.total / self.count if self.count else 0.0

    @property
    def stdev(self) -> float:
        if self.count < 2:
            return 0.0
        variance = max(0.0, self.total_sq / self.count - self.mean * self.mean)
        return sqrt(variance)

    @property
    def span(self) -> float:
        if self.minimum is None or self.maximum is None:
            return 0.0
        return self.maximum - self.minimum


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", nargs="+", type=Path, help="Processing CSV log files")
    parser.add_argument("--min-files", type=int, default=3)
    parser.add_argument("--min-rows", type=int, default=3000)
    parser.add_argument("--min-labels", type=int, default=4)
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit with a non-zero status if the dataset is not ready.",
    )
    return parser.parse_args()


def read_logs(paths: list[Path]):
    missing_files = [path for path in paths if not path.exists()]
    if missing_files:
        raise SystemExit("Missing CSV files: " + ", ".join(str(path) for path in missing_files))

    labels: Counter[str] = Counter()
    input_modes: Counter[str] = Counter()
    profiles: Counter[str] = Counter()
    summaries = {column: NumericSummary() for column in VARIATION_COLUMNS}
    missing_columns: dict[Path, list[str]] = {}
    row_count = 0

    for path in paths:
        with path.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            if reader.fieldnames is None:
                missing_columns[path] = REQUIRED_COLUMNS
                continue

            missing = [column for column in REQUIRED_COLUMNS if column not in reader.fieldnames]
            if missing:
                missing_columns[path] = missing
                continue

            for row in reader:
                row_count += 1
                labels[row.get("label", "") or "unlabeled"] += 1
                input_modes[row.get("input_mode", "") or "unknown"] += 1
                profiles[row.get("wekinator_profile", "") or "unknown"] += 1

                for column in VARIATION_COLUMNS:
                    try:
                        summaries[column].add(float(row[column]))
                    except (TypeError, ValueError):
                        pass

    return row_count, labels, input_modes, profiles, summaries, missing_columns


def readiness_messages(
    file_count: int,
    row_count: int,
    label_count: int,
    summaries: dict[str, NumericSummary],
    args: argparse.Namespace,
) -> list[str]:
    messages = []
    if file_count < args.min_files:
        messages.append(f"record at least {args.min_files} CSV files")
    if row_count < args.min_rows:
        messages.append(f"record at least {args.min_rows} rows")
    if label_count < args.min_labels:
        messages.append(f"use at least {args.min_labels} labels")

    weak_columns = [
        column
        for column, summary in summaries.items()
        if summary.count > 0 and summary.span < 0.12
    ]
    if weak_columns:
        messages.append("add more variation for: " + ", ".join(weak_columns))

    return messages


def main() -> None:
    args = parse_args()
    paths = sorted(args.csv)
    row_count, labels, input_modes, profiles, summaries, missing_columns = read_logs(paths)

    print(f"files={len(paths)}")
    print(f"rows={row_count}")
    print("labels=" + ", ".join(f"{key}:{value}" for key, value in labels.most_common()))
    print("input_modes=" + ", ".join(f"{key}:{value}" for key, value in input_modes.most_common()))
    print("profiles=" + ", ".join(f"{key}:{value}" for key, value in profiles.most_common()))

    for column in VARIATION_COLUMNS:
        summary = summaries[column]
        print(
            f"{column}: count={summary.count} "
            f"min={summary.minimum if summary.minimum is not None else 'n/a'} "
            f"max={summary.maximum if summary.maximum is not None else 'n/a'} "
            f"span={summary.span:.4f} stdev={summary.stdev:.4f}"
        )

    if missing_columns:
        print("missing_columns:")
        for path, columns in missing_columns.items():
            print(f"  {path}: {', '.join(columns)}")

    messages = readiness_messages(len(paths), row_count, len(labels), summaries, args)
    if messages:
        print("ready=false")
        for message in messages:
            print(f"next={message}")
        if args.strict:
            raise SystemExit(1)
    else:
        print("ready=true")
        print("next=train with ml/train_sensor_fusion.py")


if __name__ == "__main__":
    main()
