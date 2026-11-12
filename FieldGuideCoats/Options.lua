-------------------------------------------------------------------------------
--  Field Guide Coats: options (a module in the Malice's Tweak Suite section)
-------------------------------------------------------------------------------
local _, ns = ...

local TIER_VALUES = { silver = "Silver", gold = "Gold", shiny = "Shiny" }
local TIER_ORDER = { "silver", "gold", "shiny" }
local PREVIEW_VALUES = { OFF = "Off", silver = "Silver", gold = "Gold", shiny = "Shiny" }
local PREVIEW_ORDER = { "OFF", "silver", "gold", "shiny" }

local function Toggle(section, key, text, tooltip, repage)
    return { type = "toggle", text = text, tooltip = tooltip,
        getValue = function() return ns.db[section][key] end,
        setValue = function(v)
            ns.db[section][key] = v
            ns.Refresh()
            if repage then EllesmereUI:RefreshPage() end
        end }
end

local function Slider(section, key, text, min, max, step)
    return { type = "slider", text = text, min = min, max = max, step = step, isPercent = false,
        getValue = function() return ns.db[section][key] end,
        setValue = function(v) ns.db[section][key] = v; ns.Refresh() end }
end

local function Dropdown(section, key, text, values, order, tooltip)
    return { type = "dropdown", text = text, values = values, order = order, tooltip = tooltip,
        getValue = function() return ns.db[section][key] end,
        setValue = function(v) ns.db[section][key] = v; ns.Refresh() end }
end

local function PreviewCfg()
    return { type = "dropdown", text = "Preview Coat", values = PREVIEW_VALUES, order = PREVIEW_ORDER,
        tooltip = "Draw this coat on your current target and every nameplate, so you can place the marks. Not saved.",
        getValue = function() return ns.preview or "OFF" end,
        setValue = function(v)
            ns.preview = (v ~= "OFF") and v or nil
            ns.Refresh()
        end }
end

local function PreviewFoundCfg()
    return { type = "dropdown", text = "Preview As", values = { NEW = "New Coat", FOUND = "Found Coat" },
        order = { "NEW", "FOUND" },
        tooltip = "Whether previewed marks count as a coat you have already found.",
        disabled = function() return not ns.preview end, disabledTooltip = "Preview Coat",
        getValue = function() return ns.previewFound and "FOUND" or "NEW" end,
        setValue = function(v)
            ns.previewFound = (v == "FOUND")
            ns.Refresh()
        end }
end

-- Glow/dim rows shared by both pages.
local function FoundSection(W, parent, y, section, D, glowTip, extra)
    local _, h
    _, h = W:SectionHeader(parent, "FOUND COATS", y); y = y - h
    _, h = W:DualRow(parent, y,
        D(Toggle(section, "glowNew", "Glow On New Coats", glowTip)),
        D(Toggle(section, "dimFound", "Dim Found Coats",
            "Desaturate and fade coats this character has already found on that species.", true)))
    y = y - h
    local function Dim(cfg)
        cfg = D(cfg)
        cfg.disabled = function() return not (ns.db[section].enabled and ns.db[section].dimFound) end
        cfg.disabledTooltip = "Dim Found Coats"
        return cfg
    end
    _, h = W:DualRow(parent, y,
        Dim(Slider(section, "foundAlpha", "Found Opacity (%)", 10, 100, 5)),
        Dim(Slider(section, "foundDesat", "Found Desaturation (%)", 0, 100, 5)))
    y = y - h
    if extra then
        _, h = W:DualRow(parent, y, extra(Dim), EllesmereUI.BlankRowCfg())
        y = y - h
    end
    return y
end

local function TargetPage(parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    local off = function() return not ns.db.target.enabled end
    local function D(cfg) cfg.disabled = off; cfg.disabledTooltip = "Portrait Laurel"; return cfg end

    _, h = W:SectionHeader(parent, "PORTRAIT LAUREL", y); y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("target", "enabled", "Portrait Laurel",
            "Field Guide's laurel around the EllesmereUI target portrait. Needs a target portrait (Portrait Style other than None).", true),
        D(Dropdown("target", "minTier", "Show From", TIER_VALUES, TIER_ORDER)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("target", "scale", "Size (%)", 50, 200, 5)),
        D(Dropdown("target", "side", "Leaves Side", { AUTO = "Auto (Outward)", RIGHT = "Right", LEFT = "Left" },
            { "AUTO", "RIGHT", "LEFT" })))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("target", "x", "X Offset", -40, 40, 1)),
        D(Slider("target", "y", "Y Offset", -40, 40, 1)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Toggle("target", "hideNative", "Hide On Rare, Elite And Boss",
            "Leave rare, elite and boss targets to EllesmereUI's portrait dragon, as Field Guide does with Blizzard's frame art.")),
        D(Toggle("target", "shimmer", "Shiny Shimmer", "Field Guide's light sweeping across the shiny laurel.", true)))
    y = y - h
    y = FoundSection(W, parent, y, "target", D,
        "Pulse the laurel while it is a coat this character has not found on that species yet.",
        function(Dim)
            local cfg = Dim(Toggle("target", "shimmerFound", "Shimmer Found Shinies",
                "Keep the shiny sweep on a dimmed shiny. It fades with Found Opacity, and tells a faded shiny from a faded gold."))
            cfg.disabled = function()
                local t = ns.db.target
                return not (t.enabled and t.dimFound and t.shimmer)
            end
            cfg.disabledTooltip = "Dim Found Coats and Shiny Shimmer"
            return cfg
        end)

    _, h = W:SectionHeader(parent, "PREVIEW", y); y = y - h
    _, h = W:DualRow(parent, y, PreviewCfg(), PreviewFoundCfg())
    y = y - h
    return math.abs(y)
