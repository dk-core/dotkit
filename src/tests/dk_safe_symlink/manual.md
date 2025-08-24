# Manual Testing Guide for dk_safe_symlink

This guide provides step-by-step instructions for manually testing the `dk ln` command functionality.

## Prerequisites

1. Set up test environment:

   ```bash
   # Create a temporary config directory for testing
   export TEST_CONFIG_HOME="$(mktemp -d)"
   export XDG_CONFIG_HOME="$TEST_CONFIG_HOME"
   echo "Test config directory: $TEST_CONFIG_HOME"
   ```

## Test Cases

### 1. Basic Functionality Tests

#### Test 1.1: Create a single symlink

```bash
# Test creating a basic symlink
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/config.conf"

# Verify the symlink was created
ls -la "$TEST_CONFIG_HOME/app1/config.conf"
readlink "$TEST_CONFIG_HOME/app1/config.conf"

# Expected output: Should show a symlink pointing to the source file
```

#### Test 1.2: Create multiple symlinks

```bash
# Test creating multiple symlinks in one command
nix run . -- ln \
  src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/config1.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config2.conf "$TEST_CONFIG_HOME/app2/config2.conf"

# Verify both symlinks were created
ls -la "$TEST_CONFIG_HOME/app1/config1.conf"
ls -la "$TEST_CONFIG_HOME/app2/config2.conf"
readlink "$TEST_CONFIG_HOME/app1/config1.conf"
readlink "$TEST_CONFIG_HOME/app2/config2.conf"

# Expected output: Both symlinks should exist and point to their respective source files
```

#### Test 1.3: Create symlink with nested directories

```bash
# Test creating symlink in a nested directory that doesn't exist
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/deep/nested/path/config.conf"

# Verify the directory structure was created
ls -la "$TEST_CONFIG_HOME/deep/nested/path/config.conf"
readlink "$TEST_CONFIG_HOME/deep/nested/path/config.conf"

# Expected output: Directory structure should be created and symlink should exist
```

### 2. Security Tests

#### Test 2.1: Reject paths outside XDG_CONFIG_HOME

```bash
# Test that absolute paths outside config home are rejected
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf /tmp/test.conf

# Expected output: Should fail with error about path being outside XDG_CONFIG_HOME
```

#### Test 2.2: Reject relative paths that escape config home

```bash
# Test that relative paths escaping config home are rejected
cd "$TEST_CONFIG_HOME"
nix run /home/richen/dev/dotkit -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf ../escape_attempt.conf

# Expected output: Should fail with error about path being outside XDG_CONFIG_HOME
```

### 3. Source Validation Tests

#### Test 3.1: Reject nonexistent source files

```bash
# Test that nonexistent source files are rejected
nix run . -- ln /nonexistent/file.conf "$TEST_CONFIG_HOME/app1/config.conf"

# Expected output: Should fail with error about missing source files
```

#### Test 3.2: Reject multiple nonexistent sources

```bash
# Test that multiple nonexistent sources are all reported
nix run . -- ln \
  /nonexistent1.conf "$TEST_CONFIG_HOME/app1/config1.conf" \
  /nonexistent2.conf "$TEST_CONFIG_HOME/app1/config2.conf"

# Expected output: Should fail and list all missing source files
```

### 4. Conflict Resolution Tests

#### Test 4.1: Handle existing file conflicts

```bash
# Create an existing file
mkdir -p "$TEST_CONFIG_HOME/app1"
echo "existing content" > "$TEST_CONFIG_HOME/app1/existing.conf"

# Try to create symlink over existing file
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/existing.conf"

# Expected output: Should warn about the file being overwritten
# Should prompt to backup the file
```

#### Test 4.2: Handle existing symlink conflicts

```bash
# Create an existing symlink
mkdir -p "$TEST_CONFIG_HOME/app1"
ln -s "/some/old/target" "$TEST_CONFIG_HOME/app1/existing_symlink.conf"

# Try to create symlink over existing symlink
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/existing_symlink.conf"

# Expected output: Should show current symlink target and prompt to overwrite
# - If you answer 'y' or 'yes': symlink should be updated to new target
# - If you answer 'n' or 'no': operation should be cancelled with exit code 125
```

#### Test 4.3: Handle multiple existing file conflicts

```bash
# Create multiple existing files
mkdir -p "$TEST_CONFIG_HOME/app1" "$TEST_CONFIG_HOME/app2"
echo "existing content 1" > "$TEST_CONFIG_HOME/app1/existing1.conf"
echo "existing content 2" > "$TEST_CONFIG_HOME/app1/existing2.conf"
echo "existing content 3" > "$TEST_CONFIG_HOME/app2/existing3.conf"

# Try to create multiple symlinks over existing files
nix run . -- ln \
  src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/existing1.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config2.conf "$TEST_CONFIG_HOME/app1/existing2.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config3.conf "$TEST_CONFIG_HOME/app2/existing3.conf"

# Expected output: Should fail with an error about multiple files being overwritten
# Should prompt to backup the files
```

#### Test 4.4: Handle multiple existing symlink conflicts

