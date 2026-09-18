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
- Current synchronized policy baseline commit: `7083487fb7d72a7ff39fd5d3fb2a83a9f4fe724b`
- `VERSION`: `0.2.0-prototype.11`
- `project.godot` version: `0.2.0-prototype.11`
- Current implementation: deterministic January month, legal public-information
  AI, yaku/scoring, Stop/Koi-Koi, stable card presentation, motion queue, run
  authority, settlement/liquidation hooks, modifier/carry ownership, reward
  generation, six-slot shop transactions, save/migration, debug scenarios, and
  the initial between-month presentation shell. The former BM-B01 through BM-B05 policy blockers are now approved and BM-B06 is not applicable; the remaining work is to wire those approved defaults into production paths, revalidate, and finish exact-engine/native visual acceptance.
- Required validation:
  `scripts/run/validate_project.ps1 -GodotBinary <discovered Godot 4.7.2 binary>`
- Baseline validation status: PASS under available Godot 4.7.1; exact Godot
  4.7.2 remains an environment preflight requirement.
- Authority status: root `AGENTS.md` is present on merged `main`. The canonical Game Design Authority was consulted externally on 2026-09-18 and BM-B01 through BM-B05 were explicitly approved; BM-B06 is no longer applicable because full-pool rewards were chosen. A Codex runtime that cannot access the external authority must treat these recorded approved rules as authoritative for this milestone.

## Milestone table

| ID | Milestone | Status | Started | Completed | Validation | Commit | Blockers | Notes |
|---|---|---|---|---|---|---|---|---|
| BM-00 | Baseline and authority preflight | COMPLETE | 2026-09-18 | 2026-09-18 | PASS (provisional Godot 4.7.1) | historical worktree, now merged | Exact Godot 4.7.2 binary not installed | Root `AGENTS.md` is present and the approved canonical Game Design Authority decisions are synchronized into the repo; stale November asset-path test and clean-checkout import warm-up were corrected. |
| BM-01 | RunState and prototype configuration | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Serializable phase/bankroll/capacity/ownership state and invariant checks are present. |
| BM-02 | Run actions, controller, journal, RNG scopes | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Copy-validate-commit, journal hashes, rejected-action hash invariance, and scoped RNG pass. |
| BM-03 | MatchResult bridge and January ingestion | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Terminal-only result extraction and duplicate protection pass; boot now carries the typed result. |
| BM-04 | Settlement, liquidation, bankruptcy | IN PROGRESS | 2026-09-18 | — | PASS for win/loss/tie and injected quote paths | merged main | — | Resale policy is now approved; production wiring and revalidation remain. |
| BM-05 | Modifier definitions, instances, capacity, placement | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 5 targeted cases | merged main | BM-B08 for later authored multi-upgrade behavior | Registry, locations, capacities, reserve inactivity, and attachment-index invariants are implemented; duplicate-definition policy is now approved. |
| BM-06 | Typed modifier seams and content validation | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 3 targeted cases | working tree | Later seams only | Wider Choice is real; future modifier behavior remains seams only. |
| BM-07 | Reward generation and Wider Choice | IN PROGRESS | 2026-09-18 | — | PASS, 8 targeted cases before policy lock | merged main | — | Full-pool 3-offer policy and Wider Choice 4-offer rule are approved; production configuration and revalidation remain. |
| BM-08 | Reward selection/refusal/acquisition | IN PROGRESS | 2026-09-18 | — | PASS, 6 targeted cases before policy lock | merged main | BM-B07 only if real Card Upgrade targeting is introduced | Full-capacity reward replacement/refusal policy is approved; implementation and revalidation remain. |
| BM-09 | Carry management transactions | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, carry/attachment cases | working tree | BM-B08 for final attachment behavior | Active/reserve movement is authoritative; unresolved Card Upgrade actions reject precisely. |
| BM-10 | Save format v1 and migration | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | working tree | — | Checksummed envelope, migration fixture, journal, and phase round-trips pass. |
| BM-11 | Debug scenarios and inspection | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 2 targeted cases | working tree | — | All required fixtures are deterministic and production-invariant-valid. |
| BM-12 | Six-slot ShopState/generation | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, shop generation cases | working tree | BM-B02/BM-B07 for final authored inventory | Six categories persist; unavailable categories remain explicit rather than invented. |
| BM-13 | Shop transactions | IN PROGRESS | 2026-09-18 | — | PASS under injected policy before lock, 5 targeted cases | merged main | — | Full-storage purchase blocking and resale formulas are approved; production wiring and revalidation remain. |
| BM-14 | Presentation and January UX foundation | IN PROGRESS | 2026-09-18 | — | PASS, 3 presentation cases plus 8 card-motion cases | working tree | — | Motion profile, cancellation hooks, focusable cards, semantic audio hooks, and decision tray are present; full visual acceptance remains. |
| BM-15 | Preparation shell, settlement/reward/carry UI | IN PROGRESS | 2026-09-18 | — | PASS, 6 between-month UI cases before policy lock | merged main | — | Shared shell exists; approved full-capacity replacement flow must now replace the temporary policy-blocker presentation and be visually validated. |
| BM-16 | Shop/finalization UI | IN PROGRESS | 2026-09-18 | — | Targeted domain/UI coverage only | merged main | — | Shop grid/finalization controls are wired; approved capacity/resale policies must be surfaced and validated. |
| BM-17 | February transition placeholder | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, month-boundary and profile cases | working tree | — | `BEGIN_FEBRUARY` reaches explicit Snow Moon placeholder without February rules. |
| BM-18 | Final hardening and release gate | IN PROGRESS | 2026-09-18 | — | Partial: 2 integration cases plus 103/103 full suite under Godot 4.7.1 | merged main | Godot 4.7.2 preflight and native visual inspection | Design-policy blockers are resolved. Approved policies must be wired/revalidated, then exact-engine and visual/renderer acceptance remain. |

