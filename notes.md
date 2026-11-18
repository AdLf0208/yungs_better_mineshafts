# YUNG's Better Mineshafts — port notes

Ported from **YUNG's Better Mineshafts 1.21.1-NeoForge-5.1.1** (mod id `bettermineshafts`) for
Minecraft Java 26.3 on the **SDK `0b14f8acfd97fa2c750e42795249dcc981178ca4`** (horizon-mixins
`e59da9094f0c2fdda6c627fe9eff22dec6a906f0`, package format 6, `api = "0.2"`).

**Class + tier:** `content` / `deep` for this slice
(`ports/_shared/source-map/atm10-sources.csv:66`, mirroring
`horizon/docs/modpacks/atm10-mods.csv`). The approach is the tier's **code** shape from
`docs/modpacks.md`: the carried data is content, and the generation is a Rust structure type.
Slice 1 delivers **one structure that generates in a level** with its own piece geometry.

**Status: `ported-partial`, and proven in a real level.** The jar's own structure type is now
implemented in Rust (`StructureType` + `StructurePiece`), so `bettermineshafts:mineshaft_oak` no
longer resolves to an unsupported type: the type emits an entrance shaft, a main corridor, branch
corridors and workstation rooms with the jar's palette. The launcher leg (2026-11-18,
`launcher@0.2.78` at the SDK pin) builds this package into a game: `/place structure
bettermineshafts:mineshaft_oak` writes the entrance's ladder, the corridor's rails, the doorway's
stone bricks and the walls' oak planks into the world, the ice variant writes its own
`packed_ice`, and the same Nightly without the package refuses the id and leaves the column empty.
The scope stays partial — the six unbuilt piece kinds are listed under **Gaps**.

## The old premise was wrong — corrected here

The previous slice recorded `blocked(java-structure-type)` with the reading *"the generator is ten
Java classes and a chain layout; it needs a structure type registered in code"*. The **second half
was right, the first half was misleading**: it suggested the obstruction was "Java code we cannot
run", when the obstruction was only *"no API to register a structure type"* — and that API landed
in SDK `0b14f8a`:

- `StructuresRegistrar::register_structure_type` — `ports/_shared/sdk/0b14f8a/api-source/
  crates/horizon-mod-vocab/src/parts/structures.rs:19` —
  `pub fn register_structure_type<T: crate::StructureType>(&mut self, name: &str, ty: T)`,
  reached from `impl Hooks::register`'s `&mut dyn Registrar`;
- `StructureType`/`StructurePiece`/`GenerationContext`/`PieceContext`/`StructureRandom` —
  `.../crates/horizon-mod-vocab/src/world/structure_type.rs`.

Nothing in the jar *is* Java-only; the geometry is authored in code, so a port **writes** it, which
is what this slice does. The `blocked(...)` record is retired. What remains blocked is narrower and
named under **Gaps** (biome decorations, the terrain-driven surface tunnel, minecarts and block
entities, and the six piece kinds not implemented).

## Licence — LGPL-3.0-only, rank 1 (copyleft, publishable)

Read from the jar, not from the project page:

- `META-INF/neoforge.mods.toml` → `license="LGPLv3"`;
- `LICENSE_YungsBetterMineshafts` (archive root, 7,817 B) → the full LGPL-3.0 text;
- Modrinth project `HjmxVlSr` → `LGPL-3.0-only`; upstream `LICENSE` at `682a598` → the same text;
- the repo has **no separate asset licence**, so there is no asset rider (unlike Twilight Forest).

Copyleft is publishable under the same licence with the complete corresponding source;
**local-only until the maintainer approves publishing** (ARCHITECTURE.md §8 — that approval exists,
so publication is the first-publication route in the changelog below). `LICENSE` (the jar's own
file, byte-identical) and [`LICENSE-NOTICE.md`](LICENSE-NOTICE.md) travel inside the package: the
SDK packer includes a root `LICENSE`/`LICENSE-NOTICE.md` by itself (evidence `package.txt`).

## Provenance

**5.1.1**, `YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar`, **493,967 B**, 130 zip entries (95
files); SHA-1 `6a14e1d8201f068ca87ef8333e471c5378955906` — **equal to ATM10's `modrinthHash`**;
SHA-256 `5625930dfb3240820d6e4ecf55fff0c39f70ce782fad117a4d418251184c7be0`. Kept at
`ports/_shared/licence-cache/`. `precheck-mod.py bettermineshafts` → exit 0, licence
`LGPL-3.0-only`, rank 1.

## The jar, counted (the brief's "20 structure JSONs" is wrong; the artefact wins)

| Kind | Count |
|---|---:|
| `data/bettermineshafts/worldgen/structure/*.json` | **13** |
| `worldgen/structure_set/*.json` | 1 |
| `tags/worldgen/biome/has_structure/*.json` | 13 |
| `data/*/tags/worldgen/structure/*.json` | 3 (this mod, `minecraft:mineshaft`, `morevillagers`) |
| `assets/bettermineshafts/lang/*.json` | 3 |
| **`.nbt` structure templates** | **0** |
| **`worldgen/template_pool` / `processor_list` / `loot_table`** | **0 / 0 / 0** |

