#!/bin/sh
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
CASES_DIR="$SCRIPT_DIR/cases"

export TIRENVI_ROOT="$ROOT_DIR"

GREEN='\033[32m'
RED='\033[31m'
BOLD='\033[1m'
RED_BG='\033[41m'
WHITE='\033[37m'
RESET='\033[0m'

UPDATE=0

PATTERNS=""

for arg in "$@"; do
  if [ "$arg" = "--update" ]; then
    UPDATE=1
  else
    PATTERNS="$PATTERNS $arg"
  fi
done

FAILED_FILE=$(mktemp)
trap 'rm -f "$FAILED_FILE"' EXIT

# find "$CASES_DIR" -type d | while read -r d; do
find "$CASES_DIR" -type d -print0 |
while IFS= read -r -d '' d; do

  # runner が無ければスキップ
  if [ ! -f "$d/run.sh" ] && [ ! -f "$d/run.vim" ]; then
    continue
  fi

  name=${d#"$CASES_DIR"/}

  # --- filter ---
  if [ -n "$PATTERNS" ]; then
    matched=0
    for p in $PATTERNS; do
      case "$name" in
        $p) matched=1 ;;
      esac
    done
    [ "$matched" -eq 1 ] || continue
  fi
  
  if [ "$UPDATE" -eq 1 ]; then
    if [ -f "$d/out-expected.txt" ]; then
      continue
    fi
  fi

  printf "%-40s ... " "$name"

  if (
    cd "$d"
    rm -f diff-*.txt gen.* stdout.txt stderr.txt out-actual.txt

    if [ -f run.sh ]; then
      sh run.sh > stdout.txt 2> stderr.txt
    else
      NVIM_TIRENVI_DEV=1 nvim --headless -u NONE -n -S run.vim \
        > stdout.txt 2> stderr.txt
    fi

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
  fi
done

if [ -s "$FAILED_FILE" ]; then
  count=$(grep -c '^' "$FAILED_FILE")
  echo
  echo "${BOLD}${RED_BG}${WHITE} FAILED CASES ($count) ${RESET}"
  awk '{printf("%3d. %s\n", NR, $0)}' "$FAILED_FILE"
  exit 1
fi

echo
echo "${BOLD}${GREEN}ALL TESTS PASSED${RESET}"
