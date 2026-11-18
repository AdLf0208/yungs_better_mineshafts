# FINDINGS — YUNG's Better Mineshafts 5.1.1 (jar inventory and what is in it)

> **Read `notes.md` for the current state (0.2.0, 2026-11-18).** This file is the inventory the
> 0.1.0 content-only slice produced; its *counts* still hold (13 structure definitions, **0**
> `.nbt` templates, 0 pools, 0 processor lists), but the conclusion drawn at the end — that the
> generator is out of reach — is retired: the structure type is implemented in `src/` and the
> launcher leg proves it generates. The jar has no templates; the geometry is **written**, not
> carried.

Read from the artefact, not from the mod page: `unzip -l`, the jar's own JSON, and
`horizon-port-pack check|carry`. Repo analysis (`ports/_shared/upstream/bettermineshafts`,
`682a598`, branch `1.21.1`, deleted after this file was written) supplied the generator's
behaviour only.

## Provenance

| | |
|---|---|
| Mod | YUNG's Better Mineshafts, mod id `bettermineshafts`, version `1.21.1-NeoForge-5.1.1` |
| Jar | `YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar`, **493,967 B**, **130 entries** |
| SHA-1 | `6a14e1d8201f068ca87ef8333e471c5378955906` — **equal to ATM10's `modrinthHash`** |
| SHA-256 | `5625930dfb3240820d6e4ecf55fff0c39f70ce782fad117a4d418251184c7be0` |
| Source | Modrinth project `HjmxVlSr` (slug `yungs-better-mineshafts`), version `Go3nbneL` |
| Pack record | `ports/_shared/licence-cache/atm10-modlist.json` → `YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar`, same `modrinthHash` |
| Jar kept | `ports/_shared/licence-cache/YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar` |
| Required by the jar | `yungsapi` `[1.21.1-NeoForge-5.1.2,)` (`neoforge.mods.toml`) |

This is the pack's own version, not a fallback.

## Licence — read from the jar

- `META-INF/neoforge.mods.toml` → `license="LGPLv3"`.
- Archive root `LICENSE_YungsBetterMineshafts`, **7,817 B**: the full **GNU Lesser General
  Public License, Version 3, 29 June 2007**.
- `[[mods]] authors="YUNGNICKYOUNG"`.
- Modrinth project field: `LGPL-3.0-only`.
- Upstream repository `LICENSE` at `682a598`: the same LGPL-3.0 text.

→ **LGPL-3.0-only, licence rank 1 (copyleft).** `precheck-mod.py` exits 2 only because the
jar had not been read yet; it is read now. Publishable under the same licence with the
complete corresponding source; local-only until the maintainer approves publishing.

## The jar, counted

| Kind | Count |
|---|---:|
| Java classes | **51** (of which 10 generator/piece classes) |
| `data/bettermineshafts/worldgen/structure/*.json` | **13** |
| `data/bettermineshafts/worldgen/structure_set/*.json` | **1** |
| `data/bettermineshafts/tags/worldgen/biome/has_structure/*.json` | **13** |
| `data/*/tags/worldgen/structure/*.json` | **3** (this mod 1, `minecraft:mineshaft` 1, `morevillagers` 1) |
| `assets/bettermineshafts/lang/*.json` | **3** (`en_us`, `ru_ru`, `uk_ua`) |
| **Structure templates (`.nbt`)** | **0** |
| **`worldgen/template_pool`** | **0** |
| **`worldgen/processor_list`** | **0** |
| **`loot_table`** | **0** |
| `mixins` | 1 config, 5 patch classes |

`horizon-port-pack check` on the jar:

```
bettermineshafts: Partly. 14 worldgen files port; not 13 worldgen files of types written in
Java, 13 worldgen features or structure types in code.
  ports: 14 worldgen files
  skipped: 13 worldgen files of types written in Java
  skipped: 13 worldgen features or structure types in code
  skipped: 1 command
  skipped: 1 game event it reacts to (LevelEvent)
  skipped: 5 Mixins (patches to the game's code)
```

`carry-report.json` → `worldgen_types: { mapped: 0, block_states: 13,
unsupported: { "bettermineshafts:mineshaft": 13 } }`.

