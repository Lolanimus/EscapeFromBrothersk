extends Node
## Plays the placeholder sound for every gameplay cue and reports it through cue_played.
## The repository has no audio assets, so each cue is synthesised once in code and
## cached. Each cue layers filtered noise (shots, hits, swooshes, scrapes) with a few
## tonal parts (body thumps, metal rings, chimes) shaped by fast natural decays.
## A level owns one node named "FeedbackAudio"; gameplay code calls play_cue() from
## any node inside that level.

signal cue_played(cue: StringName, at: Variant)

const NODE_NAME := "FeedbackAudio"
const MIX_RATE := 22050
## Overall loudness of the generated samples, and a further playback attenuation.
const MASTER_GAIN := 0.3
const PLAYBACK_VOLUME_DB := -8.0
## Each cue is a list of layers:
## [kind, start Hz, end Hz, seconds, delay, decay per second (0 = swell), gain]
## "noise" Hz values are a low-pass cutoff sweep; "sine" Hz values are a pitch sweep.
const CUE_LAYERS := {
	&"pistol_fire": [
		[&"noise", 7000.0, 1200.0, 0.22, 0.0, 22.0, 1.0],
		[&"sine", 160.0, 55.0, 0.14, 0.0, 30.0, 0.6],
	],
	&"shotgun_fire": [
		[&"noise", 4000.0, 500.0, 0.45, 0.0, 9.0, 1.0],
		[&"sine", 95.0, 38.0, 0.3, 0.0, 13.0, 0.8],
	],
	&"ak47_fire": [
		[&"noise", 8000.0, 2200.0, 0.13, 0.0, 34.0, 0.9],
		[&"sine", 210.0, 90.0, 0.09, 0.0, 40.0, 0.45],
	],
	&"empty_click": [
		[&"noise", 9000.0, 9000.0, 0.015, 0.0, 300.0, 0.45],
		[&"sine", 3200.0, 3000.0, 0.03, 0.0, 160.0, 0.08],
	],
	&"reload": [
		[&"noise", 5000.0, 3000.0, 0.035, 0.0, 120.0, 0.45],
		[&"noise", 7500.0, 4000.0, 0.05, 0.14, 90.0, 0.6],
		[&"sine", 1850.0, 1800.0, 0.08, 0.14, 55.0, 0.1],
	],
	&"weapon_pickup": [
		[&"noise", 2500.0, 1200.0, 0.1, 0.0, 35.0, 0.4],
		[&"sine", 950.0, 900.0, 0.08, 0.04, 60.0, 0.1],
	],
	&"magazine_pickup": [
		[&"noise", 6000.0, 4000.0, 0.025, 0.0, 180.0, 0.4],
		[&"sine", 2400.0, 2350.0, 0.06, 0.0, 80.0, 0.08],
	],
	&"thrown_impact": [
		[&"noise", 2200.0, 500.0, 0.22, 0.0, 24.0, 0.8],
		[&"sine", 230.0, 120.0, 0.16, 0.0, 28.0, 0.35],
	],
	&"punch": [
		[&"noise", 1300.0, 300.0, 0.13, 0.0, 34.0, 0.85],
		[&"sine", 115.0, 60.0, 0.11, 0.0, 34.0, 0.6],
	],
	&"katana_swing": [
		[&"noise", 900.0, 4500.0, 0.26, 0.0, 0.0, 0.55],
	],
	&"knockout": [
		[&"noise", 650.0, 150.0, 0.35, 0.0, 11.0, 0.8],
		[&"sine", 72.0, 40.0, 0.32, 0.0, 12.0, 0.6],
	],
	&"choking": [
		[&"noise", 520.0, 330.0, 0.55, 0.0, 0.0, 0.5],
		[&"sine", 145.0, 105.0, 0.5, 0.0, 0.0, 0.08],
	],
	&"detection": [
		[&"sine", 2650.0, 2850.0, 0.28, 0.0, 6.0, 0.2],
		[&"noise", 3000.0, 3000.0, 0.28, 0.0, 6.0, 0.05],
	],
	&"player_death": [
		[&"noise", 450.0, 120.0, 0.45, 0.0, 9.0, 0.6],
		[&"sine", 180.0, 65.0, 0.75, 0.0, 4.0, 0.35],
	],
	&"level_complete": [
		[&"sine", 523.0, 523.0, 0.5, 0.0, 6.0, 0.25],
		[&"sine", 659.0, 659.0, 0.5, 0.12, 6.0, 0.25],
		[&"sine", 784.0, 784.0, 0.5, 0.24, 6.0, 0.25],
	],
	&"door_open": [
		[&"noise", 700.0, 1300.0, 0.5, 0.0, 0.0, 0.4],
		[&"sine", 62.0, 70.0, 0.5, 0.0, 0.0, 0.12],
	],
}

