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
    echo "[dk] ✓ $*"
}

dk_fail() { 
    echo "[dk] ✗ $*" >&2
}
