#!/usr/bin/env bash

# Global setup for all benchmarks in this file
set_up_before_script() {
    # Ensure DK_EVENTS is declared as an associative array
    declare -gA DK_EVENTS
    declare -gA _DK_SORTED_EVENTS

    # Define dummy functions for emission once
    local i
    for i in $(seq 1 1000); do
        eval "func_$i() { :; }"
    done

}

# Setup function to run before each benchmark
set_up() {
    # Reset DK_EVENTS and _DK_SORTED_EVENTS before each test
    DK_EVENTS=()
    _DK_SORTED_EVENTS=()
}

# Benchmark: dk_on - single hook registration
# @revs=1 @its=100
function bench_dk_on_single() {
    set_up
    dk_on "test_event" "my_func"
}

# Benchmark: dk_on - 100 hook registrations to the same event
# @revs=1 @its=100
function bench_dk_on_100() {
    set_up
    local i
    for i in $(seq 1 100); do
        dk_on "test_event_100" "my_func_$i" "$i"
    done
}

# Helper function for benchmarks involving many events
_setup_many_events() {
    local event_name="$1"
    local num_events="$2"
    local i
    for i in $(seq 1 "$num_events"); do
        dk_on "$event_name" "func_$i" "$((RANDOM % 1000))"
    done
}

# Benchmark: _dk_finalize_events with 100 events
# @revs=1 @its=100
function bench_dk_finalize_events_100() {
    set_up
    _setup_many_events "finalize_event_100" 100
    _dk_finalize_events
}

# Benchmark: _dk_finalize_events with 1000 events
# @revs=1 @its=100
function bench_dk_finalize_events_1000() {
    set_up
    _setup_many_events "finalize_event_1000" 1000
    _dk_finalize_events
}

# Benchmark: dk_emit with 100 events
# @revs=1 @its=100
function bench_dk_emit_100() {
    set_up
    local i
    local event_name="emit_event_100"
    for i in $(seq 1 100); do
        dk_on "$event_name" "func_$i" "$((RANDOM % 1000))"
    done
    _dk_finalize_events
    dk_emit "$event_name"
}

# Benchmark: dk_emit with 100 executable events
# @revs=1 @its=100
function bench_dk_emit_100_exec() {
    set_up
    local i
    local event_name="emit_event_100_exec"
    for i in $(seq 1 100); do
        local exec_hook="$TEST_DIR/bench_exec_hook_$i.sh"
        echo -e '#!/usr/bin/env bash\n:' > "$exec_hook"
        chmod +x "$exec_hook"
        dk_on "$event_name" "$exec_hook" "$((RANDOM % 1000))"
    done
    _dk_finalize_events
    dk_emit "$event_name"
}

# Benchmark: dk_emit with 1000 events
# @revs=1 @its=100
function bench_dk_emit_1000() {
    set_up
    local i
    local event_name="emit_event_1000"
    for i in $(seq 1 1000); do
        dk_on "$event_name" "func_$i" "$((RANDOM % 1000))"
    done
    _dk_finalize_events
    dk_emit "$event_name"
}
