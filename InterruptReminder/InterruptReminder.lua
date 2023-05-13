local interruptReminder_ClassInterruptSpell -- Table of class spells that can interrupt
local interruptReminder_SpellActionBarLocation -- Table of the interrupt spell in the action bars
local interruptReminder_IsHighlighted -- Boolean to keep track of whether the spell has been highlighted
local interruptReminder_InitialLoad -- Boolean for whether this is the first load (to counter some nil exceptions)
local interruptReminder_AlreadyWarned -- Boolean to keep track if user has been warned about missing interrupt spell
local interruptReminder_CurrentTargetCanBeAttacked -- Boolean to keep track whether the current target can be attacked
local interruptReminder_ShowOverlayGlow = ActionButton_ShowOverlayGlow
local interruptReminder_HideOverlayGlow = ActionButton_HideOverlayGlow

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

local f = CreateFrame('Frame', 'InterruptReminder')

function f:OnEvent(event, ...)
    self[event](self, event, ...)
end

--[[
Scan all of the player action bars and find the slot location for all interrupting spells for the player's class.
Found in: https://www.wowinterface.com/forums/showthread.php?t=45731 - modified a bit to meet the needs of this addon
--]]
function FindInterruptSpell(spells)
    local actionBars = {'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft', 'MultiBar7', 'MultiBar6', 'MultiBar5'}
    local buttonLocations = {}
    local lowerCases = {}

    for _, spell in ipairs(spells) do
        for _, barName in ipairs(actionBars) do
            for i = 1, 12 do
                lowerCases = {}
                local button = _G[barName .. 'Button' .. i]
                local slot = button:GetPagedID() or button:CalculateAction() or button:GetAttribute('action')
                if HasAction(slot) then
                    local actionType, id, _, actionName = GetActionInfo(slot)
                    if actionType == 'spell' then
                        actionName = GetSpellInfo(id)
                    end
                    if actionName then
                        table.insert(lowerCases, string.lower(actionName))
                        table.insert(lowerCases, string.lower(spell))
                        if string.match(lowerCases[1], lowerCases[2]) then
                            table.insert(buttonLocations, button)
                        end
                    end
                end
            end
        end
    end
    return buttonLocations
end


-- Get the current cooldown on all interrupting spells and save their status to a table
function InterruptReminder_GetSpellCooldowns()
    local onCooldown = {}

    for _, spell in ipairs(interruptReminder_ClassInterruptSpell) do
        local currentCooldown = GetSpellCooldown(spell)
        table.insert(onCooldown, currentCooldown)
    end
    return onCooldown
end

--[[
Check whether the target is attackable, and for every spell the player class has, get the current cooldown status of
that spell. If the interrupting spell is off cooldown, the target's spell being cast is not instant and is
interruptible, then highlight the action bar slot of the spell. Otherwise (if not already), hide the highlight.
--]]
function InterruptReminder_HandleActiveTargetSpellCasting(interruptSpells, startTime, endTime, notInterruptible)
    if interruptReminder_CurrentTargetCanBeAttacked and not notInterruptible and startTime ~= nil and endTime ~= nil then
        for _, cooldownedSpell in ipairs(interruptSpells) do
            if cooldownedSpell == 0 then
                if not interruptReminder_IsHighlighted then
                    for _, location in ipairs(interruptReminder_SpellActionBarLocation) do
                        interruptReminder_ShowOverlayGlow(location)
                    end
                    interruptReminder_IsHighlighted = true
                end
            end
        end
    else
        for _, location in ipairs(interruptReminder_SpellActionBarLocation) do
            interruptReminder_HideOverlayGlow(location)
        end
        interruptReminder_IsHighlighted = false
    end
end

--[[
In case the player switched targets, get whether the current target is either casting or channeling a spell that can
be interrupted.
--]]
function InterruptReminder_HandleSwitchedTargetSpellCasting()
    local name, _, _, startTime, endTime, _, _, notInterruptible, _ = UnitCastingInfo('target')

    if name == nil then
        name, _, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo('target')
    end
    if name ~= nil then
        InterruptReminder_HandleActiveTargetSpellCasting(InterruptReminder_GetSpellCooldowns(), startTime, endTime, notInterruptible)
    end
end

