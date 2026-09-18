# Card Motion Presentation Model

The January prototype keeps rules authoritative in `MatchController` and `GameState`. Card
motion is a presentation concern layered over an accepted action:

`accepted action -> before/after state snapshots -> semantic presentation sequence -> input unlock`

## Persistent visual cards

`match_screen.gd` owns a stable-ID registry of `card_id -> MoonCardView`. Gameplay cards live on
one full-screen motion layer, so a card can travel from a hand to the field, resolution area, or
capture spread without being destroyed and recreated. The registry is never consulted by the
rules engine. When a transition cannot keep a card node in place, the motion controller uses that
same registered node as the deliberate visual proxy.

## Sequencing and cancellation

`MoonPresentationQueue` accepts semantic jobs and runs them in order. `MoonCardMotionController`
contains the reusable tween primitives for travel, staggered movement, flip, impact, pulse, hover,
and fade. `match_screen.gd` owns only the semantic choreography: deal, play, reveal, match/slap,
capture transfer, reflow, yaku feedback, and score-decision timing.

The screen sets `presentation_busy` as soon as an action is accepted. Card clicks and score
buttons remain locked until the queued sequence is complete. Queue cancellation increments a
generation token and kills active tweens during scene teardown or January restart; a cancelled
presentation cannot mutate authoritative state.

## Motion language

Timings are centralized in `MoonMotionTimings` with normal, fast, and reduced-motion modes. The
prototype uses brisk ease-out travel, short reflow, a restrained capture impact, a readable draw
reveal hold, and a brief yaku emphasis. The opening 8/8/8 deal uses a staggered packet from the
draw-pile origin. Opponent cards use the same choreography while remaining face-down until their
play reveal.

Choice phases leave the pending card in the resolution area and highlight only legal field
targets. Yaku feedback waits until the responsible cards have arrived in the capture spread;
Stop/Koi-Koi therefore cannot appear while capture motion is still underway.

## Godot references

The implementation uses Godot's native `SceneTreeTween` API: property tweening, sequential and
parallel groups, completion waits, bound tweens, and cancellation. A `Control`'s pivot and global
position support the lightweight scale-X card flip and full-screen motion layer. Reparenting is
not required by the current layout, but Godot's `Node.reparent(..., true)` remains the safe option
if future table zones become separate parents.

- [Godot 4.7 Tween reference](https://docs.godotengine.org/en/4.7/classes/class_tween.html)
- [Godot Control reference](https://docs.godotengine.org/en/4.6/classes/class_control.html)
- [Godot Node reference](https://docs.godotengine.org/en/4.5/classes/class_node.html)
- [Godot animation introduction](https://docs.godotengine.org/en/4.7/tutorials/animation/introduction.html)
- [Godot Hanafuda prototype reference](https://github.com/game-prototypes/hanafuda)
- [Godot card-hand layout reference](https://github.com/jkvastad/Godot-4-Card-Hand-Tutorial)

No external animation framework is introduced. The Compatibility renderer and deterministic
January rules remain unchanged.
