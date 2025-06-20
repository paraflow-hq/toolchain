cmake_minimum_required(VERSION 3.16)
project(EmscriptenTest CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

message(STATUS "Building with Emscripten")

# Emscripten-specific settings
set(CMAKE_EXECUTABLE_SUFFIX ".js")

# Create the main executable
add_executable(emscripten_test main.cpp)

# Simple Emscripten linker flags for Node.js execution
set_target_properties(emscripten_test PROPERTIES
    LINK_FLAGS "-s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s NODEJS_CATCH_EXIT=0"
)

message(STATUS "Emscripten build configured for Node.js")

# Enable testing
enable_testing()

# Test the generated JavaScript with Node.js
add_test(NAME emscripten_node_test 
            COMMAND node emscripten_test.js
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
