local INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL -- Table of class spells that can interrupt
local INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION -- Table of the interrupt spell in the action bars
local INTERRUPT_REMINDER_IS_HIGHLIGHTED -- Boolean to keep track of whether the spell has been highlighted
local INTERRUPT_REMINDER_INITIAL_LOAD -- Boolean for whether this is the first load (to counter some nil exceptions)
local INTERRUPT_REMINDER_ALREADY_WARNED -- Boolean to keep track if user has been warned about missing interrupt spell

local f = CreateFrame("Frame")

function f:OnEvent(event, ...)
    self[event](self, event, ...)
end

--[[
Scan all of the player action bars and find the slot location for all interrupting spells for the player's class.
Found in: https://www.wowinterface.com/forums/showthread.php?t=45731 - modified a bit to meet the needs of this mod
--]]
function FindInterruptSpell(spells)
    local actionBars = {"Action", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MultiBar7", "MultiBar6", "MultiBar5"}
    local buttonLocations = {}
    for _, spell in ipairs(spells) do
        for _, barName in ipairs(actionBars) do
            for i = 1, 12 do
                local button = _G[barName .. 'Button' .. i]
                local slot = button:GetPagedID() or button:CalculateAction() or button:GetAttribute('action')
                if HasAction(slot) then
                    local actionType, id, _, actionName = GetActionInfo(slot)
                    if actionType == "spell" then
                        actionName = GetSpellInfo(id)
                    end
                    if actionName and string.match(string.lower(actionName), string.lower(spell)) then
                        table.insert(buttonLocations, button)
                    end
                end
            end
        end
    end
    return buttonLocations
end

--[[
On initial load (and when there's a loading screen), read the player class, use a makeshift switch to generate a
list that class' interrupting spells, and find their location in the action bars
--]]
function f:PLAYER_ENTERING_WORLD()
    local playerClass = UnitClass("player")
    local switch = {
        ["Death Knight"] = {"Mind Freeze", "Asphyxiate", "Strangulate", "Death Grip"},
        ["Demon Hunter"] = {"Disrupt"},
        ["Druid"] = {"Skull Bash", "Solar Beam"},
        ["Evoker"] = {"Quell"},
        ["Hunter"] = {"Counter Shot", "Muzzle"},
        ["Mage"] = {"Counterspell"},
        ["Monk"] = {"Spear Hand Strike"},
        ["Paladin"] = {"Rebuke", "Avenger's Shield"},
        ["Priest"] = {"Silence"},
        ["Rogue"] = {"Kick"},
        ["Shaman"] = {"Wind Shear"},
        ["Warlock"] = {"Spell Lock", "Optical Blast", "Axe Toss"},
        ["Warrior"] = {"Pummel"}
    }
    INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL = switch[playerClass]
    INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION = FindInterruptSpell(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL)
    INTERRUPT_REMINDER_IS_HIGHLIGHTED = 0
    INTERRUPT_REMINDER_ALREADY_WARNED = 0
    if next(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) == nil then
        print("|cffffff00Warning (InterruptReminder): |cffffffffInterrupting spell(s) |" .. table.concat(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL, ", ") .. "| not found in the action bar. Please move one to an action bar.")
        if playerClass == "Warlock" then
            print("|cffffff00Info (InterruptReminder): |cffffffffDetcted that player class is " .. playerClass .. ". Please move the interrupt ability to one of the action bars (not pet action bar) for AddOn to function correctly.")
        end
        INTERRUPT_REMINDER_ALREADY_WARNED = 1
    end
    INTERRUPT_REMINDER_INITIAL_LOAD = 1
end

--[[
Check whether the target is attackable, and for every spell the player class has, get the current cooldown status of
that spell. If the interrupting spell is off cooldown, the target's spell being cast is not instant and is
interruptible, then highlight the action bar slot of the spell. Otherwise (if not already), hide the highlight.
--]]
function f:UNIT_SPELLCAST_START()
    local attackable = UnitCanAttack("player", "target")
    local onCooldown = {}
    for _, spell in ipairs(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL) do
        local startTime = GetSpellCooldown(spell)
        table.insert(onCooldown, startTime)
    end
    local _, _, _, startTime, endTime, _, _, notInterruptible, _ = UnitCastingInfo("target")
    if attackable and not notInterruptible and startTime ~= nil and endTime ~= nil then
        for _, cooldownedSpell in ipairs(onCooldown) do
            if cooldownedSpell == 0 then
                if INTERRUPT_REMINDER_IS_HIGHLIGHTED == 0 then
                    for _, location in ipairs(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) do
                        ActionButton_ShowOverlayGlow(location)
                    end
                    INTERRUPT_REMINDER_IS_HIGHLIGHTED = 1
                end
            end
        end
    else
        for _, location in ipairs(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) do
            ActionButton_HideOverlayGlow(location)
        end
        INTERRUPT_REMINDER_IS_HIGHLIGHTED = 0
    end
end

-- Same as UNIT_SPELLCAST_START but for channeling spells
function f:UNIT_SPELLCAST_CHANNEL_START()
    local attackable = UnitCanAttack("player", "target")
    local onCooldown = {}
    for _, spell in ipairs(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL) do
        local startTime = GetSpellCooldown(spell)
        table.insert(onCooldown, startTime)
    end
    local _, _, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo("target")
    if attackable and not notInterruptible and startTime ~= nil and endTime ~= nil then
        for _, cooldownedSpell in ipairs(onCooldown) do
            if cooldownedSpell == 0 then
                if INTERRUPT_REMINDER_IS_HIGHLIGHTED == 0 then
                    for _, location in ipairs(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) do
                        ActionButton_ShowOverlayGlow(location)
                    end
                    INTERRUPT_REMINDER_IS_HIGHLIGHTED = 1
                end
            end
        end
    else
        for _, location in ipairs(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) do
            ActionButton_HideOverlayGlow(location)
        end
        INTERRUPT_REMINDER_IS_HIGHLIGHTED = 0
    end
end

--[[
If the player has cast his interrupt spell, the target has finished casting his spell, or someone else has interrupted
the target, then remove the overlay.
--]]
function f:COMBAT_LOG_EVENT_UNFILTERED()
    local _, subEvent,_ , sourceGUID, _, _, _, destGUID, _, _, _, _, spellName = CombatLogGetCurrentEventInfo()
    for _, spell in ipairs(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL) do
        if ((subEvent == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") and spellName == spell)
                or (subEvent == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("target"))
                or (subEvent == "SPELL_INTERRUPT") and sourceGUID ~= UnitGUID("player")
                and destGUID == UnitGUID("target")) then
            for _, location in ipairs(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) do
                ActionButton_HideOverlayGlow(location)
            end
            INTERRUPT_REMINDER_IS_HIGHLIGHTED = 0
        end
    end
end

-- If the player changed the target, hide the overlay glow
function f:PLAYER_TARGET_CHANGED()
    if (INTERRUPT_REMINDER_IS_HIGHLIGHTED == 1) then
        for _, location in ipairs(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) do
            ActionButton_HideOverlayGlow(location)
        end
        INTERRUPT_REMINDER_IS_HIGHLIGHTED = 0
    end
end

-- Fires when the player has updates his action bar to get the new location of the interrupting spell
function f:ACTIONBAR_SLOT_CHANGED()
    if INTERRUPT_REMINDER_INITIAL_LOAD == 1 then
        if next(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL) ~= nil then
            INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION = FindInterruptSpell(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL)
        end
        if next(INTERRUPT_REMINDER_SPELL_ACTION_BAR_LOCATION) == nil and INTERRUPT_REMINDER_ALREADY_WARNED == 0 then
            print("|cffffff00Warning (InterruptReminder): |cffffffffInterrupting spell(s) |" .. table.concat(INTERRUPT_REMINDER_CLASS_INTERRUPT_SPELL, ", ") .. "| not found in the action bar. Please move one to an action bar.")
            INTERRUPT_REMINDER_ALREADY_WARNED = 1
        end
    end
end

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_SPELLCAST_START")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
f:SetScript("OnEvent", f.OnEvent)