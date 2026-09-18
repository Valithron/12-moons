# 12 Moons: Deterministic Run Architecture, Modifier Framework, Run Economy, Testing, and Development Infrastructure

## Architecture and immediate milestone

**Executive Technical Recommendation**

The strongest architecture is **not** to enlarge the existing `GameState` until it becomes a twelve-month god object. The current January engine already has the most valuable properties a turn-based roguelike can possess: stable physical card IDs, a single mutation gateway, explicit legal actions, copy-before-commit validation, state hashing, replay logging, public-information projection, and strong card-conservation invariants. The repository's `MatchController.submit_action()` already clones `GameState`, applies the proposed action to the candidate, checks invariants, and commits only on success. That pattern should become the architectural template for the run layer rather than being replaced. fileciteturn11file0L2-L2 fileciteturn10file0L2-L2

The recommended structure is:

```text
                         ┌─────────────────────────────┐
                         │     RunSession / Scene      │
                         │ lifecycle + presentation    │
                         │         only                │
                         └──────────────┬──────────────┘
                                        │
                      ┌─────────────────┴─────────────────┐
                      │                                   │
              ┌───────▼────────┐                  ┌───────▼────────┐
              │ RunController  │                  │MatchController │
              │ sole run-layer │                  │sole match-layer│
              │ mutation gate  │                  │ mutation gate  │
              └───────┬────────┘                  └───────┬────────┘
                      │                                   │
              ┌───────▼────────┐                  ┌───────▼────────┐
              │    RunState    │                  │   GameState    │
              │ persistent year│                  │ conceptual     │
              │ state          │                  │ MatchState     │
              └───────┬────────┘                  └───────┬────────┘
                      │                                   │
        ┌─────────────┼──────────────┐          ┌─────────┼──────────┐
        │             │              │          │         │          │
     Carry/        RewardState    ShopState   Matching   Scoring   Draw/Turn
   Modifiers                                  Rules      Rules     Rules
        │             │              │          │         │          │
        └─────────────┴──────┬───────┘          └─────────┴────┬─────┘
                             │                                 │
                       Effect / Rule Resolution Pipelines
                             │
        ┌────────────────────┼─────────────────────────┐
        │                    │                         │
     Moon rules        card-owned effects       player-owned effects
                                                   │
                                                   ▼
                              deterministic EffectOperations
                                                   │
                                                   ▼
                                    controller validates + commits
```

The authoritative division should be:

| Concern | Authority | Representation |
|---|---|---|
| Currency, month, carry capacities | `RunState` | Plain deterministic data |
| Owned modifier instances | `RunState` | Stable instance IDs |
| Active/reserve placement | `RunState` | Explicit authoritative location |
| Card Upgrade attachments | `RunState` | `modifier_instance_id → card_id` |
| Current rewards | `RewardState` inside `RunState` | Generated offers, never UI-derived |
| Current shop | `ShopState` inside `RunState` | Generated persistent offers |
| Pending settlement/liquidation | `RunState` | Explicit phase state |
| Match cards/hands/field/draw pile | existing `GameState` | Current deterministic match model |
| Match mutation | existing `MatchController` | Action-driven |
| Run mutation | new `RunController` | Action-driven |
| Modifier definitions | immutable content registry | JSON + typed GDScript definitions |
| Modifier implementations | GDScript handler registry | Preloaded executable handlers |
| Per-month modifier charges | match runtime state | Keyed by modifier instance |
| Root run seed | `RunState` | Persistent integer |
| Deck/reward/shop random generation | derived deterministic RNG scopes | Local `RandomNumberGenerator`s |
| Save data | `SaveEnvelope` | Explicit versioned JSON |
| Scene/UI state | Nodes | Non-authoritative |
| VFX/animation RNG | presentation only | Separate RNG entirely |

Runtime state and controllers should remain `RefCounted`, following the existing project. A Godot `Resource` is also reference-counted, but resources loaded from the same path are cached and subsequent loads normally return the same reference; that is useful for immutable authored definitions but undesirable for per-run mutable authority because accidental mutation can become shared mutation. citeturn13view3 citeturn13view4

`ShopState` and `RewardState` should exist, but **not** as separate `ShopController`, `RewardController`, `CarryManager`, `EconomyManager`, `ModifierManager`, and so forth. For this project's scale, those would fracture one coherent state machine into a forest of mutation owners. `RunController` should delegate calculations to small pure helpers—`RewardGenerator`, `ShopGenerator`, `EffectRegistry`, `SettlementRules`—while remaining the only entity allowed to mutate `RunState`.

Likewise, the existing `GameState` is conceptually a `MatchState`, but I would **not rename it during the January-to-February milestone unless the rename is essentially free**. Its current scope is already match-specific: deck, field, players, match phase, pending card resolution, Koi-Koi state, and terminal result. Its `canonical_dict()`, explicit serialization and SHA-256 hash are strong infrastructure worth preserving. fileciteturn9file0L2-L2 fileciteturn13file0L2-L2

The match should also be a **logical child of the run, not the same mutable object nested under two controllers**. While January is active:

```text
RunState
  phase = MONTH_MATCH
  month = 1
  root_seed = ...
  persistent build = ...

MatchController
  state = GameState/MatchState for January
```

A session-level Node may hold references to both controllers. A save envelope may contain both state snapshots. But `RunController` must not mutate the live `GameState`, and `MatchController` must not mutate bankroll or carry data.

When January finishes, create a small immutable-style boundary object:

```text
MatchResult
  match_id
  month
  winner
  resolved_score
  end_reason
  final_match_state_hash
```

The session then submits something equivalent to:

```text
RunAction.RESOLVE_MONTH(match_result)
```

to `RunController`. The UI does **not** execute:

```gdscript
run_state.currency += score
```

and does not calculate the settlement itself. This directly extends the repository's existing rule that `MatchController` is the authoritative match mutation gateway. fileciteturn11file0L2-L2

February eventually starts in the opposite direction:

```text
RunState
    ↓ derive deterministic MatchStartConfig
MatchStartConfig
  month = 2
  match_seed
  moon_id
  active player modifiers
  active card attachments
    ↓
MatchController / February setup
```

The current milestone stops at a February placeholder.

**Immediate January-to-February Architecture**

The smallest safe milestone is narrower than the final architecture.

| Build now | Put a hook in now | Defer |
|---|---|---|
| `RunState` | Match modifier-resolution contexts | February gameplay |
| `RunAction` | Moon effects as future rule sources | Full twelve-month content |
| `RunController` | AI-readable modifier metadata | Multiplayer backend |
| Run phases | Telemetry sink interface | Cloud analytics |
| Settlement | Effect trace instrumentation point | Sophisticated AI |
| Liquidation state | Save migration chain | Generic ability language |
| Slot unlocking | Cross-language action schema discipline | TypeScript rules port |
| Carry active/reserve model | Debug scenario factory | Modding SDK |
| Modifier Definition/Instance model | Simulation runner entry point | Statechart plugin |
| Reward generator | Replacement/addition priority framework | Generic inventory |
| Shop state/generator/transactions | Match hooks for six representative effects | Custom PRNG unless needed |
| Save v1 | Run journal/replay extensibility | Full replay viewer |
| Content validators | Null/local telemetry sink | Production economy balance |
| Between-month UI | RNG scope inspector | All approved modifiers |
| February placeholder | Headless simulation policy interface | House Rules system |

The immediate authoritative flow should be:

```text
January reaches GameState.PHASE_MONTH_COMPLETE
        ↓
MatchResult created from terminal authoritative state
        ↓
RunController.RESOLVE_MONTH
        ↓
settlement
   ┌────┴─────────────────────┐
   │ enough money             │ insufficient money
   ↓                          ↓
slot unlock              LIQUIDATION phase
   │                          │
   │                     sale actions
   │                          ↓
   │                    debt satisfied?
   │                    yes / no possible sales
   │                     ↓          ↓
   └──────────────────► REWARD   BANKRUPT
                           ↓
                      choose/refuse
                           ↓
                   CARRY_MANAGEMENT
                           ↓
                         SHOP
                           ↓
                    FINALIZE_BUILD
                           ↓
                FEBRUARY_PLACEHOLDER
```

The current project already has a headless validation entry point that checks the 48-card manifest, asset mappings and January state, and its README describes a validation process that includes headless UI flow and GdUnit4. Extending that existing path is preferable to introducing another unrelated build/test toolchain. fileciteturn14file0L2-L2 fileciteturn11file0L2-L2

The match-side effect implementations for Sweep, Mulligan, Second Draw, Quad Koi and Chaff Point **do not need to be wired into February gameplay for this milestone**. What does need to be locked is where they will enter the rules engine. Wider Choice is the one representative effect worth implementing end-to-end immediately because it acts directly on the reward system being built.

**Run-State Model**

A practical `RunState` can remain plain and explicit:

```gdscript
class_name RunState
extends RefCounted

const PHASE_MONTH_MATCH := &"month_match"
const PHASE_LIQUIDATION := &"liquidation"
const PHASE_REWARD := &"reward"
const PHASE_CARRY := &"carry"
const PHASE_SHOP := &"shop"
const PHASE_FINALIZE := &"finalize"
const PHASE_TRANSITION := &"transition"
const PHASE_COMPLETE := &"complete"
const PHASE_BANKRUPT := &"bankrupt"

var root_seed: int
var month: int = 1
var phase: StringName = PHASE_MONTH_MATCH

var currency: int = 20

var unlocked_active_slots: int = 0
var reserve_capacity: int = 4

var modifier_instances: Array[ModifierInstance] = []
var active_modifier_ids: Array[String] = []
var reserve_modifier_ids: Array[String] = []

var reward_state: RewardState
var shop_state: ShopState
var pending_settlement: PendingSettlement

var settled_match_ids: Array[String] = []

# Incremented only by authoritative generation events.
var reward_sequence: int = 0
var shop_sequence: int = 0
```

The literal values `20` and `4` should ultimately come from a small `run_rules.json` or equivalent prototype configuration rather than being spread through code. They are design values under test, not structural constants.

`RunState` needs the same disciplines already present in `GameState`:

```text
to_dict()
from_dict()
canonical_dict()
canonical_json()
state_hash()
invariant_errors()
invariants_ok()
```

The existing `GameState` already demonstrates explicit serialization and canonical hashing, and its invariant checker verifies that all 48 physical cards remain represented exactly once among authoritative zones. fileciteturn9file0L2-L2 fileciteturn13file0L2-L2

Run invariants should include:

```text
currency >= 0

1 <= month <= 12

every modifier_instance_id is unique

every owned modifier exists in exactly one valid authoritative location
  active
  reserve
  card attachment
  or an explicitly defined temporary pending-acquisition state

active_count <= unlocked_active_slots
reserve_count <= reserve_capacity

reserve modifiers never appear in active effect projections

each card attachment references a real one of the 48 card IDs

each modifier definition ID resolves

reward_state exists iff the current phase needs it

shop_state exists iff the current phase needs it

pending_settlement exists iff liquidation is active

a match_result_id cannot be settled twice

shop offer IDs are unique

a purchased shop offer is marked consumed exactly once
```

Use persistent **string identifiers** for serialized action/phase/content IDs. Numeric GDScript enums are convenient internally but become fragile persistent identifiers if later reordered.

A corresponding controller should deliberately resemble `MatchController`:

```gdscript
class_name RunController
extends RefCounted

var state: RunState
var registry: ModifierRegistry
var replay_log: RunReplayLog

func submit_action(action: RunAction) -> RunActionResult:
    if action == null:
        return RunActionResult.rejected("Action is null")

    if not state.invariants_ok(registry):
        return RunActionResult.rejected("Run state is already invalid")

    if not is_legal_action(action):
        return RunActionResult.rejected("Illegal run action")

    var candidate := RunState.from_dict(state.to_dict())
    var outcome := _apply_action(candidate, action)

    if not outcome.ok:
        return RunActionResult.rejected(outcome.reason)

    var errors := candidate.invariant_errors(registry)
    if not errors.is_empty():
        return RunActionResult.rejected(
            "Run invariant failed: %s" % "; ".join(errors)
        )

    state = candidate
    replay_log.record_action(action, state.state_hash())

    state_committed.emit(action, state.state_hash())
    return RunActionResult.accepted(...)
```

This is not theoretical architecture: it is a direct extension of what January already does in `MatchController.submit_action()`. fileciteturn10file0L2-L2

Copy-validate-commit is particularly appropriate here because a year-long card run is tiny in data terms. Even the complete physical deck is only 48 IDs. There is no justification for a database-style transaction framework or structural-sharing library.

A `RunSession` Node may handle scene transitions and controller lifetime:

```text
RunSession Node
  owns RunController reference
  owns current MatchController reference
  creates/disposes scenes
  asks SaveStore to save
  forwards committed-state signals to presentation
```

But its job is orchestration, **not domain mutation**.

**Modifier Architecture**

The modifier system should be built around three layers:

```text
immutable definition
        ↓
persistent instance
        ↓
typed effect handler(s)
```

A definition describes *what kind of modifier exists*:

```gdscript
class_name ModifierDefinition
extends RefCounted

var modifier_id: StringName
var family: StringName
var target_kind: StringName
var unique_group: StringName
var effect_specs: Array[EffectSpec]

var rarity: StringName
var base_price: int
var offer_weight: int

var ai_tags: Array[StringName]
```

An instance describes *this run's copy of it*:

```gdscript
class_name ModifierInstance
extends RefCounted

var instance_id: String
var definition_id: StringName

var acquired_month: int
var acquisition_source: StringName
var purchase_price: int

var economic_owner_id: int = 0

# Empty for player-owned effects.
var target_card_id: StringName

var location: StringName
var persistent_state: Dictionary = {}
```

An `EffectSpec` binds content to code:

```text
hook/domain
handler_key
priority
parameters
```

For example:

```json
{
  "modifier_id": "sweep",
  "family": "card_upgrade",
  "target_kind": "hanafuda_card",
  "effects": [
    {
      "hook": "capture_plan",
      "handler": "capture.sweep",
      "priority": 100
    }
  ]
}
```

The JSON string does **not** dynamically load an arbitrary script. Instead:

```gdscript
const HANDLERS := {
    &"capture.sweep": preload("res://scripts/modifiers/effects/sweep_effect.gd"),
    &"score.kasu_card_bonus": preload("res://scripts/modifiers/effects/chaff_point_effect.gd"),
    &"decision.mulligan": preload("res://scripts/modifiers/effects/mulligan_effect.gd"),
    &"draw.second_draw": preload("res://scripts/modifiers/effects/second_draw_effect.gd"),
    &"multiplier.quad_koi": preload("res://scripts/modifiers/effects/quad_koi_effect.gd"),
    &"reward.wider_choice": preload("res://scripts/modifiers/effects/wider_choice_effect.gd")
}
```

Thus there is one explicit binding point between data and executable code. `MatchController`, `YakuEvaluator`, `RewardGenerator`, `ShopGenerator`, UI, AI and save code never contain:

```gdscript
if modifier_id == "sweep":
```

The central registry knowing that `"capture.sweep"` maps to a handler is healthy. Scattered feature code knowing `"sweep"` is not.

I recommend **typed domain hooks, not a global event bus**. A universal `"before_anything"`/`"after_anything"` signal architecture would make ordering, legality and state mutation increasingly invisible. The six proposed effects already reveal the natural domains:

```text
Action / decision providers
  Mulligan
  Second Draw

CapturePlan pipeline
  Sweep

Score pipeline
  Chaff Point Upgrade

Settlement multiplier pipeline
  Quad Koi

RewardRequest pipeline
  Wider Choice
```

Future domains can be added **when a concrete modifier first needs them**:

```text
CardFacts / classification
Yaku eligibility
Stop / Koi-Koi availability
Currency quote
Shop offer request
Reroll request
Modifier acquisition
```

This is the middle ground between modifier spaghetti and an unnecessary general-purpose ability engine.

For card-attached upgrades, the correct representation is:

```text
immutable CardCatalog base definition
        +
RunState modifier attachment keyed by stable card ID
        ↓
derived effects/properties at query time
```

Do **not** mutate `CardDefinition`. The current `CardCatalog` loads a single manifest keyed by stable IDs and already validates 48 cards, twelve months, four cards per month, allowed classifications and asset references. fileciteturn15file0L2-L2

A decorated replacement card object is also unnecessary. There is still one physical card:

```text
card_id = "jan_crane"
```

and perhaps:

```text
active_card_modifiers["jan_crane"] = ["modifier_instance_017"]
```

That preserves the existing physical-card invariant.

Ownership should be separated into **economic ownership** and **effect subject**.

For Sweep:

```text
economic owner = human player's run
effect subject = physical hanafuda card
beneficiary = whoever currently captures with that card
```

For Quad Koi:

```text
economic owner = human player's run
effect subject = player
beneficiary = that player
```

Therefore Sweep cannot ask, “Is this the player's card?” The handler receives:

```text
source card ID
acting/capturing player
field state
active card attachments
```

and applies according to the physical card's attachment.

A reserve modifier still belongs to the player economically but is omitted from the active effect projection. That makes “reserve has no effect” an authoritative data rule rather than a visual-slot convention.

Temporary state should follow its lifetime:

| Data | Home |
|---|---|
| Name, family, effect parameters | `ModifierDefinition` |
| Acquired month | `ModifierInstance` |
| Acquisition source | `ModifierInstance` |
| Purchase price | `ModifierInstance` |
| Target card | `ModifierInstance` |
| Active/reserve placement | `RunState` |
| Persistent run-long counters | `ModifierInstance.persistent_state` |
| Used this month | match modifier runtime state |
| Activations this month | match modifier runtime state |
| Temporary disabled flag | match modifier runtime state |
| Current event/capture candidate | transient resolution context |
| Trigger-chain visited set | transient resolution context |
| Pending user choice | authoritative `GameState`, because it must survive save/load |

The six representative modifiers then fit cleanly:

| Modifier | Domain | Architecture |
|---|---|---|
| Chaff Point Upgrade | score | Score handler examines contributing card IDs and adds one point; does not alter Kasu count |
| Sweep | capture | Card-owned handler augments an already-successful `CapturePlan` |
| Mulligan | pre-match action | Player-owned action provider exposes a one-time opening decision |
| Second Draw | draw decision | Player-owned action provider creates a decision after reveal and before resolution |
| Quad Koi | multiplier replacement | Replaces named Koi-Koi multiplier from 2 to 4 |
| Wider Choice | reward request | Changes requested reward choice count before generation |

The important detail for Chaff Point is to have the scoring evaluator expose a structured result such as:

```text
ScoreBreakdown
  yakus
    kasu
      qualified = true
      threshold_count = 11
      contributing_card_ids = [...]
      base_points = 2
  ...
```

The upgrade then alters `base_points` or contributes a separate bonus:

```text
kasu_card_upgrade_bonus = +1
```

but never changes:

```text
threshold_count
```

That satisfies the exact rule that the upgraded Chaff participates normally in the threshold but does not count twice.

For Sweep, refactor capture computation into:

```text
base matching
    ↓
CapturePlan
    ↓
active capture effects
    ↓
final CapturePlan
    ↓
card-conservation validation
    ↓
commit
```

The current match controller already centralizes pending-card capture in `_resolve_pending_card()`, making this a bounded future refactor instead of a rewrite. fileciteturn10file0L2-L2

Mulligan should introduce one explicit pre-turn decision phase rather than an animation callback:

```text
opening deal complete
    ↓
PHASE_OPENING_DECISIONS
    ↓
MULLIGAN(selected_card_ids)
or
PASS_OPENING_DECISIONS
    ↓
PHASE_HAND_PLAY
```

The exact deterministic rule for how returned cards re-enter the deck—shuffle into remaining deck, return then reshuffle, insert at defined positions, etc.—is a **game-design decision that must be locked before implementing Mulligan**.

Second Draw requires a similarly explicit decision window. At present January's draw logic reveals a drawn card and can move directly into resolution. The correct future sequence is:

```text
draw normal card
    ↓
authoritative PHASE_DRAW_REVEAL
    ↓
legal actions:
  KEEP_DRAW
  SECOND_DRAW     [only if active + unused]
    ↓
if SECOND_DRAW:
  revealed card → bottom of draw pile
  next card → pending draw
  consume monthly use
    ↓
resolve match normally
```

The defining rule is that an unresolved user choice is always represented by state and legal actions—not by suspended coroutine control flow.

Quad Koi belongs in a named multiplier pipeline:

```text
base score
    ↓
base Koi-Koi multiplier = x2
    ↓
replacement effects
      Quad Koi => x4
    ↓
other explicitly additive/multiplicative effects
    ↓
final resolved score
```

It must never be implemented as “multiply by another 2,” because that would accidentally turn future multiplier interactions into stacking behavior.

Wider Choice should not be code inside `RewardGenerator`. Instead:

```text
base RewardRequest(choice_count = 3)
    ↓
run-layer active effects
    ↓
RewardRequest(choice_count = 4)
    ↓
RewardGenerator
```

The generator therefore remains ignorant of the modifier ID.

**Effect Resolution and Priority**

Effect ordering should be **explicit before the modifier pool becomes large**, but it should be domain-specific rather than one enormous global rules language.

Each operation should carry at least:

```text
domain
stage
priority
source kind
stable source ID
stable operation ID
mode
```

Modes are intentionally few:

```text
REPLACE
PREVENT
ADD
MULTIPLY
AUGMENT
```

A deterministic total order can be:

```text
(stage,
 explicit_priority,
 source_kind_tiebreak,
 stable_source_id,
 operation_id)
```

The final ID tie-break exists to guarantee reproducibility. It should **not** become a hidden balance rule. If two noncommutative effects rely on the arbitrary ID tie-break to produce the intended game result, their priorities or compatibility rules are underspecified.

For scoring, define semantic stages approximately as:

```text
printed/base card facts
        ↓
derived card classification
        ↓
yaku eligibility + threshold calculation
        ↓
base yaku point calculation
        ↓
point replacements
        ↓
point additions
        ↓
multiplier replacements
        ↓
other explicit multipliers
        ↓
final integer score
```

For capture:

```text
base month matching
        ↓
capture replacement / prevention
        ↓
capture augmentation
        ↓
physical-card conservation validation
        ↓
commit
```

For draws:

```text
base deterministic draw
        ↓
reveal
        ↓
optional decision providers
        ↓
selected replacement
        ↓
resolution
```

For multiple score bonuses, integer additions can commute but should still be logged in stable order.

For multiple replacements of the **same named property**, the preferred rule is:

1. Content validation prevents impossible/unintended conflicts.
2. If coexistence is legitimate, explicit priority decides.
3. Stable ID ordering is only deterministic final tie-breaking.
4. In development, same-priority noncommutative conflicts produce a validator warning or error.

This is especially important for:

```text
normal Koi multiplier = 2
Quad Koi replacement = 4
future Moon replacement = ?
future additive score multiplier = ?
```

A replacement targets the named property:

```text
koi_koi_multiplier
```

rather than multiplying the current number.

Trigger recursion should be bounded structurally. Each resolution gets a stable event token and maintains something equivalent to:

```text
activated:
  (root_event_id, source_instance_id, hook_name)
```

By default, the same modifier cannot trigger the same hook twice for the same event. Effects explicitly marked repeatable can opt out. Child triggers keep the same root chain ID.

A reasonable defensive depth limit can exist, but exceeding it should be a **hard development/test failure before commit**, not “quietly stop resolving effects.” Silent truncation would create bugs that are almost impossible to diagnose.

Charges and once-per-month state should only be consumed on a successfully committed candidate state. If an action is rejected after validation, the modifier remains unused. That naturally falls out of copy-validate-commit.

Moon rules should eventually be another **effect source**, not another parallel modifier engine:

```text
RuleSource
  base rules
  Moon rule
  active card upgrades
  active player modifiers
```

This lets a Moon and Card Upgrade operate through the same score/capture stages while retaining distinct source provenance.

## Run economy, rewards, shops, persistence, and randomness

**Reward Architecture**

Use one deterministic `OfferGenerator` driven by a declarative request:

```text
RewardRequest
  month
  choice_count
  slot_specs[]
  exclusions[]
  duplicate_policy
  source = month_reward
```

The two competing reward designs then differ only in their slot specifications.

Whole-pool model:

```text
slot 0: ANY_MODIFIER
slot 1: ANY_MODIFIER
slot 2: ANY_MODIFIER
```

Family-guaranteed model:

```text
slot 0: CARD_UPGRADE
slot 1: HAND_MECHANIC
slot 2: STRATEGIC_META
```

This deliberately **does not resolve the design-authority conflict**.

Their consequences are different:

| Dimension | Three from whole pool | One per family |
|---|---|---|
| Short-term variance | Higher | Lower |
| Build consistency | Lower | Higher |
| Player agency | Lower when family distribution is unlucky | Higher family-level agency |
| Synergy spikes | More volatile | More regular |
| Family exposure | Emergent from weights | Guaranteed each reward |
| Dead-offer risk | Can produce several irrelevant offers | Can force a weak/dead family slot |
| Balancing pool weights | More important | Less important between families |
| Implementation complexity | Slightly simpler request | Slightly richer slot specification |
| Long-run discovery | More stochastic | More systematic |
| Build forcing | Lower | Potentially higher |

Neither is technically problematic if both are expressed by the same generator.

Generation should be:

```text
slot spec
   ↓
collect eligible candidates
   ↓
apply exclusions
   ↓
build deterministic candidate order
   ↓
weighted seeded sample
   ↓
reserve sampled candidate if duplicates disallowed
   ↓
materialize immutable Offer
```

Every generated offer should have:

```text
offer_id
slot_index
slot_category
modifier_definition_id
target_card_id if fixed
quoted value/price if applicable
generation_sequence
provenance
```

Do not regenerate offers when a UI screen is reopened. Once generated, the offers are state.

Card Upgrade target selection should support both possible future policies without choosing one:

```text
FIXED_TARGET
  generator samples an eligible pair:
    (upgrade definition, physical card ID)

PLAYER_SELECTS_TARGET
  offer contains target criteria;
  CHOOSE_REWARD action includes one legal target card ID
```

The architecture need not determine which feels better.

Sampling should normally be without replacement within an offer set unless a specific modifier is allowed to duplicate. Candidate arrays must be put into a stable order before weighted choice.

Wider Choice modifies the `RewardRequest` before generation:

```text
choice_count: 3 → 4
```

The unresolved design question under the one-per-family model is **what category the fourth slot is**. The engine should not guess. Make this a policy/configuration field such as:

```text
extra_choice_policy
```

whose exact value is a design decision.

If carry capacity is full when a reward is selected, do not secretly overflow reserve. A technically safe interim representation is:

```text
RewardState.pending_acquisition
```

The selection has happened, but the newly acquired modifier has not yet been placed. The player must resolve its legal disposition during carry management before entering the shop. That lets the storage/replacement design remain explicit rather than corrupting capacity invariants.

**Shop and Transaction Architecture**

Yes: the shop should use atomic commands following the same philosophy as match actions.

Recommended run actions include:

```text
RESOLVE_MONTH
LIQUIDATE_MODIFIER
CHOOSE_REWARD
REFUSE_REWARD
PLACE_PENDING_ACQUISITION
MOVE_MODIFIER
BUY_OFFER
SELL_MODIFIER
REROLL_SHOP
ENTER_SHOP
EXIT_SHOP
FINALIZE_BUILD
BEGIN_NEXT_MONTH
```

The advantages are unusually strong for 12 Moons:

```text
one mutation gateway
deterministic replay
invalid UI cannot corrupt state
future server validation becomes natural
telemetry can observe committed actions
debugging becomes reproducible
transaction invariants are centrally enforceable
```

The cost is some command boilerplate. That cost is acceptable; avoid turning the command layer into a generic enterprise command framework.

`ShopState` should contain the actual authoritative offers:

```gdscript
class_name ShopState
extends RefCounted

var shop_id: String
var month: int
var generation: int = 0
var reroll_count: int = 0
var offers: Array[ShopOffer] = []
```

The six `ShopOffer`s retain their slot category:

```text
CARD_UPGRADE
HAND_MECHANIC
STRATEGIC_META
WILDCARD
WILDCARD
SPECIAL
```

A reroll asks the generator to refill each slot **from its stored slot specification**. Thus the category-preservation rule is structural.

Wildcard is a slot eligibility rule, not a modifier family.

The special sixth slot should use a bounded payload kind:

```text
MODIFIER
SERVICE
ECONOMY
SLOT_ACCESS
```

There is no need for a generic item/inventory system.

`BUY_OFFER` should atomically validate:

```text
correct run phase
offer ID exists
offer has not been purchased
offer remains eligible
quoted price is valid
currency >= quoted price
modifier/service isn't prohibited
target card is valid
destination/capacity requirements are satisfied
```

Only then:

```text
currency -= price
materialize acquisition/service result
mark offer purchased
emit committed domain event
```

A failure at any point must leave the canonical state hash unchanged.

`REROLL_SHOP` validates:

```text
reroll_count < 2
currency >= reroll_costs[reroll_count]
```

then atomically:

```text
subtract cost
increment reroll_count
derive reroll RNG scope
regenerate eligible unsold/rerollable offers by the same slot specs
commit
```

The prototype `[1, 2]` cost schedule belongs in configuration.

`SELL_MODIFIER` validates ownership and sale eligibility, removes the instance from its active/reserve/card attachment location, and only then applies the configured proceeds. Resale formulas remain a design parameter.

`MOVE_MODIFIER` has no currency logic. It merely validates source, destination and capacity and moves one existing instance.

A Rain Check-style effect later should not require replacing the generator. `ShopOffer` can have persisted provenance and optional persistence metadata; a future rule can copy selected persisted offers into the next `ShopRequest`. That hook can wait until the modifier exists.

**Transaction safety**

The existing match controller is already doing the right thing: clone, apply, validate invariants, commit. fileciteturn10file0L2-L2

Use exactly that for run transactions.

This makes several bugs structurally difficult:

```text
double purchase
negative bankroll
modifier existing in active and reserve
sale without deactivation
reroll charged twice
reward selected twice
partial purchase mutations
UI callback halfway modifying state
```

In test/debug builds, every rejected transaction should additionally assert:

```text
hash_after == hash_before
```

**Emergency liquidation and bankruptcy**

Liquidation should absolutely be a distinct run phase.

Do not implement bankruptcy by temporarily setting:

```text
currency = -7
```

and then asking the UI to fix it.

Instead, `RESOLVE_MONTH` calculates a `PendingSettlement`:

```text
settlement_id
match_result_id
month
resolved_score
economic_delta
amount_due
bankroll_before
```

For a win:

```text
economic_delta = +resolved_score
```

For a loss:

```text
amount_due = resolved_score
```

If:

```text
currency >= amount_due
```

the loss can be settled immediately.

If:

```text
currency < amount_due
```

then:

```text
phase = LIQUIDATION
pending_settlement.amount_due = resolved_score
```

and **currency stays nonnegative**.

While liquidation is active, normal shop/reward spending is illegal. The only player-facing economic commands are liquidation actions.

One clean accounting model is:

```text
sell modifier
    ↓
sale proceeds enter currency
    ↓
currency >= amount_due?
```

If yes, the controller immediately or explicitly executes:

```text
currency -= amount_due
pending_settlement = null
continue post-month transition
```

Any excess raised remains bankroll.

If the player raises only part of the debt, the run remains in liquidation. If no legal remaining asset can raise enough to satisfy the obligation, transition to `BANKRUPT`. The engine need not invent a resale value now; inject the currently configured resale policy.

The replay should therefore show:

```text
RESOLVE_MONTH(loss = 12)
LIQUIDATE_MODIFIER(instance A)
LIQUIDATE_MODIFIER(instance B)
SETTLEMENT_COMPLETED
```

or:

```text
RESOLVE_MONTH(loss = 12)
LIQUIDATE_MODIFIER(instance A)
BANKRUPTCY
```

The debt is paid once, at final settlement, rather than decremented piecemeal by UI logic.

Slot unlocking should occur only after the completed month's settlement is successfully resolved, before reward generation. January completion therefore changes the authoritative carry capacity from zero to one according to the current January-through-August design.

**Save/Load and Migration Strategy**

Use **explicit, versioned JSON** for authoritative run saves.

Godot 4.7's JSON API directly supports conversion between Variants and JSON text, and `FileAccess` is designed for persistent user files. Godot's own JSON documentation also notes that JSON does not retain an integer/float distinction, so deserialization code should explicitly coerce schema-defined integer fields rather than treating parsed numeric types as an implicit schema. citeturn13view0 citeturn13view1

A save envelope should look conceptually like:

```json
{
  "format": "12_moons_run",
  "schema_version": 1,
  "game_version": "…",
  "content_version": "…",
  "run_id": "…",
  "payload_sha256": "…",
  "payload": {
    "run_state": {},
    "current_match": {},
    "run_replay": {},
    "match_replay": {}
  }
}
```

The exact contents depend on whether a match is active.

Serialize:

```text
RunState
modifier instances
modifier locations
reward/shop/liquidation state
root seed
generation counters
current MatchState snapshot if a match is active
current match replay/action sequence
run action journal
content IDs
schema/content versions
```

Do not serialize:

```text
Nodes
scene tree
Control state
Tweens
Timers
presentation queue animation progress
Callables
textures/audio duplicates
CardDefinition copies
ModifierDefinition copies
UI selection highlights
global Resource references
```

The save holds IDs for static content.

Using mutable `.tres` Resources as the authoritative save format would be less appropriate here. Godot Resources are path-cached and shared on subsequent loads, while the project needs explicit migrations, language-neutral data and tight control over what enters the authority boundary. Resources remain useful for immutable authored presentation content. citeturn13view4

Use a migration chain:

```text
load JSON
   ↓
validate envelope/checksum
   ↓
schema 1?
  yes → decode
  no  → migrate 1→2→3...
   ↓
resolve stable content IDs / rename aliases
   ↓
construct RunState/MatchState
   ↓
run invariants
   ↓
accept loaded state
```

Migration functions should be pure dictionary transformations:

```gdscript
func migrate_v1_to_v2(data: Dictionary) -> Dictionary:
    var result := data.duplicate(true)
    # Explicit transformation.
    result["schema_version"] = 2
    return result
```

Renamed content IDs require explicit alias/migration rules:

```text
old_modifier_id → new_modifier_id
```

A removed modifier should not silently disappear from a save. Either migrate it to a defined replacement, compensate under an explicit migration rule, or report the save as incompatible. Silent fallback is one of the highest-risk AI-assisted-development failure modes.

For crash resistance:

```text
serialize canonical payload
        ↓
write user://run.tmp
        ↓
flush/close
        ↓
verify parse/checksum
        ↓
retain/rotate previous good save as backup
        ↓
rename temp to final
```

`FileAccess` supports explicit writing/flushing, while `DirAccess` provides filesystem operations. Filesystem rename semantics can vary, so call this **crash-resistant/best-effort atomic save replacement**, not a mathematical guarantee on every OS/filesystem. citeturn13view1 citeturn11search2

State snapshots and replay logs should coexist.

The snapshot is the production resume mechanism:

```text
fast
migration-friendly
contains exactly what is needed now
```

The action log is evidence:

```text
reproducibility
bug reports
state-hash verification
debugging
future multiplayer audit
```

Do not make production load depend on replaying the entire run from January every time. Old replay semantics may legitimately become version-sensitive after rule patches.

**Deterministic RNG Architecture**

Use **one authoritative root run seed, but not one mutable RNG stream**.

The best practical model is:

```text
root_run_seed
      ↓ stable hash derivation
 ┌────┼───────────────────────────────────┐
 │    │            │          │           │
match reward      shop      reroll      future
seed  seed        seed      seed        modifier RNG
```

Example scopes:

```text
match/deck/1/0
match/deck/2/0

reward/1/0
reward/2/0

shop/1/initial
shop/1/reroll/1
shop/1/reroll/2

ai/1/turn/12/decision

modifier/<instance_id>/<event_sequence>
```

Godot 4.7's `RandomNumberGenerator` guarantees that the same seed produces a reproducible sequence, exposes the generator state for save/restore, and specifically warns that nearby seeds do not have an avalanche effect and should be hashed when externally derived. Godot also warns that the underlying PRNG algorithm—currently PCG32—is an implementation detail and should not be depended on as a permanent cross-version contract. citeturn11search1

That strongly supports a stable seed-derivation function:

```text
derived_seed =
  stable_hash(
    root_seed
    + generation_schema_version
    + subsystem
    + month
    + sequence
  )
```

Use SHA-256 or another explicitly fixed hash, not a convenience mechanism whose algorithm is unspecified as a save-format contract.

Then instantiate a local RNG for one generation transaction:

```gdscript
var rng := RandomNumberGenerator.new()
rng.seed = derive_seed(
    state.root_seed,
    "shop",
    state.month,
    state.shop_state.reroll_count
)
```

The key advantage is **random-call isolation**.

With one global gameplay RNG:

```text
adding one random AI tie-break
        ↓
changes next shop
        ↓
changes next reward
        ↓
changes February deck
```

With scoped RNG:

```text
shop changes consume only shop scope
deck scope remains unchanged
reward scope remains unchanged
```

VFX, particle variance, card wobble, audio pitch variation and cosmetic animation randomness must never consume a gameplay RNG.

For a reproducible bug report, record:

```text
game version
content version
root run seed
month
RNG scope name
scope sequence/index
run action log
match action log
state hash before/after
```

Because Godot explicitly treats its RNG algorithm as an implementation detail, 12 Moons should not promise indefinite cross-engine-version reconstruction from seed alone. citeturn11search1

For the foreseeable project:

```text
save generated deck order
save generated shop/reward offers
version replay files
maintain golden-seed tests across engine upgrades
```

Only build a small custom fixed PRNG later if permanent cross-Godot-version seed compatibility becomes a concrete production requirement.

## Determinism, content, tooling, simulation, telemetry, and tests

**Determinism Failure Checklist**

The following should become the project-level **12 Moons Determinism Checklist**.

| Check | Rule |
|---|---|
| Gameplay RNG | Every authoritative random outcome comes from an explicit seeded RNG scope |
| Global RNG | No authoritative `rand*()` or `randomize()` calls |
| Presentation RNG | Separate from gameplay RNG |
| Seed derivation | Stable hashed subsystem scopes |
| RNG versioning | Derivation scheme has a version |
| Generated offers | Persist once generated; never regenerate on UI redraw |
| Deck order | Authoritative state, not scene order |
| Iteration | Sort semantically unordered IDs before logic that depends on order |
| Filesystem enumeration | Never treat directory iteration as deterministic content order |
| Dictionaries | Canonical hashes explicitly normalize/sort semantic collections |
| Sorting | Comparator has a total tie-break using stable IDs |
| Object identity | Never use instance IDs/RIDs as gameplay IDs |
| Physical cards | Stable 48 card IDs remain identity |
| Signals | Observe committed state; do not secretly mutate authority |
| Timers | Never determine game rule outcomes |
| Tweens | Never determine game rule outcomes |
| Animation completion | Cannot decide legality or card location |
| `_process()` | No authoritative turn progression |
| `_physics_process()` | No authoritative card-game progression |
| `await` | Never suspend an unresolved rule decision that is absent from state |
| Threads | No shared authoritative-state mutation |
| Resources | No per-run mutable shared loaded Resources |
| UI callbacks | Submit actions only |
| Floating point | Avoid for money, score, counts, weighted totals where integers suffice |
| Effect ordering | Explicit stage/priority/stable tie-break |
| Pending decisions | Serializable authoritative phases |
| Legal actions | Generated deterministically and returned in stable order |
| Rejected actions | State hash unchanged |
| Accepted actions | Invariants checked before commit |
| Save/load | Continuation after load produces same outcome/hash |
| Replay | Same version + seed + actions reproduces same canonical state |
| Engine upgrade | Golden seed/replay suite required before upgrade |
| Content loading | Registries expose stable sorted IDs |
| Debug cheats | Use actions or validated scenario builders, never arbitrary live mutation |

