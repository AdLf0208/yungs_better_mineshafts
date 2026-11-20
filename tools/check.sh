#!/usr/bin/env bash
# The SDK ladder for this port, inside one build-slot lease:
#
#   ports/tools/build-slot.sh run --job bms-port --port ports/bettermineshafts \
#       --step build -- ports/bettermineshafts/tools/check.sh
#
# It proves the crate compiles and tests against the pinned SDK, that the package is well formed,
# that it still fits the build it declares, that two builds are byte-identical, and that the
# content carried into the package root is byte-for-byte the bytes the previous content-only
# package delivered. It runs from the port directory and never passes `--target-dir`.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

# `/tmp` is a full tmpfs on this box; rustc and rustdoc need scratch space beside the crate.
export TMPDIR=${TMPDIR:-$PWD/target/tmp}
mkdir -p "$TMPDIR"

status=0
step() {
    echo "== $*"
    "$@" || status=1
}

step env CARGO_INCREMENTAL=0 cargo test --offline
step env CARGO_INCREMENTAL=0 cargo clippy --offline --all-targets -- -D warnings
step env CARGO_INCREMENTAL=0 cargo fmt --check

# `cargo test` writes a root Cargo.lock, and the packer would ship it: the package carries the
# crate's sources and content, never the lock (the launcher resolves against its own SDK).
rm -f Cargo.lock
step env CARGO_INCREMENTAL=0 cargo horizon-mod build
step cp target/horizon-mod/bettermineshafts.hmod ./bettermineshafts.hmod

# The deliverable is the port root's copy: `check` and `fits` must see the bytes this run built.
# Always name the file: `check` with no argument compiles wasm instead of checking the package.
step cargo horizon-mod check bettermineshafts.hmod
step cargo horizon-mod fits --build 0b14f8a bettermineshafts.hmod

# A second build in the same lease, compared byte-for-byte with the delivered copy.
rm -f Cargo.lock
step env CARGO_INCREMENTAL=0 cargo horizon-mod build
step cmp target/horizon-mod/bettermineshafts.hmod ./bettermineshafts.hmod

# The content moved to the package root is unchanged: every file equals the previous package's.
step python3 tools/carry_proof.py

echo "== package"
stat -c '%s bytes  %n' bettermineshafts.hmod || status=1
sha256sum bettermineshafts.hmod || status=1
python3 -c 'import sys,zipfile; print(f"{len(zipfile.ZipFile(sys.argv[1]).namelist())} entries")' \
    bettermineshafts.hmod || status=1
echo "CHECK_EXIT:$status"
exit $status
