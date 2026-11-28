extends Control

const Market := preload("res://market.tscn")
const Card := preload("res://fruit_card.tscn")
const Subjects := preload("res://subject_card.tscn")
const BANK := preload("res://subject_cards.json")
const FIRST := ["word", "count", "english", "observe", "pattern"]
const ROUTES := ["hangul", "english", "numbers", "shop"]
var save_path := "user://fruit_round.cfg"
var audio_path := "user://preferences.cfg"
var deck: Array = []
var results: Array = []
var index := 0
var number := 0
var route := "shop"
var writing_only := false
var saved := ConfigFile.new()
var page
var at_home := false
var pause_button: Button
var mode_button: Button
var menu: ColorRect

func _ready() -> void:
	get_tree().quit_on_go_back = false
	saved.load(save_path)
	# 0.5 stored only the fruit shop. Keep that section as its live save slot.
	open_card(true)

func section(chosen: String, writing: bool) -> String:
	if chosen == "shop":
		return "round"
	return chosen + ("_writing" if writing else "_play")

func start_route(chosen: String, writing := false) -> void:
	if chosen not in ROUTES:
		return
	route = chosen
	writing_only = writing and route != "shop"
	var slot := section(route, writing_only)
	var stored = saved.get_value(slot, "deck", [])
	var history = saved.get_value(slot, "results", [])
	number = maxi(0, int(saved.get_value(slot, "number", 0)))
	if valid_deck(stored, history):
		deck = stored.duplicate()
		results = history.duplicate(true)
		index = results.size()
		if index < deck.size():
			save_progress()
			open_card()
			return
		number += 1
	else:
		deck = []
	new_round()

func valid_deck(stored: Variant, history: Variant) -> bool:
	var length := 5 if route == "shop" else 3
	if not stored is Array or not history is Array or stored.size() != length or history.size() > length:
		return false
	for i in stored.size():
		var key = stored[i]
		if not key is String or stored.count(key) != 1:
			return false
		if route == "shop":
			if key not in FIRST and key != "trace":
				return false
		elif not BANK.data.has(key) or BANK.data[key].subject != route or (writing_only and BANK.data[key].task != "write"):
			return false
		if i < history.size():
			var result = history[i]
			if not result is Dictionary or result.get("kind") != key or result.get("outcome") not in ["direct", "helped", "skipped"]:
				return false
	return true

func new_round() -> void:
	var last_first: String = "" if deck.is_empty() else str(deck.front())
	if route == "shop":
		deck = FIRST.duplicate()
		if number % 2 == 1:
			deck[1] = "trace"
	else:
		var groups := {}
		for key in BANK.data:
			var entry: Dictionary = BANK.data[key]
			if entry.subject != route:
				continue
			if not groups.has(entry.task):
				groups[entry.task] = []
			groups[entry.task].append(key)
		deck = []
		if writing_only:
			deck = groups.write.duplicate()
		else:
			for task in groups:
				var candidates: Array = groups[task]
				deck.append(candidates[number % candidates.size()])
	if number > 0:
		deck.shuffle()
		if deck.front() == last_first:
			var swap = deck[1]
			deck[1] = deck[0]
			deck[0] = swap
	results = []
	index = 0
	save_progress()
	open_card()

func save_progress() -> void:
	var slot := section(route, writing_only)
	saved.set_value(slot, "deck", deck)
	saved.set_value(slot, "number", number)
	saved.set_value(slot, "index", results.size())
	saved.set_value(slot, "results", results)
	saved.set_value("menu", route, writing_only)
	saved.save(save_path)

func pick_route(chosen: String) -> void:
	start_route(chosen, saved.get_value("menu", chosen, false))

func switch_mode() -> void:
	start_route(route, not writing_only)

