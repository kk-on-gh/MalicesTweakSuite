-------------------------------------------------------------------------------
--  Malice's Tweak Suite: shared sidebar section
--  Every suite addon ships this file unchanged. Whichever copy loads first
--  owns the table; each addon adds its module from its main chunk or
--  ADDON_LOADED, and the section is registered once, at PLAYER_LOGIN, with
--  every module in it.
-------------------------------------------------------------------------------
local suite = MalicesTweakSuite
if not suite then
    suite = { ID = "MalicesTweakSuite", LABEL = "Malice's Tweak Suite", modules = {} }
    MalicesTweakSuite = suite

    function suite.AddModule(order, spec)
        suite.modules[#suite.modules + 1] = { order = order, spec = spec }
    end

    function suite.Open(moduleKey, pageName)
        return EllesmereUI.OpenPlugin(suite.ID, moduleKey, pageName)
    end

    local boot = CreateFrame("Frame")
    boot:RegisterEvent("PLAYER_LOGIN")
    boot:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        table.sort(suite.modules, function(a, b)
            if a.order ~= b.order then return a.order < b.order end
            return a.spec.key < b.spec.key
        end)
        local list = {}
        for i, m in ipairs(suite.modules) do list[i] = m.spec end
        if #list > 0 then
            suite.registered = EllesmereUI.RegisterPlugin(suite.ID, { label = suite.LABEL, modules = list })
        end
    end)
end
