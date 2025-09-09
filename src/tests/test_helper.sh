#!/usr/bin/env bash
# test_helper.sh - Global setup, teardown, and mock functions for bashunit tests

DOTKIT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)

# shellcheck source=../main.sh
source "$DOTKIT_ROOT/main.sh" source

# Test helper functions
create_test_file() {
    local file="$1"
    local content="${2:-test content}"
    # Add error checking to each step
    mkdir -p "$(dirname "$file")" || { echo "ERROR: Failed to create directory for $file" >&2; return 1; }
    echo "$content" > "$file" || { echo "ERROR: Failed to write to file $file" >&2; return 1; }
    [[ -f "$file" ]] || { echo "ERROR: File $file was not created after write attempt" >&2; return 1; }
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
            style) return 0 ;;
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

# Mock dk_warn_list to do nothing
mock_dk_warn_list_silent() {
    # shellcheck disable=SC2329
    dk_warn_list() {
        # This function intentionally does nothing
        return 0
    }
    export -f dk_warn_list
}
