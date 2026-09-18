# AGENTS.md

This file defines permanent working rules for AI coding agents operating in the 12 Moons repository.

It applies to the entire repository unless a more specific nested `AGENTS.md` is added later for a narrower subtree.

## 1. Project Identity

12 Moons is a deterministic Godot 4 hanafuda roguelike built around recognizable Koi-Koi play.

The game is not a generic deckbuilder or card-combat game. Preserve:

- the standard physical 48-card hanafuda deck;
- normal hanafuda month matching as the core interaction;
- traditional yaku as the scoring language;
- Stop / Koi-Koi risk decisions;
- a January-through-December run;
- money as the survival/shop resource;
- the eight-slot carry build;
- Moon rules that modify or reinterpret the existing hanafuda game rather than replacing it.

Do not introduce HP, energy, block, enemy-intent combat, route maps, duplicate deck copies above the standard 48 cards, or unrelated card-battler mechanics unless an explicit approved design change authorizes them.

## 2. Source-of-Truth Order

Before changing behavior, determine which source has authority.

### Game design authority

The canonical external design document is:

**12 Moons — Game Design Authority**

For gameplay rules, scoring, yaku, modifiers, Moon rules, economy, rewards, shops, carry/reserve behavior, AI behavior, multiplayer rules, progression, or other game-design decisions, consult the latest relevant sections before implementation.

Treat its status labels literally:

- **LOCKED** or **LOCKED PROTOTYPE RULESET**: do not change incidentally.
- **APPROVED DIRECTION**: preserve the direction while implementation details may be refined.
- **WORKING**, **PROTOTYPE**, or **TEST**: provisional and expected to change through testing.
- **UNRESOLVED**, **TBD**, **NOT YET LOCKED**, or contradictory instructions: do not silently invent a permanent rule.

If a task encounters an unresolved design issue:

1. do not guess;
2. implement neutral architecture or seams when possible;
3. document the blocker;
4. continue independent work that does not depend on the answer;
5. stop only when the unresolved decision prevents meaningful further progress.

When the user explicitly approves a new game-design decision, the canonical Game Design Authority must be updated so later work does not drift back to an obsolete rule.

Do not create a competing design-authority document inside this repository.

### Current implementation specification

For the current January-to-February milestone, the primary repository specification is:

`docs/BETWEEN_MONTH_DEVELOPMENT_MAP.md`

That document defines implementation architecture, UX, production/presentation standards, acceptance criteria, and deliberate non-goals. Follow it unless it conflicts with a newer explicit design-authority decision.

The research reports under `docs/` are reference material. The development map is the distilled implementation direction. Do not cherry-pick a research suggestion that the development map intentionally deferred or rejected.

### Existing code and tests

Existing code is evidence of current behavior, not permission to contradict the Game Design Authority.

Extend the current authoritative path rather than creating a parallel implementation.

Tests should preserve approved behavior, but a stale test must be updated when an explicitly approved design change supersedes it.

## 3. Required Preflight Before Substantial Work

Before implementing a substantial feature, milestone, or handoff:

1. inspect the current remote/default branch state;
2. read `VERSION`;
3. confirm `project.godot` mirrors the same version;
4. read the latest relevant `CHANGELOG.md` entries;
5. read `README.md` for the current validation command and project conventions;
6. read the relevant sections of `docs/BETWEEN_MONTH_DEVELOPMENT_MAP.md`;
7. consult the latest relevant Game Design Authority sections for any gameplay/design work;
8. inspect the existing code path and tests before adding new architecture.

Do not rely on remembered version numbers, remembered file layouts, or remembered rules.

## 4. Versioning

`VERSION` is the canonical repository version.

`project.godot` must mirror it.

Use semantic-version intent:

- **MAJOR**: fundamental core-rules, architecture, save-compatibility, or product-direction change.
- **MINOR**: substantial backward-compatible gameplay systems, complete new phases/features, or major milestones.
- **PATCH**: bug fixes, balance tuning, polish, UI/layout corrections, documentation/architecture refinements, and contained implementation improvements.

