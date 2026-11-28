extends SceneTree

const Round := preload("res://round.tscn")
const Card := preload("res://catalog_card.tscn")
const Deck := preload("res://round_deck.gd")
var failures := 0
var save := "user://catalog_test_%d.cfg" % OS.get_process_id()
var preferences := "user://catalog_audio_%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, context: String) -> void:
	if not ok:
		failures += 1
		push_error(context)

func tap(node: Control) -> void:
	var position := node.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.pressed = down
		event.button_index = MOUSE_BUTTON_LEFT
		root.push_input(event, true)

func drag(src: Control, dst: Control) -> void:
	var origin := src.get_global_rect().get_center()
	var end := dst.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.position = origin
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down, true)
	var motion := InputEventMouseMotion.new()
	motion.position = end
	motion.relative = end - origin
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	var up := InputEventMouseButton.new()
	up.position = end
	up.button_index = MOUSE_BUTTON_LEFT
	root.push_input(up, true)

func trace_strokes(p) -> void:
	var pad = p.trace
	for stroke in pad.strokes:
		var down := InputEventMouseButton.new()
		down.position = pad.global_position + stroke[0]
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		root.push_input(down, true)
		for point in stroke:
			var motion := InputEventMouseMotion.new()
			motion.position = pad.global_position + point
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(motion, true)
		var up := InputEventMouseButton.new()
		up.position = pad.global_position + stroke[-1]
		up.button_index = MOUSE_BUTTON_LEFT
		root.push_input(up, true)

func solve(p) -> void:
	var lesson: Dictionary = p.lesson
	match lesson.task:
		"fill":
			if p.kind != "F4-M1" and int(lesson.available) > int(lesson.target) - int(lesson.start):
				for i in int(lesson.target) - int(lesson.start) + 1:
					tap(p.stock)
				tap(p.confirm_fill)
				check(not p.finished, p.kind + " overfilled")
				tap(p.container)
			else:
				drag(p.stock, p.container)
				for i in int(lesson.target) - int(lesson.start) - 1:
					tap(p.stock)
			if not p.finished:
				tap(p.confirm_fill)
		"trace":
			var count: int = p.trace.strokes.size()
			if p.kind in ["F5-K2", "B5-K2", "W5-E1", "W5-M2"]:
				trace_strokes(p)
				check(not p.helped and count > 1, p.kind + " direct multi-stroke tracing")
			else:
				for i in range(count * 6):
					if p.finished:
						break
					tap(p.help_button)
				check(p.helped and count > 0, p.kind + " tracing assistance")
		"dots":
			for slot in p.target_slots:
				tap(slot)
		"layout":
			for i in lesson.row.size():
				tap(find_choice(p, lesson.row[i]))
				tap(p.target_slots[i])
		"repair":
			tap(p.target_slots[0])
			check(not p.finished, p.kind + " wrong repair accepted")
			tap(p.target_slots[int(lesson.position)])
			tap(find_choice(p, lesson.target))
		_:
			for b in p.choices:
				if b.get_meta("value") != lesson.target:
					tap(b)
					break
			check(not p.finished, p.kind + " wrong choice accepted")
			tap(find_choice(p, lesson.target))
	check(p.finished and p.get_node("Replay").visible, p.kind + " did not complete")

func find_choice(p, value: Variant) -> Button:
	for b in p.choices:
		if b.get_meta("value") == value:
			return b
	return null

func run() -> void:
	var game = Round.instantiate()
	game.save_path = save
	game.audio_path = preferences
	root.add_child(game)
	await process_frame
	check(game.chosen_age == 0 and game.profile.onboarding and game.page.route_buttons.shop.disabled, "First-run age selection missing")
	tap(game.profile.get_child(0 + 1))
	check(game.chosen_age == 2 and game.page.route_buttons.size() == 5, "First-run age menu failed")
	tap(game.page.route_buttons.bakery)
	check(game.active_age == 2 and game.deck.size() == 5, "Bakery route fails")
	var first: Array = game.deck.duplicate()
	solve(game.page)
	tap(game.page.get_node("Replay"))
	game.enter_home()
	tap(game.profile_button)
	tap(game.profile.get_child(4))
	tap(game.page.route_buttons.bakery)
	check(game.active_age == 2 and game.chosen_age == 5 and game.index == 1 and game.deck == first, "Age change reset an active round")
	for i in range(1, 5):
		solve(game.page)
		tap(game.page.get_node("Replay"))
	check(game.page.kind == "catalog_end" and game.history_log.size() == 1, "Bakery finish not recorded")
	tap(game.page.get_node("Replay"))
	check(game.active_age == 5 and game.deck.size() == 5, "Next round does not inherit new age")
	var restored := ConfigFile.new()
	check(restored.load(save) == OK and restored.get_value("profile", "age", 0) == 5 and restored.get_value("profile", "history", []).size() == 1, "Parent settings or history not preserved")
	game.queue_free()
	await process_frame
	var count := 0
	for id in Deck.CATALOG.data:
		var lesson: Dictionary = Deck.CATALOG.data[id]
		var p = Card.instantiate()
		p.in_round = true
		p.kind = id
		p.age = int(id[1])
		p.venue = "bakery" if id[0] == "B" else "shop"
		p.subject = p.venue
		p.preferences_path = preferences
		root.add_child(p)
		check(p.get_node("Voice").playing and ResourceLoader.exists("res://sound/catalog/" + lesson.voice + ".wav"), id + " missing voice")
		solve(p)
		p.stop_voice()
		p.get_node("Done").stop()
		p.get_node("Chime").stop()
		p.queue_free()
		await process_frame
		count += 1
		var muted := ConfigFile.new()
		muted.set_value("audio", "enabled", false)
		if count == Deck.CATALOG.data.size():
			muted.save(preferences)
	for age in range(2, 6):
		for venue in ["bakery", "shop"]:
			var seen: Array = []
			var last: Array = []
			var write_count := 0
			for visit in 3:
				var next := Deck.generate(venue, age, false, seen, last, [])
				var selected := {}
				for key in next:
					selected[Deck.identity(key)] = true
					if Deck.CATALOG.data[key].task == "trace":
						write_count += 1
					seen.erase(key)
					seen.append(key)
				check(selected.size() == 5 and write_count <= visit + 1, "Invalid mixed deck")
				if visit > 0:
					check(Deck.identity(last[0]) != Deck.identity(next[0]), "Repeated first area")
				last = next
	var silent = Card.instantiate()
	silent.kind = "B5-E1"
	silent.venue = "bakery"
	silent.subject = "bakery"
	silent.preferences_path = preferences
	root.add_child(silent)
	check(not silent.get_node("Voice").playing and silent.helped and silent.focus_item.get_child_count() > 0, "Silent English order has no clue")
	silent.queue_free()
	await create_timer(0.6).timeout
	DirAccess.remove_absolute(save)
	DirAccess.remove_absolute(preferences)
	print("Catalog cards: %d, failures: %d" % [count, failures])
	quit(1 if failures else 0)
