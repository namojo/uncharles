class_name BattleState
extends RefCounted
## Turn-based battle rules for one Charles vs. one enemy fight. Pure logic:
## no Node, no scene, no singleton, no randomness. Implements Story 001
## (production/epics/uncharles/story-001-battle-persuade.md).
##
## Turn order is Charles -> enemy, strictly alternating. The caller drives it:
## `player_act()` while the phase is PLAYER_TURN, then `enemy_act()` while it is
## ENEMY_TURN. Keeping the two calls separate lets a UI pace the enemy's turn.
##
## Phase transitions (PHASE_TRANSITIONS):
##   PLAYER_TURN -> ENEMY_TURN   a command did not end the battle
##   PLAYER_TURN -> ENDED        enemy HP reached 0, or persuade gauge is full
##   ENEMY_TURN  -> PLAYER_TURN  Charles survived the attack
##   ENEMY_TURN  -> ENDED        battery reached 0

enum Phase { PLAYER_TURN, ENEMY_TURN, ENDED }
## How the battle ended: enemy beaten, enemy persuaded, or Charles out of battery.
enum Result { DEFEATED, PERSUADED, DEPLETED }

const PHASE_TRANSITIONS: Dictionary = {
	Phase.PLAYER_TURN: [Phase.ENEMY_TURN, Phase.ENDED],
	Phase.ENEMY_TURN: [Phase.PLAYER_TURN, Phase.ENDED],
	Phase.ENDED: [],
}

## Emitted once, after the closing log line, when the battle ends.
signal battle_ended(result: Result)
## Emitted for every log line (command result, enemy attack, closing line).
signal line_logged(text: String)

var enemy: BattleEnemy
var battery_max: int
## Charles' HP, shown as a percentage. Never below 0.
var battery: int
var enemy_hp: int
var persuade_gauge: int = 0
## Percent of the next enemy attack absorbed. Set by DEFEND, spent by one attack.
var guard_percent: int = 0
var phase: Phase = Phase.PLAYER_TURN
## Valid only when `phase == Phase.ENDED`; check `is_ended()` first.
var result: Result = Result.DEFEATED
var turn_number: int = 1

var _enemy_attack_count: int = 0


## `enemy_data` is the injected enemy data. `battery_start` lets a caller carry
## Charles' battery in from an earlier fight.
func _init(enemy_data: BattleEnemy, battery_max_value: int, battery_start: int) -> void:
	assert(enemy_data.max_hp > 0 and enemy_data.persuade_max > 0, "enemy data needs max_hp and persuade_max > 0")
	assert(not enemy_data.attack_lines.is_empty(), "enemy data needs at least one attack line")
	assert(battery_max_value > 0 and battery_start > 0, "battery must start above 0")
	enemy = enemy_data
	battery_max = battery_max_value
	battery = mini(battery_start, battery_max_value)
	enemy_hp = enemy_data.max_hp


## True once the battle has ended; `result` is then valid.
func is_ended() -> bool:
	return phase == Phase.ENDED


## Charles uses `command`. Returns false (and changes nothing) outside PLAYER_TURN.
func player_act(command: BattleCommand) -> bool:
	if phase != Phase.PLAYER_TURN:
		return false
	match command.kind:
		BattleCommand.Kind.ATTACK:
			enemy_hp = maxi(0, enemy_hp - command.power)
		BattleCommand.Kind.PERSUADE:
			persuade_gauge = mini(enemy.persuade_max, persuade_gauge + command.persuade_amount)
		BattleCommand.Kind.DEFEND:
			guard_percent = clampi(command.guard_percent, 0, 100)
	line_logged.emit(command.result_line.format({
		"damage": command.power,
		"persuade": command.persuade_amount,
		"guard": command.guard_percent,
	}))
	if enemy_hp == 0:
		_end(Result.DEFEATED)
	elif persuade_gauge >= enemy.persuade_max:
		_end(Result.PERSUADED)
	else:
		_transition_to(Phase.ENEMY_TURN)
	return true


## The enemy attacks. Returns false (and changes nothing) outside ENEMY_TURN.
func enemy_act() -> bool:
	if phase != Phase.ENEMY_TURN:
		return false
	var damage: int = roundi(enemy.attack_power * (100 - guard_percent) / 100.0)
	guard_percent = 0
	battery = maxi(0, battery - damage)
	var line: String = enemy.attack_lines[_enemy_attack_count % enemy.attack_lines.size()]
	_enemy_attack_count += 1
	line_logged.emit(line.format({"damage": damage}))
	if battery == 0:
		_end(Result.DEPLETED)
	else:
		turn_number += 1
		_transition_to(Phase.PLAYER_TURN)
	return true


func _transition_to(next: Phase) -> void:
	assert(next in PHASE_TRANSITIONS[phase], "illegal battle phase transition")
	phase = next


func _end(end_result: Result) -> void:
	_transition_to(Phase.ENDED)
	result = end_result
	match end_result:
		Result.DEFEATED:
			line_logged.emit(enemy.defeated_line)
		Result.PERSUADED:
			line_logged.emit(enemy.persuaded_line)
		Result.DEPLETED:
			line_logged.emit(enemy.depleted_line)
	battle_ended.emit(end_result)
