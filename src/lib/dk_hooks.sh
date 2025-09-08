#!/usr/bin/env bash

# Declare an associative array to store hooks.
# The key will be the event name, and the value will be a space-separated string
# of function names and their associated order (e.g., "func1:10 func2:50").
declare -A DK_HOOKS
declare -A _DK_SORTED_HOOKS # Stores pre-sorted function names for each event

# dk_on: Registers a function to be called when an event is emitted.
# Arguments:
#   $1: The event name (e.g., "pre_install", "post_set").
#   $2: The name of the function to register.
#   $3: (Optional) The order in which the function should be executed. Lower numbers run first.
#       Defaults to 50 if not provided.
dk_on() {
  local event="$1"
  local func_name="$2"
  local order="${3:-50}" # Default order to 50 if not provided

  local -A temp_hooks # Temporary associative array to manage unique functions for this event
  local existing_func_info
  local existing_func_name
  local existing_order
  local new_hook_list=""

  # Populate temp_hooks with existing functions for this event
  # This loop handles the case where DK_HOOKS["$event"] might be empty or unset
  for existing_func_info in ${DK_HOOKS["$event"]:-}; do
    # Check if existing_func_info contains a colon to avoid issues with malformed entries
    if [[ "$existing_func_info" == *:* ]]; then
      existing_func_name="${existing_func_info%:*}"
      existing_order="${existing_func_info#*:}"
      temp_hooks["$existing_func_name"]="$existing_order"
    fi
  done

  # Add or update the new function
  temp_hooks["$func_name"]="$order"

  # Reconstruct the hook list string
  for key in "${!temp_hooks[@]}"; do
    new_hook_list+="$key:${temp_hooks[$key]} "
  done

  # Trim leading/trailing whitespace
  DK_HOOKS["$event"]="$(echo -e "$new_hook_list" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
}

# dk_emit: Emits an event, triggering all registered functions for that event.
# Arguments:
#   $1: The event name to emit.
#   $@: Any additional arguments to pass to the registered functions.
dk_emit() {
  local event="$1"; shift
  local func_name

  # Execute pre-sorted functions
  for func_name in ${_DK_SORTED_HOOKS["$event"]:-}; do
    if [[ -n "$func_name" ]]; then
      "$func_name" "$@"
    fi
  done
}
# _dk_finalize_hooks: Pre-sorts and stores hooks for faster emission.
# This function should be called once after all hook scripts have been loaded.
_dk_finalize_hooks() {
  local event
  local func_info
  local funcs_to_sort
  local sorted_funcs_array
  local sorted_func_names

  for event in "${!DK_HOOKS[@]}"; do
    funcs_to_sort=()
    for func_info in ${DK_HOOKS["$event"]:-}; do
      funcs_to_sort+=("$func_info")
    done

    # Sort functions by order and extract only the function names
    # Using printf and sort -n to sort numerically by order, then cut to get func_name
    mapfile -t sorted_funcs_array < <(printf "%s\n" "${funcs_to_sort[@]}" | sort -t':' -k2,2n | cut -d':' -f1)

    # Join the sorted function names into a space-separated string
    sorted_func_names=$(IFS=" "; echo "${sorted_funcs_array[*]}")
    _DK_SORTED_HOOKS["$event"]="$sorted_func_names"
  done
}

# dk_load_hooks: Loads hook scripts from predefined paths.
# This function sources dk_hooks.sh files from modules and profiles in a specific order.
# The order ensures that profile hooks can override module and dotfile hooks.
dk_load_hooks() {
  local hook_file

  # 1. For each module in DK_DOTFILE/modules/module_name/lib/dk_hooks.sh
  # This path needs to be dynamic based on actual module directories.
  # Assuming DK_DOTFILE is set and points to the current dotfile directory.
  # For now, this will be a placeholder as DK_DOTFILE is not defined in this context.
  # We'll need to ensure DK_DOTFILE and DK_PROFILE are properly set in the environment
  # where this function is called.
  # Example: find "$DK_DOTFILE/modules/" -type d -name "module_name" -exec find {} -name "dk_hooks.sh" \;
  # This part requires more context on how DK_DOTFILE and modules are structured.
  # For now, I'll use a simplified glob.

  # Placeholder for DK_DOTFILE/modules/*/lib/dk_hooks.sh
  for hook_file in "$DK_DOTFILE"/modules/*/lib/dk_hooks.sh; do
    if [[ -f "$hook_file" ]]; then
      dk_debug "Loading hook file: $hook_file"
       # shellcheck source=/dev/null
      source "$hook_file"
    fi
  done

  # 2. DK_DOTFILE/lib/dk_hooks.sh
  hook_file="$DK_DOTFILE/lib/dk_hooks.sh"
  if [[ -f "$hook_file" ]]; then
    dk_debug "Loading hook file: $hook_file"
     # shellcheck source=/dev/null
    source "$hook_file"
  fi

  # 3. For each module in DK_PROFILE/modules/module_name/lib/dk_hooks.sh
  # Placeholder for DK_PROFILE/modules/*/lib/dk_hooks.sh
  for hook_file in "$DK_PROFILE"/modules/*/lib/dk_hooks.sh; do
    if [[ -f "$hook_file" ]]; then
      dk_debug "Loading hook file: $hook_file"
       # shellcheck source=/dev/null
      source "$hook_file"
    fi
  done

  # 4. DK_PROFILE/lib/dk_hooks.sh
  hook_file="$DK_PROFILE/lib/dk_hooks.sh"
  if [[ -f "$hook_file" ]]; then
    dk_debug "Loading hook file: $hook_file"
    # shellcheck source=/dev/null
    source "$hook_file"
  fi

  # Finalize hooks after all loading is complete
  _dk_finalize_hooks
}
