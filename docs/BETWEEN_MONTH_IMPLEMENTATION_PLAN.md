# Between-Month Implementation Plan

Status: execution plan for the January-to-February milestone. This document is
intended to be followed by a long-running Codex goal and updated only when the
architecture or an approved design decision changes.

## Milestone outcome

The milestone proves this complete loop around the existing January match:

`January → settlement → liquidation if required → carry-slot unlock → reward → carry preparation → six-offer shop → finalize → Begin February placeholder`

The loop must remain deterministic, saveable, replayable, accessible without
hover or drag, and presentation-safe under NORMAL, FAST, INSTANT, and Reduced
Motion modes. February gameplay, the full modifier catalogue, multiplayer, and
large presentation systems are outside this milestone.

## Current repository audit

Baseline: branch `main`, commit `e26a5da112aef4afd5e54e25e741b4cfb3712fba`.

### EXISTS AND SUFFICIENT

- `GameState` has explicit January phases, serialization, canonical JSON/hash,
  and 48-card conservation invariants.
- `MatchController` is the January mutation gateway and already uses
  copy-apply-validate-commit.
- `ActionGenerator`, `PublicStateView`, and `SimpleAI` provide a legal,
  public-information January AI path.
- January setup, 8/8/8 dealing, terminal state, scoring, Stop/Koi-Koi, and
  replay hash coverage exist.
- `CardCatalog`, stable card IDs, imported card faces, the Compatibility
  renderer, GdUnit4, and the existing PowerShell validation pipeline exist.

### EXISTS BUT NEEDS EXTENSION

- `terminal_result` must become a typed serializable `MatchResult` bridge.
- `ReplayLog` and state hashing must extend to run actions, before/after hashes,
  save continuation, and deterministic RNG-scope inspection.
- `MoonPresentationQueue`, `MoonCardMotionController`, stable card nodes, and
  `MoonMotionTimings` are good foundations but need semantic domain presenters,
  INSTANT mode, final-state restoration, and independent Reduced Motion.
- `boot.gd`, the result screen, and match scene need a run session and shared
  preparation shell.
- Stop/Koi-Koi currently uses a full-screen modal; it must become a
  context-preserving decision tray.
- Existing UI uses fixed coordinates, local theme overrides, tiny score text,
  and `FOCUS_NONE` on cards; new surfaces must use semantic Theme/components,
  Containers, focus navigation, and redundant state cues.
- Existing validators and integration tests must cover run content, saves,
  scenarios, shop/reward flows, accessibility paths, and profiling fixtures.

### MISSING

- `RunState`, `RunAction`, `RunController`, run journal, scoped RNG, and
  `MatchResult`.
- Settlement, `PendingSettlement`, liquidation, bankruptcy, carry capacity,
  modifier locations, reward state, shop state, and authoritative transactions.
- Modifier definitions/instances/registry and typed match-side effect seams.
- Reward generation, Wider Choice, six-slot shop generation, buy/sell/reroll,
  versioned JSON save/load, migration fixtures, and debug scenarios.
- Shared preparation shell, semantic Theme, focus restoration, modifier-card
  presentation, MonthPresentationProfile, and February placeholder.

### BLOCKED BY DESIGN DECISION

The unresolved decisions below are recorded as stable blockers. Engineering may
build policy-neutral schemas and tests, but must not select a gameplay rule.

| ID | Decision | Classification | First blocked milestone |
|---|---|---|---|
| BM-B01 | Whole-pool rewards or one-per-family rewards | BLOCKING NOW | BM-07 |
| BM-B02 | Duplicate modifier policy | BLOCKING NOW | BM-05/BM-07 |
| BM-B03 | Selected reward when active and reserve are full | BLOCKING NOW | BM-08 |
| BM-B04 | Shop purchase when storage is full | BLOCKING NOW | BM-13 |
| BM-B05 | Resale formula and free-reward sale eligibility | BLOCKING NOW | BM-04/BM-13 |
| BM-B06 | Wider Choice fourth slot under family quotas | BLOCKING LATER | BM-07 if BM-B01 selects quotas |
| BM-B07 | Fixed or player-selected Card Upgrade target | BLOCKING LATER | first Card Upgrade content |
| BM-B08 | Multiple Card Upgrades on one physical card | BLOCKING LATER | first attachment content |
| BM-B09 | Mulligan returned-card/shuffle procedure | BLOCKING LATER | future Mulligan behavior |
| BM-B10 | Second Draw with one or zero cards remaining | BLOCKING LATER | future Second Draw behavior |
| BM-B11 | Conflicting replacement-effect behavior | BLOCKING LATER | future Quad Koi behavior |
| BM-B12 | Voluntary bankruptcy | NON-BLOCKING for this loop | future liquidation UX |

