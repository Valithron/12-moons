# Between-Month Development Map

Status: Planning map only. Expand each section into a dedicated design/implementation spec before building it.

This document defines the next ordered development steps after the playable January match and initial card-motion pass. It incorporates the current UX research, deterministic run-architecture research, and production research for physicality, rendering, audio, and game feel while preserving the Game Design Authority as the source of truth for gameplay rules.

Research-derived architecture and UX recommendations in this document are implementation guidance. They must not silently resolve gameplay decisions that the Game Design Authority marks as WORKING, PROTOTYPE, UNRESOLVED, or contradictory.

## North-Star Milestone

Prove the first complete roguelike month loop around the existing hanafuda game:

`play January → settle money → unlock carry capacity → choose reward → prepare carry build → shop → finalize build → Begin February`

For this milestone, **Begin February may end at a clean placeholder**. Do not build February gameplay until the between-month loop itself is proven.

The milestone must prove three things at once:

1. the player-facing loop is clear, tactile, and feels like one continuous tabletop experience;
2. the run layer is deterministic, replayable, saveable, testable, and incapable of bypassing the existing authoritative match architecture; and
3. ordinary cards, scoring, rewards, carry movement, purchases, and transitions share one restrained material language whose presentation can be accelerated, cancelled, reduced, or skipped without changing authoritative outcomes.

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

# 3A. Production Presentation + Game-Feel Foundation

The production target is:

> **Compact rigid cards, decisive movement, controlled settling, material sound, localized emphasis, and almost no effect without a physical or informational cause.**

12 Moons should feel like a beautifully handled physical game whose interface occasionally becomes ceremonial. It should not feel like a functional card game covered in generic juice.

This foundation extends the existing semantic presentation queue and Tween-based card-motion work. Do not replace that architecture.

## Presentation authority contract

Presentation is downstream of committed state.

- Gameplay/state controllers decide what happened.
- Presentation events describe the semantic result, not Node coordinates.
- Presenters resolve semantic objects into scene positions, sounds, shaders, and motion.
- Animation completion never decides legality, settlement, ownership, score, bankroll, offer generation, or phase advancement.
- Presentation may lag behind already-committed authoritative state.
- Counters may animate a display value from immutable before/after snapshots, but the displayed interpolation never owns the economic value.
- Presentation randomness uses a separate cosmetic RNG and must never consume gameplay RNG.

Queue events should resemble:

```text
capture_resolved
yaku_resolved
settlement_stage
carry_slot_unlocked
reward_acquired
shop_purchase
shop_sale
shop_reroll
month_transition
```

They should not resemble low-level commands such as move-node-to-x/y.

As the queue grows, split behavior into narrow domain presenters rather than one enormous match statement:

```text
PresentationQueue
├── CardPresenter
├── ScorePresenter
├── DecisionPresenter
├── RewardPresenter
├── CarryPresenter
├── ShopPresenter
├── TransitionPresenter
└── AudioFeedbackPresenter
```

A small presentation-recipe model may support SEQUENCE, PARALLEL, and BARRIER semantics so related visual/audio operations can overlap intentionally without nested await chains becoming the architecture.

## MotionProfile

Create one reusable MotionProfile Resource or equivalent semantic token source.

Initial motion intents:

- HOVER
- PRESS
- MOVE_FAST
- MOVE_STANDARD
- MOVE_DRAMATIC
- IMPACT
- SETTLE
- REFLOW
- REVEAL
- MAJOR_REVEAL
- EXIT_FAST
- PHASE_TRANSITION

Do not allow new screens to choose arbitrary duration/easing combinations without a reason.

Motion character:

- hover: fast ease-out, no overshoot;
- press: immediate compression/down response;
- routine travel: quick acceleration and smooth deceleration;
- impact: sharp controlled arrival;
- settle: one tiny correction at most;
- reflow: smooth identity-preserving interpolation;
- major reveal: longer settle, not rubbery bounce;
- phase transition: smooth ease-in-out;
- universal TRANS_BACK-style overshoot is prohibited as a house style.

Prototype starting values may live in the profile and remain tunable. They are not design canon.

### Timing targets at 1280 × 720

