# syntax=docker/dockerfile:1
#
# Single-file build for the tree-sitter CLI, linked against glibc 2.17.
#
# Base: manylinux2014 (CentOS 7) -> native glibc 2.17.
# GNU ld (bfd) is forced because rust-lld can't resolve le16toh/be16toh and
# rejects -Wl,--dynamic-list (needed for runtime grammar loading).
#
# manylinux2014 supports the following architectures (TARGET_ARCH), each with
# a published pypa base image:
#   x86_64  : 64-bit Intel/AMD
#   i686    : 32-bit Intel/AMD
#   aarch64 : 64-bit ARM (AWS Graviton, Raspberry Pi 4, ...)
#   (also ppc64le / s390x; armv7l has NO manylinux2014 image, so it is not built)
#
# RUST_TARGET is the matching Rust host target triple, installed explicitly
# because inside a container `uname -m` reports the HOST kernel (x86_64), so
# rustup cannot detect i686/aarch64 correctly on its own.
#
# Build:
#   docker build -t ts --build-arg REF=v0.25.10 \
#     --build-arg TARGET_ARCH=aarch64 --build-arg RUST_TARGET=aarch64-unknown-linux-gnu .
#   id=$(docker create ts); docker cp "$id":/tree-sitter ./tree-sitter; docker rm "$id"
#
# REF may be a tag (v0.25.10), branch (master) or sha.

ARG REF=master
ARG TARGET_ARCH=x86_64
ARG RUST_TARGET=x86_64-unknown-linux-gnu

FROM quay.io/pypa/manylinux2014_${TARGET_ARCH}:latest AS builder

ARG REF
ARG RUST_TARGET
ENV REF="${REF}" RUST_TARGET="${RUST_TARGET}"

RUN yum install -y git curl >/dev/null 2>&1 || true

# Install Rust (explicit host target — see header note on uname/rustup).
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --profile minimal \
 && rustup toolchain install "stable-${RUST_TARGET}" --profile minimal \
 && rustup default "stable-${RUST_TARGET}"
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build

# Clone the requested ref (tag/branch). Fall back for raw shas.
RUN git clone --depth 1 --branch "${REF}" https://github.com/tree-sitter/tree-sitter.git . \
 || { git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git . \
      && git fetch --depth 1 origin "${REF}" \
      && git checkout "${REF}"; }

# Build the CLI. Force GNU ld and expose le16toh/be16toh as macros (glibc 2.17).
RUN export CFLAGS="-D_GNU_SOURCE" \
 && export CXXFLAGS="-D_GNU_SOURCE" \
 && export RUSTFLAGS="-C linker=cc -C link-arg=-fuse-ld=bfd" \
 && cargo build --release --bin tree-sitter \
 && strip target/release/tree-sitter

# Minimal final image carrying only the binary.
FROM scratch
COPY --from=builder /build/target/release/tree-sitter /tree-sitter
# A command is required so `docker create` works (used only to extract the binary).
CMD ["/tree-sitter", "--help"]
