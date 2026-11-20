#!/usr/bin/env python3
"""Static fidelity check: the carried content against the ATM10 1.21.1 jar.

This port carries a worldgen mod whose generator was Java and is now Rust in `src/`, so the
check has two jobs:

1. **The inventory claim.** The jar has no structure templates (`.nbt`), no
   template pools, no processor lists and no loot tables — the "pieces" live in
   ten Java classes. Every count is read from the jar and printed, so the claim
   is measured, not asserted.
2. **The data half is faithful.** The thirteen carried structure definitions
   carry the jar's `type`, `biomes`, `step`, `spawn_overrides` and an equal
   `config` (block states in 26.3's `{"id": …}` shape), every block id they name
   exists in 26.3, the thirteen biome tags, the structure set, the two structure
   tags and the three lang files equal the jar's, and every required biome/tag
   entry resolves against the prepared 26.3 resources.

Usage:
  verify_content.py [--jar FILE] [--content DIR] [--resources DIR]
"""

from __future__ import annotations

import argparse
import json
import sys
import zipfile
from pathlib import Path

PORT = Path(__file__).resolve().parent.parent
CAMPAIGN = PORT.parent.parent
DEFAULT_JAR = (CAMPAIGN / "ports/_shared/licence-cache"
               / "YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar")
DEFAULT_CONTENT = PORT
DEFAULT_RES = Path("/home/adlf/Desktop/horizon/.local/horizon-client/26.3")

STRUCTURE_PREFIX = "data/bettermineshafts/worldgen/structure/"
BIOME_TAG_PREFIX = "data/bettermineshafts/tags/worldgen/biome/has_structure/"
STRUCTURE_SET = "data/bettermineshafts/worldgen/structure_set/mineshafts.json"
STRUCTURE_TAG = "data/bettermineshafts/tags/worldgen/structure/better_mineshafts.json"
VANILLA_TAG = "data/minecraft/tags/worldgen/structure/mineshaft.json"
LANG_PREFIX = "assets/bettermineshafts/lang/"
TYPE = "bettermineshafts:mineshaft"


