class_name MotionProfile
extends RefCounted

enum Speed {
	NORMAL,
	FAST,
	INSTANT
}

var speed: Speed = Speed.NORMAL
var reduced_motion: bool = false

func duration(base_seconds: float) -> float:
	if reduced_motion or speed == Speed.INSTANT:
		return 0.0
	if speed == Speed.FAST:
		return base_seconds * 0.58
	return base_seconds

func set_speed(next_speed: Speed) -> void:
	speed = next_speed

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
