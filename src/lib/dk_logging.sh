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
    echo -e "\033[32m[dk] ✓ $*\033[0m"
}

dk_fail() { 
    echo -e "\033[31m[dk] ✗ $*\033[0m" >&2
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
        echo -e "\033[1m$title\033[0m"
    fi
    printf '\033[36m  • %s\033[0m\n' "${items[@]}"
}

# Pretty print warnings with lists
dk_warn_list() {
    local title="$1"
    shift
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo -e "\033[33m\033[1m[dk] WARN: $title\033[0m"
    printf '\033[33m  • %s\033[0m\n' "${items[@]}"
    
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
    
    echo -e "\033[31m\033[1m[dk] ERROR: $title\033[0m" >&2
    printf '\033[31m  • %s\033[0m\n' "${items[@]}" >&2
    
    # Also log to system journal
    dk_error "$title: ${items[*]}"
}
