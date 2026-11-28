extends "res://market.gd"

const TraceTwo := preload("res://trace_two.gd")
const FRUIT := {
	"pear": preload("res://art/pear.svg"), "apple": APPLE,
	"orange": preload("res://art/orange.svg"), "slice": preload("res://art/slice.svg"),
	"banana": preload("res://art/banana.svg"), "basket": preload("res://art/basket.svg")
}
# Subject, spoken order, short action prompt, completion, spoken hint.
const LINES := {
	"word": ["한글", "배 이름표를 달아 줄래?", "이름표를 톡 눌러 봐.", "배! 이름표가 꼭 맞네.", "배를 찾아볼까?"],
	"english": ["영어", "Banana, please!", "모모가 말한 과일을 찾아봐.", "A banana! Thank you!", "Banana."],
	"observe": ["관찰", "속을 보니 어떤 과일일까?", "통째로 있을 때 모습을 찾아봐.", "동그란 오렌지였네!", "바깥 모양도 볼까?"],
	"pattern": ["규칙", "빈칸에 어떤 과일이 올까?", "다음에 올 과일을 놓아 봐.", "사과 다음엔 배!", "사과, 배. 사과, 배. 그다음은?"],
	"trace": ["수학", "두 개네! 2를 써 볼까?", "점에서 손가락으로 그려 봐.", "사과 두 개, 숫자 2!", "여기서 이어 볼까?"],
	"home": ["과일 가게", "모모의 과일 가게에 놀러 와!", "", "", ""],
	"end": ["진열대", "오늘 가게 일, 같이 해 줘서 고마워!", "또 놀기", "", ""]
}
const OPTIONS := {"word": ["사과", "배"], "english": ["pear", "banana"], "observe": ["banana", "orange"], "pattern": ["apple", "pear"]}
var kind := "word"
var swap_options := false
var prizes: Array = []
var layer: Control
var focus_item: Control
var choices: Array[Button] = []
var drag_item: Button
var drag_origin: Vector2
var finger_origin: Vector2
var trace: TraceTwo
var help_button: Button
var attempts := 0
var helped := false
var hint_timer: Timer

func setup_board(order_text: String, title: String, prompt: String) -> void:
	for item in [$Basket, $CounterPill, $Count, $Crate, $FruitStand, $Apple1, $Apple2, $OrderApple1, $OrderApple2, $Demo, $Replay]:
		item.hide()
	$Momo.position = Vector2(48, 265)
	$Momo.size = Vector2(340, 476)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(112, 222), Vector2(123, 261), Vector2(167, 222)])
	tail.color = $Note.get_theme_stylebox("panel").bg_color
	add_child(tail)
	move_child(tail, $Note.get_index())
	$Note.size.x = 738
	$Order.size.x = 688
	$Order.add_theme_font_size_override("font_size", 35)
	$Order.text = order_text
	$Title.text = title
	for node in [$PromptCard, $Prompt, $Replay]:
		node.position = Vector2(422, 695)
		node.size = Vector2(800, 72)
	$Replay.text = "다음 주문  →"
	$Prompt.text = prompt
	layer = Control.new()
	add_child(layer)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var board := Panel.new()
	put(board, Rect2(411, 267, 819, 411))
	board.add_theme_stylebox_override("panel", $FruitStand.get_theme_stylebox("panel"))
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE

func start_activity() -> void:
	setup_board(LINES[kind][1], "과일 가게 · " + str(LINES[kind][0]), LINES[kind][2])
	match kind:
		"word": focus_item = picture("pear", Rect2(742, 280, 153, 153))
		"english": focus_item = card("?", Rect2(735, 290, 168, 120), reveal_hint)
		"observe": focus_item = picture("slice", Rect2(735, 285, 160, 160))
		"pattern":
			for i in 5:
				picture("apple" if i % 2 == 0 else "pear", Rect2(444 + 125 * i, 315, 106, 106))
			focus_item = card("?", Rect2(1065, 315, 118, 113), demonstrate)
		"trace": build_trace()
		"end": build_shelf()
	if OPTIONS.has(kind):
		build_choices()
	hint_timer = Timer.new()
	hint_timer.one_shot = true
	hint_timer.wait_time = 6
	add_child(hint_timer)
	hint_timer.timeout.connect(demonstrate)
	if kind not in ["end", "home"]:
		hint_timer.start()
	repeat_line()

