# OpenCards provenance

- Repository: https://github.com/lyuai/opencards
- Commit: `546c8e9f6d010a6638ea568e1e992d9d37e337d6`
- Vendored: 2026-09-17
- License: MIT; see `LICENSE`.
- Role: architecture reference and selective GDScript donor, not the gameplay
  base and not a runtime dependency.

The snapshot under `reference/` contains only the selected architecture files:

- `scripts/core/game_action.gd`, `action_result.gd`, `match_state.gd`,
  `player_state.gd`, `replay_log.gd`, `match_controller.gd`
- `scripts/ai/action_generator.gd`, `ai_match_runner.gd`
- `tests/core/test_replay.gd`
- `tests/ai/test_ai.gd`, `test_ai_matches.gd`

12 Moons adapts concepts into original classes under `scripts/core/` and
`scripts/ai/`. No code imports classes from this reference snapshot. Combat,
HP, energy, block, HQ, credits, lanes, factions, art, and deck-builder systems
were intentionally not copied or adapted.
