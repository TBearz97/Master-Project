extends Node

const DB_PATH := "res://data/Codex2.db"
const IMPORT_ROOT := "res://data/Imported"

@export var run_on_ready: bool = true
@export var wipe_existing_files: bool = true
@export var log_progress: bool = true
@export var quit_when_done: bool = true


func _ready() -> void:
	if not run_on_ready:
		return

	var ok := rebuild_from_database()
	if quit_when_done:
		get_tree().quit(0 if ok else 1)


func rebuild_from_database() -> bool:
	var db := SQLite.new()
	db.path = DB_PATH
	if not db.open_db():
		push_error("Failed to open database: %s" % DB_PATH)
		return false

	_prepare_output_root()
	if wipe_existing_files:
		_wipe_existing_imports()

	var ok := true
	ok = _import_attributes(db) and ok
	ok = _import_skills(db) and ok
	ok = _import_defenses(db) and ok
	ok = _import_conditions(db) and ok
	ok = _import_perks(db) and ok
	ok = _import_races(db) and ok
	ok = _import_homelands(db) and ok
	ok = _import_backgrounds(db) and ok
	ok = _import_attacks(db) and ok
	ok = _import_weapons(db) and ok
	ok = _import_armor(db) and ok
	ok = _import_clothing(db) and ok
	ok = _import_consumables(db) and ok
	ok = _import_utilities(db) and ok
	ok = _import_npcs(db) and ok
	ok = _import_modifiers(db) and ok
	ok = _import_damage_origins(db) and ok
	ok = _import_damage_types(db) and ok
	ok = _import_effects(db) and ok
	ok = _import_ranges(db) and ok
	ok = _import_resources(db) and ok
	ok = _import_spell_schools(db) and ok
	ok = _import_spells(db) and ok
	ok = _import_spell_variants(db) and ok
	ok = _import_item_effects(db) and ok
	ok = _import_keywords(db) and ok
	ok = _import_level_progression(db) and ok
	ok = _import_skill_rank_costs(db) and ok
	ok = _import_starter_packs(db) and ok
	ok = _import_starter_pack_items(db) and ok
	ok = _import_strain_table(db) and ok
	ok = _import_weapon_qualities(db) and ok

	db.close_db()

	if ok and log_progress:
		print("Finished rebuilding imported .tres files from Codex2.db")

	return ok


func _import_attributes(db: SQLite) -> bool:
	return _import_named_table(db, "attributes", "res://content/codex/imported/attribute.gd")


func _import_skills(db: SQLite) -> bool:
	return _import_named_table(db, "skills", "res://content/codex/imported/skill.gd")


func _import_defenses(db: SQLite) -> bool:
	return _import_named_table(db, "defenses", "res://content/codex/imported/defense.gd")


func _import_conditions(db: SQLite) -> bool:
	return _import_named_table(db, "conditions", "res://content/codex/imported/condition.gd")


func _import_perks(db: SQLite) -> bool:
	return _import_named_table(db, "perks", "res://content/codex/imported/perk.gd")


func _import_races(db: SQLite) -> bool:
	return _import_named_table(db, "races", "res://content/codex/imported/race.gd")


func _import_homelands(db: SQLite) -> bool:
	return _import_named_table(db, "homelands", "res://content/codex/imported/homeland.gd")


func _import_backgrounds(db: SQLite) -> bool:
	return _import_named_table(db, "backgrounds", "res://content/codex/imported/background.gd")


func _import_attacks(db: SQLite) -> bool:
	return _import_named_table(db, "attacks", "res://content/codex/imported/attack.gd")


func _import_weapons(db: SQLite) -> bool:
	var rows := _query(db, "SELECT * FROM weapons ORDER BY name")
	return _save_rows("weapons", rows, func(row: Dictionary) -> CodexItem:
		return _build_weapon_item(row)
	)


func _import_armor(db: SQLite) -> bool:
	return _import_named_table(db, "armor", "res://content/codex/imported/armor.gd")


func _import_clothing(db: SQLite) -> bool:
	return _import_named_table(db, "clothing", "res://content/codex/imported/clothing.gd")


func _import_consumables(db: SQLite) -> bool:
	return _import_named_table(db, "consumables", "res://content/codex/imported/consumable.gd")


func _import_utilities(db: SQLite) -> bool:
	return _import_named_table(db, "utilities", "res://content/codex/imported/utility.gd")


func _import_npcs(db: SQLite) -> bool:
	return _import_named_table(db, "npcs", "res://content/codex/imported/npc.gd")


func _import_modifiers(db: SQLite) -> bool:
	return _import_named_table(db, "modifiers", "res://content/codex/imported/modifier.gd")


func _import_damage_origins(db: SQLite) -> bool:
	return _import_named_table(db, "damage_origins", "res://content/codex/imported/damage_origin.gd")