For every BLOCKING NOW item, implementation must stop at the stated milestone
and ask the smallest concrete question rather than inventing a default:

- **BM-B01:** choose whole-pool or one-per-family rewards. Whole-pool increases
  variance; family quotas increase consistency and require BM-B06.
- **BM-B02:** choose no duplicate definitions or multiple instances. The latter
  requires explicit stacking and eligibility semantics.
- **BM-B03:** choose refusal/conversion, replacement, pre-sale/pre-move, or
  pending acquisition when all storage is full.
- **BM-B04:** choose rejection, replacement, pre-sale, or pending acquisition
  for a full-storage shop purchase.
- **BM-B05:** define sale proceeds and whether free rewards may be sold; this
  determines liquidation recovery and shop sale behavior.

Mulligan, Second Draw, Card Upgrade target selection/stacking, and replacement
conflicts receive seams only during this milestone. No unresolved behavior is
to be demonstrated with invented rules.

### DEFERRED BY ROADMAP

February gameplay; all twelve Moon rules; the full approved modifier catalogue;
multiplayer/networking; a second TypeScript rules engine; a generic ability DSL,
event bus, ECS, database, generic inventory framework, cloud saves/telemetry,
advanced AI search; touch-specific layout; 3D/rigid-body cards; full-screen
post-processing; large shader/VFX libraries; adaptive music; complex haptics;
and bespoke boards or seasonal content beyond the February placeholder.

## Architecture review gates

`AGENTS.md` is not present in the current repository or its parent chain. Until
the canonical file is supplied, these map-derived gates are the provisional
review contract:

- **G1 Authority:** `MatchController` owns match mutation; `RunController` owns
  run mutation; no third mutation authority exists.
- **G2 Transactions:** accepted actions clone, validate, commit, journal, and
  hash; rejected actions leave the canonical hash unchanged.
- **G3 Determinism:** stable string IDs, sorted candidate collections, scoped
  gameplay RNG, persisted generated offers, and no scene/timer/tween authority.
- **G4 Serialization:** every authoritative field and pending decision is
  serializable, migratable, and invariant-checked.
- **G5 Modifiers:** definitions are immutable, instances are run-owned,
  locations are unique, reserve is inactive, and physical cards are never
  duplicated.
- **G6 Presentation:** UI observes committed state and submits actions;
  animation cannot decide legality, ownership, economy, or phase progression.
- **G7 UX/accessibility:** focus/select/destination/commit works by mouse,
  keyboard, and controller; state is not color-only; focus is restored after
  dynamic mutations; new structure uses Containers and semantic Theme tokens.
- **G8 Production:** Compatibility-safe local effects, restrained causal motion,
  NORMAL/FAST/INSTANT convergence, Reduced Motion information equivalence,
  cancellation safety, 720p and higher-resolution inspection, and profiling.

## Ordered milestones

### BM-00 — Baseline and authority preflight

**Objective:** Freeze the repository baseline and remove tooling/documentation
ambiguity before domain work.

**Why this comes now:** All later checkpoints need an unambiguous version,
authority source, and validation command.

**Existing systems to reuse:** `VERSION`, `project.godot`, `CHANGELOG.md`,
`README.md`, and `scripts/run/validate_project.ps1`.

**Deliverables:** synchronize version surfaces to the intended current version;
record the absent `AGENTS.md` and inaccessible Game Design Authority; discover a
Godot 4.7.2 binary; initialize the progress ledger.

**Authority boundaries:** documentation/tooling only; no gameplay state changes.