Use these as production ranges, not immutable rules:

| Interaction | Normal target | First-time / dramatic ceiling |
|---|---:|---:|
| Hover in/out | ~70–140 ms | n/a |
| Press acknowledgment | ~60–100 ms | must acknowledge immediately |
| Play hand → field | ~140–220 ms | ~300 ms |
| Contact settle | ~40–80 ms | ~100 ms |
| Draw extraction | ~100–160 ms | n/a |
| Draw reveal / card flip | ~160–280 ms | ~350–400 ms |
| Hand reflow | ~120–220 ms | n/a |
| Capture sequence | ~300–450 ms | ~600 ms |
| Small yaku feedback | ~250–400 ms | n/a |
| Named yaku | ~350–700 ms | ~900 ms |
| Major Bright yaku | ~650–900 ms | ~1.2 s |
| Stop response | ~250–450 ms | n/a |
| Koi-Koi declaration | ~350–600 ms | ~800 ms |
| Settlement stage | ~200–400 ms | ~550 ms |
| Ordinary full settlement | ~1.8–3.0 s | ~4 s maximum |
| Reward entrance | ~300–500 ms | ~650 ms |
| Reward → owned slot | ~180–250 ms | ~350 ms |
| Purchase / sell | ~120–240 ms | n/a |
| Reroll | ~220–350 ms | ~450 ms |
| Carry-slot unlock | ~600–900 ms | ~1 s first reveal |
| Ordinary phase transition | ~250–450 ms | ~600 ms |
| Moon introduction | ~1.2–1.8 s | ~2 s first time |

The stricter rule is:

> **Direct input should visibly and/or audibly acknowledge on the next rendered frame whenever practical.**

Do not add anticipation delay before proving a click registered.

## Card height, shadow, and rigid physical language

Hanafuda cards should feel compact and rigid.

At rest:

- effectively zero rotation in organized hand/capture layouts;
- stable placement;
- no idle floating;
- tight shallow shadow.

During interaction:

- considered/hovered card rises;
- committed card travels decisively;
- travel rotation normally stays around ±1–2 degrees;
- brisk deal travel may reach about ±3 degrees if readability remains strong;
- settling returns to stable orientation;
- deformation is absent or nearly subliminal. Do not make cards squash like rubber.

Use a small visual-height vocabulary:

| State | Starting shadow character |
|---|---|
| Rest | tight ~1–2 px offset |
| Selected | ~3–4 px |
| Hovered | ~4–6 px |
| Traveling / dragged | ~6–10 px |
| Settling | contracts toward resting shadow |
| Locked slot | minimal/recessed |
| Elevated reward | stronger but still tight |

Implement height with simple CanvasItem-era techniques where possible. A predictable rectangular card does not need a bespoke blurred shader merely to imply elevation.

## Capture choreography

Capture is the everyday hero interaction. Refine it instead of adding spectacle.

Standard recipe:

1. **Target recognition:** ~70–120 ms local edge/shadow emphasis.
2. **Commit travel:** ~140–200 ms shallow authored path.
3. **Contact:** ~40–70 ms firm arrival with dry material transient.
4. **Relationship hold:** ~50–80 ms so the matched pair registers.
5. **Collection lift:** ~40–70 ms shared height increase.
6. **Capture travel:** ~140–220 ms toward captured-card region.
7. **Capture reflow:** ~100–160 ms.
8. **Yaku feedback:** only after card identity/relationship is readable.

Normal capture uses:

- no camera shake;
- no generic particles;
- no magical trail;
- no repeated bounce.

An accelerated mode may collapse recognition/hold and overlap collection travel while preserving comprehensibility.

## Deal, draw, and reflow

Do not force 24 isolated serialized deal ceremonies.

Use overlapping waves from a visible deck origin:

- player hand;
- field;
- AI hand;
- remaining stack settles as draw pile.

Individual cards may travel quickly with modest stagger so the whole opening deal lands in roughly the ~0.7–1.1 s range when practical.

Monthly deals after January must be fast-forwardable.

Draw and hand-play should remain visually distinct:

- draw: sharp extraction → reveal → outcome;
- hand play: deliberate player commitment → contact/outcome.

