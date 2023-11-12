SLASH_INTERRUPT_REMINDER_HELP1 = "/irhelp"

-- Table from which the add-on retrieves and stores all runtime data about the target, player, and more.
local IR_Table = {}

-- WoW default action bar names
IR_Table.ActionBars = {'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft',
                       'MultiBar7', 'MultiBar6', 'MultiBar5'}

--All keywords that are found in varying Crowd Control spells
IR_Table.CrownControlTypes = {'knock', 'control', 'confuse', 'fear', 'flee', 'stun', 'interrupt', 'incapacit',
                              'intimidat', 'sleep', 'disorient', 'horr', 'silenc'}

--Spells that will get picked up by IR_Table.get_all_crowd_control_spells() because they contain a keyword from CrownControlTypes that we do not want to be added to the list
IR_Table.ExtraneousCCSpells = {
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
}

--Default interrupts for all classes. These spell's primarily goal is to interrupt (with sometimes a secondary effect)
IR_Table.InterruptSpells = {
    ['Death Knight'] = {'Mind Freeze', 'Asphyxiate', 'Strangulate', 'Death Grip'},
    ['Demon Hunter'] = {'Disrupt'},
    ['Druid'] = {'Skull Bash', 'Solar Beam'},
    ['Evoker'] = {'Quell'},
    ['Hunter'] = {'Counter Shot', 'Muzzle'},
    ['Mage'] = {'Counterspell'},
    ['Monk'] = {'Spear Hand Strike'},
    ['Paladin'] = {'Rebuke', "Avenger's Shield"},
    ['Priest'] = {'Silence'},
    ['Rogue'] = {'Kick'},
    ['Shaman'] = {'Wind Shear'},
    ['Warlock'] = {'Spell Lock', 'Optical Blast', 'Axe Toss'},
    ['Warrior'] = {'Pummel'}
}
IR_Table.InitialLoadDone = false

local f = CreateFrame('Frame', 'InterruptReminder')
local playerClass = UnitClass('player')

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

-- Local version of Lua global functions for slightly faster runtime access
local string = string
local table = table
local ipairs = ipairs
local pairs = pairs
local select = select
local print = print

local function printInfo(text) print("|cff00ffffInfo (InterruptReminder): |cffffffff"..text) end
local function printWarning(text) print("|cffffff00Warning (InterruptReminder): |cffffffff"..text) end

---Options frame
local function CreateInterface()
    local panel = CreateFrame("Frame", "InterruptReminderSettings")
    panel.name = "Interrupt Reminder"

    local advancedMode = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
    advancedMode.Text:SetText("Enable Advanced Options")
    advancedMode:SetPoint("TOPLEFT", 8, -10)
    advancedMode.tooltip = "Brings up a list of checkboxes for the user to select from for individual spells that the"..
            " user would like to see highlighted."
    if InterruptReminder_Table.IsInit == true then
        advancedMode:SetChecked(true)
    else
        advancedMode:SetChecked(false)
    end
    local horizontal_line = panel:CreateLine()
    horizontal_line:SetColorTexture(1, 1, 1, 0.5)
    horizontal_line:SetThickness(1)
    horizontal_line:SetStartPoint("TOPLEFT", 12, -40)
    horizontal_line:SetEndPoint("TOPRIGHT", -12, -40)
    advancedMode:SetScript("OnClick", function()
        local checkStatus = advancedMode:GetChecked()
        if checkStatus == true then
            InterruptReminder_Table.IsInit = true
            IR_Table.get_all_crowd_control_spells()
            InterruptReminder_Table.ActionBarTable, InterruptReminder_Table.ActionBarSlot = IR_Table.find_all_interrupt_spell(InterruptReminder_Table.spells)
        else
            InterruptReminder_Table.IsInit = false
            InterruptReminder_Table.spells = IR_Table.InterruptSpells[playerClass]
            InterruptReminder_Table.ActionBarTable, InterruptReminder_Table.ActionBarSlot = IR_Table.find_all_interrupt_spell(InterruptReminder_Table.spells)
            IR_Table.TargetCanBeStunned = false
        end
    end)
    InterfaceOptions_AddCategory(panel, true)
