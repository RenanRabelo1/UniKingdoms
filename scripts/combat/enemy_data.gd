class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
## chaser: golpe em arco; ranged: orbita e atira; kamikaze: corre e explode; charger: investida anunciada.
@export_enum("chaser", "ranged", "kamikaze", "charger") var kind := "chaser"
@export var max_hp := 30
@export var speed := 120.0
@export var damage := 10
## Distância em que começa o ataque (no kamikaze, o raio da explosão é 1.6x isso).
@export var attack_range := 40.0
@export var windup := 0.4
@export var attack_cooldown := 1.0
@export var projectile_speed := 300.0
@export_group("Ritmo e impacto")
@export var recovery := 0.25
@export var initial_attack_delay := Vector2(0.2, 0.8)
@export var stagger_time := 0.15
@export var knockback_speed := 230.0
@export var knockback_decay := 1500.0
@export var hit_flash_time := 0.12
@export_group("Comportamento")
@export var orbit_speed_ratio := 0.55
@export var melee_arc_degrees := 110.0
@export var melee_hit_padding := 14.0
@export var explosion_range_multiplier := 1.6
@export var charge_speed := 440.0
@export var charge_duration := 0.32
@export var charge_hit_radius := 40.0
## Antecipação de obstáculos locais; não substitui navegação global pelo campus.
@export var steering_probe := 44.0
@export_group("Recompensa e aparência")
@export var bits := 2
## Colisão de movimento (pés). Não serve para receber golpes.
@export var body_radius := 14.0
## Área que recebe golpes (Hurtbox): largura × altura e centro, medidos no corpo visível do sprite.
@export var hurtbox_size := Vector2(56, 70)
@export var hurtbox_center := Vector2(0, -34)
@export var sprite_scale := 1.0
@export var sprite_offset := Vector2(0, -30)
## Formato de SheetFrames.build: precisa de "idle", "run" e "attack".
@export var animations: Dictionary = {}
