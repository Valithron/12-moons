# Third-Party Notices

12 Moons preserves the license and attribution information for every vendored or
adapted source under `third_party/<vendor>/LICENSE`. Files under
`third_party/*/reference/` are development provenance only and are not runtime
dependencies.

## Card Framework

- Repository: https://github.com/chun92/card-framework
- Version: `v1.4.0`
- Exact commit: `a74b713863adb27a22965a8e6ed039d0c4016791`
- License: MIT
- Role: runtime visual/presentation dependency.
- Copied paths: `addons/card-framework/` runtime addon files, excluding
  upstream screenshots and example-project material.
- Provenance: `third_party/card-framework/UPSTREAM.md` and `LICENSE`.

12 Moons-specific rules do not live inside this addon.

## GdUnit4

- Repository: https://github.com/godot-gdunit-labs/gdUnit4
- Version: `v6.2.1`
- Exact commit: `08ffc7c65b61b1b2edd545616061a99973c13ce1`
- License: MIT
- Role: development/test dependency.
- Copied paths: `addons/gdUnit4/plugin.cfg`, `plugin.gd`, `runtest.cmd`,
  `runtest.sh`, `bin/`, and `src/`; upstream `test/` material is excluded.
- Provenance: `third_party/gdunit4/UPSTREAM.md` and `LICENSE`.

## hanafuda-js

- Repository: https://github.com/fudapop/hanafuda-js
- Version: `0.3.0`
- Exact commit: `642110d7deb60e5b941f331816754dfadd2b8f04`
- License: MIT
- Role: reference/data/rules code donor, never a runtime TypeScript
  dependency.
- Copied/adapted reference paths are listed in
  `third_party/hanafuda-js/UPSTREAM.md`.
- Provenance: `third_party/hanafuda-js/UPSTREAM.md` and `LICENSE`.
  
12 Moons is implemented in GDScript. Where upstream behavior conflicts with
the 12 Moons Game Design Authority, 12 Moons rules take precedence.

## OpenCards

- Repository: https://github.com/lyuai/opencards
- Exact commit: `546c8e9f6d010a6638ea568e1e992d9d37e337d6`
- License: MIT
- Role: architecture/code reference and selective donor, never a gameplay
  base or runtime dependency.
- Copied/adapted reference paths are listed in
  `third_party/opencards/UPSTREAM.md`.
- Provenance: `third_party/opencards/UPSTREAM.md` and `LICENSE`.

No OpenCards combat, HP, energy, block, faction, HQ, credit, battlefield, art,
or deck-builder systems are used by 12 Moons.

## Louie Mantia hanafuda card art

- Upstream repository: https://github.com/game-prototypes/hanafuda
- Exact upstream commit: `170082cc3dc928987c04b1abbed6145331f72034`
- Source path: `assets/cards/`
- Copied paths: the manifest-referenced PNG card faces under `assets/cards/`.
  The upstream Godot `.import` files and GPL game code are not vendored.
- Artist: Louie Mantia.
- License: CC BY-SA 4.0.
- Source attribution: the upstream project identifies these images as Louie
  Mantia artwork sourced from Wikimedia/Wikipedia.
- Full provenance and the local license notice are in
  `third_party/louie-mantia-hanafuda/UPSTREAM.md` and `LICENSE`.

The card textures are temporary prototype art. Each stable 12 Moons card ID
maps to one texture through `data/hanafuda/cards.json`.
