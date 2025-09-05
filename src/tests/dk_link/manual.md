# manual testing guide for dk ln

- [manual testing guide for dk ln](#manual-testing-guide-for-dk-ln)
  - [prerequisites](#prerequisites)
    - [debug tips](#debug-tips)
  - [test automation](#test-automation)
  - [test cases](#test-cases)
    - [successful operation tests](#successful-operation-tests)
      - [test: creates single symlink](#test-creates-single-symlink)
      - [test: creates multiple symlinks](#test-creates-multiple-symlinks)
      - [test: creates target directories](#test-creates-target-directories)
    - [source validation tests](#source-validation-tests)
      - [test: rejects nonexistent sources](#test-rejects-nonexistent-sources)
      - [test: rejects multiple nonexistent sources](#test-rejects-multiple-nonexistent-sources)
      - [test: accepts existing sources](#test-accepts-existing-sources)
    - [conflict resolution tests](#conflict-resolution-tests)
      - [test: exits on existing file conflict](#test-exits-on-existing-file-conflict)
      - [test: prompts for existing symlink overwrite](#test-prompts-for-existing-symlink-overwrite)
      - [test: exits when user declines symlink overwrite](#test-exits-when-user-declines-symlink-overwrite)
      - [test: exits on multiple existing file conflicts](#test-exits-on-multiple-existing-file-conflicts)
      - [test: handles multiple existing symlink conflicts](#test-handles-multiple-existing-symlink-conflicts)
      - [test: exits when user declines multiple symlink overwrite](#test-exits-when-user-declines-multiple-symlink-overwrite)
      - [test: exits on mixed file and symlink conflicts](#test-exits-on-mixed-file-and-symlink-conflicts)
      - [test: handles broken symlink targets](#test-handles-broken-symlink-targets)
    - [error handling tests](#error-handling-tests)
      - [test: rejects empty arguments](#test-rejects-empty-arguments)
      - [test: rejects odd number of arguments](#test-rejects-odd-number-of-arguments)
    - [fallback tests (when gum is not available)](#fallback-tests-when-gum-is-not-available)
      - [test: fallback prompt yes](#test-fallback-prompt-yes)
      - [test: fallback exits on file conflict](#test-fallback-exits-on-file-conflict)

this guide provides step-by-step instructions for manually testing the `dk_link` command functionality.

## prerequisites

1. set up test environment:

   ```bash
   # create a temporary config directory for testing
   export tmpdir="$(mktemp -d)"

   # remember to clean up after you're done testing
   unset tmpdir
   ```

2. setup for manual testing:

   ```bash
   # Ensure the script is executable
   chmod +x src/lib/dk_link.sh

   # Test if you can run dk_link directly
   src/lib/dk_link.sh
   ```

### debug tips

1. use `DK_DEBUG=1` to enable debug logging. remember to unset it afterwards `unset DK_DEBUG`
2. verify paths with `realpath -m <path>` to see resolved absolute paths
3. use `ls -la` to check file types and permissions

## test automation

for automated testing, you can run the comprehensive test suite:

```bash
# run the automated tests
bash src/tests/run_tests.sh
```

## test cases

### successful operation tests

#### test: creates single symlink

```bash
# test creating a basic symlink
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/config.conf"

# verify the symlink was created
ls -la "$tmpdir/app1/config.conf"
readlink "$tmpdir/app1/config.conf"

# expected output: should show a symlink pointing to the source file

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: creates multiple symlinks

```bash
# test creating multiple symlinks in one command
src/lib/dk_link.sh \
  src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/config1.conf" \
  src/tests/dk_link/fixtures/test_sources/config2.conf "$tmpdir/app2/config2.conf"

# verify both symlinks were created
ls -la "$tmpdir/app1/config1.conf"
ls -la "$tmpdir/app2/config2.conf"
readlink "$tmpdir/app1/config1.conf"
readlink "$tmpdir/app2/config2.conf"

# expected output: both symlinks should exist and point to their respective source files

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: creates target directories

```bash
# test creating symlink in a nested directory that doesn't exist
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/new_app/subdir/config.conf"

# verify the directory structure was created
ls -la "$tmpdir/new_app/subdir/config.conf"
readlink "$tmpdir/new_app/subdir/config.conf"

# expected output: directory structure should be created and symlink should exist

# clean the temporary directory
rm -rf "$tmpdir"/*
```

### source validation tests

#### test: rejects nonexistent sources

```bash
# test that nonexistent source files are rejected
src/lib/dk_link.sh /nonexistent/file.conf "$tmpdir/app1/config.conf"

# expected output: should fail with error about missing source files
```

#### test: rejects multiple nonexistent sources

```bash
# test that multiple nonexistent sources are all reported
src/lib/dk_link.sh \
  /nonexistent1.conf "$tmpdir/app1/config1.conf" \
  /nonexistent2.conf "$tmpdir/app1/config2.conf"

# expected output: should fail and list all missing source files
```

#### test: accepts existing sources

```bash
# test that existing source files are accepted
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/config.conf"

# expected output: should succeed

# clean the temporary directory
rm -rf "$tmpdir"/*
```

### conflict resolution tests

#### test: exits on existing file conflict

```bash
# create an existing file
mkdir -p "$tmpdir/app1"
echo "existing content" > "$tmpdir/app1/existing.conf"

# try to create symlink over existing file
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/existing.conf"

# expected output: should exit with error about file being overwritten

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: prompts for existing symlink overwrite

```bash
# create an existing symlink
mkdir -p "$tmpdir/app1"
ln -s "/some/old/target" "$tmpdir/app1/existing_symlink.conf"

# try to create symlink over existing symlink
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/existing_symlink.conf"

# expected output: should show current symlink target and prompt to overwrite
# select 'y' or 'yes': symlink should be updated to new target

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: exits when user declines symlink overwrite

```bash
# create an existing symlink
mkdir -p "$tmpdir/app1"
ln -s "/some/old/target" "$tmpdir/app1/existing_symlink.conf"

# try to create symlink over existing symlink and decline
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/existing_symlink.conf"

# expected output: shoudl show current symlink target and prompt to overwrite
# select 'n' or 'no': operation should be cancelled with exit code 125

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: exits on multiple existing file conflicts

```bash
# create multiple existing files
mkdir -p "$tmpdir/app1" "$tmpdir/app2"
echo "existing content 1" > "$tmpdir/app1/existing1.conf"
echo "existing content 2" > "$tmpdir/app1/existing2.conf"
echo "existing content 3" > "$tmpdir/app2/existing3.conf"

# try to create multiple symlinks over existing files
src/lib/dk_link.sh \
  src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/existing1.conf" \
  src/tests/dk_link/fixtures/test_sources/config2.conf "$tmpdir/app1/existing2.conf" \
  src/tests/dk_link/fixtures/test_sources/config3.conf "$tmpdir/app2/existing3.conf"

# expected output: should exit with an error about multiple files being overwritten

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: handles multiple existing symlink conflicts

```bash
# create multiple existing symlinks
mkdir -p "$tmpdir/app1" "$tmpdir/app2"
ln -s "/some/old/target1" "$tmpdir/app1/existing1.conf"
ln -s "/some/old/target2" "$tmpdir/app1/existing2.conf"
ln -s "/some/old/target3" "$tmpdir/app2/existing3.conf"

# try to create multiple symlinks over existing symlinks
src/lib/dk_link.sh \
  src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/existing1.conf" \
  src/tests/dk_link/fixtures/test_sources/config2.conf "$tmpdir/app1/existing2.conf" \
  src/tests/dk_link/fixtures/test_sources/config3.conf "$tmpdir/app2/existing3.conf"

# expected output: should show a formatted list of symlinks with their current targets
# - if you answer 'y' or 'yes': all symlinks should be updated to new targets
# - if you answer 'n' or 'no': operation should be cancelled with exit code 125

# clean the temporary directory
rm -rf "$tmpdir"/* 
```

#### test: exits when user declines multiple symlink overwrite

```bash
# create multiple existing symlinks
mkdir -p "$tmpdir/app1" "$tmpdir/app2"
ln -s "/some/old/target1" "$tmpdir/app1/existing1.conf"
ln -s "/some/old/target2" "$tmpdir/app1/existing2.conf"
ln -s "/some/old/target3" "$tmpdir/app2/existing3.conf"

# try to create multiple symlinks over existing symlinks and decline
src/lib/dk_link.sh \
  src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/existing1.conf" \
  src/tests/dk_link/fixtures/test_sources/config2.conf "$tmpdir/app1/existing2.conf" \
  src/tests/dk_link/fixtures/test_sources/config3.conf "$tmpdir/app2/existing3.conf"

# expected output: operation should be cancelled with exit code 125

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: exits on mixed file and symlink conflicts

```bash
# create a mix of existing files and symlinks
mkdir -p "$tmpdir/app1" "$tmpdir/app2"
echo "existing file content 1" > "$tmpdir/app1/existing_file1.conf"
ln -s "/some/old/target1" "$tmpdir/app1/existing_symlink1.conf"
echo "existing file content 2" > "$tmpdir/app2/existing_file2.conf"
ln -s "/some/old/target2" "$tmpdir/app2/existing_symlink2.conf"

# try to create symlinks over the mixed conflicts
src/lib/dk_link.sh \
  src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/existing_file1.conf" \
  src/tests/dk_link/fixtures/test_sources/config2.conf "$tmpdir/app1/existing_symlink1.conf" \
  src/tests/dk_link/fixtures/test_sources/config3.conf "$tmpdir/app2/existing_file2.conf" \
  src/tests/dk_link/fixtures/test_sources/config4.conf "$tmpdir/app2/existing_symlink2.conf"

# expected output: should exit with error about overwriting files

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: handles broken symlink targets

```bash
# create symlink to non-existent target
mkdir -p "$tmpdir/app1"
ln -s "$tmpdir/nonexistent/target" "$tmpdir/app1/broken.conf"

# create a source file for this test
echo "test content" > "$tmpdir/source.conf"

# try to create symlink over broken symlink
src/lib/dk_link.sh "$tmpdir/source.conf" "$tmpdir/app1/broken.conf"

# expected output: should show current symlink target and prompt to overwrite, then update symlink

# clean the temporary directory
rm -rf "$tmpdir"/*
```

### error handling tests

#### test: rejects empty arguments

```bash
# test with no arguments
src/lib/dk_link.sh

# expected output: should fail with usage message
```

#### test: rejects odd number of arguments

```bash
# test with odd number of arguments
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf

# expected output: should fail with usage message

```

### fallback tests (when gum is not available)

#### test: fallback prompt yes

```bash
# simulate gum missing and run a command that would normally prompt
# this test verifies that the function works when gum is missing and no prompt is needed
src/lib/dk_link.sh src/tests/dk_link/fixtures/test_sources/config1.conf "$tmpdir/app1/new.conf"

# expected output: symlink should be created successfully without a prompt

# clean the temporary directory
rm -rf "$tmpdir"/*
```

#### test: fallback exits on file conflict

```bash
# simulate gum missing
# create existing file
mkdir -p "$tmpdir/app1"
echo "existing content" > "$tmpdir/app1/existing.conf"

# create a source file for this test
echo "test content" > "$tmpdir/source.conf"

# try to create symlink over existing file
src/lib/dk_link.sh "$tmpdir/source.conf" "$tmpdir/app1/existing.conf"

# expected output: should exit with error about file being overwritten (no prompt)

# clean the temporary directory
rm -rf "$tmpdir"/*
```
