# Between-Month Development Map

Status: Planning map only. Expand each section into a dedicated design/implementation spec before building it.

This document defines the next ordered development steps after the playable January match and initial card-motion pass. It incorporates the current UX research and deterministic run-architecture research while preserving the Game Design Authority as the source of truth for gameplay rules.

Research-derived architecture and UX recommendations in this document are implementation guidance. They must not silently resolve gameplay decisions that the Game Design Authority marks as WORKING, PROTOTYPE, UNRESOLVED, or contradictory.

## North-Star Milestone

Prove the first complete roguelike month loop around the existing hanafuda game:

`play January → settle money → unlock carry capacity → choose reward → prepare carry build → shop → finalize build → Begin February`

For this milestone, **Begin February may end at a clean placeholder**. Do not build February gameplay until the between-month loop itself is proven.

The milestone must prove two things at once:

1. the player-facing loop is clear, tactile, and feels like one continuous tabletop experience; and
2. the run layer is deterministic, replayable, saveable, testable, and incapable of bypassing the existing authoritative match architecture.

---

# 0. Deterministic Run Architecture Foundation

This is the first engineering dependency. Do not let reward, shop, carry, or money UI create temporary sources of truth that later need to be replaced.

## Authority boundary

Preserve the existing match architecture and add a parallel run-level authority:

```text
RunSession / scene orchestration
        │
        ├── RunController ──► RunState
        │
        └── MatchController ─► GameState
```

Rules:

- **RunState** owns persistent year/run data:
  - current month;
  - run phase;
  - bankroll;
  - unlocked active carry capacity;
  - reserve capacity;
  - modifier instances and authoritative locations;
  - reward state;
  - shop state;
  - pending settlement/liquidation;
  - root run seed and generation counters.
- **GameState** remains the authoritative state for the active hanafuda match.
- **RunController** is the sole run-layer mutation gateway.
- **MatchController** remains the sole match-layer mutation gateway.
- RunController must not directly mutate live GameState.
- MatchController must not mutate bankroll, carry, rewards, or shop state.
- UI and scenes observe state and submit actions. They do not calculate or commit authoritative outcomes.
- Do not rename GameState merely for conceptual purity during this milestone unless the rename is essentially free and demonstrably low-risk.

## MatchResult bridge

When January reaches its terminal authoritative state, create a small serializable MatchResult containing at least:

- match ID;
- month;
- winner/result;
- final resolved score;
- end reason;
- final match-state hash.

The completed match enters the run layer through an action equivalent to:

`RESOLVE_MONTH(match_result)`

The UI must never directly perform bankroll math.

A match result ID may be settled exactly once.

## Run phases

Use explicit authoritative phases rather than inferring progression from visible screens.

At minimum:

```text
MONTH_MATCH
LIQUIDATION
REWARD
CARRY
SHOP
FINALIZE
TRANSITION
BANKRUPT
COMPLETE
```

The immediate flow is:

```text
January terminal match
      ↓
RESOLVE_MONTH
      ↓
settlement
  ┌───┴──────────────────┐
  │ payable              │ debt cannot yet be covered
  ↓                      ↓
slot unlock          LIQUIDATION
  │                      │
  │                 liquidation actions
  │                      ↓
  │                debt satisfied?
  │                 yes / impossible
  │                  ↓       ↓
  └──────────────► REWARD   BANKRUPT
                      ↓
                    CARRY
                      ↓
                     SHOP
                      ↓
                  FINALIZE
                      ↓
                  TRANSITION
                      ↓
          FEBRUARY PLACEHOLDER
```

Pending player choices must exist in authoritative state and legal actions. Never represent an unresolved gameplay decision only by an animation callback, coroutine, modal Node, Timer, or awaited signal.

## Copy-validate-commit

RunController should deliberately extend the current MatchController transaction model:

1. validate the current RunState;
2. validate the requested RunAction;
3. clone the current run state;
4. apply the action to the candidate;
5. validate all run invariants;
6. commit only if valid;
7. record the action and resulting state hash.

Rejected actions must leave the canonical state hash unchanged.

Do not create separate mutation-owning ShopController, RewardController, CarryManager, EconomyManager, ModifierManager, or similar parallel authorities. Narrow pure helpers are appropriate, but mutation remains centralized in RunController.

