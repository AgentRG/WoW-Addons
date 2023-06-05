SLASH_INTERRUPT_REMINDER_INIT1 = "/irinit"
SLASH_INTERRUPT_REMINDER_PRINT1 = "/irprint"
SLASH_INTERRUPT_REMINDER_DEL1 = "/irdel"
SLASH_INTERRUPT_REMINDER_HELP1 = "/irhelp"

-- Table from which the add-on retrieves and stores all runtime data about the target, player, and more.
local IR_Table = {}

-- WoW default action bar names
IR_Table.ActionBars = {'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft', 'MultiBar7', 'MultiBar6', 'MultiBar5'}

--All keywords that are found in varying Crowd Control spells
IR_Table.CrownControlTypes = {'knock', 'control', 'confuse', 'fear', 'flee', 'stun', 'incapacit', 'intimidat', 'sleep', 'disorient', 'horr', 'silenc'}

--Spells that will get picked up by generate_cc_spells_table_from_spellbook() because they contain a keyword from CrownControlTypes that we do not want to be added to the list
IR_Table.ExtraneousCCSpells = {
    --Evoker
    'Deep Breath', 'Dream Flight', 'Emerald Communion',
    --Warlock
    'Axe Toss' --[[Interrupt spell]], 'Dark Pact', 'Unending Resolve', 'Grimoire: Felguard',
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
    'Divine Shield', 'Divine Protection', "Justicar's Vengeance", 'Wakes of Ashes' --[[Works on only Demons/Undead]], "Avenger's Shield" --[[Interrupt spell]],
    --Shaman
    'Flame Shock' --[[CC happens when affect is dispelled]], 'Earthquake' --[[Only 5% chance to cause a CC]],
    --Monk
    'Crackling Jade Lightning' --[[Has a low chance to cause CC]], 'Restoral', 'Storm, Earth, and Fire'
}

--Dedicated interrupts for all classes. These spell's primarily goal is to interrupt (with sometimes a secondary effect)
IR_Table.InterruptSpellsSwitch = {
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
IR_Table.CCSpellsSwitch = {}
IR_Table.CCActionBarSlot = {}
IR_Table.DungeonBoss_Names = nil
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
local UnitCanAttack =UnitCanAttack
local C_Map = C_Map
local Enum = Enum

-- Local version of Lua global functions for slightly faster runtime access
local string = string
local table = table
local ipairs = ipairs
local pairs = pairs
local select = select
local print = print
local next = next

local function printInfo(text) print("|cff00ffffInfo (InterruptReminder): |cffffffff"..text) end
local function printWarning(text) print("|cffffff00Warning (InterruptReminder): |cffffffff"..text) end


---Slash command that will initialize tracking of Crowd Control spells
SlashCmdList.INTERRUPT_REMINDER_INIT = function()
    if not InterruptReminder_IsInit then
        IR_Table.generate_cc_spells_table_from_spellbook()
        InterruptReminder_IsInit = true
        printInfo("Interrupt Reminder Crowd Control initialize has initialized. To view saved Crowd Control spells, use /irprint.")
    else
        printWarning("Interrupt Reminder Crowd Control initialize was already initialized and is tracking spell upgrades. To view saved Crowd Control and Interrupt spells, use /irprint.")
    end
end


---Slash command to print all slash commands
SlashCmdList.INTERRUPT_REMINDER_HELP = function()
    print("/irinit: Opt-in for additional tracking of your class' Crowd Control spells.")
    print("/irprint: Print all currently tracked Crowd Control spells as well as the class interrupt spell.")
    print("/irdel: Opt-out of the additional tracking and revert back to only tracking the class interrupt.")
end


---Slash command to print all found Crowd Control spells as well as the interrupt spells. Will work only if /irinit ran.
SlashCmdList.INTERRUPT_REMINDER_PRINT = function()
    if next(IR_Table.CCSpellsSwitch) == nil then
        printWarning("Saved Crowd Control spells were not found. Maybe /irinit was not yet run?")
    else
        local ccTable = IR_Table.CCSpellsSwitch[playerClass]
        if ccTable then
            print('Class: ' .. playerClass)
            for _, spell in ipairs(ccTable) do
                print('  '..spell)
            end
            for _, spellName in ipairs(IR_Table.ClassInterruptSpell) do
                print('  '..spellName)
            end
        end
    end
end


---Slash command to disable Crowd Control spell tracking. Add-on will revert to interrupt only functionality.
SlashCmdList.INTERRUPT_REMINDER_DEL = function()
    IR_Table.CCSpellsSwitch = {}
    InterruptReminder_IsInit = false
    printInfo("Saved Crowd Control spells have been cleared from addon.")
end


---Reads the player's spellbook and grabs all spells capable of causing a Crowd Control (CC) effect to interrupt a spell.
--- Will filter out false positive spells that contain CC keywords like "cleanse a stun". This function can run only after
--- WoW has finished loading the UI. Otherwise, Spell object will be returned as nil.
function IR_Table.generate_cc_spells_table_from_spellbook()
    -- Initialize the table that will store the spells under the player class hash key
    IR_Table.CCSpellsSwitch = {[playerClass] = {}}
    -- Get the total number of tabs under the spellbook
    local numSpellTabs = GetNumSpellTabs()

    -- For each spellbook tab, iterate through all spells, create a Spell object, and get the description of the spell.
    -- If the spell contains a CC keyword and is not a false positive from IR_Table.ExtraneousCCSpells, add it to the
    -- CCSpellsSwitch table.
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
                                table.insert(IR_Table.CCSpellsSwitch[playerClass], spellName)
                                break
                            end
                        end
                    end)
                end
            end
        end
    end