func _import_damage_types(db: SQLite) -> bool:
	return _import_named_table(db, "damage_types", "res://content/codex/imported/damage_type.gd")


func _import_effects(db: SQLite) -> bool:
	return _import_named_table(db, "effects", "res://content/codex/imported/effect.gd")


func _import_ranges(db: SQLite) -> bool:
	return _import_named_table(db, "ranges", "res://content/codex/imported/range.gd")


func _import_resources(db: SQLite) -> bool:
	return _import_named_table(db, "resources", "res://content/codex/imported/resource_pool.gd")


func _import_spell_schools(db: SQLite) -> bool:
	return _import_named_table(db, "spell_schools", "res://content/codex/imported/spell_school.gd")


func _import_spells(db: SQLite) -> bool:
	return _import_named_table(db, "spells", "res://content/codex/imported/spell.gd")


func _import_spell_variants(db: SQLite) -> bool:
	return _import_position_table(db, "spell_variants", "res://content/codex/imported/spell_variant.gd", "spell_id", "ordinal_position")


func _import_item_effects(db: SQLite) -> bool:
	return _import_id_table(db, "item_effects", "res://content/codex/imported/item_effect.gd")


func _import_keywords(db: SQLite) -> bool:
	return _import_id_table(db, "keywords", "res://content/codex/imported/keyword.gd")


func _import_level_progression(db: SQLite) -> bool:
	return _import_value_table(db, "level_progression", "res://content/codex/imported/level_progression.gd", "level_value")


func _import_skill_rank_costs(db: SQLite) -> bool:
	return _import_value_table(db, "skill_rank_costs", "res://content/codex/imported/skill_rank_cost.gd", "target_rank")


func _import_starter_packs(db: SQLite) -> bool:
	return _import_named_table(db, "starter_packs", "res://content/codex/imported/starter_pack.gd")


func _import_starter_pack_items(db: SQLite) -> bool:
	return _import_id_table(db, "starter_pack_items", "res://content/codex/imported/starter_pack_item.gd")


func _import_strain_table(db: SQLite) -> bool:
	return _import_value_table(db, "strain_table", "res://content/codex/imported/strain_result.gd", "roll_total")


func _import_weapon_qualities(db: SQLite) -> bool:
	return _import_named_table(db, "weapon_qualities", "res://content/codex/imported/weapon_quality.gd")


func _import_named_table(db: SQLite, table_name: String, script_path: String) -> bool:
	var rows := _query(db, "SELECT * FROM %s ORDER BY name" % table_name)
	return _save_rows(table_name, rows, func(row: Dictionary) -> CodexItem:
		return _make_named_item(script_path, row)
	)


func _import_id_table(db: SQLite, table_name: String, script_path: String) -> bool:
	var rows := _query(db, "SELECT * FROM %s ORDER BY id" % table_name)
	return _save_rows(table_name, rows, func(row: Dictionary) -> CodexItem:
		var fallback_name := "%s %s" % [_label_for_table(table_name), _text(row, "id")]
		return _make_named_item(script_path, row, fallback_name)
	)


func _import_value_table(db: SQLite, table_name: String, script_path: String, key_name: String) -> bool:
	var rows := _query(db, "SELECT * FROM %s ORDER BY %s" % [table_name, key_name])
	return _save_rows(table_name, rows, func(row: Dictionary) -> CodexItem:
		var fallback_name := "%s %s" % [_label_for_table(table_name), _text(row, key_name)]
		return _make_named_item(script_path, row, fallback_name)
	)


func _import_position_table(db: SQLite, table_name: String, script_path: String, foreign_key: String, position_key: String) -> bool:
	var rows := _query(db, "SELECT * FROM %s ORDER BY %s, %s" % [table_name, foreign_key, position_key])
	return _save_rows(table_name, rows, func(row: Dictionary) -> CodexItem:
		var fallback_name := "%s %s %s" % [_label_for_table(table_name), _text(row, foreign_key), _text(row, position_key)]
		return _make_named_item(script_path, row, fallback_name)
	)


func _save_rows(table_name: String, rows: Array, item_builder: Callable) -> bool:
	var folder_path := "%s/%s" % [IMPORT_ROOT, table_name]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder_path))

	var ok := true
	var used_names := {}
	for row in rows:
		var item := item_builder.call(row) as CodexItem
		if item == null:
			push_error("Failed building CodexItem for table %s" % table_name)
			ok = false
			continue

		var resource_name := item._name
		if resource_name.is_empty():
			push_error("CodexItem from table %s is missing _name" % table_name)
			ok = false
			continue

		var path := "%s/%s.tres" % [folder_path, _unique_file_name(resource_name, used_names)]
		var error := ResourceSaver.save(item, path)
		if error != OK:
			push_error("Failed saving %s (error %s)" % [path, error])
			ok = false
		elif log_progress:
			print("Saved %s" % path)

	return ok


