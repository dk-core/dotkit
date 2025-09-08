#!/usr/bin/env bash
# test_ln.sh - Comprehensive tests for dk_link command

# Global setup for all tests
set_up_before_script() {
    # Create a temporary directory for all tests
    mkdir -p "$DOTKIT_ROOT/.test_temp"
    sleep 0.1 # Wait for temp dir to be created
    TEST_BASE_DIR="$(mktemp -d "$DOTKIT_ROOT/.test_temp/test.XXXXXX")"
    export TEST_BASE_DIR

    sleep 0.1 # Wait for temp dir to be created
    
    # Disable interactive prompts for testing
    export DEBIAN_FRONTEND=noninteractive
}

# Setup for individual test files
set_up() {
    # Create a unique test directory for each test file
    TEST_DIR="$TEST_BASE_DIR/$(date +%s%N)"
    export TEST_DIR
    mkdir -p "$TEST_DIR"

    # Get paths for testing relative to the test file
    TEST_FILE_DIR="$(dirname "${BASH_SOURCE[0]}")"

    log "TEST_FILE_DIR: $TEST_FILE_DIR"

    # Define FIXTURES_DIR relative to the test file's directory
    export FIXTURES_DIR="$TEST_FILE_DIR/fixtures"
}

tear_down() {
    # Clean up the unique test directory for this test file
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
    unset TEST_DIR
    unset TEST_FILE_DIR
    unset FIXTURES_DIR
}


# Global teardown for all tests
tear_down_after_script() {
    [[ -n "$TEST_BASE_DIR" ]] && rm -rf "$TEST_BASE_DIR"
    rm -rf "$DOTKIT_ROOT/.test_temp"
    unset TEST_DIR
    unset TEST_BASE_DIR
    unset FIXTURES_DIR
    unset DEBIAN_FRONTEND
}

# Source Validation Tests
test_rejects_nonexistent_sources() {
    dk_link "/nonexistent/file.conf" "$TEST_DIR/app1/config.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
}

test_rejects_multiple_nonexistent_sources() {
    
    dk_link "/nonexistent1.conf" "$TEST_DIR/app1/config1.conf" "/nonexistent2.conf" "$TEST_DIR/app1/config2.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
    
}

test_accepts_existing_sources() {
    
    dk_link "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_DIR/app1/config.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
}

# Target Conflict Tests
test_exits_on_existing_file_conflict() {
    
    # Create existing file
    create_test_file "$TEST_DIR/app1/existing.conf" "existing content"
    
    dk_link "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_DIR/app1/existing.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
    
    # Verify original file is unchanged
    [[ -f "$TEST_DIR/app1/existing.conf" && ! -L "$TEST_DIR/app1/existing.conf" ]]
    local file_check_result=$?
    assert_equals 0 "$file_check_result"
    
}

test_prompts_for_existing_symlink_overwrite() {
    mock_gum_yes
    
    # Create existing symlink within config home
    create_test_symlink "$TEST_DIR/old_target" "$TEST_DIR/app1/existing.conf"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_DIR/source.conf" "test content"
    
    dk_link "$TEST_DIR/source.conf" "$TEST_DIR/app1/existing.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
    # Verify symlink was updated
    local link_target
    link_target=$(readlink "$TEST_DIR/app1/existing.conf")
    assert_equals "$TEST_DIR/source.conf" "$link_target"
    
}

test_exits_when_user_declines_symlink_overwrite() {
    mock_gum_no
    
    # Create existing symlink within config home
    create_test_symlink "$TEST_DIR/old_target" "$TEST_DIR/app1/existing.conf"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_DIR/source.conf" "test content"
    
    dk_link "$TEST_DIR/source.conf" "$TEST_DIR/app1/existing.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 125 "$result"
    
    # Verify original symlink is unchanged
    local link_target
    link_target=$(readlink "$TEST_DIR/app1/existing.conf")
    assert_equals "$TEST_DIR/old_target" "$link_target"
    
}

