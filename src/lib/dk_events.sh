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
  dk_debug "dk_on called for event: $event, function: $func_name, order: $order"

  # Append with a space, but only if the variable is not empty
  if [[ -v DK_EVENTS["$event"] && -n "${DK_EVENTS[$event]}" ]]; then
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
  dk_debug "dk_emit called for event: $event with args: $*"

  # Execute pre-sorted handlers (functions or executables)
  if [[ -v _DK_SORTED_EVENTS["$event"] ]]; then
    dk_debug "Handlers for $event: ${_DK_SORTED_EVENTS["$event"]}"
    for handler in ${_DK_SORTED_EVENTS["$event"]}; do
      if [[ -n "$handler" ]]; then
        if declare -F "$handler" >/dev/null; then
          dk_debug "Executing function handler: $handler for event: $event"
          "$handler" "$@"
        elif [[ -x "$handler" ]]; then
          dk_debug "Executing executable handler: $handler for event: $event"
          "$handler" "$@"
        else
          dk_warn "Handler $handler is not a function or executable for event: $event"
        fi
      fi
    done
  else
    dk_debug "No handlers registered for event: $event"
  fi
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
  dk_debug "_dk_finalize_events called. Raw DK_EVENTS: $(declare -p DK_EVENTS)"

  for event in "${!DK_EVENTS[@]}"; do
    dk_debug "Finalizing event: $event. Raw entries: ${DK_EVENTS["$event"]}"
    # Use an associative array to store the latest order for each function,
    # effectively handling duplicates. The last one wins.
    local -A unique_events=() # Declare and initialize unique_events inside the loop to reset it for each event
    if [[ -v DK_EVENTS["$event"] ]]; then
      for func_info in ${DK_EVENTS["$event"]}; do
        func_name="${func_info%:*}"
        order="${func_info#*:}"
        unique_events["$func_name"]="$order"
        dk_debug "  Processing func_info: $func_info -> func_name: $func_name, order: $order"
      done
    fi
    dk_debug "  Unique events for $event before sorting: $(declare -p unique_events)"

    # Prepare for sorting. We need to convert the associative array
    # back to a format that the 'sort' command can use.
    local -a funcs_to_sort=()
    for func_name in "${!unique_events[@]}"; do
      # We use "order:func_name" to make numeric sorting on the key simple.
      funcs_to_sort+=("${unique_events[$func_name]}:$func_name")
    done
    dk_debug "  Functions to sort for $event: ${funcs_to_sort[*]}"

    # Sort numerically by order (first field, -k1,1n) and extract the function name (second field, -f2-).
    mapfile -t sorted_funcs_array < <(printf "%s\n" "${funcs_to_sort[@]}" | sort -t':' -k1,1n | cut -d':' -f2-)
    dk_debug "  Sorted function array for $event: ${sorted_funcs_array[*]}"

    # Join the sorted function names into a space-separated string
    if [[ ${#sorted_funcs_array[@]} -gt 0 ]]; then
      sorted_func_names=$(IFS=" "; echo "${sorted_funcs_array[*]}")
      # Trim trailing space
      _DK_SORTED_EVENTS["$event"]="${sorted_func_names% }"
      dk_debug "  _DK_SORTED_EVENTS[$event] set to: ${_DK_SORTED_EVENTS["$event"]}"
    else
      # Ensure the entry is cleared if no events are left
      unset "_DK_SORTED_EVENTS[$event]"
      dk_debug "  No functions for event $event, _DK_SORTED_EVENTS[$event] unset."
    fi
  done
  dk_debug "Final _DK_SORTED_EVENTS: $(declare -p _DK_SORTED_EVENTS)"
}

# dk_load_events: Loads hook scripts from predefined paths.
# This function sources dk_events.sh files from modules and profiles in a specific order.
# The order ensures that profile events can override module and dotfile events.
dk_load_events() {
  local hook_file
  dk_debug "dk_load_events called"

  # Clear existing events to ensure idempotency
  DK_EVENTS=()
  _DK_SORTED_EVENTS=()
  dk_debug "Events cleared. DK_EVENTS: $(declare -p DK_EVENTS), _DK_SORTED_EVENTS: $(declare -p _DK_SORTED_EVENTS)"

  # 1. Load core events from DOTKIT_ROOT/lib/events/
  # These are the default event handlers for the dotkit system.
  for hook_file in "$DOTKIT_ROOT"/lib/events/*.sh; do
    if [[ -f "$hook_file" ]]; then
      dk_debug "Loading core event file: $hook_file"
      # shellcheck source=/dev/null
      source "$hook_file"
    fi
  done

  # 2. For each module in DK_DOTFILE/modules/module_name/lib/dk_events.sh
  # This path needs to be dynamic based on actual module directories.
  # Assuming DK_DOTFILE is set and points to the current dotfile directory.
  # For now, this will be a placeholder as DK_DOTFILE is not defined in this context.
  # We'll need to ensure DK_DOTFILE and DK_PROFILE are properly set in the environment
  # where this function is called.
  # Example: find "$DK_DOTFILE/modules/" -type d -name "module_name" -exec find {} -name "dk_events.sh" \;
  # This part requires more context on how DK_DOTFILE and modules are structured.
  # For now, I'll use a simplified glob.

  # TODO: Load events from modules, dotfiles, and profiles
  # Placeholder for DK_DOTFILE/modules/*/lib/dk_events.sh
  for hook_file in "$DK_DOTFILE"/modules/*/lib/dk_events.sh; do
    if [[ -f "$hook_file" ]]; then
      dk_debug "Loading hook file: $hook_file"
       # shellcheck source=/dev/null
      source "$hook_file"
    fi
  done

  # 3. DK_DOTFILE/lib/dk_events.sh
  hook_file="$DK_DOTFILE/lib/dk_events.sh"
  if [[ -f "$hook_file" ]]; then
    dk_debug "Loading hook file: $hook_file"
     # shellcheck source=/dev/null
    source "$hook_file"
  fi

  # 4. For each module in DK_PROFILE/modules/module_name/lib/dk_events.sh
  # Placeholder for DK_PROFILE/modules/*/lib/dk_events.sh
  for hook_file in "$DK_PROFILE"/modules/*/lib/dk_events.sh; do
    if [[ -f "$hook_file" ]]; then
      dk_debug "Loading hook file: $hook_file"
       # shellcheck source=/dev/null
      source "$hook_file"
    fi
  done

  # 5. DK_PROFILE/lib/dk_events.sh
  hook_file="$DK_PROFILE/lib/dk_events.sh"
  if [[ -f "$hook_file" ]]; then
    dk_debug "Loading hook file: $hook_file"
    # shellcheck source=/dev/null
    source "$hook_file"
  fi

  # Finalize events after all loading is complete
  _dk_finalize_events
}