`unzip -l | grep -c worldgen/structure/` prints 20 because it also counts four directory entries and
the two tag namespaces; the definitions are 13. Evidence: `jar-inventory.txt`.

So the port **carries settings, not pieces**. The pieces are ten Java classes that build their
blocks in `postProcess`, which is exactly why the generation is Rust code in this package.

## Upstream analysis (analysis aid only)

Repo `https://github.com/YUNG-GANG/YUNGs-Better-Mineshafts`, branch `1.21.1`, commit
`682a598efa366b76f51de1a6520d307de520b6da` (shallow clone, deleted after the findings were
written). Files read this slice: `world/BetterMineshaftStructure.java`,
`world/generator/BetterMineshaftGenerator.java`, `world/generator/pieces/{BetterMineshaftPiece,
VerticalEntrance,BigTunnel,SmallTunnel,SideRoom}.java`, `module/ConfigModule.java`, and the
thirteen `data/bettermineshafts/worldgen/structure/*.json`. **No Java was translated**: the layout,
the boxes and the decoration rules were re-derived and written as Rust with tests.

## The SDK surface this port uses (quoted)

All from `ports/_shared/sdk/0b14f8a/api-source/`:

| Symbol | Where | Signature used |
|---|---|---|
| `Registrar::register_structure_type` | `horizon-mod-vocab/src/parts/structures.rs:19` | `fn register_structure_type<T: StructureType>(&mut self, name: &str, ty: T)` |
| `StructureType` | `horizon-mod-vocab/src/world/structure_type.rs:58` | `fn find_generation_point(&self, ctx: &mut dyn GenerationContext) -> Option<FoundStructure>`, `fn load_piece(&self, metadata: &dyn BlockMetadata, tag: &Compound) -> Result<Arc<dyn StructurePiece>, StructureError>`, `fn after_place(...)` (defaulted, unused here) |
| `FoundStructure` | `…/structure_type.rs:47` | `{ position: [i32; 3], pieces: Vec<Arc<dyn StructurePiece>> }` |
| `StructurePiece` | `…/structure_type.rs:132` | `bounding_box() -> BoundingBox`, `post_process(&self, ctx: &mut dyn PieceContext)`, `add_additional_save_data(&self, tag: &mut Compound)` |
| `StructureRandom` | `…/structure_type.rs:152` | `next_int_bound`, `next_long`, `next_float`, `next_double`, `next_boolean` |
| `GenerationContext` | `…/structure_type.rs:249` | `metadata()`, `chunk() -> ChunkPos`, `seed()`, `min_y()`, `max_y()`, `random()`, `base_height(x, z, HeightmapType)`, `config() -> Arc<Tag>` |
| `PieceContext` | `…/structure_type.rs:286` | `chunk_box() -> BoundingBox`, `random()`, `state(BlockKey)`, `state_with(BlockKey, &[(&str, &str)])`, `is_air(BlockState)`, `block([i32; 3]) -> Option<BlockState>`, `set_block([i32; 3], BlockState) -> bool`, `solid_render(BlockState)` |
| `BoundingBox` | `horizon-core/src/bounding_box.rs:1` | `new(min, max)`, `min`/`max`, `is_inside`, `span` (inclusive box) |
| `BlocksRegistrar::block_key` | `horizon-mod-vocab/src/parts/blocks.rs:133` | `fn block_key(&mut self, id: &str) -> BlockKey` (registration time only; see the gap) |
| `BlockState::of` / `StateConstraint` | `horizon-mod-vocab/src/block/block_state.rs:40`, `block/block_states.rs:31` | `BlockState::of(metadata, block, &[StateConstraint])` |
| `StructureError` | `…/structure_type.rs:26` | `StructureError(String)`, `Display + Error` |

The package's own `uses.json` (inside the `.hmod`) records 223 SDK entries, including
`method:StructureType::find_generation_point`, `method:StructureType::load_piece`,
`method:StructurePiece::post_process`, `method:GenerationContext::config`,
`method:PieceContext::set_block`, `method:BlocksRegistrar::block_key` and
`handle:Registrar::register_structure_type` — `sdk-uses.txt`.

## The piece vocabulary (what this slice writes, and what it drops)

Four kinds, each a `StructurePiece` with its own writer (`src/pieces.rs`):