## The data half — 13 structures that are *configuration*, not pieces

All thirteen definitions share one type and one schema:

```json
{ "type": "bettermineshafts:mineshaft",
  "biomes": "#bettermineshafts:has_structure/better_mineshaft_<variant>",
  "step": "underground_structures",
  "spawn_overrides": {},
  "config": { "replacementRate": 0.6, "legVariant": "edge"|"center", "decorationChances": {…},
              "blockStates": {…}, "blockStateRandomizers": {…} } }
```

`config.blockStates` names the palette a variant is built from (main planks, support fence,
slab, gravel, stone-brick wall/slab, trapdoor, small leg), `blockStateRandomizers` the
weighted replacements (e.g. 10 % cobblestone in an oak floor, or mossy/cracked stone bricks
for the brick variants), `decorationChances` vines/snow/cactus/dead bush/mushroom/gravel
piles/lush/dripstone, and `legVariant` where the entrance legs go. Every variant differs only
in that config: same layout, different palette.

| Variant | Required biome entries in its tag |
|---|---|
| `acacia` | `minecraft:savanna`, `minecraft:savanna_plateau` |
| `desert` | `minecraft:desert` |
| `dripstone` | `minecraft:dripstone_caves` |
| `ice` | `minecraft:ice_spikes`, `minecraft:frozen_peaks` |
| `jungle` | `#minecraft:is_jungle` |
| `lush` | `minecraft:lush_caves` |
| `mesa` | `#minecraft:is_badlands` |
| `mushroom` | `minecraft:mushroom_fields` |
| `oak` | `minecraft:plains`, `sunflower_plains`, `swamp`, `meadow` |
| `overgrown` | `#minecraft:is_forest` |
| `red_desert` | `#minecraft:is_badlands` |
| `spruce` | `#minecraft:is_taiga` |
| `spruce_snowy` | `minecraft:snowy_taiga`, `snowy_plains`, `snowy_slopes`, `jagged_peaks` |

62 further entries are `{"id": …, "required": false}` — Terralith, Project Vibrant Journeys,
Regions Unexplored biomes and NeoForge's `#c:` tags. They stay in the carried files (all
optional: an absent biome is skipped, not an error).

The structure set `bettermineshafts:mineshafts` is vanilla's `minecraft:random_spread` with
**salt 593751784, spacing 1, separation 0, `frequency_reduction_method:
legacy_type_3`, frequency 0.003** — one candidate chunk in 333, the same shape vanilla's
mineshafts use, and all thirteen variants weighted 1.

## The generator half — Java, and the whole mod

`bettermineshafts:mineshaft` is registered by `StructureTypeModule` and implemented by
`BetterMineshaftStructure` + `BetterMineshaftGenerator` + ten piece classes. Read from the
source at `682a598`:

- `findGenerationPoint`: one `nextDouble`, then a random Y in `[minY, maxY]` (config default
  **-55 … 30**), start at the chunk's block (3, y, 3); the direction comes from
  `WorldgenRandom(LegacyRandomSource)` seeded on the chunk; the start is a `VerticalEntrance`
  whose `addChildren` builds the whole tree (no blocks are placed until `postProcess`).
- `BetterMineshaftGenerator`: chain limits (`chainLength > 3` stops big tunnels;
  `smallShaftPieceChainLength = 9`), roll thresholds 10/60/70/80/90 for big tunnels,
  intersections, stairs, turns and ore deposits; a chain's end becomes a `ZombieVillagerRoom`
  or an `OreDeposit` (`zombieVillagerRoomSpawnRate = 2`, ore weights cobble 50, coal 20,
  iron 9, redstone 7, gold 7, lapis 3, emerald 3, diamond 1).
- Pieces and their boxes (secondary × Y × main, world blocks):