end

---Slash command for information help.
SlashCmdList.INTERRUPT_REMINDER_HELP = function()

end

---Remove duplicates in a table and return the table
local function remove_duplicates(table)
    local currentCopy = table
    local hash = {}
    local res = {}

    for _, v in pairs(currentCopy) do
        if (not hash[v]) then
            res[#res + 1] = v
            hash[v] = true
        end
    end
    table = res
    return table
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
    if configID == nil then return end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if configInfo == nil then return end

    for _, treeID in ipairs(configInfo.treeIDs) do -- in the context of talent trees, there is only 1 treeID
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            for _, entryID in ipairs(nodeInfo.entryIDs) do -- each node can have multiple entries (e.g. choice nodes have 2)
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
            local spell = Spell:CreateFromSpellID(spellId)

            if spell:IsSpellEmpty() == false then
                spell:ContinueOnSpellLoad(function()
                    local desc = string.lower(spell:GetSpellDescription())

                    for _, cc in pairs(IR_Table.CrownControlTypes) do
                        if string.find(desc, cc, 1, true) then
                            table.insert(list, spellName)
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
                        local desc = string.lower(spell:GetSpellDescription())

                        for _, cc in pairs(IR_Table.CrownControlTypes) do
                            if string.find(desc, cc, 1, true) then
                                table.insert(list, spellName)
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

function IR_Table.get_all_crowd_control_spells()
    InterruptReminder_Table.spells = {}
    local copy = {}
    copy = get_spellbook_spells()
    copy = merge_two_tables(copy, get_specialization_spells())
    copy = remove_duplicates(copy)
    InterruptReminder_Table.spells = copy
end

---Returns whenever the player is currently in an instance or in open world
local function is_in_instance()
    local _, instanceType = GetInstanceInfo()
    if instanceType ~= 'none' then return true else return false end
end

---Algorithm that determines whether the currently selected target is a boss and reassigns IR_Table.TargetCanBeStunned
--- as either true or false depending on the circumstances. Since there is no actual API call to determine whether a
--- target can be stunned, we need to make use of the information we do have access to. For example, units that have
--- a frame around them more likely than not cannot be stunned. When in dungeons, this is troublesome since normal mobs
--- also have a frame around them. To get around that, we are reading InterruptReminder_Table.currentBossList to determine
--- whether the current target is a boss or a minion of a boss in that dungeon, and therefore cannot be stunned.
---DEV NOTE: Although this works in most cases, a giant drake in a raid that is not a boss will be tagged as
--- stunnable - that cannot be reasonably kept track of without having a huge table of all units that have a non-public
--- flag that makes them stun immune. Basically, if the non-boss minion seems too big to be stunned, it probably is.
function IR_Table.is_target_a_boss()
    local bosses = InterruptReminder_Table.currentBossList
    --[[ There's a small bug here that I couldn't find a fix for. If the target switched to is nothing, it will still
         pull the target information from the previous target, even though GetUnitName should return nil at that point.
         Luckily, thin air cannot cast spells, so the rest of the addon will still function as intended. ]]
    if InterruptReminder_Table.IsInit then
        local targetName = GetUnitName('target', false)

        -- Check to see if the user is currently in an instance
        if is_in_instance() == true then

            -- Safety measure in case the dungeon boss names has not been defined as either list of bosses or empty
            if bosses == nil then
                IR_Table.handle_zone_changed()
                bosses = InterruptReminder_Table.currentBossList
            end

            -- Otherwise, check whether the target is a boss. If he's a boss, he's not stunnable.
            if tContains(bosses, targetName) then
                IR_Table.TargetCanBeStunned = false
            else
                IR_Table.TargetCanBeStunned = true
            end
        else
            -- Otherwise, assume we're in the open world
            local enemyRarity = UnitClassification('target')
            -- In WoW, units that are world bosses, elites and rare elites are more likely than not stun immune.
            if enemyRarity == 'worldboss' or enemyRarity == 'elite' or enemyRarity == 'rareelite' then
                IR_Table.TargetCanBeStunned = false
            else
                IR_Table.TargetCanBeStunned = true
            end
        end
    end
end


---Scan all of the player action bars and find the slot location for all interrupting spells for the player's class.
--- Found in: https://www.wowinterface.com/forums/showthread.php?t=45731 - modified a bit to meet the needs of this addon
function IR_Table.find_all_interrupt_spell(spells)
    local buttonTables = {}
    local buttonIds = {}

    for _, spell in ipairs(spells) do
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
                            table.insert(buttonTables, button)
                            table.insert(buttonIds, slot)
                        end
                    end
                end
            end
        end
    end
    return buttonTables, buttonIds
end


---Retrieves the cooldown status of a list of spells and their corresponding location on the action bar(s).
---Returns two tables: one for spells ready to be cast and another for spells that are still on cool down.
---Parameters:
--- class_spells (table): A list of spell names (strings) to check the cooldown for.
---Returns:
--- readyToCast (table): A table of spells ready to be cast.
--- stillOnCooldown (table): A table of spells still on cooldown.
function IR_Table.get_spell_cooldowns(spells_table, interrupt_only)
    interrupt_only = interrupt_only or false

    if interrupt_only == true then
        spells_table = IR_Table.InterruptSpells[playerClass]
    end

    local readyToCast = {}
    local stillOnCooldown = {}

    ---Same as IR_Table.find_all_interrupt_spell, but for a single spell. Used when the callback handler is called
    --- in case a spell was on cooldown.
    local function find_interrupt_spell(spell)
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

    for i = 1, #spells_table do
        local start, duration = GetSpellCooldown(spells_table[i])
        local spellLocation = find_interrupt_spell(spells_table[i])

        if start then
            if start == 0 then
                table.insert(readyToCast, {['cooldown']=start, ['location']=spellLocation})
            end
            if start ~= 0 then
                -- Add a 0.01 overhead to ensure the spell gets highlighted after it is off cooldown
                local calculatedTimeRemaining = (start + duration - GetTime()) + 0.01
                -- Safety check to ensure we don't save a negative number by mistake
                if calculatedTimeRemaining > 0 then
                    -- Check that the spell will be ready before the spellcast from the target ends
                    if IR_Table.EndTime ~= nil and IR_Table.EndTime < ((start + duration) * 1000) then
                        table.insert(stillOnCooldown, { ['cooldown']= calculatedTimeRemaining, ['location']=spellLocation})
                    end
                end
            end
        end
    end
    return readyToCast, stillOnCooldown
end


---Checks if the target is casting or channeling a spell and set IR_Table.* values.
function IR_Table.is_target_casting_interruptible_spell()
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
        else
            IR_Table.EndTime = endTime
            IR_Table.StartTime = startTime
            IR_Table.IsInterruptible = false
        end
    else
        IR_Table.EndTime = nil
        IR_Table.StartTime = nil
        IR_Table.IsInterruptible = false
    end
end


---Handles the unhighlight of spells.
function IR_Table.handle_target_stopped_casting()
    for _, location in ipairs(InterruptReminder_Table.ActionBarTable) do
        LibButtonGlow.HideOverlayGlow(location)
    end
end


---Handles the logic for highlighting interruptible spells on the current target (whether target can be interrupted is
--- deduced during PLAYER_TARGET_CHANGED event).
---In case a spell is not in cooldown, highlight the spell at its action bar location.
---In case a spell is in cooldown, use C_Timer.After to check whether by the time it is off cooldown, that target
--- can still be interrupted, in which case it will highlight the ability at its location.
function IR_Table.handle_current_target_spell_casting()

    IR_Table.is_target_casting_interruptible_spell()

    local spells = InterruptReminder_Table.spells

    if IR_Table.IsInterruptible == true and IR_Table.CurrentTargetCanBeAttacked == true then
        if IR_Table.TargetCanBeStunned == true then -- Can be true only when Crowd Control spell tracking is enabled
            local readyToCast, stillOnCooldown = IR_Table.get_spell_cooldowns(spells, false)
            for i = 1, #readyToCast do
                LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
            end
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    IR_Table.is_target_casting_interruptible_spell()
                    if IR_Table.IsInterruptible == true then
                        LibButtonGlow.ShowOverlayGlow(stillOnCooldown[i].location)
                    end
                end)
            end
        else
            local readyToCast, stillOnCooldown = IR_Table.get_spell_cooldowns(spells, true)
            for i = 1, #readyToCast do
                LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
            end
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    IR_Table.is_target_casting_interruptible_spell()
                    if IR_Table.IsInterruptible == true then
                        LibButtonGlow.ShowOverlayGlow(stillOnCooldown[i].location)
                    end
                end)
            end
        end
    end
