# Between-Month Development Map

Status: Planning map only. Expand each section into a dedicated design/implementation spec before building it.

This document defines the next ordered development steps after the playable January match and initial card-motion pass. It incorporates the current UX research direction while preserving the Game Design Authority as the source of truth for gameplay rules. Research-derived UI recommendations in this document are implementation guidance, not silent changes to locked or unresolved game rules.

## North-Star Milestone

Prove the first complete roguelike month loop around the existing hanafuda game:

play January → settle money → unlock carry capacity → choose reward → prepare carry build → shop → finalize build → Begin February

For this milestone, **Begin February may end at a clean placeholder**. Do not build February gameplay until the between-month loop itself is proven.

The between-month experience should feel like a continuation of the same tabletop world, not a stack of unrelated menus. Settlement, reward, carry management, shop, and finalization should occupy one shared preparation environment with stable spatial anchors for the carry build and bankroll.

---

## 0. UX Architecture Foundation

Build the reusable interface foundation before the between-month feature surface multiplies.

### Shared preparation shell

- Establish one persistent between-month **PhaseShell / preparation-table environment**.
- Use a restrained orientation rail such as:
  - Settlement
  - Reward
  - Prepare
  - Shop
  - February
- The rail communicates progression. It should not behave like a tab bar unless backtracking is intentionally supported.
- Settlement should visually transform from the January result rather than cutting to a completely unrelated dashboard.
- Reward and shop offers should reuse the same offer region.
- Carry and bankroll should remain in stable locations through reward, preparation, shop, and finalization.

### Structural layout rules

- New major UI structure should use Godot Control and Container composition instead of multiplying fixed absolute positions.
- Preserve 1280 × 720 as the current canonical prototype canvas.
- Do not change stretch behavior merely to hide layout problems. Containerize the major regions first.
- Keep hanafuda cards as the primary visual objects. Interface chrome must not compete with the card art.
- Do not create a new panel for every piece of information. Prefer spatial grouping, trays, sheets, slots, and one clear table surface.
- Modifier offers must use a visual silhouette/material grammar distinct from hanafuda cards.

### Theme and component foundation

Create a lightweight project Theme and reusable semantic components before reward/shop implementation.

Initial semantic roles should cover:

- table / inset / raised / overlay surfaces;
- primary / secondary / muted text;
- subtle / strong / focus borders;
- selectable / selected / disabled / invalid / warning states;
- economy gain / loss;
- active / reserve / locked carry states;
- the three modifier families.

High-value reusable components:

- HanafudaCardView or the existing MoonCardView evolved into that role;
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

Do not prematurely lock final hues, exact corner radii, or decorative materials in this milestone.

### Input and focus architecture

The primary interaction grammar should be:

**focus/select → inspect if needed → choose target/destination → commit**

- Mouse hover and drag may accelerate interaction but must never be required.
- Click-select-click / focus-select-destination is the canonical carry interaction.
- Pointer, keyboard, and controller paths should invoke the same semantic commands.
- Do not bind gameplay mechanics directly to Godot's built-in focus-navigation actions.
- Make playable card controls focusable. Remove FOCUS_NONE as the interaction policy for MoonCardView.
- Define explicit focus neighbors for hands, offer grids, carry rows, reserve rows, and decision surfaces where automatic focus guessing is ambiguous.
- After phase changes, rerolls, purchases, sales, swaps, or dialogs, restore focus deliberately with a defined destination.
- Every hover tooltip must have an equivalent focus/inspect path.

### Readability and accessibility baseline

- Raise meaningful UI text out of the current 9–10 px range.
- Prototype target: roughly 14–16 px for body/mechanical text, 16–18 px for actions/important values, and 12–14 px only for genuinely secondary metadata.
- Verify actual rendered size at 1280 × 720 rather than treating the Godot font-size number as certification.
- Never communicate a gameplay state by color alone.
- Focus should use a clear border/shape/weight change, not glow alone.
- Keep reduced-motion behavior centralized through the presentation timing system.
- No essential information may exist only as a transient animation or audio cue.
- Add accessibility names/descriptions to reusable semantic controls as they are created.
- Keep layouts localization-resilient: wrapping labels, content-sized buttons, translatable complete phrases, and periodic pseudolocalization checks.

