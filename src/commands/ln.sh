#!/usr/bin/env bash
# ln.sh - Safe symlink creation for dotkit

# Source global variables and functions
source "$(dirname "$(dirname "$(realpath "$0")")")/lib/global.sh"

# dk_safe_symlink_logic - Core logic for symlink creation
# This function is called by run_ln_command with either direct arguments or
# arguments derived from an associative array.
dk_safe_symlink_logic() {
  local -a sources=()
  local -a targets=()
  local -a missing_sources=()
  local -a conflicting_files=()
  local -a conflicting_symlinks=()

  # Parse arguments into source/target pairs
  if [[ $# -eq 0 ]]; then
      dk_error "No arguments provided to ln command"
      dk_fail "Usage: dk ln <source> <target> [source2 target2 ...]"
      return 1
  fi

  if [[ $((($# % 2))) -ne 0 ]]; then
      dk_error "Odd number of arguments provided - sources and targets must be paired"
      dk_fail "Usage: dk ln <source> <target> [source2 target2 ...]"
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

      # Normalize path (remove .., ., etc.) without following symlinks
      # Use a custom normalization that doesn't follow existing symlinks
      local target_dir
      target_dir="$(dirname "$resolved_target")"
      local target_name
      target_name="$(basename "$resolved_target")"

      # Normalize the directory path (this is safe even if it doesn't exist)
      if [[ -d "$target_dir" ]]; then
          target_dir="$(cd "$target_dir" && pwd)"
      else
          # For non-existent directories, use realpath -m on the directory part
          target_dir="$(realpath -m "$target_dir")"
      fi

      resolved_target="$target_dir/$target_name"

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

# run_ln_command - Main entry point for the ln command
# Handles both direct arguments and associative array input.
run_ln_command() {
    # Check if the first argument is an associative array name (bash 4+)
    if [[ ${BASH_VERSION%%.*} -ge 4 && -n "${1:-}" && "$(declare -p "$1" 2>/dev/null)" =~ "declare -A" ]]; then
        local map_name="$1"
        local -a args=()
        
        # Use eval to avoid circular name reference and expand the associative array into positional arguments
        eval "
            for source in \"\${!${map_name}[@]}\"; do
                args+=(\"\$source\" \"\${${map_name}[\$source]}\")
            done
        "
        dk_safe_symlink_logic "${args[@]}"
    else
        # Otherwise, treat arguments as direct source/target pairs
        dk_safe_symlink_logic "$@"
    fi
}

# Call the main function with all arguments passed to the script
run_ln_command "$@"
