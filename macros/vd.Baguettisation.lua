script_name = "Baguettisation"
script_description = "Handle dialogue stuff"
script_version = "1.7.2"
script_author = "Vardë"
script_namespace = "vd.Baguettisation"

local tr = aegisub.gettext

local DependencyControl = require("l0.DependencyControl")
local depctrl = DependencyControl{
    feed="https://raw.githubusercontent.com/Ichunjo/aegisub-scripts/master/DependencyControl.json",
    {
        "YUtils",
        "moonscript.util",
        "aegisub.re"
    }
}
include("karaskel.lua")
local YUtils, util, re = depctrl:requireModules()


DASHES = {"-", "–", "—"}

DEFAULT_CONFIG = {
    presets = {
        Default = {
            dash = "–",
            sn_default = "Default",
            sn_default_ita = "Default - Italique",
            sn_default_dia = "Default - Dialogue",
            sn_default_dia_ita = "Default - Dialogue",
        },
        Crunchyroll = {
            dash = "–",
            sn_default = "Default",
            sn_default_ita = "Italique",
            sn_default_dia = "TiretsDefault",
            sn_default_dia_ita = "TiretsItalique",
        },
    }
}
DEFAULT_CONFIG.presets["[Last Settings]"] = DEFAULT_CONFIG.presets.Default

config = depctrl:getConfigHandler(DEFAULT_CONFIG, "config")


---@enum buttons
local BUTTONS = {
    OK = tr"OK",
    CREATE = tr"Create",
    SAVE = tr"Save",
    LOAD = tr"Load",
    DELETE = tr"Delete",
    CANCEL = tr"Cancel",
}

---Update presets from res in config if field from diag have config=true
---@param self any
---@param diag table
---@param res table
config.update_presets = function(self, diag, res)
    for _, v in pairs(diag) do
        if v.class ~= "label" and v.config then
            self.c.presets[res.name][v.name] = res[v.name]
        end
    end
    self:write()
end

---@param title string
---@param desc string
---@return string, table
local function user_warning(title, desc)
    local diag = {
        {class="label", label=title, x=0, y=0},
        {class="label", label=desc, x=0, y=1}
    }
    local buttons = {BUTTONS.OK, BUTTONS.CANCEL}
    local buttons_ids = {ok=BUTTONS.OK, cancel=BUTTONS.CANCEL}
    return aegisub.dialog.display(diag, buttons, buttons_ids)
end


---Get styles names from file
---@param subs Subs
---@return string[]
local function get_styles_names(subs)
    local _, styles = karaskel.collect_head(subs)

    ---@type string[]
    local styles_s = {}
    for _, value in ipairs(styles) do
        table.insert(styles_s, value.name)
    end

    return styles_s
end


---Get preset names from the config
---@return string[]
local function get_preset_names()
    ---@type string[]
    local preset_names = {}

    for p, _ in pairs(config.c.presets) do
        table.insert(preset_names, p)
    end

    -- Sort preset_names to make sure [Last Settings] is first element
    -- and Default is second
    table.sort(preset_names, function (a, b)
        if a == "[Last Settings]" then
            return true
        elseif b == "[Last Settings]" then
            return false
        elseif a == "Default" and b == "[Last Settings]" then
            return false
        elseif a == "Default" and b ~= "[Last Settings]" then
            return true
        elseif a ~= "[Last Settings]" and b == "Default" then
            return false
        else
            return a:lower() < b:lower()
        end
    end)

    return preset_names
end