| Kind | Box | Writes | Upstream source |
|---|---|---|---|
| `Entrance` | 5 × (surface−floor−1) × 5 | the shaft's walls patched with planks and randomized through `mainRandomizer`, plank floor, carved 3×3 shaft, ladder on the back wall facing in, stone-brick doorway with a slab lintel, four legs down up to 6 blocks | `VerticalEntrance.java:129-160` |
| `Corridor` | 9 × 8 × 24 | randomized walls, plank/randomized floor, vaulted carve (7-wide to y 5, 5-wide at 6, 3-wide at 7), fence supports on covered cells (big/small), rails with powered ones, hanging lanterns, gravel piles, cobwebs, vines | `BigTunnel.java:162-192`, `:427-544` |
| `Branch` | 5 × 5 × 8 | the same at small scale: supports on covered cells, rails, cobwebs, vines, its doorway into the corridor | `SmallTunnel.java:104-127` |
| `Room` | 10 × 5 × 5 | brick floor and wall ring from `brickRandomizer`, carved interior, ceiling patched only where terrain has a block, iron-bar columns under cover, half-chance crafting table, doorway into the corridor, corner legs | `SideRoom.java:103-162` |

The layout is `BetterMineshaftGenerator`'s: a 5×5 shaft at the chunk's block (3, y, 3); the main
corridor starts three blocks off the shaft's centre and each segment's far face is the next
segment's near face; the corridor continues while `nextInt(100) >= 10 || depth < 2` and stops after
depth 3 (`chainLength > 3`); a branch hangs off a side wall with chance `0.07` (a straight run of
at most 3 segments — upstream allows 9 *and* turns); a workstation room with chance `0.025`.
`src/runtime.rs` also carries `ConfigModule`'s rates (`lantern 0.0067`, `torch 0.02`,
`workstation 0.025`, `smallShaft 0.07`, `cobweb 0.15`) and `minY -55 … maxY 30`.
`legVariant` is upstream's `edge`/`inner` (`BetterMineshaftConfiguration.LegVariant:135-137`); it is
parsed, saved and reloaded, but the corridor's EDGE/INNER leg patterns are not built yet, so it
changes nothing in the writers (recorded below).

**Dropped, with the reason:**
- **stairs, turns, layered intersections 4/5, ore deposits, zombie-villager rooms, side-room
  dungeons** — six more piece classes with their own geometry. The brief's stop condition applies:
  a small faithful vocabulary rather than twenty invented ones. `BetterMineshaftGenerator.java:63-103`
  is the roll table they would use.
- **the terrain-driven surface tunnel** (`VerticalEntrance.determineDirection`, `:300-361`) — it
  samples the surface in a ring and *chooses* a direction and a length at generation time; the port
  builds the shaft half only.
- **biome decorations** (`snow`, `cactus`, `dead bush`, `mushroom`, `lush`, `dripstone`) — upstream
  places **configured features** and asks the biome; `PieceContext` has no biome and no feature
  placement (`structure_type.rs:286-323`).
- **minecarts, chests, furnaces, barrels** — they need entity/block-entity payloads whose exact NBT
  the port cannot verify without a launcher, and `LevelRef::set_block` drops block entities. No
  loot table is carried either (the jar has none; upstream uses `chests/abandoned_mineshaft`).
- **loot/torch on branch walls**: the torch placement is implemented as supports and cobwebs only;
  wall torches need the wall behind them and are not written.

## The palette comes from the data, not from the code

Every structure's `config` (`blockStates`, `blockStateRandomizers`, `decorationChances`,
`replacementRate`, `legVariant`) is read from `GenerationContext::config()` and overrides
`Palette::oak_defaults()` field by field (`src/support.rs::palette_from`). That is why the mesa
variant builds from terracotta and the desert one from sandstone without a line of per-variant code.
The reader accepts both the 26.3 shape (`{"id": …, "properties": …}`) and the 1.21.1 spelling
(`Name`/`Properties`), and every number as int, long, float or double — the JSON→NBT conversion at
load is not documented field by field, so the reader is tolerant by design and the oak defaults are
the fallback for anything it cannot see.

`legVariant` was first read as `center` from an earlier shorthand; the artefact says `inner`
(`ice` and `mushroom` carry it), so the reader accepts `inner` and keeps `center` as an alias.

Block keys are requested **once at startup** for the union of every block the thirteen configs name
plus the nine fixed blocks (`support::REQUESTED_BLOCKS`, 76 names). This is forced by the API: the
only name→`BlockKey` route is `Registrar::block_key` (`parts/blocks.rs:133`), and a worldgen
context has no host. A data pack that adds a palette block outside that table makes
`find_generation_point` answer `None` for that structure — recorded as a gap.

## Layout logic and tests (`src/runtime.rs`, 25 tests total)

Pure Rust, no `mod_api` type: `Box3`, `Facing`, `PieceKind`, `PieceSpec::local_to_world`, the chain
rules, the clamps, the budget, the palette types, the randomizers, vanilla's LCG, and the readout.
`cargo test --offline` → **25 passed, 0 failed** (doc-tests 0).

The fail-capable ones (each builds an assembly that *would* differ if the rule broke):

