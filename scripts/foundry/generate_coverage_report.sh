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
EXCLUDE="*test* *mocks* *node_modules* *scripts* *lib*"
lcov --rc lcov_branch_coverage=1 --ignore-errors unused --ignore-errors inconsistent --remove lcov.info $EXCLUDE --output-file coverage/foundry/forge-pruned-lcov.info

# Remove the original lcov.info file and coverage.json
rm lcov.info && rm coverage.json

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
  open coverage/foundry/index.html
fi

# List the generated files for debugging purposes
echo "Generated files in coverage directory:"
ls -R coverage
