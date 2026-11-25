-------------------------------------------------------------------------------
--  MobInfo2 Button: options (a module in the Malice's Tweak Suite section)
-------------------------------------------------------------------------------
local _, ns = ...

local function MinimapLoaded()
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIMinimap")
end

local function Page(parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    _, h = W:SectionHeader(parent, "MINIMAP BUTTON", y); y = y - h
    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Collectible Button",
            tooltip = "Let EllesmereUI's minimap group MobInfo2's button with your other addon buttons. EllesmereUI skips it otherwise, because its name ends in a number. MobInfo2's own Show Minimap Button option still hides it.",
            getValue = function() return ns.db.enabled end,
            setValue = function(v)
                ns.db.enabled = v
                ns.Apply()
                if MinimapLoaded() then
                    EllesmereUI:ShowConfirmPopup({
                        title = "Reload UI",
                        message = "EllesmereUI's minimap picks up the change after a reload. Reload now?",
                        confirmText = "Reload",
                        reload = true,
                    })
                end
            end },
        EllesmereUI.BlankRowCfg())
    y = y - h
    return math.abs(y)
end

function ns.RegisterOptions()
    MalicesTweakSuite.AddModule(30, {
        key = "MobInfoButton",
        title = "MobInfo2 Button",
        description = "MobInfo2's minimap button, grouped by EllesmereUI's minimap.",
        pages = { "Minimap Button" },
        buildPage = function(_, parent, yOffset) return Page(parent, yOffset) end,
    })
end
