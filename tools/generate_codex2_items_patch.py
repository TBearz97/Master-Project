import sqlite3
from pathlib import Path


ROOT = Path(r"C:\Users\torb1\Documents\GitHub\Master-Project")
OLD_DB = ROOT / "data" / "Codex.db"
OUT_SQL = ROOT / "sql" / "codex2_items_patch.sql"


def esc(value):
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def insert(table, columns, row):
    return f"INSERT OR REPLACE INTO {table} ({', '.join(columns)}) VALUES ({', '.join(esc(v) for v in row)});"


def main() -> None:
    con = sqlite3.connect(OLD_DB)
    con.row_factory = sqlite3.Row
    cur = con.cursor()

    lines = [
        "BEGIN TRANSACTION;",
        "",
        "ALTER TABLE weapons ADD COLUMN name TEXT NOT NULL DEFAULT '';",
        "ALTER TABLE weapons ADD COLUMN crit_die INTEGER NOT NULL DEFAULT 0;",
        "ALTER TABLE weapons ADD COLUMN qualities TEXT NOT NULL DEFAULT '';",
        "ALTER TABLE weapons ADD COLUMN cost REAL NOT NULL DEFAULT 0;",
        "ALTER TABLE weapons ADD COLUMN weight REAL NOT NULL DEFAULT 0;",
        "",
        "CREATE TABLE IF NOT EXISTS clothing (",
        "    id INTEGER PRIMARY KEY,",
        "    name TEXT NOT NULL,",
        "    short_description TEXT NOT NULL DEFAULT '',",
        "    long_description TEXT NOT NULL DEFAULT '',",
        "    clothing_type TEXT NOT NULL DEFAULT '',",
        "    locations_covered TEXT NOT NULL DEFAULT '',",
        "    effect_text TEXT NOT NULL DEFAULT '',",
        "    cost REAL NOT NULL DEFAULT 0,",
        "    weight REAL NOT NULL DEFAULT 0,",
        "    UNIQUE (name)",
        ");",
        "",
        "CREATE TABLE IF NOT EXISTS consumables (",
        "    id INTEGER PRIMARY KEY,",
        "    name TEXT NOT NULL,",
        "    short_description TEXT NOT NULL DEFAULT '',",
        "    long_description TEXT NOT NULL DEFAULT '',",
        "    consumable_type TEXT NOT NULL DEFAULT '',",
        "    hp_healed INTEGER NOT NULL DEFAULT 0,",
        "    addiction_threshold INTEGER NOT NULL DEFAULT 0,",
        "    alcoholic INTEGER NOT NULL DEFAULT 0,",
        "    cost REAL NOT NULL DEFAULT 0,",
        "    weight REAL NOT NULL DEFAULT 0,",
        "    UNIQUE (name)",
        ");",
        "",
        "CREATE TABLE IF NOT EXISTS utilities (",
        "    id INTEGER PRIMARY KEY,",
        "    name TEXT NOT NULL,",
        "    short_description TEXT NOT NULL DEFAULT '',",
        "    long_description TEXT NOT NULL DEFAULT '',",
        "    category TEXT NOT NULL DEFAULT '',",
        "    effect_text TEXT NOT NULL DEFAULT '',",
        "    cost REAL NOT NULL DEFAULT 0,",
        "    weight REAL NOT NULL DEFAULT 0,",
        "    UNIQUE (name)",
        ");",
        "",
    ]

    for row in cur.execute(
        "SELECT ID, item, damage_die, crit_die, base_speed, qualities, size, weight, cost, range FROM Weapon ORDER BY ID"
    ):
        lines.append(
            "UPDATE weapons SET "
            f"name = {esc(row['item'])}, crit_die = {esc(row['crit_die'])}, qualities = {esc(row['qualities'] or '')}, cost = {esc(row['cost'])}, weight = {esc(row['weight'])} "
            f"WHERE id = {row['ID']};"
        )
    lines.append("")

    for row in cur.execute(
        "SELECT ID, item, locations_covered, weight, cost, type FROM Clothing ORDER BY ID"
    ):
        lines.append(
            insert(
                "clothing",
                [
                    "id",
                    "name",
                    "short_description",
                    "long_description",
                    "clothing_type",
                    "locations_covered",
                    "effect_text",
                    "cost",
                    "weight",
                ],
                [
                    row["ID"],
                    row["item"],
                    "",
                    "",
                    row["type"],
                    row["locations_covered"],
                    "",
                    row["cost"],
                    row["weight"],
                ],
            )
        )
    lines.append("")

    for row in cur.execute(
        "SELECT ID, item, type, hp_healed, addiction_threshold, alcoholic, weight, cost, effect FROM Consumable ORDER BY ID"
    ):
        lines.append(
            insert(
                "consumables",
                [
                    "id",
                    "name",
                    "short_description",
                    "long_description",
                    "consumable_type",
                    "hp_healed",
                    "addiction_threshold",
                    "alcoholic",
                    "cost",
                    "weight",
                ],
                [
                    row["ID"],
                    row["item"],
                    "",
                    "",
                    row["type"],
                    row["hp_healed"] or 0,
                    row["addiction_threshold"] or 0,
                    1 if row["alcoholic"] else 0,
                    row["cost"],
                    row["weight"],
                ],
            )
        )
    lines.append("")

    for row in cur.execute(
        "SELECT ID, item, category, effect, weight, cost FROM Utility ORDER BY ID"
    ):
        lines.append(
            insert(
                "utilities",
                [
                    "id",
                    "name",
                    "short_description",
                    "long_description",
                    "category",
                    "effect_text",
                    "cost",
                    "weight",
                ],
                [
                    row["ID"],
                    row["item"],
                    "",
                    "",
                    row["category"],
                    row["effect"] or "",
                    row["cost"],
                    row["weight"],
                ],
            )
        )

    lines.append("")
    lines.append("COMMIT;")
    OUT_SQL.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
