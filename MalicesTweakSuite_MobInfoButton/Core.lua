-------------------------------------------------------------------------------
--  MobInfo2 Button: core
--  EllesmereUI's minimap skips buttons whose name ends in digits, so MobInfo2's
--  LibDBIcon10_MobInfo2 is never collected. This registers a stand-in button
--  (LibDBIcon10_MobInfo) that forwards to MobInfo2's own data object, and hides
--  the original. MobInfo2's "show minimap button" option still decides whether
--  it shows. Nothing is registered while the module is off.
-------------------------------------------------------------------------------
local ADDON, ns = ...

local SOURCE = "MobInfo2"
local CLONE = "MobInfo"
local ICON = "Interface\\CharacterFrame\\TemporaryPortrait-Monster"

local DEFAULTS = { enabled = false, icon = {} }

local DBIcon
local cloneWant, syncing

local function Source()
    local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
    return ldb and ldb:GetDataObjectByName(SOURCE)
end

-- Mirrors MobInfo2's own minimap button setting.
local function SourceWants()
    local c = MobInfoConfig
    if type(c) ~= "table" then return true end
    if type(c.minimapIcon) == "table" then return not c.minimapIcon.hide end
    return c.ShowMMButton ~= 0
end

local proxy = {
    type = "launcher",
    icon = ICON,
    OnClick = function(frame, button)
        local o = Source()
        if o and o.OnClick then o.OnClick(frame, button) end
    end,
    OnTooltipShow = function(tt)
        local o = Source()
        if o and o.OnTooltipShow then o.OnTooltipShow(tt) end
    end,
}

local function Sync()
    if syncing or not DBIcon then return end
    syncing = true
    local want = SourceWants()
    local orig = DBIcon:GetMinimapButton(SOURCE)
    local clone = DBIcon:GetMinimapButton(CLONE)
    if ns.db.enabled then
        if orig and orig:IsShown() then orig:Hide() end
    elseif orig and want and not orig:IsShown() then
        DBIcon:Show(SOURCE)
    end
    local cw = ns.db.enabled and want
    ns.db.icon.hide = not cw
    -- Act on changes only: EUI hides collected buttons itself, so IsShown() is not our state.
    if clone and cw ~= cloneWant then
        if cw then DBIcon:Show(CLONE) else DBIcon:Hide(CLONE) end
    end
    cloneWant = cw
    syncing = false
end

local hookedOrig
local function HookOriginal(btn)
    if hookedOrig or not btn then return end
    hookedOrig = true
    hooksecurefunc(btn, "Show", Sync)
    hooksecurefunc(btn, "Hide", Sync)
end

function ns.Apply()
    DBIcon = DBIcon or (LibStub and LibStub("LibDBIcon-1.0", true))
    if not DBIcon then return end
    if ns.db.enabled and not DBIcon:IsRegistered(CLONE) then
        local o = Source()
        if o and o.icon then proxy.icon = o.icon end
        ns.db.icon.hide = not SourceWants()
        cloneWant = not ns.db.icon.hide
        DBIcon:Register(CLONE, proxy, ns.db.icon)
        DBIcon.RegisterCallback(ns, "LibDBIcon_IconCreated", function(_, btn, name)
            if name == SOURCE then
                HookOriginal(btn)
                Sync()
            end
        end)
    end
    HookOriginal(DBIcon:GetMinimapButton(SOURCE))
    Sync()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON then return end
    self:UnregisterAllEvents()
    MobInfoButtonDB = MobInfoButtonDB or {}
    for k, v in pairs(DEFAULTS) do
        if MobInfoButtonDB[k] == nil then MobInfoButtonDB[k] = type(v) == "table" and {} or v end
    end
    ns.db = MobInfoButtonDB
    ns.RegisterOptions()
    if ns.db.enabled then ns.Apply() end
end)
