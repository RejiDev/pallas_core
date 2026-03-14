local options = {
  Name = "Monk (Mistweaver)", -- shown as collapsing header

  Widgets = { { type = "text", text = "=== General ===" } },
}

local auras = { tiger_palm = 125359 }

local function DoCombat()
  local target = Combat.BestTarget
  if not target then
    return
  end

  if not Me:InMeleeRange(target) then
    return
  end

  if not Me:IsAutoAttacking() and Spell.AutoAttack:CastEx(target) then
    return
  end

  if Spell:IsGCDActive() then
    return
  end
  if not Me:HasAura(auras.tiger_palm) and Spell.TigerPalm:CastEx(target) then
    return
  end

  if Spell.BlackoutKick:CastEx(target) then
    return
  end
  if Spell.Jab:CastEx(target) then
    return
  end
  if Spell.TigerPalm:CastEx(target) then
    return
  end
end

local function DoHeal()
  local lowest = Heal:GetLowestMember()
  if not lowest then
    return
  end

  if lowest.HealthPct < 90 and Spell.SoothingMist:CastEx(lowest) then
    return
  end

  if not lowest or lowest.HealthPct > 98 and Me:IsCastingOrChanneling() then
    Me:StopCasting()
  end
end

local behaviors = {
  [BehaviorType.Heal] = DoHeal,
  [BehaviorType.Combat] = DoCombat,
  -- [BehaviorType.Tank] = DoTank,
}

return { Options = options, Behaviors = behaviors }
