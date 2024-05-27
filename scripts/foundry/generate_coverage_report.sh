#!/bin/bash

# Generate lcov.info
forge coverage --report lcov

# Install lcov if not installed
if ! command -v lcov &>/dev/null; then
  echo "lcov is not installed. Installing..."
  sudo apt-get install -y lcov
fi

lcov --version

# Exclude test, mock, and node_modules folders
EXCLUDE="*test* *mocks* *node_modules* *scripts* *lib*"
lcov --rc lcov_branch_coverage=1 --ignore-errors unused --ignore-errors inconsistent --remove lcov.info $EXCLUDE --output-file forge-pruned-lcov.info

# Generate HTML report if not running in CI
if [ "$CI" != "true" ]; then
  genhtml forge-pruned-lcov.info --branch-coverage --ignore-errors deprecated,inconsistent,corrupt --output-directory coverage/foundry
  open coverage/foundry/index.html
fi
