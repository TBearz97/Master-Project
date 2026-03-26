BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS Action (
    ID                INTEGER PRIMARY KEY AUTOINCREMENT,
    name              TEXT NOT NULL UNIQUE,
    short_description TEXT DEFAULT '',
    long_description  TEXT DEFAULT '',
    expressions       TEXT DEFAULT '[]'
);

DELETE FROM Action
WHERE ID NOT IN (
    SELECT MIN(ID)
    FROM Action
    GROUP BY name
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_action_name
ON Action(name);

INSERT OR IGNORE INTO Action (name, short_description, long_description, expressions) VALUES
    ('Strike', 'A basic attack.',            'A direct, unadorned blow.',                          '["dealDamage(target, source)"]'),
    ('Slash',  'A broad cutting attack.',    'A wide swinging cut aimed at exposed flesh.',        '["dealDamage(target, source)"]'),
    ('Thrust', 'A precise piercing attack.', 'A focused lunge driving the point into the target.', '["dealDamage(target, source)"]'),
    ('Rend',   'A tearing attack.',          'A vicious strike intended to tear and wound.',       '["dealDamage(target, source)"]'),
    ('Smash',  'A crushing blow.',           'A heavy strike that crushes bone and armour.',       '["dealDamage(target, source)"]'),
    ('Sweep',  'A wide sweeping attack.',    'A broad arc that can catch multiple foes.',          '["dealDamage(target, source)"]'),
    ('Cleave', 'A powerful chopping blow.',  'A downward chop with full force behind it.',         '["dealDamage(target, source)"]'),
    ('Bash',   'An impact attack.',          'Driving a shield or blunt weapon into the target.',  '["dealDamage(target, source)"]'),
    ('Crack',  'A whip strike.',             'Snapping the whip at speed to cut or stun.',         '["dealDamage(target, source)"]'),
    ('Fire',   'A ranged attack.',           'Releasing a projectile at the target.',              '["dealDamage(target, source)"]');

UPDATE Weapon SET actions = 'Strike'             WHERE item = 'Unarmed';
UPDATE Weapon SET actions = 'Slash,Rend'         WHERE item = 'Bear Claws';

UPDATE Weapon SET actions = 'Thrust,Slash,Rend'  WHERE item = 'Dagger';
UPDATE Weapon SET actions = 'Thrust,Slash,Rend'  WHERE item = 'Knife';
UPDATE Weapon SET actions = 'Thrust,Rend'        WHERE item = 'Stiletto';

UPDATE Weapon SET actions = 'Slash,Thrust'       WHERE item = 'Short Sword';
UPDATE Weapon SET actions = 'Slash,Thrust,Sweep' WHERE item = 'Broad Sword';
UPDATE Weapon SET actions = 'Slash,Thrust,Sweep' WHERE item = 'Scimitar';
UPDATE Weapon SET actions = 'Thrust,Slash'       WHERE item = 'Rapier';
UPDATE Weapon SET actions = 'Slash,Sweep,Cleave' WHERE item = 'Great Sword';

UPDATE Weapon SET actions = 'Slash,Thrust'       WHERE item = 'Wakizashi';
UPDATE Weapon SET actions = 'Slash,Thrust,Sweep' WHERE item = 'Katana';
UPDATE Weapon SET actions = 'Slash,Sweep,Cleave' WHERE item LIKE '%dachi';

UPDATE Weapon SET actions = 'Slash,Rend'         WHERE item = 'Hand Axe';
UPDATE Weapon SET actions = 'Slash,Rend,Cleave'  WHERE item = 'Battle Axe';
UPDATE Weapon SET actions = 'Slash,Cleave,Sweep' WHERE item = 'Great Axe';

UPDATE Weapon SET actions = 'Smash,Strike'       WHERE item = 'Club';
UPDATE Weapon SET actions = 'Smash,Strike'       WHERE item = 'Hammer';
UPDATE Weapon SET actions = 'Smash,Strike'       WHERE item = 'Warhammer';
UPDATE Weapon SET actions = 'Smash,Rend'         WHERE item = 'Flail';
UPDATE Weapon SET actions = 'Smash,Rend,Strike'  WHERE item = 'Morning Star';

UPDATE Weapon SET actions = 'Smash,Sweep'        WHERE item = 'Maul';
UPDATE Weapon SET actions = 'Smash,Sweep'        WHERE item = 'Great Hammer';

UPDATE Weapon SET actions = 'Strike,Sweep,Smash' WHERE item = 'Staff';
UPDATE Weapon SET actions = 'Slash,Crack'        WHERE item = 'Whip';

UPDATE Weapon SET actions = 'Thrust,Strike'      WHERE item = 'Spear';
UPDATE Weapon SET actions = 'Thrust,Sweep'       WHERE item = 'Pike';
UPDATE Weapon SET actions = 'Thrust,Sweep,Slash' WHERE item = 'Polearm';
UPDATE Weapon SET actions = 'Slash,Thrust,Sweep' WHERE item = 'Halberd';
UPDATE Weapon SET actions = 'Thrust,Strike'      WHERE item = 'Javelin';

UPDATE Weapon SET actions = 'Slash,Sweep,Rend'   WHERE item = 'Reaper';

UPDATE Weapon SET actions = 'Fire' WHERE item = 'Short Bow';
UPDATE Weapon SET actions = 'Fire' WHERE item = 'Hunting Bow';
UPDATE Weapon SET actions = 'Fire' WHERE item = 'War Bow';
UPDATE Weapon SET actions = 'Fire' WHERE item = 'Long Bow';

UPDATE Weapon SET actions = 'Fire' WHERE item = 'Hand Crossbow';
UPDATE Weapon SET actions = 'Fire' WHERE item = 'Crossbow';
UPDATE Weapon SET actions = 'Fire' WHERE item = 'Arbalest';

UPDATE Weapon SET actions = 'Fire' WHERE item = 'Pistol';
UPDATE Weapon SET actions = 'Fire' WHERE item = 'Musket';
UPDATE Weapon SET actions = 'Fire' WHERE item = 'Blunderbuss';

UPDATE Weapon SET actions = 'Bash'        WHERE item = 'Buckler';
UPDATE Weapon SET actions = 'Bash,Strike' WHERE item = 'Shield';
UPDATE Weapon SET actions = 'Bash,Smash'  WHERE item = 'Tower Shield';

UPDATE Weapon SET actions = 'Strike' WHERE item = 'Wand';

COMMIT;
