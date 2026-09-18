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
- Starting synchronized policy baseline commit: `7a4f9436cf749b54d43363a9098c26089c06d712`
- Current committed implementation checkpoint: `851ae10`
- `VERSION`: `0.2.0-prototype.11`
- `project.godot` version: `0.2.0-prototype.11`
- Current implementation: deterministic January month, legal public-information
  AI, yaku/scoring, Stop/Koi-Koi, stable card presentation, motion queue, run
  authority, settlement/liquidation hooks, modifier/carry ownership, reward
  generation, six-slot shop transactions, save/migration, debug scenarios, and
  the initial between-month presentation shell. BM-B01 through BM-B05 are now
  wired as production defaults and BM-B06 is not applicable. Remaining
  acceptance work is exact-engine/native visual validation plus authored
  eligible reward content; no unresolved modifier seam is being activated.
- Required validation:
  `scripts/run/validate_project.ps1 -GodotBinary <discovered Godot 4.7.2 binary>`
- Baseline validation status: PASS under available Godot 4.7.1; exact Godot
  4.7.2 remains an environment preflight requirement.
- Authority status: root `AGENTS.md` is present on merged `main`. The continuation objective and merged repository authority notes record BM-B01 through BM-B05 as approved; BM-B06 is no longer applicable because full-pool rewards were chosen. The authenticated canonical **12 Moons — Game Design Authority** was read during the 2026-09-18 continuation audit. It confirms the approved full-pool reward/carry/shop/resale rules and the approved modifier catalogue; unresolved execution details remain recorded in the blocker register and no additional rule is inferred.

## Current acceptance blockers

- `ENV-BM-01` — no Godot 4.7.2 executable is available in the discovered
  environment; the full suite is currently provisional under Godot 4.7.1.
- `UX-BM-01` — native CUA inspection did not expose an interactive Godot/native
  surface, so visual acceptance remains a human/environment check.
- `CONTENT-BM-01` — RESOLVED by the validated addition of the two canonical
  non-seam service definitions (`salvage` and `rain_check`). The production
  registry now contains three eligible definitions and fresh whole-pool reward
  generation produces three persisted offers without promoting seam entries.

## Milestone table

