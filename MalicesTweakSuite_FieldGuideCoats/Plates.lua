-------------------------------------------------------------------------------
--  Field Guide Coats: quality mark beside the EUI nameplate health bar
--  The mark is our own frame, parented to Blizzard's nameplate base (which
--  EUI's plate also sits on) and anchored to EUI's health bar.
-------------------------------------------------------------------------------
local _, ns = ...

local Plates = {}
ns.Plates = Plates

local marks = setmetatable({}, { __mode = "k" }) -- Blizzard nameplate -> our mark
local shown = {}                                   -- unit -> mark
local queued = {}
local flushPending = false

-- Prefers the public getter (EUI with GetNameplateForUnit); stock EUI only
-- exposes its plate table, so fall back to it and fail quietly if it moves.
local function FindBar(unit)
    if EllesmereUI.GetNameplateForUnit then
        local plate, bar = EllesmereUI.GetNameplateForUnit(unit)
        return plate, bar
    end
    local npns = _G.EllesmereNameplates_NS
    local plates = type(npns) == "table" and npns.plates
    local plate = type(plates) == "table" and plates[unit]
    local bar = type(plate) == "table" and plate.health
    if type(bar) == "table" and bar.GetObjectType then return plate, bar end
    return nil
end

local function GetMark(nameplate)
    local mark = marks[nameplate]
    if not mark then
        mark = CreateFrame("Frame", nil, nameplate)
        mark.tex = mark:CreateTexture(nil, "OVERLAY")
        mark.tex:SetAllPoints(mark)
        -- New-coat ping: a bright copy that swells and fades.
        local glow = mark:CreateTexture(nil, "OVERLAY", nil, 1)
        glow:SetAllPoints(mark)
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0)
        mark.glow = glow
        local anim = mark:CreateAnimationGroup()
        anim:SetLooping("REPEAT")
        local grow = anim:CreateAnimation("Scale")
        grow:SetTarget(glow)
        grow:SetScaleFrom(1, 1)
        grow:SetScaleTo(1.9, 1.9)
        grow:SetOrigin("CENTER", 0, 0)
        grow:SetStartDelay(0.8)
        grow:SetDuration(0.9)
        grow:SetSmoothing("OUT")
        local fade = anim:CreateAnimation("Alpha")
        fade:SetTarget(glow)
        fade:SetFromAlpha(0.9)
        fade:SetToAlpha(0)
        fade:SetStartDelay(0.8)
        fade:SetDuration(0.9)
        mark.ping = anim
        marks[nameplate] = mark
    end
    return mark
end

local function HideMark(mark)
    mark.ping:Stop()
    mark:Hide()
end

local function Paint(unit)
    local old = shown[unit]
    shown[unit] = nil
    local db = ns.db.plates
    local tier = db.enabled and ns.Tier(unit, db.minTier)
    local nameplate = tier and C_NamePlate.GetNamePlateForUnit(unit)
    local plate, bar
    if nameplate then plate, bar = FindBar(unit) end
    if not (bar and plate:IsShown()) then
        if old then HideMark(old) end
        return
    end
    local mark = GetMark(nameplate)
    if old and old ~= mark then HideMark(old) end
    mark:SetFrameStrata(bar:GetFrameStrata())
    mark:SetFrameLevel(bar:GetFrameLevel() + 5)
    mark:SetSize(db.size, db.size)
    mark:ClearAllPoints()
    if db.side == "LEFT" then
        mark:SetPoint("RIGHT", bar, "LEFT", -db.gap, db.y)
    else
        mark:SetPoint("LEFT", bar, "RIGHT", db.gap, db.y)
    end
    local found = ns.Found(unit, tier)
    local dim = db.dimFound and found == true
    mark.tex:SetAtlas(ns.ICONS[tier])
    mark.tex:SetDesaturation(dim and db.foundDesat / 100 or 0)
    mark.glow:SetAtlas(ns.ICONS[tier])
    mark:SetAlpha(dim and db.alpha * db.foundAlpha / 100 or db.alpha)
    mark:Show()
    if db.glowNew and found == false then
        if not mark.ping:IsPlaying() then mark.ping:Play() end
    else
        mark.ping:Stop()
        mark.glow:SetAlpha(0)
    end
    shown[unit] = mark
end

-- EUI builds its plate in the same event; read it on the next frame.
local function Flush()
    flushPending = false
    for unit in pairs(queued) do
        queued[unit] = nil
        Paint(unit)
    end
end

function Plates.Added(unit)
    queued[unit] = true
    if not flushPending then
        flushPending = true
        C_Timer.After(0, Flush)
    end
end

function Plates.Removed(unit)
    queued[unit] = nil
    local mark = shown[unit]
    if mark then HideMark(mark) end
    shown[unit] = nil
end

function Plates.RefreshAll()
    for unit, mark in pairs(shown) do
        HideMark(mark)
        shown[unit] = nil
    end
    if not ns.db.plates.enabled then return end
    for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = nameplate.unitToken or nameplate.namePlateUnitToken
            or (nameplate.GetUnit and nameplate:GetUnit())
        if type(unit) == "string" and not ns.issecret(unit) then Paint(unit) end
    end
end
