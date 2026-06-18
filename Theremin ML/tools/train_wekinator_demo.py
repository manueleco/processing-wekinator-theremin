#!/usr/bin/env python3
"""Send a small bootstrap training set to an open Wekinator 6x4 project.

This uses only Python's standard library. Wekinator must already have the
expressive 6-input / 4-output project open, and "Enable OSC control of GUI"
must be checked in Wekinator's Actions menu.
"""

from __future__ import annotations

import argparse
import math
import random
import socket
import struct
import sys
import time
from dataclasses import dataclass
from typing import Iterable


WEKINATOR_HOST = "localhost"
WEKINATOR_PORT = 6448
INPUT_ADDRESS = "/wek/inputs"
OUTPUTS_ADDRESS = "/wekinator/control/outputs"
START_RECORDING_ADDRESS = "/wekinator/control/startRecording"
STOP_RECORDING_ADDRESS = "/wekinator/control/stopRecording"
TRAIN_ADDRESS = "/wekinator/control/train"
START_RUNNING_ADDRESS = "/wekinator/control/startRunning"
STOP_RUNNING_ADDRESS = "/wekinator/control/stopRunning"
DELETE_ALL_ADDRESS = "/wekinator/control/deleteAllExamples"


@dataclass(frozen=True)
class TrainingExample:
    name: str
    base_inputs: tuple[float, float, float, float, float, float]
    outputs: tuple[float, float, float, float]
    jitter: tuple[float, float, float, float, float, float]
    seconds: float = 1.15
    moving: bool = False


def osc_string(value: str) -> bytes:
    data = value.encode("utf-8") + b"\0"
    padding = (4 - len(data) % 4) % 4
    return data + b"\0" * padding


def osc_message(address: str, values: Iterable[float | int] = ()) -> bytes:
    values = list(values)
    tags = ","
    payload = bytearray()
    for value in values:
        if isinstance(value, int):
            tags += "i"
            payload.extend(struct.pack(">i", value))
        else:
            tags += "f"
            payload.extend(struct.pack(">f", float(value)))
    return osc_string(address) + osc_string(tags) + bytes(payload)


def clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


class OscSender:
    def __init__(self, host: str, port: int) -> None:
        self.targets: list[tuple[socket.socket, tuple]] = []
        seen: set[tuple[int, tuple]] = set()
        for family, _, _, _, sockaddr in socket.getaddrinfo(host, port, type=socket.SOCK_DGRAM):
            key = (family, sockaddr)
            if key in seen:
                continue
            seen.add(key)
            sock = socket.socket(family, socket.SOCK_DGRAM)
            self.targets.append((sock, sockaddr))
        if not self.targets:
            raise RuntimeError(f"Could not resolve OSC target {host}:{port}")

    def close(self) -> None:
        for sock, _ in self.targets:
            sock.close()

    def __enter__(self) -> "OscSender":
        return self

    def __exit__(self, exc_type, exc, traceback) -> None:
        self.close()

    def send(self, address: str, values: Iterable[float | int] = ()) -> None:
        packet = osc_message(address, values)
        sent = 0
        last_error: OSError | None = None
        for sock, sockaddr in self.targets:
            try:
                sock.sendto(packet, sockaddr)
                sent += 1
            except OSError as exc:
                last_error = exc
        if sent == 0 and last_error is not None:
            raise last_error


def varied_inputs(example: TrainingExample, frame: int, total_frames: int, rng: random.Random) -> tuple[float, ...]:
    phase = frame / max(1, total_frames - 1)
    values: list[float] = []
    for index, base in enumerate(example.base_inputs):
        motion = 0.0
        if example.moving and index in (0, 1, 2, 3):
            motion = math.sin(phase * math.tau * 1.6 + index * 0.7) * example.jitter[index] * 1.8
        noise = rng.uniform(-example.jitter[index], example.jitter[index])
        values.append(clamp(base + motion + noise))
    return tuple(values)