| Piece | Box | Role |
|---|---|---|
| `VerticalEntrance` | 29-ish column, shaft at local x/z 22–26 | entry shaft down from `y`, picks the tunnel floor |
| `BigTunnel` | 9 × 8 × 24 | the main shaft: planks floor/walls, fence supports, slabs, rails, lanterns/torches, carts |
| `SmallTunnel` | 5 × 5 × 8 | branch corridor, cobwebs/torches/carts |
| `SmallTunnelStairs` | 5 × 9 × 5 | descends one layer |
| `SmallTunnelTurn` | 5 × 5 × 5 | turn, `TurnDirection` |
| `LayeredIntersection4` | 7 × 9 × 7 | four-way stacked crossing |
| `LayeredIntersection5` | 5 × 10 × 5 | five-way stacked crossing |
| `SideRoom` | 10 × 5 × 5 | workstation room off the main shaft |
| `SideRoomDungeon` | 9 × 4 × 9 | cellar under a workstation (spawner + chests) |
| `ZombieVillagerRoom` | 7 × 5 × 7 | chain-end room |
| `OreDeposit` | 5 × 5 × 4 | chain-end ore vein, `OreType` |

- Decorations and spawn rates (`lantern 0.0067`, `torch 0.02`, `cobweb 0.15`,
  `smallShaft 0.07`, carts `0.00125`/`0.0025`, …) are config, not data.
- `DisableVanillaMineshaftsMixin` (config `disableVanillaMineshafts = true`) turns vanilla
  mineshafts off, and `LocateVanillaMineshaftCommandMixin` adds a locate command. Neither is
  data.

**So there is no data half of the pieces**: no template, no template pool, no processor list,
no loot table. The thirteen JSON files are the *settings* the Java code would read.

## What the game at the pin does with the carried data

The pin knows this case and names it: `StructureKind::Unsupported(String)` — *"A structure
type whose generator is not implemented yet."*
(`horizon-world/src/worldgen/structure/start.rs:100-101`). The definition is registered (so
the id resolves), and `structure_start` returns `None` for it, which is what `/place
structure` reports as *"Failed to place structure"* and `/locate structure` as *"Could not
find a structure of type … nearby"*. Measured in game in
`ports/_shared/evidence/bettermineshafts/e2e-default.log`.

Consequence, recorded as a gap: **vanilla mineshafts still generate** (upstream turns them
off with a mixin), so the carried data is inert until a generator of that type exists.

## The carried folder (`content/`)

33 data/resource files (32 carried + the port's `horizon-mod.toml`), every one from the jar:

```
assets/bettermineshafts/lang/{en_us,ru_ru,uk_ua}.json            byte-identical
data/bettermineshafts/tags/worldgen/biome/has_structure/*.json   13, equal to the jar (+ "replace": false)
data/bettermineshafts/tags/worldgen/structure/better_mineshafts.json
data/minecraft/tags/worldgen/structure/mineshaft.json            the 13 added to vanilla's tag
data/bettermineshafts/worldgen/structure/*.json                  13, jar's type/step/spawn_overrides
                                                                  + 26.3-shaped config block states
data/bettermineshafts/worldgen/structure_set/mineshafts.json     equal to the jar
outside/data/morevillagers/tags/worldgen/structure/on_mineshaft_explorer_maps.json
                                                                  kept out: another mod's namespace
```

Two rewrites, both recorded in `notes.md`: the carry's 1.21.1 → 26.3 block-state shape in the
thirteen configs, and `restore_jar_fields.py` putting back `type`/`step`/`spawn_overrides`
(the carry drops them for a Java type) and `"replace": false` on the tags (the loader's
default; restored for byte fidelity).

No block id in any config is unknown to 26.3 (`tools/verify_content.py` checks all of them
against the prepared 26.3 `facts.json`): nothing this mod names was renamed or removed, unlike
Moog's `minecraft:chain` → `iron_chain` case.

## What the 0.1.0 port did not have (the generator exists now)

- ~~The generator~~ **— ported (0.2.0).** `register_structure_type("mineshaft", …)` with
  `StructureType`, `GenerationContext` and `PieceContext` landed in SDK `0b14f8a`; four of the ten
  piece kinds (entrance, corridor, branch, workroom) are written and proven in game. The other six,
  the surface tunnel, the corridor legs and the carts/chests are still missing — `notes.md` lists
  them with the reason.
- `DisableVanillaMineshaftsMixin` (vanilla mineshafts stay).
- YUNG's API's `yungsapi` placement/terrain helpers, which the type would use.
- The mod's own config file (`config/bettermineshafts-common.toml` shape) — the values live in
  `ConfigModule`'s defaults; the structure JSON carries the per-variant palette.
