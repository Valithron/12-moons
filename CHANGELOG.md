# Changelog

## v0.3.0-prototype.2 — Between-Month Shop Layout Fix

- Keep the SHOP offer and owned-modifier content inside a bounded vertical scroll region so large inventories cannot push required controls below the viewport.
- Keep REROLL SHOP and CONTINUE TO FINALIZE in a persistent footer, with an explanatory disabled state if the authoritative six-slot shop is incomplete.
- Add a 1280×720 overflow regression test covering bounded content, visible progression, and authoritative transition to FINALIZE.
- Validate the repository with Godot 4.7.2: 119/119 GdUnit4 cases across 21 suites.

## v0.3.0-prototype.1 — January-to-February Between-Month Milestone

- Complete the authoritative January → settlement/liquidation → reward → carry
  preparation → six-slot shop → finalization → February placeholder loop.
- Add deterministic run state, scoped RNG, replay/save continuation, persisted
  reward/shop offers, capacity-safe carry transactions, and rejection-hash
  invariants while preserving `GameState`/`MatchController` as January authority.
- Ship the approved full-pool reward policy, Wider Choice request transformation,
  Salvage, Rain Check, shared resale rules, and production-safe content validation.
- Complete the table-first preparation UI with causal settlement/shop feedback,
  focus restoration, NORMAL/FAST/INSTANT motion, reduced-motion equivalence,
  cancellation hooks, and an explicit February placeholder transition.
- Validate the project with Godot 4.7.2: 118/118 GdUnit4 cases across 21 suites,
  January/core smoke, runtime UI flow, and native 1280×720 plus higher-resolution
  inspection.

## v0.2.0-prototype.11 — Between-Month Policy Lock

- Record the five approved between-month policy decisions in the canonical Game Design Authority and synchronize the repository roadmap, implementation plan, and progress ledger.
- Lock monthly free rewards to 3 offers from the full eligible modifier pool, with Wider Choice increasing the count to 4 without family quotas.
- Lock default duplicate handling: no duplicate Hand/Mechanic or Strategic/Meta definitions unless explicitly stackable; Card Upgrade types may recur on different physical cards but not duplicate on the same physical card unless explicitly allowed.
- Lock full-capacity reward handling to replace-and-sell or the normal +2 refusal, with no overflow inventory; lock full-storage shop purchases to remain blocked until legal space is created.
- Lock resale to 50% of actual purchase price for purchased modifiers and 50% of normal base shop value for free reward modifiers, both rounded down.
- Reconcile stale pre-merge planning notes so root `AGENTS.md`, the merged Codex implementation, and resolved BM-B01 through BM-B06 status are reflected accurately.
- The Codex implementation foundation remains partially validated at 103/103 GdUnit4 cases under Godot 4.7.1; exact Godot 4.7.2 validation and native visual inspection remain required before BM-18 can complete.

## v0.2.0-prototype.10 — Agent Governance Preflight

- Add root `AGENTS.md` with permanent repository guidance for design-authority precedence, deterministic state ownership, RNG isolation, the 48-card invariant, modifier architecture, AI privacy, UI/presentation standards, Compatibility-renderer constraints, validation, versioning, scope control, and long-running Codex goal execution.
- Make the Game Design Authority the explicit source of truth for gameplay decisions while directing implementation agents to continue independent work rather than silently invent unresolved rules.
- Require generated code to extend the existing authoritative paths, preserve replay/save/hash invariants, and pass a project-specific AI-assisted architecture review gate.
- Restore canonical version-source consistency by advancing both `VERSION` and `project.godot` to `0.2.0-prototype.10`; prior documentation-only prototype bumps had left `VERSION` behind.
- No gameplay rules, scoring values, economy values, modifier effects, presentation behavior, or renderer behavior are changed by this governance pass.

## v0.2.0-prototype.9 — Production Game-Feel Architecture Map

