-------------------------------------------------------------------------------
--  Party Compass: arrows on EllesmereUI party/raid frames
--  Our own small frames, parented to UIParent and anchored to EUI's unit
--  buttons (found with EllesmereUI.GetUnitFrame). Nothing is written onto
--  the buttons themselves.
-------------------------------------------------------------------------------
local _, ns = ...

local FA = {}
ns.FrameArrows = FA

local arrows = {}    -- [unit] = arrow frame
local buttons = {}   -- [unit] = EUI button (re-resolved periodically)
local pass, resolveAt, styleGen = 0, 0, 1

local function P() return ns.db and ns.db.frames end

local function Create()
    local a = CreateFrame("Frame", nil, UIParent)
    a.tex = a:CreateTexture(nil, "OVERLAY")
    a.tex:SetAllPoints()
    a.tex:SetTexture(ns.ARROW)
    a.text = a:CreateFontString(nil, "OVERLAY")
    a.text:SetPoint("TOP", a, "BOTTOM", 0, -1)
    return a
end

local function Style(a, p)
    a:SetSize(p.size, p.size)
    a.text:SetFont(ns.FontPath(), p.fontSize, ns.FontFlags())
    a.text:SetShown(p.showDistance)
    a._gen = styleGen
    a._btn = nil   -- force a re-anchor with the current offsets
end

local function Resolve()
    wipe(buttons)
    if not EllesmereUI.GetUnitFrame then return end
    for _, unit in ipairs(ns.GetUnits()) do
        buttons[unit] = EllesmereUI.GetUnitFrame(unit)
    end
end

function FA.Hide()
    for _, a in pairs(arrows) do a:Hide() end
end

-- Roster changed: EUI's header reassigns units a moment after the event.
function FA.Invalidate()
    resolveAt = 0
    if P() and P().enabled then
        C_Timer.After(0.5, function() resolveAt = 0 end)
    end
end

function FA.Restyle()
    styleGen = styleGen + 1
    resolveAt = 0
end

function FA.Update()
    local p = P()
    if not (p and p.enabled and ns.ctx.ok) then FA.Hide() return end
    pass = pass + 1
    local now = GetTime()
    if now >= resolveAt then
        Resolve()
        resolveAt = now + 1
    end
    for _, unit in ipairs(ns.GetUnits()) do
        local btn = buttons[unit]
        if btn and btn:IsVisible() then
            local status, rot, yards = ns.Locate(unit)
            if status == "ok" and rot and yards >= p.hideWithin then
                local a = arrows[unit]
                if not a then a = Create(); arrows[unit] = a end
                if a._gen ~= styleGen then Style(a, p) end
                if a._btn ~= btn or a._point ~= p.point then
                    a._btn, a._point = btn, p.point
                    a:ClearAllPoints()
                    a:SetPoint(p.point, btn, p.point, p.x, p.y)
                    a:SetFrameStrata(btn:GetFrameStrata())
                    a:SetFrameLevel(btn:GetFrameLevel() + 25)
                end
                local r, g, b = 1, 1, 1
                if p.arrowColor == "CLASS" then
                    r, g, b = ns.ClassColor(unit)
                elseif p.arrowColor == "CUSTOM" then
                    r, g, b = p.customColor.r, p.customColor.g, p.customColor.b
                end
                a.tex:SetVertexColor(r, g, b)
                a.tex:SetRotation(rot)
                if p.showDistance then a.text:SetText(ns.FormatDistance(yards)) end
                a._pass = pass
                a:Show()
            end
        end
    end
    for _, a in pairs(arrows) do
        if a._pass ~= pass then a:Hide() end
    end
end