Hand reflow rules:

- preserve stable card identity;
- interpolate from the card's current visual transform;
- do not rebuild/jump objects to newly computed slots;
- do not randomize hand angles;
- do not continuously resort;
- hover must not trigger full-hand movement;
- selected/hovered cards may elevate in z-order;
- defer nonessential resorting while input is active;
- interrupted reflow starts from the current visual position, not an obsolete animation origin.

## Yaku and Stop / Koi-Koi intensity

Use a feedback ceiling according to consequence.

| Intent | Examples | Typical treatment |
|---|---|---|
| Rest | passive board | ambience only |
| Acknowledge | focus, hover, press | ≤120 ms, tiny motion/sound |
| Resolve | play, draw, capture, purchase | 120–450 ms, material motion/sound |
| Reward | named yaku, modifier trigger, reward acquired | 300–700 ms, localized accent |
| Milestone | Koi-Koi, slot unlock, month victory | 500–1200 ms, short stinger/sparse accent |
| Landmark | season boundary, December completion | ~1–2.5 s, strongest coordinated treatment |

A level is a ceiling, not an instruction to fire every channel.

For yaku:

- incremental Kasu/Ribbon/Seed progress stays quiet;
- threshold increases get compact confirmation;
- named yaku may lift related cards and show a recognizable tonal motif;
- Bright/major yaku receive stronger local framing;
- simultaneous yaku should form one coherent grouped presentation rather than replaying full ceremony repeatedly.

For Stop/Koi-Koi:

- finish yaku presentation first;
- brief ~100–150 ms hold;
- reduce board contrast only modestly;
- keep the table readable;
- Stop sounds conclusive and immediately leads toward settlement;
- Koi-Koi gets a short stamp/calligraphic identity and restrained stinger;
- post-Koi tension should come from persistent state, not bigger explosions on every action.

## Presentation cancellation, speed, and reduced motion

Cancellation is a first-class outcome.

Required cases:

- restart;
- leave scene;
- skip ceremony;
- reduced motion;
- debug fast-forward;
- phase teardown.

Use a presentation generation/epoch or equivalent cancellation token.

Cancellation must:

- kill tracked Tweens/AnimationPlayers safely;
- clear presentation input locks;
- restore required final visual state;
- invalidate stale async continuations;
- never require an animation-completion callback to keep gameplay progressing.

Every presentation recipe supports conceptual modes:

- NORMAL
- FAST
- INSTANT

INSTANT sets the correct final visual state synchronously. It must not use a different gameplay path.

Settings direction:

```text
Animation Speed
  Normal
  Fast
  Instant

Reduced Motion
  Off
  On
```

Reduced motion should remove camera impulses, parallax drift, decorative tilt, long arcs, spring/overshoot, nonessential particles, and large sliding-screen transitions while preserving state highlights, ownership, destination, and causal order.

## Audio foundation

Establish internal buses:

```text
Master
├── Music
├── SFX
├── UI
└── Ambience
```

Player settings initially need at least Master, Music, SFX, and Ambience once ambience is substantial. UI may remain grouped under SFX in user-facing settings while retaining its internal bus.

Audio communicates **material first, semantic importance second**.

Initial SFX families:

- card pickup/lift;
- card slide/deal;
- card placement/contact;
- card flip;
- capture/collect;
- UI press;
- invalid;
- tray/slot mechanism;
- economy/ledger;
- yaku motif family;
- Koi-Koi identity;
- Stop/closure;
- reward reveal/acquire;
- phase/Moon cues.

Repeated card families need several samples because they will be heard constantly. Start around 3–5 useful variants for common physical actions, with subtle cosmetic pitch/level variation. Tonal motifs should vary little or not at all.

Important interactions may layer a physical sound with one or two semantic layers:

- capture = card movement + dry contact + very quiet tonal confirmation;
- slot unlock = latch + frame/tray material + restrained tonal bloom;
- reward acquisition = object movement + destination seating + short confirm;
- purchase = owned-object movement + ledger debit;
- Koi-Koi = stamp/declaration transient + lower tonal body + optional later music stinger.

Avoid casino coin showers, stock fantasy chimes, loud confirmation on every button, wide random pitch, or five-plus layers on routine actions.

