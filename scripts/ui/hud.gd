class_name Hud
extends CanvasLayer
## Recursos e oportunidades de combate. Toda a camada deixa cliques chegarem ao mundo.

const CYAN := Color("67dce5")
const GOLD := Color("ffd47c")
const MUTED := Color("bdcbd2")

var player: Player
var room_text := ""
var _hp: ProgressBar
var _hp_label: Label
var _special: ProgressBar
var _special_label: Label
var _dash: ProgressBar
var _dash_label: Label
var _bits: Label
var _room: Label
var _items: Array[Label] = []
var _teachings: Label
var _prompt: Label
var _combo: Label
var _combo_hint: Label
var _notice: Label
var _boss_bar: ProgressBar
var _objective_box: PanelContainer
var _objective_title: Label
var _objective_detail: Label
var _objective_progress: ProgressBar
var _notice_tween: Tween
var _combo_tween: Tween
var _root: Control
var _special_was_full := false


func _ready() -> void:
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vitals := _panel(Control.PRESET_TOP_LEFT, Vector2(14, 12), Vector2(256, 104))
	var row := HBoxContainer.new()
	vitals.add_child(row)
	var title := UI.hud_label(row, "ALUNO", 12)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override(&"font_color", MUTED)
	_hp_label = UI.hud_label(row, "", 14)
	_hp = UI.bar(vitals, Color("ed716a"), 228, 13)
	_special_label = UI.hud_label(vitals, "[Q] ESPECIAL", 12)
	_special = UI.bar(vitals, CYAN, 228, 8)
	_special.max_value = SpecialMeter.MAX
	_special.step = 0.1
	var info := _panel(Control.PRESET_TOP_RIGHT, Vector2(-314, 12), Vector2(300, 68))
	_room = UI.hud_label(info, "", 15)
	_room.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bits = UI.hud_label(info, "", 21)
	_bits.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bits.add_theme_color_override(&"font_color", GOLD)
	var objective := _panel(Control.PRESET_CENTER_TOP, Vector2(-235, 12), Vector2(470, 0))
	_objective_box = objective.get_parent()
	_objective_title = UI.hud_label(objective, "", 16)
	_objective_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_detail = UI.hud_label(objective, "", 12)
	_objective_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_detail.add_theme_color_override(&"font_color", MUTED)
	_objective_progress = UI.bar(objective, CYAN, 440, 5)
	_objective_progress.max_value = 1.0
	_objective_progress.step = 0.001
	_objective_box.hide()
	var items := _panel(Control.PRESET_BOTTOM_LEFT, Vector2(14, -66), Vector2(300, 52))
	var item_row := HBoxContainer.new()
	items.add_child(item_row)
	for i in GameState.USABLE_ITEMS.size():
		UI.icon(item_row, GameState.item(GameState.USABLE_ITEMS[i]).icon, 28)
		_items.append(UI.hud_label(item_row, "", 13))
	var skills := _panel(Control.PRESET_CENTER_BOTTOM, Vector2(-155, -65), Vector2(310, 51))
	_dash_label = UI.hud_label(skills, "[ESPAÇO] ESQUIVA PRONTA", 13)
	_dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash = UI.bar(skills, CYAN, 282, 6)
	_dash.max_value = 1.0
	_dash.step = 0.001
	_teachings = _label("", 13, Control.PRESET_BOTTOM_RIGHT, Vector2(-300, -110), Vector2(286, 96))
	_teachings.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_teachings.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_teachings.add_theme_color_override(&"font_color", MUTED)
	_prompt = _label("", 18, Control.PRESET_CENTER_BOTTOM, Vector2(-350, -129), Vector2(700, 28))
	_combo_hint = _label("", 14, Control.PRESET_CENTER_BOTTOM, Vector2(-320, -94), Vector2(640, 24))
	_combo_hint.add_theme_color_override(&"font_color", GOLD)
	_combo = _label("", 28, Control.PRESET_CENTER_TOP, Vector2(-280, 140), Vector2(560, 36))
	_combo.add_theme_color_override(&"font_color", GOLD)
	_notice = _label("", 18, Control.PRESET_CENTER_TOP, Vector2(-380, 188), Vector2(760, 60))
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.add_theme_color_override(&"font_color", Color("fff1ce"))
	UI.ignore_mouse(self)
	GameState.bits_changed.connect(refresh)
	GameState.items_changed.connect(refresh)
	GameState.notice.connect(show_notice)
	refresh()