## RunState invariants

RunState should expose the same basic disciplines already used by GameState:

- `to_dict()`;
- `from_dict()`;
- canonical dictionary/JSON;
- deterministic state hash;
- `invariant_errors()`;
- `invariants_ok()`.

At minimum validate:

- bankroll never becomes negative in canonical state;
- month is in a legal range;
- every modifier instance ID is unique;
- every owned modifier exists in exactly one legal authoritative location;
- active count does not exceed unlocked active capacity;
- reserve count does not exceed reserve capacity;
- reserve modifiers are excluded from active effect projection;
- card attachments reference real stable card IDs;
- referenced modifier definitions exist;
- RewardState exists only when appropriate;
- ShopState exists only when appropriate;
- PendingSettlement exists only when appropriate;
- a match result cannot be settled twice;
- shop/reward offer IDs are unique;
- a consumed offer cannot be consumed twice.

Use stable serialized string IDs for phases, actions, content, offers, and modifier instances. Do not rely on reordered numeric enums as persistent identifiers.

## Prototype configuration

Keep tunable prototype values centralized in a small run-rules data file rather than scattering literals through UI and effect handlers.

Examples:

- starting bankroll = 20;
- reserve capacity = 4;
- maximum active slots = 8;
- January-through-August unlock schedule;
- reward refusal cash = +2;
- shop reroll costs = [1, 2];
- prototype prices/weights when defined.

These remain prototype values where the Design Authority says they are not locked.

**Architecture status:** engineering direction to lock for implementation. This section does not alter game-design values.

---

# 1. Deterministic RNG, Persistence, and Content Contracts

These foundations must exist before rewards and shops become authoritative systems.

## RNG ownership

Use one persistent root run seed, but **not one mutable global gameplay RNG stream**.

Derive local deterministic RNG scopes using a fixed stable hash over inputs such as:

```text
root_run_seed
generation_schema_version
subsystem
month
sequence
```

Expected scopes include:

- match/deck/month;
- reward/month/generation;
- shop/month/initial;
- shop/month/reroll/1;
- shop/month/reroll/2;
- future modifier-specific scopes.

Requirements:

- no authoritative global `rand*()` or `randomize()`;
- deterministic candidate collections must be put into a stable order before random selection;
- VFX, sound pitch, particles, wobble, and presentation randomness use separate non-authoritative RNG;
- adding one random call in AI or presentation must not change a future reward, shop, or deck;
- once a deck, reward set, or shop is generated, persist the generated result in authoritative state rather than regenerating it when UI opens.

Do not promise permanent cross-Godot-version reconstruction from seed alone. Persist generated authoritative outcomes and version the derivation scheme.

## Authoritative content model

Use the existing pattern rather than introducing a general data framework:

- JSON for deterministic gameplay definitions and prototype configuration;
- GDScript for executable rule handlers, schemas, registries, and validators;
- optional Resources for immutable/presentation metadata;
- scenes for visual composition only.

Do not store per-run mutable authority in shared loaded Resources.

Recommended data areas:

- `data/modifiers/modifiers.json`;
- `data/run/run_rules.json`;
- shop-table data if/when needed;
- Moon definitions later.

## Headless content validation

Extend the existing project validator so malformed content fails loudly before gameplay.

Validate at least:

- unique modifier IDs;
- all effect-handler keys registered;
- valid modifier family/target combinations;
- referenced hanafuda card IDs exist;
- required fields present;
- forbidden fields absent where appropriate;
- price/weight values nonnegative;
- configured run-rule values valid;
- each baseline shop slot can produce at least one eligible candidate;
- renamed-ID aliases do not cycle;
- referenced assets/definitions exist;
- typed definition round-trip succeeds.

Keep GdUnit4 as the test framework.

## Save format v1

Once the between-month domain state exists, implement an explicit versioned JSON save envelope.

It should include authoritative state only:

- RunState;
- modifier instances and placement;
- root seed and generation counters;
- reward/shop/liquidation state;
- active MatchState snapshot when a match is active;
- run and match action/replay journals as appropriate;
- schema/game/content versions;
- payload checksum/hash.

Do not serialize:

- Nodes/scenes;
- Controls;
- Tweens/Timers;
- animation queue progress;
- textures/audio copies;
- Callables;
- UI selection/focus;
- mutable Resource graphs.

