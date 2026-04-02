import sqlite3
from pathlib import Path


ROOT = Path(r"C:\Users\torb1\Documents\GitHub\Master-Project")
INSERT_PATH = ROOT / "sql" / "codex2_insert.sql"


def q(con: sqlite3.Connection, sql: str, params: tuple = ()):
    return con.execute(sql, params).fetchall()


def esc(val):
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    return "'" + str(val).replace("'", "''") + "'"


def insert(out: list[str], table: str, columns: list[str], rows: list[tuple]):
    for row in rows:
        vals = ", ".join(esc(v) for v in row)
        out.append(
            f"INSERT OR IGNORE INTO {table} ({', '.join(columns)}) VALUES ({vals});"
        )


def item_table_for_category(cat: str | None) -> str:
    if cat in ("Melee Weapon", "Ranged Weapon"):
        return "weapons"
    if cat == "Armor":
        return "armor"
    if cat in ("Food", "Beverage", "Potion or Herb", "Poison"):
        return "consumables"
    if cat in ("Tool or Utility", "Crafting Tool", "Instrument"):
        return "utilities"
    if cat in ("Clothing", "Outfit"):
        return "clothing"
    return "items"


def main() -> None:
    old_sql = INSERT_PATH.read_text(encoding="utf-8")

    con = sqlite3.connect(":memory:")
    con.row_factory = sqlite3.Row
    con.executescript(
        """
        CREATE TABLE resources (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE defenses (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE damage_origins (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE damage_types (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE ranges (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, short_code TEXT UNIQUE, min_distance INTEGER, max_distance INTEGER, description TEXT);
        CREATE TABLE effects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT, defense_id INTEGER);
        CREATE TABLE conditions (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE weapon_qualities (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE keywords (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE spell_schools (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE magical_identities (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT, spell_school_id INTEGER);
        CREATE TABLE languages (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE);
        CREATE TABLE attributes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT, min_value INTEGER, max_value INTEGER);
        CREATE TABLE attribute_progression (attribute_id INTEGER, attribute_value INTEGER, metric_name TEXT, metric_value_text TEXT, UNIQUE(attribute_id, attribute_value, metric_name));
        CREATE TABLE skills (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT, min_rank INTEGER, max_rank INTEGER);
        CREATE TABLE skill_rank_costs (target_rank INTEGER PRIMARY KEY, point_cost INTEGER);
        CREATE TABLE perks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, category TEXT, description TEXT, UNIQUE(name, category));
        CREATE TABLE races (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT, perk_id INTEGER);
        CREATE TABLE homelands (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT, perk_id INTEGER);
        CREATE TABLE homeland_languages (homeland_id INTEGER, language_id INTEGER, UNIQUE(homeland_id, language_id));
        CREATE TABLE backgrounds (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT, perk_id INTEGER);
        CREATE TABLE background_skills (background_id INTEGER, skill_id INTEGER, ordinal_position INTEGER, UNIQUE(background_id, skill_id));
        CREATE TABLE level_progression (level_value INTEGER PRIMARY KEY, xp_required INTEGER, formula_text TEXT, skill_points_gained INTEGER, perks_gained INTEGER);
        CREATE TABLE item_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, parent_category_id INTEGER, description TEXT);
        CREATE TABLE items (id INTEGER PRIMARY KEY AUTOINCREMENT, category_id INTEGER, name TEXT, description TEXT, cost_gold REAL, weight REAL, size_code TEXT, UNIQUE(name, category_id));
        CREATE TABLE item_effects (id INTEGER PRIMARY KEY AUTOINCREMENT, item_id INTEGER, effect_type TEXT, effect_text TEXT, duration_text TEXT, addictive INTEGER, ordinal_position INTEGER);
        CREATE TABLE weapons (item_id INTEGER PRIMARY KEY, weapon_class TEXT, damage_die TEXT, base_speed INTEGER, range_id INTEGER, handedness TEXT, attack_package_notes TEXT);
        CREATE TABLE weapon_quality_map (weapon_item_id INTEGER, weapon_quality_id INTEGER, UNIQUE(weapon_item_id, weapon_quality_id));
        CREATE TABLE armor (item_id INTEGER PRIMARY KEY, armor_class TEXT, physical_dt INTEGER, magical_dt INTEGER, necrotic_dt INTEGER, equip_load REAL);
        CREATE TABLE starter_packs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, leftover_gold REAL);
        CREATE TABLE starter_pack_items (starter_pack_id INTEGER, item_id INTEGER, quantity INTEGER, loadout_group TEXT, UNIQUE(starter_pack_id, item_id, loadout_group));
        CREATE TABLE attacks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, attack_tier TEXT, description TEXT);
        CREATE TABLE weapon_attack_packages (weapon_item_id INTEGER, attack_id INTEGER, ordinal_position INTEGER, UNIQUE(weapon_item_id, attack_id));
        CREATE TABLE spells (id INTEGER PRIMARY KEY AUTOINCREMENT, spell_school_id INTEGER, name TEXT, difficulty_value TEXT, range_id INTEGER, base_cast_text TEXT, UNIQUE(spell_school_id, name));
        CREATE TABLE spell_tags (spell_id INTEGER, keyword_id INTEGER, UNIQUE(spell_id, keyword_id));
        CREATE TABLE spell_variants (id INTEGER PRIMARY KEY AUTOINCREMENT, spell_id INTEGER, name TEXT, mana_cost_text TEXT, description TEXT, ordinal_position INTEGER);
        CREATE TABLE strain_table (roll_total INTEGER PRIMARY KEY, result_name TEXT, result_text TEXT);
        CREATE TABLE npc_types (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE npc_reactions (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, description TEXT);
        CREATE TABLE npc_xp_awards (npc_level INTEGER, npc_type_id INTEGER, xp_award INTEGER, formula_text TEXT, PRIMARY KEY(npc_level, npc_type_id));
        """
    )
    con.executescript(old_sql)

    out: list[str] = ["BEGIN TRANSACTION;"]

    insert(
        out,
        "resources",
        ["id", "name", "short_description", "long_description"],
        [
            (r["id"], r["name"], "", r["description"] or "")
            for r in q(con, "SELECT * FROM resources ORDER BY id")
        ],
    )
    insert(
        out,
        "defenses",
        ["id", "name", "short_description", "long_description"],
        [
            (r["id"], r["name"], "", r["description"] or "")
            for r in q(con, "SELECT * FROM defenses ORDER BY id")
        ],
    )
    insert(
        out,
        "damage_origins",
        ["id", "name", "short_description", "long_description"],
        [
            (r["id"], r["name"], "", r["description"] or "")
            for r in q(con, "SELECT * FROM damage_origins ORDER BY id")
        ],
    )
    insert(
        out,
        "damage_types",
        ["id", "name", "short_description", "long_description"],
        [
            (r["id"], r["name"], "", r["description"] or "")
            for r in q(con, "SELECT * FROM damage_types ORDER BY id")
        ],
    )
    insert(
        out,
        "conditions",
        ["id", "name", "short_description", "long_description"],
        [
            (r["id"], r["name"], "", r["description"] or "")
            for r in q(con, "SELECT * FROM conditions ORDER BY id")
        ],
    )
    insert(
        out,
        "effects",
        ["id", "name", "short_description", "long_description", "defense_id"],
        [
            (r["id"], r["name"], "", r["description"] or "", r["defense_id"])
            for r in q(con, "SELECT * FROM effects ORDER BY id")
        ],
    )
    insert(
        out,
        "weapon_qualities",
        ["id", "name", "short_description", "long_description"],
        [
            (r["id"], r["name"], "", r["description"] or "")
            for r in q(con, "SELECT * FROM weapon_qualities ORDER BY id")
        ],
    )
    insert(
        out,
        "spell_schools",
        ["id", "name", "short_description", "long_description"],
        [
            (r["id"], r["name"], "", r["description"] or "")
            for r in q(con, "SELECT * FROM spell_schools ORDER BY id")
        ],
    )
    insert(
        out,
        "ranges",
        ["id", "name", "short_description", "long_description", "max_distance"],
        [
            (
                r["id"],
                r["name"],
                r["short_code"] or "",
                r["description"] or "",
                r["max_distance"],
            )
            for r in q(con, "SELECT * FROM ranges ORDER BY id")
        ],
    )

    modifier_specs = {
        "Might": [
            (1, "Damage & Healing", "%", "(x - 5) * 7"),
            (2, "Max Carry Weight", "kg", "(x * 10) + 45"),
        ],
        "Dexterity": [
            (3, "Action Points", "", "x + 6 - floor(x / 4)"),
            (4, "Deflection", "", "x"),
        ],
        "Constitution": [
            (5, "Health", "x Level", "x + 5"),
            (6, "Vitality", "x Health", "3 + floor(x / 3)"),
        ],
        "Perception": [
            (7, "Accuracy", "", "x + 2"),
            (8, "Crit Dice", "", "2 * ceil(x / 2.0) + 2"),
        ],
        "Intelligence": [
            (9, "Potency", "", "x + 2"),
            (10, "Bestiary Progression", "%", "x * 3"),
        ],
        "Resolve": [
            (11, "Mana Generation", "", "floor(x / 2)"),
            (12, "Concentration", "", "ceil(x / 2.0)"),
        ],
    }
    mod_rows = []
    for specs in modifier_specs.values():
        for mid, name, label, expr in specs:
            mod_rows.append((mid, name, "", "", label, expr))
    insert(
        out,
        "modifiers",
        [
            "id",
            "name",
            "short_description",
            "long_description",
            "value_label",
            "expression",
        ],
        mod_rows,
    )

    attr_rows = []
    for r in q(con, "SELECT * FROM attributes ORDER BY id"):
        spec_1, spec_2 = modifier_specs.get(
            r["name"], [(None, "", "", ""), (None, "", "", "")]
        )
        attr_rows.append(
            (
                r["id"],
                r["name"],
                "",
                r["description"] or "",
                spec_1[0],
                0,
                spec_2[0],
                0,
                r["min_value"],
                r["max_value"],
            )
        )
    insert(
        out,
        "attributes",
        [
            "id",
            "name",
            "short_description",
            "long_description",
            "modifier_id_1",
            "modifier_value_1",
            "modifier_id_2",
            "modifier_value_2",
            "min_value",
            "max_value",
        ],
        attr_rows,
    )

    insert(
        out,
        "skills",
        ["id", "name", "short_description", "long_description", "min_rank", "max_rank"],
        [
            (
                r["id"],
                r["name"],
                "",
                r["description"] or "",
                r["min_rank"],
                r["max_rank"],
            )
            for r in q(con, "SELECT * FROM skills ORDER BY id")
        ],
    )
    insert(
        out,
        "skill_rank_costs",
        ["target_rank", "short_description", "long_description", "point_cost"],
        [
            (r["target_rank"], "", "", r["point_cost"])
            for r in q(con, "SELECT * FROM skill_rank_costs ORDER BY target_rank")
        ],
    )
    insert(
        out,
        "perks",
        [
            "id",
            "name",
            "category",
            "short_description",
            "long_description",
            "requirement_text",
        ],
        [
            (r["id"], r["name"], r["category"], "", r["description"] or "", "")
            for r in q(con, "SELECT * FROM perks ORDER BY id")
        ],
    )
    insert(
        out,
        "races",
        ["id", "name", "short_description", "long_description", "perk_id"],
        [
            (r["id"], r["name"], "", r["description"] or "", r["perk_id"])
            for r in q(con, "SELECT * FROM races ORDER BY id")
        ],
    )
    insert(
        out,
        "homelands",
        ["id", "name", "short_description", "long_description", "perk_id"],
        [
            (r["id"], r["name"], "", r["description"] or "", r["perk_id"])
            for r in q(con, "SELECT * FROM homelands ORDER BY id")
        ],
    )

    bg_skill_map: dict[int, list[int]] = {}
    for r in q(
        con, "SELECT * FROM background_skills ORDER BY background_id, ordinal_position"
    ):
        bg_skill_map.setdefault(r["background_id"], []).append(r["skill_id"])
    bg_rows = []
    for r in q(con, "SELECT * FROM backgrounds ORDER BY id"):
        ids = bg_skill_map.get(r["id"], [])
        skill_1 = ids[0] if len(ids) > 0 else None
        skill_2 = ids[1] if len(ids) > 1 else None
        bg_rows.append(
            (
                r["id"],
                r["name"],
                "",
                r["description"] or "",
                r["perk_id"],
                skill_1,
                skill_2,
            )
        )
    insert(
        out,
        "backgrounds",
        [
            "id",
            "name",
            "short_description",
            "long_description",
            "perk_id",
            "skill_id_1",
            "skill_id_2",
        ],
        bg_rows,
    )

    insert(
        out,
        "level_progression",
        [
            "level_value",
            "short_description",
            "long_description",
            "xp_required",
            "formula_text",
            "skill_points_gained",
            "perks_gained",
        ],
        [
            (
                r["level_value"],
                "",
                "",
                r["xp_required"],
                r["formula_text"] or "",
                r["skill_points_gained"],
                r["perks_gained"],
            )
            for r in q(con, "SELECT * FROM level_progression ORDER BY level_value")
        ],
    )
    insert(
        out,
        "attacks",
        ["id", "name", "short_description", "long_description", "attack_tier"],
        [
            (r["id"], r["name"], "", r["description"] or "", r["attack_tier"] or "")
            for r in q(con, "SELECT * FROM attacks ORDER BY id")
        ],
    )

    spell_tag_map: dict[int, list[str]] = {}
    for r in q(
        con,
        "SELECT st.spell_id, k.name AS keyword_name FROM spell_tags st JOIN keywords k ON k.id = st.keyword_id ORDER BY st.spell_id, st.keyword_id",
    ):
        spell_tag_map.setdefault(r["spell_id"], []).append(r["keyword_name"])
    spell_rows = []
    for r in q(
        con,
        "SELECT s.*, sc.name AS school_name, rg.short_code, rg.name AS range_name FROM spells s LEFT JOIN spell_schools sc ON sc.id = s.spell_school_id LEFT JOIN ranges rg ON rg.id = s.range_id ORDER BY s.id",
    ):
        range_band = r["short_code"] if r["short_code"] else (r["range_name"] or "")
        spell_rows.append(
            (
                r["id"],
                r["name"],
                "",
                "",
                r["school_name"] or "",
                ",".join(spell_tag_map.get(r["id"], [])),
                r["difficulty_value"] or "",
                range_band,
                r["base_cast_text"] or "",
            )
        )
    insert(
        out,
        "spells",
        [
            "id",
            "name",
            "short_description",
            "long_description",
            "school",
            "tags",
            "difficulty",
            "range_band",
            "base_cast",
        ],
        spell_rows,
    )
    insert(
        out,
        "spell_variants",
        [
            "id",
            "spell_id",
            "name",
            "short_description",
            "mana_cost",
            "long_description",
            "ordinal_position",
        ],
        [
            (
                r["id"],
                r["spell_id"],
                r["name"],
                "",
                r["mana_cost_text"] or "",
                r["description"] or "",
                r["ordinal_position"],
            )
            for r in q(con, "SELECT * FROM spell_variants ORDER BY id")
        ],
    )
    insert(
        out,
        "strain_table",
        ["roll_total", "result_name", "short_description", "long_description"],
        [
            (r["roll_total"], r["result_name"], "", r["result_text"] or "")
            for r in q(con, "SELECT * FROM strain_table ORDER BY roll_total")
        ],
    )

    item_by_id: dict[int, dict] = {}
    for r in q(
        con,
        "SELECT i.*, c.name AS category_name FROM items i LEFT JOIN item_categories c ON c.id = i.category_id ORDER BY i.id",
    ):
        item_by_id[r["id"]] = dict(r)

    armor_rows = []
    for r in q(con, "SELECT * FROM armor ORDER BY item_id"):
        item = item_by_id.get(r["item_id"])
        if item is None:
            continue
        location = ""
        for suffix in (" Head", " Torso", " Arm", " Leg"):
            if item["name"].endswith(suffix):
                location = suffix.strip()
                break
        armor_rows.append(
            (
                r["item_id"],
                item["name"],
                "",
                item["description"] or "",
                r["armor_class"] or "",
                location,
                r["physical_dt"] or 0,
                r["magical_dt"] or 0,
                r["necrotic_dt"] or 0,
                r["equip_load"] or 0,
                item["cost_gold"] or 0,
                item["weight"] or 0,
            )
        )
    insert(
        out,
        "armor",
        [
            "id",
            "name",
            "short_description",
            "long_description",
            "armor_class",
            "locations_covered",
            "physical_dt",
            "magical_dt",
            "necrotic_dt",
            "equip_load",
            "cost",
            "weight",
        ],
        armor_rows,
    )

    weapon_tier_map: dict[int, dict[str, int | None]] = {}
    for r in q(
        con,
        "SELECT wap.weapon_item_id, a.id AS attack_id, a.attack_tier FROM weapon_attack_packages wap JOIN attacks a ON a.id = wap.attack_id ORDER BY wap.weapon_item_id, wap.ordinal_position",
    ):
        entry = weapon_tier_map.setdefault(
            r["weapon_item_id"],
            {"Basic": None, "Proficiency": None, "Expertise": None, "Mastery": None},
        )
        if entry.get(r["attack_tier"]) is None:
            entry[r["attack_tier"]] = r["attack_id"]
    weapon_rows = []
    for r in q(
        con,
        "SELECT w.*, rg.short_code, rg.name AS range_name FROM weapons w LEFT JOIN ranges rg ON rg.id = w.range_id ORDER BY w.item_id",
    ):
        item = item_by_id.get(r["item_id"])
        entry = weapon_tier_map.get(r["item_id"], {})
        range_band = r["short_code"] if r["short_code"] else (r["range_name"] or "")
        weapon_rows.append(
            (
                r["item_id"],
                "",
                (item["description"] if item else "") or "",
                r["weapon_class"] or "",
                r["damage_die"] or "",
                r["base_speed"] or 0,
                range_band,
                r["handedness"] or "",
                entry.get("Basic"),
                entry.get("Proficiency"),
                entry.get("Expertise"),
                entry.get("Mastery"),
            )
        )
    insert(
        out,
        "weapons",
        [
            "id",
            "short_description",
            "long_description",
            "weapon_class",
            "damage_die",
            "base_speed",
            "range_band",
            "handedness",
            "basic_attack_id",
            "proficient_attack_id",
            "expert_attack_id",
            "master_attack_id",
        ],
        weapon_rows,
    )

    effect_rows = []
    for i, r in enumerate(q(con, "SELECT * FROM item_effects ORDER BY id"), start=1):
        item = item_by_id.get(r["item_id"])
        if item is None:
            continue
        effect_rows.append(
            (
                i,
                r["item_id"],
                item_table_for_category(item["category_name"]),
                r["effect_type"] or "",
                r["effect_text"] or "",
                "",
                r["duration_text"] or "",
                r["ordinal_position"] or 1,
            )
        )
    insert(
        out,
        "item_effects",
        [
            "id",
            "item_id",
            "item_table",
            "name",
            "expression",
            "value",
            "duration",
            "sort_order",
        ],
        effect_rows,
    )

    insert(
        out,
        "starter_packs",
        ["id", "name", "short_description", "long_description", "leftover_gold"],
        [
            (r["id"], r["name"], "", "", r["leftover_gold"] or 0)
            for r in q(con, "SELECT * FROM starter_packs ORDER BY id")
        ],
    )
    pack_item_rows = []
    for i, r in enumerate(
        q(
            con,
            "SELECT * FROM starter_pack_items ORDER BY starter_pack_id, loadout_group, item_id",
        ),
        start=1,
    ):
        item = item_by_id.get(r["item_id"])
        if item is None:
            continue
        pack_item_rows.append(
            (
                i,
                r["starter_pack_id"],
                item_table_for_category(item["category_name"]),
                r["item_id"],
                "",
                "",
                r["quantity"] or 1,
                r["loadout_group"] or "",
            )
        )
    insert(
        out,
        "starter_pack_items",
        [
            "id",
            "starter_pack_id",
            "item_table",
            "item_id",
            "short_description",
            "long_description",
            "quantity",
            "loadout_group",
        ],
        pack_item_rows,
    )

    keyword_sources = {
        "attributes": "SELECT id, '' AS short_description, description AS long_description FROM attributes ORDER BY id",
        "skills": "SELECT id, '' AS short_description, description AS long_description FROM skills ORDER BY id",
        "defenses": "SELECT id, '' AS short_description, description AS long_description FROM defenses ORDER BY id",
        "conditions": "SELECT id, '' AS short_description, description AS long_description FROM conditions ORDER BY id",
        "perks": "SELECT id, '' AS short_description, description AS long_description FROM perks ORDER BY id",
        "races": "SELECT id, '' AS short_description, description AS long_description FROM races ORDER BY id",
        "homelands": "SELECT id, '' AS short_description, description AS long_description FROM homelands ORDER BY id",
        "backgrounds": "SELECT id, '' AS short_description, description AS long_description FROM backgrounds ORDER BY id",
        "attacks": "SELECT id, '' AS short_description, description AS long_description FROM attacks ORDER BY id",
        "armor": "SELECT a.item_id AS id, '' AS short_description, COALESCE(i.description, '') AS long_description FROM armor a LEFT JOIN items i ON i.id = a.item_id ORDER BY a.item_id",
        "spells": "SELECT id, '' AS short_description, base_cast_text AS long_description FROM spells ORDER BY id",
        "resources": "SELECT id, '' AS short_description, description AS long_description FROM resources ORDER BY id",
        "damage_origins": "SELECT id, '' AS short_description, description AS long_description FROM damage_origins ORDER BY id",
        "damage_types": "SELECT id, '' AS short_description, COALESCE(description, '') AS long_description FROM damage_types ORDER BY id",
        "effects": "SELECT id, '' AS short_description, description AS long_description FROM effects ORDER BY id",
        "weapon_qualities": "SELECT id, '' AS short_description, description AS long_description FROM weapon_qualities ORDER BY id",
        "ranges": "SELECT id, COALESCE(short_code, '') AS short_description, description AS long_description FROM ranges ORDER BY id",
        "spell_schools": "SELECT id, '' AS short_description, description AS long_description FROM spell_schools ORDER BY id",
    }
    keyword_id = 1
    for table, sql in keyword_sources.items():
        for r in q(con, sql):
            out.append(
                f"INSERT OR IGNORE INTO keywords (id, short_description, long_description, table_name, foreign_id) VALUES ({keyword_id}, {esc(r['short_description'])}, {esc(r['long_description'])}, {esc(table)}, {esc(r['id'])});"
            )
            keyword_id += 1

    out.append("COMMIT;")
    INSERT_PATH.write_text("\n".join(out) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
