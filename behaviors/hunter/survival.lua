local function SurvivalCombat()
  local target = Combat.BestTarget
  if not target then return end

  if not target:HasAura("Serpent Sting") then
    if Spell.SerpentSting:CastEx(target) then return end
  end

  if Spell.ExplosiveShot:CastEx(target) then return end
  if Spell.ArcaneShot:CastEx(target) then return end
  Spell.SteadyShot:CastEx(target)
end

return {
  Options = { Name = "Hunter (Survival)", Widgets = {} },
  Behaviors = { [BehaviorType.Combat] = SurvivalCombat },
}
