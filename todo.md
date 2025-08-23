<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit progress 

- [dotkit progress](#dotkit-progress)
  - [status](#status)
  - [dk](#dk)
  - [what does this look like in practice?](#what-does-this-look-like-in-practice)
    - [how it works](#how-it-works)
    - [what is the full plan of LDE, layered desktop environment?](#what-is-the-full-plan-of-lde-layered-desktop-environment)
  - [user journeys](#user-journeys)
  - [todo](#todo)
    - [while below is in progress](#while-below-is-in-progress)
      - [testing library](#testing-library)
    - [scripts - 10%](#scripts---10)
    - [configuration, init - 30%](#configuration-init---30)
    - [dotfiles - hyprland template - 40%](#dotfiles---hyprland-template---40)
    - [install script 50%](#install-script-50)
    - [testing, lots of testing 60%](#testing-lots-of-testing-60)
    - [dk (cli) - 70%](#dk-cli---70)
    - [documentation - 80%](#documentation---80)
    - [misc \& polish - 90%](#misc--polish---90)
    - [final release (100%)](#final-release-100)
    - [whats next?](#whats-next)
  - [notepad](#notepad)
  - [dk/hyde](#dkhyde)
    - [what i plan to change / remove](#what-i-plan-to-change--remove)
    - [what i plan on not changing](#what-i-plan-on-not-changing)
    - [what is the completed result](#what-is-the-completed-result)
    - [dk/hyde todo](#dkhyde-todo)
      - [dk/hyde inventory](#dkhyde-inventory)
      - [dk/hyde scripts and configs](#dkhyde-scripts-and-configs)
      - [dk/hyde cli](#dkhyde-cli)
      - [initialize content](#initialize-content)

## status

![progress-bar](https://progress-bar.xyz/1/?width=1000)
> see [#todo](#todo) for more info on progress

## dk

- [ ] add dotfile layer to below, then add to readme

## what does this look like in practice?

**file structure:**

```bash
~/.local/share/dk/
├── current/
│   ├── profile/ -> ~/.local/share/dk/profiles/my-custom-profile/
│   ├── dotfile/ -> ~/.local/share/dk/dotfiles/my-dotfile/
│   ├── mode (light/dark)
│   └── wallpaper
├── profiles/
│   └── my-custom-profile/
│       ├── lib/
│       │   ├── dk.rofi.start.sh
│       │   └── dk.waybar.start.sh
│       └── waybar/
│           └── modules/
│               └── custom-module.json
└── dotfile/
    └── my-dotfile/
        ├── lib/
        │   ├── dk.dotfile.install.sh
        │   ├── dk.dotfile.set.sh
        │   └── dk.wallpaper.set.sh
        ├── hypr/
        │   └── hyprland.conf
        ├── waybar/
        │   └── config
        ├── walls/
        │   └── default.jpg
        └── vars
~/.config/waybar/
├── config -> ~/.local/share/dk/profile/waybar/config
└── modules/
    └── custom-module.json -> ~/.local/share/dk/current/profile/waybar/modules/custom-module.json
~/.config/hypr/
└── hyprland.conf -> ~/.local/share/dk/current/dotfile/hypr/hyprland.conf
~/.config/rofi/ (directory does not exist, as user has disabled rofi)
~/.config/wofi/
└── config -> ~/.local/share/dk/current/profile/wofi/config (example)
```

### how it works

1. **dk base layer:** dk provides core functionalities and default scripts (e.g., in `$home/.local/share/dk/lib`).
2. **dotfile layer (`my-dotfile`):** `~/.local/share/dk/current/dotfile/` symlinks to `~/.local/share/dk/dotfiles/my-dotfile/`. theme's `dk.theme.set.sh` symlinks its `hyprland.conf` to `~/.config/hypr/hyprland.conf` and `waybar/config` to `~/.config/waybar/config`.
3. **themes layer (`my-theme`):** if the dotfiles support themes, `~/.local/share/dk/current/theme/` symlinks to `~/.local/share/dk/themes/my-theme/`. theme's `dk.theme.set.sh` symlinks its `hyprland.conf` to `~/.config/hypr/hyprland.conf` and `waybar/config` to `~/.config/waybar/config`.
4. **user profile layer (`my-custom-profile`):** `~/.local/share/dk/current/profile/` symlinks to `~/.local/share/dk/profiles/my-custom-profile/`.
    - **override rofi with wofi:** user creates `/lib/dk.rofi.start.sh` with `exit 0` (disabling rofi) and `/lib/dk.wofi.start.sh` (starting wofi). any config referencing `dk.rofi.start.sh` now calls `dk.wofi.start.sh`.
    - **custom waybar module:** user places `custom-module.json` in `/waybar/modules/`. `/lib/dk.waybar.start.sh` loads theme's waybar config, modifies it to include the custom module, and symlinks the result to `~/.config/waybar/config`. this script overrides any theme/dk waybar script.

### what is the full plan of LDE, layered desktop environment?

1. **namespaced lifecycle hook system**
   - runs as a systemd service for easy lifecycle management
   - loads PATH, in order of hierarchy:
     - `$HOME/.local/share/dk/lib"`
     - `$HOME/dk/current/dotfile/lib"`
     - `$HOME/dk/current/theme/lib"`
     - `$HOME/dk/current/profile/lib"`
     - (dk -> theme -> user) - user named scripts override all
   - namespace system (*this will be subject to change*)
     - `dk.<var>.*.sh`
       - lib - lib namespace - anything dk needs to be sure is loaded first
       - dotfile - dotfile namespace
       - theme - theme namespace
       - profile - profile namespace
       - last name overwrites *all* - eg. user `dk.dotfile.set.sh` overrides theme `dk.dotfile.set.sh`
     - `dk.*.<var>.sh`
        - `start, restart, stop, status, set, next, prev`
        - `install/uninstall` may become one but that may become too complex
     - example: `dk.foo.restart.sh` -> restarts foo
     - allows themes and users can define multiple apps into their own namespace
     - these scripts can be referenced to configuration files provided in themes and user profiles
     - `dk/lib` provides helper functions to help user and theme maintainers
     - examples (both theme maintainers and users):
       - "I want to override theme setting functionality"
         - `dk.theme.set.sh` - revise to `~/.local/share/dk/(dotfiles/profiles/themes)/(my-dotfile/my-profile/my-theme)/lib/dk.theme.set.sh`
       - "I want to use wofi instead of rofi"
         - `dk.rofi.start.sh` - set to `exit 0` in `~/.local/share/dk/(profiles/themes)/(my-profile/my-theme)/lib/dk.rofi.start.sh`
         - create `dk.wofi.start.sh` in `~/.local/share/dk/(profiles/themes)/(my-profile/my-theme)/lib/`
         - set `dk.rofi.start.sh` to `dk.wofi.start.sh` in `~/.local/share/dk/(profiles/themes)/(my-profile/my-theme)/lib/dk.rofi.start.sh`

2. **namespaced dotfiles system**
   - dotfiles system will 

3. **namespaced theme system**
   - theme system will be namespaced to allow for easier extension of dk.
   - paths:
     - `~/.local/share/dk/current/wallpaper` - path to the current wallpaper
   - paths for theme maintainers:
     - `~/.local/share/dk/current/theme/` - symlinked folder to `~/.local/share/dk/themes/`
     - `~/.local/share/dk/current/theme/lib` - allows for themes to add lib functions to dk
       - important files:
       - `~/.local/share/dk/current/theme/dk.theme.install.sh` - installs the theme - anything required for the theme to work
       - `~/.local/share/dk/current/theme/dk.theme.set.sh` - sets the theme
       - `~/.local/share/dk/current/theme/dk.wallpaper.set.sh` - sets the wallpaper
     - `~/.local/share/dk/current/theme/mode` - `dark/light` mode for the theme, sets `~/.local/share/dk/current/mode`
     - `~/.local/share/dk/current/theme/walls/` - wallpapers
     - `~/.local/share/dk/current/theme/vars`
       - variables for the theme. defaults are gtk theme, font, cursor, icons. additional variables can be added but can cause collisions
     - `~/.local/share/dk/current/theme/*/*` - any files in folders can be referenced by the theme
        - example: `~/.local/share/dk/current/theme/waybar/*` can be symlinked to `~/.config/waybar/*`
        - themes and profiles will use their own custom `dk.theme.set.sh` and `dk.profile.set.sh` to create the theme in the right directories

4. **user profile system**
   - same namespace system as themes, but for user profiles
   - user profiles will be stored in `~/.local/share/dk/profiles/`.
   - `~/.local/share/dk/current/profile/` - symlinked folder to `~/.local/share/dk/profiles/`
   - ensures user configurations are on top of dk and theming
   - users allowed to have multiple profiles
   - designed to modify `/currrent/*` namespace, allowing users to modify themes
   - user lib functions for each app will be stored in `~/.local/share/dk/profiles/*/lib/`.

## user journeys

here are some needs users will have, the goal is to meet them with the proposed changes, you'll notice some duplicates!

- **dotfiles maintainers:**
  - "I want to be able to diagnose issues that have been caused by my dotfilesalone and not have to worry about theme and user configurations."
  - "I want easy to read diffs while updating and not have to worry about tooling."
  - "I want to be able to test dotfiles via ci/cd"
  - "I want to control when scripts are run in the lifecycle the users system"

- **themes maintainers:**
  - "I want my theme to have ***x*** app instead of ***y*** dotfiles default."
  - "I want dotfiles updates to not break my theme."
  - "I want to use a different wallpaper backend."
  - "I want to use something other than bash!"

- **users:**
  - "I want my *system* to have ***x*** app instead of ***y*** dotfiles default."
  - "I like all the themes, but I want them to use ***my*** app instead of ***their*** app/icon/theme/etc."
  - "I like this from a theme and that from another theme"
  - "I want to use a different wallpaper backend."
  - "I don't want to have to maintain a theme in order to get the configuration I want"
  - "I want the same/different fonts for gtk/bar/
  - "I want to control when scripts are run in the lifecycle of *my* system"
  - "I want to use something other than bash!"

## todo

### while below is in progress

#### testing library

in order for dk to maintained long term, dk needs a fully integrated testing library\
some scripts can run via github actions headlessly, while others will require a graphical target\
additionally, users need to have checks and balances to ensure dk is working as intended on their system, at runtime (more on the [dk cli](#dk-cli---70) section)

- using bashunit for bash testing

- [ ] headless installation of dotfiles
- [ ] programs installed correctly
- [ ] scripts produce expected output

### scripts - 10%

- [ ] lib, helper functions
  - [ ] safe symlink function
  - [ ] logging functions
  - [ ] printing functions
  - [ ] status script
    - [ ] small version print
    - [ ] shows current dotfile
    - [ ] shows current profile
    - [ ] shows current theme
    - [ ] shows symlink status of dotfiles shorthand
    - [ ] minified error output if any
    - [ ] disclaimer for dotfiles & themes
    - [ ] dotfile/theme status --diff for showing diffable view that can be compared to default dotfile/theme
  - [ ] tools for dotfile maintainers
    - [ ] dotfile/theme installation
    - [ ] set dotfile/theme
    - [ ] update dotfile/theme
    - [ ] migration tool
    - [ ] supported systems
    - [ ] supported package managers
    - [ ] supported desktop environments
    - [ ] get user packages
- [ ] "current" system
- [ ] namespace hook system
- [ ] dotfile layer
- [ ] theme layer
- [ ] profile layer
- [ ] status script

### configuration, init - 30%

- [ ] hyprland config
- [ ] waybar config
- [ ] rofi config
- [ ] dunst config
- [ ] gtk theme
- [ ] font
- [ ] icons
- [ ] cursor
- [ ] qt theme

- [ ] setup dknix vm within this repo
  - only for faster testing. just nixos packages no envs no home-manager, and copied files to play with

- hand feed dk configuration till its stable using new model
  - [ ] shell
  - [ ] hyprland
  - [ ] waybar
  - [ ] rofi
  - [ ] /current/theme using catpuccino mocha
  - [ ] hand feed wallbash template temporarily to catpuccino mocha

- [ ] fully configure an initial theme using the new model

### dotfiles - hyprland template - 40%

- [ ] move dotfiles to new template

### install script 50%

- [ ] install script for dotfiles, using the template
- [ ] update dkvm for new install script
- [ ] test install on bare metal

### testing, lots of testing 60%

- desktop (intelcpu, amdgpu, nvidiagpu)
- thinkpad (intelcpu)
- laptop (intelcpu, nvidiagpu)

### dk (cli) - 70%

bare bones cli for dk, just pulls in existing scripts in path and runs them
dotfiles / themes / users can use dotkit in their own bash scripts

### documentation - 80%

- [ ] revised readme
- [ ] dotkit guide
- [ ] theming guide
- [ ] user profile guide
- [ ] website

### misc & polish - 90%

### final release (100%)

### whats next?

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