| Test | What it proves |
|---|---|
| `pieces_do_not_overlap_and_their_local_frames_agree_with_their_boxes` | for four seeds, no two pieces overlap in volume **and** `local_to_world` reproduces each piece's box from its two extreme cells (a wrong frame would disagree) |
| `a_segment_continues_where_the_previous_one_ended` | consecutive corridors share no gap: the next near face is the previous far face ± 1 on the facing axis |
| `a_normal_start_places_an_entrance_a_corridor_a_branch_and_a_room` | seed 9's exact assembly: `17 pieces (entrance 1, corridor 4, branch 9, room 3)` |
| `every_facing_builds_a_contiguous_corridor_chain` | forty seeds covering **all four facings**, each with at least two contiguous corridor segments — this is the test the in-game run's bug needed (a negative run read its far face from the box's high coordinate and stopped after one segment) |
| `the_same_seed_gives_the_same_assembly_and_a_different_seed_does_not` | determinism per seed, and two seeds differ |
| `a_surface_above_the_world_ceiling_is_clamped_and_the_shaft_still_fits` | surface 400 in a 320-tall level → ceiling 318, shaft still inside the level (**clamp case**) |
| `a_floor_under_the_world_floor_is_clamped_and_recorded` | floor −300 → −58 and `Refusal::FloorClamped` names the ask and the answer |
| `a_surface_too_low_over_the_floor_refuses_the_start` | floor 10 / surface 12 → `Refusal::Shaft`, no pieces |
| `a_budget_below_two_refuses_the_start` | `budget = 1` → `Refusal::Budget { needed: 2 }`, no pieces (**budget-refusal case**) |
| `a_small_budget_stops_the_chain_and_says_so` | `budget = 3` → exactly 3 pieces, `truncated`, and the three are the funded assembly's first three (a budget stops a chain, it does not change it) |
| `a_corridor_opens_its_wall_where_a_room_hangs_off_it` | the room's doorway column is exactly the corridor's carved opening |
| `the_probe_is_deterministic_and_its_summary_is_what_the_readout_prints` | the probe is stable **and** its pinned summary is `17 pieces (entrance 1, corridor 4, branch 12, room 0)` — the in-game readout printed exactly that |
| `the_biome_list_is_the_carried_tag_and_the_palette_is_the_carried_config` | `BIOME_ENTRIES` and `Palette::oak_defaults` are read out of the **carried** tag/config files (`include_str!`) |
| `every_block_the_carried_configs_name_is_requested` | reads all thirteen configs from disk, finds 13 files and ≥60 block ids, and fails if any is missing from `REQUESTED_BLOCKS` |
| `a_palette_round_trips_through_its_saved_tag` | save/load is lossless, floats by bits, properties included |
| `a_saved_piece_without_its_box_or_palette_is_a_typed_error_never_a_panic` | `load_piece` refuses a tag without `BB`/kind with a `StructureError` |
| `a_saved_piece_reads_its_kind_facing_box_and_openings_back` | kind, facing, depth, box and openings survive the round trip |
| `the_config_overrides_the_oak_defaults_field_by_field`, `a_config_with_no_fields_is_the_oak_palette_and_the_root_is_accepted`, `the_121_and_263_spellings_of_a_block_state_both_read` | the config reader: overrides, oak fallback, wrapped-or-bare root, both block-state spellings |
| `vanilla_random_matches_the_lcg_arithmetic_it_documents`, `the_randomizer_picks_by_cumulative_probability_and_falls_back_to_its_default`, `decorations_are_stable_and_inside_their_piece`, `facings_round_trip_and_their_axes_are_right_handed`, `the_entrance_shaft_is_five_wide_and_centred_on_the_start` | the primitives those rules stand on |

`/bettermineshafts status` prints exactly what the probe test pins:

```
bettermineshafts: structure bettermineshafts:mineshaft_oak (type bettermineshafts:mineshaft) — one of 13 carried variants
bettermineshafts: biomes 4 required (+3 optional): minecraft:plains, minecraft:sunflower_plains, minecraft:swamp, minecraft:meadow
bettermineshafts: probe seed 20261118 chunk 0,0, floor 0, surface 48 -> 17 pieces (entrance 1, corridor 4, branch 12, room 0)
```

That is not a claim from the unit test alone: the launcher-built game answered these three lines
verbatim (`ports/_shared/evidence/bettermineshafts-e2e/e2e-launcher.log`), which is how the
readout, the probe and the pure logic are pinned to each other.

## Upstream defects fixed

**The start's height is drawn twice.** `BetterMineshaftStructure.findGenerationPoint` draws
`y = random.nextInt(maxY - minY + 1) + minY` for the `GenerationStub`'s position
(`BetterMineshaftStructure.java:42`) and then calls `generatePieces`, which draws the height
**again** from the same `context.random()` for the `VerticalEntrance` (`:62`). The stub's position
and the shaft's floor are therefore two different Y values for every mineshaft in the mod.

- **What the port does instead:** one draw. `src/support.rs::find_generation_point` draws the floor
  once and uses it both for `FoundStructure::position` and for the entrance's box, so the start the
  engine records is the start the pieces occupy.
