class_name BattleCommand
extends Resource
## One Charles command, defined as data (.tres). Implements Story 001
## (production/epics/uncharles/story-001-battle-persuade.md).
##
## `kind` decides which numeric field the rules read:
##   ATTACK   -> `power`           (damage dealt to the enemy)
##   PERSUADE -> `persuade_amount` (added to the enemy's persuade gauge)
##   DEFEND   -> `guard_percent`   (damage reduction for the next enemy attack)
## `result_line` is the one-line result text; it may use the placeholders
## {damage}, {persuade} and {guard}, which BattleState fills in.

enum Kind { ATTACK, PERSUADE, DEFEND }

## Stable identifier, also used by the `--commands=` debug argument.
@export var id: StringName = &""
## Name shown in the command list.
@export var display_name: String = ""
@export var kind: Kind = Kind.ATTACK
## ATTACK: damage dealt to the enemy.
@export var power: int = 0
## PERSUADE: amount added to the persuade gauge.
@export var persuade_amount: int = 0
## DEFEND: percent (0-100) of the next enemy attack that is absorbed.
@export_range(0, 100) var guard_percent: int = 0
## One-line result text shown in the log when the command is used.
@export_multiline var result_line: String = ""