| ID | Milestone | Status | Started | Completed | Validation | Commit | Blockers | Notes |
|---|---|---|---|---|---|---|---|---|
| BM-00 | Baseline and authority preflight | COMPLETE | 2026-09-18 | 2026-09-18 | PASS (provisional Godot 4.7.1) | historical worktree, now merged | Exact Godot 4.7.2 binary not installed | Root `AGENTS.md` is present and the approved canonical Game Design Authority decisions are synchronized into the repo; stale November asset-path test and clean-checkout import warm-up were corrected. |
| BM-01 | RunState and prototype configuration | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | 317d11b | — | Serializable phase/bankroll/capacity/ownership state and invariant checks are present. |
| BM-02 | Run actions, controller, journal, RNG scopes | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | 317d11b | — | Copy-validate-commit, journal hashes, rejected-action hash invariance, and scoped RNG pass. |
| BM-03 | MatchResult bridge and January ingestion | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | 317d11b | — | Terminal-only result extraction and duplicate protection pass; boot now carries the typed result. |
| BM-04 | Settlement, liquidation, bankruptcy | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, settlement/liquidation/bankruptcy and authoritative resale cases | 317d11b | ENV-BM-01 for final release gate | Shared `ModifierResalePolicy` now drives emergency liquidation and exact-zero/debt outcomes without injected production quotes. |
| BM-05 | Modifier definitions, instances, capacity, placement | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 5 targeted cases | merged main | BM-B08 for later authored multi-upgrade behavior | Registry, locations, capacities, reserve inactivity, and attachment-index invariants are implemented; duplicate-definition policy is now approved. |
| BM-06 | Typed modifier seams and content validation | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 3 targeted cases | 317d11b | Later seams only | Wider Choice is real; future modifier behavior remains seams only. |
| BM-07 | Reward generation and Wider Choice | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, reward/seam/shop suites and full suite 116/116 under Godot 4.7.1 | pending checkpoint commit | ENV-BM-01 | Approved defaults, full-pool 3 offers, Wider Choice 4 offers, exclusion, persistence, deterministic generation, and three canonical non-seam definitions are wired. |
| BM-08 | Reward selection/refusal/acquisition | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, pending replacement/refusal, atomic rejection, save/replay cases | 317d11b | BM-B07 only if real Card Upgrade targeting is introduced | Full-capacity reward replacement sells through the shared resale authority, or refusal grants +2; no overflow inventory exists. |
| BM-09 | Carry management transactions | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, carry/attachment cases | 317d11b | BM-B08 for later multi-type attachment policy | Active/reserve movement and one-instance/one-physical-card attachment are authoritative; later different-type stacking remains a seam. |
| BM-10 | Save format v1 and migration | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 4 targeted cases | 317d11b | — | Checksummed envelope, migration fixture, journal, and phase round-trips pass. |
| BM-11 | Debug scenarios and inspection | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, 2 targeted cases | 317d11b | — | All required fixtures are deterministic and production-invariant-valid. |
| BM-12 | Six-slot ShopState/generation | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, shop generation cases | 317d11b | BM-B02/BM-B07 for final authored inventory | Six categories persist; unavailable categories remain explicit rather than invented. |
| BM-13 | Shop transactions | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, atomic full-storage rejection, purchase-price/free-reward resale, reroll, Salvage, and Rain Check cases | pending checkpoint commit | ENV-BM-01 for final release gate | Full storage blocks purchase without consuming currency/offer; sale and Salvage use explicit shared economy rules; preserved offers persist and return in the next generated month slot. |
| BM-14 | Presentation and January UX foundation | IN PROGRESS | 2026-09-18 | — | PASS, 3 presentation cases plus 9 card-motion cases | 851ae10 | — | Motion profile, cancellation hooks, focusable cards, semantic audio hooks, and decision tray are present; all tested motion modes converge on the same card state; full visual acceptance remains. |
| BM-15 | Preparation shell, settlement/reward/carry UI | IN PROGRESS | 2026-09-18 | — | PASS, 8/8 between-month UI cases under Godot 4.7.1 | pending checkpoint commit | UX-BM-01 | Shared shell presents authoritative liquidation, replacement/refusal, Salvage, and carry actions; native visual acceptance remains. |
| BM-16 | Shop/finalization UI | IN PROGRESS | 2026-09-18 | — | PASS, 8/8 between-month UI cases under Godot 4.7.1 | pending checkpoint commit | UX-BM-01 | Six category slots, sale, buy rejection, reroll, Rain Check preservation, and finalization controls are wired; unavailable content stays explicit. |
| BM-17 | February transition placeholder | COMPLETE | 2026-09-18 | 2026-09-18 | PASS, month-boundary and profile cases | 317d11b | — | `BEGIN_FEBRUARY` reaches explicit Snow Moon placeholder without February rules. |
| BM-18 | Final hardening and release gate | IN PROGRESS | 2026-09-18 | — | PASS, 116/116 across 21 suites plus full validator under Godot 4.7.1 | pending checkpoint commit | ENV-BM-01, UX-BM-01 | Approved policy implementation and authored minimum reward content are green under the available engine; exact-engine and native visual acceptance remain. |

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

Approved gameplay canon is recorded here only as a synchronization note from the continuation objective, merged repository authority notes, and the canonical Game Design Authority read on 2026-09-18. This repository remains an implementation record, not a replacement design-authority document.