Godot's resource-loading APIs explicitly warn that directory listing order may be nondeterministic in some contexts, reinforcing the rule that content discovery should always normalize ordering before gameplay use. citeturn12search18

Resource caching is another subtle determinism hazard: a loaded Resource is normally shared by path, so modifying a definition in one place can affect all users of that reference. Static definitions should therefore be treated as immutable. citeturn13view4

The existing 12 Moons code is already ahead of most prototypes here because `GameState` exposes a canonical dictionary/hash and explicitly sorts collections where semantic ordering should not matter. fileciteturn13file0L2-L2

**Data-Driven Content Model**

Do not replace the existing card JSON architecture. `CardCatalog` already reads `data/hanafuda/cards.json`, creates stable typed definitions and validates the fundamental 48-card/12-month structure. fileciteturn15file0L2-L2

For 12 Moons, the strongest content model is a **hybrid**, with JSON as deterministic gameplay truth:

```text
JSON
  deterministic/static gameplay definitions

GDScript
  executable rules/effect handlers
  registries
  schemas/validators

.tres Resources
  optional Godot-specific presentation bundles
  textures/audio/themes/editor-friendly metadata

Scenes
  visual composition only
```

Comparison:

| Format | Strength | Weakness | Recommendation |
|---|---|---|---|
| JSON | Excellent diffs, explicit schema, language-neutral, TypeScript-portable | No Inspector typing, asset paths are strings | Primary gameplay content |
| Custom `.tres` Resources | Great Inspector workflow, typed asset references | Godot-specific, cached/shared, noisier cross-language story | Presentation/editor metadata |
| Hard-coded dictionaries | Fast for tiny constants | String drift, poor validation/diffs at scale | Avoid for content |
| Registry scripts | Excellent for executable handler bindings | Code change required | Use |
| Generated code | Can provide typed ID constants | Adds build complexity | Optional later |
| Scene files | Good visual authoring | Bad authoritative rules storage | Presentation only |

This recommendation also prepares for a future TypeScript server without forcing one now. The static gameplay definition:

```json
{
  "modifier_id": "quad_koi",
  "family": "hand_mechanic",
  "effects": [
    {
      "handler": "multiplier.quad_koi",
      "priority": 100
    }
  ]
}
```

is easy for a future non-Godot implementation to understand, whereas an arbitrary serialized Godot Resource graph is not.

Godot Resources remain good presentation containers, but their path-level caching makes them poor mutable per-run entities. citeturn13view4

Prototype balance data should also be centralized:

```text
data/run/run_rules.json

starting_bankroll
reserve_capacity
reward_refusal_cash
shop_reroll_costs
slot_unlock_schedule
rarity weights
price bands
```

This does not mean *everything* becomes data. Run phases, operation modes, invariants, transaction semantics and effect-handler code belong in code.

**Content validation**

Extend the current validator model. The repository already has a headless `validate_project.gd` that checks card manifest/art consistency and exits nonzero on error. fileciteturn14file0L2-L2

Add checks for:

```text
every modifier ID unique

every effect handler key registered

every Card Upgrade target rule valid

every explicit card ID exists

every Moon ID unique

every referenced modifier exists

every shop baseline category can produce at least one eligible candidate

price >= 0

weight >= 0

required fields present

fields forbidden for a family are absent

card-owned effects have valid target semantics

player-owned effects do not accidentally require card targets

unique-group references valid

renamed-ID aliases have no cycles

asset paths exist

presentation IDs match gameplay IDs

service handlers registered

all configured run-rule values are valid

every generated definition can round-trip into typed representation
```

Run this:

```text
Godot --headless
    ↓
content validation
    ↓
GdUnit4
    ↓
headless integration scenario
```

Godot 4.7 supports `--headless` execution, making the existing headless-validation strategy a first-class engine-supported approach rather than a workaround. citeturn12search22

**Debug/Developer Tooling**

The highest-leverage debug infrastructure is not a console with fifty cheats. It is a deterministic scenario harness.

Priority should be:

| Rank | Tool | Why |
|---|---|---|
| Highest | Seed + state hash inspector | Makes every bug reproducible |
| Highest | Restart same seed | Immediate determinism debugging |
| Highest | Jump to valid settlement/reward/shop states | Eliminates replaying January during between-month work |
| Highest | Authoritative state inspector | Shows what game actually believes |
| Highest | Instant/fast/normal presentation modes | Separates logic from animation latency |
| Highest | Action-by-action stepping | Reveals state-transition bugs |
| Very high | 48-card location inspector | Protects physical-deck invariant |
| Very high | Replay/action journal inspector | Explains mutation history |
| Very high | Force terminal result/score fixture | Economy testing |
| Very high | Force reward/shop offers | UI and transaction testing |
| High | Grant/move modifiers | Carry testing |
| High | Trigger liquidation/bankruptcy | Edge-path testing |
| High | RNG scope/derived seed inspector | Diagnoses random-generation issues |
| High | Draw-order inspector | Match determinism |
| High | Public AI view inspector | Prevents accidental cheating |
| Later | Effect-resolution trace | Essential once modifier interactions grow |

The overlay should expose:

```text
Run
  root seed
  current month
  phase
  run hash
  bankroll
  capacities

RNG
  subsystem scope
  derived seed
  generation index

Match
  match seed
  match hash
  phase
  draw pile order [debug only]
  48 card locations

Modifiers
  active
  reserve
  card attachments
  monthly usage state

Shop/Rewards
  offer IDs
  slot categories
  eligibility provenance
  RNG scope

Replay
  accepted actions
  resulting hashes
```

“Jump to January settlement” should not mutate twenty private variables manually. It should ask something like:

```text
DebugScenarioFactory.january_terminal_win(score = 8)
```

to construct a fully valid state that passes invariants.

Likewise, forcing a specific opening deal should be implemented either as:

```text
a validated explicit deck-order fixture
```

or:

```text
a seed-search helper
```

not by dragging card Nodes into different zones.

Debug commands that represent legal gameplay should go through the normal controllers. Impossible scenario construction can use a test/debug factory, but the resulting state must pass all production invariants before being admitted.

**Automated Simulation Architecture**

The current domain architecture is already unusually simulation-friendly because match authority lives in `RefCounted` data/controllers instead of animated Nodes. fileciteturn10file0L2-L2

Eventually add:

```text
tools/simulate_runs.gd
        ↓
SimulationRunner
        ↓
RunController + MatchController
        ↓
PolicyAgent
        ↓
legal actions
```

Run it headlessly, with no table scene and no animation. Godot explicitly supports headless execution. citeturn12search22

Policy agents should start simple:

```text
RandomLegalPolicy
  randomly selects among legal actions
  excellent for fuzzing
  poor model of human balance

HeuristicMatchPolicy
  evaluates captures/yaku/Koi-Koi with current rules

ScriptedRunPolicy
  specific spending/reroll/reward heuristics

PairedPolicy
  runs two economy/modifier versions over same seed cohort
```

Every simulation row should include at minimum:

```text
build/content version
root seed
policy ID/version
month
terminal outcome
bankroll
score
shop/reward generation IDs
```

Export summary CSV for bulk statistics and JSON traces only for interesting/pathological seeds.

Useful metrics include:

```text
survival probability by month
bankroll median and percentiles
bankroll tail risk
bankruptcy month distribution
settlement-score distribution
loss size relative to current bankroll
Koi-Koi declaration frequency
Koi-Koi conditional gain/loss
reward exposure rate by definition/family
shop eligibility and offer rate
purchase rate conditional on being offered
reroll rate
reroll affordability
modifier acquisition
modifier activation
modifier retention
modifier sale
unused currency at month boundaries
```

Metrics that are easily misleading:

| Metric | Why misleading alone |
|---|---|
| Modifier win rate | Selection and synergy bias |
| Average bankroll | Hides bankruptcy/tail risk |
| Random-agent survival | Not a human-skill proxy |
| Activation frequency | Frequency is not power |
| Raw offer frequency | Must divide by eligibility opportunities |
| Raw purchase rate | Depends on price and bankroll |
| Overall Koi-Koi success | Ignores decision context |
| Average score | Can hide extremely volatile losses |

Simulation should answer questions such as:

> “Does changing first reroll from 1 to 2 dramatically increase the share of runs that cannot afford any January shop purchase?”

It should not answer:

> “Is this fun?”

Human playtesting remains the final judge.

**Telemetry Event Model**

Keep telemetry completely outside authoritative mutation.

The controller commits an action and can produce immutable domain-event facts:

```text
action
   ↓
validate/candidate/commit
   ↓
DomainEvent[]
   ├─ presentation
   ├─ debug log
   └─ TelemetrySink
```

Telemetry must never feed back into the rules.

A provider-neutral envelope:

```json
{
  "event_name": "shop.purchase",
  "schema_version": 1,
  "event_id": "…",
  "run_id": "…",
  "sequence": 42,
  "game_version": "…",
  "content_version": "…",
  "month": 3,
  "payload": {}
}
```

Use stable names:

```text
run.started
run.month_entered
run.month_completed
run.completed
run.bankrupt

match.completed
match.yaku_formed
match.koi_koi_declared
match.stop_chosen

economy.settled
economy.liquidated
economy.purchase
economy.sale
economy.reroll

reward.offers_shown
reward.selected
reward.refused

carry.equipped
carry.reserved
carry.moved

modifier.activated

shop.offers_generated
shop.purchase
shop.reroll
shop.exited
```

A deterministic event ID can derive from:

```text
run_id
+
committed action sequence
+
event index within action
+
event name
```

This makes retry deduplication possible later.

Do not put personally identifying data into gameplay telemetry by default. A balance event does not need a player's name, email address, chat contents, contact information or IP address. An opaque run/install identifier is sufficient if cohort analysis is ever needed, subject to whatever consent/privacy rules ultimately apply.

Batching, retries, compression and remote providers belong behind a `TelemetrySink`. Initially:

```text
NullTelemetrySink
JsonlTelemetrySink     # development
```

is enough.

**Test Architecture**

Keep GdUnit4.