end


---Used when event ACTIONBAR_SLOT_CHANGED is triggered. Checks if that event triggered for a Crowd Control or one of
--- the interrupt spells. Returns true/false. Without this, the event is triggered for any spell that is updated in the
--- action bars.
function IR_Table.is_actionbar_slot_changed_on_interrupt_or_cc_spell(slot)
    if IR_Table.InitialLoadDone then
        local action_bar_slots = {}

        if InterruptReminder_IsInit then
            for _, value in ipairs(IR_Table.InterruptActionBarSlot) do
                table.insert(action_bar_slots, value)
            end

            if next(IR_Table.CCActionBarSlot) == nil and IR_Table.InitialLoadDone == true then
                IR_Table.CombinedSpellTableForTargetsThatCanBeStunned = {}
                IR_Table.generate_cc_spells_table_from_spellbook()
                IR_Table.ClassCCSpell = IR_Table.CCSpellsSwitch[playerClass]
                local i, c = IR_Table.find_all_interrupt_spell(IR_Table.ClassCCSpell)
                IR_Table.CCActionBarTable = i
                IR_Table.CCActionBarSlot = c
                IR_Table.InitialCCLoadDone = true
                for _, value in ipairs(IR_Table.ClassInterruptSpell) do
                    table.insert(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned, value)
                end
                for _, value in ipairs(IR_Table.ClassCCSpell) do
                    table.insert(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned, value)
                end
            end

            for _, value in ipairs(IR_Table.CCActionBarSlot) do
                table.insert(action_bar_slots, value)
            end
        else
            for _, value in ipairs(IR_Table.InterruptActionBarSlot) do
                table.insert(action_bar_slots, value)
            end
        end

        if next(action_bar_slots) ~= nil and tContains(action_bar_slots, slot) then
            return true
        else
            return false
        end
    end
end


