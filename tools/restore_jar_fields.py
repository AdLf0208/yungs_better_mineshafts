#!/usr/bin/env python3
"""Restore the fields `horizon-port-pack carry` drops from carried worldgen JSON.

The carry is faithful for everything it ports, but two things are lost on the
way into a 26.3 data pack:

1. **A Java structure type.** For a structure whose `"type"` is a Java type the
   carry writes the file without the type decision at all, leaving `biomes` and
   the rewritten `config` only (the `worldgen_types.unsupported` map in
   `carry-report.json` names them). YUNG's Better Mineshafts' thirteen
   structures are all `"type": "bettermineshafts:mineshaft"`, registered by its
   own `StructureTypeModule`; the port keeps the data half faithful, so the
   jar's `type`, `step` and `spawn_overrides` are restored around the carry's
   26.3-shaped `config`.
2. **`"replace": false`** on every carried tag. It is the loader's default, so
   the carry drops it; restoring it makes the tag bytes equal the jar's.

Both steps are idempotent: running the script twice gives the same bytes.

    python3 tools/restore_jar_fields.py --jar <jar> --content content
"""
from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path

STRUCTURE_PREFIX = "data/bettermineshafts/worldgen/structure/"
CARRIED_STRUCTURES = Path("data/bettermineshafts/worldgen/structure")


def jar_structures(jar: Path) -> dict[str, dict]:
    out = {}
    with zipfile.ZipFile(jar) as archive:
        for name in archive.namelist():
            if name.startswith(STRUCTURE_PREFIX) and name.endswith(".json"):
                out[Path(name).stem] = json.loads(archive.read(name))
    return out


def restore_structures(jar: Path, content: Path) -> list[str]:
    structures = jar_structures(jar)
    if not structures:
        raise SystemExit(f"no structure files under {STRUCTURE_PREFIX} in {jar}")
    written = []
    for stem, original in sorted(structures.items()):
        path = content / CARRIED_STRUCTURES / f"{stem}.json"
        if not path.is_file():
            raise SystemExit(f"carried structure is missing: {path}")
        carried = json.loads(path.read_text())
        if "config" not in carried:
            raise SystemExit(f"{path} has no carried config")
        merged = {
            "type": original["type"],
            "biomes": original["biomes"],
            "step": original["step"],
            "spawn_overrides": original.get("spawn_overrides", {}),
            "config": carried["config"],
        }
        path.write_text(json.dumps(merged, indent=2, sort_keys=False) + "\n")
        written.append(stem)
    return written


def restore_replace(jar: Path, content: Path) -> list[str]:
    written = []
    with zipfile.ZipFile(jar) as archive:
        for name in archive.namelist():
            if not (name.startswith("data/") and "/tags/worldgen/" in name and name.endswith(".json")):
                continue
            path = content / name
            if not path.is_file():
                continue  # a namespace this mod does not own (kept under content/outside/)
            original = json.loads(archive.read(name))
            carried = json.loads(path.read_text())
            if "replace" in original and "replace" not in carried:
                carried = {"replace": original["replace"], **carried}
                path.write_text(json.dumps(carried, indent=2, sort_keys=False) + "\n")
                written.append(name)
    return written


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", required=True, type=Path)
    parser.add_argument("--content", default=Path("content"), type=Path)
    args = parser.parse_args()
    jar = args.jar.resolve()
    content = args.content.resolve()

    structures = restore_structures(jar, content)
    print(f"restored the Java structure type on {len(structures)} structure(s)")
    for stem in structures:
        print(f"  {CARRIED_STRUCTURES}/{stem}.json  type=bettermineshafts:mineshaft")

    tags = restore_replace(jar, content)
    print(f"restored `replace` on {len(tags)} tag(s)")
    for name in tags:
        print(f"  {name}")


if __name__ == "__main__":
    main()
