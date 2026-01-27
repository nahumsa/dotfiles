#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define locations
export INSTALL_PATH="./install"

# Install
source "$INSTALL_PATH/all.sh"