- **What a user notices:** the structure's start and its shaft agree — the start box is where the
  entrance is, which matters for `/locate`, for the chunk's structure reference and for box
  overlap checks against other structures.
- **Worth an upstream report?** Yes, it is a one-line fix (pass the drawn `y` into
  `generatePieces`); not filed — the campaign files upstream reports only on request.

### Defects the in-game run caught (port defects, fixed here)

**A westward/northward corridor chain stopped after one segment.** The next segment's near face was
computed from the box's **high** coordinate on every facing; for a negative run (`west`, `north`)
the near face is the **low** one, so the second segment overlapped the first, the collision check
refused it and the chain ended. The readout exposed it on the first game run: the probe faces west
and reported `5 pieces (entrance 1, corridor 1, branch 3, room 0)` instead of `17`. Fixed in
`runtime::assemble` (the far face is `max` on a positive run and `min` on a negative one), covered by
`every_facing_builds_a_contiguous_corridor_chain`, and re-measured in game: the probe now prints
`17 pieces (entrance 1, corridor 4, branch 12, room 0)` and the placed structure holds several
rails (5 in the recorded run) instead of a single segment's handful. A unit test with only south-facing seeds (the original suite)
could not see it — the lesson is recorded in **Traps**.

## Gaps (with what blocks them)

- **The in-game leg passes — what it does *not* yet cover.** The three legs are green (below), but
  they assert the entrance, the corridor, the doorway and two palettes; they do **not** reach a
  branch corridor or a workstation room (their positions depend on the chunk seed and the sites
  chosen), the biome decorations (not built), or the six unbuilt piece kinds. `tools/e2e.sh` grows a
  leg when the piece exists, rather than asserting around it.
- **Biome decorations:** `addBiomeDecorations` (`BetterMineshaftPiece.java:175-240`) places
  configured features and reads the biome; `PieceContext` (`world/structure_type.rs:286-323`) has
  neither. Snow/lush/dripstone/cactus/dead-bush/mushroom decorations are dropped, vines are kept.
- **Corridor legs (`edge`/`inner`):** `BigTunnel.generateLegsVariant1/2` (`BigTunnel.java:253-369`)
  draws plank legs from the corridor's edges or its inner line and hangs supports between them; the
  port parses `legVariant` but writes no corridor legs.
- **Surface tunnel:** `VerticalEntrance.determineDirection` (`VerticalEntrance.java:300-361`)
  samples the surface ring and picks a direction and length at generation time; the port builds the
  shaft only.
- **Six piece kinds:** stairs, turns, layered intersections 4/5, ore deposits, zombie-villager
  rooms and side-room dungeons (`BetterMineshaftGenerator.java:63-103`).
- **Minecarts, chests, furnaces, barrels:** not attempted in this slice. `PieceContext::entity` and
  `block_entity` (`structure_type.rs:319-322`) exist and the launcher leg can verify their payloads
  now, so this is next-slice work rather than an API gap; `LevelRef::set_block` still drops block
  entities, so those need `block_entity` and not a state write.
- **A palette block outside `REQUESTED_BLOCKS`:** `Registrar::block_key`
  (`horizon-mod-vocab/src/parts/blocks.rs:133`) is the only name→key route and it is registration
  time only, so a data pack that names a new block makes that structure's start `None`. The table
  covers all thirteen carried configs (tested).
- **The config's NBT shape: measured in game, and read tolerantly.** `GenerationContext::config()`
  is documented as "the structure's NBT config, converted once when its definition loads"
  (`structure_type.rs:278-279`) without naming the conversion, so the reader accepts a wrapped or
  bare root, both block-state spellings (`id`/`Name`) and every numeric tag. The launcher leg
  confirms it end to end: the ice variant — whose config names `packed_ice` as its main, support and
  brick block — placed 574 `minecraft:packed_ice` and **no** oak planks, so the per-variant config
  really reaches the pieces. What remains untested is a *data pack* that changes the config after
  the fact.
- **Vanilla mineshafts are not disabled.** Upstream's `DisableVanillaMineshaftsMixin` turns them
  off (`disableVanillaMineshafts = true`); the SDK has no "disable a vanilla structure" hook, and
  `horizon:disables` applies only to a replacement that can start (`docs/modpacks.md`). Vanilla
  mineshafts therefore still generate beside this mod's.
- **`morevillagers`' explorer-map tag** stays outside the package (`content/outside/`): another
  mod's namespace.
- **Not ported at all:** the locate command mixin, the biome/ore/spawn config file (Java
  `ModConfigSpec`; its defaults are recorded above) and `yungsapi`'s placement/terrain helpers.

## Verification

Skills: superpowers/using-superpowers,writing-plans,test-driven-development,systematic-debugging,verification-before-completion; BeautifulRust/rust-best-practices

Everything ran through `ports/tools/build-slot.sh` (`BUILD_LOCAL=1`, one lease, `CARGO_INCREMENTAL=0`,
`TMPDIR` inside the port); `ports/_shared/evidence/bettermineshafts/` holds the logs.

