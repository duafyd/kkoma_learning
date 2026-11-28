extends Control

const Market := preload("res://market.tscn")
const Card := preload("res://fruit_card.tscn")
const Subjects := preload("res://subject_card.tscn")
const CatalogCard := preload("res://catalog_card.tscn")
const Deck := preload("res://round_deck.gd")
const Profile := preload("res://profile.gd")
const BANK := preload("res://subject_cards.json")
const LEGACY_SHOP := ["word", "count", "english", "observe", "pattern", "trace"]
const ROUTES := ["hangul", "english", "numbers", "shop", "bakery"]
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
var profile: Panel
var profile_button: Button
var active_age := 4
var chosen_age := 4
var history_log: Array = []

func _ready() -> void:
	get_tree().quit_on_go_back = false
	saved.load(save_path)
	# Previous versions had a single default age of four.
	var fallback := 4 if saved.has_section("round") or saved.has_section("menu") else 0
	chosen_age = clampi(int(saved.get_value("profile", "age", fallback)), 0, 5)
	if chosen_age == 1:
		chosen_age = 0
	var history = saved.get_value("profile", "history", [])
	if history is Array:
		history_log = history
	open_card(true)

func section(chosen: String, writing: bool) -> String:
	if chosen == "shop":
		return "round"
	return chosen + ("_writing" if writing else "_play")

func start_route(chosen: String, writing := false) -> void:
	if chosen not in ROUTES or chosen_age < 2:
		return
	route = chosen
	writing_only = writing and Deck.TOPICS.has(route)
	var slot := section(route, writing_only)
	var stored = saved.get_value(slot, "deck", [])
	var history = saved.get_value(slot, "results", [])
	active_age = clampi(int(saved.get_value(slot, "age", 4)), 2, 5)
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
	var length := 3 if Deck.TOPICS.has(route) else 5
	if not stored is Array or not history is Array or stored.size() != length or history.size() > length:
		return false
	for i in stored.size():
		var key = stored[i]
		if not key is String or stored.count(key) != 1 or Deck.CATALOG.data.has(key) != Deck.CATALOG.data.has(stored[0]):
			return false
		if Deck.CATALOG.data.has(key):
			var prefix := str(key).split("-")[0]
			if prefix.substr(1) != str(active_age):
				return false
			if route == "shop" and not key.begins_with("F"):
				return false
			if route == "bakery" and not key.begins_with("B"):
				return false
			if Deck.TOPICS.has(route) and (key[3] != Deck.TOPICS[route] or (writing_only and not key.begins_with("W"))):
				return false
		elif route == "shop":
			if key not in LEGACY_SHOP:
				return false
		elif not BANK.data.has(key) or BANK.data[key].subject != route or (writing_only and BANK.data[key].task != "write"):
			return false
		if i < history.size():
			var result = history[i]
			if not result is Dictionary or result.get("kind") != key or result.get("outcome") not in ["direct", "helped", "skipped"]:
				return false
	return true

func new_round() -> void:
	active_age = maxi(2, chosen_age)
	var slot := section(route, writing_only)
	var seen: Array = saved.get_value(slot, "seen", [])
	var practice: Array = saved.get_value(slot, "practice", [])
	deck = Deck.generate(route, active_age, writing_only, seen, deck, practice)
	results = []
	index = 0
	save_progress()
	open_card()

func save_progress() -> void:
	var slot := section(route, writing_only)
	saved.set_value(slot, "deck", deck)
	saved.set_value(slot, "age", active_age)
	saved.set_value("profile", "age", chosen_age)
	saved.set_value("profile", "history", history_log)
	saved.set_value(slot, "number", number)
	saved.set_value(slot, "index", results.size())
	saved.set_value(slot, "results", results)
	saved.set_value("menu", route, writing_only)
	write_save()

func write_save() -> void:
	var pending := save_path + ".tmp"
	var error := saved.save(pending)
	if error == OK:
		error = DirAccess.rename_absolute(pending, save_path)
	if error != OK:
		push_error("Could not save play progress: " + error_string(error))

func pick_route(chosen: String) -> void:
	start_route(chosen, saved.get_value("menu", chosen, false))

func switch_mode() -> void:
	start_route(route, not writing_only)

