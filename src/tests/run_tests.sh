#!/usr/bin/env bash
# run_tests.sh - Discovers and runs all bashunit tests & show_ tests in the src/tests directory.
set -euo pipefail

# shellcheck source=../main.sh
source "$DOTKIT_ROOT/main.sh" api source
# shellcheck source=test_helper.sh
source "$DOTKIT_ROOT/tests/test_helper.sh"

# Check if bashunit is available
if ! command -v bashunit >/dev/null 2>&1; then
    echo "bashunit not found. Please install bashunit to run tests."
    echo "In nix environment: nix develop"
    exit 1
fi

# Run global setup
global_setup

# Find all test files and run them with bashunit
find "$DOTKIT_ROOT/tests" -type f -name "test_*.sh" -not -name "test_helper.sh" -print0 | while IFS= read -r -d $'\0' test_file; do
    if [[ -f "$test_file" ]]; then
        echo "Running tests in: $test_file"
        bashunit --helper "$DOTKIT_ROOT/tests/test_helper.sh" "$test_file"
    fi
done

# run all show_ tests
find "$DOTKIT_ROOT/tests" -type f -name "show_*.sh" -print0 | while IFS= read -r -d $'\0' test_file; do
    if [[ -f "$test_file" ]]; then
        echo "Running print tests in: $test_file"
        "$test_file"
    fi
done

# Run global teardown
global_teardown
