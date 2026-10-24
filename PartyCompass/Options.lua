-------------------------------------------------------------------------------
--  Party Compass: options
--  A plugin section in the EllesmereUI options panel (/pcompass opens it).
-------------------------------------------------------------------------------
local _, ns = ...

local COLOR_VALUES = { CLASS = "Class Color", WHITE = "White", CUSTOM = "Custom" }
local COLOR_ORDER = { "CLASS", "WHITE", "CUSTOM" }
local POINT_ORDER = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local POINT_VALUES = {}
for _, p in ipairs(POINT_ORDER) do POINT_VALUES[p] = p:sub(1, 1) .. p:sub(2):lower() end

-- Cfg builders: section = key into ns.db, after = refresh callback.
local function Toggle(section, key, text, tooltip, repage)
    return { type = "toggle", text = text, tooltip = tooltip,
        getValue = function() return ns.db[section][key] end,
        setValue = function(v)
            ns.db[section][key] = v
            ns.Refresh()
            if repage then EllesmereUI:RefreshPage() end
        end }
end

local function Slider(section, key, text, min, max, step, disabled)
    return { type = "slider", text = text, min = min, max = max, step = step, isPercent = false,
        disabled = disabled,
        getValue = function() return ns.db[section][key] end,
        setValue = function(v) ns.db[section][key] = v; ns.Refresh() end }
end

local function Dropdown(section, key, text, values, order, repage)
    return { type = "dropdown", text = text, values = values, order = order,
        getValue = function() return ns.db[section][key] end,
        setValue = function(v)
            ns.db[section][key] = v
            ns.Refresh()
            if repage then EllesmereUI:RefreshPage() end
        end }
end

local function Swatch(section, text)
    return { type = "colorpicker", text = text,
        disabled = function() return ns.db[section].arrowColor ~= "CUSTOM" end,
        disabledTooltip = "Arrow Color: Custom",
        getValue = function() local c = ns.db[section].customColor; return c.r, c.g, c.b end,
        setValue = function(r, g, b) ns.db[section].customColor = { r = r, g = g, b = b }; ns.Refresh() end }
end

local function TestModeCfg()
    return { type = "toggle", text = "Test Mode",
        tooltip = "Show sample members on the tile so you can style it while solo. Not saved.",
        getValue = function() return ns.testMode == true end,
        setValue = function(v) ns.testMode = v and true or false; ns.Arm() end }
end

local function TilePage(parent, y)
    local W = EllesmereUI.Widgets
    local blank = EllesmereUI.BlankRowCfg
    local _, h
    local off = function() return not ns.db.tile.enabled end
    local function D(cfg) cfg.disabled = cfg.disabled or off; cfg.disabledTooltip = cfg.disabledTooltip or "Standalone Tile"; return cfg end

    _, h = W:SectionHeader(parent, "STANDALONE TILE", y); y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("tile", "enabled", "Enable Standalone Tile", "A movable tile with an arrow, name and distance for each party member. Move it from EllesmereUI Unlock Mode.", true),
        D(Dropdown("tile", "layout", "Layout", { HORIZONTAL = "Horizontal", VERTICAL = "Vertical" }, { "HORIZONTAL", "VERTICAL" })))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("tile", "max", "Max Members", 1, 40, 1)),
        D(Toggle("tile", "hideSolo", "Hide When Not Grouped")))
    y = y - h

    _, h = W:SectionHeader(parent, "APPEARANCE", y); y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("tile", "arrowSize", "Arrow Size", 12, 80, 1)),
        D(Slider("tile", "fontSize", "Text Size", 8, 24, 1)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("tile", "spacing", "Spacing", 0, 30, 1)),
        D(Slider("tile", "bgAlpha", "Background Opacity", 0, 1, 0.05)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Dropdown("tile", "arrowColor", "Arrow Color", COLOR_VALUES, COLOR_ORDER, true)),
        D(Swatch("tile", "Custom Arrow Color")))
    y = y - h

    _, h = W:SectionHeader(parent, "TEXT", y); y = y - h
    _, h = W:DualRow(parent, y,
        D(Toggle("tile", "showName", "Show Names")),
        D(Toggle("tile", "nameClassColor", "Class-Colored Names")))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Toggle("tile", "showDistance", "Show Distance")),
        D(Toggle("tile", "showStatus", "Show Dead / Offline / Zone")))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Toggle("tile", "showOtherZone", "Show Members In Other Zones")),
        D(Dropdown("tile", "nameFormat", "Name Format", { FULL = "Full Name", FIRST = "First Name Only" }, { "FULL", "FIRST" })))
    y = y - h
    return math.abs(y)
end

local function FramesPage(parent, y)
    local W = EllesmereUI.Widgets
    local blank = EllesmereUI.BlankRowCfg
    local _, h
    local off = function() return not ns.db.frames.enabled end
    local function D(cfg) cfg.disabled = cfg.disabled or off; cfg.disabledTooltip = cfg.disabledTooltip or "Frame Arrows"; return cfg end

    _, h = W:SectionHeader(parent, "FRAME ARROWS", y); y = y - h
    _, h = W:DualRow(parent, y,
        Toggle("frames", "enabled", "Enable Frame Arrows", "Show a direction arrow on each EllesmereUI party and raid frame.", true),
        D(Slider("frames", "size", "Arrow Size", 8, 48, 1)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Dropdown("frames", "point", "Anchor", POINT_VALUES, POINT_ORDER)),
        D(Slider("frames", "hideWithin", "Hide Within (yd)", 0, 100, 1)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Slider("frames", "x", "X Offset", -60, 60, 1)),
        D(Slider("frames", "y", "Y Offset", -60, 60, 1)))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Dropdown("frames", "arrowColor", "Arrow Color", COLOR_VALUES, COLOR_ORDER, true)),
        D(Swatch("frames", "Custom Arrow Color")))
    y = y - h
    _, h = W:DualRow(parent, y,
        D(Toggle("frames", "showDistance", "Show Distance", nil, true)),
        D(Slider("frames", "fontSize", "Distance Text Size", 6, 18, 1,
            function() return not (ns.db.frames.enabled and ns.db.frames.showDistance) end)))
    y = y - h
    return math.abs(y)
end

local function GeneralPage(parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    _, h = W:SectionHeader(parent, "GENERAL", y); y = y - h
    _, h = W:DualRow(parent, y,
        Dropdown("general", "units", "Distance Units", { YARDS = "Yards", METERS = "Meters" }, { "YARDS", "METERS" }),
        Slider("general", "interval", "Update Interval (s)", 0.03, 0.3, 0.01))
    y = y - h
    _, h = W:DualRow(parent, y,
        TestModeCfg(),
        EllesmereUI.BlankRowCfg())
    y = y - h
    return math.abs(y)
end

local PAGES = { ["Standalone Tile"] = TilePage, ["Frame Arrows"] = FramesPage, ["General"] = GeneralPage }

function ns.RegisterOptions()
    EllesmereUI.RegisterPlugin("PartyCompass", {
        label = "Malice's Tweak Suite",
        modules = { {
            key = "Arrows",
            title = "Party Compass",
            description = "Direction arrows toward your party members.",
            pages = { "Standalone Tile", "Frame Arrows", "General" },
            buildPage = function(pageName, parent, yOffset)
                return PAGES[pageName](parent, yOffset)
            end,
        } },
    })
end
