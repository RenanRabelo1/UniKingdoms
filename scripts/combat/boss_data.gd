class_name BossData
extends Resource
## Tuning do professor-chefe; ataques e avisos usam os mesmos valores.

@export var max_hp := 900
@export var speed := 115.0
@export var opening_delay := 1.2
@export var chase_time := 1.25
@export var turbo_chase_time := 0.8
@export_group("Investida")
@export var charge_speed := 640.0
@export var charge_time := 0.45
@export var charge_damage := 22
@export var contact_range := 52.0
@export var charge_warning := 0.75
@export var turbo_charge_warning := 0.55
@export var charge_recovery := 0.65
@export_group("Leque")
@export var throw_damage := 12
@export var throw_warning := 0.6
@export var throw_recovery := 0.55
@export var projectile_speed := 300.0
@export var fan_count := 5
@export var fan_step_degrees := 15.0
@export_group("Segunda fase e impacto")
@export var summon_every := 9.0
@export var first_summon_delay := 2.0
@export var summon_count := 2
@export var hit_flash_time := 0.12
