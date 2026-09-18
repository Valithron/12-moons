# 12 Moons UX Research: A Disciplined Table-First Interface System

12 Moons should not be designed as a collection of screens with a hanafuda game in the middle. It should be designed as **one continuous tabletop experience whose information surfaces expand and contract around the player's current decision**.

The strongest direction is therefore **table-first, context-preserving, focus-driven, and progressively disclosed**:

> **Hanafuda cards are the primary objects. The table is the persistent world. Strategic information lives around the table. Roguelike systems enter as attached trays, slips, seals, ledgers, and offers—not as a second dashboard-style game layered on top.**

That direction is especially important because the current repository already has a useful separation between the main table, moving-card layer, and overlay/presentation layers; it also has a deterministic presentation queue. Those are good foundations for maintaining spatial continuity across future systems. At the same time, the current UI contains several prototype conventions that should **not** become architectural precedent: extensive absolute positioning, local color/font overrides, 9–10 px scoring text, full-screen score-decision dimming, and interactive cards that explicitly set `focus_mode = FOCUS_NONE`. fileciteturn10file0L2-L2 fileciteturn14file0L2-L2 fileciteturn8file0L2-L2

Godot's own UI architecture supports the opposite direction: `Control` plus `Container` composition, Theme resources, explicit focus neighbors, `grab_focus()`, localization-aware layout direction, and accessibility metadata. Godot specifically warns that automatic focus guessing can become unreliable in complex interfaces and recommends explicit navigation where necessary. citeturn23view0turn24view0turn24view1

## Strategic direction and immediate milestone

**1. Executive UX Recommendation**

The interface should operate through four simultaneous levels of information.

| Level | Purpose in 12 Moons | Typical content |
|---|---|---|
| **Object layer** | What the player is physically acting on now | hand, field, draw pile, captures, modifier offer, carry slot |
| **Persistent strategic layer** | Facts that could change the current decision | turn, Moon/rule, scores, relevant yaku progress, bankroll when economically relevant, active modifiers |
| **Contextual inspection layer** | Details useful when investigating something | card month/class, modifier full text, exact yaku requirements, upgrade effect |
| **Reference layer** | Complete knowledge that should remain available but not occupy normal play | all yaku, terminology help, Moon-rule explanation, full modifier glossary |

This is a practical application of recognition rather than recall: a player should not have to remember the current build, opponent's captured yaku pieces, Moon rule, or available money while choosing whether to continue, purchase, replace, or equip something. Nintendo's own digital Koi-Koi presentation permits players to check yaku during play, and Nintendo's strategy guidance explicitly tells players to observe the opponent's captured cards when deciding what to deny. citeturn23view8

The information hierarchy should be:

**Cards > current choice > immediate strategic consequences > persistent run state > explanatory detail > decoration.**

That order matters. A decorative Moon emblem should never compete with a legal match. A modifier-family color should never be stronger than a selected hanafuda card. An animated shop ornament should never compete with a changed bankroll. A tutorial explanation should disappear once the player understands what is required.

The primary input grammar should be:

**focus/select → inspect if needed → choose target/destination → commit**

Mouse hover and drag-and-drop should be accelerators, not requirements. Microsoft accessibility guidance specifically warns against interfaces whose functionality depends on pointer or analog input and recommends digital alternatives; its UI-navigation guidance likewise emphasizes predictable focus and consistent select/back conventions. citeturn25view2turn23view7

The density philosophy should be **dense objects, sparse chrome**. Hanafuda requires many simultaneously visible physical pieces. That makes it especially important that borders, title bars, cards-within-cards, badges, decorative panels, and repeated labels remain restrained. The field should be visually rich because the hanafuda art is rich; the interface surrounding it should be disciplined.

The progressive-disclosure rule should be:

> **Always show state; reveal explanation on demand.**

For example, always show that a modifier is used, ready, disabled, active, or reserved; reveal the paragraph explaining why on focus. Always show that a yaku is one card from completion when that fact is strategically material; do not permanently display the complete rules for every yaku.

The accessibility baseline should be designed into the components rather than patched onto settings later. Godot's `Control` now exposes accessibility names/descriptions and focus relationships directly, and Microsoft's guidance stresses keyboard-only operation, visible focus, readable text, and redundant state communication. citeturn23view0turn24view5turn25view1

**Immediate repository implications**

Four changes should be treated as architectural prerequisites before the between-month UI multiplies:

1. **Stop creating new major layouts primarily through absolute `position`/`size` values.** The current result and gameplay scripts contain extensive fixed coordinates; that is workable for a prototype but hostile to localization, UI scaling, ultrawide, and iterative hierarchy changes. fileciteturn9file0L2-L2 fileciteturn14file0L2-L2
2. **Remove `FOCUS_NONE` as the interaction policy for playable cards.** `MoonCardView` already extends `Button`, so retaining focusability is much cheaper than redesigning every card interaction later. fileciteturn8file0L2-L2
3. **Create one project Theme and semantic component variants.** Godot Theme resources are designed to centralize colors, fonts, constants, icons, StyleBoxes, and focus overlays; local overrides should become exceptions. citeturn24view1
4. **Raise dense strategic text out of the 9–10 px range.** The current score panel renders category counts at 10 px and yaku names at 9 px. Microsoft's PC accessibility criteria use 18 rendered pixels at 1080p as a default minimum and require support for substantial scaling; at 1280×720, a practical 12 Moons baseline should be approximately **14–16 px for meaningful UI text**, with 12 px reserved for truly secondary metadata. The exact rendered-pixel measurement should be tested rather than inferred solely from Godot's font-size property. fileciteturn14file0L2-L2 citeturn25view0turn25view1

**2. Immediate Between-Month UX**

Three flow models are viable.

| Model | Structure | Strengths | Weaknesses | Verdict |
|---|---|---|---|---|
| **Shared preparation table** | One between-month scene; settlement, reward, carry, and shop occupy changing regions around a persistent carry tray and bankroll | Maximum continuity; preserves comparisons; strongly physical; few scene changes | Requires deliberate layout shell and state machine | **Recommended** |
| **Guided phase rail** | One scene with explicit Settlement → Reward → Carry → Shop → Finalize progression; center content swaps | Very clear orientation; easiest controller topology; straightforward implementation | Can feel slightly more menu-like | Excellent fallback / combine with first model |
| **Separate screens with persistent header** | Distinct reward/carry/shop scenes sharing top bar | Simplest local screen logic | Highest context loss; repeated transitions; encourages divergent visual components | Do not use unless engineering constraints force it |

The best answer is a hybrid of the first two: **one shared preparation table plus a restrained phase rail**.

The visual state should evolve like this:

```text
January table
     ↓
Settlement sheet appears over/alongside table
     ↓
Carry tray enters / newly earned slot visibly opens
     ↓
Reward offers are placed above that tray
     ↓
Chosen reward physically transfers to carry/reserve
     ↓
Same offer region becomes the shop
Carry + bankroll remain fixed
     ↓
Finalize state summarizes prepared build
     ↓
Table clears / February Moon banner enters
```

The phase rail should communicate orientation, not act like a tab bar:

`Settlement › Reward › Prepare › Shop › February`

Past phases may become quiet completed marks. Future phases should not look clickable unless backtracking is actually allowed.

**Settlement**

Settlement should be the transformation of the current January result, not a completely new app screen. The player's existing captured/scoring context should resolve into the settlement sheet. The current result screen already exposes yaku, additive score, Wolf Moon bonus, multipliers, and final score; those values should become a traceable scoring ledger rather than disappear before the economy begins. fileciteturn9file0L2-L2

Recommended order:

`Yaku → Moon adjustment → Koi-Koi/multiplier → final hand value → economic/run result → bankroll`

Animate or reveal the arithmetic in one direction. Do not simultaneously animate every row.

**Slot unlock**

Yes: **reveal the newly unlocked slot before reward selection**.

That creates a causal chain:

> January success → increased capacity → something can now occupy that capacity.

The active tray should already imply all eight eventual slots. Locked slots remain visibly present but physically closed, marked, or unavailable. When one unlocks, the player understands that run progression increases *capacity*, not just abstract level.

Do not award a reward and only afterward explain that it has nowhere to go.

**Reward**

After slot unlock, offers arrive in the same preparation space. The carry tray remains visible. Bankroll remains visible even though the reward is free because the refusal-for-cash option makes money relevant to the choice.

Selecting an offer should preview its destination or effect before commitment. Once accepted, the actual modifier object moves into the carry system. That movement teaches ownership more effectively than a toast saying “Added to inventory.”

**Carry**

Carry management should be an embedded preparation phase, not a disconnected “inventory menu.” At minimum, active slots and reserve should be simultaneously visible.

The game should only force the player into replacement mode when a choice requires replacement. An empty active slot should make equipping trivial.

**Shop**

The shop should replace the reward-offer region rather than replace the entire screen. The carry tray, active/reserve distinction, bankroll, and phase position remain anchored.

This solves one of the most common strategic-shop UX problems: making players mentally shuttle between “What is for sale?” and “What do I already have?”

**Finalize**

The final state should not say generic `Continue`.

Use:

**Begin February**

Immediately above or adjacent, summarize:

`Active 5/5` or current unlocked capacity, reserve count, remaining bankroll, and February/Moon rule if known.

If the player's build contains no unresolved invalid state, one press should finalize. Do not add a second “Are you sure?” dialog merely because it is the end of a phase. Confirmation is justified when there is an actual destructive or unresolved consequence, not as ritual.

