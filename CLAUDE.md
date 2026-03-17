# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pallas Core is a modular PvE combat automation framework for World of Warcraft: Mists of Pandaria (5.4.8), running as a jmrMoP CommunityScript. It automates rotations for DPS, healing, and tanking across all classes/specs.

There are no build, test, or lint systems. Development is done by editing Lua files directly — changes take effect on script reload (END key in-game).

The API surface is documented in `jmrmop.d.ts` (TypeScript type definitions for the C++ game bindings exposed to Lua).

## Architecture

### Execution Flow

`plugin.lua` is the entry point. Every frame:
1. `onTick` runs at 20Hz (50ms throttle) via `os.clock()`
2. Targeting pipelines (`Combat`, `Heal`, `Tank`) call `:Update()` to refresh targets
3. `Behavior:Tick()` dispatches all registered behavior functions in order
4. `onDraw` renders the ImGui menu and ESP overlay

### Module Loading & Globals

Modules are loaded via `Pallas.include(rel_path)` which wraps `loadfile`/`pcall`. All core modules set globals that behavior files use directly (no `require`):

| Global | Source | Purpose |
|--------|--------|---------|
| `Me` | `common/player.lua` | Local player wrapper |
| `Spell` | `common/spell.lua` | Spell cache + casting system |
| `Unit` | `common/unit.lua` | Entity wrapper constructor |
| `Combat` | `system/combat.lua` | Enemy targeting for DPS |
| `Heal` | `system/heal.lua` | Friendly targeting for healers |
| `Tank` | `system/tank.lua` | Threat-aware enemy targeting for tanks |
| `Behavior`, `BehaviorType` | `system/behavior.lua` | Behavior registration/dispatch |
| `Menu` | `common/menu.lua` | ImGui menu system |
| `GroupRole`, `UnitReaction` | `common/group.lua` | Role/faction enums |

### Targeting Pipelines

All three targeting systems (`Combat`, `Heal`, `Tank`) inherit from `common/targeting.lua` via metatable and follow this template method:

```
Reset → WantToRun → CollectTargets → ExclusionFilter → InclusionFilter → WeighFilter
```

After `Update()`:
- `Combat.BestTarget` / `Tank.BestTarget` — best enemy `Unit` to act on
- `Heal.PriorityList` — sorted friendly `Unit` list
- `Heal.Friends.Tanks` / `.Healers` / `.DPS` / `.All` — role-grouped friendlies
- `Combat.Enemies`, `Combat.EnemiesInMeleeRange` — all filtered enemies

### Spell System (`common/spell.lua`)

`Spell` is a table populated from `game.known_spells()` at load time. Keys are camelCase spell names. Each value is a `SpellWrapper` with:

- `Spell.SomeName:CastEx(unit)` — full check cast (cooldown, range, facing, 0.2s throttle, 1s backoff on hard fail). Returns `true` on success.
- `Spell.SomeName:CastAt(unit)` — cast without checks
- `Spell.SomeName:CastAtPos(x, y, z)` — ground-targeted AoE
- `Spell.SomeName.Cooldown` — remaining cooldown in seconds
- `Spell.SomeName.IsKnown` — whether spell is in the cache

### Behavior Registration

Behaviors are Lua files at `behaviors/<classkey>/<spec>.lua`. The file must return a table with:

```lua
return {
  Options = {
    Name = "Class (Spec)",
    Widgets = { ... },   -- menu widgets, each needs a unique `uid`
  },
  Behaviors = {
    { type = BehaviorType.Combat, func = DoCombat },
    { type = BehaviorType.Heal,   func = DoHeal },
    { type = BehaviorType.Extra,  func = DoExtra },
  },
}
```

`BehaviorType` values: `Heal=1`, `Tank=2`, `Combat=3`, `Rest=4`, `Extra=5`

`behavior.lua` loads the file whose path is derived from `data/classes.lua`'s `class_key()` (e.g., "Death Knight" → `"deathknight"`) and the detected spec name lowercased.

## Adding a New Behavior

1. Create `behaviors/<classkey>/<spec>.lua` — see `behaviors/_template.lua`
2. Use `BehaviorType.Tank` + `Tank.BestTarget` for tanks; `BehaviorType.Combat` + `Combat.BestTarget` for DPS; `BehaviorType.Heal` + `Heal.PriorityList` for healers; `BehaviorType.Extra` for buff maintenance
3. Guard every function: `if not target then return end` before acting
4. Use priority casting (early return): `if Spell.X:CastEx(target) then return end`
5. Check auras before applying: `if not target:HasAura("Name") then ... end`
6. Declare menu widgets in `Options.Widgets` with unique `uid` strings; read them via `Menu:GetValue(uid)`

## Key Unit Methods

`Unit` objects (from targeting pipelines or `Unit:New(obj)`) expose:

- `.HealthPct`, `.Health`, `.MaxHealth`, `.Power`, `.MaxPower`
- `.IsDead`, `.IsInCombat`, `.IsCasting`, `.IsMoving`
- `:HasAura(name)`, `:HasAura(name, caster_unit)` — buff/debuff check
- `:InMeleeRange(other)`, `:DistanceTo(other)` — range checks
- `:IsTank()`, `:IsHealer()`, `:IsDPS()` — role detection
- `:HasLOS(other)` — line of sight (terrain + WMO, no model collision)

## Settings

`Menu:GetValue(uid)` reads widget state. Settings auto-persist every ~5 seconds to `settings.dat` via the parent-level `settings.lua` utility. The settings key is `CommunityScripts\pallas_core`.

## Cursor AI Command

`.cursor/commands/newbehavior.md` contains a detailed prompt for scaffolding new behavior files — it validates spell availability by level and enforces BehaviorType separation rules.
