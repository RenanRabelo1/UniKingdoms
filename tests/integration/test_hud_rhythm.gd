extends GutTest

const PlayerScene := preload("res://scenes/player/player.tscn")

var hud: Hud
var player: Player
var _saved_profile: Dictionary
var _saved_run: Dictionary


func before_all() -> void:
	_saved_profile = GameState.profile.duplicate(true)
	_saved_run = GameState.run.duplicate(true)


func after_all() -> void:
	GameState.profile = _saved_profile
	GameState.run = _saved_run


func before_each() -> void:

	GameState.profile = GameState.default_profile()
	GameState.run = {}
	player = PlayerScene.instantiate()
	add_child_autofree(player)
	hud = Hud.new()
	add_child_autofree(hud)
	hud.bind_player(player)


func test_hud_starts_with_actual_special_charge() -> void:
	player.special_meter.add(65.0)
	var second_hud := Hud.new()
	add_child_autofree(second_hud)
	second_hud.bind_player(player)
	assert_eq(second_hud._special.value, player.special_meter.value)


func test_latest_notice_is_not_faded_by_previous_notice() -> void:
	hud.show_notice("Primeiro")
	await wait_seconds(2.6)
	hud.show_notice("Segundo")
	await wait_seconds(0.9)
	assert_eq(hud._notice.text, "Segundo")
	assert_almost_eq(hud._notice.modulate.a, 1.0, 0.01)


func test_hud_never_consumes_world_mouse_input() -> void:
	assert_eq(_blocking_controls(hud), 0)
	hud.show_boss("Professor", 900)
	hud.set_objective("Encontro", "4 inimigos", 0.4)
	assert_eq(_blocking_controls(hud), 0, "objetivo e barra do chefe também deixam clicar")


func test_objective_progress_can_change_to_a_non_combat_instruction() -> void:
	hud.set_objective("Encontro", "4 inimigos", 0.4)
	assert_almost_eq(hud._objective_progress.value, 0.4, 0.001)
	assert_true(hud._objective_progress.visible)
	hud.set_objective("Próxima aula: CCT", "Siga o marcador")
	assert_false(hud._objective_progress.visible)
	assert_eq(hud._objective_title.text, "Próxima aula: CCT")


func _blocking_controls(node: Node) -> int:
	var count := 0
	if node is Control and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		count += 1
	for child in node.get_children():
		count += _blocking_controls(child)
	return count
