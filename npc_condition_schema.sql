INSERT INTO Condition (name, short_description, long_description)
VALUES
    ('Stunned', 'Unable to act effectively.', 'The creature is staggered and struggles to take meaningful action.'),
    ('Poisoned', 'Suffering from a toxic effect.', 'The creature is weakened by poison and may take ongoing harm or penalties.'),
    ('Burning', 'On fire.', 'The creature is engulfed in flames and may take ongoing fire damage until the effect ends.'),
    ('Frozen', 'Slowed by intense cold.', 'The creature is hampered by ice and severe cold, reducing mobility and responsiveness.'),
    ('Grappled', 'Pinned or held in place.', 'The creature is physically restrained and cannot move freely until it escapes.'),
    ('Frightened', 'Shaken by fear.', 'The creature is mentally unsettled and may hesitate or struggle to approach the source of fear.')
ON CONFLICT(name) DO NOTHING;

INSERT OR IGNORE INTO NPC (
    name,
    short_description,
    long_description,
    creature_type,
    max_hp,
    level,
    attributes
)
SELECT
    'Bandit Raider',
    'A desperate highway thief.',
    'A rough criminal who relies on aggression, speed, and opportunistic attacks.',
    'HumanoidData',
    11,
    1,
    json_group_object(name, 1)
FROM Attribute
;

INSERT OR IGNORE INTO NPC (
    name,
    short_description,
    long_description,
    creature_type,
    max_hp,
    level,
    attributes
)
SELECT
    'Wolf',
    'A fast hunting beast.',
    'A lean predator that fights with quick movement, sharp instincts, and relentless bites.',
    'BeastData',
    9,
    1,
    json_group_object(name, 1)
FROM Attribute
;

INSERT OR IGNORE INTO NPC (
    name,
    short_description,
    long_description,
    creature_type,
    max_hp,
    level,
    attributes
)
SELECT
    'Zombie',
    'A shambling corpse driven onward.',
    'A decaying undead creature that endures punishment and closes in through sheer persistence.',
    'UndeadData',
    14,
    1,
    json_group_object(name, 1)
FROM Attribute
;

INSERT OR IGNORE INTO NPC (
    name,
    short_description,
    long_description,
    creature_type,
    max_hp,
    level,
    attributes
)
SELECT
    'Dire Boar',
    'A thick-skinned charging beast.',
    'A vicious boar that relies on momentum, toughness, and savage impact to overwhelm prey.',
    'BeastData',
    16,
    1,
    json_group_object(name, 1)
FROM Attribute
;

INSERT OR IGNORE INTO NPC (
    name,
    short_description,
    long_description,
    creature_type,
    max_hp,
    level,
    attributes
)
SELECT
    'Cult Adept',
    'A dangerous occult practitioner.',
    'A sinister humanoid who combines ritual knowledge, fanatic resolve, and unsettling magical talent.',
    'HumanoidData',
    10,
    1,
    json_group_object(name, 1)
FROM Attribute
;

INSERT OR IGNORE INTO NPC (
    name,
    short_description,
    long_description,
    creature_type,
    max_hp,
    level,
    attributes
)
SELECT
    'Ghoul',
    'A feral flesh-hungry undead.',
    'A swift and ravenous undead horror that attacks in frenzied bursts and drags foes down.',
    'UndeadData',
    12,
    1,
    json_group_object(name, 1)
FROM Attribute
;