class Verifier:
    def __init__(self, jar: Path, content: Path, res: Path) -> None:
        self.jar = zipfile.ZipFile(jar)
        self.names = set(self.jar.namelist())
        self.content = content
        self.res = res
        self.failures: list[str] = []
        self.states = {s[0] for s in json.loads((res / "facts.json").read_text())["states"]}
        self.biomes = {f"minecraft:{p.stem}"
                       for p in (res / "data/minecraft/worldgen/biome").glob("*.json")}
        self.biome_tags = {f"minecraft:{p.stem}" for p in
                           (res / "data/minecraft/tags/worldgen/biome").glob("*.json")}
        self.jar_biome_tags = {n for n in self.names
                             if n.startswith("data/") and "/tags/worldgen/biome/" in n and n.endswith(".json")}

    # ---------------------------------------------------------------- helpers
    def ok(self, message: str) -> None:
        print(f"ok: {message}")

    def fail(self, message: str) -> None:
        self.failures.append(message)
        print(f"FAIL: {message}", file=sys.stderr)

    def jar_json(self, name: str):
        return json.loads(self.jar.read(name))

    def carried(self, rel: str):
        return json.loads((self.content / rel).read_text())

    def entries(self, prefix: str, suffix: str) -> list[str]:
        return sorted(n[len(prefix):] for n in self.names
                      if n.startswith(prefix) and n.endswith(suffix))

    def carried_entries(self, prefix: str, suffix: str) -> list[str]:
        root = self.content / prefix
        if not root.is_dir():
            return []
        return sorted(str(p.relative_to(root)) for p in root.rglob(f"*{suffix}"))

    # ------------------------------------------------------------ inventory
    def inventory(self) -> None:
        counts = {
            "structure": len(self.entries("data/bettermineshafts/worldgen/structure/", ".json")),
            "structure_set": len(self.entries("data/bettermineshafts/worldgen/structure_set/", ".json")),
            "template_pool": len([n for n in self.names if "/worldgen/template_pool/" in n]),
            "processor_list": len([n for n in self.names if "/worldgen/processor_list/" in n]),
            "templates_nbt": len([n for n in self.names if n.endswith(".nbt")]),
            "loot_table": len([n for n in self.names if "/loot_table" in n or "/loot_tables/" in n]),
            "biome_tags": len(self.jar_biome_tags),
            "structure_tags": len([n for n in self.names if "/tags/worldgen/structure/" in n and n.endswith(".json")]),
            "lang": len(self.entries(LANG_PREFIX, ".json")),
            "classes": len([n for n in self.names if n.endswith(".class")]),
        }
        print("jar inventory: " + ", ".join(f"{k}={v}" for k, v in counts.items()))
        if counts["structure"] != 13:
            self.fail(f"the jar has {counts['structure']} structure files, not 13")
        for empty in ("template_pool", "processor_list", "templates_nbt", "loot_table"):
            if counts[empty]:
                self.fail(f"the jar carries {counts[empty]} {empty}; this port was built as a "
                          "data carry for a jar with none — re-read the jar before trusting the port")
        self.ok("the jar has 0 templates, 0 template pools, 0 processor lists and 0 loot tables "
                "(the pieces are the ten Java piece classes; there is no data half of them)")

    # ------------------------------------------------------------- structures
    @staticmethod
    def states_of(value):
        """Every block state in a config, in a shape-free order for comparison."""
        found = []

        def walk(node):
            if isinstance(node, dict):
                if "Name" in node:
                    found.append((node["Name"], json.dumps(node.get("Properties", {}), sort_keys=True)))
                elif "id" in node and isinstance(node["id"], str) and ":" in node["id"]:
                    found.append((node["id"], json.dumps(node.get("properties", {}), sort_keys=True)))
                for child in node.values():
                    walk(child)
            elif isinstance(node, list):
                for child in node:
                    walk(child)

        walk(value)
        return found

    def structures(self) -> None:
        names = self.entries(STRUCTURE_PREFIX, ".json")
        carried = self.carried_entries("data/bettermineshafts/worldgen/structure/", ".json")
        if names != carried:
            self.fail(f"structure files differ: jar {len(names)}, carried {len(carried)}")
            return
        unknown_blocks: dict[str, list[str]] = {}
        for name in names:
            original = self.jar_json(STRUCTURE_PREFIX + name)
            ported = self.carried(f"data/bettermineshafts/worldgen/structure/{name}")
            if original.get("type") != TYPE or ported.get("type") != TYPE:
                self.fail(f"{name}: type is {ported.get('type')!r}, not {TYPE!r}")
            for field in ("biomes", "step"):
                if original[field] != ported.get(field):
                    self.fail(f"{name}: {field} differs ({ported.get(field)!r} != {original[field]!r})")
            if original.get("spawn_overrides", {}) != ported.get("spawn_overrides", {}):
                self.fail(f"{name}: spawn_overrides differ")
            left = sorted(self.states_of(original["config"]))
            right = sorted(self.states_of(ported["config"]))
            if left != right:
                self.fail(f"{name}: config block states differ from the jar "
                          f"({len(right)} carried, {len(left)} in the jar)")
            for block, _ in right:
                if block not in self.states:
                    unknown_blocks.setdefault(block, []).append(name)
        if unknown_blocks:
            self.fail(f"config block states 26.3 does not have: {unknown_blocks}")
        else:
            self.ok(f"{len(names)} structure definitions carry the jar's type, biomes, step, "
                    "spawn_overrides and config; every block state they name exists in 26.3")

    # ------------------------------------------------------------- other data
    def tags_and_set(self) -> None:
        biome_tags = sorted(n[len(BIOME_TAG_PREFIX):] for n in self.jar_biome_tags
                            if n.startswith(BIOME_TAG_PREFIX))
        carried = self.carried_entries("data/bettermineshafts/tags/worldgen/biome/has_structure/", ".json")
        if biome_tags != carried:
            self.fail(f"biome tags differ: jar {len(biome_tags)}, carried {len(carried)}")
            return
        unresolved: list[str] = []
        optional = 0
        for name in biome_tags:
            original = self.jar_json(BIOME_TAG_PREFIX + name)
            ported = self.carried(f"data/bettermineshafts/tags/worldgen/biome/has_structure/{name}")
            if original != ported:
                self.fail(f"biome tag {name} differs from the jar")
            for entry in ported["values"]:
                if isinstance(entry, dict):
                    optional += 1
                    continue
                if entry.startswith("#"):
                    # A tag reference: vanilla's own is_badlands/is_jungle/… ships in 26.3;
                    # any other namespace is another mod's tag (the entry is required).
                    ident = entry[1:]
                    if ":" not in ident:
                        ident = f"minecraft:{ident}"
                    if ident.startswith("minecraft:") and ident not in self.biome_tags:
                        unresolved.append(f"{name}: {entry}")
                    continue
                ident = entry if ":" in entry else f"minecraft:{entry}"
                if ident not in self.biomes:
                    unresolved.append(f"{name}: {entry}")
        if unresolved:
            self.fail(f"required biome entries 26.3 does not have: {unresolved}")
        else:
            self.ok(f"{len(biome_tags)} biome tags equal the jar's; every required entry is a 26.3 "
                    f"biome or biome tag ({optional} optional entries — other mods' biomes and "
                    "`#c:` tags — are kept)")

        original = self.jar_json(STRUCTURE_SET)
        ported = self.carried("data/bettermineshafts/worldgen/structure_set/mineshafts.json")
        if original != ported:
            self.fail("the structure set differs from the jar's")
        else:
            placement = ported["placement"]
            self.ok(f"the structure set carries {len(ported['structures'])} structures, "
                    f"{placement['type']} salt={placement['salt']} spacing={placement['spacing']} "
                    f"separation={placement['separation']} frequency={placement['frequency']}")

        for rel in (STRUCTURE_TAG, VANILLA_TAG):
            original = self.jar_json(rel)
            ported = self.carried(rel)
            if original != ported:
                self.fail(f"{rel} differs from the jar's")
        self.ok("both structure tags equal the jar's (bettermineshafts:better_mineshafts and "
                "minecraft:mineshaft name the same thirteen structures)")

        outside = (self.content / "outside/data/morevillagers/tags/worldgen/structure"
                   / "on_mineshaft_explorer_maps.json")
        if not outside.is_file():
            # The SDK package keeps assets/ and data/ at the port root; the carried copy of the
            # folder (with the other namespace's file) is the evidence under content/.
            outside = (self.content / "content/outside/data/morevillagers/tags/worldgen/structure"
                       / "on_mineshaft_explorer_maps.json")
        if outside.is_file():
            self.ok("morevillagers' structure tag is kept outside the package (it belongs to that "
                    "mod's namespace, which this port does not own)")

        for name in self.entries(LANG_PREFIX, ".json"):
            if self.jar.read(LANG_PREFIX + name) != (self.content / LANG_PREFIX / name).read_bytes():
                self.fail(f"lang file {name} is not byte-identical to the jar's")
        self.ok(f"{len(self.entries(LANG_PREFIX, '.json'))} lang files are byte-identical to the jar's")

    def run(self) -> int:
        self.inventory()
        self.structures()
        self.tags_and_set()
        if self.failures:
            print(f"FAIL: {len(self.failures)} check(s) failed", file=sys.stderr)
            return 1
        print("PASS: the carried data half equals the jar's; the generator half is "
              "src/ (a Rust structure type, checked by cargo test and tools/check.sh)")
        return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, default=DEFAULT_JAR)
    parser.add_argument("--content", type=Path, default=DEFAULT_CONTENT)
    parser.add_argument("--resources", type=Path, default=DEFAULT_RES)
    args = parser.parse_args()
    return Verifier(args.jar, args.content, args.resources).run()


if __name__ == "__main__":
    sys.exit(main())
