-------------------------------------------------------------------------------
--  Party Compass: standalone tile
--  One movable frame (EllesmereUI unlock mode) with a cell per party member:
--  arrow, name and distance, or a status (Offline / Dead / zone name).
--  Built lazily the first time it is needed.
-------------------------------------------------------------------------------
local _, ns = ...

local Tile = {}
ns.Tile = Tile

local PAD = 4
local frame
local cells = {}
local setupDone = false

local function P() return ns.db and ns.db.tile end

-- Sample data for test mode / unlock mode so the tile can be styled solo.
local SAMPLE = {
    { name = "Tank Test",   class = "WARRIOR", yards = 12,  status = "ok",   spin = 0 },
    { name = "Healer Test", class = "PRIEST",  yards = 48,  status = "ok",   spin = 2 },
    { name = "Mage Test", class = "MAGE",    yards = 130, status = "ok",   spin = 4 },
    { name = "Rogue Test", class = "ROGUE",   status = "dead" },
    { name = "Hunter Test", class = "HUNTER",  status = "zone", zone = "Elwynn Forest" },
    { name = "Druid Test",  class = "DRUID",   status = "offline" },
}

local function CellSize(p)
    local textW = (p.showName or p.showDistance) and (p.fontSize * 7) or 0
    local w = p.arrowSize + (textW > 0 and (6 + textW) or 0)
    local h = math.max(p.arrowSize, p.fontSize * 2 + 2)
    return w, h
end

local function CreateTile()
    frame = CreateFrame("Frame", "PartyCompassTile", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, P().bgAlpha)
    frame.empty = frame:CreateFontString(nil, "OVERLAY")
    frame.empty:SetFont(ns.FontPath(), P().fontSize, ns.FontFlags())
    frame.empty:SetPoint("CENTER")
    frame.empty:SetTextColor(0.7, 0.7, 0.7)
    frame.empty:SetText("No group")
    frame:Hide()
    Tile.ApplyPosition()
end

local function CreateCell(i)
    local c = CreateFrame("Frame", nil, frame)
    c.arrow = c:CreateTexture(nil, "OVERLAY")
    c.arrow:SetTexture(ns.ARROW)
    c.glyph = c:CreateFontString(nil, "OVERLAY")
    c.glyph:SetPoint("CENTER", c.arrow, "CENTER", 0, 0)
    c.name = c:CreateFontString(nil, "OVERLAY")
    c.name:SetJustifyH("LEFT")
    c.dist = c:CreateFontString(nil, "OVERLAY")
    c.dist:SetJustifyH("LEFT")
    cells[i] = c
    return c
end

-- Text sits beside the arrow, or hugs a narrower X / ? glyph (horizontal only,
-- so vertical columns stay aligned).
local function SetLead(c, p, glyphOn)
    local tight = glyphOn and p.layout ~= "VERTICAL"
    local two = p.showName and c.dist:IsShown()
    if c._lead == tight and c._two == two then return end
    c._lead, c._two = tight, two
    local lead = tight and c.glyph or c.arrow
    local gap = tight and 4 or 6
    c.glyph:ClearAllPoints()
    if tight then
        c.glyph:SetPoint("LEFT", c, "LEFT", 0, 0)
    else
        c.glyph:SetPoint("CENTER", c.arrow, "CENTER", 0, 0)
    end
    c.name:ClearAllPoints()
    c.dist:ClearAllPoints()
    if two then
        c.name:SetPoint("BOTTOMLEFT", lead, "RIGHT", gap, 1)
        c.dist:SetPoint("TOPLEFT", lead, "RIGHT", gap, -1)
    else
        c.name:SetPoint("LEFT", lead, "RIGHT", gap, 0)
        c.dist:SetPoint("LEFT", lead, "RIGHT", gap, 0)
    end
end

local function StyleCell(c, p)
    local font, flags = ns.FontPath(), ns.FontFlags()
    local w, h = CellSize(p)
    c:SetSize(w, h)
    c.arrow:SetSize(p.arrowSize, p.arrowSize)
    c.arrow:ClearAllPoints()
    c.arrow:SetPoint("LEFT", c, "LEFT", 0, 0)
    c.glyph:SetFont(font, math.floor(p.arrowSize * 1.1), flags ~= "" and flags or "OUTLINE")
    c.name:SetFont(font, p.fontSize, flags)
    c.dist:SetFont(font, p.fontSize, flags)
    local textW = w - p.arrowSize - 6
    c.name:SetWidth(textW)
    c.dist:SetWidth(textW)
    c._lead, c._two = nil, nil
    c._styleW, c._styleH = w, h