**Tests/validation:** `scripts/run/validate_project.ps1 -GodotBinary <Godot 4.7.2 binary>`.

**Acceptance:** version surfaces agree, the validator can be invoked, and the
authority fallback is explicitly recorded.

**Blockers:** preflight availability only.

**Checkpoint:** append baseline commit, version, validator path/result, and
authority-source status to the progress ledger.

### BM-01 — RunState and prototype configuration

**Objective:** Add a serializable run authority beside `GameState`.

**Why this comes now:** Rewards, carry, shop, and economy must not create
temporary UI-owned truth.

**Existing systems to reuse:** `GameState.to_dict()`, `from_dict()`,
`canonical_dict()`, `state_hash()`, and invariant reporting.

**Deliverables:** `RunState`, explicit string phases, `PendingSettlement`, root
seed, capacities, generation counters, run rules configuration, canonical
serialization/hash/invariants.

**Authority boundaries:** `RunState` owns month, phase, bankroll, carry,
modifier ownership, reward/shop/liquidation state; `GameState` remains match-only.

**Required behavior:** new runs start in January with configured bankroll and
capacities; bankroll cannot become negative; every pending state is explicit.

**Presentation/UX:** none beyond stable phase IDs exposed to future presenters.

**Tests:** defaults, round-trip, hash stability, invalid phase/capacity/location
rejection, nonnegative bankroll.

**Validation:** targeted GdUnit4 run tests, then the full project validator.

**Acceptance:** a valid new run can be hashed, serialized, restored, and
validated without creating a second match state.

**Architecture gates:** G1, G3, G4.

**Blockers:** none.

**Checkpoint:** record test command, result, commit, and hash/round-trip evidence.

### BM-02 — Run actions, controller, journal, and RNG scopes

**Objective:** Establish the run copy-validate-commit transaction boundary.

**Why this comes now:** Every later economy and ownership operation must be one
replayable authoritative action.

**Existing systems to reuse:** `MatchController.submit_action()`, `ActionResult`,
and `ReplayLog` patterns.

**Deliverables:** `RunAction`, `RunActionResult`, `RunController`, run journal,
before/after hashes, stable hashed RNG-scope helper.

**Authority boundaries:** only `RunController` mutates `RunState`; UI, scenes,
debug tools, and presenters submit actions.

**Required behavior:** accepted actions record hashes; rejected actions do not
change state; gameplay RNG scopes are isolated from presentation randomness.

**Presentation/UX:** action result reasons are structured for readable UI errors.

**Tests:** accepted commits, rejected hash invariance, stable action ordering,
scope isolation, no global gameplay RNG.

**Validation:** targeted run transaction/determinism tests plus full validator.

**Acceptance:** no run mutation path bypasses `RunController`.

**Architecture gates:** G1, G2, G3, G6.

**Blockers:** none.

**Checkpoint:** journal and RNG evidence recorded.

### BM-03 — MatchResult bridge and January ingestion

**Objective:** Connect terminal January to the run layer exactly once.

**Why this comes now:** Settlement must consume authoritative match output rather
than recalculate from UI state.

**Existing systems to reuse:** `GameState.PHASE_MONTH_COMPLETE`,
`terminal_result`, `MatchController`, and the current boot flow.

**Deliverables:** serializable `MatchResult`, terminal extraction,
`RESOLVE_MONTH`, settled-match IDs, session-level ownership of both controllers.

**Authority boundaries:** `MatchController` produces the result; `RunController`
consumes it; neither mutates the other controller's state.

**Required behavior:** terminal-only ingestion, duplicate-result rejection, and
match hash preservation.

**Presentation/UX:** result presentation receives immutable before/after data.

**Tests:** terminal-only ingestion, malformed result rejection, duplicate
settlement rejection, UI cannot change bankroll directly.

**Validation:** January integration and run-bridge tests plus full validator.

**Acceptance:** completed January enters the run layer through one accepted action.

**Architecture gates:** G1, G2, G6.

**Blockers:** none.

**Checkpoint:** terminal bridge hash and duplicate-protection evidence recorded.

### BM-04 — Settlement, liquidation, and bankruptcy

