extends SceneTree
## Rebuilds assets/data/audio/sound_bank.tres from every WAV in
## assets/audio/sfx/: the file name (without .wav) is the event id.
## Run after tools/audio/make_chiptune.py and an import:
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/audio/build_sound_bank.gd

const SFX_DIR: String = "res://assets/audio/sfx/"
const BANK_PATH: String = "res://assets/data/audio/sound_bank.tres"


func _initialize() -> void:
	var bank := SoundBank.new()
	for file: String in DirAccess.get_files_at(SFX_DIR):
		if file.get_extension() == "wav":
			bank.events[StringName(file.get_basename())] = load(SFX_DIR + file)
	DirAccess.make_dir_recursive_absolute(BANK_PATH.get_base_dir())
	var err: Error = ResourceSaver.save(bank, BANK_PATH)
	print("sound bank: %d events -> %s (%s)" % [bank.events.size(), BANK_PATH, error_string(err)])
	quit(0 if err == OK else 1)
