local interruptReminder_Table = {}

local f = CreateFrame('Frame', 'InterruptReminder')
local LibButtonGlow = LibStub("LibButtonGlow-1.0")


---Scan all of the player action bars and find the slot location for all interrupting spells for the player's class.
--- Found in: https://www.wowinterface.com/forums/showthread.php?t=45731 - modified a bit to meet the needs of this addon
local function find_all_interrupt_spell(spells)
    local actionBars = {'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft', 'MultiBar7', 'MultiBar6', 'MultiBar5'}
    local buttonLocations = {}

    for _, spell in ipairs(spells) do
        for _, barName in ipairs(actionBars) do
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
                            table.insert(buttonLocations, button)
                        end
                    end
                end
            end
        end
    end
    return buttonLocations
end


---Same as InterruptReminder_find_all_interrupt_spell, but for a single spell. Used when the callback handler is called
--- in case a spell was on cooldown.
local function find_interrupt_spell(spell)
    local actionBars = {'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft', 'MultiBar7', 'MultiBar6', 'MultiBar5'}

    for _, barName in ipairs(actionBars) do
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
local function get_spell_cooldowns(class_spells)
    local readyToCast = {}
    local stillOnCooldown = {}

    for i = 1, #class_spells do
        local start, duration = GetSpellCooldown(class_spells[i])
        local spellLocation = find_interrupt_spell(class_spells[i])
        if start == 0 and start then
            table.insert(readyToCast, {['cooldown']=start, ['location']=spellLocation})
        end
        if start ~= 0 and start then
            -- Add a 0.01 overhead to ensure the spell gets highlighted after it is off cooldown
            local calculateTimeRemaining = (start + duration - GetTime()) + 0.01
            -- Safety check to ensure we don't save a negative number by mistake
            if calculateTimeRemaining > 0 then
                table.insert(stillOnCooldown, {['cooldown']=calculateTimeRemaining, ['location']=spellLocation})
            end
        end
    end
    return readyToCast, stillOnCooldown
end


---Checks if the target is casting interruptible or channeling a spell that can be interrupted.
---Parameters:
--- targetCanBeAttacked (boolean): Indicates whether the target can be attacked.
---Returns:
--- (boolean) Whether the target is casting or channeling a spell that can be interrupted.
local function is_target_casting_interruptible_spell(targetCanBeAttacked)
    local name, _, _, startTime, endTime, _, _, notInterruptible, _ = UnitCastingInfo('target')
    if name == nil then
        name, _, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo('target')
    end
    -- Safety measure to make sure a nil is not returned somehow
    if name ~= nil then
        return targetCanBeAttacked and not notInterruptible and startTime ~= nil and endTime ~= nil
    else
        return false
    end
end


---Handles the unhighlight of the interrupt spells. Executes only if the spells are already highlighted.
local function handle_target_stopped_casting()
    if interruptReminder_Table['IsHighlighted'] then
        for _, location in ipairs(interruptReminder_Table['SpellActionBarLocation']) do
            LibButtonGlow.HideOverlayGlow(location)
        end
        interruptReminder_Table['IsHighlighted'] = false
    end
end


---Handles the logic for highlighting interruptible spells on the current target (whether target can be interrupted is
--- deduced during PLAYER_TARGET_CHANGED event).
---In case a spell is not in cooldown, highlight the spell at its action bar location.
---In case a spell is in cooldown, use C_Timer.After to check whether by the time it is off cooldown, that target
--- can still be interrupted, in which case it will highlight the ability at its location.
local function handle_current_target_spell_casting()
    local targetHighlighted = interruptReminder_Table['IsHighlighted']

    if is_target_casting_interruptible_spell(interruptReminder_Table['CurrentTargetCanBeAttacked']) then
        local readyToCast = get_spell_cooldowns(interruptReminder_Table['ClassInterruptSpell'])
        for i = 1, #readyToCast do
            if not targetHighlighted then
                LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
            end
            interruptReminder_Table['IsHighlighted'] = true
        end
    end

    local stillOnCooldown = select(2, get_spell_cooldowns(interruptReminder_Table['ClassInterruptSpell']))
    for i = 1, #stillOnCooldown do
        C_Timer.After(stillOnCooldown[i].cooldown, function()
            targetHighlighted = interruptReminder_Table['IsHighlighted']
            if is_target_casting_interruptible_spell(interruptReminder_Table['CurrentTargetCanBeAttacked']) then
                if not targetHighlighted then
                    LibButtonGlow.ShowOverlayGlow(stillOnCooldown[i].location)
                end
                interruptReminder_Table['IsHighlighted'] = true
            end
        end)
    end
