extends SceneTree

var scene: Control
var failures := 0

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

func run() -> void:
	scene = load("res://market.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var spoken: Array[String] = []
	scene.get_node("Voice").finished.connect(func() -> void:
		spoken.append(scene.get_node("Voice").stream.resource_path)
	)
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
	print("Apple market tap flow: %d failures" % failures)
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