**Objective:** Resolve January's economic result without negative canonical
bankroll.

**Why this comes now:** Carry and rewards depend on a settled, debt-free or
explicitly liquidating run phase.

**Existing systems to reuse:** `YakuEvaluator.settle()` and terminal score data.

**Deliverables:** settlement rules, `PendingSettlement`, payable settlement,
liquidation actions, bankruptcy phase, configured resale quote hook.

**Authority boundaries:** run rules calculate economic outcomes; presentation
only stages immutable before/after snapshots.

**Required behavior:** wins add resolved score; losses owe resolved score; exact
zero is legal; debt never appears as negative bankroll; recovery or bankruptcy
is explicit.

**Presentation/UX:** yaku → modifiers → final score → economic delta → bankroll;
no per-unit slot-machine counting.

**Tests:** win, loss, exact zero, insufficient funds, partial recovery,
successful recovery, unrecoverable bankruptcy, duplicate payment, hash invariance.

**Validation:** targeted settlement/liquidation tests plus full validator.

**Acceptance:** settlement is paid exactly once or the run enters `BANKRUPT`.

**Architecture gates:** G1, G2, G4, G6.

**Blockers:** BM-B05; BM-B12 only if voluntary bankruptcy is required.

**Checkpoint:** settlement fixtures and economic before/after hashes recorded.

### BM-05 — Modifier definitions, instances, capacity, and placement

**Objective:** Establish persistent modifier ownership and carry invariants.

**Why this comes now:** Rewards and shop offers need real legal destinations.

**Existing systems to reuse:** `CardCatalog` stable-ID content model and
`CardCollection` uniqueness behavior.

**Deliverables:** immutable definitions, persistent instances, registry,
active/reserve/card-attachment locations, eight-slot active model, four-slot
reserve configuration, January slot unlock, content validation skeleton.

**Authority boundaries:** `RunState` owns instances and locations; card
definitions remain immutable; upgrades attach to physical card IDs.

**Required behavior:** unique instance IDs, one legal location per instance,
capacity checks, reserve inactivity, valid card attachments, January unlock.

**Presentation/UX:** future active/reserve/locked states must be distinct by
placement, shape, and symbols, not color alone.

**Tests:** uniqueness, capacity, reserve inactivity, attachment validity,
January unlock, round-trip, physical 48-card conservation.

**Validation:** targeted modifier/carry tests plus content validator and full suite.

**Acceptance:** no modifier can exist in two authoritative locations or create a
49th physical card.

**Architecture gates:** G1, G3, G4, G5.

**Blockers:** BM-B02 for final duplicate policy; BM-B08 for multiple attachments.

**Checkpoint:** registry/content/invariant evidence recorded.

### BM-06 — Typed modifier seams and content validation

**Objective:** Create narrow effect domains without inventing unresolved rules.

**Why this comes now:** Wider Choice and future modifier content must not become
scattered modifier-ID conditionals.

**Existing systems to reuse:** matching, scoring, draw, and action pipelines.

**Deliverables:** handler registry and validation; seams for `RewardRequest`,
`CapturePlan`, `ScoreBreakdown`, opening decisions, draw-reveal decisions, and
named multiplier replacement; deterministic stage/priority metadata.

**Authority boundaries:** typed pipelines resolve effects; no UI or modifier ID
special-casing owns gameplay.

**Required behavior:** reserve modifiers are excluded; pending decisions are
serializable; conflicting replacement metadata fails loudly in development.

**Presentation/UX:** effect traces may be inspected but do not become UI truth.

**Tests:** synthetic handlers, invalid content rejection, reserve inactivity,
physical-card conservation through synthetic capture plans, conflict detection.

**Validation:** content validator and targeted seam tests.

**Acceptance:** future Sweep, Chaff Point Upgrade, Mulligan, Second Draw, and
Quad Koi have explicit insertion points without invented gameplay behavior.

**Architecture gates:** G3, G4, G5, G6.

**Blockers:** BM-B08–BM-B11 only for future behavior.

**Checkpoint:** seam coverage and negative validation evidence recorded.

### BM-07 — Reward requests, deterministic generation, and Wider Choice

