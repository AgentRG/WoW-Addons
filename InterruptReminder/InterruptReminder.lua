local L

-- Table from which the add-on retrieves and stores all runtime data about the target, player, and more.
local IR_Table = {
    Mod_Version = function()
        return "Interrupt Reminder ".. L["VERSION"] ..": 2.4.3"
    end,
    -- WoW default action bar names
    ActionBars = { 'ActionButton', 'MultiBarBottomLeftButton', 'MultiBarBottomRightButton', 'MultiBarRightButton',
                   'MultiBarLeftButton', 'MultiBar7Button', 'MultiBar6Button', 'MultiBar5Button' },
    ElvUIActionBars = { 'ElvUI_Bar1Button', 'ElvUI_Bar2Button', 'ElvUI_Bar3Button', 'ElvUI_Bar4Button',
                        'ElvUI_Bar5Button', 'ElvUI_Bar6Button', 'ElvUI_Bar7Button', 'ElvUI_Bar8Button',
                        'ElvUI_Bar9Button', 'ElvUI_Bar10Button', 'ElvUI_Bar13Button', 'ElvUI_Bar14Button',
                        'ElvUI_Bar15Button' },
    -- Default interrupts for all classes. These spell's primarily goal is to interrupt (with sometimes a secondary
    --effect)
    InterruptSpells = {
        [6] = { 47528 }, --Death Knight
        [12] = { 183752 }, --Demon Hunter
        [11] = { 78675 }, --Druid
        [13] = { 351338 }, --Evoker
        [3] = { 147362, 187707 }, --Hunter
        [8] = { 2139 }, --Mage
        [10] = { 116705 }, --Monk
        [2] = { 96231 }, --Paladin
        [5] = { 15487 }, --Priest
        [4] = { 1766 }, --Rogue
        [7] = { 57994 }, --Shaman
        [9] = { 19647, 115781, 89766 }, --Warlock
        [1] = { 6552 } --Warrior
    },
    CCSpells = {
        [6] = { 47528 --[[Mind freeze]], 221562 --[[Asphyxiate]], 108194 --[[Asphyxiate]], 444010 --[[Death Charge]],
                207167 --[[Blinding Sleet]], 374049 --[[Suppression]], 206970 --[[Tightening Grasp]] },
        [12] = { 183752 --[[Disrupt]], 217832 --[[Imprison]], 191427 --[[Metamorphosis]], 211881 --[[Fel Eruption]],
                 202137 --[[Sigil of Silence]], 207684 --[[Sigil of Misery]], 179057 --[[Chaos Nova]],
                 452403 --[[Wave of Debilitation]]},
        [11] = { 78675 --[[Solar Beam]], 106839 --[[Skull Bash]], 132469 --[[Typhoon]], 2637 --[[Hibernate]],
                 33786 --[[Cyclone]], 22570 --[[Maim]], 99 --[[Incapacitating Roar]], 5211 --[[Mighty Bash]],
                 102359 --[[Mass Entanglement]] },
        [13] = { 351338 --[[Quell]], 360806 --[[Sleep Walk]] },
        [3] = { 147362 --[[Counter Shot]], 187707 --[[Muzzle]], 187650 --[[Freezing Trap]], 1513 --[[Scare Beast]],
                109248 --[[Binding Shot]], 19577 --[[Intimidation]], 186387 --[[Bursting Shot]],
                213691 --[[Scatter Shot]], 236776 --[[High Explosive Trap]], 462031 --[[Implosive Trap]],
                355589 --[[Wailing Arrow]]},
        [8] = { 2139 --[[Counterspell]], 118 --[[Polymorph (Sheep)]], 113724 --[[Ring of Frost]],
                157981 --[[Blast Wave]], 383121 --[[Mass Polymorph]], 31661 --[[Dragon's Breath]],
                157980 --[[Supernova]]},
        [10] = { 117952 --[[Crackling Jade Lightning]], 119381 --[[Leg Sweep]], 115078 --[[Paralysis]],
                 198898 --[[Song of Chi-Ji]], 116705 --[[Spear Hand Strike]]},
        [2] = { 853 --[[Hammer of Justice]], 31935 --[[Avenger's Shield]], 255937 --[[Wake of Ashes]],
                20066 --[[Repentance]], 115750 --[[Blinding Light]], 96231 --[[Rebuke]], 10326 --[[Turn Evil]]},
        [5] = { 64044 --[[Psychic Horror]], 8122 --[[Psychic Scream]], 88625 --[[Holy Word: Chastise]],
                34914 --[[Vampiric Touch]], 15487 --[[Silence]], 605 --[[Mind Control]],
                205364 --[[Dominate Mind]]},
        [4] = { 1833 --[[Cheap Shot]], 1766 --[[Kick]], 408 --[[Kidney Shot]], 2094 --[[Blind]], 1776 --[[Gouge]]},
        [7] = { 188389 --[[Flame Shock]], 197214 --[[Sundering]], 462620 --[[Earthquake (At target)]],
                61882 --[[Earthquake (Selected location]], 192058 --[[Capacitor Totem]], 305483 --[[Lightning Lasso]],
                51490 --[[Thunderstorm]], 57994 --[[Wind Shear]], 51514 --[[Hex]]},
        [9] = { 5782 --[[Fear]], 316099 --[[Unstable Affliction]], 1122 --[[Summon Infernal]], 30283 --[[Shadowfury]],
                5484 --[[Howl of Terror]], 6789 --[[Mortal Coil]], 19647 --[[Spell Lock]],
                115781 --[[Optical Blast]], 89766 --[[Axe Toss]]},
        [1] = { 6552 --[[Pummel]], 386071 --[[Disrupting Shout]], 385952 --[[Shield Charge]], 107570 --[[Storm Bolt]],
                46968 --[[Shockwave]], 5246 --[[Intimidating Shout]] }
    },
    RaceSpells = {
        [52] = { 368970 --[[Tail Swipe]], 357214 --[[Wing Buffet]] }, --Dracthyr (Alliance)
        [70] = { 368970 --[[Tail Swipe]], 357214 --[[Wing Buffet]] }, --Dracthyr (Horde)
        [32] = { 287712 --[[Haymaker]] }, --Kul Tiran
        [6] = { 20549 --[[War Stomp]] }, --Tauren
        [28] = { 255654 --[[Bull Rush]] }, --Highmountain Tauren
        [24] = { 107079 --[[Quaking Palm]] }, --Pandaren (Neutral)
        [25] = { 107079 --[[Quaking Palm]] }, --Pandaren (Alliance)
        [26] = { 107079 --[[Quaking Palm]] }, --Pandaren (Horde)
        [84] = {}, [3] = {}, [29] = {}, [35] = {}, [4] = {}, [34] = {}, [10] = {}, [33] = {}, [31] = {}, [2] = {},
        [27] = {}, [22] = {}, [11] = {}, [36] = {}, [9] = {}, [37] = {}, [30] = {}, [5] = {}, [8] = {}, [7] = {}
    },
    SpellCache = {},
    SaveHidden = true,
    BossInserts = 0,
    EndTime = nil,
    StartTime = nil,
    IsInterruptible = false,
    TargetCanBeStunned = false,
    CurrentTargetCanBeAttacked = false,
    SpecializationChanged = false,
    Panel = CreateFrame("Frame", "InterruptReminderSettings"),
    ButtonCache = {},
    GlowCache = nil,
    HideCache = nil,
    Sound = "Interface\\AddOns\\InterruptReminder\\Resources\\sound.mp3",
    SoundHandlerID = nil
}

local f = CreateFrame('Frame', 'InterruptReminder')
local PlayerClass = select(3, UnitClass('player'))
local PlayerRace = select(3, UnitRace('player'))
local CheckButtonFramePool

-- Library used to highlight spells. Without the library, the addon will encounter protected action access error
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local LibFramePool = LibStub("LibFramePool-1.0")

-- Local version of WoW global functions for slightly faster runtime access
local GetActionInfo = GetActionInfo
local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local tContains = tContains
local GetUnitName = GetUnitName
local UnitClassification = UnitClassification
local HasAction = HasAction
local C_Spell_GetSpellInfo = C_Spell.GetSpellInfo
local C_Spell_GetSpellName = C_Spell.GetSpellName
local C_Spell_GetSpellDescription = C_Spell.GetSpellDescription
local C_Spell_RequestLoadSpellData = C_Spell.RequestLoadSpellData
local GetTime = GetTime
local C_Timer = C_Timer
local C_EncounterJournal = C_EncounterJournal
local EJ_GetCreatureInfo = EJ_GetCreatureInfo
local UnitCanAttack = UnitCanAttack
local C_Map = C_Map
local GetInstanceInfo = GetInstanceInfo
local PlaySoundFile = PlaySoundFile
local IsPlayerSpell = IsPlayerSpell
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local CreateFrame = CreateFrame
local StopSound = StopSound

-- Local version of Lua global functions for slightly faster runtime access
local string = string
local table = table
local ipairs = ipairs
local pairs = pairs
local select = select

-- Patch 11.0 new settings initialization
IR_Table.Panel.name = "Interrupt Reminder"
local category = Settings.RegisterCanvasLayoutCategory(IR_Table.Panel, IR_Table.Panel.name, IR_Table.Panel.name);
category.ID = IR_Table.Panel.name

local function printInfo(text)
    print("|cff00ffffInfo (InterruptReminder): |cffffffff" .. text)
end

local function printWarning(text)
    print("|cffffff00Warning (InterruptReminder): |cffffffff" .. text)
end

local function printDebug(text)
    if InterruptReminder_Table.Debug == true then
        print("|cff00ff00Debug (InterruptReminder): |cffffffff" .. text)
    end
end

SLASH_INTERRUPT_REMINDER_HELP1 = "/irhelp"

--- Slash command for information help.
SlashCmdList['INTERRUPT_REMINDER_HELP'] = function()
    printInfo("To view more options, head to Options → AddOns → Interrupt Reminder or typing /irconfig. The" ..
            " mod works by highlighting your interrupt spell when the target is casting a spell that is interruptible.")
end

SLASH_INTERRUPT_REMINDER_OPTIONS1 = "/irconfig"
--- Slash command to open the options menu.
SlashCmdList['INTERRUPT_REMINDER_OPTIONS'] = function()
    Settings.OpenToCategory(category.ID)
end

--- Remove duplicates in a table and return the table
local function remove_duplicates_from_array(input_table)
    local currentCopy = input_table
    local hash = {}
    local res = {}

    for _, v in pairs(currentCopy) do
        if (not hash[v]) then
            res[#res + 1] = v
            hash[v] = true
        end
    end
    input_table = res
    return input_table
end

--- Remove duplicates in a table based on the key of a nested table
local function remove_duplicates_from_nested_table(input_table, key)
    local hash = {}
    local res = {}

    for _, nestedTable in ipairs(input_table) do
        local serialized = nestedTable[key]
        if not hash[serialized] then
            res[#res + 1] = nestedTable
            hash[serialized] = true
        end
    end
    input_table = res
    return input_table
end

local function merge_two_tables(table_one, table_two)
    for i = 1, #table_two do
        table_one[#table_one + 1] = table_two[i]
    end
    return table_one
end

--- Read the cached spells table and get the name/description for each spell inside of it
local function get_spellbook_spells()
    local spells = IR_Table.SpellCache
    local list = {}
    for _ = 1, #spells do
        local name = C_Spell_GetSpellName(spells[_])
        local desc = C_Spell_GetSpellDescription(spells[_])
        table.insert(list, { spellName = name, description = desc })
    end
    return list
end

local function hide_and_show_frames(hide, show)
    if hide ~= nil then
        for i = 1, #hide do
            if hide[i]:IsVisible() == true then
                hide[i]:Hide()
            end
        end
    end
    if show ~= nil then
        for i = 1, #show do
            if show[i]:IsVisible() == false then
                show[i]:Show()
            end
        end
    end
end

local function enable_and_disable_mouse_frames(disable, enable)
    if disable ~= nil then
        for i = 1, #disable do
            if disable[i]:IsMouseEnabled() == true then
                disable[i]:EnableMouse(false)
            end
        end
    end
    if enable ~= nil then
        for i = 1, #enable do
            if enable[i]:IsMouseEnabled() == false then
                enable[i]:EnableMouse(true)
            end
        end
    end
end

local function check_and_uncheck_frames(uncheck, check)
    if uncheck ~= nil then
        for i = 1, #uncheck do
            if uncheck[i]:GetChecked() == true then
                uncheck[i]:SetChecked(false)
            end
        end
    end
    if check ~= nil then
        for i = 1, #check do
            if check[i]:GetChecked() == false then
                check[i]:SetChecked(true)
            end
        end
    end
end

local function copy_table(origin)
    local copy

    if type(origin) == 'table' then
        copy = {}
        for k, v in pairs(origin) do
            copy[k] = v
        end
    else
        copy = origin
    end
    return copy
end

---Returns whenever the player is currently in an instance or in open world
local function is_in_instance()
    local _, instanceType = GetInstanceInfo()

    if instanceType ~= 'none' then
        printDebug("is_in_instance: Player is in instance.")
        return true
    else
        printDebug("is_in_instance: Player is not in instance.")
        return false
    end
end

---Read the encounter journal for the zone and grab all bosses + boss minions for that zone
local function get_bosses()
    local bestMapForPlayer = C_Map.GetBestMapForUnit('player')

    if bestMapForPlayer ~= nil then
        local encounters = C_EncounterJournal.GetEncountersOnMap(bestMapForPlayer) or {}
        IR_Table.BossInserts = 0
        for _, encounter in pairs(encounters) do
            for i = 1, 9 do
                local name = select(2, EJ_GetCreatureInfo(i, encounter.encounterID))
                if name then
                    InterruptReminder_Table.CurrentBossList[#InterruptReminder_Table.CurrentBossList + 1] = name
                    IR_Table.BossInserts = IR_Table.BossInserts + 1
                else
                    break
                end
            end
        end
    end
    printDebug("get_bosses: Boss list now consists of: " .. table.concat(InterruptReminder_Table, ","))
end

---Keep the boss list at the capacity of 30
local function truncate_boss_list()
    local inserts = IR_Table.BossInserts

    if #InterruptReminder_Table.CurrentBossList >= 30 then
        for _ = 1, inserts do
            table.remove(InterruptReminder_Table.CurrentBossList, 1)
        end
        printDebug("truncate_boss_list: Truncate boss list by " .. inserts .. ".")
    end
end

---Options frame
function IR_Table:CreateInterface(self)

    L = InterruptReminder_Localization

    local about_mod_hover = CreateFrame("Frame", nil, IR_Table.Panel)
    local about_mod_frame = CreateFrame("Frame", nil, IR_Table.Panel, 'BackdropTemplate')
    local save_button = CreateFrame("Button", nil, IR_Table.Panel, "UIPanelButtonTemplate")
    local cancel_button = CreateFrame("Button", nil, IR_Table.Panel, "UIPanelButtonTemplate")
    local refresh_button = CreateFrame("Button", nil, IR_Table.Panel, "UIPanelButtonTemplate")
    local debug_mode = CreateFrame("CheckButton", nil, IR_Table.Panel, "ChatConfigCheckButtonTemplate")
    local play_sound = CreateFrame("CheckButton", nil, IR_Table.Panel, "ChatConfigCheckButtonTemplate")
    local glow_texture_test = CreateFrame("Frame", nil, IR_Table.Panel)
    local proc_glow_checkbox = CreateFrame("CheckButton", nil, IR_Table.Panel, "ChatConfigCheckButtonTemplate")
    local glow_glow_checkbox = CreateFrame("CheckButton", nil, IR_Table.Panel, "ChatConfigCheckButtonTemplate")
    local pixel_glow_checkbox = CreateFrame("CheckButton", nil, IR_Table.Panel, "ChatConfigCheckButtonTemplate")
    local cast_glow_checkbox = CreateFrame("CheckButton", nil, IR_Table.Panel, "ChatConfigCheckButtonTemplate")
    local save_warning_text = IR_Table.Panel:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    local version_text = IR_Table.Panel:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    local r_slider = CreateFrame("Slider", "RSlider", IR_Table.Panel, "OptionsSliderTemplate")
    local g_slider = CreateFrame("Slider", "GSlider", IR_Table.Panel, "OptionsSliderTemplate")
    local b_slider = CreateFrame("Slider", "BSlider", IR_Table.Panel, "OptionsSliderTemplate")
    local a_slider = CreateFrame("Slider", "ASlider", IR_Table.Panel, "OptionsSliderTemplate")
    local n_slider = CreateFrame("Slider", "NSlider", IR_Table.Panel, "OptionsSliderTemplate")
    local t_slider = CreateFrame("Slider", "TSlider", IR_Table.Panel, "OptionsSliderTemplate")
    local f_slider = CreateFrame("Slider", "FSlider", IR_Table.Panel, "OptionsSliderTemplate")
    local s_slider = CreateFrame("Slider", "SSlider", IR_Table.Panel, "OptionsSliderTemplate")
    local about_mod_text = about_mod_frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    local horizontal_line_top = IR_Table.Panel:CreateLine()
    local horizontal_line_bottom = IR_Table.Panel:CreateLine()

    version_text:SetText(IR_Table.Mod_Version())
    version_text:SetPoint("BOTTOMLEFT", 8, 0)
    version_text:Show()

    --- Create 30 checkboxes to be used
    local function create_checkboxes(frame)
        CheckButtonFramePool = LibFramePool:CreateFramePool(30, "CheckButton", { nil, frame, "ChatConfigCheckButtonTemplate" })
        LibFramePool:SetOnClickScript(CheckButtonFramePool, function()
            if IR_Table.SaveHidden == true then
                save_warning_text:Show()
                IR_Table.SaveHidden = false
            end
        end)
        local x, y, r = 8, -50, 0

        for i = 1, 30 do
            if r == 3 then
                y = y - 20
                x = 8
                r = 0
            end
            CheckButtonFramePool[i].frame:SetPoint("TOPLEFT", x, y)
            x = x + 200
            r = r + 1
        end
    end

    local function load_slider_data(checkbox)
        local checkbox_table = {
            glow = "Glow",
            pixel = "Pixel",
            cast = "Cast"
        }
        local colors = InterruptReminder_Table.Styles[checkbox_table[checkbox]]['color']

        r_slider:SetValue(colors[1])
        g_slider:SetValue(colors[2])
        b_slider:SetValue(colors[3])
        a_slider:SetValue(colors[4])
        if checkbox == 'glow' or checkbox == 'cast' then
            f_slider:SetValue(InterruptReminder_Table.Styles[checkbox_table[checkbox]]['frequency'])
        end
        if checkbox == 'pixel' or checkbox == 'cast' then
            n_slider:SetValue(InterruptReminder_Table.Styles[checkbox_table[checkbox]]['N'])
        end
        if checkbox == 'pixel' then
            t_slider:SetValue(InterruptReminder_Table.Styles[checkbox_table[checkbox]]['thickness'])
        end
        if checkbox == 'cast' then
            s_slider:SetValue(InterruptReminder_Table.Styles[checkbox_table[checkbox]]['scale'])
        end
    end

    --- Create all glow checkboxes and fill in the relevant data for the them where appropriate, as well as the OnClick
    --- script
    local function generate_spell_glow_checkboxes()
        local checkboxes = { proc_glow_checkbox, glow_glow_checkbox, pixel_glow_checkbox, cast_glow_checkbox }
        local sliders = { r_slider, g_slider, b_slider, a_slider, n_slider, t_slider, f_slider, s_slider }
        local names = { L["PROC"], L["GLOW"], L["PIXEL"], L["CAST"] }
        local load_data = { 'glow', 'pixel', 'cast' }
        local x = 8

        for i = 1, 4 do
            local checkboxes_copy = copy_table(checkboxes)
            local show_sliders
            local hide_sliders

            checkboxes[i].Text:SetText(names[i])
            checkboxes[i]:SetPoint("TOPLEFT", x, -315)
            if i == 1 then
                hide_sliders = sliders
                show_sliders = nil
            elseif i == 2 then
                hide_sliders = { sliders[5], sliders[8], sliders[6] }
                show_sliders = { sliders[1], sliders[2], sliders[3], sliders[4], sliders[7] }
            elseif i == 3 then
                hide_sliders = { sliders[8], sliders[7] }
                show_sliders = { sliders[1], sliders[2], sliders[3], sliders[4], sliders[6], sliders[5] }
            else
                hide_sliders = { sliders[6] }
                show_sliders = { sliders[1], sliders[2], sliders[3], sliders[4], sliders[7], sliders[5], sliders[8] }
            end
            table.remove(checkboxes_copy, i)
            if i == 1 then
                checkboxes[i]:SetScript("OnClick", function()
                    enable_and_disable_mouse_frames({ checkboxes[i] }, checkboxes_copy)
                    check_and_uncheck_frames(checkboxes_copy, { checkboxes[i] })
                    hide_and_show_frames(hide_sliders, show_sliders)
                    IR_Table:Hide_Glow(glow_texture_test)
                    IR_Table.GlowCache = nil
                    IR_Table.HideCache = nil
                    InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles[names[i]]
                    IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle
                    IR_Table:Show_Glow(glow_texture_test)
                end)
            else
                checkboxes[i]:SetScript("OnClick", function()
                    enable_and_disable_mouse_frames({ checkboxes[i] }, checkboxes_copy)
                    check_and_uncheck_frames(checkboxes_copy, { checkboxes[i] })
                    hide_and_show_frames(hide_sliders, show_sliders)
                    IR_Table:Hide_Glow(glow_texture_test)
                    IR_Table.GlowCache = nil
                    IR_Table.HideCache = nil
                    InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles[names[i]]
                    IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle
                    load_slider_data(load_data[i - 1])
                    if IR_Table.SelectedGlow.name == 'Glow' then
                        f_slider:SetPoint("TOPLEFT", 8, select(5, a_slider:GetPoint()) - 30)
                    elseif IR_Table.SelectedGlow.name == 'Cast' then
                        f_slider:SetPoint("TOPLEFT", 8, select(5, s_slider:GetPoint()) - 30)
                    end
                    IR_Table:Show_Glow(glow_texture_test)
                end)
            end
            x = x + 180
        end
    end

    --- Create all sliders and fill in the relevant data for the them where appropriate, as well as the OnMouseUp script
    local function generate_sliders()
        local sliders = { r_slider, g_slider, b_slider, a_slider, n_slider, t_slider, f_slider, s_slider }
        local text = { L["RED"], L["GREEN"], L["BLUE"], L["ALPHA"], L["LINES"], L["THICKNESS"], L["FREQUENCY"], L["SCALE"] }
        local global_text = { "RSlider", "GSlider", "BSlider", "ASlider", "NSlider", "TSlider", "FSlider", "SSlider" }
        local y = -367
        local scripts = { function()
            local currentGlow = IR_Table.SelectedGlow.name
            enable_and_disable_mouse_frames(sliders, nil)
            InterruptReminder_Table.Styles[currentGlow]['color'] = {
                tonumber(string.format("%.2f", r_slider:GetValue())),
                tonumber(string.format("%.2f", g_slider:GetValue())),
                tonumber(string.format("%.2f", b_slider:GetValue())),
                tonumber(string.format("%.2f", a_slider:GetValue())),
            }
            InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles[currentGlow]
            IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle
            IR_Table:Hide_Glow(glow_texture_test)
            IR_Table:Show_Glow(glow_texture_test)
            enable_and_disable_mouse_frames(nil, sliders)
        end, function()
            local currentGlow = IR_Table.SelectedGlow.name
            enable_and_disable_mouse_frames(sliders, nil)
            InterruptReminder_Table.Styles[currentGlow]['N'] = n_slider:GetValue()
            InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles[currentGlow]
            IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle
            IR_Table:Hide_Glow(glow_texture_test)
            IR_Table:Show_Glow(glow_texture_test)
            enable_and_disable_mouse_frames(nil, sliders)
        end, function()
            local currentGlow = IR_Table.SelectedGlow.name
            enable_and_disable_mouse_frames(sliders, nil)
            InterruptReminder_Table.Styles[currentGlow]['thickness'] = t_slider:GetValue()
            InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles[currentGlow]
            IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle
            IR_Table:Hide_Glow(glow_texture_test)
            IR_Table:Show_Glow(glow_texture_test)
            enable_and_disable_mouse_frames(nil, sliders)
        end, function()
            local currentGlow = IR_Table.SelectedGlow.name
            enable_and_disable_mouse_frames(sliders, nil)
            InterruptReminder_Table.Styles[currentGlow]['frequency'] = f_slider:GetValue()
            InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles[currentGlow]
            IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle
            IR_Table:Hide_Glow(glow_texture_test)
            IR_Table:Show_Glow(glow_texture_test)
            enable_and_disable_mouse_frames(nil, sliders)
        end, function()
            local currentGlow = IR_Table.SelectedGlow.name
            enable_and_disable_mouse_frames(sliders, nil)
            InterruptReminder_Table.Styles[currentGlow]['scale'] = s_slider:GetValue()
            InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles[currentGlow]
            IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle
            IR_Table:Hide_Glow(glow_texture_test)
            IR_Table:Show_Glow(glow_texture_test)
            enable_and_disable_mouse_frames(nil, sliders)
        end }

        for i = 1, #sliders do
            local glow = IR_Table.SelectedGlow

            sliders[i].text = _G[global_text[i] .. "Text"]
            sliders[i].text:SetText(text[i])
            sliders[i].textLow = _G[global_text[i] .. "Low"]
            sliders[i].textHigh = _G[global_text[i] .. "High"]
            sliders[i]:SetObeyStepOnDrag(true)
            sliders[i]:SetOrientation('HORIZONTAL')
            sliders[i]:SetWidth(400)
            sliders[i]:SetHeight(20)
            sliders[i]:SetPoint("TOPLEFT", 8, y)
            --- RGBA SLIDERS
            if i <= 4 then
                sliders[i]:SetMinMaxValues(0, 1)
                sliders[i]:SetValueStep(0.01)
                if glow.name == 'Pixel' or glow.name == 'Cast' or glow.name == 'Glow' then
                    sliders[i]:SetValue(glow.color[i])
                else
                    sliders[i]:Hide()
                end
                sliders[i].textLow:SetText(0.0)
                sliders[i].textHigh:SetText(1.0)
                sliders[i]:SetScript("OnMouseUp", scripts[1])
                --- N SLIDER
            elseif i == 5 then
                sliders[i]:SetMinMaxValues(1, 20)
                sliders[i]:SetValueStep(1)
                if glow.name == 'Pixel' or glow.name == 'Cast' then
                    sliders[i]:SetValue(glow.N)
                else
                    sliders[i]:Hide()
                end
                sliders[i].textLow:SetText(1)
                sliders[i].textHigh:SetText(20)
                sliders[i]:SetScript("OnMouseUp", scripts[2])
                --- T SLIDER
            elseif i == 6 then
                sliders[i]:SetMinMaxValues(1, 10)
                sliders[i]:SetValueStep(1)
                if glow.name == 'Pixel' then
                    sliders[i]:SetValue(glow.thickness)
                else
                    sliders[i]:Hide()
                end
                sliders[i].textLow:SetText(1)
                sliders[i].textHigh:SetText(10)
                sliders[i]:SetScript("OnMouseUp", scripts[3])
                --- F SLIDER
            elseif i == 7 then
                sliders[i]:SetMinMaxValues(0.01, 1)
                sliders[i]:SetValueStep(0.01)
                if glow.name == 'Cast' or glow.name == 'Glow' then
                    sliders[i]:SetValue(glow.frequency)
                else
                    sliders[i]:Hide()
                end
                if glow.name == 'Glow' then
                    sliders[i]:SetPoint("TOPLEFT", 8, select(5, a_slider:GetPoint()) - 30)
                end
                sliders[i].textLow:SetText(0.01)
                sliders[i].textHigh:SetText(1.0)
                sliders[i]:SetScript("OnMouseUp", scripts[4])
                --- S SLIDER
            else
                sliders[i]:SetMinMaxValues(1, 5)
                sliders[i]:SetValueStep(1)
                if glow.name == 'Cast' then
                    sliders[i]:SetValue(glow.scale)
                else
                    sliders[i]:Hide()
                end
                sliders[i]:SetPoint("TOPLEFT", 8, select(5, n_slider:GetPoint()) - 30)
                sliders[i].textLow:SetText(1)
                sliders[i].textHigh:SetText(5)
                sliders[i]:SetScript("OnMouseUp", scripts[5])
            end
            y = y - 30
        end
    end

    --- Set the name/description of checkbox at position i to that of that spell. If the spell is present in
    --- SelectedSpells, set the checkbox to checked status. Hide all other checkboxes.
    local function pre_fill_checkboxes()
        local spells = self.Spells
        local checkedSpells = self.SelectedSpells

        for i = 1, #spells do
            local spell_name = spells[i].spellName
            local spell_description = spells[i].description
            local checkbox = CheckButtonFramePool[i].frame
            checkbox.Text:SetText(spell_name)
            checkbox.tooltip = spell_description
            if tContains(checkedSpells, spell_name) then
                checkbox:SetChecked(true)
            else
                checkbox:SetChecked(false)
            end
            checkbox:Show()
        end
    end

    --- For every spell inside Spells, set the name/description of checkbox at position i to that of that spell. If the
    --- spell is present in SelectedSpells, set the checkbox to checked status. Hide all other checkboxes.
    local function generate_spell_checkboxes()
        local selectedSpells = self.SelectedSpells
        local spells = self.Spells
        local endIteration = #spells + 1

        for i = 1, #spells do
            local checkbox = CheckButtonFramePool[i].frame
            local spell_name = spells[i].spellName
            local spell_description = spells[i].description
            checkbox.Text:SetText(spell_name)
            checkbox.tooltip = spell_description
            if tContains(selectedSpells, spell_name) then
                checkbox:SetChecked(true)
            else
                checkbox:SetChecked(false)
                checkbox:SetChecked(false)
            end
            checkbox:Show()
        end
        for i = endIteration, 30 do
            local checkbox = CheckButtonFramePool[i].frame
            checkbox:Hide()
            checkbox:SetChecked(false)
        end
    end

    --- Create all header checkboxes and fill in the relevant data for the them where appropriate, as well as the
    --- OnClick script
    local function generate_header_checkboxes()
        local checkboxes = { debug_mode, play_sound }
        local text = { L['ENABLE_DEBUGGER'], L['ENABLE_AUDIO_CUE'] }
        local tooltip = { 'Enable the debugger for event handling and other functions.', 'Play a sound when the target is casting an interruptible spell.' }
        local x = 8
        local scripts = { function(checkbox)
            if checkbox:GetChecked() == true then
                self.Debug = true
                printInfo("Debugger has been enabled.")
            else
                self.Debug = false
                printInfo("Debugger has been disabled.")
            end
        end, function(checkbox)
            if checkbox:GetChecked() == true then
                self.PlaySound = true
            else
                self.PlaySound = false
            end
        end }

        for i = 1, #checkboxes do
            checkboxes[i].Text:SetText(text[i])
            checkboxes[i].tooltip = tooltip[i]
            checkboxes[i]:SetPoint("TOPLEFT", x, -10)
            if i == 1 then
                if self.Debug == true then
                    checkboxes[i]:SetChecked(true)
                else
                    checkboxes[i]:SetChecked(false)
                end
            elseif i == 2 then
                checkboxes[i]:SetChecked(true)
            else
                checkboxes[i]:SetChecked(false)
            end
            checkboxes[i]:SetScript("OnClick", scripts[i])
            x = x + 240
        end
    end

    --- Wipe SelectedSpells and iterate through each checkbox. If checked, save spell into SelectedSpells.
    local function save_spells_into_table()
        self.SelectedSpells = {}
        local copy = {}

        for i = 1, 30 do
            local checkbox = CheckButtonFramePool[i].frame
            local check_status = checkbox:GetChecked()
            if check_status == true then
                copy[#copy + 1] = checkbox.Text:GetText()
            end
        end
        if #copy == 0 then
            printWarning("No interrupt or crowd control spells were selected!")
        end
        self.SelectedSpells = copy
        IR_Table.SelectedSpells = copy
    end

    --- Create all spell-related buttons and fill in the relevant data for the them where appropriate, as well as the OnClick script
    local function generate_buttons()
        local buttons = { save_button, cancel_button }
        local text = { L['SAVE_SPELLS'], L['CANCEL'] }
        local x = -50
        local scripts = { function()
            enable_and_disable_mouse_frames(buttons, nil)
            PlaySoundFile(567407, "SFX")
            save_spells_into_table()
            if IR_Table.SaveHidden == false then
                save_warning_text:Hide()
                IR_Table.SaveHidden = true
            end
            enable_and_disable_mouse_frames(nil, buttons)
        end, function()
            enable_and_disable_mouse_frames(buttons, nil)
            PlaySoundFile(567407, "SFX")
            pre_fill_checkboxes()
            if IR_Table.SaveHidden == false then
                save_warning_text:Hide()
                IR_Table.SaveHidden = true
            end
            enable_and_disable_mouse_frames(nil, buttons)
        end }

        for i = 1, #buttons do
            buttons[i]:Show()
            buttons[i]:SetText(text[i])
            buttons[i]:SetWidth(100)
            buttons[i]:SetPoint("BOTTOM", x, 300)
            buttons[i]:SetScript("OnClick", scripts[i])
            x = x + 100
        end
    end

    --- If one of the checkboxes were checked but changes were not saved, this warning will appear.
    save_warning_text:Hide()
    save_warning_text:SetText(L["UNSAVED_CHANGES"])
    save_warning_text:SetTextColor(1.0, 0, 0, 1)
    save_warning_text:SetPoint("BOTTOM", 0, 325)

    about_mod_hover:SetPoint("BOTTOMRIGHT", 0, 0)
    about_mod_hover:SetSize(25, 25)
    about_mod_hover:EnableMouseMotion(true)
    about_mod_hover.tex = about_mod_hover:CreateTexture()
    about_mod_hover.tex:SetAllPoints(about_mod_hover)
    about_mod_hover.tex:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
    about_mod_hover:SetScript("OnEnter", function()
        hide_and_show_frames({ save_button, refresh_button, cancel_button, proc_glow_checkbox,
                               glow_glow_checkbox, pixel_glow_checkbox, cast_glow_checkbox, glow_texture_test,
                               r_slider, g_slider, b_slider, a_slider, horizontal_line_bottom },
                { about_mod_frame })
    end)
    about_mod_hover:SetScript("OnLeave", function()
        if IR_Table.SelectedGlow.name == 'Proc' then
            hide_and_show_frames({ about_mod_frame }, { save_button, refresh_button, cancel_button,
                                                        proc_glow_checkbox, glow_glow_checkbox, pixel_glow_checkbox,
                                                        cast_glow_checkbox, glow_texture_test, horizontal_line_bottom })
        else
            hide_and_show_frames({ about_mod_frame }, { save_button, refresh_button, cancel_button,
                                                        proc_glow_checkbox, glow_glow_checkbox, pixel_glow_checkbox,
                                                        cast_glow_checkbox, glow_texture_test, r_slider, b_slider,
                                                        g_slider, a_slider, horizontal_line_bottom })
        end
    end)

    about_mod_frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    about_mod_frame:SetBackdropColor(0, 0, 0, 1)
    about_mod_frame:SetSize(675, 300)
    about_mod_frame:SetMovable(false)
    about_mod_frame:SetResizable(false)
    about_mod_frame:SetPoint("CENTER", 0, -28)
    about_mod_frame:Hide()
    about_mod_text:SetTextColor(1.0, 1.0, 1.0, 0.8)
    about_mod_text:SetPoint("CENTER", 0, -15)
    about_mod_text:SetSize(650, 290)
    about_mod_text:SetJustifyH("LEFT")
    about_mod_text:SetJustifyV("TOP");
    about_mod_text:SetText(L["ABOUT_MOD"])
    about_mod_text:SetWordWrap(true)

    --- Pre-run certain scripts
    IR_Table:GetAllCrowdControlSpells(self)
    create_checkboxes(IR_Table.Panel)
    generate_spell_checkboxes()
    pre_fill_checkboxes()

    --- Horizontal line at the top
    horizontal_line_top:SetColorTexture(1, 1, 1, 0.5)
    horizontal_line_top:SetThickness(1)
    horizontal_line_top:SetStartPoint("TOPLEFT", 12, -40)
    horizontal_line_top:SetEndPoint("TOPRIGHT", -12, -40)

    --- Horizontal line at the bottom
    horizontal_line_bottom:SetColorTexture(1, 1, 1, 0.5)
    horizontal_line_bottom:SetThickness(1)
    horizontal_line_bottom:SetStartPoint("BOTTOMLEFT", 12, 295)
    horizontal_line_bottom:SetEndPoint("BOTTOMRIGHT", -12, 295)

    --- Texture where glow is tested
    glow_texture_test:SetPoint("TOPLEFT", 548, -345)
    glow_texture_test:SetSize(50, 50)
    glow_texture_test.tex = glow_texture_test:CreateTexture()
    glow_texture_test.tex:SetAllPoints(glow_texture_test)
    glow_texture_test.tex:SetTexture("Interface\\ICONS\\Ability_DemonHunter_ConsumeMagic")

    generate_buttons()
    generate_header_checkboxes()
    IR_Table:Show_Glow(glow_texture_test)
    generate_spell_glow_checkboxes()
    generate_sliders()

    if IR_Table.SelectedGlow.name == 'Proc' then
        proc_glow_checkbox:SetChecked(true)
        proc_glow_checkbox:EnableMouse(false)
    elseif IR_Table.SelectedGlow.name == 'Pixel' then
        pixel_glow_checkbox:SetChecked(true)
        pixel_glow_checkbox:EnableMouse(false)
    elseif IR_Table.SelectedGlow.name == 'Cast' then
        cast_glow_checkbox:SetChecked(true)
        cast_glow_checkbox:EnableMouse(false)
    else
        glow_glow_checkbox:SetChecked(true)
        glow_glow_checkbox:EnableMouse(false)
    end

    Settings.RegisterAddOnCategory(category);
end

function InterruptReminder_OnAddonCompartmentClick()
    Settings.OpenToCategory(category.ID)
end

function IR_Table:GetAllCrowdControlSpells(self)
    self.Spells = {}
    self.Spells = get_spellbook_spells()
end

---Algorithm that determines whether the currently selected target is a boss and reassigns IR_Table.TargetCanBeStunned
--- as either true or false depending on the circumstances. Since there is no actual API call to determine whether a
--- target can be stunned, we need to make use of the information we do have access to. For example, units that have
--- a frame around them more likely than not cannot be stunned. When in dungeons, this is troublesome since normal mobs
--- also have a frame around them. To get around that, we are reading InterruptReminder_Table.CurrentBossList to
--- determine whether the current target is a boss or a minion of a boss in that dungeon, and therefore cannot be
--- stunned.
function IR_Table:IsTargetABoss(self)
    local bosses = self.CurrentBossList
    --[[ There's a small bug here that I couldn't find a fix for. If the target switched to is nothing, it will still
         pull the target information from the previous target, even though GetUnitName should return nil at that point.
         Luckily, thin air cannot cast spells, so the rest of the addon will still function as intended. ]]

    local targetName = GetUnitName('target', false)

    -- Check to see if the user is currently in an instance
    if is_in_instance() == true then

        -- Safety measure in case the dungeon boss names has not been defined as either list of bosses or empty
        if bosses == nil then
            IR_Table:Handle_ZoneChanged(self)
            bosses = self.CurrentBossList
        end

        -- Otherwise, check whether the target is a boss. If he's a boss, he's not stunnable.
        if tContains(bosses, targetName) then
            IR_Table.TargetCanBeStunned = false
            printDebug("IsTargetABoss: Target is in boss list.")
        else
            IR_Table.TargetCanBeStunned = true
            printDebug("IsTargetABoss: Target is not in boss list.")
        end
    else
        -- Otherwise, assume we're in the open world
        local enemyRarity = UnitClassification('target')
        -- In WoW, units that are world bosses, elites and rare elites are more likely than not stun immune.
        if enemyRarity == 'worldboss' or enemyRarity == 'elite' or enemyRarity == 'rareelite' then
            IR_Table.TargetCanBeStunned = false
            printDebug("IsTargetABoss: Target has a frame, therefore cannot be stunned.")
        else
            printDebug("IsTargetABoss: Target has no frame, therefore can be stunned.")
            IR_Table.TargetCanBeStunned = true
        end
    end
end

---Return the button location of the spell from the cached ButtonCache. If there is no cache for the button or the
--- slot has been updated, then find the location of the button and save it to ButtonCache.
function IR_Table:FindSpellLocation(spell)
    spell = string.lower(spell)

    local function find_button()
        local actionBars

        if C_AddOns_IsAddOnLoaded("ElvUI") == true then
            actionBars = IR_Table.ElvUIActionBars
        else
            actionBars = IR_Table.ActionBars
        end
        for _, barName in ipairs(actionBars) do
            for i = 1, 12 do
                local button = _G[barName .. i]
                local slot = button:GetAttribute('action') or button:GetPagedID()

                if HasAction(slot) then
                    local actionType, id, _, actionName = GetActionInfo(slot)

                    if actionType == 'spell' then
                        local spellInfo = C_Spell_GetSpellInfo(id)
                        actionName = spellInfo.name
                    end

                    if actionName then
                        if string.lower(actionName) == spell then
                            IR_Table.ButtonCache[spell] = { button = button, slot = slot }
                        end
                    end
                end
            end
        end
    end

    local function is_button_still_spell()
        local _, _, _, actionName = GetActionInfo(IR_Table.ButtonCache[spell].slot)

        if actionName ~= spell then
            IR_Table.ButtonCache[spell] = nil
            find_button()
        end
    end
    if IR_Table.ButtonCache[spell] == nil then
        find_button()
    else
        is_button_still_spell()
    end
    if IR_Table.ButtonCache[spell] ~= nil then
        return IR_Table.ButtonCache[spell].button
    else
        return nil
    end
end

---Retrieves the cooldown status of a list of spells and their corresponding location on the action bar(s).
---Returns two tables: one for spells ready to be cast and another for spells that are still on cool down.
function IR_Table:GetSpellCooldowns(spells_table, interrupt_only)

    if interrupt_only == true then
        spells_table = {}
        spells_table = IR_Table.InterruptSpells[PlayerClass]
    elseif interrupt_only == false then
        spells_table = spells_table
    end

    local readyToCast, stillOnCooldown = {}, {}

    if spells_table ~= nil then
        for i = 1, #spells_table do
            local spell = spells_table[i]
            local spellInfo = C_Spell_GetSpellInfo(spell)
            if spellInfo ~= nil then
                local spellID = spellInfo.spellID
                if type(spellID) == 'number' then
                    local isInSpellbook = IsPlayerSpell(spellID)
                    if isInSpellbook then
                        local spellCooldownInfo = C_Spell_GetSpellCooldown(spellID)
                        local duration = spellCooldownInfo.duration
                        local start = spellCooldownInfo.startTime
                        if duration == 0 or duration <= 1.5 --[[Global Cooldown]] then
                            table.insert(readyToCast, { ['location'] = IR_Table:FindSpellLocation(spell) })
                        else
                            -- Add a 0.01 overhead to ensure the spell gets highlighted after it is off cooldown
                            local calculatedTimeRemaining = (start + duration - GetTime()) + 0.01
                            -- Safety check to ensure we don't save a negative number by mistake
                            if calculatedTimeRemaining > 0 then
                                -- Check that the spell will be ready before the spellcast from the target ends
                                if IR_Table.EndTime ~= nil and IR_Table.EndTime < ((start + duration) * 1000) then
                                    table.insert(stillOnCooldown, { ['cooldown'] = calculatedTimeRemaining, ['location'] = IR_Table:FindSpellLocation(spell) })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    printDebug("C_Spell_GetSpellCooldown: " .. #readyToCast .. " spells ready to cast. " .. #stillOnCooldown ..
            " spells are still on cooldown.")
    return readyToCast, stillOnCooldown
end

---Checks if the target is casting or channeling a spell and set IR_Table.* values.
function IR_Table:IsTargetCastingInterruptibleSpell()
    local name, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo('target')

    if name == nil then
        name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo('target')
    end
    -- Safety measure to make sure a nil is not returned somehow
    if name ~= nil then
        if notInterruptible == false then
            IR_Table.EndTime = endTime
            IR_Table.StartTime = startTime
            IR_Table.IsInterruptible = true
            printDebug("IsTargetCastingInterruptibleSpell: Spell " .. name .. " is interruptible.")
        else
            IR_Table.EndTime = endTime
            IR_Table.StartTime = startTime
            IR_Table.IsInterruptible = false
            printDebug("IsTargetCastingInterruptibleSpell: Spell " .. name .. "  is not interruptible.")
        end
    else
        IR_Table.EndTime = nil
        IR_Table.StartTime = nil
        IR_Table.IsInterruptible = false
        printDebug("IsTargetCastingInterruptibleSpell: Target is not casting or channeling anything.")
    end
end

function IR_Table:Show_Glow(frame)
    if IR_Table.GlowCache == nil then
        local highlights = {
            ['Proc'] = function(frame_loc)
                LibCustomGlow.ProcGlow_Start(frame_loc)
            end,
            ['Pixel'] = function(frame_loc)
                LibCustomGlow.PixelGlow_Start(frame_loc, IR_Table.SelectedGlow.color,
                        IR_Table.SelectedGlow.N, nil, nil, IR_Table.SelectedGlow.thickness, nil, nil,
                        IR_Table.SelectedGlow.border)
            end,
            ['Cast'] = function(frame_loc)
                LibCustomGlow.AutoCastGlow_Start(frame_loc, IR_Table.SelectedGlow.color,
                        IR_Table.SelectedGlow.N, IR_Table.SelectedGlow.frequency, IR_Table.SelectedGlow.scale)
            end,
            ['Glow'] = function(frame_loc)
                LibCustomGlow.ButtonGlow_Start(frame_loc, IR_Table.SelectedGlow.color, IR_Table.SelectedGlow.frequency)
            end
        }
        local name = IR_Table.SelectedGlow.name
        IR_Table.GlowCache = highlights[name]
    end
    IR_Table.GlowCache(frame)
end

function IR_Table:Hide_Glow(frame)
    if IR_Table.HideCache == nil then
        local highlights = {
            ['Proc'] = function(frame_loc)
                LibCustomGlow.ProcGlow_Stop(frame_loc)
            end,
            ['Pixel'] = function(frame_loc)
                LibCustomGlow.PixelGlow_Stop(frame_loc)
            end,
            ['Cast'] = function(frame_loc)
                LibCustomGlow.AutoCastGlow_Stop(frame_loc)
            end,
            ['Glow'] = function(frame_loc)
                LibCustomGlow.ButtonGlow_Stop(frame_loc)
            end
        }
        local name = IR_Table.SelectedGlow.name
        IR_Table.HideCache = highlights[name]
    end
    IR_Table.HideCache(frame)
end

---Handles the unhighlight of spells.
function IR_Table:Handle_TargetStoppedCasting(self)
    if InterruptReminder_Table.PlaySound then
        if IR_Table.SoundHandlerID ~= nil and type(IR_Table.SoundHandlerID) == 'number' then
            StopSound(IR_Table.SoundHandlerID)
            IR_Table.SoundHandlerID = nil
        end
    end
    if self.SelectedSpells ~= nil then
        for i = 1, #self.SelectedSpells do
            local spellLocation = IR_Table:FindSpellLocation(self.SelectedSpells[i])
            if spellLocation ~= nil then
                printDebug("Handle_TargetStoppedCasting: Hide spell " .. self.SelectedSpells[i] ..
                        " highlight at location " .. tostring(spellLocation) .. ".")
                self:Hide_Glow(spellLocation)
            else
                printDebug("Handle_TargetStoppedCasting: Spell " .. self.SelectedSpells[i] ..
                        " is not in the action bars.")
            end
        end
    end
end

---Handles the logic for highlighting interruptible spells on the current target (whether target can be interrupted is
--- deduced during PLAYER_TARGET_CHANGED event).
---In case a spell is not in cooldown, highlight the spell at its action bar location.
---In case a spell is in cooldown, use C_Timer.After to check whether by the time it is off cooldown, that target
--- can still be interrupted, in which case it will highlight the ability at its location.
function IR_Table:Handle_CurrentTargetSpellCasting(self)
    self:IsTargetCastingInterruptibleSpell()

    if self.IsInterruptible == true and self.CurrentTargetCanBeAttacked == true then
        if self.TargetCanBeStunned == true then
            -- Can be true only when Crowd Control spell tracking is enabled
            local readyToCast, stillOnCooldown = self:GetSpellCooldowns(self.SelectedSpells, false)

            for i = 1, #readyToCast do
                if readyToCast[i].location ~= nil then
                    printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " ..
                            tostring(readyToCast[i].location) .. ".")
                    self:Show_Glow(readyToCast[i].location)
                    if InterruptReminder_Table.PlaySound and IR_Table.SoundHandlerID == nil then
                        IR_Table.SoundHandlerID = select(2, PlaySoundFile(IR_Table.Sound, "SFX"))
                    end
                end
            end
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    self:IsTargetCastingInterruptibleSpell()
                    if self.IsInterruptible == true and self.CurrentTargetCanBeAttacked then
                        if stillOnCooldown[i].location ~= nil then
                            printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " ..
                                    tostring(stillOnCooldown[i].location) .. ".")
                            self:Show_Glow(stillOnCooldown[i].location)
                            if InterruptReminder_Table.PlaySound and IR_Table.SoundHandlerID == nil then
                                IR_Table.SoundHandlerID = select(2, PlaySoundFile(IR_Table.Sound, "SFX"))
                            end
                        end
                    end
                end)
            end
        else
            local readyToCast, stillOnCooldown = self:GetSpellCooldowns(self.SelectedSpells, true)

            for i = 1, #readyToCast do
                if readyToCast[i].location ~= nil then
                    printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " ..
                            tostring(readyToCast[i].location) .. ".")
                    self:Show_Glow(readyToCast[i].location)
                    if InterruptReminder_Table.PlaySound and IR_Table.SoundHandlerID == nil then
                        IR_Table.SoundHandlerID = select(2, PlaySoundFile(IR_Table.Sound, "SFX"))
                    end
                end
            end
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    self:IsTargetCastingInterruptibleSpell()
                    if self.IsInterruptible == true and self.CurrentTargetCanBeAttacked then
                        if stillOnCooldown[i].location ~= nil then
                            printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " ..
                                    tostring(stillOnCooldown[i].location) .. ".")
                            self:Show_Glow(stillOnCooldown[i].location)
                            if InterruptReminder_Table.PlaySound and IR_Table.SoundHandlerID == nil then
                                IR_Table.SoundHandlerID = select(2, PlaySoundFile(IR_Table.Sound, "SFX"))
                            end
                        end
                    end
                end)
            end
        end
    end
end

---Each time the player's zone changes, determine whether the player is currently in the dungeon. If the player is in
--- a dungeon, use C_EncounterJournal.GetEncountersOnMap to grab all the boss fights in the current zone. Each encounter
--- can have a maximum of 9 unit types present.
function IR_Table:Handle_ZoneChanged(self)
    get_bosses()
    self.CurrentBossList = remove_duplicates_from_array(self.CurrentBossList)
    truncate_boss_list()
end

---Handles the logic for when the player switches his targets. Unhighlight all spells and check whether the new target
--- is in the process of spell casting already and act accordingly.
function IR_Table:Handle_PlayerSwitchingTargets(self)
    -- If the interrupt spells were already highlighted, unhighlight them all.
    IR_Table:Handle_TargetStoppedCasting(self)

    -- Check if the target is valid to attack by the player (e.g. not a friendly player, friendly npc, a pet...)
    if UnitCanAttack('player', 'target') then
        IR_Table:IsTargetABoss(InterruptReminder_Table)
        self.CurrentTargetCanBeAttacked = true
        printDebug("Handle_PlayerSwitchingTargets: Unit can be attacked.")
        -- Determine whether the target can be stunned
        -- When the player gains his initial target or switches to a target, check whether the target is casting an
        -- interruptible spell, and proceed to handle the highlighting of spells in the action bars
        IR_Table:Handle_CurrentTargetSpellCasting(self)
    else
        printDebug("Handle_PlayerSwitchingTargets: Unit cannot be attacked.")
        self.CurrentTargetCanBeAttacked = false
    end
end

---Handles the logic for when the player initially logs in or does a /reload
function IR_Table:Handle_PlayerLogin()

    local spells = merge_two_tables(IR_Table.CCSpells[PlayerClass], IR_Table.RaceSpells[PlayerRace])
    for _ = 1, #spells do
        C_Spell_RequestLoadSpellData(spells[_])
    end

    if InterruptReminder_FirstLaunch == nil then
        InterruptReminder_FirstLaunch = true
        printInfo('First time loading the add-on? Type /irhelp for more information.')
    end
    if InterruptReminder_Table == nil then
        InterruptReminder_Table = {}
    end
    if InterruptReminder_Table.Spells == nil then
        InterruptReminder_Table.Spells = {}
    end
    if InterruptReminder_Table.SelectedSpells == nil then
        InterruptReminder_Table.SelectedSpells = IR_Table.InterruptSpells[PlayerClass]
    end
    if InterruptReminder_Table.CurrentBossList == nil then
        InterruptReminder_Table.CurrentBossList = {}
    end
    if InterruptReminder_Table.Debug == nil then
        InterruptReminder_Table.Debug = false
    end
    if InterruptReminder_Table.PlaySound == nil then
        InterruptReminder_Table.PlaySound = false
    end
    if InterruptReminder_Table.Styles == nil then
        InterruptReminder_Table.Styles = {
            ['Pixel'] = { name = 'Pixel', color = { 0.95, 0.95, 0.32, 1 }, N = 8, thickness = 2, border = true },
            ['Cast'] = { name = 'Cast', color = { 0.95, 0.95, 0.32, 1 }, N = 4, frequency = 0.125, scale = 1 },
            ['Glow'] = { name = 'Glow', color = { 0.95, 0.98, 0.65, 1 }, frequency = 0.125 },
            ['Proc'] = { name = 'Proc' }
        }
    end
    if InterruptReminder_Table.SelectedStyle == nil then
        InterruptReminder_Table.SelectedStyle = InterruptReminder_Table.Styles['Proc']
    end
end

function f:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
        IR_Table:Handle_PlayerLogin()
    end
    if (event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START') and ... == 'target' then
        IR_Table:Handle_CurrentTargetSpellCasting(IR_Table)
    end
    if (event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_SUCCEEDED' or event == 'UNIT_SPELLCAST_STOP'
            or event == 'UNIT_SPELLCAST_CHANNEL_STOP') and ... == 'target' then
        IR_Table:Handle_TargetStoppedCasting(IR_Table)
    end
    if event == 'PLAYER_TARGET_CHANGED' then
        IR_Table:Handle_PlayerSwitchingTargets(IR_Table)
    end
    if (event == 'ZONE_CHANGED_NEW_AREA' or event == 'ZONE_CHANGED_INDOORS' or event == 'ZONE_CHANGED') then
        IR_Table:Handle_ZoneChanged(InterruptReminder_Table)
    end
    if event == 'SPELL_DATA_LOAD_RESULT' then
        local spellID, success = ...
        local spells = merge_two_tables(IR_Table.CCSpells[PlayerClass], IR_Table.RaceSpells[PlayerRace])
        if success and tContains(spells, spellID) then
            table.insert(IR_Table.SpellCache, spellID)
        end
        if #IR_Table.SpellCache == #spells then
            IR_Table.SelectedSpells = InterruptReminder_Table.SelectedSpells
            IR_Table.SelectedGlow = InterruptReminder_Table.SelectedStyle

            IR_Table:CreateInterface(InterruptReminder_Table)
            f:UnregisterEvent('SPELL_DATA_LOAD_RESULT')
            printDebug("Handle_PlayerLogin: Options interface created.")
        end
    end
end

f:RegisterEvent('PLAYER_LOGIN')
f:RegisterEvent('UNIT_SPELLCAST_START')
f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
f:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
f:RegisterEvent('UNIT_SPELLCAST_STOP')
f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
f:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
f:RegisterEvent('PLAYER_TARGET_CHANGED')
f:RegisterEvent('ZONE_CHANGED')
f:RegisterEvent('ZONE_CHANGED_NEW_AREA')
f:RegisterEvent('ZONE_CHANGED_INDOORS')
f:RegisterEvent('SPELL_DATA_LOAD_RESULT')
f:SetScript('OnEvent', f.OnEvent)