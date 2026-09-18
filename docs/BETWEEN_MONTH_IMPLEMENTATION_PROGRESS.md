# Between-Month Implementation Progress

This ledger is the durable resume point for the long-running January-to-
February milestone goal. Update it after every milestone checkpoint. Do not
replace completed evidence with a summary; append concise validation results.

## Goal

Implement and validate:

`January → settlement → liquidation if required → carry-slot unlock → reward → carry preparation → six-offer shop → finalize → Begin February placeholder`

Preserve January's `GameState`/`MatchController` authority and complete the run
layer, determinism, save/load, presentation, accessibility, testing, and
production infrastructure required by the implementation plan.

## Current repository baseline

- Branch: `main`
- Base commit: `e26a5da112aef4afd5e54e25e741b4cfb3712fba`
- `VERSION`: `0.2.0-prototype.9`
- `project.godot` version: `0.2.0-prototype.9`
- Current implementation: deterministic January month, legal public-information
  AI, yaku/scoring, Stop/Koi-Koi, stable card presentation, motion queue, run
  authority, settlement/liquidation hooks, modifier/carry ownership, reward
  generation, six-slot shop transactions, save/migration, debug scenarios, and
  the initial between-month presentation shell. The player-facing loop remains
  intentionally stopped at unresolved Sterling policy decisions.
- Required validation:
  `scripts/run/validate_project.ps1 -GodotBinary <discovered Godot 4.7.2 binary>`
- Baseline validation status: PASS under available Godot 4.7.1; exact Godot
  4.7.2 remains an environment preflight requirement.
- Authority status: `AGENTS.md` and the canonical Game Design Authority were not
  accessible. The implementation plan and development map are the active
  fallback authority; unresolved decisions remain blockers.

## Milestone table

| ID | Milestone | Status | Started | Completed | Validation | Commit | Blockers | Notes |
|---|---|---|---|---|---|---|---|---|
| BM-00 | Baseline and authority preflight | COMPLETE | 2026-09-18 | 2026-09-18 | PASS (provisional Godot 4.7.1) | working tree | Exact Godot 4.7.2 binary not installed; canonical Game Design Authority unavailable | Stale November asset-path test and clean-checkout import warm-up corrected. |
| BM-01 | RunState and prototype configuration | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Serializable phase/bankroll/capacity/ownership state and invariant checks are present. |
| BM-02 | Run actions, controller, journal, RNG scopes | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Copy-validate-commit, journal hashes, rejected-action hash invariance, and scoped RNG pass. |
| BM-03 | MatchResult bridge and January ingestion | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Terminal-only result extraction and duplicate protection pass; boot now carries the typed result. |
| BM-04 | Settlement, liquidation, bankruptcy | BLOCKED | 2026-09-18 | — | PASS for win/loss/tie and injected quote paths | working tree | BM-B05 | Production resale quote/free-reward policy is intentionally not selected. |
| BM-05 | Modifier definitions, instances, capacity, placement | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 5 targeted cases | working tree | BM-B02/BM-B08 for authored content | Registry, locations, capacities, reserve inactivity, and attachment-index invariants are implemented. |
| BM-06 | Typed modifier seams and content validation | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 3 targeted cases | working tree | Later seams only | Wider Choice is real; future modifier behavior remains seams only. |
| BM-07 | Reward generation and Wider Choice | BLOCKED | 2026-09-18 | — | PASS, 8 targeted cases | working tree | BM-B01/BM-B02/BM-B06 | Both request shapes, configured RunRules generation, and active Wider Choice 3→4 transformation pass; no production policy is silently selected. |
| BM-08 | Reward selection/refusal/acquisition | BLOCKED | 2026-09-18 | — | PASS, 6 targeted cases | working tree | BM-B03/BM-B07 | Once-only selection/refusal and explicit pending acquisition pass; full-capacity acceptance awaits policy. |
| BM-09 | Carry management transactions | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, carry/attachment cases | working tree | BM-B08 for final attachment behavior | Active/reserve movement is authoritative; unresolved Card Upgrade actions reject precisely. |
| BM-10 | Save format v1 and migration | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Checksummed envelope, migration fixture, journal, and phase round-trips pass. |
| BM-11 | Debug scenarios and inspection | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 2 targeted cases | working tree | — | All required fixtures are deterministic and production-invariant-valid. |
| BM-12 | Six-slot ShopState/generation | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, shop generation cases | working tree | BM-B02/BM-B07 for final authored inventory | Six categories persist; unavailable categories remain explicit rather than invented. |
| BM-13 | Shop transactions | BLOCKED | 2026-09-18 | — | PASS under injected resale policy, 5 targeted cases | working tree | BM-B04/BM-B05 | Buy/reroll/sale/finalize actions exist; production full-storage and resale policies await approval. |
| BM-14 | Presentation and January UX foundation | IN PROGRESS | 2026-09-18 | — | PASS, 3 presentation cases plus 8 card-motion cases | working tree | — | Motion profile, cancellation hooks, focusable cards, semantic audio hooks, and decision tray are present; full visual acceptance remains. |
| BM-15 | Preparation shell, settlement/reward/carry UI | IN PROGRESS | 2026-09-18 | — | PASS, 6 between-month UI cases | working tree | BM-B03 | Shared shell renders causal score/debt summaries, configured reward generation, carry movement controls, six-slot shop entry, and policy blockers. |
| BM-16 | Shop/finalization UI | IN PROGRESS | 2026-09-18 | — | Targeted domain/UI coverage only | working tree | BM-B04/BM-B05 | Shop grid and finalization controls are wired; full acceptance remains blocked by policy. |
| BM-17 | February transition placeholder | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, month-boundary and profile cases | working tree | — | `BEGIN_FEBRUARY` reaches explicit Snow Moon placeholder without February rules. |
| BM-18 | Final hardening and release gate | BLOCKED | 2026-09-18 | — | Partial: 2 integration cases plus 103/103 full suite | working tree | All current blockers plus Godot 4.7.2 preflight and visual inspection | Authoritative configured win/liquidation loops converge to February; production-policy and final visual/renderer acceptance remain unclaimable. |

