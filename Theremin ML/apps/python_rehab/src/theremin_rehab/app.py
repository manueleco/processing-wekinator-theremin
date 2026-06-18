"""OpenCV demo app for trajectory-based rehab practice."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
from time import monotonic

from .dtw import Point, trajectory_features, trajectory_score
from .exercises import TrajectoryExercise, load_first_trajectory, load_trajectory_exercises
from .tracking import HandTracker, TrackingDependencyError


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Python rehab tracking demo.")
    parser.add_argument("--config", type=Path, help="Path to exercises.json.")
    parser.add_argument("--camera", type=int, default=0)
    parser.add_argument("--no-mirror", action="store_true")
    parser.add_argument("--window", default="Adaptive Expressive Theremin Rehab")
    return parser.parse_args()


def pixel(point: Point, width: int, height: int) -> tuple[int, int]:
    return int(point[0] * width), int(point[1] * height)


def draw_path(cv2, frame, points: list[Point], color: tuple[int, int, int], thickness: int) -> None:
    if len(points) < 2:
        return
    height, width = frame.shape[:2]
    for index in range(1, len(points)):
        cv2.line(frame, pixel(points[index - 1], width, height), pixel(points[index], width, height), color, thickness)


def draw_ui(
    cv2,
    frame,
    exercise: TrajectoryExercise,
    user_path: list[Point],
    score: float,
    best_score: float,
    repetitions: int,
    gesture: str,
    smoothness: float,
    exercise_index: int,
    exercise_count: int,
) -> None:
    height, width = frame.shape[:2]
    overlay = frame.copy()
    cv2.rectangle(overlay, (0, 0), (width, 110), (10, 14, 22), -1)
    cv2.addWeighted(overlay, 0.82, frame, 0.18, 0, frame)

    cv2.putText(frame, "Adaptive Expressive Theremin Rehab", (24, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.75, (245, 245, 245), 2)
    cv2.putText(frame, exercise.name, (24, 58), cv2.FONT_HERSHEY_SIMPLEX, 0.52, (210, 210, 210), 1)
    cv2.putText(
        frame,
        f"score {score:03.0f}  best {best_score:03.0f}  reps {repetitions}/{exercise.repetitions}",
        (width - 380, 44),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.62,
        (80, 220, 255),
        2,
    )
    cv2.putText(
        frame,
        f"gesture {gesture}  target {exercise.expected_gesture}  smooth {smoothness * 100:03.0f}  {exercise_index + 1}/{exercise_count}",
        (24, 92),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.5,
        (220, 220, 220),
        1,
    )

    draw_path(cv2, frame, exercise.path, (80, 190, 255), 5)
    draw_path(cv2, frame, user_path, (255, 205, 70), 3)

    for index, point in enumerate(exercise.path):
        radius = 8 if index else 11
        cv2.circle(frame, pixel(point, width, height), radius, (105, 230, 160) if index == 0 else (80, 190, 255), -1)

    if user_path:
        cv2.circle(frame, pixel(user_path[-1], width, height), 12, (255, 255, 255), -1)


def run_app(args: argparse.Namespace) -> int:
    try:
        import cv2  # type: ignore
    except ModuleNotFoundError as exc:
        raise TrackingDependencyError(
            "Install camera dependencies with: pip install -r apps/python_rehab/requirements.txt"
        ) from exc

    exercises = load_trajectory_exercises(args.config)
    if not exercises:
        exercises = [load_first_trajectory(args.config)]
    exercise_index = 0
    exercise = exercises[exercise_index]
    tracker = HandTracker(camera_index=args.camera, mirror=not args.no_mirror)
    path: deque[Point] = deque(maxlen=exercise.sample_count)
    score = 0.0
    best_score = 0.0
    repetitions = 0
    last_rep = 0.0
    gesture = "collecting"
    smoothness = 0.0

    try:
        while True:
            result = tracker.read()
            if result.frame is None:
                continue

            if result.point is not None and result.confidence > 0.2:
                path.append(result.point)

            if len(path) >= 6:
                score, _distance = trajectory_score(path, exercise.path, exercise.sample_count, exercise.tolerance)
                features = trajectory_features(path)
                gesture = str(features["gesture"])
                smoothness = float(features["smoothness"])
                best_score = max(best_score, score)

            now = monotonic()
            if len(path) > exercise.sample_count * 0.72 and score >= exercise.required_score and now - last_rep > 0.9:
                repetitions += 1
                last_rep = now
                path.clear()

            draw_ui(
                cv2,
                result.frame,
                exercise,
                list(path),
                score,
                best_score,
                repetitions,
                gesture,
                smoothness,
                exercise_index,
                len(exercises),
            )
            cv2.imshow(args.window, result.frame)
            key = cv2.waitKey(1) & 0xFF
            if key in (27, ord("q")):
                return 0
            if key == ord("r"):
                path.clear()
                score = 0.0
                best_score = 0.0
                repetitions = 0
                gesture = "collecting"
                smoothness = 0.0
            if key == ord("n"):
                exercise_index = (exercise_index + 1) % len(exercises)
                exercise = exercises[exercise_index]
                path = deque(maxlen=exercise.sample_count)
                score = 0.0
                best_score = 0.0
                repetitions = 0
                gesture = "collecting"
                smoothness = 0.0
    finally:
        tracker.close()
        cv2.destroyAllWindows()


def main() -> int:
    args = parse_args()
    return run_app(args)


if __name__ == "__main__":
    raise SystemExit(main())
