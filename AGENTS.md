# AGENTS.md
Guidance for coding agents working in this repository.

## Project Snapshot
- Project type: Godot 4.5 game project.
- Game/thesis identity: `Threads of Fate`, a software-first tabletop RPG system.
- Main scene: `res://Scenes/Main Menu/Main_Menu.tscn`.
- Core architectural stance: data-driven rules, software-executed outcomes, GM-authoritative multiplayer.

## Repository Rules Checked
- Follow `CLAUDE.md`.
- Follow `docs/AI_CONTEXT.md`.
- No `.cursorrules` file was found.
- No files were found under `.cursor/rules/`.
- No `.github/copilot-instructions.md` file was found.

## Workflow Reality
- Most development and verification happens through the Godot editor.
- No lint command is configured in the repo.
- No automated test framework is configured in the repo.
- No true single-test runner exists in the repo.
- When describing commands, prefer editor-first instructions and label CLI invocations as best-effort.

## Build / Run Commands

### Run the game
- Preferred: open the project in Godot 4.5 and press `F5`.
- Main scene path: `res://Scenes/Main Menu/Main_Menu.tscn`.
- If Godot CLI is installed locally, a reasonable equivalent is:

```bash
godot4.5 --path .
```

- On some machines the binary may be `godot` instead of `godot4.5`.

### Run a specific scene
```bash
godot4.5 --path . --scene "res://Scenes/Main Menu/Main_Menu.tscn"
```

### Rebuild codex resources from SQL
- Permanent codex content is backed by `res://data/Codex.db`.
- Importer script: `res://tools/rebuild_codex_from_db.gd`.
- The repository currently includes `res://tools/temp.tscn` wired to that importer.
- Running the importer can wipe and regenerate `.tres` files under `res://data/`.

Editor flow:
- Open `res://tools/temp.tscn`.
- Run the scene.

Best-effort CLI equivalent:

```bash
godot4.5 --path . --headless --scene "res://tools/temp.tscn"
```

## Test / Verification Commands
- There is no `test` command like `pytest`, `npm test`, or `go test`.
- There is no repo-defined lint step.
- Verification is scene-driven and manual.

Practical verification options:
- Run the whole project.
- Run a focused scene related to the changed system.
- Use `res://tools/test.tscn` as the existing action smoke test.

Best-effort CLI smoke test:

```bash
godot4.5 --path . --headless --scene "res://tools/test.tscn"
```

## Running a Single Test
- There is no framework-backed single-test selector.
- In this repo, “single test” usually means “run one small purpose-built scene”.
- Closest current example:
  - `res://tools/test.tscn`
  - `res://tools/action_test.gd`
- Recommended pattern for targeted validation:
  1. Create or reuse a tiny scene under `tools/`.
  2. Attach a focused script that exercises one behavior.
  3. Run only that scene in the editor or with `--scene`.

## Content Source-of-Truth Rules
- Do not treat generated `.tres` files in `res://data/` as the permanent authoring source.
- For permanent codex data changes, update the SQL-backed source and re-import.
- Use runtime resources as the working game format, but treat SQL/import as the durable fallback source.
- Keep SQL/import mappings simple and aligned with the actual Godot resource model.

## Architecture Constraints
- `CampaignVariables` holds shared campaign state and the active `Codex`.
- `PlayerVariables` holds the local/current player character state.
- `RuleEngine` is the execution point for expressions, dice, and damage.
- `SignalBus` coordinates cross-system signaling.
- Multiplayer is GM-authoritative P2P; host/server resolves outcomes.
- `CreatureData` is the universal runtime actor base.
- `PlayerData` extends `HumanoidData`; `NPC` stores a `CreatureData` inside codex content.
- Keep rule execution aligned with: request -> resolve -> apply effects -> broadcast/update UI.

## GDScript Style Guidelines

### File structure
- Typical order is `extends`, then `class_name` if the script is a reusable type.
- Put `@export` properties near the top.
- Put `@onready` node references near the top of node scripts.
- Keep constants near the top with `const NAME := value`.
- Group methods by responsibility and separate groups with blank lines.
- Comments are sparse; add them only when a block is genuinely non-obvious.