# Enhanced Test 4.1: Multiple file conflicts
test_exits_on_multiple_existing_file_conflicts() {
    
    # Create multiple existing files
    create_test_file "$TEST_DIR/app1/existing1.conf" "existing content 1"
    create_test_file "$TEST_DIR/app1/existing2.conf" "existing content 2"
    create_test_file "$TEST_DIR/app2/existing3.conf" "existing content 3"
    
    # Create source files within config home for this test
    create_test_file "$TEST_DIR/source1.conf" "test content 1"
    create_test_file "$TEST_DIR/source2.conf" "test content 2"
    create_test_file "$TEST_DIR/source3.conf" "test content 3"
    
    dk_link \
        "$TEST_DIR/source1.conf" "$TEST_DIR/app1/existing1.conf" \
        "$TEST_DIR/source2.conf" "$TEST_DIR/app1/existing2.conf" \
        "$TEST_DIR/source3.conf" "$TEST_DIR/app2/existing3.conf" \
        >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
    
    # Verify original files are unchanged
    [[ -f "$TEST_DIR/app1/existing1.conf" && ! -L "$TEST_DIR/app1/existing1.conf" ]]
    local file_check_result1=$?
    assert_equals 0 "$file_check_result1"
    [[ -f "$TEST_DIR/app1/existing2.conf" && ! -L "$TEST_DIR/app1/existing2.conf" ]]
    local file_check_result2=$?
    assert_equals 0 "$file_check_result2"
    [[ -f "$TEST_DIR/app2/existing3.conf" && ! -L "$TEST_DIR/app2/existing3.conf" ]]
    local file_check_result3=$?
    assert_equals 0 "$file_check_result3"
    
}

# Enhanced Test 4.2: Multiple symlink conflicts
test_handles_multiple_existing_symlink_conflicts() {
    mock_gum_yes
    
    # Create multiple existing symlinks within config home
    create_test_symlink "$TEST_DIR/old_target1" "$TEST_DIR/app1/existing1.conf"
    create_test_symlink "$TEST_DIR/old_target2" "$TEST_DIR/app1/existing2.conf"
    create_test_symlink "$TEST_DIR/old_target3" "$TEST_DIR/app2/existing3.conf"
    
    # Create source files within config home for this test
    create_test_file "$TEST_DIR/source1.conf" "test content 1"
    create_test_file "$TEST_DIR/source2.conf" "test content 2"
    create_test_file "$TEST_DIR/source3.conf" "test content 3"
    
    dk_link \
        "$TEST_DIR/source1.conf" "$TEST_DIR/app1/existing1.conf" \
        "$TEST_DIR/source2.conf" "$TEST_DIR/app1/existing2.conf" \
        "$TEST_DIR/source3.conf" "$TEST_DIR/app2/existing3.conf" \
        >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
    # Verify all symlinks were updated
    local link_target1 link_target2 link_target3
    link_target1=$(readlink "$TEST_DIR/app1/existing1.conf")
    link_target2=$(readlink "$TEST_DIR/app1/existing2.conf")
    link_target3=$(readlink "$TEST_DIR/app2/existing3.conf")
    assert_equals "$TEST_DIR/source1.conf" "$link_target1"
    assert_equals "$TEST_DIR/source2.conf" "$link_target2"
    assert_equals "$TEST_DIR/source3.conf" "$link_target3"
    
}

