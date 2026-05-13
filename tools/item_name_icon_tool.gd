extends Node

const ICON_SIZE := Vector2i(256, 256)
const OUTPUT_DIR := "res://Art/Icons/Items"
const MAX_CODEX_WAIT_FRAMES := 30
const NAME_ICON_SCENE: PackedScene = preload("res://tools/NameIcon.tscn")

func _ready() -> void:
	await generate_all_icons()
	get_tree().quit()

func generate_all_icons() -> void:
	var codex: Codex = await _wait_for_codex()
	if codex == null:
		push_error("Item name icon generation failed: CampaignVariables.codex is unavailable.")
		return

	if NAME_ICON_SCENE == null:
		push_error("Item name icon generation failed: res://tools/NameIcon.tscn could not be loaded.")
		return

	var output_dir_path := ProjectSettings.globalize_path(OUTPUT_DIR)
	var make_dir_result := DirAccess.make_dir_recursive_absolute(output_dir_path)
	if make_dir_result != OK:
		push_error("Item name icon generation failed: could not create %s. Error code: %s" % [output_dir_path, make_dir_result])
		return

	var item_names: Array[String] = codex.Items.keys()
	item_names.sort()

	var generated_count := 0
	for item_name in item_names:
		var item: Item = codex.Items.get(item_name, null)
		if item == null:
			continue

		var save_result := await _generate_icon(item)
		if save_result == OK:
			generated_count += 1
		else:
			push_error("Failed to generate item icon for %s. Error code: %s" % [item._name, save_result])

	print("Item name icon generation finished. Generated %s icons." % generated_count)

func _generate_icon(item: Item) -> Error:
	var viewport := SubViewport.new()
	viewport.size = ICON_SIZE
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)

	var root := Control.new()
	root.size = Vector2(ICON_SIZE.x, ICON_SIZE.y)
	viewport.add_child(root)

	var icon := NAME_ICON_SCENE.instantiate() as Control
	if icon == null:
		viewport.queue_free()
		return ERR_CANT_CREATE

	root.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not icon.has_method("set_item_name"):
		viewport.queue_free()
		return ERR_METHOD_NOT_FOUND
	icon.call("set_item_name", item._name)

	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image := viewport.get_texture().get_image()
	var save_path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(item._name + ".png"))
	var save_result := image.save_png(save_path)

	viewport.queue_free()
	return save_result

func _wait_for_codex() -> Codex:
	for _frame in range(MAX_CODEX_WAIT_FRAMES):
		if CampaignVariables != null and CampaignVariables.codex != null:
			return CampaignVariables.codex
		await get_tree().process_frame
	return null