func put(node: Control, bounds: Rect2) -> void:
	layer.add_child(node)
	node.position = bounds.position
	node.size = bounds.size

func picture(key: String, bounds: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = FRUIT[key]
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(image, bounds)
	return image

func card(caption: String, bounds: Rect2, action: Callable) -> Button:
	var button: Button = $Listen.duplicate(0)
	button.text = caption
	button.add_theme_font_size_override("font_size", 42)
	put(button, bounds)
	button.pressed.connect(action)
	return button

func set_picture(button: Button, key: String) -> void:
	button.text = ""
	button.icon = FRUIT[key]
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", roundi(minf(button.size.x, button.size.y) * 0.85))

func build_choices() -> void:
	var options: Array = OPTIONS[kind].duplicate()
	if swap_options:
		options.reverse()
	for i in options.size():
		var key: String = options[i]
		var button := card(key, Rect2(534 + 326 * i, 463, 243, 155), answer.bind(key))
		if kind != "word":
			set_picture(button, key)
		button.set_meta("key", key)
		choices.append(button)

func build_trace() -> void:
	picture("basket", Rect2(427, 376, 191, 166))
	picture("apple", Rect2(446, 394, 72, 72))
	picture("apple", Rect2(513, 395, 72, 72))
	trace = TraceTwo.new()
	trace.paper = $Listen.get_theme_stylebox("normal")
	put(trace, Rect2(664, 292, 531, 347))
	trace.completed.connect(trace_done)
	trace.stroke_started.connect(func(): hint_timer.stop())
	trace.stroke_paused.connect(func(): hint_timer.start())
	help_button = card("함께 그리기", Rect2(426, 577, 213, 69), trace.help_section)
	help_button.add_theme_font_size_override("font_size", 25)

func build_shelf() -> void:
	for i in prizes.size():
		var item: String = {"word":"pear", "count":"basket", "trace":"basket", "english":"banana", "observe":"orange", "pattern":"pear"}[prizes[i]]
		var x := 445 + i * 151
		var prize := picture(item, Rect2(x, 385, 142, 142))
		if item == "basket":
			picture("apple", Rect2(x + 21, 417, 52, 52))
			picture("apple", Rect2(x + 69, 415, 52, 52))
		if prizes[i] == "trace" or prizes[i] == "word":
			var tag := Label.new()
			tag.text = "2" if prizes[i] == "trace" else "배"
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tag.add_theme_color_override("font_color", Color("#284c42"))
			tag.add_theme_stylebox_override("normal", $Listen.get_theme_stylebox("normal"))
			put(tag, Rect2(x + 25, 507, 92, 53))
		pulse(prize, 0.08 * i)
	$Speaker.text = "모모"
	$Momo.texture = CHEER
	$Replay.text = "또 놀기  →"
	$Replay.show()
	$PromptCard.hide()
	$Prompt.hide()

func trace_done(assisted: bool) -> void:
	helped = assisted
	help_button.hide()
	var shrink := trace.create_tween().set_parallel()
	shrink.tween_property(trace, "position", Vector2(491, 471), 0.55)
	shrink.tween_property(trace, "scale", Vector2(0.23, 0.23), 0.55)
	complete()

func pulse(node: Control, delay := 0.0) -> void:
	node.pivot_offset = node.size / 2
	var tween := node.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(node, "scale", Vector2(1.07, 1.07), 0.17)
	tween.tween_property(node, "scale", Vector2.ONE, 0.22)

func demonstrate() -> void:
	if finished or kind in ["end", "home"]:
		return
	if kind == "trace":
		trace.replay_guide()
		if trace.drawn > 0:
			$Prompt.text = LINES.trace[4]
	elif kind == "pattern":
		var fruits := layer.get_children()
		for i in 5:
			pulse(fruits[i + 1], i * 0.17)
	elif is_instance_valid(focus_item):
		pulse(focus_item)
		if kind == "english" and not sound_on:
			reveal_english()

func reveal_english() -> void:
	if not finished:
		set_picture(focus_item as Button, "banana")
		helped = true
		$Prompt.text = "그림과 같은 과일을 찾아봐."

func reveal_hint() -> void:
	if finished:
		return
	helped = true
	match kind:
		"english": reveal_english()
		"observe": focus_item.texture = FRUIT.orange
		"word":
			for button in choices:
				button.icon = FRUIT.pear if button.text == "배" else APPLE
				button.add_theme_constant_override("icon_max_width", 55)
		"pattern": demonstrate()
	$Prompt.text = LINES[kind][4] if kind != "english" else "그림과 같은 과일을 찾아봐."
	speak_clip("hint")

func answer(key: String) -> void:
	if finished:
		return
	hint_timer.stop()
	if key != OPTIONS[kind][1]:
		attempts += 1
		if attempts >= 2 or kind == "english":
			reveal_hint()
		else:
			$Prompt.text = LINES[kind][4]
			speak_clip("hint")
			demonstrate()
		return
	for button in choices:
		if button.get_meta("key") != key:
			button.hide()
			continue
		button.disabled = true
		button.add_theme_color_override("font_disabled_color", Color("#284c42"))
		button.add_theme_stylebox_override("disabled", $Listen.get_theme_stylebox("normal"))
		var destination := Vector2(694, 425)
		match kind:
			"english":
				button.hide()
				var banana := picture("banana", Rect2(button.position, Vector2(143, 143)))
				banana.create_tween().tween_property(banana, "position", Vector2(249, 422), 0.4)
				continue
			"observe":
				focus_item.hide()
				destination = Vector2(695, 308)
			"pattern":
				focus_item.hide()
				button.hide()
				var fruit := picture(key, Rect2(button.position, Vector2(108, 108)))
				fruit.create_tween().tween_property(fruit, "position", focus_item.position, 0.35)
				continue
		button.create_tween().tween_property(button, "position", destination, 0.35)
	complete()

func complete() -> void:
	finished = true
	hint_timer.stop()
	$Order.text = LINES[kind][3]
	$Momo.texture = CHEER
	pulse($Momo)
	play_cue($Done, JINGLE)
	speak_clip("done")
	$Prompt.hide()
	$PromptCard.hide()
	$Replay.show()

func speak_clip(suffix: String) -> void:
	stop_voice()
	if sound_on:
		var clip := load("res://sound/round/%s_%s.wav" % [kind, suffix]) as AudioStream
		play_cue($Voice, clip)

func repeat_line() -> void:
	if not is_instance_valid(layer):
		return
	demonstrate()
	speak_clip("done" if finished else "order")

func show_demo() -> void:
	demonstrate()

func toggle_sound() -> void:
	super()
	if kind == "english" and not sound_on:
		reveal_english()

func _input(event: InputEvent) -> void:
	if not is_node_ready() or kind != "pattern" or finished or not event is InputEventMouse:
		return
	var point: Vector2 = make_input_local(event).position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for button in choices:
				if button.get_rect().has_point(point):
					drag_item = button
					drag_origin = button.position
					finger_origin = point
					break
		elif drag_item:
			var key: String = drag_item.get_meta("key")
			var accept: bool = not event.canceled and (point.distance_to(finger_origin) < 18 or focus_item.get_rect().grow(36).has_point(point))
			reset_drag()
			if accept:
				answer(key)
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventMouseMotion and drag_item:
		drag_item.position = drag_origin + point - finger_origin
	if drag_item:
		get_viewport().set_input_as_handled()

func reset_drag() -> void:
	if drag_item:
		drag_item.position = drag_origin
		drag_item = null

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		reset_drag()
