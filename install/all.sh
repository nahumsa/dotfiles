#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

confirm_each=true

for argument in "$@"; do
  case "$argument" in
    --no-confirm)
      confirm_each=false
      ;;
    -h|--help)
      echo "Usage: $0 [--no-confirm]"
      exit 0
      ;;
    *)
      echo "Unknown option: $argument" >&2
      echo "Usage: $0 [--no-confirm]" >&2
      exit 1
      ;;
  esac
done

# Ask for sudo password at the beginning
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Running all installers..."

# Find all install-* scripts in the same directory as this script
# and execute them.
for installer in "$(dirname "$0")"/install-*; do
  if [ -f "$installer" ] && [ "$0" != "$installer" ]; then
    installer_name="$(basename "$installer")"

    if [[ "$confirm_each" == true ]]; then
      if ! read -r -p "Run ${installer_name}? [y/N] " confirmation; then
        confirmation=""
      fi
    else
      confirmation="yes"
    fi

    case "$confirmation" in
      y|Y|yes|YES|Yes)
        echo "Running $installer..."
        bash "$installer"
        ;;
      *)
        echo "Skipping $installer..."
        ;;
    esac
  fi
done

echo "All installers have been run."