| Check | Evidence |
|---|---|
| `cargo test --offline` | **25 passed, 0 failed**, doc-tests 0 (`ladder.log`) |
| `cargo clippy --offline --all-targets -- -D warnings` | 0 warnings |
| `cargo fmt --check` | clean |
| `cargo horizon-mod build` | `bettermineshafts.hmod`, **65,749 B**, SHA-256 `fe2740675665d2c3999a3998ecafa5c9abaf218b874713ce22b19aa870d16798`, **42 entries** |
| the same build, second time in the lease | `cmp` clean — **byte-identical** |
| `cargo horizon-mod check bettermineshafts.hmod` | exit 0: `native-mod, format native-1/0b14f8ac…/e59da909…, for 26.3`, unsigned |
| `cargo horizon-mod fits bettermineshafts.hmod` | exit 0: `0b14f8a  made for` |
| `python3 tools/carry_proof.py` | **34 files identical** to the superseded 0.1.0 package (32 content + `LICENSE` + `LICENSE-NOTICE.md`); manifest rewritten on purpose |
| `python3 tools/verify_content.py` | **PASS**: 13 definitions, 13 biome tags, the set and both structure tags equal the jar's; every block state resolves in 26.3; 3 lang files byte-identical |
| `tools/e2e.sh`, launcher leg | **PASS + `E2E EXIT:0`** on the launcher-built game (`0b14f8a`, launcher 0.2.78): `e2e-launcher.log` |
| the same script, control | **FAIL + `E2E EXIT:1`** on the unmodified Nightly (`GAME=$CONTROL_GAME`): no command, the id refused, 0 ladder/rail/planks/packed ice — `e2e-launcher-control.log` |
| the same script, `SELFTEST=1` | **FAIL + `E2E EXIT:1`** (the readout is asserted to report 18 pieces and answers 17): `e2e-launcher-selftest.log` |
| `python3 ports/tools/check-e2e-logs.py bettermineshafts-e2e --strict` | **exit 0** — `logs=3 ok=3 missing-exit=0 bad-exit=0` |

The in-game transcript (abridged only where the log repeats the box listing; the full log has
every command and reply):

```
== A: /bettermineshafts status ==
bettermineshafts: structure bettermineshafts:mineshaft_oak (type bettermineshafts:mineshaft) — one of 13 carried variants
bettermineshafts: biomes 4 required (+3 optional): minecraft:plains, minecraft:sunflower_plains, minecraft:swamp, minecraft:meadow
bettermineshafts: probe seed 20261118 chunk 0,0, floor 0, surface 48 -> 17 pieces (entrance 1, corridor 4, branch 12, room 0)
== B: the carried set starts, and an id it does not carry does not ==
locate bettermineshafts:mineshaft_oak -> The nearest bettermineshafts:mineshaft_oak is at [16, ~, 48] (48 blocks away)
locate bettermineshafts:not_a_structure -> Could not find a structure of type "bettermineshafts:not_a_structure" nearby
== C: the oak mineshaft generates and writes its own blocks ==
forceload 1024 1024: Marked 49 chunks in minecraft:overworld from [61, 61] to [67, 67] to be force loaded
before: ladder=0 rail=0 oak_planks=0
place bettermineshafts:mineshaft_oak 1024 -20 1024 -> Generated structure "bettermineshafts:mineshaft_oak" at 1024, -20, 1024
after: minecraft:ladder=96
after: minecraft:rail=5
after: minecraft:oak_planks=490
after: minecraft:stone_brick_wall=4
-- read back at their own coordinates:
ctl block 1026 -51 1027 -> minecraft:ladder (the box found minecraft:ladder at [1026,-51,1027])
ctl block 1031 -51 1027 -> minecraft:rail (the box found minecraft:rail at [1031,-51,1027])
ctl block 1031 -52 1024 -> minecraft:oak_planks (the box found minecraft:oak_planks at [1031,-52,1024])
doorway frame: stone_brick_wall=4 around the ladder at 1026 -51 1027
== D: the ice variant builds from its own carried palette ==
before at the ice site: packed_ice=0
place bettermineshafts:mineshaft_ice 1536 -20 1536 -> Generated structure "bettermineshafts:mineshaft_ice" at 1536, -20, 1536
after at the ice site: packed_ice=548 oak_planks=0
PASS: bettermineshafts — bettermineshafts:mineshaft_oak generates its entrance (ladder at 1026 -51 1027, doorway stone
      bricks), corridor (rail at 1031 -51 1027) and plank walls (at 1031 -52 1024) in a real level;
      the ice variant builds from its own packed_ice palette; the readout reports
      17 pieces for the probe; and an id the mod does not carry is refused
E2E EXIT:0
```

