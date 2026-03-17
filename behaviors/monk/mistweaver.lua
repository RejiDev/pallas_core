-- Monk Mistweaver behavior (MoP 5.4.8).
-- Jab (lv 1), Tiger Palm (lv 1), Blackout Kick (lv 3),
-- Soothing Mist (lv 10 — channeled; instant-cancelled after first tick for throughput).

local options = {
  Name = "Monk (Mistweaver)",
  Widgets = {
    { type = "text", text = "=== General ===" },
    { type = "checkbox", uid = "MistweaverDoDamage", text = "Do Damage", default = true },
  },
}

local auras = { tiger_palm = 125359 }

local function DoCombat()
  local target = Combat.BestTarget
  if not target then return end
  if not Me:InMeleeRange(target) then return end
  if not Me:IsAutoAttacking() and Me:StartAttack(target) then return end
  if not PallasSettings.MistweaverDoDamage then return end
  if Spell:IsGCDActive() then return end

  if not Me:HasAura(auras.tiger_palm) and Spell.TigerPalm:CastEx(target) then return end
  if Spell.BlackoutKick:CastEx(target) then return end
  if Spell.Jab:CastEx(target) then return end
  if Spell.TigerPalm:CastEx(target) then return end
end

local function DoHeal()
  -- Soothing Mist channels indefinitely; cancel after the first instant tick
  -- so the next heal cycle can start immediately rather than waiting for the full channel.
  if Me.ChannelingSpellId == 115175 then Me:StopCasting() end  -- Soothing Mist

  if Spell:IsGCDActive() then return end

  local lowest = Heal:GetLowestMember()
  if not lowest then return end

  if lowest.HealthPct < 90 and Spell.SoothingMist:CastEx(lowest, false, true) then return end
end

local behaviors = {
  [BehaviorType.Heal]   = DoHeal,
  [BehaviorType.Combat] = DoCombat,
}

return { Options = options, Behaviors = behaviors }
