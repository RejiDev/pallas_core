-- Threat assessment — scans all hostile mobs, reads each mob's threat table,
-- cross-references against the current group roster, and classifies each
-- mob into a threat level based on who currently holds aggro.
--
-- Threat Levels (ascending severity):
--   ThreatLevel.None        (0) — no group member appears in the threat table
--   ThreatLevel.Controlled  (1) — a TANK has aggro (expected, no action needed)
--   ThreatLevel.Loose       (2) — a DPS/DAMAGER has aggro (should be corrected)
--   ThreatLevel.Critical    (3) — a HEALER has aggro (urgent)
--
-- Usage:
--   Threat.Update()
--   for _, entry in ipairs(Threat.Entries) do
--     -- entry.Mob        : Unit  — the hostile mob
--     -- entry.Holder     : GroupMember | nil
--     -- entry.HolderName : string
--     -- entry.Level      : ThreatLevel
--   end
--
--   local loose = Threat.GetByLevel(ThreatLevel.Loose)
--   local crit  = Threat.GetByLevel(ThreatLevel.Critical)
-- ─────────────────────────────────────────────────────────────────────────────

ThreatLevel = {
  None       = 0,
  Controlled = 1,
  Loose      = 2,
  Critical   = 3,
}

local Threat = {}
Threat.Entries = {}

-- ── Internal: build a guid_lo → GroupMember lookup from the roster ──────────

local function BuildGroupIndex()
  local index = {}
  local ok, members = pcall(game.group_members)
  if not ok or not members then return index end
  for _, m in ipairs(members) do
    if m.guid_lo and m.guid_lo ~= 0 then
      index[m.guid_lo] = m
    end
  end
  -- Also index the local player so solo play still works
  if Me and Me.guid_lo and Me.guid_lo ~= 0 then
    if not index[Me.guid_lo] then
      index[Me.guid_lo] = {
        guid_lo    = Me.guid_lo,
        guid_hi    = Me.guid_hi,
        name       = Me.Name,
        combatRole = Me:IsTank() and "TANK" or Me:IsHealer() and "HEALER" or "DAMAGER",
        obj_ptr    = Me.obj_ptr,
        online     = true,
      }
    end
  end
  return index
end

-- ── Internal: classify a threat entry against the group index ───────────────

local function ClassifyHolder(tanking_guid_lo, group_index)
  if not tanking_guid_lo or tanking_guid_lo == 0 then
    return ThreatLevel.None, nil
  end
  local member = group_index[tanking_guid_lo]
  if not member then
    return ThreatLevel.None, nil
  end
  local role = member.combatRole or "NONE"
  if role == "TANK" then
    return ThreatLevel.Controlled, member
  elseif role == "HEALER" then
    return ThreatLevel.Critical, member
  else
    -- DAMAGER or NONE
    return ThreatLevel.Loose, member
  end
end

-- ── Internal: find the current aggro holder from a raw threat list ──────────
-- Prefer the entry with is_tanking = true; fall back to highest threat_val.

local function FindAggroHolder(threat_list)
  local best = nil
  for _, entry in ipairs(threat_list) do
    if entry.is_tanking then
      return entry
    end
    if not best or entry.threat_val > best.threat_val then
      best = entry
    end
  end
  return best
end

-- ── Public: scan all hostile mobs and populate Threat.Entries ───────────────

function Threat.Update()
  Threat.Entries = {}

  if not Me then return end

  local group_index = BuildGroupIndex()

  local ok, units = pcall(game.objects, "Unit")
  if not ok or not units then return end

  for _, entity in ipairs(units) do
    -- Skip non-attackable, dead, or friendly units
    if entity.obj_ptr and not (entity.unit and entity.unit.is_dead) then
      local attackable_ok, attackable = pcall(game.unit_is_attackable, entity.obj_ptr)
      if attackable_ok and attackable then
        local tl_ok, threat_list = pcall(game.unit_threat_list, entity.obj_ptr)
        if tl_ok and threat_list and #threat_list > 0 then
          local holder_entry = FindAggroHolder(threat_list)
          local holder_guid  = holder_entry and holder_entry.guid_lo or nil
          local level, member = ClassifyHolder(holder_guid, group_index)

          local holder_name = "unknown"
          if member then
            holder_name = member.name or holder_name
          end

          Threat.Entries[#Threat.Entries + 1] = {
            Mob        = Unit:New(entity),
            Holder     = member,
            HolderName = holder_name,
            Level      = level,
          }
        end
      end
    end
  end

  -- Sort: highest threat level first (Critical before Loose before Controlled)
  table.sort(Threat.Entries, function(a, b)
    return a.Level > b.Level
  end)
end

-- ── Public helpers ───────────────────────────────────────────────────────────

--- Return all entries at or above the given threat level.
--- e.g. Threat.GetByLevel(ThreatLevel.Loose) → loose + critical mobs
function Threat.GetByLevel(min_level)
  local out = {}
  for _, e in ipairs(Threat.Entries) do
    if e.Level >= min_level then
      out[#out + 1] = e
    end
  end
  return out
end

--- Return the single most dangerous entry, or nil if Entries is empty.
function Threat.GetMostDangerous()
  return Threat.Entries[1]
end

--- Return all mobs with no group member in their threat table.
function Threat.GetUncontrolled()
  return Threat.GetByLevel(ThreatLevel.None)
end

return Threat
