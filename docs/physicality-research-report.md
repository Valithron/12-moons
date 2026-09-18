# 12 Moons: Production Research for Physicality, Rendering, Audio, and Game Feel

The central recommendation is simple:

**12 Moons should feel like a beautifully handled physical game whose interface occasionally becomes ceremonial—not like a functional card game covered in “juice.”**

The hanafuda cards should carry most of the tactile burden. Their acceleration, shadows, contact sounds, spatial continuity, settling, and relationship to the table should establish the game’s physical language. UI, scoring, rewards, shops, and month transitions should then inherit that same material logic. Spectacle should be scarce enough that a Koi-Koi declaration, a major yaku, a carry-slot unlock, and the end of the year still have somewhere to go.

The current architecture described in the project context—authoritative game state separated from a serialized presentation queue, with reusable cancellable Tween-based motion—is already the correct foundation. The recommendations below build on it rather than replacing it.

## Executive direction and January-to-February milestone

**Executive Game-Feel Recommendation.**

A good one-sentence target for the production team is:

> **Compact rigid cards, decisive movement, controlled settling, material sound, localized emphasis, and almost no effect without a physical or informational cause.**

Hanafuda should not move like loose poker cards, collectible spell cards, or rubber tiles. They are visually compact and rigid. That points toward relatively quick acceleration, shallow travel arcs, minimal rotational wobble, firm contact, and a single restrained settle. Resting objects should actually rest.

The game should generally feel **fast between decisions and deliberate at consequences**. A player action ought to acknowledge input immediately, ordinary play/capture should normally resolve in well under half a second, while events that change strategic context can claim roughly half a second to a second. Only run-level landmarks should regularly exceed a second.

The strongest practical priorities are:

| Production priority | Recommendation | Why it pays off |
|---|---|---|
| **Build now** | Motion tokens, card height/shadows, immediate input response, capture timing, tactile SFX | These affect almost every turn |
| **Build now** | Settlement arithmetic presentation | Immediate January milestone and critical rules comprehension |
| **Build now** | Reward → carry spatial continuity | Makes the roguelike layer feel physically integrated |
| **Build now** | Shop purchase/sell/reroll feedback | High-frequency between-month interaction |
| **Build now** | Persistent transition language between settlement/reward/carry/shop | Prevents prototype-menu feeling |
| **Establish now** | Central motion profile | Prevents arbitrary easing and duration proliferation |
| **Establish now** | Presentation cancellation/fast-forward contract | Becomes expensive to retrofit later |
| **Establish now** | SFX families and audio buses | Repetition quality depends on architecture |
| **Establish now** | Month-presentation data resource | Makes twelve months scalable |
| **Establish now** | Tiny parameterized shader library | Prevents shader sprawl |
| **Add later** | Seasonal ambience layers and richer month dressing | Valuable after core actions feel good |
| **Add later** | Post-Koi-Koi adaptive music layer | Worthwhile only once music/SFX foundation exists |
| **Add later** | Rare hero VFX and optional haptics | Appropriate for true milestones |
| **Do not prioritize** | Full-screen post-processing | High cost and weak contribution to card feel |
| **Do not prioritize** | Physics-simulated cards | Harder to art-direct and worse for determinism/readability |
| **Avoid** | Particles on routine card captures | Dilutes hierarchy |
| **Avoid** | Universal bounce, shake, glow, and overshoot | Produces synthetic “game juice” rather than materiality |

Godot’s current renderer documentation continues to distinguish Compatibility from Forward+ and Mobile and makes renderer choice a real feature/platform constraint rather than a cosmetic toggle. That is important here: polish should be designed around robust CanvasItem-era techniques first rather than around effects that presume a Forward+ graphics stack. citeturn3view0

**Immediate January-to-February Polish Plan.**

The between-month milestone should read as one continuous transformation of the player’s table rather than a sequence of unrelated menus.

| Moment | Motion | Audio | VFX | Transition treatment | Priority |
|---|---|---|---|---|---|
| **January settlement enters** | Match elements de-emphasize; score panel/tray enters from a spatially plausible edge in ~250–350 ms | Soft material shift, one restrained settlement cue | Board dim only; no particles | Keep table/background visible | P0 |
| **Resolved yaku** | Relevant cards briefly gather/highlight before each score row resolves | Short tonal confirmation by significance | Local edge emphasis | No screen change | P0 |
| **Subtotal** | Number transitions quickly to resolved subtotal | One subdued tick/landing cue | None | Same panel | P0 |
| **Moon bonus** | Bonus row enters and equation changes | Distinct but quiet confirmation | Local line/mark illumination | Same panel | P0 |
| **7+ multiplier** | Multiplier visibly transforms subtotal rather than merely replacing final number | Lower, firmer impact | Tiny local emphasis | Same panel | P0 |
| **Koi-Koi multiplier** | Same arithmetic grammar, slightly stronger | Reuse Koi-Koi tonal identity | Local only | Same panel | P0 |
| **Final score** | Final amount settles, not endlessly counts | Strongest settlement landing sound | Optional brief underline/sheen | Hold ~250 ms | P0 |
| **Currency change** | `old bankroll → +earned → new bankroll` in ~250–400 ms | Ledger/token/material cue, not coin shower | None | Bankroll remains in persistent location | P0 |
| **Carry slot unlock** | Existing locked slot physically opens/reveals itself in ~600–900 ms | Latch + material movement + restrained harmonic bloom | One glint or very sparse debris at most | Carry tray comes forward | P0 |
| **Reward reveal** | 3–4 options arrive in 60–90 ms stagger; all readable within ~400 ms | Soft placement family + reveal cue | No rarity beams | Settlement retracts, reward objects occupy table center | P0 |
| **Reward choice** | Immediate lift; selected object then travels into carry/reserve | Confirmation + card/material movement | Brief local selection edge | Spatial continuity is the transition | P0 |
| **Carry management** | Drag/move or click-place uses clear slot snapping and shadow height | Pickup/place family | Legal-slot highlight only | Tray persists | P0 |
| **Enter shop** | Shop stock slides/reframes around persistent carry/economy UI | Quiet room/tray shift | None | Same table/world shell | P0 |
| **Purchase** | Offer moves toward owned area in ~160–220 ms | Item movement + ledger debit | Price delta only | No cut | P0 |
| **Insufficient funds** | Price responds immediately with 120–180 ms constrained nudge/pulse | Dry invalid cue | No red explosion | Stay put | P0 |
| **Sell** | Reverse physical travel, ~180–250 ms | Material departure + ledger credit | None | Stay put | P0 |
| **Reroll** | Old offers leave coherently; replacements enter; ~250–350 ms total | One shuffle/replacement gesture | No slot-reel spin | Preserve offer positions | P0 |
| **Finalize** | Interactive shop/carry layers retract and lock into run state | Closure/case sound | None | Environmental layer begins transitioning | P1 |
| **Begin February** | Background/month layer transitions behind stable foreground framing | Brief Moon cue | Seasonal accent only | Moon title/rule → February setup | P1 |

The critical production insight is that **slot unlock → reward → carry → shop should share physical space**. Reward choice should not disappear from one UI and appear magically in another. The selected modifier should visibly travel to its destination whenever practical.

That one choice will make the roguelike progression layer feel far more authored than several additional particle systems would.

For settlement, the model’s bankroll can already be authoritative before the visual count finishes. The presentation should receive immutable `before` and `after` values and animate a **display value**, never make the actual economic mutation depend on the animation.

The first carry-slot unlock deserves a modest ceremony because it changes the player’s strategic capability for the rest of the run. Later monthly unlocks should use the same material grammar but become faster.

## Motion, physicality, and feedback language

**Card Motion Language.**

There should be a deliberately small vocabulary of motion.

A card at rest is quiet. A card being considered rises. A card being committed moves decisively. Contact is firm. Capture pulls related cards together. A card entering ownership travels somewhere meaningful. Nothing bounces merely because an animation library permits it.

For 12 Moons, use this division:

| Motion problem | Preferred technique | Avoid |
|---|---|---|
| Dynamic card travel | Tween with shallow Bézier/procedural path | RigidBody physics |
| Hand reflow | Tweened transforms to stable slots | Random spring simulation |
| Hover | Fast Tween or lightweight damped spring | Constant bobbing |
| Pointer-follow tilt | Procedural, clamped | Tween chains recreated every frame |
| Deal | Tweened overlapping paths | Fully serial 24-card ceremony |
| Card flip | Tween/AnimationPlayer controlling apparent width/scale | 3D camera machinery |
| Fixed UI ceremony | `AnimationPlayer` | Huge Tween scripts |
| Slot unlock | `AnimationPlayer` + parameterized SFX/VFX | Physics destruction |
| Fine pixel emphasis | CanvasItem shader | Node-heavy animation |
| One-shot accent debris | Particle system | Handmade dozens of sprites |
| Ongoing game state | Authoritative model | Animation callbacks |

The existing Tween motion controller should therefore **remain the foundation**.

Use Bézier travel when the origin and destination are spatially meaningful and far apart—deck to hand, field to capture area, reward to carry slot. Use near-linear curved interpolation for hand reflow because the player is tracking card identity, not watching a flourish.

A card’s rotation can be inferred from movement direction or set from a tiny authored offset rather than randomized continually. Recommended visual bounds at 1280×720:

- routine travel: roughly **±1–2°**;
- brisk deal trajectories: up to roughly **±3°** if it remains readable;
- resting organized hand: effectively **0°**;
- loose field variation, if used: deterministic roughly **±1°**;
- dramatic wobble after impact: **do not use**.

Hanafuda’s rigid feel argues against the soft elastic squash associated with cartoon objects. Contact deformation should be almost subliminal—perhaps a **1–2% scale compression for tens of milliseconds**, or none at all if it reads as rubbery.

**Easing language.**

Centralize motion intent rather than letting each scene choose arbitrary `Tween.TRANS_*` values.

A useful resource vocabulary is:

```text
HOVER
PRESS
MOVE_FAST
MOVE_STANDARD
MOVE_DRAMATIC
IMPACT
SETTLE
REFLOW
REVEAL
MAJOR_REVEAL
EXIT_FAST
PHASE_TRANSITION
```

Recommended character:

| Token | Character |
|---|---|
| `HOVER` | Fast ease-out; no overshoot |
| `PRESS` | Near-immediate compression/down response |
| `MOVE_FAST` | Strong ease-out |
| `MOVE_STANDARD` | Quick acceleration, smooth deceleration |
| `MOVE_DRAMATIC` | Slightly longer deceleration, still no bounce |
| `IMPACT` | Sharp deceleration/contact |
| `SETTLE` | Tiny secondary correction only |
| `REFLOW` | Smooth ease-in-out; identity-preserving |
| `REVEAL` | Confident ease-out |
| `MAJOR_REVEAL` | Fast initial movement with longer final settle |
| `EXIT_FAST` | Ease-in toward departure |
| `PHASE_TRANSITION` | Smooth cubic-style ease-in-out |

Do not make `TRANS_BACK`-style overshoot the house style. A small overshoot is suitable for an intentionally spring-loaded latch or perhaps one UI emphasis, but a hanafuda card should not overshoot every destination.

An implementation can keep these values in one `Resource`:

```gdscript
class_name MotionProfile
extends Resource

@export_group("Durations")
@export var hover_in := 0.085
@export var hover_out := 0.110
@export var move_fast := 0.145
@export var move_standard := 0.190
@export var reflow := 0.160
@export var impact := 0.055
@export var settle := 0.065
@export var phase_transition := 0.320

@export_group("Distances at 720p")
@export var hover_lift_px := 6.0
@export var travel_rotation_degrees := 1.5
```

The exact numbers should remain tunable data, not buried constants.

**Motion Timing Table.**

These are recommended production ranges for **12 Moons**, not claims of universal animation law.

| Interaction | Fast | Standard | Dramatic / first-time | Skip? |
|---|---:|---:|---:|---|
| Hover in | 50–75 ms | 70–110 ms | — | Reduced motion may make instant |
| Hover out | 70–100 ms | 90–140 ms | — | Yes |
| Button/card press acknowledgment | 40–70 ms | 60–100 ms | — | Never delay response |
| Card lift | 60–90 ms | 80–120 ms | — | Simplify |
| Play hand → field | 110–160 ms | 140–220 ms | 220–300 ms | Fast mode |
| Contact settle | 30–50 ms | 40–80 ms | 70–100 ms | Remove in reduced mode |
| Draw-pile extraction | 80–120 ms | 100–160 ms | — | Fast mode |
| Draw reveal | 140–200 ms | 180–280 ms | 280–400 ms | Yes |
| Card flip total | 120–170 ms | 160–240 ms | 250–350 ms | Yes |
| Hand reflow | 90–140 ms | 120–220 ms | — | Instant option |
| Deal per card | 45–70 ms | 60–100 ms | 100–140 ms | Sequence skippable |
| Deal stagger | 15–30 ms | 25–45 ms | 50–70 ms | Compress |
| Capture sequence | 180–280 ms | 300–450 ms | 450–600 ms | Accelerated mode |
| Small yaku feedback | 180–300 ms | 250–400 ms | — | Compress |
| Named yaku | 250–400 ms | 350–700 ms | 700–900 ms | Advance |
| Major Bright yaku | 450–650 ms | 650–900 ms | 900–1200 ms | Advance |
| Stop response | 180–300 ms | 250–450 ms | — | Yes |
| Koi-Koi declaration | 250–400 ms | 350–600 ms | 600–800 ms | Yes |
| Settlement stage | 120–200 ms | 200–400 ms | 400–550 ms | Advance |
| Entire ordinary settlement | 1.0–1.6 s | 1.8–3.0 s | 3–4 s maximum | Yes |
| Reward entrance | 220–320 ms | 300–500 ms | 500–650 ms | Yes |
| Reward stagger | 40–60 ms | 60–90 ms | 100 ms | Compress |
| Reward → owned slot | 140–190 ms | 180–250 ms | 250–350 ms | Fast |
| Purchase | 100–150 ms | 120–220 ms | — | Fast |
| Sell | 120–170 ms | 140–240 ms | — | Fast |
| Reroll | 180–240 ms | 220–350 ms | 350–450 ms | Fast |
| Slot unlock | 350–500 ms | 600–900 ms | ~1 s first reveal | Yes |
| Ordinary phase transition | 180–280 ms | 250–450 ms | 450–600 ms | Yes |
| Moon introduction | 600–900 ms | 1.2–1.8 s | ~2 s first time | Must be accelerable |

The most important responsiveness rule is stricter than these durations:

> **A click should visibly and/or audibly acknowledge in the next rendered frame whenever possible.**

Do not wait 150 ms for a card to begin “anticipating” before proving the click worked. Direct interaction gets immediate lift, shadow, selection state, or contact sound; the longer motion follows.

**Capture Animation.**

Capture is the everyday hero interaction. It deserves refinement, not spectacle.

Recommended sequence:

1. **Target recognition, 70–120 ms.** The matching field card gets a subtle edge/brightness/shadow cue.
2. **Commit travel, 140–200 ms.** The played card moves on a shallow path with increased shadow height.
3. **Contact, 40–70 ms.** Movement arrests cleanly. One dry card/table transient lands precisely here.
4. **Relationship hold, 50–80 ms.** Both cards remain visually together just long enough for the match to register.
5. **Collection lift, 40–70 ms.** Captured cards gain height/shadow together.
6. **Capture travel, 140–220 ms.** The group travels toward its capture region, optionally with a 15–25 ms internal stagger.
7. **Capture-area reflow, 100–160 ms.**
8. **Yaku resolution follows only after card identity and relationship are readable.**

Normal capture should use **no camera shake and no particles**.

The impact should be carried by timing, a shadow-height change, and a layered sound. Adding a burst every time would turn a fundamental hanafuda operation into an arcade reward trigger.

An accelerated setting can collapse recognition/hold and overlap collection travel, bringing repeated capture closer to **180–280 ms**.

**Deal and Draw Animation.**

Do not force the player to watch 24 cards complete 24 isolated paths.

The deck should nevertheless be the visible origin so the initial state feels physically constituted rather than appearing by UI magic.

Use overlapping waves. One workable pattern is:

```text
deck begins active
→ fast player-hand wave
→ field wave overlaps before player wave fully finishes
→ AI wave overlaps
→ remaining stack settles visibly as draw pile
```

Individual cards may travel in roughly 60–100 ms with a 25–45 ms stagger. Because these overlap, the opening deal can plausibly complete in roughly **0.7–1.1 seconds**, rather than 2–4 seconds of serialization.