end

local function PlatesPage(parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    local off = function() return not ns.db.plates.enabled end
    local function D(cfg) cfg.disabled = off; cfg.disabledTooltip = "Nameplate Mark"; return cfg end

    _, h = W:SectionHeader(parent, "NAMEPLATE MARK", y); y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("plates", "enabled", "Nameplate Mark",
            "Field Guide's quality mark beside the EllesmereUI nameplate health bar.", true),
        D(Dropdown("plates", "minTier", "Show From", TIER_VALUES, TIER_ORDER)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("plates", "size", "Size", 8, 40, 1)),
        D(Slider("plates", "alpha", "Opacity", 0.1, 1, 0.05)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Dropdown("plates", "side", "Side", { RIGHT = "Right Of Bar", LEFT = "Left Of Bar" }, { "RIGHT", "LEFT" })),
        D(Slider("plates", "gap", "Gap From Bar", -20, 40, 1)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("plates", "y", "Y Offset", -20, 20, 1)),
        EllesmereUI.BlankRowCfg())
    y = y - h
    y = FoundSection(W, parent, y, "plates", D,
        "Ping the mark while it is a coat this character has not found on that species yet.")

    _, h = W:SectionHeader(parent, "PREVIEW", y); y = y - h
    _, h = W:DualRow(parent, y, PreviewCfg(), PreviewFoundCfg())
    y = y - h
    return math.abs(y)
end

local PAGES = { ["Target Portrait"] = TargetPage, ["Nameplates"] = PlatesPage }

local function EndPreview()
    if ns.preview then
        ns.preview = nil
        ns.Refresh()
    end
end

function ns.RegisterOptions()
    if EllesmereUI.RegisterOnHide then EllesmereUI:RegisterOnHide(EndPreview) end
    MalicesTweakSuite.AddModule(20, {
        key = "FieldGuideCoats",
        title = "Field Guide Coats",
        description = "Field Guide Forever's silver, gold and shiny marks on EllesmereUI frames.",
        pages = { "Target Portrait", "Nameplates" },
        buildPage = function(pageName, parent, yOffset)
            return PAGES[pageName](parent, yOffset)
        end,
        onModuleLeave = EndPreview,
        onPageCacheRestore = function() EllesmereUI:RefreshPage() end,
    })
end
