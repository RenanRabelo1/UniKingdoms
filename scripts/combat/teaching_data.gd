class_name TeachingData
extends Resource
## Ensinamento temporário (vale só na run), oferecido por um professor.

@export var id: StringName
@export var display_name: String
@export var professor: String
@export var description: String
## Chave de Constants.STAT_KEYS e quanto soma.
@export var stat: StringName
@export var amount := 0.0
## Cura imediata ao escolher.
@export var heal := 0
## Só entra no pool depois de conquistar o CCT.
@export var locked := false
