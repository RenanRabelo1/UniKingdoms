class_name WeaponData
extends Resource

@export var id: StringName
@export var display_name: String
@export var basic_damage := 10
@export var basic_cooldown := 0.25
@export var heavy_damage := 25
@export var heavy_cooldown := 0.6
## O golpe é uma cápsula que sai do corpo do player e vai até `reach` na direção da mira,
## com raio `hit_radius`. Medido no sprite: a espada do Warrior chega a ~67 px do corpo.
@export var reach := 58.0
@export var hit_radius := 30.0
## Multiplicador de alcance e raio do golpe pesado.
@export var heavy_size := 1.15
