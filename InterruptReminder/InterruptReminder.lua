local interruptReminder_Table = {}

local f = CreateFrame('Frame', 'InterruptReminder')
local LibButtonGlow = LibStub("LibButtonGlow-1.0")

function f:OnEvent(event, ...)
    self[event](self, event, ...)
end


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


---Same as InterruptReminder_find_all_interrupt_spell, but for a single spell
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
        if start == 0 then
            table.insert(readyToCast, {['cooldown']=start, ['location']=spellLocation})
        end
        if start ~= 0 then
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
    return targetCanBeAttacked and not notInterruptible and startTime ~= nil and endTime ~= nil
end


---Handles the logic for highlighting interruptible spells on the active target (whether target can be interrupted is
--- deduced during PLAYER_TARGET_CHANGED event).
---In case a spell is not in cooldown, highlight the spell at its action bar location.
---In case a spell is in cooldown, use C_Timer.After to check whether by the time it is off cooldown, that target
--- can still be interrupted, in which case it will highlight the ability at its location.
local function handle_active_target_spell_casting()
    local targetHighlighted = interruptReminder_Table['IsHighlighted']
    local readyToCast, stillOnCooldown = get_spell_cooldowns(interruptReminder_Table['ClassInterruptSpell'])

    if is_target_casting_interruptible_spell(interruptReminder_Table['CurrentTargetCanBeAttacked']) then
        for i = 1, #readyToCast do
            if not targetHighlighted then
                LibButtonGlow.ShowOverlayGlow(readyToCast[i].location)
            end
            interruptReminder_Table['IsHighlighted'] = true
        end
    end

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


---Filter combat logs to detect interrupts (or successful target casts) on the target to hide the highlighting on all spell action bar locations
local function filter_combat_logs_for_interrupts()
    local subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, _, spellName = select(2, CombatLogGetCurrentEventInfo())
    local classInterruptSpells = interruptReminder_Table['ClassInterruptSpell']
    local spellActionBarLocation = interruptReminder_Table['SpellActionBarLocation']
    local isHighlighted = interruptReminder_Table['IsHighlighted']
    local playerGUID = UnitGUID('player')
    local targetGUID = UnitGUID('target')

    -- Used to determine interrupt cases
    local spellCastSuccessEvent = (subEvent == 'SPELL_CAST_SUCCESS')
    local isPlayerSource = (sourceGUID == playerGUID)
    local isTargetSource = (sourceGUID == targetGUID)
    local isInterruptEvent = (subEvent == 'SPELL_INTERRUPT')
    local isOutsideInterrupt = (sourceGUID ~= playerGUID and destGUID == targetGUID)

    for _, spell in ipairs(classInterruptSpells) do
        if ((spellCastSuccessEvent and isPlayerSource and spellName == spell)
                or (spellCastSuccessEvent and isTargetSource)
                or (isInterruptEvent and isOutsideInterrupt))then
            if isHighlighted then
                for _, location in ipairs(spellActionBarLocation) do
                    LibButtonGlow.HideOverlayGlow(location)
                end
            end
            interruptReminder_Table['IsHighlighted'] = false
            break
        end
    end
end


---Triggers when the player enters the world (or any phase, or on /reload)
function f:PLAYER_ENTERING_WORLD()
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

function f:UNIT_SPELLCAST_START() handle_active_target_spell_casting() end

function f:UNIT_SPELLCAST_CHANNEL_START() handle_active_target_spell_casting() end

function f:COMBAT_LOG_EVENT_UNFILTERED() filter_combat_logs_for_interrupts() end


---Triggers when the player changes his target (or gains one)
function f:PLAYER_TARGET_CHANGED()
    local targetHighlighted = interruptReminder_Table['IsHighlighted']
    local spellActionBarLocation = interruptReminder_Table['SpellActionBarLocation']

    -- If the interrupt spells were already highlighted, unhighlight them all.
    if targetHighlighted then
        for _, location in ipairs(spellActionBarLocation) do
            LibButtonGlow.HideOverlayGlow(location)
        end
        interruptReminder_Table['IsHighlighted'] = false
    end

    -- Check if the target is valid to attack by the player (e.g. not a friendly player, friendly npc, a pet...)
    if UnitCanAttack('player', 'target') then
        interruptReminder_Table['CurrentTargetCanBeAttacked'] = true
    else
        interruptReminder_Table['CurrentTargetCanBeAttacked'] = false
    end

    -- When the player gains his initial target or switches to a target, check whether the target is casting an
    -- interruptible spell, and proceed to handle the highlighting of spells in the action bars
    handle_active_target_spell_casting()
end


---Triggers when the player updates his action bar. Checks if the interrupt spells are still there and throws a warning
--- if they are missing. Warning will not be thrown as long as at least one is present.
function f:ACTIONBAR_SLOT_CHANGED()
    local initialLoad = interruptReminder_Table['InitialLoad']
    local classInterruptSpells = interruptReminder_Table['ClassInterruptSpell']
    local alreadyWarned = interruptReminder_Table['AlreadyWarned']

    if initialLoad then
        if next(classInterruptSpells) ~= nil then
            interruptReminder_Table['SpellActionBarLocation'] = find_all_interrupt_spell(classInterruptSpells)
        end
        if next(interruptReminder_Table['SpellActionBarLocation']) == nil and not alreadyWarned then
            local tableConcat = table.concat(interruptReminder_Table['ClassInterruptSpell'], ", ")
            print("|cffffff00Warning (InterruptReminder): |cffffffffInterrupting spell(s) |" .. tableConcat .. "| not found in the action bar. Please move one to an action bar.")
            interruptReminder_Table['AlreadyWarned'] = true
        end
    end
end

f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('UNIT_SPELLCAST_START')
f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
f:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
f:RegisterEvent('PLAYER_TARGET_CHANGED')
f:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
f:SetScript('OnEvent', f.OnEvent)