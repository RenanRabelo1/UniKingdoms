class_name Hud
extends CanvasLayer
## HUD do jogo: vida, especial, Bits, sala, itens, ensinamentos, avisos e prompt de interação.

var player: Player
var room_text := ""

var _hp: ProgressBar
var _hp_label: Label
var _special: ProgressBar
var _bits: Label
var _room: Label
var _items: Array[Label] = []
var _teachings: Label
var _prompt: Label
var _combo: Label
var _notice: Label
var _boss_bar: ProgressBar


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top_left := VBoxContainer.new()
	top_left.position = Vector2(14, 8)
	root.add_child(top_left)
	var hp_row := HBoxContainer.new()
	top_left.add_child(hp_row)
	_hp = UI.bar(hp_row, Color(0.85, 0.2, 0.2), 240, 20)
	_hp_label = UI.hud_label(hp_row, "", 16)
	_special = UI.bar(top_left, Color(0.3, 0.7, 1.0), 240, 12)
	_special.max_value = SpecialMeter.MAX

	var top_right := HBoxContainer.new()
	top_right.position = Vector2(822, 6)
	top_right.custom_minimum_size.x = 316
	top_right.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(top_right)
	_room = UI.hud_label(top_right, "", 18)
	UI.icon(top_right, load(UI.FREE_UI + "Icons/Icon_03.png"), 34)
	_bits = UI.hud_label(top_right, "0", 22)

	var bottom_left := HBoxContainer.new()
	bottom_left.position = Vector2(14, 596)
	root.add_child(bottom_left)
	for i in GameState.USABLE_ITEMS.size():
		var it := GameState.item(GameState.USABLE_ITEMS[i])
		UI.icon(bottom_left, it.icon, 36)
		_items.append(UI.hud_label(bottom_left, "", 16))

	_teachings = UI.hud_label(root, "", 14)
	_teachings.position = Vector2(860, 520)
	_teachings.size = Vector2(280, 120)
	_teachings.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_teachings.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	_prompt = UI.hud_label(root, "", 20)
	_prompt.position = Vector2(376, 560)
	_prompt.size.x = 400
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_combo = UI.hud_label(root, "", 34)
	_combo.add_theme_color_override(&"font_color", Color(1, 0.84, 0))
	_combo.position = Vector2(376, 96)
	_combo.size.x = 400
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_notice = UI.hud_label(root, "", 20)
	_notice.add_theme_color_override(&"font_color", Color(1, 0.95, 0.7))
	_notice.position = Vector2(176, 150)
	_notice.size.x = 800
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	UI.ignore_mouse(self)
	GameState.bits_changed.connect(refresh)
	GameState.items_changed.connect(refresh)
	GameState.notice.connect(show_notice)
	refresh()


func bind_player(p: Player) -> void:
	player = p
	p.health_changed.connect(func(hp: int, max_hp: int) -> void:
		_hp.max_value = max_hp
		_hp.value = hp
		_hp_label.text = "%d/%d" % [hp, max_hp])
	p.special_meter.changed.connect(func(v: float) -> void: _special.value = v)
	p.attacked.connect(func(_kind: StringName, combo: ComboData) -> void:
		if combo:
			_combo.text = combo.display_name + "!"
			_combo.modulate.a = 1.0
			create_tween().tween_property(_combo, "modulate:a", 0.0, 0.8).set_delay(0.4))
	p.health_changed.emit(p.hp, p.max_hp)


func refresh() -> void:
	_bits.text = str(GameState.wallet())
	_room.text = room_text
	for i in _items.size():
		_items[i].text = "[%d] x%d   " % [i + 1, GameState.item_count(GameState.USABLE_ITEMS[i])]
	var names := []
	if GameState.has_run():
		for id in GameState.run.teachings:
			names.append(GameState.teaching(id).display_name)
	_teachings.text = "\n".join(names)


## Barra grande do boss no topo da tela.
func show_boss(boss_name: String, max_hp: int) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(326, 40)
	box.custom_minimum_size.x = 500
	get_child(0).add_child(box)
	var title := UI.hud_label(box, boss_name, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar = UI.bar(box, Color(0.6, 0.2, 0.8), 500, 18)
	_boss_bar.max_value = max_hp
	_boss_bar.value = max_hp
	UI.ignore_mouse(box)


func set_boss_hp(hp: int) -> void:
	if _boss_bar:
		_boss_bar.value = hp


func set_prompt(text: String) -> void:
	_prompt.text = text


func show_notice(text: String) -> void:
	_notice.text = text
	_notice.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.8)
	tween.tween_property(_notice, "modulate:a", 0.0, 0.6)