static var _streams: Dictionary[StringName, AudioStreamWAV] = {}


## Plays a cue on the FeedbackAudio node of the level that contains context.
## at is a global position for positional cues, or null for interface cues.
static func play_cue(context: Node, cue: StringName, at: Variant = null) -> void:
	var host := context
	while host != null:
		var feedback := host.get_node_or_null(NODE_NAME)
		if feedback != null and feedback.has_method(&"play"):
			feedback.play(cue, at)
			return
		host = host.get_parent()


static func stream_for(cue: StringName) -> AudioStreamWAV:
	if not CUE_LAYERS.has(cue):
		return null
	if not _streams.has(cue):
		_streams[cue] = _generate(cue, CUE_LAYERS[cue])
	return _streams[cue]


func _ready() -> void:
	# Completion stops gameplay, but its own cue must still be heard.
	process_mode = Node.PROCESS_MODE_ALWAYS


func play(cue: StringName, at: Variant = null) -> void:
	var stream := stream_for(cue)
	if stream == null:
		push_warning("Unknown feedback cue: %s" % cue)
		return
	var player: Node
	if at is Vector2:
		var positional := AudioStreamPlayer2D.new()
		positional.stream = stream
		positional.volume_db = PLAYBACK_VOLUME_DB
		add_child(positional)
		positional.global_position = at
		positional.play()
		player = positional
	else:
		var interface := AudioStreamPlayer.new()
		interface.stream = stream
		interface.volume_db = PLAYBACK_VOLUME_DB
		add_child(interface)
		interface.play()
		player = interface
	get_tree().create_timer(stream.get_length() + 0.1, true).timeout.connect(player.queue_free)
	cue_played.emit(cue, at)


static func _generate(cue: StringName, layers: Array) -> AudioStreamWAV:
	var total_seconds := 0.0
	for layer: Array in layers:
		total_seconds = maxf(total_seconds, layer[4] + layer[3])
	var sample_count := int(total_seconds * MIX_RATE)
	var mix := PackedFloat32Array()
	mix.resize(sample_count)
	var random := RandomNumberGenerator.new()
	random.seed = hash(cue)
	for layer: Array in layers:
		_add_layer(mix, layer, random)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		# tanh keeps layered peaks soft instead of clipping harshly.
		data.encode_s16(index * 2, int(tanh(mix[index] * MASTER_GAIN * 1.5) * 32767.0 / 1.5))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func _add_layer(mix: PackedFloat32Array, layer: Array, random: RandomNumberGenerator) -> void:
	var kind: StringName = layer[0]
	var start_hz: float = layer[1]
	var end_hz: float = layer[2]
	var seconds: float = layer[3]
	var first := int(layer[4] * MIX_RATE)
	var decay: float = layer[5]
	var gain: float = layer[6]
	var count := int(seconds * MIX_RATE)
	var phase := 0.0
	var filtered := 0.0
	for offset in count:
		var index := first + offset
		if index >= mix.size():
			return
		var progress := float(offset) / count
		var t := float(offset) / MIX_RATE
		var hz := lerpf(start_hz, end_hz, progress)
		var value := 0.0
		if kind == &"noise":
			# One-pole low-pass: lower cutoffs give duller thuds, higher ones sharper cracks.
			var alpha := 1.0 - exp(-TAU * hz / MIX_RATE)
			filtered += alpha * (random.randf_range(-1.0, 1.0) - filtered)
			value = filtered * 1.6
		else:
			phase = fmod(phase + hz / MIX_RATE, 1.0)
			value = sin(phase * TAU)
		# Percussive layers decay exponentially after a 2 ms attack; swells rise and fall.
		var envelope := sin(PI * progress) if decay <= 0.0 else minf(t / 0.002, 1.0) * exp(-decay * t)
		# Fade the final 5% so no layer ends with a click.
		envelope *= minf((1.0 - progress) / 0.05, 1.0)
		mix[index] += value * envelope * gain
