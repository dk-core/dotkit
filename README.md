<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs, the below is subject to change.

## status

![progress-bar](https://progress-bar.xyz/1/?width=1000)
> see [#todo](./todo.md) for more info on progress

## overview

`dotkit` is a dotfiles manager designed for both dotfile maintainers and users.

- **for maintainers:** extensible module system, developer-friendly api, profile isolation
- **for users:** intelligent conflict resolution and easy import/export of configurations.

the project is built on four core principles:

1. **dotkit api:** a simple, consistent api for module/dotfile developers featuring:
2. **module system:** an extensible, language-agnostic component system using the above.
3. **dotfiles layer:** standardized, community-driven dotfile configurations leveraging both the above.
   - dotkit provides some [core modules](#core-modules) for optional, but common functionality
4. **user profiles:** composable user-specific customizations, the users home for all things dotfiles.

in the end, dotkit is what users interact with to install, manage, and configure their dotfiles.

## why?

dotfiles offer a personalized experience, but they can be difficult to share and adapt. dotkit simplifies dotfile management, making it more efficient and enjoyable.

ever wanted to try a program config for a day, or a full dotfile setup for a weekend? dotkit makes that possible.

the end goal is to enable true multi-platform, multi-session, and multi-user dotfile management. reinstalling an entire OS just to try a new dotfile setup isn't sustainable. however, this is a community-driven effort, and we need your help to build using dotkit to make this a reality.

dotkits modules extend beyond program configuration, offering a wide range of functionality from package management to system detection.

dotkit is developing the following core modules:

- [package management](docs/modules/packages.md)
- [gpu management](docs/modules/gpu.md)
- [system detection](docs/modules/system.md)
- more to come!

but these are just the beginning. build your own modules and share them with the community!
some ideas:

- session management
- file locking with `chattr`
- automated backups
- theme management & switching

anything you can do with on linux, you can do with dotkit.

## api summary

`dotkit` provides a rich set of bash helper functions for module & dotfile developers:

- **event management:**:
  - dotfiles/modules/users can call scripts on install, set, update, etc.
  - dotfile -> module -> user - user overrides default behavior
- **file & symlink helpers:**
  - `dk_link`: creates symlinks with advanced conflict resolution. can take an associative array for batch linking.
  - `dk_unlink` - deletes symlinks
- **logging helpers:** `dk_log`, `dk_warn`, `dk_error`, `dk_success` for structured, color-coded output.
- **user interaction:** `dk_ask`, `dk_choose`, `dk_input` for advanced user prompts
- **environment management:**  scripts have access to the full environment, including variables from the parent shell and all active modules
  - core paths `DK_CONFIG`, `DK_DOTFILE`, etc.
  - behavior flags `DK_INTERACTIVE`
  - all functions from dotkit, dotfile, and module scripts

## dotkit.toml

dotfiles, profiles, and modules will all be able to define their own configurations in a `dotkit.toml` file.

- metadata
- files - symlink definitions
- events - scripts to call on install, set, update, etc.

## module system design

the module system is the core of `dotkit`'s extensibility.
dotfiles will be able to install modules from the community to handle common tasks that end up being repeated across dotfiles.

- **core principles:** modules are language-agnostic (any script with a shebang / bash callable), extensible, annd self-contained

## cli interface

dotkit operates as a command-line tool with the module functions available through the module system:

```bash
# dotfile management
dotkit install github:user/my-dotfile  # install dotfile repository & immediately set as current
dotkit dotfile set my-dotfile          # set current dotfile to my-dotfile
dotkit unset dotfile                   # unsets current dotfile & profile

# profile management  
dotkit profile set dev               # switch to dev profile
dotkit profile unset                 # unsets current profile (using dotfile defaults)
```

## example user experience

```bash
# user installs hyde dotfiles
dotkit install github:hyde-project/hyde
# ...installs packages, some interactive prompts...

# hyde cli is automatically available
hyde theme list
hyde theme set catppuccin-mocha
hyde update
hyde status

# dotkit commands still work
dotkit profile set gaming
dotkit dotfile set my-dotfile # changes from hyde to my-dotfile

# hybrid commands work with hyde branding
hyde set  # uses hyde's custom set command
dotkit set  # uses dotkit's default set command
```

## marketplace

dotkit provides a centralized module registry and marketplace for dotfile maintainers to create cohesive, user-friendly configurations.

maintainers will be able to upload dotfiles and modules to the registry, and users will be able to install and update them with ease.

## documentation - wip

- [docs](./docs/docs.md)
- [dotfiles](./docs/dotfiles.md)
- [profiles](./docs/profiles.md)
- [modules](./docs/modules.md)
- [goals](./docs/goals.md)
- [marketplace](./docs/marketplace.md)