func _make_named_item(script_path: String, row: Dictionary, fallback_name: String = "") -> CodexItem:
	var item := _make_item(script_path, row)
	if item == null:
		return null
	if item._name.is_empty():
		item._name = fallback_name
	return item


func _build_weapon_item(row: Dictionary) -> CodexItem:
	var item := _make_item("res://content/codex/imported/weapon.gd", {})
	if item == null:
		return null

	item._name = _text(row, "name")
	item.short_description = _text(row, "short_description")
	item.long_description = _text(row, "long_description")

	_set_if_present(item, "id", _int(row, "id"))
	_set_if_present(item, "weapon_class", _text(row, "weapon_class"))
	_set_if_present(item, "damage_die", _text(row, "damage_die"))
	_set_if_present(item, "crit_die", _int(row, "crit_die"))
	_set_if_present(item, "base_speed", _int(row, "base_speed"))
	_set_if_present(item, "range_band", _text(row, "range_band"))
	_set_if_present(item, "handedness", _text(row, "handedness"))
	_set_if_present(item, "basic_attack_id", _int(row, "basic_attack_id"))
	_set_if_present(item, "proficient_attack_id", _int(row, "proficient_attack_id"))
	_set_if_present(item, "expert_attack_id", _int(row, "expert_attack_id"))
	_set_if_present(item, "master_attack_id", _int(row, "master_attack_id"))
	_set_if_present(item, "qualities", _split_csv(_text(row, "qualities")))
	_set_if_present(item, "cost", _float(row, "cost"))
	_set_if_present(item, "weight", _float(row, "weight"))

	return item


func _make_item(script_path: String, row: Dictionary) -> CodexItem:
	var script := load(script_path)
	if script == null:
		push_error("Missing script: %s" % script_path)
		return null

	var resource := Resource.new()
	resource.set_script(script)
	_apply_row(resource, row)
	return resource as CodexItem


func _apply_row(resource: Resource, row: Dictionary) -> void:
	for key in row.keys():
		var property_name := _target_property_name(str(key))
		if not _has_property(resource, property_name):
			continue
		resource.set(property_name, _convert_value(row[key]))


func _set_if_present(resource: Resource, property_name: String, value: Variant) -> void:
	if _has_property(resource, property_name):
		resource.set(property_name, value)


func _target_property_name(column_name: String) -> String:
	match column_name:
		"name":
			return "_name"
		_:
			return column_name


func _convert_value(value: Variant) -> Variant:
	if typeof(value) != TYPE_STRING:
		return value

	var text := str(value).strip_edges()
	if text.is_empty():
		return value

	if (text.begins_with("{") and text.ends_with("}")) or (text.begins_with("[") and text.ends_with("]")):
		var parsed = JSON.parse_string(text)
		if parsed != null:
			return parsed

	return value


func _has_property(resource: Resource, property_name: String) -> bool:
	for property_info in resource.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true
	return false


func _label_for_table(table_name: String) -> String:
	return table_name.replace("_", " ").capitalize()


func _prepare_output_root() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(IMPORT_ROOT))


func _wipe_existing_imports() -> void:
	_remove_tres_files_recursively(IMPORT_ROOT)


func _remove_tres_files_recursively(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var child_path := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			if entry != "." and entry != "..":
				_remove_tres_files_recursively(child_path)
		elif entry.ends_with(".tres"):
			dir.remove(entry)
		entry = dir.get_next()


func _unique_file_name(resource_name: String, used_names: Dictionary) -> String:
	var base_name := _safe_file_name(resource_name)
	if base_name.is_empty():
		base_name = "entry"
	var count := int(used_names.get(base_name, 0))
	used_names[base_name] = count + 1
	if count == 0:
		return base_name
	return "%s-%s" % [base_name, count + 1]


func _safe_file_name(value: String) -> String:
	return value.replace("/", "-").replace("\\", "-").replace(":", "").replace("?", "").replace("*", "").replace("\"", "").replace("<", "").replace(">", "").replace("|", "").strip_edges()


func _text(row: Dictionary, key: String) -> String:
	if not row.has(key) or row[key] == null:
		return ""
	return str(row[key])


func _int(row: Dictionary, key: String) -> int:
	if not row.has(key) or row[key] == null:
		return 0
	return int(row[key])


func _float(row: Dictionary, key: String) -> float:
	if not row.has(key) or row[key] == null:
		return 0.0
	return float(row[key])


func _split_csv(value: String) -> Array[String]:
	var result: Array[String] = []
	for token in value.split(",", false):
		var trimmed := token.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result


func _query(db: SQLite, sql: String) -> Array:
	if not db.query(sql):
		push_error("SQL query failed: %s" % sql)
		return []
	return db.query_result
