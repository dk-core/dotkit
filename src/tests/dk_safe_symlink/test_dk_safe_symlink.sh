#!/usr/bin/env bash
# test_dk_safe_symlink.sh - Comprehensive tests for dk_safe_symlink function

#TODO: create a single test entry that sources dotkit
#TODO: fix tests

# Setup test environment
setup() {
    # Get absolute paths for testing
    TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Go up two levels from src/tests/dk_safe_symlink to get to src
    SRC_DIR="$(dirname "$(dirname "$TEST_DIR")")"
    FIXTURES_DIR="$TEST_DIR/fixtures"
    
    # Source the function under test
    # shellcheck disable=SC1091
    source "$SRC_DIR/lib/dk_safe_symlink.sh"
    
    # Create temporary test config directory
    TEST_CONFIG_HOME="$(mktemp -d)"
    export XDG_CONFIG_HOME="$TEST_CONFIG_HOME"
    
    # Create test directories
    mkdir -p "$TEST_CONFIG_HOME/app1"
    mkdir -p "$TEST_CONFIG_HOME/app2"
    mkdir -p "$FIXTURES_DIR/test_configs"
    
    # Disable interactive prompts for testing
    export DEBIAN_FRONTEND=noninteractive
}

# Cleanup after each test
teardown() {
    [[ -n "$TEST_CONFIG_HOME" ]] && rm -rf "$TEST_CONFIG_HOME"
    unset XDG_CONFIG_HOME
}

# Test helper functions
create_test_file() {
    local file="$1"
    local content="${2:-test content}"
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
}

create_test_symlink() {
    local target="$1"
    local link="$2"
    mkdir -p "$(dirname "$link")"
    ln -sf "$target" "$link"
}

# Mock gum to always return success (yes)
mock_gum_yes() {
    # shellcheck disable=SC2329
    gum() {
        # shellcheck disable=SC2317  # Function is called indirectly via export -f
        case "$1" in
            confirm) return 0 ;;
            *) command gum "$@" 2>/dev/null || true ;;
        esac
    }
    export -f gum
}

# Mock gum to always return failure (no)
mock_gum_no() {
    # shellcheck disable=SC2329
    gum() {
        # shellcheck disable=SC2317  # Function is called indirectly via export -f
        case "$1" in
            confirm) return 1 ;;
            *) command gum "$@" 2>/dev/null || true ;;
        esac
    }
    export -f gum
}

# Mock gum to not exist
mock_gum_missing() {
    # shellcheck disable=SC2329
    gum() {
        # shellcheck disable=SC2317  # Function is called indirectly via export -f
        return 127
    }
    export -f gum
}

# Security Tests
test_rejects_paths_outside_config_home() {
    setup
    
    # Test absolute path outside config home
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "/etc/test.conf" >/dev/null 2>&1
    assert_equals 1 $?
    
    # Test relative path that resolves outside config home
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "../../../etc/test.conf" >/dev/null 2>&1
    assert_equals 1 $?
    
    teardown
}

test_allows_paths_within_config_home() {
    setup
    
    # Test absolute path within config home
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/app1/config.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    # Test relative path within config home
    cd "$TEST_CONFIG_HOME" || exit
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config2.conf" "app2/config.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    teardown
}

# Source Validation Tests
test_rejects_nonexistent_sources() {
    setup
    
    dk_safe_symlink "/nonexistent/file.conf" "$TEST_CONFIG_HOME/app1/config.conf" >/dev/null 2>&1
    assert_equals 1 $?
    
    teardown
}

test_rejects_multiple_nonexistent_sources() {
    setup
    
    dk_safe_symlink "/nonexistent1.conf" "$TEST_CONFIG_HOME/app1/config1.conf" "/nonexistent2.conf" "$TEST_CONFIG_HOME/app1/config2.conf" >/dev/null 2>&1
    assert_equals 1 $?
    
    teardown
}

test_accepts_existing_sources() {
    setup
    
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/app1/config.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    teardown
}

