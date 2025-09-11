#!/usr/bin/env bash

# Global setup for all benchmarks in this file
set_up_before_script() {
    # Create a temporary directory for all tests
    mkdir -p "$DOTKIT_ROOT/.test_temp"
    TEST_BASE_DIR="$(mktemp -d "$DOTKIT_ROOT/.test_temp/bench.XXXXXX")"
    export TEST_BASE_DIR

    FIXTURES_DIR="$TEST_BASE_DIR/fixtures"
    mkdir -p "$FIXTURES_DIR"

    # Pre-create TOML fixtures for benchmarks
    cat > "$FIXTURES_DIR/benchmark.toml" <<EOF
name="benchmark-module"
version="1.0.0"
description="Module for benchmarking"
type="module"

[files]
"config.conf" = "~/.config/app/config.conf"
"style.css" = "~/.config/app/style.css"

[events.pre_install]
install = "echo 'Installing'"
setup = "echo 'Setting up'"

[events.post_install]
notify = "echo 'Done'"
EOF

    # Pre-create multiple TOML files for batch benchmarks
    for i in $(seq 1 10); do
        cat > "$FIXTURES_DIR/benchmark_$i.toml" <<EOF
name="benchmark-module-$i"
version="1.0.$i"
description="Module $i for benchmarking"
type="module"

[files]
"config$i.conf" = "~/.config/app$i/config.conf"
"style$i.css" = "~/.config/app$i/style.css"

[events.pre_install]
install$i = "echo 'Installing module $i'"
setup$i = "echo 'Setting up module $i'"

[events.post_install]
notify$i = "echo 'Done with module $i'"
EOF
    done

    # Pre-create 100 TOML files for stress testing
    for i in $(seq 1 100); do
        cat > "$FIXTURES_DIR/benchmark_100_$i.toml" <<EOF
name="benchmark-module-100-$i"
version="1.0.$i"
description="Module $i for stress benchmarking"
type="module"

[files]
"config$i.conf" = "~/.config/app$i/config.conf"
"style$i.css" = "~/.config/app$i/style.css"
"data$i.json" = "~/.config/app$i/data.json"

[events.pre_install]
install$i = "echo 'Installing module $i'"
setup$i = "echo 'Setting up module $i'"
prepare$i = "echo 'Preparing module $i'"

[events.post_install]
notify$i = "echo 'Done with module $i'"
cleanup$i = "echo 'Cleaning up module $i'"
EOF
    done
}

# Setup function to run before each benchmark
set_up() {
    TEST_DIR="$TEST_BASE_DIR/$(date +%s%N)"
    export TEST_DIR
    mkdir -p "$TEST_DIR"

    # Create temporary directories for dk_toml benchmarks
    DK_DOTFILE="$TEST_DIR/dotfile"
    DK_PROFILE="$TEST_DIR/profile"
    mkdir -p "$DK_DOTFILE"
    mkdir -p "$DK_PROFILE"
    
    export DK_DOTFILE DK_PROFILE

    # Clear TOML cache before each benchmark
    dk_toml_clear_cache
}

# Teardown function to run after each benchmark
tear_down() {
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
    dk_toml_clear_cache
}

# Global teardown for all benchmarks
tear_down_after_script() {
    [[ -n "$TEST_BASE_DIR" ]] && rm -rf "$TEST_BASE_DIR"
    rm -rf "$DOTKIT_ROOT/.test_temp"
    unset TEST_BASE_DIR
    unset FIXTURES_DIR
}

# Benchmark: dk_toml_validate - single file validation
# @revs=1 @its=100
function bench_dk_toml_validate_single() {
    set_up
    
    local test_file="$TEST_DIR/test.toml"
    cp "$FIXTURES_DIR/benchmark.toml" "$test_file"
    
    dk_toml_validate "$test_file"
    
    tear_down
}

# Benchmark: dk_toml_find_all - single file discovery
# @revs=1 @its=100
function bench_dk_toml_find_all_single() {
    set_up
    
    cp "$FIXTURES_DIR/benchmark.toml" "$DK_DOTFILE/dotkit.toml"
    
    dk_toml_find_all >/dev/null
    
    tear_down
}

# Benchmark: dk_toml_find_all - 10 files discovery
# @revs=1 @its=10
function bench_dk_toml_find_all_10() {
    set_up
    
    local i
    for i in $(seq 1 10); do
        mkdir -p "$DK_DOTFILE/modules/mod$i"
        cp "$FIXTURES_DIR/benchmark_$i.toml" "$DK_DOTFILE/modules/mod$i/dotkit.toml"
    done
    
    dk_toml_find_all >/dev/null
    
    tear_down
}

