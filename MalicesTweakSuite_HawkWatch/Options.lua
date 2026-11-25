-------------------------------------------------------------------------------
--  Hawk Watch: options (/hawkwatch opens it)
-------------------------------------------------------------------------------
local _, ns = ...

local function Off() return not ns.db.enabled end

local function Cfg(cfg, key, needs, needsText)
    cfg.getValue = function() return ns.db[key] end
    cfg.setValue = function(v)
        ns.db[key] = v
        ns.Refresh()
        if cfg.repage then EllesmereUI:RefreshPage() end
    end
    if key ~= "enabled" then
        cfg.disabled = function() return Off() or (needs and not ns.db[needs]) or false end
        cfg.disabledTooltip = needsText or "Hawk Tile"
    end
    return cfg
end

local function Toggle(key, text, tooltip, repage, needs, needsText)
    return Cfg({ type = "toggle", text = text, tooltip = tooltip, repage = repage }, key, needs, needsText)
end

local function Slider(key, text, min, max, step, needs, needsText)
    return Cfg({ type = "slider", text = text, min = min, max = max, step = step, isPercent = false }, key, needs, needsText)
end

local function Dropdown(key, text, values, order)
    return Cfg({ type = "dropdown", text = text, values = values, order = order }, key)
end

local function Swatch(key, text, needs, needsText)
    return { type = "colorpicker", text = text,
        disabled = function() return Off() or not ns.db[needs] end,
        disabledTooltip = needsText,
        getValue = function() local c = ns.db[key]; return c.r, c.g, c.b end,
        setValue = function(r, g, b) ns.db[key] = { r = r, g = g, b = b }; ns.Refresh() end }
end

local function Page(parent, y)
    local W = EllesmereUI.Widgets
    local _, h

    _, h = W:SectionHeader(parent, "HAWK TILE", y); y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("enabled", "Enable Hawk Tile", "Hunters with the Summon Hawk talent only. A movable tile showing which of your two hawks are out, their time left, and the cooldown Summon Hawk shares with Arcane Shot. Move it from EllesmereUI Unlock Mode.", true),
        Dropdown("show", "Show", { ALWAYS = "Always", COMBAT = "In Combat or Hawks Out" }, { "ALWAYS", "COMBAT" }))
    y = y - h
    _, h = W:DualRow(parent, y,
        Dropdown("layout", "Layout", { HORIZONTAL = "Horizontal", VERTICAL = "Vertical" }, { "HORIZONTAL", "VERTICAL" }),
        { type = "toggle", text = "Test Mode",
            tooltip = "Show both hawks and the recast hint (if on) so you can style the tile. Not saved.",
            disabled = function() return not ns.running end,
            disabledTooltip = "Hawk Tile and the Summon Hawk talent",
            getValue = function() return ns.testMode == true end,
            setValue = function(v) ns.testMode = v and true or false; ns.Refresh() end })
    y = y - h

    _, h = W:SectionHeader(parent, "APPEARANCE", y); y = y - h
    _, h = W:DualRow(parent, y,
        Slider("size", "Icon Size", 16, 80, 1),
        Slider("spacing", "Spacing", 0, 20, 1))
    y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("showSeconds", "Show Seconds", nil, true),
        Slider("fontSize", "Text Size", 8, 32, 1, "showSeconds", "Show Seconds"))
    y = y - h
    _, h = W:DualRow(parent, y,
        Slider("bgAlpha", "Background Opacity", 0, 1, 0.05),
        EllesmereUI.BlankRowCfg())
    y = y - h

    _, h = W:SectionHeader(parent, "COOLDOWN BAR", y); y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("bar", "Show Cooldown Bar", "Drains over the cooldown Summon Hawk shares with Arcane Shot. Empty means ready.", true),
        Slider("barHeight", "Bar Height", 2, 20, 1, "bar", "Show Cooldown Bar"))
    y = y - h
    _, h = W:DualRow(parent, y,
        Swatch("barColor", "Bar Color", "bar", "Show Cooldown Bar"),
        EllesmereUI.BlankRowCfg())
    y = y - h

    _, h = W:SectionHeader(parent, "RECAST HINT", y); y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("hint", "Show Recast Hint", "In combat, outline the tile when a hawk is missing or the older one is about to leave. A third cast replaces the older hawk.", true),
        Slider("hintAt", "Seconds Left", 0, 12, 1, "hint", "Show Recast Hint"))
    y = y - h
    _, h = W:DualRow(parent, y,
        Swatch("hintColor", "Hint Color", "hint", "Show Recast Hint"),
        EllesmereUI.BlankRowCfg())
    y = y - h
    return math.abs(y)
end

function ns.RegisterOptions()
    MalicesTweakSuite.AddModule(40, {
        key = "HawkWatch",
        title = "Hawk Watch",
        description = "Your Summon Hawk hawks, their time left and the shared cooldown.",
        pages = { "Hawk Tile" },
        buildPage = function(_, parent, yOffset) return Page(parent, yOffset) end,
    })
end
