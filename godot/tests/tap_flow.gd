extends SceneTree

var scene: Control
var failures := 0
var spoken: Array[String] = []
var audio_path := "user://test_market_audio_" + str(OS.get_process_id()) + ".cfg"

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func tap(node: Control) -> void:
	var center := node.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)

func drag(from: Vector2, to: Vector2, cancel: bool = false) -> void:
	var down := InputEventMouseButton.new()
	down.position = from
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down, true)
	var move := InputEventMouseMotion.new()
	move.position = to
	move.relative = to - from
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move, true)
	var up := InputEventMouseButton.new()
	up.position = to
	up.button_index = MOUSE_BUTTON_LEFT
	up.canceled = cancel
	root.push_input(up, true)

func note_playing_voice() -> void:
	if is_instance_valid(scene):
		var voice: AudioStreamPlayer = scene.get_node("Voice")
		if voice.playing and not spoken.has(voice.stream.resource_path):
			spoken.append(voice.stream.resource_path)

func run() -> void:
	scene = load("res://market.tscn").instantiate()
	scene.preferences_path = audio_path
	root.add_child(scene)
	await process_frame
	process_frame.connect(note_playing_voice)
	tap(scene.get_node("Apple1"))
	tap(scene.get_node("Apple1"))
	await create_timer(0.6).timeout
	check(scene.get_node("Count").text.ends_with("1 / 2"), "Repeated tap counted twice")
	tap(scene.get_node("Apple2"))
	await create_timer(1.7).timeout
	check(scene.get_node("Count").text.ends_with("2 / 2"), "Second apple missing")
	check(scene.get_node("Replay").is_visible_in_tree(), "Completion not reachable")
	tap(scene.get_node("Replay"))
	check(scene.get_node("Count").text.ends_with("0 / 2"), "Replay did not reset")
	tap(scene.get_node("Apple2"))
	tap(scene.get_node("Apple1"))
	await create_timer(2.8).timeout
	check(scene.get_node("Replay").visible and scene.landed.size() == 2, "Rapid taps lost")
	check(spoken.has("res://sound/voice_one.wav") and spoken.has("res://sound/voice_two.wav"), "Count audio did not play")
	tap(scene.get_node("Replay"))
	tap(scene.get_node("Crate"))
	await create_timer(0.55).timeout
	check(scene.landed.size() == 1, "Small crate target did not work")
	tap(scene.get_node("Sound"))
	tap(scene.get_node("Listen"))
	check(not scene.get_node("Voice").playing, "Muted replay spoke")
	tap(scene.get_node("Sound"))
	check(scene.get_node("Voice").playing, "Unmuting did not give the hint")
	if scene.get_node("Voice").playing:
		await scene.get_node("Voice").finished
	await process_frame
	tap(scene.get_node("Sound"))
	var restarted: Control = load("res://market.tscn").instantiate()
	scene.queue_free()
	await process_frame
	restarted.preferences_path = audio_path
	root.add_child(restarted)
	scene = restarted
	check(not scene.sound_on and not scene.get_node("Chime").playing and not scene.get_node("Voice").playing, "Muted launch made sound")
	check(scene.get_node("Demo").visible and scene.get_node("OrderApple2").visible, "Missing visual order")
	var start := scene.get_node("Apple1").get_global_rect().get_center() as Vector2
	var basket := scene.get_node("Basket").get_global_rect().get_center() as Vector2
	drag(start, Vector2(320,320))
	check(scene.selected.is_empty() and scene.get_node("Apple1").get_global_rect().has_point(start), "Missed drop did not return")
	drag(start, basket, true)
	check(scene.selected.is_empty(), "Canceled drop counted")
	drag(start, basket)
	await create_timer(0.6).timeout
	check(scene.landed.size() == 1, "Basket drop failed")
	tap(scene.get_node("Listen"))
	check(scene.get_node("Demo").visible and not scene.get_node("Voice").playing, "Silent help failed")
	tap(scene.get_node("Apple2"))
	await create_timer(1.5).timeout
	check(scene.finished and scene.get_node("Replay").visible and not scene.get_node("Done").playing, "Silent mixed-input round failed")
	tap(scene.get_node("Replay"))
	tap(scene.get_node("Sound"))
	scene.stop_voice()
	print("Apple market tap and drop flow: %d failures" % failures)
	scene.queue_free()
	await process_frame
	process_frame.disconnect(note_playing_voice)
	await create_timer(0.7).timeout
	DirAccess.remove_absolute(audio_path)
	quit(1 if failures else 0)