# Benchmark: dk_toml_find_all - 100 files discovery
# @revs=1 @its=10
function bench_dk_toml_find_all_100() {
    set_up
    
    local i
    for i in $(seq 1 100); do
        mkdir -p "$DK_DOTFILE/modules/mod$i"
        cp "$FIXTURES_DIR/benchmark_100_$i.toml" "$DK_DOTFILE/modules/mod$i/dotkit.toml"
    done
    
    dk_toml_find_all >/dev/null
    
    tear_down
}

# Benchmark: dk_toml_load_all - single file processing
# @revs=1 @its=50
function bench_dk_toml_load_all_single() {
    set_up
    
    cp "$FIXTURES_DIR/benchmark.toml" "$DK_DOTFILE/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    
    tear_down
}

# Benchmark: dk_toml_load_all - 10 files processing
# @revs=1 @its=10
function bench_dk_toml_load_all_10() {
    set_up
    
    local i
    for i in $(seq 1 10); do
        mkdir -p "$DK_DOTFILE/modules/mod$i"
        cp "$FIXTURES_DIR/benchmark_$i.toml" "$DK_DOTFILE/modules/mod$i/dotkit.toml"
    done
    
    dk_toml_load_all >/dev/null 2>&1
    
    tear_down
}

# Benchmark: dk_toml_load_all - 100 files processing
# @revs=1 @its=10
function bench_dk_toml_load_all_100() {
    set_up
    
    local i
    for i in $(seq 1 100); do
        mkdir -p "$DK_DOTFILE/modules/mod$i"
        cp "$FIXTURES_DIR/benchmark_100_$i.toml" "$DK_DOTFILE/modules/mod$i/dotkit.toml"
    done
    
    dk_toml_load_all >/dev/null 2>&1
    
    tear_down
}

# Benchmark: dk_toml_batch_validate - 10 files validation
# @revs=1 @its=25
function bench_dk_toml_batch_validate_10() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 10); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_validate "${toml_files[@]}"
    
    tear_down
}

# Benchmark: dk_toml_batch_validate - 100 files validation
# @revs=1 @its=10
function bench_dk_toml_batch_validate_100() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 100); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_100_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_validate "${toml_files[@]}"
    
    tear_down
}

# Benchmark: dk_toml_batch_get_metadata - 10 files
# @revs=1 @its=25
function bench_dk_toml_batch_get_metadata_10() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 10); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_get_metadata "${toml_files[@]}"
    
    tear_down
}

# Benchmark: dk_toml_batch_get_metadata - 100 files
# @revs=1 @its=10
function bench_dk_toml_batch_get_metadata_100() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 100); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_100_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_get_metadata "${toml_files[@]}"
    
    tear_down
}

# Benchmark: dk_toml_batch_get_files - 10 files
# @revs=1 @its=25
function bench_dk_toml_batch_get_files_10() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 10); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_get_files "${toml_files[@]}"
    
    tear_down
}

# Benchmark: dk_toml_batch_get_files - 100 files
# @revs=1 @its=10
function bench_dk_toml_batch_get_files_100() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 100); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_100_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_get_files "${toml_files[@]}"
    
    tear_down
}

# Benchmark: dk_toml_batch_get_events - 10 files
# @revs=1 @its=25
function bench_dk_toml_batch_get_events_10() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 10); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_get_events "${toml_files[@]}"
    
    tear_down
}

# Benchmark: dk_toml_batch_get_events - 100 files
# @revs=1 @its=10
function bench_dk_toml_batch_get_events_100() {
    set_up
    
    local i
    local -a toml_files=()
    for i in $(seq 1 100); do
        local test_file="$TEST_DIR/test_$i.toml"
        cp "$FIXTURES_DIR/benchmark_100_$i.toml" "$test_file"
        toml_files+=("$test_file")
    done
    
    dk_toml_batch_get_events "${toml_files[@]}"
    
    tear_down
}

# Benchmark: Accessor functions after loading - 100 files
# @revs=1 @its=10
function bench_dk_toml_accessors_100() {
    set_up
    
    local i
    for i in $(seq 1 100); do
        mkdir -p "$DK_DOTFILE/modules/mod$i"
        cp "$FIXTURES_DIR/benchmark_100_$i.toml" "$DK_DOTFILE/modules/mod$i/dotkit.toml"
    done
    
    # Load all data first
    dk_toml_load_all >/dev/null 2>&1
    
    # Benchmark accessor functions
    dk_toml_get_all_metadata >/dev/null
    dk_toml_get_all_file_mappings >/dev/null
    dk_toml_get_events_by_type "pre_install" >/dev/null
    dk_toml_count_files >/dev/null
    
    tear_down
}
