class_name MoonMotionTimings
extends RefCounted

## Central timing vocabulary for the January presentation layer.
##
## These values are intentionally presentation-only. They never participate in
## MatchController or GameState timing, scoring, or legal-action generation.

enum Mode {
	NORMAL,
	FAST,
	REDUCED
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

func duration(seconds: float) -> float:
	match mode:
		Mode.FAST:
			return seconds * 0.58
		Mode.REDUCED:
			return 0.0
	return seconds

func is_reduced() -> bool:
	return mode == Mode.REDUCED
