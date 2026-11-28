extends Control

signal completed(assisted: bool)
signal stroke_paused
signal stroke_started

var glyph := "2"
var paper: StyleBox

var path: PackedVector2Array
var drawn := 0
var tracking := false
var assisted := false
var demo_index := -1
var guide: Tween

func _ready() -> void:
	var curve := Curve2D.new()
	curve.bake_interval = 7.0
	match glyph:
		"2":
			curve.add_point(Vector2(135, 101), Vector2.ZERO, Vector2(4, -94))
			curve.add_point(Vector2(373, 96), Vector2(14, -102), Vector2(-5, 60))
			curve.add_point(Vector2(148, 270), Vector2(126, -83))
			curve.add_point(Vector2(390, 270))
		"3":
			curve.add_point(Vector2(166, 80), Vector2.ZERO, Vector2(113, -93))
			curve.add_point(Vector2(241, 166), Vector2(137, -7), Vector2(160, -14))
			curve.add_point(Vector2(157, 262), Vector2(100, 92))
		"C":
			curve.add_point(Vector2(367, 91), Vector2.ZERO, Vector2(-185, -150))
			curve.add_point(Vector2(365, 252), Vector2(-180, 145))
		_:
			var vertices: Array = {
				"ㄱ": [Vector2(151, 88), Vector2(374, 88), Vector2(374, 262)],
				"ㄴ": [Vector2(152, 82), Vector2(152, 262), Vector2(377, 262)],
				"L": [Vector2(196, 67), Vector2(196, 271), Vector2(361, 271)],
				"ㅡ": [Vector2(134, 179), Vector2(394, 179)],
				"I": [Vector2(263, 64), Vector2(263, 279)],
				"1": [Vector2(263, 64), Vector2(263, 279)]
			}[glyph]
			for vertex in vertices:
				curve.add_point(vertex)
	path = curve.get_baked_points()
	replay_guide()

func replay_guide() -> void:
	if guide:
		guide.kill()
	guide = create_tween()
	guide.tween_method(show_guide_point, float(drawn), float(path.size() - 1), 1.3)
	guide.tween_callback(show_guide_point.bind(-1.0))

func show_guide_point(value: float) -> void:
	demo_index = int(value)
	queue_redraw()

func _draw() -> void:
	if path.is_empty():
		return
	draw_style_box(paper, Rect2(Vector2.ZERO, size))
	for point in path:
		draw_circle(point, 27, Color("#d9c79e"), true, -1, true)
	for i in range(0, path.size(), 3):
		draw_circle(path[i], 2.8, Color("#fff5db"), true, -1, true)
	if drawn > 0:
		draw_polyline(path.slice(0, drawn + 1), Color("#428979"), 19, true)
	draw_circle(path[drawn], 18, Color("#ffffff"), true, -1, true)
	draw_circle(path[drawn], 13, Color("#2e7866"), true, -1, true)
	if demo_index >= 0:
		draw_circle(path[demo_index], 10, Color("#d78339"), true, -1, true)

func _gui_input(event: InputEvent) -> void:
	if drawn >= path.size() - 1:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and tracking and drawn > 0:
			stroke_paused.emit()
		tracking = event.pressed and path[drawn].distance_to(event.position) <= 42
		if tracking:
			if guide:
				guide.kill()
			show_guide_point(-1)
			stroke_started.emit()
		accept_event()
	elif event is InputEventMouseMotion and tracking:
		while drawn + 1 < path.size() and path[drawn + 1].distance_to(event.position) <= 24:
			drawn += 1
		check_progress()
		accept_event()

func help_section() -> void:
	if drawn >= path.size() - 1:
		return
	assisted = true
	if guide:
		guide.kill()
	show_guide_point(-1)
	drawn = mini(path.size() - 1, drawn + ceili((path.size() - 1) / 3.0))
	check_progress()

func check_progress() -> void:
	queue_redraw()
	if drawn == path.size() - 1:
		tracking = false
		completed.emit(assisted)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		tracking = false
