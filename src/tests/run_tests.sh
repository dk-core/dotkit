#!/usr/bin/env bash
# run_tests.sh - Discovers and runs all bashunit tests in the src/tests directory.

set -euo pipefail

# Source the global test helper functions
# shellcheck source=./test_helper.sh
source "$(dirname "$0")/test_helper.sh"

# Check if bashunit is available
if ! command -v bashunit >/dev/null 2>&1; then
    echo "bashunit not found. Please install bashunit to run tests."
    echo "In nix environment: nix develop"
    exit 1
fi

# Run global setup
global_setup

# Find all test files and run them with bashunit
TEST_DIR=$(dirname "$0")
find "$TEST_DIR" -type f -name "test_*.sh" -not -name "test_helper.sh" -print0 | while IFS= read -r -d $'\0' test_file; do
    if [[ -f "$test_file" ]]; then
        echo "Running tests in: $test_file"
        bashunit --helper "$TEST_DIR/test_helper.sh" "$test_file"
    fi
done

# Run global teardown
global_teardown
