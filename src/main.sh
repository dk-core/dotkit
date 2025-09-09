#!/usr/bin/env bash
set -euo pipefail

DOTKIT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export DOTKIT_ROOT

# shellcheck source=lib/dk_global.sh
source "$DOTKIT_ROOT/lib/dk_global.sh"

command="${1:-}"

case "$command" in
  version)
    echo "dotkit version $DOTKIT_VERSION"
    ;;
  status)
    echo "dotkit is a work in progress"
    ;;
  *)
    if [[ -n "$command" ]]; then
      echo "Unknown command: $command" >&2
    else
      echo "No command specified." >&2
    fi
    ;;
esac
