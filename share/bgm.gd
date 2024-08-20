extends AudioStreamPlayer

const BGM_DIR := "res://world/assets/bgm/"

var tracks := {
	"the_night_before_battle.mp3": preload(BGM_DIR + "the_night_before_battle.mp3"),
	"the_elben_castle.mp3": preload(BGM_DIR + "the_elben_castle.mp3")
}
var current_track: Maybe = Maybe.None()

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