**Objective:** Generate and persist the January reward set.

**Why this comes now:** Reward acquisition is the first persistent build choice.

**Existing systems to reuse:** scoped RNG, modifier registry, stable IDs, and
content validation.

**Deliverables:** `RewardRequest`, `RewardState`, offer IDs/provenance,
deterministic generator supporting both policy shapes, Wider Choice transformation
from 3 to 4.

**Authority boundaries:** generated offers are authoritative state; UI only
displays stored offers.

**Required behavior:** stable candidate order, persisted generated offers,
configured duplicate/exclusion policy, Wider Choice changes only choice count.

**Presentation/UX:** offers are face-up and comparable; no loot-box reveal.

**Tests:** both request shapes, same-seed determinism, reopen persistence,
exclusions, duplicate policy, 3→4 transformation, RNG isolation.

**Validation:** targeted reward/determinism tests plus full validator.

**Acceptance:** reward UI reopening cannot regenerate or reorder offers.

**Architecture gates:** G2, G3, G5, G6.

**Blockers:** BM-B01, BM-B02, BM-B06.

**Checkpoint:** record the selected approved policy before enabling acceptance flow.

### BM-08 — Reward selection, refusal, and acquisition placement

**Objective:** Resolve exactly one reward or configured cash refusal.

**Why this comes now:** A generated offer is not owned until a legal action
commits its destination.

**Existing systems to reuse:** `RunController`, `RewardState`, and carry model.

**Deliverables:** `CHOOSE_REWARD`, `REFUSE_REWARD`, pending-acquisition handling
if approved, and future target-selection shape.

**Authority boundaries:** acquisition is committed only by `RunController`.

**Required behavior:** once-only selection/refusal, configured refusal cash,
legal placement, no silent overflow.

**Presentation/UX:** selected offer travels to its committed destination only
after commit; carry and bankroll stay visible.

**Tests:** once-only selection/refusal, refusal cash, invalid offer, full-capacity
behavior, target legality, replay/save of pending acquisition.

**Validation:** targeted reward/carry tests and flow validation.

**Acceptance:** selected reward becomes owned legally, or the approved full-
capacity policy is followed.

**Architecture gates:** G1, G2, G4, G5, G6.

**Blockers:** BM-B03 and BM-B07 where applicable.

**Checkpoint:** acquisition location and capacity evidence recorded.

### BM-09 — Carry management transactions

**Objective:** Make active/reserve movement authoritative and replayable.

**Why this comes now:** The player must be able to prepare a build before the
shop and reserve effects must remain inert.

**Existing systems to reuse:** modifier placement and selection grammar.

**Deliverables:** `MOVE_MODIFIER`, legal destination queries, capacity validation,
attachment-aware movement, structured error reasons.

**Authority boundaries:** UI never edits active/reserve arrays directly; drag is
only a shortcut for the same action.

**Required behavior:** legal active↔reserve movement, no overflow, deterministic
replay, reserve excluded from effect projection.

**Presentation/UX:** select source → show legal destinations → select destination
→ commit; focus returns to the moved instance or source region.

**Tests:** movement, capacity rejection, attachment handling, reserve inactivity,
rejected hash invariance, keyboard/controller path.

**Validation:** targeted carry tests.

**Acceptance:** every legal movement is one replayable action.

**Architecture gates:** G1, G2, G5, G7.

**Blockers:** BM-B08 only for final multi-upgrade semantics.

**Checkpoint:** active/reserve hashes and focus-path evidence recorded.

### BM-10 — Save format v1 and migration harness

**Objective:** Resume every unresolved between-month phase deterministically.

**Why this comes now:** UI iteration must not require replaying January and saves
must preserve pending decisions.

**Existing systems to reuse:** `RunState`/`GameState` serialization and hashes.

**Deliverables:** versioned JSON envelope, checksum, run/match snapshots, action
journals, crash-resistant temp-write/verify/backup flow, explicit migration chain,
stable content-ID aliases.

**Authority boundaries:** save contains authoritative data only; no Nodes,
Tweens, Controls, focus, textures, or shared mutable Resources.

