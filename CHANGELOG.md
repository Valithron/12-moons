# Changelog

## v0.2.0-prototype.1 — January Playable Month

This milestone turns the deterministic foundation into the first playable 12 Moons
vertical slice:

- First complete January match with a title, January introduction, table, and result screen.
- Three-card starting-player ritual with player-first reveal and earlier revealed month.
- Deterministic 8/8/8 legal dealing with invalid opening-field redeals.
- Complete hanafuda play-and-draw turns, including 0/1/2/3-match resolution and target choices.
- Canonical prototype yaku evaluator with structured score breakdowns and stacking.
- January Wolf Moon: all Chaff points are doubled, “Strength of the Pack.”
- End-of-full-turn Stop/Koi-Koi decisions, seven-plus doubling, and one Koi-Koi multiplier.
- Rudimentary legal AI restricted to its own hand and public information.
- Functional first table UI with real hanafuda face art and a neutral procedural card back.
- Stronger hidden-information boundaries, transactional mutations, and all-48-card conservation invariants.
- Deterministic full-month replay/state-hash integration coverage.

Rewards, shops, carry builds, later Moons, multiplayer, and final presentation remain
out of scope for this prototype.

## v0.1.0-prototype.1 — Open-Source Foundation

The first 12 Moons prototype implementation establishes:

- A Godot 4.7.2 Compatibility-renderer project.
- The pinned Card Framework runtime addon and GdUnit4 development/test addon.
- A native, stable-ID 48-card hanafuda manifest.
- Deterministic state, action, seeded-deck, replay, and state-hash foundations.
- A public/perspective state boundary for hidden-information AI.
- Card Framework presentation adapters that never own gameplay state.
- Automated core validation and third-party provenance notices.

January gameplay, complete yaku scoring, Stop/Koi-Koi UI, and the first playable
vertical slice are intentionally part of the next milestone.
