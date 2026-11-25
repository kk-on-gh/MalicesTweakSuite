-------------------------------------------------------------------------------
--  Hawk Watch: tile
--  One icon per hawk slot and a bar for the cooldown shared with Arcane Shot.
--  Secret totem values go straight into widgets that accept them.
-------------------------------------------------------------------------------
local _, ns = ...

local Tile = {}
ns.Tile = Tile

local PAD, EDGE = 4, 2
local frame
local cells = {}
local setupDone = false

local function Preview() return ns.testMode or ns.unlockActive end

local function FontPath()
    return (EllesmereUI.GetFontPath and EllesmereUI.GetFontPath()) or "Fonts\\FRIZQT__.TTF"
end
local function FontFlags()
    return (EllesmereUI.GetFontOutlineFlag and EllesmereUI.GetFontOutlineFlag()) or "OUTLINE"
end

local function CreateIcon(parent, texture)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetPoint("TOPLEFT", 1, -1)
    t:SetPoint("BOTTOMRIGHT", -1, 1)
    t:SetTexture(texture)
    t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return t
end

local function CreateCell(i, texture)
    local c = CreateFrame("Frame", nil, frame)
    c.bg = c:CreateTexture(nil, "BACKGROUND")
    c.bg:SetAllPoints()
    c.bg:SetColorTexture(0, 0, 0, 0.8)
    c.dim = CreateIcon(c, texture)
    c.dim:SetDesaturated(true)
    c.dim:SetAlpha(0.35)
    c.lit = CreateFrame("Frame", nil, c)
    c.lit:SetAllPoints()
    c.lit:SetAlpha(0)
    c.icon = CreateIcon(c.lit, texture)
    c.cd = CreateFrame("Cooldown", nil, c.lit, "CooldownFrameTemplate")
    c.cd:SetPoint("TOPLEFT", 1, -1)
    c.cd:SetPoint("BOTTOMRIGHT", -1, 1)
    c.cd:EnableMouse(false)
    c.cd:SetReverse(true)
    c.cd:SetDrawBling(false)
    c.cd:SetDrawEdge(false)
    c.cd:SetSwipeColor(0, 0, 0, 0.6)
    cells[i] = c
end

