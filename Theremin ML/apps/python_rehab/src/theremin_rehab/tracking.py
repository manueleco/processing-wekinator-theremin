"""Optional webcam hand tracking for the Python rehab app."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .dtw import Point, clamp


class TrackingDependencyError(RuntimeError):
    """Raised when optional camera tracking dependencies are not installed."""


@dataclass(frozen=True)
class TrackingResult:
    point: Point | None
    confidence: float
    frame: Any


class HandTracker:
    """Track the index-finger tip as a normalized `(x, y)` point."""

    def __init__(self, camera_index: int = 0, mirror: bool = True) -> None:
        try:
            import cv2  # type: ignore
            import mediapipe as mp  # type: ignore
        except ModuleNotFoundError as exc:
            raise TrackingDependencyError(
                "Install camera dependencies with: pip install -r apps/python_rehab/requirements.txt"
            ) from exc

        self.cv2 = cv2
        self.mp = mp
        self.mirror = mirror
        self.capture = cv2.VideoCapture(camera_index)
        if not self.capture.isOpened():
            raise RuntimeError(f"Could not open camera index {camera_index}.")

        self.hands = mp.solutions.hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.55,
            min_tracking_confidence=0.55,
        )

    def read(self) -> TrackingResult:
        ok, frame = self.capture.read()
        if not ok:
            return TrackingResult(point=None, confidence=0.0, frame=None)

        if self.mirror:
            frame = self.cv2.flip(frame, 1)

        rgb = self.cv2.cvtColor(frame, self.cv2.COLOR_BGR2RGB)
        results = self.hands.process(rgb)

        if not results.multi_hand_landmarks:
            return TrackingResult(point=None, confidence=0.0, frame=frame)

        hand_landmarks = results.multi_hand_landmarks[0]
        point = hand_landmarks.landmark[self.mp.solutions.hands.HandLandmark.INDEX_FINGER_TIP]
        normalized = (clamp(point.x), clamp(point.y))
        return TrackingResult(point=normalized, confidence=1.0, frame=frame)

    def close(self) -> None:
        self.capture.release()
        self.hands.close()
