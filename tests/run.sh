#!/usr/bin/env bash

# Usage:
#   ./run.sh                 # run all tests
#   ./run.sh file/csv        # run tests matching pattern
#   ./run.sh --update        # generate expected outputs (for new tests)
#
# Environment variables:
#   FAIL_FAST=1              # stop on first failure
#   NO_COLOR=1               # disable colored output
#
# Notes:
# - Tests are located under cases/
# - Each test must have run.sh or run.vim
# - --update does NOT overwrite existing out-expected.txt

set -euo pipefail

GREEN='\033[32m'
RED='\033[31m'
BOLD='\033[1m'
RED_BG='\033[41m'
WHITE='\033[37m'
RESET='\033[0m'

# disable color
if [ -n "${NO_COLOR:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
  GREEN=""
  RED=""
  RESET=""
  BOLD=""
  RED_BG=""
  WHITE=""
fi

NVIM_BIN="${NVIM_BIN:-nvim}"
echo "Running with: $NVIM_BIN"
printf "${BOLD}${GREEN}%s${RESET}\n" "$($NVIM_BIN --version | head -n 1)"

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
CASES_DIR="$SCRIPT_DIR/cases"
STATS="luacov.stats.out"

export TIRENVI_ROOT="$ROOT_DIR"

eval "$(luarocks path)"
: >  "$ROOT_DIR/$STATS"

UPDATE=0
FAIL_FAST=${FAIL_FAST:-0}

PATTERNS=""

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  sed -n '2,15p' "$0"
  exit 0
fi

for arg in "$@"; do
  if [ "$arg" = "--update" ]; then
    UPDATE=1
  else
    PATTERNS="$PATTERNS $arg"
  fi
done

FAILED_FILE=$(mktemp)
trap 'rm -f "$FAILED_FILE"' EXIT

TOTAL=0

while IFS= read -r -d '' d; do

  if [ ! -f "$d/run.sh" ] && [ ! -f "$d/run.vim" ]; then
    continue
  fi

  if [ -f "$d/skip-ci" ]; then
    if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
      echo "skip (ci): $d"
      continue
    fi
  fi

  #name=${d#"$SCRIPT_DIR"/}
  name_match=${d#"$ROOT_DIR"/}
  name=${d#"$CASES_DIR"/}

  # --- filter ---
  if [ -n "$PATTERNS" ]; then
    matched=0
    for p in $PATTERNS; do
      case "$name_match" in
        *"$p"*) matched=1 ;;
      esac
    done
    [ "$matched" -eq 1 ] || continue
  fi

  TOTAL=$((TOTAL+1))

  if [ "$UPDATE" -eq 1 ]; then
    if [ -f "$d/out-expected.txt" ]; then
      continue
    fi
  fi

  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::group::test $name"
  fi

  printf "%-40s ... " "$name"

  if (
    cd "$d"
    rm -f diff-*.txt gen.* stdout.txt stderr.txt out-actual.txt

    if [ ! -e "./$STATS" ]; then
      ln -s "$ROOT_DIR/$STATS" "./$STATS"
    fi
      NVIM_TIRENVI_DEV=1 $NVIM_BIN --headless -u NONE -n \
        -c "source run.vim" \
        -c "qa!" \
        > stdout.txt 2> stderr.txt
    if [ -f run.sh ]; then
      sh run.sh > stdout.txt 2> stderr.txt
    fi

    LC_ALL=C sed -E '/PRB/! s/ [0-9]+]/]/g' out-actual.txt > gen.txt
    # LC_ALL=C sed -E 's/ [0-9]+]/]/g' out-actual.txt > gen.txt
    mv gen.txt out-actual.txt
    LC_ALL=C sed -E 's/[0-9]+ seconds? ago/<time>/g' out-actual.txt > gen.txt
    mv gen.txt out-actual.txt

    if [ "$UPDATE" -eq 1 ]; then
      if [ -f out-expected.txt ]; then
        echo "Refusing update: out-expected.txt already exists"
        exit 1
      fi
      mv out-actual.txt out-expected.txt
      exit 0
    fi

    if [ ! -f out-expected.txt ]; then
      echo "Missing out-expected.txt"
      exit 1
    fi

    diff_file="diff-$name.txt"
    diff_file=$(printf '%s' "$diff_file" | tr ' /' '__')

    if diff -u out-expected.txt out-actual.txt > "$diff_file"; then
      rm "$diff_file"
    else
      echo "DIFF FOUND (see $diff_file)"
      exit 1
    fi

  ); then
    if [ "$UPDATE" -eq 1 ]; then
      printf "${GREEN}UPDATED${RESET}\n"
    else
      printf "${GREEN}SUCCESS${RESET}\n"
    fi
  else
    printf "${RED}FAIL${RESET}\n"
    echo "$name" >> "$FAILED_FILE"

    if [ "$FAIL_FAST" -eq 1 ]; then
      printf "\n${BOLD}${RED}FAIL-FAST: stopping after first failure${RESET}"
      exit 1
    fi
  fi

  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::endgroup::"
  fi

done < <(find "$CASES_DIR" -type d -print0)

if [ -s "$FAILED_FILE" ]; then
  count=$(grep -c '^' "$FAILED_FILE")
  printf "\n${BOLD}${RED_BG}${WHITE} FAILED CASES ($count) ${RESET}\n"
  awk '{printf("%3d. %s\n", NR, $0)}' "$FAILED_FILE"
  exit 1
fi

printf "\n${BOLD}${GREEN}ALL TESTS PASSED (${TOTAL} cases)${RESET}\n"
