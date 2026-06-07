#!/bin/zsh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROCESSING_APP="/Applications/Processing.app/Contents/MacOS/Processing"
SKETCH_DIR="$PROJECT_ROOT/processing_wekinator_theremin"

echo "Adaptive Expressive Theremin"
echo "Project: $PROJECT_ROOT"
echo

if [[ ! -x "$PROCESSING_APP" ]]; then
  echo "Processing was not found at:"
  echo "$PROCESSING_APP"
  echo
  echo "Install Processing or open the sketch manually."
  read "?Press Enter to close."
  exit 1
fi

echo "Launching Processing sketch..."
echo "Tip: Press M for sound, B for demo guide, N for next step."
echo

"$PROCESSING_APP" cli --sketch="$SKETCH_DIR" --run

echo
read "?Processing closed. Press Enter to close this window."
