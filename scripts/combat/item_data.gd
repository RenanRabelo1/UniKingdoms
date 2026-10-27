class_name ItemData
extends Resource
## Item de mercado. Comprado fora da run vai para o estoque (persiste se não usado);
## comprado dentro da run só vale naquela run.

@export var id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var price := 20
## heal: cura `amount`; special: enche `amount`% da barra; teaching: ensina um ensinamento;
## max_hp: passivo, soma `amount` de vida máxima na run (consumido ao entrar).
@export_enum("heal", "special", "teaching", "max_hp") var effect := "heal"
@export var amount := 0.0