### Current January UX debt to clear before the interface surface grows

These are not new gameplay rules. They are presentation corrections that become more expensive if deferred.

- Replace the full-screen, heavily dimmed Stop / Koi-Koi modal with a context-preserving decision tray so the table and public opponent information remain readable.
- Keep current score, relevant yaku progress, known Koi-Koi consequences, and opponent public threats accessible during that decision.
- Retain current legal-target assistance but evolve it toward stable selection/focus outlines rather than broad dimming or constant glow.
- Preserve hanafuda artwork as the dominant card identity. Helper marks should live at the perimeter and remain optional.
- Keep Japanese hanafuda terms consistent and provide English support rather than alternating among multiple player-facing names for the same class.

**Authority status:** UX implementation direction from research. No gameplay-rule authority changes are created by this section.

---

## 1. Money + January Settlement

Build the economic handoff from the completed January result into the run state.

- Start the solo prototype with the current **20 currency** baseline.
- Use resolved hanafuda/yaku score as the core money scale.
- A winning result adds the resolved score.
- A losing result subtracts the resolved score.
- Koi-Koi and other score multipliers affect the economic result through the final resolved score.
- Spending down to 0 is legal.
- If a settlement debt cannot be covered, allow the authority-defined emergency-liquidation step before bankruptcy.
- Settlement should appear as a readable ledger or sheet attached to the current table context rather than as an unrelated result dashboard.
- Present the scoring/economic chain in one causal direction:
  1. yaku;
  2. Moon/additive adjustments;
  3. multipliers;
  4. final resolved score;
  5. economic result;
  6. bankroll.
- Animate/reveal one causal step at a time. Do not animate every row simultaneously.
- Keep the bankroll visible from settlement forward, with the delta shown locally when it changes.

**Authority status:** APPROVED PROTOTYPE BASELINE / still subject to playtesting.

**Expansion later:** exact bankruptcy presentation, liquidation UX, economy telemetry, and tuning.

---

## 2. Unlock the First Carry Slot

Introduce the primary roguelike build capacity immediately after January settlement.

- Completing January unlocks **active carry slot #1**.
- Carry capacity ultimately reaches 8 active slots.
- One normal active slot unlocks after each completed month through August.
- Show the full eventual eight-slot active tray from the first between-month sequence.
- Locked future slots remain physically visible and unmistakably unavailable.
- Reveal slot #1 changing from locked to available **before** the player sees the free reward choice.
- Use placement + slot form + lock state, not color alone, to communicate locked versus available.
- Keep slot-unlock feedback short and causal. Do not add a separate congratulations dialog.
- This step should establish the underlying run-state representation for active carry capacity without implementing later-month progression yet.

**Authority status:** LOCKED.

**Prototype presentation values still adjustable:** exact slot dimensions, spacing, unlock timing, and ornament.

---

## 3. Free Reward Choice

Add the dependable build-growth layer that occurs after every completed month.

- Present **3 free modifier offers**.
- Player chooses **1**.
- Player may refuse the reward set and take the current working **+2 currency** alternative.
- Losing January must still grant the normal reward opportunity. Loss affects economic position, not access to basic build growth.
- Reward generation should use the approved modifier pool rather than inventing a new relic/item system.
- Reward offers appear in the shared preparation shell while the carry tray and bankroll remain visible.
- Modifier offers must look materially different from hanafuda cards.
- Each normal offer should prioritize:
  - family;
  - name;
  - one concise mechanical sentence;
  - target/requirement if needed;
  - FREE.
