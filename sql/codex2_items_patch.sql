BEGIN TRANSACTION;

ALTER TABLE weapons ADD COLUMN name TEXT NOT NULL DEFAULT '';
ALTER TABLE weapons ADD COLUMN crit_die INTEGER NOT NULL DEFAULT 0;
ALTER TABLE weapons ADD COLUMN qualities TEXT NOT NULL DEFAULT '';
ALTER TABLE weapons ADD COLUMN cost REAL NOT NULL DEFAULT 0;
ALTER TABLE weapons ADD COLUMN weight REAL NOT NULL DEFAULT 0;

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

UPDATE weapons SET name = 'Unarmed', crit_die = 12, qualities = '', cost = 0, weight = 0.0 WHERE id = 1;
UPDATE weapons SET name = 'Bear Claws', crit_die = 6, qualities = 'Brutal', cost = 30, weight = 1.0 WHERE id = 2;
UPDATE weapons SET name = 'Whip', crit_die = 6, qualities = 'Grappling, Reach', cost = 22, weight = 1.5 WHERE id = 3;
UPDATE weapons SET name = 'Knife', crit_die = 12, qualities = 'Concealed, Thrown (M)', cost = 18, weight = 0.5 WHERE id = 4;
UPDATE weapons SET name = 'Dagger', crit_die = 12, qualities = 'Accurate, Concealed, Thrown (M)', cost = 19, weight = 0.5 WHERE id = 5;
UPDATE weapons SET name = 'Stiletto', crit_die = 12, qualities = 'Concealed, Brutal, Thrown (C)', cost = 20, weight = 0.5 WHERE id = 6;
UPDATE weapons SET name = 'Reaper', crit_die = 6, qualities = '', cost = 34, weight = 4.0 WHERE id = 7;
UPDATE weapons SET name = 'Staff', crit_die = 6, qualities = '', cost = 20, weight = 1.5 WHERE id = 8;
UPDATE weapons SET name = 'Club', crit_die = 6, qualities = '', cost = 20, weight = 1.5 WHERE id = 9;
UPDATE weapons SET name = 'Maul', crit_die = 4, qualities = '', cost = 39, weight = 5.5 WHERE id = 10;
UPDATE weapons SET name = 'Hand Axe', crit_die = 6, qualities = 'Brutal', cost = 23, weight = 2.0 WHERE id = 11;
UPDATE weapons SET name = 'Battle Axe', crit_die = 6, qualities = 'Versatile, Brutal', cost = 31, weight = 4.0 WHERE id = 12;
UPDATE weapons SET name = 'Great Axe', crit_die = 4, qualities = 'Brutal', cost = 45, weight = 5.5 WHERE id = 13;
UPDATE weapons SET name = 'Hammer', crit_die = 6, qualities = '', cost = 21, weight = 2.0 WHERE id = 14;
UPDATE weapons SET name = 'Warhammer', crit_die = 6, qualities = 'Versatile', cost = 45, weight = 4.0 WHERE id = 15;
UPDATE weapons SET name = 'Great Hammer', crit_die = 4, qualities = '', cost = 44, weight = 5.5 WHERE id = 16;
UPDATE weapons SET name = 'Short Sword', crit_die = 6, qualities = 'Parry', cost = 22, weight = 2.0 WHERE id = 17;
UPDATE weapons SET name = 'Broad Sword', crit_die = 6, qualities = 'Parry, Versatile', cost = 32, weight = 3.5 WHERE id = 18;
UPDATE weapons SET name = 'Great Sword', crit_die = 4, qualities = 'Parry', cost = 46, weight = 5.5 WHERE id = 19;
UPDATE weapons SET name = 'Javelin', crit_die = 6, qualities = 'Thrown (M)', cost = 26, weight = 1.0 WHERE id = 20;
UPDATE weapons SET name = 'Spear', crit_die = 6, qualities = 'Accurate, Reach', cost = 22, weight = 2.0 WHERE id = 21;
UPDATE weapons SET name = 'Pike', crit_die = 6, qualities = 'Reach', cost = 34, weight = 4.0 WHERE id = 22;
UPDATE weapons SET name = 'Wakizashi', crit_die = 6, qualities = '', cost = 28, weight = 2.0 WHERE id = 23;
UPDATE weapons SET name = 'Katana', crit_die = 6, qualities = 'Versatile', cost = 31, weight = 4.0 WHERE id = 24;
UPDATE weapons SET name = 'Ōdachi', crit_die = 4, qualities = '', cost = 46, weight = 5.5 WHERE id = 25;
UPDATE weapons SET name = 'Flail', crit_die = 6, qualities = '', cost = 34, weight = 2.0 WHERE id = 26;
UPDATE weapons SET name = 'Morning Star', crit_die = 6, qualities = 'Versatile', cost = 45, weight = 4.0 WHERE id = 27;
UPDATE weapons SET name = 'Scimitar', crit_die = 6, qualities = '', cost = 26, weight = 2.0 WHERE id = 28;
UPDATE weapons SET name = 'Rapier', crit_die = 10, qualities = 'Accurate', cost = 26, weight = 2.0 WHERE id = 29;
UPDATE weapons SET name = 'Polearm', crit_die = 4, qualities = 'Reach', cost = 47, weight = 4.0 WHERE id = 30;
UPDATE weapons SET name = 'Halberd', crit_die = 4, qualities = 'Reach', cost = 48, weight = 5.0 WHERE id = 31;
UPDATE weapons SET name = 'Blunderbuss', crit_die = 4, qualities = 'Brutal, Close Quarters', cost = 40, weight = 2.0 WHERE id = 32;
UPDATE weapons SET name = 'Pistol', crit_die = 6, qualities = 'Brutal, Close Quarters', cost = 35, weight = 2.0 WHERE id = 33;
UPDATE weapons SET name = 'Musket', crit_die = 4, qualities = 'Brutal', cost = 50, weight = 5.0 WHERE id = 34;
UPDATE weapons SET name = 'Short Bow', crit_die = 12, qualities = '', cost = 20, weight = 1.0 WHERE id = 35;
UPDATE weapons SET name = 'Hunting Bow', crit_die = 6, qualities = '', cost = 25, weight = 1.0 WHERE id = 36;
UPDATE weapons SET name = 'War Bow', crit_die = 6, qualities = '', cost = 32, weight = 2.0 WHERE id = 37;
UPDATE weapons SET name = 'Long Bow', crit_die = 4, qualities = '', cost = 40, weight = 2.0 WHERE id = 38;
UPDATE weapons SET name = 'Hand Crossbow', crit_die = 10, qualities = 'Accurate, Close Quarters', cost = 28, weight = 2.0 WHERE id = 39;
UPDATE weapons SET name = 'Crossbow', crit_die = 6, qualities = 'Accurate', cost = 34, weight = 3.0 WHERE id = 40;
UPDATE weapons SET name = 'Arbalest', crit_die = 4, qualities = 'Accurate', cost = 42, weight = 4.0 WHERE id = 41;
UPDATE weapons SET name = 'Wand', crit_die = 6, qualities = 'Accurate, Close Quarters', cost = 35, weight = 0.5 WHERE id = 42;
UPDATE weapons SET name = 'Buckler', crit_die = 6, qualities = 'Parry, +1 Defense, Accurate', cost = 25, weight = 2.0 WHERE id = 43;
UPDATE weapons SET name = 'Shield', crit_die = 6, qualities = 'Parry, +2 Defense', cost = 40, weight = 4.0 WHERE id = 44;
UPDATE weapons SET name = 'Tower Shield', crit_die = 6, qualities = 'Parry, +3 Defense, Heavy, Cover', cost = 60, weight = 7.0 WHERE id = 45;

INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (1, 'Alchemist''s Attire', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 20, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (2, 'Blacksmith''s Outfit', '', '', 'Outfit', 'Leg Left, Leg Right, Torso', '', 10, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (3, 'Bandit''s Outfit', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 10, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (4, 'Mercenary''s Outfit', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 40, 3.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (5, 'Nature''s Gown', '', '', 'Outfit', 'Head, Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 20, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (6, 'Noble''s Attire', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 40, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (7, 'Performer''s Outfit', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 20, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (8, 'Pirate''s Attire', '', '', 'Outfit', 'Head, Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 30, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (9, 'Priest''s Garments', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 30, 0.5);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (10, 'Scribe''s Robe', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 30, 0.5);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (11, 'Ranger''s Outfit', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 20, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (12, 'Tribal Outfit', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right', '', 30, 0.5);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (13, 'Wizard''s Robe', '', '', 'Outfit', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 30, 0.5);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (14, 'Commoner''s Clothing', '', '', 'Clothing', 'Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 10, 1.0);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (15, 'Desert Clothing', '', '', 'Clothing', 'Head, Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 20, 0.5);
INSERT OR REPLACE INTO clothing (id, name, short_description, long_description, clothing_type, locations_covered, effect_text, cost, weight) VALUES (16, 'Fur Clothing', '', '', 'Clothing', 'Head, Arm Left, Arm Right, Leg Left, Leg Right, Torso', '', 20, 2.0);

INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (1, 'Apple', '', '', 'Food', 2, 0, 0, 8, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (2, 'Bear Meat', '', '', 'Food', 9, 0, 0, 85, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (3, 'Bear Ribs', '', '', 'Food', 13, 0, 0, 90, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (4, 'Bear Roast', '', '', 'Food', 14, 0, 0, 110, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (5, 'Bread', '', '', 'Food', 5, 0, 0, 12, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (6, 'Carrot', '', '', 'Food', 2, 0, 0, 6, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (7, 'Cheese', '', '', 'Food', 6, 0, 0, 25, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (8, 'Corn', '', '', 'Food', 2, 0, 0, 6, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (9, 'Crab Meat', '', '', 'Food', 9, 0, 0, 18, 0.3);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (10, 'Crab Cake', '', '', 'Food', 13, 0, 0, 35, 0.3);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (11, 'Deer Meat', '', '', 'Food', 8, 0, 0, 50, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (12, 'Deer Stew', '', '', 'Food', 12, 0, 0, 60, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (13, 'Grilled Deer', '', '', 'Food', 11, 0, 0, 60, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (14, 'Dragon Egg', '', '', 'Food', 7, 0, 0, 72, 0.3);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (15, 'Dragon Meat', '', '', 'Food', 9, 0, 0, 110, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (16, 'Dragon Omelet', '', '', 'Food', 11, 0, 0, 90, 0.3);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (17, 'Dragon Steak', '', '', 'Food', 14, 0, 0, 130, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (18, 'Squirrel Meat', '', '', 'Food', 4, 0, 0, 4, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (19, 'Roasted Squirrel', '', '', 'Food', 6, 0, 0, 15, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (20, 'Squirrel Stew', '', '', 'Food', 10, 0, 0, 24, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (21, 'Tomato', '', '', 'Food', 3, 0, 0, 6, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (22, 'Potato', '', '', 'Food', 3, 0, 0, 6, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (23, 'Pork Meat', '', '', 'Food', 4, 0, 0, 12, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (24, 'Pork Ribs', '', '', 'Food', 7, 0, 0, 15, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (25, 'Pork Roast', '', '', 'Food', 9, 0, 0, 17, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (26, 'Raw Beef', '', '', 'Food', 3, 0, 0, 28, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (27, 'Cooked Beef', '', '', 'Food', 10, 0, 0, 40, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (28, 'Vegetable Soup', '', '', 'Food', 7, 0, 0, 13, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (29, 'Banana', '', '', 'Food', 3, 0, 0, 7, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (30, 'Mango', '', '', 'Food', 3, 0, 0, 9, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (31, 'Raw Fish', '', '', 'Food', 3, 0, 0, 8, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (32, 'Fried Fish', '', '', 'Food', 7, 0, 0, 15, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (33, 'Raw Chicken', '', '', 'Food', 4, 0, 0, 20, 2.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (34, 'Roasted Chicken', '', '', 'Food', 8, 0, 0, 28, 2.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (35, 'Pancakes', '', '', 'Food', 8, 0, 0, 18, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (36, 'Burger', '', '', 'Food', 9, 0, 0, 22, 0.3);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (37, 'Wolf Meat', '', '', 'Food', 4, 0, 0, 10, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (38, 'Grilled Wolf', '', '', 'Food', 7, 0, 0, 16, 0.4);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (39, 'Dirty Water', '', '', 'Beverage', 2, 0, 0, 3, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (40, 'Clean Water', '', '', 'Beverage', 3, 0, 0, 10, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (41, 'Ale', '', '', 'Beverage', 0, 0, 1, 5, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (42, 'Apple Juice', '', '', 'Beverage', 3, 0, 0, 18, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (43, 'Bourbon', '', '', 'Beverage', 0, 0, 1, 12, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (44, 'Carrot Juice', '', '', 'Beverage', 3, 0, 0, 9, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (45, 'Dirty Wanderer', '', '', 'Beverage', 0, 0, 1, 14, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (46, 'Milk', '', '', 'Beverage', 1, 0, 0, 17, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (47, 'Moonshine', '', '', 'Beverage', 0, 0, 1, 13, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (48, 'Stillheart Champagne', '', '', 'Beverage', 10, 0, 1, 40, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (49, 'Stillheart Port Wine', '', '', 'Beverage', 3, 0, 1, 34, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (50, 'Stillheart Wine', '', '', 'Beverage', 2, 0, 1, 20, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (51, 'Rum', '', '', 'Beverage', 0, 0, 1, 15, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (52, 'Tomato Juice', '', '', 'Beverage', 3, 0, 0, 10, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (53, 'Vodka', '', '', 'Beverage', 2, 0, 1, 32, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (54, 'Whiskey', '', '', 'Beverage', 0, 0, 1, 27, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (55, 'Wine', '', '', 'Beverage', 0, 0, 1, 15, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (56, 'Brox Weed', '', '', 'Herb', 0, 2, 0, 60, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (57, 'Grol Bark', '', '', 'Herb', 0, 2, 0, 50, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (58, 'Yorin''s Root', '', '', 'Herb', 0, 1, 0, 100, 0.1);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (59, 'Potion of Vitality', '', '', 'Potion', 0, 2, 0, 45, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (60, 'Potion of Greater Vitality', '', '', 'Potion', 0, 1, 0, 75, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (61, 'Potion of Fitness', '', '', 'Potion', 0, 1, 0, 75, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (62, 'Potion of Sharp Mind', '', '', 'Potion', 0, 3, 0, 50, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (63, 'Potion of Quickened Mind', '', '', 'Potion', 0, 1, 0, 50, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (64, 'Potion of the Eased Mind', '', '', 'Potion', 0, 1, 0, 40, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (65, 'Potion of the Opened Mind', '', '', 'Potion', 0, 2, 0, 60, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (66, 'Potion of Fury', '', '', 'Potion', 0, 1, 0, 30, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (67, 'Potion of Charm', '', '', 'Potion', 0, 2, 0, 60, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (68, 'Potion of Speed', '', '', 'Potion', 0, 2, 0, 50, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (69, 'Potion of Greater Speed', '', '', 'Potion', 0, 3, 0, 67, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (70, 'Potion of Lasting Speed', '', '', 'Potion', 0, 1, 0, 60, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (71, 'Demon Blood, Raw', '', '', 'Potion', 0, 1, 0, 55, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (72, 'Demon Blood, Distilled', '', '', 'Potion', 0, 2, 0, 50, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (73, 'Potion of Demon Speed', '', '', 'Potion', 0, 1, 0, 70, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (74, 'Potion of Demon Vitality', '', '', 'Potion', 0, 1, 0, 70, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (75, 'Potion of Demon Mind', '', '', 'Potion', 0, 1, 0, 70, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (76, 'Potion of Invisibility', '', '', 'Potion', 0, 1, 0, 100, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (77, 'Healing Potion', '', '', 'Potion', 0, 0, 0, 30, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (78, 'Greater Healing Potion', '', '', 'Potion', 0, 0, 0, 50, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (79, 'Superior Healing Potion', '', '', 'Potion', 0, 0, 0, 90, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (80, 'The Erudite''s Brew', '', '', 'Potion', 0, 1, 0, 60, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (81, 'Potion of Mana', '', '', 'Potion', 0, 3, 0, 32, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (82, 'Greater Potion of Mana', '', '', 'Potion', 0, 2, 0, 53, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (83, 'Superior Potion of Mana', '', '', 'Potion', 0, 1, 0, 110, 0.2);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (84, 'Stunning Poison', '', '', 'Poison', 0, 0, 0, 25, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (85, 'Persistent Poison', '', '', 'Poison', 0, 0, 0, 25, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (86, 'Nightshade Toxin', '', '', 'Poison', 0, 0, 0, 32, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (87, 'Paralytic Venom', '', '', 'Poison', 0, 0, 0, 30, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (88, 'Blinding Powder', '', '', 'Poison', 0, 0, 0, 20, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (89, 'Corrosive Oil', '', '', 'Poison', 0, 0, 0, 35, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (90, 'Sleeping Draught', '', '', 'Poison', 0, 0, 0, 28, 0.5);
INSERT OR REPLACE INTO consumables (id, name, short_description, long_description, consumable_type, hp_healed, addiction_threshold, alcoholic, cost, weight) VALUES (91, 'Weakness Ichor', '', '', 'Poison', 0, 0, 0, 26, 0.5);

INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (1, 'Backpack, Large', '', '', 'Utility', 'Wearer adds 5 × STR to maximum Carry Weight.', 60, 2.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (2, 'Backpack, Small', '', '', 'Utility', 'Wearer adds 3 × STR to maximum Carry Weight.', 30, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (3, 'Lockpick', '', '', 'Utility', 'Reduces difficulty of Lockpick tests by 1 (min 1). One bobby pin breaks per complication.', 1, 0.1);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (4, 'Medical Bag', '', '', 'Utility', 'Reduce difficulty of Medicine tests by 1. Allows care of 2 extra patients.', 300, 5.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (5, 'Bandages', '', '', 'Utility', 'Heal +1 on First Aid. Stops bleeding effects.', 1, 0.1);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (6, 'Lantern', '', '', 'Utility', 'Generates bright light within Close range, dim light within Medium.', 15, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (7, 'Lockpick Set', '', '', 'Utility', 'Reduces difficulty of Lockpick tests by 1 (min 0). Breaks after 3 complications.', 150, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (8, 'Torch', '', '', 'Utility', 'Bright light within Close until end of scene. Requires INT+Survival to light.', 10, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (9, 'Bedroll', '', '', 'Utility', 'Allows a character to become rested outdoors.', 35, 4.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (10, 'Hunting Trap', '', '', 'Utility', 'Hidden trap, PER+Investigation to detect. On trigger: 4 CD damage + Intense, Grappling, Vicious 1, Breaking.', 50, 10.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (11, 'Ink', '', '', 'Utility', 'Used for writing. Empty after 30 uses.', 5, 0.4);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (12, 'Ink Pen', '', '', 'Utility', 'Used for writing. May break on complication.', 3, 0.1);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (13, 'Paper', '', '', 'Utility', 'Used for writing. Bought in stacks of 30.', 7, 0.1);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (14, 'Manacles', '', '', 'Utility', 'Restrains limbs. Can be broken with STR+Athletics (diff 4) or unlocked with Sleight of Hand (diff 2).', 28, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (15, 'Oil', '', '', 'Utility', 'Flammable. Once ignited, cannot be cleared with Clear Minor action.', 19, 0.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (16, 'Portable Ram', '', '', 'Utility', 'Two-handed. Deals 3 CD to structures with Vicious 4.', 125, 18.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (17, 'Rope', '', '', 'Utility', '15 meter hemp rope.', 11, 5.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (18, 'Two-Person Tent', '', '', 'Utility', 'Allows 2 characters to rest outdoors.', 84, 10.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (19, 'One-Person Tent', '', '', 'Utility', 'Allows 1 character to rest outdoors.', 65, 7.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (20, 'Waterskin', '', '', 'Utility', 'Holds 2 liters of liquid.', 16, 0.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (21, 'Bottle', '', '', 'Utility', 'Holds 1 liter of liquid.', 22, 0.3);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (22, 'Pouch', '', '', 'Utility', 'Holds smaller items (chems, bullets, coins).', 18, 0.2);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (23, 'Vial', '', '', 'Utility', 'Holds 0.5 liters of liquid.', 35, 0.1);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (24, 'Bit and Bridle', '', '', 'Utility', 'Standard gear to direct a mount.', 20, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (25, 'Smithing Tools', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 100, 4.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (26, 'Alchemy Kit', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 125, 4.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (27, 'Bowyer''s Tools', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 68, 4.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (28, 'Cooking Utensils', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 30, 4.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (29, 'Tailoring Kit', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 50, 2.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (30, 'Tanner''s Tools', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 84, 2.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (31, 'Tinkering Kit', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 145, 5.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (32, 'Scribe''s Supplies', '', '', 'Crafting', 'Craft/repair gear without workstation (+1 difficulty). Breaks after 3 complications.', 60, 2.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (33, 'Bagpipes', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 28, 3.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (34, 'Banjo', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 26, 5.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (35, 'Chácaras', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 3, 0.1);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (36, 'Drum', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 12, 1.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (37, 'Flute', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 6, 0.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (38, 'Hurdy-gurdy', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 50, 3.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (39, 'Lute', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 22, 0.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (40, 'Lyre', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 17, 0.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (41, 'Pan Flute', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 12, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (42, 'Viol', '', '', 'Instrument', 'Used to perform music (soothe, inspire, rally).', 24, 0.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (43, 'Compass', '', '', 'Utility', 'Gives advantage on Navigation/Survival checks.', 25, 0.2);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (44, 'Shovel', '', '', 'Utility', 'Used for digging or burying items; can be an improvised weapon.', 15, 2.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (45, 'Spyglass', '', '', 'Utility', 'Allows spotting at Long range without penalty.', 75, 0.5);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (46, 'Fishing Rod', '', '', 'Utility', 'Lets you attempt fishing tests to gather food.', 20, 1.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (47, 'Chalk', '', '', 'Utility', 'Mark surfaces or leave trails; fades with weather.', 2, 0.1);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (48, 'Pickaxe', '', '', 'Utility', 'Used for mining or breaking hard surfaces.', 28, 3.0);
INSERT OR REPLACE INTO utilities (id, name, short_description, long_description, category, effect_text, cost, weight) VALUES (49, 'Portable Stove', '', '', 'Utility', 'Lets you cook outdoors without a campfire.', 90, 6.0);

COMMIT;
