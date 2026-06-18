#!/bin/zsh
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
LAUNCHER="$PROJECT_ROOT/scripts/run_demo.command"

if [[ ! -x "$LAUNCHER" ]]; then
  echo "Launcher not found or not executable:"
  echo "$LAUNCHER"
  echo
  read "?Press Enter to close this window."
  exit 1
fi

exec "$LAUNCHER"
