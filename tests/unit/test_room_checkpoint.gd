extends GutTest

const TEST_SAVE := "res://tests/.checkpoint-save.dat"
var _saved_profile: Dictionary
var _saved_run: Dictionary
var _saved_path: String


class FakeEnemy:
	extends Node
	var data: EnemyData


func before_all() -> void:
	_saved_profile = GameState.profile.duplicate(true)
	_saved_run = GameState.run.duplicate(true)
	_saved_path = GameState.save_path


func before_each() -> void:
	GameState.save_path = TEST_SAVE
	GameState.profile = GameState.default_profile()
	GameState.run = {}


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	GameState.profile = _saved_profile
	GameState.run = _saved_run
	GameState.save_path = _saved_path


func test_v1_save_loads_without_checkpoint_or_seed() -> void:
	GameState.start_run()
	GameState.run.erase("room_checkpoint")
	GameState.run.erase("seed")
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_var({"version": 1, "profile": GameState.profile, "run": GameState.run})
	file.close()
	GameState.run = {}
	assert_true(GameState.load_game())
	assert_eq(GameState.room_phase(), "fighting")
	assert_eq(GameState.run.seed, 0)
	assert_eq(GameState.run.room, 0)


func test_checkpoint_keeps_hp_and_progress_then_resets_on_next_room() -> void:
	GameState.start_run()
	GameState.add_bits(17)
	GameState.checkpoint_room(63, "reward", {"bonus_earned": true})
	assert_true(GameState.load_game())
	assert_eq(GameState.room_phase(), "reward")
	assert_eq(GameState.run.hp, 63)
	assert_eq(GameState.run.bits, 17)
	assert_true(GameState.run.room_checkpoint.summary.bonus_earned)
	GameState.advance_room(63)
	assert_eq(GameState.room_phase(), "fighting")
	assert_eq(GameState.run.room, 1)
	assert_eq(GameState.run.bits, 17)


func test_teaching_cannot_be_claimed_twice_and_invalid_checkpoint_is_ignored() -> void:
	GameState.start_run()
	var teaching := GameState.teaching("recursao")
	GameState.take_teaching(teaching)
	GameState.take_teaching(teaching)
	assert_eq(GameState.run.teachings, ["recursao"])
	GameState.checkpoint_room(50, "unknown")
	assert_eq(GameState.room_phase(), "fighting")
	GameState.run.room_checkpoint = {"room": 8, "phase": "cleared"}
	assert_eq(GameState.room_phase(), "fighting", "checkpoint antigo não limpa sala nova")


func test_mission_save_during_combat_keeps_permanent_reward_but_not_repeatable_run_loot() -> void:
	GameState.profile.stash = {"marmita": 1}
	GameState.profile.mission = {"id": "caca_bugs", "enemy": "bug", "goal": 1, "progress": 0}
	GameState.start_run()
	GameState.add_bits(10)
	GameState.consume_item("marmita")
	var enemy := FakeEnemy.new()
	enemy.data = load("res://data/enemies/bug.tres")
	GameState.notify_kill(enemy)
	enemy.free()
	assert_true(GameState.load_game())
	assert_eq(GameState.run.bits, 0, "combate reiniciado não mantém loot do mesmo combate")
	assert_eq(GameState.run.kills, 0)
	assert_eq(GameState.profile.bits, GameState.START_BITS + GameState.MISSION_BITS)
	assert_eq(GameState.profile.missions_done, 1)
	assert_eq(GameState.item_count("marmita"), 1, "replay também restaura consumível da entrada")