The collar around the entrance (the 9×9×11 box the script reads, in the log) is the mod's own
randomizers at work: `cobblestone 13`, `cracked_stone_bricks 11`, `mossy_stone_bricks 9`,
`stone_bricks 8`, `oak_planks 78`, `gravel 37`, `ladder 9`, `stone_brick_wall 4`,
`stone_brick_slab 1` beside the terrain's `deepslate 438`, `sculk 70`, `tuff 3` — the plank walls
are patched through the stone, not a box drawn around it.

The control leg's own lines (the differential, which must fail):

```
status -> {"chat":["Unknown or incomplete command. See below for error","bettermineshafts status<--[HERE]"],"ok":true}
place bettermineshafts:mineshaft_oak 1024 -20 1024 -> There is no structure with type "bettermineshafts:mineshaft_oak"
control: minecraft:ladder=0
control: minecraft:rail=0
control: minecraft:oak_planks=0
control: minecraft:packed_ice=0
CONTROL OK: the same Nightly without the package knows no bettermineshafts: no command,
  the structure id refused, and no ladder/rail/planks/packed_ice in the site's column.
FAIL: CONTROL — this leg is the differential and must end non-zero (the modded run is the PASS)
E2E EXIT:1
```

Re-run:

```sh
ports/tools/launcher-game.sh build bettermineshafts    # after any src/ change: `run` reuses an export
ports/tools/launcher-game.sh run bettermineshafts      # the modded leg, in a build slot
eval "$(ports/tools/launcher-game.sh env bettermineshafts)"
ports/tools/build-slot.sh run --job e2e-bms-control --port ports/bettermineshafts --step e2e \
    -- env CONTROL=1 GAME="$CONTROL_GAME" bash ports/bettermineshafts/tools/e2e.sh
ports/tools/build-slot.sh run --job bms-port --port ports/bettermineshafts \
    --step build -- ports/bettermineshafts/tools/check.sh
python3 ports/tools/check-e2e-logs.py bettermineshafts-e2e --strict
```

## Package

`ports/bettermineshafts/bettermineshafts.hmod` — **65,749 B**, SHA-256
`fe2740675665d2c3999a3998ecafa5c9abaf218b874713ce22b19aa870d16798`, **42 entries**:
`horizon-mod.toml`, `Cargo.toml`, `src/{lib,runtime,pieces,support}.rs`, `assets/bettermineshafts/lang/*`
(3), `data/bettermineshafts/**` and `data/minecraft/tags/worldgen/structure/mineshaft.json` (29),
`LICENSE`, `LICENSE-NOTICE.md`, `README.md`, `uses.json`. **No `Cargo.lock`.** Listing: `package.txt`.

