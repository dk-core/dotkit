<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit goals

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs, the below is subject to change.

here are the main goals for dotkit, organized by user type. these clarify what each group wants to achieve with the system:

- **dotfiles maintainers:**
  - easily diagnose issues caused by their dotfiles, separate from user or theme configs
  - see clear, readable diffs when updating dotfiles, without extra tools
  - reliably test dotfiles in ci/cd pipelines
  - have precise control over when scripts run during the system lifecycle

- **theme maintainers:**
  - use a specific app instead of the dotfiles' default
  - ensure dotfiles updates don't break their theme
  - use a different wallpaper backend if needed
  - use a shell other than bash

- **users:**
  - choose their preferred app instead of the dotfiles' default
  - use any theme, but keep their preferred app, icon, or theme
  - mix and match features from different themes
  - use a different wallpaper backend
  - customize configuration without maintaining a full theme
  - set the same or different fonts for gtk, bars, and other components
  - control when scripts run during their system's lifecycle
  - use a shell other than bash
