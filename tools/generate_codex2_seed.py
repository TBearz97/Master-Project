from __future__ import annotations

import re
from pathlib import Path
from typing import Any


ROOT = Path(r"C:\Users\torb1\Documents\GitHub\Master-Project")
VAULT = ROOT / "Threads Of Fate"
OUTPUT = ROOT / "sql" / "codex2_seed.sql"


SOURCE_FILES = {
    "combat": VAULT / "2. Combat" / "2.2 Damage, Effects and Qualities.md",
    "magic_explained": VAULT / "6. Magic" / "Magic Explained.md",
    "primal_spells": VAULT / "6. Magic" / "Primal Spells.md",
    "theoretical_spells": VAULT / "6. Magic" / "Theoretical Spells.md",
    "zealous_spells": VAULT / "6. Magic" / "Zealous Spells.md",
    "languages": VAULT / "7. A Guide to Al'otoro" / "Languages.md",
    "races": VAULT / "8. Character Creation" / "8.2 Choosing your Race.md",
    "homelands": VAULT / "8. Character Creation" / "8.3 Choosing your Homeland.md",
    "backgrounds": VAULT / "8. Character Creation" / "8.4 Choosing your Background.md",
    "attributes": VAULT / "8. Character Creation" / "8.5 Distributing Attributes.md",
    "skills": VAULT / "8. Character Creation" / "8.6 Distributing Skills.md",
    "starting_equipment": VAULT / "8. Character Creation" / "8.7 Starting Equipment.md",
    "advancement": VAULT / "8. Character Creation" / "8.9 Character Advancement.md",
    "perks": VAULT / "8. Character Creation" / "8.10 Perks.md",
    "melee_weapons": VAULT / "5. Equipment" / "5.2 Melee Weapons.md",
    "ranged_weapons": VAULT / "5. Equipment" / "5.3 Ranged Weapons.md",
    "clothing": VAULT / "5. Equipment" / "5.4 Clothing and Outfits.md",
    "armor": VAULT / "5. Equipment" / "5.5 Armor.md",
    "consumables": VAULT / "5. Equipment" / "5.6 Consumables.md",
    "tools": VAULT / "5. Equipment" / "5.7 Tools and Utility.md",
    "npc_xp": VAULT
    / "10. Creatures and Characters"
    / "10.3 Defeating or Overcoming NPCs.md",
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def clean_inline(text: str) -> str:
    text = text.strip()
    text = text.replace("<br><br>", "\n\n")
    text = text.replace("<br>", "\n")
    text = re.sub(r"\[\[(?:[^\]|]+\|)?([^\]]+)\]\]", r"\1", text)
    text = text.replace("**", "")
    text = text.replace("`", "")
    return text.strip()


def sql_quote(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def parse_markdown_tables(text: str) -> list[list[dict[str, str]]]:
    tables: list[list[dict[str, str]]] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines) - 1:
        if lines[i].startswith("|") and lines[i + 1].startswith("|"):
            header = [
                clean_inline(part) for part in lines[i].strip().strip("|").split("|")
            ]
            i += 2
            rows: list[dict[str, str]] = []
            while i < len(lines) and lines[i].startswith("|"):
                parts = [
                    clean_inline(part)
                    for part in lines[i].strip().strip("|").split("|")
                ]
                if len(parts) == len(header):
                    rows.append(dict(zip(header, parts)))
                i += 1
            tables.append(rows)
            continue
        i += 1
    return tables


def emit_insert(
    lines: list[str], table: str, columns: list[str], values: list[Any]
) -> None:
    rendered = ", ".join(sql_quote(value) for value in values)
    lines.append(f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({rendered});")


def emit_note_inserts(lines: list[str]) -> None:
    for path in SOURCE_FILES.values():
        relative = path.relative_to(ROOT).as_posix()
        title = path.stem
        chapter_match = re.match(r"^(\d+(?:\.\d+)?)\s+(.*)$", title)
        chapter_code = chapter_match.group(1) if chapter_match else None
        chapter_name = chapter_match.group(2) if chapter_match else title
        content_type = path.parent.name
        lines.append(
            "INSERT INTO source_notes (vault_path, title, chapter_code, chapter_name, content_type) "
            f"VALUES ({sql_quote(relative)}, {sql_quote(title)}, {sql_quote(chapter_code)}, {sql_quote(chapter_name)}, {sql_quote(content_type)}) "
            "ON DUPLICATE KEY UPDATE title = VALUES(title), chapter_code = VALUES(chapter_code), chapter_name = VALUES(chapter_name), content_type = VALUES(content_type);"
        )


def subselect_note(path: Path) -> str:
    rel = path.relative_to(ROOT).as_posix()
    return f"(SELECT id FROM source_notes WHERE vault_path = {sql_quote(rel)})"


def insert_core_lookups(lines: list[str]) -> None:
    combat_text = read_text(SOURCE_FILES["combat"])
    magic_text = read_text(SOURCE_FILES["magic_explained"])

    resources = [
        ("Action Points", "AP spent to perform actions in combat."),
        ("Mana", "Power resource used to cast spells and fuel supernatural effects."),
        (
            "Health",
            "Determines how long a creature stays conscious and combat-effective.",
        ),
        ("Vitality", "Determines how close a creature is to death."),
        (
            "Concentration",
            "Represents how well a creature holds together planned actions under pressure.",
        ),
        ("Gold", "Default currency unit used for equipment and services."),
    ]
    for name, description in resources:
        lines.append(
            f"INSERT INTO resources (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    defenses = {
        "Deflection": "Represents a character's ability to deflect direct melee and ranged attacks.",
        "Reflex": "Represents a character's ability to dodge area of effect attacks.",
        "Endurance": "Represents resistance to bodily harm, force, poison, and disease.",
        "Mind": "Represents strength of mind and resistance to mental attack.",
    }
    for name, description in defenses.items():
        lines.append(
            f"INSERT INTO defenses (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    for name, description in {
        "Physical": "Anything from the physical world not affected by magic.",
        "Magical": "Anything made with magical origin or affected by magic.",
        "Necrotic": "Exposure to undead or dark magic.",
    }.items():
        lines.append(
            f"INSERT INTO damage_origins (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    damage_types = [
        "Piercing",
        "Blunt",
        "Blade",
        "Fire",
        "Frost",
        "Lightning",
        "Acid",
        "Poison",
        "Psychic",
        "Ethereal",
        "Radiant",
        "Corrupt",
    ]
    for name in damage_types:
        lines.append(
            f"INSERT INTO damage_types (name) VALUES ({sql_quote(name)}) ON DUPLICATE KEY UPDATE name = VALUES(name);"
        )

    ranges = [
        ("Adjacent", "A", 1, 1, "Most effective against targets in an adjacent hex."),
        ("Close", "C", 2, 4, "Most effective against targets within 2-4 hexes."),
        ("Medium", "M", 5, 7, "Most effective against targets within 5-7 hexes."),
        ("Long", "L", 8, 10, "Most effective against targets within 8-10 hexes."),
        ("Extreme", "X", 11, 13, "Most effective against targets within 11-13 hexes."),
        ("Reach", None, None, None, "Touch or immediate melee reach."),
    ]
    for row in ranges:
        emit_insert(
            lines,
            "ranges",
            ["name", "short_code", "min_distance", "max_distance", "description"],
            list(row),
        )

    effects = {
        "Bleed": "The target continues to suffer damage over the following rounds until the bleeding stops.",
        "Cleave": "The attack may hit one additional target adjacent to the primary target using the same roll.",
        "Cripple": "The target cannot move on their next round.",
        "Freeze": "Reduces Action Points for a number of rounds and can stack.",
        "Burning": "The target is set ablaze and continues to suffer fire damage until extinguished.",
        "Infectious": "If the effect gets through, the target immediately suffers a disease.",
        "Knockdown": "The attack knocks the target prone.",
        "Necrotic": "Deals separate tracked necrotic damage that reduces maximum Health.",
        "Penetrate": "The attack can pass through the primary target and hit an additional target behind it.",
        "Revealing": "The target is revealed and cannot hide.",
        "Stun": "The target skips the entire round and takes no actions.",
        "Turn Undead": "If the target is Undead, that target cannot attack you.",
    }
    for name, description in effects.items():
        lines.append(
            f"INSERT INTO effects (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    conditions = {
        "Burning": "A burning creature suffers ongoing fire damage until the flames are extinguished.",
        "Poisoned": "A poisoned creature is suffering from a toxin with penalties and duration based on the poison.",
        "Prone": "The creature crawls, ranged attackers suffer a penalty, and adjacent enemies gain an accuracy bonus.",
    }
    for name, description in conditions.items():
        lines.append(
            f"INSERT INTO conditions (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    qualities = {
        "Brutal": "Scores a critical hit on the two highest possible damage rolls rather than only the highest.",
        "Close Quarters": "Ignores the normal accuracy penalty for being used while threatened in melee.",
        "Concealed": "Easy to hide on your person and harder to notice.",
        "Quiet": "Making an attack with this weapon will not make any sound.",
        "Reach": "You can attack creatures up to 2 hexes or grids away.",
        "Versatile": "Two-handed by default, but can also be used in one hand with a lower damage die.",
    }
    for name, description in qualities.items():
        lines.append(
            f"INSERT INTO weapon_qualities (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    keyword_names = sorted(
        {
            "Arcane",
            "Beast",
            "Concentration",
            "Conjuration",
            "Control",
            "Earth",
            "Elemental",
            "Fire",
            "Harmless",
            "Hazard",
            "Healing",
            "Hunt",
            "Ice",
            "Illusion",
            "Instant",
            "Lasting",
            "Mind",
            "Mind Control",
            "Movement",
            "Nature",
            "Necrotic",
            "Poison",
            "Radiant",
            "Time",
            "Transformation",
            "Undead",
            "Ward",
            "Water",
            "Weapon",
            "Weather",
            "Zealous",
            "Dragon",
            "Eldritch",
            "Elemental",
            "Kith",
            "Virtuous",
            "Vicious",
            "Scout",
            "Knight",
            "Cultist",
            "Bandit",
        }
    )
    for name in keyword_names:
        lines.append(
            f"INSERT INTO keywords (name) VALUES ({sql_quote(name)}) ON DUPLICATE KEY UPDATE name = VALUES(name);"
        )

    schools = {
        "Theoretical": "Magic studied, understood, and shaped through knowledge, analysis, and discipline.",
        "Zealous": "Magic shaped by belief, devotion, conviction, and the powers that answer them.",
        "Primal": "Magic drawn from nature, instinct, spirits, and the living forces of the world.",
    }
    for name, description in schools.items():
        lines.append(
            f"INSERT INTO spell_schools (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    identities = [
        (
            "Magical Student",
            "Learns Theoretical spells through study and observation.",
            "Theoretical",
        ),
        (
            "Patronage",
            "Grants spells through bargains, sacrifices, or narrative bonds with greater powers.",
            None,
        ),
        (
            "Conviction",
            "Grants a fixed set of Zealous spells shaped by belief or devotion.",
            "Zealous",
        ),
        (
            "Ritualist",
            "Prepares a limited set of Primal spells through ritual.",
            "Primal",
        ),
        (
            "Innate Power",
            "Expresses magic through a natural affinity, talent, or defining supernatural theme.",
            None,
        ),
    ]
    for name, description, school in identities:
        school_expr = "NULL"
        if school:
            school_expr = (
                f"(SELECT id FROM spell_schools WHERE name = {sql_quote(school)})"
            )
        lines.append(
            "INSERT INTO magical_identities (name, description, spell_school_id) VALUES "
            f"({sql_quote(name)}, {sql_quote(description)}, {school_expr}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), spell_school_id = VALUES(spell_school_id);"
        )


def insert_languages(lines: list[str]) -> None:
    for raw in read_text(SOURCE_FILES["languages"]).splitlines():
        name = raw.strip()
        if name:
            lines.append(
                f"INSERT INTO languages (name) VALUES ({sql_quote(name)}) ON DUPLICATE KEY UPDATE name = VALUES(name);"
            )


def insert_attributes_and_skills(lines: list[str]) -> None:
    attr_text = read_text(SOURCE_FILES["attributes"])
    sections = re.split(r"\n## \*\*(.+?)\*\*\n", attr_text)
    for i in range(1, len(sections), 2):
        title = clean_inline(sections[i])
        body = sections[i + 1]
        name = title.split(" (")[0]
        description = clean_inline(body.splitlines()[0]) if body.splitlines() else ""
        lines.append(
            f"INSERT INTO attributes (name, description, min_value, max_value) VALUES ({sql_quote(name)}, {sql_quote(description)}, 1, 10) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), min_value = VALUES(min_value), max_value = VALUES(max_value);"
        )
        for table in parse_markdown_tables(body):
            for row in table:
                value = int(row[title.split(" (")[0]])
                for metric_name, metric_value in row.items():
                    if metric_name == name:
                        continue
                    lines.append(
                        "INSERT INTO attribute_progression (attribute_id, attribute_value, metric_name, metric_value_text) VALUES "
                        f"((SELECT id FROM attributes WHERE name = {sql_quote(name)}), {value}, {sql_quote(metric_name)}, {sql_quote(metric_value)}) "
                        "ON DUPLICATE KEY UPDATE metric_value_text = VALUES(metric_value_text);"
                    )

    skill_tables = parse_markdown_tables(read_text(SOURCE_FILES["skills"]))
    cost_table = skill_tables[0]
    skills_table = skill_tables[1]
    for row in cost_table:
        emit_insert(
            lines,
            "skill_rank_costs",
            ["target_rank", "point_cost"],
            [int(row["Skill Rank"]), int(row["Cost To Increase"])],
        )
    for row in skills_table:
        lines.append(
            f"INSERT INTO skills (name, description, min_rank, max_rank) VALUES ({sql_quote(row['Skill'])}, {sql_quote(row['Detail'])}, 0, 10) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), min_rank = VALUES(min_rank), max_rank = VALUES(max_rank);"
        )


def insert_character_creation(lines: list[str]) -> None:
    race_rows = parse_markdown_tables(read_text(SOURCE_FILES["races"]))[0]
    race_note = subselect_note(SOURCE_FILES["races"])
    for row in race_rows:
        perk_name, perk_desc = row["Perk"].split("\n\n", 1)
        lines.append(
            "INSERT INTO perks (name, category, description, source_note_id) VALUES "
            f"({sql_quote(perk_name)}, 'Race', {sql_quote(perk_desc)}, {race_note}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), source_note_id = VALUES(source_note_id);"
        )
        lines.append(
            "INSERT INTO races (name, description, perk_id, source_note_id) VALUES "
            f"({sql_quote(row['Race'])}, NULL, (SELECT id FROM perks WHERE name = {sql_quote(perk_name)} AND category = 'Race'), {race_note}) "
            "ON DUPLICATE KEY UPDATE perk_id = VALUES(perk_id), source_note_id = VALUES(source_note_id);"
        )

    homeland_note = subselect_note(SOURCE_FILES["homelands"])
    blocks = parse_homeland_blocks(read_text(SOURCE_FILES["homelands"]))
    for name, languages, perk_name, perk_desc in blocks:
        name = clean_inline(name)
        perk_name = clean_inline(perk_name)
        perk_desc = clean_inline(perk_desc)
        lines.append(
            "INSERT INTO perks (name, category, description, source_note_id) VALUES "
            f"({sql_quote(perk_name)}, 'Homeland', {sql_quote(perk_desc)}, {homeland_note}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), source_note_id = VALUES(source_note_id);"
        )
        lines.append(
            "INSERT INTO homelands (name, description, perk_id, source_note_id) VALUES "
            f"({sql_quote(name)}, NULL, (SELECT id FROM perks WHERE name = {sql_quote(perk_name)} AND category = 'Homeland'), {homeland_note}) "
            "ON DUPLICATE KEY UPDATE perk_id = VALUES(perk_id), source_note_id = VALUES(source_note_id);"
        )
        for language in [clean_inline(part) for part in languages.split(",")]:
            lines.append(
                "INSERT IGNORE INTO homeland_languages (homeland_id, language_id) VALUES "
                f"((SELECT id FROM homelands WHERE name = {sql_quote(name)}), (SELECT id FROM languages WHERE name = {sql_quote(language)}));"
            )

    background_rows = parse_markdown_tables(read_text(SOURCE_FILES["backgrounds"]))[0]
    background_note = subselect_note(SOURCE_FILES["backgrounds"])
    for row in background_rows:
        perk_name, perk_desc = row["Perk"].split(":", 1)
        lines.append(
            "INSERT INTO perks (name, category, description, source_note_id) VALUES "
            f"({sql_quote(clean_inline(perk_name))}, 'Background', {sql_quote(clean_inline(perk_desc))}, {background_note}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), source_note_id = VALUES(source_note_id);"
        )
        lines.append(
            "INSERT INTO backgrounds (name, description, perk_id, source_note_id) VALUES "
            f"({sql_quote(row['Background'])}, {sql_quote(row['Description'])}, (SELECT id FROM perks WHERE name = {sql_quote(clean_inline(perk_name))} AND category = 'Background'), {background_note}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), perk_id = VALUES(perk_id), source_note_id = VALUES(source_note_id);"
        )
        for index, skill in enumerate(
            [clean_inline(part) for part in row["Skills"].split(",")], start=1
        ):
            lines.append(
                "INSERT IGNORE INTO background_skills (background_id, skill_id, ordinal_position) VALUES "
                f"((SELECT id FROM backgrounds WHERE name = {sql_quote(row['Background'])}), (SELECT id FROM skills WHERE name = {sql_quote(skill)}), {index});"
            )

    advancement_rows = parse_markdown_tables(read_text(SOURCE_FILES["advancement"]))[0]
    for row in advancement_rows:
        level_text = row["Level"]
        if level_text == "21+":
            continue
        xp = row["XP Required"].replace(",", "")
        emit_insert(
            lines,
            "level_progression",
            [
                "level_value",
                "xp_required",
                "formula_text",
                "skill_points_gained",
                "perks_gained",
            ],
            [int(level_text), int(xp), None, 6, 1],
        )
    emit_insert(
        lines,
        "level_progression",
        [
            "level_value",
            "xp_required",
            "formula_text",
            "skill_points_gained",
            "perks_gained",
        ],
        [21, None, "(Level x (Level -1)/2) x 100", 6, 1],
    )


def parse_homeland_blocks(text: str) -> list[tuple[str, str, str, str]]:
    lines = text.splitlines()
    blocks: list[tuple[str, str, str, str]] = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if re.fullmatch(r"\*\*.+\*\*", line):
            name = clean_inline(line)
            j = i + 1
            while j < len(lines) and not lines[j].strip():
                j += 1
            if j < len(lines) and lines[j].strip().startswith("**Language:**"):
                languages = clean_inline(lines[j].split(":", 1)[1])
                j += 1
                while j < len(lines) and not lines[j].strip():
                    j += 1
                if j < len(lines) and lines[j].strip().startswith("**Perk:**"):
                    perk_name = clean_inline(lines[j].split(":", 1)[1])
                    j += 1
                    desc_lines: list[str] = []
                    while j < len(lines):
                        current = lines[j].strip()
                        if re.fullmatch(r"\*\*.+\*\*", current):
                            break
                        if current:
                            desc_lines.append(clean_inline(current))
                        j += 1
                    blocks.append(
                        (name, languages, perk_name, " ".join(desc_lines).strip())
                    )
                    i = j
                    continue
        i += 1
    return blocks


def parse_perks(text: str) -> list[dict[str, str]]:
    perks: list[dict[str, str]] = []
    lines = text.splitlines()
    category = "General"
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        section_match = re.match(r"#+ \*\*(.+?)\*\*", line)
        if section_match:
            category = clean_inline(section_match.group(1)).replace(" Perks", "")
            i += 1
            continue
        if (
            re.fullmatch(r"\*\*.+\*\*", line)
            and i + 1 < len(lines)
            and lines[i + 1].strip().startswith("**Requirement:**")
        ):
            name = clean_inline(line)
            requirement = clean_inline(lines[i + 1].split(":", 1)[1])
            i += 2
            body: list[str] = []
            while i < len(lines):
                current = lines[i].strip()
                if re.match(r"#+ \*\*.+\*\*", current):
                    break
                if (
                    re.fullmatch(r"\*\*.+\*\*", current)
                    and i + 1 < len(lines)
                    and lines[i + 1].strip().startswith("**Requirement:**")
                ):
                    break
                if current:
                    body.append(clean_inline(current))
                i += 1
            perks.append(
                {
                    "name": name,
                    "category": category,
                    "requirement": requirement,
                    "description": " ".join(body).strip(),
                }
            )
            continue
        i += 1
    return perks


def insert_perks(lines: list[str]) -> None:
    note = subselect_note(SOURCE_FILES["perks"])
    for perk in parse_perks(read_text(SOURCE_FILES["perks"])):
        description = perk["description"]
        if perk["requirement"]:
            description = f"Requirement: {perk['requirement']}\\n\\n{description}"
        lines.append(
            "INSERT INTO perks (name, category, description, source_note_id) VALUES "
            f"({sql_quote(perk['name'])}, {sql_quote(perk['category'])}, {sql_quote(description)}, {note}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), source_note_id = VALUES(source_note_id);"
        )


def quality_names(raw: str) -> list[str]:
    cleaned = clean_inline(raw)
    if cleaned == "-":
        return []
    return [part.strip() for part in cleaned.split(",") if part.strip()]


def insert_item_categories(lines: list[str]) -> None:
    categories = [
        ("Weapon", None),
        ("Melee Weapon", "Weapon"),
        ("Ranged Weapon", "Weapon"),
        ("Armor", None),
        ("Clothing", None),
        ("Outfit", "Clothing"),
        ("Consumable", None),
        ("Food", "Consumable"),
        ("Beverage", "Consumable"),
        ("Potion or Herb", "Consumable"),
        ("Poison", "Consumable"),
        ("Tool or Utility", None),
        ("Crafting Tool", "Tool or Utility"),
        ("Instrument", "Tool or Utility"),
    ]
    for name, parent in categories:
        parent_expr = "NULL"
        if parent:
            parent_expr = (
                f"(SELECT id FROM item_categories WHERE name = {sql_quote(parent)})"
            )
        lines.append(
            f"INSERT INTO item_categories (name, parent_category_id) VALUES ({sql_quote(name)}, {parent_expr}) "
            "ON DUPLICATE KEY UPDATE parent_category_id = VALUES(parent_category_id);"
        )


def insert_equipment(lines: list[str]) -> None:
    insert_item_categories(lines)
    melee_rows = parse_markdown_tables(read_text(SOURCE_FILES["melee_weapons"]))[0]
    ranged_rows = parse_markdown_tables(read_text(SOURCE_FILES["ranged_weapons"]))[0]
    clothing_tables = parse_markdown_tables(read_text(SOURCE_FILES["clothing"]))[0]
    armor_tables = parse_markdown_tables(read_text(SOURCE_FILES["armor"]))
    consumable_tables = parse_markdown_tables(read_text(SOURCE_FILES["consumables"]))
    tool_rows = parse_markdown_tables(read_text(SOURCE_FILES["tools"]))[0]

    melee_note = subselect_note(SOURCE_FILES["melee_weapons"])
    ranged_note = subselect_note(SOURCE_FILES["ranged_weapons"])
    clothing_note = subselect_note(SOURCE_FILES["clothing"])
    armor_note = subselect_note(SOURCE_FILES["armor"])
    consumable_note = subselect_note(SOURCE_FILES["consumables"])
    tools_note = subselect_note(SOURCE_FILES["tools"])

    for row in melee_rows:
        lines.append(
            "INSERT INTO items (category_id, name, cost_gold, weight, size_code, source_note_id) VALUES "
            f"((SELECT id FROM item_categories WHERE name = 'Melee Weapon'), {sql_quote(row['Weapon'])}, {sql_quote(float(row['Cost']))}, {sql_quote(None if row['Weight'] == '-' else float(row['Weight']))}, {sql_quote(row['Size'])}, {melee_note}) "
            "ON DUPLICATE KEY UPDATE cost_gold = VALUES(cost_gold), weight = VALUES(weight), size_code = VALUES(size_code), source_note_id = VALUES(source_note_id);"
        )
        lines.append(
            "INSERT INTO weapons (item_id, weapon_class, damage_die, base_speed, handedness, attack_package_notes) VALUES "
            f"((SELECT items.id FROM items JOIN item_categories ON item_categories.id = items.category_id WHERE items.name = {sql_quote(row['Weapon'])} AND item_categories.name = 'Melee Weapon'), 'Melee', {sql_quote(row['Damage Die'])}, {int(row['Base Speed'])}, {sql_quote(row['Size'])}, {sql_quote(row['Attacks'])}) "
            "ON DUPLICATE KEY UPDATE damage_die = VALUES(damage_die), base_speed = VALUES(base_speed), handedness = VALUES(handedness), attack_package_notes = VALUES(attack_package_notes);"
        )
        for quality in quality_names(row["Qualities"]):
            lines.append(
                "INSERT IGNORE INTO weapon_quality_map (weapon_item_id, weapon_quality_id) VALUES "
                f"((SELECT item_id FROM weapons WHERE item_id = (SELECT id FROM items WHERE name = {sql_quote(row['Weapon'])})), (SELECT id FROM weapon_qualities WHERE name = {sql_quote(quality)}));"
            )

    for row in ranged_rows:
        range_expr = (
            f"(SELECT id FROM ranges WHERE short_code = {sql_quote(row['Range'])})"
        )
        lines.append(
            "INSERT INTO items (category_id, name, cost_gold, weight, size_code, source_note_id) VALUES "
            f"((SELECT id FROM item_categories WHERE name = 'Ranged Weapon'), {sql_quote(row['Ranged Weapon'])}, {sql_quote(float(row['Cost']))}, {float(row['Weight'])}, {sql_quote(row['Size'])}, {ranged_note}) "
            "ON DUPLICATE KEY UPDATE cost_gold = VALUES(cost_gold), weight = VALUES(weight), size_code = VALUES(size_code), source_note_id = VALUES(source_note_id);"
        )
        lines.append(
            "INSERT INTO weapons (item_id, weapon_class, damage_die, base_speed, range_id, handedness, attack_package_notes) VALUES "
            f"((SELECT items.id FROM items JOIN item_categories ON item_categories.id = items.category_id WHERE items.name = {sql_quote(row['Ranged Weapon'])} AND item_categories.name = 'Ranged Weapon'), 'Ranged', {sql_quote(row['Damage Die'])}, {int(row['Base Speed'])}, {range_expr}, {sql_quote(row['Size'])}, {sql_quote(row['Attacks'])}) "
            "ON DUPLICATE KEY UPDATE damage_die = VALUES(damage_die), base_speed = VALUES(base_speed), range_id = VALUES(range_id), handedness = VALUES(handedness), attack_package_notes = VALUES(attack_package_notes);"
        )
        for quality in quality_names(row["Qualities"]):
            lines.append(
                "INSERT IGNORE INTO weapon_quality_map (weapon_item_id, weapon_quality_id) VALUES "
                f"((SELECT item_id FROM weapons WHERE item_id = (SELECT id FROM items WHERE name = {sql_quote(row['Ranged Weapon'])})), (SELECT id FROM weapon_qualities WHERE name = {sql_quote(quality)}));"
            )

    clothing_bonus_map = {}
    clothing_lines = read_text(SOURCE_FILES["clothing"]).splitlines()
    current = None
    for raw in clothing_lines:
        line = raw.strip()
        if re.fullmatch(r"\*\*.+\*\*", line):
            current = clean_inline(line)
            continue
        if current and line:
            clothing_bonus_map[current] = clean_inline(line)
            current = None

    for row in clothing_tables:
        if row["Item"] in {"Outfits", "Clothing"}:
            continue
        category = (
            "Outfit"
            if row["Item"]
            in {
                "Alchemist's Attire",
                "Blacksmith's Outfit",
                "Bandit's Outfit",
                "Mercenary's Outfit",
                "Nature's Gown",
                "Noble's Attire",
                "Performer's Outfit",
                "Pirate's Attire",
                "Priest's Garments",
                "Scribe's Robe",
                "Ranger's Outfit",
                "Tribal Outfit",
                "Wizard's Robe",
            }
            else "Clothing"
        )
        lines.append(
            "INSERT INTO items (category_id, name, description, cost_gold, weight, source_note_id) VALUES "
            f"((SELECT id FROM item_categories WHERE name = {sql_quote(category)}), {sql_quote(row['Item'])}, {sql_quote('Covers: ' + row['Locations Covered'])}, {float(row['Cost'])}, {float(row['Weight'])}, {clothing_note}) "
            "ON DUPLICATE KEY UPDATE description = VALUES(description), cost_gold = VALUES(cost_gold), weight = VALUES(weight), source_note_id = VALUES(source_note_id);"
        )
        if row["Item"] in clothing_bonus_map:
            lines.append(
                "INSERT INTO item_effects (item_id, effect_type, effect_text, ordinal_position) VALUES "
                f"((SELECT id FROM items WHERE name = {sql_quote(row['Item'])}), 'Passive Bonus', {sql_quote(clothing_bonus_map[row['Item']])}, 1);"
            )

    armor_classes = ["Light Armor", "Medium Armor", "Heavy Armor"]
    for armor_class, table in zip(armor_classes, armor_tables):
        for row in table:
            lines.append(
                "INSERT INTO items (category_id, name, cost_gold, weight, source_note_id) VALUES "
                f"((SELECT id FROM item_categories WHERE name = 'Armor'), {sql_quote(row['Item'])}, {float(row['Cost'])}, {float(row['Weight'])}, {armor_note}) "
                "ON DUPLICATE KEY UPDATE cost_gold = VALUES(cost_gold), weight = VALUES(weight), source_note_id = VALUES(source_note_id);"
            )
            lines.append(
                "INSERT INTO armor (item_id, armor_class, physical_dt, magical_dt, necrotic_dt, equip_load) VALUES "
                f"((SELECT id FROM items WHERE name = {sql_quote(row['Item'])}), {sql_quote(armor_class)}, {int(row['Physical DT'])}, {int(row['Magical DT'])}, {int(row['Necrotic DT'])}, {float(row['Weight'])}) "
                "ON DUPLICATE KEY UPDATE armor_class = VALUES(armor_class), physical_dt = VALUES(physical_dt), magical_dt = VALUES(magical_dt), necrotic_dt = VALUES(necrotic_dt), equip_load = VALUES(equip_load);"
            )

    consumable_categories = ["Food", "Beverage", "Potion or Herb", "Poison"]
    for category, table in zip(consumable_categories, consumable_tables):
        for row in table:
            cost_value = None if row.get("Cost", "-") == "-" else float(row["Cost"])
            lines.append(
                "INSERT INTO items (category_id, name, cost_gold, weight, source_note_id) VALUES "
                f"((SELECT id FROM item_categories WHERE name = {sql_quote(category)}), {sql_quote(row['Item'])}, {sql_quote(cost_value)}, {float(row['Weight'])}, {consumable_note}) "
                "ON DUPLICATE KEY UPDATE cost_gold = VALUES(cost_gold), weight = VALUES(weight), source_note_id = VALUES(source_note_id);"
            )
            if category == "Food":
                effect = f"HP Healed: {row['HP Healed']}"
                if row["Effect"] != "-":
                    effect += f"; {row['Effect']}"
                lines.append(
                    "INSERT INTO item_effects (item_id, effect_type, effect_text, ordinal_position) VALUES "
                    f"((SELECT id FROM items WHERE name = {sql_quote(row['Item'])}), 'Consumable', {sql_quote(effect)}, 1);"
                )
            elif category == "Beverage":
                effect = f"HP Healed: {row['HP Healed']}"
                if row["Effect"] != "-":
                    effect += f"; {row['Effect']}"
                lines.append(
                    "INSERT INTO item_effects (item_id, effect_type, effect_text, ordinal_position) VALUES "
                    f"((SELECT id FROM items WHERE name = {sql_quote(row['Item'])}), 'Consumable', {sql_quote(effect)}, 1);"
                )
            else:
                addictive = None
                if row.get("Addictive") == "No":
                    addictive = 0
                elif row.get("Addictive"):
                    addictive = 1
                lines.append(
                    "INSERT INTO item_effects (item_id, effect_type, effect_text, duration_text, addictive, ordinal_position) VALUES "
                    f"((SELECT id FROM items WHERE name = {sql_quote(row['Item'])}), {sql_quote(category)}, {sql_quote(row['Effect'])}, {sql_quote(row['Duration'])}, {sql_quote(addictive)}, 1);"
                )

    tool_section = "Tool or Utility"
    for row in tool_rows:
        name = row["Item"]
        if name in {"Crafting Tools", "Instruments"}:
            continue
        if name in {
            "Smithing Tools",
            "Alchemy Kit",
            "Bowyer's Tools",
            "Cooking Utensils",
            "Tailoring Kit",
            "Tanner's Tools",
            "Tinkering Kit",
            "Scribe's Supplies",
        }:
            tool_section = "Crafting Tool"
        elif name in {
            "Bagpipes",
            "Banjo",
            "Chacaras",
            "Drum",
            "Flute",
            "Hurdy-gurdy",
            "Lute",
            "Lyre",
            "Pan Flute",
            "Viol",
        }:
            tool_section = "Instrument"
        lines.append(
            "INSERT INTO items (category_id, name, cost_gold, weight, source_note_id) VALUES "
            f"((SELECT id FROM item_categories WHERE name = {sql_quote(tool_section)}), {sql_quote(name)}, {sql_quote(None if row['Cost'] == '-' else float(row['Cost']))}, {sql_quote(None if row['Weight'] == '-' else float(row['Weight']))}, {tools_note}) "
            "ON DUPLICATE KEY UPDATE cost_gold = VALUES(cost_gold), weight = VALUES(weight), source_note_id = VALUES(source_note_id);"
        )
        if row["Effect"] != "-":
            lines.append(
                "INSERT INTO item_effects (item_id, effect_type, effect_text, ordinal_position) VALUES "
                f"((SELECT id FROM items WHERE name = {sql_quote(name)}), 'Passive Bonus', {sql_quote(row['Effect'])}, 1);"
            )


def insert_attacks(lines: list[str]) -> None:
    def parse_attacks(text: str) -> tuple[dict[str, str], dict[str, list[str]]]:
        lines_local = text.splitlines()
        tier = None
        attacks: dict[str, str] = {}
        tiers: dict[str, list[str]] = {}
        for raw in lines_local:
            line = raw.strip()
            if line.startswith("## **") and line.endswith("**"):
                tier = clean_inline(line.replace("## ", ""))
                continue
            attack_match = re.match(r"- \*\*(.+?)\*\* - (.+)", line)
            if attack_match and tier:
                name = clean_inline(attack_match.group(1))
                description = clean_inline(attack_match.group(2))
                attacks[name] = description
                tiers[name] = [tier]
        return attacks, tiers

    melee_attacks, melee_tiers = parse_attacks(read_text(SOURCE_FILES["melee_weapons"]))
    ranged_attacks, ranged_tiers = parse_attacks(
        read_text(SOURCE_FILES["ranged_weapons"])
    )
    all_attacks = {**melee_attacks, **ranged_attacks}
    tiers = {**melee_tiers, **ranged_tiers}
    note_expr = subselect_note(SOURCE_FILES["melee_weapons"])
    for name, description in sorted(all_attacks.items()):
        tier_name = tiers[name][0]
        lines.append(
            "INSERT INTO attacks (name, attack_tier, description, source_note_id) VALUES "
            f"({sql_quote(name)}, {sql_quote(tier_name)}, {sql_quote(description)}, {note_expr}) "
            "ON DUPLICATE KEY UPDATE attack_tier = VALUES(attack_tier), description = VALUES(description);"
        )

    for row in parse_markdown_tables(read_text(SOURCE_FILES["melee_weapons"]))[0]:
        for index, attack in enumerate(
            [clean_inline(part) for part in row["Attacks"].split(",")], start=1
        ):
            lines.append(
                "INSERT IGNORE INTO weapon_attack_packages (weapon_item_id, attack_id, ordinal_position) VALUES "
                f"((SELECT id FROM items WHERE name = {sql_quote(row['Weapon'])}), (SELECT id FROM attacks WHERE name = {sql_quote(attack)}), {index});"
            )
    for row in parse_markdown_tables(read_text(SOURCE_FILES["ranged_weapons"]))[0]:
        for index, attack in enumerate(
            [clean_inline(part) for part in row["Attacks"].split(",")], start=1
        ):
            lines.append(
                "INSERT IGNORE INTO weapon_attack_packages (weapon_item_id, attack_id, ordinal_position) VALUES "
                f"((SELECT id FROM items WHERE name = {sql_quote(row['Ranged Weapon'])}), (SELECT id FROM attacks WHERE name = {sql_quote(attack)}), {index});"
            )


def parse_spells(text: str, school: str) -> list[dict[str, Any]]:
    lines = text.splitlines()
    spells: list[dict[str, Any]] = []
    i = 0
    while i < len(lines):
        title_line = lines[i].strip()
        if (
            re.fullmatch(r"\*\*.+\*\*", title_line)
            and i + 1 < len(lines)
            and lines[i + 1].strip().startswith("**Tag")
        ):
            spell = {
                "name": clean_inline(title_line),
                "school": school,
                "tags": [],
                "difficulty": None,
                "range": None,
                "base_cast": [],
                "variants": [],
            }
            i += 1
            mode = None
            while i < len(lines):
                line = lines[i].strip()
                if (
                    i + 1 < len(lines)
                    and re.fullmatch(r"\*\*.+\*\*", line)
                    and lines[i + 1].strip().startswith("**Tag")
                ):
                    break
                if line.startswith("**Tag:") or line.startswith("**Tags:"):
                    spell["tags"] = [
                        clean_inline(part) for part in line.split(":", 1)[1].split(",")
                    ]
                elif line.startswith("**Difficulty:"):
                    spell["difficulty"] = clean_inline(line.split(":", 1)[1])
                elif line.startswith("**Optimal Range:"):
                    spell["range"] = clean_inline(line.split(":", 1)[1])
                elif line.startswith("**Base Cast:"):
                    mode = "base"
                elif line.startswith("**Variety Cast:"):
                    mode = "variant"
                elif line.startswith("- (") and mode == "variant":
                    cost, rest = line[2:].split(")", 1)
                    variant_name, description = rest.strip().split(":", 1)
                    spell["variants"].append(
                        {
                            "cost": cost.strip("(").strip(),
                            "name": clean_inline(variant_name),
                            "description": clean_inline(description),
                        }
                    )
                elif line:
                    if mode == "base":
                        spell["base_cast"].append(clean_inline(line))
                i += 1
            spells.append(spell)
            continue
        i += 1
    return spells


def insert_spells(lines: list[str]) -> None:
    spell_sources = [
        ("Primal", SOURCE_FILES["primal_spells"]),
        ("Theoretical", SOURCE_FILES["theoretical_spells"]),
        ("Zealous", SOURCE_FILES["zealous_spells"]),
    ]
    for school, path in spell_sources:
        for spell in parse_spells(read_text(path), school):
            range_expr = "NULL"
            if spell["range"]:
                short = str(spell["range"])
                if short in {"A", "C", "M", "L", "X"}:
                    range_expr = (
                        f"(SELECT id FROM ranges WHERE short_code = {sql_quote(short)})"
                    )
                else:
                    range_expr = (
                        f"(SELECT id FROM ranges WHERE name = {sql_quote(short)})"
                    )
            lines.append(
                "INSERT INTO spells (spell_school_id, name, difficulty_value, range_id, base_cast_text, source_note_id) VALUES "
                f"((SELECT id FROM spell_schools WHERE name = {sql_quote(school)}), {sql_quote(spell['name'])}, {sql_quote(spell['difficulty'])}, {range_expr}, {sql_quote(' '.join(spell['base_cast']))}, {subselect_note(path)}) "
                "ON DUPLICATE KEY UPDATE difficulty_value = VALUES(difficulty_value), range_id = VALUES(range_id), base_cast_text = VALUES(base_cast_text), source_note_id = VALUES(source_note_id);"
            )
            for tag in spell["tags"]:
                lines.append(
                    "INSERT IGNORE INTO spell_tags (spell_id, keyword_id) VALUES "
                    f"((SELECT id FROM spells WHERE name = {sql_quote(spell['name'])} AND spell_school_id = (SELECT id FROM spell_schools WHERE name = {sql_quote(school)})), (SELECT id FROM keywords WHERE name = {sql_quote(tag)}));"
                )
            for index, variant in enumerate(spell["variants"], start=1):
                lines.append(
                    "INSERT INTO spell_variants (spell_id, name, mana_cost_text, description, ordinal_position) VALUES "
                    f"((SELECT id FROM spells WHERE name = {sql_quote(spell['name'])} AND spell_school_id = (SELECT id FROM spell_schools WHERE name = {sql_quote(school)})), {sql_quote(variant['name'])}, {sql_quote(variant['cost'])}, {sql_quote(variant['description'])}, {index});"
                )

    strain_rows = parse_markdown_tables(read_text(SOURCE_FILES["magic_explained"]))[0]
    for row in strain_rows:
        result_name, result_text = row["Strain Result"].split(":", 1)
        emit_insert(
            lines,
            "strain_table",
            ["roll_total", "result_name", "result_text"],
            [int(row["2d20"]), clean_inline(result_name), clean_inline(result_text)],
        )


def insert_starter_packs(lines: list[str]) -> None:
    text = read_text(SOURCE_FILES["starting_equipment"])
    note = subselect_note(SOURCE_FILES["starting_equipment"])
    pattern = re.compile(
        r"#### \*\*(.+?)\*\*\n\n- \*\*Leftover Gold:\*\* (\d+)\n(?:- \*\*Weapons:\*\* (.+)\n)?(?:- \*\*Armor and Clothing:\*\* (.+)\n)?(?:- \*\*Supplies:\*\* (.+)\n)?(?:- \*\*Consumables:\*\* (.+)\n)?",
        re.M,
    )
    for match in pattern.finditer(text):
        name, gold, weapons, armor_clothing, supplies, consumables = match.groups()
        lines.append(
            f"INSERT INTO starter_packs (name, leftover_gold, source_note_id) VALUES ({sql_quote(name)}, {int(gold)}, {note}) "
            "ON DUPLICATE KEY UPDATE leftover_gold = VALUES(leftover_gold), source_note_id = VALUES(source_note_id);"
        )
        for group_name, payload in [
            ("Weapons", weapons),
            ("Armor and Clothing", armor_clothing),
            ("Supplies", supplies),
            ("Consumables", consumables),
        ]:
            if not payload:
                continue
            for part in [item.strip() for item in payload.split(";")]:
                quantity = 1
                item_name = part
                qty_match = re.search(r" x(\d+)$", part)
                if qty_match:
                    quantity = int(qty_match.group(1))
                    item_name = part[: qty_match.start()].strip()
                lines.append(
                    "INSERT IGNORE INTO starter_pack_items (starter_pack_id, item_id, quantity, loadout_group) VALUES "
                    f"((SELECT id FROM starter_packs WHERE name = {sql_quote(name)}), (SELECT id FROM items WHERE name = {sql_quote(item_name)}), {quantity}, {sql_quote(group_name)});"
                )


def insert_npc_data(lines: list[str]) -> None:
    for name, description in {
        "Minion": "A weak or disposable foe useful for crowds, packs, guards, and lesser threats.",
        "Normal": "The standard benchmark for most creatures and characters.",
        "Mighty": "A stronger version of a creature, champion, elite guard, leader, or dangerous specialist.",
        "Legendary": "A rare and exceptional threat whose abilities go beyond ordinary limits.",
    }.items():
        lines.append(
            f"INSERT INTO npc_types (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )
    for name, description in {
        "Ally": "Friendly and inclined to help.",
        "Enemy": "Hostile and willing to hinder, threaten, or attack.",
        "Bystander": "Not committed either way, but capable of becoming an ally, problem, witness, or future contact.",
    }.items():
        lines.append(
            f"INSERT INTO npc_reactions (name, description) VALUES ({sql_quote(name)}, {sql_quote(description)}) ON DUPLICATE KEY UPDATE description = VALUES(description);"
        )

    xp_rows = parse_markdown_tables(read_text(SOURCE_FILES["npc_xp"]))[0]
    for row in xp_rows:
        level_text = row["NPC Level"]
        if level_text == "21+":
            for npc_type, formula in {
                "Normal": "+7 per level",
                "Mighty": "+14 per level",
                "Legendary": "+21 per level",
            }.items():
                lines.append(
                    "INSERT INTO npc_xp_awards (npc_level, npc_type_id, xp_award, formula_text) VALUES "
                    f"(21, (SELECT id FROM npc_types WHERE name = {sql_quote(npc_type)}), NULL, {sql_quote(formula)}) "
                    "ON DUPLICATE KEY UPDATE formula_text = VALUES(formula_text);"
                )
            continue
        level = int(level_text)
        for npc_type, xp in [
            ("Normal", int(row["XP (Normal)"])),
            ("Mighty", int(row["XP (Mighty)"])),
            ("Legendary", int(row["XP (Legendary)"])),
        ]:
            lines.append(
                "INSERT INTO npc_xp_awards (npc_level, npc_type_id, xp_award, formula_text) VALUES "
                f"({level}, (SELECT id FROM npc_types WHERE name = {sql_quote(npc_type)}), {xp}, NULL) "
                "ON DUPLICATE KEY UPDATE xp_award = VALUES(xp_award);"
            )


def main() -> None:
    lines: list[str] = [
        "USE Codex2;",
        "SET NAMES utf8mb4;",
        "START TRANSACTION;",
        "",
    ]
    emit_note_inserts(lines)
    lines.append("")
    insert_core_lookups(lines)
    lines.append("")
    insert_languages(lines)
    lines.append("")
    insert_attributes_and_skills(lines)
    lines.append("")
    insert_character_creation(lines)
    lines.append("")
    insert_perks(lines)
    lines.append("")
    insert_equipment(lines)
    lines.append("")
    insert_attacks(lines)
    lines.append("")
    insert_spells(lines)
    lines.append("")
    insert_starter_packs(lines)
    lines.append("")
    insert_npc_data(lines)
    lines.append("")
    lines.append("COMMIT;")
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
