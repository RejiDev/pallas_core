local options = {
	Name = "Hunter (Survival)", -- shown as collapsing header

	Widgets = {
		{ type = "text", text = "=== General ===" },
	},
}


local function DoCombat()
    if Me:IsCastingOrChanneling() then
        return
    end

    local target = Combat.BestTarget
    if not target then
        return
    end

    if not Me:IsAutoRanging() then
        Me:StartRanging(target)
    end

    if Spell:IsGCDActive() then
        return
    end

    if Spell.ArcaneShot:CastEx(target) then
        return
    end

    if Spell.SteadyShot:CastEx(target) then
        return
    end
end

local behaviors = {
	[BehaviorType.Combat] = DoCombat,
}

return { Options = options, Behaviors = behaviors }