Prototype suffixes may advance within the current semantic milestone.

For substantial completed work:

- update `VERSION`;
- mirror it in `project.godot`;
- add a player/developer-facing `CHANGELOG.md` entry;
- update `README.md` when setup, scope, validation, or project status materially changes.

Never leave version sources disagreeing.

## 5. Authoritative State Boundaries

Keep gameplay truth separate from presentation.

### Match authority

`GameState` is authoritative for the active hanafuda match.

`MatchController` is the sole match-layer mutation gateway.

Match rules, card movement between authoritative zones, scoring decisions, pending choices, and terminal match results must pass through the match authority.

### Run authority

The between-month architecture adds persistent `RunState`.

`RunController` is the sole run-layer mutation gateway once implemented.

Bankroll, month progression, carry capacity, owned modifier instances, active/reserve placement, reward state, shop state, settlement/liquidation state, and run-generation counters belong to run authority.

### Boundary rule

Do not let:

- UI scripts mutate authoritative gameplay/run state directly;
- presentation callbacks decide game rules;
- animation completion determine legality or progression;
- `MatchController` mutate run economy/carry;
- `RunController` mutate the live match state;
- telemetry mutate gameplay;
- debug tools bypass invariants.

The UI observes state and submits actions.

Controllers decide.

State records.

Rules calculate.

Presentation explains committed outcomes.

## 6. Determinism Requirements

Determinism is a core product requirement, not optional test polish.

Preserve:

- stable physical card IDs;
- explicit serializable actions;
- canonical serialization;
- canonical state hashes;
- copy-validate-commit mutations;
- invariant checking before commit;
- deterministic legal-action ordering;
- replayability;
- save/load of every unresolved authoritative decision.

Rejected authoritative actions must leave the canonical state hash unchanged.

Do not use scene-tree order, dictionary incidental order, filesystem enumeration order, Object instance IDs, RIDs, Timer timing, Tween timing, frame timing, or animation completion as gameplay inputs.

Sort semantically unordered collections before order-sensitive logic.

Use stable IDs as final deterministic tie-breaks.

Avoid floating point for money, scores, counts, and integer-weighted rules where integers are sufficient.

## 7. RNG Rules

Use one persistent root run seed with deterministic derived subsystem scopes.

Do not use one global mutable gameplay RNG stream.

Gameplay RNG scopes must be isolated so that adding an AI tie-break, animation variation, sound variation, or unrelated random call cannot change future deck order, rewards, or shops.

Presentation randomness, VFX randomness, card wobble, and audio pitch/sample variation must use a separate cosmetic RNG path.

Once authoritative random outcomes such as reward/shop offers are generated, persist the generated result in state. Do not regenerate it because a screen reopens.

## 8. Physical 48-Card Invariant

The standard deck always contains exactly 48 physical hanafuda cards.

Card Upgrades attach behavior to an existing stable physical card ID.

They do not create a second copy.

Do not mutate immutable base `CardDefinition` data to represent per-run upgrades.

All 48 physical cards must remain represented exactly once among authoritative card zones during a match.

Any feature touching capture, draw, mulligan, upgraded cards, setup, or cleanup must preserve and test this invariant.

## 9. Modifier Architecture

Do not spread feature logic through checks such as:

`if modifier_id == "specific_modifier"`

Use the repository's modifier architecture:

`ModifierDefinition → ModifierInstance → typed effect handler/domain`

Keep card-owned effects distinct from player-owned effects.

Reserve modifiers are economically owned but inactive and must not project gameplay effects.

Use narrow typed rule domains such as capture planning, scoring, draw/opening decisions, multiplier replacement, or reward-request transformation.

Do not build a universal ability DSL or global event bus unless a future concrete requirement proves the current typed domains insufficient.

