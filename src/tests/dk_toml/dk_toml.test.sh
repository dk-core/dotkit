#!/usr/bin/env bash

# Global setup for all tests
set_up_before_script() {
    # Create a temporary directory for all tests
    mkdir -p "$DOTKIT_ROOT/.test_temp"
    sleep 0.1 # Wait for temp dir to be created
    TEST_BASE_DIR="$(mktemp -d "$DOTKIT_ROOT/.test_temp/test.XXXXXX")"
    export TEST_BASE_DIR

    sleep 0.1 # Wait for temp dir to be created
    
    # Create test fixtures directory
    TEST_FIXTURES_DIR="$TEST_BASE_DIR/test_fixtures"
    mkdir -p "$TEST_FIXTURES_DIR"
    export TEST_FIXTURES_DIR
    
    # Pre-create 100 test TOML files for stress testing
    for i in $(seq 1 100); do
        cat > "$TEST_FIXTURES_DIR/stress_test_$i.toml" <<EOF
name="mod$i"
version="1.0.0"
description="Module $i for stress testing"
type="module"

[files]
"config$i.conf" = "~/.config/app$i/config.conf"

[events.pre_install]
install$i = "echo 'Installing module $i'"
EOF
    done
    
    # Disable interactive prompts for testing
    export DEBIAN_FRONTEND=noninteractive
}

# Setup function to run before each test
set_up() {
    TEST_DIR="$TEST_BASE_DIR/$(date +%s%N)"
    export TEST_DIR
    mkdir -p "$TEST_DIR"

    # Create temporary directories for dk_toml tests
    DK_DOTFILE="$TEST_DIR/dotfile"
    DK_PROFILE="$TEST_DIR/profile"
    mkdir -p "$DK_DOTFILE"
    mkdir -p "$DK_PROFILE"
    
    export DK_DOTFILE DK_PROFILE

    # Get paths for testing relative to the test file
    TEST_FILE_DIR="$(dirname "${BASH_SOURCE[0]}")"
    export FIXTURES_DIR="$TEST_FILE_DIR/fixtures"

    # Clear TOML cache before each test
    dk_toml_clear_cache
}

# Teardown function to run after each test
tear_down() {
    rm -rf "$DK_DOTFILE" "$DK_PROFILE"
    unset DK_DOTFILE
    unset DK_PROFILE
    unset TEST_DIR
    unset FIXTURES_DIR
}

# Global teardown for all tests
tear_down_after_script() {
    [[ -n "$TEST_BASE_DIR" ]] && rm -rf "$TEST_BASE_DIR"
    rm -rf "$DOTKIT_ROOT/.test_temp"
    unset TEST_BASE_DIR
    unset TEST_FIXTURES_DIR
    unset DEBIAN_FRONTEND
}

# Discovery Tests
test_dk_toml_find_all_discovers_dotfile_toml() {
    # Create dotfile TOML
    cp "$FIXTURES_DIR/valid/simple-dotfile.toml" "$DK_DOTFILE/dotkit.toml"
    
    local -a found_files
    mapfile -t found_files < <(dk_toml_find_all)
    
    assert_equals 1 "${#found_files[@]}"
    assert_equals "$DK_DOTFILE/dotkit.toml" "${found_files[0]}"
}

test_dk_toml_find_all_discovers_dotfile_module_tomls() {
    # Create dotfile modules
    mkdir -p "$DK_DOTFILE/modules/mod1" "$DK_DOTFILE/modules/mod2"
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    cp "$FIXTURES_DIR/valid/minimal-profile.toml" "$DK_DOTFILE/modules/mod2/dotkit.toml"
    
    local -a found_files
    mapfile -t found_files < <(dk_toml_find_all)
    
    assert_equals 2 "${#found_files[@]}"
    # Files should be found in glob order
    echo "${found_files[@]}" | grep -q "$DK_DOTFILE/modules/mod1/dotkit.toml"
    assert_equals 0 "$?"
    echo "${found_files[@]}" | grep -q "$DK_DOTFILE/modules/mod2/dotkit.toml"
    assert_equals 0 "$?"
}

test_dk_toml_find_all_discovers_profile_toml() {
    # Create profile TOML
    cp "$FIXTURES_DIR/valid/minimal-profile.toml" "$DK_PROFILE/dotkit.toml"
    
    local -a found_files
    mapfile -t found_files < <(dk_toml_find_all)
    
    assert_equals 1 "${#found_files[@]}"
    assert_equals "$DK_PROFILE/dotkit.toml" "${found_files[0]}"
}

test_dk_toml_find_all_discovers_profile_module_tomls() {
    # Create profile modules
    mkdir -p "$DK_PROFILE/modules/mod1" "$DK_PROFILE/modules/mod2"
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_PROFILE/modules/mod1/dotkit.toml"
    cp "$FIXTURES_DIR/valid/simple-dotfile.toml" "$DK_PROFILE/modules/mod2/dotkit.toml"
    
    local -a found_files
    mapfile -t found_files < <(dk_toml_find_all)
    
    assert_equals 2 "${#found_files[@]}"
    echo "${found_files[@]}" | grep -q "$DK_PROFILE/modules/mod1/dotkit.toml"
    assert_equals 0 "$?"
    echo "${found_files[@]}" | grep -q "$DK_PROFILE/modules/mod2/dotkit.toml"
    assert_equals 0 "$?"
}