end


---Handles the logic for when the enter players the world (initial login, /reload, or instance load).
function IR_Table.handle_player_entering_world()

    -- Should execute only once during initial character login or /reload
    if IR_Table.InitialLoadDone == false then

        -- If InterruptReminder_IsInit is undefined, set it to false
        if InterruptReminder_Table.IsInit == nil then
            InterruptReminder_Table.IsInit = false
            -- Find the location of those spells on the action bars
            InterruptReminder_Table.ActionBarTable, InterruptReminder_Table.ActionBarSlot = IR_Table.find_all_interrupt_spell(InterruptReminder_Table.spells)
        -- If InterruptReminder_IsInit is true, grab all the spells that can CC and find their locations on the action bar
        elseif InterruptReminder_Table.IsInit == true then
            --[[Timer usage required because part of WoW's API is unavailable during initial character login. Timer will
            execute once the game is in a playable state]]
            C_Timer.After(1, function()
                -- Find the location of those spells on the action bars
                InterruptReminder_Table.ActionBarTable, InterruptReminder_Table.ActionBarSlot = IR_Table.find_all_interrupt_spell(InterruptReminder_Table.spells)
            end)
        end

        -- ACTIONBAR_SLOT_CHANGED is triggered during login, so calling the handler function here to avoid nil scenarios
        C_Timer.After(2, function()
            IR_Table.InitialLoadDone = true
        end)
    end