end

-- Horizontal cells are as wide as their own text, so entries sit close
-- together at low spacing. Returns the cell's width.
local function Size(c, p, w)
    if p.layout == "VERTICAL" then return w end
    local textW = 0
    if c.name:IsShown() then textW = c.name:GetStringWidth() end
    if c.dist:IsShown() then textW = math.max(textW, c.dist:GetStringWidth()) end
    local lead, gap = p.arrowSize, 6
    if c._lead then lead, gap = math.ceil(c.glyph:GetStringWidth()), 4 end
    local cw = lead
    if textW > 0 then
        textW = math.ceil(textW) + 1
        cw = cw + gap + textW
        c.name:SetWidth(textW)
        c.dist:SetWidth(textW)
    end
    c:SetWidth(cw)
    return cw
end

local function Place(c, p, offset)
    c:ClearAllPoints()
    if p.layout == "VERTICAL" then
        c:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD - offset)
    else
        c:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + offset, -PAD)
    end
end

-- Fills one cell. Returns true when the cell is shown.
local function Fill(c, p, name, r, g, b, status, rot, yards, zone)
    c.name:SetShown(p.showName)
    if p.showName then
        c.name:SetText(name)
        if p.nameClassColor then c.name:SetTextColor(r, g, b) else c.name:SetTextColor(1, 1, 1) end
    end
    c.glyph:Hide()
    if status == "ok" then
        if rot then
            c.arrow:SetRotation(rot)
            local ar, ag, ab = 1, 1, 1
            if p.arrowColor == "CLASS" then ar, ag, ab = r, g, b
            elseif p.arrowColor == "CUSTOM" then ar, ag, ab = p.customColor.r, p.customColor.g, p.customColor.b end
            c.arrow:SetVertexColor(ar, ag, ab)
            c.arrow:Show()
        else
            c.arrow:Hide()
        end
        c.dist:SetShown(p.showDistance)
        if p.showDistance then
            c.dist:SetText(ns.FormatDistance(yards))
            c.dist:SetTextColor(0.9, 0.9, 0.9)
        end
    else
        c.arrow:Hide()
        if status == "dead" then
            c.glyph:SetText("X"); c.glyph:SetTextColor(1, 0.15, 0.15); c.glyph:Show()
        elseif status == "offline" then
            c.glyph:SetText("X"); c.glyph:SetTextColor(0.5, 0.5, 0.5); c.glyph:Show()
        elseif status == "zone" then
            c.glyph:SetText("?"); c.glyph:SetTextColor(0.75, 0.75, 0.75); c.glyph:Show()
        end
        c.dist:SetShown(p.showStatus)
        if p.showStatus then
            if status == "offline" then
                c.dist:SetText("Offline"); c.dist:SetTextColor(0.5, 0.5, 0.5)
            elseif status == "dead" then
                c.dist:SetText("Dead"); c.dist:SetTextColor(1, 0.2, 0.2)
            else
                c.dist:SetText(zone or "Unknown"); c.dist:SetTextColor(0.7, 0.7, 0.7)
            end
        end
    end
    SetLead(c, p, c.glyph:IsShown())
    c:Show()
end

local function MemberName(unit, p)
    local name = UnitName(unit)
    if not name or ns.Secret(name) then return "?" end
    if p.nameFormat == "FIRST" then name = name:match("^(%S+)") or name end
    return name
end

local function ZoneName(mapID)
    local info = mapID and C_Map.GetMapInfo(mapID)
    return info and info.name
end

function Tile.Hide()
    if frame then frame:Hide() end
end