The draw pile should behave differently from hand play. A draw card is extracted sharply from the stack, lifted/revealed, then sent to its outcome. A hand card is an intentional player commitment and can use a slightly more deliberate travel.

AI and player cards should share the same physical rules. Difference should come from direction, face state, and origin—not from making AI cards mysteriously sluggish or unnaturally robotic.

After January, monthly deals should be fast-forwardable.

**Hand Reflow.**

Reflow has one job above all others: **preserve object identity**.

Every card should interpolate from its actual current transform to its new slot. Never rebuild a hand so objects jump to newly computed positions.

Use stable logical slots and stable sorting. A card under the pointer should not suddenly migrate because another animation finishes.

Recommended rules:

- do not randomize hand angles;
- do not re-sort continuously;
- do not trigger full-hand movement from a hover;
- temporarily elevate hovered/selected cards in z-order;
- move neighbors only as much as necessary;
- if a reflow is interrupted, calculate the replacement animation from the card’s *current visual position*, not its obsolete start point;
- when input is active, defer non-essential resorting until a safe boundary.

For fanned cards, let position and slight overlap communicate arrangement; avoid strong perspective rotations that make hanafuda art harder to read.

**Yaku Feedback.**

The feedback hierarchy should distinguish ordinary scoring thresholds from named accomplishments.

| Yaku event | Visual treatment | Audio | Interruption |
|---|---|---|---|
| Incremental Kasu/Ribbon/Seed progress | Relevant category cards pulse/edge-emphasize; compact score delta | Very small tonal tick or none | ~150–250 ms, largely concurrent |
| Threshold score increase | Relevant group highlights together | Small confirm | ~250–400 ms |
| Named yaku | Relevant cards lift slightly; yaku name appears near score area | Recognizable tonal motif | ~350–700 ms |
| Strong/Bright yaku | Local board focus; slightly stronger framing | Fuller motif | ~650–900 ms |
| Multiple simultaneous yaku | Grouped/staggered presentation | One coherent musical phrase | Do not play full ceremony repeatedly |
| New score after Koi-Koi | Score delta emphasized with existing Koi-Koi identity | Risk-success cue | ~300–600 ms |

Avoid full-screen banners for routine threshold scoring. They would become visual punctuation on nearly every sentence.

For stacked yaku, present a compact stack of result rows rather than playing one complete animation per item.

**Stop / Koi-Koi Presentation.**

This is a genuine dramatic decision, so the visual field should become quieter rather than noisier.

When the choice appears:

- finish the yaku resolution first;
- hold for roughly 100–150 ms;
- reduce board contrast or brightness by only about 8–12%;
- emphasize the current score and relevant scoring cards;
- bring the two options into a stable decision area;
- change the musical/ambient state only if that system already exists.

**Stop:** a dry, conclusive audio cue; score visually locks; settlement begins.

**Koi-Koi:** use a short calligraphic/stamp-like identity, around 250–400 ms of visual emphasis plus a restrained stinger. Then return quickly to playable state.

The next Koi-Koi state should feel tenser primarily through **persistent state**—an indicator, changed musical layer, slightly altered ambience—not by escalating every future action into a larger explosion.

**Settlement Presentation.**

Do not reveal all arithmetic at once, but do not turn the score into a slot-machine count either.

Use visible causality:

```text
resolved yaku
→ additive subtotal
→ Moon bonus, if applicable
→ 7+ multiplier, if applicable
→ Koi-Koi multiplier, if applicable
→ final score
→ currency delta
→ bankroll
```

Skip inapplicable stages.

A useful presentation shape is an equation that changes:

```text
Yaku:        5
Moon bonus: +2
             ──
Subtotal:    7
7+ bonus:   ×2
             ──
Final:      14
```

Then:

```text
Bankroll  24
January  +14
          ──
          38
```

The visual count may interpolate for 200–350 ms, but it should not tick once per currency unit. That produces casino connotations and becomes painfully slow at larger values.

**Reward and Slot-Unlock Presentation.**

The locked carry slot should ideally already be present in the layout before it unlocks. That gives the player a visible sense of latent capacity.

At unlock:

```text
locked slot
→ latch/seal releases
→ frame opens/clears
→ available-state material settles
→ one restrained tonal flourish
```

Do not have the slot scale from zero. It already existed conceptually.

Rewards should appear quickly and mostly face-up. The player’s real task is comparison, not suspense. Loot-box conventions—prolonged face-down states, rarity beams, escalating reveal sounds—would work against the game’s identity.

After selection, **move the actual reward representation into its carry/reserve destination**. This is one of the highest-value spatial-continuity improvements available.

**Shop Feedback.**

The shop should optimize repeated decisions.

Purchase is:

```text
press acknowledgement
→ item starts moving immediately
→ bankroll visually debits
→ item arrives in owned space
→ sold-out/empty offer state remains
```

Sell reverses the object relationship. Reroll replaces offers as a coherent group rather than cycling dozens of fake possibilities.

For insufficient funds, animate the **price or affordance**, not the entire screen. A small constrained nudge plus a dry “cannot” sound is enough.

**Transition Language.**

Use one persistent presentational shell if architecture permits without disruptive rewrites:

```text
persistent table / world
├── match layer
├── settlement layer
├── reward layer
├── carry tray
├── shop layer
└── month/environment layer
```

That does not require every phase to live in one giant scene. It means the *presentation contract* preserves spatial landmarks even where implementation scenes change.

Physical objects move. Abstract state crossfades. Background/world changes happen behind stable UI landmarks.

**Camera / Framing Rules.**

The default camera is effectively fixed.

Use framing shifts only where they answer “what should the player look at now?”

Recommended maximums:

| Event | Camera/framing |
|---|---|
| Hover/play/capture | None |
| Ordinary yaku | None |
| Named yaku | Optional local UI emphasis |
| Major yaku | 1–2% slow push-in at most |
| Stop/Koi-Koi | Slight board reframe or 1–2% push |
| Settlement | Layout reframe, not shake |
| Slot unlock | Optional tiny local/camera impulse |
| Moon intro | Slow controlled reframe |
| Season change | Background parallax/crossfade, not active camera sweep |
| December completion | Strongest available framing |

If camera impulse is used at all, begin around **1–2 pixels at 720p for under ~100 ms** and test downward. Disable it in reduced-motion mode. Ordinary capture does not deserve shake.

**Feedback Intensity Hierarchy.**

A six-level hierarchy is useful, but I would rename the levels around *intent*:

| Level | Meaning | Examples | Typical duration | Sound | VFX | Camera |
|---|---|---|---:|---|---|---|
| **Rest** | Passive state | Board, captured cards, bankroll | — | Ambience only | None | None |
| **Acknowledge** | “Your input registered” | Hover, focus, press | ≤120 ms | 0–1 quiet layer | None | None |
| **Resolve** | Normal game consequence | Play, draw, capture, purchase | 120–450 ms | 1–2 material layers | Usually none | None |
| **Reward** | Meaningful advancement | Named yaku, modifier activation, reward acquisition | 300–700 ms | 2–3 layers | Localized accent | Rare |
| **Milestone** | Strategic/phase significance | Koi-Koi, slot unlock, month victory | 500–1200 ms | Short stinger + material layer | Sparse/local | Optional restrained |
| **Landmark** | Run-defining | Season boundary, December/run completion | 1–2.5 s | Fullest coordinated cue | Deliberate | Controlled |

The important rule is not “fire all channels at Level 4.” It is that each level has a **ceiling**.

## Rendering, VFX, cards, depth, materiality, and shaders

**VFX System.**

VFX should answer one of three questions:

1. **What can I interact with?**
2. **What state just changed?**
3. **Why was this event more important than an ordinary one?**

Everything else is suspect.

Useful reusable VFX categories are therefore small:

```text
TARGET_LEGAL
TARGET_SELECTED
MODIFIER_READY
MODIFIER_ACTIVATE
SLOT_UNLOCK
REWARD_ACQUIRED
YAKU_MAJOR
MONTH_TRANSITION
```

For ordinary captures, purchases, card placement, hand reflow, and basic score changes, motion + shadow + sound should normally be sufficient.

Particles are appropriate when they have a material cause: a seal breaks, a paper edge sheds a few flecks, a seasonal foreground produces sparse petals or snow behind the table. They are inappropriate as a generic synonym for “reward.”