As of 2026, upstream GdUnit4 is actively maintained, MIT-licensed, and its current compatibility table includes Godot 4.7/4.7.1; it provides scene testing and a CI-oriented ecosystem. 12 Moons already uses it, so there is no architectural reason to replace the framework. citeturn14search0turn14search2turn14search6

Organize tests by risk rather than trying to force everything into unit tests:

```text
pure rule tests
        ↓
controller/transaction tests
        ↓
determinism/replay tests
        ↓
serialization/migration tests
        ↓
seed/property sweeps
        ↓
headless UI integration
```

Recommended matrix:

| Area | Essential tests |
|---|---|
| RunState | defaults, invariants, canonical hash, round-trip |
| RunController | accepted action commits; rejected action unchanged |
| Settlement | win gain, loss payment, exact zero legal |
| Liquidation | insufficient bankroll enters phase, sales, successful recovery, bankruptcy |
| Slot unlock | Jan–Aug schedule; no excess unlock |
| Carry | active cap, reserve cap, one location per instance |
| Reserve | inactive effects never projected |
| Rewards | deterministic same state/seed |
| Rewards | both requested generation models |
| Rewards | no illegal duplicates according to configured policy |
| Wider Choice | 3→4 request transformation only |
| Shop | correct six category specs |
| Shop | rerolls preserve category |
| Shop | first/second cost and third refusal |
| Purchase | exact payment once |
| Sale | exact proceeds once |
| Invalid buy | hash unchanged |
| Save | every run phase round-trip |
| Save | pending reward/shop/liquidation round-trip |
| Migration | fixture for every historical schema |
| RNG | same scope = same sequence |
| RNG | different subsystem scope isolated |
| Replay | same initial state + actions = same hash |
| Resume | save/load then continuation equals uninterrupted run |
| Physical deck | existing 48-card invariant after every match modifier |
| Content | all registries/IDs/handlers/assets validated |

Representative modifier tests:

**Chaff Point Upgrade**

```text
target is contributing Kasu card → +1 point
target exists but Kasu not scoring → no bonus
Kasu threshold count unchanged
two legal bonuses combine deterministically
reserve upgrade does nothing
target card remains one physical card
round-trip save retains target
```

**Sweep**

```text
modified card fails to match → no sweep
modified card succeeds → remaining same-month middle cards included
captor may be human or AI
benefit follows physical card
0/1/2/3 base-match cases
no physical-card duplication
card conservation after commit
reserve attachment inactive
```

**Mulligan**

```text
only available in pre-first-turn phase
0 selected legal
1 selected legal
2 selected legal
3 rejected
same action/seed gives same replacement hand
cannot activate twice
returned cards remain conserved
monthly usage reset next month
save during decision resumes identically
```

**Second Draw**

```text
only legal after normal reveal and before resolution
original revealed card goes to exact defined bottom position
replacement draw is next deterministic card
cannot activate twice
edge case with insufficient remaining cards specified
physical-card conservation
save during reveal resumes identically
```

**Quad Koi**

```text
normal Koi x2 becomes x4
never x8
does nothing when Koi multiplier does not apply
replacement conflict resolved deterministically
reserve version inactive
```

**Wider Choice**

```text
3 → 4
same seed/state gives same four offers
does not affect shop slot count
reserve version inactive
works with shared-pool configuration
works with family-quota configuration once fourth-slot policy supplied
```

For property/fuzz testing, do **not** build a homegrown QuickCheck clone. GdUnit4 itself provides fuzzing-oriented testing capabilities, but the highest-value approach for this project is simpler: deterministic seed sweeps plus random legal action selection. citeturn14search4

A test loop should do approximately:

```text
for seed in known_seed_matrix:
    construct valid state

    while nonterminal:
        actions = legal_actions()
        deterministically choose an action
        hash_before = state_hash()

        result = submit_action(action)

        assert invariants

        periodically:
            serialize
            deserialize
            assert same canonical hash
```

For mutation fuzzing:

```text
wrong phase
invalid modifier ID
already-bought offer
illegal target card
negative/forged price
third reroll
overfull reserve
double reward selection
```

and assert:

```text
rejected
AND
hash_after == hash_before
```

When fuzzing finds a failure, print:

```text
seed
initial snapshot hash
action prefix
failing action
RNG scope
```

Then replay prefixes to minimize the reproduction. That provides most of property testing's practical value without importing another framework.

## Future boundaries and architecture quality

**Multiplayer Future-Proofing**

The architecture decisions that matter now are not WebSockets or Cloudflare APIs. They are authority boundaries.

Preserve:

```text
serializable player commands
single authoritative mutation gateway
explicit validation
plain stable state IDs
deterministic rule resolution
explicit RNG ownership
public/private state projection
pending decision phases
action logs
state hashes
versioned content IDs
versioned save/action schemas
```

12 Moons already has an important multiplayer prerequisite: `PublicStateView` separates what the AI can see from hidden hands/draw information, and the README explicitly describes that privacy boundary. fileciteturn11file0L2-L2 fileciteturn7file0L2-L2

Future authoritative networking can conceptually become:

```text
Godot client
   │
   │ RunAction / GameAction
   ▼
TypeScript authoritative server
   │
   ├─ validate action
   ├─ update hidden authoritative state
   ├─ run deterministic rules
   └─ create player-specific projection
   │
   ▼
Godot client
```

Do **not** attempt to “share GDScript” with a Cloudflare Worker.

Instead preserve language-neutral contracts:

```json
{
  "type": "buy_offer",
  "offer_id": "shop-3-1-02",
  "destination": "reserve"
}
```

and build golden fixtures later:

```text
initial state JSON
+
actions JSON
=
expected result JSON
+
expected hash
```

A future TypeScript rules port can run those same fixtures to detect divergence.

For hidden information and cheating resistance, a future server should ultimately own unrevealed deck order, authoritative reward/shop generation and action validation. Godot 4's own multiplayer facilities are not relevant to choosing the current run architecture because the stated likely direction is an external authoritative backend. No backend work is needed now.

One warning: Godot's `RandomNumberGenerator` algorithm is explicitly not a permanent API guarantee. Therefore, if a TypeScript backend someday needs bit-identical cross-language RNG, a fixed shared PRNG specification would need to be introduced then. That is not a reason to build it for the January-to-February milestone. citeturn11search1

**AI Future-Proofing**

The most important future AI tool is **simulation through the same rules**, not a list of modifier-specific heuristics.

For Sweep:

```text
AI considers PLAY_CARD
        ↓
simulate through CapturePlan pipeline
        ↓
Sweep automatically changes resulting captured cards
        ↓
AI evaluates resulting state
```

The AI does not need:

```gdscript
if modifier_id == "sweep":
    value += ...
```

The same is true for scoring effects and Quad Koi.

However, simulation alone can be expensive or insufficient for strategic abstractions, so each effect definition may expose coarse machine-readable semantic tags:

```json
{
  "ai_tags": [
    "capture_augmentation",
    "same_month_capture",
    "shared_card_risk"
  ]
}
```

or structured metadata:

```text
domain = CAPTURE
target = PHYSICAL_CARD
effect_direction = POSITIVE_FOR_CAPTOR
scope = SAME_MONTH
```

For Wider Choice:

```text
domain = REWARD
choice_delta = +1
```

For Quad Koi:

```text
domain = KOI_DECISION
risk_reward_multiplier = replacement(4)
```

These tags should help generic heuristics; they are **not** a second rules engine.

Maintain the current information-security principle: AI simulation begins from its legal public/belief state, not the actual hidden player hand or unrevealed deck order. The repository already treats this as an architectural boundary. fileciteturn11file0L2-L2

Later, a generic `preview_action()`/rule-simulation path can share the same transition functions without committing. Be careful that the AI-specific simulation API cannot accidentally expose the live authoritative hidden candidate state.

**Anti-AI-Slop Engineering Checklist**

AI assistance becomes dangerous when generated code optimizes locally for “make this feature work” while eroding global authority boundaries. The prevention mechanism should be repository-specific.

Before accepting an AI-generated contribution, check:

| Gate | Required answer |
|---|---|
| Mutation authority | Does all authoritative mutation still pass through `MatchController` or `RunController`? |
| Second truth | Did the patch create another copy of currency, card location, offer state or modifier placement? |
| Modifier IDs | Are modifier IDs compared outside definition/handler registries or tests? |
| RNG | Did any gameplay code introduce global/randomized RNG? |
| UI authority | Is a UI script calculating price, settlement, legality or score? |
| Animation authority | Does game progression depend on Timer/Tween/animation completion? |
| Singleton | Did the patch add an Autoload? Is it genuinely necessary? |
| Manager proliferation | Did it introduce another `*Manager` instead of a narrow existing helper? |
| Abstraction evidence | Does a new abstraction solve at least two real current cases or one imminent required case? |
| Generic system creep | Did a six-line requirement become a universal event/message/plugin framework? |
| Logic duplication | Is scoring, capture, pricing, validation or eligibility implemented twice? |
| Strings | Are new stable IDs centralized and validated rather than repeated ad hoc? |
| Typing | Are domain-facing GDScript APIs typed where practical? |
| Failure behavior | Does invalid content fail loudly in tests rather than silently default? |
| Transactions | Can a failure occur after partial state mutation? |
| Rejected state | Is rejected-action hash unchanged? |
| Persistence | Are new authoritative fields serialized/migrated or explicitly transient? |
| Resource safety | Is mutable runtime state being stored in a shared `.tres`? |
| Effect ordering | Does a new modifier specify its hook/stage/priority? |
| Effect ownership | Is card-owned vs player-owned explicit? |
| Reserve | Can an inactive modifier accidentally trigger? |
| Physical cards | Does a Card Upgrade duplicate/create a card? |
| AI privacy | Does AI gain hidden-state access? |
| Replay | Is the new player decision represented as a logged action? |
| Pending choice | Can a save capture every unresolved decision? |
| Comments | Do comments explain *why/invariants*, not merely restate code? |
| Dead abstractions | Did the agent leave unused helpers/interfaces behind? |
| Scene authoring | Did a reusable visual screen become a giant procedural UI script unnecessarily? |
| Dependency direction | Does core/run/modifier code import UI? It should not. |
| Tests | Did the patch add the invariant/interaction tests demanded by its new behavior? |
| Existing architecture | Did the agent inspect and extend current code instead of creating a parallel implementation? |

