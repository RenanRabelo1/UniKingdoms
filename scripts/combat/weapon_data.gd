class_name WeaponData
extends Resource

@export var id: StringName
@export var display_name: String
@export var basic_damage := 10
@export var basic_cooldown := 0.25
@export var heavy_damage := 25
@export var heavy_cooldown := 0.6
## Distância do centro do golpe até o player, na direção da mira.
@export var reach := 50.0
@export var hit_radius := 36.0
