class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
## chaser: persegue e ataca de perto; ranged: mantém distância e atira; kamikaze: corre e explode.
@export_enum("chaser", "ranged", "kamikaze") var kind := "chaser"
@export var max_hp := 30
@export var speed := 120.0
@export var damage := 10
## Distância em que começa o ataque (no kamikaze, o raio da explosão é 1.6x isso).
@export var attack_range := 40.0
@export var windup := 0.4
@export var attack_cooldown := 1.0
@export var projectile_speed := 300.0
@export var bits := 2
@export var body_radius := 14.0
@export var sprite_scale := 1.0
@export var sprite_offset := Vector2(0, -30)
## Formato de SheetFrames.build: precisa de "idle", "run" e "attack".
@export var animations: Dictionary = {}
