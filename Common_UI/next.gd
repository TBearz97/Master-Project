extends Node

@export var list : Array[Control]
@export var next : Button
@export var prev : Button

var idx : int = 0

func _ready() -> void:
	next.pressed.connect(_next)
	prev.pressed.connect(_prev)
	
func _next() -> void:
	if idx < list.size():
		idx += 1
		for v in list:
			v.visible = false
		list[idx].visible = true

func _prev() -> void:
	if idx > 0:
		idx -= 1
		for v in list:
			v.visible = false
		list[idx].visible = true
