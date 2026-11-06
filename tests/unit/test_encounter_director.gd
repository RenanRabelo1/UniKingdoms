extends GutTest


func test_intro_uses_only_bugs_and_profiles_have_distinct_compositions() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var intro := EncounterDirector.plan(0, rng, 0.0)
	assert_eq(intro.size(), 3)
	for id in intro:
		assert_eq(id, &"bug")
	assert_ne(EncounterDirector.profile_for(2).enemy_cycle,
		EncounterDirector.profile_for(3).enemy_cycle)
	assert_eq(EncounterDirector.profile_for(2).id, &"cerco")
	assert_eq(EncounterDirector.profile_for(3).id, &"demolicao")


func test_same_seed_repeats_the_encounter_and_ally_removes_ambushes() -> void:
	for room_index in 11:
		var first := RandomNumberGenerator.new()
		var second := RandomNumberGenerator.new()
		first.seed = 1234
		second.seed = 1234
		var queue := EncounterDirector.plan(room_index, first, 0.0)
		assert_eq(queue, EncounterDirector.plan(room_index, second, 0.0))
		assert_eq(queue.size(), 3 + room_index)
		assert_does_not_have(queue, &"atletica")
	var hostile := RandomNumberGenerator.new()
	hostile.seed = 99
	assert_has(EncounterDirector.plan(7, hostile, 1.0), &"atletica")


func test_reinforcement_budget_accounts_for_survivors_and_pending_count() -> void:
	var profile := EncounterDirector.profile_for(7)
	for alive in 9:
		for queued in 15:
			var count := EncounterDirector.reinforcement_count(alive, queued, profile)
			assert_gte(count, 0)
			assert_lte(count, queued)
			if alive <= profile.max_active:
				assert_lte(alive + count, profile.max_active)
			if alive > profile.reinforce_at:
				assert_eq(count, 0)
	assert_eq(EncounterDirector.reinforcement_count(1, 20, profile), 5)
