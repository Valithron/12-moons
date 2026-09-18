extends GdUnitTestSuite

func test_motion_profile_has_independent_speed_and_reduced_motion_controls() -> void:
	var profile := MotionProfile.new()
	assert_float(profile.duration(1.0)).is_equal(1.0)
	profile.set_speed(MotionProfile.Speed.FAST)
	assert_float(profile.duration(1.0)).is_equal_approx(0.58, 0.001)
	profile.set_reduced_motion(true)
	assert_float(profile.duration(1.0)).is_equal(0.0)
	profile.set_reduced_motion(false)
	profile.set_speed(MotionProfile.Speed.INSTANT)
	assert_float(profile.duration(1.0)).is_equal(0.0)

func test_legacy_timings_and_new_profile_converge() -> void:
	var timings := MoonMotionTimings.new()
	assert_float(timings.duration(1.0)).is_equal(1.0)
	timings.mode = MoonMotionTimings.Mode.FAST
	assert_float(timings.duration(1.0)).is_equal_approx(0.58, 0.001)
	timings.set_reduced_motion(true)
	assert_float(timings.duration(1.0)).is_equal(0.0)
	timings.set_reduced_motion(false)
	timings.mode = MoonMotionTimings.Mode.INSTANT
	assert_float(timings.duration(1.0)).is_equal(0.0)

func test_month_profiles_keep_february_as_an_explicit_placeholder() -> void:
	var january := MonthPresentationProfile.january()
	var february := MonthPresentationProfile.february_placeholder()
	assert_int(january.month).is_equal(1)
	assert_int(february.month).is_equal(2)
	assert_bool(february.placeholder).is_true()
	assert_str(february.subtitle).contains("placeholder")
