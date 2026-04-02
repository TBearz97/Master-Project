BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS item_effects_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    item_table TEXT NOT NULL DEFAULT '',
    name TEXT NOT NULL,
    expression TEXT NOT NULL DEFAULT '',
    value TEXT NOT NULL DEFAULT '',
    duration TEXT NOT NULL DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 1,
    UNIQUE (item_table, item_id, name, sort_order)
);

WITH RECURSIVE source AS (
    SELECT
        item_id,
        item_table,
        name,
        TRIM(
            CASE
                WHEN COALESCE(expression, '') <> '' THEN expression
                WHEN COALESCE(long_description, '') <> '' THEN long_description
                WHEN COALESCE(short_description, '') <> '' THEN short_description
                ELSE ''
            END
        ) AS raw_text,
        COALESCE(duration, '') AS base_duration,
        sort_order
    FROM item_effects
),
split AS (
    SELECT
        item_id,
        item_table,
        name,
        base_duration,
        sort_order,
        1 AS part_index,
        TRIM(CASE WHEN INSTR(raw_text, ';') > 0 THEN SUBSTR(raw_text, 1, INSTR(raw_text, ';') - 1) ELSE raw_text END) AS part,
        TRIM(CASE WHEN INSTR(raw_text, ';') > 0 THEN SUBSTR(raw_text, INSTR(raw_text, ';') + 1) ELSE '' END) AS rest
    FROM source
    WHERE raw_text <> ''

    UNION ALL

    SELECT
        item_id,
        item_table,
        name,
        base_duration,
        sort_order,
        part_index + 1,
        TRIM(CASE WHEN INSTR(rest, ';') > 0 THEN SUBSTR(rest, 1, INSTR(rest, ';') - 1) ELSE rest END),
        TRIM(CASE WHEN INSTR(rest, ';') > 0 THEN SUBSTR(rest, INSTR(rest, ';') + 1) ELSE '' END)
    FROM split
    WHERE rest <> ''
),
parsed AS (
    SELECT
        item_id,
        item_table,
        name AS original_name,
        part,
        LOWER(part) AS part_lower,
        base_duration,
        sort_order,
        part_index
    FROM split
    WHERE part <> ''
)
INSERT INTO item_effects_new (
    item_id,
    item_table,
    name,
    expression,
    value,
    duration,
    sort_order
)
SELECT
    item_id,
    item_table,
    CASE
        WHEN part_lower LIKE 'hp healed:%' OR part_lower LIKE 'heals % hp%' THEN 'Restore HP'
        WHEN part_lower LIKE 'gain % mana%' THEN 'Restore Mana'
        WHEN part_lower LIKE 'gain % ap%' OR part_lower LIKE 'immediately gain % ap%' THEN 'Gain AP'
        WHEN part_lower LIKE '+% max hp%' THEN 'Increase Max HP'
        WHEN part_lower LIKE '+% physical dt%' THEN 'Increase Physical DT'
        WHEN part_lower LIKE '+% magical dt%' THEN 'Increase Magical DT'
        WHEN part_lower LIKE '+% necrotic dt%' THEN 'Increase Necrotic DT'
        WHEN part_lower LIKE '+% deflection%' THEN 'Increase Deflection'
        WHEN part_lower LIKE '%carry weight increases by +%' THEN 'Increase Carry Weight'
        WHEN part_lower LIKE 'heal % necrotic damage%' THEN 'Restore Necrotic Damage'
        WHEN part_lower LIKE '%alcoholic%' THEN 'Alcoholic'
        WHEN part_lower LIKE 'underwater breathing%' THEN 'Underwater Breathing'
        WHEN part_lower LIKE 'grants the stun effect%' THEN 'Apply Stun'
        ELSE original_name
    END,
    CASE
        WHEN part_lower LIKE 'hp healed:%' OR part_lower LIKE 'heals % hp%' THEN 'hp + value'
        WHEN part_lower LIKE 'gain % mana%' THEN 'mana + value'
        WHEN part_lower LIKE 'gain % ap%' OR part_lower LIKE 'immediately gain % ap%' THEN 'ap + value'
        WHEN part_lower LIKE '+% max hp%' THEN 'max_hp + value'
        WHEN part_lower LIKE '+% physical dt%' THEN 'physical_dt + value'
        WHEN part_lower LIKE '+% magical dt%' THEN 'magical_dt + value'
        WHEN part_lower LIKE '+% necrotic dt%' THEN 'necrotic_dt + value'
        WHEN part_lower LIKE '+% deflection%' THEN 'deflection + value'
        WHEN part_lower LIKE '%carry weight increases by +%' THEN 'carry_weight + value'
        WHEN part_lower LIKE 'heal % necrotic damage%' THEN 'necrotic_damage - value'
        WHEN part_lower LIKE '%alcoholic%' THEN '1'
        WHEN part_lower LIKE 'underwater breathing%' THEN '1'
        WHEN part_lower LIKE 'grants the stun effect%' THEN '1'
        ELSE 'custom'
    END,
    CASE
        WHEN part_lower LIKE 'hp healed:%' THEN TRIM(SUBSTR(part, INSTR(part, ':') + 1))
        WHEN part_lower LIKE 'heals % hp%' THEN TRIM(SUBSTR(part, 7, INSTR(SUBSTR(part, 7), ' ') - 1))
        WHEN part_lower LIKE 'gain % mana%' THEN TRIM(SUBSTR(part, 6, INSTR(SUBSTR(part, 6), ' ') - 1))
        WHEN part_lower LIKE 'gain % ap%' THEN TRIM(SUBSTR(part, 6, INSTR(SUBSTR(part, 6), ' ') - 1))
        WHEN part_lower LIKE 'immediately gain % ap%' THEN TRIM(SUBSTR(part, 18, INSTR(SUBSTR(part, 18), ' ') - 1))
        WHEN part_lower LIKE '+% max hp%' THEN TRIM(SUBSTR(part, 2, INSTR(SUBSTR(part, 2), ' ') - 1))
        WHEN part_lower LIKE '+% physical dt%' THEN TRIM(SUBSTR(part, 2, INSTR(SUBSTR(part, 2), ' ') - 1))
        WHEN part_lower LIKE '+% magical dt%' THEN TRIM(SUBSTR(part, 2, INSTR(SUBSTR(part, 2), ' ') - 1))
        WHEN part_lower LIKE '+% necrotic dt%' THEN TRIM(SUBSTR(part, 2, INSTR(SUBSTR(part, 2), ' ') - 1))
        WHEN part_lower LIKE '+% deflection%' THEN TRIM(SUBSTR(part, 2, INSTR(SUBSTR(part, 2), ' ') - 1))
        WHEN part_lower LIKE '%carry weight increases by +%' THEN TRIM(SUBSTR(part, INSTR(part, '+') + 1, INSTR(SUBSTR(part, INSTR(part, '+') + 1), ' ') - 1))
        WHEN part_lower LIKE 'heal % necrotic damage%' THEN TRIM(SUBSTR(part, 6, INSTR(SUBSTR(part, 6), ' ') - 1))
        WHEN part_lower LIKE '%alcoholic%' THEN '1'
        WHEN part_lower LIKE 'underwater breathing%' THEN '1'
        WHEN part_lower LIKE 'grants the stun effect%' THEN 'Stunned'
        ELSE part
    END,
    CASE
        WHEN part_lower LIKE '%until end of next scene%' THEN 'Until End of Next Scene'
        WHEN part_lower LIKE '%at the start of the next scene%' THEN 'Start of Next Scene'
        WHEN part_lower LIKE '%at the start of each turn%' AND base_duration = '' THEN 'While Active'
        ELSE base_duration
    END,
    (sort_order * 10) + part_index
FROM parsed;

DROP TABLE item_effects;
ALTER TABLE item_effects_new RENAME TO item_effects;

COMMIT;
