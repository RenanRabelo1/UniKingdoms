class_name ComboTracker
extends RefCounted
## Guarda os últimos golpes e reconhece quando a sequência termina num combo.

var combos: Array[ComboData] = []
var window: float

var _sequence: Array[StringName] = []
var _last_time := -INF


func _init(p_combos: Array, p_window: float) -> void:
	combos.assign(p_combos)
	window = p_window


## Registra um golpe no instante `now` (segundos). Retorna o combo fechado ou null.
func register(attack: StringName, now: float) -> ComboData:
	if now - _last_time > window:
		_sequence.clear()
	_last_time = now
	_sequence.append(attack)
	for combo in combos:
		if _ends_with(combo.sequence):
			_sequence.clear()
			return combo
	return null


func _ends_with(tail: Array[StringName]) -> bool:
	return _sequence.size() >= tail.size() and _sequence.slice(-tail.size()) == tail
