local options = {
	Name = "Priest (Discipline)", -- shown as collapsing header

	Widgets = {
		{ type = "text", text = "=== General ===" },
		{ type = "checkbox", uid = "DiscAutoDispel", text = "Auto Dispel", default = true },
	},
}

-- Disc priests can dispel Magic (1) and Disease (3)
local DISPEL_TYPES = { 1, 3 }

local dotMode = false
local function DoCombat()
	if imgui.is_key_pressed(551) then
		dotMode = not dotMode
	end

	if Me:IsCastingOrChanneling() then
		return
	end

	if Spell:IsGCDActive() then
		return
	end

	if not Me:HasAura("Power Word: Shield") and not Me:HasAura("Weakened Soul") then
		Spell.PowerWordShield:CastEx(Me)
		return
	end

	if dotMode then
		local nearbyTargets = Me:getUnitsAroundUnit(40)
		for _, target in pairs(nearbyTargets) do
			if not target:HasAura("Shadow Word: Pain") then
				Spell.ShadowWordPain:CastEx(target, false, true)
				return
			end
		end
	end

	local target = Combat.BestTarget
	if not target then
		return
	end

	if Spell.Smite:CastEx(target) then
		return
	end
end

local function DoHeal()
	if Me:IsCastingOrChanneling() then
		return
	end

	if Spell:IsGCDActive() then
		return
	end

	-- Dispel: highest-priority friendly with Magic or Disease debuff
	if PallasSettings.DiscAutoDispel then
		if Spell.Purify:Dispel(DISPEL_TYPES) then
			return
		end
	end

	local lowest = Heal:GetLowestMember()
	if not lowest then
		return
	end

	-- PW:S on lowest if no Weakened Soul
	if lowest.HealthPct < 90
		and not lowest:HasAura("Power Word: Shield")
		and not lowest:HasAura("Weakened Soul") then
		if Spell.PowerWordShield:CastEx(lowest) then
			return
		end
	end

	-- Penance on low health
	if lowest.HealthPct < 60 then
		if Spell.Penance:CastEx(lowest) then
			return
		end
	end

	-- Flash Heal on moderate damage
	if lowest.HealthPct < 75 then
		if Spell.FlashHeal:CastEx(lowest) then
			return
		end
	end

	-- Heal (efficient) for light damage
	if lowest.HealthPct < 90 then
		if Spell.Heal:CastEx(lowest) then
			return
		end
	end
end

local behaviors = {
	[BehaviorType.Combat] = DoCombat,
	[BehaviorType.Heal] = DoHeal,
}

return { Options = options, Behaviors = behaviors }