test_exits_when_user_declines_multiple_symlink_overwrite() {
    mock_gum_no
    
    # Create multiple existing symlinks within config home
    create_test_symlink "$TEST_DIR/old_target1" "$TEST_DIR/app1/existing1.conf"
    create_test_symlink "$TEST_DIR/old_target2" "$TEST_DIR/app1/existing2.conf"
    create_test_symlink "$TEST_DIR/old_target3" "$TEST_DIR/app2/existing3.conf"
    
    # Create source files within config home for this test
    create_test_file "$TEST_DIR/source1.conf" "test content 1"
    create_test_file "$TEST_DIR/source2.conf" "test content 2"
    create_test_file "$TEST_DIR/source3.conf" "test content 3"
    
    dk_link \
        "$TEST_DIR/source1.conf" "$TEST_DIR/app1/existing1.conf" \
        "$TEST_DIR/source2.conf" "$TEST_DIR/app1/existing2.conf" \
        "$TEST_DIR/source3.conf" "$TEST_DIR/app2/existing3.conf" \
        >/dev/null 2>&1
    local result=$?
    assert_equals 125 "$result"
    
    # Verify original symlinks are unchanged
    local link_target1 link_target2 link_target3
    link_target1=$(readlink "$TEST_DIR/app1/existing1.conf")
    link_target2=$(readlink "$TEST_DIR/app1/existing2.conf")
    link_target3=$(readlink "$TEST_DIR/app2/existing3.conf")
    assert_equals "$TEST_DIR/old_target1" "$link_target1"
    assert_equals "$TEST_DIR/old_target2" "$link_target2"
    assert_equals "$TEST_DIR/old_target3" "$link_target3"
    
}

# Mixed conflict test - file conflicts always cause exit 1
test_exits_on_mixed_file_and_symlink_conflicts() {
    
    # Create a mix of existing files and symlinks
    create_test_file "$TEST_DIR/app1/existing_file1.conf" "existing content 1"
    create_test_symlink "$TEST_DIR/old_target1" "$TEST_DIR/app1/existing_symlink1.conf"
    create_test_file "$TEST_DIR/app2/existing_file2.conf" "existing content 2"
    create_test_symlink "$TEST_DIR/old_target2" "$TEST_DIR/app2/existing_symlink2.conf"
    
    # Create source files within config home for this test
    create_test_file "$TEST_DIR/source1.conf" "test content 1"
    create_test_file "$TEST_DIR/source2.conf" "test content 2"
    create_test_file "$TEST_DIR/source3.conf" "test content 3"
    create_test_file "$TEST_DIR/source4.conf" "test content 4"
    
    dk_link \
        "$TEST_DIR/source1.conf" "$TEST_DIR/app1/existing_file1.conf" \
        "$TEST_DIR/source2.conf" "$TEST_DIR/app1/existing_symlink1.conf" \
        "$TEST_DIR/source3.conf" "$TEST_DIR/app2/existing_file2.conf" \
        "$TEST_DIR/source4.conf" "$TEST_DIR/app2/existing_symlink2.conf" \
        >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
    
    # Verify original files/symlinks are unchanged
    [[ -f "$TEST_DIR/app1/existing_file1.conf" && ! -L "$TEST_DIR/app1/existing_file1.conf" ]]
    local file_check_result1=$?
    assert_equals 0 "$file_check_result1"
    [[ -L "$TEST_DIR/app1/existing_symlink1.conf" ]]
    local symlink_check_result1=$?
    assert_equals 0 "$symlink_check_result1"
    local link_target
    link_target=$(readlink "$TEST_DIR/app1/existing_symlink1.conf")
    assert_equals "$TEST_DIR/old_target1" "$link_target"
    [[ -f "$TEST_DIR/app2/existing_file2.conf" && ! -L "$TEST_DIR/app2/existing_file2.conf" ]]
    local file_check_result2=$?
    assert_equals 0 "$file_check_result2"
    
}

# Successful Operation Tests
test_creates_single_symlink() {
    
    dk_link "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_DIR/app1/config.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
    # Verify symlink was created correctly
    if [[ -L "$TEST_DIR/app1/config.conf" ]]; then
        assert_equals 0 0
    else
        assert_equals 0 1
    fi
    local link_target
    link_target=$(readlink "$TEST_DIR/app1/config.conf")
    assert_equals "$FIXTURES_DIR/test_sources/config1.conf" "$link_target"
    
}

test_creates_multiple_symlinks() {
    
    dk_link \
        "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_DIR/app1/config1.conf" \
        "$FIXTURES_DIR/test_sources/config2.conf" "$TEST_DIR/app2/config2.conf" \
        >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
    # Verify both symlinks were created
    [[ -L "$TEST_DIR/app1/config1.conf" ]]
    local symlink_check_result1=$?
    assert_equals 0 "$symlink_check_result1"
    [[ -L "$TEST_DIR/app2/config2.conf" ]]
    local symlink_check_result2=$?
    assert_equals 0 "$symlink_check_result2"
    
}