---Get the dialog for the configure macro
---@param name string
---@param styles table
---@return table
local function get_diag_configure(name, styles)
    local preset_names = get_preset_names()
    local diag = {
        name_label = {
            class="label", label=tr"Name :",
            x=0, y=0
        },
        -- Label
        dash_label = {
            class="label", label=tr"Dash :",
            x=0, y=1
        },
        default_label = {
            class="label", label=tr"Default :",
            x=0, y=2
        },
        default_ita_label = {
            class="label", label=tr"Italic :",
            x=0, y=3
        },
        default_dia_label = {
            class="label", label=tr"Dialogue :",
            x=0, y=4
        },
        default_ita_dia_label = {
            class="label", label=tr"Italic dialogue :",
            x=0, y=5
        },
        -- User input
        name = {
            class="edit", name="name", value=name,
            x=1, y=0
        },
        dash = {
            class="dropdown", name="dash", value=config.c.presets[name].dash,
            items=DASHES,
            x=1, y=1, config=true
        },
        sn_default= {
            class="dropdown", name="sn_default", value=config.c.presets[name].sn_default,
            items=styles,
            x=1, y=2, config=true
        },
        sn_default_ita = {
            class="dropdown", name="sn_default_ita", value=config.c.presets[name].sn_default_ita,
            items=styles,
            x=1, y=3, config=true
        },
        sn_default_dia = {
            class="dropdown", name="sn_default_dia", value=config.c.presets[name].sn_default_dia,
            items=styles,
            x=1, y=4, config=true
        },
        sn_default_dia_ita = {
            class="dropdown", name="sn_default_dia_ita", value=config.c.presets[name].sn_default_dia_ita,
            items=styles,
            x=1, y=5, config=true
        },
        --
        existing_presets_label = {
            class="label", label=tr"Existing presets :",
            x=3, y=0
        },
        existing_presets = {
            class="dropdown", name="preset_sel", value=name,
            items=preset_names,
            x=4, y=0, width=1
        }
    }
    return diag
end


---Get the dialog for the (un)baguette macro
---@param name string
---@param styles table
---@return table
local function get_diag_baguette(name, styles)
    local preset_names = get_preset_names()
    local diag = {
        name_label = {
            class="label", label=tr"Name :",
            x=0, y=0
        },
        -- Label
        dash_label = {
            class="label", label=tr"Dash :",
            x=0, y=1
        },
        default_label = {
            class="label", label=tr"Default :",
            x=0, y=2
        },
        default_ita_label = {
            class="label", label=tr"Italic :",
            x=0, y=3
        },
        default_dia_label = {
            class="label", label=tr"Dialogue :",
            x=0, y=4
        },
        default_ita_dia_label = {
            class="label", label=tr"Italic dialogue :",
            x=0, y=5
        },
        -- User input
        name = {
            class="label", label=name,
            x=1, y=0
        },
        dash = {
            class="dropdown", name="dash", value=config.c.presets[name].dash,
            items=DASHES,
            x=1, y=1, config=true
        },
        sn_default= {
            class="dropdown", name="sn_default", value=config.c.presets[name].sn_default,
            items=styles,
            x=1, y=2, config=true
        },
        sn_default_ita = {
            class="dropdown", name="sn_default_ita", value=config.c.presets[name].sn_default_ita,
            items=styles,
            x=1, y=3, config=true
        },
        sn_default_dia = {
            class="dropdown", name="sn_default_dia", value=config.c.presets[name].sn_default_dia,
            items=styles,
            x=1, y=4, config=true
        },
        sn_default_dia_ita = {
            class="dropdown", name="sn_default_dia_ita", value=config.c.presets[name].sn_default_dia_ita,
            items=styles,
            x=1, y=5, config=true
        },
        --
        existing_presets_label = {
            class="label", label=tr"Existing presets :",
            x=3, y=0
        },
        existing_presets = {
            class="dropdown", name="preset_sel", value=name,
            items=preset_names,
            x=4, y=0, width=1
        }
    }
    return diag
end


---@param line Line
---@param dash string
---@return Line
local function reset_line(line, dash)
    for _, d in ipairs(DASHES) do
        line.text = re.sub(line.text, d, "-")
    end
    line.text = re.sub(line.text, "- ", "- ") -- Espace insécable fine

    line.text = re.sub(line.text, "- ", dash .. " ")
    line.text = re.sub(line.text, "-{", dash .. "{")

    line.text = re.sub(line.text, "\\an8", "\\an7")
    line.text = re.sub(line.text, "\\an1", "\\an2")

    return line
end


---@param text string
---@param dash string
---@return boolean
local function is_dialogue(text, dash)
    local res = re.find(text, "^" .. dash .. "\\s") and (
        re.find(text, "\\\\N" .. dash .. "\\s") or re.find(text, "\\\\N " .. dash .. "\\s")
    )
    if res then
        return true
    else
        return false
    end
end


