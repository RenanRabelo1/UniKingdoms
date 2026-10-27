class_name ComboData
extends Resource

@export var id: StringName
@export var display_name: String
## Golpes em ordem, usando &"basic" e &"heavy". O último é o finalizador.
@export var sequence: Array[StringName] = []
## Aplicado ao dano do golpe finalizador.
@export var damage_multiplier := 1.5
