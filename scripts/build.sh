#!/bin/sh
#
# Build the tree-sitter CLI binary, linked against glibc 2.17 (CentOS 7+).
#
# This is meant to run inside a manylinux2014 (CentOS 7) container, whose
# glibc is 2.17. Building there yields a binary that runs on any system with
# glibc >= 2.17. GNU ld (not lld) is required because tree-sitter-cli passes
# -Wl,--dynamic-list for runtime grammar loading, which zig's lld rejects.
#
# Usage:
#   scripts/build.sh <tree-sitter-ref> [output-path]
#
#   <tree-sitter-ref>  tag / branch / sha of tree-sitter/tree-sitter (default: master)
#   [output-path]      where to write the finished binary (default: ./tree-sitter)
#
set -eu

REF="${1:-master}"
OUT="${2:-$(pwd)/tree-sitter}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Cloning tree-sitter@${REF}"
git clone --depth 1 --branch "${REF}" https://github.com/tree-sitter/tree-sitter.git "${WORK}" \
  || { git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git "${WORK}" \
       && git -C "${WORK}" fetch --depth 1 origin "${REF}" \
       && git -C "${WORK}" checkout "${REF}"; }

cd "${WORK}"

echo "==> Building tree-sitter CLI"
# shellcheck disable=SC1090
. "$HOME/.cargo/env"
# Force the system GNU linker (bfd), not rust-lld: rust-lld can't resolve
# le16toh/be16toh and rejects -Wl,--dynamic-list (needed for runtime grammar
# loading). The base image's glibc is 2.17, so the result still targets 2.17.
export RUSTFLAGS="-C linker=cc -C link-arg=-fuse-ld=bfd"
cargo build --release --bin tree-sitter

SRC="${WORK}/target/release/tree-sitter"
strip "${SRC}"
mkdir -p "$(dirname "${OUT}")"
cp "${SRC}" "${OUT}"
chmod +x "${OUT}"

echo "==> Built: ${OUT}"
"${OUT}" --version
