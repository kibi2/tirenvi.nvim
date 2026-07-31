TEST_BIN="${TEST_BIN:-nvim}"

backend_setup() {
    echo "Running with: $TEST_BIN"
    printf "${BOLD}${GREEN}%s${RESET}\n" "$($TEST_BIN --version | head -n 1)"
    STATS="luacov.stats.out"
    eval "$(luarocks path)"
    : > "$ROOT_DIR/$STATS"
}

backend_case_setup() {
    if [ ! -e "./$STATS" ]; then
        ln -s "$ROOT_DIR/$STATS" "./$STATS"
    fi
}

backend_case_cleanup() {
    :
}

backend_runner() {
    echo "run.vim"
}

backend_run() {
    if [ -f run.sh ]; then
        TEST_BIN=$TEST_BIN sh run.sh > stdout.txt 2> stderr.txt
    else
        [ -f run.env ] && . run.env
        env \
            NVIM_APPNAME="${NVIM_APPNAME:-}" \
            NVIM_TIRENVI_DEV=1 \
            $TEST_BIN --headless -u NONE -n \
                -c "source run.vim" \
                -c "qa!" \
            >> stdout.txt 2>> stderr.txt
    fi
}