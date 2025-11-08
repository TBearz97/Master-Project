extends VBoxContainer

var health = {}
var resources = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = JsonData.get_health()
	resources = JsonData.get_resources() # Replace with function body.
	update()

func update() -> void:
	%ActionPointsValue.text = str(resources["action_points"] - health["fatigue"])
	%ManaPointsValue.text = str(resources["mana_points"])
	%LuckPointsValue.text = str(resources["luck_points"])