function Tile.Update()
    local p = P()
    if not (p and p.enabled) then Tile.Hide() return end
    if not frame then CreateTile() end

    local preview = ns.testMode or ns.unlockActive
    local count, offset = 0, 0
    local w, h = CellSize(p)
    local vertical = p.layout == "VERTICAL"

    if ns.testMode or (preview and not IsInGroup()) then
        local t = GetTime()
        for i = 1, math.min(#SAMPLE, p.max) do
            local s = SAMPLE[i]
            local c = cells[i] or CreateCell(i)
            if c._styleW ~= w or c._styleH ~= h then StyleCell(c, p) end
            local col = RAID_CLASS_COLORS[s.class]
            local rot = s.status == "ok" and ((t * 0.6 + s.spin) % (2 * math.pi)) or nil
            Fill(c, p, p.nameFormat == "FIRST" and s.name:match("^(%S+)") or s.name, col.r, col.g, col.b, s.status, rot, s.yards, s.zone)
            count = count + 1
            Place(c, p, offset)
            offset = offset + (vertical and h or Size(c, p, w)) + p.spacing
        end
    elseif ns.wantTick() then
        for _, unit in ipairs(ns.GetUnits()) do
            if count >= p.max then break end
            local status, rot, yards, mapID = ns.Locate(unit)
            if status ~= "none" and (status ~= "zone" or p.showOtherZone) then
                count = count + 1
                local c = cells[count] or CreateCell(count)
                if c._styleW ~= w or c._styleH ~= h then StyleCell(c, p) end
                local r, g, b = ns.ClassColor(unit)
                Fill(c, p, MemberName(unit, p), r, g, b, status, rot, yards, ZoneName(mapID))
                Place(c, p, offset)
                offset = offset + (vertical and h or Size(c, p, w)) + p.spacing
            end
        end
    end

    for i = count + 1, #cells do cells[i]:Hide() end

    if count == 0 and p.hideSolo and not preview then
        frame:Hide()
        return
    end
    frame.empty:SetFont(ns.FontPath(), p.fontSize, ns.FontFlags())
    frame.empty:SetShown(count == 0)
    local fw, fh
    local span = count > 0 and (offset - p.spacing) or 0
    if vertical then
        fw, fh = math.max(w, count == 0 and 70 or 0) + PAD * 2, math.max(span, h) + PAD * 2
    else
        fw, fh = math.max(span, count == 0 and 70 or 0) + PAD * 2, h + PAD * 2
    end
    if frame._w ~= fw or frame._h ~= fh then
        frame._w, frame._h = fw, fh
        frame:SetSize(fw, fh)
        if EllesmereUI._unlockActive and EllesmereUI.RepositionBarToMover then
            EllesmereUI.RepositionBarToMover("PartyCompass_Tile")
        end
    end
    frame:Show()
end

-- Styling changed: drop cached cell styles so the next Update rebuilds them.
function Tile.Restyle()
    local p = P()
    for _, c in ipairs(cells) do c._styleW = nil end
    if frame then
        frame._w = nil
        frame.bg:SetColorTexture(0, 0, 0, p.bgAlpha)
    end
    Tile.Setup()
end

-------------------------------------------------------------------------------
--  Position and unlock mode
-------------------------------------------------------------------------------
function Tile.ApplyPosition()
    if not frame then return end
    local p = P()
    local pos = p and p.pos
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", pos and pos.centerX or 0, pos and pos.centerY or 200)
end

local function RegisterUnlock()
    local MK = EllesmereUI.MakeUnlockElement
    if not (MK and EllesmereUI.RegisterUnlockElements) then return end
    EllesmereUI:RegisterUnlockElements({
        MK({
            key = "PartyCompass_Tile",
            label = "Party Compass",
            group = "Party Compass",
            order = 100,
            noResize = true,
            noAnchorTarget = true,
            isHidden = function() local p = P(); return not (p and p.enabled) end,
            getFrame = function()
                if not frame then CreateTile() end
                return frame
            end,
            getSize = function()
                if not frame then CreateTile() end
                return frame:GetWidth(), frame:GetHeight()
            end,
            savePos = function(_, _, _, x, y)
                local p = P(); if p then p.pos = { centerX = x, centerY = y } end
            end,
            loadPos = function()
                local p = P()
                if p and p.pos then
                    return { point = "CENTER", relPoint = "CENTER", x = p.pos.centerX, y = p.pos.centerY }
                end
            end,
            clearPos = function() local p = P(); if p then p.pos = nil end end,
            applyPos = function() Tile.ApplyPosition() end,
        }),
    })
end

-- Registers with unlock mode the first time the tile is enabled.
function Tile.Setup()
    local p = P()
    if setupDone or not (p and p.enabled) then return end
    setupDone = true
    RegisterUnlock()
    if EllesmereUI.RegisterUnlockModeListener then
        EllesmereUI:RegisterUnlockModeListener("PartyCompass", function(active)
            ns.unlockActive = active and true or false
            ns.Arm()
        end)
    end
end
