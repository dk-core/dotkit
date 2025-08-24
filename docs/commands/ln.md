# dk ln - safe symlink creation for dotkit

## overview

the `dk_safe_symlink.sh` script provides safe symlink creation functionality for the dotkit project. it includes validation, user prompts for conflicts, and ensures all operations are restricted to the xdg_config_home directory for security.

## functions

### dk_safe_symlink

creates symlinks safely with validation and user prompts for conflicts.

#### usage

```bash
dk ln source1 target1 [source2 target2 ...]
```

#### parameters

- **source1, source2, ...**: source files/directories to link from
- **target1, target2, ...**: target paths where symlinks will be created

#### features

- **validation**: ensures all source files exist before creating any symlinks
- **security**: restricts all target paths to xdg_config_home (defaults to `~/.config`)
- **conflict detection**: identifies existing files and symlinks at target locations
- **user prompts**: interactive confirmation for overwriting existing symlinks
- **safe failure**: aborts operation if regular files would be overwritten
- **absolute paths**: converts relative source paths to absolute to prevent broken symlinks
- **directory creation**: automatically creates target directories as needed

#### return codes

- **0**: all symlinks created successfully
- **1**: general error (missing sources, validation failure, creation failure)
- **125**: user declined to overwrite existing symlinks

#### examples

##### basic usage

```bash
# single symlink
dk ln ~/.dotfiles/vimrc ~/.config/vim/vimrc

# multiple symlinks
dk ln \
    ~/.dotfiles/bashrc ~/.config/bash/bashrc \
    ~/.dotfiles/gitconfig ~/.config/git/config \
    ~/.dotfiles/tmux.conf ~/.config/tmux/tmux.conf
```

##### relative paths

```bash
# using relative paths (will be converted to absolute)
cd ~/.dotfiles
dk ln \
    ./configs/zshrc ~/.config/zsh/.zshrc \
    ./configs/alacritty.yml ~/.config/alacritty/alacritty.yml
```

### dk_safe_symlink_array

alternative function for use with associative arrays (requires bash 4+).

#### usage

```bash
dk ln array_name
```

#### parameters

- **array_name**: name of an associative array where keys are source paths and values are target paths

#### examples

##### basic array usage

```bash
#!/usr/bin/env bash

# declare associative array
declare -A dotfiles_map=(
    ["$HOME/.dotfiles/vimrc"]="$HOME/.config/vim/vimrc"
    ["$HOME/.dotfiles/bashrc"]="$HOME/.config/bash/bashrc"
    ["$HOME/.dotfiles/gitconfig"]="$HOME/.config/git/config"
)

# create symlinks using the array
dk ln dotfiles_map
```

##### dynamic array building

```bash
#!/usr/bin/env bash

# build array dynamically
declare -A config_links=()

# add configurations based on conditions
if [[ -f "$HOME/.dotfiles/zshrc" ]]; then
    config_links["$HOME/.dotfiles/zshrc"]="$HOME/.config/zsh/.zshrc"
fi

if [[ -f "$HOME/.dotfiles/tmux.conf" ]]; then
    config_links["$HOME/.dotfiles/tmux.conf"]="$HOME/.config/tmux/tmux.conf"
fi

if [[ -d "$HOME/.dotfiles/nvim" ]]; then
    config_links["$HOME/.dotfiles/nvim"]="$HOME/.config/nvim"
fi

# create all symlinks
dk ln config_links
```

## scripting examples

### loop-based configuration

```bash
#!/usr/bin/env bash

# define configurations to link
configs=(
    "bashrc:bash/bashrc"
    "zshrc:zsh/.zshrc"
    "vimrc:vim/vimrc"
    "gitconfig:git/config"
    "tmux.conf:tmux/tmux.conf"
)

# build arguments for dk_safe_symlink
args=()
for config in "${configs[@]}"; do
    IFS=':' read -r source_name target_path <<< "$config"
    source_file="$HOME/.dotfiles/$source_name"
    target_file="$HOME/.config/$target_path"
    
    if [[ -f "$source_file" ]]; then
        args+=("$source_file" "$target_file")
    else
        echo "warning: $source_file not found, skipping"
    fi
done

# create all symlinks at once
if [[ ${#args[@]} -gt 0 ]]; then
    dk ln "${args[@]}"
else
    echo "no valid configurations found to link"
fi
```

