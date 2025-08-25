group "default" {
  targets = ["toolchain"]
}

target "toolchain" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64", "linux/arm64"]
  target = "toolchain"
}
