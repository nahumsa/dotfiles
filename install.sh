#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Run all installers
"./install/all.sh" "$@"
