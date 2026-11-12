-------------------------------------------------------------------------------
--  Party Compass: core
--  Settings, party-member positioning math, and the single shared ticker.
--  Everything is off by default. With no feature enabled nothing is
--  registered and nothing ticks. The ticker is a looping Animation (no
--  per-frame Lua) that only plays while a feature is on, you are in a group
--  and you are outside an instance (positions are unavailable inside one).
--  Arrow texture: Media\Arrow.tga, from MagicQuestTracker (GPL v3).
-------------------------------------------------------------------------------
local ADDON, ns = ...

local atan2, sqrt = math.atan2, math.sqrt

ns.ARROW = "Interface\\AddOns\\MalicesTweakSuite_PartyCompass\\Media\\Arrow"

local DEFAULTS = {
    general = { units = "YARDS", interval = 0.05 },
    tile = {
        enabled = false, layout = "HORIZONTAL", max = 5, arrowSize = 28, fontSize = 12,
        spacing = 8, showName = true, showDistance = true, nameClassColor = true, nameFormat = "FULL",
        arrowColor = "CLASS", customColor = { r = 1, g = 1, b = 1 },
        bgAlpha = 0.5, hideSolo = true, showOtherZone = true, showStatus = true,
    },
    frames = {
        enabled = false, size = 14, point = "RIGHT", x = -2, y = 0,
        arrowColor = "CLASS", customColor = { r = 1, g = 1, b = 1 },
        showDistance = false, fontSize = 9, hideWithin = 0,
    },
}

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

local function Secret(v) return issecretvalue and issecretvalue(v) end
ns.Secret = Secret

-------------------------------------------------------------------------------
--  Units
-------------------------------------------------------------------------------
local units = {}
function ns.GetUnits()
    wipe(units)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local u = "raid" .. i
            local same = UnitIsUnit(u, "player")
            if Secret(same) or not same then units[#units + 1] = u end
        end
    else
        for i = 1, GetNumSubgroupMembers() do units[#units + 1] = "party" .. i end
    end
    return units
end

function ns.ClassColor(unit)
    local _, class = UnitClass(unit)
    if class and not Secret(class) then
        local c = RAID_CLASS_COLORS[class]
        if c then return c.r, c.g, c.b end
    end
    return 1, 1, 1
end

function ns.FormatDistance(yards)
    if ns.db.general.units == "METERS" then
        local m = yards * 0.9144
        if m >= 1000 then return string.format("%.1fkm", m / 1000) end
        return string.format("%dm", m)
    end
    return string.format("%dyd", yards)
end

function ns.FontPath()
    return (EllesmereUI.GetFontPath and EllesmereUI.GetFontPath()) or "Fonts\\FRIZQT__.TTF"
end
function ns.FontFlags()
    return (EllesmereUI.GetFontOutlineFlag and EllesmereUI.GetFontOutlineFlag()) or "OUTLINE"
end

-------------------------------------------------------------------------------
--  Positioning
--  Map offsets are scaled to yards using the map's real world size so
--  non-square maps don't skew direction or distance. Rotation follows the
--  same convention as SetRotation (radians counter-clockwise, 0 = up).
-------------------------------------------------------------------------------
local mapSizes = {}
local function WorldDist(a, b)
    local dx, dy = b.x - a.x, b.y - a.y
    return sqrt(dx * dx + dy * dy)
end

local function GetMapSize(mapID)
    local size = mapSizes[mapID]
    if size == nil then
        local _, o = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
        local _, r = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 0))
        local _, d = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 1))
        if o and r and d then
            size = { WorldDist(o, r), WorldDist(o, d) }
        else
            size = false
        end
        mapSizes[mapID] = size
    end
    return size
end

local ctx = { ok = false }
ns.ctx = ctx

-- Reads the player's own position once per tick. False when unavailable.
local function BeginPass()
    ctx.ok = false
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return false end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    local size = GetMapSize(mapID)
    if not (pos and size) then return false end
    local x, y = pos:GetXY()
    if Secret(x) or Secret(y) then return false end
    ctx.mapID, ctx.x, ctx.y = mapID, x, y
    ctx.w, ctx.h = size[1], size[2]
    ctx.facing = GetPlayerFacing()
    ctx.ok = true
    return true
end

-- status: "ok" | "offline" | "dead" | "zone" (no position) | "none" (not in group / no data yet)
-- ok: rotation (nil when facing is unavailable), yards.  zone: mapID.
function ns.Locate(unit)
    if not UnitExists(unit) then return "none" end
    local conn = UnitIsConnected(unit)
    if not Secret(conn) and not conn then return "offline" end
    local dead = UnitIsDeadOrGhost(unit)
    if not Secret(dead) and dead then return "dead" end
    if not ctx.ok then return "none" end
    local pos = C_Map.GetPlayerMapPosition(ctx.mapID, unit)
    if not pos then
        -- No position (other zone, instance, phase, ...): keep the member listed.
        return "zone", nil, nil, C_Map.GetBestMapForUnit(unit)
    end
    local x, y = pos:GetXY()
    if Secret(x) or Secret(y) then return "none" end
    local east, south = (x - ctx.x) * ctx.w, (y - ctx.y) * ctx.h
    local rot = ctx.facing and (atan2(-east, -south) - ctx.facing) or nil
    return "ok", rot, sqrt(east * east + south * south)
end

-------------------------------------------------------------------------------
--  Ticker and lifecycle
-------------------------------------------------------------------------------
local function Active()
    local db = ns.db
    return db and (db.tile.enabled or db.frames.enabled)
end

local function OnTick()
    if not (Active() and ns.wantTick()) then
        ns.Tile.Update()
        ns.FrameArrows.Hide()
        return false
    end
    BeginPass()
    ns.Tile.Update()
    ns.FrameArrows.Update()
    return true
end

local ticker = EllesmereUI.Tick.NewAnimTicker(CreateFrame("Frame"), OnTick, 0.05)

function ns.wantTick()
    if ns.testMode or ns.unlockActive then return true end
    if not IsInGroup() then return false end
    local inInstance = IsInInstance()
    return not inInstance
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event)
    if event == "GROUP_ROSTER_UPDATE" then ns.FrameArrows.Invalidate() end
    ns.Arm()
end)

-- Re-evaluates whether anything needs to run. Call after any setting or
-- roster/zone change.
function ns.Arm()
    if not ns.db then return end
    if Active() then
        events:RegisterEvent("GROUP_ROSTER_UPDATE")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        if ns.wantTick() then
            ticker.Start(ns.db.general.interval)
            return
        end
    else
        events:UnregisterAllEvents()
    end
    ticker.Stop()
    ns.Tile.Update()
    ns.FrameArrows.Hide()
end

-- Settings changed: restyle and re-evaluate.
function ns.Refresh()
    ns.Tile.Restyle()
    ns.FrameArrows.Restyle()
    ns.Arm()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON then return end
    self:UnregisterAllEvents()
    PartyCompassDB = PartyCompassDB or {}
    Fill(PartyCompassDB, DEFAULTS)
    ns.db = PartyCompassDB
    ns.Tile.Setup()
    ns.RegisterOptions()
    ns.Arm()
end)

SLASH_PARTYCOMPASS1 = "/pcompass"
SlashCmdList.PARTYCOMPASS = function() MalicesTweakSuite.Open("Arrows") end
