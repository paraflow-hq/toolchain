FROM mcr.microsoft.com/devcontainers/base:jammy AS base

##################################################

FROM base AS emsdk

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

FROM base AS mold

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

FROM base AS sccache

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

FROM base AS ossutil

ARG OSSUTIL_VERSION=1.7.19

COPY files/arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget
RUN <<EOF
#!/bin/bash
set -eu
arch-wget \
    "https://gosspublic.alicdn.com/ossutil/${OSSUTIL_VERSION}/ossutil-v${OSSUTIL_VERSION}-linux-arm64.zip" \
    "https://gosspublic.alicdn.com/ossutil/${OSSUTIL_VERSION}/ossutil-v${OSSUTIL_VERSION}-linux-amd64.zip" \
    "/tmp/ossutil.zip"
mkdir /tmp/ossutil/
unzip /tmp/ossutil.zip -d /tmp/ossutil/
mv /tmp/ossutil/ossutil-* /tmp/ossutil/ossutil64
EOF

##################################################

FROM base AS wasm-split

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

FROM base AS direnv

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

FROM base AS protoc

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

FROM base AS mkcert

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

RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} <<EOF
#!/bin/bash
set -eu
apt-get update && apt-get upgrade -y
apt-get install -y lsb-release wget software-properties-common gnupg
EOF

# llvm & C/C++
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} <<EOF
#!/bin/bash
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh ${LLVM_VERSION}
apt-get install -y clang-format-${LLVM_VERSION} cppcheck cpplint
apt-get install -y build-essential ninja-build make cmake protobuf-compiler
apt-get install -y libc++-${LLVM_VERSION}-dev libc++abi-${LLVM_VERSION}-dev libclang-rt-${LLVM_VERSION}-dev

update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-${LLVM_VERSION}/bin/clang 100
update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-${LLVM_VERSION}/bin/clang++ 100
EOF

ARG POETRY_VERSION=1.4.2
ARG UV_VERSION=0.6.4

# python
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} <<EOF
#!/bin/bash
set -eu
apt-get update
apt-get install -y python3 python3-pip pre-commit
pip3 install poetry==${POETRY_VERSION} uv==${UV_VERSION}
EOF

ARG NODE_VERSION=22.x
ARG NPM_VERSION=10.9.0
ARG PNPM_VERSION=9.12.3

# node & playwright
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} <<EOF
#!/bin/bash
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
apt-get update
apt-get install -y nodejs
npm install -g npm@${NPM_VERSION} pnpm@v${PNPM_VERSION}
npx -y playwright install-deps
EOF

# link ld to mold
RUN <<EOF
#!/bin/bash
ln -sf /usr/local/bin/mold /usr/bin/ld
EOF

# skia build dependencies
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} <<EOF
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
EOF

# fix lldb path: https://github.com/llvm/llvm-project/issues/55575
RUN <<EOF
#!/bin/bash
set -eu
mkdir -p /usr/lib/local/lib/python3.10/dist-packages/
ln -s /usr/lib/llvm-${LLVM_VERSION}/lib/python3.10/dist-packages/lldb /usr/lib/local/lib/python3.10/dist-packages/lldb
EOF

# node-canvas deps
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} <<EOF
#!/bin/bash
set -eu
apt-get update
apt-get install -y libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev libpixman-1-dev pkg-config
EOF

# others
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} <<EOF
#!/bin/bash
set -eu
apt-get update
apt-get install -y brotli ghostscript imagemagick libdw-dev librsvg2-bin ripgrep
EOF

# imagemagick
RUN sed -i '/domain="coder" .* pattern="PDF"/ s/rights="none"/rights="read"/' /etc/ImageMagick-6/policy.xml

# fonts
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-${TARGETARCH} --mount=type=cache,target=/var/lib/apt,id=apt-lib-${TARGETARCH} --mount=type=bind,source=files/fangsong.ttf,target=/tmp/fangsong.ttf <<EOF
#!/bin/bash
set -eu
# Accept Microsoft Font EULA
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
# copy fonts
mkdir -p /usr/share/fonts/truetype/msttcorefontscd
cp /tmp/fangsong.ttf /usr/share/fonts/truetype/msttcorefontscd/
# Other fonts
apt install -y --no-install-recommends fontconfig ttf-mscorefonts-installer
EOF

ENV DEBIAN_FRONTEND=dialog
ENV EMSCRIPTEN_ROOT=${EMSDK_DIR}/upstream/emscripten
ENV LLVM_ROOT=/usr/lib/llvm-${LLVM_VERSION}
ENV PATH=${LLVM_ROOT}/bin:${PATH}

COPY --link --from=sccache /tmp/sccache/sccache /usr/local/bin/
COPY --link --from=wasm-split /tmp/wasm-split /usr/local/bin/
COPY --link --from=emsdk /tmp/emsdk ${EMSDK_DIR}
COPY --link --from=mold /tmp/mold/ /usr/local/
COPY --link --from=ossutil /tmp/ossutil/ossutil64 /usr/local/bin/
COPY --link --from=direnv /tmp/direnv /usr/local/bin/
COPY --link --from=protoc /tmp/protoc/ /usr/local/
COPY --link --from=mkcert /tmp/mkcert /usr/local/bin/

ADD files/check-env /usr/local/bin/check-env

# Check if the environment is set up correctly
RUN <<EOF
#!/bin/bash
set -eu

source /opt/emsdk/emsdk_env.sh

chmod +x /usr/local/bin/check-env

# Check environment
em++ --version # sanity checks
/usr/local/bin/check-env

# Test node-canvas installation
mkdir -pv /tmp/test-canvas
cd /tmp/test-canvas
npm init -y
pnpm install canvas
cd /
rm -rf /tmp/test-canvas
EOF