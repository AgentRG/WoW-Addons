SLASH_INTERRUPT_REMINDER_HELP1 = "/irhelp"

-- Table from which the add-on retrieves and stores all runtime data about the target, player, and more.
local IR_Table = {
    -- Pool of frames that will contain the check buttons that the player wants checked in the options interface
    CheckButtonFramePool = {},
    -- WoW default action bar names
    ActionBars = { 'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft',
                   'MultiBar7', 'MultiBar6', 'MultiBar5' },
    --All keywords that are found in varying Crowd Control spells
    CrownControlTypes = { 'knock', 'control', 'confuse', 'fear', 'flee', 'stun', 'interrupt', 'incapacit',
                          'intimidat', 'sleep', 'disorient', 'horr', 'silenc' },
    --Spells that will get picked up by IR_Table:get_all_crowd_control_spells because they contain a keyword from CrownControlTypes that we do not want to be added to the list
    ExtraneousCCSpells = {
        --Evoker
        'Deep Breath', 'Dream Flight', 'Emerald Communion', 'Breath of Eons',
        --Warlock
        'Dark Pact', 'Unending Resolve', 'Grimoire: Felguard',
        --Humans
        'Will to Survive',
        --Warrior
        'Enraged Regeneration',
        --Worgen
        'Calm the Wolf',
        --Mage
        'Blink',
        --Demon Hunter
        'Isolated Prey', 'Chaos Fragments', 'Disrupting Fury',
        --Druid
        'Barkskin',
        --Hunter
        'Eyes of the Beast',
        --Death Knight
        "Death's Advance", 'Lichborne',
        --Priest
        'Pain Suppression', 'Guardian Spirit',
        --Orc
        'Hardiness',
        --Undead
        'Will of the Forsaken',
        --Paladin
        'Divine Shield', 'Divine Protection', "Justicar's Vengeance",
        --Shaman
        --Monk
        'Restoral', 'Storm, Earth, and Fire'
    },
    --Default interrupts for all classes. These spell's primarily goal is to interrupt (with sometimes a secondary effect)
    InterruptSpells = {
        ['Death Knight'] = { 'Mind Freeze', 'Asphyxiate', 'Strangulate', 'Death Grip' },
        ['Demon Hunter'] = { 'Disrupt' },
        ['Druid'] = { 'Skull Bash', 'Solar Beam' },
        ['Evoker'] = { 'Quell' },
        ['Hunter'] = { 'Counter Shot', 'Muzzle' },
        ['Mage'] = { 'Counterspell' },
        ['Monk'] = { 'Spear Hand Strike', 'Quaking Palm' },
        ['Paladin'] = { 'Rebuke', "Avenger's Shield" },
        ['Priest'] = { 'Silence' },
        ['Rogue'] = { 'Kick' },
        ['Shaman'] = { 'Wind Shear' },
        ['Warlock'] = { 'Spell Lock', 'Optical Blast', 'Axe Toss' },
        ['Warrior'] = { 'Pummel' }
    },
    SaveHidden = true,
    bossInserts = 0,
    EndTime = nil,
    StartTime = nil,
    IsInterruptible = false,
    TargetCanBeStunned = false,
    CurrentTargetCanBeAttacked = false,
    SpecializationChanged = false,
    panel = CreateFrame("Frame", "InterruptReminderSettings")
}

local f = CreateFrame('Frame', 'InterruptReminder')
local PlayerClass = UnitClass('player')

-- Library used to highlight spells. Without the library, the addon will encounter protected action access error
local LibButtonGlow = LibStub("LibButtonGlow-1.0")

-- Local version of WoW global functions for slightly faster runtime access
local GetActionInfo = GetActionInfo
local GetSpellCooldown = GetSpellCooldown
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellTabInfo = GetSpellTabInfo
local GetSpellBookItemName = GetSpellBookItemName
local tContains = tContains
local Spell = Spell
local GetUnitName = GetUnitName
local UnitClassification = UnitClassification
local HasAction = HasAction
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local C_Timer = C_Timer
local C_EncounterJournal = C_EncounterJournal
local EJ_GetCreatureInfo = EJ_GetCreatureInfo
local UnitCanAttack = UnitCanAttack
local C_Map = C_Map
local C_ClassTalents = C_ClassTalents
local C_Traits = C_Traits
local GetInstanceInfo = GetInstanceInfo
local PlaySoundFile = PlaySoundFile
local IsPlayerSpell = IsPlayerSpell