### Formatting
- Existing `.gd` files use tabs for indentation.
- Preserve the local formatting of the file you edit instead of normalizing unrelated lines.
- Keep edits compact; there is no repo-enforced max line length.
- Avoid repo-wide formatting churn because no formatter config is present.

### Types
- The codebase uses typed GDScript heavily; preserve and extend that habit.
- Prefer typed exports like `@export var speed: int`.
- Use typed arrays/dictionaries such as `Array[String]` and `Dictionary[String, Race]`.
- Use explicit casts on loaded resources when helpful, e.g. `as Codex`.
- Use `:=` when the inferred type is obvious and stable.
- Use explicit `: Type` when it improves clarity or catches mistakes.
- Avoid `:=` when values come from dictionary lookups, array iteration, or vector math like `cell + offset`; prefer explicit local types in those cases.
- In `Node` and `Control` scripts, avoid local variable names that shadow engine properties like `position`, `size`, `scale`, `rotation`, `visible`, or `name`.
- Prefer domain-specific locals such as `grid_position`, `cell_position`, `panel_size`, or `token_name`.

### Naming
- `class_name` types use PascalCase.
- Local variables usually use snake_case.
- The repo mixes snake_case and legacy camelCase methods.
- Examples of existing camelCase APIs: `dealDamage`, `replaceText`, `setCampaignName`.
- Do not rename existing public or widely used APIs just for style consistency.
- For new code, match the naming convention already used in the file you are touching.
- Content/resource identifiers use `_name`, not `name`, to avoid collisions with Godot node naming.

### Imports and dependencies
- GDScript here does not use Python-style imports.
- Reusable script types are usually accessed through `class_name`.
- Use `preload()` for explicit script/resource constants when file-scope loading is useful.
- Use `ResourceLoader.load()` for runtime loading of `.tres`/`.res` assets.
- Prefer existing autoload singletons over introducing duplicate service entry points.

### Resources and data modeling
- Gameplay/content containers are usually `Resource` subclasses with exported fields.
- Constructors commonly initialize every field in `_init()`.
- Collections are often stored in typed dictionaries keyed by string names.
- Duplicate template resources before mutating runtime-specific copies when needed.
- `Codex.createKeywords()` merges typed content dictionaries into a keyword lookup map.

### Error handling
- Follow the repo pattern of guard clauses and early returns.
- Use `push_error(...)` for failures that should be visible in Godot output.
- Return `null`, `false`, or a small result dictionary when that matches the surrounding code.
- Check `OK` return codes from saving, networking setup, and SQLite queries.
- Check file existence before loading user save resources.
- In multiplayer RPC handlers, guard authority explicitly, e.g. `if not multiplayer.is_server(): return`.

### Gameplay logic
- Keep rule execution centralized in `RuleEngine`.
- Add expression helper functions to `RuleEngine` instead of inventing a second rule language.
- `RuleEngine.dealDamage(...)` is the engine boundary for damage application.
- Do not move damage resolution into weapon-specific branches unless the task explicitly requires it.
- Prefer data-driven codex/resource definitions over hardcoded branching where practical.

### UI and scene scripts
- Scene scripts usually connect signals in `_ready()`.
- UI node access often uses typed `%NodeName` or `$NodeName` references.
- Some legacy code uses direct scene-tree lookups; preserve local style unless already refactoring that area.
- Keep UI scripts focused on orchestration and presentation rather than deep gameplay state rules.

## Scope and Safety
- Prefer small, focused edits over broad refactors.
- Preserve GM authority in networking and state synchronization.
- Favor correctness, inspectability, and modifiability over speculative abstractions.
- Because the repo mixes older and newer styles, local consistency matters more than global purity.
- Never claim a lint/test pipeline exists when it does not.

## Finish Checklist
- Avoided permanent edits to generated codex `.tres` files?
- Matched the local style/naming of touched files?
- Kept changes aligned with `RuleEngine`, `Codex`, and autoload responsibilities?
- Described verification in terms of Godot scenes when necessary?