local function CreateTile()
    frame = CreateFrame("Frame", "HawkWatchTile", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()

    local texture = C_Spell.GetSpellTexture(ns.ICON) or "Interface\\Icons\\ability_hunter_animalhandler"
    for i = 1, #ns.SLOTS do CreateCell(i, texture) end

    frame.track = frame:CreateTexture(nil, "BORDER")
    frame.track:SetColorTexture(0, 0, 0, 0.8)
    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetAllPoints(frame.track)
    frame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    frame.bar:SetAlpha(0)

    frame.hint = CreateFrame("Frame", nil, frame)
    frame.hint:SetAllPoints()
    frame.hint.edges = {}
    for i = 1, 4 do frame.hint.edges[i] = frame.hint:CreateTexture(nil, "OVERLAY") end
    local top, bottom, left, right = unpack(frame.hint.edges)
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(EDGE)
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(EDGE)
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(EDGE)
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(EDGE)
    frame.hint:Hide()

    frame:Hide()
    Tile.ApplyPosition()
    Tile.Restyle()
end

-------------------------------------------------------------------------------
--  Updates
-------------------------------------------------------------------------------
function Tile.UpdateSlots()
    if not frame then return end
    local now = GetTime()
    for i, slot in ipairs(ns.SLOTS) do
        local c = cells[i]
        if Preview() then
            c.lit:SetAlpha(1)
            c.cd:SetCooldown(now - 6 * (3 - i), 18)
        else
            local have = GetTotemInfo(slot)
            if ns.Secret(have) then
                c.lit:SetAlphaFromBoolean(have, 1, 0)
            else
                c.lit:SetAlpha(have and 1 or 0)
            end
            local duration = GetTotemDuration(slot)
            if duration then
                c.cd:SetCooldownFromDurationObject(duration, true)
            else
                c.cd:Clear()
            end
        end
    end
end

function Tile.UpdateCooldown()
    if not (frame and ns.db.bar) then return end
    local duration = ns.spellID and C_Spell.GetSpellCooldownDuration(ns.spellID, true)
    if not duration then
        frame.bar:SetAlpha(0)
        return
    end
    frame.bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
    frame.bar:SetAlphaFromBoolean(duration:IsZero(), 0, 1)
end

-- Visibility and recast hint.
function Tile.UpdateState()
    local p = ns.db
    local now = GetTime()
    local preview = Preview()
    local shown = ns.running
        and (preview or p.show == "ALWAYS" or ns.inCombat or ns.Hawks(now) > 0)
    if not shown then
        if frame then frame:Hide() end
        return
    end
    if not frame then CreateTile() end
    if not frame:IsShown() then
        Tile.UpdateSlots()
        Tile.UpdateCooldown()
        frame:Show()
    end
    frame.hint:SetShown(p.hint and (preview or (ns.inCombat and ns.WantHawk(now))) and true or false)
end

function Tile.Restyle()
    if not frame then return end
    local p = ns.db
    local vertical = p.layout == "VERTICAL"
    local n = #cells
    local long = n * p.size + (n - 1) * p.spacing
    local barH = p.bar and (p.barHeight + p.spacing) or 0
    local w = vertical and p.size or long
    local h = (vertical and long or p.size) + barH

    frame:SetSize(w + PAD * 2, h + PAD * 2)
    frame.bg:SetColorTexture(0, 0, 0, p.bgAlpha)
    for i, c in ipairs(cells) do
        local offset = (i - 1) * (p.size + p.spacing)
        c:SetSize(p.size, p.size)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + (vertical and 0 or offset), -PAD - (vertical and offset or 0))
        c.cd:SetHideCountdownNumbers(not p.showSeconds)
        local text = c.cd:GetCountdownFontString()
        if text then text:SetFont(FontPath(), p.fontSize, FontFlags()) end
    end
    frame.track:ClearAllPoints()
    frame.track:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
    frame.track:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    frame.track:SetHeight(p.barHeight)
    frame.track:SetShown(p.bar)
    frame.bar:SetShown(p.bar)
    frame.bar:SetStatusBarColor(p.barColor.r, p.barColor.g, p.barColor.b)
    for _, edge in ipairs(frame.hint.edges) do
        edge:SetColorTexture(p.hintColor.r, p.hintColor.g, p.hintColor.b, 1)
    end
    Tile.UpdateSlots()
    Tile.UpdateCooldown()
    if EllesmereUI._unlockActive and EllesmereUI.RepositionBarToMover then
        EllesmereUI.RepositionBarToMover("HawkWatch_Tile")
    end
end

-------------------------------------------------------------------------------
--  Position and unlock mode
-------------------------------------------------------------------------------
function Tile.ApplyPosition()
    if not frame then return end
    local pos = ns.db.pos
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", pos and pos.centerX or 0, pos and pos.centerY or -160)
end

-- Registers with unlock mode the first time the tile is enabled.
function Tile.Setup()
    if setupDone then return end
    setupDone = true
    local MK = EllesmereUI.MakeUnlockElement
    if not (MK and EllesmereUI.RegisterUnlockElements) then return end
    EllesmereUI:RegisterUnlockElements({
        MK({
            key = "HawkWatch_Tile",
            label = "Hawk Watch",
            group = "Hawk Watch",
            order = 110,
            noResize = true,
            noAnchorTarget = true,
            isHidden = function() return not ns.running end,
            getFrame = function()
                if not frame then CreateTile() end
                return frame
            end,
            getSize = function()
                if not frame then CreateTile() end
                return frame:GetWidth(), frame:GetHeight()
            end,
            savePos = function(_, _, _, x, y) ns.db.pos = { centerX = x, centerY = y } end,
            loadPos = function()
                local pos = ns.db.pos
                if pos then
                    return { point = "CENTER", relPoint = "CENTER", x = pos.centerX, y = pos.centerY }
                end
            end,
            clearPos = function() ns.db.pos = nil end,
            applyPos = function() Tile.ApplyPosition() end,
        }),
    })
    if EllesmereUI.RegisterUnlockModeListener then
        EllesmereUI:RegisterUnlockModeListener("HawkWatch", function(active)
            ns.unlockActive = active and true or false
            ns.Refresh()
        end)
    end
end
