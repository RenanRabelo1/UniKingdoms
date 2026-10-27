extends GutTest

var gs


class FakeEnemy:
	extends Node
	var data: EnemyData


func before_each():
	gs = GameState
	gs.save_path = "user://test_save.dat"
	gs.profile = gs.default_profile()
	gs.run = {}


func after_all():
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.dat"))
	GameState.save_path = "user://save.dat"
	GameState.load_game()


func _kill(id: String) -> void:
	var e := FakeEnemy.new()
	e.data = load("res://data/enemies/%s.tres" % id)
	gs.notify_kill(e)
	e.free()


func test_plan_has_12_rooms_boss_last_shops_and_teachings():
	for i in 20:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		var plan: Array = gs.make_plan(rng)
		assert_eq(plan.size(), 12)
		assert_eq(plan[0], "teaching")
		assert_eq(plan[11], "boss")
		assert_eq(plan.count("shop"), 2)
		assert_eq(plan.count("teaching"), 3)
		assert_eq(plan.count("combat"), 6)


func test_start_run_wears_jaleco_from_stash():
	gs.profile.stash = {"jaleco": 1}
	gs.start_run()
	assert_eq(gs.profile.stash.jaleco, 0)
	assert_eq(gs.stats().get(&"max_hp", 0.0), 25.0)
	assert_eq(gs.profile.runs, 1)


func test_death_loses_run_bits_but_keeps_relics_and_bank():
	gs.start_run()
	gs.add_bits(40)
	assert_eq(gs.run.bits, 40)
	gs.profile.relics.append("martelo")
	var result: Dictionary = gs.end_run(false)
	assert_false(gs.has_run())
	assert_eq(gs.profile.bits, gs.START_BITS)
	assert_has(gs.profile.relics, "martelo")
	assert_false(result.victory)
	assert_eq(gs.profile.deaths, 1)


func test_victory_banks_bits_and_unlocks_teachings():
	gs.start_run()
	gs.add_bits(30)
	var result: Dictionary = gs.end_run(true)
	assert_eq(gs.profile.bits, gs.START_BITS + 30)
	assert_true(gs.profile.cct_conquered)
	assert_has(gs.profile.unlocked, "overclock")
	assert_has(result.unlocked, "Overclock")


func test_locked_teachings_only_after_unlock_and_no_repeats():
	gs.start_run()
	for i in 10:
		for t in gs.offer_teachings(3):
			assert_false(t.locked)
	gs.take_teaching(gs.teaching("recursao"))
	for i in 10:
		for t in gs.offer_teachings(3):
			assert_ne(String(t.id), "recursao")
	gs.profile.unlocked = ["overclock", "coleta_lixo"]
	var ids := []
	for i in 30:
		ids.append_array(gs.offer_teachings(9).map(func(t): return String(t.id)))
	assert_has(ids, "overclock")


func test_stats_sum_relics_teachings_and_extras():
	gs.profile.relics = ["patinho"]
	gs.start_run()
	gs.take_teaching(gs.teaching("laco_infinito"))
	gs.take_teaching(gs.teaching("aterramento"))
	var s: Dictionary = gs.stats()
	assert_almost_eq(s[&"dmg_all"], 0.06, 0.001)
	assert_almost_eq(s[&"dmg_basic"], 0.2, 0.001)
	assert_almost_eq(s[&"max_hp"], 20.0, 0.001)


func test_campus_purchase_goes_to_stash_and_needs_bits():
	var marmita: ItemData = gs.item("marmita")
	assert_true(gs.buy(marmita, "cct"))
	assert_eq(gs.profile.bits, gs.START_BITS - marmita.price)
	assert_eq(gs.item_count("marmita"), 1)
	gs.profile.bits = 0
	assert_false(gs.buy(marmita, "cct"))


func test_atletica_discount_grows_with_reputation():
	var codigo: ItemData = gs.item("codigo_penal")
	assert_eq(gs.price(codigo, "atletica"), codigo.price)
	gs.profile.reputation = 50
	assert_eq(gs.price(codigo, "atletica"), roundi(codigo.price * 0.8))
	assert_eq(gs.price(codigo, "cct"), codigo.price)


func test_run_purchase_uses_run_bits_and_run_items_go_first():
	gs.profile.stash = {"marmita": 1}
	gs.start_run()
	gs.run.bits = 100
	assert_true(gs.buy(gs.item("marmita"), "run"))
	assert_eq(gs.run.bits, 100 - gs.item("marmita").price)
	assert_eq(gs.item_count("marmita"), 2)
	assert_true(gs.consume_item("marmita"))
	assert_eq(gs.run.items.marmita, 0, "gasta primeiro o item da run")
	assert_eq(gs.profile.stash.marmita, 1)
	assert_true(gs.buy(gs.item("jaleco"), "run"))
	assert_eq(gs.stats()[&"max_hp"], 25.0, "jaleco comprado na run vale na hora")


func test_bits_gain_relic_bonus():
	gs.profile.relics = ["pepita"]
	gs.start_run()
	assert_eq(gs.add_bits(20), 23)


func test_relic_roll_never_repeats():
	for i in gs.RELICS.size():
		assert_not_null(gs.roll_relic(1.0))
	assert_eq(gs.profile.relics.size(), gs.RELICS.size())
	assert_null(gs.roll_relic(1.0), "sem relíquias restantes")


func test_kill_mission_rewards_reputation_and_bits():
	gs.profile.mission = gs.MISSIONS[0].duplicate()
	gs.profile.mission.progress = 0
	watch_signals(gs)
	for i in 15:
		_kill("bug")
	assert_eq(gs.profile.reputation, gs.MISSION_REP)
	assert_eq(gs.profile.bits, gs.START_BITS + gs.MISSION_BITS)
	assert_true(gs.profile.mission.is_empty())
	assert_signal_emitted(gs, "notice")


func test_room_mission_completes_when_reaching_room():
	gs.profile.mission = gs.MISSIONS[3].duplicate()
	gs.profile.mission.progress = 0
	gs.start_run()
	for i in 5:
		gs.advance_room(50)
	assert_false(gs.profile.mission.is_empty())
	gs.advance_room(50)
	assert_true(gs.profile.mission.is_empty())
	assert_eq(gs.profile.reputation, gs.MISSION_REP)


func test_accept_mission_avoids_last_one():
	gs.profile.last_mission = "caca_bugs"
	for i in 20:
		gs.profile.mission = {}
		assert_ne(gs.accept_mission().id, "caca_bugs")


func test_ally_stops_ambushes():
	assert_gt(gs.ambush_chance(), 0.0)
	gs.profile.reputation = 50
	assert_true(gs.is_ally())
	assert_eq(gs.ambush_chance(), 0.0)


func test_save_and_load_roundtrip_keeps_types():
	gs.profile.color = "Purple"
	gs.profile.relics = ["estilete"]
	gs.start_run()
	gs.advance_room(77)
	gs.take_teaching(gs.teaching("capacitor"))
	gs.save_game()
	gs.profile = {}
	gs.run = {}
	assert_true(gs.load_game())
	assert_eq(gs.profile.color, "Purple")
	assert_eq(gs.run.room, 1)
	assert_typeof(gs.run.room, TYPE_INT)
	assert_eq(gs.run.hp, 77)
	assert_has(gs.run.teachings, "capacitor")
	assert_almost_eq(gs.stats()[&"special_rate"], 0.5, 0.001)
