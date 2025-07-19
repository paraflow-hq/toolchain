# syntax=docker/dockerfile:1.4
# -----------------------------------------------------------------------------

ARG BASE=ubuntu:22.04
ARG BUILDPACK=buildpack-deps:22.04

FROM ${BASE} AS base
FROM ${BUILDPACK} AS build

# SYNC_BEGIN

##################################################

FROM build AS emsdk

ARG EMSCRIPTEN_VERSION=4.0.5

RUN <<EOF
#!/bin/bash
set -eu
git clone https://github.com/emscripten-core/emsdk.git /tmp/emsdk
cd /tmp/emsdk
./emsdk install ${EMSCRIPTEN_VERSION}
./emsdk activate ${EMSCRIPTEN_VERSION}
EOF

##################################################

FROM build AS mold

ARG MOLD_VERSION=2.40.1

COPY files/arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget \
    "https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-aarch64-linux.tar.gz" \
    "https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-x86_64-linux.tar.gz" \
    "/tmp/mold.tar.gz"
mkdir /tmp/mold/
tar xf /tmp/mold.tar.gz --strip-components=1 -C /tmp/mold/
EOF

##################################################

FROM build AS sccache

ARG SCCACHE_VERSION=0.10.0

COPY files/arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget \
    "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-aarch64-unknown-linux-musl.tar.gz" \
    "https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    "/tmp/sccache.tar.gz"
mkdir /tmp/sccache/
tar xf /tmp/sccache.tar.gz --strip-components=1 -C /tmp/sccache/
EOF

##################################################

FROM build AS ossutil

ARG OSSUTIL_VERSION=1.7.8

COPY files/arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget
RUN <<EOF
#!/bin/bash
set -eu
arch-wget \
    "https://github.com/paraflow-hq/third_party/releases/download/ossutil-v${OSSUTIL_VERSION}/ossutil-linux-arm64" \
    "https://github.com/paraflow-hq/third_party/releases/download/ossutil-v${OSSUTIL_VERSION}/ossutil-linux-x64" \
    "/tmp/ossutil64"
chmod a+x /tmp/ossutil64
EOF

##################################################

FROM build AS wasm-split

ARG WASM_SPLIT_VERSION=25.6.0

# Init Rust Environment
RUN <<EOF
#!/bin/bash
set -eu
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env
EOF

ENV PATH="/root/.cargo/bin:${PATH}"

RUN <<EOF
#!/bin/bash
set -eu
apt-get update
apt-get install -y git build-essential pkg-config libssl-dev
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*
EOF

RUN <<EOF
#!/bin/bash
set -eu
source ~/.cargo/env
git clone https://github.com/getsentry/symbolicator.git /tmp/symbolicator
cd /tmp/symbolicator
git checkout ${WASM_SPLIT_VERSION}
cargo build --release -p wasm-split
cp target/release/wasm-split /tmp/wasm-split
EOF

##################################################

FROM build AS direnv

ARG DIR_ENV_VERSION=2.36.0

COPY files/arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget "https://github.com/direnv/direnv/releases/download/v${DIR_ENV_VERSION}/direnv.linux-arm64" \
    "https://github.com/direnv/direnv/releases/download/v${DIR_ENV_VERSION}/direnv.linux-amd64" \
    "/tmp/direnv"
chmod +x /tmp/direnv
EOF

##################################################

FROM build AS protoc

ARG PROTOC_VERSION=29.4

COPY files/arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-aarch_64.zip" \
    "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip" \
    "/tmp/protoc.zip"

mkdir /tmp/protoc
unzip /tmp/protoc.zip -d /tmp/protoc -x readme.txt
EOF

##################################################

FROM build AS mkcert

ARG MKCERT_VERSION=latest

COPY files/arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget "https://dl.filippo.io/mkcert/${MKCERT_VERSION}?for=linux/arm64" \
    "https://dl.filippo.io/mkcert/${MKCERT_VERSION}?for=linux/amd64" \
    "/tmp/mkcert"
chmod +x /tmp/mkcert
EOF

##################################################

FROM base AS toolchain

ARG EMSDK_DIR=/opt/emsdk
ARG LLVM_VERSION=20
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOF
#!/bin/bash
set -eu
apt-get update && apt-get upgrade -y
apt-get install -y curl wget gnupg lsb-release ca-certificates software-properties-common
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache
EOF

# llvm & C/C++
RUN <<EOF
#!/bin/bash
set -eu

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
add-apt-repository "deb https://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main"
apt-get update

apt-get install -y \
    clang-${LLVM_VERSION} \
    clang++-${LLVM_VERSION} \
    clang-tidy-${LLVM_VERSION} \
    clang-format-${LLVM_VERSION} \
    clangd-${LLVM_VERSION} \
    llvm-${LLVM_VERSION} \
    lldb-${LLVM_VERSION} \
    libc++-${LLVM_VERSION}-dev \
    libc++abi-${LLVM_VERSION}-dev \
    libclang-rt-${LLVM_VERSION}-dev

apt-get install -y build-essential ninja-build make cmake protobuf-compiler cppcheck cpplint

update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-${LLVM_VERSION}/bin/clang 100
update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-${LLVM_VERSION}/bin/clang++ 100
update-alternatives --install /usr/bin/lldb lldb /usr/lib/llvm-${LLVM_VERSION}/bin/lldb 100

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache
EOF

ARG POETRY_VERSION=1.4.2
ARG UV_VERSION=0.6.4