Effect ordering must be deterministic and explicit. Noncommutative conflicts may not depend on arbitrary incidental iteration order.

## 10. AI Rules

Solo AI obeys the same visible hanafuda rules as the player.

It may use:

- its own hidden hand;
- public cards and captures;
- visible score/yaku progress;
- public modifier/Moon information;
- public-card tracking;
- strategic inference.

It must never read:

- the player's hidden hand;
- unrevealed draw-pile order;
- other hidden authoritative information that a human opponent would not know.

Difficulty should initially improve through decision quality, planning, denial, risk judgment, and public-information tracking, not cheating or hidden bonuses.

Monthly opponents do not require bespoke gameplay powers merely to differentiate characters.

## 11. Multiplayer Boundary

Do not introduce a networking stack unless the task requires it.

The intended future boundary is a deterministic Godot client rules model with an external authoritative backend direction based on Cloudflare Workers / Durable Objects, TypeScript, and WebSockets.

Preserve language-neutral serializable action/state contracts so a future server implementation can validate the same concepts.

Do not add Steam networking, accounts, matchmaking platforms, or a different backend stack incidentally.

## 12. UI and Interaction Standards

The interface is table-first and context-preserving.

Use Godot `Control` / `Container` composition for major structural UI rather than multiplying absolute positions.

The current canonical prototype canvas is 1280 × 720.

Interaction grammar:

**focus/select → inspect if needed → choose target/destination → commit**

Mouse hover and drag may accelerate actions but must not be the only path.

Keyboard/controller focus paths must invoke the same semantic commands.

Do not communicate gameplay state by color alone.

Hover-only information must have a focus/inspect equivalent.

Meaningful mechanical text must remain readable at the target canvas.

Do not hide public strategic information behind unnecessary full-screen modal treatments.

## 13. Presentation and Game Feel

12 Moons should feel like a beautifully handled physical game whose interface occasionally becomes ceremonial, not like a functional card game covered in generic juice.

Presentation target:

**compact rigid cards, decisive movement, controlled settling, material sound, localized emphasis, and almost no effect without a physical or informational cause.**

Use the existing semantic presentation queue and reusable Tween-based card-motion foundation.

Prefer:

- semantic motion tokens;
- immediate input acknowledgment;
- firm card contact;
- stable spatial continuity;
- card height/shadow changes;
- material audio;
- localized emphasis;
- quiet resting states.

Avoid:

- universal bounce/overshoot;
- idle floating everywhere;
- routine camera shake;
- routine capture particles;
- arbitrary UI motion directions;
- glow on every interactable;
- loot-box reward reveals;
- casino coin-shower economy feedback;
- full-screen post-processing as routine presentation.

Presentation must support NORMAL, FAST, and INSTANT execution plus Reduced Motion where the roadmap requires it.

Cancellation/restart/scene teardown must restore a valid final visual state and may never deadlock gameplay.

## 14. Rendering and Asset Direction

The project targets Godot 4 Compatibility rendering.

Prefer:

- CanvasItem transforms/modulate;
- prepared textures;
- local parameterized CanvasItem shaders;
- sparse causal particles;
- reusable environment layers;
- profiling-driven optimization.

Do not make core presentation depend on Forward+-specific features, compute effects, stacked full-screen screen-read shaders, heavy dynamic 2D lighting, or multiple routine SubViewports.

Keep the shader library intentionally small and parameterized.

Preserve crisp, readable hanafuda art at small captured-card sizes and high-resolution output.

Do not build an atlas pipeline merely because there are 48 cards. Profile before adding complexity.

For AI-assisted or externally sourced art/audio:

1. retain provenance/license information;
2. treat generated output as source/reference, not automatic final runtime art;
3. require human selection and editing;
4. perform consistency and technical-export passes;
5. inspect the asset in game before approval.

## 15. Architecture Restraint

Do not solve a feature by creating a second source of truth.

Avoid unnecessary:

