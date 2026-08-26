#!/bin/sh
#
# Build the tree-sitter CLI binary, linked against glibc 2.17 (CentOS 7+).
#
# Uses `zig cc` purely as the linker so the produced x86_64 binary runs on any
# system with glibc >= 2.17. No cargo-zigbuild / extra rust target needed.
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

echo "==> Configuring zig as linker (target x86_64-linux-gnu.2.17)"
ZIG_TARGET="x86_64-linux-gnu.2.17"
BIN_DIR="${WORK}/.zig-bin"
mkdir -p "${BIN_DIR}"
cat > "${BIN_DIR}/zigcc" <<'ZIG'
#!/bin/sh
exec zig cc -target x86_64-linux-gnu.2.17 "$@"
ZIG
cat > "${BIN_DIR}/zigcxx" <<'ZIG'
#!/bin/sh
exec zig c++ -target x86_64-linux-gnu.2.17 "$@"
ZIG
cat > "${BIN_DIR}/zig-ar" <<'ZIG'
#!/bin/sh
exec zig ar "$@"
ZIG
chmod +x "${BIN_DIR}/zigcc" "${BIN_DIR}/zigcxx" "${BIN_DIR}/zig-ar"

export AR="${BIN_DIR}/zig-ar"
export CC="${BIN_DIR}/zigcc"
export CXX="${BIN_DIR}/zigcxx"
export RUSTFLAGS="-C linker=${BIN_DIR}/zigcc"

echo "==> Building tree-sitter CLI"
# shellcheck disable=SC1090
. "$HOME/.cargo/env"
cargo build --release --bin tree-sitter

SRC="${WORK}/target/release/tree-sitter"
strip "${SRC}"
mkdir -p "$(dirname "${OUT}")"
cp "${SRC}" "${OUT}"
chmod +x "${OUT}"

echo "==> Built: ${OUT}"
"${OUT}" --version
