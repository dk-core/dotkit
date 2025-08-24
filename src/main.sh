#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(dirname "$(realpath "$0")")"

# Source required libraries
source "$SRC_DIR/lib/dk_logging.sh"
source "$SRC_DIR/lib/dk_safe_symlink.sh"

case "${1:-}" in
  ln)     shift; dk_safe_symlink "$@" ;;
  *)      echo "Unknown command: ${1:-}" >&2; echo "Usage: dk ln <source> <target> [source2 target2 ...]" >&2; exit 1 ;;
esac