- Expand `docs/BETWEEN_MONTH_DEVELOPMENT_MAP.md` with the production research for physicality, animation, rendering, VFX, audio, transitions, asset production, accessibility, and performance while preserving the deterministic run and table-first UX architecture.
- Establish a semantic `MotionProfile`, rigid-card height/shadow language, timing ceilings, immediate input acknowledgment, capture/deal/reflow recipes, and an explicit hierarchy from quiet acknowledgments through rare run landmarks.
- Extend the presentation queue toward domain presenters with semantic events, explicit sequence/parallel/barrier recipes, NORMAL/FAST/INSTANT execution, cancellation epochs, final-state restoration, and reduced-motion behavior that cannot affect authoritative outcomes.
- Add material-first SFX families, Master/Music/SFX/UI/Ambience bus guidance, separate cosmetic audio randomness, and a restrained music/ambience scope instead of a premature adaptive-audio system.
- Lock Compatibility-first production direction around CanvasItem transforms, prepared textures, local parameterized shaders, sparse causal VFX, stable card art readability, and no routine full-screen post-processing.
- Add card-resolution/import guidance, height/shadow/material rules, a tiny shared shader library, `MonthPresentationProfile` direction, seasonal-layer reuse, asset provenance/human-approval workflow, and explicit anti-synthetic presentation gates.
- Expand settlement, carry unlock, reward, shop, and February-transition choreography so objects preserve spatial continuity and routine economic actions remain faster/quieter than true milestones.
- Add 60 FPS headroom targets, stable profiling scenarios, 720p/high-resolution testing, texture-memory warnings, and production acceptance criteria for cancellation, reduced motion, deterministic cosmetic isolation, and repeated-action pacing.
- Preserve all unresolved gameplay-rule questions and all prior deterministic authority boundaries; this documentation pass changes presentation architecture and production standards only.

## v0.2.0-prototype.8 — Deterministic Run Architecture Map

- Rework `docs/BETWEEN_MONTH_DEVELOPMENT_MAP.md` around a separate deterministic `RunState` / `RunController` authority while preserving the existing `GameState` / `MatchController` match authority.
- Add a serializable `MatchResult` bridge, explicit run phases, copy-validate-commit run transactions, canonical run hashing/invariants, and stable string IDs as prerequisites for settlement, rewards, carry, and shop systems.
- Require one root run seed with hashed subsystem RNG scopes, persisted generated offers, isolated presentation randomness, and deterministic offer/shop generation that cannot be perturbed by unrelated random calls.
- Define modifier definitions, persistent instances, stable physical-card attachments, typed effect domains, deterministic priority/replacement semantics, reserve inactivity, and validation against modifier-ID special-case leakage.
- Move emergency liquidation into an authoritative run phase that keeps canonical bankroll nonnegative and resolves debt through legal transactions before reward progression.
- Make reward and shop offers authoritative persisted state, with atomic buy/sell/reroll/move actions and Wider Choice as the only representative modifier required end-to-end for the between-month milestone.
- Add versioned JSON save v1, migration hooks, content validation, deterministic scenario/debug tooling, replay/save-continuation tests, and an AI-assisted architecture review gate to the milestone.
- Preserve all prior table-first UX requirements and all unresolved gameplay-rule questions; this documentation pass does not choose reward-family policy, modifier stacking, resale rules, Mulligan shuffle semantics, Second Draw edge cases, or full-storage behavior.
- No January hanafuda rules, canonical scoring values, approved economy values, modifier effects, or renderer behavior are changed by this documentation pass.

## v0.2.0-prototype.7 — Between-Month UX Architecture Map

- Revise `docs/BETWEEN_MONTH_DEVELOPMENT_MAP.md` around the research-backed table-first UX direction while preserving the Game Design Authority as the source of gameplay rules.
- Make one shared preparation environment the implementation target for settlement, reward, carry management, shop, and finalization, with stable carry and bankroll anchors.
- Move semantic Theme, Container-based structural layout, focus/navigation, readable typography, inspect/tooltip equivalence, reduced-motion, and localization-resilience work ahead of the expanding between-month surface.
- Require the full eight-slot carry tray to be visible from the first between-month sequence, with future slots locked, active/reserve state communicated redundantly, and select-to-destination as the canonical interaction.
- Add concrete reward/shop UX constraints for modifier-vs-hanafuda visual separation, a stable 3 × 2 six-offer shop, explicit affordability/capacity errors, predictable focus restoration, and semantic action copy.
- Flag the current reward-family authority conflict as still unresolved rather than using UX research to silently choose a gameplay rule.
- No January gameplay rules, scoring rules, economy values, modifier effects, or renderer behavior are changed by this documentation pass.

## v0.2.0-prototype.6 — Hanafuda Card Motion

