<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# todo

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs, the below is subject to change.

## testing library

- using bashunit for bash testing

- [ ] headless installation of dotfiles
- [ ] programs installed correctly
- [ ] scripts produce expected output

## scripts - 40%

- [x] safe symlink function - [dk ln](./src/lib/dk_safe_symlink.sh)
- [x] logging & printing functions - [dk log](./src/lib/dk_logging.sh)

- [ ] add commands folder, revise build script
- [ ] rename scripts, remove dk prefix
- [ ] rename `dk ln` to `dk link`
- [ ] better test system
- [ ] command arg handler
- [ ] command flag handler
- [ ] logging command & args
- [ ] `dn ln` infers type, associative array or list of args
- [ ] args for `dn ln`
  - dry-run
  - force
  - non-interactive
- [ ] fix `dn ln` test printing
- style gum confirm
- remove theme layer, as we can support themes without it
  - themes go in the dotfiles dir, gitignored

init:

- [x] setup nix development environment with direnvs
- [x] implement basic logging system (`dk_log`, `dk_warn`, `dk_error`, `dk_success`, `dk_fail`)
- [x] implement basic symlink management (`dk_link`, `dk_unlink`)
- [ ] implement file system helpers (`dk_exists`, `dk_is_link`)
- [ ] implement environment management (`dk.env.set.sh`, `dk.env.unset.sh`)
- [ ] add intelligent conflict resolution (file vs symlink handling)
- [ ] implement module priority system (profile → dotfile)

testing:

- [ ] setup bashunit testing framework

toml:

- [ ] implement core toml parsing functions (`dk_toml_get`, `dk_toml_get_table`)
- [ ] implement file generation/scaffolding functions (`dk_generate_dotfile`, `dk_generate_profile`, `dk_generate_module`)
- [ ] toml validation `dk_profile_validate`, `dk_dotfile_validate`, `dk_module_validate`
- [ ] implement automatic module discovery and execution based on `module.toml` `dotfile.toml` `profile.toml`

first run:

- [ ] make a module that prints hello world
- [ ] make a dotfile that uses the module
- [ ] make a profile that overrides the module

- [ ] make a module that makes a config for some program

hello world release:

- [ ] releaserc with commitlint, semantic-release, and changelog
- [ ] setup package distribution (aur, homebrew, etc.)
- [ ] create automated release pipeline

hello world guides:

- [ ] revamp dotkit-web to fumadocs
- [ ] start creating core api documentation
- [ ] start making guides for dotfile development

- [ ] dotkit state `~/.local/state/dotkit/`

## configuration, init - 60%

- [ ] setup dkvm for dev
  - [ ] quickemu??

- no themes just dotfiles

- [ ] hyprland config
- [ ] waybar config
- [ ] walker config
- [ ] swaync config
- [ ] gtk theme
- [ ] font
- [ ] icons
- [ ] cursor
- [ ] qt theme

- hand feed dk configuration till its stable using new model
  - [ ] shell
  - [ ] hyprland
  - [ ] waybar
  - [ ] rofi
  - [ ] hand feed wallbash template temporarily to catpuccino mocha

- [ ] fully configure an initial dotfiles using the new model
- [ ] build scripts for install, set, update

## dotfiles - hyprland template - 70%

- [ ] move dotfiles to new template

## install script 50%

- [ ] install script for dotfiles, using the template
- [ ] create dkvm
- [ ] test install on bare metal

## testing, lots of testing 60%

- desktop (intelcpu, amdgpu, nvidiagpu)
- thinkpad (intelcpu)
- laptop (intelcpu, nvidiagpu)

will test on arch, debian, fedora, ubuntu, and nixos

## dk (cli) - 70%

bare bones cli for dk, just pulls in existing scripts in path and runs them
dotfiles / themes / users can use dotkit in their own bash scripts

## documentation - 80%

- [ ] revised readme
- [ ] dotkit guide
- [ ] theming guide
- [ ] user profile guide
- [ ] website

## misc & polish - 90%

## final release (100%)

## whats next?

- more templates
  - niri
  - x11 themes possible?

