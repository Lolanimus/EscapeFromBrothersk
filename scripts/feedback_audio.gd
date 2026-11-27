extends Node
## Plays the placeholder sound for every gameplay cue and reports it through cue_played.
## The repository has no audio assets, so each cue is a short tone generated once and
## cached; cues differ in pitch sweep, length, and wave shape. A level owns one node
## named "FeedbackAudio"; gameplay code calls play_cue() from any node inside that level.

signal cue_played(cue: StringName, at: Variant)

const NODE_NAME := "FeedbackAudio"
const MIX_RATE := 22050
const VOLUME := 0.45
## cue: [start Hz, end Hz, seconds, wave]. Noise waves resample random values at the given rate.
const CUE_TONES := {
	&"pistol_fire": [900.0, 300.0, 0.09, &"square"],
	&"shotgun_fire": [3000.0, 500.0, 0.25, &"noise"],
	&"ak47_fire": [600.0, 250.0, 0.06, &"square"],
	&"empty_click": [2000.0, 2000.0, 0.03, &"square"],
	&"reload": [300.0, 650.0, 0.18, &"saw"],
	&"weapon_pickup": [500.0, 1000.0, 0.15, &"sine"],
	&"magazine_pickup": [1200.0, 1500.0, 0.08, &"sine"],
	&"thrown_impact": [1200.0, 200.0, 0.12, &"noise"],
	&"punch": [400.0, 100.0, 0.08, &"noise"],
	&"katana_swing": [6000.0, 2000.0, 0.2, &"noise"],
	&"knockout": [300.0, 80.0, 0.3, &"sine"],
	&"choking": [140.0, 110.0, 0.4, &"saw"],
	&"detection": [1000.0, 1400.0, 0.2, &"square"],
	&"player_death": [400.0, 60.0, 0.7, &"saw"],
	&"level_complete": [523.0, 1046.0, 0.6, &"sine"],
	&"door_open": [90.0, 160.0, 0.35, &"saw"],
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
	if not CUE_TONES.has(cue):
		return null
	if not _streams.has(cue):
		_streams[cue] = _generate(cue, CUE_TONES[cue])
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
		add_child(positional)
		positional.global_position = at
		positional.play()
		player = positional
	else:
		var interface := AudioStreamPlayer.new()
		interface.stream = stream
		add_child(interface)
		interface.play()
		player = interface
	get_tree().create_timer(stream.get_length() + 0.1, true).timeout.connect(player.queue_free)
	cue_played.emit(cue, at)


static func _generate(cue: StringName, tone: Array) -> AudioStreamWAV:
	var start_hz: float = tone[0]
	var end_hz: float = tone[1]
	var seconds: float = tone[2]
	var wave: StringName = tone[3]
	var sample_count := int(seconds * MIX_RATE)
	var random := RandomNumberGenerator.new()
	random.seed = hash(cue)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	var noise_value := 0.0
	for index in sample_count:
		var progress := float(index) / sample_count
		var previous_phase := phase
		phase = fmod(phase + lerpf(start_hz, end_hz, progress) / MIX_RATE, 1.0)
		var value := 0.0
		match wave:
			&"sine": value = sin(phase * TAU)
			&"square": value = 1.0 if phase < 0.5 else -1.0
			&"saw": value = phase * 2.0 - 1.0
			&"noise":
				if phase < previous_phase or index == 0:
					noise_value = random.randf_range(-1.0, 1.0)
				value = noise_value
		# Five-millisecond attack, then a linear fade so every cue ends without a click.
		var envelope := minf(index / (0.005 * MIX_RATE), 1.0) * (1.0 - progress)
		data.encode_s16(index * 2, int(clampf(value * envelope * VOLUME, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