test_dk_toml_find_all_discovers_all_locations() {
    # Create TOML files in all locations
    cp "$FIXTURES_DIR/valid/simple-dotfile.toml" "$DK_DOTFILE/dotkit.toml"
    mkdir -p "$DK_DOTFILE/modules/mod1"
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    
    cp "$FIXTURES_DIR/valid/minimal-profile.toml" "$DK_PROFILE/dotkit.toml"
    mkdir -p "$DK_PROFILE/modules/mod2"
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_PROFILE/modules/mod2/dotkit.toml"
    
    local -a found_files
    mapfile -t found_files < <(dk_toml_find_all)
    
    assert_equals 4 "${#found_files[@]}"
    # Check that all expected files are found
    echo "${found_files[@]}" | grep -q "$DK_DOTFILE/dotkit.toml"
    assert_equals 0 "$?"
    echo "${found_files[@]}" | grep -q "$DK_DOTFILE/modules/mod1/dotkit.toml"
    assert_equals 0 "$?"
    echo "${found_files[@]}" | grep -q "$DK_PROFILE/dotkit.toml"
    assert_equals 0 "$?"
    echo "${found_files[@]}" | grep -q "$DK_PROFILE/modules/mod2/dotkit.toml"
    assert_equals 0 "$?"
}

test_dk_toml_find_all_handles_no_files_gracefully() {
    # No TOML files created
    local -a found_files
    mapfile -t found_files < <(dk_toml_find_all)
    
    assert_equals 0 "${#found_files[@]}"
}

# Validation Tests
test_dk_toml_validate_accepts_valid_toml() {
    local test_file="$TEST_DIR/valid.toml"
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$test_file"
    
    dk_toml_validate "$test_file"
    assert_equals 0 "$?"
}

test_dk_toml_validate_rejects_malformed_toml() {
    local test_file="$TEST_DIR/invalid.toml"
    cp "$FIXTURES_DIR/invalid/malformed-syntax.toml" "$test_file"
    
    dk_toml_validate "$test_file" >/dev/null 2>&1
    assert_equals 1 "$?"
}

test_dk_toml_validate_rejects_missing_name_field() {
    local test_file="$TEST_DIR/missing_name.toml"
    echo 'type="module"' > "$test_file"
    
    dk_toml_validate "$test_file" >/dev/null 2>&1
    assert_equals 1 "$?"
}

test_dk_toml_validate_rejects_missing_type_field() {
    local test_file="$TEST_DIR/missing_type.toml"
    echo 'name="test"' > "$test_file"
    
    dk_toml_validate "$test_file" >/dev/null 2>&1
    assert_equals 1 "$?"
}

test_dk_toml_validate_rejects_nonexistent_file() {
    dk_toml_validate "/nonexistent/file.toml" >/dev/null 2>&1
    assert_equals 1 "$?"
}

# Batch Processing Tests
test_dk_toml_load_all_processes_valid_files() {
    # Create valid TOML files
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    mkdir -p "$DK_DOTFILE/modules/mod1"
    cp "$FIXTURES_DIR/valid/simple-dotfile.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    
    dk_toml_load_all
    assert_equals 0 "$?"
    
    # Verify files were discovered
    local count
    count=$(dk_toml_count_files)
    assert_equals 2 "$count"
}

test_dk_toml_load_all_fails_on_invalid_files() {
    # Create invalid TOML file
    cp "$FIXTURES_DIR/invalid/malformed-syntax.toml" "$DK_DOTFILE/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    assert_equals 1 "$?"
}

test_dk_toml_load_all_handles_mixed_valid_invalid_files() {
    # Create mix of valid and invalid files
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    mkdir -p "$DK_DOTFILE/modules/mod1"
    cp "$FIXTURES_DIR/invalid/malformed-syntax.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    assert_equals 1 "$?"
}

# Metadata Extraction Tests
test_dk_toml_batch_get_metadata_extracts_all_fields() {
    # Create TOML file and load it
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    dk_toml_load_all >/dev/null 2>&1
    
    local metadata
    metadata=$(dk_toml_get_metadata "$DK_DOTFILE/dotkit.toml")
    
    echo "$metadata" | grep -q "name=waybar-module"
    assert_equals 0 "$?"
    echo "$metadata" | grep -q "version=0.1.0"
    assert_equals 0 "$?"
    echo "$metadata" | grep -q "type=module"
    assert_equals 0 "$?"
}

test_dk_toml_get_all_metadata_returns_all_files() {
    # Create multiple TOML files
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    mkdir -p "$DK_DOTFILE/modules/mod1"
    cp "$FIXTURES_DIR/valid/simple-dotfile.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    
    local -a all_metadata
    mapfile -t all_metadata < <(dk_toml_get_all_metadata)
    
    assert_equals 2 "${#all_metadata[@]}"
    echo "${all_metadata[@]}" | grep -q "waybar-module"
    assert_equals 0 "$?"
    echo "${all_metadata[@]}" | grep -q "simple-dotfile"
    assert_equals 0 "$?"
}

