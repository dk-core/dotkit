#!/usr/bin/env bash
# dk_safe_symlink.sh - Safe symlink creation for dotkit

# Source logging functions
source "$(dirname "${BASH_SOURCE[0]}")/dk_logging.sh"

# dk_safe_symlink - Creates symlinks safely with validation and user prompts
# Usage: dk_safe_symlink source1 target1 [source2 target2 ...]
# Or with associative array: dk_safe_symlink_array
dk_safe_symlink() {
    local -a sources=()
    local -a targets=()
    local -a missing_sources=()
    local -a conflicting_files=()
    local -a conflicting_symlinks=()
    
    # Parse arguments into source/target pairs
    if [[ $# -eq 0 ]]; then
        dk_error "No arguments provided to dk_safe_symlink"
        dk_fail "Usage: dk_safe_symlink source1 target1 [source2 target2 ...]"
        return 1
    fi
    
    if [[ $((($# % 2))) -ne 0 ]]; then
        dk_error "Odd number of arguments provided - sources and targets must be paired"
        dk_fail "Usage: dk_safe_symlink source1 target1 [source2 target2 ...]"
        return 1
    fi
    
    # Collect source/target pairs
    while [[ $# -gt 0 ]]; do
        sources+=("$1")
        targets+=("$2")
        shift 2
    done
    
    dk_debug "Processing ${#sources[@]} symlink pairs"
    
    # Set XDG_CONFIG_HOME default if not set
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    dk_debug "Using config home: $config_home"
    
    # Validate all targets are within XDG_CONFIG_HOME
    local i
    for i in "${!targets[@]}"; do
        local target="${targets[$i]}"
        local resolved_target
        
        # Resolve target path to absolute path
        if [[ "$target" = /* ]]; then
            resolved_target="$target"
        else
            resolved_target="$(pwd)/$target"
        fi
        
        # Normalize path (remove .., ., etc.)
        resolved_target="$(realpath -m "$resolved_target")"
        
        # Check if target is within config_home
        if [[ "$resolved_target" != "$config_home"* ]]; then
            dk_error "Target path outside XDG_CONFIG_HOME: $target -> $resolved_target"
            dk_fail "dk ln is not permitted to write outside of $config_home"
            return 1
        fi
        
        dk_debug "Target validated: $target -> $resolved_target"
    done
    
    # Check if sources exist
    for i in "${!sources[@]}"; do
        local source="${sources[$i]}"
        if [[ ! -e "$source" ]]; then
            missing_sources+=("$source")
        fi
    done
    
    if [[ ${#missing_sources[@]} -gt 0 ]]; then
        dk_error "Missing source files: ${missing_sources[*]}"
        dk_fail "Sources [${missing_sources[*]}] do not exist"
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
    if [[ ${#conflicting_files[@]} -gt 0 ]]; then
        dk_warn "The following files will be overwritten:"
        printf '  %s\n' "${conflicting_files[@]}"
        
        if command -v gum >/dev/null 2>&1; then
            if ! gum confirm "Overwrite these files?"; then
                dk_log "User declined to overwrite files: ${conflicting_files[*]}"
                dk_fail "dk ln safely exited. Please manually backup files [${conflicting_files[*]}]"
                return 125
            fi
        else
            # Fallback to read if gum is not available
            echo -n "Overwrite these files? [y/N]: " >&2
            read -r response </dev/tty 2>/dev/null || read -r response
            if [[ ! "$response" =~ ^[Yy]([Ee][Ss])?$ ]]; then
                dk_log "User declined to overwrite files: ${conflicting_files[*]}"
                dk_fail "dk ln safely exited. Please manually backup files [${conflicting_files[*]}]"
                return 125
            fi
        fi
    fi
    
    # Handle symlink conflicts with user prompt
    if [[ ${#conflicting_symlinks[@]} -gt 0 ]]; then
        dk_warn "The following symlinks will be overwritten:"
        for symlink in "${conflicting_symlinks[@]}"; do
            local link_target
            link_target="$(readlink "$symlink" 2>/dev/null || echo "broken")"
            printf '  %s -> %s\n' "$symlink" "$link_target"
        done
        
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
    for i in "${!sources[@]}"; do
        local source="${sources[$i]}"
        local target="${targets[$i]}"
        
        # Convert source to absolute path to avoid dead symlinks
        local absolute_source
        if [[ "$source" = /* ]]; then
            absolute_source="$source"
        else
            absolute_source="$(realpath "$source")"
        fi
        
        dk_debug "Converting source path: $source -> $absolute_source"
        
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
        
        # Create symlink with ln -sfn (force, no-dereference) using absolute source path
        if ln -sfn "$absolute_source" "$target"; then
            dk_success "Linked $absolute_source -> $target"
            dk_log "Created symlink: $absolute_source -> $target"
            success_count=$((success_count + 1))
        else
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
dk_safe_symlink_array() {
    local map_name="$1"
    local -a args=()
    
    # Use eval to avoid circular name reference
    eval "
        for source in \"\${!${map_name}[@]}\"; do
            args+=(\"\$source\" \"\${${map_name}[\$source]}\")
        done
    "
    
    dk_safe_symlink "${args[@]}"
}
