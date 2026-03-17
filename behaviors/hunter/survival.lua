-- Hunter Survival behavior (MoP 5.4.8).
-- Counter Shot (lv 22), Serpent Sting (lv 3), Multi-Shot (lv 26),
-- Explosive Shot (lv 10, SV signature), Arcane Shot (lv 22).

local options = {
  Name = "Hunter (Survival)",
  Widgets = {},
}

local function SurvivalCombat()
  local target = Combat.BestTarget
  if not target then return end

  if target:IsInterruptible() then
    if Spell.CounterShot:CastEx(target) then return end
  end

  if Combat:GetEnemiesAroundUnit(target, 10) >= 2 then
    if Spell.MultiShot:CastEx(target) then return end
  end

  if not target:HasDebuffByMe("Serpent Sting") then
    if Spell.SerpentSting:CastEx(target) then return end
  end

  if Spell.ExplosiveShot:CastEx(target) then return end
  if Me.Power > 45 then
    if Spell.ArcaneShot:CastEx(target) then return end
  end
end

local behaviors = {
  [BehaviorType.Combat] = SurvivalCombat,
}

return { Options = options, Behaviors = behaviors }
