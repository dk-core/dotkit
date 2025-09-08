#!/usr/bin/env bash

# Global setup for all tests
set_up_before_script() {
    # Create a temporary directory for all tests
    mkdir -p "$DOTKIT_ROOT/.test_temp"
    sleep 0.1 # Wait for temp dir to be created
    TEST_BASE_DIR="$(mktemp -d "$DOTKIT_ROOT/.test_temp/test.XXXXXX")"
    export TEST_BASE_DIR

    sleep 0.1 # Wait for temp dir to be created
    
    # Disable interactive prompts for testing
    export DEBIAN_FRONTEND=noninteractive
}

# Setup function to run before each test
set_up() {

  TEST_DIR="$TEST_BASE_DIR/$(date +%s%N)"
  export TEST_DIR
  mkdir -p "$TEST_DIR"

  # Create temporary directories for dk_load_hooks tests
  DK_DOTFILE="$TEST_DIR/dotfile"
  DK_PROFILE="$TEST_DIR/profile"
  mkdir -p "$DK_DOTFILE"
  mkdir -p "$DK_PROFILE"
  declare -A DK_HOOKS

  export DK_DOTFILE DK_PROFILE DK_HOOKS
}

# Teardown function to run after each test
tear_down() {
  rm -rf "$DK_DOTFILE" "$DK_PROFILE"
  unset DK_DOTFILE
  unset DK_PROFILE
  unset DK_HOOKS
}

# Global teardown for all tests
tear_down_after_script() {
    [[ -n "$TEST_BASE_DIR" ]] && rm -rf "$TEST_BASE_DIR"
    rm -rf "$DOTKIT_ROOT/.test_temp"
    unset TEST_DIR
    unset TEST_BASE_DIR
    unset FIXTURES_DIR
    unset DEBIAN_FRONTEND
}

test_dk_on_registers_basic_hook() {
  my_func() { echo "Hello from my_func"; }
  dk_on "test_event" "my_func"
  _dk_finalize_hooks

  assert_equals "my_func" "${_DK_SORTED_HOOKS["test_event"]}"
}

test_dk_on_registers_hook_with_custom_order() {
  my_func() { echo "Hello from my_func"; }
  dk_on "test_event" "my_func" 10
  _dk_finalize_hooks

  assert_equals "my_func" "${_DK_SORTED_HOOKS["test_event"]}"
}

test_dk_on_overwrites_an_existing_hook_by_name() {
  func_a() { echo "Func A"; }
  dk_on "overwrite_event" "func_a" 10
  dk_on "overwrite_event" "func_a" 90 # Overwrite with new order
  _dk_finalize_hooks

  assert_equals "func_a" "${_DK_SORTED_HOOKS["overwrite_event"]}"
}

test_dk_on_adds_multiple_unique_hooks_to_an_event() {
  func_a() { echo "Func A"; }
  func_b() { echo "Func B"; }
  dk_on "multi_event" "func_a" 10
  dk_on "multi_event" "func_b" 20

  # Order of elements in associative array is not guaranteed, so check for both
  # Using grep to check for presence of both strings, as assert_match is not consistently available
  echo "${DK_HOOKS["multi_event"]}" | grep -q "func_a:10"
  assert_equals 0 "$?" "func_a:10 not found in DK_HOOKS[multi_event]"
  echo "${DK_HOOKS["multi_event"]}" | grep -q "func_b:20"
  assert_equals 0 "$?" "func_b:20 not found in DK_HOOKS[multi_event]"
  # Ensure no duplicates and correct count
  local count=$(echo "${DK_HOOKS["multi_event"]}" | wc -w)
  assert_equals 2 "$count"
}

test_dk_emit_executes_a_single_registered_hook() {
  my_func() { echo "Single hook executed"; }
  dk_on "single_event" "my_func"
  _dk_finalize_hooks # Finalize hooks for this test

  local output=$(dk_emit "single_event")
  assert_equals "Single hook executed" "$output"
}

test_dk_emit_executes_multiple_hooks_in_correct_order() {
  func_first() { echo "First"; }
  func_second() { echo "Second"; }
  func_third() { echo "Third"; }

  dk_on "ordered_event" "func_second" 50
  dk_on "ordered_event" "func_first" 10
  dk_on "ordered_event" "func_third" 90
  _dk_finalize_hooks # Finalize hooks for this test

  local output=$(dk_emit "ordered_event")
  assert_equals "First"$'\n'"Second"$'\n'"Third" "$output"
}

test_dk_emit_passes_arguments_to_hooks() {
  my_arg_func() { echo "Args: $1 $2"; }
  dk_on "arg_event" "my_arg_func"
  _dk_finalize_hooks # Finalize hooks for this test

  local output=$(dk_emit "arg_event" "arg1" "arg2")
  assert_equals "Args: arg1 arg2" "$output"
}

test_dk_emit_does_nothing_if_no_hooks_are_registered_for_an_event() {
  local output=$(dk_emit "non_existent_event")
  assert_equals "" "$output"
  # bashunit doesn't have direct status assertion, but if output is empty, it implies success
}