- Add persistent stable-ID `MoonCardView` presentation so cards visibly travel between hands, field, draw resolution, and capture spreads.
- Add a semantic presentation queue and reusable motion controller for dealing, hand/field/capture reflow, play, draw reveal, card flip, capture slap, yaku feedback, and score-decision timing.
- Lock card and score input while mandatory presentation is active, and make AI turns wait for presentation completion.
- Add centralized normal/fast/reduced-motion timing modes and cancellation-safe scene teardown/restart behavior.
- Document the motion model in `docs/CARD_MOTION.md` and add runtime coverage for the animated UI handoff.
- January hanafuda rules, deterministic state, scoring, and the Compatibility renderer are unchanged.

## v0.2.0-prototype.5 — January Table Stabilization

- Correct the standard 48-card manifest's November Willow red-ribbon card and vendor its distinct Tanzaku face art.
- Add manifest checks for 48 unique cards, twelve four-card months, valid classes, complete art assets, and unintended duplicate art mappings.
- Replace the 960 × 540 positional table with a 1280 × 720 named-region layout for hands, captures, field, draw/resolution, scores, status, and modal decisions.
- Keep capture groups readable, separate the draw pile from the revealed resolution card, and make selectable/hovered cards visually explicit.
- Slow house turns with short presentation pauses and describe played, captured, drawn, Stop, and Koi-Koi actions in the table status.
- Expand the title, January intro, and result screens to the shared 16:9 virtual surface.
- Add baseline table-region layout coverage alongside the existing full January UI-flow validation.

## v0.2.0-prototype.4 — Starter Card Input Fix

- Stop the empty full-screen UI layers from intercepting clicks on playable cards.
- Validate that each player action reaches a rendered selectable card and its `Button.pressed` signal.
- January gameplay rules are unchanged.

## v0.2.0-prototype.3 — Godot 4.7.2 Runtime Stability

- Defer UI screen teardown so title, January intro, match, and result transitions do not free a locked signal-emitting node.
- Fix Godot 4.7.2 parser/type-inference errors in the match capture-group renderer and test suites.
- Normalize `project.godot` to the Godot 4.7 configuration format.
- Add a headless end-to-end UI-flow validation covering title, intro, January, and result screens.
- January gameplay rules are unchanged.

## v0.2.0-prototype.2 — Godot 4.7 Launch Fix

- Fix Godot 4.7.2 parser/type-inference errors in `boot.gd` when dynamically instantiated scenes are assigned with inferred `:=` declarations.
- January gameplay rules and behavior are unchanged.

## v0.2.0-prototype.1 — January Playable Month

This milestone turns the deterministic foundation into the first playable 12 Moons
vertical slice:

- First complete January match with a title, January introduction, table, and result screen.
- Three-card starting-player ritual with player-first reveal and earlier revealed month.
- Deterministic 8/8/8 legal dealing with invalid opening-field redeals.
- Complete hanafuda play-and-draw turns, including 0/1/2/3-match resolution and target choices.
- Canonical prototype yaku evaluator with structured score breakdowns and stacking.
- January Wolf Moon: all Chaff points are doubled, “Strength of the Pack.”
- End-of-full-turn Stop/Koi-Koi decisions, seven-plus doubling, and one Koi-Koi multiplier.
- Rudimentary legal AI restricted to its own hand and public information.
- Functional first table UI with real hanafuda face art and a neutral procedural card back.
- Stronger hidden-information boundaries, transactional mutations, and all-48-card conservation invariants.
- Deterministic full-month replay/state-hash integration coverage.

Rewards, shops, carry builds, later Moons, multiplayer, and final presentation remain
out of scope for this prototype.

## v0.1.0-prototype.1 — Open-Source Foundation

The first 12 Moons prototype implementation establishes:

- A Godot 4.7.2 Compatibility-renderer project.
- The pinned Card Framework runtime addon and GdUnit4 development/test addon.
- A native, stable-ID 48-card hanafuda manifest.
- Deterministic state, action, seeded-deck, replay, and state-hash foundations.
- A public/perspective state boundary for hidden-information AI.
- Card Framework presentation adapters that never own gameplay state.
- Automated core validation and third-party provenance notices.

January gameplay, complete yaku scoring, Stop/Koi-Koi UI, and the first playable
vertical slice are intentionally part of the next milestone.