local dialoguisation = {
    ---@param subs Subs
    ---@param sel integer[]
    ---@return integer[], integer
    dialogue = function(subs, sel)
        local i, j = sel[1], sel[2]
        ---@type Line, Line
        local line_a, line_b = subs[i], subs[j]

        line_a.text = "- " .. line_a.text .. "\\N- " .. line_b.text
        line_a.end_time = line_b.end_time

        subs[i] = line_a
        -- subs[j] = nil
        subs.delete(j)
        return {i, i}, i
    end,

    ---@param sel integer[]
    ---@return boolean
    valid_dialogue = function(_, sel)
        return #sel == 2
    end,

    ---@param subs Subs
    ---@param sel integer[]
    undialogue = function(subs, sel)
        for _, i in ipairs(sel) do
            local line = subs[i]
            line = reset_line(line, "-")

            local line_clean = line.text:gsub("{[^}]+}", "")

            if is_dialogue(line_clean, "-") then
                local split_line = util.split(line.text:gsub('- ', ''), "\\N")

                line.margin_l = 0

                local end_time = line.end_time
                line.end_time = line.start_time + (line.end_time - line.start_time) / 2
                line.text = split_line[1]
                subs[i] = line

                line.start_time = line.end_time
                line.end_time = end_time
                line.text = split_line[2]
                subs.insert(i + 1, line)
            end
        end
    end
}


---@param subs Subs
---@param sel integer[]
---@param res table
local function baguette(subs, sel, res)
    ---@type integer|nil
    local xres, _, _, _ = aegisub.video_size()
    ---@type Meta, Styles
    local meta, styles = karaskel.collect_head(subs)

    video_x = meta.res_x or xres

    if not video_x then
        aegisub.log(0, tr"You need to set a script resolution or open a video!")
        aegisub.cancel()
    end

    for _, i in ipairs(sel) do
        local line = subs[i]

        -- Vérifications si CorrectPonc a déjà été utilisé
        if line.text:find("– ") then
            replace_space = true
        else
            replace_space = false
        end

        -- Réinitialisation des lignes
        line = reset_line(line, res.dash)

        local line_clean = line.text:gsub("{[^}]+}", "")

        -- Modifier si et seulement si la ligne commence par un tiret et contient un retour à la ligne suivi d'un 2e tiret
        if is_dialogue(line_clean, res.dash) then
            local split_line = util.split(line_clean, "\\N")
            if split_line[2] then
                if split_line[1]:len() >= split_line[2]:len() then
                    longest_line = split_line[1]
                else
                    longest_line = split_line[2]
                end

                ---@type integer
                local width, _, _, _ = aegisub.text_extents(styles[line.style], longest_line)
                line.margin_l = video_x / 2 - YUtils.math.round(width / 2, 0)

                local style = styles[line.style]
                if style.align == 8 then
                    line.text = "{\\an7}" .. line.text
                    if line.style == res.sn_default then
                        line.style = res.sn_default_dia
                    elseif line.style == res.sn_default_ita then
                        line.style = res.sn_default_dia_ita
                    end
                elseif res.sn_default_ita == res.sn_default and line.style == res.sn_default then
                    line.style = res.sn_default_dia
                elseif line.style == res.sn_default_ita or line.style == res.sn_default_dia_ita then
                    line.style = res.sn_default_dia_ita
                else
                    line.style = res.sn_default_dia
                end

                if replace_space then
                    line.text = line.text:gsub("– ", "– ")
                end

                subs[i] = line
            end
        end
    end
end

---@param subs Subs
---@param sel integer[]
---@param res table
local function unbaguette(subs, sel, res)
    for _, i in ipairs(sel) do
        ---@type Line
        local line = subs[i]
        line = reset_line(line, res.dash)

        local line_clean = line.text:gsub("{[^}]+}", "")

        if is_dialogue(line_clean, res.dash) then
            if line.style == res.sn_default_dia then
                line.style = res.sn_default
            elseif line.style == res.sn_default_dia_ita then
                line.style = res.sn_default_ita
            else
                line.style = res.sn_default
            end

            line.margin_l = 0

            subs[i] = line
        end
    end
end


