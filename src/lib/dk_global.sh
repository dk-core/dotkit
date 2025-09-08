#!/usr/bin/env bash

DK_LIB="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
export DK_LIB

### --- Lib ---

# shellcheck source=dk_logging.sh
source "$DK_LIB/dk_logging.sh"

# shellcheck source=dk_hooks.sh
source "$DK_LIB/dk_hooks.sh"

# shellcheck source=/dk_link.sh
source "$DK_LIB/dk_link.sh"

### --- Commands ---