Add a migration chain from schema v1 onward. Migration functions should be explicit dictionary transformations.

Removed or renamed content IDs must have explicit migration/alias behavior. Never silently discard unknown content from a save.

Use crash-resistant temp-write → verify → backup/rotate previous save → replace-final behavior. Treat this as best-effort filesystem safety, not a mathematical guarantee.

**Milestone requirement:** closing/reloading during reward, carry, shop, or liquidation must restore the same authoritative state and continue deterministically.

---

# 2. Modifier Definition / Instance / Effect Architecture

Do not wire modifiers as scattered `if modifier_id == ...` conditionals.

## Three-layer model

Use:

```text
immutable ModifierDefinition
        ↓
persistent ModifierInstance
        ↓
typed effect handler(s)
```

A definition contains stable authored data such as:

- modifier ID;
- family;
- target kind;
- effect specs;
- base price/offer data where appropriate;
- optional AI semantic metadata.

An instance contains run-specific data such as:

- stable instance ID;
- definition ID;
- acquired month;
- acquisition source;
- actual purchase price where applicable;
- target card ID for Card Upgrades;
- authoritative location;
- persistent run-long state.

Card Upgrades attach to stable physical hanafuda card IDs. They must not mutate CardDefinition or create duplicate card copies.

## Ownership model

Distinguish:

- **economic owner**: whose run owns the modifier;
- **effect subject**: player or physical hanafuda card;
- **beneficiary**: determined by the effect.

A Card Upgrade such as Sweep belongs to the player's run economically but follows the physical upgraded card when that card is captured/used, including by the AI where the approved effect says it is shared-risk.

Reserve modifiers remain owned but are excluded from the active effect projection.

## Typed effect domains

Use small typed rule pipelines rather than a universal event bus.

Initial concrete domains:

- RewardRequest transformation;
- CapturePlan augmentation;
- structured scoring/ScoreBreakdown adjustment;
- draw-decision provider;
- opening-decision provider;
- named multiplier replacement.

Add new hooks only when a concrete approved modifier or Moon rule requires them.

The registry may map stable handler keys to preloaded GDScript handlers. Gameplay systems should depend on domains/handlers, not on modifier IDs.

## Effect order

Before many modifiers exist, establish deterministic operation metadata:

- domain;
- stage;
- explicit priority;
- source kind;
- stable source ID;
- stable operation ID;
- mode.

Keep modes small and explicit, such as:

- REPLACE;
- PREVENT;
- ADD;
- MULTIPLY;
- AUGMENT.

Stable ID ordering is only the final deterministic tie-break. If intended behavior depends on arbitrary IDs, the priorities/compatibility rules are underspecified.

Same-priority noncommutative replacement conflicts should fail validation in development unless an explicit coexistence rule exists.

## Trigger safety

Each effect-resolution chain should have a stable root event token and prevent the same modifier from retriggering the same hook for the same event unless explicitly marked repeatable.

A defensive recursion/depth limit may exist, but exceeding it should fail loudly before commit rather than silently truncating resolution.

Charges/once-per-month usage are consumed only on successful authoritative commit.

## Moon-rule future seam

Future Moon rules should eventually participate as another rule source in the same typed pipelines:

```text
base rules
Moon rule
active card upgrades
active player modifiers
```

Do not build a second parallel Moon-effect engine.

**Architecture status:** engineering direction. Exact modifier stacking, duplicate policy, and conflict game rules remain design decisions where noted below.

---

# 3. UX Architecture Foundation

Build the reusable interface foundation without allowing it to own run truth.

## Shared preparation shell

Establish one persistent between-month **PhaseShell / preparation-table environment**.

Use a restrained orientation rail such as:

- Settlement
- Reward
- Prepare
- Shop
- February

The rail communicates orientation, not authority. The current RunState phase decides what is legal.

Settlement should visually transform from the January result rather than cutting to a completely unrelated dashboard.

Reward and shop offers should reuse the same offer region.

Carry and bankroll should remain in stable locations through reward, preparation, shop, and finalization.

## Structural layout rules

