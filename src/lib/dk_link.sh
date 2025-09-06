#!/usr/bin/env bash
# dk_link.sh - Safe symlink creation for dotkit

# dk_link - Creates symlinks safely with validation and user prompts
# Usage: dk_link source1 target1 [source2 target2 ...]
# Or with associative array: dk_link_array
# TODO: associative array should be the preferred method of interacting with dk
# TODO: detect if input is associative array or list of args??
dk_link() {
    dk_debug "Entering dk_link function"
    local -a sources=()
    local -a targets=()
    local -a missing_sources=()
    local -a conflicting_files=()
    local -a conflicting_symlinks=()
    
    # Parse arguments into source/target pairs
    if [[ $# -eq 0 ]]; then
        dk_error "No arguments provided to dk_link"
        dk_fail "Usage: dk_link source1 target1 [source2 target2 ...]"
        return 1
    fi
    
    if [[ $(( $# % 2 )) -ne 0 ]]; then
        dk_error "Odd number of arguments provided - sources and targets must be paired"
        dk_fail "Usage: dk_link source1 target1 [source2 target2 ...]"
        return 1
    fi
    
    # Collect source/target pairs
    while [[ $# -gt 0 ]]; do
        sources+=("$1")
        targets+=("$2")
        shift 2
    done
    
    dk_debug "Processing ${#sources[@]} symlink pairs"
    
    
    # Check if sources exist
    for ((i=0; i<${#sources[@]}; i++)); do
        local source="${sources[$i]}"
        if [[ ! -e "$source" ]]; then
            missing_sources+=("$source")
        fi
    done
    
    if [[ ${#missing_sources[@]} -gt 0 ]]; then
        dk_error_list "Missing source files" "${missing_sources[@]}"
        return 1
    fi
    
    # Check for target conflicts
    for i in "${!targets[@]}"; do
        local target="${targets[$i]}"
        
        if [[ -f "$target" && ! -L "$target" ]]; then
            conflicting_files+=("$target")
        elif [[ -L "$target" ]]; then
            conflicting_symlinks+=("$target")
        fi
    done
    
    # Handle file conflicts with user prompt
    # File conflicts will cause dk to fail and prompt user to backup manually
    if [[ ${#conflicting_files[@]} -gt 0 ]]; then
        dk_error_list "The following files would be overwritten (operation aborted):" "${conflicting_files[@]}"
        dk_fail "dk ln safely exited. Please manually backup these files before proceeding."
        return 1
    fi
    
    # Handle symlink conflicts with user prompt
    if [[ ${#conflicting_symlinks[@]} -gt 0 ]]; then
        local -a symlink_descriptions=()
        for symlink in "${conflicting_symlinks[@]}"; do
            local link_target
            link_target="$(readlink "$symlink" 2>/dev/null || echo "broken")"
            symlink_descriptions+=("$symlink -> $link_target")
        done
        
        dk_warn_list "The following symlinks will be overwritten" "${symlink_descriptions[@]}"
        
        if command -v gum >/dev/null 2>&1; then
            if ! gum confirm "Overwrite these symlinks?"; then
                dk_log "User declined to overwrite symlinks: ${conflicting_symlinks[*]}"
                dk_fail "dk ln safely exited. Please manually backup symlinks [${conflicting_symlinks[*]}]"
                return 125
            fi
        else
            # Fallback to read if gum is not available
            echo -n "Overwrite these symlinks? [y/N]: " >&2
            read -r response </dev/tty 2>/dev/null || read -r response
            if [[ ! "$response" =~ ^[Yy]([Ee][Ss])?$ ]]; then
                dk_log "User declined to overwrite symlinks: ${conflicting_symlinks[*]}"
                dk_fail "dk ln safely exited. Please manually backup symlinks [${conflicting_symlinks[*]}]"
                return 125
            fi
        fi
    fi
    
    # Create symlinks
    local success_count=0
    for ((i=0; i<${#sources[@]}; i++)); do
        local source="${sources[$i]}"
        local target="${targets[$i]}"
        
        # For debugging: use source directly, assuming it's absolute or relative to CWD
        local absolute_source="$source"
        
        dk_debug "Using source path directly: $source -> $absolute_source"
        
        # Create target directory if it doesn't exist
        local target_dir
        target_dir="$(dirname "$target")"
        if [[ ! -d "$target_dir" ]]; then
            dk_debug "Creating target directory: $target_dir"
            if ! mkdir -p "$target_dir"; then
                dk_error "Failed to create target directory: $target_dir"
                dk_fail "Failed to create directory for $target"
                continue
            fi
        fi
        
        dk_debug "About to execute ln command: command ln -sfn '$absolute_source' '$target'"
        if command ln -sfn "$absolute_source" "$target"; then
            dk_debug "ln command successful. Exit code: $?"
            dk_success "Linked $absolute_source -> $target"
            dk_log "Created symlink: $absolute_source -> $target"
            success_count=$((success_count + 1))
        else
            local ln_exit_code=$?
            dk_debug "ln command failed. Exit code: $ln_exit_code"
            dk_error "Failed to create symlink: $absolute_source -> $target"
            dk_fail "Failed to link $absolute_source -> $target"
        fi
    done
    
    dk_log "Successfully created $success_count/${#sources[@]} symlinks"
    
    if [[ $success_count -eq ${#sources[@]} ]]; then
        dk_success "All symlinks created successfully"
        return 0
    else
        dk_fail "Some symlinks failed to create ($success_count/${#sources[@]} successful)"
        return 1
    fi
}

# Alternative function for associative arrays (bash 4+)
dk_link_array() {
    local map_name="$1"
    local -a args=()
    
    # Use eval to avoid circular name reference
    eval "
        for source in \"\${!${map_name}[@]}\"; do
            args+=(\"\$source\" \"\${${map_name}[\$source]}\")
        done
    "
    
    dk_link "${args[@]}"
}

# Call dk_link function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    dk_link "$@"
fi
