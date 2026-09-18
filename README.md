# 12 Moons

12 Moons is a deterministic hanafuda roguelike built in GDScript. The first
playable prototype is a complete January month against a rudimentary legal AI,
using the standard 48-card deck and recognizable Koi-Koi matching.

## Development

- Engine: Godot 4.7.2 stable, Compatibility renderer.
- Version: the canonical version is stored in `VERSION` and mirrored in
  `project.godot`.
- Run: open this directory in Godot and press Play. Choose **Start January**,
  read the Wolf Moon introduction, select a starter card, and play through the
  month on the table.
- Test: run `scripts/run/validate_project.ps1 -GodotBinary <path-to-godot>`.
  The script validates the manifest, runs the headless title-to-result UI flow,
  and then invokes the vendored GdUnit4 runner for `tests/`.

## January prototype

The January slice includes:

- A three-card starting-player ceremony with unique months.
- Deterministic 8/8/8 dealing with invalid opening-field redeals.
- Full hand-play plus draw turns with 0/1/2/3-match resolution.
- Canonical prototype yaku, Wolf Moon Chaff doubling, and settlement multipliers.
- End-of-full-turn Stop/Koi-Koi decisions.
- A legal public-information AI and a functional card table.
- Licensed Louie Mantia hanafuda face art mapped to all 48 stable card IDs.
- Deterministic replay and state-hash validation with strict card conservation.

Rewards, shops, carry builds, later Moons, multiplayer, and final presentation
remain outside this prototype milestone.

## Architecture

Authoritative gameplay state contains stable card IDs and deterministic data.
`MatchController` is the single mutation gateway; `ActionGenerator` supplies
legal actions; `ReplayLog` records deterministic action sequences; and
`PublicStateView` hides private hands and unrevealed deck order from AI. The
Card Framework addon remains a presentation adapter only.

The canonical card data lives at `data/hanafuda/cards.json`. Third-party source
provenance and license notices are documented in `THIRD_PARTY_NOTICES.md`.
