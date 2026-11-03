class_name SoundPlayer
extends Node
## Plays named audio events from a SoundBank, plus one looping music track.
## UI asks for an event id; it never loads or plays a stream itself
## (.claude/rules/ui-code.md: UI sounds go through the audio event system).
## Add it as a child of the screen that owns it.

## Overlapping effects that can sound at once.
const VOICES: int = 4

## Event id -> stream.
@export var bank: SoundBank
## Background track, looped by its import settings. Empty plays no music.
@export var music: AudioStream
@export var music_volume_db: float = -10.0
@export var sfx_volume_db: float = -6.0

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_player: AudioStreamPlayer


func _ready() -> void:
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = sfx_volume_db
		add_child(voice)
		_voices.append(voice)
	if music != null:
		_music_player = AudioStreamPlayer.new()
		_music_player.stream = music
		_music_player.volume_db = music_volume_db
		add_child(_music_player)
		_music_player.play()


## Plays event `id`. An id the bank does not have warns and plays nothing.
func play(id: StringName) -> void:
	var stream: AudioStream = bank.events.get(id) if bank != null else null
	if stream == null:
		push_warning("SoundPlayer: no sound for event '%s'" % id)
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.play()


## Stops the background track (for example when a result jingle takes over).
func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