-- Local version of Lua global functions for slightly faster runtime access
local string = string
local table = table
local ipairs = ipairs
local pairs = pairs
local select = select
local print = print

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

---Slash command for information help.
SlashCmdList.INTERRUPT_REMINDER_HELP = function()
    printInfo("To view more options, head to Options → AddOns → Interrupt Reminder. The mod works by"..
            " highlighting spells that are interruptible by the target. If advanced spell selection is disabled in"..
            " the options, only spells that are for interrupting will be highlighted.")
end

---Remove duplicates in a table and return the table
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

---Remove duplicates in a table based on the key of a nested table
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

local function get_specialization_spells()
    local spellIDs = {}
    local list = {}

    local configID = C_ClassTalents.GetActiveConfigID()
    if configID == nil then
        return
    end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if configInfo == nil then
        return
    end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            for _, entryID in ipairs(nodeInfo.entryIDs) do
                local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                if entryInfo and entryInfo.definitionID then
                    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                    if definitionInfo.spellID then
                        table.insert(spellIDs, definitionInfo.spellID)
                    end
                end
            end
        end
    end
    for _, spellId in ipairs(spellIDs) do
        local spell = Spell:CreateFromSpellID(spellId)
        local spellName = spell:GetSpellName()
        if spellName and not tContains(IR_Table.ExtraneousCCSpells, spellName) then

            if spell:IsSpellEmpty() == false then
                spell:ContinueOnSpellLoad(function()
                    local desc = spell:GetSpellDescription()
                    local descLower = string.lower(desc)

                    for _, cc in pairs(IR_Table.CrownControlTypes) do
                        if string.find(descLower, cc, 1, true) then
                            printDebug("get_specialization_spells: Inserted spell " .. spellName .. ".")
                            table.insert(list, { spellName = spellName, description = desc })
                            break
                        end
                    end
                end)
            end
        end
    end
    return list
end

