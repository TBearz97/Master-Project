extends Node

var characterSheetData = {}
var characterSheetPath = "res://JSON/CharacterSheet.json"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	characterSheetData = load_json_data(characterSheetPath)

#region stats
func get_attributes():
	return characterSheetData["stats"]["attributes"]

func get_health():
	return characterSheetData["stats"]["health"]

func get_resources():
	return characterSheetData["stats"]["resources"]
	
func get_defenses():
	return characterSheetData["stats"]["defenses"]

func set_attributes(change : Dictionary) -> void:
	characterSheetData["stats"]["attributes"] = change

func set_health(change : Dictionary) -> void:
	characterSheetData["stats"]["health"] = change

func set_resources(change : Dictionary) -> void:
	characterSheetData["stats"]["resources"] = change
	
func set_defenses(change : Dictionary) -> void:
	characterSheetData["stats"]["defenses"] = change
#endregion

func get_skills():
	return characterSheetData["skills"]
	

	
func load_json_data(filePath: String):
	if FileAccess.file_exists(filePath):
		var file = FileAccess.open(filePath, FileAccess.READ)
		var parsedResult = JSON.parse_string(file.get_as_text())
		if parsedResult is Dictionary:
			file.close()
			return parsedResult
		else:
			print("Error!")
			
func _save_json(fileLocation : String, jsonString : Dictionary):
	var writeFile = FileAccess.open(fileLocation, FileAccess.WRITE)
	var jsonStringStringified = JSON.stringify(jsonString, "\t")
	writeFile.store_string(jsonStringStringified)
	writeFile.close()
	
