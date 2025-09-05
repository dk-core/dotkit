#!/usr/bin/env bash

this_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

### --- Lib ---

# shellcheck source=dk_logging.sh
source "$this_dir/dk_logging.sh"


### --- Commands ---

# shellcheck source=/dk_link.sh
source "$this_dir/dk_link.sh"
