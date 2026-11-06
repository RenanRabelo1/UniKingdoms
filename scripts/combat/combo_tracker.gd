class_name ComboTracker
extends RefCounted
## Guarda os últimos golpes e reconhece quando a sequência termina num combo.

var combos: Array[ComboData] = []
var window: float

var _sequence: Array[StringName] = []
var _last_time := -INF
var _max_length := 1


func _init(p_combos: Array, p_window: float) -> void:
	combos.assign(p_combos)
	window = p_window
	for combo in combos:
		_max_length = maxi(_max_length, combo.sequence.size())


## Registra um golpe no instante `now` (segundos). Retorna o combo fechado ou null.
func register(attack: StringName, now: float) -> ComboData:
	if now - _last_time > window:
		_sequence.clear()
	_last_time = now
	_sequence.append(attack)
	if _sequence.size() > _max_length:
		_sequence.pop_front()
	for combo in combos:
		if not combo.sequence.is_empty() and _ends_with(combo.sequence):
			_sequence.clear()
			return combo
	return null


## Melhor prefixo de combo ainda aberto. Ler o HUD não altera o reconhecimento.
func progress(now: float) -> Dictionary:
	if now - _last_time > window:
		return {}
	var best := {}
	var best_steps := 0
	for combo in combos:
		for steps in range(1, combo.sequence.size()):
			if steps > best_steps and _ends_with(combo.sequence.slice(0, steps)):
				best_steps = steps
				best = {
					"sequence": combo.sequence.duplicate(),
					"next_attack": combo.sequence[steps],
					"combo_name": combo.display_name,
					"steps": steps,
					"total": combo.sequence.size(),
					"time_left": maxf(window - (now - _last_time), 0.0),
				}
	return best


func _ends_with(tail: Array[StringName]) -> bool:
	return _sequence.size() >= tail.size() and _sequence.slice(-tail.size()) == tail
