-------------------------------------------------------------------------------
--  Field Guide Coats: core
--  Field Guide Forever paints its coat marks on Blizzard's target frame and
--  nameplates, which EllesmereUI hides. This draws them on EUI's frames.
--  Tiers come only from the public FieldGuideForever.API.SpawnTier. Nothing
--  is registered while every feature is off.
-------------------------------------------------------------------------------
local ADDON, ns = ...

ns.ART = "Interface\\AddOns\\FieldGuideForever\\media\\Rarity\\Laurel-"
ns.LAURELS = { silver = ns.ART .. "Silver.tga", gold = ns.ART .. "Gold.tga", shiny = ns.ART .. "Shiny.tga" }
ns.ICONS = {
    silver = "Professions-Icon-Quality-Tier2",
    gold = "Professions-Icon-Quality-Tier3",
    shiny = "Professions-Icon-Quality-Tier4",
}

local DEFAULTS = {
    target = { enabled = false, minTier = "silver", scale = 100, side = "AUTO", x = 0, y = 0,
        hideNative = true, shimmer = true, glowNew = false, dimFound = false, foundAlpha = 50, foundDesat = 60,
        shimmerFound = true },
    plates = { enabled = false, minTier = "silver", size = 17, alpha = 0.72, side = "RIGHT", gap = 2, y = 0,
        glowNew = false, dimFound = false, foundAlpha = 50, foundDesat = 60, hideFGF = true },
    alerts = { enabled = false, minTier = "silver", filter = "ANY", repeatSec = 0, stopOnTarget = true,
        skipTapped = true, message = false, soundSilver = "file:1514328", soundGold = "file:5259954", soundShiny = "file:7467270" },
}

local RANK = { bronze = 0, silver = 1, gold = 2, shiny = 3 }

local function Fill(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            Fill(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local issecret = issecretvalue or function() return false end
ns.issecret = issecret

-- Session only: forces a coat (and found state) on every drawn mark so they can be placed.
ns.preview = nil
ns.previewFound = false

local api
local function ResolveAPI()
    local fg = FieldGuideForever and FieldGuideForever.API
    if fg and fg.version == 3 and type(fg.SpawnTier) == "function" then
        api = fg
    end
end

-- The unit's real coat (preview ignored), or nil when it is below minTier.
function ns.SpawnTier(unit, minTier)
    if not api then return nil end
    local tier = api.SpawnTier(unit)
    local rank = tier and RANK[tier]
    if rank and rank > 0 and rank >= (RANK[minTier] or 1) then return tier end
    return nil
end

-- The coat to draw for a unit, or nil when it is below minTier.
function ns.Tier(unit, minTier)
    if ns.preview then return ns.preview end
    return ns.SpawnTier(unit, minTier)
end

-- speciesId -> Specimen() row, or false when FGF has no row; wiped on any FGF change.
local specimens = {}

-- FGF's species id is the NPC id in the GUID: Creature-0-server-instance-zone-npcID-spawn.
local function SpeciesId(unit)
    local guid = UnitGUID(unit)
    if type(guid) ~= "string" or issecret(guid) then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    return tonumber(id)
end

-- The unit's species row from FGF (preview ignored), or nil when unknown
-- (unreadable GUID, species not in FGF's catalogue).
function ns.Specimen(unit)
    if not api or type(api.Specimen) ~= "function" then return nil end
    local id = SpeciesId(unit)
    if not id then return nil end
    local row = specimens[id]
    if row == nil then
        row = api.Specimen(id) or false
        specimens[id] = row
    end
    return row or nil
end

-- True when this character has found `tier` on the unit's species, false when
-- not yet, nil when unknown.
function ns.Found(unit, tier)
    if ns.preview then return ns.previewFound end
    local row = ns.Specimen(unit)
    if not row then return nil end
    return row[tier] == true
end

local function OnFGFChange()
    wipe(specimens)
    ns.Target.Update()
    ns.Plates.RefreshAll()
    ns.Alerts.Recheck()
end

local unsubscribe
local function WantsFound(db)
    return db.enabled and (db.glowNew or db.dimFound)
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        if ns.db.plates.enabled then ns.Plates.Added(unit) end
        if ns.db.alerts.enabled then ns.Alerts.Added(unit) end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        ns.Plates.Removed(unit)
        ns.Alerts.Removed(unit)
    elseif event == "PLAYER_TARGET_CHANGED" then
        ns.Target.Update()
        ns.Alerts.TargetChanged()
    else
        ns.Target.Update()
    end
end)

-- Registers only what an enabled feature needs. Call after any setting change.
function ns.Arm()
    events:UnregisterAllEvents()
    local db = ns.db
    local alerts = db.alerts
    if db.target.enabled then
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", "target")
    end
    if db.target.enabled or (alerts.enabled and alerts.stopOnTarget) then
        events:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
    if db.plates.enabled or alerts.enabled then
        events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    end
    local want = WantsFound(db.target) or WantsFound(db.plates)
        or (alerts.enabled and alerts.filter ~= "ANY")
    if want and not unsubscribe and api and type(api.Subscribe) == "function" then
        wipe(specimens)
        unsubscribe = api.Subscribe(OnFGFChange)
    elseif not want and unsubscribe then
        unsubscribe()
        unsubscribe = nil
    end
end

function ns.Refresh()
    ns.Arm()
    ns.Target.Update()
    ns.Plates.RefreshAll()
    ns.Alerts.Refresh()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON then return end
    self:UnregisterAllEvents()
    FieldGuideCoatsDB = FieldGuideCoatsDB or {}
    Fill(FieldGuideCoatsDB, DEFAULTS)
    ns.db = FieldGuideCoatsDB
    ResolveAPI()
    ns.RegisterOptions()
    ns.Arm()
end)

SLASH_FIELDGUIDECOATS1 = "/fgcoats"
SlashCmdList.FIELDGUIDECOATS = function() MalicesTweakSuite.Open("FieldGuideCoats") end
