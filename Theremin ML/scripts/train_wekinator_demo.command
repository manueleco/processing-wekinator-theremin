#!/bin/zsh
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$PROJECT_ROOT/wekinator_projects/expressive_6x4/AdaptiveExpressiveTheremin6x4/AdaptiveExpressiveTheremin6x4.wekproj"

clear
echo "Adaptive Expressive Theremin - Wekinator demo trainer"
echo
echo "1. Open this Wekinator project:"
echo "   $PROJECT_FILE"
echo
echo "2. In Wekinator, make sure:"
echo "   - Actions -> Enable OSC control of GUI is checked"
echo "   - Click Start listening if the setup screen says Not listening"
echo "   - Click Next so the project is on the main training screen"
echo "   - The main screen shows OSC In as green"
echo
read "REPLY?Press Enter when Wekinator is ready, or Ctrl+C to cancel..."
echo
cd "$PROJECT_ROOT"
python3 tools/train_wekinator_demo.py --delete-existing
python3 tools/probe_wekinator_outputs.py || true
echo
read "REPLY?Done. Press Enter to close this window..."