A practical art-direction budget for a localized accent is roughly **6–16 visible elements lasting 250–500 ms**, not hundreds of glowing sprites. That is a project constraint, not a Godot performance limit.

Prefer alpha-blended material-looking fragments. Reserve additive blending for tiny highlights where actual light emission is the intended impression.

**Compatibility-Renderer Rendering Guide.**

Godot’s official renderer documentation makes Compatibility the renderer oriented toward the broadest hardware/platform reach, while Forward+ owns more advanced rendering features. 12 Moons should exploit that constraint positively: most of its premium look can come from 2D transforms, carefully prepared textures, CanvasItem shaders, shadows, audio, and authored transitions. citeturn3view0

| Technique | Compatibility recommendation |
|---|---|
| CanvasItem transforms/modulate | **Core technique** |
| Sprite/Control material effects | **Core technique** |
| Simple CanvasItem fragment shaders | **Core technique** |
| Parameterized outlines/tints/masks | **Recommended** |
| Alpha/additive local effects | **Safe when restrained** |
| Simple 2D particles | **Reasonable; test target hardware** |
| CPU particle fallback | **Useful for simple sparse accents if needed** |
| Additional SubViewports | **Supported conceptually but avoid unless effect earns render cost** |
| Screen-reading shader | **Use sparingly** |
| Full-screen screen-texture effects | **Avoid as normal presentation** |
| Multiple stacked full-screen shader passes | **Do not build around them** |
| Heavy dynamic 2D lighting | **Possible direction, but low payoff here** |
| Forward+-specific advanced effects | **Do not make dependencies** |
| Compute-driven custom effects | **Not a suitable foundation for Compatibility-first production** |

Godot documents screen-reading shaders around a copy of the rendered screen/back buffer rather than treating the framebuffer as a free arbitrary texture. That makes such effects qualitatively different from a local card shader: they introduce screen-sized copying/sampling and special ordering considerations. Use them only when a transition truly needs them. citeturn3view1

For this game, a translucent overlay, authored texture wipe, background-layer crossfade, or localized mask will usually outperform a full-screen blur aesthetically **and** architecturally.

**Card Rendering Guide.**

The cards are the one asset category where oversupplying source quality is justified.

Do not choose runtime resolution by “720p card game” alone. Determine the **largest physical pixel size a card can occupy on a 4K output during hover/reward presentation**, then keep enough source resolution to avoid magnifying a low-resolution raster.

A strong starting strategy:

| Asset | Editable master | Suggested runtime strategy |
|---|---|---|
| Hanafuda card | ~1536–2048 px tall or vector/high-resolution equivalent | Usually 768–1024 px tall; raise only if actual 4K maximum display requires it |
| Modifier card | ~1536 px tall | ~768–1024 px tall |
| UI icon | Vector master where possible | Raster sizes appropriate to actual UI scale; avoid enormous universal icon sheets |
| Full-screen environment | 4K-capable master | Export only layers that require full resolution at 2K/4K |
| Decorative prop | 2× expected largest screen size | Per-asset |
| Particle sprite | Usually 32–128 px | Keep tiny |
| Masks/gradients | Resolution driven by edge quality | Often much smaller than background |

Godot’s image importer exposes texture compression and mipmap-related decisions at import time, so source-file choice and runtime import policy should be intentional rather than treated as a last-minute optimization. citeturn3view2

For painted/illustrated hanafuda:

- use **lossless or visually lossless treatment** for final card faces;
- use **linear filtering** rather than nearest-neighbor unless the art is intentionally pixel art;
- enable mipmaps when cards spend substantial time scaled down or rotating;
- do not force global pixel snapping for smooth illustrated cards;
- prefer settled transforms that land cleanly and stay fixed;
- inspect smallest captured-card rendering for thin-line loss;
- inspect hover scale for raster softness;
- inspect 4K output independently.

Nearest filtering would make a non-pixel-art card edge and diagonal illustration visibly stair-step. Conversely, unfiltered high-frequency artwork that is dramatically minified can shimmer. The import strategy should therefore follow the actual art style rather than a blanket “2D = nearest” rule. Godot’s importer documentation is the correct source of truth for current import options. citeturn3view2

**Atlases versus individual textures.**

For just 48 traditional cards, authoring simplicity matters more than prematurely constructing an atlas pipeline.

Start with individual card assets or a clean asset-resource abstraction. Atlas only if profiling demonstrates a meaningful rendering/state-change benefit.

An atlas introduces:

- bleed/padding requirements;
- more awkward per-card replacement;
- larger regeneration steps;
- more friction for art iteration;
- possible modding/variant complications.

Its upside is consolidated texture management and potentially fewer texture changes.

That trade is worth measuring, not guessing.

**Depth and Shadow System.**

Do not attempt realistic global illumination. Build a consistent **height vocabulary**.

At 720p, a useful starting point is:

| State | Shadow character |
|---|---|
| Resting card | Tight, subtle 1–2 px offset |
| Selected card | ~3–4 px |
| Hovered card | ~4–6 px |
| Card in travel | ~6–10 px |
| Dragged/owned modifier | ~6–10 px |
| Settling card | Shadow contracts as object lands |
| Locked UI slot | Minimal/recessed shadow |
| Elevated reward | Stronger but still tight |

This can be implemented with duplicated silhouettes, a reusable shadow texture/frame, or other CanvasItem-based treatments. A rectangular card with predictable shape does **not** need an expensive bespoke blurred shader just to communicate height.

The key relationship is:

```text
higher visual object
= slightly greater shadow offset
+ perhaps slightly greater shadow softness
+ perhaps tiny scale increase
```

Never use enormous soft web-dashboard shadows around every panel.

**Materiality System.**

Give every visual effect a material answer.

Suggested grammar:

| Object | Material impression | Presentation consequence |
|---|---|---|
| Hanafuda | Rigid printed/lacquered card stock | Firm movement, short transient, restrained highlight |
| Table/game surface | Wood, cloth, paper, or other chosen physical base | Defines friction/contact sound |
| Carry slot | Tray/sleeve/frame | Object visibly seats into it |
| Modifier | Card/tile/sleeve consistent with final art direction | Can support slightly richer sheen than traditional cards |
| Currency | Ledger/chit/token metaphor | Avoid casino coin shower unless actual object design justifies coin |
| Locked capability | Seal/latch/closed frame | Unlock movement has physical cause |
| Month environment | Background/world layer | Should not glow as though it were UI |

Put most paper grain, ink irregularity, edge treatment, and surface character in the artwork itself.

Shader-added grain should be an exception because moving procedural texture across static paper frequently looks less material, not more.

**Shader Library.**

The useful library can remain very small.

| Shader | Purpose | Complexity | Cost | Compatibility | Warning |
|---|---|---:|---|---|---|
| `card_state` | Selection/legal/locked/desaturated state | Low–medium | Low per card | Strong fit for CanvasItem | Do not neon-outline every active card |
| `modifier_sheen` | Directional lacquer/foil-like highlight | Medium | Low–medium | CanvasItem-friendly | Only where material justifies it |
| `mask_reveal` | Slot seal/reveal, Moon wipe | Medium | Low–medium | Local CanvasItem use | Avoid making every UI entrance a dissolve |
| `focus_overlay` | Controlled dim/vignette/focus | Low | Low | Prefer overlay without screen sampling | Never obscure card values |
| `season_tint` | Optional background/environment tint | Low | Low | Good | Do not tint card faces and distort identification |

`card_state` should be parameterized:

```text
outline_enabled
outline_color
outline_width
saturation
brightness
locked_amount
highlight_amount
```

Do not create:

```text
card_selected.gdshader
card_legal.gdshader
card_upgraded.gdshader
card_locked.gdshader
card_reward.gdshader
```

when one shared shader can express those states.

Likewise, a baked edge texture is better than a shader when nothing about the edge changes dynamically.

The shader rule is:

> **If the effect describes a changing pixel state, consider a shader. If it describes an unchanging material detail, bake it. If transform/opacity solves it, do not write a shader.**

Avoid screen-reading implementations for focus/blur merely because they look impressive in isolation. Godot’s screen-reading mechanism involves back-buffer handling, making it a materially heavier architectural tool than local CanvasItem shading. citeturn3view1

## Seasonal presentation and sound

**Seasonal Visual System.**

Do not build twelve boards.

Build a data-driven composition system with a small number of reusable layers:

```text
Base table / architecture
Distant environment
Seasonal large-form layer
Month-specific prop layer
Foreground accent layer
Optional low-density ambience
Palette/light profile
Audio ambience profile
Moon title treatment
```

A `MonthPresentationProfile` resource can own references:

```gdscript
class_name MonthPresentationProfile
extends Resource

@export var month_id: StringName
@export var moon_name: String
@export_multiline var rule_summary: String

@export var background_layer: Texture2D
@export var seasonal_overlay: Texture2D
@export var foreground_accent: Texture2D
@export var ambient_scene: PackedScene

@export var ambience_stream: AudioStream
@export var intro_stinger: AudioStream

@export var environment_tint: Color = Color.WHITE
@export var transition_duration := 1.0
```

The high-value production distribution is approximately:

1. **Palette/background lighting:** very high impact, very low marginal cost.
2. **A few seasonal environmental layers:** high impact, reusable.
3. **Month-specific props/vegetation:** good identity per asset.
4. **Ambient audio:** extremely high mood-to-cost ratio.
5. **Sparse seasonal particles:** useful only in appropriate months.
6. **Unique board scene:** poor reuse; avoid.
7. **Unique shader stack per month:** poor maintainability; avoid.

Do not make Moon names mechanically literal. A Snow Moon does not require a gameplay-state blizzard. Environmental art should reinforce the calendar, not imply nonexistent modifiers.

**Moon Introduction System.**

Use one repeatable grammar:

```text
environment settles
→ Moon name
→ one-line rule
→ opponent identifier if needed
→ short sound/music cue
→ player can proceed
```

Standard length: roughly **1.2–1.8 seconds**. Fast mode: roughly **0.6–1.0 second**.

The title should have enough art direction to be recognizable in a trailer frame, but the *information* is the Moon name and rule.

Do not create twelve mini-cinematics. Create one strong presentation template with month data and a limited number of seasonal variants.

**Audio Style Guide.**

Audio should communicate **material first, semantic importance second**.

A surprisingly small family library is sufficient:

| Family | Variants needed initially | Used for |
|---|---:|---|
| Card pickup/lift | 3–4 | Select, drag |
| Card slide/deal | 4–6 | Deal, travel |
| Card placement/contact | 4–6 | Play, settle |
| Card flip | 3–4 | Reveal |
| Card collect/capture | 3–5 | Capture movement |
| UI press | 2–4 | Buttons |
| Invalid | 1–2 | Disabled/insufficient |
| Tray/slot mechanism | 2–3 | Carry movement/unlock |
| Economy/ledger | 3–4 | Buy/sell/currency |
| Yaku tonal motif | 2–3 intensity variants | Scoring |
| Koi-Koi | 1 strong identity | Declaration |
| Stop/closure | 1–2 | Stop/finalization |
| Reward | 2–3 | Reveal/acquire |
| Phase/Moon | small family | Transitions |

You do not need 40 completely unrelated effects.

The repeated card sounds need the most variation because the player will hear them hundreds or thousands of times.

**Layered SFX Architecture.**

Important interactions should combine a physical layer with at most one or two semantic layers.

**Capture**

```text
paper/card travel
+ precise dry contact transient
+ very quiet tonal confirmation
```

**Slot unlock**

```text
latch/mechanism
+ frame/paper/wood movement
+ restrained tonal bloom
```

**Reward acquisition**

```text
card/object movement
+ destination-seat contact
+ short confirmation tone
```

**Purchase**

```text
owned object movement
+ ledger/token debit
```

**Named yaku**

```text
subtle card/group movement texture
+ tonal identity
```

**Koi-Koi**

```text
declaration/stamp-like transient
+ lower tonal body
+ optional music stinger
```

Keep these stems independently adjustable.

For frequently repeated card sounds, start with **3–5 samples per family** and subtle cosmetic variation, perhaps roughly ±2–3% pitch and around ±1 dB level. These are recommended tuning bounds for 12 Moons, not universal standards. Tonal stingers should vary much less or not at all because pitch changes can weaken musical identity.

Critically:

> **Audio variation must never consume or perturb gameplay RNG.**

Presentation randomness can be nondeterministic or have its own cosmetic seed.

**Music-System Recommendation.**

A sophisticated adaptive soundtrack is **not justified yet**.

The smallest useful structure is:

```text
ordinary match loop
between-month / reward / shop loop
Koi-Koi stinger
major result stinger
month transition cue
```

Later, a single optional tension layer after Koi-Koi would produce most of the value of a much more complicated adaptive system:

```text
normal play
+ tension stem at low level after Koi-Koi
```

That is enough.

Do not build an elaborate multi-stem state machine before the game has strong card SFX and baseline music assets.

Crossfades should occur at logical phase boundaries. Where the eventual music is written for synchronized transitions, use musical boundaries; otherwise a well-tuned short crossfade is preferable to brittle beat logic.

**Ambience System.**

Use ambience to make the year feel inhabited.

The scalable answer is four broad seasonal families plus small month accents, not twelve completely unrelated soundscapes.

Examples:

```text
Winter base
+ sparse exterior/wind texture
+ January accent
+ February accent

Spring base
+ light garden/insect/bird texture
+ March/April/May accents
```

The actual ambience must agree with the visual space. Do not play rain because “rain sounds atmospheric” when no rain exists visually.

Ambience should be quiet enough that the player notices its *absence* before consciously noticing the loop.

**Audio Bus / Mixing Architecture.**

Use:

```text
Master
├── Music
├── SFX
├── UI
└── Ambience
```

That is sufficient.

Do not split card/card-impact/yaku/economy into user-facing buses unless a real mix requirement emerges.

During development, mix normal play with clear headroom rather than using a limiter to rescue constant clipping. Hover/focus sounds should sit substantially below card impact and scoring cues. Ambience should sit below music, and music should leave room for card transients.

A Master limiter can remain a final safety layer, not a method of making every event loud.

The game should expose at least:

- Master;
- Music;
- SFX;
- Ambience, if ambience becomes substantial.

UI can remain under SFX in settings even if it has its own internal bus for mix control.

**Haptics.**

Do not implement haptics for this milestone.

Do establish feedback calls so a future `HapticPresenter` could consume the same semantic events:

```text
capture_impact
major_yaku
koi_koi
slot_unlock
run_landmark
```

Ordinary hover/deal/reflow should never need vibration.

## Production architecture, assets, accessibility, and performance

**Asset Pipeline.**

A maintainable layout could be:

```text
source_assets/                    # editable masters; ignored by Godot import
    cards/
    modifiers/
    backgrounds/
    ui/
    audio/
    licenses/

game/
    assets/
        cards/
        modifiers/
        ui/
        backgrounds/
            base/
            seasons/
            months/
        vfx/
    audio/
        sfx/
            cards/
            ui/
            economy/
            yaku/
            transitions/
        music/
        ambience/
    shaders/
    presentation/
        resources/
            motion/
            audio/
            months/
```

If editable source files live inside the repository, keep them outside active Godot import paths or otherwise exclude them appropriately. Runtime assets should be intentional exports rather than PSD/Krita/DAW working files.

Recommended naming:

```text
card_01_pine_crane.png
card_02_pine_kasu_a.png

mod_extra_carry_01.png

sfx_card_place_01.wav
sfx_card_place_02.wav
sfx_capture_collect_01.wav

mus_match_winter.ogg
amb_winter_garden_01.ogg

sh_card_state.gdshader
sh_modifier_sheen.gdshader

month_january_presentation.tres
motion_default.tres
```

Keep metadata for externally sourced or AI-assisted assets: source, generation method where relevant, license/rights, human revision status, and final approver.

AI-assisted production should therefore be:

```text
generation/reference
→ human selection
→ deliberate editing
→ palette/material consistency pass
→ technical export
→ in-game inspection
→ approved runtime asset
```

not:

```text
prompt
→ output file
→ game
```

For audio, short frequent SFX are good candidates for PCM/lossless runtime assets; long music/ambience should use a compressed streaming-oriented format supported by the project. For textures, card faces deserve conservative compression; large backgrounds can tolerate more aggressive optimization after visual inspection.

Godot’s import pipeline is designed around editable source assets being converted to engine-ready imported resources, and its image import settings are the place to establish compression/mipmap policy. citeturn3view2

**Animation Architecture.**

Keep the division extremely clear:

