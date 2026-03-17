-- Warrior Protection behavior (MoP 5.4.8).
-- Level 24: Shield Slam, Revenge, Devastate, Thunder Clap, Shield Block,
--   Shield Wall, Taunt, Heroic Strike, Cleave, Pummel, Defensive Stance.
-- Shockwave is learned at 30 (no-op until then).

local options = {
  Name = "Warrior (Protection)",
  Widgets = {},
}

local function ProtectionTank()
  local target = Tank.BestTarget
  if not target then return end

  if not Me:InMeleeRange(target) then return end
  if not Me:IsAutoAttacking() and Me:StartAttack(target) then return end

  if Me.HealthPct and Me.HealthPct < 40 then
    if Spell.ShieldWall:CastEx(Me) then return end
  end

  local ok, is_tanking = pcall(game.unit_threat, target.obj_ptr)
  if ok and is_tanking ~= true then
    if Spell.Taunt:CastEx(target) then return end
  end

  if Combat:GetEnemiesAroundUnit(target, 8) >= 2 then
    if Spell.ThunderClap:CastEx(target) then return end
  end

  -- Self-cast: Spell wrapper uses target.obj_ptr (Me.obj_ptr) when target is Me.
  if Spell.ShieldBlock:CastEx(Me) then return end

  -- Learned at 30; no-op until then.
  if Combat:GetEnemiesAroundUnit(target, 8) >= 2 then
    if Spell.Shockwave:CastEx(target) then return end
  end

  if Spell.ShieldSlam:CastEx(target) then return end
  if Spell.Revenge:CastEx(target) then return end
  if Spell.Devastate:CastEx(target) then return end
end

local function ProtectionCombat()
  local target = Combat.BestTarget
  if not target then return end

  if not Me:InMeleeRange(target) then return end
  if not Me:IsAutoAttacking() and Me:StartAttack(target) then return end

  if target:IsInterruptible() then
    if Spell.Pummel:CastEx(target) then return end
  end

  if Combat:GetEnemiesAroundUnit(target, 8) >= 2 then
    if Spell.Cleave:CastEx(target) then return end
  end

  if Me.Power and Me.Power > 60 then
    if Spell.HeroicStrike:CastEx(target) then return end
  end
  if Spell.Devastate:CastEx(target) then return end
end

local function ProtectionExtra()
  if not Me:HasAura("Battle Shout") then
    if Spell.BattleShout:CastEx(Me) then return end
  end
end

return {
  Options = options,
  Behaviors = {
    [BehaviorType.Tank] = ProtectionTank,
    [BehaviorType.Combat] = ProtectionCombat,
    [BehaviorType.Extra] = ProtectionExtra,
  },
}
