<img src="https://www.dotkit.app/dk-logo.svg" width="65" align="right">

# dk ln - safe symlink creation for dotkit

## overview

the `dk ln` command provides safe symlink creation functionality for the dotkit projects.\
it includes validation, user prompts for conflicts, and ensures all operations are restricted to the xdg_config_home directory for security.

## functions

### dk ln

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
# single symlink from dotfile layer
dk ln ~/.local/share/dk/current/dotfile/hyprland.conf ~/.config/hypr/hyprland.conf

# multiple symlinks from theme layer
dk ln \
    ~/.local/share/dk/current/theme/waybar/config ~/.config/waybar/config \
    ~/.local/share/dk/current/theme/rofi/config.rasi ~/.config/rofi/config.rasi \
    ~/.local/share/dk/current/theme/dunst/dunstrc ~/.config/dunst/dunstrc
```

##### relative paths

```bash
# using relative paths from within a dotfile directory
cd ~/.local/share/dk/dotfiles/my-dotfiles
dk ln \
    ./hypr/hyprland.conf ~/.config/hypr/hyprland.conf \
    ./waybar/config ~/.config/waybar/config \
    ./alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
```

### dk ln

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
    ["$HOME/.local/share/dk/dotfiles/my-hyprland/hypr/hyprland.conf"]="$HOME/.config/hypr/hyprland.conf"
    ["$HOME/.local/share/dk/dotfiles/my-hyprland/waybar/config"]="$HOME/.config/waybar/config"
    ["$HOME/.local/share/dk/dotfiles/my-hyprland/rofi/config.rasi"]="$HOME/.config/rofi/config.rasi"
)

# create symlinks using the array
dk ln dotfiles_map
```

## layered desktop environment integration


### dotfile layer application

example of how a dotfile applies its configurations
this would typically be in dk.dotfile.set.sh within a dotfile

```bash
#!/usr/bin/env bash

DOTFILE_PATH="$HOME/.local/share/dk/dotfiles/my-dotfiles"

# apply dotfile configurations
dk ln \
    "$DOTFILE_PATH/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf" \
    "$DOTFILE_PATH/waybar/config" "$HOME/.config/waybar/config" \
    "$DOTFILE_PATH/rofi/config.rasi" "$HOME/.config/rofi/config.rasi" \
    "$DOTFILE_PATH/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
```

### theme layer application

```bash
#!/usr/bin/env bash

# example of how a theme applies its customizations
# this would typically be in dk.theme.set.sh within a theme

DOTKIT_ROOT="$HOME/.local/share/dk"
THEME_NAME="catppuccin-mocha"
THEME_PATH="$DOTKIT_ROOT/themes/$THEME_NAME"

# apply theme-specific configurations (colors, styling)
if [[ -f "$THEME_PATH/hypr/colors.conf" ]]; then
    dk ln "$THEME_PATH/hypr/colors.conf" "$HOME/.config/hypr/colors.conf"
fi

if [[ -f "$THEME_PATH/waybar/style.css" ]]; then
    dk ln "$THEME_PATH/waybar/style.css" "$HOME/.config/waybar/style.css"
fi

# apply wallpaper
if [[ -f "$THEME_PATH/wallpaper.jpg" ]]; then
    dk ln "$THEME_PATH/wallpaper.jpg" "$DOTKIT_ROOT/current/wallpaper"
fi
```

### user profile customization

```bash
#!/usr/bin/env bash

# example of how a user profile overrides configurations
# this would typically be in dk.profile.set.sh within a user profile

DOTKIT_ROOT="$HOME/.local/share/dk"
PROFILE_NAME="my-profile"
PROFILE_PATH="$DOTKIT_ROOT/profiles/$PROFILE_NAME"

# override waybar with custom configuration
if [[ -f "$PROFILE_PATH/waybar/config" ]]; then
    dk ln "$PROFILE_PATH/waybar/config" "$HOME/.config/waybar/config"
fi

# add custom rofi themes
if [[ -d "$PROFILE_PATH/rofi/themes" ]]; then
    for theme_file in "$PROFILE_PATH/rofi/themes"/*.rasi; do
        if [[ -f "$theme_file" ]]; then
            theme_name=$(basename "$theme_file" .rasi)
            dk ln "$theme_file" "$HOME/.config/rofi/themes/$theme_name.rasi"
        fi
    done
fi

# custom keybindings or additional configs
if [[ -f "$PROFILE_PATH/hypr/keybindings.conf" ]]; then
    dk ln "$PROFILE_PATH/hypr/keybindings.conf" "$HOME/.config/hypr/keybindings.conf"
fi
```

### profile hook system integration

```bash
#!/usr/bin/env bash

# example of how dk ln integrates with the namespace hook system
# this shows how apps can use their own scripts while leveraging dk ln

# function to set up waybar with theme support
setup_waybar() {
    local waybar_config="$1"
    local waybar_style="$2"

    # link base configuration
    dk ln "$waybar_config" "$HOME/.config/waybar/config"

    # link style if provided
    if [[ -n "$waybar_style" && -f "$waybar_style" ]]; then
        dk ln "$waybar_style" "$HOME/.config/waybar/style.css"
    fi

    # restart waybar if it's running
    if pgrep waybar >/dev/null; then
        pkill waybar
        # waybar will be restarted by the hook system
    fi
}

# usage in a theme's dk.theme.set.sh
DOTKIT_ROOT="$HOME/.local/share/dk"
THEME_PATH="$DOTKIT_ROOT/current/theme"

if [[ -d "$THEME_PATH/waybar" ]]; then
    setup_waybar \
        "$THEME_PATH/waybar/config" \
        "$THEME_PATH/waybar/style.css"
fi
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

# build arguments for dk ln
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

1. **understand the layered approach**: familiarize yourself with how dotkit's layered desktop environment works (dotfile → theme → profile layers)
2. **use dotkit paths**: leverage `~/.local/share/dk/current/*` paths in your scripts for better integration
3. **validate layer availability**: check if layers exist before trying to link from them
4. **group related configurations**: create symlinks for related applications together for better error handling
5. **handle return codes**: properly handle the specific exit codes (0, 1, 125) in your scripts
6. **use associative arrays**: for complex configurations, use `dk_safe_symlink_array` with associative arrays
7. **implement error handling**: wrap dk ln calls in functions with proper error checking
8. **test with layered scenarios**: ensure your scripts work with the full dotkit layered structure