- Focus/inspect should reveal fuller rule text without permanently printing long paragraphs on every offer.
- The cash refusal must be explicit, such as **Take +2 currency**, not hidden under a vague Skip action.
- If a reward requires choosing a hanafuda target, enter a clear target-selection mode using the same legal-target grammar as gameplay.
- Before commitment, show the destination or replacement consequence when one is required.
- Acquisition should visibly move the chosen modifier into the carry/reserve system so ownership is spatially clear.

### Authority conflict to resolve before implementation

The current authority contains two instructions that should not be silently reconciled:

- **Carry Build / LOCKED:** three reward offers are drawn from the full modifier pool and do **not** need to contain one from each family.
- **Solo Reward and Economy Baseline / APPROVED PROTOTYPE BASELINE:** present one Card Upgrade, one Hand/Mechanic Modifier, and one Strategic/Meta Modifier.

Before implementation, explicitly decide which prototype rule supersedes the other and update the canonical authority accordingly.

**Expansion later:** reward-generation weighting, duplicate handling, rarity if any, deeper comparison logic, and final art treatment.

---

## 4. Carry-Build Preparation

Carry management is part of the shared preparation table, not a disconnected inventory screen.

- Keep all 8 eventual active slots visible.
- After January, only active slot #1 is normally unlocked.
- Show the reserve/bank as a separate named storage region.
- Current working reserve recommendation: **4 reserve slots**.
- Reserve modifiers have no effect while inactive.
- Allow active/reserve rearrangement only during the between-month management phase unless a specific approved modifier says otherwise.
- Make active, reserve, locked, empty, selected, disabled, ready, and used states distinguishable by structure and symbols, not opacity/color alone.
- Primary operation:
  - select source modifier;
  - show valid destinations;
  - select destination;
  - commit the move.
- Optional drag-and-drop may call the same underlying move command, but drag must never be required.
- Selling must be an explicit action. Dragging an item out of the tray must not mean sell.
- A move should be represented internally by one source-of-truth command such as move_modifier(source, destination), independent of input method.
- Keep this system centered on the three approved functional modifier families:
  - Card Upgrades
  - Hand/Mechanic Modifiers
  - Strategic/Meta Modifiers

**Authority status:** active carry system LOCKED; 4-slot reserve is WORKING INITIAL.

**Do not build yet:** sorting/filtering systems, radial menus, separate inventory/loadout screens, advanced collection browsing, or unlimited reserve storage.

---

## 5. Minimal Six-Offer Shop

Implement the first functional between-month shop after the free reward choice.

Initial shop map:

1. **Card Upgrade**
2. **Hand/Mechanic Modifier**
3. **Strategic/Meta Modifier**
4. **Wildcard modifier**
5. **Wildcard modifier**
6. **Service / special item / economy / slot-access / other nonstandard opportunity**

### Shop presentation

- Reuse the shared offer region rather than changing to a new environment.
- Keep bankroll, active carry, reserve, and phase position visible.
- Use a **3 × 2 offer grid** at the current 1280 × 720 prototype target.
- Keep sold offer tiles spatially stable and mark them SOLD rather than collapsing/reflowing the grid.
- Keep unaffordable offers visible and state the shortfall directly, such as **Need 3 more**.
- Focusing an offer should update a stable inspect/compare area rather than spawning a modal.
- Mechanical prose should be left-aligned and concise.

### Core shop actions

- Buy.
- Sell where allowed.
- Reroll the full shop.
- Manage active and reserve modifiers.
- Leave/finalize the shop.

### Purchase and capacity behavior

Recommended UX direction, subject to the eventual inventory command contract:

- If reserve has room, purchase may land there by default, followed by an optional Equip action.
- If an active slot is empty, offer Equip now rather than forcing a destination dialog before every purchase.
- If both active and reserve capacity are full, resolve replacement/sale requirements **before** deducting currency.
- Never silently reject a legal-looking purchase.
- Routine purchases should not receive generic Are you sure? dialogs. Confirm only unusual destructive actions.