- New major UI structure should use Godot Control and Container composition instead of multiplying fixed absolute positions.
- Preserve 1280 × 720 as the current canonical prototype canvas.
- Do not change stretch behavior merely to hide layout problems. Containerize the major regions first.
- Keep hanafuda cards as the primary visual objects.
- Prefer spatial grouping, trays, sheets, slots, and one clear table surface rather than a panel behind every datum.
- Modifier offers must use a visual silhouette/material grammar distinct from hanafuda cards.

## Theme and reusable components

Create a lightweight project Theme and reusable semantic components.

High-value components include:

- existing MoonCardView evolved into the reusable hanafuda-card role;
- ModifierCard;
- CarrySlot;
- InspectPanel;
- Tooltip;
- CurrencyDisplay;
- OfferGrid;
- ComparePanel;
- PhaseShell;
- semantic ActionButton variants;
- MoonRuleDisplay;
- YakuSummary where the current gameplay UI touches it.

Do not prematurely lock final hues/materials in this milestone.

## Input and focus

Canonical interaction grammar:

**focus/select → inspect if needed → choose target/destination → commit**

- hover and drag are accelerators only;
- click-select-click / focus-select-destination is canonical for carry movement;
- all input methods submit the same semantic RunAction/GameAction;
- make MoonCardView focusable rather than relying on FOCUS_NONE;
- define explicit focus neighbors where geometry is ambiguous;
- restore focus deliberately after mutations;
- every hover tooltip needs a focus/inspect path.

## Readability/accessibility

- meaningful body/mechanical text should generally target roughly 14–16 px at the 1280 × 720 prototype scale;
- important actions/values roughly 16–18 px;
- 12–14 px only for genuinely secondary metadata;
- verify rendered results rather than treating the integer font size as certification;
- state cannot rely on color alone;
- focus uses a clear border/shape/weight cue, not glow alone;
- reduced-motion handling remains centralized;
- reusable semantic controls receive accessibility names/descriptions;
- new layouts remain localization-resilient.

## January UX debt to clear before surface area grows

- Replace the heavily dimmed full-screen Stop/Koi-Koi modal with a context-preserving decision tray.
- Keep current score, relevant yaku progress, exact known Koi-Koi consequences, and public opponent threats accessible.
- Retain legal-target assistance but favor stable selection/focus outlines over broad dimming or constant glow.
- Preserve hanafuda artwork as dominant card identity.
- Keep Japanese terms consistent with English support.

---

# 4. Money + January Settlement + Liquidation

Build the first run action bridge from completed January into persistent run state.

## Settlement

- Start with the current **20 currency** prototype baseline.
- Use final resolved hanafuda score as the economic scale.
- A win adds the resolved score.
- A loss owes the resolved score.
- Koi-Koi and other score multipliers enter the economy only through the final resolved score.
- Spending down to 0 is legal.
- The settlement is calculated by run-domain rules from MatchResult, not by UI.

The settlement presentation should reveal:

1. yaku;
2. Moon/additive adjustments;
3. multipliers;
4. final resolved score;
5. economic result;
6. bankroll.

## Emergency liquidation

Liquidation is a distinct authoritative run phase.

Do **not** make canonical bankroll negative and ask UI to repair it.

If a loss is payable immediately:

- subtract the amount once;
- clear settlement;
- continue.

If the loss cannot yet be covered:

- keep bankroll nonnegative;
- create PendingSettlement;
- enter LIQUIDATION;
- disallow normal reward/shop spending;
- permit only legal liquidation actions.

When legal sales raise enough to cover the debt, pay the debt once and continue.

If no legal remaining assets can satisfy the debt, transition to BANKRUPT.

The exact resale value of free rewards and other unresolved sale rules remain design decisions and must not be invented here.

**Authority status:** economy sequence follows the approved prototype baseline; final tuning/resale details remain provisional or unresolved as stated in the Game Design Authority.

---

# 5. Carry Capacity + Authoritative Modifier Placement

After a successfully resolved January settlement:

- unlock active carry slot #1;
- one normal slot unlocks per completed month through August;
- active maximum remains 8.

RunState must authoritatively own:

- unlocked active capacity;
- active modifier instance IDs;
- reserve modifier instance IDs;
- card-upgrade attachments;
- any explicit pending-acquisition state if that design is used.

The UI should show all eight eventual active positions from the first between-month sequence, with future positions visibly locked.

Current working reserve recommendation remains **4 slots**.

Movement must be a RunAction, conceptually:

`MOVE_MODIFIER(source, destination)`

and must validate capacity/location invariants atomically.

Selling is a separate explicit action, never an accidental drag-out behavior.

---

# 6. Reward Request, Generation, and Selection

The reward system is authoritative run state, not a UI list generated on open.

## Shared deterministic generator

Use one deterministic offer generator driven by a declarative RewardRequest.

A request specifies at least:

- month;
- choice count;
- slot/category specifications;
- exclusions;
- duplicate policy;
- source/provenance.

Both currently competing reward models must use the same generator architecture.

Whole-pool model:

```text
ANY_MODIFIER
ANY_MODIFIER
ANY_MODIFIER
```

Family-guaranteed model:

```text
CARD_UPGRADE
HAND_MECHANIC
STRATEGIC_META
```

The architecture must support both without choosing between them.

Generated offers are stored in RewardState and must not change when the UI is reopened.

Each offer should have a stable ID and provenance.

## Wider Choice

**Wider Choice is the one representative modifier to implement end-to-end during this milestone.**

It should transform a RewardRequest:

`choice_count: 3 → 4`

before deterministic generation.

It must not be hard-coded inside RewardGenerator.

The category/policy of the fourth slot under the family-guaranteed reward model is unresolved and must be explicitly decided before that configuration can use Wider Choice.

## Selection/refusal

Use RunActions equivalent to:

- CHOOSE_REWARD;
- REFUSE_REWARD;
- PLACE_PENDING_ACQUISITION where required.

The cash refusal remains the current working **+2 currency** value.

A reward can be selected/refused exactly once.

If a chosen reward cannot immediately fit because storage is full, do not secretly overflow capacity. The final placement/replacement policy is a design decision; a pending-acquisition state is an acceptable engineering representation if that policy requires a later placement resolution.

## Presentation

- carry and bankroll remain visible;
- modifiers do not visually masquerade as hanafuda;
- offer copy is concise/mechanical first;
- full detail is available through focus/inspect;
- cash refusal is explicit;
- target selection uses the same stable legal-target grammar as gameplay;
- acquisition visibly moves to its authoritative destination only after commit.

---

# 7. Carry-Build Preparation

Carry management remains part of the shared preparation environment, not a disconnected inventory screen.

Primary interaction:

1. select source modifier;
2. show legal destinations;
3. select destination;
4. submit MOVE_MODIFIER;
5. render the committed state.

Optional drag-and-drop may call the same action path.

Active, reserve, locked, empty, selected, disabled, ready, and used states should be redundantly legible through placement/form/symbols rather than color or opacity alone.

Do not build sorting/filtering, radial menus, generic inventory abstractions, or unlimited storage.

---

# 8. Six-Offer Shop as Authoritative State

ShopState contains the actual persistent offers.

Initial slot specifications remain:

1. Card Upgrade
2. Hand/Mechanic Modifier
3. Strategic/Meta Modifier
4. Wildcard modifier
5. Wildcard modifier
6. Service / special / economy / slot-access / other bounded nonstandard opportunity

Wildcard is a slot-eligibility rule, not a new modifier family.

The sixth slot does not justify a generic item/inventory system.

## Shop actions

Use atomic RunActions equivalent to:

- ENTER_SHOP;
- BUY_OFFER;
- SELL_MODIFIER;
- REROLL_SHOP;
- MOVE_MODIFIER;
- EXIT_SHOP.

Buying must validate, before commit:

- correct phase;
- offer exists and is not consumed;
- quoted price is authoritative/current;
- sufficient bankroll;
- definition/service is legal;
- target is legal if required;
- destination/capacity rules are satisfied under the approved inventory policy.

Only then deduct currency and materialize the result.

Rejected purchases change nothing.

## Rerolls

Current baseline:

- first reroll: **1 currency**;
- second reroll: **2 currency**;
- no third reroll.

Reroll price schedule belongs in configuration.

Each reroll derives its own deterministic RNG scope.

Rerolls preserve the six stored slot specifications.

Sold/consumed tiles remain stable in the UI instead of causing a geometry reshuffle.

## Presentation

- use a 3 × 2 offer grid at 1280 × 720;
- keep bankroll, carry, reserve, and phase orientation visible;
- unaffordable offers remain visible with a direct shortfall explanation;
- focus updates a stable inspect/compare area;
- routine purchase should not use generic confirmation dialogs;
- focus return after buy/sell/reroll is explicitly defined.