---@param subs Subs
---@param sel integer[]
---@param name string|nil
local function prepare_baguette(subs, sel, _, name)
    name = name or "[Last Settings]"

    config:load()

    local styles = get_styles_names(subs)
    local diag = get_diag_baguette(name, styles)

    ---@type string, table
    local btn, res = aegisub.dialog.display(diag, {BUTTONS.OK, BUTTONS.LOAD, BUTTONS.CANCEL})

    if btn == BUTTONS.OK then
        if res.preset_sel ~= res.name then
            for key, value in pairs(config.c.presets[res.preset_sel]) do
                res[key] = value
            end
        end
        baguette(subs, sel, res)
        res.name = "[Last Settings]"
        config:update_presets(diag, res)
    elseif btn == BUTTONS.LOAD then
        prepare_baguette(subs, sel, nil, res.preset_sel)
    elseif btn == BUTTONS.CANCEL then
        aegisub.cancel()
    end
end


---@param subs Subs
---@param sel integer[]
---@param name string|nil
local function prepare_unbaguette(subs, sel, _, name)
    name = name or "[Last Settings]"

    config:load()

    local styles = get_styles_names(subs)
    local diag = get_diag_baguette(name, styles)

    ---@type string, table
    local btn, res = aegisub.dialog.display(diag, {BUTTONS.OK, BUTTONS.LOAD, BUTTONS.CANCEL})

    if btn == BUTTONS.OK then
        if res.preset_sel ~= res.name then
            for key, value in pairs(config.c.presets[res.preset_sel]) do
                res[key] = value
            end
        end
        unbaguette(subs, sel, res)
        res.name = "[Last Settings]"
        config:update_presets(diag, res)
    elseif btn == BUTTONS.LOAD then
        prepare_unbaguette(subs, sel, nil, res.preset_sel)
    elseif btn == BUTTONS.CANCEL then
        aegisub.cancel()
    end
end


---@param subs Subs
---@param name string|nil
local function configure(subs, _, _, name)
    name = name or "Default"

    -- local preset = config:getSectionHandler({"config", "presets", name}, DEFAULT_CONFIG.presets.Default)
    config:load()

    local styles = get_styles_names(subs)
    local diag = get_diag_configure(name, styles)

    ---@type string, table
    local btn, res = aegisub.dialog.display(diag, {BUTTONS.CREATE, BUTTONS.SAVE, BUTTONS.LOAD, BUTTONS.DELETE, BUTTONS.CANCEL})

    if btn == BUTTONS.CREATE then
        if not config.c.presets[res.name] then
            config.c.presets[res.name] = {}
            config:update_presets(diag, res)
            config:write()
            configure(subs, nil, nil, res.name)
        else
            local btnw, _ = user_warning(tr"Existing preset", tr[[Given preset name already exists.
Please choose another name]])
            if btnw == BUTTONS.CANCEL then
                aegisub.cancel()
            else
                configure(subs, nil, nil, "Default")
            end
        end
    elseif btn == BUTTONS.SAVE then
        if not DEFAULT_CONFIG.presets[res.name] and not DEFAULT_CONFIG.presets[res.preset_sel] then
            config.c.presets[name] = nil
            config.c.presets[res.name] = {}
            config:update_presets(diag, res)
            config:write()
            configure(subs, nil, nil, res.name)
        else
            configure(subs, nil, nil, res.preset_sel)
        end
    elseif btn == BUTTONS.LOAD then
        configure(subs, nil, nil, res.preset_sel)
    elseif btn == BUTTONS.DELETE then
        if not DEFAULT_CONFIG.presets[res.preset_sel] then
            config.c.presets[res.preset_sel] = nil
            config:write()
            -- local preset = config:getSectionHandler({"config", "presets", res.preset_sel}, DEFAULT_CONFIG)
            -- preset:delete()
        end
        configure(subs, nil, nil, nil)
    elseif btn == BUTTONS.CANCEL then
        aegisub.cancel()
    end
end


local macros = {
    {": Baguette :", tr"Find proper margin to alignate a dialogue subtitle to the left", prepare_baguette},
    {": Dialogue :", tr"Merge two subtitles to make a dialogue line", dialoguisation.dialogue, dialoguisation.valid_dialogue},
    {": Unbaguette :", tr"Reverse Baguette macro", prepare_unbaguette},
    {": Undialogue :", tr"Reverse Dialogue macro", dialoguisation.undialogue},
    {"Config", tr"Open configuration menu", configure},
}

depctrl:registerMacros(macros)