func open_card(show_home := false) -> void:
	at_home = show_home
	for button in [pause_button, mode_button, profile_button, profile]:
		if is_instance_valid(button):
			remove_child(button)
			button.queue_free()
	pause_button = null
	mode_button = null
	profile_button = null
	profile = null
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
			var length := 3 if Deck.TOPICS.has(chosen) else 5
			if saved.has_section(slot) and int(saved.get_value(slot, "index", 0)) < length:
				page.resume_routes.append(chosen)
		page.preferences_path = audio_path
		page.route_selected.connect(pick_route)
		add_child(page)
		profile_button = make_button("보호자", Rect2(341, 27, 185, 60), open_profile)
		add_child(profile_button)
		if chosen_age == 0:
			open_profile()
		return
	var is_end := index == deck.size()
	var key: String = "end" if is_end else str(deck[index])
	var catalog_round: bool = Deck.CATALOG.data.has(deck.front())
	if catalog_round:
		page = CatalogCard.instantiate()
		page.kind = "catalog_end" if is_end else key
		page.age = active_age
		page.venue = route
		page.subject = route
	elif route != "shop":
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
	if not is_end:
		remember_presented(key)
	page.advance_requested.connect(advance)
	if is_end:
		pause_button = make_button("놀이 선택", Rect2(341, 27, 185, 60), enter_home)
	else:
		page.get_node("Speaker").text = "%s     %d / %d" % ["모모의 주문" if not Deck.TOPICS.has(route) else "모모", index + 1, deck.size()]
		page.get_node("Replay").visibility_changed.connect(record_completion)
		if index == deck.size() - 1:
			page.get_node("Replay").text = "진열대 보기  →" if not Deck.TOPICS.has(route) else "놀이 마치기  →"
		pause_button = make_button("Ⅱ   잠깐 쉬기", Rect2(341, 27, 185, 60), pause_round)
	add_child(pause_button)
	if Deck.TOPICS.has(route):
		mode_button = make_button("세 장 놀기" if writing_only else "따라 쓰기", Rect2(551, 27, 175, 60), switch_mode)
		add_child(mode_button)

func remember_presented(key: String) -> void:
	var slot := section(route, writing_only)
	var seen: Array = saved.get_value(slot, "seen", [])
	seen.erase(key)
	seen.append(key)
	if seen.size() > 60:
		seen.pop_front()
	saved.set_value(slot, "seen", seen)
	save_progress()

func store_result(outcome: String) -> void:
	var key: String = deck[index]
	results.append({"kind": key, "outcome": outcome})
	var slot := section(route, writing_only)
	if outcome == "helped":
		var practice: Array = saved.get_value(slot, "practice", [])
		practice.erase(key)
		practice.append(key)
		if practice.size() > 6:
			practice.pop_front()
		saved.set_value(slot, "practice", practice)
	if results.size() == deck.size():
		var summary := {"title": page.TITLES[route] if Deck.TOPICS.has(route) or route == "bakery" else "과일 가게", "age": active_age, "direct": 0, "helped": 0, "skipped": 0}
		for result in results:
			summary[result.outcome] += 1
		history_log.append(summary)
		if history_log.size() > 30:
			history_log.pop_front()
	save_progress()

func open_profile() -> void:
	if is_instance_valid(profile):
		return
	for button in page.route_buttons.values():
		button.disabled = true
	profile_button.hide()
	profile = Profile.new()
	profile.age = chosen_age
	profile.onboarding = chosen_age == 0
	profile.history = history_log
	profile.age_changed.connect(select_age)
	profile.returned.connect(enter_home)
	add_child(profile)

func select_age(value: int) -> void:
	chosen_age = value
	saved.set_value("profile", "age", chosen_age)
	write_save()
	open_card(true)

func record_completion() -> void:
	if index >= deck.size() or results.size() != index or not page.get_node("Replay").visible:
		return
	var assistance: bool = deck[index] != "count" and page.helped
	store_result("helped" if assistance else "direct")

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
	menu.add_child(make_button("다음 주문으로   →" if not Deck.TOPICS.has(route) else "다음 놀이로   →", Rect2(453, 354, 374, 86), skip_card))
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
		store_result("skipped")
	close_menu()
	advance()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		if is_instance_valid(menu):
			resume_round()
		elif at_home:
			if is_instance_valid(profile) and chosen_age > 0:
				enter_home()
			else:
				get_tree().quit()
		elif index < deck.size():
			pause_round()
		else:
			enter_home()