end


---Handles the logic for when the player updates his action bar. Just checks to make sure he has at least one interrupt
--- available in his action bars and updated their locations.
function IR_Table.handle_player_changing_his_action_bar()
    if IR_Table.InitialLoadDone == true then
        InterruptReminder_Table.ActionBarTable, InterruptReminder_Table.ActionBarSlot = IR_Table.find_all_interrupt_spell(InterruptReminder_Table.spells)
    end
end

---Read the encounter journal for the zone and grab all bosses + boss minions for that zone
local function get_bosses()
    local bestMapForPlayer = C_Map.GetBestMapForUnit('player')
    if bestMapForPlayer ~= nil then
        local encounters = C_EncounterJournal.GetEncountersOnMap(bestMapForPlayer) or {}
        IR_Table.bossInserts = 0
        for _, encounter in pairs(encounters) do
            for i = 1, 9 do
                local name = select(2, EJ_GetCreatureInfo(i, encounter.encounterID))
                if name then
                    InterruptReminder_Table.currentBossList[#InterruptReminder_Table.currentBossList + 1] = name
                    IR_Table.bossInserts = IR_Table.bossInserts + 1
                else
                    break
                end
            end
        end
    end
end

---Keep the boss list at the capacity of 30
local function truncate_boss_list()
    local inserts = IR_Table.bossInserts
    if #InterruptReminder_Table.currentBossList >= 30 then
        for _ = 1, inserts do
            table.remove(InterruptReminder_Table.currentBossList, 1)
        end
    end
end


---Each time the player's zone changes, determine whether the player is currently in the dungeon. If the player is in
--- a dungeon, use C_EncounterJournal.GetEncountersOnMap to grab all the boss fights in the current zone. Each encounter
--- can have a maximum of 9 unit types present. Return 'empty' if the current zone has no bosses.
function IR_Table.handle_zone_changed()
    get_bosses()
    InterruptReminder_Table.currentBossList = remove_duplicates(InterruptReminder_Table.currentBossList)
    truncate_boss_list()
end


---Handles the logic for when the player switches his targets. Unhighlight all spells and check whether the new target
--- is in the process of spell casting already and act accordingly.
function IR_Table.handle_player_switching_targets()
    -- If the interrupt spells were already highlighted, unhighlight them all.
    IR_Table.handle_target_stopped_casting()

    -- Check if the target is valid to attack by the player (e.g. not a friendly player, friendly npc, a pet...)
    if UnitCanAttack('player', 'target') then
        IR_Table.CurrentTargetCanBeAttacked = true
        -- Determine whether the target can be stunned
        IR_Table.is_target_a_boss()
        -- When the player gains his initial target or switches to a target, check whether the target is casting an
        -- interruptible spell, and proceed to handle the highlighting of spells in the action bars
        IR_Table.handle_current_target_spell_casting()
    else
        IR_Table.CurrentTargetCanBeAttacked = false
    end
end

---Handles the logic for when the player initially logs in or does a /reload
function IR_Table.handle_player_login()
    -- Initial values for IR_Table
    IR_Table.EndTime = nil
    IR_Table.StartTime = nil
    IR_Table.IsInterruptible = false
    IR_Table.TargetCanBeStunned = false
    IR_Table.CurrentTargetCanBeAttacked = false

    if InterruptReminder_FirstLaunch == nil then
        InterruptReminder_FirstLaunch = true
        printInfo('First time loading the add-on? Type /irhelp for more information.')
    end

    if InterruptReminder_Table == nil then
        InterruptReminder_Table = {}
        InterruptReminder_Table.spells = IR_Table.InterruptSpells[playerClass]
    end

    CreateInterface()
end


function f:OnEvent(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then IR_Table.handle_player_entering_world()
    elseif (event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START') and ... == 'target' then IR_Table.handle_current_target_spell_casting()
    elseif (event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_STOP' or event == 'UNIT_SPELLCAST_CHANNEL_STOP') and ... == 'target' then IR_Table.handle_target_stopped_casting()
    elseif event == 'PLAYER_TARGET_CHANGED' then IR_Table.handle_player_switching_targets()
    elseif event == 'ACTIONBAR_SLOT_CHANGED' then IR_Table.handle_player_changing_his_action_bar()
    elseif event == 'PLAYER_LOGIN' then IR_Table.handle_player_login()
    elseif (event == 'ZONE_CHANGED_NEW_AREA' or event == 'ZONE_CHANGED_INDOORS' or event == 'ZONE_CHANGED') and InterruptReminder_Table.IsInit == true then IR_Table.handle_zone_changed() end
end


f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('UNIT_SPELLCAST_START')
f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
f:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
f:RegisterEvent('UNIT_SPELLCAST_STOP')
f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
f:RegisterEvent('PLAYER_TARGET_CHANGED')
f:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
f:RegisterEvent('ZONE_CHANGED')
f:RegisterEvent('ZONE_CHANGED_NEW_AREA')
f:RegisterEvent('ZONE_CHANGED_INDOORS')
f:RegisterEvent('PLAYER_LOGIN')
f:SetScript('OnEvent', f.OnEvent)