---Returns the dungeon ID or false (not a dungeon) depending on the player's current location in the world.
function IR_Table.is_dungeon_instance()
    local currentMapId = C_Map.GetBestMapForUnit("player")
    if currentMapId then
        local mapInfo = C_Map.GetMapInfo(currentMapId)
        if mapInfo and mapInfo.mapType == Enum.UIMapType.Dungeon then
            IR_Table.current_dungeon_map_id = currentMapId
        else
            IR_Table.current_dungeon_map_id = false
        end
        return
    else
        IR_Table.current_dungeon_map_id = false
    end
end


---Algorithm that determines whether the currently selected target is a boss and reassigns IR_Table.TargetCanBeStunned
--- as either true or false depending on the circumstances. Since there is no actual API call to determine whether a
--- target can be stunned, we need to make use of the information we do have access to. For example, units that have
--- a frame around them more likely than not cannot be stunned. When in dungeons, this is troublesome since normal mobs
--- also have a frame around them. To get around that, we are reading IR_Table.DungeonBoss_Names to determine whether
--- the current target is a boss, and therefore cannot be stunned.
---DEV NOTE: Although this works in most cases, even a giant drake in a dungeon that is not a boss will be tagged as
--- stunnable - that cannot be reasonably kept track of without having a huge table of all units that have a non-public
--- flag that makes them stun immune. Basically, if the non-boss minion seems too big to be stunned, it probably is.
function IR_Table.is_target_a_boss()
    --[[ There's a small bug here that I couldn't find a fix for. If the target switched to is nothing, it will still
         pull the target information from the previous target, even though GetUnitName should return nil at that point.
         Luckily, thin air cannot cast spells, so the rest of the addon will still function as intended. ]]
    if InterruptReminder_IsInit then
        local targetName = GetUnitName('target', false)

        if targetName then
            targetName = string.lower(targetName)
        end

        -- Safety measure to make sure current_dungeon_map_id is defined as either a valid dungeon id or false
        if IR_Table.current_dungeon_map_id == nil then
            IR_Table.is_dungeon_instance()
        end

        -- Check to see if the user is currently in a dungeon
        if IR_Table.current_dungeon_map_id ~= false then

            -- Safety measure in case the dungeon boss names has not been defined as either list of bosses or empty
            if IR_Table.DungeonBoss_Names == nil then
                IR_Table.handle_zone_changed()
            end

            -- If handle_zone_changed found that no bosses exist in the current zone, assume the target can be stunned
            if next(IR_Table.DungeonBoss_Names) == 'empty' then
                IR_Table.TargetCanBeStunned = true
            else
                -- Otherwise, check whether the target is a boss. If he's a boss, he's not stunnable.
                if tContains(IR_Table.DungeonBoss_Names, targetName) then
                    IR_Table.TargetCanBeStunned = false
                else
                    IR_Table.TargetCanBeStunned = true
                end
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
function IR_Table.get_spell_cooldowns(spells_table)
    local readyToCast = {}
    local stillOnCooldown = {}

    ---Same as InterruptReminder_find_all_interrupt_spell, but for a single spell. Used when the callback handler is called
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
                local calculateTimeRemaining = (start + duration - GetTime()) + 0.01
                -- Safety check to ensure we don't save a negative number by mistake
                if calculateTimeRemaining > 0 then
                    local endTime = select(4, IR_Table.is_target_casting_spell(IR_Table.CurrentTargetCanBeAttacked))
                    -- Check that the spell will be ready before the spellcast from the target ends
                    if endTime ~= nil and endTime < ((start + duration) * 1000) then
                        table.insert(stillOnCooldown, {['cooldown']=calculateTimeRemaining, ['location']=spellLocation})
                    end
                end
            end
        end
    end
    return readyToCast, stillOnCooldown
end


---Check if two tables are equal before continuing with the function which this used in.
function IR_Table.are_two_tables_equal(t1, t2)
    if #t1 ~= #t2 then return false end

    for k, v in pairs(t1) do
        if v ~= t2[k] then
            return false
        end
    end
    return true
end


