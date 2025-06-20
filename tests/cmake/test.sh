#!/bin/bash

set -e

echo "=== CMake Project Build and Test ==="

# Clean previous build
if [ -d "build" ]; then
    echo "Cleaning previous build..."
    rm -rf build
fi

# Create build directory
mkdir build
cd build

echo "Configuring project with CMake..."
cmake ..

echo "Building project..."
make

echo "Running tests..."
ctest --verbose

echo "Running executable directly..."
./libcxx_test

echo "=== Build and test completed successfully! ==="
