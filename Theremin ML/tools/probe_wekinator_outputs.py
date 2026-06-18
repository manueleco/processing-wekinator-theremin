#!/usr/bin/env python3
"""Probe whether Wekinator is sending /wek/outputs to port 12000."""

from __future__ import annotations

import socket
import struct
import sys
import time
import select
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from train_wekinator_demo import (  # noqa: E402
    INPUT_ADDRESS,
    OscSender,
    START_RUNNING_ADDRESS,
    WEKINATOR_HOST,
    WEKINATOR_PORT,
    osc_message,
)


LISTEN_PORT = 12000


def read_osc_string(data: bytes, offset: int) -> tuple[str, int]:
    end = data.index(b"\0", offset)
    value = data[offset:end].decode("utf-8", errors="replace")
    offset = end + 1
    while offset % 4 != 0:
        offset += 1
    return value, offset


def decode_osc(data: bytes) -> tuple[str, list[float | int | str]]:
    address, offset = read_osc_string(data, 0)
    tags, offset = read_osc_string(data, offset)
    values: list[float | int | str] = []
    for tag in tags[1:]:
        if tag == "f":
            values.append(struct.unpack(">f", data[offset:offset + 4])[0])
            offset += 4
        elif tag == "i":
            values.append(struct.unpack(">i", data[offset:offset + 4])[0])
            offset += 4
        elif tag == "s":
            value, offset = read_osc_string(data, offset)
            values.append(value)
    return address, values


def open_listeners(port: int) -> list[socket.socket]:
    listeners: list[socket.socket] = []
    bind_errors: list[str] = []
    for family, bind_addr in (
        (socket.AF_INET6, ("", port)),
        (socket.AF_INET, ("", port)),
    ):
        listener = socket.socket(family, socket.SOCK_DGRAM)
        listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        if family == socket.AF_INET6 and hasattr(socket, "IPV6_V6ONLY"):
            listener.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        try:
            listener.bind(bind_addr)
        except OSError as exc:
            listener.close()
            bind_errors.append(str(exc))
            continue
        listener.setblocking(False)
        listeners.append(listener)
    if not listeners:
        print(f"Could not listen on port {port}: {'; '.join(bind_errors)}")
        print("Close Processing if it is already using that port, then try again.")
    return listeners

def close_listeners(listeners: list[socket.socket]) -> None:
    for listener in listeners:
        listener.close()


def main() -> int:
    listeners = open_listeners(LISTEN_PORT)
    if not listeners:
        return 2

    try:
        with OscSender(WEKINATOR_HOST, WEKINATOR_PORT) as sender:
            sender.send(START_RUNNING_ADDRESS)
            deadline = time.time() + 3.0
            test_inputs = (0.50, 0.62, 0.08, 0.05, 1.00, 0.04)
            while time.time() < deadline:
                sender.send(INPUT_ADDRESS, test_inputs)
                readable, _, _ = select.select(listeners, [], [], 0.25)
                if not readable:
                    time.sleep(0.05)
                    continue
                data, _ = readable[0].recvfrom(4096)
                address, values = decode_osc(data)
                print(f"received {address}: {values}")
                return 0
    finally:
        close_listeners(listeners)

    print("No Wekinator output received within 3 seconds.")
    print("Check that Wekinator is running, trained, and sending /wek/outputs to localhost:12000.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
