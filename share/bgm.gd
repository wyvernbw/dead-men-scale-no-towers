extends AudioStreamPlayer

const BGM_DIR := "res://world/assets/bgm/"

var tracks: Dictionary
var current_track: Maybe = Maybe.None()

func _ready() -> void:
	load_tracks()

func play_track(name: String) -> void:
	if name == "":
		return
	if not name in tracks:
		Tracer.warn("Attempt to play nonexistent track: %s" % name)
		return 
	var current_track_name = current_track.unwrap_or("")
	if name != current_track_name:
		stream = tracks[name]
		current_track = Maybe.Some(name)
		playing = true

func load_tracks() -> void:
	var dir := DirAccess.open(BGM_DIR)
	assert(dir)
	dir.list_dir_begin()
	dir.include_navigational = false
	var track_list = _get_tracks(dir)
	dir.list_dir_end()
	for track in track_list:
		tracks[track] = load(BGM_DIR + track)
	Tracer.info("Loaded %s bgm tracks." % tracks.size())

func _get_tracks(dir: DirAccess) -> Array:
	return _navigate_tracks(dir).filter(func(el): return not el in ["..", ".", ""] and not el.ends_with(".import"))

func _navigate_tracks(dir: DirAccess) -> Array:
	var next = dir.get_next()
	var ret = [next]
	if next != "":
		ret.append_array(_get_tracks(dir))
		return ret
	else:
		return ret
