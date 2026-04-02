PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS attributes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    modifier_id_1 INTEGER,
    modifier_value_1 INTEGER NOT NULL DEFAULT 0,
    modifier_id_2 INTEGER,
    modifier_value_2 INTEGER NOT NULL DEFAULT 0,
    min_value INTEGER NOT NULL,
    max_value INTEGER NOT NULL,
    FOREIGN KEY (modifier_id_1) REFERENCES modifiers(id) ON DELETE SET NULL,
    FOREIGN KEY (modifier_id_2) REFERENCES modifiers(id) ON DELETE SET NULL,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS modifiers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    value_label TEXT NOT NULL DEFAULT '',
    expression TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    min_rank INT NULL,
    max_rank INT NULL,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS skill_rank_costs (
    target_rank INTEGER PRIMARY KEY,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    point_cost INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS defenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS resources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS damage_origins (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS damage_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS conditions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS effects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    defense_id INTEGER,
    CONSTRAINT fk_effects_defense
        FOREIGN KEY (defense_id) REFERENCES defenses(id)
        ON DELETE SET NULL,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS weapon_qualities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS ranges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    max_distance INTEGER,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS keywords (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    table_name TEXT NOT NULL,
    foreign_id INTEGER NOT NULL,
    UNIQUE (table_name, foreign_id)
);

CREATE TABLE IF NOT EXISTS perks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    requirement_text TEXT NOT NULL DEFAULT '',
    UNIQUE (name, category)
);

CREATE TABLE IF NOT EXISTS races (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    perk_id INTEGER,
    FOREIGN KEY (perk_id) REFERENCES perks(id) ON DELETE SET NULL,
    UNIQUE (name)
);


CREATE TABLE IF NOT EXISTS homelands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    perk_id INTEGER,
    FOREIGN KEY (perk_id) REFERENCES perks(id) ON DELETE SET NULL,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS backgrounds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    perk_id INTEGER,
    skill_id_1 INTEGER,
    skill_id_2 INTEGER,
    FOREIGN KEY (perk_id) REFERENCES perks(id) ON DELETE SET NULL,
    FOREIGN KEY (skill_id_1) REFERENCES skills(id) ON DELETE SET NULL,
    FOREIGN KEY (skill_id_2) REFERENCES skills(id) ON DELETE SET NULL,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS level_progression (
    level_value INTEGER PRIMARY KEY,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    xp_required INTEGER,
    formula_text TEXT NOT NULL DEFAULT '',
    skill_points_gained INTEGER,
    perks_gained INTEGER
);


CREATE TABLE IF NOT EXISTS item_effects (
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

CREATE TABLE IF NOT EXISTS weapons (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    weapon_class TEXT NOT NULL,
    damage_die TEXT NOT NULL DEFAULT '',
    crit_die INTEGER NOT NULL DEFAULT 0,
    base_speed INTEGER NOT NULL DEFAULT 0,
    range_band TEXT NOT NULL DEFAULT '',
    handedness TEXT NOT NULL DEFAULT '',
    qualities TEXT NOT NULL DEFAULT '',
    cost REAL NOT NULL DEFAULT 0,
    weight REAL NOT NULL DEFAULT 0,
    basic_attack_id INTEGER,
    proficient_attack_id INTEGER,
    expert_attack_id INTEGER,
    master_attack_id INTEGER,
    FOREIGN KEY (basic_attack_id) REFERENCES attacks(id) ON DELETE SET NULL,
    FOREIGN KEY (proficient_attack_id) REFERENCES attacks(id) ON DELETE SET NULL,
    FOREIGN KEY (expert_attack_id) REFERENCES attacks(id) ON DELETE SET NULL,
    FOREIGN KEY (master_attack_id) REFERENCES attacks(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS clothing (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    clothing_type TEXT NOT NULL DEFAULT '',
    locations_covered TEXT NOT NULL DEFAULT '',
    effect_text TEXT NOT NULL DEFAULT '',
    cost REAL NOT NULL DEFAULT 0,
    weight REAL NOT NULL DEFAULT 0,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS consumables (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    consumable_type TEXT NOT NULL DEFAULT '',
    hp_healed INTEGER NOT NULL DEFAULT 0,
    addiction_threshold INTEGER NOT NULL DEFAULT 0,
    alcoholic INTEGER NOT NULL DEFAULT 0,
    cost REAL NOT NULL DEFAULT 0,
    weight REAL NOT NULL DEFAULT 0,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS utilities (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT '',
    effect_text TEXT NOT NULL DEFAULT '',
    cost REAL NOT NULL DEFAULT 0,
    weight REAL NOT NULL DEFAULT 0,
    UNIQUE (name)
);


CREATE TABLE IF NOT EXISTS armor (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    armor_class TEXT NOT NULL DEFAULT '',
    locations_covered TEXT NOT NULL DEFAULT '',
    physical_dt INTEGER NOT NULL DEFAULT 0,
    magical_dt INTEGER NOT NULL DEFAULT 0,
    necrotic_dt INTEGER NOT NULL DEFAULT 0,
    equip_load REAL NOT NULL DEFAULT 0,
    cost REAL NOT NULL DEFAULT 0,
    weight REAL NOT NULL DEFAULT 0,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS starter_packs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    leftover_gold REAL NOT NULL DEFAULT 0,
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS starter_pack_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    starter_pack_id INTEGER NOT NULL,
    item_table TEXT NOT NULL DEFAULT '',
    item_id INTEGER NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    quantity INTEGER NOT NULL DEFAULT 1,
    loadout_group TEXT NOT NULL DEFAULT '',
    FOREIGN KEY (starter_pack_id) REFERENCES starter_packs(id) ON DELETE CASCADE,
    UNIQUE (starter_pack_id, item_table, item_id, loadout_group)
);

CREATE TABLE IF NOT EXISTS attacks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    attack_tier TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS spell_schools (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS spells (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    school TEXT NOT NULL DEFAULT '',
    tags TEXT NOT NULL DEFAULT '',
    difficulty TEXT NOT NULL DEFAULT '',
    range_band TEXT NOT NULL DEFAULT '',
    base_cast TEXT NOT NULL DEFAULT '',
    UNIQUE (name, school)
);
CREATE TABLE IF NOT EXISTS spell_variants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    spell_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    mana_cost TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    ordinal_position INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (spell_id) REFERENCES spells(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS strain_table (
    roll_total INTEGER PRIMARY KEY,
    result_name TEXT NOT NULL,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS npcs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    short_description TEXT NOT NULL DEFAULT '',
    long_description TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT '',
    level INTEGER NOT NULL DEFAULT 1,
    max_hp INTEGER NOT NULL DEFAULT 1,
    attributes TEXT NOT NULL DEFAULT '',
    skills TEXT NOT NULL DEFAULT '',
    attacks TEXT NOT NULL DEFAULT '',
    perks TEXT NOT NULL DEFAULT ''
);