**Required behavior:** save/load liquidation, reward, pending acquisition, carry,
shop, finalize, transition, and active match state.

**Presentation/UX:** reopening restores the correct phase and focus entry point,
not animation progress.

**Tests:** all phase round-trips, malformed save rejection, migration fixtures,
unknown-content rejection, continuation equivalence.

**Validation:** targeted save/migration tests plus full validator.

**Acceptance:** save/reload continuation matches uninterrupted canonical hash and
future outcomes.

**Architecture gates:** G3, G4.

**Blockers:** none for schema; content policy blockers remain explicit.

**Checkpoint:** schema version, fixture results, and continuation hashes recorded.

### BM-11 — Debug scenarios and inspection

**Objective:** Remove manual January replay from development workflows.

**Why this comes now:** UI and edge-case work need deterministic valid states.

**Existing systems to reuse:** normal controllers, actions, and invariant checks.

**Deliverables:** `DebugScenarioFactory` fixtures for terminal win/loss,
liquidation, bankruptcy, reward, carry, initial shop, reroll 1/2, full capacity,
and February placeholder; read-only run inspector.

**Authority boundaries:** scenario construction must yield production-valid state;
subsequent mutations use normal actions.

**Required behavior:** expose root seed, phase/hash, bankroll/capacities,
locations/attachments, offer IDs, RNG scope, match hash, and action journal.

**Presentation/UX:** support FAST/INSTANT modes for scenario iteration.

**Tests:** every fixture passes invariants and has stable canonical hash.

**Validation:** targeted scenario tests.

**Acceptance:** every required phase opens deterministically without arbitrary
live-state mutation.

**Architecture gates:** G1, G2, G3, G4, G5.

**Blockers:** none.

**Checkpoint:** fixture list and hashes recorded.

### BM-12 — Six-slot ShopState and deterministic generation

**Objective:** Create persistent six-offer shop inventory.

**Why this comes now:** Shop transactions require stored offers, prices, and slot
specifications.

**Existing systems to reuse:** reward generator primitives and scoped RNG.

**Deliverables:** `ShopState`, six slot specifications, `ShopOffer`, initial
generation, stable prices/provenance, persisted offer state.

**Authority boundaries:** shop offers/prices live in `RunState`; UI never
regenerates inventory.

**Required behavior:** Card Upgrade, Hand/Mechanic, Strategic/Meta, two Wildcards,
and one Special slot; six offers persist unchanged on reopen.

**Presentation/UX:** fixed 3×2 offer geometry; carry/bankroll remain visible.

**Tests:** exact categories, stable slots, deterministic initial generation,
persisted reopen behavior, eligibility/content validation.

**Validation:** targeted shop-generation tests and content validator.

**Acceptance:** six authoritative offers exist with stable IDs and category slots.

**Architecture gates:** G2, G3, G5, G6.

**Blockers:** BM-B02 and BM-B07 for authored Card Upgrade content.

**Checkpoint:** initial shop IDs/categories/prices recorded.

### BM-13 — Shop transactions

**Objective:** Implement buy, sell, reroll, enter, and exit atomically.

**Why this comes now:** The shop completes the economic preparation loop.

**Existing systems to reuse:** `RunController`, carry actions, configured rules.

**Deliverables:** `ENTER_SHOP`, `BUY_OFFER`, `SELL_MODIFIER`, `REROLL_SHOP`,
`EXIT_SHOP`; reroll costs `[1, 2]`; no third reroll; category-preserving refill.

**Authority boundaries:** validation precedes currency deduction, materialization,
sale, or offer consumption.

**Required behavior:** exact payment/proceeds once, stable consumed tiles,
capacity and affordability errors, deterministic reroll scopes.

**Presentation/UX:** purchase/sale/re-roll are fast and quiet; no generic
confirmation dialog; focus remains predictable.

**Tests:** purchase/sale atomicity, insufficient funds, full storage, first/second
reroll, third rejection, deterministic rerolls, rejected hash invariance.

**Validation:** targeted shop transaction tests plus full validator.

**Acceptance:** invalid shop actions change nothing and valid actions commit once.

**Architecture gates:** G1, G2, G3, G5, G6, G7.

