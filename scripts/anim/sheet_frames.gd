class_name SheetFrames
## Monta SpriteFrames a partir de spritesheets em grade (Tiny Swords).
## Cada animação: [caminho, largura, altura, linha, quantidade, fps, loop, coluna_inicial (opcional)].

static var _cache := {}


static func build(anims: Dictionary) -> SpriteFrames:
	var key := str(anims)
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_name in anims:
		var a: Array = anims[anim_name]
		var tex: Texture2D = load(a[0])
		var first: int = a[7] if a.size() > 7 else 0
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, a[5])
		frames.set_animation_loop(anim_name, a[6])
		for i in a[4]:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2((first + i) * a[1], a[3] * a[2], a[1], a[2])
			frames.add_frame(anim_name, atlas)
	_cache[key] = frames
	return frames


## Animações do Warrior do Free Pack na cor pedida (Blue, Yellow, Purple, Black, Red).
static func warrior(color: String) -> Dictionary:
	var base := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/%s Units/Warrior/" % color
	return {
		"idle": [base + "Warrior_Idle.png", 192, 192, 0, 8, 10.0, true],
		"run": [base + "Warrior_Run.png", 192, 192, 0, 6, 12.0, true],
		"attack1": [base + "Warrior_Attack1.png", 192, 192, 0, 4, 16.0, false],
		"attack2": [base + "Warrior_Attack2.png", 192, 192, 0, 4, 12.0, false],
	}
