extends Control

const APPLE := preload("res://art/apple.svg")
const POP := preload("res://sound/place.wav")
const JINGLE := preload("res://sound/finish.wav")
const DOORBELL := preload("res://sound/door.wav")
const WAVE := preload("res://art/fox.webp")
const CHEER := preload("res://art/cheer.webp")
const ORDER := "사과 두 개를 담아 줘!"
const WORDS := ["하나!", "둘!"]
const VOICES := {
	ORDER: preload("res://sound/voice_order.wav"),
	"하나!": preload("res://sound/voice_one.wav"),
	"둘!": preload("res://sound/voice_two.wav"),
	"사과 하나 더 담아 볼까?": preload("res://sound/voice_hint.wav"),
	"사과 두 개, 고마워!": preload("res://sound/voice_thanks.wav")
}
var voice_queue: Array[AudioStream] = []
const TARGETS := [Vector2(479, 485), Vector2(571, 484)]

@onready var apples: Array[TextureButton] = [$Apple1, $Apple2]
var selected: Array[int] = []
var landed: Array[TextureRect] = []
var delivering := false
var sound_on := true
var finished := false
var reaction: Tween
var idle: Tween

func _ready() -> void:
	for i in apples.size():
		apples[i].pressed.connect(choose.bind(i))
	$Listen.pressed.connect(repeat_line)
	$Sound.pressed.connect(toggle_sound)
	$Replay.pressed.connect(begin)
	$Voice.finished.connect(play_next_voice)
	$Crate.pressed.connect(choose_next)
	idle = create_tween().set_loops()
	idle.tween_property($Momo, "rotation", 0.016, 1.3).set_trans(Tween.TRANS_SINE)
	idle.tween_property($Momo, "rotation", -0.012, 1.3).set_trans(Tween.TRANS_SINE)
	begin()

func begin() -> void:
	$Momo.texture = WAVE
	selected.clear()
	for fruit in landed:
		fruit.queue_free()
	landed.clear()
	finished = false
	for button in apples:
		button.disabled = false
		button.show()
	$Replay.hide()
	$PromptCard.show()
	$Prompt.show()
	$Order.text = ORDER
	$Count.text = "바구니  0 / 2"
	$Prompt.text = "사과를 톡 눌러 봐!"
	play_cue($Chime, DOORBELL)
	repeat_line()

func choose_next() -> void:
	for i in apples.size():
		if not selected.has(i):
			choose(i)
			return

func choose(which: int) -> void:
	if finished or selected.has(which):
		return
	selected.append(which)
	apples[which].disabled = true
	if not delivering:
		deliver()

func deliver() -> void:
	delivering = true
	while landed.size() < selected.size():
		var slot := landed.size()
		var source := apples[selected[slot]]
		var fruit := TextureRect.new()
		fruit.texture = APPLE
		fruit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fruit.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fruit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fruit)
		fruit.size = source.size
		fruit.position = source.position
		source.hide()
		var start := fruit.position
		var end: Vector2 = TARGETS[slot]
		var arc := create_tween()
		arc.tween_method(func(t: float) -> void:
			fruit.position = start.lerp(end, t) - Vector2(0, sin(PI * t) * 92)
			fruit.size = source.size.lerp(Vector2(88, 88), t)
		, 0.0, 1.0, 0.44).set_trans(Tween.TRANS_SINE)
		await arc.finished
		landed.append(fruit)
		$Count.text = "바구니  %d / 2" % landed.size()
		$Order.text = WORDS[slot]
		play_cue($Chime, POP)
		say(WORDS[slot], slot == 0)
		bounce(12.0)
		if slot == 0:
			$Prompt.text = "하나 더 담아 볼까?"
	delivering = false
	if landed.size() == TARGETS.size():
		finished = true
		await get_tree().create_timer(0.65).timeout
		$Momo.texture = CHEER
		$Order.text = "사과 두 개, 고마워!"
		play_cue($Done, JINGLE)
		say($Order.text, false)
		bounce(34.0)
		$Prompt.hide()
		$PromptCard.hide()
		$Replay.show()

func bounce(height: float) -> void:
	if reaction:
		reaction.kill()
	reaction = create_tween()
	reaction.tween_property($Momo, "position:y", 228.0 - height, 0.16).set_trans(Tween.TRANS_SINE)
	reaction.tween_property($Momo, "position:y", 228.0, 0.24).set_trans(Tween.TRANS_BOUNCE)

func play_cue(player: AudioStreamPlayer, cue: AudioStream) -> void:
	if sound_on:
		player.stream = cue
		player.play()

func repeat_line() -> void:
	var line := ORDER
	if finished:
		line = "사과 두 개, 고마워!"
	elif landed.size() == 1:
		line = "사과 하나 더 담아 볼까?"
	say(line, true)

func say(line: String, interrupt: bool) -> void:
	if not sound_on:
		return
	if interrupt:
		stop_voice()
	voice_queue.append(VOICES[line])
	if not $Voice.playing:
		play_next_voice()

func play_next_voice() -> void:
	if not voice_queue.is_empty():
		$Voice.stream = voice_queue.pop_front()
		$Voice.play()

func stop_voice() -> void:
	voice_queue.clear()
	$Voice.stop()

func toggle_sound() -> void:
	sound_on = not sound_on
	$Sound.text = "소리 켜짐" if sound_on else "소리 꺼짐"
	if sound_on:
		repeat_line()
	else:
		stop_voice()
		$Chime.stop()
		$Done.stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_node_ready():
		stop_voice()
