extends SceneTree

const Round := preload("res://round.tscn")
var game
var failures := 0
var save_path := "user://routes_test_%s.cfg" % OS.get_process_id()
var audio_path := "user://routes_audio_%s.cfg" % OS.get_process_id()

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		push_error(msg)

func launch() -> void:
	game = Round.instantiate()
	game.save_path = save_path
	game.audio_path = audio_path
	root.add_child(game)

func button(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = pos
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	root.push_input(ev, true)

func tap(node: Control) -> void:
	var pos := node.get_global_rect().get_center()
	button(pos, true)
	button(pos, false)

func finish_card() -> void:
	var p = game.page
	check(p.lesson.subject == game.route and p.sound_on and p.get_node("Voice").playing, "Subject or sound mismatch")
	if p.lesson.task == "write":
		var pad = p.trace
		button(pad.global_position + pad.path[0], true)
		for point in pad.path:
			var ev := InputEventMouseMotion.new()
			ev.position = pad.global_position + point
			ev.button_mask = MOUSE_BUTTON_MASK_LEFT
			root.push_input(ev, true)
		button(pad.global_position + pad.path[-1], false)
	else:
		for choice in p.choices:
			if choice.get_meta("key") == p.lesson.target:
				tap(choice)
	check(p.finished, "Cannot solve " + p.kind)
	tap(p.get_node("Replay"))

func run() -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("round", "number", 0)
	legacy.set_value("round", "deck", ["word", "count", "english", "observe", "pattern"])
	legacy.set_value("round", "results", [{"kind":"word","outcome":"direct"}])
	legacy.set_value("round", "index", 1)
	legacy.save(save_path)
	launch()
	await process_frame
	check(game.page.route_buttons.size() == 4 and game.page.sound_on, "Direct menu or initial sound")
	tap(game.page.route_buttons.hangul)
	finish_card()
	var pending: String = game.deck[game.index]
	tap(game.pause_button)
	tap(game.menu.get_child(2))
	tap(game.page.route_buttons.english)
	check(game.index == 0 and game.route == "english", "Routes share progress")
	finish_card()
	game.queue_free()
	await process_frame
	launch()
	await process_frame
	tap(game.page.route_buttons.shop)
	check(game.index == 1 and game.deck[1] == "count", "0.5 save was overwritten")
	game.enter_home()
	tap(game.page.route_buttons.hangul)
	check(game.index == 1 and game.page.kind == pending, "Subject did not resume after relaunch")
	game.enter_home()
	for route in ["hangul", "english", "numbers"]:
		tap(game.page.route_buttons[route])
		var first: Array = game.deck.duplicate()
		for i in range(game.index, 3):
			finish_card()
		check(game.page.kind == "subject_end", "Subject lacks finish")
		tap(game.page.get_node("Replay"))
		check(game.deck != first and game.deck[0] != first[0], "Replay variation")
		for i in 3:
			finish_card()
		tap(game.mode_button)
		check(game.writing_only and game.deck.size() == 3, "Writing shelf missing")
		for i in 3:
			check(game.page.lesson.task == "write", "Writing route has wrong task")
			finish_card()
		tap(game.pause_button)
		check(game.at_home, "Cannot leave subject summary")
	game.queue_free()
	await create_timer(0.75).timeout
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(audio_path)
	print("Independent subject routes: %d failures" % failures)
	quit(1 if failures else 0)
