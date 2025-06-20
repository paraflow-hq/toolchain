#!/bin/bash

set -e

echo "=== Emscripten Project Build and Test ==="

# Set up Emscripten environment (for Docker)
if [ -d "/opt/emsdk" ]; then
    echo "Setting up Emscripten environment from /opt/emsdk..."
    source /opt/emsdk/emsdk_env.sh
fi

# Check if emcc is available
if ! command -v emcc &>/dev/null; then
    echo "Error: emcc not found in PATH"
    echo "Please make sure Emscripten is properly installed"
    exit 1
fi

echo "emcc version:"
emcc --version

# Clean previous build
if [ -d "build" ]; then
    echo "Cleaning previous build..."
    rm -rf build
fi

# Create build directory
mkdir build
cd build

echo "Configuring project with emcmake..."
emcmake cmake ..

echo "Building project with emmake..."
emmake make

echo "Running tests..."
if [ -f "emscripten_test.js" ]; then
    echo "Testing WebAssembly module with Node.js..."
    node emscripten_test.js
    echo "WebAssembly test completed!"
else
    echo "Error: emscripten_test.js not found"
    exit 1
fi

echo "Running CTest..."
ctest --verbose

echo "=== Build and test completed successfully! ==="
