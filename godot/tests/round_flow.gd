extends SceneTree

var game
var failures := 0
var save_path: String
var audio_path: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func launch() -> void:
	game = preload("res://round.tscn").instantiate()
	game.save_path = save_path
	game.audio_path = audio_path
	root.add_child(game)

func button_at(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)

func move_to(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)

func tap(node: Control) -> void:
	var point := node.get_global_rect().get_center()
	button_at(point, true)
	button_at(point, false)

func option(key: String) -> Button:
	for btn in game.page.choices:
		if btn.get_meta("key") == key:
			return btn
	return null

func play_card(key: String) -> void:
	var pg = game.page
	match key:
		"word":
			tap(option("사과"))
			check(not pg.finished, "Wrong label advanced")
			tap(option("배"))
		"count":
			tap(pg.get_node("Apple1"))
			tap(pg.get_node("Apple2"))
			await create_timer(1.8).timeout
		"english":
			check(pg.focus_item.icon == null, "English answer revealed before listening")
			tap(pg.get_node("Sound"))
			check(not pg.get_node("Voice").playing and pg.focus_item.icon != null, "Muted English needs picture support")
			tap(option("banana"))
			tap(pg.get_node("Sound"))
		"observe": tap(option("orange"))
		"pattern":
			var choice := option("pear")
			button_at(choice.get_global_rect().get_center(), true)
			move_to(Vector2(100, 400))
			button_at(Vector2(100, 400), false)
			check(not pg.finished, "Drop outside slot accepted")
			var dest: Vector2 = pg.focus_item.get_global_rect().get_center()
			button_at(choice.get_global_rect().get_center(), true)
			move_to(dest)
			button_at(dest, false)
		"trace":
			var pad = pg.trace
			var start: Vector2 = pad.global_position
			button_at(start + pad.path[0], true)
			move_to(start + pad.path[-1])
			button_at(start + pad.path[-1], false)
			check(not pg.finished, "Endpoint shortcut accepted")
			button_at(start + pad.path[0], true)
			for i in range(1, pad.path.size() / 2):
				move_to(start + pad.path[i])
			button_at(start + pad.path[pad.drawn], false)
			var mark: int = pad.drawn
			check(mark > 4 and mark < pad.path.size() - 1, "Partial ink lost")
			button_at(start + pad.path[mark], true)
			for i in range(mark, pad.path.size()):
				move_to(start + pad.path[i])
			button_at(start + pad.path[-1], false)
			check(not pg.helped, "Independent tracing counted as assisted")
	check(pg.get_node("Replay").visible, "Missing completion for " + key)

func run() -> void:
	var suffix := str(OS.get_process_id())
	save_path = "user://test_round_" + suffix + ".cfg"
	audio_path = "user://test_audio_" + suffix + ".cfg"
	launch()
	await process_frame
	check(game.at_home and game.page.route_buttons.size() == 4, "Missing four choices")
	tap(game.page.route_buttons.shop)
	check(game.deck == game.FIRST and game.page.sound_on and game.page.get_node("Voice").playing, "First launch order or voice")
	tap(game.pause_button)
	check(paused and game.menu.visible, "Pause overlay")
	tap(game.menu.get_child(0))
	check(not paused, "Resume")
	var first: Array = game.deck.duplicate()
	for i in 5:
		await play_card(first[i])
		check(game.results.size() == i + 1, "Outcome must be stored exactly once")
		if i == 0:
			game.queue_free()
			await process_frame
			launch()
			await process_frame
			tap(game.page.route_buttons.shop)
			check(game.index == 1 and game.deck == first, "Restart lost progress")
		else:
			tap(game.page.get_node("Replay"))
		await process_frame
	check(game.page.kind == "end" and game.page.prizes.size() == 5, "Missing prize shelf")
	tap(game.page.get_node("Replay"))
	check(game.deck.has("trace") and not game.deck.has("count") and game.deck[0] != first[0], "Second round variety")
	var second: Array = game.deck.duplicate()
	for key in second:
		await play_card(key)
		tap(game.page.get_node("Replay"))
		await process_frame
	check(game.index == 5 and game.page.kind == "end", "Second shelf unreachable")
	tap(game.page.get_node("Replay"))
	tap(game.pause_button)
	tap(game.menu.get_child(1))
	check(game.index == 1 and game.results[0].outcome == "skipped", "Skip counted as direct")
	game.enter_home()
	check(game.at_home and game.page.route_buttons.shop.text.contains("이어서"), "Entrance should offer resume")
	tap(game.page.route_buttons.shop)
	check(game.index == 1 and not game.at_home, "Entrance resume failed")
	game.queue_free()
	await process_frame
	var assisted = preload("res://fruit_card.tscn").instantiate()
	assisted.kind = "trace"
	assisted.preferences_path = audio_path
	root.add_child(assisted)
	for i in 3:
		tap(assisted.help_button)
	check(assisted.finished and assisted.helped, "Tap-only tracing did not complete as assisted")
	assisted.queue_free()
	await process_frame
	await create_timer(0.7).timeout
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(audio_path)
	print("Fruit round flow: %d failures" % failures)
	quit(1 if failures else 0)
