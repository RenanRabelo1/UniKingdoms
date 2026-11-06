class_name EncounterDirector
extends RefCounted
## Planejamento puro: composições identificáveis e reforços limitados pelos sobreviventes.

const PROFILES: Array[EncounterData] = [
	preload("res://data/encounters/pressao.tres"),
	preload("res://data/encounters/cerco.tres"),
	preload("res://data/encounters/demolicao.tres"),
]


static func profile_for(room_index: int) -> EncounterData:
	if room_index < 2:
		return PROFILES[0]
	if room_index == 2:
		return PROFILES[1]
	return PROFILES[(room_index - 1) % PROFILES.size()]


static func plan(room_index: int, rng: RandomNumberGenerator, ambush_chance: float) -> Array[StringName]:
	var profile := profile_for(room_index)
	var queue: Array[StringName] = []
	var offset := rng.randi_range(0, profile.enemy_cycle.size() - 1)
	for i in profile.base_enemies + room_index:
		var id := profile.enemy_cycle[(i + offset) % profile.enemy_cycle.size()]
		if room_index == 0:
			id = "bug"
		queue.append(StringName(id))
	if room_index > 0 and rng.randf() < ambush_chance:
		for i in 2 + int(room_index >= 6):
			queue.push_front(&"atletica")
	return queue


static func reinforcement_count(alive: int, queued: int, profile: EncounterData) -> int:
	if alive > profile.reinforce_at:
		return 0
	return mini(queued, maxi(0, profile.max_active - alive))
