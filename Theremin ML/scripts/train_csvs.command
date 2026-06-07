#!/bin/zsh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Adaptive Expressive Theremin CSV Training"
echo "Project: $PROJECT_ROOT"
echo

if [[ -x ".venv/bin/python" ]]; then
  PYTHON=".venv/bin/python"
else
  PYTHON="python3"
fi

echo "Using Python: $PYTHON"
echo

"$PYTHON" ml/train_csvs.py "$@"

echo
read "?Training script finished. Press Enter to close this window."
