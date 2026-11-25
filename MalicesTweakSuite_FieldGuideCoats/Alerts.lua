-------------------------------------------------------------------------------
--  Field Guide Coats: sound alert when a coated mob's nameplate comes into range
--  Real tiers only (preview ignored). One alert per spawn per session, plus an
--  optional repeat while a matching spawn stays in range.
-------------------------------------------------------------------------------
local _, ns = ...

local Alerts = {}
ns.Alerts = Alerts

local RANK = { silver = 1, gold = 2, shiny = 3 }
local SOUND_KEY = { silver = "soundSilver", gold = "soundGold", shiny = "soundShiny" }
local LABEL = { silver = "Silver", gold = "Gold", shiny = "Shiny" }
local COLOR = { silver = { 0.82, 0.86, 0.92 }, gold = { 1, 0.82, 0.2 }, shiny = { 0.45, 0.9, 1 } }

-- Game sound files (FileDataIDs) listed after EUI's own sounds.
local GAME_SOUNDS = {
    { file = 1514328, name = "Chime" },
    { file = 5259954, name = "Shimmer" },
    { file = 7467270, name = "Rare Pet Sparkle" },
    { file = 569183, name = "Elemental Rain" },
}

local issecret = ns.issecret
local nearby = {}  -- unit -> guid of a matching spawn in nameplate range
local heard = {}   -- guid -> true once announced this session
local quiet = {}   -- guid -> true once targeted (Stop Once Targeted)
local queued = {}
local flushPending = false
local lastPlay = -math.huge
local timer

