import re
import sqlite3
from pathlib import Path


ROOT = Path(r"C:\Users\torb1\Documents\GitHub\Master-Project")
VAULT = ROOT / "Threads Of Fate" / "5. Equipment"
DB_PATH = ROOT / "data" / "Codex2.db"
OUT_SQL = ROOT / "sql" / "codex2_current_items_patch.sql"


def esc(value):
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def parse_table(path: Path):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    tables = []
    i = 0
    while i < len(lines) - 1:
        if lines[i].startswith("|") and lines[i + 1].startswith("|"):
            headers = [clean_md(c) for c in lines[i].strip().strip("|").split("|")]
            i += 2
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                vals = [clean_md(c) for c in lines[i].strip().strip("|").split("|")]
                if len(vals) == len(headers):
                    rows.append(dict(zip(headers, vals)))
                i += 1
            tables.append(rows)
            continue
        i += 1
    return tables


def clean_md(value: str) -> str:
    value = value.strip()
    value = value.replace("**", "")
    value = re.sub(r"\[\[(?:[^\]|]+\|)?([^\]]+)\]\]", r"\1", value)
    return value.strip()


def parse_attack_sections(path: Path):
    text = path.read_text(encoding="utf-8")
    sections = {"Basic": [], "Proficiency": [], "Expertise": [], "Mastery": []}
    current = None
    for line in text.splitlines():
        line = line.strip()
        if line == "## **Basic**":
            current = "Basic"
            continue
        if line == "## **Proficiency**":
            current = "Proficiency"
            continue
        if line == "## **Expertise**":
            current = "Expertise"
            continue
        if line == "## **Mastery**":
            current = "Mastery"
            continue
        m = re.match(r"- \*\*(.+?)\*\* - ", line)
        if current and m:
            sections[current].append(m.group(1).strip())
    return sections


def normalize_locations(value: str) -> str:
    mapping = {
        "Arms": "Arm",
        "Legs": "Leg",
        "Arm Left": "Left Arm",
        "Arm Right": "Right Arm",
        "Leg Left": "Left Leg",
        "Leg Right": "Right Leg",
    }
    parts = []
    for token in value.split(","):
        token = token.strip()
        parts.append(mapping.get(token, token))
    return ", ".join(parts)