- Autoloads;
- `*Manager` classes;
- service locators;
- dependency-injection frameworks;
- repository/service/use-case layer stacks;
- generic inventory systems;
- ECS;
- universal messaging buses;
- statechart plugins;
- generic ability languages.

A new abstraction should solve at least two real current cases or one clearly imminent required case.

Prefer small pure helpers beneath the existing authoritative controllers.

Do not leave unused abstractions, duplicate implementations, dead compatibility paths, or speculative framework code behind.

## 16. Validation

The baseline full-project validation command is documented in `README.md`:

`scripts/run/validate_project.ps1 -GodotBinary <path-to-godot>`

Use the actual discovered Godot 4.7.2 binary path in the working environment.

For implementation work:

1. run targeted tests while iterating;
2. add tests for every new rule/invariant/transaction boundary;
3. run content validation where data changes;
4. run the complete project validation before considering a milestone complete.

Keep GdUnit4 as the current test framework.

High-risk changes require tests for:

- accepted vs rejected action mutation;
- invariant preservation;
- deterministic state hashes;
- save/load round trips;
- replay equivalence;
- RNG-scope isolation;
- physical card conservation;
- hidden-information boundaries;
- authoritative offer persistence;
- reserve inactivity;
- presentation cancellation/final-state convergence when presentation code changes.

A feature is not complete merely because it compiles or renders.

## 17. Long-Running Goal Workflow

When executing a long implementation goal:

- use the implementation plan, when present, as the ordered checklist;
- use the development map as the full specification;
- maintain the designated progress document after each completed milestone;
- complete the smallest coherent milestone;
- validate it;
- fix failures before advancing;
- record important implementation decisions and blockers;
- continue until the stated Definition of Done is actually verified.

Do not declare completion because individual subsystems exist.

If operating in an isolated Codex worktree, checkpoint commits may be created after validated milestones when the goal explicitly requests them. Do not force-push, rewrite unrelated history, merge to protected/default branches, or publish releases unless explicitly instructed.

When operating through an environment that supplies repository connector/tools instead of local Git authority, use the provided repository tools and do not bypass them with local Git operations.

## 18. Scope Discipline for the Current Between-Month Milestone

The current milestone proves:

`January → settlement → liquidation if needed → carry unlock → reward → carry preparation → six-offer shop → finalize → Begin February placeholder`

Do not expand it into:

- February gameplay;
- all twelve Moon effects;
- the full modifier catalogue;
- full House Rules infrastructure;
- multiplayer/backend implementation;
- accounts/matchmaking;
- cloud telemetry;
- meta-progression;
- achievements;
- tutorial campaign;
- giant glossary/codex;
- twelve bespoke board scenes;
- physics-simulated cards;
- full-screen post-processing architecture;
- sophisticated AI search;
- late-game/December hero polish.

Build only the infrastructure explicitly required now to make later expansion safe.

## 19. AI-Assisted Code Review Gate

Before accepting a generated patch, verify:

- authoritative mutations still use MatchController or RunController;
- no duplicate currency/card-location/offer/modifier-placement truth was created;
- modifier IDs did not leak into unrelated feature conditionals;
- no gameplay RNG bypass was added;
- UI does not calculate authoritative prices, score, settlement, legality, or ownership;
- animation/timing cannot alter gameplay outcomes;
- no unnecessary manager/Autoload/framework appeared;
- logic was not duplicated;
- new IDs are stable and validated;
- invalid content fails loudly;
- transactions cannot partially commit;
- authoritative fields serialize/migrate or are explicitly transient;
- reserve effects remain inactive;
- upgraded cards remain one physical card;
- AI hidden-information rules remain intact;
- pending decisions can survive save/load;
- domain code does not import UI;
- tests cover the new invariant/interaction;
- existing authoritative paths were extended instead of bypassed.

The standing engineering rule is:

> **No new feature gets a private path around authoritative state.**
