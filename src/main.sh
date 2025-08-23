#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(dirname "$(realpath "$0")")"

case "${1:-}" in
  *)      echo "Unknown command: $1" >&2; exit 1 ;;
esac
