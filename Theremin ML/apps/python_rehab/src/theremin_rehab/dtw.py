"""Trajectory scoring with Dynamic Time Warping.

The functions in this module are dependency-free on purpose. They can be used
by the OpenCV demo, TensorFlow data preparation, or future web/app ports.
"""

from __future__ import annotations

from math import hypot
from typing import Iterable, Sequence

Point = tuple[float, float]


def clamp(value: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def normalize_point(point: Sequence[float]) -> Point:
    if len(point) < 2:
        raise ValueError("A point must contain at least x and y.")
    return clamp(float(point[0])), clamp(float(point[1]))


def path_length(points: Sequence[Point]) -> float:
    return sum(distance(points[index - 1], points[index]) for index in range(1, len(points)))


def distance(a: Point, b: Point) -> float:
    return hypot(a[0] - b[0], a[1] - b[1])


def resample_path(points: Iterable[Sequence[float]], sample_count: int = 48) -> list[Point]:
    source = [normalize_point(point) for point in points]
    if sample_count <= 0:
        raise ValueError("sample_count must be positive.")
    if not source:
        return []
    if len(source) == 1:
        return [source[0]] * sample_count

    cumulative = [0.0]
    for index in range(1, len(source)):
        cumulative.append(cumulative[-1] + distance(source[index - 1], source[index]))

    total = cumulative[-1]
    if total <= 1e-9:
        return [source[0]] * sample_count

    result: list[Point] = []
    segment = 1
    for index in range(sample_count):
        target = total * index / max(1, sample_count - 1)
        while segment < len(cumulative) - 1 and cumulative[segment] < target:
            segment += 1
        previous_distance = cumulative[segment - 1]
        segment_length = max(1e-9, cumulative[segment] - previous_distance)
        t = clamp((target - previous_distance) / segment_length)
        start = source[segment - 1]
        end = source[segment]
        result.append((start[0] + (end[0] - start[0]) * t, start[1] + (end[1] - start[1]) * t))
    return result


def dtw_distance(path_a: Iterable[Sequence[float]], path_b: Iterable[Sequence[float]]) -> float:
    a = [normalize_point(point) for point in path_a]
    b = [normalize_point(point) for point in path_b]
    if not a or not b:
        return 1.0

    rows = len(a) + 1
    cols = len(b) + 1
    matrix = [[float("inf")] * cols for _ in range(rows)]
    matrix[0][0] = 0.0

    for row in range(1, rows):
        for col in range(1, cols):
            cost = distance(a[row - 1], b[col - 1])
            matrix[row][col] = cost + min(
                matrix[row - 1][col],
                matrix[row][col - 1],
                matrix[row - 1][col - 1],
            )

    return matrix[-1][-1] / max(1, len(a) + len(b))


def trajectory_score(
    user_path: Iterable[Sequence[float]],
    target_path: Iterable[Sequence[float]],
    sample_count: int = 48,
    tolerance: float = 0.42,
) -> tuple[float, float]:
    """Return `(score, distance)` for a user path against a target path."""

    user = resample_path(user_path, sample_count)
    target = resample_path(target_path, sample_count)
    if not user or not target:
        return 0.0, 1.0
    error = dtw_distance(user, target)
    score = clamp(1.0 - error / tolerance) * 100.0
    return score, error


def angle_delta(a: float, b: float) -> float:
    from math import pi

    diff = a - b
    while diff > pi:
        diff -= 2 * pi
    while diff < -pi:
        diff += 2 * pi
    return diff


def trajectory_features(points: Iterable[Sequence[float]]) -> dict[str, float | int | str]:
    from math import atan2

    path = [normalize_point(point) for point in points]
    if len(path) < 3:
        return {
            "gesture": "collecting",
            "smoothness": 0.0,
            "path_length": 0.0,
            "directness": 0.0,
            "direction_changes": 0,
        }

    start = path[0]
    end = path[-1]
    min_x = max_x = start[0]
    min_y = max_y = start[1]
    total = 0.0
    changes = 0
    previous_angle: float | None = None

    for previous, current in zip(path, path[1:]):
        dx = current[0] - previous[0]
        dy = current[1] - previous[1]
        segment = hypot(dx, dy)
        total += segment
        min_x = min(min_x, current[0])
        max_x = max(max_x, current[0])
        min_y = min(min_y, current[1])
        max_y = max(max_y, current[1])
        if segment > 0.015:
            angle = atan2(dy, dx)
            if previous_angle is not None and abs(angle_delta(angle, previous_angle)) > 0.95:
                changes += 1
            previous_angle = angle

    dx = end[0] - start[0]
    dy = end[1] - start[1]
    direct = hypot(dx, dy)
    width = max_x - min_x
    height = max_y - min_y
    directness = clamp(direct / total) if total > 1e-9 else 0.0
    smoothness = clamp(directness * 0.72 + (1.0 - min(1.0, changes / 5.0)) * 0.28)

    return {
        "gesture": classify_gesture(dx, dy, width, height, total, direct, changes),
        "smoothness": smoothness,
        "path_length": total,
        "directness": directness,
        "direction_changes": changes,
    }


def classify_gesture(
    dx: float,
    dy: float,
    width: float,
    height: float,
    total: float,
    direct: float,
    changes: int,
) -> str:
    if total < 0.08:
        return "hold"
    if changes >= 5 and total > 0.28:
        return "unstable"
    if total > 0.45 and direct < 0.22 and width > 0.16 and height > 0.12:
        return "loop"
    if abs(dx) > 0.18 and abs(dy) > 0.14:
        if dx > 0 and dy < 0:
            return "diagonal_up_right"
        if dx < 0 and dy < 0:
            return "diagonal_up_left"
        if dx > 0:
            return "diagonal_down_right"
        return "diagonal_down_left"
    if abs(dx) > abs(dy) * 1.35 and abs(dx) > 0.18:
        return "reach_right" if dx > 0 else "reach_left"
    if abs(dy) > abs(dx) * 1.35 and abs(dy) > 0.16:
        return "reach_up" if dy < 0 else "reach_down"
    if width > 0.25 and height > 0.10:
        return "arc"
    return "controlled_reach"


def best_trajectory_match(
    user_path: Iterable[Sequence[float]],
    candidates: Sequence[tuple[str, Iterable[Sequence[float]], float]],
    sample_count: int = 48,
) -> tuple[str, float, float]:
    """Return `(candidate_id, score, distance)` for the best target path."""

    best_id = ""
    best_score = -1.0
    best_distance = 1.0
    cached_user = list(user_path)
    for candidate_id, target_path, tolerance in candidates:
        score, error = trajectory_score(cached_user, target_path, sample_count, tolerance)
        if score > best_score:
            best_id = candidate_id
            best_score = score
            best_distance = error
    return best_id, max(0.0, best_score), best_distance
