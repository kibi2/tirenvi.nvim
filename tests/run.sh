#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

exec "$SCRIPT_DIR/golden_test.sh" "$SCRIPT_DIR/backend/nvim.sh" "$@"