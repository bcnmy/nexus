#!/bin/bash

# Generate lcov.info
yarn coverage:forge --report lcov

# Install lcov if not installed
if ! command -v lcov &>/dev/null; then
  echo "lcov is not installed. Installing..."
  sudo apt-get install -y lcov
fi

lcov --version

# Create the necessary directories if they do not exist
mkdir -p coverage/foundry

# Exclude test, mock, and node_modules folders
EXCLUDES=("*test*" "*mocks*" "*node_modules*" "*scripts*" "*lib*")
lcov --rc lcov_branch_coverage=1 --ignore-errors unused --ignore-errors inconsistent --remove lcov.info "${EXCLUDES[@]}" --output-file coverage/foundry/forge-pruned-lcov.info

# Remove the original lcov.info file and coverage.json
rm -f lcov.info coverage.json

# Check if the coverage file is created
if [ -f coverage/foundry/forge-pruned-lcov.info ]; then
  echo "Foundry coverage report generated successfully."
else
  echo "Failed to generate Foundry coverage report."
  exit 1
fi

# Generate HTML report if not running in CI
if [ "$CI" != "true" ]; then
  genhtml coverage/foundry/forge-pruned-lcov.info --ignore-errors deprecated,inconsistent,corrupt --output-directory coverage/foundry
  if command -v xdg-open &>/dev/null; then
    xdg-open coverage/foundry/index.html
  elif command -v open &>/dev/null; then
    open coverage/foundry/index.html
  fi
fi

# List the generated files for debugging purposes
echo "Generated files in coverage directory:"
ls -R coverage
