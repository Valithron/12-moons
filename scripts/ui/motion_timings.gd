class_name MoonMotionTimings
extends RefCounted

## Central timing vocabulary for the January presentation layer.
##
## These values are intentionally presentation-only. They never participate in
## MatchController or GameState timing, scoring, or legal-action generation.

enum Mode {
	NORMAL,
	FAST,
	INSTANT,
	REDUCED # Kept as a compatibility alias for older UI settings.
}

const DEAL_TRAVEL := 0.18
const DEAL_STAGGER := 0.045
const HAND_HOVER := 0.10
const HAND_REFLOW := 0.19
const PLAY_TRAVEL := 0.23
const FIELD_REFLOW := 0.18
const CAPTURE_APPROACH := 0.19
const CAPTURE_IMPACT := 0.085
const CAPTURE_PAUSE := 0.075
const CAPTURE_TRANSFER := 0.22
const DRAW_TRAVEL := 0.18
const DRAW_FLIP := 0.15
const DRAW_HOLD := 0.24
const CHOICE_HOLD := 0.10
const YAKU_FEEDBACK := 0.30
const CEREMONY_FLIP := 0.16
const CEREMONY_HOLD := 0.20
const MODAL_DISMISS := 0.13
const RESULT_HOLD := 0.24

var mode: Mode = Mode.NORMAL
var reduced_motion: bool = false
var profile: MotionProfile = MotionProfile.new()

func duration(seconds: float) -> float:
	profile.reduced_motion = reduced_motion or mode == Mode.REDUCED
	match mode:
		Mode.FAST:
			profile.speed = MotionProfile.Speed.FAST
		Mode.INSTANT:
			profile.speed = MotionProfile.Speed.INSTANT
		_:
			profile.speed = MotionProfile.Speed.NORMAL
	return profile.duration(seconds)

func is_reduced() -> bool:
	return reduced_motion or mode == Mode.REDUCED or mode == Mode.INSTANT

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled

func set_speed(speed: MotionProfile.Speed) -> void:
	match speed:
		MotionProfile.Speed.FAST:
			mode = Mode.FAST
		MotionProfile.Speed.INSTANT:
			mode = Mode.INSTANT
		_:
			mode = Mode.NORMAL
