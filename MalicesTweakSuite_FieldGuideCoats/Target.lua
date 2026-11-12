-------------------------------------------------------------------------------
--  Field Guide Coats: laurel around the EUI target portrait
--  Own frame, parented to the EUI target frame (so it shows and hides with
--  it) and anchored to the portrait backdrop. Nothing is written onto EUI.
-------------------------------------------------------------------------------
local _, ns = ...

local Target = {}
ns.Target = Target

-- FGF's laurel art: 256 px square, portrait hole centred at (96, 160) px with
-- a clear radius of about 51 px. So the texture is 256/102 hole diameters
-- wide and its centre sits 1/8 of its size right of and above the hole.
local SIZE_PER_HOLE = 256 / 102
local CENTER_SHIFT = 0.125

-- Classifications EUI's portrait dragon already marks.
local NATIVE = { rare = true, rareelite = true, elite = true, worldboss = true }

-- FGF's shiny sheen: the loot toast sweep, on FGF's timing, masked to the laurel.
-- Masks do not reliably mirror, so a mirrored laurel uses a pre-mirrored mask.
local SHEEN_ATLAS = "loottoast-sheen"
local MIRRORED_MASK = "Interface\\AddOns\\MalicesTweakSuite_FieldGuideCoats\\Media\\LaurelMask-Shiny-Mirrored.tga"

local holder, laurel, glow, pulse
local sheen, sheenMask, sheenAnim, sheenTravel, sheenAspect, sheenSize

local function Alpha(group, target, from, to, delay, duration, endDelay, order, smoothing)
    local a = group:CreateAnimation("Alpha")
    a:SetTarget(target)
    a:SetFromAlpha(from)
    a:SetToAlpha(to)
    a:SetStartDelay(delay)
    a:SetDuration(duration)
    if endDelay then a:SetEndDelay(endDelay) end
    if smoothing then a:SetSmoothing(smoothing) end
    a:SetOrder(order)
    return a
end

local function Build()
    holder = CreateFrame("Frame", nil, UIParent)
    holder:Hide()
    laurel = holder:CreateTexture(nil, "ARTWORK")
    laurel:SetAllPoints(holder)
    glow = holder:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(holder)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0)

    pulse = holder:CreateAnimationGroup()
    pulse:SetLooping("REPEAT")
    Alpha(pulse, glow, 0, 0.8, 1.6, 0.45, nil, 1, "OUT")
    Alpha(pulse, glow, 0.8, 0, 0, 0.9, nil, 2, "IN")

    sheen = holder:CreateTexture(nil, "OVERLAY", nil, 2)
    sheen:SetBlendMode("ADD")
    sheen:SetAlpha(0)
    sheenMask = holder:CreateMaskTexture(nil, "OVERLAY", nil, 2)
    sheenMask:SetAllPoints(holder)
    sheen:AddMaskTexture(sheenMask)

    sheenAnim = holder:CreateAnimationGroup()
    sheenAnim:SetLooping("REPEAT")
    Alpha(sheenAnim, sheen, 0, 1, 1.1, 0.18, nil, 1)
    Alpha(sheenAnim, sheen, 1, 0, 1.575, 0.25, 2.4, 1)
    sheenTravel = sheenAnim:CreateAnimation("Translation")
    sheenTravel:SetTarget(sheen)
    sheenTravel:SetStartDelay(1.1)
    sheenTravel:SetDuration(0.725)
    sheenTravel:SetOrder(1)
end

local function Native(unit)
    local boss = UnitIsBossMob and UnitIsBossMob(unit)
    if boss and not ns.issecret(boss) then return true end
    local c = UnitClassification(unit)
    return c ~= nil and not ns.issecret(c) and NATIVE[c] == true
end

local function StopPulse()
    pulse:Stop()
    glow:SetAlpha(0)
end

local function StopSheen()
    sheenAnim:Stop()
    sheen:SetAlpha(0)
end

local function HideArt()
    if not holder then return end
    StopPulse()
    StopSheen()
    holder:Hide()
end

-- Leaves point away from the frame: the art's leaves sit on its right, so a
-- portrait left of the frame's centre flips it.
local function Mirrored(side, frame, backdrop)
    if side == "LEFT" then return true end
    if side == "RIGHT" then return false end
    local px = backdrop:GetCenter()
    local fx = frame:GetCenter()
    return px ~= nil and fx ~= nil and px < fx
end

local function PlaySheen(tier, size, flip)
    if not sheenAspect then
        sheen:SetAtlas(SHEEN_ATLAS, true)
        local w, h = sheen:GetSize()
        sheenAspect = (w and h and w > 0 and h > 0) and w / h or 0.5
    end
    sheenMask:SetTexture(flip and MIRRORED_MASK or ns.LAURELS[tier], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    local h = size * 1.1
    sheen:SetSize(h * sheenAspect, h)
    sheen:ClearAllPoints()
    sheen:SetPoint("CENTER", holder, "CENTER", -0.75 * size, 0)
    if sheenSize ~= size then
        sheenAnim:Stop()
        sheenTravel:SetOffset(1.5 * size, 0)
        sheenSize = size
    end
    if not sheenAnim:IsPlaying() then
        sheen:SetAlpha(0)
        sheenAnim:Play()
    end
end

function Target.Update()
    local db = ns.db.target
    if not db.enabled or not UnitExists("target") then return HideArt() end
    local frame = _G.EllesmereUIUnitFrames_Target
    local portrait = frame and frame.Portrait
    local backdrop = portrait and portrait.backdrop
    if not (backdrop and backdrop:IsShown()) then return HideArt() end

    local tier
    if ns.preview then
        tier = ns.preview
    elseif not (db.hideNative and Native("target")) then
        tier = ns.Tier("target", db.minTier)
    end
    if not tier then return HideArt() end

    if not holder then Build() end
    if holder:GetParent() ~= frame then holder:SetParent(frame) end
    holder:SetFrameStrata(backdrop:GetFrameStrata())
    holder:SetFrameLevel(backdrop:GetFrameLevel() + 6)

    local hole = math.min(backdrop:GetWidth(), backdrop:GetHeight())
    local size = hole * SIZE_PER_HOLE * db.scale / 100
    local flip = Mirrored(db.side, frame, backdrop)
    holder:SetSize(size, size)
    holder:ClearAllPoints()
    holder:SetPoint("CENTER", backdrop, "CENTER",
        (flip and -CENTER_SHIFT or CENTER_SHIFT) * size + db.x, CENTER_SHIFT * size + db.y)

    local l, r = 0, 1
    if flip then l, r = 1, 0 end
    local found = ns.Found("target", tier)
    local dim = db.dimFound and found == true
    local fresh = db.glowNew and found == false
    laurel:SetTexture(ns.LAURELS[tier])
    glow:SetTexture(ns.LAURELS[tier])
    laurel:SetTexCoord(l, r, 0, 1)
    glow:SetTexCoord(l, r, 0, 1)
    laurel:SetDesaturation(dim and db.foundDesat / 100 or 0)
    holder:SetAlpha(dim and db.foundAlpha / 100 or 1)
    holder:Show()

    if tier == "shiny" and db.shimmer and (not dim or db.shimmerFound) then
        PlaySheen(tier, size, flip)
    else
        StopSheen()
    end
    if fresh then
        if not pulse:IsPlaying() then pulse:Play() end
    else
        StopPulse()
    end
end
