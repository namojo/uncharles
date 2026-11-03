class_name SoundBank
extends Resource
## Maps audio event ids ("hit", "cursor", ...) to streams. Screens ask for an
## event by id through SoundPlayer; which sound that is lives here, in data.
## Built by tools/audio/build_sound_bank.gd from assets/audio/sfx/.

## Event id (StringName) -> AudioStream.
@export var events: Dictionary = {}