### conditional linking with arrays

```bash
#!/usr/bin/env bash

# function to conditionally add to symlink map
add_if_exists() {
    local -n map_ref=$1
    local source=$2
    local target=$3
    
    if [[ -e "$source" ]]; then
        map_ref["$source"]="$target"
        echo "added: $source -> $target"
    else
        echo "skipped: $source (not found)"
    fi
}

# build symlink map
declare -A symlink_map=()

# add various configurations
add_if_exists symlink_map "$HOME/.dotfiles/bashrc" "$HOME/.config/bash/bashrc"
add_if_exists symlink_map "$HOME/.dotfiles/zshrc" "$HOME/.config/zsh/.zshrc"
add_if_exists symlink_map "$HOME/.dotfiles/vimrc" "$HOME/.config/vim/vimrc"
add_if_exists symlink_map "$HOME/.dotfiles/gitconfig" "$HOME/.config/git/config"

# check for desktop environment specific configs
if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
    add_if_exists symlink_map "$HOME/.dotfiles/gtk-3.0" "$HOME/.config/gtk-3.0"
fi

if command -v i3 >/dev/null 2>&1; then
    add_if_exists symlink_map "$HOME/.dotfiles/i3" "$HOME/.config/i3"
fi

# create symlinks
if [[ ${#symlink_map[@]} -gt 0 ]]; then
    echo "creating ${#symlink_map[@]} symlinks..."
    dk ln symlink_map
else
    echo "no configurations to link"
fi
```

### error handling in scripts

```bash
#!/usr/bin/env bash

# function to handle symlink creation with error checking
safe_link_configs() {
    local dotfiles_dir="$1"
    local -a link_args=()
    
    # validate dotfiles directory
    if [[ ! -d "$dotfiles_dir" ]]; then
        echo "error: dotfiles directory '$dotfiles_dir' not found" >&2
        return 1
    fi
    
    # build symlink arguments
    while IFS= read -r -d '' config_file; do
        local relative_path="${config_file#$dotfiles_dir/}"
        local target_path="$HOME/.config/$relative_path"
        link_args+=("$config_file" "$target_path")
    done < <(find "$dotfiles_dir" -type f -name "*.conf" -print0)
    
    # create symlinks with error handling
    if [[ ${#link_args[@]} -eq 0 ]]; then
        echo "no .conf files found in $dotfiles_dir"
        return 0
    fi
    
    echo "linking ${#link_args[@]} configuration files..."
    if dk ln "${link_args[@]}"; then
        echo "successfully linked all configurations"
        return 0
    else
        local exit_code=$?
        case $exit_code in
            1)
                echo "error: failed to create some symlinks" >&2
                ;;
            125)
                echo "info: user cancelled symlink creation" >&2
                ;;
            *)
                echo "error: unknown error occurred (exit code: $exit_code)" >&2
                ;;
        esac
        return $exit_code
    fi
}

# usage
safe_link_configs "$HOME/.dotfiles/configs"
```

## security features

### xdg_config_home restriction

all target paths are validated to ensure they fall within the xdg_config_home directory (defaults to `~/.config`). this prevents accidental symlink creation outside the user's configuration directory.

```bash
# these will work (within ~/.config)
dk ln source.conf ~/.config/app/config.conf
dk ln source.conf $XDG_CONFIG_HOME/app/config.conf

# these will fail (outside ~/.config)
dk ln source.conf ~/config.conf          # error: outside xdg_config_home
dk ln source.conf /etc/config.conf       # error: outside xdg_config_home
```

### conflict handling

the script handles two types of conflicts:

1. **regular files**: operation aborts with error message, requiring manual backup
2. **existing symlinks**: user is prompted for confirmation to overwrite

## dependencies

- **bash 4+**: required for associative arrays (dk_safe_symlink_array function)
- **gum** (optional): enhanced user prompts; falls back to standard read if not available
- **realpath**: for path normalization (usually available on modern systems)

## best practices

1. **always validate sources exist** before calling the function (though the function does this too)
2. **use absolute paths** when possible to avoid confusion
3. **group related symlinks** in single function calls for better error handling
4. **handle return codes** appropriately in scripts
5. **test with dry-run** approach by echoing commands first in development
6. **use associative arrays** for complex configurations to improve readability
7. **implement proper error handling** in wrapper scripts
