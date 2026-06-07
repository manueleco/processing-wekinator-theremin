#!/usr/bin/env python3
"""Build a local clickable macOS launcher app for the Processing sketch.

The generated app is a launcher, not a standalone Processing export. It lives
under `dist/`, which is ignored by Git.
"""

from __future__ import annotations

import plistlib
import shutil
import stat
from pathlib import Path


APP_NAME = "Adaptive Expressive Theremin Launcher.app"


def project_root() -> Path:
    return Path(__file__).resolve().parents[1]


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
    with (contents / "Info.plist").open("wb") as handle:
        plistlib.dump(info, handle)

    launcher = f"""#!/bin/zsh
set -e

PROJECT_ROOT={str(root)!r}
PROCESSING_APP="/Applications/Processing.app/Contents/MacOS/Processing"
SKETCH_DIR="$PROJECT_ROOT/processing_wekinator_theremin"
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
