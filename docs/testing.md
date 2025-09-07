<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit/testing - streamlined bashunit testing

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs.

## overview

This guide outlines the new, streamlined approach to testing `dotkit` using `bashunit`. We've introduced a global configuration to simplify test execution and improve debugging.

### test helpers

`src/tests/test_helper.sh` provides a set of functions and variables that simplify test setup and teardown

### running tests

To run all tests, simply execute `bashunit` from the project root:

```bash
bashunit
```

To run a specific test file:

```bash
bashunit src/tests/your_test_file.test.sh
```

To run tests matching a specific name (using a filter):

```bash
bashunit --filter "your_test_name"
```

### debugging tests

For even more detailed debugging, you can use the `-vvv` flag:

```bash
bashunit -vvv src/tests/your_test_file.sh
```

futhermore, you can use `--debug` to enable debug mode for a specific test file:

```bash
bashunit --debug src/tests/your_test_file.sh
```

### writing new tests

1. Create a new test file in the `src/tests` directory (or a subdirectory within `src/tests`).
2. Name your test file following the `*.test.sh` convention (e.g., `my_test.test.sh`).
3. Inside your test file, define functions starting with `test_` for your test cases.
4. Use `bashunit` assertions to validate your code's behavior.

Example `src/tests/example_test.test.sh`:

```bash
#!/usr/bin/env bash

# shellcheck source=../main.sh
source "$DOTKIT_ROOT/main.sh" api source

function test_example_function_returns_success() {
  # Call the function you want to test
  local result
  result=$(your_function_to_test) # Replace with your actual function call

  # Assertions
  assert_equals "expected_output" "$result"
}

function test_another_example() {
  assert_true "1 -eq 1"
}
```

Remember that `src/tests/test_helper.sh` provides `global_setup`, `global_teardown`, `setup`, and `teardown` functions, as well as helper functions like `create_test_file` and `mock_gum_yes` that you can use in your tests.
