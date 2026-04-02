extends Resource
class_name CodexItem

@export var id: int
@export var _name: String
@export var short_description: String
@export var long_description: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "") -> void:
	id = idDB
	_name = _nameDB
	short_description = short_descriptionDB
	long_description = long_descriptionDB

func save_to_codex(folder_name: String) -> void:
	if _name.is_empty():
		push_error("Cannot save CodexItem without a name.")
		return

	var path := "res://data/%s/%s.res" % [folder_name, _name]
	var error := ResourceSaver.save(self, path)
	if error != OK:
		push_error("Failed to save %s to %s: %s" % [_name, path, error])
