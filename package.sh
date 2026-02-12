#!/bin/bash
# Launch package.py in this directory with all forwarded arguments

SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/package.py"

if command -v python &> /dev/null; then
  python "$SCRIPT" "$@"
  exit $?
elif command -v python3 &> /dev/null; then
  python3 "$SCRIPT" "$@"
  exit $?
else
  echo "Python launcher not found. Install Python or add it to PATH."
  exit 1
fi