**Audio variation must never consume gameplay RNG.**

Do not build sophisticated adaptive music yet. Initial music structure may remain:

- ordinary match;
- between-month/reward/shop;
- Koi-Koi stinger;
- major result stinger;
- Moon transition cue.

A post-Koi tension stem can be evaluated later after baseline music/SFX exist.

## Rendering and VFX policy

The Compatibility renderer remains the target. Production polish should be built around robust 2D techniques first.

Core techniques:

- CanvasItem transforms/modulate;
- prepared textures;
- local CanvasItem shaders;
- parameterized outlines/tints/masks;
- restrained alpha/additive local effects;
- simple sparse particles when materially justified.

Do not make ordinary presentation depend on:

- Forward+-specific features;
- compute effects;
- stacked full-screen post-processing;
- routine screen-reading shaders;
- multiple SubViewports;
- heavy dynamic 2D lighting.

VFX must answer at least one question:

1. What can I interact with?
2. What state just changed?
3. Why was this event more important than an ordinary one?

Useful reusable VFX categories:

- TARGET_LEGAL
- TARGET_SELECTED
- MODIFIER_READY
- MODIFIER_ACTIVATE
- SLOT_UNLOCK
- REWARD_ACQUIRED
- YAKU_MAJOR
- MONTH_TRANSITION

Routine capture, purchase, placement, reflow, and basic scoring should normally need no particles.

If a localized burst is justified, begin with only a handful of visible material-looking elements rather than hundreds of glow sprites.

## Tiny shader library

Prefer about 3–5 parameterized shaders rather than one shader per feature.

Initial candidates:

- `card_state`: legal/selected/locked/desaturated/highlight state;
- `modifier_sheen`: only if final material art direction justifies a lacquer/foil highlight;
- `mask_reveal`: slot seal/reveal and selected transition wipes;
- `focus_overlay`: controlled dim/focus without normal screen-read blur;
- optional `season_tint`: environment only, never card-face identification.

Rule:

> **If the effect describes changing pixel state, consider a shader. If it describes permanent material detail, bake it. If transform/opacity solves it, do not write a shader.**

## Card image and import strategy

Card art is the asset category where high-quality source masters are justified.

Direction:

- retain high-resolution editable masters;
- runtime exports should remain large enough for the maximum 4K hover/reward display actually used;
- use linear filtering for illustrated non-pixel-art cards;
- use mipmaps when cards spend substantial time minified or rotated;
- use conservative/lossless or visually lossless treatment for final card faces;
- inspect smallest capture rendering for line loss;
- inspect hover scale for softness;
- inspect 4K independently.

Do not prematurely build an atlas pipeline for only 48 traditional cards. Start with clean individual assets/resource abstraction and atlas only after profiling proves value.

## MonthPresentationProfile

Do not build twelve bespoke boards.

Establish a data-driven month presentation profile now so February proves the year can scale through data/assets rather than scene proliferation.

A month profile should be able to reference:

- month ID;
- Moon name;
- one-line rule summary;
- background/environment layer;
- seasonal overlay;
- foreground accent;
- optional ambient scene;
- ambience stream;
- intro cue/stinger;
- environment tint/palette data;
- transition duration/profile.

Reusable composition model:

```text
base table/world
+ distant environment
+ seasonal large-form layer
+ month-specific props
+ foreground accent
+ optional sparse ambience/particles
+ palette/light profile
+ audio ambience profile
+ Moon title/rule treatment
```

High-value production order:

1. palette/background lighting;
2. reusable seasonal environment layers;
3. small month props/vegetation;
4. ambience;
5. sparse seasonal particles only where justified.

The Moon name must not force literal weather that implies nonexistent gameplay.

Moon intro grammar:

```text
environment settles
→ Moon name
→ one-line rule
→ opponent identifier if needed
→ short cue
→ player may proceed
```

Use one authored template, not twelve mini-cinematics.

## Asset-production discipline

Keep editable source material distinct from runtime Godot exports.

A maintainable production organization should separate:

- source card/modifier/background/UI art;
- runtime card/modifier/UI/background assets;
- SFX/music/ambience;
- shaders;
- presentation resources;
- licenses/provenance.

