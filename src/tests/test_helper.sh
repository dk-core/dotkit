#!/usr/bin/env bash
# test_helper.sh - Global setup, teardown, and mock functions for bashunit tests

DOTKIT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)

# shellcheck source=../main.sh
source "$DOTKIT_ROOT/main.sh" api source

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
