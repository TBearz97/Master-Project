extends Node2D

var dir = DirAccess.open("user://")

func _ready():
	if not dir.dir_exists("."):
		dir.make_dir(".")
	print(OS.get_user_data_dir())  # This will ensure the base user:// path exists
