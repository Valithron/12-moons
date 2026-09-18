# Changelog

## v0.2.0-prototype.5 — January Table Stabilization

- Correct the standard 48-card manifest's November Willow red-ribbon card and vendor its distinct Tanzaku face art.
- Add manifest checks for 48 unique cards, twelve four-card months, valid classes, complete art assets, and unintended duplicate art mappings.
- Replace the 960 × 540 positional table with a 1280 × 720 named-region layout for hands, captures, field, draw/resolution, scores, status, and modal decisions.
- Keep capture groups readable, separate the draw pile from the revealed resolution card, and make selectable/hovered cards visually explicit.
- Slow house turns with short presentation pauses and describe played, captured, drawn, Stop, and Koi-Koi actions in the table status.
- Expand the title, January intro, and result screens to the shared 16:9 virtual surface.
- Add baseline table-region layout coverage alongside the existing full January UI-flow validation.

## v0.2.0-prototype.4 — Starter Card Input Fix

- Stop the empty full-screen UI layers from intercepting clicks on playable cards.
- Validate that each player action reaches a rendered selectable card and its `Button.pressed` signal.
- January gameplay rules are unchanged.

## v0.2.0-prototype.3 — Godot 4.7.2 Runtime Stability

- Defer UI screen teardown so title, January intro, match, and result transitions do not free a locked signal-emitting node.
- Fix Godot 4.7.2 parser/type-inference errors in the match capture-group renderer and test suites.
- Normalize `project.godot` to the Godot 4.7 configuration format.
- Add a headless end-to-end UI-flow validation covering title, intro, January, and result screens.
- January gameplay rules are unchanged.

## v0.2.0-prototype.2 — Godot 4.7 Launch Fix

- Fix Godot 4.7.2 parser/type-inference errors in `boot.gd` when dynamically instantiated scenes are assigned with inferred `:=` declarations.
- January gameplay rules and behavior are unchanged.

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
