extends Control

@onready var name_label: Label = %NameLabel

func set_item_name(text: String) -> void:
	name_label.text = text