local sounds
-- paths, names, order for the sound dropdowns; LibSharedMedia sounds are
-- appended on every call so ones registered after login still show.
function Alerts.Sounds()
    if not sounds then
        local paths, names, order
        if EllesmereUI.BuildAlertSoundTables then
            paths, names, order = EllesmereUI.BuildAlertSoundTables()
        else
            paths, names, order = {}, { none = "None" }, { "none" }
        end
        local files = {}
        order[#order + 1] = "---game"
        for _, s in ipairs(GAME_SOUNDS) do
            local key = "file:" .. s.file
            paths[key] = s.file
            names[key] = s.name
            files[key] = true
            order[#order + 1] = key
        end
        sounds = { paths = paths, names = names, order = order, files = files }
    end
    if EllesmereUI.AppendSharedMediaSounds then
        EllesmereUI.AppendSharedMediaSounds(sounds.paths, sounds.names, sounds.order)
    end
    return sounds.paths, sounds.names, sounds.order
end

-- A numeric path is a FileDataID for our game sounds, a SoundKit id otherwise.
function Alerts.PlayKey(key)
    local path = key and key ~= "none" and Alerts.Sounds()[key]
    if not path then return end
    if type(path) ~= "number" or sounds.files[key] then
        PlaySoundFile(path, "Master")
    elseif path ~= 1 then
        PlaySound(path, "Master")
    end
end
local PlayKey = Alerts.PlayKey

local function Play(tier)
    PlayKey(ns.db.alerts[SOUND_KEY[tier]])
    lastPlay = GetTime()
end

-- True only when the flag is readable and set.
local function Flag(fn, unit)
    if not fn then return false end
    local v = fn(unit)
    return not issecret(v) and v == true
end

local function ReadGUID(unit)
    local guid = UnitGUID(unit)
    if type(guid) ~= "string" or issecret(guid) then return nil end
    return guid
end

-- The unit's coat when it passes every alert filter, else nil.
local function Match(unit)
    local db = ns.db.alerts
    local tier = ns.SpawnTier(unit, db.minTier)
    if not tier then return nil end
    if Flag(UnitIsDead, unit) then return nil end
    if db.skipTapped and Flag(UnitIsTapDenied, unit) then return nil end
    if db.filter ~= "ANY" then
        local row = ns.Specimen(unit)
        if row then
            if db.filter == "NEW_COAT" and row[tier] then return nil end
            if db.filter == "NEW_SPECIES" and (row.bronze or row.silver or row.gold or row.shiny) then return nil end
        end
    end
    return tier
end

local function Best(a, b)
    if not a then return b end
    if b and RANK[b] > RANK[a] then return b end
    return a
end

-- Drops spawns that left, died, got tapped or targeted; returns the best coat left.
local function Prune()
    local best
    for unit, guid in pairs(nearby) do
        local tier = not quiet[guid] and ReadGUID(unit) == guid and Match(unit)
        if tier then
            best = Best(best, tier)
        else
            nearby[unit] = nil
        end
    end
    return best
end

local function Cancel()
    if timer then
        timer:Cancel()
        timer = nil
    end
end

local Tick
local function Schedule()
    local db = ns.db.alerts
    if timer or not db.enabled or db.repeatSec <= 0 or not next(nearby) then return end
    timer = C_Timer.NewTimer(math.max(0.1, lastPlay + db.repeatSec - GetTime()), Tick)
end

function Tick()
    timer = nil
    local db = ns.db.alerts
    if not db.enabled or db.repeatSec <= 0 then return end
    local best = Prune()
    if not best then return end
    if GetTime() - lastPlay >= db.repeatSec - 0.05 then Play(best) end
    Schedule()
end

local function Message(tier, name)
    local frame = UIErrorsFrame
    if not (ns.db.alerts.message and frame) then return end
    local text = LABEL[tier] .. " coat nearby"
    if name then text = text .. ": " .. name end
    local c = COLOR[tier]
    frame:AddMessage(text, c[1], c[2], c[3])
end

local function Announce(unit, tier)
    local name = UnitName(unit)
    Message(tier, type(name) == "string" and not issecret(name) and name or nil)
end

-- Batches one frame of nameplates so a pack coming into view rings once.
local function Flush()
    flushPending = false
    local best
    for unit in pairs(queued) do
        queued[unit] = nil
        local guid = ReadGUID(unit)
        local tier = guid and not quiet[guid] and Match(unit)
        if tier then
            nearby[unit] = guid
            if not heard[guid] then
                heard[guid] = true
                best = Best(best, tier)
                Announce(unit, tier)
            end
        end
    end
    if best then
        Play(best)
        Cancel()
    end
    Schedule()
end

function Alerts.Added(unit)
    queued[unit] = true
    if not flushPending then
        flushPending = true
        C_Timer.After(0, Flush)
    end
end

function Alerts.Removed(unit)
    queued[unit] = nil
    nearby[unit] = nil
    if not next(nearby) then Cancel() end
end

function Alerts.TargetChanged()
    local db = ns.db.alerts
    if not (db.enabled and db.stopOnTarget) then return end
    local guid = ReadGUID("target")
    if not guid then return end
    quiet[guid] = true
    for unit, g in pairs(nearby) do
        if g == guid then nearby[unit] = nil end
    end
    if not next(nearby) then Cancel() end
end

-- FGF data changed (a kill or a find): drop spawns that no longer match.
function Alerts.Recheck()
    if not ns.db.alerts.enabled then return end
    Prune()
    if not next(nearby) then Cancel() end
end

-------------------------------------------------------------------------------
--  Preview: the previewed coat rings as a real spawn would, filters included,
--  with "Preview As" standing in for the species row. Own timer, no lastPlay.
-------------------------------------------------------------------------------
local previewTimer

local function PreviewTier()
    local db = ns.db.alerts
    local tier = ns.preview
    if not (db.enabled and tier and RANK[tier]) then return nil end
    if RANK[tier] < (RANK[db.minTier] or 1) then return nil end
    if db.filter ~= "ANY" and ns.previewFound then return nil end
    return tier
end

local function StopPreview()
    if previewTimer then
        previewTimer:Cancel()
        previewTimer = nil
    end
end

local function PreviewTick()
    previewTimer = nil
    local tier = PreviewTier()
    local db = ns.db.alerts
    if not tier or db.repeatSec <= 0 then return end
    PlayKey(db[SOUND_KEY[tier]])
    previewTimer = C_Timer.NewTimer(db.repeatSec, PreviewTick)
end

-- Call when the previewed coat or its found state changes.
function Alerts.PlayPreview()
    StopPreview()
    local tier = PreviewTier()
    if not tier then return end
    local db = ns.db.alerts
    PlayKey(db[SOUND_KEY[tier]])
    Message(tier, "Preview")
    if db.repeatSec > 0 then previewTimer = C_Timer.NewTimer(db.repeatSec, PreviewTick) end
end

-- Settings changed: rescan plates in range. Spawns already heard stay silent.
function Alerts.Refresh()
    if not PreviewTier() then
        StopPreview()
    elseif not previewTimer and ns.db.alerts.repeatSec > 0 then
        previewTimer = C_Timer.NewTimer(ns.db.alerts.repeatSec, PreviewTick)
    end
    Cancel()
    wipe(nearby)
    if not ns.db.alerts.enabled then
        wipe(queued)
        return
    end
    for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = nameplate.unitToken or nameplate.namePlateUnitToken
            or (nameplate.GetUnit and nameplate:GetUnit())
        if type(unit) == "string" and not issecret(unit) then Alerts.Added(unit) end
    end
end
