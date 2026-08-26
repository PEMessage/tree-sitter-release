# tree-sitter-release

Prebuilt **tree-sitter CLI** binaries for **x86_64 Linux**, linked against
**glibc 2.17** (runs on CentOS 7 / RHEL 7 and newer — anything with glibc ≥ 2.17).

The binary is produced inside a **manylinux2014** (CentOS 7) container, whose
native glibc is 2.17, so the result runs on any glibc ≥ 2.17 system. GNU ld
(bfd) is used (not rust-lld) because rust-lld can't resolve `le16toh`/`be16toh`
and rejects `-Wl,--dynamic-list` (needed for runtime grammar loading).

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
curl -fSL -o tree-sitter.gz https://github.com/PEMessage/tree-sitter-release/releases/download/nightly/tree-sitter-nightly-linux-x86_64.gz
gunzip tree-sitter.gz
chmod +x tree-sitter
./tree-sitter --version
```

The `tree-sitter` CLI shells out to a C compiler (`cc`) at runtime to compile
grammars, so keep `gcc`/`clang` available on the target machine.

## How it builds

- CI: GitHub Actions, **manual `workflow_dispatch`** only, **x86_64 only**,
  **no Dependabot**. The workflow just runs `docker build` (with the `REF`
  build arg), extracts the binary, packages and publishes it.
- All build logic lives in the single **[`Dockerfile`](Dockerfile)**.

### Build locally with Docker (single file)

```sh
# Build a specific version
docker build -t ts --build-arg REF=v0.25.10 .
id=$(docker create ts)
docker cp "$id":/tree-sitter ./tree-sitter
docker rm "$id"

./tree-sitter --version
```

`REF` may be a tag (`v0.25.10`), a branch (`master`) or a commit sha.
