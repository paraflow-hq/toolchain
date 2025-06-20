#!/bin/bash

set -e

echo "=== Playwright Browser Automation Test ==="

# Install dependencies
echo "Installing Node.js dependencies..."
pnpm install

# Install Playwright browsers if not already installed
echo "Installing Playwright browsers..."
npx playwright install

# Verify browser installations
echo "Verifying browser installations..."
npx playwright install --dry-run

# Run the test
echo "Running Playwright automation tests..."
pnpm test

# Clean up screenshots
echo "Cleaning up test artifacts..."
rm -f *.png

echo "=== Playwright test completed successfully! ==="
