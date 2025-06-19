FROM mcr.microsoft.com/devcontainers/base:jammy AS base

##################################################

FROM base AS emscripten

ARG http_proxy=http://sg-squid-test.zhenguanyu.com:80
ARG https_proxy=http://sg-squid-test.zhenguanyu.com:80

RUN <<EOF
#!/bin/bash
set -eu
git clone https://github.com/emscripten-core/emsdk.git /tmp/emsdk
cd /tmp/emsdk
./emsdk install 4.0.5
./emsdk activate 4.0.5
EOF

##################################################

FROM base AS wasm-split

COPY arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget \
    "https://github.com/getsentry/symbolicator/releases/download/25.6.0/wasm-split-Darwin-universal" \
    "https://github.com/getsentry/symbolicator/releases/download/25.6.0/wasm-split-Linux-x86_64" \
    "/tmp/wasm-split"
chmod +x /tmp/wasm-split
EOF

##################################################

FROM base AS sccache

COPY arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget \
    "https://github.com/mozilla/sccache/releases/download/v0.10.0/sccache-v0.10.0-aarch64-apple-darwin.tar.gz" \
    "https://github.com/mozilla/sccache/releases/download/v0.10.0/sccache-v0.10.0-x86_64-unknown-linux-musl.tar.gz" \
    "/tmp/sccache.tar.gz"
mkdir /tmp/sccache/
tar xf /tmp/sccache.tar.gz --strip-components=1 -C /tmp/sccache/
EOF

##################################################

FROM base AS mold

COPY arch-wget /usr/local/bin/arch-wget
RUN chmod +x /usr/local/bin/arch-wget

RUN <<EOF
#!/bin/bash
set -eu
arch-wget \
    "https://github.com/rui314/mold/releases/download/v2.40.1/mold-2.40.1-aarch64-linux.tar.gz" \
    "https://github.com/rui314/mold/releases/download/v2.40.1/mold-2.40.1-x86_64-linux.tar.gz" \
    "/tmp/mold.tar.gz"
mkdir /tmp/mold/
tar xf /tmp/mold.tar.gz --strip-components=1 -C /tmp/mold/
EOF

##################################################

FROM base AS paraflow-build

ARG EMSDK_DIR=/opt/emsdk
ARG LLVM_VERSION=20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y lsb-release wget software-properties-common gnupg

# llvm
RUN <<EOF
#!/bin/bash
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh ${LLVM_VERSION}
apt-get install -y clang-format-${LLVM_VERSION}
apt-get install -y build-essential ninja-build mold cmake direnv protobuf-compiler
EOF

# python
RUN <<EOF
#!/bin/bash
apt-get install -y python3 python3-pip
pip install uv
pip install pre-commit
EOF

# node
RUN <<EOF
#!/bin/bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g pnpm@9
EOF

# mold
RUN <<EOF
#!/bin/bash
ln -sf /usr/local/bin/mold /usr/bin/ld
EOF

ENV DEBIAN_FRONTEND=dialog

COPY --link --from=sccache /tmp/sccache/sccache /usr/local/bin/
COPY --link --from=wasm-split /tmp/wasm-split /usr/local/bin/
COPY --link --from=emscripten /tmp/emsdk ${EMSDK_DIR}
COPY --link --from=mold /tmp/mold/ /usr/local/

##################################################

FROM paraflow-build AS paraflow-dev-container

WORKDIR /workspaces