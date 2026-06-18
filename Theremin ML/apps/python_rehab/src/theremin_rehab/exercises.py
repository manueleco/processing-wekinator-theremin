"""Exercise configuration shared by the Python rehab app."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .dtw import Point, normalize_point


@dataclass(frozen=True)
class TrajectoryExercise:
    id: str
    name: str
    goal: str
    path: list[Point]
    expected_gesture: str = "controlled_reach"
    tolerance: float = 0.42
    sample_count: int = 48
    required_score: float = 72.0
    repetitions: int = 3


def project_root_from_file() -> Path:
    return Path(__file__).resolve().parents[4]


def default_config_path() -> Path:
    return project_root_from_file() / "config" / "exercises.json"


def _as_trajectory(raw: dict[str, Any]) -> TrajectoryExercise | None:
    if raw.get("type") != "trajectory_match":
        return None
    raw_path = raw.get("path")
    if not isinstance(raw_path, list) or len(raw_path) < 2:
        return None

    points: list[Point] = []
    for item in raw_path:
        if not isinstance(item, dict):
            continue
        points.append(normalize_point((item.get("x", 0.5), item.get("y", 0.5))))

    if len(points) < 2:
        return None

    return TrajectoryExercise(
        id=str(raw.get("id", "trajectory")),
        name=str(raw.get("name", "Trajectory Match")),
        goal=str(raw.get("goal", "Follow the target trajectory.")),
        path=points,
        expected_gesture=str(raw.get("expectedGesture", "controlled_reach")),
        tolerance=float(raw.get("tolerance", 0.42)),
        sample_count=int(raw.get("sampleCount", 48)),
        required_score=float(raw.get("requiredScore", 72.0)),
        repetitions=int(raw.get("repetitions", 3)),
    )


def load_trajectory_exercises(path: Path | None = None) -> list[TrajectoryExercise]:
    config_path = path or default_config_path()
    with config_path.open(encoding="utf-8") as handle:
        data = json.load(handle)

    exercises = []
    for raw in data.get("exercises", []):
        if not isinstance(raw, dict):
            continue
        exercise = _as_trajectory(raw)
        if exercise is not None:
            exercises.append(exercise)
    return exercises


def load_first_trajectory(path: Path | None = None) -> TrajectoryExercise:
    exercises = load_trajectory_exercises(path)
    if exercises:
        return exercises[0]
    return TrajectoryExercise(
        id="fallback_arc",
        name="Guided Reach Arc",
        goal="Follow the arc with a smooth controlled movement.",
        path=[
            (0.23, 0.58),
            (0.36, 0.46),
            (0.50, 0.40),
            (0.64, 0.46),
            (0.78, 0.58),
        ],
        expected_gesture="arc",
    )