Godot's static typing can detect more errors before runtime and improve editor comprehension/autocompletion; applying it consistently at the domain boundaries is worthwhile in an AI-assisted codebase where ambiguous Variants otherwise make generated patches harder to review. citeturn12search17

A useful code-review search should routinely look for patterns such as:

```text
if modifier_id
rand
randomize
.currency =
active_modifiers.append
field_ids.append
get_node(...)
Timer
await
Tween
autoload
Manager
```

The presence of one is not automatically wrong. It is a prompt to verify that the architecture boundary remains intact.

The single most important AI-development rule for this repository should be:

> **An agent must modify the existing authoritative path unless the architecture explicitly requires a new one. It may not solve a feature by creating a parallel source of truth.**

## Open-source evidence, repository layout, and decisions

**Relevant Open-Source Examples**

These projects are worth studying selectively. None justify turning 12 Moons into a dependency-heavy project.

| Project | License / maintenance | Specific systems worth studying | Reuse posture |
|---|---|---|---|
| Godot demo projects | MIT; official Godot ecosystem | JSON/save examples and idiomatic engine APIs | Direct snippets possible with license compliance; mostly educational |
| GdUnit4 | MIT; actively maintained in 2026 | test runner, fuzzing, scene tests, CI/action integration | Already used; keep as actual dependency |
| boardgame.io | MIT; mature turn-based framework | `src/plugins/plugin-random.ts`, `src/core/player-view.ts`, `src/master/filter-player-view.ts`, game/move architecture, testing docs | Conceptual architecture; TypeScript code not directly useful to Godot |
| Battle for Wesnoth | GPL v2+; actively maintained in Sep 2026 | `src/synced_context.cpp`, `src/synced_context.hpp`, synchronized RNG/replay concepts | Conceptual only unless project licensing is GPL-compatible |
| Unciv | MPL-2.0; active modern project | Ruleset Validator, typed “Unique” content validation, mod content structure docs | Conceptual; direct copied files bring MPL obligations |
| Godot State Charts | MIT; Godot 4 | transition validation and runtime state debugging | Do not add now; useful reference for debug UX |
| Pandora | MIT; Godot 4, explicitly alpha | editor/data registries, entity/category IDs, content testing | Study tooling patterns only; not appropriate dependency |
| SaveKit | MIT; updated June 2026 | serializer/deserializer boundaries and JSON/binary format separation | Conceptual; its node/resource saving model should not become 12 Moons authority |

GdUnit4's repository currently identifies itself as an embedded Godot 4 testing framework with scene testing, mocking and automated-test features, and upstream activity continued into July 2026. citeturn14search0turn14search2

Repository URL:

`https://github.com/godot-gdunit-labs/gdUnit4`

This is the strongest direct dependency example because 12 Moons already uses it.

Godot State Charts is MIT-licensed and designed around declarative statecharts, guards and an in-game debug view. Those capabilities are interesting references, but they are **technically more sophisticated than this run needs**. A ten-phase explicit `RunState.phase` plus controller validation is easier for one developer and AI agents to inspect. citeturn14search3

Repository URL:

`https://github.com/derkork/godot-statecharts`

Pandora is a Godot 4 data-management project with editor tooling and tests, but its own README marks it alpha/not production-ready. Its useful lesson for 12 Moons is stable data IDs and validation/editor tooling—not adopting an RPG entity framework. citeturn14search7

Repository URL:

`https://github.com/bitbrain/pandora`

SaveKit is MIT-licensed, targets modern Godot 4.5+, supports JSON/binary serialization and explicit serializer/deserializer extension points, and was updated in June 2026. Its architecture is useful to inspect, but its “save Nodes/resources” orientation is intentionally different from 12 Moons' requirement that scene-tree state not be authoritative. citeturn14search1turn14search11

Repository URL:

`https://github.com/fernforestgames/godot-savekit`

boardgame.io is particularly useful conceptually because its architecture separates game moves/state, seeded random functionality, player-specific views and testable random behavior. Its source contains a dedicated random plugin and player-view filtering rather than letting presentation code determine hidden-state visibility. fileciteturn16file1L17-L32 fileciteturn17file6L78-L88 fileciteturn17file8L109-L119

Repository URL:

`https://github.com/boardgameio/boardgame.io`

Do **not** import its architecture wholesale. Its networking/plugin abstractions solve a much broader web-board-game framework problem.

Battle for Wesnoth is a much larger project, but its synchronized-context code explicitly connects synchronized actions, replay and synchronized RNG. The repository remains active and is GPL v2+; GitHub showed main project activity as recently as September 16, 2026. fileciteturn18file0L1-L19 fileciteturn18file1L20-L38 citeturn11search0turn11search10

Repository URL:

`https://github.com/wesnoth/wesnoth`

The license means this should be treated primarily as conceptual inspiration unless 12 Moons' own licensing strategy is compatible with GPL requirements.

Unciv provides a strong content-validation precedent. Its mod/content documentation describes typed gameplay “Uniques” and a Ruleset Validator that flags unknown/invalid content, which is exactly the kind of fail-fast behavior 12 Moons needs for modifier definitions. Unciv is MPL-2.0 and remained actively discussed/developed in 2026. citeturn11search8turn11search13turn11search11

Repository URL:

`https://github.com/yairm210/Unciv`

The relevant documentation path is:

```text
docs/Modders/Mod-file-structure/1-Overview.md
```

and the broader system worth examining is its Ruleset Validator.

Godot's official demo repository is still the appropriate source for small idiomatic FileAccess/JSON examples rather than generic tutorials. Conceptually, however, its simple examples should not be mistaken for a complete migration/backup save strategy.

Repository URL:

`https://github.com/godotengine/godot-demo-projects`

Across these examples, the practical lesson is **copy ideas before copying systems**.

**Recommended Repository Structure**

A structure aligned with the current project would be:

```text
scripts/
  core/
    # Existing deterministic match engine.
    action_result.gd
    card_catalog.gd
    card_definition.gd
    deck_state.gd
    game_action.gd
    game_state.gd
    january_setup.gd
    match_controller.gd
    matching_rules.gd
    player_state.gd
    public_state_view.gd
    replay_log.gd
    yaku_evaluator.gd

  run/
    run_state.gd
    run_action.gd
    run_action_result.gd
    run_controller.gd
    run_replay_log.gd
    match_result.gd
    pending_settlement.gd

  modifiers/
    modifier_definition.gd
    modifier_instance.gd
    modifier_registry.gd
    effect_spec.gd
    effect_operation.gd

    resolution/
      capture_plan.gd
      capture_resolver.gd
      score_breakdown.gd
      score_resolver.gd
      multiplier_resolver.gd
      action_effect_provider.gd
      reward_effect_resolver.gd

    effects/
      chaff_point_effect.gd
      sweep_effect.gd
      mulligan_effect.gd
      second_draw_effect.gd
      quad_koi_effect.gd
      wider_choice_effect.gd

  rewards/
    reward_state.gd
    reward_request.gd
    offer_slot_spec.gd
    reward_offer.gd
    offer_generator.gd

  shop/
    shop_state.gd
    shop_offer.gd
    shop_request.gd
    shop_generator.gd
    price_rules.gd

  save/
    save_codec.gd
    save_store.gd
    save_migrations.gd

  telemetry/
    telemetry_event.gd
    telemetry_sink.gd
    null_telemetry_sink.gd
    jsonl_telemetry_sink.gd

  simulation/
    simulation_runner.gd
    policies/
      random_legal_policy.gd
      heuristic_policy.gd

  debug/
    debug_scenario_factory.gd

  ui/
    # Existing UI plus:
    between_month/
      settlement_view.gd
      reward_view.gd
      carry_view.gd
      shop_view.gd
      february_placeholder.gd

data/
  hanafuda/
    cards.json

  modifiers/
    modifiers.json

  moons/
    moons.json

  run/
    run_rules.json
    shop_tables.json

resources/
  presentation/
    modifiers/
    moons/

tools/
  validate_project.gd
  validate_content.gd
  simulate_runs.gd

tests/
  core/
  hanafuda/
  ai/
  run/
  modifiers/
  rewards/
  shop/
  save/
  determinism/
  simulation/
  integration/

docs/
  architecture/
    run-state.md
    modifiers.md
    determinism.md
    save-format.md
```

The current repository already has `core`, `ai`, `run` and `ui` top-level script areas, although `scripts/run` currently contains validation scripts rather than run-domain code. fileciteturn6file0L2-L2 fileciteturn8file0L2-L2

I would move the validation entry points toward `tools/` as the new run domain takes over `scripts/run/`; this is organization cleanup, not an architectural requirement.

Do not create:

```text
managers/
services/
repositories/
providers/
factories/
adapters/
use_cases/
```

as broad architectural layers. A named helper should exist because the game has a concrete need for it.

**Architecture Decisions to Lock Before Implementation**

There are three distinct categories.

**True game-design decisions**

These must not be silently answered by engineering:

| Decision | Why it matters technically |
|---|---|
| Shared-pool rewards vs one-per-family | Determines RewardRequest slot policy |
| Wider Choice's fourth category in quota model | Needed for deterministic generation |
| Mulligan return/shuffle procedure | Changes deck semantics and replay |
| Second Draw with one/no remaining card | Must have deterministic legality |
| Modifier duplicate/stacking policy | Eligibility and conflict validation |
| Card Upgrade stacking on same physical card | Attachment rules |
| Full inventory behavior for a selected reward | Pending acquisition/replacement rules |
| Full inventory behavior for shop purchase | Buy rejection vs replace/sell transaction |
| Resale formula/eligibility | Liquidation and shop sales |
| Voluntary bankruptcy | Liquidation action set |
| Conflicting replacement effects | Compatibility/game rule |
| Whether specific Card Upgrade targets are random or player-selected | Offer representation |

**Engineering decisions that should be locked now**

These have strong answers:

```text
RunState remains separate from match GameState.

RunController is sole run mutation gateway.

MatchController remains sole match mutation gateway.

Runtime authoritative state uses RefCounted/plain serializable data.

Generated offers are authoritative state.

Run actions are stable serializable commands.

Copy-validate-commit is used for run transactions.

Modifier definitions are separate from modifier instances.

Base card definitions are never mutated per run.

Card upgrades attach by stable physical card ID.

Card-owned and player-owned effect semantics are explicit.

Effects use small typed rule hooks rather than ID conditionals or a universal bus.

Pending choices are authoritative phases.

JSON is the authoritative save/content interchange format.

Save format is explicitly versioned.

Gameplay RNG uses a root seed plus hashed deterministic scopes.

UI/VFX never consume gameplay RNG.

Content IDs/handler mappings are validated headlessly.

GdUnit4 remains the test framework.

Telemetry observes successful commits only.
```

**Prototype values that must stay configurable**

```text
starting bankroll = 20
reserve capacity = 4
active maximum = 8
unlock schedule Jan–Aug
reward refusal cash = +2
reroll costs = [1, 2]
number of reward offers
rarity weights
modifier weights
prices
resale values
shop special-slot weights
```

Do not bury those in effect handlers.

**Things NOT to Build Yet**

The architecture is strongest when it actively rejects unnecessary scope.

Do not build:

```text
Cloudflare multiplayer backend
matchmaking
accounts
Steam networking
rollback netcode
TypeScript duplicate rules engine
cross-language PRNG implementation
generic ability DSL
generic event/message bus
ECS
dependency injection framework
service locator
statechart plugin
database
generic item/inventory framework
modding/plugin API
all twelve Moon implementations
full House Rules infrastructure
every planned modifier
sophisticated AI search
cloud telemetry provider
full analytics dashboard
save encryption
cloud saves
binary/compressed save format
replay-video viewer
generic modifier dependency graph
production rarity economy
procedural route/map framework
separate controller/manager for every run screen
```

The run does not need “more architecture.” It needs a few explicit boundaries that remain hard to violate.

## Risks and implementation sequence

**Risk Register**

| Risk | Likelihood | Severity | Cost if fixed late | Mitigation |
|---|---:|---:|---:|---|
| Modifier ID conditionals spread through systems | High | High | Very high | Typed effect registry/pipelines now |
| Effect-order ambiguity | High | High | Very high | Stages, priorities, replacement semantics now |
| Global RNG coupling | Medium-high | High | High | Scoped derived RNG |
| UI becomes economic authority | Medium | High | High | RunActions only |
| `RunController` grows monolithic | Medium | High | Medium-high | Delegate pure generators/resolvers, not mutation |
| Too many micro-controllers/managers | High with AI agents | Medium-high | High | One run authority; review checklist |
| Save schema drift | Medium | High | High | Explicit version/migrations from v1 |
| Silent unknown-content fallbacks | Medium-high | High | High | Validators + hard development errors |
| Shared mutable Resources | Medium | High | Medium | Runtime RefCounted, immutable Resources |
| Reward/shop duplicate implementations | Medium | Medium-high | Medium | Shared offer-generation primitives |
| Physical card duplication from upgrades | Medium | Critical | High | Attachments by stable card ID + existing invariants |
| Reserve modifiers accidentally active | Medium | High | Medium | Active effect projection + invariant tests |
| Double settlement/purchase | Medium | High | Medium | Stable transaction IDs + copy/commit |
| Liquidation special-cased in UI | Medium | High | High | Explicit run phase |
| Second Draw implemented through coroutine timing | Medium | High | High | Explicit draw-reveal decision state |
| Over-general ability engine | Medium-high | Medium-high | High | Add hook only for concrete effect domain |
| AI cannot understand effects | Medium | Medium | Medium later | Forward simulation + semantic metadata |
| Future server port diverges | Low now / higher later | High | High | JSON contracts + golden fixtures |
| Engine upgrade changes RNG reconstruction | Low-medium | High for old replays | Medium | Save generated outcomes, version replays, golden tests |
| AI agents create parallel sources of truth | High | High | Very high | Mandatory architecture review gates |
| Debug cheats corrupt state | Medium | Medium | Medium | Validated scenario factories |
| Average-based simulation misleads balance | High | Medium | Low-medium | Percentiles/conditional metrics + human playtests |

The three risks worth treating as **architecture blockers** are modifier special-case leakage, effect-order ambiguity and RNG coupling. They are cheap to prevent now and expensive to untangle after dozens of modifiers.

**Recommended Implementation Order**

The implementation sequence below keeps the January-to-February milestone narrow while proving each architectural boundary.

| Step | Dependency | Main code area | Required tests | Acceptance condition |
|---|---|---|---|---|
| Define architecture contracts | Existing January | `docs/architecture/` | Review current invariants | Run/match authority, phases, action semantics and RNG model documented |
| Add `RunState` | None beyond content IDs | `scripts/run/` | defaults, serialization, canonical hash, invariants | Valid new run represents January + 20 bankroll + capacities correctly |
| Add `RunAction` / `RunController` | `RunState` | `scripts/run/` | accept/reject, hash unchanged on rejection | All run mutation passes one controller |
| Add `MatchResult` bridge | Run controller + existing match | `core/`, `run/` | terminal-only ingestion, duplicate result rejection | January terminal result can enter run layer without UI changing money |
| Implement settlement | MatchResult | `run/` | win, loss, exact zero, double-settlement rejection | Bankroll changes exactly once according to resolved score |
| Implement liquidation phase | Settlement | `run/` | insufficient funds, partial sale, successful recovery, bankruptcy | Currency never needs to go invalid/negative |
| Implement slot unlock + carry state | Settlement | `run/`, `modifiers/` | capacity, uniqueness, active/reserve | January completion yields one legal active slot |
| Add modifier definitions/instances/registry | Carry model | `modifiers/`, `data/modifiers/` | IDs, handler mapping, target validity | Card/player ownership and attachment survive round-trip |
| Add run content validator | Modifier registry | `tools/` | deliberately malformed fixture tests | CI/headless run rejects invalid modifier content |
| Build reward request/generator | RNG scopes + modifiers | `rewards/` | deterministic offers, eligibility, both policies | Both disputed reward models use same generator |
| Implement Wider Choice | Reward pipeline | `modifiers/effects/`, `rewards/` | 3→4, reserve inactive | First real modifier proves run-layer hook architecture |
| Implement reward selection/refusal | RewardState | `run/`, `rewards/` | once-only selection, +2 configured refusal | Reward cannot be taken twice |
| Implement carry-management actions | Modifier instances | `run/` | move/placement/capacity | Active/reserve changes are authoritative and replayable |
| Build six-slot ShopState/generator | RNG + offer framework | `shop/` | slot categories, deterministic initial inventory | Six offers persist in state |
| Implement buy/sell/reroll | Shop state | `run/`, `shop/` | atomicity, funds, sold flag, `[1,2]`, no third | Invalid transaction changes nothing |
| Add save format v1 | Run state now stable | `save/` | each between-month phase round-trip | Close/reload during reward/carry/shop resumes identically |
| Add migration harness | Save v1 | `save/`, `tests/save/` | v1 fixture migration identity | Future schema can evolve without redesign |
| Build scenario/debug harness | Stable phases | `debug/` | fixture invariants | One action jumps to settlement/reward/shop/bankruptcy states |
| Build between-month UI | All domain flow | `ui/between_month/` | headless scene flow | UI contains no direct economic/carry mutation |
| Add February placeholder | Finalize command | run/session/UI | full January→Feb integration | `FINALIZE_BUILD` reaches deterministic February placeholder |
| Expand determinism matrix | Complete milestone | `tests/determinism/` | seed sweep, replay, save continuation | Same seed/actions reproduce hashes |
| Add modifier match seams | After milestone unless immediately needed | `core/`, `modifiers/` | synthetic hook tests | Capture/score/draw/multiplier hooks exist without ID checks |
| Implement match-side modifiers when gameplay needs them | Seam exists | `effects/` | six-modifier matrix above | Each modifier uses normal authoritative rules path |
| Add simulation runner | Stable run loop | `simulation/`, `tools/` | fixed seed cohort | Hundreds/thousands of runs reproducible headlessly |
| Add telemetry sinks | Stable domain events | `telemetry/` | event schema/dedup ID | Telemetry failure cannot affect gameplay |

The crucial bridge is the first five domain steps:

```text
existing January MatchController
          ↓
       MatchResult
          ↓
     new RunController
          ↓
        RunState
          ↓
settlement / reward / carry / shop
```

That preserves January rather than putting it behind a new framework.

**Final architecture judgment**

12 Moons is already built around the right fundamental idea: **authoritative deterministic data receives explicit legal actions, mutations occur through one controller, and the presentation is downstream of truth**. The repository's current `GameState` has strong physical-card invariants and canonical hashing, while `MatchController` already performs copy-apply-validate-commit transactions. Those are not prototype shortcuts to replace; they are the foundation of the complete game. fileciteturn9file0L2-L2 fileciteturn10file0L2-L2

The smallest architecture capable of carrying the game through December is therefore:

```text
ONE persistent RunState
ONE RunController mutation gateway

ONE match state per active month
ONE MatchController mutation gateway

ONE explicit modifier registry
A SMALL SET of typed rule pipelines

ONE root seed
MANY deterministic derived RNG scopes

ONE explicit versioned save schema
ONE invariant-driven validation philosophy

PLAIN serializable commands
PLAIN stable IDs

UI observes and requests.
Controllers decide.
State records.
Rules calculate.
Effects transform typed rule results.
Tests prove invariants.
Replays prove reproducibility.
```

Everything else should justify its existence against that model.

The defining rule for future development should be:

> **No new feature gets a private path around authoritative state.**

Money, rewards, shops, carry slots, Card Upgrades, Moon effects, Koi-Koi replacements, liquidation, save/load, AI, telemetry and eventual multiplayer can all remain tractable if they enter through the same explicit transaction boundary that January already uses. That gives 12 Moons enough architecture to safely become a twelve-month roguelike without turning a compact deterministic hanafuda game into a generalized game-engine framework.