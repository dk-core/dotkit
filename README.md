<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs, the below is subject to change.

## status

![progress-bar](https://progress-bar.xyz/1/?width=1000)
> see [#todo](./todo.md) for more info on progress

## motivation

managing dotfiles across different setups is hard. copying configs by hand is messy, and sharing them with others is even harder. theres no real standards, every dotfile creates solutions for their own needs.

dotkit tries to fit a need: you can install, switch, and update your configs with just a few commands. you can also try out someone else’s setup for a day, all while keeping your custom profiles intact. the event & module system allows extensibility, and the marketplace makes it easy to share and install configs and modules.

the goal is simple: make desktop environments easy to use, share, and extend.

## overview

dotkit is a tool for managing dotfiles. it helps you organize, share, and switch between different setups. it works for both people who make & share dotfiles and people who just want to use them.

## core ideas

- **dotfiles:** collections of modules and scripts that are standalone, sharable and reusable by the community
  - build on top of the dotkit api
  - create or add modules and scripts to your dotfiles from the community marketplace
  - share your dotfiles with others, update them, and switch between them
- **profiles:** so you can keep different setups for different needs
  - still built on the dotkit api
  - allows safely extending and overriding dotfiles
  - able to be used standalone to create your own future dotfiles

the dotkit api:

- **modules:** composable systems for adding new features to either dotfiles or profiles
- **events** for running custom actions at certain times (like before or after installing)
- **links:** that safely links your config files where they need to go

dotkit cli:

- simple commands for installing, setting, and updating dotfiles
- dotfile and profile management

## modules

dotkit will start off with some core modules:

- logging
- [package management](docs/modules/packages.md)
- [gpu management](docs/modules/gpu.md)
- [system detection](docs/modules/system.md)
- migrations
- theme management

the usecases for modules are endless.

## cli usage

```bash
dotkit install github:user/my-dotfile

dotkit profile set my-dotfile-dev
dotkit profile set my-dotfile-gaming
```

## configuration

dotfiles, profiles, and modules use `dotkit.toml` for metadata, files, and events.
lets say we have a module called `waybar-module` on the dotkit marketplace.

```toml
name="waybar-module"
version="0.1.0"
description="waybar module"
type="module"

# automatically linked by dotkit event install and set
[files]
"waybar/config" = "~/.config/waybar/config"
"waybar/style.css" = "~/.config/waybar/style.css"

# automatically called by dotkit event pre_install
# shell commands, scripts, and functions are supported
# priority is by order of entry
[events.pre_install]
wb_install = "sudo pacman -S waybar"
wb_config = "scripts/extra-setup.sh"
wb_function = "custom_pre_install_function"

# automatically called by dotkit event post_set
[events.post_set]
wb_notify = "notify-send 'waybar config applied!'"
wb_script = "scripts/notify-extra.sh"
wb_set_function = "custom_post_set_function" # not to conflict with wb_function
```

to use this module, add it to your dotfile or profile:

```bash
dotkit module add github:user/waybar-module
# will prompt to add to your dotfiles or profiles
```

## marketplace

the [marketplace](https://dotkit.app) is a central place to share and discover dotfiles and modules. you can publish your own configs or modules for others to use, and find ready-made setups for popular tools. this makes it easy to:

- reuse configs and modules from the community
- keep your dotfiles up to date across machines
- contribute improvements or fixes to shared modules
- avoid duplicating work—build on what others have made

## docs

- [getting started](./docs/docs.md)
- [dotfiles](./docs/dotfiles.md)
- [profiles](./docs/profiles.md)
- [modules](./docs/modules.md)
- [goals](./docs/goals.md)
- [marketplace](./docs/marketplace.md)