For externally sourced or AI-assisted assets, track:

- source;
- license/rights;
- generation method where relevant;
- human revision status;
- final approval.

Production path:

```text
generation/reference
→ human selection
→ deliberate editing
→ palette/material consistency pass
→ technical export
→ in-game inspection
→ approved runtime asset
```

Never use prompt-output-as-final-asset as the pipeline.

## Performance and profiling targets

60 FPS gives 16.67 ms total frame time. The goal is meaningful headroom on modest integrated graphics.

Internal regression targets:

- representative CPU/GPU frame work preferably remains below roughly 8–10 ms each on the chosen modest reference machine;
- ordinary turns usually move no more than the causal card cluster;
- deal may move the full dealt group because input is not active;
- routine particles are zero or near zero;
- hero bursts use dozens at most, not hundreds/thousands;
- no extra rendered SubViewports in ordinary play;
- no full-screen screen-read passes in ordinary play;
- keep full-screen transparent layers few/simple;
- monitor texture memory aggressively, especially for 4K layers.

A single uncompressed 3840×2160 RGBA8 image is roughly 31.6 MiB before overhead. Do not casually stack unique 4K backgrounds, masks, render targets, and copies.

Maintain stable profiling scenarios:

- idle January board;
- opening deal;
- ordinary play;
- capture;
- capture + yaku;
- Stop/Koi-Koi;
- largest settlement;
- reward reveal;
- carry rearrangement;
- shop reroll;
- Moon transition.

For each major polish system:

1. record baseline;
2. add the system;
3. repeat the same scenarios;
4. investigate large regressions that do not buy equivalent player value;
5. test 720p and at least one higher-resolution configuration;
6. test actual modest integrated graphics.

## Production anti-slop gates

Reject or justify any new presentation that does the following:

- same ease for every object/action;
- scale-from-zero as generic entrance;
- overshoot/bounce after routine placement;
- constant idle floating;
- random card rotation on every move;
- unrelated UI sliding from arbitrary directions;
- camera zoom for every meaningful event;
- giant scale pulses instead of local height/shadow/grouping;
- unrelated simultaneous motion;
- delayed response after click;
- slow serialized 24-card deal;
- permanent reward hovering;
- UI reflow under the pointer;
- motion with no meaningful origin/destination;
- glow around every interactable;
- neon/rainbow rarity vocabulary;
- particles on routine reward/capture;
- trails behind ordinary cards;
- full-screen flash/blur for ordinary state changes;
- unique shader/animation per modifier;
- generic casino economy audio;
- identical click everywhere;
- loud semantic confirmation on every action.

The production rule is:

> **Resting objects should actually rest. Motion should explain causality, ownership, attention, or consequence.**

**Production status:** implementation direction from research. Exact durations, shadow offsets, asset resolution, mix levels, and particle counts remain tunable production values rather than gameplay canon.

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

Approved prototype resale rule: purchased modifiers sell for 50% of actual purchase price, rounded down; free reward modifiers sell for 50% of normal base shop value, rounded down.

## Settlement production choreography

Settlement should explain causality rather than behave like a slot-machine counter.

Recommended presentation sequence:

```text
resolved yaku
→ additive subtotal
→ Moon/additive adjustment if applicable
→ 7+ multiplier if applicable
→ Koi-Koi multiplier if applicable
→ final resolved score
→ currency delta
→ bankroll
```

Skip inapplicable stages.

Presentation rules:

- keep the table/world visible;
- settlement sheet/tray enters in roughly ~250–350 ms;
- relevant captured cards may briefly gather/highlight before a scoring row resolves;
- reveal arithmetic in causal order;
- final score gets the strongest settlement landing;
- animate bankroll as old value → signed delta → new value over roughly ~250–400 ms;
- do not tick once per currency unit;
- ordinary settlement should usually complete within roughly ~1.8–3.0 s and remain accelerable/skippable;
- the authoritative bankroll may already be committed before the display animation finishes;
- skip/instant mode must land on exactly the same visible final values.

**Authority status:** economy sequence follows the approved prototype baseline. Resale handling is approved for this prototype; broader economy tuning remains provisional where the Game Design Authority says so.

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