# python
RUN <<EOF
#!/bin/bash
set -eu
apt-get update
apt-get install -y python3 python3-pip pre-commit
pip3 install poetry==${POETRY_VERSION} uv==${UV_VERSION}
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.local/share/pip
EOF

ARG NODE_VERSION=22.x
ARG NPM_VERSION=10.9.0
ARG PNPM_VERSION=10.12.1

# node & playwright
RUN <<EOF
#!/bin/bash
set -eu

curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
apt-get update
apt-get install -y nodejs
npm install -g npm@${NPM_VERSION} pnpm@v${PNPM_VERSION}
npx -y playwright install-deps
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.npm
EOF

# link ld to mold
RUN ln -sf /usr/local/bin/mold /usr/bin/ld

# skia build dependencies
RUN <<EOF
#!/bin/bash
set -eu

apt-get update
apt-get install -y freeglut3-dev \
    libegl1-mesa-dev \
    libfontconfig-dev \
    libfreetype6-dev \
    libgif-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libharfbuzz-dev \
    libicu-dev \
    libjpeg-dev \
    libpng-dev \
    libwebp-dev
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache
EOF

# fix lldb path: https://github.com/llvm/llvm-project/issues/55575
RUN <<EOF
#!/bin/bash
set -eu

mkdir -p /usr/lib/local/lib/python3.10/dist-packages/
ln -s /usr/lib/llvm-${LLVM_VERSION}/lib/python3.10/dist-packages/lldb /usr/lib/local/lib/python3.10/dist-packages/lldb
EOF

# node-canvas deps
RUN <<EOF
#!/bin/bash
set -eu

apt-get update
apt-get install -y libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev libpixman-1-dev pkg-config
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache
EOF

# Cypress dependencies
RUN <<EOF
#!/bin/bash
set -eu

apt-get update
apt-get install -y \
    libgtk2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache
EOF

# others
RUN <<EOF
#!/bin/bash
set -eu

apt-get update
apt-get install -y brotli ghostscript imagemagick libdw-dev librsvg2-bin ripgrep git git-lfs gnupg2 openssh-client zsh unzip
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache
EOF

# imagemagick
RUN sed -i '/domain="coder" .* pattern="PDF"/ s/rights="none"/rights="read"/' /etc/ImageMagick-6/policy.xml

# fonts
RUN --mount=type=bind,source=files/fangsong.ttf,target=/tmp/fangsong.ttf <<EOF
#!/bin/bash
set -eu

apt-get update
# Accept Microsoft Font EULA
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
# copy fonts
mkdir -p /usr/share/fonts/truetype/msttcorefontscd
cp /tmp/fangsong.ttf /usr/share/fonts/truetype/msttcorefontscd/
# Other fonts
apt install -y --no-install-recommends fontconfig ttf-mscorefonts-installer
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* ~/.cache
EOF

ENV DEBIAN_FRONTEND=dialog
ENV EMSCRIPTEN_ROOT=${EMSDK_DIR}/upstream/emscripten
ENV LLVM_ROOT=/usr/lib/llvm-${LLVM_VERSION}
ENV PATH=${LLVM_ROOT}/bin:${PATH}

COPY --link --from=sccache /tmp/sccache/sccache /usr/local/bin/
COPY --link --from=wasm-split /tmp/wasm-split /usr/local/bin/
COPY --link --from=emsdk /tmp/emsdk ${EMSDK_DIR}
COPY --link --from=mold /tmp/mold/ /usr/local/
COPY --link --from=ossutil /tmp/ossutil64 /usr/local/bin/
COPY --link --from=direnv /tmp/direnv /usr/local/bin/
COPY --link --from=protoc /tmp/protoc/ /usr/local/
COPY --link --from=mkcert /tmp/mkcert /usr/local/bin/

RUN ${EMSCRIPTEN_ROOT}/em++ --version # sanity checks

# SYNC_END

##################################################

FROM toolchain AS test-env

ADD tests/check-env /usr/local/bin/check-env
RUN chmod +x /usr/local/bin/check-env

RUN <<EOF
#!/bin/bash
set -eu

source /opt/emsdk/emsdk_env.sh
em++ --version # sanity checks

# Check environment
/usr/local/bin/check-env
EOF

##################################################

FROM toolchain AS test-node-canvas

# Test node-canvas installation
RUN <<EOF
mkdir -pv /tmp/test-canvas
cd /tmp/test-canvas
npm init -y
pnpm install canvas
cd /
rm -rf /tmp/test-canvas
EOF

##################################################

FROM toolchain AS test-cmake

# Copy the cmake test project
COPY tests/cmake /tmp/test

# Build and test the cmake project
RUN <<EOF
#!/bin/bash
set -eu
cd /tmp/test
chmod +x test.sh
./test.sh
EOF

##################################################

FROM toolchain AS test-emscripten

# Copy the emscripten test project
COPY tests/emscripten /tmp/test

# Build and test the emscripten project
RUN <<EOF
#!/bin/bash
set -eu
cd /tmp/test
chmod +x test.sh
./test.sh
EOF

##################################################

FROM toolchain AS test-playwright

# Copy the playwright test project
COPY tests/playwright /tmp/test

# Build and test the playwright automation
RUN <<EOF
#!/bin/bash
set -eu
cd /tmp/test
chmod +x test.sh
./test.sh
EOF

##################################################

FROM toolchain AS test-chinese-font

# Copy the chinese font test project
COPY tests/chinese-font /tmp/test

# Test Chinese font rendering capabilities
RUN <<EOF
#!/bin/bash
set -eu
cd /tmp/test
chmod +x test.sh
./test.sh
EOF

