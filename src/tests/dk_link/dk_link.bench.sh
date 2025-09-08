#!/usr/bin/env bash

# Global setup for all benchmarks in this file
set_up_before_script() {
    # Create a temporary directory for all tests
    mkdir -p "$DOTKIT_ROOT/.test_temp"
    TEST_BASE_DIR="$(mktemp -d "$DOTKIT_ROOT/.test_temp/bench.XXXXXX")"
    export TEST_BASE_DIR

    FIXTURES_DIR="$TEST_BASE_DIR/fixtures"
    mkdir -p "$FIXTURES_DIR"

    # Mock gum to always return yes for prompts globally
    mock_gum_yes
    # Mock dk_warn_list to do nothing during benchmarks
    mock_dk_warn_list_silent

    # Pre-create source files for single link creation
    create_test_file "$FIXTURES_DIR/source_single.txt" "content"

    # Pre-create source files for multiple link creation (10 links)
    for i in $(seq 1 10); do
        create_test_file "$FIXTURES_DIR/source_$i.txt" "content_$i"
    done

    # Pre-create source files for multiple link creation (100 links)
    for i in $(seq 1 100); do
        create_test_file "$FIXTURES_DIR/source_100_$i.txt" "content_100_$i"
    done

    # Pre-create files for overwriting existing symlinks (single)
    create_test_file "$FIXTURES_DIR/source_overwrite.txt" "new content"
    create_test_file "$FIXTURES_DIR/old_target.txt" "old content"

    # Pre-create files for overwriting existing symlinks (10 links)
    for i in $(seq 1 10); do
        create_test_file "$FIXTURES_DIR/source_overwrite_$i.txt" "new content_$i"
        create_test_file "$FIXTURES_DIR/old_target_$i.txt" "old content_$i"
    done

    # Pre-create files for overwriting existing symlinks (100 links)
    for i in $(seq 1 100); do
        create_test_file "$FIXTURES_DIR/source_overwrite_100_$i.txt" "new content_100_$i"
        create_test_file "$FIXTURES_DIR/old_target_100_$i.txt" "old content_100_$i"
    done
}

# Setup function to run before each benchmark
set_up() {
    TEST_DIR="$TEST_BASE_DIR/$(date +%s%N)"
    export TEST_DIR
    mkdir -p "$TEST_DIR"

}

# Teardown function to run after each benchmark
tear_down() {
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Global teardown for all benchmarks
tear_down_after_script() {
    [[ -n "$TEST_BASE_DIR" ]] && rm -rf "$TEST_BASE_DIR"
    rm -rf "$DOTKIT_ROOT/.test_temp"
    unset TEST_BASE_DIR
    unset FIXTURES_DIR
    unset -f gum # Unset the mocked gum function
    unset -f dk_warn_list # Unset the mocked dk_warn_list function
}

# Benchmark: dk_link - single link creation
# @revs=1 @its=100
function bench_dk_link_single() {
    set_up

    local source_file="$FIXTURES_DIR/source_single.txt"
    local target_file="$TEST_DIR/target_single.txt"
    dk_link "$source_file" "$target_file"

    tear_down
}

# Benchmark: dk_link - multiple link creation (10 links)
# @revs=50 @its=5
function bench_dk_link_multiple_10() {
    set_up

    local i
    local source_files=()
    local target_files=()
    for i in $(seq 1 10); do
        source_files+=("$FIXTURES_DIR/source_$i.txt")
        target_files+=("$TEST_DIR/target_$i.txt")
    done
    dk_link "${source_files[@]}" "${target_files[@]}"

    tear_down
}

# Benchmark: dk_link - multiple link creation (100 links)
# @revs=1 @its=100
function bench_dk_link_multiple_100() {
    set_up

    local i
    local source_files=()
    local target_files=()
    for i in $(seq 1 100); do
        source_files+=("$FIXTURES_DIR/source_100_$i.txt")
        target_files+=("$TEST_DIR/target_$i.txt")
    done
    dk_link "${source_files[@]}" "${target_files[@]}"

    tear_down
}

# Benchmark: dk_link - overwriting existing symlinks (single)
# @revs=1 @its=100
function bench_dk_link_overwrite_single() {
    set_up
    
    local source_file="$FIXTURES_DIR/source_overwrite.txt"
    local target_file="$TEST_DIR/target_overwrite.txt"
    local old_target="$FIXTURES_DIR/old_target.txt"
    create_test_symlink "$old_target" "$target_file"
    dk_link "$source_file" "$target_file"

    tear_down
}

# Benchmark: dk_link - overwriting existing symlinks (10 links)
# @revs=1 @its=100
function bench_dk_link_overwrite_10() {
    set_up
    
    local i
    local source_files=()
    local target_files=()
    local old_targets=()
    for i in $(seq 1 10); do
        source_files+=("$FIXTURES_DIR/source_overwrite_$i.txt")
        target_files+=("$TEST_DIR/target_overwrite_$i.txt")
        old_targets+=("$FIXTURES_DIR/old_target_$i.txt")
        create_test_symlink "${old_targets[-1]}" "${target_files[-1]}"
    done
    dk_link "${source_files[@]}" "${target_files[@]}"

    tear_down
}

# Benchmark: dk_link - overwriting existing symlinks (100 links)
# @revs=1 @its=25
function bench_dk_link_overwrite_100() {
    set_up
    
    local i
    local source_files=()
    local target_files=()
    local old_targets=()
    for i in $(seq 1 100); do
        source_files+=("$FIXTURES_DIR/source_overwrite_100_$i.txt")
        target_files+=("$TEST_DIR/target_overwrite_$i.txt")
        old_targets+=("$FIXTURES_DIR/old_target_100_$i.txt")
        create_test_symlink "${old_targets[-1]}" "${target_files[-1]}"
    done
    dk_link "${source_files[@]}" "${target_files[@]}"

    tear_down
}
