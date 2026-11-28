extends Panel

signal age_changed(age: int)
signal returned

var age := 4
var onboarding := false
var history := []
const FONT := preload("res://art/menu.otf")

func _ready() -> void:
	position = Vector2(393, 261)
	size = Vector2(840, 416)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff1d4")
	style.border_color = Color("#a67a51")
	style.set_border_width_all(4)
	style.set_corner_radius_all(28)
	add_theme_stylebox_override("panel", style)
	var title := label("아이 나이를 골라 주세요", 31, Rect2(46, 24, 748, 59))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for i in 4:
		var n := i + 2
		var b := action("만 %d세" % n, Rect2(45 + i * 191, 99, 172, 77))
		b.modulate = Color("#f1bf75") if not onboarding and n == age else Color.WHITE
		b.pressed.connect(age_changed.emit.bind(n))
	if onboarding:
		label("선택한 나이에 맞춰 놀이를 준비할게요.", 23, Rect2(46, 225, 748, 50))
	else:
		var text := "최근 놀이 기록이 여기에 나타나요."
		if not history.is_empty():
			var lines: PackedStringArray = []
			for i in range(history.size() - 1, maxi(-1, history.size() - 4), -1):
				var item: Dictionary = history[i]
				lines.append("%s · 만 %d세   혼자 %d   도움 %d   건너뜀 %d" % [item.title, item.age, item.direct, item.helped, item.skipped])
			text = "\n".join(lines)
		var recent := label(text, 23, Rect2(46, 196, 748, 120))
		recent.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		var back := action("놀이마당으로", Rect2(295, 325, 250, 68))
		back.pressed.connect(returned.emit)

func label(caption: String, font_size: int, bounds: Rect2) -> Label:
	var control := Label.new()
	control.text = caption
	control.add_theme_font_override("font", FONT)
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", Color("#315548"))
	control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	place(control, bounds)
	return control

func action(caption: String, bounds: Rect2) -> Button:
	var control := Button.new()
	control.text = caption
	control.add_theme_font_override("font", FONT)
	control.add_theme_font_size_override("font_size", 27)
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = Color("#2a685c")
	style.border_color = Color("#254d43")
	for state in ["normal", "hover", "pressed", "focus"]:
		control.add_theme_stylebox_override(state, style)
	place(control, bounds)
	return control

func place(control: Control, bounds: Rect2) -> void:
	add_child(control)
	control.position = bounds.position
	control.size = bounds.size
