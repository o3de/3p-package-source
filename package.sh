#!/bin/bash
# Launch package.py in this directory with all forwarded arguments

BASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT=$BASE_PATH/package.py

SUBMODULE_PATH=$BASE_PATH/Scripts/packaging

echo $SUBMODULE_PATH

if [ ! -d "$SUBMODULE_PATH" ]; then
  echo "Submodule not found. Please run 'git submodule update --init --recursive' to initialize the submodule."
  exit 1
fi

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
