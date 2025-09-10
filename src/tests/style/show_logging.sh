#!/usr/bin/env bash

# shellcheck source=../main.sh
source "$DOTKIT_ROOT/main.sh" api source

dk_print "This is a regular print message."
dk_status "This is a status update."
dk_success "Operation completed successfully!"
dk_fail "Operation failed."

echo ""

dk_print_list "List of items:" "Item 1" "Item 2" "Item 3"

echo ""

dk_warn_list "Warning list:" "Warning 1" "Warning 2"
dk_error_list "Error list:" "Error A" "Error B"

echo ""

dk_log "This message goes to the system journal."
dk_error "This error goes to the system journal."
dk_debug "This debug message goes to the system journal and stdout (if DK_DEBUG is set)."
dk_warn "This warning goes to the system journal."

echo ""

# Test with DK_DEBUG enabled
export DK_DEBUG=1
dk_debug "This debug message should be visible on stdout."
unset DK_DEBUG