func open_card(show_home := false) -> void:
	at_home = show_home
	for button in [pause_button, mode_button]:
		if is_instance_valid(button):
			remove_child(button)
			button.queue_free()
	pause_button = null
	mode_button = null
	if is_instance_valid(page):
		var replay: Button = page.get_node("Replay")
		if replay.visibility_changed.is_connected(record_completion):
			replay.visibility_changed.disconnect(record_completion)
		page.stop_voice()
		page.get_node("Chime").stop()
		page.get_node("Done").stop()
		remove_child(page)
		page.queue_free()
	if at_home:
		page = Subjects.instantiate()
		page.kind = "hub"
		for chosen in ROUTES:
			var slot := section(chosen, saved.get_value("menu", chosen, false))
			var length := 5 if chosen == "shop" else 3
			if saved.has_section(slot) and int(saved.get_value(slot, "index", 0)) < length:
				page.resume_routes.append(chosen)
		page.preferences_path = audio_path
		page.route_selected.connect(pick_route)
		add_child(page)
		return
	var is_end := index == deck.size()
	var key: String = "end" if is_end else str(deck[index])
	if route != "shop":
		page = Subjects.instantiate()
		page.kind = "subject_end" if is_end else key
		page.subject = route
	elif key == "count":
		page = Market.instantiate()
	else:
		page = Card.instantiate()
		page.kind = key
	page.in_round = true
	page.preferences_path = audio_path
	if key != "count":
		page.swap_options = (index + number) % 2 == 1
		for item in results:
			if item.outcome != "skipped":
				page.prizes.append(item.kind)
	add_child(page)
	page.advance_requested.connect(advance)
	if is_end:
		pause_button = make_button("놀이 선택", Rect2(341, 27, 185, 60), enter_home)
	else:
		page.get_node("Speaker").text = "%s     %d / %d" % ["모모의 주문" if route == "shop" else "모모", index + 1, deck.size()]
		page.get_node("Replay").visibility_changed.connect(record_completion)
		if index == deck.size() - 1:
			page.get_node("Replay").text = "진열대 보기  →" if route == "shop" else "놀이 마치기  →"
		pause_button = make_button("Ⅱ   잠깐 쉬기", Rect2(341, 27, 185, 60), pause_round)
	add_child(pause_button)
	if route != "shop":
		mode_button = make_button("세 장 놀기" if writing_only else "따라 쓰기", Rect2(551, 27, 175, 60), switch_mode)
		add_child(mode_button)

func record_completion() -> void:
	if index >= deck.size() or results.size() != index or not page.get_node("Replay").visible:
		return
	var assistance: bool = deck[index] != "count" and page.helped
	results.append({"kind": deck[index], "outcome": "helped" if assistance else "direct"})
	save_progress()

func advance() -> void:
	if index == deck.size():
		number += 1
		new_round()
		return
	record_completion()
	index += 1
	open_card()

func make_button(caption: String, bounds: Rect2, action: Callable) -> Button:
	var button: Button = page.get_node("Listen").duplicate(0)
	button.theme = page.theme
	button.text = caption
	button.position = bounds.position
	button.size = bounds.size
	button.pressed.connect(action)
	return button

func pause_round() -> void:
	if is_instance_valid(menu) or index >= deck.size():
		return
	page.stop_voice()
	page.get_node("Chime").stop()
	page.get_node("Done").stop()
	page.cancel_hold()
	if page.has_method("reset_drag"):
		page.reset_drag()
	get_tree().paused = true
	menu = ColorRect.new()
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	menu.color = Color(0.12, 0.20, 0.18, 0.71)
	menu.size = size
	add_child(menu)
	menu.add_child(make_button("계속 놀기   ▶", Rect2(453, 233, 374, 86), resume_round))
	menu.add_child(make_button("다음 주문으로   →" if route == "shop" else "다음 놀이로   →", Rect2(453, 354, 374, 86), skip_card))
	menu.add_child(make_button("놀이 선택", Rect2(453, 475, 374, 86), enter_home))

func enter_home() -> void:
	if is_instance_valid(menu):
		close_menu()
	index = results.size()
	open_card(true)

func resume_round() -> void:
	close_menu()
	page.repeat_line()

func close_menu() -> void:
	if not is_instance_valid(menu):
		return
	remove_child(menu)
	menu.queue_free()
	menu = null
	get_tree().paused = false

func skip_card() -> void:
	if results.size() == index:
		results.append({"kind": deck[index], "outcome": "skipped"})
		save_progress()
	close_menu()
	advance()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		if is_instance_valid(menu):
			resume_round()
		elif at_home:
			get_tree().quit()
		elif index < deck.size():
			pause_round()
		else:
			enter_home()
