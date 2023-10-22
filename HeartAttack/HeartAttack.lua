local HA_Table = {}

local f = CreateFrame('Frame', 'HeartAttack')
local start_time
local stopped_walking_ticker
local heart_attack_ticker
local time = time
local IsMounted = IsMounted

local function printInfo(text) print("|cff00ffffInfo (HeartAttack): |cffffffff"..text) end

--Main function that determines whether a heart attack will occur and plays all the actions during heart attack event.
local function do_heart_attack(overwrite)
    overwrite = overwrite or false
    local test = 'wow'
    if test == 'owo' then
        heart_attack_ticker:Cancel()
        heart_attack_ticker = nil
        HeartAttack_GameOver = true
    end
end

--Main function to lower the value of HeartAttack_MaxVal every time the player does an action.
local function subtract_max_val(value)
    local max_val_copy = HeartAttack_MaxVal
    if value == nil then
        max_val_copy = max_val_copy - 1
    else
        max_val_copy = max_val_copy - value
    end
    HeartAttack_MaxVal = max_val_copy
    --In case HeartAttack_MaxVal became 0 or less, initiate heart attack.
    if HeartAttack_MaxVal <= 0 then
        do_heart_attack(true)
    end
end


--[[For every 5 seconds walked, decrease HeartAttack_MaxVal by that much. Reset all values to nil to save memory. If for
 some reason, start_time was nil, just subtract HeartAttack_MaxVal by 1]]
local function calculate_time_walked()
    local end_time = time()
    if start_time ~= nil then
        local total = end_time - start_time
        local division = math.floor(total / 5)
        if division >= 1 then
            subtract_max_val(division)
        end
        start_time = nil
    else
        subtract_max_val()
    end
    stopped_walking_ticker = nil
end

--Handles the logic for when the enter players the world (initial login or /reload).
function HA_Table.handle_player_entering_world()
    if HeartAttack_FirstTimeDone == nil then
        HeartAttack_FirstTimeDone = true
        HeartAttack_GameOver = false
        HeartAttack_MaxVal = 9223372036854775807
        printInfo('First time? Type /hahelp for more information.')
    end
    --Every hour, trigger do_heart_attack to see if the player will experience a heart attack
    if not heart_attack_ticker then
        heart_attack_ticker = C_Timer.NewTicker(3600, do_heart_attack)
    end
end

--[[If the player started walking, save current epoch seconds to start_time. If stopped_walking_ticker was already
active, cancel it and set it to nil and do not reassign start_time]]
function HA_Table.handle_player_started_moving()
    if not IsMounted() then
        if stopped_walking_ticker then
            stopped_walking_ticker:Cancel()
            stopped_walking_ticker = nil
        else
            start_time = time()
        end
    end
end

--If the player stopped walking, start a ticker that will execute calculate_time_walked.
function HA_Table.handle_player_stopped_moving()
    if not IsMounted() then
        if not stopped_walking_ticker then
            stopped_walking_ticker = C_Timer.NewTicker(2.5, calculate_time_walked, 1)
        end
    end
end

--If the player got hit, subtract HeartAttack_MaxVal by 1, otherwise by 2 if the hit was critical or crushing.
function HA_Table.handle_unit_combat(flagText)
    if flagText == nil or flagText == '' or flagText ~= 'GLANCING' then
        subtract_max_val()
    else
        subtract_max_val(2)
    end
end

--[[Once the player unghosts, get the epoch seconds and calculate how many seconds the player was in dead state.
Multiply it by 1.15 and subtract HeartAttack_MaxVal by that much. Set HeartAttack_DeadTime to nil. If for some reason,
HeartAttack_DeadTime was nil, just subtract HeartAttack_MaxVal by 20.]]
function HA_Table.handle_player_alive()
    local revive_time = time()
    if HeartAttack_DeadTime ~= nil then
        local dead_time = HeartAttack_DeadTime
        local time_dead = revive_time - dead_time
        local multiply = math.floor(time_dead * 1.15)
        subtract_max_val(multiply)
        HeartAttack_DeadTime = nil
    else
        subtract_max_val(20)
    end
end

-- If the player died, subtract HeartAttack_MaxVal by 10 and save current epoch seconds in case the player quits.
function HA_Table.handle_player_dead()
    HeartAttack_DeadTime = time()
    subtract_max_val(10)
end


function f:OnEvent(event, arg1, arg2, arg3)
    if HeartAttack_GameOver == false then
        if event == 'PLAYER_ENTERING_WORLD' then HA_Table.handle_player_entering_world() end
        if event == 'PLAYER_STARTED_MOVING' then HA_Table.handle_player_started_moving() end
        if event == 'PLAYER_STOPPED_MOVING' then HA_Table.handle_player_stopped_moving() end
        if event == 'UNIT_COMBAT' and arg1 == 'player' and arg2 == 'WOUND' then HA_Table.handle_unit_combat(arg3) end
        if --[[event == 'PLAYER_ALIVE' or]] event == 'PLAYER_UNGHOST' then HA_Table.handle_player_alive() end
        if event == 'PLAYER_DEAD' then HA_Table.handle_player_dead() end
    end
end


f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('PLAYER_STARTED_MOVING')
f:RegisterEvent('PLAYER_STOPPED_MOVING')
f:RegisterEvent('UNIT_COMBAT')
--[[f:RegisterEvent('PLAYER_ALIVE') Commenting out PLAYER_ALIVE because it triggers when player turns to ghost as well.
Assume revive from other people has magical properties that does not result in scaring.]]
f:RegisterEvent('PLAYER_DEAD')
f:RegisterEvent('PLAYER_UNGHOST')
f:SetScript('OnEvent', f.OnEvent)