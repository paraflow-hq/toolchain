#!/bin/bash

set -e

echo "=== Playwright Installation Test ==="

# Install dependencies
echo "Installing Node.js dependencies..."
pnpm install

# Verify Playwright can be installed
echo "Installing Playwright browsers..."
npx playwright install chromium firefox

# Verify browser installations
echo "Verifying browser installations..."
npx playwright install --dry-run

# Test that Playwright CLI works
echo "Testing Playwright CLI..."
npx playwright --version

echo "=== Playwright installation test completed successfully! ==="
