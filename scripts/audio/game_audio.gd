class_name GameAudio
## Efeitos curtos originais sintetizados e cacheados. Não usa assets externos nem autoload.

const SAMPLE_RATE := 22050
const MAX_VOICES := 12
const SPECS := {
	&"swing": [0.10, 420.0, 120.0, 0.75, 0.16],
	&"heavy": [0.17, 260.0, 65.0, 0.65, 0.22],
	&"hit": [0.10, 180.0, 42.0, 0.5, 0.28],
	&"dash": [0.15, 280.0, 840.0, 0.65, 0.14],
	&"special": [0.42, 180.0, 760.0, 0.18, 0.25],
	&"ready": [0.25, 660.0, 990.0, 0.0, 0.12],
	&"coin": [0.08, 1250.0, 1650.0, 0.0, 0.09],
	&"clear": [0.38, 440.0, 880.0, 0.0, 0.18],
	&"hurt": [0.19, 180.0, 72.0, 0.28, 0.20],
}

static var enabled := true
static var settings_path := "user://audio.cfg"
static var _loaded := false
static var _streams: Dictionary = {}
static var _last_played: Dictionary = {}


static func load_preferences() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		enabled = bool(config.get_value("audio", "effects", true))


static func set_enabled(value: bool) -> void:
	enabled = value
	_loaded = true
	var config := ConfigFile.new()
	config.set_value("audio", "effects", enabled)
	var error := config.save(settings_path)
	if error != OK:
		push_warning("Não foi possível guardar a preferência de áudio (%d)." % error)


static func play(parent: Node, cue: StringName, pitch := 1.0) -> void:
	load_preferences()
	if not enabled or not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	# Testes headless não precisam criar vozes de áudio.
	if DisplayServer.get_name() == "headless":
		return
	if not SPECS.has(cue):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(cue, -1000)) < 45:
		return
	if parent.get_tree().get_nodes_in_group(&"game_sfx").size() >= MAX_VOICES:
		return
	_last_played[cue] = now
	var voice := AudioStreamPlayer.new()
	voice.stream = stream_for(cue)
	voice.pitch_scale = pitch
	voice.volume_db = -6.0
	parent.add_child(voice)
	voice.add_to_group(&"game_sfx")
	voice.finished.connect(voice.queue_free)
	voice.play()


static func stream_for(cue: StringName) -> AudioStreamWAV:
	if _streams.has(cue):
		return _streams[cue]
	var spec: Array = SPECS[cue]
	var count := int(float(spec[0]) * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var noise_seed := 17
	for i in count:
		var t := float(i) / count
		phase += TAU * lerpf(spec[1], spec[2], t) / SAMPLE_RATE
		noise_seed = (noise_seed * 1103515245 + 12345) & 0x7fffffff
		var noise := float(noise_seed) / 1073741824.0 - 1.0
		var envelope := minf(t * 30.0, 1.0) * pow(1.0 - t, 2.0)
		var sample := lerpf(sin(phase), noise, spec[3]) * envelope * float(spec[4])
		bytes.encode_s16(i * 2, roundi(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	_streams[cue] = stream
	return stream