---Checks if the target is casting or channeling a spell.
---Parameters:
--- targetCanBeAttacked (boolean): Indicates whether the target can be attacked.
---Returns:
--- the saved variables for targetCanBeAttacked, notInterruptible, startTime, endTime or false if no spell is being cast.
function IR_Table.is_target_casting_spell(targetCanBeAttacked)
    local name, _, _, startTime, endTime, _, _, notInterruptible, _ = UnitCastingInfo('target')
    if name == nil then
        name, _, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo('target')
    end
    -- Safety measure to make sure a nil is not returned somehow
    if name ~= nil then
        return targetCanBeAttacked, notInterruptible, startTime, endTime
    else
        return false
    end
end


---Handles the unhighlight of spells.
function IR_Table.handle_target_stopped_casting()
    if IR_Table.PlayerInCombat == true then
        IR_Table.handle_player_changing_his_action_bar()
    end
    for _, location in ipairs(IR_Table.InterruptActionBarTable) do
        LibButtonGlow.HideOverlayGlow(location)
    end
    if InterruptReminder_IsInit then
        for _, location in ipairs(IR_Table.CCActionBarTable) do
            LibButtonGlow.HideOverlayGlow(location)
        end
    end
    IR_Table.IsHighlighted = false
end


---Handles the logic for highlighting interruptible spells on the current target (whether target can be interrupted is
--- deduced during PLAYER_TARGET_CHANGED event).
---In case a spell is not in cooldown, highlight the spell at its action bar location.
---In case a spell is in cooldown, use C_Timer.After to check whether by the time it is off cooldown, that target
--- can still be interrupted, in which case it will highlight the ability at its location.
function IR_Table.handle_current_target_spell_casting()
    local isSpellNotInterruptible = select(2, IR_Table.is_target_casting_spell(IR_Table.CurrentTargetCanBeAttacked))
    if isSpellNotInterruptible == false then
        if IR_Table.TargetCanBeStunned then
            local readyToCast = IR_Table.get_spell_cooldowns(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned)
            for i = 1, #readyToCast do
                if IR_Table.IsHighlighted ~= true then
                    LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
                end
            end
            local stillOnCooldown = select(2, IR_Table.get_spell_cooldowns(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned))
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    if select(2, IR_Table.is_target_casting_spell(IR_Table.CurrentTargetCanBeAttacked)) == false then
                        if IR_Table.IsHighlighted ~= true then
                            LibButtonGlow.ShowOverlayGlow(stillOnCooldown[i].location)
                        end
                    end
                end)
            end
        else
            local readyToCast = IR_Table.get_spell_cooldowns(IR_Table.ClassInterruptSpell)
            for i = 1, #readyToCast do
                if IR_Table.IsHighlighted ~= true then
                    LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
                end
            end
            local stillOnCooldown = select(2, IR_Table.get_spell_cooldowns(IR_Table.ClassInterruptSpell))
            for i = 1, #stillOnCooldown do
                C_Timer.After(stillOnCooldown[i].cooldown, function()
                    if select(2, IR_Table.is_target_casting_spell(IR_Table.CurrentTargetCanBeAttacked)) == false then
                        if IR_Table.IsHighlighted ~= true then
                            LibButtonGlow.ShowOverlayGlow(stillOnCooldown[i].location)
                        end
                    end
                end)
            end
        end
        IR_Table.IsHighlighted = true
    end
end