**Authority status:** shop direction follows the approved prototype baseline; exact prices, rarity, services, resale formulas, and full-inventory policy remain configurable/unresolved where the Design Authority says so.

---

# 9. Match-Side Modifier Seams, Not Full Modifier Content

Do **not** implement the entire six-modifier representative set end-to-end as part of the between-month milestone.

The milestone must establish the correct seams and tests so later implementations do not become special cases.

Required seams:

## Chaff Point Upgrade

Structured score output must be able to identify contributing card IDs and accept an additive card-upgrade bonus without changing the Kasu threshold count.

## Sweep

Capture resolution must be able to produce a base CapturePlan, apply card-owned capture augmentation, validate physical-card conservation, then commit.

## Mulligan

Future implementation must use an explicit opening-decision phase and legal action, not an animation/coroutine callback.

**Do not implement until the exact returned-card/shuffle procedure is explicitly approved.**

## Second Draw

Future implementation must use an explicit draw-reveal decision phase between reveal and resolution.

**Do not implement until legality with one/no remaining draw cards is explicitly approved.**

## Quad Koi

Scoring must expose a named `koi_koi_multiplier` replacement seam so Quad Koi replaces x2 with x4 rather than multiplying by another x2.

## Wider Choice

Implement now through the run-layer RewardRequest transformation described above.

The architecture must make reserve modifiers inert and Card Upgrades follow stable physical card IDs.

---

# 10. Save/Load, Determinism, and Debug Acceptance Infrastructure

Before declaring the between-month milestone complete, build the tools that prevent repeated manual January playthroughs and make failures reproducible.

## Save/load tests

Round-trip every between-month phase:

- liquidation;
- reward;
- pending acquisition if used;
- carry;
- shop;
- finalize/transition.

Save/load continuation must match uninterrupted continuation in canonical hash and outcomes.

## Determinism tests

At minimum:

- same root seed + same actions = same canonical state/hash;
- different RNG subsystem scopes do not affect each other;
- rejected actions preserve hash;
- generated offers persist after reopening/reloading;
- rerolls are deterministic and category-preserving;
- replay of run actions reproduces the same run hash;
- stable sorting/IDs provide total deterministic ordering.

## Scenario/debug harness

Build a deterministic DebugScenarioFactory or equivalent that constructs fully valid states such as:

- January terminal win at selected score;
- January terminal loss;
- liquidation required;
- reward phase;
- full/partial carry configurations;
- initial shop;
- shop after first/second reroll;
- bankruptcy edge case;
- February placeholder.

Scenario states must pass production invariants.

Legal debug operations should use normal controller actions.

Do not create cheats that manually mutate twenty private fields or move card Nodes as if they were authority.

High-value debug inspection:

- root seed;
- run phase/hash;
- bankroll/capacities;
- current RNG scope/derived seed;
- active/reserve/card attachments;
- reward/shop offer IDs and categories;
- match hash/card locations;
- accepted action journal and resulting hashes.

Keep fast/instant/reduced presentation modes so domain iteration does not require waiting for animation.

---

# 11. Between-Month UI Flow

Only after the underlying run transactions exist should the UI be wired to them.

The UI must contain no direct authoritative mutation such as:

- `currency += ...`;
- direct active/reserve array edits;
- direct offer removal;
- direct modifier materialization;
- reroll generation;
- settlement calculation.

It submits actions and renders committed state.

The player-facing progression remains:

**Settlement → Slot Unlock → Reward → Prepare → Shop → Begin February**

The shared preparation shell should make those phases feel spatially continuous even though RunState explicitly records the current legal phase.

---

# 12. Finalize Build + February Placeholder

Create the final deterministic transition for the milestone.

Use a RunAction equivalent to:

`FINALIZE_BUILD`

then transition to the February placeholder through authoritative run state.

Show:

- active slots used/unlocked;
- reserve count;
- bankroll;
- February / Snow Moon identity;
- February rule only if that rule has been explicitly approved by then.

Use the exact action copy **Begin February** rather than generic Continue.

No ritual second confirmation is needed if the build is valid.

The placeholder must inherit the finalized bankroll/build state and prove that a save/reload at the boundary reproduces the same run state.