# Target Conflict Tests
test_prompts_for_existing_file_overwrite() {
    setup
    mock_gum_yes
    
    # Create existing file
    create_test_file "$TEST_CONFIG_HOME/app1/existing.conf" "existing content"
    
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/app1/existing.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify symlink was created
    [[ -L "$TEST_CONFIG_HOME/app1/existing.conf" ]]
    assert_equals 0 $?
    
    teardown
}

test_exits_when_user_declines_file_overwrite() {
    setup
    mock_gum_no
    
    # Create existing file
    create_test_file "$TEST_CONFIG_HOME/app1/existing.conf" "existing content"
    
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/app1/existing.conf" >/dev/null 2>&1
    assert_equals 125 $?
    
    # Verify original file is unchanged
    [[ -f "$TEST_CONFIG_HOME/app1/existing.conf" && ! -L "$TEST_CONFIG_HOME/app1/existing.conf" ]]
    assert_equals 0 $?
    
    teardown
}

test_prompts_for_existing_symlink_overwrite() {
    setup
    mock_gum_yes
    
    # Create existing symlink within config home
    create_test_symlink "$TEST_CONFIG_HOME/old_target" "$TEST_CONFIG_HOME/app1/existing.conf"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_CONFIG_HOME/source.conf" "test content"
    
    dk_safe_symlink "$TEST_CONFIG_HOME/source.conf" "$TEST_CONFIG_HOME/app1/existing.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify symlink was updated
    local link_target
    link_target=$(readlink "$TEST_CONFIG_HOME/app1/existing.conf")
    assert_equals "$TEST_CONFIG_HOME/source.conf" "$link_target"
    
    teardown
}

test_exits_when_user_declines_symlink_overwrite() {
    setup
    mock_gum_no
    
    # Create existing symlink within config home
    create_test_symlink "$TEST_CONFIG_HOME/old_target" "$TEST_CONFIG_HOME/app1/existing.conf"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_CONFIG_HOME/source.conf" "test content"
    
    dk_safe_symlink "$TEST_CONFIG_HOME/source.conf" "$TEST_CONFIG_HOME/app1/existing.conf" >/dev/null 2>&1
    assert_equals 125 $?
    
    # Verify original symlink is unchanged
    local link_target
    link_target=$(readlink "$TEST_CONFIG_HOME/app1/existing.conf")
    assert_equals "$TEST_CONFIG_HOME/old_target" "$link_target"
    
    teardown
}

# Successful Operation Tests
test_creates_single_symlink() {
    setup
    
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/app1/config.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify symlink was created correctly
    if [[ -L "$TEST_CONFIG_HOME/app1/config.conf" ]]; then
        assert_equals 0 0
    else
        assert_equals 0 1
    fi
    local link_target
    link_target=$(readlink "$TEST_CONFIG_HOME/app1/config.conf")
    assert_equals "$FIXTURES_DIR/test_sources/config1.conf" "$link_target"
    
    teardown
}

test_creates_multiple_symlinks() {
    setup
    
    dk_safe_symlink \
        "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/app1/config1.conf" \
        "$FIXTURES_DIR/test_sources/config2.conf" "$TEST_CONFIG_HOME/app2/config2.conf" \
        >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify both symlinks were created
    [[ -L "$TEST_CONFIG_HOME/app1/config1.conf" ]]
    assert_equals 0 $?
    [[ -L "$TEST_CONFIG_HOME/app2/config2.conf" ]]
    assert_equals 0 $?
    
    teardown
}

test_creates_target_directories() {
    setup
    
    dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/new_app/subdir/config.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify directory was created and symlink exists
    [[ -d "$TEST_CONFIG_HOME/new_app/subdir" ]]
    assert_equals 0 $?
    [[ -L "$TEST_CONFIG_HOME/new_app/subdir/config.conf" ]]
    assert_equals 0 $?
    
    teardown
}

# Edge Cases
test_rejects_empty_arguments() {
    setup
    
    local result
    result=$(dk_safe_symlink 2>/dev/null; echo $?)
    assert_equals 1 "$result"
    
    teardown
}