**Now versus later**

Build now:

- shared between-month shell;
- phase rail;
- settlement ledger;
- persistent currency display;
- eight-slot visual carry tray with locked/unlocked states;
- modifier offer component;
- reserve region;
- selection-based swap;
- six-offer shop;
- reroll;
- sell;
- final summary;
- keyboard focus infrastructure;
- helper/tooltip infrastructure;
- semantic Theme.

Do not build now:

- elaborate shopkeepers;
- collection encyclopedia;
- advanced modifier filtering;
- touch-specific re-layout;
- animated 3D card binder;
- multiple shop categories/tabs;
- deep run-history UI;
- every eventual Moon-specific ornament.

Those systems would increase surface area before the interaction grammar is proven.

## Gameplay information and decision interfaces

**3. Full Information Architecture**

The controlling test is simple:

> **Could hiding this fact plausibly change the player's decision right now?**

If yes, it cannot be buried behind a screen transition.

| Information | Normal state | During relevant decision | Inspection/reference |
|---|---|---|---|
| Player hand | Persistent | Persistent | Card focus expands identity |
| Shared field | Persistent | Persistent | Card focus |
| Draw pile | Persistent object + remaining count | Persistent where draw risk matters | No separate screen |
| Player captures | Persistent, compact grouped layout | Persistent | Expandable yaku relation |
| Opponent captures | Persistent, compact grouped layout | **Must remain accessible during Koi-Koi** | Expandable |
| Turn | Persistent but visually quiet outside transition | Persistent | None |
| Current Moon | Persistent | Persistent | Moon rule detail |
| Moon rule | One-line compact state | Full wording available | Detail panel |
| Bankroll | Small persistent run anchor | Prominent in reward/shop/finalize; only moderate in match unless match rules affect it | Economy detail |
| Active modifiers | Compact persistent strip/tray or icon row | Full build visible when modifier decision occurs | Detail panel |
| Reserve | Hidden during ordinary match | Visible during build/shop | Carry screen/phase |
| Own yaku | Compact persistent progress | Expanded for Koi-Koi | Full yaku reference |
| Opponent yaku/threat | Compact strategically relevant progress | Expanded for Koi-Koi | Full reference |
| Card upgrade state | Small visual mark on card | Visible whenever card is a choice | Focus detail |
| Modifier full rules | Not constantly printed | Contextual compare | Focus/detail |
| Shop prices | Shop only | Always visible | No tooltip needed for base price |
| Reroll escalation | Shop only | Current cost + next known cost | Rules tooltip if formula complex |

**Persistent** should not mean “full-sized.” Persistence is about availability and location, not equal visual weight.

**Hover/focus** is appropriate for names, taxonomy, rule prose, card upgrades, modifier details, and exact yaku requirements.

**Detail panels** should contain compound information that benefits from comparison: modifier text, yaku composition, Moon rules, upgrade details.

**Modals** should be rare. Appropriate uses include destructive sale confirmation under unusually consequential conditions, an unavoidable conflict that requires a binary resolution, and settings. Ordinary Stop/Koi-Koi, reward choice, purchase, and carry swapping should not require screen-obscuring modal dialogs.

**Dedicated screens** are justified for title, settings/accessibility, perhaps run history, and later a full rules/glossary reference. Reward, carry, and shop are better understood as **phases of the preparation table**, not destinations in a menu hierarchy.

**4. Gameplay Screen Hierarchy**

Normal hanafuda play should be organized roughly as:

```text
[ Moon / rule ]        [ Turn / phase ]        [ Bankroll / run state ]

                     OPPONENT HAND

             OPPONENT CAPTURED CARDS
                + compact yaku state

                         FIELD

                   DRAW / RESOLUTION

                PLAYER CAPTURED CARDS
                + compact yaku state

                     PLAYER HAND

         [ active modifier summary / inspect affordance ]
```

The existing game already uses recognizable regions for opponent hand, captures, field, draw/resolution, player captures, player hand, and score. The valuable part is that spatial model; the weak part is the amount of tiny text and panel chrome currently used to describe it. fileciteturn11file0L2-L2

Do **not** show all eight future carry slots, reserve contents, full modifier descriptions, complete yaku catalog, Moon lore, and economy arithmetic simultaneously during card play.

Instead:

- active modifiers occupy one compact edge region;
- reserve disappears during play;
- bankroll becomes small unless directly actionable;
- own/opponent scoring summaries remain visible;
- the Moon rule is one sentence or one compact icon+phrase;
- full details are one focus/click away.

Captured-card grouping by Bright / Seed / Ribbon / Chaff is a strong idea because it chunks unfamiliar cards by functional class; the current prototype already groups captures by class. Retain that organization, but stop abbreviating those classes to `B`, `A`, `R`, `C` as the primary novice-facing label. fileciteturn14file0L2-L2

**5. Hanafuda Readability System**

Nintendo describes the standard hanafuda deck as 48 cards arranged into 12 months of four cards each, and Koi-Koi fundamentally matches cards by month. That makes **month recognition the first literacy problem** and card class/yaku relationships the second. citeturn23view8turn23view9

The card's traditional illustration must remain the dominant identity.

Do not redesign hanafuda into conventional Western CCG cards with:

- title bars;
- rules boxes;
- rarity banners;
- giant class icons;
- numerical corners occupying the artwork.

Use a layered assistance system instead.

**Default first-run helper mode**

On first run, enable assistance.

A hanafuda card may gain a **small, standardized outer-corner month marker**. Prefer an external corner tab/notch or numeral in the frame rather than text printed over the original image.

On focus/hover, a nearby inspect line can say:

`January · Pine · Bright`

or:

`June · Peony · Tane (Seed) · Ino-Shika-Cho`

This lets the player learn the original art rather than replacing recognition with labels.

An optional `Card helpers` setting can support:

- **Full:** month marker + class marker + focus labels;
- **Minimal:** month marker + focus labels;
- **Traditional:** artwork only until focused.

Avoid automatically turning helpers off based on inferred expertise. The player should control assistance.

**Legal matches**

After the player selects a card:

- selected card: unmistakable heavy selection frame and modest elevation;
- legal targets: crisp outer outline plus slight physical lift;
- pointer/focus target: stronger focus frame;
- illegal cards: remain readable and largely unchanged.

Do **not** solve legal targeting by dimming 90% of the board into near-invisibility. Illegal cards are still strategically meaningful.

Do not use constant pulsing. One brief pulse at the start of a required choice is enough; persistent outline carries the state thereafter.

The current prototype already highlights pending legal field matches; evolve this into a redundant visual state rather than changing interaction logic unnecessarily. fileciteturn14file0L2-L2

**Current-month recognition**

Current-month relevance should use a **peripheral state marker**, not an effect laid over the image:

- thin outer edge treatment;
- small Moon glyph;
- corner cut/notch;
- table-side indicator referencing matching cards.

Do not make all current-month cards glow continuously. Glow should be reserved for transient attention, not a permanent taxonomy.

**Card upgrades**

Every upgraded hanafuda card should still be instantly identifiable as its original physical card.

Use two signals:

1. a consistent **upgrade seal** in one fixed corner or frame position;
2. a modest material/frame treatment.

Focus reveals the actual effect.

Never stack a current-month badge, class badge, family badge, upgrade badge, “new” badge, ready badge, and selected badge in six different corners. State priority should be:

**card identity → selected/legal state → upgrade state → current-month strategic state → explanatory detail.**

The ownership of an upgrade belongs to the carry/modifier system; it does not need a second full modifier card attached visually to the hanafuda surface.

**6. Yaku Communication**

Nintendo's digital Koi-Koi teaching explicitly keeps yaku consultable during play, and its strategy guidance emphasizes evaluating the opponent's developing combinations. citeturn23view8

That argues against both extremes:

- hiding yaku in a separate encyclopedia; and
- permanently displaying every yaku as a checklist.

Use a **two-level yaku system**.

**Persistent yaku summary**

For each player:

- completed yaku: name + current points;
- class accumulation: `Tane 4/5`, `Tanzaku 3/5`, `Kasu 7/10`;
- only strategically relevant named combinations that are near completion.

For a named combination such as Ino-Shika-Cho, use recognizable miniature card pieces:

`Ino-Shika-Cho  [Boar] [Deer] [—Butterfly—]  2/3`

The missing card can remain an outlined silhouette/miniature, not a paragraph.

This builds visual memory of the actual hanafuda.

**Expanded yaku reference**

A single inspect action opens a non-destructive side sheet containing:

- yaku name;
- English explanation;
- component card miniatures;
- scoring condition;
- current ownership;
- opponent ownership if public information permits;
- status: complete / possible / blocked only when objectively knowable.

Do not attempt to predict “73% chance” or “likely to complete” unless the underlying game explicitly computes valid probabilities. A strategy interface should not manufacture certainty.

**Completion feedback**

When a yaku completes:

1. briefly elevate the relevant captured cards;
2. present yaku name + point change;
3. settle it into the persistent yaku summary.

For multiple yaku completing together, show one consolidated scoring event instead of three overlapping banners.

**7. Stop / Koi-Koi UX**

The current implementation creates an 82%-darkened full-screen overlay with a 640×390 centered panel. It shows the player's current yaku and general explanation, but it visually suppresses the table and opponent state at the exact moment Nintendo's own teaching says the opponent's captured cards matter to the risk decision. fileciteturn14file0L2-L2 citeturn23view9

Replace it with a **decision tray**, not a conventional modal.