---

# Cross-Cutting Determinism Rules

These rules apply to every implementation in the milestone.

- No authoritative gameplay progression in `_process()`, `_physics_process()`, Timer, Tween, or animation completion.
- No unresolved rule decision may live only in suspended coroutine control flow.
- No global gameplay RNG.
- No UI callback mutates authority directly.
- No mutable shared Resource holds per-run authority.
- No scene-tree order, dictionary incidental order, filesystem enumeration order, Object instance ID, or RID may decide gameplay.
- Sort semantically unordered collections before logic that depends on order.
- Use total deterministic tie-breaks with stable IDs.
- Avoid floating-point for money, score, counts, and integer-weighted decisions where integers suffice.
- Signals observe successful commits; they do not secretly mutate canonical state.
- Generated offers are authoritative state, not presentation output.
- Rejected transactions leave state unchanged.
- Accepted transactions run invariants before commit.
- Every pending decision can be serialized.
- Reserve effects never project as active.
- Card Upgrades never create a 49th physical card.
- AI retains the current public-information boundary.
- Telemetry, when added, observes committed immutable domain events and cannot feed back into rules.

---

# Architecture Review Gate for AI-Assisted Contributions

Before accepting generated code, verify:

- all authoritative mutation still passes through MatchController or RunController;
- no second copy of currency/card location/offer state/modifier placement was created;
- modifier IDs are not being special-cased throughout unrelated systems;
- no authoritative random call bypasses scoped RNG;
- UI is not calculating settlement, price, legality, or score;
- animation/timing does not determine game state;
- no unnecessary Autoload or broad `*Manager` layer was introduced;
- new abstractions solve a concrete current/imminent need;
- scoring/capture/pricing/eligibility logic is not duplicated;
- stable IDs are centralized and validated;
- invalid content fails loudly in tests;
- transactions cannot partially mutate canonical state;
- new authoritative fields are serialized/migrated or explicitly transient;
- effect hook/stage/priority/ownership is explicit;
- reserve modifiers cannot trigger;
- Card Upgrades preserve one physical card;
- AI gains no hidden information;
- player decisions are replayable actions;
- pending decisions survive save/load;
- core/run/modifier code does not import UI;
- required invariant/interaction tests accompany the behavior;
- the patch extends the current authoritative path instead of creating a parallel implementation.

The standing engineering rule is:

> **No new feature gets a private path around authoritative state.**

---

# Design Decisions Still Requiring Explicit Approval

Do not silently answer these while implementing architecture:

- reward model: three from the full pool vs one per family;
- Wider Choice's fourth slot/category under a family-quota reward model;
- Mulligan return/shuffle procedure;
- Second Draw behavior with one/no remaining draw cards;
- modifier duplicate/stacking policy;
- whether multiple Card Upgrades may stack on one physical card;
- whether Card Upgrade reward/shop targets are fixed during generation or player-selected;
- selected-reward behavior when both active and reserve storage are full;
- shop-purchase behavior when storage is full;
- exact resale formula/eligibility, including free reward modifiers;
- whether voluntary bankruptcy is allowed;
- game-rule behavior for legitimately conflicting replacement effects.

Architecture may expose explicit policy/configuration fields for these decisions. It may not choose the values.

---

# First Between-Month Acceptance Loop

The first complete implementation should allow this exact flow:

1. Play and finish January through the existing MatchController.
2. Produce a terminal MatchResult.
3. Submit RESOLVE_MONTH to RunController.
4. Resolve January settlement exactly once.
5. If required, enter authoritative liquidation without making bankroll negative.
6. Resolve debt or bankruptcy through legal run actions.
7. Unlock active carry slot #1.
8. Generate and persist the free reward set from a deterministic RewardRequest.
9. Choose one reward or take the configured cash refusal.
10. Resolve legal placement into active/reserve/pending-acquisition state.
11. Rearrange the build through RunActions.
12. Generate and persist the six-offer shop.
13. Buy, sell, reroll, inspect, compare, and rearrange without direct UI mutation.
14. Finalize the build.
15. Save/reload successfully from between-month states.
16. Reach a deterministic **Begin February** transition.
17. Stop at a February placeholder.

The acceptance pass must also prove:

