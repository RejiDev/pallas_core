-- Priest Discipline behavior (MoP 5.4.8).
-- Smite (lv 1), Flash Heal (lv 1), Power Word: Fortitude (lv 1),
-- Power Word: Shield (lv 6), Renew (lv 8), Shadow Word: Pain (lv 10),
-- Penance (lv 10), Inner Fire (lv 12), Heal (lv 16), Holy Fire (lv 20),
-- Prayer of Mending (lv 20).

local options = {
  Name = "Priest (Discipline)",
  Widgets = {},
}

-- ── Heal ────────────────────────────────────────────────────────────

local function DisciplineHeal()
  -- 1. PW:Shield on tank proactively — instant mitigation before damage spikes.
  local tank = Heal.Friends.Tanks and Heal.Friends.Tanks[1]
  if tank and tank.HealthPct < 85 then
    if Spell.PowerWordShield:CastEx(tank) then return end
  end

  local lowest = Heal:GetLowestMember()
  if not lowest then return end

  -- 2. Flash Heal — emergency only, expensive.
  if lowest.HealthPct < 40 then
    if Spell.FlashHeal:CastEx(lowest) then return end
  end

  -- 3. PW:Shield on anyone else in danger.
  if lowest.HealthPct < 60 then
    if Spell.PowerWordShield:CastEx(lowest) then return end
  end

  -- 4. Penance — primary burst heal, prioritised above the slow Heal cast.
  if lowest.HealthPct < 80 then
    if Spell.Penance:CastEx(lowest) then return end
  end

  -- 5. Renew — HoT maintenance; only reapply our own.
  if not lowest:HasBuffByMe("Renew") and lowest.HealthPct < 90 then
    if Spell.Renew:CastEx(lowest) then return end
  end

  -- 6. Prayer of Mending — prefers tank, falls back to lowest.
  local pom_target = (Heal.Friends.Tanks and Heal.Friends.Tanks[1]) or lowest
  if pom_target and pom_target.HealthPct < 85 then
    if Spell.PrayerOfMending:CastEx(pom_target) then return end
  end

  -- 7. Heal — efficient slow filler when nothing urgent is needed.
  if lowest.HealthPct < 85 then
    if Spell.Heal:CastEx(lowest) then return end
  end
end

-- ── Combat ──────────────────────────────────────────────────────────

local function DisciplineCombat()
  -- Hard gate: if anyone needs healing, skip damage entirely.
  local lowest = Heal:GetLowestMember()
  if lowest and lowest.HealthPct < 85 then return end

  local target = Combat.BestTarget
  if not target then return end

  if not target:HasDebuffByMe("Shadow Word: Pain") then
    if Spell.ShadowWordPain:CastEx(target) then return end
  end

  if Spell.HolyFire:CastEx(target) then return end
  if Spell.Smite:CastEx(target) then return end
end

-- ── Extra ────────────────────────────────────────────────────────────

local function DisciplineExtra()
  for _, member in ipairs(Heal.Friends.All or {}) do
    if not member:HasAura("Power Word: Fortitude") then
      if Spell.PowerWordFortitude:CastEx(member) then return end
    end
  end
  if not Me:HasAura("Inner Fire") then
    if Spell.InnerFire:CastEx(Me) then return end
  end
end

-- ── Export ───────────────────────────────────────────────────────────

return {
  Options = options,
  Behaviors = {
    [BehaviorType.Heal]   = DisciplineHeal,
    [BehaviorType.Combat] = DisciplineCombat,
    [BehaviorType.Extra]  = DisciplineExtra,
  },
}