def training_examples() -> list[TrainingExample]:
    return [
        TrainingExample(
            "low stable",
            (0.14, 0.54, 0.03, 0.02, 1.00, 0.03),
            (0.14, 0.54, 0.00, 0.10),
            (0.018, 0.025, 0.010, 0.010, 0.000, 0.010),
        ),
        TrainingExample(
            "middle stable",
            (0.50, 0.60, 0.03, 0.02, 1.00, 0.03),
            (0.50, 0.60, 0.00, 0.18),
            (0.018, 0.025, 0.010, 0.010, 0.000, 0.010),
        ),
        TrainingExample(
            "high stable",
            (0.86, 0.60, 0.03, 0.02, 1.00, 0.03),
            (0.86, 0.60, 0.00, 0.25),
            (0.018, 0.025, 0.010, 0.010, 0.000, 0.010),
        ),
        TrainingExample(
            "silent near loop",
            (0.50, 0.04, 0.02, 0.02, 1.00, 0.04),
            (0.50, 0.00, 0.00, 0.00),
            (0.020, 0.018, 0.010, 0.010, 0.000, 0.010),
        ),
        TrainingExample(
            "slow expressive",
            (0.44, 0.64, 0.18, 0.12, 0.95, 0.08),
            (0.44, 0.62, 0.18, 0.30),
            (0.050, 0.040, 0.035, 0.030, 0.030, 0.025),
            moving=True,
        ),
        TrainingExample(
            "fast expressive",
            (0.66, 0.80, 0.72, 0.65, 0.93, 0.14),
            (0.66, 0.80, 0.65, 0.85),
            (0.070, 0.055, 0.060, 0.065, 0.030, 0.035),
            moving=True,
        ),
        TrainingExample(
            "noisy stabilized",
            (0.52, 0.38, 0.42, 0.48, 0.55, 0.72),
            (0.50, 0.35, 0.15, 0.15),
            (0.120, 0.100, 0.120, 0.120, 0.080, 0.100),
            moving=True,
        ),
        TrainingExample(
            "intentional circular motion",
            (0.70, 0.74, 0.58, 0.52, 0.92, 0.16),
            (0.70, 0.74, 0.80, 0.70),
            (0.080, 0.070, 0.060, 0.060, 0.030, 0.035),
            moving=True,
        ),
    ]


def run_training(args: argparse.Namespace) -> None:
    rng = random.Random(args.seed)
    frame_interval = 1.0 / args.rate

    with OscSender(args.host, args.port) as osc:
        print(f"Sending OSC to Wekinator on {args.host}:{args.port}")
        print("Make sure the 6-input / 4-output project is open and OSC GUI control is enabled.")
        osc.send(STOP_RUNNING_ADDRESS)
        time.sleep(0.20)

        if args.delete_existing:
            print("Deleting existing examples in the currently open Wekinator project.")
            osc.send(DELETE_ALL_ADDRESS)
            time.sleep(0.50)

        total_sent = 0
        for index, example in enumerate(training_examples(), start=1):
            print(f"Recording {index}/8: {example.name} -> {example.outputs}")
            osc.send(OUTPUTS_ADDRESS, example.outputs)
            time.sleep(0.25)

            frames = max(6, int(example.seconds * args.rate))
            osc.send(START_RECORDING_ADDRESS)
            time.sleep(0.05)
            for frame in range(frames):
                osc.send(INPUT_ADDRESS, varied_inputs(example, frame, frames, rng))
                total_sent += 1
                time.sleep(frame_interval)
            osc.send(STOP_RECORDING_ADDRESS)
            time.sleep(0.35)

        print(f"Sent {total_sent} input frames.")
        print("Training Wekinator models.")
        osc.send(TRAIN_ADDRESS)
        time.sleep(args.train_wait)
        print("Starting Wekinator running mode.")
        osc.send(START_RUNNING_ADDRESS)

    print("Done. In Processing, press X until expressive 6x4, then W to use Wekinator.")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Bootstrap-train the currently open Wekinator expressive 6x4 project via OSC."
    )
    parser.add_argument(
        "--delete-existing",
        action="store_true",
        help="Delete all existing examples before recording the bootstrap examples.",
    )
    parser.add_argument("--rate", type=float, default=30.0, help="Input frames per second to send while recording.")
    parser.add_argument("--train-wait", type=float, default=3.0, help="Seconds to wait after sending /train.")
    parser.add_argument("--seed", type=int, default=42, help="Deterministic jitter seed.")
    parser.add_argument("--host", default=WEKINATOR_HOST, help="Wekinator OSC host.")
    parser.add_argument("--port", type=int, default=WEKINATOR_PORT, help="Wekinator OSC input/control port.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.rate <= 0:
        print("--rate must be positive", file=sys.stderr)
        return 2
    run_training(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
