#!/usr/bin/env bash

# Declare an associative array to store events.
# The key will be the event name, and the value will be a space-separated string
# of function names and their associated order (e.g., "func1:10 func2:50").
declare -A DK_EVENTS
declare -A _DK_SORTED_EVENTS # Stores pre-sorted function names for each event

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

  # Append with a space, but only if the variable is not empty
  if [[ -n "${DK_EVENTS[$event]}" ]]; then
    DK_EVENTS["$event"]+="$func_name:$order "
  else
    DK_EVENTS["$event"]="$func_name:$order "
  fi
}

# dk_emit: Emits an event, triggering all registered functions for that event.
# Arguments:
#   $1: The event name to emit.
#   $@: Any additional arguments to pass to the registered functions.
dk_emit() {
  local event="$1"; shift
  local handler

  # Execute pre-sorted handlers (functions or executables)
  for handler in ${_DK_SORTED_EVENTS["$event"]:-}; do
    if [[ -n "$handler" ]]; then
      if declare -F "$handler" >/dev/null; then
        "$handler" "$@"
      elif [[ -x "$handler" ]]; then
        "$handler" "$@"
      else
        echo "Warning: Handler $handler is not a function or executable" >&2
      fi
    fi
  done
}
# _dk_finalize_events: Pre-sorts and stores events for faster emission.
# This function should be called once after all hook scripts have been loaded.
_dk_finalize_events() {
  local event
  local func_info
  local sorted_funcs_array
  local sorted_func_names
  local func_name
  local order

  for event in "${!DK_EVENTS[@]}"; do
    # Use an associative array to store the latest order for each function,
    # effectively handling duplicates. The last one wins.
    local -A unique_events
    for func_info in ${DK_EVENTS["$event"]}; do
      func_name="${func_info%:*}"
      order="${func_info#*:}"
      unique_events["$func_name"]="$order"
    done

    # Prepare for sorting. We need to convert the associative array
    # back to a format that the 'sort' command can use.
    local -a funcs_to_sort=()
    for func_name in "${!unique_events[@]}"; do
      # We use "order:func_name" to make numeric sorting on the key simple.
      funcs_to_sort+=("${unique_events[$func_name]}:$func_name")
    done

    # Sort numerically by order (first field, -k1,1n) and extract the function name (second field, -f2-).
    mapfile -t sorted_funcs_array < <(printf "%s\n" "${funcs_to_sort[@]}" | sort -t':' -k1,1n | cut -d':' -f2-)

    # Join the sorted function names into a space-separated string
    if [[ ${#sorted_funcs_array[@]} -gt 0 ]]; then
      sorted_func_names=$(IFS=" "; echo "${sorted_funcs_array[*]}")
      # Trim trailing space
      _DK_SORTED_EVENTS["$event"]="${sorted_func_names% }"
    else
      # Ensure the entry is cleared if no events are left
      unset "_DK_SORTED_EVENTS[$event]"
    fi
  done
}

# dk_load_events: Loads hook scripts from predefined paths.
# This function sources dk_events.sh files from modules and profiles in a specific order.
# The order ensures that profile events can override module and dotfile events.
dk_load_events() {
  local hook_file

  # 1. For each module in DK_DOTFILE/modules/module_name/lib/dk_events.sh
  # This path needs to be dynamic based on actual module directories.
  # Assuming DK_DOTFILE is set and points to the current dotfile directory.
  # For now, this will be a placeholder as DK_DOTFILE is not defined in this context.
  # We'll need to ensure DK_DOTFILE and DK_PROFILE are properly set in the environment
  # where this function is called.
  # Example: find "$DK_DOTFILE/modules/" -type d -name "module_name" -exec find {} -name "dk_events.sh" \;
  # This part requires more context on how DK_DOTFILE and modules are structured.
  # For now, I'll use a simplified glob.

  # Placeholder for DK_DOTFILE/modules/*/lib/dk_events.sh
  for hook_file in "$DK_DOTFILE"/modules/*/lib/dk_events.sh; do
    if [[ -f "$hook_file" ]]; then
      dk_debug "Loading hook file: $hook_file"
       # shellcheck source=/dev/null
      source "$hook_file"
    fi
  done

  # 2. DK_DOTFILE/lib/dk_events.sh
  hook_file="$DK_DOTFILE/lib/dk_events.sh"
  if [[ -f "$hook_file" ]]; then
    dk_debug "Loading hook file: $hook_file"
     # shellcheck source=/dev/null
    source "$hook_file"
  fi

  # 3. For each module in DK_PROFILE/modules/module_name/lib/dk_events.sh
  # Placeholder for DK_PROFILE/modules/*/lib/dk_events.sh
  for hook_file in "$DK_PROFILE"/modules/*/lib/dk_events.sh; do
    if [[ -f "$hook_file" ]]; then
      dk_debug "Loading hook file: $hook_file"
       # shellcheck source=/dev/null
      source "$hook_file"
    fi
  done

  # 4. DK_PROFILE/lib/dk_events.sh
  hook_file="$DK_PROFILE/lib/dk_events.sh"
  if [[ -f "$hook_file" ]]; then
    dk_debug "Loading hook file: $hook_file"
    # shellcheck source=/dev/null
    source "$hook_file"
  fi

  # Finalize events after all loading is complete
  _dk_finalize_events
}