---Handles the logic for when the enter players the world (initial login or /reload).
function IR_Table.handle_player_entering_world()

    -- This should execute only once in addon's lifetime.
    if InterruptReminder_FirstLaunch == nil then
        InterruptReminder_FirstLaunch = true
        printInfo('First time loading the add-on? Type /irhelp for more options.')
    end

    -- Should execute only once during initial character login or /reload
    if IR_Table.InitialLoadDone == false then

        -- Grab the player's interrupt spells based on playerClass and the makeshift switch
        IR_Table.ClassInterruptSpell = IR_Table.InterruptSpellsSwitch[playerClass]

        -- Find the location of those spells on the action bars
        local j, k = IR_Table.find_all_interrupt_spell(IR_Table.ClassInterruptSpell)
        IR_Table.InterruptActionBarTable = j
        IR_Table.InterruptActionBarSlot = k

        -- If InterruptReminder_IsInit is undefined, set it to false
        if InterruptReminder_IsInit == nil then
            InterruptReminder_IsInit = false
        -- If InterruptReminder_IsInit is true, grab all the spells that can CC and find their locations on the action bar
        elseif InterruptReminder_IsInit == true then
            --[[Timer usage required because part of WoW's API is unavailable during initial character login. Timer will
            execute once the game is in a playable state]]
            C_Timer.After(1, function()
                IR_Table.CombinedSpellTableForTargetsThatCanBeStunned = {}
                IR_Table.generate_cc_spells_table_from_spellbook()
                IR_Table.ClassCCSpell = IR_Table.CCSpellsSwitch[playerClass]
                local i, c = IR_Table.find_all_interrupt_spell(IR_Table.ClassCCSpell)
                IR_Table.CCActionBarTable = i
                IR_Table.CCActionBarSlot = c
                IR_Table.InitialCCLoadDone = true
                for _, value in ipairs(IR_Table.ClassInterruptSpell) do
                    table.insert(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned, value)
                end
                for _, value in ipairs(IR_Table.ClassCCSpell) do
                    table.insert(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned, value)
                end
            end)
        end

        -- Initial values for interruptReminder_Table
        IR_Table.IsHighlighted = false
        IR_Table.AlreadyWarned = false
        IR_Table.TargetCanBeStunned = false
        IR_Table.CurrentTargetCanBeAttacked = false
        IR_Table.PlayerInCombat = false


        -- Check if the action bars do not contain any interrupt spell, in which case a warning will be thrown
        if #IR_Table.InterruptActionBarTable == 0 then
            local tableConcat = table.concat(IR_Table.ClassInterruptSpell, ", ")
            printWarning("Interrupting spell(s) |" .. tableConcat .. "| not found in the action bar. Please move one to an action bar.")
            if playerClass == 'Warlock' then
                printInfo("Detected that player class is " .. playerClass .. ". Please move the interrupt ability to one of the action bars (not pet action bar) for AddOn to function correctly.")
            end
            IR_Table.AlreadyWarned = true
        end

        -- ACTIONBAR_SLOT_CHANGED is triggered during login, so calling the handler function here to avoid nil scenarios
        C_Timer.After(2, function()
            IR_Table.is_actionbar_slot_changed_on_interrupt_or_cc_spell()
            IR_Table.InitialLoadDone = true
        end)
    end
    if InterruptReminder_IsInit then
        IR_Table.handle_zone_changed()
    end
end


