extends VBoxContainer

@export var points : SpinBox
@export var selected : ItemList
@export var weaponGrid : GridContainer
@export var armorGrid : GridContainer
@export var clothingGrid : GridContainer
@export var consumableGrid : GridContainer
@export var utilityItemGrid : GridContainer


func _ready() -> void:
	_setup()

func _setup ():
	DbHelper.item_chosen.connect(_on_item_chosen)
	selected.item_selected.connect(_on_selected)
	DbHelper.populate_weapons_grid(weaponGrid)
	DbHelper.populate_armor_grid(armorGrid)
	DbHelper.populate_clothing_grid(clothingGrid)
	DbHelper.populate_consumables_grid(consumableGrid)
	DbHelper.populate_utility_grid(utilityItemGrid)
		

func _on_item_chosen(perk: Dictionary) -> void:
	if points.value - perk["cost"] >= 0:
		for i in selected.item_count:
			var curr_Item = selected.get_item_text(i)
			var parts = curr_Item.split(" x")
			if parts[0] == perk["name"]:
				var count := 1
				if parts.size() > 1:
					count = int(parts[1])
				count += 1
				selected.set_item_text(i, "%s x%d" % [parts[0], count])
				selected.set_item_metadata(selected.item_count - 1, perk["cost"])
				points.value -= perk["cost"]
				return 
		
		var idx = selected.add_item(perk["name"])
		selected.set_item_metadata(idx, perk)
		points.value -= perk["cost"]
	
func _on_selected(index: int) -> void:
	var curr_Item = selected.get_item_text(index)
	var parts = curr_Item.split(" x")
	if parts.size() > 1:
		var count = int(parts[1]) - 1
		points.value += selected.get_item_metadata(index)["cost"]
		if count == 1 :
			selected.set_item_text(index, parts[0])
		else :
			selected.set_item_text(index, "%s x%d" % [parts[0], count])
		selected.deselect(index)
	else :
		points.value += selected.get_item_metadata(index)["cost"]
		selected.remove_item(index)
	

func _item_exists(_iList : ItemList, _name : String) -> bool :
	for i in range(_iList.item_count) :
		if _iList.get_item_text(i) == _name:
			return true
	return false

func _save ():
	var items = []
	for i in range(selected.item_count) :
		items.append(selected.get_item_metadata(i))
	PlayerVariables.inventory = items
	PlayerVariables.money = points.value