The content now lives at the package root (`assets/`, `data/`) because the SDK layout has no
`content/` directory; `content/` keeps only the carry evidence (`carry-report.json`, `check.json`,
the other namespace's file under `outside/`), and `tools/carry_proof.py` proves the move changed
nothing.

### Launcher-leg traps (measured this job)

- **`launcher-game.sh run` does not rebuild an existing export.** It builds only when the export is
  missing, so after a `src/` change it happily ran the *old* binary and reported the old readout
  (`5 pieces`) — twice, before it was obvious. Call `launcher-game.sh build <mod>` explicitly after
  any source change, then `run`.
- **A multi-line command reply needs all of `.chat`.** `ctl command "/bettermineshafts status" | jq
  -r '.chat[0]'` returned one line of three and the assertion "does not report the four required
  biomes" was a harness truncation, not a port failure.
- **`ctl blocks` entries carry the full state** (`minecraft:ladder[facing=east]`), so a position
  lookup must match a prefix (`startswith`), while `.counts` is keyed by the bare id.
- **`ctl find-block` is radius-limited in blocks.** The player stands at y≈120 while the mineshaft
  sits at y≈-51, so a 64-block radius found the ladder (whose top reaches the surface) but not the
  corridor's rail; the e2e reads positions out of the scanned column instead.
- **A helper's own `echo` is captured with its answer.** `VAR=$(helper)` takes everything the helper
  prints on stdout; the transcript lines inside `place`/`read_back` go to stderr, so the variable is
  only the reply (the first attempt fed `ctl` into `$(( … ))` and produced `ctl: unbound variable`).
- **A south-only unit suite cannot see a facing bug.** The chain bug above passed 24 tests because
  every seed in the layout tests happened to draw a positive facing; the in-game probe drew west.
  The suite now sweeps all four facings.

## Traps new to this port (beyond the brief's list)

- **`box` is a reserved word in edition 2024.** A field named `box` in a struct literal is a
  compile error (`expected identifier, found reserved keyword box`); the box field is `bounds`.
- **`JavaString::to_string_lossy()` returns `String`, not `Result`** in this SDK
  (`horizon-core/src/nbt.rs:30`); the fallible one is `to_string()` (`:27`). Mixing them up gives
  "no method `ok` found for `String`" in a dozen places at once.
- **`mod_api::block_key` does not exist**: it is `__private`
  (`horizon-mod-vocab/src/exports/registry_keys.rs:10`). The only name→`BlockKey` route a mod may
  call is `Registrar::block_key`, at registration, which is why the requested table exists.
- **A room or branch must be connected through the corridor's *own* wall.** Carving the attached
  piece's near face is not enough: the corridor's wall cell sits between them. The corridor carries
  an `Opening { along, len, side }` in its saved tag and carves it, so a save/load keeps the doorway.
- **Decoration positions must not be drawn inside `post_process`.** A support's slabs span three
  blocks and can cross a chunk border, so a `nextFloat` per chunk would build half a support in one
  chunk and a different half in the next. Supports and gravel piles are precomputed from a hash of
  the piece's box (`runtime::piece_seed`), stable across chunks and save/load.
- **Room/branch boxes must not overlap the corridor** or the piece-collision check refuses them; the
  port keeps them adjacent (one block outside the wall) and proves it.

## Next slice

1. ~~Run `tools/e2e.sh` on a launcher-built game~~ — done 2026-11-18 (PASS, control FAIL, selftest
   FAIL). The config NBT assumption is answered by leg D: the ice variant read `packed_ice` from its
   own config. Next: extend the scenario to a branch corridor and a workstation room once their
   positions are located from the placed assembly rather than guessed.
2. Add the remaining piece kinds from `BetterMineshaftGenerator`'s roll table — stairs, turns,
   layered intersections 4/5 first (they need the corridor's `genDepth`), then ore deposits and the
   zombie-villager room with their entities.
3. The surface tunnel and the biome decorations, once a context exposes the surface ring and the
   biome/configured features (or via `after_place`, which has a `PieceContext` but the same limits).
4. Disable vanilla mineshafts when the engine offers a hook for it (or via `horizon:disables` when
   a start can be proven).
5. Try `block_entity`/`entity` payloads for the furnace, barrel and minecarts once a game can
   confirm their NBT.

## Artifacts

- `bettermineshafts.hmod` — the package above.
- `src/{lib,runtime,pieces,support}.rs` — the type, the pure layout, the writers, the glue.
- `assets/`, `data/` — the carried content at the package root; `content/` — the carry evidence.
- `tools/check.sh` — the SDK ladder; `tools/carry_proof.py` — the carried-bytes proof;
  `tools/e2e.sh` — the unclaimed in-game scenario; `tools/carry.sh`,
  `tools/restore_jar_fields.py`, `tools/verify_content.py` — the content half (reproducible).
  `tools/package.sh` and `tools/notice.py` were the 0.1.0 content-only packager; the SDK packer
  now builds the package and includes the licence files, so they are removed (the 0.1.0 bytes they
  produced are preserved in the evidence folder).
- `../_shared/evidence/bettermineshafts-e2e/` — `e2e-launcher.log` (PASS, `E2E EXIT:0`),
  `e2e-launcher-control.log` (the unmodified Nightly, `E2E EXIT:1`), `e2e-launcher-selftest.log`
  (`E2E EXIT:1`).
- `../_shared/evidence/bettermineshafts/` — `ladder.log`, `package.txt`, `jar-inventory.txt`,
  `sdk-uses.txt`, `superseded-content-0.1.0.hmod`, plus the previous slice's
  `carry-check.txt`, `check.json`, `carry-report.json`, `verify-content.txt`, `hmod-build.log`,
  `e2e-default.log`, `e2e-selftest.log`.

## First publication — changelog (0.2.0)

**YUNG's Better Mineshafts for Horizon 0.2.0 — first publication.** LGPL-3.0-only; the complete
corresponding source is this repository (`src/`, the manifests, the tools), published under the same
licence with the jar's own `LICENSE` and a `LICENSE-NOTICE.md` naming where it was read.

- **New:** the mod's structure type in Rust (`bettermineshafts:mineshaft`), so the thirteen carried
  structure definitions generate instead of being unsupported.
- **New:** piece geometry — vertical entrance with ladder, doorway and legs; nine-wide main corridor
  with fence supports, rails, powered rails, hanging lanterns, gravel piles, cobwebs and vines; branch
  corridors; workstation rooms with iron bars and a crafting table.
- **New:** every variant builds from its own carried palette (oak, acacia, spruce, jungle, mesa,
  desert, red desert, ice, mushroom, lush, dripstone, overgrown, snowy spruce).
- **New:** `/bettermineshafts status` — the structure, its four required biomes (+3 optional) and a
  deterministic probe's piece count.
- **Changed:** the content moved to the SDK package layout (one flat `.hmod`, `assets/` and `data/`
  at the root); nothing carried was lost (`tools/carry_proof.py`).
- **Proven in a real level** at the SDK pin: the structure generates (ladder, rails, planks, stone
  brick doorway), the ice variant builds from its own palette, and the same Nightly without the
  package refuses the id and writes nothing.
- **Known gaps:** stairs, turns, layered intersections, ore deposits and zombie-villager rooms;
  the terrain-driven surface tunnel; biome decorations; minecarts, chests and furnaces; vanilla
  mineshafts still generate. All in `notes.md`.
