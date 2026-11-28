extends "res://subject_card.gd"

const CATALOG := preload("res://activity_catalog.json")
const BAKERY := preload("res://art/bakery.webp")
const PROMPTS := {
	"match":"같은 그림을 골라 봐.", "listen":"모모가 말한 그림을 골라 봐.",
	"label":"알맞은 이름표를 골라 봐.", "bundles":"주문표와 같은 묶음을 찾아봐.",
	"listen_bundles":"모모가 말한 묶음을 골라 봐.", "observe":"어느 그림과 어울릴까?",
	"fill":"물건을 톡 누르거나 옮겨 봐.", "dots":"물건 아래에 점을 찍어 봐.",
	"trace":"큰 점에서 시작해서 그려 봐.", "pattern":"빈칸에 들어갈 것을 골라 봐.",
	"match_row":"견본과 같은 순서를 찾아봐.", "repair":"견본과 다른 칸을 톡 눌러 봐.",
	"layout":"물건을 고르고 자리를 톡 눌러 봐.", "how_many":"하나씩 세고 숫자를 눌러 봐.",
	"quantity_choice":"개수가 같은 것을 골라 봐."
}
var venue := ""
var age := 4
var item_total := 0
var source_count := 0
var target_slots: Array[Button] = []
var marked := {}
var selected_item := ""
var task_board: Control
var stock: Button
var container: Button
var stock_line: Label
var order_line: Label
var confirm_fill: Button
var grab_source: Button
var grab_start := Vector2.ZERO
var moving: TextureRect
var quantity_task := false

func start_activity() -> void:
	if venue == "bakery":
		$Orchard.texture = BAKERY
	var title: String = TITLES.get(subject, "빵집" if venue == "bakery" else "과일 가게")
	if kind == "catalog_end":
		setup_board("오늘 놀이를 다 했네!", title, "")
		$Momo.texture = CHEER
		var offset := 818.0 - 72.0 * prizes.size()
		for i in prizes.size():
			var item: Dictionary = CATALOG.data[prizes[i]]
			var v = item.get("item", item.target)
			var r := Rect2(offset + i * 144, 402, 136, 127)
			if v is Array:
				v = v.front()
			if v is String and sprite(v) != null:
				picture(v, r)
			else:
				caption(str(item.target) if item.target is not Array else "완료", r)
		$Prompt.hide()
		$PromptCard.hide()
		$Replay.text = "또 놀기   →"
		$Replay.show()
		repeat_line()
		return
	lesson = CATALOG.data[kind]
	quantity_task = lesson.task == "fill"
	setup_board(lesson.order, title, PROMPTS[lesson.task])
	$Order.add_theme_font_size_override("font_size", 30)
	$Order.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match lesson.task:
		"trace": build_catalog_trace()
		"fill": build_fill()
		"dots": build_dots()
		"layout": build_layout()
		"repair": build_repair()
		"pattern", "match_row":
			var sample := Rect2(456, 308, 718, 115)
			if lesson.task == "pattern":
				sample.size.x -= 117
			task_board = picture_row(lesson.row, sample)
			if lesson.task == "pattern":
				focus_item = caption("?", Rect2(1066, 308, 108, 115))
			build_catalog_options()
		_:
			var sample = lesson.get("sample")
			if lesson.task in ["listen", "listen_bundles"]:
				focus_item = card("?", Rect2(692, 301, 250, 112), show_help)
				if not sound_on:
					show_help()
			elif lesson.task == "how_many":
				focus_item = picture_row(copies("apple", int(sample)), Rect2(535, 292, 571, 140))
			elif sample is String and sprite(sample):
				focus_item = picture(sample, Rect2(719, 279, 196, 155))
			elif sample != null:
				focus_item = caption(str(sample), Rect2(573, 308, 491, 115))
			build_catalog_options()
	repeat_line()

