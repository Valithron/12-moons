class_name MonthPresentationProfile
extends RefCounted

var month: int = 1
var moon_id: String = "wolf_moon"
var title: String = "JANUARY"
var subtitle: String = "Wolf Moon"
var background: Color = Color(0.045, 0.075, 0.11)
var accent: Color = Color(0.95, 0.84, 0.56)
var foreground: Color = Color(0.91, 0.90, 0.82)
var transition_label: String = "Begin February"
var placeholder: bool = false

static func january() -> MonthPresentationProfile:
	return MonthPresentationProfile.new()

static func february_placeholder() -> MonthPresentationProfile:
	var result := MonthPresentationProfile.new()
	result.month = 2
	result.moon_id = "snow_moon"
	result.title = "FEBRUARY"
	result.subtitle = "Snow Moon — placeholder"
	result.background = Color(0.075, 0.11, 0.17)
	result.accent = Color(0.72, 0.85, 0.95)
	result.foreground = Color(0.90, 0.95, 1.0)
	result.transition_label = "February gameplay is next"
	result.placeholder = true
	return result

func to_dict() -> Dictionary:
	return {
		"month": month,
		"moon_id": moon_id,
		"title": title,
		"subtitle": subtitle,
		"background": background.to_html(false),
		"accent": accent.to_html(false),
		"foreground": foreground.to_html(false),
		"transition_label": transition_label,
		"placeholder": placeholder
	}