def main():
    melee_rows = parse_table(VAULT / "5.2 Melee Weapons.md")[0]
    ranged_rows = parse_table(VAULT / "5.3 Ranged Weapons.md")[0]
    clothing_rows = parse_table(VAULT / "5.4 Clothing and Outfits.md")[0]
    consumable_tables = parse_table(VAULT / "5.6 Consumables.md")
    utility_rows = parse_table(VAULT / "5.7 Tools and Utility.md")[0]

    con = sqlite3.connect(DB_PATH)
    con.row_factory = sqlite3.Row
    cur = con.cursor()
    attack_names = {
        row["id"]: row["name"] for row in cur.execute("SELECT id, name FROM attacks")
    }
    weapons = [dict(r) for r in cur.execute("SELECT * FROM weapons ORDER BY id")]

    weapon_candidates = []
    for row in melee_rows:
        attacks = [x.strip() for x in row["Attacks"].split(",")]
        weapon_candidates.append(
            {
                "name": row["Weapon"],
                "weapon_class": "Melee",
                "damage_die": row["Damage Die"],
                "base_speed": int(row["Base Speed"]),
                "range_band": "",
                "handedness": row["Size"],
                "qualities": row["Qualities"].replace(" - ", "").replace("-", ""),
                "cost": float(row["Cost"]),
                "weight": 0.0 if row["Weight"] == "-" else float(row["Weight"]),
                "attacks": attacks,
            }
        )
    for row in ranged_rows:
        attacks = [x.strip() for x in row["Attacks"].split(",")]
        weapon_candidates.append(
            {
                "name": row["Ranged Weapon"],
                "weapon_class": "Ranged",
                "damage_die": row["Damage Die"],
                "base_speed": int(row["Base Speed"]),
                "range_band": row["Range"],
                "handedness": row["Size"],
                "qualities": row["Qualities"].replace(" - ", "").replace("-", ""),
                "cost": float(row["Cost"]),
                "weight": float(row["Weight"]),
                "attacks": attacks,
            }
        )

    matched = {}
    used_names = set()
    for row in weapons:
        required = [
            attack_names.get(row[k])
            for k in [
                "basic_attack_id",
                "proficient_attack_id",
                "expert_attack_id",
                "master_attack_id",
            ]
            if row[k] is not None
        ]
        candidates = []
        for cand in weapon_candidates:
            if cand["name"] in used_names:
                continue
            if cand["weapon_class"] != row["weapon_class"]:
                continue
            if cand["damage_die"] != row["damage_die"]:
                continue
            if cand["base_speed"] != row["base_speed"]:
                continue
            if cand["range_band"] != (row["range_band"] or ""):
                continue
            if cand["handedness"] != row["handedness"]:
                continue
            if all(req in cand["attacks"] for req in required):
                candidates.append(cand)
        if len(candidates) == 1:
            matched[row["id"]] = candidates[0]
            used_names.add(candidates[0]["name"])

    effect_map = {}
    clothing_text = (VAULT / "5.4 Clothing and Outfits.md").read_text(encoding="utf-8")
    for match in re.finditer(
        r"\*\*(.+?)\*\*\n([^\n].+?)(?=\n\n\*\*|\Z)", clothing_text, re.S
    ):
        name = clean_md(match.group(1))
        effect = clean_md(match.group(2).replace("\n", " "))
        if name in {"Outfits", "Clothing"}:
            continue
        effect_map[name] = effect

    lines = ["BEGIN TRANSACTION;", ""]
    lines += [
        "ALTER TABLE weapons ADD COLUMN name TEXT NOT NULL DEFAULT '';",
        "ALTER TABLE weapons ADD COLUMN crit_die INTEGER NOT NULL DEFAULT 0;",
        "ALTER TABLE weapons ADD COLUMN qualities TEXT NOT NULL DEFAULT '';",
        "ALTER TABLE weapons ADD COLUMN cost REAL NOT NULL DEFAULT 0;",
        "ALTER TABLE weapons ADD COLUMN weight REAL NOT NULL DEFAULT 0;",
        "",
        "CREATE TABLE IF NOT EXISTS clothing (id INTEGER PRIMARY KEY, name TEXT NOT NULL, short_description TEXT NOT NULL DEFAULT '', long_description TEXT NOT NULL DEFAULT '', clothing_type TEXT NOT NULL DEFAULT '', locations_covered TEXT NOT NULL DEFAULT '', effect_text TEXT NOT NULL DEFAULT '', cost REAL NOT NULL DEFAULT 0, weight REAL NOT NULL DEFAULT 0, UNIQUE (name));",
        "CREATE TABLE IF NOT EXISTS consumables (id INTEGER PRIMARY KEY, name TEXT NOT NULL, short_description TEXT NOT NULL DEFAULT '', long_description TEXT NOT NULL DEFAULT '', consumable_type TEXT NOT NULL DEFAULT '', hp_healed INTEGER NOT NULL DEFAULT 0, addiction_threshold INTEGER NOT NULL DEFAULT 0, alcoholic INTEGER NOT NULL DEFAULT 0, cost REAL NOT NULL DEFAULT 0, weight REAL NOT NULL DEFAULT 0, UNIQUE (name));",
        "CREATE TABLE IF NOT EXISTS utilities (id INTEGER PRIMARY KEY, name TEXT NOT NULL, short_description TEXT NOT NULL DEFAULT '', long_description TEXT NOT NULL DEFAULT '', category TEXT NOT NULL DEFAULT '', effect_text TEXT NOT NULL DEFAULT '', cost REAL NOT NULL DEFAULT 0, weight REAL NOT NULL DEFAULT 0, UNIQUE (name));",
        "",
    ]

    for wid, cand in matched.items():
        lines.append(
            f"UPDATE weapons SET name = {esc(cand['name'])}, crit_die = 0, qualities = {esc(cand['qualities'])}, cost = {esc(cand['cost'])}, weight = {esc(cand['weight'])} WHERE id = {wid};"
        )

    clothing_id = 22
    for row in clothing_rows:
        item = row["Item"]
        if item in {"Outfits", "Clothing"}:
            continue
        ctype = (
            "Outfit"
            if "Outfit" in item
            or "Attire" in item
            or "Robe" in item
            or "Garments" in item
            or "Gown" in item
            else "Clothing"
        )
        lines.append(
            f"INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES ({clothing_id}, {esc(item)}, '', '', {esc(ctype)}, {esc(normalize_locations(row['Locations Covered']))}, {esc(effect_map.get(item, ''))}, {esc(float(row['Cost']))}, {esc(float(row['Weight']))});"
        )
        clothing_id += 1

    cid = 62
    categories = ["Food", "Beverage", "Potion or Herb", "Poison"]
    for category, table in zip(categories, consumable_tables):
        for row in table:
            hp_healed = int(row.get("HP Healed", 0) or 0)
            addictive = row.get("Addictive", "")
            addiction_threshold = 0
            if isinstance(addictive, str) and addictive.startswith("Yes"):
                parts = addictive.split()
                addiction_threshold = (
                    int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 1
                )
            alcoholic = 1 if "Alcoholic" in row.get("Effect", "") else 0
            cost = 0 if row.get("Cost", "-") == "-" else float(row["Cost"])
            lines.append(
                f"INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES ({cid}, {esc(row['Item'])}, '', '', {esc(category)}, {hp_healed}, {addiction_threshold}, {alcoholic}, {esc(cost)}, {esc(float(row['Weight']))});"
            )
            cid += 1

    uid = 148
    current_category = "Utility"
    for row in utility_rows:
        item = row["Item"]
        if item in {"Crafting Tools", "Instruments"}:
            current_category = item
            continue
        cost = 0 if row.get("Cost", "-") == "-" else float(row["Cost"])
        weight = 0 if row.get("Weight", "-") == "-" else float(row["Weight"])
        lines.append(
            f"INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES ({uid}, {esc(item)}, '', '', {esc(current_category)}, {esc(row['Effect'])}, {esc(cost)}, {esc(weight)});"
        )
        uid += 1

    lines.append("")
    lines.append("COMMIT;")
    OUT_SQL.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