local function get_spellbook_spells()
    local list = {}
    local numSpellTabs = GetNumSpellTabs()

    for tabIndex = 1, numSpellTabs do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)

        for spellIndex = offset + 1, offset + numSpells do
            local spellName, _, spellId = GetSpellBookItemName(spellIndex, BOOKTYPE_SPELL)

            if spellName and not tContains(IR_Table.ExtraneousCCSpells, spellName) then
                local spell = Spell:CreateFromSpellID(spellId)

                if spell:IsSpellEmpty() == false then
                    spell:ContinueOnSpellLoad(function()
                        local desc = spell:GetSpellDescription()
                        local descLower = string.lower(desc)

                        for _, cc in pairs(IR_Table.CrownControlTypes) do
                            if string.find(descLower, cc, 1, true) then
                                printDebug("get_spellbook_spells: Inserted spell " .. spellName .. ".")
                                table.insert(list, { spellName = spellName, description = desc })
                                break
                            end
                        end
                    end)
                end
            end
        end
    end
    return list
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
    local copy = InterruptReminder_Table.CurrentBossList
    local bestMapForPlayer = C_Map.GetBestMapForUnit('player')
    if bestMapForPlayer ~= nil then
        local encounters = C_EncounterJournal.GetEncountersOnMap(bestMapForPlayer) or {}
        IR_Table.bossInserts = 0
        for _, encounter in pairs(encounters) do
            for i = 1, 9 do
                local name = select(2, EJ_GetCreatureInfo(i, encounter.encounterID))
                if name then
                    copy[#copy + 1] = name
                    IR_Table.bossInserts = IR_Table.bossInserts + 1
                else
                    break
                end
            end
        end
    end
    printDebug("get_bosses: Boss list now consists of: " .. table.concat(copy, ","))
    InterruptReminder_Table.CurrentBossList = copy
end

---Keep the boss list at the capacity of 30
local function truncate_boss_list()
    local copy = InterruptReminder_Table.CurrentBossList
    local inserts = IR_Table.bossInserts
    if #copy >= 30 then
        for _ = 1, inserts do
            table.remove(copy, 1)
        end
        printDebug("truncate_boss_list: Truncate boss list by " .. inserts .. ".")
    end
    InterruptReminder_Table.CurrentBossList = copy
end

---Options frame
function IR_Table:CreateInterface(self)

    IR_Table.panel.name = "Interrupt Reminder"

    --- If one of the checkboxes were checked but changes were not saved, this warning will appear.
    local save_warning_text = IR_Table.panel:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    save_warning_text:Hide()
    save_warning_text:SetText("You have unsaved changes!")
    save_warning_text:SetTextColor(1.0, 0, 0, 1)
    save_warning_text:SetPoint("BOTTOM", 0, 325)

    local about_mod_text = IR_Table.panel:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    about_mod_text:Show()
    about_mod_text:SetTextColor(1.0, 1.0, 1.0, 0.8)
    about_mod_text:SetPoint("TOPLEFT", 8, -315)
    about_mod_text:SetSize(650, 290)
    about_mod_text:SetJustifyH("LEFT")
    about_mod_text:SetJustifyV("TOP");
    about_mod_text:SetText("About the mod:\n\n"..
            "• If \"Enable Advanced Spell Selection\" is disabled, the default interrupt spells will be highlighted."..
            " In the case of your player class, it will be the spell(s): ".. table.concat(IR_Table.InterruptSpells[PlayerClass], ',') ..".\n\n"..
            "• If \"Enable Advanced Spell Selection\" is enabled, a list of checkboxes will appear for selection. A "..
            "special algorithm runs in the background to determine which spells are eligible to be considered Crowd "..
            "Control spells. If you noticed that a spell that should not be in the list is there, or one that should "..
            "be there is missing, please let the developer know as he plays only one class.\n\n"..
            "• If you notice that the list of available spells seems too short, or that only the spells that you previously"..
            " selected appear on the list of checkboxes, please click on the \"Refresh Spells\" button. World of"..
            " Warcraft does not always load all objects by the time this options menu is generated, so at the time the"..
            " algorithm ran, it's possible that some parts of the game were not available for the addon.\n\n"..
            "• If you have changed your specialization, you will get a notification in chat to remind you to refresh "..
            "your spells, as each specialization has their own unique Crowd Control spells.\n\n"..
            "• The debugger is mainly for developer use. Enabling it will cause a lot of chat noise.\n\n"..
            "• Please let the developer of any bugs you come across at either the GitHub repository, CurseForge or"..
            " WoWInterface.")
    about_mod_text:SetWordWrap(true)

    --- Create 30 checkboxes to be used
    local function create_checkboxes(frame)
        local x, y, r = 8, -50, 0
        for i = 1, 30 do
            IR_Table.CheckButtonFramePool[#IR_Table.CheckButtonFramePool + 1] = { frame = CreateFrame("CheckButton", UIParent, frame, "ChatConfigCheckButtonTemplate") }
            IR_Table.CheckButtonFramePool[i].frame:Hide()
            if r == 3 then
                y = y - 20
                x = 8
                r = 0
            end
            IR_Table.CheckButtonFramePool[i].frame:SetScript("OnClick", function()
                if IR_Table.SaveHidden == true then
                    save_warning_text:Show()
                    IR_Table.SaveHidden = false
                end
            end)
            IR_Table.CheckButtonFramePool[i].frame:SetPoint("TOPLEFT", x, y)
            x = x + 200
            r = r + 1
        end
    end

    --- If advanced options are enabled, set the name/description of checkbox at position i to that of that spell. If the
    --- spell is present in SelectedSpells, set the checkbox to checked status. Hide all other checkboxes.
    local function pre_fill_checkboxes()
        if self.IsInit == true then
            local spells = self.Spells
            local checkedSpells = self.SelectedSpells
            for i = 1, #spells do
                local spell_name = spells[i].spellName
                local spell_description = spells[i].description
                local checkbox = IR_Table.CheckButtonFramePool[i].frame
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
    end

    --- For every spell inside Spells, set the name/description of checkbox at position i to that of that spell. If the
    --- spell is present in SelectedSpells, set the checkbox to checked status. Hide all other checkboxes.
    local function generate_spell_checkboxes()
        local selectedSpells = self.SelectedSpells
        local spells = self.Spells
        local endIteration = #spells + 1
        for i = 1, #spells do
            local checkbox = IR_Table.CheckButtonFramePool[i].frame
            local spell_name = spells[i].spellName
            local spell_description = spells[i].description
            checkbox.Text:SetText(spell_name)
            checkbox.tooltip = spell_description
            if tContains(selectedSpells, spell_name) then
                checkbox:SetChecked(true)
            else
                checkbox:SetChecked(false)
            end
            checkbox:Show()
        end
        for i = endIteration, 30 do
            local checkbox = IR_Table.CheckButtonFramePool[i].frame
            checkbox:Hide()
            checkbox:SetChecked(false)
        end
    end

    --- Set SelectedSpells to default interrupt spells. Hide all checkboxes and set them to unchecked.
    local function remove_spell_checkboxes()
        self.SelectedSpells = IR_Table.InterruptSpells[PlayerClass]
        IR_Table.SelectedSpells = self.selectedSpells
        for i = 1, 30 do
            local checkbox = IR_Table.CheckButtonFramePool[i].frame
            checkbox:Hide()
            checkbox:SetChecked(false)
        end
        IR_Table.TargetCanBeStunned = false
    end

    --- Wipe SelectedSpells and iterate through each checkbox. If checked, save spell into SelectedSpells.
    local function save_spells_into_table()
        self.SelectedSpells = {}
        local copy = {}
        for i = 1, 30 do
            local checkbox = IR_Table.CheckButtonFramePool[i].frame
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

    --- Pre-run certain scripts
    IR_Table:GetAllCrowdControlSpells(self)
    create_checkboxes(IR_Table.panel)
    pre_fill_checkboxes()

    --- Horizontal line at the top
    local horizontal_line_top = IR_Table.panel:CreateLine()
    horizontal_line_top:SetColorTexture(1, 1, 1, 0.5)
    horizontal_line_top:SetThickness(1)
    horizontal_line_top:SetStartPoint("TOPLEFT", 12, -40)
    horizontal_line_top:SetEndPoint("TOPRIGHT", -12, -40)

    --- Horizontal line at the bottom
    local horizontal_line_bottom = IR_Table.panel:CreateLine()
    horizontal_line_bottom:SetColorTexture(1, 1, 1, 0.5)
    horizontal_line_bottom:SetThickness(1)
    horizontal_line_bottom:SetStartPoint("BOTTOMLEFT", 12, 295)
    horizontal_line_bottom:SetEndPoint("BOTTOMRIGHT", -12, 295)

    --- SAVE BUTTON
    local save_button = CreateFrame("Button", UIParent, IR_Table.panel, "UIPanelButtonTemplate")
    if self.IsInit == false then
        save_button:Hide()
    else
        save_button:Show()
    end
    save_button:SetText("Save Spells")
    save_button:SetWidth(100)
    save_button:SetPoint("BOTTOM", -100, 300)
    save_button:SetScript("OnClick", function()
        PlaySoundFile(567407, "SFX")
        save_spells_into_table()
        if IR_Table.SaveHidden == false then
            save_warning_text:Hide()
            IR_Table.SaveHidden = true
        end
    end)

    --- CANCEL BUTTON
    local cancel_button = CreateFrame("Button", UIParent, IR_Table.panel, "UIPanelButtonTemplate")
    if self.IsInit == false then
        cancel_button:Hide()
    else
        cancel_button:Show()
    end
    cancel_button:SetText("Cancel")
    cancel_button:SetWidth(100)
    cancel_button:SetPoint("BOTTOM", 100, 300)
    cancel_button:SetScript("OnClick", function()
        PlaySoundFile(567407, "SFX")
        pre_fill_checkboxes()
        if IR_Table.SaveHidden == false then
            save_warning_text:Hide()
            IR_Table.SaveHidden = true
        end
    end)

    --- REFRESH BUTTON
    local refresh_button = CreateFrame("Button", UIParent, IR_Table.panel, "UIPanelButtonTemplate")
    if self.IsInit == false then
        refresh_button:Hide()
    else
        refresh_button:Show()
    end
    refresh_button:SetText("Refresh Spells")
    refresh_button:SetWidth(100)
    refresh_button:SetPoint("BOTTOM", 0, 300)
    refresh_button:SetScript("OnClick", function()
        PlaySoundFile(567407, "SFX")
        self.SelectedSpells = IR_Table.InterruptSpells[PlayerClass]
        IR_Table.SelectedSpells = self.selectedSpells
        pre_fill_checkboxes()
        IR_Table:GetAllCrowdControlSpells(self)
        generate_spell_checkboxes(IR_Table.panel)
        if IR_Table.SaveHidden == false then
            save_warning_text:Hide()
            IR_Table.SaveHidden = true
        end
        LibButtonGlow.HideOverlayGlow(refresh_button)
    end)
    refresh_button:SetScript("OnEvent", function(_, event)
        if event == 'ACTIVE_PLAYER_SPECIALIZATION_CHANGED' then
            printInfo('Specialization changed! Please go to the mod settings to update your spell highlighting.')
            LibButtonGlow.ShowOverlayGlow(refresh_button)
        end
    end)
    refresh_button:RegisterEvent('ACTIVE_PLAYER_SPECIALIZATION_CHANGED')

    --- DEBUG MODE CHECKBOX
    local debug_mode = CreateFrame("CheckButton", UIParent, IR_Table.panel, "ChatConfigCheckButtonTemplate")
    debug_mode.Text:SetText("Enable Debugger")
    debug_mode:SetPoint("TOPLEFT", 408, -10)
    debug_mode.tooltip = "Enable the debugger for event handling and other functions."
    if self.Debug == true then
        debug_mode:SetChecked(true)
    else
        debug_mode:SetChecked(false)
    end
    debug_mode:SetScript("OnClick", function()
        local check_status = debug_mode:GetChecked()
        if check_status == true then
            self.Debug = true
            printInfo("Debugger has been enabled.")
        else
            self.Debug = false
            printInfo("Debugger has been disabled.")
        end
    end)

    --- ADVANCED MODE CHECKBOX
    local advanced_mode = CreateFrame("CheckButton", UIParent, IR_Table.panel, "ChatConfigCheckButtonTemplate")
    advanced_mode.Text:SetText("Enable Advanced Spell Selection")
    advanced_mode:SetPoint("TOPLEFT", 8, -10)
    advanced_mode.tooltip = "Brings up a list of checkboxes for the user to select from for individual spells that the" ..
            " user would like to see highlighted."
    if self.IsInit == true then
        advanced_mode:SetChecked(true)
        generate_spell_checkboxes(IR_Table.panel)
    else
        advanced_mode:SetChecked(false)
    end
    advanced_mode:SetScript("OnClick", function()
        local check_status = advanced_mode:GetChecked()
        if check_status == true then
            self.IsInit = true
            generate_spell_checkboxes(IR_Table.panel)
            save_button:Show()
            cancel_button:Show()
            refresh_button:Show()
        else
            self.IsInit = false
            remove_spell_checkboxes()
            save_button:Hide()
            cancel_button:Hide()
            refresh_button:Hide()
            save_warning_text:Hide()
        end
    end)
    InterfaceOptions_AddCategory(IR_Table.panel, true)
end

function InterruptReminder_OnAddonCompartmentClick()
    InterfaceOptionsFrame_OpenToCategory(IR_Table.panel)
end

function IR_Table:GetAllCrowdControlSpells(self)
    self.Spells = {}
    local copy = {}

    copy = get_spellbook_spells()
    local specialization_spells = get_specialization_spells()
    if specialization_spells ~= nil then
        copy = merge_two_tables(copy, get_specialization_spells())
    end
    copy = remove_duplicates_from_nested_table(copy, 'spellName')
    self.Spells = copy
end

---Algorithm that determines whether the currently selected target is a boss and reassigns IR_Table.TargetCanBeStunned
--- as either true or false depending on the circumstances. Since there is no actual API call to determine whether a
--- target can be stunned, we need to make use of the information we do have access to. For example, units that have
--- a frame around them more likely than not cannot be stunned. When in dungeons, this is troublesome since normal mobs
--- also have a frame around them. To get around that, we are reading InterruptReminder_Table.CurrentBossList to determine
--- whether the current target is a boss or a minion of a boss in that dungeon, and therefore cannot be stunned.
---DEV NOTE: Although this works in most cases, a giant drake in a raid that is not a boss will be tagged as
--- stunnable - that cannot be reasonably kept track of without having a huge table of all units that have a non-public
--- flag that makes them stun immune. Basically, if the non-boss minion seems too big to be stunned, it probably is.
function IR_Table:IsTargetABoss(self)
    local bosses = self.CurrentBossList
    --[[ There's a small bug here that I couldn't find a fix for. If the target switched to is nothing, it will still
         pull the target information from the previous target, even though GetUnitName should return nil at that point.
         Luckily, thin air cannot cast spells, so the rest of the addon will still function as intended. ]]
    if self.IsInit then
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
end

---Same as IR_Table:FindAllInterruptSpells, but for a single spell. Used when the callback handler is called
--- in case a spell was on cooldown.
function IR_Table:FindSpellLocation(spell)
    for _, barName in ipairs(IR_Table.ActionBars) do
        for i = 1, 12 do
            local button = _G[barName .. 'Button' .. i]
            local slot = button:GetPagedID() or button:CalculateAction() or button:GetAttribute('action')

            if HasAction(slot) then
                local actionType, id, _, actionName = GetActionInfo(slot)

                if actionType == 'spell' then
                    actionName = GetSpellInfo(id)
                end

                if actionName then
                    if string.lower(actionName) == string.lower(spell) then
                        return button
                    end
                end
            end
        end
    end
end

---Retrieves the cooldown status of a list of spells and their corresponding location on the action bar(s).
---Returns two tables: one for spells ready to be cast and another for spells that are still on cool down.
---Parameters:
--- class_spells (table): A list of spell names (strings) to check the cooldown for.
---Returns:
--- readyToCast (table): A table of spells ready to be cast.
--- stillOnCooldown (table): A table of spells still on cooldown.
function IR_Table:GetSpellCooldowns(spells_table, interrupt_only)

    if interrupt_only == true then
        spells_table = {}
        spells_table = IR_Table.InterruptSpells[PlayerClass]
    elseif interrupt_only == false then
        spells_table = spells_table
    end

    local readyToCast, stillOnCooldown = {}, {}
    for i = 1, #spells_table do
        local spell = spells_table[i]
        local _, _, _, _, _, _, spellID = GetSpellInfo(spell)
        local isInSpellbook = IsPlayerSpell(spellID)
        if isInSpellbook then
            local start, duration = GetSpellCooldown(spellID)
                if duration == 0 or duration <= 1.5 --[[Global Cooldown]] then
                    table.insert(readyToCast, {['location'] = IR_Table:FindSpellLocation(spell)})
                else
                    -- Add a 0.01 overhead to ensure the spell gets highlighted after it is off cooldown
                    local calculatedTimeRemaining = (start + duration - GetTime()) + 0.01
                    -- Safety check to ensure we don't save a negative number by mistake
                    if calculatedTimeRemaining > 0 then
                        -- Check that the spell will be ready before the spellcast from the target ends
                        if IR_Table.EndTime ~= nil and IR_Table.EndTime < ((start + duration) * 1000) then
                            table.insert(stillOnCooldown, { ['cooldown'] = calculatedTimeRemaining, ['location'] = IR_Table:FindSpellLocation(spell)})
                        end
                    end
                end
        end
    end
    printDebug("GetSpellCooldowns: " .. #readyToCast .. " spells ready to cast. " .. #stillOnCooldown .. " spells are still on cooldown.")
    return readyToCast, stillOnCooldown
end

---Checks if the target is casting or channeling a spell and set IR_Table.* values.
function IR_Table:IsTargetCastingInterruptibleSpell()
    local name, _, _, startTime, endTime, _, _, notInterruptible, _ = UnitCastingInfo('target')

    if name == nil then
        name, _, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo('target')
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

---Handles the unhighlight of spells.
function IR_Table:Handle_TargetStoppedCasting(self)

    for i = 1, #self.SelectedSpells do
        local spellLocation = IR_Table:FindSpellLocation(self.SelectedSpells[i])
        if spellLocation ~= nil then
            printDebug("Handle_TargetStoppedCasting: Hide spell " .. self.SelectedSpells[i] .. " highlight at location " .. tostring(spellLocation) .. ".")
            LibButtonGlow.HideOverlayGlow(spellLocation)
        else
            printDebug("Handle_TargetStoppedCasting: Spell " .. self.SelectedSpells[i] .. " is not in the action bars.")
        end
    end
end

---Handles the logic for highlighting interruptible spells on the current target (whether target can be interrupted is
--- deduced during PLAYER_TARGET_CHANGED event).
---In case a spell is not in cooldown, highlight the spell at its action bar location.
---In case a spell is in cooldown, use C_Timer.After to check whether by the time it is off cooldown, that target
--- can still be interrupted, in which case it will highlight the ability at its location.
function IR_Table:Handle_CurrentTargetSpellCasting(self)

    IR_Table:IsTargetCastingInterruptibleSpell()

    if IR_Table.IsInterruptible == true and IR_Table.CurrentTargetCanBeAttacked == true then
        if IR_Table.TargetCanBeStunned == true then
            -- Can be true only when Crowd Control spell tracking is enabled
            local readyToCast, stillOnCooldown = IR_Table:GetSpellCooldowns(self.SelectedSpells, false)
            for i = 1, #readyToCast do
                if readyToCast[i].location ~= nil then
                    printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " .. tostring(readyToCast[i].location) .. ".")
                    LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
                end
            end
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    IR_Table:IsTargetCastingInterruptibleSpell()
                    if IR_Table.IsInterruptible == true and IR_Table.CurrentTargetCanBeAttacked then
                        if stillOnCooldown[i].location ~= nil then
                            printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " .. tostring(stillOnCooldown[i].location) .. ".")
                            LibButtonGlow.ShowOverlayGlow(stillOnCooldown[i].location)
                        end
                    end
                end)
            end
        else
            local readyToCast, stillOnCooldown = IR_Table:GetSpellCooldowns(self.SelectedSpells, true)
            for i = 1, #readyToCast do
                if readyToCast[i].location ~= nil then
                    printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " .. tostring(readyToCast[i].location) .. ".")
                    LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
                end
            end
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    IR_Table:IsTargetCastingInterruptibleSpell()
                    if IR_Table.IsInterruptible == true and IR_Table.CurrentTargetCanBeAttacked then
                        if stillOnCooldown[i].location ~= nil then
                            printDebug("Handle_CurrentTargetSpellCasting: Show highlight at location " .. tostring(stillOnCooldown[i].location) .. ".")
                            LibButtonGlow.ShowOverlayGlow(stillOnCooldown[i].location)
                        end
                    end
                end)
            end
        end
    end
end

---Each time the player's zone changes, determine whether the player is currently in the dungeon. If the player is in
--- a dungeon, use C_EncounterJournal.GetEncountersOnMap to grab all the boss fights in the current zone. Each encounter
--- can have a maximum of 9 unit types present. Return 'empty' if the current zone has no bosses.
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

    if InterruptReminder_FirstLaunch == nil then
        InterruptReminder_FirstLaunch = true
        printInfo('First time loading the add-on? Type /irhelp for more information.')
    end

    if InterruptReminder_Table == nil then InterruptReminder_Table = {} end
    if InterruptReminder_Table.Spells == nil then InterruptReminder_Table.Spells = {} end
    if InterruptReminder_Table.SelectedSpells == nil then InterruptReminder_Table.SelectedSpells = IR_Table.InterruptSpells[PlayerClass] end
    if InterruptReminder_Table.CurrentBossList == nil then InterruptReminder_Table.CurrentBossList = {} end
    if InterruptReminder_Table.Debug == nil then InterruptReminder_Table.Debug = false end

    C_Timer.After(1, function()
        IR_Table:CreateInterface(InterruptReminder_Table)
        printDebug("Handle_PlayerLogin: Options interface created.")
    end)

    -- Initial values for IR_Table
    IR_Table.SelectedSpells = InterruptReminder_Table.SelectedSpells
end

function f:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
        IR_Table:Handle_PlayerLogin()
    end
    if (event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START') and ... == 'target' then
        IR_Table:Handle_CurrentTargetSpellCasting(IR_Table)
    end
    if (event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_SUCCEEDED' or event == 'UNIT_SPELLCAST_STOP' or event == 'UNIT_SPELLCAST_CHANNEL_STOP') and ... == 'target' then
        IR_Table:Handle_TargetStoppedCasting(IR_Table)
    end
    if event == 'PLAYER_TARGET_CHANGED' then
        IR_Table:Handle_PlayerSwitchingTargets(IR_Table)
    end
    if (event == 'ZONE_CHANGED_NEW_AREA' or event == 'ZONE_CHANGED_INDOORS' or event == 'ZONE_CHANGED') and InterruptReminder_Table.IsInit == true then
        IR_Table:Handle_ZoneChanged(InterruptReminder_Table)
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
f:SetScript('OnEvent', f.OnEvent)