If a chosen reward cannot immediately fit because both active and reserve storage are full, the player must replace one owned modifier: select an owned modifier to sell at its normal resale value, then place the new reward into the freed authoritative position. The player may instead refuse the reward for the normal +2 currency. A transient authoritative pending-replacement state is acceptable while that choice is unresolved, but it is not extra storage and the run cannot proceed as though both modifiers are legally stored.

## Presentation

- carry and bankroll remain visible;
- modifiers do not visually masquerade as hanafuda;
- offer copy is concise/mechanical first;
- full detail is available through focus/inspect;
- cash refusal is explicit;
- target selection uses the same stable legal-target grammar as gameplay;
- acquisition visibly moves to its authoritative destination only after commit.

Production choreography:

- locked carry positions are already visible before the unlock;
- first slot unlock uses a physical latch/seal/frame-opening grammar in roughly ~600–900 ms;
- later monthly unlocks reuse the grammar but may be faster;
- reward offers arrive mostly face-up, with ~60–90 ms stagger and all options readable within roughly ~400–500 ms;
- avoid loot-box suspense, rarity beams, prolonged face-down reveals, and escalating gacha sounds;
- selection acknowledges immediately with lift/shadow;
- after commit, the actual reward representation travels to the authoritative carry/reserve destination in roughly ~180–250 ms;
- object travel teaches ownership and should replace redundant “added to inventory” ceremony;
- slot unlock may use one restrained glint/material accent, not a particle storm.

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

Production choreography:

- entering shop reframes/slides stock into the established offer region while carry/economy anchors remain fixed;
- purchase acknowledges immediately, then offer/object travels toward owned space in roughly ~120–220 ms while the displayed bankroll debits;
- sell uses the reverse physical relationship in roughly ~140–240 ms;
- insufficient funds emphasizes the price/affordance only with a constrained ~120–180 ms nudge/pulse and dry invalid sound;
- reroll removes/replaces offers coherently in their existing slots in roughly ~220–350 ms;
- do not use slot-reel spins, fake cycling through dozens of possibilities, coin showers, or full-screen purchase effects;
- repeated shopping should remain faster and quieter than reward acquisition, slot unlock, or month completion.

**Authority status:** shop direction follows the approved prototype baseline. Exact prices, rarity, and special/service inventory remain configurable where the Game Design Authority says so; resale and full-storage purchase behavior are approved for this prototype.

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
- pending reward replacement/acquisition decision if one is unresolved;
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

## February transition production contract

Finalization should retract/settle interactive preparation layers rather than hard-cut to an unrelated screen.

Then:

- stable foreground framing remains readable;
- environment/month layer transitions behind it;
- February uses the MonthPresentationProfile system rather than a bespoke scene architecture;
- Moon name + concise rule are the primary information;
- standard Moon intro target is roughly ~1.2–1.8 s and must be accelerable/skippable;
- Fast target is roughly ~0.6–1.0 s;
- reduced-motion mode substitutes fades/local changes for large parallax/sliding movement;
- February should look and sound distinct through palette/environment/ambience/profile data without implying unapproved Snow Moon gameplay.

---

# Cross-Cutting Production Rules

These presentation rules apply to January cleanup and every between-month phase.

## Causal motion

- one causal cluster moves at a time during ordinary play;
- deal is the main mass-motion exception because input is not expected;
- selection remains stable while input is expected;
- hover must not cause resort/reflow under the pointer;
- effects stay behind or outside identity-bearing hanafuda art;
- every movement needs a meaningful origin, destination, ownership change, attention change, or state cause;
- ordinary objects rest when nothing is happening.

## Camera/framing

Default camera is effectively fixed.

- hover/play/capture: no camera movement;
- ordinary yaku: no camera movement;
- major yaku or Koi-Koi: optional ~1–2% controlled push at most;
- settlement: layout reframe rather than shake;
- slot unlock: optional tiny local impulse;
- Moon intro: controlled environmental reframe;
- December/run completion later receives the strongest framing.

If any camera impulse is used, start extremely small and test downward. Reduced-motion mode disables it.

## Material hierarchy

