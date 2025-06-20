# CMake generated Testfile for 
# Source directory: /Users/pw/workspace/toolchain/tests/verify-emscripten
# Build directory: /Users/pw/workspace/toolchain/tests/verify-emscripten/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(emscripten_node_test "node" "emscripten_test.js")
set_tests_properties(emscripten_node_test PROPERTIES  WORKING_DIRECTORY "/Users/pw/workspace/toolchain/tests/verify-emscripten/build" _BACKTRACE_TRIPLES "/Users/pw/workspace/toolchain/tests/verify-emscripten/CMakeLists.txt;27;add_test;/Users/pw/workspace/toolchain/tests/verify-emscripten/CMakeLists.txt;0;")