test_creates_target_directories() {
    
    dk_link "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_DIR/new_app/subdir/config.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
    # Verify directory was created and symlink exists
    [[ -d "$TEST_DIR/new_app/subdir" ]]
    local dir_check_result=$?
    assert_equals 0 "$dir_check_result"
    [[ -L "$TEST_DIR/new_app/subdir/config.conf" ]]
    local symlink_check_result=$?
    assert_equals 0 "$symlink_check_result"
    
}

# Edge Cases
test_rejects_empty_arguments() {
    
    dk_link >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
    
}

test_rejects_odd_number_of_arguments() {
    
    dk_link "$FIXTURES_DIR/test_sources/config1.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
    
}

test_handles_broken_symlink_targets() {
    mock_gum_yes
    
    # Create symlink to non-existent target within config home
    create_test_symlink "$TEST_DIR/nonexistent/target" "$TEST_DIR/app1/broken.conf"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_DIR/source.conf" "test content"
    
    dk_link "$TEST_DIR/source.conf" "$TEST_DIR/app1/broken.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
    # Verify symlink was updated
    local link_target
    link_target=$(readlink "$TEST_DIR/app1/broken.conf")
    assert_equals "$TEST_DIR/source.conf" "$link_target"
    
}

# TODO: assoicative arrays
# # Associative Array Tests (bash 4+)
# test_associative_array_function() {
#   
    
#     # Skip if bash version < 4
#     if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
#         skip "Associative arrays require bash 4+"
#         return
#     fi
    
#     # Create source files within config home for this test
#     create_test_file "$TEST_DIR/source1.conf" "test content 1"
#     create_test_file "$TEST_DIR/source2.conf" "test content 2"
    
#     # shellcheck disable=SC2034  # symlink_map is used by name in dokit_safe_symlink_array
#     declare -A symlink_map=(
#         ["$TEST_DIR/source1.conf"]="$TEST_DIR/app1/config1.conf"
#         ["$TEST_DIR/source2.conf"]="$TEST_DIR/app2/config2.conf"
#     )
    
#     dk_link symlink_map >/dev/null 2>&1
#     assert_equals 0 $?
    
#     # Verify both symlinks were created
#     [[ -L "$TEST_DIR/app1/config1.conf" ]]
#     assert_equals 0 $?
#     [[ -L "$TEST_DIR/app2/config2.conf" ]]
#     assert_equals 0 $?
    
#   
# }

# Fallback Tests (when gum is not available)
test_fallback_prompt_yes() {
    mock_gum_missing
    
    # Create a source file within config home for this test
    create_test_file "$TEST_DIR/source.conf" "test content"
    
    # Test without conflicts (no prompt needed) - this tests that the function works when gum is missing
    dk_link "$TEST_DIR/source.conf" "$TEST_DIR/app1/new.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 0 "$result"
    
    # Verify symlink was created
    [[ -L "$TEST_DIR/app1/new.conf" ]]
    local symlink_check_result=$?
    assert_equals 0 "$symlink_check_result"
    
}

test_fallback_exits_on_file_conflict() {
    mock_gum_missing
    
    # Create existing file
    create_test_file "$TEST_DIR/app1/existing.conf" "existing content"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_DIR/source.conf" "test content"
    
    # File conflicts always exit with code 1, no user prompt
    dk_link "$TEST_DIR/source.conf" "$TEST_DIR/app1/existing.conf" >/dev/null 2>&1
    local result=$?
    assert_equals 1 "$result"
    
}

# Debug Mode Tests
test_debug_mode_logging() {
    
    export dokit_DEBUG=1
    
    # Capture debug output
    local output
    # shellcheck disable=SC2034
    output=$(dk_link "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_DIR/app1/config.conf" 2>&1)
    
    # Debug output goes to logger, so we just verify the function succeeds
    local result=$?
    assert_equals 0 "$result"
    
    unset dokit_DEBUG
}

# The run_tests.sh script will handle calling bashunit