### Reroll baseline

- First reroll: **1 currency**
- Second reroll: **2 currency**
- No third reroll in the same shop.

- Rerolls should preserve the six offer-slot categories instead of becoming an unrestricted search for any exact effect.
- Show the current reroll price before commitment.
- If the next reroll cost is deterministic, show it before the player commits the current one.
- Restore focus predictably after reroll, purchase, sale, or offer removal.

**Authority status:** shop direction LOCKED; exact prices, rarity distribution, service contents, and some inventory details remain prototype values.

**Expansion later:** price tuning, rarity if needed, services, liquidation UX, Rain Check behavior, offer persistence, and economy telemetry.

---

## 6. Wire a Small Representative Modifier Set

Do **not** implement the entire approved modifier catalogue immediately.

First prove that all three modifier families can operate cleanly through the deterministic rules engine and the new between-month flow.

Recommended first implementation set:

### Card Upgrades
- **Chaff Point Upgrade**
- **Sweep**

### Hand/Mechanic Modifiers
- **Mulligan**
- **Second Draw**

### Strategic/Meta Modifiers
- **Quad Koi**
- **Wider Choice**

These effects are already part of the approved prototype modifier direction. The purpose of this initial subset is architectural coverage, not final balance.

The first six should prove:

- an upgrade attached to an existing one-of-48 game card;
- a card upgrade that changes capture behavior;
- a pre-month hand-management decision;
- a draw-manipulation decision during play;
- a Stop/Koi-Koi economic/risk modifier;
- a reward-system modifier that changes the between-month layer.

Modifier UI requirements:

- family is communicated by icon/shape/pattern plus text support, not color alone;
- full modifier text is available through focus/inspect;
- card upgrades preserve the original hanafuda card identity and use a standardized peripheral upgrade seal/frame;
- triggering feedback scales with importance and frequency;
- frequent modifier triggers must remain quieter than yaku completion, Koi-Koi, slot unlock, or month completion.

**Authority status:** APPROVED PROTOTYPE DIRECTION.

**Expansion later:** remaining approved modifiers, pricing, AI awareness, interactions, safeguards, balance, and final names/art.

---

## 7. Finalize Build + February Placeholder

Create a deliberate end state for the between-month sequence.

- Keep the finalized active build, reserve count, and remaining bankroll visible.
- Use the exact action copy **Begin February** rather than a generic Continue.
- Immediately near the final action, summarize:
  - active slots used/unlocked;
  - reserve count;
  - bankroll;
  - February / Snow Moon identity and rule if that rule has been approved by then.
- If the prepared build contains no unresolved invalid state, one press should finalize.
- Do not add a second confirmation dialog merely because the phase is ending.
- Transition into a February Moon banner / placeholder that preserves the same visual grammar.
- Reduced-motion mode must reach the same stable end state without relying on flourish.
- Stop at the placeholder for this milestone.

---

# Cross-Cutting UX Rules for This Milestone

These rules apply across settlement, reward, carry, shop, and finalization.

## Information hierarchy

Use this priority:

**physical objects → current choice → immediate consequences → persistent run state → explanation → decoration**

If hiding a fact could plausibly change the current decision, it must remain available without leaving the current decision context.

## Feedback hierarchy

- Minor: focus, hover, ordinary selection.
- Moderate: purchase, modifier trigger, currency change.
- Major: yaku completion, Koi-Koi, slot unlock, month completion.
- Exceptional: reserved for later run-defining events such as December completion.

Frequency and spectacle should be inversely related.

## Copy rules

Prefer exact actions:

- Take
- Equip
- Sell for X
- Reroll X
- Stop
- Koi-Koi
- Begin February

Avoid vague filler such as Continue Journey, Manage Your Modifiers, Insufficient Funds, or generic Confirm when a mechanical verb can be shown instead.

## Anti-slop constraints