- rejected run actions preserve the state hash;
- same root seed + action sequence reproduces the same run state;
- reward/shop generation is isolated from unrelated RNG calls;
- offer sets do not regenerate on UI reopen;
- all modifier instances have one legal authoritative location;
- reserve modifiers do not apply effects;
- the player can complete all major UI actions without required hover/drag;
- focus remains visible/predictable;
- no essential state relies on color alone;
- structural UI is not primarily hard-coded absolute positions;
- the player can explain where money changed, where a reward went, what is active/reserved, what a shop action costs, and what crosses into February.

---

# Development Order

Do not parallelize these systems blindly.

## Domain/architecture order

1. Document the run/match authority boundary, RunAction philosophy, phases, RNG scope model, and invariants.
2. Add RunState serialization, canonical hash, invariants, root seed, prototype configuration, and phases.
3. Add RunAction / RunActionResult / RunController with copy-validate-commit and replay journal.
4. Add MatchResult bridge and duplicate-settlement protection.
5. Implement settlement and PendingSettlement.
6. Implement authoritative liquidation/bankruptcy phase.
7. Implement carry capacity, modifier instance locations, and slot unlock.
8. Add ModifierDefinition / ModifierInstance / registry / handler validation.
9. Extend headless content validation.
10. Add deterministic RNG-scope derivation and offer-generation primitives.
11. Add RewardRequest / RewardState / deterministic reward generator supporting both unresolved reward policies.
12. Implement Wider Choice through RewardRequest transformation.
13. Implement reward select/refuse and legal acquisition placement state.
14. Implement MOVE_MODIFIER and carry-management transactions.
15. Add ShopState / ShopOffer / deterministic six-slot shop generator.
16. Implement BUY_OFFER / SELL_MODIFIER / REROLL_SHOP atomically.
17. Implement versioned JSON save v1 and migration harness.
18. Add deterministic DebugScenarioFactory and run-state inspector hooks.
19. Add the match-side modifier seams for capture/score/draw/opening/multiplier domains without implementing unresolved modifier behavior.
20. Expand run determinism, replay, save-continuation, and seed-sweep tests.

## UI order

The reusable Theme, focus policy, semantic controls, and PhaseShell may be developed once the corresponding state/action contracts are stable, but UI must not invent temporary domain rules to get ahead of them.

Then wire:

1. settlement/liquidation;
2. slot unlock/carry tray;
3. reward;
4. carry preparation;
5. shop;
6. finalization;
7. February placeholder.

Finally run end-to-end tests with:

- normal/fast/reduced motion;
- mouse;
- keyboard/controller focus path;
- save/reload at each major phase;
- pseudolocalization stress;
- deterministic replay.

---

# Things Not to Build Yet

Do not expand this milestone into:

- February gameplay;
- all twelve Moon effects;
- the full approved modifier catalogue;
- Cloudflare multiplayer backend;
- matchmaking/accounts;
- Steam networking;
- TypeScript duplicate rules engine;
- cross-language PRNG implementation;
- generic ability DSL;
- universal event/message bus;
- ECS;
- dependency-injection/service-locator framework;
- statechart plugin;
- database;
- generic item/inventory framework;
- modding/plugin SDK;
- full House Rules infrastructure;
- production cloud telemetry provider;
- analytics dashboard;
- cloud saves;
- save encryption/compression;
- replay-video viewer;
- sophisticated AI search;
- tutorial campaign;
- giant glossary/encyclopedia;
- separate Inventory / Loadout / Relics / Upgrades / Collection screens;
- touch-specific layout;
- rich 3D binder/card physics;
- multiple shop tabs;
- Moon-specific structural UI layouts;
- final art palette/material locking;
- predictive best-move/odds advice;
- heavyweight replacement card framework.

After the run loop is stable, useful next infrastructure includes a headless SimulationRunner, simple policy agents, and provider-neutral telemetry sinks. Those should consume the same controllers/actions, not create alternate rule paths.

The primary milestone question remains:

> Does finishing a hanafuda month and immediately making clear, tactile build/economy decisions in the same tabletop world create a compelling roguelike loop worth repeating across twelve Moons?

The technical acceptance question is equally important:

> Can the same run state be replayed, saved, loaded, tested, and eventually validated remotely without creating a second source of truth?

Do not expand into additional Moon gameplay until both answers are strong enough to justify more content.