test_rejects_odd_number_of_arguments() {
    setup
    
    local result
    result=$(dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" 2>/dev/null; echo $?)
    assert_equals 1 "$result"
    
    teardown
}

test_handles_broken_symlink_targets() {
    setup
    mock_gum_yes
    
    # Create symlink to non-existent target within config home
    create_test_symlink "$TEST_CONFIG_HOME/nonexistent/target" "$TEST_CONFIG_HOME/app1/broken.conf"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_CONFIG_HOME/source.conf" "test content"
    
    dk_safe_symlink "$TEST_CONFIG_HOME/source.conf" "$TEST_CONFIG_HOME/app1/broken.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify symlink was updated
    local link_target
    link_target=$(readlink "$TEST_CONFIG_HOME/app1/broken.conf")
    assert_equals "$TEST_CONFIG_HOME/source.conf" "$link_target"
    
    teardown
}

# Associative Array Tests (bash 4+)
test_associative_array_function() {
    setup
    
    # Skip if bash version < 4
    if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
        skip "Associative arrays require bash 4+"
        return
    fi
    
    # Create source files within config home for this test
    create_test_file "$TEST_CONFIG_HOME/source1.conf" "test content 1"
    create_test_file "$TEST_CONFIG_HOME/source2.conf" "test content 2"
    
    # shellcheck disable=SC2034  # symlink_map is used by name in dk_safe_symlink_array
    declare -A symlink_map=(
        ["$TEST_CONFIG_HOME/source1.conf"]="$TEST_CONFIG_HOME/app1/config1.conf"
        ["$TEST_CONFIG_HOME/source2.conf"]="$TEST_CONFIG_HOME/app2/config2.conf"
    )
    
    dk_safe_symlink_array symlink_map >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify both symlinks were created
    [[ -L "$TEST_CONFIG_HOME/app1/config1.conf" ]]
    assert_equals 0 $?
    [[ -L "$TEST_CONFIG_HOME/app2/config2.conf" ]]
    assert_equals 0 $?
    
    teardown
}

# Fallback Tests (when gum is not available)
test_fallback_prompt_yes() {
    setup
    mock_gum_missing
    
    # Create a source file within config home for this test
    create_test_file "$TEST_CONFIG_HOME/source.conf" "test content"
    
    # Test without conflicts (no prompt needed) - this tests that the function works when gum is missing
    dk_safe_symlink "$TEST_CONFIG_HOME/source.conf" "$TEST_CONFIG_HOME/app1/new.conf" >/dev/null 2>&1
    assert_equals 0 $?
    
    # Verify symlink was created
    [[ -L "$TEST_CONFIG_HOME/app1/new.conf" ]]
    assert_equals 0 $?
    
    teardown
}

test_fallback_prompt_no() {
    setup
    mock_gum_missing
    
    # Create existing file
    create_test_file "$TEST_CONFIG_HOME/app1/existing.conf" "existing content"
    
    # Create a source file within config home for this test
    create_test_file "$TEST_CONFIG_HOME/source.conf" "test content"
    
    # Simulate user typing "no"
    echo "no" | dk_safe_symlink "$TEST_CONFIG_HOME/source.conf" "$TEST_CONFIG_HOME/app1/existing.conf" >/dev/null 2>&1
    assert_equals 125 $?
    
    teardown
}

# Debug Mode Tests
test_debug_mode_logging() {
    setup
    
    export DK_DEBUG=1
    
    # Capture debug output
    local output
    # shellcheck disable=SC2034
    output=$(dk_safe_symlink "$FIXTURES_DIR/test_sources/config1.conf" "$TEST_CONFIG_HOME/app1/config.conf" 2>&1)
    
    # Debug output goes to logger, so we just verify the function succeeds
    local result=$?
    assert_equals 0 "$result"
    
    unset DK_DEBUG
    teardown
}

# Run all tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if bashunit is available
    if ! command -v bashunit >/dev/null 2>&1; then
        echo "bashunit not found. Please install bashunit to run tests."
        echo "In nix environment: nix develop"
        exit 1
    fi
    
    # Run the tests
    bashunit "$0"
fi
