# YUNG's Better Mineshafts — a Horizon port

**YUNG's Better Mineshafts** is a Minecraft mod. A long-awaited and much-needed Minecraft abandoned mineshaft overhaul!. This repository is a **port of it to [Horizon](https://github.com/horizon-rust/horizon)**, the Rust engine for Minecraft Java 26.3. It carries the complete source of the port plus the content files it ships, and installs as a single `.hmod` package.

Upstream: [YUNG-GANG/YUNGs-Better-Mineshafts](https://github.com/YUNG-GANG/YUNGs-Better-Mineshafts) — licence **LGPL-3.0-only**.

| | |
|---|---|
| Upstream mod | YUNG's Better Mineshafts ([source](https://github.com/YUNG-GANG/YUNGs-Better-Mineshafts)) |
| Ported to | Horizon 0b14f8a, Minecraft Java 26.3, mod API `0.2` |
| Package | `bettermineshafts.hmod` (install it with the Horizon launcher) |
| Licence | **LGPL-3.0-only** — the upstream mod's licence; see [Licence and credit](#licence-and-credit) |

## What this port implements

- **stairs, turns, layered intersections 4/5, ore deposits, zombie-villager rooms, side-room
- **the terrain-driven surface tunnel** (`VerticalEntrance.determineDirection`, `:300-361`) — it
- **biome decorations** (`snow`, `cactus`, `dead bush`, `mushroom`, `lush`, `dripstone`) — upstream
- **minecarts, chests, furnaces, barrels** — they need entity/block-entity payloads whose exact NBT
- **loot/torch on branch walls**: the torch placement is implemented as supports and cobwebs only;
- **The in-game leg passes — what it does *not* yet cover.** The three legs are green (below), but
- **Biome decorations:** `addBiomeDecorations` (`BetterMineshaftPiece.java:175-240`) places
- **Corridor legs (`edge`/`inner`):** `BigTunnel.generateLegsVariant1/2` (`BigTunnel.java:253-369`)

## Not yet ported

- **The in-game leg passes — what it does *not* yet cover.** The three legs are green (below), but
- **Biome decorations:** `addBiomeDecorations` (`BetterMineshaftPiece.java:175-240`) places
- **Corridor legs (`edge`/`inner`):** `BigTunnel.generateLegsVariant1/2` (`BigTunnel.java:253-369`)
- **Surface tunnel:** `VerticalEntrance.determineDirection` (`VerticalEntrance.java:300-361`)
- **Six piece kinds:** stairs, turns, layered intersections 4/5, ore deposits, zombie-villager
- **Minecarts, chests, furnaces, barrels:** not attempted in this slice. `PieceContext::entity` and
- **A palette block outside `REQUESTED_BLOCKS`:** `Registrar::block_key`
- **The config's NBT shape: measured in game, and read tolerantly.** `GenerationContext::config()`

## Installing

1. Install the [Horizon launcher](https://github.com/horizon-rust/horizon/releases) (0.2.70 or newer).
2. Add `bettermineshafts.hmod` to the instance's mods.
3. The package is pinned to a specific Horizon build; the launcher checks that pin.

## Licence and credit

YUNG's Better Mineshafts was created by its upstream authors; the code, models and assets in the original mod
remain theirs and are used here under **LGPL-3.0-only**. The Rust in this repository is a clean-room
rewrite for Horizon, not a translation of the original source.

- `LICENSE` — the upstream licence text.
- `LICENSE-NOTICE.md` — what this port carries and where it came from.
- The upstream project: https://github.com/YUNG-GANG/YUNGs-Better-Mineshafts

## Technical details

```
horizon-mod.toml   package manifest (id, version, api, [native] pin)
Cargo.toml         the crate; depends on `horizon-mod-api` from the fetched SDK
src/               lib.rs (the one `impl Hooks`), runtime.rs (pure logic + tests), glue
assets/ data/      the content the package ships
tools/             content generators and the e2e scenario
```

- Build: `cargo horizon-mod build` (packages; it does not compile against the game).
- Test: `cargo test`, `cargo clippy --all-targets -- -D warnings`.
- In-game: `ports/tools/launcher-game.sh run bettermineshafts` in the campaign tree, or install the
  `.hmod` and play; the harness scenario is `tools/e2e.sh`.

This repository is generated from the campaign's port at `ports/bettermineshafts/`; the port's own
`notes.md` is the full record (decisions, traps, evidence).
