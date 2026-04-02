import sqlite3
from pathlib import Path


ROOT = Path(r"C:\Users\torb1\Documents\GitHub\Master-Project")
OLD_DB = ROOT / "data" / "Codex.db"
OUTPUT = ROOT / "sql" / "codex2_copy_descriptions_from_codex.sql"


def esc(value: str) -> str:
    return value.replace("'", "''")


def fetch_map(con: sqlite3.Connection, sql: str) -> dict[str, tuple[str, str]]:
    result: dict[str, tuple[str, str]] = {}
    for name, short_desc, long_desc in con.execute(sql):
        result[str(name)] = (str(short_desc or ""), str(long_desc or ""))
    return result


def emit_table_updates(
    lines: list[str], table: str, key_column: str, rows: dict[str, tuple[str, str]]
) -> None:
    for name, (short_desc, long_desc) in sorted(rows.items()):
        lines.append(
            f"UPDATE {table} SET short_description = '{esc(short_desc)}', long_description = '{esc(long_desc)}' WHERE {key_column} = '{esc(name)}';"
        )


def emit_keyword_updates(
    lines: list[str], table_name: str, rows: dict[str, tuple[str, str]]
) -> None:
    for name, (short_desc, long_desc) in sorted(rows.items()):
        lines.append(
            f"UPDATE keywords SET short_description = '{esc(short_desc)}', long_description = '{esc(long_desc)}' "
            f"WHERE table_name = '{esc(table_name)}' AND foreign_id = (SELECT id FROM {table_name} WHERE name = '{esc(name)}');"
        )


def main() -> None:
    con = sqlite3.connect(OLD_DB)

    old_keyword = fetch_map(
        con, "SELECT keyword, short_description, long_description FROM Keyword"
    )
    old_attributes = fetch_map(
        con, "SELECT name, short_description, long_description FROM Attribute"
    )
    old_skills = fetch_map(
        con, "SELECT name, short_description, long_description FROM Skill"
    )
    old_defenses = fetch_map(
        con, "SELECT name, short_description, long_description FROM Defence"
    )
    old_conditions = fetch_map(
        con, "SELECT name, short_description, long_description FROM Condition"
    )
    old_perks = fetch_map(
        con, "SELECT name, short_description, long_description FROM Perk"
    )
    old_races = fetch_map(
        con, "SELECT name, short_description, long_description FROM Race"
    )
    old_homelands = fetch_map(
        con, "SELECT name, short_description, long_description FROM Homeland"
    )
    old_backgrounds = fetch_map(
        con, "SELECT name, short_description, long_description FROM Background"
    )
    old_attacks = fetch_map(
        con, "SELECT name, short_description, long_description FROM Action"
    )
    old_npcs = fetch_map(
        con, "SELECT name, short_description, long_description FROM NPC"
    )

    lines = ["BEGIN TRANSACTION;", ""]

    emit_table_updates(lines, "attributes", "name", old_attributes)
    lines.append("")
    emit_table_updates(lines, "skills", "name", old_skills)
    lines.append("")
    emit_table_updates(lines, "defenses", "name", old_defenses)
    lines.append("")
    emit_table_updates(lines, "conditions", "name", old_conditions)
    lines.append("")
    emit_table_updates(lines, "perks", "name", old_perks)
    lines.append("")
    emit_table_updates(lines, "races", "name", old_races)
    lines.append("")
    emit_table_updates(lines, "homelands", "name", old_homelands)
    lines.append("")
    emit_table_updates(lines, "backgrounds", "name", old_backgrounds)
    lines.append("")
    emit_table_updates(lines, "attacks", "name", old_attacks)
    lines.append("")
    emit_table_updates(lines, "npcs", "name", old_npcs)
    lines.append("")

    for table_name in [
        "resources",
        "damage_origins",
        "damage_types",
        "effects",
        "weapon_qualities",
        "ranges",
        "spell_schools",
        "spells",
        "armor",
    ]:
        emit_table_updates(lines, table_name, "name", old_keyword)
        lines.append("")

    emit_keyword_updates(lines, "attributes", old_attributes)
    emit_keyword_updates(lines, "skills", old_skills)
    emit_keyword_updates(lines, "defenses", old_defenses)
    emit_keyword_updates(lines, "conditions", old_conditions)
    emit_keyword_updates(lines, "perks", old_perks)
    emit_keyword_updates(lines, "races", old_races)
    emit_keyword_updates(lines, "homelands", old_homelands)
    emit_keyword_updates(lines, "backgrounds", old_backgrounds)
    emit_keyword_updates(lines, "attacks", old_attacks)
    emit_keyword_updates(lines, "npcs", old_npcs)
    emit_keyword_updates(lines, "resources", old_keyword)
    emit_keyword_updates(lines, "damage_origins", old_keyword)
    emit_keyword_updates(lines, "damage_types", old_keyword)
    emit_keyword_updates(lines, "effects", old_keyword)
    emit_keyword_updates(lines, "weapon_qualities", old_keyword)
    emit_keyword_updates(lines, "ranges", old_keyword)
    emit_keyword_updates(lines, "spell_schools", old_keyword)
    emit_keyword_updates(lines, "spells", old_keyword)
    emit_keyword_updates(lines, "armor", old_keyword)
    lines.append("")
    lines.append("COMMIT;")

    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