end


---Handles the logic for when the enter players the world (initial login, phase change, or /reload). Grabs the player
--- class and gets the class' interrupt spells via a makeshift switch. Then saves some default values and checks
--- whether the action bars contain any of the interrupting spells. Throws a warning if there's no spell found.
local function handle_player_entering_world()
    local playerClass = UnitClass('player')
    -- Makeshift switch to map each class' interrupt spells to a class
    local interruptReminder_InterruptSpellsSwitch = {
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
    -- Grab the player's interrupt spells based on playerClass and the makeshift switch
    interruptReminder_Table['ClassInterruptSpell'] = interruptReminder_InterruptSpellsSwitch[playerClass]

    -- Find the location of those spells on the action bars
    interruptReminder_Table['SpellActionBarLocation'] = find_all_interrupt_spell(interruptReminder_Table['ClassInterruptSpell'])

    -- Initial values for interruptReminder_Table
    interruptReminder_Table['IsHighlighted'] = false
    interruptReminder_Table['AlreadyWarned'] = false
    interruptReminder_Table['CurrentTargetCanBeAttacked'] = false

    -- Check if the action bars do not contain any interrupt spell, in which case a warning will be thrown
    if next(interruptReminder_Table['SpellActionBarLocation']) == nil then
        local tableConcat = table.concat(interruptReminder_Table['ClassInterruptSpell'], ", ")
        print("|cffffff00Warning (InterruptReminder): |cffffffffInterrupting spell(s) |" .. tableConcat .. "| not found in the action bar. Please move one to an action bar.")
        if playerClass == 'Warlock' then
            print("|cffffff00Info (InterruptReminder): |cffffffffDetcted that player class is " .. playerClass .. ". Please move the interrupt ability to one of the action bars (not pet action bar) for AddOn to function correctly.")
        end
        interruptReminder_Table['AlreadyWarned'] = true
    end
    interruptReminder_Table['InitialLoad'] = true
end


---Handles the logic for when the player switches his targets. Unhighlight all spells and check whether the new target
--- is in the process of spell casting already and act accordingly.
local function handle_player_switching_targets()

    -- If the interrupt spells were already highlighted, unhighlight them all.
    handle_target_stopped_casting()

    -- Check if the target is valid to attack by the player (e.g. not a friendly player, friendly npc, a pet...)
    if UnitCanAttack('player', 'target') then
        interruptReminder_Table['CurrentTargetCanBeAttacked'] = true
        -- When the player gains his initial target or switches to a target, check whether the target is casting an
        -- interruptible spell, and proceed to handle the highlighting of spells in the action bars
        handle_current_target_spell_casting()
    else
        interruptReminder_Table['CurrentTargetCanBeAttacked'] = false
    end
end


---Handles the logic for when the player updates his action bar. Just checks to make sure he has at least one interrupt
--- available in his action bars.
local function handle_player_changing_his_action_bar()

    if interruptReminder_Table['InitialLoad'] then
        local classInterruptSpells = interruptReminder_Table['ClassInterruptSpell']
        if next(classInterruptSpells) ~= nil then
            interruptReminder_Table['SpellActionBarLocation'] = find_all_interrupt_spell(classInterruptSpells)
        end
        if next(interruptReminder_Table['SpellActionBarLocation']) == nil and not interruptReminder_Table['AlreadyWarned'] then
            local tableConcat = table.concat(interruptReminder_Table['ClassInterruptSpell'], ", ")
            print("|cffffff00Warning (InterruptReminder): |cffffffffInterrupting spell(s) |" .. tableConcat .. "| not found in the action bar. Please move one to an action bar.")
            interruptReminder_Table['AlreadyWarned'] = true
        end
    end
end


function f:OnEvent(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then handle_player_entering_world() end
    if (event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START') and ... == 'target' then handle_current_target_spell_casting() end
    if (event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_STOP' or event == 'UNIT_SPELLCAST_CHANNEL_STOP') and ... == 'target' then handle_target_stopped_casting() end
    if event == 'PLAYER_TARGET_CHANGED' then handle_player_switching_targets() end
    if event == 'ACTIONBAR_SLOT_CHANGED' then handle_player_changing_his_action_bar() end
end


f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('UNIT_SPELLCAST_START')
f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
f:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
f:RegisterEvent('UNIT_SPELLCAST_STOP')
f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
f:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
f:RegisterEvent('PLAYER_TARGET_CHANGED')
f:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
f:SetScript('OnEvent', f.OnEvent)