# hanafuda-js provenance

- Repository: https://github.com/fudapop/hanafuda-js
- Version: `0.3.0`
- Commit: `642110d7deb60e5b941f331816754dfadd2b8f04`
- Vendored: 2026-09-17
- License: MIT; see `LICENSE`.
- Role: reference material and selective data/rules donor, not runtime code.

The snapshot under `reference/` contains these exact upstream files:

- `src/core/cards.ts`, `collection.ts`, `deck.ts`, `matching.ts`, `types.ts`
- `src/koikoi/game.ts`, `setup.ts`, `state.ts`
- `src/scoring/rules/animal.ts`, `bright.ts`, `chaff.ts`, `month.ts`,
  `ribbon.ts`, `viewing.ts`
- `tests/core/cards.test.ts`, `deck.test.ts`, `matching.test.ts`
- `tests/scoring/manager.test.ts`

12 Moons is implemented in original GDScript. 12 Moons rules override any
conflicting hanafuda-js behavior, including values, timing, opening rules,
viewing rules, and special-card treatment.