The table should pause, but remain readable.

Recommended layout:

```text
TABLE / CAPTURES REMAIN VISIBLE

┌──────────────────────────────────────────────────────┐
│ YAKU COMPLETE                           Current: 6   │
│ Akatan +5 · Kasu +1                                  │
│                                                      │
│ Opponent: Tane 4/5 · Ino-Shika-Cho 2/3              │
│                                                      │
│ [ STOP — score/bank 6 ]   [ KOI-KOI — continue ]     │
│                                                      │
│ Koi-Koi: you keep playing for more. If the opponent  │
│ completes and ends the hand first, this hand may     │
│ score 0 for you.                                     │
└──────────────────────────────────────────────────────┘
```

Nintendo explains the central risk directly: after calling Koi-Koi, if the opponent completes a yaku first and ends the game, the caller can receive no points from that hand. 12 Moons should state its own exact rule consequences just as concretely. citeturn23view9

The interface should show only **known consequences**:

- score/value if Stop is chosen now;
- current Koi-Koi multiplier state;
- whether Koi-Koi has already been declared;
- economic outcome if precisely defined;
- own yaku progression;
- relevant opponent threats.

It should not say:

`Koi-Koi: High Risk`

unless “high” has a defined meaning.

It should say what makes the risk exist.

For controller/keyboard, the tray receives focus immediately. `Stop` may be the initial focus because it is the deterministic current-value choice, but both actions should be visually symmetric enough that Koi-Koi does not look like a hidden secondary option. Godot requires explicitly focusing a control for keyboard/controller navigation to function reliably when a scene or decision surface begins. citeturn24view0

One press commits the choice. No `KOI-KOI` → `Are you sure?` second modal.

**8. Reward UX**

Modifier offers should **not imitate hanafuda cards**.

This distinction is essential to visual literacy:

- hanafuda card = physical playing piece with immutable traditional identity;
- modifier = owned run rule/effect.

Give modifiers a different physical metaphor: a narrow seal, talisman, ticket, wooden plaque, folded slip, or another authored object family. The final art direction can decide material, but the silhouette should be visibly different even in grayscale.

A normal offer needs only:

```text
[ family mark ]  NAME

One concise mechanical sentence.

Optional requirement / target

FREE
```

The family indicator should combine:

- shape/icon;
- family name or abbreviated text on inspection;
- border/pattern variation;
- color as a secondary cue.

For the three families:

| Family | Structural cue |
|---|---|
| Card Upgrades | card/seal icon + notched/marked frame |
| Hand/Mechanic | hand/motion icon + second border grammar |
| Strategic/Meta | Moon/ledger/strategy icon + third pattern/frame grammar |

Do not make “red, blue, purple” the only distinction.

**Card-specific upgrades**

If an offer is already bound to one hanafuda card, include a small thumbnail and canonical card name/month.

If the modifier lets the player choose a target:

1. select upgrade offer;
2. enter `Choose a card` mode;
3. show actual hanafuda cards or a compact 48-card reference;
4. valid targets receive the same legal-target grammar used in gameplay;
5. focus shows resulting card state before confirmation.

The player should never have to remember a card ID or infer a target from prose.

**Comparison**

Focusing an offer should update a stable compare panel:

`New` versus `currently selected/equipped comparable modifier`.

If accepting the reward would require replacement, show:

`Replace [Modifier Name]`

before commitment.

Never erase the carry build behind the reward card.

**Refusal for cash**

Use explicit mechanical copy:

`Take ¥5 instead`

or the game's final currency notation.

It should be a visible alternative at the same decision level, though visually secondary to the reward offers. Do not hide it under `Skip` and only reveal the cash in a tooltip.

**Dead or inaccessible rewards**

The best policy is to avoid generating offers that are mechanically impossible where feasible.

When an inaccessible option does exist:

- show it;
- disable acquisition;
- state the reason directly.

Example:

`No eligible cards`

not:

`Unavailable`.

Hiding offers makes the player question whether the game generated fewer choices or whether something disappeared.

**9. Carry-Build UX**

The carry build should be one of the game's strongest recurring visual identities.

Show all eight eventual active slots from the beginning:

```text
ACTIVE
[1][2][3][4][5][6][7][8]
 ✓  ✓  ✓  🔒 🔒 🔒 🔒 🔒

RESERVE
[ modifier ][ modifier ][ empty ]
```

The exact number initially unlocked is a prototype/game-balance value, but the eight-slot eventual structure should be spatially legible.

The primary interaction should be **click-select-click** / **focus-select-destination**, with drag-and-drop supported only as a shortcut.

| Pattern | Mouse | Controller | Accessibility | Error risk | Complexity | Recommendation |
|---|---:|---:|---:|---:|---:|---|
| Click → destination | Excellent | Excellent | Excellent | Low | Low–moderate | **Primary** |
| Direct slot swap | Excellent | Excellent | Excellent | Low | Low | **Primary operation** |
| Drag/drop | Excellent for experts | Poor without parallel model | Moderate/poor alone | Moderate | Moderate | Optional shortcut |
| Context menu | Moderate | Moderate | Moderate | Low | Moderate | Use sparingly |
| Radial menu | Unnecessary | Moderate | Moderate | Moderate | High | Avoid |
| Right-click actions | Fast | Poor | Poor alone | Moderate | Low | Never required |

Microsoft's input guidance explicitly says functionality should remain available through single digital input even when pointer/analog interaction is the primary method. citeturn25view2

The internal command should therefore be something like:

`move_modifier(source_slot, destination_slot)`

Drag, mouse clicks, keyboard, and controller should all invoke that same command.

**Active versus reserve**

Do not differentiate them by opacity alone.

Use redundant structure:

| State | Placement | Form | Symbol/text | Motion |
|---|---|---|---|---|
| Active | dedicated active tray | strong open socket | active indicator on inspect | normal |
| Reserve | separate named region | storage pocket/shelf | `Reserve` region label | quieter |
| Locked | active position still visible | closed/blocked slot | lock glyph | none |
| Empty/unlocked | active tray | receptive/open socket | `Empty` on focus | subtle response |
| Selected | unchanged placement | heavy focus/selection frame | optional prompt | small lift |
| Recently acquired | destination remains normal | brief arrival seal | `New` transiently | short entry |
| Disabled | normal position | barred state | reason on focus | no pulsing |
| Ready | active position | readiness mark | `Ready` on focus | quiet |
| Used this month | active position | stamp/check/notch | `Used` | static |

Reserve should look like **storage**, not like “active cards drawn 50% transparent.”

Selling should be an explicit action from the selected modifier. Do not make dragging out of the tray mean “sell”; that is too easy to trigger accidentally and has weak controller equivalence.

**10. Shop UX**

Use a **3×2 offer grid** at 1280×720. It gives each of six offers enough width for a concise rule sentence while maintaining predictable D-pad navigation.

Recommended shell:

```text
┌ Bankroll ────────────────────── February preparation ┐
│                                                     │
│ SHOP                       INSPECT / COMPARE         │
│ [offer] [offer] [offer]    selected effect          │
│ [offer] [offer] [offer]    current modifier         │
│                                                     │
│ Reroll ¥3 · Next ¥5                                 │
│                                                     │
│ ACTIVE [ ][ ][ ][ ][ ][ ][ ][ ]                     │
│ RESERVE [ ][ ][ ]                                   │
│                                    [Begin February] │
└─────────────────────────────────────────────────────┘
```

This also maps naturally to controller focus. Microsoft's UI navigation guidance specifically uses marketplace grids as an example where directional navigation should move to the spatially adjacent tile, not follow surprising focus order. citeturn23view7

**Purchase rule**

If reserve has room:

> Purchase → reserve by default → optional `Equip` action.

Do not ask the player to choose a destination before **every** purchase. That adds unnecessary friction.

If an active slot is empty, after purchase the item can offer:

`Equip now`

but should still have a deterministic safe destination.

If active slots are full but reserve has capacity, purchase succeeds to reserve.

If both active and reserve capacity are full, selecting `Buy` should enter explicit replacement/sell resolution **before money is deducted**.

**Affordability**

Unaffordable items remain visible.

State:

`¥8 — Need ¥3 more`

Purchase action disabled.

This is better information architecture than hiding objects the player cannot afford because price comparison itself is strategic information.

**Sold items**

Keep the spatial tile.

Mark:

`SOLD`

Do not collapse five offers into a differently spaced grid after one purchase; stable geometry improves scanning and focus predictability.

**Reroll**

Show:

`Reroll — ¥3`

If escalation is deterministic and known:

`Next reroll ¥5`

The player should not have to discover rising cost after committing the first reroll.

If exhausted:

`No rerolls remaining`

not an unexplained dead button.

**Sale**

Selecting an owned modifier reveals:

`Sell for ¥4`

If sale is ordinary and reversible only through economy, one clear commit can be enough. If a unique/permanent upgrade is destroyed or another unusually consequential state is lost, a confirmation is justified. Error-prevention guidance is strongest when an action is destructive; confirmation dialogs should not be mechanically attached to every routine action. citeturn24view5

**Error-state rule**

Use four categories:

- **Prevent** when an action is never valid.
- **Disable + explain** when the player can understand a missing requirement.
- **Warn before commit** when the action is legal but destructive.
- **Allow + show correction path** when experimentation is safe.

Never silently reject.

## Input, accessibility, learning, and language

**11. Input Model**

Design for mouse first operationally, but design the **interaction architecture** for discrete focus from day one.

