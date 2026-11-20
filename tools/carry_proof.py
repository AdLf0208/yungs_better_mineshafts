#!/usr/bin/env python3
"""Proof that the content carried to the package root did not change.

The port was a content-only `.hmod` before this slice. Its delivered archive is kept as
`ports/_shared/evidence/bettermineshafts/superseded-content-0.1.0.hmod`; this script reads it and
compares **every** `assets/` and `data/` entry with the file now at the same path under the port
root, byte for byte, plus the two licence files. The manifest is deliberately *not* compared: it
changed (version 0.1.0 → 0.2.0, and the package now carries native code).

Usage: `python3 tools/carry_proof.py [--old FILE] [--root DIR]`
Exit: 0 when every carried file is identical and the counts are the recorded ones; 1 otherwise.
"""

from __future__ import annotations

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

PORT = Path(__file__).resolve().parent.parent
DEFAULT_OLD = (PORT.parent / "_shared/evidence/bettermineshafts"
               / "superseded-content-0.1.0.hmod")

# The recorded counts of the content-only package (notes.md, 0.1.0): 32 data/resource files.
EXPECTED = {
    "assets/bettermineshafts/lang": 3,
    "data/bettermineshafts/worldgen/structure": 13,
    "data/bettermineshafts/tags/worldgen/biome/has_structure": 13,
    "data/bettermineshafts/tags/worldgen/structure": 1,
    "data/minecraft/tags/worldgen/structure": 1,
    "data/bettermineshafts/worldgen/structure_set": 1,
}
EXPECTED_TOTAL = 32


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--old", default=str(DEFAULT_OLD))
    parser.add_argument("--root", default=str(PORT))
    args = parser.parse_args()
    old, root = Path(args.old), Path(args.root)
    if not old.exists():
        print(f"carry: missing the superseded package {old}", file=sys.stderr)
        return 1

    carried = []
    failures = []
    with zipfile.ZipFile(old) as archive:
        for name in archive.namelist():
            if not (name.startswith("assets/") or name.startswith("data/")
                    or name in {"LICENSE", "LICENSE-NOTICE.md"}):
                continue
            expected = archive.read(name)
            path = root / name
            if not path.exists():
                failures.append(f"missing {name}")
                continue
            actual = path.read_bytes()
            if sha256(actual) != sha256(expected):
                failures.append(f"changed {name}")
                continue
            carried.append(name)

    by_family = {}
    for name in carried:
        for family in EXPECTED:
            if name.startswith(family + "/"):
                by_family[family] = by_family.get(family, 0) + 1
                break

    print(f"carry: {len(carried)} files identical to the superseded content package")
    for family, count in sorted(by_family.items()):
        print(f"carry:   {count:3d}  {family}/")
        if count != EXPECTED[family]:
            failures.append(f"{family}: {count} files, expected {EXPECTED[family]}")
    payload = [name for name in carried if name.startswith(("assets/", "data/"))]
    if len(payload) != EXPECTED_TOTAL:
        failures.append(f"{len(payload)} content files, expected {EXPECTED_TOTAL}")

    # The manifest changed on purpose; say so rather than let it look like a lost file.
    with zipfile.ZipFile(old) as archive:
        old_manifest = archive.read("horizon-mod.toml")
    new_manifest = (root / "horizon-mod.toml").read_bytes()
    print(f"carry: manifest rewritten (0.1.0 -> 0.2.0, native block added): "
          f"{len(old_manifest)} -> {len(new_manifest)} bytes")

    for failure in failures:
        print(f"carry: FAIL {failure}", file=sys.stderr)
    if failures:
        print(f"carry: FAIL {len(failures)} problems")
        return 1
    print("carry: PASS — nothing carried was lost or altered")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
