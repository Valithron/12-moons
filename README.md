# 12 Moons

12 Moons is a deterministic hanafuda game foundation built in GDScript. This
repository is the open-source foundation prototype, not the first complete
January gameplay milestone.

## Development

- Engine: Godot 4.7.2 stable, Compatibility renderer.
- Version: the canonical version is stored in `VERSION` and mirrored in
  `project.godot`.
- Run: open this directory in Godot and press Play. The launch scene is a
  deliberately small boot check.
- Test: run `scripts/run/validate_project.ps1 -GodotBinary <path-to-godot>`.
  The script validates the manifest and then invokes the vendored GdUnit4
  runner for `tests/`.

## Architecture

Authoritative gameplay state contains stable card IDs and deterministic data.
`MatchController` is the single mutation gateway; `ActionGenerator` supplies
legal actions; `ReplayLog` records deterministic action sequences; and
`PublicStateView` hides private hands and unrevealed deck order from AI. The
Card Framework addon is used only through `scripts/ui/` presentation adapters.

The canonical card data lives at `data/hanafuda/cards.json`. Pinned source
provenance and full MIT notices are documented in `THIRD_PARTY_NOTICES.md`.
