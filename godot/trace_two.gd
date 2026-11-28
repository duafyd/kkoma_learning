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
var strokes: Array[PackedVector2Array] = []
var stroke_index := 0
var done := false
var forgiving := false

func _ready() -> void:
	var multiple := {
		"A": [[[156,276],[265,61]],[[265,61],[379,276]],[[193,199],[338,199]]],
		"B": [[[184,64],[184,278]],[[184,64],[302,64],[351,84],[361,119],[343,151],[303,167],[184,167]],[[184,167],[311,167],[362,193],[372,227],[351,263],[307,278],[184,278]]],
		"P": [[[186,64],[186,279]],[[186,64],[302,64],[352,87],[363,122],[342,155],[297,171],[186,171]]],
		"ㅁ": [[[157,76],[157,265]],[[157,76],[375,76],[375,265]],[[157,265],[375,265]]],
		"4": [[[307,65],[175,207],[366,207]],[[306,64],[306,283]]],
		"배": [[[135,84],[135,260]],[[249,83],[249,260]],[[135,169],[249,169]],[[135,260],[249,260]],[[307,70],[307,280]],[[307,150],[363,150]],[[416,69],[416,282]]],
		"빵": [[[108,60],[108,169]],[[170,60],[170,169]],[[108,111],[170,111]],[[108,169],[170,169]],[[207,60],[207,169]],[[269,60],[269,169]],[[207,111],[269,111]],[[207,169],[269,169]],[[334,53],[334,177]],[[335,112],[404,112]]]
	}
	if multiple.has(glyph):
		for points in multiple[glyph]:
			strokes.append(bake(points))
		if glyph == "빵":
			strokes.append(arc_points(Vector2(263, 253), Vector2(88, 46), -PI / 2, -TAU))
	elif glyph == "우":
		strokes.append(arc_points(Vector2(264, 126), Vector2(80, 65), -PI / 2, -TAU))
		strokes.append(bake([[119,210],[405,210]]))
		strokes.append(bake([[264,210],[264,290]]))
	else:
		strokes.append(single_path())
	path = strokes[0]
	replay_guide()

func bake(points: Array) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.bake_interval = 7
	for point in points:
		curve.add_point(Vector2(point[0], point[1]))
	return curve.get_baked_points()

func single_path() -> PackedVector2Array:
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
		"O", "◯":
			return arc_points(Vector2(266, 173), Vector2(106, 111), -PI / 2, -TAU)
		"⌒":
			return arc_points(Vector2(264, 227), Vector2(145, 132), PI, PI)
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
				"1": [Vector2(263, 64), Vector2(263, 279)],
				"—": [Vector2(118, 174), Vector2(412, 174)],
				"│": [Vector2(264, 61), Vector2(264, 279)],
				"ㅣ": [Vector2(264, 61), Vector2(264, 279)],
				"5": [Vector2(362, 72), Vector2(200, 72), Vector2(182, 170), Vector2(241, 147), Vector2(315, 154), Vector2(357, 199), Vector2(344, 252), Vector2(288, 283), Vector2(214, 281), Vector2(175, 257)]
			}[glyph]
			for vertex in vertices:
				curve.add_point(vertex)
	return curve.get_baked_points()

func arc_points(center: Vector2, radii: Vector2, start: float, span: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 97:
		var angle := start + span * i / 96
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	return points

func replay_guide() -> void:
	if done:
		return
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
	for stroke in strokes:
		for point in stroke:
			draw_circle(point, 31 if forgiving else 25, Color("#d9c79e"), true, -1, true)
	for i in stroke_index:
		draw_polyline(strokes[i], Color("#428979"), 19, true)
	for i in range(0, path.size(), 3):
		draw_circle(path[i], 2.8, Color("#fff5db"), true, -1, true)
	if drawn > 0:
		draw_polyline(path.slice(0, drawn + 1), Color("#428979"), 19, true)
	if done:
		return
	draw_circle(path[drawn], 18, Color("#ffffff"), true, -1, true)
	draw_circle(path[drawn], 13, Color("#2e7866"), true, -1, true)
	if demo_index >= 0:
		draw_circle(path[demo_index], 10, Color("#d78339"), true, -1, true)

func _gui_input(event: InputEvent) -> void:
	if done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and tracking and drawn > 0:
			stroke_paused.emit()
		tracking = event.pressed and path[drawn].distance_to(event.position) <= (58.0 if forgiving else 42.0)
		if tracking:
			if guide:
				guide.kill()
			show_guide_point(-1)
			stroke_started.emit()
		accept_event()
	elif event is InputEventMouseMotion and tracking:
		while drawn + 1 < path.size() and path[drawn + 1].distance_to(event.position) <= (35.0 if forgiving else 24.0):
			drawn += 1
		check_progress()
		accept_event()

func help_section() -> void:
	if done:
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
		if stroke_index + 1 < strokes.size():
			stroke_index += 1
			drawn = 0
			path = strokes[stroke_index]
			replay_guide()
		else:
			done = true
			completed.emit(assisted)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		tracking = false
