#!/usr/bin/env python3
"""Build a local clickable macOS launcher app for the Processing sketch.

The generated app is a launcher, not a standalone Processing export. It lives
under `dist/`, which is ignored by Git.
"""

from __future__ import annotations

import plistlib
import shutil
import stat
import struct
import subprocess
import zlib
from pathlib import Path


APP_NAME = "Adaptive Expressive Theremin Launcher.app"
ICON_NAME = "AppIcon"


def project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    checksum = zlib.crc32(chunk_type)
    checksum = zlib.crc32(data, checksum)
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", checksum & 0xFFFFFFFF)


def write_png(path: Path, size: int, pixels: list[tuple[int, int, int, int]]) -> None:
    raw_rows = []
    for y in range(size):
        start = y * size
        row = bytearray([0])
        for r, g, b, a in pixels[start:start + size]:
            row.extend((r, g, b, a))
        raw_rows.append(bytes(row))

    data = b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            png_chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)),
            png_chunk(b"IDAT", zlib.compress(b"".join(raw_rows), 9)),
            png_chunk(b"IEND", b""),
        ]
    )
    path.write_bytes(data)


def alpha_blend(base: tuple[int, int, int, int], top: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    tr, tg, tb, ta = top
    br, bg, bb, ba = base
    alpha = ta / 255.0
    inv = 1.0 - alpha
    return (
        int(tr * alpha + br * inv),
        int(tg * alpha + bg * inv),
        int(tb * alpha + bb * inv),
        255,
    )


def draw_circle(
    pixels: list[tuple[int, int, int, int]],
    size: int,
    cx: float,
    cy: float,
    radius: float,
    color: tuple[int, int, int, int],
    inner_radius: float = 0,
) -> None:
    min_x = max(0, int(cx - radius - 1))
    max_x = min(size - 1, int(cx + radius + 1))
    min_y = max(0, int(cy - radius - 1))
    max_y = min(size - 1, int(cy + radius + 1))
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            distance = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if inner_radius <= distance <= radius:
                index = y * size + x
                pixels[index] = alpha_blend(pixels[index], color)


def draw_line(
    pixels: list[tuple[int, int, int, int]],
    size: int,
    x1: float,
    y1: float,
    x2: float,
    y2: float,
    thickness: float,
    color: tuple[int, int, int, int],
) -> None:
    steps = max(1, int(max(abs(x2 - x1), abs(y2 - y1)) * 2))
    for step in range(steps + 1):
        t = step / steps
        x = x1 + (x2 - x1) * t
        y = y1 + (y2 - y1) * t
        draw_circle(pixels, size, x, y, thickness, color)


def render_icon_png(path: Path, size: int) -> None:
    pixels: list[tuple[int, int, int, int]] = []
    for y in range(size):
        for x in range(size):
            shade = int(15 + 22 * (y / max(1, size - 1)))
            pixels.append((shade, shade + 4, shade + 10, 255))

    draw_line(pixels, size, size * 0.68, size * 0.15, size * 0.68, size * 0.82, size * 0.018, (80, 205, 255, 255))
    draw_circle(pixels, size, size * 0.68, size * 0.15, size * 0.055, (80, 205, 255, 230))
    draw_circle(pixels, size, size * 0.32, size * 0.62, size * 0.17, (255, 194, 80, 230), size * 0.105)
    draw_line(pixels, size, size * 0.48, size * 0.43, size * 0.68, size * 0.43, size * 0.010, (80, 205, 255, 170))
    draw_line(pixels, size, size * 0.48, size * 0.43, size * 0.32, size * 0.62, size * 0.010, (255, 194, 80, 170))
    draw_circle(pixels, size, size * 0.48, size * 0.43, size * 0.075, (255, 255, 255, 245))
    draw_circle(pixels, size, size * 0.48, size * 0.43, size * 0.13, (255, 255, 255, 45))
    write_png(path, size, pixels)


def write_icns_from_iconset(iconset: Path, icns_path: Path) -> None:
    entries = [
        ("icp4", iconset / "icon_16x16.png"),
        ("icp5", iconset / "icon_32x32.png"),
        ("icp6", iconset / "icon_32x32@2x.png"),
        ("ic07", iconset / "icon_128x128.png"),
        ("ic08", iconset / "icon_256x256.png"),
        ("ic09", iconset / "icon_512x512.png"),
        ("ic10", iconset / "icon_512x512@2x.png"),
    ]
    payload = bytearray()
    for icon_type, path in entries:
        data = path.read_bytes()
        payload.extend(icon_type.encode("ascii"))
        payload.extend(struct.pack(">I", len(data) + 8))
        payload.extend(data)

    icns_path.write_bytes(b"icns" + struct.pack(">I", len(payload) + 8) + bytes(payload))


def build_icon(resources: Path, root: Path) -> bool:
    iconset = root / "dist" / f"{ICON_NAME}.iconset"
    icns_path = resources / f"{ICON_NAME}.icns"
    if iconset.exists():
        shutil.rmtree(iconset)
    iconset.mkdir(parents=True, exist_ok=True)

    icon_sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for filename, size in icon_sizes.items():
        render_icon_png(iconset / filename, size)

    result = subprocess.run(
        ["iconutil", "-c", "icns", "-o", str(icns_path), str(iconset)],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        write_icns_from_iconset(iconset, icns_path)
        print("Icon generation used the built-in .icns fallback because iconutil rejected the iconset.")
    return True


def main() -> None:
    root = project_root()
    app_path = root / "dist" / APP_NAME
    contents = app_path / "Contents"
    macos = contents / "MacOS"
    resources = contents / "Resources"
    executable = macos / "adaptive-expressive-theremin"

    if app_path.exists():
        shutil.rmtree(app_path)

    macos.mkdir(parents=True, exist_ok=True)
    resources.mkdir(parents=True, exist_ok=True)
    icon_ready = build_icon(resources, root)

    info = {
        "CFBundleDevelopmentRegion": "en",
        "CFBundleExecutable": executable.name,
        "CFBundleIdentifier": "edu.upf.adaptive-expressive-theremin.launcher",
        "CFBundleInfoDictionaryVersion": "6.0",
        "CFBundleName": "Adaptive Expressive Theremin",
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": "0.1.0",
        "CFBundleVersion": "0.1.0",
        "LSMinimumSystemVersion": "12.0",
        "NSHighResolutionCapable": True,
    }
    if icon_ready:
        info["CFBundleIconFile"] = ICON_NAME

    with (contents / "Info.plist").open("wb") as handle:
        plistlib.dump(info, handle)

    launcher = f"""#!/bin/zsh
set -e

PROJECT_ROOT={str(root)!r}
PROCESSING_APP="/Applications/Processing.app/Contents/MacOS/Processing"
SKETCH_DIR="$PROJECT_ROOT/apps/processing_wekinator/processing_wekinator_theremin"
LOG_DIR="$PROJECT_ROOT/dist/logs"
LOG_FILE="$LOG_DIR/launcher.log"

mkdir -p "$LOG_DIR"

if [[ ! -x "$PROCESSING_APP" ]]; then
  osascript -e 'display dialog "Processing was not found in /Applications. Install Processing or open the sketch manually." buttons {{"OK"}} default button "OK" with icon caution'
  exit 1
fi

cd "$PROJECT_ROOT"
exec "$PROCESSING_APP" cli --sketch="$SKETCH_DIR" --run >> "$LOG_FILE" 2>&1
"""
    executable.write_text(launcher, encoding="utf-8")
    executable.chmod(executable.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    print(f"created={app_path}")
    print("This launcher requires Processing to be installed in /Applications.")


if __name__ == "__main__":
    main()