The current `MoonCardView` already inherits from `Button`, which is advantageous, but explicitly disables focus. Godot buttons normally support focus, while `FOCUS_NONE` makes the control inaccessible to keyboard/controller focus navigation. fileciteturn8file0L2-L2 citeturn24view0

Recommended action vocabulary:

```text
Navigate
Select / Confirm
Cancel / Back
Inspect
Secondary action
Page left / right   [only where genuinely useful]
```

Gameplay actions should be semantically named:

```text
card_select
target_select
inspect
cancel
confirm
```

Do not bind game mechanics directly to Godot's `ui_up`, `ui_down`, etc.; Godot documentation explicitly says those built-in actions are used for focus and should not be reused as gameplay actions. citeturn24view0

**Mouse**

Primary:
- click select;
- click destination;
- hover mirrors focus inspection;
- wheel only where scroll exists.

Optional:
- drag modifier between carry slots;
- drag card only if it never becomes necessary for normal play.

**Keyboard**

- arrows/WASD according to mapping for spatial choice;
- Enter/Space confirm;
- Esc cancel;
- dedicated inspect key;
- Tab may cycle logical regions where appropriate.

The full game should be operable without mouse-dependent hover. Microsoft's PC accessibility criteria explicitly call for complete keyboard operation and remappable gameplay actions. citeturn25view1

**Controller**

Use D-pad as canonical menu navigation. Analog stick can mirror it, but spatial UI should not require precise cursor simulation.

Examples:

- hand: left/right;
- hand → field after selecting card: up;
- field: directional neighbor;
- offer grid: geometric 3×2 navigation;
- carry: horizontal active row, down to reserve;
- detail actions: explicit nearby actions, not tiny pointer targets.

Godot permits explicit `focus_neighbor_left/right/top/bottom`; use those for any screen where automatic geometric guessing can become ambiguous. citeturn23view0turn24view0

**Touch later**

The click-select architecture already gives future touch a clean mapping:

tap object → tap target.

Long press may later map to Inspect, but **nothing essential should depend on long press**.

That is much safer than building the game around hover + right-click + drag and later trying to translate those interactions.

**Controller-hostile patterns to ban now**

- hover-only mechanics;
- right-click-required actions;
- drag-and-drop as the only move mechanism;
- tiny freeform pointer targets;
- invisible focus;
- focus moving to elements under an overlay;
- changing A/Confirm semantics from screen to screen;
- context menus that cannot be reached without pointer positioning;
- reflowing grids without restoring focus deterministically after purchase/reroll.

Microsoft's focus guidance requires focus to remain visible and contained appropriately during overlays; its navigation guidance stresses consistent focus behavior and interaction mapping. citeturn24view5turn23view7

**12. Accessibility Baseline**

The goal is not to promise every accessibility feature at prototype stage. It is to avoid inexpensive architectural mistakes that later become expensive.

| Priority | Feature | Cost now | Why it belongs here |
|---|---|---:|---|
| **High-value / cheap** | Keyboard-operable all major UI | Low if designed now | Prevents pointer-only architecture |
| **High-value / cheap** | Visible focus outline + shape/weight cue | Low | Essential for controller/keyboard |
| **High-value / cheap** | Never encode state by color alone | Low | Helps color vision and general clarity |
| **High-value / cheap** | Focus/click equivalent for every hover tooltip | Low | Prevents hover dependency |
| **High-value / cheap** | Text baseline raised to readable sizes | Low now | Gets harder once layouts are crowded |
| **High-value / cheap** | Reduced-motion flag routed through presentation system | Low now | Existing motion layer makes centralized handling feasible |
| **High-value / cheap** | No essential audio-only cues | Low | Redundant visual feedback |
| **High-value / cheap** | No essential visual-only transient cues when a persistent state can show it | Low | Supports missed-event recovery |
| **High-value / cheap** | Logical accessible names/descriptions on reusable controls | Low–moderate | Godot supports metadata directly |
| **High-value / cheap** | Tooltip pin/persistence on focus | Low | Cognitive/readability benefit |
| **Moderate** | UI-scale choices | Moderate | Needs responsive layouts |
| **Moderate** | Full input-remapping screen | Moderate | Architecture should support now; UI may follow milestone |
| **Moderate** | High-contrast theme/setting | Moderate | Easier after semantic theme tokens exist |
| **Moderate** | Animation-speed setting | Moderate | Presentation queue can centralize timing |
| **Moderate** | Disabled-motion/flash alternatives | Moderate | Needed as VFX grows |
| **Future enhancement** | Full screen-reader QA/narrative descriptions | High | Needs dedicated test pass despite Godot metadata support |
| **Future enhancement** | Dedicated touch layout | High | No need for January–February milestone |
| **Future enhancement** | Multiple specialized reading/font presets | Moderate–high | Better after baseline typography stabilizes |

For text, Microsoft's current PC criteria call for a rendered minimum of 18 px at 1080p, important text contrast of at least 4.5:1, support for scaling text substantially, and full keyboard support. 12 Moons should not mechanically translate every external target into a Godot integer font size; it should screenshot and measure actual rendered text. The actionable project rule is nevertheless clear: **9–10 px strategic text should not survive into the polished UI.** citeturn25view0turn25view1

Focus should never be communicated by a subtle glow alone. Microsoft specifically calls out weak glow-based focus as difficult for low-vision and cognitively impaired players and recommends highly visible indicators such as borders plus other redundant changes. citeturn24view5

For colorblindness, modifier families and state should therefore use **icon + shape/pattern + text/placement**, with color only reinforcing them.

For reduced motion, preserve **meaning** when removing animation:

- card ends in same destination;
- yaku completion still has a stable label;
- purchase still changes bankroll visibly;
- slot unlock still changes the actual slot form;
- focus never depends on bouncing/pulsing.

For dyslexia-friendly considerations, prioritize the fundamentals before a specialty “dyslexia font”: readable sans-serif body option, adequate size, restrained uppercase, good line spacing, left alignment for explanatory prose, no text over busy card art, and persistent tooltips.

**13. Onboarding Strategy**

Do not create a tutorial chapter.

Teach **at the first decision that gives the concept meaning**.

Nintendo's own beginner teaching sequence naturally introduces Koi-Koi through hand play, matching by month, drawing, captured cards, yaku, and only then the Koi-Koi decision. citeturn23view9

Recommended first January run:

| Moment | Teach | UI behavior |
|---|---|---|
| January Moon intro | Moon identity + one rule | one short sentence; Inspect for full explanation |
| First player's turn | Cards match by month | highlight selectable hand, then legal field match |
| First successful match | Capture meaning | short label points to player's capture area |
| First unmatched card | Card stays on field | contextual one-line explanation |
| First two-match case | Player chooses target | highlight only legal alternatives |
| First draw | Draw resolves after hand play | visual choreography teaches sequence |
| First meaningful class accumulation | Tane/Tanzaku/Kasu concept | small yaku progress callout |
| First named-yaku opportunity | recognizable set | show component thumbnails |
| First yaku completion | Stop / Koi-Koi | decision tray explains actual current stakes |
| Settlement | points become run outcome/economy | trace arithmetic once |
| First carry unlock | limited active build | point to eight-slot tray and opened slot |
| First reward | modifier family + ownership | reward moves physically to build |
| First reserve use | active versus reserve | teach only when overflow or swap actually occurs |
| First shop | price, buy, reroll | teach each control when first focused |

A tutorial message should generally contain:

**one action + one reason.**

Bad:

> “Welcome to the exciting world of Hanafuda! In 12 Moons, cards correspond to each month and can be collected to form powerful scoring combinations called yaku…”

Better:

> **Match months.**  
> Your January Pine can capture a January card on the field.

Then let the interaction teach.

**Legal-move assistance**

Default legal assistance ON for new profiles.

Use:
- outline;
- slight lift;
- selection frame;
- optionally a single brief entry pulse.

Do not use:
- perpetual glow;
- arrows from every playable card;
- constant “BEST MOVE” indicators;
- dimming the entire board into irrelevance.

The assistance should identify what the rules permit, **not recommend strategy**.

Keep it re-enableable permanently. Never shame the player with an “expert mode” label.

**14. Typography System**

12 Moons needs two typographic voices at most:

- **interface/body voice:** highly readable sans-serif;
- **display/seasonal voice:** optional authored face for Moon banners, major yaku, or ceremonial transitions.

Do not use the display face for modifier paragraphs, prices, tooltips, or dense yaku summaries.

A 1280×720 prototype scale can begin approximately here:

| Role | Prototype target |
|---|---:|
| Exceptional Moon/result display | 32–40 |
| Major phase heading | 26–32 |
| Section / major yaku | 20–24 |
| Buttons / important values | 16–18 |
| Body / modifier effect | 14–16 |
| Secondary metadata | 12–14 |
| Below 12 | Avoid for meaningful information |

These are **prototype tokens**, not final accessibility certification measurements. Microsoft's guidance measures actual rendered pixel height, so visual QA must verify final fonts rather than assuming a Godot `font_size` maps one-to-one. citeturn25view0

Other rules:

- all-caps only for very short labels such as `STOP`, `ACTIVE`, `SOLD`;
- sentence case for explanations;
- left-align modifier descriptions and tooltips;
- use tabular numerals if available for prices/scores;
- do not center multiline rule prose;
- avoid ultra-light weights;
- tooltip body should usually stay around 45–70 Latin characters per line;
- yaku names may be typographically distinctive, but scoring data must remain more legible than ornamental.

**Japanese terminology**