## Design blocker register

| ID | Decision | Status | Required before |
|---|---|---|---|
| BM-B01 | Full-pool versus one-per-family rewards | RESOLVED: full eligible pool, 3 offers | BM-07 production wiring |
| BM-B02 | Duplicate modifier policy | RESOLVED: no duplicate Hand/Strategic definitions by default; Card Upgrade type may recur only on different physical cards unless explicitly stackable | content validation |
| BM-B03 | Full active+reserve selected reward | RESOLVED: replace-and-sell one owned modifier or refuse for +2; no overflow inventory | BM-08/BM-15 production flow |
| BM-B04 | Full-storage shop purchase | RESOLVED: block purchase until legal space exists; no automatic replacement/pending-purchase inventory | BM-13/BM-16 production flow |
| BM-B05 | Resale/free reward eligibility | RESOLVED: purchased = 50% actual purchase price floor; free reward = 50% base shop value floor | BM-04/BM-13 production wiring |
| BM-B06 | Wider Choice fourth slot under family quotas | RESOLVED / N/A: full-pool policy; Wider Choice changes 3 offers to 4 | BM-07 production wiring |
| BM-B07 | Card Upgrade target fixed/player-selected | UNRESOLVED / BLOCKING LATER | authored Card Upgrade content |
| BM-B08 | Multiple different upgrades on one physical card | UNRESOLVED / BLOCKING LATER | attachment content |
| BM-B09 | Mulligan return/shuffle | UNRESOLVED / BLOCKING LATER | Mulligan behavior |
| BM-B10 | Second Draw one/zero-card behavior | UNRESOLVED / BLOCKING LATER | Second Draw behavior |
| BM-B11 | Replacement conflicts | UNRESOLVED / BLOCKING LATER | Quad Koi/conflicting replacement behavior |
| BM-B12 | Voluntary bankruptcy | NON-BLOCKING FOR THIS MILESTONE | future liquidation UX |

## Decisions made during implementation

Record reversible engineering choices here, such as file placement, schema
version increments, test fixture names, or presentation token values. Do not
record new gameplay canon here; use the blocker register and approved authority.

Approved gameplay canon is recorded here only as a synchronization note; the canonical source remains the Game Design Authority.

- 2026-09-18 policy lock: monthly free rewards are 3 offers from the full eligible modifier pool; Wider Choice changes the count to 4 without family quotas.
- 2026-09-18 policy lock: duplicate Hand/Mechanic and Strategic/Meta modifier definitions are disallowed by default unless explicitly stackable; Card Upgrade types may recur on different physical cards but not duplicate on the same card unless explicitly allowed.
- 2026-09-18 policy lock: with full active+reserve storage, a selected free reward requires replacing and selling one owned modifier at normal resale value, or the player may refuse for +2; no overflow inventory.
- 2026-09-18 policy lock: a shop purchase at full storage is blocked until the player creates legal space; there is no automatic replacement or pending-purchase inventory.
- 2026-09-18 policy lock: purchased modifiers resell for 50% of actual purchase price rounded down; free rewards resell for 50% of normal base shop value rounded down.
- Run state uses canonical sorted arrays for hashes while raw dictionaries remain in `to_dict()` so transaction cloning preserves keyed ownership data.
- Pre-approval liquidation and sale pricing used injected `Callable` policies. Continuation work must make the approved resale formulas the production defaults while retaining deterministic testability.
- Shop slots persist unavailable offers when the current registry has no approved content for a category; no placeholder gameplay modifier was invented.
- Debug scenarios construct valid states, but all subsequent changes still go through `RunController.submit_action()`.
- The January result payload preserves the existing terminal-result shape and adds a typed `match_result` bridge for the between-month screen.
- The pre-approval RunRules path persisted empty reward/duplicate-policy fields. Continuation work must replace those empty production defaults with the approved full-pool and duplicate rules while preserving configuration/fixture injection for tests. Active Wider Choice remains derived only from an active owned instance so reserve placement cannot affect reward count.
- End-to-end integration fixtures previously injected temporary test policies. Continuation work must prove the same win/liquidation paths using the approved production defaults, while preserving replay hash convergence.

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
