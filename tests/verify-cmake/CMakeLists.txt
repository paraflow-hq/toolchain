cmake_minimum_required(VERSION 3.16)
project(LibcxxTest CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use libc++ as the standard library
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")

# Find required libraries
find_library(LIBCXX_LIBRARY c++)
find_library(LIBCXXABI_LIBRARY c++abi)

if(NOT LIBCXX_LIBRARY)
    message(FATAL_ERROR "libc++ not found")
endif()

if(NOT LIBCXXABI_LIBRARY)
    message(FATAL_ERROR "libc++abi not found")
endif()

message(STATUS "Found libc++: ${LIBCXX_LIBRARY}")
message(STATUS "Found libc++abi: ${LIBCXXABI_LIBRARY}")

# Create test executable
add_executable(libcxx_test main.cpp)

# Link libraries
target_link_libraries(libcxx_test ${LIBCXX_LIBRARY} ${LIBCXXABI_LIBRARY})

# Enable testing
enable_testing()
add_test(NAME libcxx_test COMMAND libcxx_test)
