# Weapon.gd
# Godot 4.x
class_name Weapon
extends RefCounted

# Represent size in a clear, typed way.
enum Handedness { ONE_HANDED, TWO_HANDED }

var weapon_name: String
var damage_multiplier: float
var base_speed: int
var qualities: PackedStringArray            # e.g. ["Parry", "Accurate"]
var handedness: Handedness                  # derived from "1H" / "2H"
var weight: float
var cost: int
var range_in_units: int                     # tiles/meters/etc.; 0 if not applicable

# ---------- Construction ----------

# Convenience: build from a SQLite result row (Dictionary of column -> value).
# Expects columns like in your screenshot:
# weapon, damage_multiplier, base_speed, qualities, size, weight, cost, range
static func from_sql_row(row: Dictionary) -> Weapon:
	var w := Weapon.new()
	w.weapon_name        = _read_text(row, "weapon")
	w.damage_multiplier  = float(_read_number(row, "damage_multiplier", 1.0))
	w.base_speed         = int(_read_number(row, "base_speed", 25))
	w.qualities          = _parse_qualities(_read_text(row, "qualities"))
	w.handedness         = _parse_handedness(_read_text(row, "size"))
	w.weight             = float(_read_number(row, "weight", 0.0))
	w.cost               = int(_read_number(row, "cost", 0))
	w.range_in_units     = int(_read_number(row, "range", 0))
	return w

# If you prefer a direct constructor, you can wrap from_sql_row:
func _init(name: String):
	DbHelper.db_fetch()
	if row.size() > 0:
		var built := Weapon.from_sql_row(row)
		weapon_name       = built.weapon_name
		damage_multiplier = built.damage_multiplier
		base_speed        = built.base_speed
		qualities         = built.qualities
		handedness        = built.handedness
		weight            = built.weight
		cost              = built.cost
		range_in_units    = built.range_in_units

# ---------- Queries / helpers ----------

func has_quality(quality_name: String) -> bool:
	return qualities.has(quality_name)

func is_two_handed() -> bool:
	return handedness == Handedness.TWO_HANDED

# Example calculation hook you can adapt to your combat rules:
# base_damage is the raw damage of the attack before the weapon multiplier.
func calculate_total_damage(base_damage: float) -> float:
	return base_damage * damage_multiplier

# You can adapt this to apply traits (e.g., "Accurate" or "Brutal") later.
func get_effective_speed() -> int:
	return base_speed


# ---------- Internal parsing ----------

static func _read_text(row: Dictionary, key: String) -> String:
	var v = row.get(key, "")
	if v == null: return ""
	if typeof(v) == TYPE_STRING and v.to_upper() == "NULL":
		return ""
	return str(v).strip_edges()

static func _read_number(row: Dictionary, key: String, default_value: float) -> float:
	var v = row.get(key, default_value)
	if v == null: return default_value
	if typeof(v) == TYPE_STRING and v.to_upper() == "NULL":
		return default_value
	return float(v)

static func _parse_qualities(text: String) -> PackedStringArray:
	if text == "": 
		return PackedStringArray()
	# Split on commas, trim whitespace, drop empties and "NULL"
	var parts := text.split(",", false)
	var out: PackedStringArray = []
	for p in parts:
		var t := String(p).strip_edges()
		if t != "" and t.to_upper() != "NULL":
			out.append(t)
	return out

static func _parse_handedness(size_text: String) -> Handedness:
	match size_text:
		"2H": return Handedness.TWO_HANDED
		"1H": return Handedness.ONE_HANDED
		_:    return Handedness.ONE_HANDED
