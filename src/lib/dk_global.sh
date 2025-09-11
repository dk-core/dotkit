#!/usr/bin/env bash

DK_LIB="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# TODO: remove hardcoded dotfile/profile paths
DK_DOTFILE="$HOME/.config/dotkit/dotfiles/testdotfile"
DK_PROFILE="$HOME/.config/dotkit/profiles/testprofile"
export DK_DOTFILE DK_PROFILE

### --- Globals ---

# dotkit version
DOTKIT_VERSION="$(cat "$DK_LIB/VERSION")"
export DOTKIT_VERSION

# shellcheck source=dk_logging.sh
source "$DK_LIB/dk_logging.sh"

# shellcheck source=dk_events.sh
source "$DK_LIB/dk_events.sh"

# shellcheck source=/dk_link.sh
source "$DK_LIB/dk_link.sh"

### --- Events ---

# Manually source event scripts