---Handles the logic for when the player updates his action bar. Just checks to make sure he has at least one interrupt
--- available in his action bars and updated their locations.
function IR_Table.handle_player_changing_his_action_bar()
    if IR_Table.InitialLoadDone then
        local i, c

        -- Find the location of those spells on the action bars
        local j, k = IR_Table.find_all_interrupt_spell(IR_Table.ClassInterruptSpell)
        if IR_Table.are_two_tables_equal(j, IR_Table.InterruptActionBarTable) == false then
            break
        else
            i, c = IR_Table.find_all_interrupt_spell(IR_Table.ClassCCSpell)
            if IR_Table.are_two_tables_equal(i, IR_Table.CCActionBarTable) == false then
                break
            else
                IR_Table.InterruptActionBarTable = j
                IR_Table.InterruptActionBarSlot = k

                -- If InterruptReminder_IsInit is true, grab all the spells that can CC and find their locations on the action bar
                if InterruptReminder_IsInit == true then
                    --[[Timer usage required because part of WoW's API is unavailable during initial character login. Timer will
                    execute once the game is in a playable state]]
                    IR_Table.CombinedSpellTableForTargetsThatCanBeStunned = {}
                    IR_Table.generate_cc_spells_table_from_spellbook()
                    IR_Table.ClassCCSpell = IR_Table.CCSpellsSwitch[playerClass]
                    IR_Table.CCActionBarTable = i
                    IR_Table.CCActionBarSlot = c
                    IR_Table.InitialCCLoadDone = true
                    for _, value in ipairs(IR_Table.ClassInterruptSpell) do
                        table.insert(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned, value)
                    end
                    for _, value in ipairs(IR_Table.ClassCCSpell) do
                        table.insert(IR_Table.CombinedSpellTableForTargetsThatCanBeStunned, value)
                    end
                end
            end
        end

        if IR_Table.InterruptActionBarTable == 0 and not IR_Table.AlreadyWarned then
            local tableConcat = table.concat(IR_Table.ClassInterruptSpell, ", ")
            printWarning("Interrupting spell(s) |" .. tableConcat .. "| not found in the action bar. Please move one to an action bar.")
            IR_Table.AlreadyWarned = true
        end
    end
end


---Each time the player's zone changes, determine whether the player is currently in the dungeon. If the player is in
--- a dungeon, use C_EncounterJournal.GetEncountersOnMap to grab all the boss fights in the current zone. Each encounter
--- can have a maximum of 9 unit types present. Return 'empty' if the current zone has no bosses.
function IR_Table.handle_zone_changed()
    IR_Table.is_dungeon_instance()
    IR_Table.DungeonBoss_Names = {}
    if IR_Table.current_dungeon_map_id ~= false then
        local name
        local dungeonBossIDs = C_EncounterJournal.GetEncountersOnMap(IR_Table.current_dungeon_map_id) or {}
        for _, encounter in pairs(dungeonBossIDs) do
            for i = 1, 9 do
                name = select(2, EJ_GetCreatureInfo(i, encounter.encounterID))
                if name then
                    table.insert(IR_Table.DungeonBoss_Names, string.lower(name))
                else
                    break
                end
            end
        end
    end
    if next(IR_Table.DungeonBoss_Names) == nil then
        table.insert(IR_Table.DungeonBoss_Names, 'empty')
    end
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


function IR_Table.handle_player_entering_combat() IR_Table.PlayerInCombat = true end
function IR_Table.handle_player_leaving_combat() IR_Table.PlayerInCombat = false end


function f:OnEvent(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then IR_Table.handle_player_entering_world() end
    if (event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START') and ... == 'target' then IR_Table.handle_current_target_spell_casting() end
    if (event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_STOP' or event == 'UNIT_SPELLCAST_CHANNEL_STOP') and ... == 'target' then IR_Table.handle_target_stopped_casting() end
    if event == 'PLAYER_TARGET_CHANGED' then IR_Table.handle_player_switching_targets() end
    if event == 'ACTIONBAR_SLOT_CHANGED' and IR_Table.is_actionbar_slot_changed_on_interrupt_or_cc_spell(...) and IR_Table.PlayerInCombat == false then IR_Table.handle_player_changing_his_action_bar() end
    if (event == 'ZONE_CHANGED_NEW_AREA' or event == 'ZONE_CHANGED_INDOORS' or event == 'ZONE_CHANGED') and InterruptReminder_IsInit then IR_Table.handle_zone_changed() end
    if event == 'PLAYER_REGEN_DISABLED' then IR_Table.handle_player_entering_combat() end
    if event == 'PLAYER_REGEN_ENABLED' then IR_Table.handle_player_leaving_combat() end
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
f:RegisterEvent('PLAYER_REGEN_DISABLED')
f:RegisterEvent('PLAYER_REGEN_ENABLED')
f:SetScript('OnEvent', f.OnEvent)