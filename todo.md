<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# todo

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs, the below is subject to change.

## scripts - 20%

- dk_link
  - `dk_link` infers type allows associative arrays as input additionally
  - as above, bring into the hooks system
  - add env handling

- add envs to dk_global.sh
  - dry-run
  - force / non-interactive
- implement file system helpers (`dk_exists`, `dk_is_link`, `dk_link_source`)

- dk_toml
  - tomlq  
  - implement core toml parsing functions (`dk_toml_get`, `dk_toml_get_table`)
  - something like `mapfile -t modules < <(tomlq -r '.files' */dotkit.toml)` to batch process a files array for example
  - implement file generation/scaffolding functions (`dk_generate_dotfile`, `dk_generate_profile`, `dk_generate_module`)
  - toml validation `dk_profile_validate`, `dk_dotfile_validate`, `dk_module_validate`
  - implement automatic module discovery and execution based on

- events - integration with all functions
  - events hold variables, eg _DK_POSTINSTALL_LINKS
  - pre/post install/set/update
    - pre install
      - install packages
    - post install
      - validate links
      - runs dk_link internally
  - use dk_hook
  - validate events
  - add handling for dotkit native hooks, pre/post install/set/update
  - add toml loading for hooks as a user friendly alternative to the dk_hooks.sh file
  
- dk_hooks
  - validation limited overwrite on named hooks like install/set/update, warning
  
- dk-logging
  - use bashunit logs by checking if the command exists for helpful logging messages during testing
  - should be 1-1 with debug logs
  - journalctl logging more robust?

## hello world + integration - 40%

first run:

- make a module that prints hello world
- make a dotfile that uses the module
- make a profile that overrides the module

hello world release:

- releaserc with commitlint, semantic-release, and changelog
- setup package distribution (aur, homebrew, etc.)
- create automated release pipeline

dotkit cli:

- dotkit status
- dotkit source command for use in bash scripts to source all dotkit functions
- dotkit state `~/.local/state/dotkit/`

dotkit-web:

- revamp dotkit-web to fumadocs
- start creating core api documentation
- start making guides for dotfile development

## further configuration, example dotfiles & modules - 60%

- create dotkitvm
  - use quickemu for dkvm
  - wraps quickemu, dotkit can load in the quickemu environment and run dotkit commands/init
  - named vm instances by date/time & commit
  - use snapshotting if supported
  - used to detect dotkit regressions and dotfile/module testing
  - something robust enough for users to use for testing their own dotfiles

- waybar module
- hyprland module
- rofi module
- swww module
- full dotfile using all parts

## testing, lots of testing 85%

- desktop (intelcpu, amdgpu, nvidiagpu)
- thinkpad (intelcpu)
- laptop (intelcpu, nvidiagpu)

will test on arch, debian, fedora, ubuntu, and nixos

CI/CD for dotkit
validation for dotkit-web publishing

## documentation - 90%

- revised readme
- dotkit guide
- theming guide
- user profile guide
- finalize website
  - login with github
  - publish modules and dotfiles  
  - can pull modules
  - can pull dotfiles

## misc & polish - 95%

## final release (100%)

## whats next?

- more templates
  - niri
  - x11 themes possible?

- more complex dotfiles
  - more info in [dk/hyde](#dkhyde)

## notepad

- logging: use `logger -t dk` for systemd
  - show errors with `logger -p user.err -t dk "ERROR: failed to apply theme"`
  - view with `journalctl --user -t dk -f`
- ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAuthentication=no vm@localhost
- bashinit.nix
  - confirm if i need any other scripts from src
  - add PR to nixpkgs

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

- app restarts
- wallpaper
- waybar
- dunst
- gtk theme
- font
- icons
- cursor
- qt theme

configs:

- hyprland
- zsh
- kitty
- waybar

wallbash cli:

- wallbash cli

#### dk/hyde cli

- wrap dk cli in hyde cli with some special features relating to hyde

#### initialize content

- scripts can be made temporarily to revise existing themes to new format
