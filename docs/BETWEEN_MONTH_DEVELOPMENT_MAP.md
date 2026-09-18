# Between-Month Development Map

Status: Planning map only. Expand each section into a dedicated design/implementation spec before building it.

This document defines the next ordered development steps after the playable January match and initial card-motion pass. It is intentionally concise. The goal is to preserve the sequence, dependencies, and current design-authority status while we expand one item at a time.

## North-Star Milestone

Prove the first complete roguelike month loop around the existing hanafuda game:

`play January → settle money → unlock carry capacity → choose reward → manage carry build → shop → finalize build → Begin February`

For this milestone, **Begin February may end at a clean placeholder**. Do not build February gameplay until the between-month loop itself is proven.

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
- Present the money change clearly on or immediately after the January result screen so the player understands why the bankroll changed.

**Authority status:** APPROVED PROTOTYPE BASELINE / still subject to playtesting.

**Expansion later:** exact bankruptcy presentation, liquidation UX, economy telemetry, and tuning.

---

## 2. Unlock the First Carry Slot

Introduce the primary roguelike build capacity immediately after January settlement.

- Completing January unlocks **active carry slot #1**.
- Carry capacity ultimately reaches 8 active slots.
- One normal active slot unlocks after each completed month through August.
- The first unlocked slot should be visible before the player makes the post-January reward/build decisions.
- This step should establish the underlying run-state representation for active carry capacity without implementing later-month progression yet.

**Authority status:** LOCKED.

**Expansion later:** slot presentation, early-unlock effects, full 8-slot layout, and month-by-month unlock feedback.

---

## 3. Free Reward Choice

Add the dependable build-growth layer that occurs after every completed month.

- Present **3 free modifier offers**.
- Player chooses **1**.
- Player may refuse the reward set and take the current working **+2 currency** alternative.
- Losing January must still grant the normal reward opportunity. Loss affects economic position, not access to basic build growth.
- Reward generation should use the approved modifier pool rather than inventing a new relic/item system.

### Authority conflict to resolve before implementation

The current authority contains two instructions that should not be silently reconciled:

- **Carry Build / LOCKED:** three reward offers are drawn from the full modifier pool and do **not** need to contain one from each family.
- **Solo Reward and Economy Baseline / APPROVED PROTOTYPE BASELINE:** present one Card Upgrade, one Hand/Mechanic Modifier, and one Strategic/Meta Modifier.

Before implementation, explicitly decide which prototype rule supersedes the other and update the canonical authority accordingly.

**Expansion later:** reward-generation weighting, duplicate handling, offer presentation, refusal UX, and modifier previews.

---

## 4. Carry-Build Management Screen

Give the player a place to understand and manage the build before entering the next Moon.

- Show the currently unlocked active carry slots.
- After January, only active slot #1 is normally unlocked.
- Show the reserve/bank separately from the active build.
- Current working reserve recommendation: **4 reserve slots**.
- Reserve modifiers have no effect while inactive.
- Allow active/reserve rearrangement only during the between-month management phase.
- Make active versus inactive status visually unmistakable.
- Keep this system centered on the three approved functional modifier families:
  - Card Upgrades
  - Hand/Mechanic Modifiers
  - Strategic/Meta Modifiers

**Authority status:** active carry system LOCKED; 4-slot reserve is WORKING INITIAL.

**Expansion later:** drag/drop or click management, overflow handling, replacement UX, selling from reserve, and later full-build refinement.

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

Core shop actions:

- Buy.
- Sell where allowed.
- Reroll the full shop.
- Manage active and reserve modifiers.
- Leave/finalize the shop.

Current reroll baseline:

- First reroll: **1 currency**
- Second reroll: **2 currency**
- No third reroll in the same shop.

Rerolls should preserve the six offer-slot categories instead of becoming an unrestricted search for any exact effect.

**Authority status:** shop direction LOCKED; exact prices, rarity distribution, and some inventory details remain prototype values.

**Expansion later:** price bands, rarity, services, liquidation UX, offer persistence, Rain Check behavior, and economic tuning.

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

**Authority status:** APPROVED PROTOTYPE DIRECTION.

**Expansion later:** the remaining approved modifiers, modifier presentation, pricing, AI awareness, interactions, safeguards, and balance.

---

# First Between-Month Acceptance Loop

The first complete implementation should allow this exact flow:

1. Play and finish January.
2. Resolve January score.
3. Apply the currency settlement.
4. If required, handle emergency liquidation before bankruptcy.
5. Unlock active carry slot #1.
6. Present the free reward choice or cash refusal.
7. Place/manage the acquired modifier in active or reserve space as legal.
8. Enter the six-offer shop.
9. Buy, sell, reroll, and rearrange the carry build.
10. Finalize the build.
11. Reach a clear **Begin February** transition.
12. Stop at a placeholder rather than implementing February gameplay as part of this milestone.

---

# Development Order

Do not parallelize these systems blindly. Build them in dependency order:

1. Run money state and January settlement.
2. Carry-slot unlock state.
3. Reward-generation and reward-selection state.
4. Active/reserve carry-state management.
5. Shop inventory and transactions.
6. Representative modifier execution.
7. Full between-month UI flow.
8. End-to-end playtest from January through the February placeholder.

The primary design question for this milestone is:

> Does finishing a hanafuda month and immediately making build/economy decisions create a compelling roguelike loop worth repeating across twelve Moons?

Do not expand into February, additional Moon rules, or a large modifier catalogue until this loop is understandable and fun enough to justify more content.