Adopt **Japanese-first, English-supported** terminology.

First or explanatory usage:

- `Koi-Koi — Continue`
- `Kasu — Chaff`
- `Tanzaku — Ribbons`
- `Tane — Seeds`
- `Akatan — Red Poetry Ribbons`
- `Aotan — Blue Ribbons`
- `Ino-Shika-Cho — Boar, Deer, Butterfly`
- `Hanami-zake — Cherry-Blossom Viewing`
- `Tsukimi-zake — Moon Viewing`

Once a term is learned, compact UI can use the Japanese term, while focus/tooltip always preserves the English descriptor.

This avoids two bad extremes:

- replacing culturally specific terminology entirely with generic English; or
- assuming an English-speaking newcomer already knows nine Japanese game terms.

Choose one canonical English display vocabulary now. In particular, do not alternate unpredictably between `Animal`, `Seed`, and `Tane`. Internal code may retain `animal`; player-facing terminology should be consistent.

**15. Localization Resilience**

Cheap decisions now can prevent expensive redesign later.

Godot supports translation contexts, language-specific pluralization, pseudolocalization, resizable controls, container-based layout, and automatic bidirectional UI mirroring for many Control/Container arrangements. citeturn24view2

Therefore:

- use translation keys or translatable source strings from the beginning;
- use named/structured placeholders rather than sentence fragments assembled by concatenation;
- use pluralization functions for counts;
- let labels wrap;
- size buttons from content + padding rather than fixed text-width assumptions;
- support 30–50% text expansion during prototype testing;
- keep text out of rasterized art;
- avoid relying on `B / A / R / C` abbreviations to save width;
- reserve fallback font coverage for Japanese/CJK even in English builds;
- use logical `start/end` alignment where possible rather than conceptual “always left/right” assumptions;
- avoid positioning text with hard-coded x-coordinates;
- run Godot pseudolocalization before every major UI milestone.

Godot's pseudolocalization is specifically intended to reveal strings that cannot expand and fonts/layouts that fail under longer translated text. citeturn24view2

RTL does not need to become a launch scope commitment, but new architecture should not gratuitously prevent it.

## Visual system, components, and responsive architecture

**16. Lightweight Design System**

12 Moons needs a design system, but not a corporate UI specification.

The right level is:

> a small token file/Theme, a short semantic-state reference, and reusable scenes for high-frequency objects.

**Spacing**

Start with:

`4 / 8 / 12 / 16 / 24 / 32 / 48`

Use 4 for micro-spacing, 8–16 inside compact components, 24–32 between strategic groups, 48 for major phase separation.

Avoid numbers like 11, 17, 27, 31 unless geometry genuinely requires them.

**Type scale**

Start with semantic tokens rather than scattered per-node overrides:

`meta / body / action / section / phase / display`

**Corner system**

Use no more than two or three corner treatments.

More importantly: not everything needs rounded corners.

Physical trays, paper sheets, card sockets, seals, and table regions can use different silhouettes for semantic reasons. A generic `12px rounded rectangle` should not become the unit of the game.

**Borders**

Define:

- subtle divider;
- object border;
- interactive hover;
- selected;
- keyboard/controller focus;
- invalid;
- major result.

Selection and focus should remain distinguishable: mouse-selected is not necessarily the same concept as controller focus.

**Semantic UI roles**

The Theme should expose roles conceptually equivalent to:

```text
surface_table
surface_inset
surface_raised
surface_overlay

text_primary
text_secondary
text_muted

border_subtle
border_strong
border_focus

state_selectable
state_selected
state_invalid
state_disabled
state_warning

economy_gain
economy_loss

slot_active
slot_reserve
slot_locked

family_card_upgrade
family_hand_mechanic
family_strategic
```

The research does **not** support prematurely locking final hues. Establish semantic roles first; choose the final palette alongside art direction.

Godot Theme resources directly support centralized colors, constants, fonts, font sizes, icons, StyleBoxes, and type variations; that is a better fit than the current pattern of repeatedly calling `add_theme_*_override()` throughout screen code. citeturn24view1

**Panel hierarchy**

Use four levels:

1. **table surface** — the world;
2. **attached tray/sheet** — normal information;
3. **decision sheet** — temporary but context-preserving;
4. **blocking modal** — rare error/destructive/required resolution.

A normal UI element should not automatically receive a floating panel behind it.

**Modifier-family language**

Each family gets:

- one stable icon;
- one stable structural frame detail;
- optional texture/pattern;
- semantic color accent;
- explicit name on inspection.

That remains legible in grayscale.

**Feedback hierarchy**

Event spectacle should scale with consequence.

| Level | Examples | Treatment |
|---|---|---|
| Minor | hover, focus, normal selection | border, tiny movement, quiet sound |
| Moderate | purchase, modifier trigger, progress | object movement, one audio cue, counter response |
| Major | yaku completion, Koi-Koi, slot unlock, month completion | short pause, banner/reveal, stronger sound |
| Exceptional | huge score, December/run completion | reserved whole-table transformation |

The crucial rule is:

> **Frequency and spectacle should be inversely related.**

A modifier that triggers seven times per hand cannot use the same spectacle as December completion.

**17. Responsive Layout Strategy**

The repository currently targets Godot 4.7, 1280×720, `canvas_items`, with the Compatibility renderer. fileciteturn7file0L2-L2

Keep **1280×720 as the logical minimum design canvas** for the desktop prototype.

Do not create hand-authored layouts for 720p, 1080p, 1440p, and 4K.

Instead:

- `Control` anchors handle edge attachment;
- `Container`s handle flexible internal layout;
- card objects preserve aspect ratio;
- center gameplay gets a maximum practical width;
- excess ultrawide space becomes margin or an inspection rail rather than stretched cards.

Godot recommends `canvas_items` for scalable 2D content where high-resolution UI/text should remain rendered at destination resolution, and its multiple-resolution guidance pairs flexible Control anchors with aspect expansion. citeturn24view3

Do **not** immediately change the existing project's stretch-aspect behavior to `expand` while the gameplay table still relies heavily on absolute geometry. Containerize the major regions first, then test `expand`. Otherwise the engine setting may expose layout assumptions without actually solving them.

Recommended behavior:

**16:9 / 1280×720:** canonical composition.

**16:10:** preserve card dimensions, use extra vertical room for breathing space between captures/field/hand.

**1080p / 1440p / 4K:** same topology, scaled text and controls with crisp rendering; eventually expose UI scale.

**Ultrawide:** do not stretch hand/field across entire monitor. Cap central table composition and place optional inspect/reference space in the additional horizontal room.

**Windowed smaller than target:** maintain a supported minimum. Do not shrink text indefinitely to fit. If necessary, constrain the minimum window size for the prototype rather than building a cramped alternate interface.

**Shop/reward responsive logic**

At canonical 16:9:
- rewards: three across;
- shop: three columns × two rows.

Only reflow to a narrower arrangement if available width genuinely cannot maintain readable offers. Do not produce a different hierarchy at every breakpoint.

**18. Component Library**

High-value reusable components:

| Component | Reuse | Responsibility |
|---|---:|---|
| `HanafudaCardView` | Very high | art, month/class helper, focus, legal state, upgrade state |
| `ModifierCard` | Very high | modifier identity, family, effect summary, owned/offer states |
| `CarrySlot` | Very high | active/reserve/locked/empty/occupied state |
| `InspectPanel` | Very high | focus-driven details for cards/modifiers/yaku |
| `Tooltip` | Very high | concise focus/hover information; pin support |
| `CurrencyDisplay` | High | stable bankroll + animated deltas |
| `YakuSummary` | High | counters/completed/near-yaku |
| `OfferGrid` | High | reward/shop spatial selection |
| `PhaseShell` | High | preparation-table anchors and phase rail |
| `ActionButton` theme variants | High | primary/secondary/destructive/disabled/focus |
| `ComparePanel` | High | new versus owned effect |
| `MoonRuleDisplay` | Medium–high | compact rule + expanded state |
| `ConfirmationDialog` | Medium | rare destructive actions |
| `Toast/Notification` | Medium | nonblocking result/error |
| `MoonBanner` | Medium | transition ceremony |

Do not turn every line of text, spacer, icon, or decorative flourish into its own scene.

Create a component when at least one of these is true:

- it appears in multiple contexts;
- it owns meaningful interaction state;
- it must enforce consistent focus/accessibility behavior;
- it expresses a distinct semantic object;
- inconsistency would create player confusion.

Godot Theme/type variations should handle many purely visual variants without creating separate component classes. citeturn24view1

**Godot-specific implementation rules**

`Control` / `Container`: prefer Containers for ordinary layout. Godot itself describes flexible UIs as a mix of both. citeturn23view0

`focus_neighbors`: explicitly define them for hands, 3×2 shop grids, active/reserve trays, and dialogs. citeturn24view0

`grab_focus()`: after a phase transition, purchase, reroll, destroyed item, or opened dialog, deliberately restore focus. citeturn24view0

`mouse_filter`: decorative overlays/icons above buttons should use appropriate ignore/pass behavior so they do not unexpectedly steal pointer input. citeturn23view0

`tooltip_text` / custom tooltip: good for mouse, but every tooltip fact needs a focus/inspect path.

`RichTextLabel`: reserve for structured modifier/tooltips/reference copy where inline icons/emphasis actually help. Do not make ordinary labels rich text by default.

`layout_direction`: allow language direction to flow through Containers rather than hard-coding mirrored UI manually. citeturn24view2

