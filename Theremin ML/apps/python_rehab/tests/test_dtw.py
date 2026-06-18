from __future__ import annotations

import sys
import unittest
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(APP_ROOT / "src"))

from theremin_rehab.dtw import best_trajectory_match, resample_path, trajectory_features, trajectory_score
from theremin_rehab.exercises import load_first_trajectory, load_trajectory_exercises


class DtwTests(unittest.TestCase):
    def test_resample_keeps_requested_length(self) -> None:
        points = [(0.0, 0.5), (0.5, 0.2), (1.0, 0.5)]
        self.assertEqual(len(resample_path(points, 24)), 24)

    def test_matching_path_scores_higher_than_wrong_path(self) -> None:
        target = [(0.2, 0.6), (0.5, 0.4), (0.8, 0.6)]
        similar = [(0.21, 0.61), (0.48, 0.42), (0.79, 0.60)]
        wrong = [(0.8, 0.2), (0.8, 0.8), (0.2, 0.8)]

        similar_score, _ = trajectory_score(similar, target)
        wrong_score, _ = trajectory_score(wrong, target)

        self.assertGreater(similar_score, 90)
        self.assertLess(wrong_score, similar_score)

    def test_loads_shared_config(self) -> None:
        exercise = load_first_trajectory()
        self.assertGreaterEqual(len(exercise.path), 2)
        self.assertGreater(exercise.required_score, 0)

    def test_gesture_classifier_detects_vertical_reach(self) -> None:
        features = trajectory_features([(0.5, 0.8), (0.5, 0.6), (0.5, 0.35)])
        self.assertEqual(features["gesture"], "reach_up")
        self.assertGreater(float(features["smoothness"]), 0.8)

    def test_best_match_prefers_similar_candidate(self) -> None:
        candidates = [
            ("horizontal", [(0.2, 0.5), (0.8, 0.5)], 0.42),
            ("vertical", [(0.5, 0.8), (0.5, 0.3)], 0.42),
        ]
        match_id, score, _ = best_trajectory_match([(0.51, 0.78), (0.5, 0.5), (0.49, 0.32)], candidates)
        self.assertEqual(match_id, "vertical")
        self.assertGreater(score, 85)

    def test_loads_multiple_trajectory_exercises(self) -> None:
        exercises = load_trajectory_exercises()
        self.assertGreaterEqual(len(exercises), 3)
        self.assertTrue(all(exercise.expected_gesture for exercise in exercises))


if __name__ == "__main__":
    unittest.main()
