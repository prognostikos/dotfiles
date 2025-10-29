#!/bin/bash
# Run devcontainer_helpers module tests

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Running devcontainer_helpers tests..."
echo ""

nvim --headless -l "$SCRIPT_DIR/test.lua"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo "🎉 Tests passed successfully!"
else
  echo ""
  echo "❌ Tests failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
fi
