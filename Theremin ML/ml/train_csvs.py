#!/usr/bin/env python3
"""Validate Processing CSV logs and train the TensorFlow model.

Run from the `Theremin ML` folder:

    python ml/train_csvs.py

The script uses the existing dataset checker first. Training only starts when
the CSV dataset is ready, unless `--allow-not-ready` is passed explicitly.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


DEFAULT_CSV_GLOB = "apps/processing_wekinator/processing_wekinator_theremin/data_logs/session-*.csv"
DEFAULT_OUTPUT = Path("ml/models/sensor_fusion_model.keras")


def project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "csv",
        nargs="*",
        type=Path,
        help="CSV files to train from. Defaults to Processing data_logs/session-*.csv.",
    )
    parser.add_argument("--epochs", type=int, default=80)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--report", type=Path)
    parser.add_argument(
        "--allow-not-ready",
        action="store_true",
        help="Train even if the dataset checker reports that more data is recommended.",
    )
    parser.add_argument(
        "--skip-check",
        action="store_true",
        help="Skip dataset readiness checks and run training directly.",
    )
    parser.add_argument(
        "--python",
        type=Path,
        help="Python executable to use for TensorFlow training.",
    )
    return parser.parse_args()


def default_csv_paths(root: Path) -> list[Path]:
    return sorted(root.glob(DEFAULT_CSV_GLOB))


def normalize_paths(paths: list[Path], root: Path) -> list[Path]:
    normalized = []
    for path in paths:
        normalized.append(path if path.is_absolute() else root / path)
    return normalized


def display_path(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def run_command(command: list[str], root: Path) -> int:
    print("+ " + " ".join(command), flush=True)
    return subprocess.call(command, cwd=root)


def training_python(args: argparse.Namespace, root: Path) -> Path:
    if args.python is not None:
        return args.python

    venv_python = root / ".venv" / "bin" / "python"
    if venv_python.exists():
        return venv_python

    return Path(sys.executable)


def print_setup_hint() -> None:
    print()
    print("If training fails because TensorFlow is missing, install dependencies with:", flush=True)
    print('  cd "Theremin ML"', flush=True)
    print("  python3 -m venv .venv", flush=True)
    print("  source .venv/bin/activate", flush=True)
    print("  pip install -r ml/requirements.txt", flush=True)


def main() -> None:
    args = parse_args()
    root = project_root()
    csv_paths = normalize_paths(args.csv, root) if args.csv else default_csv_paths(root)

    if not csv_paths:
        raise SystemExit(
            "No CSV files found. Record data in Processing with L first, then rerun this script."
        )

    missing = [path for path in csv_paths if not path.exists()]
    if missing:
        missing_text = ", ".join(display_path(path, root) for path in missing)
        raise SystemExit(f"CSV files not found: {missing_text}")

    print("CSV files:", flush=True)
    for path in csv_paths:
        print("  " + display_path(path, root), flush=True)

    csv_args = [display_path(path, root) for path in csv_paths]

    if not args.skip_check:
        check_command = [sys.executable, "ml/check_dataset.py", *csv_args]
        if not args.allow_not_ready:
            check_command.append("--strict")

        check_status = run_command(check_command, root)
        if check_status != 0:
            print()
            print("Dataset is not ready for a useful first model.", flush=True)
            print("Record more labeled CSV sessions, or pass --allow-not-ready for a smoke test.", flush=True)
            raise SystemExit(check_status)

    trainer_python = training_python(args, root)
    train_command = [
        str(trainer_python),
        "ml/train_sensor_fusion.py",
        *csv_args,
        "--epochs",
        str(args.epochs),
        "--batch-size",
        str(args.batch_size),
        "--seed",
        str(args.seed),
        "--output",
        str(args.output),
    ]
    if args.report is not None:
        train_command.extend(["--report", str(args.report)])

    print_setup_hint()
    raise SystemExit(run_command(train_command, root))


if __name__ == "__main__":
    main()