func sprite(key: String) -> Texture2D:
	if FRUIT.has(key):
		return FRUIT[key]
	var path_to_art := "res://art/" + key + ".webp"
	if ResourceLoader.exists(path_to_art, "Texture2D"):
		return load(path_to_art)
	return null

func picture(key: String, bounds: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = sprite(key)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(image, bounds)
	return image

func copies(texture_key: String, amount: int) -> Array:
	var items := []
	items.resize(amount)
	items.fill(texture_key)
	return items

func picture_row(items: Array, bounds: Rect2, parent: Control = null) -> Control:
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent:
		parent.add_child(row)
		row.position = bounds.position
		row.size = bounds.size
	else:
		put(row, bounds)
	var step := minf(bounds.size.x / items.size(), bounds.size.y)
	var start := (bounds.size.x - step * items.size()) / 2.0
	for i in items.size():
		var texture := TextureRect.new()
		texture.texture = sprite(items[i])
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(texture)
		texture.position = Vector2(start + i * step, (bounds.size.y - step) / 2)
		texture.size = Vector2(step, step)
	return row

func build_catalog_options() -> void:
	var options: Array = lesson.choices.duplicate()
	if swap_options:
		options.reverse()
	var width := 220 if options.size() == 3 else 316
	for i in options.size():
		var b := card("", Rect2(818 - options.size() * (width + 16) / 2.0 + i * (width + 16), 464, width, 156), pick_option.bind(options[i]))
		draw_option(b, options[i])
		b.set_meta("value", options[i])
		choices.append(b)

func draw_option(b: Button, value: Variant) -> void:
	if value is Array:
		var items: Array = value
		if value.size() == 2 and (value[1] is int or value[1] is float):
			items = copies(value[0], int(value[1]))
		picture_row(items, Rect2(Vector2(7, 7), b.size - Vector2(14, 14)), b)
	elif sprite(str(value)) and lesson.task != "label":
		b.icon = sprite(str(value))
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", 122)
	else:
		b.text = str(value)
		b.add_theme_font_size_override("font_size", 33)

func pick_option(value: Variant) -> void:
	if finished:
		return
	if lesson.task == "layout":
		selected_item = str(value)
		for choice in choices:
			choice.modulate = Color("#ffdc99") if choice.get_meta("value") == value else Color.WHITE
		return
	if lesson.task == "repair" and not marked.has(lesson.position):
		return
	if value != lesson.target:
		try_again()
		return
	for choice in choices:
		choice.disabled = true
		if choice.get_meta("value") != value:
			choice.hide()
		else:
			choice.add_theme_stylebox_override("disabled", $Listen.get_theme_stylebox("normal"))
			choice.add_theme_color_override("font_disabled_color", Color("#315548"))
			pulse(choice)
	if lesson.task in ["pattern", "repair"]:
		focus_item.hide()
		var result := picture(str(value), focus_item.get_rect().grow(-10))
		pulse(result)
	if lesson.task == "observe":
		focus_item.hide()
		pulse(picture(str(value), Rect2(719, 279, 196, 155)))
	elif lesson.task == "label":
		pulse(caption(str(value), Rect2(720, 395, 192, 58)))
	complete()

func build_catalog_trace() -> void:
	var original: String = lesson.item
	if not original.is_empty() and int(lesson.count) > 0:
		picture_row(copies(original, int(lesson.count)), Rect2(427, 360, 217, 155))
	elif not original.is_empty():
		picture(original, Rect2(450, 324, 172, 193))
	else:
		caption(lesson.target, Rect2(454, 354, 178, 156))
	trace = TraceTwo.new()
	trace.glyph = lesson.target
	trace.forgiving = age <= 3
	trace.paper = $Listen.get_theme_stylebox("normal")
	put(trace, Rect2(659, 292, 532, 349))
	trace.completed.connect(writing_done)
	help_button = card("함께 쓰기", Rect2(438, 565, 210, 72), trace.help_section)
	help_button.add_theme_font_size_override("font_size", 26)

func build_dots() -> void:
	var n: int = int(lesson.target)
	for i in n:
		var x := 818.0 - n * 110.0 + i * 220
		picture(lesson.item, Rect2(x+25, 298, 160, 160))
		target_slots.append(card("○", Rect2(x+32, 470, 146, 125), stamp.bind(i)))

func stamp(i: int) -> void:
	if finished or marked.has(i):
		return
	marked[i] = true
	target_slots[i].text = "●"
	pulse(target_slots[i])
	play_cue($Chime, POP)
	if marked.size() == target_slots.size():
		complete()

func build_fill() -> void:
	item_total = int(lesson.start)
	source_count = int(lesson.available)
	order_line = caption("", Rect2(495, 295, 239, 76))
	order_line.add_theme_font_size_override("font_size", 27)
	picture_row(copies(lesson.item, int(lesson.target)), Rect2(772, 294, 370, 79))
	container = card("", Rect2(485, 398, 280, 156), take_out)
	container.icon = sprite("bag" if lesson.vessel == "봉투" else "basket")
	container.expand_icon = true
	container.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_theme_constant_override("icon_max_width", 153)
	stock = card("", Rect2(885, 398, 269, 156), add_one)
	stock_line = caption("", Rect2(917, 569, 207, 70))
	stock_line.add_theme_font_size_override("font_size", 25)
	confirm_fill = card("다 담았어", Rect2(494, 570, 262, 69), submit_fill)
	confirm_fill.add_theme_font_size_override("font_size", 28)
	refresh_fill()

func refresh_fill() -> void:
	var target: int = int(lesson.target)
	order_line.text = "%s   %d / %d" % [lesson.vessel, item_total, target]
	stock_line.text = "남은 것  %d" % source_count
	stock.disabled = source_count == 0
	container.disabled = item_total == 0
	for holder in [container, stock]:
		for child in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	if item_total > 0:
		picture_row(copies(lesson.item, item_total), Rect2(12, 12, 256, 65), container)
	if source_count > 0:
		picture_row(copies(lesson.item, source_count), Rect2(12, 8, 245, 140), stock)

func add_one() -> void:
	if finished or source_count == 0:
		return
	item_total += 1
	source_count -= 1
	refresh_fill()
	pulse(container)
	play_cue($Chime, POP)
	if item_total == int(lesson.target) and (age == 2 or kind == "F4-M1"):
		submit_fill()

func take_out() -> void:
	if finished or item_total == 0:
		return
	item_total -= 1
	source_count += 1
	refresh_fill()

func submit_fill() -> void:
	if item_total == int(lesson.target):
		complete()
	else:
		$Prompt.text = "조금 더 담아 볼까?" if item_total < int(lesson.target) else "눌러서 한 개씩 빼 봐."
		try_again()

func build_layout() -> void:
	var step := 216
	var x: float = 818.0 - lesson.row.size() * step / 2.0
	for i in lesson.row.size():
		var shift := Vector2(0, 66 * i) if lesson.vertical else Vector2(step * i, 0)
		picture(lesson.row[i], Rect2(Vector2(x, 270) + shift, Vector2(98, 98)))
		shift = Vector2(75, 66 * i) if lesson.vertical else Vector2(step * i + 112, 0)
		target_slots.append(card("□", Rect2(Vector2(x, 282) + shift, Vector2(86, 85)), place_item.bind(i)))
	if lesson.row.size() == 1 and lesson.vertical:
		target_slots.append(card("□", Rect2(x+75, 355, 86, 85), place_item.bind(1)))
	build_catalog_options()

func place_item(i: int) -> void:
	if finished or selected_item.is_empty() or marked.has(i):
		return
	if i >= lesson.row.size() or selected_item != lesson.row[i]:
		try_again()
		return
	marked[i] = true
	draw_option(target_slots[i], selected_item)
	pulse(target_slots[i])
	if marked.size() == lesson.row.size():
		complete()

func build_repair() -> void:
	picture_row(lesson.row, Rect2(472, 286, 690, 79))
	var left: float = 818.0 - lesson.row.size() * 105 / 2
	for i in lesson.broken.size():
		var b := card("", Rect2(left + i * 105, 365, 99, 85), find_wrong.bind(i))
		draw_option(b, lesson.broken[i])
		target_slots.append(b)
	build_catalog_options()
	for b in choices:
		b.hide()

func find_wrong(i: int) -> void:
	if finished or marked.has(lesson.position):
		return
	if i != int(lesson.position):
		try_again()
		return
	marked[lesson.position] = true
	focus_item = target_slots[i]
	focus_item.icon = null
	focus_item.text = "?"
	for b in choices:
		b.show()
	$Prompt.text = "제자리에 올 그림을 골라 봐."

func show_help() -> void:
	if finished:
		return
	helped = true
	if lesson.task in ["listen", "listen_bundles"]:
		if focus_item.get_child_count() == 0 and focus_item.icon == null:
			draw_option(focus_item, lesson.target)
		$Prompt.text = "그림과 같은 것을 찾아봐."
	elif lesson.task == "trace":
		trace.replay_guide()
	elif quantity_task:
		pulse(stock if item_total < int(lesson.target) else container)
	elif lesson.task in ["layout", "repair", "dots"]:
		for slot in target_slots:
			pulse(slot)
	elif lesson.task == "observe" and focus_item:
		var correct_texture: Texture2D = sprite(lesson.target)
		if focus_item.texture != correct_texture:
			var fade := create_tween()
			fade.tween_property(focus_item, "modulate:a", 0.0, 0.17)
			fade.tween_callback(func(): focus_item.texture = correct_texture)
			fade.tween_property(focus_item, "modulate:a", 1.0, 0.22)
	elif focus_item:
		pulse(focus_item)
	elif task_board:
		pulse(task_board)

func try_again() -> void:
	show_help()
	play_line("hint")

func repeat_line() -> void:
	if kind == "catalog_end":
		play_line("done")
	elif finished:
		play_line("done")
	else:
		if not sound_on and lesson.task in ["listen", "listen_bundles"]:
			show_help()
		play_line(lesson.get("voice", kind))

func demonstrate() -> void:
	if not lesson.is_empty() and not sound_on and lesson.task in ["listen", "listen_bundles"]:
		show_help()
	elif is_instance_valid(trace):
		trace.replay_guide()

func complete() -> void:
	if finished:
		return
	finished = true
	$Order.text = "잘했어! 함께 마쳤네."
	$Momo.texture = CHEER
	pulse($Momo)
	play_cue($Done, JINGLE)
	play_line("done")
	$Prompt.hide()
	$PromptCard.hide()
	$Replay.show()

func play_line(key: String) -> void:
	stop_voice()
	if not sound_on:
		return
	var wav := "res://sound/catalog/" + key + ".wav"
	if ResourceLoader.exists(wav):
		play_cue($Voice, load(wav))

func _input(event: InputEvent) -> void:
	if not quantity_task or finished or not is_instance_valid(stock) or not event is InputEventMouse:
		return
	var point: Vector2 = make_input_local(event).position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and source_count > 0 and stock.get_rect().has_point(point):
			grab_source = stock
			grab_start = point
		elif not event.pressed and grab_source:
			var should_add: bool = not event.canceled and (container.get_rect().grow(24).has_point(point) or point.distance_to(grab_start) < 18)
			reset_drag()
			if should_add:
				add_one()
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventMouseMotion and grab_source and point.distance_to(grab_start) >= 18:
		if not moving:
			moving = picture(lesson.item, Rect2(point - Vector2(54, 54), Vector2(108, 108)))
			moving.z_index = 5
		moving.position = point - moving.size / 2
	if grab_source:
		get_viewport().set_input_as_handled()

func reset_drag() -> void:
	grab_source = null
	if is_instance_valid(moving):
		moving.hide()
		moving.queue_free()
		moving = null