## Design blocker register

| ID | Decision | Status | Required before |
|---|---|---|---|
| BM-B01 | Whole-pool versus one-per-family rewards | UNRESOLVED / BLOCKING NOW | BM-07 acceptance |
| BM-B02 | Duplicate modifier policy | UNRESOLVED / BLOCKING NOW | BM-05/BM-07 authored content |
| BM-B03 | Full active+reserve selected reward | UNRESOLVED / BLOCKING NOW | BM-08 full-capacity flow |
| BM-B04 | Full-storage shop purchase | UNRESOLVED / BLOCKING NOW | BM-13 full-capacity flow |
| BM-B05 | Resale formula and free reward eligibility | UNRESOLVED / BLOCKING NOW | BM-04/BM-13 |
| BM-B06 | Wider Choice fourth slot under family quotas | UNRESOLVED / BLOCKING LATER | BM-07 if quotas selected |
| BM-B07 | Card Upgrade target fixed/player-selected | UNRESOLVED / BLOCKING LATER | Card Upgrade content |
| BM-B08 | Multiple upgrades on one physical card | UNRESOLVED / BLOCKING LATER | Attachment content |
| BM-B09 | Mulligan return/shuffle | UNRESOLVED / BLOCKING LATER | Mulligan behavior |
| BM-B10 | Second Draw one/zero-card behavior | UNRESOLVED / BLOCKING LATER | Second Draw behavior |
| BM-B11 | Replacement conflicts | UNRESOLVED / BLOCKING LATER | Quad Koi behavior |
| BM-B12 | Voluntary bankruptcy | NON-BLOCKING FOR THIS MILESTONE | Future liquidation UX |

## Decisions made during implementation

Record reversible engineering choices here, such as file placement, schema
version increments, test fixture names, or presentation token values. Do not
record new gameplay canon here; use the blocker register and approved authority.

- Run state uses canonical sorted arrays for hashes while raw dictionaries remain in `to_dict()` so transaction cloning preserves keyed ownership data.
- Liquidation and sale pricing are injected `Callable` policies; absent policy produces BM-B05 instead of a guessed economic rule.
- Shop slots persist unavailable offers when the current registry has no approved content for a category; no placeholder gameplay modifier was invented.
- Debug scenarios construct valid states, but all subsequent changes still go through `RunController.submit_action()`.
- The January result payload preserves the existing terminal-result shape and adds a typed `match_result` bridge for the between-month screen.
- RunRules persists empty reward/duplicate-policy fields until Sterling approves
  the canon; controller and UI consume configured policies without selecting a
  default. Active Wider Choice is derived only from an active owned instance
  (or explicit test/configuration input), so reserve placement cannot affect
  reward count.
- End-to-end integration fixtures inject approved test policies explicitly: the
  production run remains policy-neutral, while win and liquidation paths prove
  authoritative action progression through the February placeholder and replay
  hash convergence.

## Validation log

Append-only entries in the format:

`YYYY-MM-DD — [milestone/full] — command — PASS/FAIL — concise evidence — commit`

