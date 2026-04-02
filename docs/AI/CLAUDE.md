# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.5 project — a software-first tabletop RPG system called "Threads of Fate". The thesis driving it: rules and software are co-designed so the engine executes formalized rules rather than just assisting a manual process. See `docs/AI_CONTEXT.md` for the full architectural and thesis context.

## Running the Project

Open the project in the Godot 4.5 editor and press F5 (or use the Play button). The main scene is `res://Scenes/Main Menu/Main_Menu.tscn`.

There is no CLI build or test runner. All execution happens through the Godot editor.

## Rebuilding Codex Resources from the Database

Game content lives in `.tres` resource files under `res://data/`. The SQLite database at `res://data/Codex.db` is the source-of-truth backup. To regenerate all `.tres` files from SQL, open and run the scene `tools/test.tscn` (which uses `tools/rebuild_codex_from_db.gd`). This wipes existing `.tres` files and recreates them from the database.

**Do not edit `.tres` files in `data/` directly** if the intent is a permanent change — edit the SQL database and re-run the importer.

## Architecture

### Autoloads (global singletons)

| Singleton | File | Purpose |
|---|---|---|
| `CampaignVariables` | `autoload/campaign_variables.gd` | Shared campaign state, active `Codex`, keyword hyperlink rendering |
| `PlayerVariables` | `autoload/player_variables.gd` | Local player character state (`PlayerData`) |
| `RuleEngine` | `autoload/rule_engine.gd` | Dice rolling, expression evaluation via Godot `Expression`, `dealDamage()` |
| `SignalBus` | `autoload/signal_bus.gd` | Global signals |
| `SteamManager` | `autoload/steam_manager.gd` | Steam SDK integration |

### Data Model Hierarchy

```
Resource
└── CreatureData          — universal runtime actor (HP, attributes, conditions, actions, perks, inventory)
    ├── HumanoidData      — adds skills, equipment, race, homeland, background
    │   └── PlayerData    — adds XP, level-up points, gender, age, backstory
    ├── BeastData
    └── UndeadData
```

### Codex (content container)

`Codex` (`content/codex/Codex.gd`) is a `Resource` holding typed dictionaries for every content category: `Races`, `Backgrounds`, `Homelands`, `Attributes`, `Skills`, `Defences`, `Perks`, `Conditions`, `Rules`, `Items`, `NPCs`. It is loaded at startup by `CampaignVariables` from `res://data/baseRules.tres`.

All content entries extend `CodexItem` (has `_name`, `short_description`, `long_description`). Keywords from all dictionaries are merged into `Codex.Keywords` and used to auto-hyperlink descriptions in the UI.

### NPC Content

`NPC` is a `CodexItem` with a `data: CreatureData` field. `Codex.NPCs` is `Dictionary[String, NPC]`. NPC templates in SQL store minimal data (`name`, `short_description`, `long_description`, `creature_type`, `max_hp`, `level`, `attributes` as JSON). Equipment is not stored in SQL — assign at runtime if needed.

### Damage

`DamageProfile` (`content/codex/gameplay/DamageProfile.gd`) carries `base_damage`, `damage_die`, `crit_die`, `origin`, `damage_types`, `ignore_dt`. Every `Weapon` holds a `damage_profile`. `RuleEngine.dealDamage(target, source, damage_profile)` is the single entry point for applying damage — do not add weapon-specific damage logic elsewhere.

### Multiplayer

GM-authoritative P2P. Supports ENet and Steam (`systems/multiplayer/`). Players send action requests; the GM/host resolves them and broadcasts state. The host is always peer ID 1 (`multiplayer.is_server()`).

### Rule Expressions

`RuleEngine.evaluate(command, variable_names, variable_values)` wraps Godot's `Expression` class. Helper functions callable from expressions should be added as methods on `RuleEngine`. Avoid replacing `Expression` with a custom language prematurely.

## Key Conventions

- Content identifiers use `_name` (not `name`) to avoid collision with Godot's built-in `Node.name`.
- Save files: characters at `user://characters/<name>.res`, campaigns at `user://campaign/<name>.res`.
- Prefer small, focused changes. Check existing code before proposing new abstractions.
- Treat SQL as import material and Godot `.tres`/`.res` resources as the working runtime format.
