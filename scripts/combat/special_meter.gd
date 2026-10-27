class_name SpecialMeter
extends RefCounted
## Barra do especial: carrega com o tempo e com o dano causado.

signal changed(value: float)

const MAX := 100.0

var value := 0.0
var per_second: float
var per_damage: float


func _init(p_per_second: float, p_per_damage: float) -> void:
	per_second = p_per_second
	per_damage = p_per_damage


func tick(delta: float) -> void:
	_set_value(value + per_second * delta)


func add_damage(amount: float) -> void:
	_set_value(value + per_damage * amount)


## Soma pontos direto na barra (itens).
func add(amount: float) -> void:
	_set_value(value + amount)


func is_full() -> bool:
	return value >= MAX


func consume() -> bool:
	if not is_full():
		return false
	_set_value(0.0)
	return true


func _set_value(v: float) -> void:
	v = clampf(v, 0.0, MAX)
	if v != value:
		value = v
		changed.emit(value)
