# AI Context

This file is for coding agents working in this repository. It captures the core project intent, architectural direction, and practical constraints that should be remembered across sessions.

## Project Identity

- Project type: software-first tabletop role-playing system built in Godot.
- Thesis title: `Bridging Manual and Software-Executed Rule Systems in Tabletop Role-Playing Games`.
- Main design premise: the rules and the software are co-designed. The software is not just a helper; it is intended to execute formalized rules.

## High-Level Thesis-Driven Direction

These points come directly from the thesis and should guide implementation decisions:

- The system is `software-first`, not a traditional VTT with light automation.
- The GM remains authoritative and must be able to override or correct outcomes.
- Rules should be `data-driven` and editable without changing engine code.
- Rule execution should be `event-driven` where possible.
- The system should support `persistent state`, triggered effects, and mechanically dense interactions that would be painful to run manually.
- Networking should follow a `GM-authoritative P2P model`.
- Players should submit `action requests`; the GM/host validates and resolves them.
- State changes should be applied in a controlled way and then synchronized to clients.

## Practical Architecture Goals

- `CampaignVariables` holds shared campaign state and the active codex.
- `PlayerVariables` holds the local/current player character state.
- `Codex` is the main rules/content container.
- `RuleEngine` evaluates expressions and helper functions.
- Combat/action resolution should move toward: `request -> resolve -> apply effects -> broadcast/update UI`.

## Current Data Model Direction

- `CreatureData` is the universal runtime base for actors that can be targeted or act.
- `HumanoidData` extends `CreatureData` and holds humanoid-only shared gameplay data.
- `PlayerData` extends `HumanoidData` and should only add player-specific state.
- `NPC` is a `CodexItem` with a `data: CreatureData` field.
- `Codex.NPCs` stores `Dictionary[String, NPC]`.

## Rules / Content Philosophy

- Keep using Godot `Expression` for now.
- Prefer adding helper functions in `RuleEngine` over replacing `Expression` with a custom language too early.
- Long-term flexibility matters, but current priority is getting the game playable for testing.
- Avoid overengineering full non-coder tooling too early.

## Damage / Combat Direction

- Damage should not be weapon-specific at the engine boundary.
- `DamageProfile` exists to represent damage definitions that can come from weapons, spells, effects, etc.
- `Weapon` now has a `damage_profile: DamageProfile`.
- `RuleEngine.dealDamage(...)` should operate on a `DamageProfile` rather than hardcoded weapon-only fields.
- Future damage handling should eventually consider DT, origin, effects, perks, and other modifiers.

## SQL Backup Policy

- The SQL database is a `backup/source-of-truth fallback`, not the primary runtime format.
- Runtime/game content is used through Godot `Resource` files (`.tres` / `.res`).
- SQL exists mainly so content can be rebuilt if resource files break.
- When designing SQL schemas, optimize for `simple import into Godot resources`, not perfect relational purity.
- Use simple strings/JSON in SQL where it makes import easier.

## Import / Rebuild Expectations

- `tools/rebuild_codex_from_db.gd` is the rebuild/import script.
- The importer should convert SQL rows into Godot resources.
- Imported data should match the actual Godot resource model, not an abstract database design.
- Keep SQL-backed NPC templates minimal unless more detail is truly needed.
- If a field is easier to randomize or fill in at runtime, keep it out of SQL.

## NPC Template Guidance

Current preferred minimal NPC SQL shape:

- `name`
- `short_description`
- `long_description`
- `creature_type`
- `max_hp`
- `level`
- `attributes`

Notes:

- NPC templates should not start with existing conditions unless explicitly requested.
- NPC attributes should include all game attributes at a minimum value of `1` when generated from SQL templates.
- Equipment can be randomized later in Godot; do not force it into SQL unless necessary.

## Playable-First Goal

Current practical milestone:

- Start a campaign
- Load at least 2 player characters
- Add at least 2 NPCs
- Select source and target
- Use at least 1 action
- Resolve damage/effects
- Update HP/state/log
- Repeat for testing

Recommended first-playable roster:

- Players: `Warrior`, `Rogue`
- NPCs: `Guard` (`HumanoidData`), `Skeleton` (`UndeadData`)

## Important Constraints

- This is still a prototype, not a production platform.
- Do not optimize prematurely for scale, matchmaking, anti-cheat, or AI NPCs.
- Favor correctness, inspectability, and modifiability over polish.
- Preserve GM authority in all major system decisions.

## Agent Guidance

- Prefer small, safe changes over broad refactors.
- Check existing code before proposing new abstractions.
- When in doubt, align implementation with the thesis architecture:
  - data-driven rules
  - event-driven rule execution
  - GM-authoritative synchronization
  - explicit state management
- Treat SQL as backup/import material and Godot resources as the working runtime format.