`accessibility_name` / descriptions: populate on semantic reusable components so future accessibility work does not have to reverse-engineer every screen. Godot exposes these properties on `Control`. citeturn23view0

`custom drawing`: excellent for hanafuda borders, slot forms, and authored table markings; keep semantic state values centralized rather than embedding a new hard-coded color palette in each `_draw()`.

## Anti-slop and authored identity

The phrase “AI slop” does not have a formal game-UX standard. The useful way to operationalize it is to identify patterns that arise when interfaces are generated feature-by-feature without a coherent material metaphor, component grammar, hierarchy, or interaction model. The corrective principles below align with established accessibility and UI practices around consistency, explicit focus, semantic states, and minimal unnecessary UI surfaces. citeturn23view7turn24view1turn24view5

**19. Anti-AI-Slop Visual Checklist**

**Warning sign:** Every piece of information sits inside its own rounded rectangle.  
**Why it feels generic:** The interface reads like a web dashboard assembled from cards rather than a physical game space. Nothing establishes semantic grouping beyond repeated containers.  
**Better principle:** Use one dominant table surface and a small hierarchy of attached trays, sheets, slots, and decision surfaces. Group related information spatially before adding another panel.

**Warning sign:** Dark navy background plus blue/purple gradient accents becomes the default aesthetic.  
**Why it feels generic:** Trend vocabulary substitutes for an identity connected to hanafuda, seasonality, material, or gameplay.  
**Better principle:** Derive material and accent decisions from 12 Moons' physical-card and seasonal identity. Semantic colors should indicate meaning, not advertise “premium UI.”

**Warning sign:** Everything interactive glows.  
**Why it feels generic:** Glow no longer indicates priority; selected, hovered, rare, purchasable, upgraded, and newly acquired objects collapse into one visual state.  
**Better principle:** Use stable outlines, shape, position, and material for persistent states. Reserve glow/illumination for brief attention events.

**Warning sign:** Modifier cards, hanafuda cards, shop items, and reward offers all share the same card rectangle.  
**Why it feels generic:** Asset reuse erases the conceptual difference between the core deck and roguelike rule objects.  
**Better principle:** Hanafuda should have one sacred physical identity. Modifiers should use a distinct silhouette/material vocabulary.

**Warning sign:** Every panel has a different corner radius, shadow, stroke, and tint.  
**Why it feels generic:** It reveals feature-by-feature construction rather than a system.  
**Better principle:** Define two or three radius treatments, border weights, and elevation levels and reuse them semantically.

**Warning sign:** Large decorative headings consume the top quarter of every screen.  
**Why it feels generic:** Hierarchy is created by scale instead of information importance, especially wasteful at 720p.  
**Better principle:** Name a phase once. Give the scarce visual area to cards, decisions, and consequences.

**Warning sign:** Every system has a badge.  
**Why it feels generic:** Badges become visual confetti rather than meaningful state.  
**Better principle:** Create a badge/seal only for a stable taxonomy or recurring state that cannot be communicated by placement or shape.

**Warning sign:** Particles, drifting motes, shine sweeps, and idle animation appear behind routine menus.  
**Why it feels generic:** Motion exists without state change.  
**Better principle:** Motion should explain movement, ownership, causality, or event importance.

**Warning sign:** Mechanical paragraphs are centered.  
**Why it feels generic:** It prioritizes compositional symmetry over fast scanning.  
**Better principle:** Center short ceremony text; left-align instructions, modifier effects, prices, comparisons, and tooltips.

**Warning sign:** Offer cards are enormous but mostly empty.  
**Why it feels generic:** Content density is dictated by a component template rather than the decision.  
**Better principle:** Size an offer for the information it must compare: name, family, effect, requirement, price.

**Warning sign:** Icon style changes with every feature.  
**Why it feels generic:** Visual vocabulary looks sourced from unrelated asset packs/generations.  
**Better principle:** Establish one icon grammar: stroke/fill style, corner behavior, optical weight, and standard sizes.

**Warning sign:** Persistent current-month, upgrade, legal, focus, rarity, family, and “new” states all use corner stickers.  
**Why it feels generic:** State systems accumulate without prioritization.  
**Better principle:** Assign different channels: placement for ownership, frame for state, seal for upgrades, icon for taxonomy, motion only for transient events.

**20. Anti-AI-Slop Interaction Checklist**

**Warning sign:** Every transition opens a modal.  
**Why it feels generic:** Dialogs are used as an implementation shortcut instead of maintaining spatial context.  
**Better principle:** Change the state of the shared preparation/table scene. Block the whole interface only when the player must resolve a truly blocking issue.

**Warning sign:** Important information exists only on hover.  
**Why it feels generic:** The UI was designed around a mouse screenshot rather than an input system.  
**Better principle:** Hover and keyboard/controller focus must produce equivalent inspection. Click/Inspect must allow persistent reading. citeturn25view2turn24view0

**Warning sign:** Dragging is the only way to equip or rearrange.  
**Why it feels generic:** Drag looks tactile in demos but creates ambiguity around destinations and excludes digital navigation.  
**Better principle:** Selection and explicit destination form the canonical action; drag calls the same command as an optional shortcut. citeturn25view2

**Warning sign:** Every purchase asks “Are you sure?”  
**Why it feels generic:** Confirmation substitutes for good preview and creates learned dismissal.  
**Better principle:** Show effect, price, destination, and consequence before commitment. Confirm only unusual destructive actions.

**Warning sign:** Reward, inventory, shop, reserve, and upgrade are five tabs.  
**Why it feels generic:** Features have been mapped one-to-one to navigation instead of the player's task.  
**Better principle:** Organize by decision flow. Reward → prepare → shop belongs in one preparation environment.

**Warning sign:** Buttons appear for actions that could be direct.  
**Why it feels generic:** “Select item → click Equip → choose slot → click Confirm” creates ceremony around trivial operations.  
**Better principle:** Selecting an owned modifier and an empty valid slot should be enough to move it.

**Warning sign:** Invalid actions silently do nothing.  
**Why it feels generic:** Implementation constraints leak as dead controls.  
**Better principle:** Disabled states state their missing condition; legal-but-failed actions explain recovery.

**Warning sign:** Focus jumps to the first item after every shop mutation.  
**Why it feels generic:** Pointer use was assumed and digital navigation added later.  
**Better principle:** Every state mutation has a defined focus destination: purchased tile → acquired modifier or nearest surviving offer; reroll → first new offer; sold modifier → nearest owned modifier.

**Warning sign:** The meaning of Confirm/Back changes unpredictably.  
**Why it feels generic:** Each feature invented its own input behavior.  
**Better principle:** One input grammar across match, rewards, carry, and shop. Microsoft's accessibility guidance explicitly emphasizes consistent UI interaction and predictable focus. citeturn23view7

**Warning sign:** A purchase succeeds but only the money number changes.  
**Why it feels generic:** Feedback happens far from the object/action.  
**Better principle:** Show state change both locally and globally: offer becomes sold, modifier travels to reserve, bankroll decrements.

**21. Anti-AI-Slop Copy Checklist**

**Warning sign:** `Manage Your Modifiers — Carefully curate your powerful collection to prepare for the challenges ahead.`  
**Why it feels generic:** It explains the existence of a screen rather than a rule.  
**Better principle:** `Carry` / `5 active · 2 reserve`.

**Warning sign:** `Embark on the next step of your lunar journey.`  
**Why it feels generic:** Vague thematic language replaces an action.  
**Better principle:** `Begin February`.

**Warning sign:** `Insufficient funds.`  
**Why it feels generic:** It reports failure without recovery information.  
**Better principle:** `Need ¥3 more.`

**Warning sign:** `This action cannot currently be performed.`  
**Why it feels generic:** The player must infer the rule.  
**Better principle:** `Reserve full — sell or replace a modifier.`

**Warning sign:** Modifier prose begins with lore or adjectives.  
**Why it feels generic:** The mechanical effect becomes harder to compare.  
**Better principle:** Lead with verb and consequence: `Your first Ribbon capture each month earns ¥2.`

**Warning sign:** Every button says `Confirm`, `Continue`, or `Select`.  
**Why it feels generic:** The action lacks semantic identity.  
**Better principle:** `Take`, `Equip`, `Sell for ¥4`, `Stop`, `Koi-Koi`, `Reroll ¥3`, `Begin February`.

**Warning sign:** The same concept receives multiple names.  
**Why it feels generic:** Copy was generated locally per feature instead of from a controlled vocabulary.  
**Better principle:** Maintain canonical terms for Tane/Seed, reserve, active, Moon, modifier, carry, reroll, reward.

**Warning sign:** Tutorial popups contain two or three paragraphs.  
**Why it feels generic:** The system anticipates every question instead of teaching the immediate action.  
**Better principle:** One action, one reason, one dismiss/perform path.

**Warning sign:** Every modifier gets flavor text during the milestone.  
**Why it feels generic:** Asset quantity is mistaken for authorship and mechanical comparison becomes harder.  
**Better principle:** Mechanical description first. Optional flavor can be added later to inspection where it supports actual world identity.

**Warning sign:** Confirmation copy repeats the button.  
**Why it feels generic:** `Are you sure you want to buy this item?` adds no information.  
**Better principle:** Confirmation text should state the irreversible consequence or not exist.

**22. Authored Visual Identity Principles**

The entire game can feel authored with surprisingly few immutable rules.

**Hanafuda art is inviolable.**  
Original card identity remains visible. UI decorates the perimeter; it does not turn traditional hanafuda into generic stat cards.

