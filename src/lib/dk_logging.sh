#!/usr/bin/env bash
# dk_logging.sh - Logging and printing utilities for dotkit

# Logging functions (to system journal)
dk_log() { 
    logger -t dk "$*" 2>/dev/null || true
}

dk_error() { 
    logger -p user.err -t dk "ERROR: $*" 2>/dev/null || true
}

dk_debug() { 
    if [[ ${DK_DEBUG:-} ]]; then
        logger -t dk "DEBUG: $*" 2>/dev/null || true
        echo "[dk] DEBUG: $*"
    fi
}

dk_warn() { 
    logger -p user.warning -t dk "WARN: $*" 2>/dev/null || true
}

# Print functions (immediate user feedback)
dk_print() { 
    echo "[dk] $*"
}

dk_status() { 
    echo "[dk] status: $*"
}

dk_success() { 
    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 2 "[dk] ✓ $*"
    else
        echo "[dk] ✓ $*"
    fi
}

dk_fail() { 
    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 1 "[dk] ✗ $*" >&2
    else
        echo "[dk] ✗ $*" >&2
    fi
}

# Pretty print arrays as lists
dk_print_list() {
    local title="$1"
    shift
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return 0
    fi
    
    if command -v gum >/dev/null 2>&1; then
        if [[ -n "$title" ]]; then
            gum style --bold "$title"
        fi
        printf '%s\n' "${items[@]}" | gum style --foreground 6 --margin "0 2"
    else
        if [[ -n "$title" ]]; then
            echo "$title"
        fi
        printf '  • %s\n' "${items[@]}"
    fi
}

# Pretty print warnings with lists
dk_warn_list() {
    local title="$1"
    shift
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return 0
    fi
    
    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 3 --bold "[dk] WARN: $title"
        printf '%s\n' "${items[@]}" | gum style --foreground 3 --margin "0 2"
    else
        dk_warn "$title"
        printf '  • %s\n' "${items[@]}"
    fi
    
    # Also log to system journal
    dk_warn "$title: ${items[*]}"
}

# Pretty print errors with lists
dk_error_list() {
    local title="$1"
    shift
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return 0
    fi
    
    if command -v gum >/dev/null 2>&1; then
        gum style --foreground 1 --bold "[dk] ERROR: $title" >&2
        printf '%s\n' "${items[@]}" | gum style --foreground 1 --margin "0 2" >&2
    else
        dk_fail "$title"
        printf '  • %s\n' "${items[@]}" >&2
    fi
    
    # Also log to system journal
    dk_error "$title: ${items[*]}"
}