func _panel(preset: int, offset: Vector2, extent: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	_root.add_child(panel)
	_anchor(panel, preset, offset, extent)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.10, 0.88)
	style.border_color = Color(0.36, 0.62, 0.66, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override(&"panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 4)
	panel.add_child(col)
	return col


func _label(text: String, font_size: int, preset: int, offset: Vector2, extent: Vector2) -> Label:
	var label := UI.hud_label(_root, text, font_size)
	_anchor(label, preset, offset, extent)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _anchor(control: Control, preset: int, offset: Vector2, extent: Vector2) -> void:
	control.set_anchors_and_offsets_preset(preset)
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + extent.x
	control.offset_bottom = offset.y + extent.y


func bind_player(p: Player) -> void:
	player = p
	p.health_changed.connect(func(hp: int, max_hp: int) -> void:
		_hp.max_value = max_hp
		_hp.value = hp
		_hp_label.text = "%d / %d" % [hp, max_hp])
	p.special_meter.changed.connect(_update_special)
	p.attacked.connect(func(_kind: StringName, combo: ComboData) -> void:
		if combo:
			show_combo(combo.display_name + "!"))
	p.health_changed.emit(p.hp, p.max_hp)
	_special_was_full = p.special_meter.is_full()
	_update_special(p.special_meter.value)


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not player.has_method("combat_status"):
		return
	var status: Dictionary = player.combat_status()
	_dash.value = status.get("dash_ratio", 1.0)
	_dash_label.text = "[ESPAÇO] ESQUIVA PRONTA" if status.get("dash_ready", true) else "[ESPAÇO] RECARREGANDO"
	if status.get("dash_strike_ready", false):
		_combo_hint.text = "ATAQUE AGORA · GOLPE DE AVANÇO +35%"
	else:
		var combo: Dictionary = status.get("combo", {})
		var steps: int = combo.get("steps", 0)
		if steps > 0:
			var next := "DIREITO · PESADO" if combo.get("next_attack", &"") == &"heavy" else "ESQUERDO · BÁSICO"
			_combo_hint.text = "%s  %d/%d · %s" % [combo.get("combo_name", "COMBO"), steps, combo.get("total", 0), next]
		else:
			_combo_hint.text = "Combo: esq → esq → dir  ·  Espaço → ataque: avanço"


func _update_special(value: float) -> void:
	_special.value = value
	var full := value >= SpecialMeter.MAX
	_special_label.text = "[Q] ESPECIAL PRONTO!" if full else "[Q] ESPECIAL  %d%%" % roundi(value)
	_special_label.add_theme_color_override(&"font_color", CYAN if full else MUTED)
	if full and not _special_was_full:
		GameAudio.play(self, &"ready")
	_special_was_full = full


func refresh() -> void:
	_bits.text = "%d BITS" % GameState.wallet()
	_room.text = room_text
	for i in _items.size():
		_items[i].text = "[%d] %d  " % [i + 1, GameState.item_count(GameState.USABLE_ITEMS[i])]
	var names: Array[String] = []
	if GameState.has_run():
		for id in GameState.run.teachings:
			names.append(GameState.teaching(id).display_name)
	if names.size() > 3:
		var total := names.size()
		names = names.slice(total - 3)
		names.push_front("+%d ensinamentos" % (total - 3))
	_teachings.text = "\n".join(names)


func set_objective(title: String, detail: String = "", progress: float = -1.0) -> void:
	_objective_box.visible = not title.is_empty()
	_objective_title.text = title
	_objective_detail.text = detail
	_objective_detail.visible = not detail.is_empty()
	_objective_progress.visible = progress >= 0.0
	_objective_progress.value = clampf(progress, 0.0, 1.0)


func show_boss(boss_name: String, max_hp: int) -> void:
	var box := _panel(Control.PRESET_CENTER_TOP, Vector2(-250, 86), Vector2(500, 0))
	var title := UI.hud_label(box, boss_name, 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar = UI.bar(box, Color("c181e8"), 472, 10)
	_boss_bar.max_value = max_hp
	_boss_bar.value = max_hp
	UI.ignore_mouse(box.get_parent())


func set_boss_hp(hp: int) -> void:
	if _boss_bar:
		_boss_bar.value = hp


func set_prompt(text: String) -> void:
	_prompt.text = text


func show_combo(text: String) -> void:
	if _combo_tween:
		_combo_tween.kill()
	_combo.text = text
	_combo.modulate.a = 1.0
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo, "modulate:a", 0.0, 0.6).set_delay(0.45)


func show_notice(text: String) -> void:
	if _notice_tween:
		_notice_tween.kill()
	_notice.text = text
	_notice.modulate.a = 1.0
	_notice_tween = create_tween()
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.6).set_delay(2.8)