Hanafuda:
- rigid printed/lacquered card stock;
- firm short transient;
- restrained highlight.

Carry:
- tray/sleeve/frame;
- object visibly seats into destination.

Modifier:
- distinct object family from hanafuda;
- may support slightly richer material treatment if art direction justifies it.

Currency:
- ledger/chit/token metaphor;
- avoid casino money spectacle.

Locked capability:
- seal/latch/closed frame;
- unlock animation has a physical cause.

Month/environment:
- world/background layer;
- must not glow as though it were UI.

## Screenshot/trailer readability

At any hero frame, a viewer should quickly read:

- player's hand;
- field;
- interacting cards;
- captured-card regions;
- important score/state;
- current phase.

Natural hero frames include:

- starting-player reveal;
- major named/Bright yaku;
- Koi-Koi;
- comprehensible large settlement;
- first carry slot opening;
- chosen reward entering its slot;
- mature carry build;
- seasonal/month transition;
- December resolution later.

Do not add mechanics merely to manufacture trailer moments.

Major presentations should often hold their composed end-state for roughly ~200–400 ms so they remain legible in recorded footage.

## Audio mix hierarchy

- hover/focus is quiet or silent;
- card contact sits above UI acknowledgment;
- scoring/Koi-Koi sit above routine card transients only when significance warrants it;
- ambience sits below music;
- music leaves headroom for card transients;
- limiter is a safety layer, not a substitute for mix discipline.

## Rendering discipline

Compatibility-first means:

- local effects before full-screen effects;
- prepared texture/material detail before procedural shader detail;
- no effect may obscure card identity;
- screen-read/full-screen effects require explicit measured justification;
- shader count remains intentionally small;
- profiling decides optimization, not intuition.

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

# Approved Between-Month Policy Decisions

The following prototype rules were explicitly approved on 2026-09-18 and are now canonical for this milestone:

- **Reward generation:** after each month, generate **3 offers from the full eligible modifier pool** with no requirement to include one modifier from each family. Wider Choice changes this to **4 offers from the same full pool**.
- **Duplicate modifiers:** Hand/Mechanic and Strategic/Meta modifier definitions cannot be owned in duplicate by default unless explicitly authored as stackable. Card Upgrade types may recur on different physical hanafuda cards, but the same Card Upgrade cannot stack multiple copies on the same physical card unless explicitly authored to allow it.
- **Full-storage reward:** if active carry and reserve are both full, claiming a selected free reward requires replacing one owned modifier. Sell the chosen modifier at normal resale value and place the reward into the freed position. The player may instead refuse the reward for the normal +2 currency. Do not create overflow inventory.
- **Full-storage shop purchase:** block the purchase until the player creates legal storage space, normally by selling an owned modifier. Do not auto-replace and do not create a pending-purchase inventory.
- **Resale:** purchased modifiers sell for **50% of actual purchase price, rounded down**. Free reward modifiers sell for **50% of normal base shop value, rounded down**.

These decisions resolve the former reward-family policy conflict and make a family-quota-specific Wider Choice rule unnecessary.

# Design Decisions Still Requiring Explicit Approval

Do not silently answer these while implementing architecture:

- whether multiple **different** Card Upgrades may stack on one physical hanafuda card;
- whether Card Upgrade reward/shop targets are fixed during generation or player-selected;
- exact Mulligan return/shuffle semantics;
- Second Draw behavior when one or zero draw cards remain;
- whether voluntary bankruptcy is allowed;
- game-rule behavior for legitimately conflicting replacement effects.

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
10. Resolve legal placement into active/reserve state; if both are full, resolve the approved replace-and-sell choice or reward refusal before proceeding.
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
- the player can explain where money changed, where a reward went, what is active/reserved, what a shop action costs, and what crosses into February;
- direct input always acknowledges immediately even when consequence presentation continues;
- ordinary capture remains readable before cards leave the field and does not require particles/camera shake;
- settlement visually reconstructs the arithmetic and bankroll change without per-unit slot-machine counting;
- reward selection visibly becomes ownership by traveling to its committed destination;
- purchase/sell/reroll remain fast enough for repeated strategic comparison;
- NORMAL, FAST, and INSTANT presentation modes converge on the same final visible state;
- reduced-motion mode preserves all strategic information without camera impulse, parallax dependence, or unnecessary particles;
- presentation cancellation/restart cannot deadlock input or game progression;
- no presentation or cosmetic RNG call changes authoritative hashes, offers, decks, or results;
- the milestone passes the defined Compatibility-renderer profiling scenarios without introducing unjustified full-screen passes or major frame-time/memory regressions.

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
11. Add RewardRequest / RewardState / deterministic reward generator using the approved full-eligible-pool policy.
12. Implement Wider Choice through RewardRequest transformation.
13. Implement reward select/refuse and legal acquisition placement state.
14. Implement MOVE_MODIFIER and carry-management transactions.
15. Add ShopState / ShopOffer / deterministic six-slot shop generator.
16. Implement BUY_OFFER / SELL_MODIFIER / REROLL_SHOP atomically.
17. Implement versioned JSON save v1 and migration harness.
18. Add deterministic DebugScenarioFactory and run-state inspector hooks.
19. Add the match-side modifier seams for capture/score/draw/opening/multiplier domains without implementing unresolved modifier behavior.
20. Expand run determinism, replay, save-continuation, and seed-sweep tests.

## Production/presentation order

Presentation infrastructure may proceed alongside domain work where the authority boundary is already stable.

1. Add/normalize MotionProfile semantic tokens and remove arbitrary new easing/duration literals.
2. Add NORMAL / FAST / INSTANT execution plus explicit cancellation/epoch handling to presentation primitives.
3. Establish card height/shadow states and immediate press/hover acknowledgment.
4. Refine ordinary play/draw/reflow and the standard capture recipe.
5. Establish audio buses, semantic cue IDs, and the first repeated card SFX families.
6. Split presentation behavior into domain presenters as queue complexity grows.
7. Add the tiny shared card-state/focus shader set only where transforms/theme cannot express the state.
8. Add settlement staging and ledger/audio feedback.
9. Add carry-slot unlock + reward-to-owned spatial continuity.
10. Add purchase/sell/reroll material/audio feedback.
11. Add MonthPresentationProfile and prove January→February environmental transition.
12. Establish stable profiling scenarios and test 720p plus a higher-resolution configuration on modest hardware.
13. Add asset provenance/approval discipline before seasonal content production scales.

Do not wait until after all UI is built to retrofit speed modes, reduced motion, cancellation, SFX families, or month-presentation data. Those are presentation architecture.

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
- heavyweight replacement card framework;
- simulated rigid-body card physics;
- full-screen blur/post-processing pipeline;
- stacked screen-read shaders;
- twelve bespoke board scenes;
- dynamic 2D lighting for every card;
- a cinematic camera framework;
- generic particle-editor abstraction;
- unique VFX/animation timeline per modifier;
- animated rarity borders or loot-box reward reveals;
- multi-stem adaptive soundtrack;
- complex haptics;
- procedural paper fibers/wear systems;
- runtime normal-map generation;
- multiple render-to-texture compositing stages;
- rare December hero effects before the repeated January→February interactions are excellent.

After the run loop is stable, useful next infrastructure includes a headless SimulationRunner, simple policy agents, and provider-neutral telemetry sinks. Those should consume the same controllers/actions, not create alternate rule paths.

The primary milestone question remains:

> Does finishing a hanafuda month and immediately making clear, tactile build/economy decisions in the same tabletop world create a compelling roguelike loop worth repeating across twelve Moons?

The technical acceptance question is equally important:

> Can the same run state be replayed, saved, loaded, tested, and eventually validated remotely without creating a second source of truth?

A third production acceptance question now applies:

> **From the last January card through the first February screen, does the player always understand what happened, what changed, what they earned, where it went, what they bought, what they now own, and where they are in the year without the game relying on generic spectacle?**

Do not expand into additional Moon gameplay until all three answers are strong enough to justify more content.

The eventual full-game production standard is:

> **Ordinary cards feel physical enough that VFX is unnecessary; important consequences are staged clearly enough that spectacle is optional; and rare spectacle remains memorable because the rest of 12 Moons knows how to be quiet.**
