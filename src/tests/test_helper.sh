#!/usr/bin/env bash
# test_helper.sh - Global setup, teardown, and mock functions for bashunit tests

# Get path to the lib directory relative to this script
HELPER_DIR=$(dirname "${BASH_SOURCE[0]}")
LIB_DIR="$HELPER_DIR/../lib"

# Source global functions and variables
# shellcheck source=../lib/dk_global.sh
source "$LIB_DIR/dk_global.sh"

# Global setup for all tests
global_setup() {
    # Create a temporary directory for all tests
    local temp_dir
    temp_dir="$(mktemp -d)"
    export TEST_BASE_DIR="$temp_dir"
    
    # Disable interactive prompts for testing
    export DEBIAN_FRONTEND=noninteractive
}

# Global teardown for all tests
global_teardown() {
    [[ -n "$TEST_BASE_DIR" ]] && rm -rf "$TEST_BASE_DIR"
}

# Setup for individual test files
setup() {
    # Create a unique test directory for each test file
    TEST_DIR="$TEST_BASE_DIR/$(date +%s%N)"
    mkdir -p "$TEST_DIR"
    
    # Get paths for testing relative to the test file
    TEST_FILE_DIR="$(dirname "${BASH_SOURCE[1]}")"
    
    # Define FIXTURES_DIR relative to the test file's directory
    # FIXTURES_DIR is used in test_dk_link.sh, so it needs to be exported
    export FIXTURES_DIR="$TEST_FILE_DIR/fixtures"
}

# Cleanup after each test file
teardown() {
    # Clean up the unique test directory for this test file
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
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
