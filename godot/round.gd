extends Control

const Market := preload("res://market.tscn")
const Card := preload("res://fruit_card.tscn")
var save_path := "user://fruit_round.cfg"
var audio_path := "user://preferences.cfg"
const FIRST := ["word", "count", "english", "observe", "pattern"]
var deck: Array
var results: Array
var index := 0
var number := 0
var saved := ConfigFile.new()
var page
var at_home := false
var pause_button: Button
var menu: ColorRect

func _ready() -> void:
	get_tree().quit_on_go_back = false
	saved.load(save_path)
	number = maxi(0, saved.get_value("round", "number", 0))
	deck = saved.get_value("round", "deck", [])
	results = saved.get_value("round", "results", [])
	index = saved.get_value("round", "index", 0)
	if deck.size() != 5 or index < 0 or index > 5 or results.size() != index:
		new_round(true)
	else:
		open_card(true)

func new_round(show_home := false) -> void:
	var last_first: String = "" if deck.is_empty() else str(deck.front())
	deck = FIRST.duplicate()
	if number % 2 == 1:
		deck[1] = "trace"
	if number > 0:
		deck.shuffle()
		if deck.front() == last_first:
			var swap = deck[1]
			deck[1] = deck[0]
			deck[0] = swap
	results = []
	index = 0
	save_progress()
	open_card(show_home)

func save_progress() -> void:
	saved.set_value("round", "deck", deck)
	saved.set_value("round", "number", number)
	saved.set_value("round", "index", results.size())
	saved.set_value("round", "results", results)
	saved.save(save_path)

func open_card(show_home := false) -> void:
	at_home = show_home
	if is_instance_valid(pause_button):
		remove_child(pause_button)
		pause_button.queue_free()
		pause_button = null
	if is_instance_valid(page):
		var replay: Button = page.get_node("Replay")
		if replay.visibility_changed.is_connected(record_completion):
			replay.visibility_changed.disconnect(record_completion)
		page.stop_voice()
		page.get_node("Chime").stop()
		page.get_node("Done").stop()
		remove_child(page)
		page.queue_free()
	var key: String = "end" if index == deck.size() else str(deck[index])
	if at_home:
		key = "home"
	page = Market.instantiate() if key == "count" else Card.instantiate()
	page.in_round = true
	page.preferences_path = audio_path
	if key != "count":
		page.kind = key
		if at_home and index > 0 and index < deck.size():
			page.home_action = "이어서 놀기  ▶"
		page.swap_options = (index + number) % 2 == 1
		page.prizes = []
		for item in results:
			if item.outcome != "skipped":
				page.prizes.append(item.kind)
	add_child(page)
	page.advance_requested.connect(advance)
	if at_home:
		return
	if key == "end":
		pause_button = make_button("가게 입구로", Rect2(341, 27, 185, 60), enter_home)
		add_child(pause_button)
		return
	page.get_node("Speaker").text = "모모의 주문     %d / 5" % (index + 1)
	page.get_node("Replay").visibility_changed.connect(record_completion)
	if index == 4:
		page.get_node("Replay").text = "진열대 보기  →"
	pause_button = make_button("Ⅱ   잠깐 쉬기", Rect2(341, 27, 185, 60), pause_round)
	add_child(pause_button)

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
	if at_home:
		open_card()
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
	menu.add_child(make_button("다음 주문으로   →", Rect2(453, 354, 374, 86), skip_card))
	menu.add_child(make_button("가게 입구로", Rect2(453, 475, 374, 86), enter_home))

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