**Blockers:** BM-B04 and BM-B05.

**Checkpoint:** transaction hashes, currency deltas, and offer persistence recorded.

### BM-14 — Presentation and January UX foundation

**Objective:** Extend presentation infrastructure without making it authoritative.

**Why this comes now:** Between-month UI must inherit safe speed, cancellation,
focus, and material language from January.

**Existing systems to reuse:** presentation queue, motion controller, stable card
registry, and motion timing vocabulary.

**Deliverables:** semantic `MotionProfile`; NORMAL/FAST/INSTANT; independent
Reduced Motion; cancellation epoch/final-state restoration; domain presenter
seams; focusable `MoonCardView`; Theme tokens; Container primitives; contextual
Stop/Koi-Koi tray.

**Authority boundaries:** committed state drives presentation; animation never
decides rules, ownership, economy, or phase progression.

**Required behavior:** immediate input acknowledgement, no stale async updates,
and final-state convergence across speed modes.

**Presentation/UX:** causal card motion, restrained effects, readable text,
redundant focus/state cues, no routine particles or full-screen blur.

**Tests:** speed convergence, reduced-motion equivalence, cancellation/restart,
no deadlock, focus visibility/restoration, non-modal Stop/Koi-Koi flow.

**Validation:** integration presentation tests plus full validator.

**Acceptance:** cancellation unlocks input and all modes end in the same visible
state.

**Architecture gates:** G6, G7, G8.

**Blockers:** none.

**Checkpoint:** motion/focus/accessibility evidence recorded.

### BM-15 — Shared preparation shell and settlement/reward/carry UI

**Objective:** Build the continuous between-month environment through carry setup.

**Why this comes now:** Player-facing flow must show causality and ownership in
one tabletop space.

**Existing systems to reuse:** result data, run projections, card motion, and
presentation queue.

**Deliverables:** `PhaseShell`, phase rail, settlement ledger, bankroll anchor,
eight-slot carry tray, reserve region, modifier offer/inspect components,
settlement/liquidation/reward/carry presenters.

**Authority boundaries:** UI renders committed `RunState` and submits actions;
it does not calculate settlement, prices, or placement.

**Required behavior:** settlement → slot unlock → reward → carry; full carry tray
visible from the start; refusal and errors explicit.

**Presentation/UX:** settlement arithmetic is causal; slot unlock precedes reward;
selected reward travels to its committed destination; mouse, keyboard, and
controller share semantic actions.

**Tests:** end-to-end flow, no direct mutation, focus paths, focus restoration,
save/reload reconstruction, reduced motion.

**Validation:** headless between-month UI flow plus full validator.

**Acceptance:** player can explain what changed, what was earned, and where it is
owned without leaving the preparation table.

**Architecture gates:** G1, G6, G7, G8.

**Blockers:** BM-B03 for full-capacity reward acceptance.

**Checkpoint:** scenario-driven UI screenshots/flow results and ledger entry.

### BM-16 — Shop, finalization, and player-facing transaction feedback

**Objective:** Complete the shop and final build preparation UI.

**Why this comes now:** Shop UI depends on real transactions, carry destinations,
and persistent offer state.

**Existing systems to reuse:** shared shell, offer region, carry tray, semantic
controls, and transaction result reasons.

**Deliverables:** 3×2 shop grid, persistent carry/bankroll, affordability and
capacity errors, buy/sell/reroll feedback, focus restoration, final summary,
exact `Begin February` action.

**Authority boundaries:** only `RunController` changes run state.

**Required behavior:** purchase, sale, reroll, inspect, compare, move, and
finalize work without required hover/drag or hidden confirmation.

**Presentation/UX:** routine shopping is faster/quieter than reward acquisition;
carry stays visible; unaffordable offers remain visible with reasons.

**Tests:** complete shop UI flow, repeated actions, keyboard/controller topology,
invalid-action messaging, valid-build-only finalization.

**Validation:** targeted UI flow and full validator.

**Acceptance:** player can see price, bankroll, destination, replacement
consequence, reroll cost, and active/reserve state from one view.

**Architecture gates:** G1, G6, G7, G8.