function InterruptReminder_FilterCombatLogsForInterrupts()
    local _, subEvent,_ , sourceGUID, _, _, _, destGUID, _, _, _, _, spellName = CombatLogGetCurrentEventInfo()
    local playerGUID = UnitGUID('player')
    local targetGUID = UnitGUID('target')

    for _, spell in ipairs(interruptReminder_ClassInterruptSpell) do
        if ((subEvent == 'SPELL_CAST_SUCCESS' and sourceGUID == playerGUID and spellName == spell)
                or (subEvent == 'SPELL_CAST_SUCCESS' and sourceGUID == targetGUID)
                or (subEvent == 'SPELL_INTERRUPT') and sourceGUID ~= playerGUID
                and destGUID == targetGUID) then
            for _, location in ipairs(interruptReminder_SpellActionBarLocation) do
                interruptReminder_HideOverlayGlow(location)
            end
            interruptReminder_IsHighlighted = false
        end
    end
end


--[[
On initial load (and when there's a loading screen), read the player class, use a makeshift switch to generate a
list that class' interrupting spells, and find their location in the action bars
--]]
function f:PLAYER_ENTERING_WORLD()
    local playerClass = UnitClass('player')

    interruptReminder_ClassInterruptSpell = interruptReminder_InterruptSpellsSwitch[playerClass]
    interruptReminder_SpellActionBarLocation = FindInterruptSpell(interruptReminder_ClassInterruptSpell)
    interruptReminder_IsHighlighted = false
    interruptReminder_AlreadyWarned = false
    if ipairs(interruptReminder_SpellActionBarLocation) == nil then
        print("|cffffff00Warning (InterruptReminder): |cffffffffInterrupting spell(s) |" .. table.concat(interruptReminder_ClassInterruptSpell, ", ") .. "| not found in the action bar. Please move one to an action bar.")
        if playerClass == 'Warlock' then
            print("|cffffff00Info (InterruptReminder): |cffffffffDetcted that player class is " .. playerClass .. ". Please move the interrupt ability to one of the action bars (not pet action bar) for AddOn to function correctly.")
        end
        interruptReminder_AlreadyWarned = true
    end
    interruptReminder_InitialLoad = true
end

-- Unit starts casting a spell, executes InterruptReminder_HighlightInterruptSpells, which handles ability highlighting
function f:UNIT_SPELLCAST_START()
    local _, _, _, startTime, endTime, _, _, notInterruptible, _ = UnitCastingInfo('target')

    InterruptReminder_HandleActiveTargetSpellCasting(InterruptReminder_GetSpellCooldowns(), startTime, endTime, notInterruptible)
end

-- Same as UNIT_SPELLCAST_START but for channeling spells
function f:UNIT_SPELLCAST_CHANNEL_START()
    local _, _, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo('target')

    InterruptReminder_HandleActiveTargetSpellCasting(InterruptReminder_GetSpellCooldowns(), startTime, endTime, notInterruptible)
end

--[[
If the player has cast his interrupt spell, the target has finished casting his spell, or someone else has interrupted
the target, then remove the overlay.
--]]
function f:COMBAT_LOG_EVENT_UNFILTERED()
    InterruptReminder_FilterCombatLogsForInterrupts()
end

--[[
If the player changed the target, hide the overlay glow, get information about the new target and execute
InterruptReminder_HandleSwitchedTargetActiveCasting, which handles ongoing castings/channeling of new target
--]]
function f:PLAYER_TARGET_CHANGED()
    if interruptReminder_IsHighlighted then
        for _, location in ipairs(interruptReminder_SpellActionBarLocation) do
            interruptReminder_HideOverlayGlow(location)
        end
        interruptReminder_IsHighlighted = false
    end
    if UnitCanAttack('player', 'target') then
        interruptReminder_CurrentTargetCanBeAttacked = true
    else
        interruptReminder_CurrentTargetCanBeAttacked = false
    end
    InterruptReminder_HandleSwitchedTargetSpellCasting()
end

-- Fires when the player has updates his action bar to get the new location of the interrupting spell
function f:ACTIONBAR_SLOT_CHANGED()
    if interruptReminder_InitialLoad then
        if next(interruptReminder_ClassInterruptSpell) ~= nil then
            interruptReminder_SpellActionBarLocation = FindInterruptSpell(interruptReminder_ClassInterruptSpell)
        end
        if next(interruptReminder_SpellActionBarLocation) == nil and not interruptReminder_AlreadyWarned then
            print("|cffffff00Warning (InterruptReminder): |cffffffffInterrupting spell(s) |" .. table.concat(interruptReminder_ClassInterruptSpell, ", ") .. "| not found in the action bar. Please move one to an action bar.")
            interruptReminder_AlreadyWarned = true
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