- 2026-09-18 policy lock: monthly free rewards are 3 offers from the full eligible modifier pool; Wider Choice changes the count to 4 without family quotas.
- 2026-09-18 policy lock: duplicate Hand/Mechanic and Strategic/Meta modifier definitions are disallowed by default unless explicitly stackable; Card Upgrade types may recur on different physical cards but not duplicate on the same card unless explicitly allowed.
- 2026-09-18 policy lock: with full active+reserve storage, a selected free reward requires replacing and selling one owned modifier at normal resale value, or the player may refuse for +2; no overflow inventory.
- 2026-09-18 policy lock: a shop purchase at full storage is blocked until the player creates legal space; there is no automatic replacement or pending-purchase inventory.
- 2026-09-18 policy lock: purchased modifiers resell for 50% of actual purchase price rounded down; free rewards resell for 50% of normal base shop value rounded down.
- Run state uses canonical sorted arrays for hashes while raw dictionaries remain in `to_dict()` so transaction cloning preserves keyed ownership data.
- Resale pricing now lives in `ModifierResalePolicy`; test fixtures may still construct explicit instance economics, but normal production actions do not require an injected quote provider.
- Shop slots persist unavailable offers when the current registry has no approved content for a category; no placeholder gameplay modifier was invented.
- Debug scenarios construct valid states, but all subsequent changes still go through `RunController.submit_action()`.
- The January result payload preserves the existing terminal-result shape and adds a typed `match_result` bridge for the between-month screen.
- `RunRules` now defaults and normalizes the approved full-pool reward and duplicate-definition policies; active Wider Choice remains derived only from an active owned instance so reserve placement cannot affect reward count.
- End-to-end integration fixtures now exercise the shared production resale authority and preserve replay hash convergence.
- Full-capacity reward replacement is represented as persisted `RewardState.pending_acquisition`, with `REPLACE_PENDING_REWARD` and `REFUSE_REWARD` as the only completion paths.
- Production modifier-content readiness is reported as a warning rather than failing structural validation while the roadmap-deferred catalogue remains incomplete; seam definitions are never treated as playable content.
- 2026-09-18 authority audit: authenticated read of the canonical Game Design Authority confirmed the approved prototype reward/carry/shop/resale rules and the named modifier effects; BM-B07/B08/B09/B10/B11 remain unresolved at their narrower execution boundaries, while BM-B12 remains non-blocking for this milestone.

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
- 2026-09-18 — BM-04/BM-07/BM-08/BM-13 continuation checkpoint — targeted run/reward/carry/settlement/shop/save suites — PASS — approved defaults, shared resale, full-capacity replacement/refusal, Card Upgrade physical targeting, and pending reward save/load cases pass — working tree
- 2026-09-18 — full-suite continuation checkpoint — `scripts/run/validate_project.ps1 -GodotBinary C:\Users\valtu\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe` — PASS (provisional Godot 4.7.1) — 110/110 GdUnit4 cases across 21 suites; validator also reports the authored reward-content readiness warning — working tree
- 2026-09-18 — BM-15/BM-16 presentation hardening checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_between_month_ui.gd --ignoreHeadlessMode` plus full validator — PASS (provisional Godot 4.7.1) — accepted shop purchase/sale/reroll event messages remain visible after re-render; 6/6 focused UI cases and 110/110 full cases pass — working tree
- 2026-09-18 — exact-engine/native inspection preflight — Godot 4.7.2 search and native CUA inspection — NOT AVAILABLE — no Godot 4.7.2 executable found and no interactive/native Godot surface was exposed — ENV-BM-01 / UX-BM-01
- 2026-09-18 — canonical authority audit — authenticated read of `12 Moons — Game Design Authority` — PASS — approved reward/carry/shop/resale rules and modifier catalogue confirmed; later execution blockers remain explicitly unresolved — 317d11b
- 2026-09-18 — post-checkpoint full validation — `scripts/run/validate_project.ps1 -GodotBinary C:\Users\valtu\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe` — PASS (provisional Godot 4.7.1) — committed checkpoint passes the project/core smoke path and retains the 110/110 suite result; validator warns that only 1/3 eligible reward definitions are authored; generated `.import` metadata was restored — 317d11b
- 2026-09-18 — BM-14 motion convergence checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.7.1 console> -a res://tests/integration/test_card_motion.gd --ignoreHeadlessMode` — PASS — 9/9 card-motion, cancellation, reduced-motion, and NORMAL/FAST/INSTANT/REDUCED final-state convergence cases — 851ae10
- 2026-09-18 — approved content and transaction checkpoint — targeted `test_shop.gd`, `test_modifier_seams.gd`, `test_rewards.gd`, `test_save.gd`, and `test_between_month_ui.gd` — PASS — 35/35 targeted cases covering three production reward definitions, Salvage atomicity/attachment cleanup, Rain Check save/load/next-month persistence, and UI actions — working tree
- 2026-09-18 — full GdUnit4 checkpoint — `addons/gdUnit4/runtest.cmd --godot_binary C:\Users\valtu\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe -a res://tests --ignoreHeadlessMode` — PASS (provisional Godot 4.7.1) — 116/116 cases across 21 suites; no errors, failures, flaky, skipped, or orphaned cases — working tree
- 2026-09-18 — full project validation checkpoint — `scripts/run/validate_project.ps1 -GodotBinary C:\Users\valtu\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe` — PASS (provisional Godot 4.7.1) — January/core smoke, runtime UI flow, headless validation, and 116/116 GdUnit4 cases; authored-content warning cleared; generated `.import` metadata restored — working tree

## Known deferred work

- February gameplay and later Moon rules.
- Full modifier catalogue and unresolved modifier behavior.
- Remaining full modifier catalogue content and unresolved modifier behavior; the three approved non-seam definitions required for this milestone are now present.
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
- Production modifier content supplies enough authored eligible definitions for the approved persisted three-offer reward pool; no deferred seam is used as filler.
- All current design blockers are resolved or the milestone is explicitly
  stopped with the blocker recorded; no unresolved rule is invented.