| System | Owns |
|---|---|
| **Tween** | Dynamic endpoints, card motion, reflow, hover, counters, panels |
| **AnimationPlayer** | Authored fixed sequences: slot unlock, Moon title, special ceremony |
| **Procedural code** | Velocity-dependent tilt, Bézier path evaluation, optional spring response |
| **CanvasItem shader** | Pixel appearance and state |
| **Particles** | One-shot visual fragments/ambient emitters |
| **Presentation queue** | Semantic ordering |
| **Gameplay model** | Actual rules and state |

`AnimationTree` is unlikely to earn its complexity for current card/UI presentation. It becomes attractive when blending many authored animation states for characters or other complex animated actors—not for a handful of cards and panels.

**Presentation Queue Evolution.**

Do not evolve the current queue into one enormous `match` statement with 100 presentation cases.

Use domain presenters:

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

Queue entries should describe *what happened*:

```gdscript
{
    "type": &"capture_resolved",
    "played_card_id": card_id,
    "matched_card_ids": matched_ids,
    "capture_owner": player_id,
    "yaku_before": old_yaku,
    "yaku_after": new_yaku
}
```

not:

```gdscript
{
    "type": "move_node",
    "node_path": "...",
    "x": 712,
    "y": 314
}
```

The presenter resolves semantic targets into scene positions.

That keeps gameplay deterministic and makes presentation replaceable.

Use explicit parallelism:

```text
sequence:
    play_card_motion

parallel:
    impact_sound
    impact_shadow
    target_response

sequence:
    capture_motion
    capture_reflow

sequence:
    yaku_feedback
```

A small concept such as `PresentationStep` with `SEQUENCE`, `PARALLEL`, and `BARRIER` semantics can scale far better than adding nested `await`s everywhere.

**Animation Cancellation / Fast-Forward.**

Cancellation must be a first-class outcome, not an exceptional case.

Cases:

```text
restart match
leave scene
skip ceremony
reduced motion
debug fast-forward
phase teardown
```

A robust pattern is a presentation generation/epoch:

```gdscript
var presentation_epoch: int = 0

func cancel_presentation() -> void:
    presentation_epoch += 1
    _kill_tracked_tweens()
    _clear_presentation_input_locks()
    _restore_required_final_visual_state()
```

At the start of a recipe:

```gdscript
var epoch := presentation_epoch

# ... await some presentation operation ...

if epoch != presentation_epoch:
    return
```

Do not design the queue so progression relies exclusively on a completion callback from an animation that cancellation can destroy.

Every presentation recipe should support three conceptual execution modes:

```text
NORMAL
FAST
INSTANT
```

`INSTANT` must set the correct final visual state synchronously. It should not take a separate gameplay route.

This gives debug tools, accessibility, and skip behavior essentially for free.

**Reduced Motion and Animation Speed.**

Recommended settings:

```text
Animation Speed
    Normal
    Fast
    Instant

Reduced Motion
    Off / On
```

Reduced motion should:

- remove camera impulses;
- disable parallax drift;
- replace long arcs with shorter direct travel;
- disable spring overshoot;
- drastically reduce or remove nonessential particles;
- replace large sliding-screen transitions with fades/local movement;
- remove decorative tilts;
- retain state highlights and spatial relationships.

Animation disabled must never make gameplay harder to understand.

A capture in Instant mode can simply:

```text
highlight match
→ place cards in captured area
→ show yaku delta
```

with no travel animation.

**Visual Clarity During Motion.**

Apply four hard rules:

**One causal cluster at a time.** During ordinary turns, only the cards involved in the current action plus necessary reflow should be moving.

**Never animate the interaction target underneath the pointer without cause.** A hover should not trigger sorting.

**Effects stay behind or outside identity-bearing card art.** No particle cloud over the flower/month image.

**Selection is stable while input is expected.** Camera movement, hand reflow, or background parallax must not interfere with click accuracy.

Deal is the one legitimate mass-motion exception because input is not expected yet.

**Animation and Input Responsiveness.**

Gameplay may be serialized visually without feeling laggy if acknowledgment is immediate.

On click:

```text
same frame:
    selection visual state
    lift/shadow response
    click/contact audio
    gameplay command

next:
    travel
    consequence presentation
```

Do not intentionally insert “anticipation” before direct manipulation. Anticipation belongs to automated reveals and ceremonies.

**Performance Budgets.**

The hard 60 FPS frame interval is **16.67 ms**. For a lightweight 2D card game, the sensible engineering goal is to leave substantial headroom rather than merely touching that limit.

Use these as **internal regression targets**, not claims about universal Godot limits:

| Category | 12 Moons target |
|---|---|
| Frame time | Stay comfortably below 16.67 ms on target integrated graphics |
| CPU main-thread work | Prefer representative gameplay below ~8–10 ms |
| GPU frame | Prefer below ~8–10 ms on reference low-end hardware |
| Moving cards during normal turn | Usually ≤4 simultaneously |
| Moving cards during deal | Up to dealt group; ~24 is visually acceptable because no input occurs |
| Routine particles | Zero or near zero |
| Hero burst particles | Prefer dozens, not hundreds/thousands |
| Extra rendered SubViewports | Zero normally |
| Full-screen screen-read passes | Zero in ordinary play |
| Full-screen transparent layers | Keep few and simple |
| Active Tweens | Do not set an artificial engine cap; profile, but keep visual concurrency controlled |
| Draw calls | Aim for low hundreds or less; baseline and regression matter more than a magic number |
| Texture memory | Establish measured baseline; treat hundreds of MiB for a simple 2D scene as a warning worth investigation |

A single uncompressed 3840×2160 RGBA8 image is approximately **31.6 MiB** of raw pixel data:

`3840 × 2160 × 4 ≈ 33.2 million bytes`.

That makes the danger of casually stacking several unique 4K backgrounds, masks, render targets, and full-screen copies obvious even before driver overhead.

Compatibility-first visual polish should therefore favor local effects and reusable layers.

**Profiling Workflow.**

Godot provides profiling facilities intended to measure runtime cost rather than relying on intuition. The official profiler documentation should remain the source of truth for the current editor’s profiler and monitor workflow. citeturn3view3

Create stable profiling scenarios:

```text
idle January board
opening deal
ordinary play
capture
capture + yaku
Stop/Koi-Koi prompt
largest settlement
reward reveal
carry rearrangement
shop reroll
Moon transition
```

For each milestone:

1. Run a baseline build.
2. Record frame time and relevant rendering/memory statistics.
3. Add one polish system.
4. Re-run the same scenarios.
5. Investigate any large regression that is not producing equally large visual value.
6. Test 1280×720 and at least one high-resolution configuration.
7. Test actual modest integrated graphics before calling a system inexpensive.

Do not optimize based on the number of Tweens in source code while ignoring a 4K full-screen shader.

Godot’s own profiling guidance is built around using runtime measurements to locate bottlenecks rather than assuming which subsystem is responsible. citeturn3view3

## Anti-synthetic review checklists

**Anti-AI-Slop Motion Checklist.**

| Warning sign | Why it feels synthetic | Better principle |
|---|---|---|
| Every object uses the same ease | Motion no longer communicates material or intent | Use semantic motion tokens |
| Everything scales from zero | Objects have no spatial origin | Enter from a real source, slot, tray, or edge |
| Every action overshoots | Cards become rubbery | Overshoot only where elastic/mechanical behavior is justified |
| Bounce after every placement | Repeated canned “juice” overwhelms material physics | One controlled settle, often none |
| Constant idle floating | Nothing feels grounded or important | Rest should be truly still |
| Random card rotation on every move | Object identity becomes unstable | Small deterministic orientation |
| All UI slides from arbitrary directions | Space has no model | Give each region a consistent physical location |
| Every important moment zooms | Importance inflation | Reserve reframing for milestones |
| Giant scale pulses | Generic “pop” replaces authored emphasis | Use lift, light, shadow, grouping |
| Unrelated objects animate simultaneously | Attention has no causal hierarchy | Sequence by cause and effect |
| Long anticipation after a click | Feels like input latency | Acknowledge direct input immediately |
| Twenty-four slow deal animations | Ceremony turns into friction | Fast overlapping waves |
| Rewards hover forever | Constant motion devalues selection | Static default, responsive hover |
| UI reflows under cursor | Breaks trust and clickability | Freeze unnecessary layout changes during interaction |
| Card motion ignores source/destination | Looks like template animation | Preserve spatial continuity |
| Every month uses the same animation with different text | Feels generated rather than art-directed | Stable grammar plus a few meaningful seasonal variables |
| Randomness changes continuously | Produces visual noise | Cosmetic randomness should establish state, then remain stable |
| Animation ends without a contact moment | Object seems weightless | Give movement a readable arrival |

