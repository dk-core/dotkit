<img src="https://www.dotkit.app/dk-logo.svg" width="65" align="right">

# dotkit_link

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs, the below is subject to change.

## overview

the `dotkit_link` function provides safe symlink creation functionality for the dotkit projects.\
it includes validation, user prompts for conflicts

### usage

```bash
dotkit_link source1 target1 [source2 target2 ...]
```

```bash
declare -A dotfiles_map=(
    ["$DK_DOTFILE_PATH/hypr/hyprland.conf"]="$HOME/.config/hypr/hyprland.conf"
    ["$DK_DOTFILE_PATH/waybar/config"]="$HOME/.config/waybar/config"
    ["$DK_DOTFILE_PATH/rofi/config.rasi"]="$HOME/.config/rofi/config.rasi"
)

dotkit_link dotfiles_map
```

### parameters

dotkit_link can take two parameters for individual linking:

- **source1, source2, ...**: source files/directories to link from
- **target1, target2, ...**: target paths where symlinks will be created

```bash
dotkit_link source1 target1 [source2 target2 ...]
```

or ideally, an associative array of source paths and target paths:

```bash
declare -A dotfiles_map=(
    ["$DK_DOTFILE_PATH/hypr/hyprland.conf"]="$HOME/.config/hypr/hyprland.conf"
    ["$DK_DOTFILE_PATH/waybar/config"]="$HOME/.config/waybar/config"
    ["$DK_DOTFILE_PATH/rofi/config.rasi"]="$HOME/.config/rofi/config.rasi"
)

dotkit_link dotfiles_map
```

### return codes

- **0**: all symlinks created successfully
- **1**: general error (missing sources, validation failure, creation failure)
- **125**: user declined to overwrite existing symlinks

### examples

#### basic usage

```bash
# single symlink from dotfile layer
# Assumed environment variables (set by dotkit):
# DK_ROOT="$HOME/.local/share/dotkit"
# DK_DOTFILE="my-dotfile"
# DK_DOTFILE_PATH="$DOTKIT_ROOT/dotfiles/$DOTFILE"

dotkit_link $DK_DOTFILE_PATH/hypr/hyprland.conf $HOME/.config/hypr/hyprland.conf

# multiple symlinks from theme layer
dotkit_link \
    $DK_DOTFILE_PATH/waybar/config ~/.config/waybar/config \
    $DK_DOTFILE_PATH/rofi/config.rasi ~/.config/rofi/config.rasi \
    $DK_DOTFILE_PATH/dunst/dunstrc ~/.config/dunst/dunstrc
```

#### basic array usage

```bash
#!/usr/bin/env bash

# Assumed environment variables (set by dotkit):
# DK_ROOT="$HOME/.local/share/dotkit"
# DK_DOTFILE="my-dotfile"
# DK_DOTFILE_PATH="$DOTKIT_ROOT/dotfiles/$DOTFILE"

# declare associative array
declare -A dotfiles_map=(
    ["$DK_DOTFILE_PATH/hypr/hyprland.conf"]="$HOME/.config/hypr/hyprland.conf"
    ["$DK_DOTFILE_PATH/waybar/config"]="$HOME/.config/waybar/config"
    ["$DK_DOTFILE_PATH/rofi/config.rasi"]="$HOME/.config/rofi/config.rasi"
)

# create symlinks using the array
dotkit_link dotfiles_map
```

## scripting examples

### dotfile installation

example of how a dotfile applies its configurations
this should be in the hook `./lib/dk_install` within a dotfile and will get called automatically by dotkit

```bash
#!/usr/bin/env bash

# Assumed environment variables (set by dotkit):
# DK_ROOT="$HOME/.local/share/dotkit"
# DK_DOTFILE="my-dotfile"
# DK_DOTFILE_PATH="$DOTKIT_ROOT/dotfiles/$DOTFILE"

# apply dotfile configurations
dotkit_link \
    "$DK_DOTFILE_PATH/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf" \
    "$DK_DOTFILE_PATH/waybar/config" "$HOME/.config/waybar/config" \
    "$DK_DOTFILE_PATH/rofi/config.rasi" "$HOME/.config/rofi/config.rasi" \
    "$DK_DOTFILE_PATH/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
```

### user profile customization

```bash
#!/usr/bin/env bash
# example of how a user profile overrides configurations

# Assumed environment variables (set by dotkit):
# DK_ROOT="$HOME/.local/share/dotkit"
# DK_PROFILE="my-profile"
# DK_PROFILE_PATH="$DOTKIT_ROOT/profiles/$PROFILE_NAME"

# override waybar with custom configuration
if [[ -f "$PROFILE_PATH/waybar/config" ]]; then
    dotkit_link "$PROFILE_PATH/waybar/config" "$HOME/.config/waybar/config"
fi

# add custom rofi themes
if [[ -d "$PROFILE_PATH/rofi/themes" ]]; then
    for theme_file in "$PROFILE_PATH/rofi/themes"/*.rasi; do
        if [[ -f "$theme_file" ]]; then
            theme_name=$(basename "$theme_file" .rasi)
            dotkit_link "$theme_file" "$HOME/.config/rofi/themes/$theme_name.rasi"
        fi
    done
fi

# custom keybindings or additional configs
if [[ -f "$PROFILE_PATH/hypr/keybindings.conf" ]]; then
    dotkit_link "$PROFILE_PATH/hypr/keybindings.conf" "$HOME/.config/hypr/keybindings.conf"
fi
```
