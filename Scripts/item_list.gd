extends ItemList

var skills_dict = {}

var icon1 : Texture2D = load("res://Art/Icons/Icon2.png")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	skills_dict = JsonData.get_skills()
	for key in skills_dict:
		self.add_item(str(key), icon1, false)
		self.add_item(str(skills_dict[key]))
