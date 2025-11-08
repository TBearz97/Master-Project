extends VBoxContainer

var health = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = JsonData.get_health() # Replace with function body.
	update()

func update() -> void:
	%HealthPointsValue.text = str(health["current_health"]) + "/" + str(health["max_health"] - health["necrotic_damage"])
	%VitalityValue.text = str(health["current_vitality"]) + "/" + str(health["max_vitality"])
	%NecroticDamageValue.text = str(health["necrotic_damage"])
	%FatigueValue.text = str(health["fatigue"])