# File Mappings Tests
test_dk_toml_batch_get_files_extracts_file_mappings() {
    # Create TOML file with file mappings
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    dk_toml_load_all >/dev/null 2>&1
    
    local files
    files=$(dk_toml_get_files "$DK_DOTFILE/dotkit.toml")
    
    echo "$files" | grep -q "waybar/config"
    assert_equals 0 "$?"
    echo "$files" | grep -q "waybar/style.css"
    assert_equals 0 "$?"
}

test_dk_toml_get_all_file_mappings_returns_all_mappings() {
    # Create multiple TOML files with file mappings
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    mkdir -p "$DK_DOTFILE/modules/mod1"
    cp "$FIXTURES_DIR/valid/simple-dotfile.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    
    local -a all_files
    mapfile -t all_files < <(dk_toml_get_all_file_mappings)
    
    assert_equals 2 "${#all_files[@]}"
    echo "${all_files[@]}" | grep -q "waybar/config"
    assert_equals 0 "$?"
    echo "${all_files[@]}" | grep -q ".zshrc"
    assert_equals 0 "$?"
}

# Events Tests
test_dk_toml_batch_get_events_extracts_events() {
    # Create TOML file with events
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    dk_toml_load_all >/dev/null 2>&1
    
    local events
    events=$(dk_toml_get_events "$DK_DOTFILE/dotkit.toml")
    
    echo "$events" | grep -q "pre_install"
    assert_equals 0 "$?"
    echo "$events" | grep -q "post_set"
    assert_equals 0 "$?"
}

test_dk_toml_get_events_by_type_filters_correctly() {
    # Create TOML file with multiple event types
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    dk_toml_load_all >/dev/null 2>&1
    
    local pre_install_events
    mapfile -t pre_install_events < <(dk_toml_get_events_by_type "pre_install")
    
    assert_equals 1 "${#pre_install_events[@]}"
    echo "${pre_install_events[0]}" | grep -q "pre_install"
    assert_equals 0 "$?"
}

# Error Collection Tests
test_dk_toml_batch_validate_collects_multiple_errors() {
    # Create multiple invalid TOML files
    cp "$FIXTURES_DIR/invalid/malformed-syntax.toml" "$DK_DOTFILE/dotkit.toml"
    mkdir -p "$DK_DOTFILE/modules/mod1"
    cp "$FIXTURES_DIR/invalid/missing-required-fields.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    
    # Should have collected multiple errors
    assert_equals 1 "$?"
}

# Warning Tests
test_dk_toml_batch_validate_collects_warnings_for_unknown_type() {
    # Create TOML with unknown type (should warn but not error)
    cp "$FIXTURES_DIR/invalid/unknown-type.toml" "$DK_DOTFILE/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    
    # Should succeed but generate warnings
    assert_equals 0 "$?"
}

# Utility Functions Tests
test_dk_toml_clear_cache_clears_all_data() {
    # Load some data first
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    dk_toml_load_all >/dev/null 2>&1
    
    # Verify data exists
    local count
    count=$(dk_toml_count_files)
    assert_equals 1 "$count"
    
    # Clear cache
    dk_toml_clear_cache
    
    # Verify data is cleared
    count=$(dk_toml_count_files)
    assert_equals 0 "$count"
}

test_dk_toml_list_discovered_files_returns_file_list() {
    # Create TOML files
    cp "$FIXTURES_DIR/valid/waybar-module.toml" "$DK_DOTFILE/dotkit.toml"
    mkdir -p "$DK_DOTFILE/modules/mod1"
    cp "$FIXTURES_DIR/valid/simple-dotfile.toml" "$DK_DOTFILE/modules/mod1/dotkit.toml"
    
    dk_toml_load_all >/dev/null 2>&1
    
    local -a file_list
    mapfile -t file_list < <(dk_toml_list_discovered_files)
    
    assert_equals 2 "${#file_list[@]}"
    echo "${file_list[@]}" | grep -q "$DK_DOTFILE/dotkit.toml"
    assert_equals 0 "$?"
}

# Stress Test - 100 modules (using pre-created fixtures for accurate timing)
test_dk_toml_load_all_with_100_modules() {
    local i
    
    # Copy pre-created fixtures instead of generating on-the-fly
    for i in $(seq 1 100); do
        mkdir -p "$DK_DOTFILE/modules/mod$i"
        cp "$TEST_FIXTURES_DIR/stress_test_$i.toml" "$DK_DOTFILE/modules/mod$i/dotkit.toml"
    done
    
    dk_toml_load_all >/dev/null 2>&1
    assert_equals 0 "$?"
    
    # Verify all files were processed
    local count
    count=$(dk_toml_count_files)
    assert_equals 100 "$count"
    
    # Verify metadata was extracted for all files
    local -a all_metadata
    mapfile -t all_metadata < <(dk_toml_get_all_metadata)
    assert_equals 100 "${#all_metadata[@]}"
}
