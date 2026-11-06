class_name EncounterData
extends Resource
## Composição e ritmo de uma sala. Conteúdo novo é um Resource, não outro ramo da IA.

@export var id: StringName
@export var display_name := ""
@export var tactic := ""
@export var enemy_cycle := PackedStringArray(["bug"])
@export var accent := Color("69d8e8")
@export_range(1, 8) var max_active := 6
@export_range(0, 3) var reinforce_at := 1
@export var spawn_warning := 0.65
@export var base_enemies := 3
@export var hp_per_room := 0.055
@export var challenge_base_time := 18.0
@export var challenge_seconds_per_enemy := 4.0
@export var challenge_bonus := 8


func challenge_time(enemy_count: int) -> float:
	return challenge_base_time + challenge_seconds_per_enemy * enemy_count
