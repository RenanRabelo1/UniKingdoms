extends SceneTree
## Playtest curto com controles reais: anda, mira, encadeia golpes e usa esquiva/especial.
## Não altera vida, dano, invencibilidade ou posição dos atores. Usa save isolado no projeto.
## godot --headless --path . -s tests/tools/combat_playtest.gd -- --seed=42 --rooms=3
## Resultado mede um bot simples, não substitui a avaliação humana de dificuldade/feel.

const SAVE_PATH := "res://tests/.combat-playtest-save.dat"
const MOVE_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]

var gs
var run_seed := 42
var target_rooms := 3
var simulation_speed := 2.0
var time_limit := 150.0
var elapsed := 0.0
var decision_left := 0.0
var attack_count := 0
var dash_count := 0
var special_count := 0
var combo_count := 0
var damage_taken := 0
var last_hp := 100
var last_room := -1
var room_started_at := 0.0
var room_reports: Array[Dictionary] = []
var steering_side := 1.0
var last_position := Vector2.ZERO
var stuck_time := 0.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			run_seed = arg.trim_prefix("--seed=").to_int()
		elif arg.begins_with("--rooms="):
			target_rooms = clampi(arg.trim_prefix("--rooms=").to_int(), 1, 4)
		elif arg.begins_with("--speed="):
			simulation_speed = clampf(arg.trim_prefix("--speed=").to_float(), 1.0, 3.0)
		elif arg.begins_with("--timeout="):
			time_limit = maxf(10.0, arg.trim_prefix("--timeout=").to_float())
	await process_frame
	gs = root.get_node_or_null("GameState")
	if gs == null:
		push_error("COMBAT_PLAYTEST: GameState não carregou; verifique os erros de importação.")
		quit(1)
		return
	gs.save_path = SAVE_PATH
	gs.new_game("Blue")
	gs.start_run()
	gs.run.seed = run_seed
	# A topologia é fixa para comparar o ritmo entre execuções; a primeira sala ensina.
	for i in range(1, target_rooms):
		gs.run.plan[i] = "combat"
	gs.save_game()
	seed(run_seed)
	Engine.time_scale = simulation_speed
	change_scene_to_file(gs.SCENE_ROOM)
	await process_frame
	await process_frame
	var result := await _play()
	_release_movement()
	Engine.time_scale = 1.0
	paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("COMBAT_PLAYTEST " + JSON.stringify({
		"result": result, "seed": run_seed, "rooms": room_reports,
		"elapsed": snappedf(elapsed, 0.01), "attacks": attack_count, "combos": combo_count,
		"dashes": dash_count, "specials": special_count, "damage_taken": damage_taken,
		"state": JSON.parse_string(gs.state_to_text()),
	}))
	quit(0 if result == "completed" else 1)


func _play() -> String:
	while elapsed < time_limit:
		await physics_frame
		var delta := simulation_speed / Engine.physics_ticks_per_second
		elapsed += delta
		if not gs.has_run():
			return "run_ended"
		var room = current_scene
		if not is_instance_valid(room) or room.get("player") == null:
			continue
		var player = room.player
		if player.is_dead:
			_record_room(room, "died")
			return "died"
		if gs.run.room != last_room:
			last_room = gs.run.room
			room_started_at = elapsed
			last_hp = player.hp
			last_position = player.global_position
			player.attacked.connect(func(_kind, combo) -> void:
				attack_count += 1
				if combo:
					combo_count += 1)
			player.dashed.connect(func() -> void: dash_count += 1)
			player.special_used.connect(func() -> void: special_count += 1)
			player.health_changed.connect(func(hp_now, _max_hp) -> void:
				damage_taken += maxi(0, last_hp - hp_now)
				last_hp = hp_now)
		if room.door_open and not _reported(last_room):
			_record_room(room, "cleared")
			if room_reports.size() >= target_rooms:
				return "completed"
		if paused:
			_release_movement()
			_press(&"item_1")
			continue
		decision_left -= delta
		if decision_left > 0.0:
			continue
		decision_left = 0.08
		if player.global_position.distance_to(last_position) < 2.0:
			stuck_time += 0.08
		else:
			stuck_time = 0.0
		last_position = player.global_position
		if stuck_time > 0.7:
			steering_side *= -1.0
			stuck_time = 0.0
		if room.door_open:
			var waypoint := Vector2(576, 150) if absf(player.position.x - 576) > 20 and player.position.y > 120 else Vector2(576, -60)
			_move(_steer(player, waypoint - player.global_position))
			continue
		var enemy = _nearest_enemy(room, player)
		if enemy != null:
			_fight(player, enemy)
		else:
			var professor = _professor()
			if professor != null:
				var to: Vector2 = professor.global_position - player.global_position
				_move(_steer(player, to) if to.length() > 55.0 else Vector2.ZERO)
				if to.length() < 65.0:
					_press(&"interact")
			else:
				_release_movement()
	return "timeout"


