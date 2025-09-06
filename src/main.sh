#!/usr/bin/env bash
set -euo pipefail

DOTKIT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export DOTKIT_ROOT

# shellcheck source=/lib/dk_global.sh
source "$DOTKIT_ROOT/lib/dk_global.sh"

command="${1:-}"
subcommand="${2:-}"

case "$command" in
  status)
    echo "dotkit is a work in progress"
    ;;
  api)
    case "$subcommand" in
      source)
        # shellcheck source=lib/dk_global.sh
        "$DOTKIT_ROOT/lib/dk_global.sh"
        ;;
      *)
        echo "Unknown command for 'dotkit api': ${subcommand}" >&2
        exit 1
        ;;
    esac
    ;;

  *)
    if [[ -n "$command" ]]; then
      echo "Unknown command: $command" >&2
    else
      echo "No command specified." >&2
    fi
    exit 1
    ;;
esac
