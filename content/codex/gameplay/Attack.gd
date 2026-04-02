extends Action
class_name Attack


func _init(_nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", ap_costDB: int = 0, speedDB: int = 0, expressionsDB: Array[String] = []) -> void:
	super(_nameDB, short_descriptionDB, long_descriptionDB, ap_costDB, speedDB, expressionsDB)
