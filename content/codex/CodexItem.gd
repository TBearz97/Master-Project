extends Resource
class_name CodexItem

@export var _name: String
@export var short_description: String
@export var long_description: String

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "") -> void:
	_name = __name
	short_description = shortDescription
	long_description = longDescription

func save_to_codex(folder_name: String) -> void:
	if _name.is_empty():
		push_error("Cannot save CodexItem without a name.")
		return

	var path := "res://data/%s/%s.res" % [folder_name, _name]
	var error := ResourceSaver.save(self, path)
	if error != OK:
		push_error("Failed to save %s to %s: %s" % [_name, path, error])
