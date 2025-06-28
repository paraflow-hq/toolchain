group "default" {
  targets = ["toolchain", "test-env", "test-node-canvas", "test-cmake", "test-emscripten", "test-playwright", "test-chinese-font"]
}

target "toolchain" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "toolchain"
}

target "test-env" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "test-env"
}

target "test-node-canvas" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "test-node-canvas"
}

target "test-cmake" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "test-cmake"
}

target "test-emscripten" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "test-emscripten"
}

target "test-playwright" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "test-playwright"
}

target "test-chinese-font" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "test-chinese-font"
}