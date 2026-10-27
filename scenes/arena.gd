extends Node2D
## Arena de teste do combate: liga o player ao HUD.

@onready var player: Player = $Player
@onready var special_bar: ProgressBar = $HUD/SpecialBar
@onready var combo_label: Label = $HUD/ComboLabel


func _ready() -> void:
	special_bar.max_value = SpecialMeter.MAX
	player.special_meter.changed.connect(func(v: float) -> void: special_bar.value = v)
	player.attacked.connect(_on_player_attacked)


func _on_player_attacked(_kind: StringName, combo: ComboData) -> void:
	if not combo:
		return
	combo_label.text = combo.display_name + "!"
	combo_label.modulate.a = 1.0
	create_tween().tween_property(combo_label, "modulate:a", 0.0, 0.8).set_delay(0.4)
