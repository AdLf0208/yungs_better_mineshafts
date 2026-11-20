# YUNG's Better Mineshafts for Horizon (partial: the generator and one vocabulary)

A port of **YUNG's Better Mineshafts 1.21.1-NeoForge-5.1.1** (mod id `bettermineshafts`, author
**YUNGNICKYOUNG**, **LGPL-3.0-only**) to Minecraft Java **26.3** on Horizon's SDK
`0b14f8acfd97fa2c750e42795249dcc981178ca4` (package format 6, `api = "0.2"`).

## What this package is

The jar's worldgen data **and** the structure type it needs, in one native package:

- the **thirteen structure definitions** (`mineshaft_oak`, `_acacia`, `_desert`, `_dripstone`,
  `_ice`, `_jungle`, `_lush`, `_mesa`, `_mushroom`, `_overgrown`, `_red_desert`, `_spruce`,
  `_spruce_snowy`) with the jar's `biomes`, `step`, `spawn_overrides` and the per-variant
  `config` (palette, randomizers, decoration chances), block states in 26.3's shape;
- the **structure set** (`random_spread`, salt 593751784, spacing 1, separation 0,
  `legacy_type_3`, frequency 0.003);
- the **thirteen biome tags** they select on, the two **structure tags** (its own and
  `minecraft:mineshaft`), and the three **lang files**, byte-identical;
- the mod's **structure type in Rust** (`src/`): `bettermineshafts:mineshaft` now generates its own
  geometry instead of being an unsupported type —
  - a **vertical entrance**: 5×5 shaft from the surface, ladder, stone-brick doorway, legs;
  - a **9×8×24 main corridor**: planks and randomized floor, fence supports under covered cells,
    rails and powered rails, hanging lanterns, gravel piles, cobwebs, vines;
  - **5×5×8 branch corridors** off the side walls, **5×9×5 stairs** that climb a branch four blocks
    with ascending rails, and **10×5×5 workstation rooms** with iron bars and a crafting table;
  - every variant builds from **its own carried palette** (oak, acacia, spruce, jungle, mesa,
    desert, red desert, ice, mushroom, lush, dripstone, overgrown, snowy spruce);
- `/bettermineshafts status`: the structure, its four required biomes (+3 optional) and a
  deterministic probe's piece count.
- `/bettermineshafts last [chunkX chunkZ]`: the start the mod just generated — its chunk, position,
  piece counts and every stair's box.

## What it does not do yet — read this before installing

- **Proven in a real level, at the SDK pin** (`launcher@0.2.78`): `/place structure` writes the
  entrance's ladder, the corridor's rails, the doorway's stone bricks and the walls' planks; a stair
  climbs a branch four blocks with an ascending rail (read back in the passage); the ice variant
  builds from its own `packed_ice` palette; the located start's column answers `execute if biome`
  for `minecraft:plains`, an entry of the carried tag. The unmodified Nightly refuses the id and
  writes nothing. The e2e does not yet read a placed workstation room's blocks.
- **Five of the ten piece kinds are gaps**: turns, layered intersections, ore deposits,
  zombie-villager rooms, side-room dungeons.
- **The terrain-driven surface tunnel** is not built (the shaft half of the entrance is).
- **Biome decorations** (snow, lush, dripstone, cactus, dead bush, mushroom) are not placed: the
  piece context has neither a biome nor configured features.
- **Minecarts, chests, furnaces and barrels** are not added (their payloads are unverified).
- **Vanilla mineshafts still generate** beside this mod's (upstream turns them off with a mixin;
  the SDK has no equivalent hook).

## Layout

```
horizon-mod.toml    the manifest (id, version 0.2.2, api 0.2, [native] pins)
Cargo.toml          the crate (depends on the fetched SDK's horizon-mod-api)
src/lib.rs          the one #[mod_api::horizon_mod] impl Hooks
src/runtime.rs      the pure layout logic and its tests (no mod_api type)
src/pieces.rs       the five piece writers, the palette resolver, save/load
src/support.rs      the structure type, the config reader, the commands, the last-start record
assets/, data/      the carried content, at the package root (SDK layout)
bettermineshafts.hmod   the built package
content/            the carry evidence only (report, inventory, other namespace's tag)
patches/inventory.json  the inventory the carry tool reads
tools/              check.sh · carry_proof.py · e2e.sh · carry.sh · restore_jar_fields.py · verify_content.py
FINDINGS.md         jar inventory, the generator's behaviour, the piece list
notes.md            licence, what this slice does, gaps, verification, next slice
LICENSE             the jar's own LGPL-3.0 text
LICENSE-NOTICE.md   where the licence was read from
```

## Verify

```sh
ports/tools/build-slot.sh run --job bms-port --port ports/bettermineshafts \
    --step build -- ports/bettermineshafts/tools/check.sh   # tests, clippy, fmt, build, check, fits, carry proof
python3 tools/verify_content.py                             # the carried data vs the jar
ports/tools/launcher-game.sh build bettermineshafts          # after any src/ change
ports/tools/launcher-game.sh run bettermineshafts            # the in-game scenario (PASS + E2E EXIT:0)
python3 ports/tools/check-e2e-logs.py bettermineshafts-e2e --strict
```

## Licence

LGPL-3.0-only, rank 1: publishable under the same licence with this complete corresponding source
and the original copyright notice. `LICENSE` is the jar's own file; `LICENSE-NOTICE.md` records
where it was read from. Local use only until publication is approved (ARCHITECTURE.md §8).
