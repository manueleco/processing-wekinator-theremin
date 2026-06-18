#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROCESSING_APP="/Applications/Processing.app/Contents/MacOS/Processing"
SKETCH_DIR="$PROJECT_ROOT/apps/processing_wekinator/processing_wekinator_theremin"
SKETCH_FILE="$SKETCH_DIR/processing_wekinator_theremin.pde"

pause() {
  echo
  read "?Press Enter to close this window."
}

echo "Adaptive Expressive Theremin"
echo "Project: $PROJECT_ROOT"
echo "Sketch: $SKETCH_FILE"
echo

if [[ ! -x "$PROCESSING_APP" ]]; then
  echo "Processing was not found at:"
  echo "$PROCESSING_APP"
  echo
  echo "Install Processing or open the sketch manually."
  pause
  exit 1
fi

if [[ ! -f "$SKETCH_FILE" ]]; then
  echo "Sketch file was not found:"
  echo "$SKETCH_FILE"
  pause
  exit 1
fi

echo "Launching Processing sketch..."
echo "Tip: Press M for sound, B for demo guide, N for next step."
echo

"$PROCESSING_APP" cli --sketch="$SKETCH_DIR" --run
status=$?

if [[ $status -ne 0 ]]; then
  echo
  echo "Processing CLI exited with status $status."
  echo "Opening the sketch in Processing so you can press Run manually."
  open -a "Processing" "$SKETCH_FILE"
fi

echo
echo "If the sketch opened in Processing but did not run, press the Run button."
pause