- 2026-09-18 — BM-00 version preflight — `VERSION`/boot/project surfaces reconciled to `0.2.0-prototype.9` — PASS — Godot 4.7.2 still unavailable; Godot 4.7.1 is available for provisional checks — working tree
- 2026-09-18 — BM-00 baseline validation — `scripts/run/validate_project.ps1` — PASS (provisional Godot 4.7.1) — manifest/core smoke, runtime UI flow, and 50/50 GdUnit4 cases passed; importer warm-up uses 600 frames — working tree
- 2026-09-18 — BM-01–BM-09 domain checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/run --ignoreHeadlessMode` — PASS — 39/39 run-domain cases covering state, bridge, settlement, modifiers, seams, rewards, save/migration, scenarios, and shop transactions — working tree
- 2026-09-18 — BM-14 presentation checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_between_month_presentation.gd --ignoreHeadlessMode` — PASS — 3/3 speed/reduced-motion/profile cases — working tree
- 2026-09-18 — BM-15 UI checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_between_month_ui.gd --ignoreHeadlessMode` — PASS — 3/3 settlement/blocker-observation/carry-focus cases — working tree
- 2026-09-18 — BM-14 cancellation checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_card_motion.gd --ignoreHeadlessMode` — PASS — 8/8 card-motion, queue-cancellation, finalizer, focus-lock, and reduced-motion cases — working tree
- 2026-09-18 — BM-10 replay checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/run/test_save.gd --ignoreHeadlessMode` plus `test_debug_scenarios.gd` — PASS — save journal replays to the same final hash and all 11 debug scenarios remain deterministic/invariant-valid — working tree
- 2026-09-18 — full-suite replay checkpoint — `scripts/run/validate_project.ps1 -GodotBinary <Godot 4.7.1 console>` — PASS (provisional Godot 4.7.1) — January/core smoke, runtime UI flow, and 96/96 GdUnit4 cases across 20 suites after replay integration — working tree
- 2026-09-18 — full-suite checkpoint — `scripts/run/validate_project.ps1 -GodotBinary <Godot 4.7.1 console>` — PASS (provisional Godot 4.7.1) — January/core smoke, runtime UI flow, and 96/96 GdUnit4 cases across 20 suites — working tree
- 2026-09-18 — BM-07 policy-config checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/run/test_rewards.gd --ignoreHeadlessMode` — PASS — 8/8 reward cases, including configured RunRules generation, active Wider Choice, and empty-payload shop-policy derivation — working tree
- 2026-09-18 — BM-15 configured UI checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_between_month_ui.gd --ignoreHeadlessMode` — PASS — 5/5 settlement/blocker/reward-generation/shop-entry/carry-focus cases — working tree
- 2026-09-18 — BM-15 causal UI checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_between_month_ui.gd --ignoreHeadlessMode` — PASS — 6/6 score/debt-summary, blocker, reward-generation, shop-entry, and carry-focus cases — working tree
- 2026-09-18 — BM-18 integration checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_between_month_run_loop.gd --ignoreHeadlessMode` — PASS — 2/2 configured win and injected-liquidation paths reach the February placeholder and replay to the same final hash — working tree
- 2026-09-18 — full-suite checkpoint — `scripts/run/validate_project.ps1 -GodotBinary <Godot 4.7.1 console>` — PASS (provisional Godot 4.7.1) — January/core smoke, runtime UI flow, and 103/103 GdUnit4 cases across 21 suites — working tree

## Known deferred work

- February gameplay and later Moon rules.
- Full modifier catalogue and unresolved modifier behavior.
- Multiplayer, networking, cloud saves, and production telemetry.
- Generic ability/event frameworks, ECS, database, generic inventory, or second
  rules engine.
- Touch-specific layout, 3D/rigid-body cards, full-screen post-processing,
  large shader/VFX libraries, adaptive music, complex haptics, and bespoke
  seasonal boards.

## Final Definition of Done

- The complete January-to-February loop reaches the exact `Begin February`
  placeholder through authoritative actions.
- January remains authoritative through `GameState` and `MatchController`.
- Run state, settlement, liquidation, carry, rewards, shop, and finalization are
  deterministic, serializable, replayable, and hash-safe on rejection.
- Reward/shop offers persist, RNG scopes are isolated, and Wider Choice is a
  request transformation.
- Modifier placement is unique, reserve is inactive, and physical 48-card
  conservation remains true.
- Save/reload continuation matches uninterrupted continuation at every
  between-month phase.
- Debug fixtures, content validation, AI privacy, focus paths, reduced motion,
  speed modes, cancellation, and presentation convergence are verified.
- Compatibility-renderer profiling and 720p/higher-resolution inspection pass.
- Full repository validation passes with the discovered Godot 4.7.2 binary.
- All current design blockers are resolved or the milestone is explicitly
  stopped with the blocker recorded; no unresolved rule is invented.