- No generic dark-dashboard layer replacing the tabletop.
- No glow as the default indicator for every interactive or special state.
- No rounded panel around every label.
- No unrelated icon styles per feature.
- No modifier cards that visually masquerade as hanafuda.
- No repeated decorative badges without semantic meaning.
- No centered multiline mechanical paragraphs.
- No idle particles or shine sweeps behind routine menus unless they communicate an actual state change.
- No heavyweight card framework replacement. Reuse the current deterministic/presentation foundation and study external patterns narrowly.

---

# First Between-Month Acceptance Loop

The first complete implementation should allow this exact flow:

1. Play and finish January.
2. Resolve January score.
3. Transform the result into a readable settlement ledger without losing table continuity.
4. Apply the currency settlement.
5. If required, handle emergency liquidation before bankruptcy.
6. Show the eight-slot carry tray and unlock active carry slot #1.
7. Present the free reward choice or cash refusal while carry and bankroll remain visible.
8. Acquire the chosen modifier into a legal carry/reserve destination.
9. Rearrange active/reserve state through select → destination interaction.
10. Enter the six-offer shop in the same preparation environment.
11. Buy, sell, reroll, inspect, compare, and rearrange the carry build.
12. Finalize the build.
13. Reach a clear **Begin February** transition.
14. Stop at a February placeholder rather than implementing February gameplay.

The acceptance pass must also prove:

- all major between-month actions can be completed without mouse-only hover or required drag;
- focus remains visible and predictable after state mutations;
- no essential state relies on color alone;
- meaningful mechanical text is readable at the 1280 × 720 target;
- new structural UI does not depend primarily on hard-coded absolute positions;
- reward, carry, and shop feel like phases of one environment rather than separate apps;
- the player can explain where money changed, where a reward went, which modifiers are active, what is in reserve, what a shop action will cost, and what crosses into February.

---

# Development Order

Do not parallelize these systems blindly. Build them in dependency order:

1. Semantic Theme/tokens, readable typography baseline, focusable-control policy, inspect/tooltip equivalence, and shared input-action grammar.
2. Shared PhaseShell / preparation-table environment plus the visible eight-slot CarryTray and reserve region.
3. Refactor the current January Stop/Koi-Koi decision into a context-preserving tray and remove the most expensive focus/layout debt where touched.
4. Run money state and January settlement ledger.
5. Carry-slot unlock state and presentation.
6. ModifierCard / OfferGrid / InspectPanel foundations and reward selection.
7. Active/reserve carry-state commands and focus topology.
8. Shop inventory, transactions, 3 × 2 grid, rerolls, sell flow, and capacity-error handling.
9. Representative modifier execution.
10. Finalization summary and February placeholder.
11. End-to-end playtest with mouse, keyboard/controller focus path, reduced motion, and pseudolocalization stress.

The player-facing progression remains:

**Settlement → Slot Unlock → Reward → Prepare → Shop → Begin February**

The engineering order intentionally establishes shared layout, focus, carry, and component rules before the reward/shop surfaces can invent incompatible conventions.

---

# Things Not to Build Yet

Do not expand this milestone into:

- a tutorial campaign;
- a giant glossary or encyclopedia;
- separate Inventory / Loadout / Relics / Upgrades / Collection screens;
- advanced modifier search/filter/sort;
- touch-specific layouts or gesture-only controls;
- rich 3D binder/card physics;
- multiple shop categories/tabs;
- Moon-specific structural UI layouts;
- elaborate shopkeepers;
- deep run history, achievements, codex progression, or meta-progression;
- final color/material locking before the broader art direction is ready;
- predictive odds / best-move advice;
- a heavyweight replacement card framework;
- February gameplay or a large modifier catalogue.

The primary design question for this milestone is:

> Does finishing a hanafuda month and immediately making clear, tactile build/economy decisions in the same tabletop world create a compelling roguelike loop worth repeating across twelve Moons?

Do not expand into additional Moon gameplay until this loop is understandable, navigable, and fun enough to justify more content.
