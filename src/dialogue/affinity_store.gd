class_name AffinityStore
extends RefCounted
## Everything the story remembers: affinity per owner candidate, flags and
## counters (jobs_completed, reboot_count, money, battery). Pure data, no
## scene, so dialogue logic can be tested headlessly and Story 003 can save it
## with `to_dict()` / `restore()`. Implements Story 002
## (production/epics/uncharles/story-002-dialogue-affinity.md).
##
## Affinity is kept per candidate id (a candidate never seen reads as 0).
## `snapshot()` / `restore()` copy the whole state; the story flow takes one
## when a job is accepted and restores it after a DEPLETED reboot.

var _affinity: Dictionary = {}
var _flags: Dictionary = {}
var _counters: Dictionary = {}


## `counter_defaults` is counter name -> starting value (from
## assets/data/dialogue/affinity_values.json).
func _init(counter_defaults: Dictionary = {}) -> void:
	restore({"counters": counter_defaults})


## Current affinity toward `candidate_id`; 0 when never changed.
func get_affinity(candidate_id: String) -> int:
	return _affinity.get(candidate_id, 0)


## Adds `delta` (may be negative) to the candidate's affinity.
func add_affinity(candidate_id: String, delta: int) -> void:
	_affinity[candidate_id] = get_affinity(candidate_id) + delta


## True when the flag has been set and not cleared.
func has_flag(flag_name: String) -> bool:
	return _flags.get(flag_name, false)


func set_flag(flag_name: String, value: bool = true) -> void:
	_flags[flag_name] = value


## Counter value; an unknown counter is a data error and reads as 0.
func get_counter(counter_name: String) -> int:
	if not _counters.has(counter_name):
		push_error("AffinityStore: unknown counter '%s'" % counter_name)
		return 0
	return _counters[counter_name]


func set_counter(counter_name: String, value: int) -> void:
	_counters[counter_name] = value


func add_counter(counter_name: String, delta: int) -> void:
	set_counter(counter_name, get_counter(counter_name) + delta)


## Plain dictionary (JSON-safe values only) for saving.
func to_dict() -> Dictionary:
	return {
		"affinity": _affinity.duplicate(),
		"flags": _flags.duplicate(),
		"counters": _counters.duplicate(),
	}


## Replaces the whole state with `data` as produced by `to_dict()`.
func restore(data: Dictionary) -> void:
	_affinity = (data.get("affinity", {}) as Dictionary).duplicate()
	_flags = (data.get("flags", {}) as Dictionary).duplicate()
	_counters = (data.get("counters", {}) as Dictionary).duplicate()
	# A JSON round trip turns ints into floats.
	for key: String in _affinity:
		_affinity[key] = int(_affinity[key])
	for key: String in _counters:
		_counters[key] = int(_counters[key])


## A copy of the current state to `restore()` later.
func snapshot() -> Dictionary:
	return to_dict()
