extends "res://fruit_card.gd"

signal route_selected(route: String)
const CONTENT := preload("res://subject_cards.json")
const TITLES := {"hangul":"한글 놀이", "english":"영어 놀이", "numbers":"숫자 놀이", "shop":"과일 가게", "bakery":"빵집"}
const ICONS := {
	"hangul": preload("res://art/book.webp"), "english": preload("res://art/blocks.webp"),
	"numbers": preload("res://art/abacus.webp"), "shop": preload("res://art/fruit_basket.png"), "bakery": preload("res://art/toast.webp")
}
var subject := "hangul"
var resume_routes: Array = []
var route_buttons: Dictionary = {}
var lesson: Dictionary

func start_activity() -> void:
	var backdrop := AtlasTexture.new()
	backdrop.atlas = $Orchard.texture
	backdrop.region = Rect2(0, 25, 830, 902)
	$Orchard.texture = backdrop
	if kind == "hub":
		setup_board("우리 뭐 하고 놀까?", "모모의 놀이마당", "")
		$Speaker.text = "모모"
		for i in TITLES.size():
			var route: String = TITLES.keys()[i]
			var label: String = TITLES[route]
			if route in resume_routes:
				label += "\n이어서"
			var bounds := Rect2(440 + (i % 2) * 382, 283 + floori(i / 2.0) * 127, 360, 111)
			if route == "bakery":
				bounds = Rect2(440, 537, 742, 109)
			var button := card(label, bounds, route_selected.emit.bind(route))
			var style: StyleBoxFlat = $Listen.get_theme_stylebox("normal").duplicate()
			style.content_margin_left = 24
			style.content_margin_right = 22
			for state in ["normal", "hover", "pressed", "focus"]:
				button.add_theme_stylebox_override(state, style)
			button.icon = ICONS[route]
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 91)
			button.add_theme_font_size_override("font_size", 34)
			route_buttons[route] = button
		$Prompt.hide()
		$PromptCard.hide()
	elif kind == "subject_end":
		setup_board("오늘 놀이를 다 했네!", TITLES[subject], "")
		$Speaker.text = "모모"
		$Momo.texture = CHEER
		var left := 815 - prizes.size() * 95
		for i in prizes.size():
			var item: Dictionary = CONTENT.data[prizes[i]]
			var tag := caption(item.target, Rect2(left + i * 190, 389, 174, 125))
			if item.task == "listen_picture":
				tag.text = ""
				picture(item.sample, tag.get_rect().grow(-8))
			pulse(tag)
		$Replay.text = "또 놀기   →"
		$Replay.show()
		$Prompt.hide()
		$PromptCard.hide()
	else:
		lesson = CONTENT.data[kind]
		var prompts := {"listen_picture":"모모가 말한 그림을 찾아봐.", "label":"그림에 맞는 이름을 골라 봐.", "write":"큰 점에서 시작해 봐.", "quantity":"개수를 세고 숫자를 골라 봐.", "set":"숫자에 맞는 카드를 찾아봐."}
		setup_board(lesson.order, TITLES[subject], prompts[lesson.task])
		$Replay.text = "다음 놀이   →"
		if lesson.task == "write":
			build_writing()
		else:
			build_question()
	repeat_line()

func caption(value: String, bounds: Rect2) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", 46)
	node.add_theme_color_override("font_color", Color("#315548"))
	node.add_theme_stylebox_override("normal", $Listen.get_theme_stylebox("normal"))
	put(node, bounds)
	return node

func show_set(parent: Control, count: int) -> void:
	var width := minf(62, (parent.size.x - 10) / count)
	for i in count:
		var image := TextureRect.new()
		image.texture = APPLE
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(image)
		image.size = Vector2(width, width)
		image.position = Vector2((parent.size.x - width * count) / 2 + i * width, (parent.size.y - width) / 2)

func build_question() -> void:
	var bounds := Rect2(708, 285, 224, 141)
	match lesson.task:
		"listen_picture": focus_item = card("?", bounds, reveal_hint)
		"label": focus_item = picture(lesson.sample, bounds)
		"quantity":
			focus_item = caption("", bounds)
			show_set(focus_item, int(lesson.sample))
		"set": focus_item = caption(lesson.sample, bounds)
	var options := [lesson.target, lesson.other]
	if swap_options:
		options.reverse()
	for i in options.size():
		var value: String = options[i]
		var button := card(value, Rect2(533 + 321 * i, 458, 252, 163), answer.bind(value))
		match lesson.task:
			"listen_picture": set_picture(button, value)
			"set":
				button.text = ""
				show_set(button, int(value))
		button.set_meta("key", value)
		choices.append(button)

func build_writing() -> void:
	caption(lesson.target, Rect2(454, 354, 178, 156))
	trace = TraceTwo.new()
	trace.glyph = lesson.target
	trace.paper = $Listen.get_theme_stylebox("normal")
	put(trace, Rect2(659, 292, 532, 349))
	trace.completed.connect(writing_done)
	help_button = card("함께 쓰기", Rect2(438, 565, 210, 72), trace.help_section)
	help_button.add_theme_font_size_override("font_size", 26)

func writing_done(assisted: bool) -> void:
	helped = assisted
	help_button.hide()
	complete()

func answer(value: String) -> void:
	if finished:
		return
	if value != lesson.target:
		reveal_hint()
		if sound_on:
			play_clip("hint")
		return
	for button in choices:
		button.disabled = true
		if button.get_meta("key") != value:
			button.hide()
		else:
			button.add_theme_stylebox_override("disabled", $Listen.get_theme_stylebox("normal"))
			button.add_theme_color_override("font_disabled_color", Color("#315548"))
			pulse(button)
	complete()

func complete() -> void:
	finished = true
	$Order.text = lesson.done
	$Momo.texture = CHEER
	pulse($Momo)
	play_cue($Done, JINGLE)
	play_clip(kind + "_done")
	$Prompt.hide()
	$PromptCard.hide()
	$Replay.show()

func reveal_hint() -> void:
	if finished or lesson.is_empty():
		return
	helped = true
	match lesson.task:
		"listen_picture":
			set_picture(focus_item, lesson.sample)
			$Prompt.text = "그림과 같은 것을 찾아봐."
		"label", "quantity", "set":
			for button in choices:
				if button.get_meta("key") == lesson.target:
					pulse(button)
		"write": trace.replay_guide()

func demonstrate() -> void:
	if finished or lesson.is_empty():
		return
	if lesson.task == "write":
		trace.replay_guide()
	elif lesson.task == "listen_picture" and not sound_on:
		reveal_hint()
	elif focus_item:
		pulse(focus_item)

func play_clip(name_key: String) -> void:
	stop_voice()
	if sound_on:
		play_cue($Voice, load("res://sound/subjects/" + name_key + ".wav"))

func repeat_line() -> void:
	if kind == "hub":
		play_clip("welcome")
	elif kind == "subject_end":
		play_clip("finish")
	else:
		demonstrate()
		play_clip(kind + ("_done" if finished else "_order"))