func _fight(player, enemy) -> void:
	var to: Vector2 = enemy.global_position - player.global_position
	var distance := to.length()
	player.aim_direction = to.normalized()
	var direction := to.normalized() if distance > 88.0 else Vector2.ZERO
	if distance < 56.0:
		direction = -to.normalized()
	# A esquiva reage à preparação real do inimigo. Nenhum dano recebido é removido.
	var winding_up: bool = enemy.get("_state") == 1
	if winding_up and distance < 165.0 and player.combat_status().dash_ready:
		direction = to.orthogonal().normalized() * steering_side
		_move(_steer(player, direction))
		_press(&"dash")
	else:
		_move(_steer(player, direction))
		if distance > 190.0 and distance < 300.0 and player.combat_status().dash_ready:
			_press(&"dash")
	if distance < 150.0:
		_press(&"attack_heavy" if attack_count % 3 == 2 else &"attack_basic")
	if distance < 140.0 and player.special_meter.is_full():
		_press(&"special")


func _nearest_enemy(room, player):
	var best = null
	var nearest := INF
	for child in room.get_children():
		if child == player or not child.has_method(&"take_damage") or child.get("hp") == null:
			continue
		if child.hp <= 0:
			continue
		var distance: float = child.global_position.distance_squared_to(player.global_position)
		if distance < nearest:
			nearest = distance
			best = child
	return best


func _professor():
	for node in get_nodes_in_group(&"interactable"):
		if node.enabled and node.prompt == "Falar com o professor":
			return node
	return null


func _steer(player, desired: Vector2) -> Vector2:
	if desired.is_zero_approx():
		return Vector2.ZERO
	var direction := desired.normalized()
	if not player.test_move(player.global_transform, direction * 32.0):
		return direction
	for side in [steering_side, -steering_side]:
		for angle in [PI / 4.0, PI / 2.0, PI * 0.75]:
			var candidate := direction.rotated(angle * side)
			if not player.test_move(player.global_transform, candidate * 32.0):
				return candidate
	return Vector2.ZERO


func _move(direction: Vector2) -> void:
	_release_movement()
	if absf(direction.x) > 0.15:
		Input.action_press(&"move_right" if direction.x > 0 else &"move_left", absf(direction.x))
	if absf(direction.y) > 0.15:
		Input.action_press(&"move_down" if direction.y > 0 else &"move_up", absf(direction.y))


func _release_movement() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventAction.new()
	release.action = action
	Input.parse_input_event(release)


func _reported(index: int) -> bool:
	return room_reports.any(func(report: Dictionary) -> bool: return report.room == index + 1)


func _record_room(room, result: String) -> void:
	var report := {"room": int(gs.run.room) + 1, "result": result, "hp": room.player.hp,
		"elapsed": snappedf(elapsed - room_started_at, 0.01), "kills": gs.run.kills}
	room_reports.append(report)
	print("COMBAT_ROOM " + JSON.stringify(report))
