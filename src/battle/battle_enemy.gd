class_name BattleEnemy
extends Resource
## One enemy type, defined as data (.tres). Implements Story 001
## (production/epics/uncharles/story-001-battle-persuade.md).
##
## Attack lines are used in order and loop (deterministic, no randomness).
## Every line may use {damage}, which BattleState fills in.

@export var id: StringName = &""
@export var display_name: String = ""
## Name used inside battle text through the {enemy} placeholder. Empty uses
## display_name.
@export var short_name: String = ""
## Battle sprite. Empty shows a gray box instead.
@export var portrait: Texture2D
@export var max_hp: int = 1
## Battery percent taken from Charles by one attack.
@export var attack_power: int = 0
## Persuade gauge value that ends the battle as PERSUADED.
@export var persuade_max: int = 1
## Shown when the battle starts.
@export_multiline var intro_line: String = ""
## Enemy attack lines, cycled in order: one per enemy turn.
@export var attack_lines: PackedStringArray = PackedStringArray()
## Shown when the enemy is defeated (DEFEATED).
@export_multiline var defeated_line: String = ""
## Shown when the enemy is persuaded (PERSUADED).
@export_multiline var persuaded_line: String = ""
## Shown when Charles runs out of battery (DEPLETED).
@export_multiline var depleted_line: String = ""
## Per-enemy text for Charles' commands: command id (String) -> result line.
## Overrides the command's own generic result_line against this enemy, with
## the same placeholders plus {enemy}.
@export var command_lines: Dictionary = {}
