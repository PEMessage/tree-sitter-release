# tree-sitter-release

Prebuilt **tree-sitter CLI** binaries for **x86_64 Linux**, linked against
**glibc 2.17** (runs on CentOS 7 / RHEL 7 and newer — anything with glibc ≥ 2.17).

Built with `zig cc` acting as the linker targeting `x86_64-linux-gnu.2.17`, so the
binary does not depend on a newer glibc than 2.17.

## Releases

- **Versioned**: building a semver tag (e.g. `v0.25.10`) publishes a stable
  release tagged `v0.25.10` with asset `tree-sitter-v0.25.10-linux-x86_64.gz`.
- **Nightly prerelease**: a **manually triggered** build of `master` (or any
  non-semver ref) rolls the `nightly` prerelease, asset
  `tree-sitter-nightly-linux-x86_64.gz`. (No automatic schedule — runs only on
  `workflow_dispatch`.)

## Usage

```sh
# Download (example)
curl -fSL -o tree-sitter.gz https://github.com/<you>/tree-sitter-release/releases/download/nightly/tree-sitter-nightly-linux-x86_64.gz
gunzip tree-sitter.gz
chmod +x tree-sitter
./tree-sitter --version
```

The `tree-sitter` CLI shells out to a C compiler (`cc`) at runtime to compile
grammars, so keep `gcc`/`clang` available on the target machine.

## How it builds

- CI: GitHub Actions, **manual `workflow_dispatch`** (+ nightly cron), **x86_64 only**, **no Dependabot**.
- Script: [`scripts/build.sh`](scripts/build.sh) clones `tree-sitter/tree-sitter`
  at the requested ref and builds the `tree-sitter` binary with `zig cc` as the
  linker (`-target x86_64-linux-gnu.2.17`).

### Reproduce locally

```sh
# requires: zig, rust (cargo), clang/libclang-dev
scripts/build.sh v0.25.10 ./tree-sitter
```