**The game has one table.**  
Match, settlement, reward, carry, and shop should feel like successive states of the same world, even if they are technically different Godot scenes.

**Season changes; interface grammar does not.**  
January and February may alter Moon motifs, ornament, surface detail, and transition art. Buttons, carry slots, focus states, offer placement, yaku logic, and hierarchy remain stable.

**Physical metaphor communicates ownership and position.**  
Cards sit on table. Active modifiers sit in active slots. Reserve modifiers live in a reserve tray. Shop offers sit in an offer region. Acquisition visibly moves an object.

**Digital overlays communicate abstraction.**  
Do not force realism where computers are better. Prices, comparisons, yaku requirements, accessibility focus, and textual explanations should be crisp digital information surfaces.

**Ornament belongs at boundaries.**  
Moon introductions, yaku completion, slot unlock, Koi-Koi, month completion, and December completion can carry authored ceremony. Normal hover and ordinary buying should remain quiet.

**Marks must mean something.**  
A seal, notch, border, thread, glyph, or pattern should map to a mechanic or repeated category. Purely decorative badges are visual debt.

**Negative space should come from hierarchy, not giant components.**  
A calm interface is not an interface where every object is oversized. It is one where secondary elements recede.

**Material consistency is more valuable than asset volume.**  
A coherent table, one family of trays, one typography system, one icon system, and a few repeated seasonal motifs will look more authored than fifty unrelated decorative assets.

## Evidence, open source, and risk

**23. Comparable Game Case Studies**

No one comparable should become a template.

**Nintendo / Clubhouse Games: Koi-Koi**

Specific solution: players can consult yaku while playing rather than memorizing every combination, and Nintendo's own guidance makes opponent captured-card observation part of strategy. citeturn23view8

Why it works for 12 Moons: hanafuda literacy is itself a UX challenge; persistent/inspectable yaku knowledge reduces recall burden without changing the rules.

What does not translate: 12 Moons has Moon rules, modifiers, economy, carry slots, and a longer roguelike run. The Nintendo implementation is a baseline for hanafuda information access, not a complete meta-game shell.

**Traditional Koi-Koi teaching**

Nintendo's introductory teaching starts from visible physical objects: hand, eight field cards, draw pile, same-month matching, face-up captures, yaku, then Koi-Koi risk. citeturn23view9

Why it works: rules are connected to the object the player is manipulating.

Translation to 12 Moons: first-run onboarding should follow the same dependency chain before introducing carry/shop abstractions.

What does not translate: 12 Moons needs to layer its Moon/economy systems only after the base physical grammar is understood.

**Sea of Thieves marketplace navigation, as documented by Microsoft**

Specific solution: multirow marketplace tiles use spatially intuitive directional focus—left goes to the tile left of the current tile—and interaction mappings remain consistent. citeturn23view7

Why it works for 12 Moons: a six-offer shop and eight-slot carry tray need predictable D-pad behavior.

What does not translate: visual style, monetization presentation, and scale are irrelevant. Copy only the **focus topology principle**.

**The Outer Worlds focus example, as documented by Microsoft**

Specific solution: focus uses multiple visual cues—outline/fill/type treatment rather than a nearly invisible glow. citeturn24view5

Why it works for 12 Moons: cards have detailed artwork and modifier families may use varied surfaces; focus must remain readable over all of them.

What does not translate: 12 Moons should not imitate its menu art, only its redundant focus strategy.

**Microsoft Solitaire interaction example**

Microsoft's accessibility guidance points to activation on release rather than immediate mouse-down as an error-tolerant interaction pattern: a player can move the pointer away before releasing if the initial click was accidental. citeturn25view2

Why it matters: routine shop/carry actions should not trigger destructive state at the earliest pointer event.

What does not translate: traditional solitaire's drag-centric card model should not determine 12 Moons' controller architecture.

**Into the Breach**

Its GDC postmortem is relevant primarily as a strategy-UI reference for a game designed around legible consequences rather than opaque spectacle. The transferable principle is not its grid aesthetics; it is that high-strategy interfaces benefit when rules and decision consequences are made inspectable before commitment. citeturn20search0

12 Moons should apply this to exact Stop outcomes, purchase consequences, destination/replacement preview, and deterministic modifier effects—without pretending to predict hidden future draws.

**MARVEL SNAP**

Ben Brode's GDC design talk is useful as a shipped digital-card-game reference for aggressively compressed game state and concise interaction, but 12 Moons should not inherit combat-card presentation, oversized ability-card conventions, or mobile-first spectacle. citeturn13search0

The transferable lesson is compression: the main state should remain legible without opening a management interface for every object.

**Tabletop UX practice**

GDC has specifically presented game-board and piece design as a UX discipline, reinforcing that physical object arrangement itself is interface design rather than merely art direction. citeturn19search0

For 12 Moons, that supports treating position—hand, field, capture pile, carry tray, reserve, shop shelf—as meaningful information before adding labels.

**24. Useful Open-Source Examples**

These should be treated as **patterns to study**, not dependencies to install indiscriminately.

| Repository | License / Godot | Files worth studying | Lesson | Reuse recommendation |
|---|---|---|---|---|
| `https://github.com/godotengine/godot-demo-projects` | MIT; current drag/drop demo declares Godot 4.7 fileciteturn40file0L2-L2 fileciteturn41file0L2-L2 | `gui/drag_and_drop/drag_drop_script.gd`, `gui/drag_and_drop/project.godot` | Native `_get_drag_data`, drag preview/drop pipeline; no dependency required fileciteturn18file0L2-L23 | **Safe to reuse/adapt** under MIT; prefer this over third-party drag frameworks |
| `https://github.com/Orama-Interactive/Pixelorama` | MIT; project declares Godot 4.7 fileciteturn22file0L2-L2 fileciteturn23file0L2-L2 | `src/Autoload/Themes.gd`, `project.godot` | Central Theme generation, default font sizing, theme variants, icon modulation fileciteturn25file0L2-L2 | **Study architecture; selectively reuse** small MIT patterns rather than app-scale theme machinery |
| `https://github.com/Maaack/Godot-Menus-Template` | MIT; documented for Godot 4.7, 4.4+ compatible fileciteturn28file0L2-L2 fileciteturn29file0L2-L2 | `addons/maaacks_menus_template/docs/OptionsMenuSetup.md`, `InputIconMapping.md`, `JoypadInputs.md`, template menu scenes | Options, key rebinding, input prompts, scalable menu foundations; README states support across multiple target resolutions fileciteturn29file0L2-L2 | **Potentially reusable**, but avoid importing a broad addon merely for one feature; copy/study isolated patterns if appropriate |
| `https://github.com/insideout-andrew/simple-card-pile-ui` | MIT; Godot 4.2 fileciteturn38file0L2-L2 fileciteturn36file0L2-L2 | `addons/simple_card_pile_ui/card_ui.gd`, `card_pile_ui.gd`, `card_dropzone.gd`, `card_ui_data.gd` fileciteturn43file0L2-L2 | Clear separation of card data/view/pile/drop-zone concepts; drop-zone validation and card signals fileciteturn37file0L2-L2 | **Study or selectively reuse** under MIT; 12 Moons already has mature card motion/state code, so replacing it wholesale would create unnecessary churn |
| `https://github.com/menaechmi/godot-card-game-framework4` | AGPL3-based framework with project declaring Godot 4.2 fileciteturn31file0L2-L2 fileciteturn32file0L2-L2 | `README.md`, card/container architecture, deck-builder/library examples, `src/custom/cards/sets` | Rich examples of card focus enlargement, piles, drag/drop, highlights, text fitting, resizable windows | **Study-only by default.** AGPL licensing and framework breadth make direct reuse unattractive unless its licensing/architecture is intentionally accepted |

The strongest lesson from this survey is actually **not to add a card framework**. 12 Moons already has its own authoritative game state, card registry, motion controller, presentation queue, and zone layout logic. fileciteturn10file0L2-L2

The highest-value external reuse candidates are much narrower:

- native Godot drag/drop patterns;
- theme architecture;
- menu/remap patterns;
- focus-navigation patterns.

Dependency bloat would work against the project's need for a small authored system.

**25. UX Risk Register**

| Risk | Likelihood | Severity | Cost later | Finding / mitigation |
|---|---|---|---|---|
| HUD overload as modifiers/Moons accumulate | High | Critical | Very high | Lock persistent/contextual hierarchy now |
| Mouse-only card architecture | **Already present** | High | Very high | Replace `FOCUS_NONE`; design discrete focus now fileciteturn8file0L2-L2 |
| Absolute-layout multiplication | **Already present** | High | Very high | New scenes use Containers/Theme; progressively refactor existing screens fileciteturn9file0L2-L2 |
| Strategic info hidden during Koi-Koi | **Already present** | High | Moderate | Replace blocking dim modal with decision tray fileciteturn14file0L2-L2 |
| Text becomes too small to preserve density | High | High | High | Establish typography tokens now |
| Hanafuda artwork obscured by labels/status | Medium | Critical identity damage | High | Peripheral helper/frame/seal system |
| Modifiers visually resemble hanafuda | Medium | High | High | Distinct object silhouette before art production |
| Reward/carry/shop become separate menu stack | High if built independently | High | High | One preparation shell |
| Drag-and-drop becomes required | Medium | High | High | Command-based selection model first |
| Active/reserve communicated by opacity/color only | Medium | High | Moderate | Separate spatial regions + symbols |
| Terminology drift (`Animal`, `Seed`, `Tane`) | High | Moderate | High once content grows | Lock terminology table |
| Tooltip dependence on hover | High | High | Moderate | Focus/click Inspect equivalent |
| Modifier descriptions expand into tiny prose | High | High | High | One-line effect + detail panel |
| Every feature invents new panel/component style | High with AI coding | High | Very high | Component gate + semantic Theme |
| Generic dark/neon/rounded-panel visual drift | Medium–high | High identity damage | High | Authored physical-material rules |
| Shop edge cases cause silent failures | High | Moderate–high | Moderate | Explicit state/error contract |
| Localization breaks fixed UI | High if deferred | Moderate–high | Very high | Containers + pseudolocalization now |
| Focus loss after dynamic mutation | Medium | High for controller | High | Define focus-return policy per action |
| Excessive animation harms clarity | Medium | Moderate | Moderate | Event feedback hierarchy + reduced motion |
| Accessibility becomes settings-only retrofit | Medium | High | Very high | Encode focus, state redundancy, metadata in components now |