**Anti-AI-Slop VFX Checklist.**

| Warning sign | Why it feels synthetic | Better principle |
|---|---|---|
| Glow around every interactable | Glow becomes UI wallpaper | Use shape, contrast, shadow, and local outline |
| Neon selection borders | Conflicts with material hanafuda identity | Ink/frame/edge treatment coherent with art |
| Rainbow rarity gradients | Imports generic loot-game vocabulary | Rarity/significance through material and composition |
| Sparkles on every reward | No causal relationship | Reserve particulate accent for genuinely rare/material events |
| Dust floating everywhere | Atmosphere becomes filler | Only use environmental particles with a specific setting |
| Lens flare | No light source or camera basis | Omit |
| Bright full-screen flash | Obscures information and causes accessibility problems | Localized contrast or tonal arrival |
| Bloom imitation everywhere | Makes cards less crisp | Keep card art high-contrast and clean |
| Trails behind ordinary cards | Makes physical cards look magical | Shadow/lift is enough |
| Dissolve for ordinary panels | Material continuity disappears | Slide/fold/retract/fade according to spatial logic |
| Every modifier has a unique shader | Style and maintenance fragment | Shared parameterized shader set |
| Stronger rarity = stronger emission | Turns strategy objects into loot | Use framing/art/material differentiation |
| Particles cover card faces | Feedback destroys information | Keep effects behind/peripheral |
| Full-screen blur for every modal | Expensive and visually fashionable rather than necessary | Controlled dimming |

**Anti-AI-Slop Audio Checklist.**

| Warning sign | Why it feels synthetic | Better principle |
|---|---|---|
| Same click everywhere | Materials and actions lose identity | Small sound families |
| Loud confirmation on every button | Audio hierarchy collapses | UI acknowledgments stay quiet |
| Casino coins for economy | Implies slot-machine reward structure | Ledger, token, paper, or chosen world material |
| Stock fantasy chime for yaku | Semantic tone has no identity | Create a small yaku motif family |
| Swoosh on every card | Emphasizes generic motion, not material | Card/paper movement first |
| Random pitch on musical stingers | Musical identity destabilizes | Randomize repeated physical effects, not motifs |
| Wide pitch randomization | Sounds like different-sized objects | Keep microvariation subtle |
| Every hover makes sound | Creates high-frequency fatigue | Sound hover selectively or omit |
| Layering 5–8 sounds for routine actions | Ordinary actions become exhausting | 1–2 layers for normal actions |
| Inconsistent room/material reverberation | World feels assembled from libraries | Establish one acoustic perspective |
| Excessive bright transients | Repetition becomes painful | Vary spectrum and keep routine cues soft |
| A “reward” sound before player understands why | Feedback gets ahead of causality | Sound at the semantic event |
| Audio RNG shares gameplay RNG | Cosmetic variation can compromise deterministic workflows | Separate RNG completely |

## Priorities, readability, comparisons, references, and risks

**High-Value Polish Ranking.**

| Tier | System | Player impact | Cost | Reuse | Risk |
|---|---|---:|---:|---:|---:|
| **Implement early** | Immediate input lift/shadow | Very high | Low | Very high | Low |
| **Implement early** | Card movement/easing vocabulary | Very high | Low | Very high | Low |
| **Implement early** | Card SFX family | Very high | Medium | Very high | Low |
| **Implement early** | Capture sequence | Very high | Medium | Very high | Low |
| **Implement early** | Settlement cause/effect | Very high | Medium | High | Low |
| **Implement early** | Reward → carry continuity | High | Medium | High | Low |
| **Implement early** | Purchase/sell/reroll feedback | High | Low–medium | High | Low |
| **Implement early** | Transition shell | High | Medium | Very high | Medium |
| **Infrastructure now** | MotionProfile | High indirect | Low | Very high | Low |
| **Infrastructure now** | Cancellation/fast-forward | High indirect | Medium | Very high | Medium |
| **Infrastructure now** | Semantic audio cues | High indirect | Medium | Very high | Low |
| **Infrastructure now** | MonthPresentationProfile | Medium now | Low | Very high | Low |
| **Infrastructure now** | Shared card-state shader | Medium | Low | Very high | Low |
| **Add later** | Seasonal environmental layers | High | Medium | High | Low |
| **Add later** | Major-yaku hero treatment | Medium | Medium | Medium | Low |
| **Add later** | Post-Koi-Koi music layer | Medium | Medium | Medium | Medium |
| **Add later** | Seasonal particles | Low–medium | Low | Medium | Low |
| **Add later** | Haptics | Low–medium | Low | Medium | Low |
| **Probably unnecessary** | Card physics simulation | Low/negative | High | Low | High |
| **Probably unnecessary** | Heavy full-screen post | Low | Medium–high | Low | High |
| **Probably unnecessary** | Twelve bespoke board scenes | Medium | Very high | Very low | High |
| **Probably unnecessary** | Unique modifier animations | Low | Very high | Low | Medium |
| **Probably unnecessary** | Large shader library | Low | Medium–high | Low | High |
| **Actively harmful** | Routine camera shake | Negative | Low | — | High |
| **Actively harmful** | Generic capture particles | Negative | Low | — | High |
| **Actively harmful** | Loot-box reward reveals | Identity damage | Medium | — | High |

**Screenshot / Trailer Readability.**

Presentation decisions that improve play also improve capture quality.

A strong 12 Moons frame should make these legible almost immediately:

```text
where the player's hand is
where the field is
which cards are interacting
where captured cards accumulate
what the current important score/state is
which phase the player is in
```

Cards must remain large enough that hanafuda imagery forms the board’s visual signature. Effects should frame the focal pair, not turn the frame into light.

Useful “hero frames” already exist naturally:

- starting-player reveal;
- a major named/Bright yaku;
- Koi-Koi declaration;
- a large but comprehensible settlement;
- the carry slot opening;
- the chosen reward entering the new slot;
- a nearly/full carry build;
- transition into a strongly differentiated season;
- December/run resolution.

Do not create mechanics merely to produce trailer moments.

For video capture, allow an action to **land and hold briefly**. A 50 ms burst may feel fine interactively but disappear in an encoded social clip. Named milestones benefit from a 200–400 ms composed end-state after the actual motion.

**Comparable Game Case Studies.**

These are comparative design readings of shipped games rather than claims about their proprietary implementation.

| Game | Technique worth studying | Adapt for 12 Moons | Do not copy |
|---|---|---|---|
| **Hearthstone** | Cards have obvious lift, travel, contact, and audiovisual consequence | Clarity of height and contact timing | Combat spell spectacle, board explosions, fantasy VFX density |
| **Balatro** | Extremely responsive card hover/selection and clear score escalation | Immediate pointer response, object identity, strong numerical readability | Casino visual vocabulary, constant chromatic spectacle, score fireworks |
| **Inscryption** | Strong spatial continuity and sense that menus/game systems inhabit one tabletop space | Between-phase continuity and tangible object destinations | Heavy 3D camera movement, horror framing, obscured information |
| **Slay the Spire** | Rapid card resolution and readable hierarchy between hand/action/result | Fast ordinary interaction and low-friction repeated play | Combat targeting vocabulary and magical effect language |
| **Digital tabletop adaptations generally** | Persistent board locations let players build spatial memory | Stable hands/field/capture/carry/economy zones | Literal physics when it makes layouts imprecise |
| **Digital poker/solitaire traditions** | Efficient dealing and unmistakable source/destination | Overlapping deal cadence and direct card movement | Casino sounds and celebratory money spectacle |

The useful synthesis is not to visually blend these games. It is to take **Hearthstone’s contact clarity, Balatro’s input immediacy, Inscryption’s spatial continuity, and Slay the Spire’s pace**, while preserving a uniquely hanafuda-centered visual language.

**Relevant Open-Source Projects.**

The only external codebase I would recommend for direct technical study here without pretending to have verified a third-party card framework to production standards is Godot’s own demo repository:

| Project | URL | License | Engine/version | Relevant material | Lessons | Reuse potential |
|---|---|---|---|---|---|---|
| Godot Demo Projects | `https://github.com/godotengine/godot-demo-projects` | MIT | Godot 4.x; use revision/tag matching the project’s engine version | 2D rendering, shaders, particles, animation, audio, viewport examples plus each demo’s `project.godot`, scripts and shader resources | Canonical small examples of engine-native techniques | **High for study, selective for snippets; do not import a demo wholesale** |
| Godot Engine source | `https://github.com/godotengine/godot` | MIT | Match the 4.7 branch/tag used by project | Tween, CanvasItem, renderer and audio implementation when documentation leaves edge cases unclear | Useful for exact behavioral questions and bug investigation | **Low direct reuse; high diagnostic value** |

For compatibility-specific behavior, the official documentation remains preferable to copying an effect from an arbitrary Godot repository. The current renderer documentation explicitly documents the project-level trade space between Compatibility and the other renderer choices. citeturn3view0

I am deliberately **not** inventing a list of third-party card-game repositories with unverified licenses, Godot versions, and supposedly relevant files. That would fail the source-quality requirement more seriously than providing a shorter verified list.

**Production Risk Register.**

| Risk | Likelihood | Severity | Cost if fixed late | Mitigation |
|---|---|---|---|---|
| Ordinary animation becomes too slow | High | High | Medium | Animation-speed mode; hard timing budgets; repeated-play testing |
| Presentation becomes coupled to game authority | Medium | Critical | Very high | Semantic queue; immutable event snapshots; animation never mutates rules |
| Queue deadlock during cancellation | Medium | High | High | Explicit cancel contract/session epoch; final-state restoration |
| Low-resolution cards discovered at 4K | Medium | High | Very high | High-res masters now; 4K visual test early |
| Cards move too much to read | Medium | High | Medium | Rotation caps, concurrency rules, input-safe reflow |
| Shader proliferation | High | Medium | Medium | Parameterized library of ~3–5 shaders |
| Full-screen effects hurt Compatibility performance | Medium | High | Medium | Zero normal screen-read passes; profile every exception |
| VFX obscures hanafuda art | Medium | High | Low–medium | Effects behind/peripheral; no routine particles |
| Camera movement causes fatigue | Medium | Medium–high | Low | Fixed camera default; major-event only; reduced-motion switch |
| Audio repetition becomes obvious | High | Medium | Medium | Families/sample pools early |
| Audio becomes casino-like | Medium | High identity cost | Medium | Material/ledger vocabulary |
| Reward presentation becomes gacha-like | Medium | High identity cost | Medium | Fast face-up comparison and physical ownership transition |
| Twelve months multiply asset work | High | High | Very high | Layered seasonal system/data profiles |
| AI-assisted art loses consistency | High | High | High | Master art direction + human approval pipeline |
| Hand reflow breaks pointer trust | Medium | High | Medium | Stable slots; no resort during interaction |
| Too many one-off hero animations | Medium | Medium | High | Ceremony templates with parameters |
| Shop animations slow strategic comparison | Medium | High | Low | 100–350 ms interaction budget |
| Reduced-motion retrofitted late | Medium | High | High | Motion modes built into primitives now |

**Things NOT to Build Yet.**

Do not spend the January-to-February milestone on:

- dynamic 2D lighting systems for every card;
- full-screen blur or post-processing pipelines;
- twelve bespoke board scenes;
- simulated rigid-body card physics;
- a general-purpose cinematic camera framework;
- a particle editor abstraction;
- individual VFX for each modifier;
- individual animation timelines for each modifier;
- rare December victory effects;
- elaborate weather simulation;
- a multi-stem adaptive soundtrack;
- complex controller haptics;
- shader-driven paper fibers;
- procedural wear/damage;
- runtime normal-map generation;
- multiple render-to-texture compositing stages;
- unique reward-opening ceremonies;
- animated rarity borders;
- elaborate first-player effects beyond the existing ceremony’s actual needs.

The most dangerous form of premature polish is an effect that looks impressive in an isolated GIF but does nothing for the hundreds of ordinary actions the player will repeat.

**Open questions / source limitations.**

The Compatibility-renderer, image-import, screen-reading-shader, and profiling recommendations above are grounded in current official Godot documentation. citeturn3view0turn3view1turn3view2turn3view3

The detailed timing numbers are intentionally **12 Moons production recommendations**, not fabricated “industry-standard” values.

Likewise, the comparable-game section describes visible design techniques rather than making unsupported claims about proprietary engines or source code. Third-party open-source Godot card projects have been omitted where exact license, current Godot compatibility, and file-level suitability were not verified to a standard appropriate for code-reuse advice.

## Recommended production order

The best roadmap begins with the actions that happen constantly, then builds outward toward the year.

| Stage | Objective | Systems affected | Assets required | Technical implementation | Performance check | Accessibility check | Acceptance criteria |
|---|---|---|---|---|---|---|---|
| **Foundation** | Establish one motion/audio/cancellation language | Motion controller, presentation queue, settings | None/minimal | `MotionProfile`, presentation speed modes, cancellation token/epoch, audio cue IDs | Baseline frame/memory profile | Normal/Fast/Instant and reduced motion all execute | No duration/easing duplicated arbitrarily in new code |
| **Card physicality** | Make ordinary manipulation feel premium | Hover, select, play, draw, flip, reflow | Card shadows, first card SFX family | Height/shadow state, restrained rotation, motion paths | Profile opening deal + full hand | No arcs/tilt/camera in reduced mode | Ten minutes of ordinary play does not feel sluggish or visually busy |
| **Capture** | Make the most repeated hanafuda reward excellent | Play → target → collect → captured layout | Contact/collect sound variants | Standard + accelerated capture recipes | Stress repeated captures | Instant mode still communicates match | Player can visually tell which cards matched before they leave field |
| **Scoring decisions** | Clarify yaku and Stop/Koi-Koi hierarchy | Yaku, score UI, decision overlay | Small/major yaku tones, Koi-Koi cue | Event-level feedback hierarchy | Test stacked yaku | No mandatory camera motion | Incremental scoring stays quiet; named yaku feels unmistakably stronger |
| **January settlement** | Explain every point and bankroll consequence | Settlement, economy | Settlement/ledger SFX, simple score graphics | Immutable `before/after` presentation data; staged equation | Worst-case settlement | Skip reaches identical final state | A new player can reconstruct why the final score is what it is |
| **Carry unlock and rewards** | Turn progression into a tangible event | Carry slots, reward selection | Lock/seal/tray assets, reward acquisition SFX | AnimationPlayer unlock + Tween reward travel | Profile several reward objects | Unlock simplifies in reduced mode | Chosen reward visibly becomes owned; no loot-box language |
| **Shop** | Make high-frequency economic actions immediate | Purchase, sale, reroll, affordance states | Small shop SFX family | Reusable item travel, ledger delta, offer replacement | Spam reroll/purchase test | Fast/Instant stays usable | Repeated shopping never feels ceremonially slow |
| **Between-phase continuity** | Eliminate prototype screen cuts | Settlement/reward/carry/shop shell | Shared background/tray/panel elements | Persistent anchors or equivalent scene-transition contract | Check overdraw/hidden node cost | Large movement replaced by fade when needed | Bankroll/carry/world maintain spatial identity through entire milestone |
| **February transition** | Prove scalable month system | Month profiles, environment, Moon intro | January/February presentation layers | `MonthPresentationProfile` + transition recipe | 720p/1080p/4K transition profile | Intro accelerable/skippable | February feels distinct without a bespoke new scene architecture |
| **Seasonal expansion** | Scale identity through December | Environments, ambience | Seasonal layers, props, ambience | Data-driven composition | Texture-memory review each season | Particles/motion optional | Adding a month is mostly data/assets, not new presentation code |
| **Late hero polish** | Make genuinely rare moments memorable | Major yaku, season landmarks, December | Hero audio/VFX | Existing hierarchy at Level 4–5 | Worst-case effects | Flash/motion alternatives | Hero events feel exceptional precisely because normal play is restrained |

The acceptance standard for the milestone should not be “the new menus animate.”

It should be:

> **From the last January card through the first February screen, the player never loses track of what happened, what changed, what they earned, where it went, what they bought, what they now own, or where they are in the year.**

And the acceptance standard for the eventual full game should be even simpler:

> **Ordinary cards feel physical enough that VFX is unnecessary; important consequences are staged clearly enough that spectacle is optional; and the rare moments that do receive spectacle remain memorable because the rest of 12 Moons knows how to be quiet.**