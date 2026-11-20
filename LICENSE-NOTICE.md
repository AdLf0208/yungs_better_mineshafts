# Licence notice — `bettermineshafts` (YUNG's Better Mineshafts)

This port carries content from **YUNG's Better Mineshafts 5.1.1**
(`YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar`, mod id `bettermineshafts`),
authored by **YUNGNICKYOUNG** (<https://github.com/YUNG-GANG/YUNGs-Better-Mineshafts>).

## What the artefact declares — read from the jar, not from a project page

| Evidence | Value |
|---|---|
| `META-INF/neoforge.mods.toml` → `license` | `LGPLv3` |
| `LICENSE_YungsBetterMineshafts` (archive root, 7,817 B) | the full **GNU Lesser General Public License, Version 3, 29 June 2007** text |
| `[[mods]] authors` | `YUNGNICKYOUNG` |
| Modrinth project `HjmxVlSr` licence field | `LGPL-3.0-only` |
| Upstream repository `LICENSE` (clone at `682a598`, branch `1.21.1`) | the same LGPL-3.0 text |

So the port is **LGPL-3.0-only → licence rank 1 (copyleft)**. Copyleft is
publishable under the same licence with the complete corresponding source; it is
**local-only until the maintainer approves publishing** (ARCHITECTURE.md §8).

## What travels with this port

- `LICENSE` — the jar's own `LICENSE_YungsBetterMineshafts`, byte-identical
  (7,817 B, the LGPL-3.0 text). The delivered `.hmod` carries it too, injected by
  `tools/notice.py` (the content loader ignores a root `LICENSE*`, so a
  downloaded package keeps the notice it is distributed under).
- `LICENSE-NOTICE.md` — this file.
- `notes.md` — provenance (jar name, SHA-1, SHA-256, version), the file
  inventory, and what the port does and does not implement.

The Rust/JSON in this port is a clean-room content carry of the jar's data files
(plus, in a later slice, a rewrite of its generator from its observed
behaviour). No Java source is copied into the package, and the jar itself is
evidence under `ports/_shared/licence-cache/` — never committed, never shipped.

## Obligations that follow from LGPL-3.0

1. Redistribution and modification are permitted under LGPL-3.0; the port and its
   complete corresponding source are published together (repository + package).
2. The original copyright notice and this licence travel with the package.
3. A modified version must state that it is modified and name the changes: this
   port is a **partial** implementation of 5.1.1 for Horizon/Minecraft 26.3, and
   `notes.md` lists exactly which halves are carried and which are not.
4. No warranty: the licence's disclaimer applies unchanged.
