#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Ask for sudo password at the beginning
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Running all installers..."

# Find all install-* scripts in the same directory as this script
# and execute them.
for installer in "$(dirname "$0")"/install-*; do
  if [ -f "$installer" ] && [ "$0" != "$installer" ]; then
    echo "Running $installer..."
    bash "$installer"
  fi
done

echo "All installers have been run."
