#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(dirname "$(realpath "$0")")"

# Source global functions and variables
# shellcheck source=lib/dk_global.sh
source "$SRC_DIR/lib/dk_global.sh"

case "${1:-}" in
  *)      echo "Unknown command: ${1:-}" >&2; 
esac
