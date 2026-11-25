-------------------------------------------------------------------------------
--  Hawk Watch: core
--  Hawks are totems. Totem values are secret in combat, so the icons are
--  driven straight from them, and the count is tracked from casts and slot events.
--  Off by default. Hunters without the talent only listen for SPELLS_CHANGED,
--  other classes for nothing.
-------------------------------------------------------------------------------
local ADDON, ns = ...

ns.SLOTS = { 2, 3 }
ns.ICON = 1293241
local RANKS = { 1293527, 1293526, 1293525, 1293241 }
local LIFE, MAX_FLIGHT, EXPIRY_SLACK = 18, 3, 1.5

local IS_RANK = {}
for _, id in ipairs(RANKS) do IS_RANK[id] = true end

local DEFAULTS = {
    enabled = false, layout = "HORIZONTAL", show = "COMBAT",
    size = 36, spacing = 4, fontSize = 14, showSeconds = true, bgAlpha = 0.5,
    bar = true, barHeight = 5, barColor = { r = 0.9, g = 0.7, b = 0.2 },
    hint = false, hintAt = 6, hintColor = { r = 0.2, g = 1, b = 0.4 },
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
--  Hawk state
-------------------------------------------------------------------------------
local hawks = {}                 -- [slot] = expiry time
local castAt                     -- cast whose hawk has not landed yet
local unsureSlot, unsureUntil    -- landing that may really have been an expiry

local function Alive(slot, now) return hawks[slot] and hawks[slot] > now end

function ns.ResetState()
    wipe(hawks)
    castAt, unsureSlot, unsureUntil = nil, nil, nil
end

function ns.OnCast(now) castAt = now end

function ns.OnTotem(slot, now)
    local have, _, start, duration = GetTotemInfo(slot)
    if not Secret(have) then
        hawks[slot] = have and not Secret(start) and (start + duration) or nil
        if have then castAt = nil end
        return
    end
    if castAt and now - castAt < MAX_FLIGHT then
        if hawks[slot] and hawks[slot] - now < EXPIRY_SLACK then
            unsureSlot, unsureUntil = slot, castAt + MAX_FLIGHT
        else
            unsureSlot = nil
        end
        castAt = nil
        hawks[slot] = now + LIFE
    elseif unsureSlot and now < unsureUntil and (slot == unsureSlot or not Alive(slot, now)) then
        hawks[unsureSlot] = nil
        hawks[slot] = now + LIFE
        unsureSlot = nil
    else
        hawks[slot] = nil
    end
end

-- Count, oldest and newest expiry of live hawks.
function ns.Hawks(now)
    local n, oldest, newest = 0, nil, nil
    for _, slot in ipairs(ns.SLOTS) do
        local e = Alive(slot, now) and hawks[slot]
        if e then
            n = n + 1
            if not oldest or e < oldest then oldest = e end
            if not newest or e > newest then newest = e end
        end
    end
    return n, oldest, newest
end

-- A hawk in flight counts as out, replacing the oldest when both are up.
function ns.WantHawk(now)
    local n, oldest, newest = ns.Hawks(now)
    if castAt and now - castAt < MAX_FLIGHT then
        return not newest or newest - now <= ns.db.hintAt
    end
    return n < #ns.SLOTS or oldest - now <= ns.db.hintAt
end

-- Seconds until the count or the hint can change without an event.
function ns.NextChange(now)
    local best
    local function Consider(t)
        if t > now and (not best or t < best) then best = t end
    end
    for _, slot in ipairs(ns.SLOTS) do
        local e = Alive(slot, now) and hawks[slot]
        if e then
            Consider(e)
            Consider(e - ns.db.hintAt)
        end
    end
    if castAt then Consider(castAt + MAX_FLIGHT) end
    return best and best - now
end

-------------------------------------------------------------------------------
--  Lifecycle
-------------------------------------------------------------------------------
local isHunter = select(2, UnitClass("player")) == "HUNTER"

local function FindSpell()
    for _, id in ipairs(RANKS) do
        if C_SpellBook.IsSpellKnown(id) then return id end
    end
end

local timer
local function StopTimer()
    if timer then timer:Cancel(); timer = nil end
end

local function Changed()
    StopTimer()
    local wait = ns.NextChange(GetTime())
    if wait then timer = C_Timer.NewTimer(wait + 0.02, Changed) end
    ns.Tile.UpdateState()
end

local function Resync()
    local now = GetTime()
    for _, slot in ipairs(ns.SLOTS) do
        if not Secret((GetTotemInfo(slot))) then ns.OnTotem(slot, now) end
    end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, arg1, _, spellID)
    if event == "SPELL_UPDATE_COOLDOWN" then
        ns.Tile.UpdateCooldown()
        return
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if Secret(spellID) or not IS_RANK[spellID] then return end
        ns.OnCast(GetTime())
    elseif event == "PLAYER_TOTEM_UPDATE" then
        if Secret(arg1) then return end
        ns.OnTotem(arg1, GetTime())
        ns.Tile.UpdateSlots()
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.inCombat = false
        Resync()
    elseif event == "SPELLS_CHANGED" then
        if FindSpell() ~= ns.spellID then ns.Refresh() end
        return
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns.inCombat = InCombatLockdown()
        ns.ResetState()
        Resync()
        ns.Tile.UpdateSlots()
        ns.Tile.UpdateCooldown()
    end
    Changed()
end)

local function Start()
    ns.running = true
    ns.inCombat = InCombatLockdown()
    ns.ResetState()
    Resync()
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    events:RegisterEvent("PLAYER_TOTEM_UPDATE")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
end

local function Stop()
    ns.running = false
    events:UnregisterAllEvents()
    StopTimer()
    ns.ResetState()
    ns.Tile.UpdateState()
end

-- Settings or known spells changed: start, stop or restyle.
function ns.Refresh()
    if not ns.db then return end
    local watch = ns.db.enabled and isHunter
    ns.spellID = watch and FindSpell() or nil
    if ns.spellID then
        if not ns.running then Start() end
        if ns.db.bar then
            events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        else
            events:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
        end
        ns.Tile.Setup()
        ns.Tile.Restyle()
        Changed()
    else
        Stop()
    end
    if watch then events:RegisterEvent("SPELLS_CHANGED") end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON then return end
    self:UnregisterAllEvents()
    HawkWatchDB = HawkWatchDB or {}
    Fill(HawkWatchDB, DEFAULTS)
    ns.db = HawkWatchDB
    ns.RegisterOptions()
    ns.Refresh()
end)

SLASH_HAWKWATCH1 = "/hawkwatch"
SlashCmdList.HAWKWATCH = function() MalicesTweakSuite.Open("HawkWatch") end
