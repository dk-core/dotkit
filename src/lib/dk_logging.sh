#!/usr/bin/env bash
# dk_logging.sh - Logging and printing utilities for dotkit

# Gum styling environment variables
export GUM_INPUT_FOREGROUND="#FF8C00" # Orange for primary color
export GUM_SPIN_FOREGROUND="#FF8C00"
export GUM_WRITE_FOREGROUND="#FF8C00"
export GUM_CHOOSE_FOREGROUND="#FF8C00"
export GUM_FILTER_FOREGROUND="#FF8C00"
export GUM_CONFIRM_FOREGROUND="#FF8C00"
export GUM_FILE_FOREGROUND="#FF8C00"
export GUM_FORMAT_FOREGROUND="#FF8C00"
export GUM_JOIN_FOREGROUND="#FF8C00"
export GUM_PAGER_FOREGROUND="#FF8C00"
export GUM_TABLE_FOREGROUND="#FF8C00"
export GUM_TEXT_FOREGROUND="#FF8C00"

# Helper function for consistent [dotkit] prefix styling
_dk_prefix() {
    gum style --foreground "#FF8C00" "[dotkit]"
}

# Logging functions (to system journal)
dk_log() { 
    logger -t dotkit "$*" 2>/dev/null || true
}

dk_error() { 
    logger -p user.err -t dotkit "ERROR: $*" 2>/dev/null || true
}

dk_debug() { 
    if [[ "${DK_DEBUG:-}" == true ]]; then
        logger -t dotkit "DEBUG: $*" 2>/dev/null || true
        echo "[dotkit] DEBUG: $*" >&2
    fi
}

dk_warn() { 
    logger -p user.warning -t dokit "WARN: $*" 2>/dev/null || true
}

# Print functions (immediate user feedback)
dk_print() { 
    gum style "$(_dk_prefix) $*"
}

dk_status() { 
    gum style "$(_dk_prefix) status: $*"
}

dk_success() { 
    gum style --foreground "2" "$(_dk_prefix) ✓ $*"
}

dk_fail() { 
    gum style --foreground "1" "$(_dk_prefix) ✗ $*" >&2
}

# Pretty print arrays as lists
dk_print_list() {
    local title="$1"
    shift
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return 0
    fi
    
    if [[ -n "$title" ]]; then
        gum style "$title"
    fi
    for item in "${items[@]}"; do
        gum style --foreground "6" "  • $item"
    done
}

# Pretty print warnings with lists
dk_warn_list() {
    local title="$1"
    shift
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return 0
    fi
    
    gum style --foreground "3" "$(_dk_prefix) WARN: $title" >&2
    for item in "${items[@]}"; do
        gum style --foreground "3" "  • $item" >&2
    done
    
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
    
    gum style --foreground "1" "$(_dk_prefix) ERROR: $title" >&2
    for item in "${items[@]}"; do
        gum style --foreground "1" "  • $item" >&2
    done
    
    # Also log to system journal
    dk_error "$title: ${items[*]}"
}
