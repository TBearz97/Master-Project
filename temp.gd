@tool
extends Node

const ICON_SIZE := Vector2i(256, 256)
const OUTPUT_DIR := "res://Art/Icons/Items/"

@export var name_icon_scene: PackedScene

func _ready() -> void:
	generate_all_icons()

func generate_all_icons() -> void:
	if CampaignVariables == null:
		return

	var codex: Variant = CampaignVariables.get("codex")
	if codex == null:
		return

	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	for item in codex.Items.values():
		_generate_icon(item)

	print("Name icon generation finished.")

func _generate_icon(item: Item) -> void:
	var viewport := SubViewport.new()
	viewport.size = ICON_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)

	var root := Control.new()
	root.size = ICON_SIZE
	viewport.add_child(root)

	var icon := name_icon_scene.instantiate()
	root.add_child(icon)
	icon.set_item_name(item._name)

	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image := viewport.get_texture().get_image()
	image.save_png(OUTPUT_DIR + item._name + ".png")

	viewport.queue_free()