- more complex dotfiles
  - more info in [dk/hyde](#dkhyde)

- marketplace
  - more info in [marketplace](marketplace.md)

## notepad

- logging: use `logger -t dk` for logging instead of python logging
  - show errors with `logger -p user.err -t dk "ERROR: failed to apply theme"`
  - view with `journalctl --user -t dk -f`
- ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAuthentication=no vm@localhost

## dk/hyde

dotkit flavor of [HyDE](https://github.com/HyDE-Project/HyDE)

### what i plan to change / remove

1. **theme files**  
   - theme files will become raw configuration files for consistency, easier issue delegation, and full extensibility by users and theme maintainers.

2. **dynamic configuration**: get the **** out of .config!
   - configuration will use paths and symlinks for a single source of truth, clearer user overrides, and simplified file loading. get the hell out of .config!

3. **deprecate existing dk binaries**  
   - binaries such as `hyq`, `hydectl`, `hyde-config`, and `hyde-ipc` will be deprecated to avoid side effects, improve transparency, align with the bash/python theme, improve version control, and establish a single, well-documented CLI.

4. **eliminate theme patching**  
   - theme patching will be eliminated due to its high cost and to encourage direct use of theme system customization. wallbash files should be pregenerated from theme initialization.
  
5. **wallbash as a standalone cli**  
   - wallbash will become a standalone cli to enhance customizability, define dk's uniqueness, and support other wallpaper backends (e.g., pywall, wallust).

### what i plan on not changing

- **style-related aspects** for dk.
- **user -> theme -> hyde hierarchy** for configuration.

### what is the completed result

- significant performance improvements for hyde.
- enhanced ease of configuration and theming for users.
- full control for theme maintainers and users to extend hyde.
  - themes can extend hyde and users can extend both themes and hyde.
- one api will full visibility for theme maintainers and users.
  - better runtime status for understanding configuration, and for debugging

### dk/hyde todo

#### dk/hyde inventory

listing each app/feature and where it is configured as i go along
<details>
<summary><strong>existing <code>~/.config</code> files (click to expand)</strong></summary>

- **baloo**: `.config/baloofilerc`
- **Code (VSCode)**: `.config/Code/User/settings.json`
- **Code - OSS (VSCode OSS)**: `.config/Code - OSS/User/settings.json`
- **Codium (VSCodium)**: `.config/VSCodium/User/settings.json`
- **dolphin**: `.config/dolphinrc` `.config/kdeglobals`
- **dunst**: `.config/dunst/`
- **electron**: `.config/electron-flags.conf`
- **fastfetch**: `.config/fastfetch/`
- **fish (shell)**: `.config/fish/`
- **hypr (Hyprland)**: `.config/hypr/`
- **kitty (terminal)**: `.config/kitty/`
- **QT Theming**: `.config/Kvantum/`, `.config/qt5ct/`, `.config/qt6ct/`
- **libinput-gestures**: `.config/libinput-gestures.conf`
- **lsd**: `.config/lsd/`
- **MangoHud**: `.config/MangoHud/MangoHud.conf`
- **nwg-look**: `.config/nwg-look/config`
- **rofi**: `.config/rofi/theme.rasi`
- **satty**: `.config/satty/config.toml`
- **spotify**: `.config/spotify-flags.conf`
- **starship**: `.config/starship/`
- **swaylock**: `.config/swaylock/config`
- **systemd**: `.config/systemd/user/`
- **uwsm**: `.config/uwsm/`
- **vim**: `.config/vim/`
- **waybar**: `.config/waybar/`
- **wlogout**: `.config/wlogout/`
- **xsettingsd**: `.config/xsettingsd/xsettingsd.conf`
- **zsh (shell)**: `.config/zsh/`

</details>

<details>
<summary><strong>revised configs (click to expand)</strong></summary>

- **theming: including gtk/fonts/icons/cursors**:
  - **xsettingsd**: `.config/xsettingsd/xsettingsd.conf`
    - required for x apps
    - `killall -HUP xsettingsd` to reload
  - `.config/gtk-3.0/settings.ini`
    - required for gtk 3.0 backwards compatibility
  - `.config/nwg-look/config.toml`
    - might deprecate as dconf is more reliable
  - `.config/Kvantum/`
    - most likely needs to be symlinked to .config
  - `.config/hypr/themes/`
  - `.config/kitty/`
  - `.config/waybar/`
  - `.config/vim/`
  - `.config/rofi/theme.rasi`
  - `.config/dk/wallbash/`
  - `.config/dunst/`
- **fonts**:
- **icons**:
- **wallbash**:
  - tool for themes and profiles only
  - kvantum, gtk, waybar, rofi, kitty, hyprland, dunst, icons
  - dk -> wallbash -> theme -> user
  - anything overriding wallbash doesnt apply
- **keybindings & functions**:
  - `.config/hypr/keybindings.conf`
  - `.config/fish/functions/`
  - `.config/zsh/functions/`
- **hyprland**:
  - dk related switching, this will be included in the default themes `/current/hypr/animation/(name/config)` etc
    - `.config/hypr/animations/`.
    - `.config/hypr/shaders/`.
    - `.config/hypr/workflows/`.
- **Environment Variables**:
  - `.config/environment.d/`
    - this seems to be the one, works both in graphical and non-graphical sessions. all distros, login sessions, tty etc
  - `.config/uwsm/` - good for graphical wayland sessions
- **menus**:
  - `.config/menus/applications.menu`
- **notifications**:
  - `.config/dunst/`
- **bar**: - waybar
- **lock Screen**:
  - `.config/hypr/hyprlock/`
  - `.config/swaylock/config`
- **logout**: `.config/wlogout/`.

</details>

#### dk/hyde scripts and configs

scripts:

- [ ] app restarts
- [ ] wallpaper
- [ ] waybar
- [ ] dunst
- [ ] gtk theme
- [ ] font
- [ ] icons
- [ ] cursor
- [ ] qt theme

configs:

- [ ] hyprland
- [ ] zsh
- [ ] kitty
- [ ] waybar

wallbash cli:

- [ ] wallbash cli

#### dk/hyde cli

- [ ] wrap dk cli in hyde cli with some special features relating to hyde

#### initialize content

- [ ] scripts can be made temporarily to revise existing themes to new format