```bash
# Create multiple existing symlinks
mkdir -p "$TEST_CONFIG_HOME/app1" "$TEST_CONFIG_HOME/app2"
ln -s "/some/old/target1" "$TEST_CONFIG_HOME/app1/existing1.conf"
ln -s "/some/old/target2" "$TEST_CONFIG_HOME/app1/existing2.conf"
ln -s "/some/old/target3" "$TEST_CONFIG_HOME/app2/existing3.conf"

# Try to create multiple symlinks over existing symlinks
nix run . -- ln \
  src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/existing1.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config2.conf "$TEST_CONFIG_HOME/app1/existing2.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config3.conf "$TEST_CONFIG_HOME/app2/existing3.conf"

# Expected output: Should show a formatted list of symlinks with their current targets
# - If you answer 'y' or 'yes': all symlinks should be updated to new targets
# - If you answer 'n' or 'no': operation should be cancelled with exit code 125
```

#### Test 4.5: Handle mixed file and symlink conflicts

```bash
# Create a mix of existing files and symlinks
mkdir -p "$TEST_CONFIG_HOME/app1" "$TEST_CONFIG_HOME/app2"
echo "existing file content 1" > "$TEST_CONFIG_HOME/app1/existing_file1.conf"
ln -s "/some/old/target1" "$TEST_CONFIG_HOME/app1/existing_symlink1.conf"
echo "existing file content 2" > "$TEST_CONFIG_HOME/app2/existing_file2.conf"
ln -s "/some/old/target2" "$TEST_CONFIG_HOME/app2/existing_symlink2.conf"

# Try to create symlinks over the mixed conflicts
nix run . -- ln \
  src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/existing_file1.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config2.conf "$TEST_CONFIG_HOME/app1/existing_symlink1.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config3.conf "$TEST_CONFIG_HOME/app2/existing_file2.conf" \
  src/tests/dk_safe_symlink/fixtures/test_sources/config4.conf "$TEST_CONFIG_HOME/app2/existing_symlink2.conf"

# Expected output: Should show separate formatted lists for files and symlinks
# - Files will be listed first with a warning about overwriting
# - Symlinks will be listed second with their current targets
# - If you answer 'n' or 'no' to either prompt: operation should be cancelled with exit code 125
# - If you answer 'y' or 'yes' to both: all should be replaced/updated with new symlinks
```

### 5. Error Handling Tests

#### Test 5.1: Invalid argument count

```bash
# Test with no arguments
nix run . -- ln

# Expected output: Should fail with usage message

# Test with odd number of arguments
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf

# Expected output: Should fail with error about paired arguments
```

#### Test 5.2: Permission errors

```bash
# Test creating symlink in read-only directory (if applicable)
mkdir -p "$TEST_CONFIG_HOME/readonly"
chmod 444 "$TEST_CONFIG_HOME/readonly"

nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/readonly/config.conf"

# Expected output: Should fail with permission error
# Clean up
chmod 755 "$TEST_CONFIG_HOME/readonly"
```

### 6. Interactive Testing with gum

If `gum` is available in your environment, test the enhanced prompts:

#### Test 6.1: gum confirmation prompts

```bash
# Test with gum available - create conflict and observe the styled prompt
echo "existing content" > "$TEST_CONFIG_HOME/app1/gum_test.conf"
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/app1/gum_test.conf"

# Expected output: Should show a styled gum confirmation dialog
```

### 7. Debug Mode Testing

#### Test 7.1: Enable debug logging

```bash
# Enable debug mode
export DK_DEBUG=1

# Run a command and check system logs
nix run . -- ln src/tests/dk_safe_symlink/fixtures/test_sources/config1.conf "$TEST_CONFIG_HOME/debug_test/config.conf"

# Check debug logs (may require appropriate permissions)
journalctl -t dk --since "1 minute ago" | grep DEBUG

# Clean up
unset DK_DEBUG
```

## Verification Commands

After each test, you can use these commands to verify the results:

```bash
# Check if a file is a symlink
test -L "$TEST_CONFIG_HOME/path/to/file" && echo "Is symlink" || echo "Not symlink"

# Show symlink target
readlink "$TEST_CONFIG_HOME/path/to/file"

# Show detailed file information
ls -la "$TEST_CONFIG_HOME/path/to/file"

# Verify symlink points to correct target
if [[ "$(readlink "$TEST_CONFIG_HOME/path/to/file")" == "expected/target/path" ]]; then
    echo "✓ Symlink target correct"
else
    echo "✗ Symlink target incorrect"
fi
```

## Expected Exit Codes

- `0`: Success - all symlinks created successfully
- `1`: Error - validation failed, sources don't exist, or other errors
- `125`: User declined - user chose not to overwrite existing files/symlinks

## Cleanup

After testing, clean up the test environment:

```bash
# Remove test directory
rm -rf "$TEST_CONFIG_HOME"
unset TEST_CONFIG_HOME
unset XDG_CONFIG_HOME
```

## Troubleshooting

### Common Issues

1. **Permission denied**: Ensure the target directory is writable
2. **Command not found**: Ensure `bin/dotkit` is executable (`chmod +x bin/dotkit`)
3. **Source not found**: Verify the source file paths are correct and files exist
4. **Path outside config home**: Ensure all target paths are within `$XDG_CONFIG_HOME`

### Debug Tips

1. Use `DK_DEBUG=1` to enable debug logging
2. Check system logs with `journalctl -t dk`
3. Verify paths with `realpath -m <path>` to see resolved absolute paths
4. Use `ls -la` to check file types and permissions

## Test Automation

For automated testing, you can run the comprehensive test suite:

```bash
# Run the automated tests
cd src/tests/dk_safe_symlink
nix develop  # Enter development environment with bashunit
bashunit test_dk_safe_symlink.sh
```

This manual guide complements the automated tests and allows for interactive verification of the `dk ln` functionality.
