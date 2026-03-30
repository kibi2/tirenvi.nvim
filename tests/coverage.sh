#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

cd "$ROOT_DIR"

eval "$(luarocks path)"

if [ ! -f "$ROOT_DIR/luacov.stats.out" ]; then
  echo "No coverage data. Run tests first."
  exit 1
fi

nvim --headless +"lua require('luacov.reporter.html').report()" +qa
mv luacov.report.out luacov.report.html
nvim --headless +"lua require('luacov.reporter.default').report()" +qa

echo "Coverage report: $ROOT_DIR/luacov.report.html"

if [ -z "${GITHUB_ACTIONS:-}" ] && command -v open >/dev/null 2>&1; then
  open "$ROOT_DIR/luacov.report.html"
fi