The three most expensive mistakes to allow through this milestone are **building new screens with absolute layout**, **continuing mouse-only interactive cards**, and **separating shop/carry/reward into unrelated visual environments**.

## Implementation locks and milestone sequence

**26. Decisions to Lock Before Implementation**

**Design decisions**

Lock these now:

- the game uses one persistent tabletop/preparation visual world;
- reward, carry, and shop are phases of the same between-month environment;
- settlement visually leads into that environment;
- carry capacity is represented as eight physical active slots;
- locked slots remain visible;
- reserve is spatially distinct from active;
- modifiers do **not** use hanafuda-card silhouette/art grammar;
- primary interaction is select → destination/target, with drag optional;
- hanafuda artwork remains unobstructed;
- legal-match assistance is enabled by default but optional;
- current-month state uses a peripheral marker, not permanent glow;
- card upgrades use one standardized seal/frame system;
- yaku has compact persistent progress + expanded reference;
- Stop/Koi-Koi is a context-preserving tray, not a full-screen modal;
- Japanese terminology is canonical with English support;
- shop and carry stay visible together;
- purchases default safely to reserve when possible;
- disabled/unaffordable options remain visible with reasons;
- event spectacle follows the feedback hierarchy.

**Engineering/UI decisions**

Lock these now:

- `MoonCardView` becomes focusable;
- pointer, keyboard, and controller paths invoke the same semantic game actions;
- explicit focus-neighbor infrastructure exists before shop/carry implementation;
- dynamic screens define focus return after mutation;
- reusable project Theme carries semantic styles/tokens;
- new structural UI uses `Container` composition;
- localization strings are not constructed from arbitrary English fragments;
- modifier family/state is data, not inferred from color;
- carry operations have one source-of-truth command API;
- purchase/sell/reroll logic produces explicit result/error reasons usable by UI;
- accessibility names/descriptions are fields of reusable semantic components;
- reduced-motion and animation-speed handling can be centralized in presentation timing.

Godot provides the necessary primitives directly: focusable Controls, directional focus neighbors, `grab_focus()`, Themes, localization-aware layout, and accessibility metadata. citeturn23view0turn24view0turn24view1turn24view2

**Prototype values — deliberately not locked**

Keep these adjustable:

- exact 14/15/16 px body size;
- precise card dimensions;
- carry-slot gap;
- reward-offer width;
- shop grid gap;
- tooltip delay;
- tooltip width;
- transition durations;
- hover elevation distance;
- focus-border thickness;
- reserve capacity;
- sell percentage;
- reroll price curve;
- animation-speed multipliers;
- max central-table width at ultrawide;
- exact helper glyph sizes.

These values should emerge from 1280×720 playtesting rather than become architecture.

**27. Things NOT to Build Yet**

Do not build a giant glossary. A searchable/reference yaku sheet can grow later; first prove contextual teaching.

Do not build a tutorial campaign. January itself should teach the game.

Do not build a separate `Inventory`, `Loadout`, `Relics`, `Upgrades`, and `Collection` navigation ecosystem. Carry is the one build system.

Do not build radial menus.

Do not build a touch-specific interface.

Do not build gesture-only interactions.

Do not build rich 3D card physics for the between-month loop.

Do not build multiple shop tabs/categories.

Do not build advanced search/filter/sort for eight active slots and a small reserve.

Do not build dozens of badge variants.

Do not build Moon-specific UI layouts. Moon-specific art/motifs should skin one stable structural grammar.

Do not create final color choices before card/table art direction establishes the game's material relationships.

Do not add complex predictive yaku/odds advice.

Do not build a bespoke narration framework before the focus/accessibility semantics of the UI are stable; do populate semantic metadata now.

Do not complete every localization. Do make every new layout localization-resilient now.

Do not build elaborate collection browsing, run history, codex progression, achievements, or December ceremony for the January→February milestone.

Do not add a heavyweight card framework. The repository already has card presentation, motion, state synchronization, and tests; external frameworks are better treated as pattern references. fileciteturn6file0L2-L2

**28. Recommended UX Implementation Order**

| Step | Prerequisite | Required components | Interaction rules | Accessibility check | Anti-slop review | Acceptance condition |
|---|---|---|---|---|---|---|
| **Settlement** | Existing January terminal result and economy conversion | `PhaseShell`, `SettlementLedger`, `CurrencyDisplay`, primary action | Reveal scoring in causal order; one Continue/advance action | Keyboard focus enters first meaningful action; text ≥ project baseline; reduced-motion version works | No giant generic result card; no redundant subtitle; no modal stack | Player can explain exactly how January result became run/economic state |
| **Slot unlock** | Carry-capacity state | `CarryTray`, eight `CarrySlot`s, unlock presentation | Newly unlocked slot changes from visibly locked → available before reward | State uses lock + shape, not color; focusable slot reports locked/unlocked | No confetti storm; no “CONGRATULATIONS! SLOT UNLOCKED!” extra dialog | Player sees total eventual capacity and understands one more slot is usable |
| **Reward** | Modifier data/families; unlocked capacity | `ModifierCard`, `RewardOffer`, `OfferGrid`, `InspectPanel`, refusal action | Focus/select offer; inspect; preview; acquire; Card Upgrade enters valid-target mode | Entire decision keyboard-operable; no hover-only text; family identity redundant | Modifier object visually distinct from hanafuda; copy effect-first | Player can compare all offers to current build and know where chosen reward will go before commit |
| **Carry** | Owned modifier state + active/reserve capacities | `CarrySlot`, active tray, reserve tray, `ComparePanel` | select source → valid destinations → select; drag invokes same command only as shortcut | D-pad topology works; Cancel always restores prior state; used/disabled not color-only | No context-menu dependency; no inventory spreadsheet | Player can move any legal modifier active↔reserve without mouse or ambiguity |
| **Shop** | Bankroll, shop offer generation, buy/sell/reroll commands | six `ShopOffer`s, 3×2 `OfferGrid`, persistent carry, currency, reroll, sell | buy → reserve when possible; replacement resolution only when required; sold tiles remain spatially stable | Logical 3×2 focus; unaffordable option states reason; focus restored after mutation | Carry stays visible; no tab explosion; no generic confirmations | Player can answer price, affordability, destination, replacement consequence, bankroll, reroll cost, and current build from one view |
| **Finalize** | Valid prepared build | summary state, primary `Begin February` action | one commit unless unresolved destructive state exists | Focus lands on summary/action; status does not rely on color | Use exact action copy; no “Continue Journey” language | Player knows exactly what loadout and money cross into February |
| **February placeholder** | Finalized run state persists | `MoonBanner` / Moon rule component | transition out of preparation without resetting visual grammar | skip/reduced motion works; focus lands in correct next action | One authored transition, not multiple splash screens | February visibly inherits the finalized carry/bankroll and feels like the same run |

The immediate engineering sequence behind those screens should be slightly different from their player-facing order:

**first** build Theme/tokens + focusable component foundation;  
**then** build the shared `PhaseShell` and `CarryTray`;  
**then** settlement;  
**then** slot unlock;  
**then** modifier/reward components;  
**then** active/reserve commands;  
**then** shop;  
**then** finalization.

That ordering prevents the reward and shop from inventing UI conventions before the carry system—the core roguelike identity—exists.

The current repository already has a strong enough presentation foundation to make this transition without rewriting the game: its card layer keeps cards independent of zone containers, state changes drive screen refresh, and presentation/motion are queued separately from authoritative rules. Preserve that separation. fileciteturn10file0L2-L2

The structural UI, however, should now mature beyond prototype assumptions. The existing card control's disabled focus, tiny yaku labels, fixed coordinates, and full-screen Koi-Koi modal are precisely the kinds of decisions that are inexpensive to correct before February and increasingly expensive after twelve Moons, shops, modifiers, localization, and controller support exist. fileciteturn8file0L2-L2 fileciteturn14file0L2-L2

The standard for every new 12 Moons interface should therefore be:

> **The player sees the physical objects that define the decision, the strategic facts capable of changing that decision remain accessible, explanation appears only when requested or newly needed, every input method follows the same semantic action model, and every visual mark exists because it means something.**

That gives 12 Moons room to become mechanically deep without becoming visually loud. It preserves hanafuda rather than repainting it as a deckbuilder. It makes the eight-slot carry build a physical identity rather than another inventory. And, most importantly, it creates a UI system whose cohesion comes from **rules, repetition, restraint, and authorship** rather than from adding more panels.