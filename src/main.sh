#!/usr/bin/env bash
set -euo pipefail

DOTKIT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export DOTKIT_ROOT

# shellcheck source=lib/dk_global.sh
source "$DOTKIT_ROOT/lib/dk_global.sh"

command="${1:-}"

dk_install_error() {
  header=$(gum style --border rounded --border-foreground "#FF8C00" --foreground "#F0F0F0" --align left --padding "0 1" "📦 dotkit install: errors")
  subtitle=$(gum style --foreground "8" --align left --width 60 --margin "0 0 1 0" "support & contribute: https://github.com/dk-core/dotkit")
  echo "$header"
  echo "$subtitle"
  gum spin --spinner.foreground "#FF8C00" --title "Checking for install errors..." -- sleep 2
  # Hook conflicts (pseudo, with real conflict example)
  hook_conflicts=$(gum join --vertical \
    "$(gum style --foreground "#F0F0F0" "warning: hook conflicts - use --suppress to ignore")" \
    "$(gum style --foreground "#E0AF68" "  • pre_install")" \
    "$(gum style --foreground "#E0AF68" "      - warning: dotfile:setup_env overwritten by profile:/events/dk_events.sh")" \
  )
  # Filesystem conflicts
 symlink_warnings=$(gum join --vertical \
    "$(gum style --foreground "#F0F0F0" "warning: symlink conficts")" \
    "$(gum style --foreground "#E0AF68" "  symlink: dotfile:/.zshrc -> /home/richen/.zshrc")" \
    "$(gum style --foreground "#E0AF68" "  symlink: profile:/.tmux.conf -> /home/richen/.tmux.conf")" \
  )
  raw_errors=$(gum join --vertical \
    "$(gum style --foreground "#F0F0F0" "error: raw conflicts - please backup manually")" \
    "$(gum style --foreground "#F7768E" "  raw: dotfile:/.bashrc -> /home/richen/.bashrc")" \
    "$(gum style --foreground "#F7768E" "  raw: profile:/.profile -> /home/richen/.profile")" \
  )
  # Summary (white)
  summary=$(gum join --vertical \
    "$(gum style --foreground "#F0F0F0" "summary:")" \
    "$(gum style --foreground "#F0F0F0" "  events: 10 hook_warnings: 1 || symlinks: 53 symlink_warnings: 2  raw_errors: 2")" \
  )
  gum join --vertical "$hook_conflicts" "$symlink_warnings" "$raw_errors" "$summary"
}

case "$command" in
  version)
    echo "dotkit version $DOTKIT_VERSION"
    ;;
  install)
    dk_load_events
    dk_emit pre_install
    dk_emit install
    dk_emit post_install
    ;;
  error)
    dk_install_error
    ;;
  source)
    ;;
  *)
    if [[ -n "$command" ]]; then
      echo "Unknown command: $command" >&2
    else
      echo "No command specified." >&2
    fi
    ;;
esac
