class_name Interactable
extends Node2D
## Algo com que o player interage apertando E (NPC, vitrine, portão).

signal used

@export var prompt := "Interagir"
var enabled := true


func _ready() -> void:
	add_to_group(&"interactable")


## NPC animado parado no mapa.
static func npc(anims: Dictionary, prompt_text: String, sprite_scale := 1.0) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt_text
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SheetFrames.build(anims)
	s.position = Vector2(0, -30) * sprite_scale
	s.scale = Vector2.ONE * sprite_scale
	s.autoplay = anims.keys()[0]
	it.add_child(s)
	return it