test_dk_load_hooks_loads_hooks_from_DK_DOTFILE_lib_dk_hooks_sh() {
  mkdir -p "$DK_DOTFILE/lib"
  cat > "$DK_DOTFILE/lib/dk_hooks.sh" <<EOF
dk_on "load_test_event" "dotfile_lib_hook"
dotfile_lib_hook() { echo "Dotfile Lib Hook"; }
EOF

  dk_load_hooks
  local output=$(dk_emit "load_test_event")
  assert_equals "Dotfile Lib Hook" "$output"
}

test_dk_load_hooks_loads_hooks_from_DK_DOTFILE_modules_lib_dk_hooks_sh() {
  mkdir -p "$DK_DOTFILE/modules/mod1/lib"
  mkdir -p "$DK_DOTFILE/modules/mod2/lib"

  cat > "$DK_DOTFILE/modules/mod1/lib/dk_hooks.sh" <<EOF
dk_on "load_test_event" "mod1_hook" 10
mod1_hook() { echo "Mod1 Hook"; }
EOF

  cat > "$DK_DOTFILE/modules/mod2/lib/dk_hooks.sh" <<EOF
dk_on "load_test_event" "mod2_hook" 20
mod2_hook() { echo "Mod2 Hook"; }
EOF

  dk_load_hooks
  local output=$(dk_emit "load_test_event")
  assert_equals "Mod1 Hook"$'\n'"Mod2 Hook" "$output"
}

test_dk_load_hooks_loads_hooks_from_DK_PROFILE_lib_dk_hooks_sh_and_overrides() {
  mkdir -p "$DK_DOTFILE/lib"
  mkdir -p "$DK_PROFILE/lib"

  cat > "$DK_DOTFILE/lib/dk_hooks.sh" <<EOF
dk_on "override_test_event" "common_hook" 10
common_hook() { echo "Dotfile Common Hook"; }
dk_on "override_test_event" "dotfile_only_hook" 20
dotfile_only_hook() { echo "Dotfile Only Hook"; }
EOF

  cat > "$DK_PROFILE/lib/dk_hooks.sh" <<EOF
dk_on "override_test_event" "common_hook" 5 # Profile should override and run first
common_hook() { echo "Profile Common Hook"; }
dk_on "override_test_event" "profile_only_hook" 30
profile_only_hook() { echo "Profile Only Hook"; }
EOF

  dk_load_hooks
  local output=$(dk_emit "override_test_event")
  # Expect profile's common_hook to override and run first, then dotfile_only, then profile_only
  assert_equals "Profile Common Hook"$'\n'"Dotfile Only Hook"$'\n'"Profile Only Hook" "$output"
}

test_dk_load_hooks_loads_hooks_from_DK_PROFILE_modules_lib_dk_hooks_sh_and_overrides() {
  mkdir -p "$DK_DOTFILE/modules/mod_common/lib"
  mkdir -p "$DK_PROFILE/modules/mod_common/lib"
  mkdir -p "$DK_PROFILE/modules/mod_profile/lib"

  cat > "$DK_DOTFILE/modules/mod_common/lib/dk_hooks.sh" <<EOF
dk_on "module_override_event" "mod_common_hook" 10
mod_common_hook() { echo "Dotfile Module Common Hook"; }
EOF

  cat > "$DK_PROFILE/modules/mod_common/lib/dk_hooks.sh" <<EOF
dk_on "module_override_event" "mod_common_hook" 5 # Profile module should override and run first
mod_common_hook() { echo "Profile Module Common Hook"; }
EOF

  cat > "$DK_PROFILE/modules/mod_profile/lib/dk_hooks.sh" <<EOF
dk_on "module_override_event" "mod_profile_hook" 15
mod_profile_hook() { echo "Profile Module Only Hook"; }
EOF

  dk_load_hooks
  local output=$(dk_emit "module_override_event")
  # Expect profile's mod_common_hook to override and run first, then profile_only
  assert_equals "Profile Module Common Hook"$'\n'"Profile Module Only Hook" "$output"
}

test_dk_load_hooks_handles_non_existent_paths_gracefully() {
  # No directories created, should not error
  dk_load_hooks
  # If no error, bashunit test passes
}

test_dk_load_hooks_with_100_modules() {
  local i
  local func_name
  local hook_file
  local expected_output=""
  local -a expected_funcs=()

  # Create 100 module directories with unique hooks
  for i in $(seq 1 100); do
    mkdir -p "$DK_DOTFILE/modules/mod$i/lib"
    hook_file="$DK_DOTFILE/modules/mod$i/lib/dk_hooks.sh"
    func_name="mod${i}_hook"
    local order=$(( RANDOM % 1000 )) # Random order

    cat > "$hook_file" <<EOF
dk_on "stress_test_event" "$func_name" $order
$func_name() { echo "$func_name"; }
EOF
    expected_funcs+=("$order:$func_name")
  done

  dk_load_hooks

  # Sort expected functions to compare with actual output
  local -a sorted_expected_funcs_names
  mapfile -t sorted_expected_funcs_names < <(printf "%s\n" "${expected_funcs[@]}" | sort -t':' -k1,1n | cut -d':' -f2)
  expected_output=$(IFS=$'\n'; echo "${sorted_expected_funcs_names[*]}")

  local output=$(dk_emit "stress_test_event")
  assert_equals "$expected_output" "$output"
}