**Blockers:** BM-B04 and BM-B05.

**Checkpoint:** transaction/UI evidence recorded.

### BM-17 — January-to-February transition placeholder

**Objective:** Cross the month boundary with finalized authoritative state.

**Why this comes now:** The milestone is incomplete until the prepared build and
bankroll reach a deterministic February placeholder.

**Existing systems to reuse:** shared shell, presentation queue, motion profile,
and run phases.

**Deliverables:** `MonthPresentationProfile`, January/February data, transition
recipe, February/Snow Moon placeholder, finalization and transition actions.

**Authority boundaries:** finalized `RunState` carries bankroll, modifiers,
capacities, and seed; no February gameplay is added.

**Required behavior:** `FINALIZE_BUILD` is legal only for a valid build; save/load
at the boundary reproduces the same state.

**Presentation/UX:** foreground remains readable while the month environment
transitions; exact action copy is `Begin February`; skip/fast/reduced work.

**Tests:** profile loading, finalization boundary, inherited state, save/reload,
speed/reduced-motion convergence.

**Validation:** full January-to-February headless flow plus full validator.

**Acceptance:** February placeholder visibly inherits finalized state and no
February rules are implied or implemented.

**Architecture gates:** G3, G4, G6, G8.

**Blockers:** none beyond unresolved asset approval.

**Checkpoint:** boundary hash and placeholder flow recorded.

### BM-18 — Final hardening and release gate

**Objective:** Prove the full milestone and remove implementation drift.

**Why this comes last:** Broad verification is meaningful only after all paths
exist.

**Deliverables:** full save/replay matrix, seed/action sweeps, content validation,
input/focus paths, reduced motion, cancellation, Compatibility profiling, 720p
and higher-resolution inspection, cleanup, README/VERSION/project/changelog
synchronization.

**Authority boundaries:** final architecture review must confirm one mutation
gateway per layer and no presentation authority.

**Required behavior:** complete loop, deterministic replay, save continuation,
physical 48-card conservation, AI privacy, and stable rejected-action hashes.

**Presentation/UX:** normal/fast/instant convergence, reduced-motion information
equivalence, causal settlement/reward/shop feedback, no unjustified full-screen
passes, profiling scenarios within the roadmap targets.

**Tests:** all unit/domain, controller/transaction, determinism, serialization,
integration, UI, privacy, physical-card, and presentation tests listed in this
document and the progress ledger.

**Validation:**
`scripts/run/validate_project.ps1 -GodotBinary <discovered Godot 4.7.2 binary>`.

**Acceptance:** January → settlement → liquidation if required → unlock → reward
/ refusal → carry → six-offer shop → buy/sell/reroll → finalize → February
placeholder succeeds and is fully evidenced.

**Architecture gates:** G1–G8.

**Blockers:** all BLOCKING NOW decisions resolved; later blockers remain only as
documented seams.

**Checkpoint:** final Definition of Done signed in the progress ledger.

## Definition of Done

- The two implementation documents exist and the progress ledger is current.
- January remains driven by the existing `MatchController`/`GameState` path.
- A typed `MatchResult` enters a separate deterministic `RunController`/`RunState`.
- Settlement, liquidation, bankruptcy, capacity, reward, carry, shop, and
  finalization are authoritative actions with hash-preserving rejection.
- Generated reward/shop offers persist and use isolated deterministic RNG scopes.
- Wider Choice is implemented through `RewardRequest` transformation only.
- All modifier instances have one legal location; reserve effects are inactive;
  card upgrades preserve physical 48-card conservation.
- Every between-month phase saves, loads, and continues identically.
- Debug scenarios cover all required phases and pass production invariants.
- The shared preparation flow is focusable by keyboard/controller and does not
  rely on color, hover, or drag alone.
- NORMAL, FAST, INSTANT, and Reduced Motion converge on the same final state;
  cancellation cannot deadlock input or progression.
- Settlement causality, reward ownership, shop feedback, and February transition
  are readable with restrained Compatibility-safe presentation.
- Full validation, determinism, save/replay, content, accessibility, and
  profiling checks pass.
- Deferred roadmap work remains explicitly outside the milestone.
