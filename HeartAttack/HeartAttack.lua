local HA_Table = {}

local f = CreateFrame('Frame', 'HeartAttack')
local walk_start_time
local turn_start_time
local stopped_walking_ticker
local stopped_turning_ticker
local initial_world_load = false
local bag_lock = false
local heart_attack_ticker
local math = math
local int32 = 2147483647
local player_guid
local time = time
local tContains = tContains
local chat_types = {'CHAT_MSG_SAY', 'CHAT_MSG_CHANNEL', 'CHAT_MSG_TEXT_EMOTE', 'CHAT_MSG_EMOTE', 'CHAT_MSG_GUILD',
                    'CHAT_MSG_INSTANCE_CHAT', 'CHAT_MSG_INSTANCE_CHAT_LEADER', 'CHAT_MSG_PARTY',
                    'CHAT_MSG_PARTY_LEADER', 'CHAT_MSG_RAID', 'CHAT_MSG_WHISPER_INFORM', 'CHAT_MSG_YELL'}
local common_events = {'PLAYER_MOUNT_DISPLAY_CHANGED', 'PLAYER_CONTROL_LOST', 'PLAYER_TARGET_CHANGED', 'GOSSIP_SHOW',
                       'QUEST_GREETING', 'AUCTION_HOUSE_SHOW', 'BANKFRAME_OPENED', 'UNIT_SPELLCAST_SENT'}
local IsMounted = IsMounted
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
SLASH_HEART_ATTACK_HELP1 = "/hahelp"
SLASH_HEART_ATTACK_DEBUG1 = "/hadebug"
SLASH_HEART_ATTACK_RESET1 = "/hareset"
SLASH_HEART_ATTACK_ZERO1 = "/haendatzero"

local function printInfo(text) print("|cff00ffffInfo (HeartAttack): |cffffffff"..text) end
local function printWarning(text) print("|cffffff00Warning (HeartAttack): |cffffffff"..text) end
local function printDebug(text) if HeartAttack_Debug then print("|cff00ff00Debug (HeartAttack): |cffffffff"..text) end end

SlashCmdList.HEART_ATTACK_RESET = function()
    HeartAttack_FirstTimeDone = true
    HeartAttack_Debug = false
    HeartAttack_EventLock = false
    HeartAttack_GameOver = false
    HeartAttack_EndAtZero = false
    HeartAttack_MaxVal = 99999999999999
    HeartAttack_StartTime = time()
    if not heart_attack_ticker then
        heart_attack_ticker = C_Timer.NewTicker(600, HA_Table.roll_heart_attack_chance)
    end
    printInfo("Add-on has been completely reset to initial parameters with new start time.")
end

SlashCmdList.HEART_ATTACK_ZERO = function(arg1)
    if (arg1 == "" or arg1 ~= "true" and arg1 ~= "false") then
        printWarning("Expected true or false but received: "..arg1)
    else
        if arg1 == "true" then
            HeartAttack_EndAtZero = true
            printInfo("Zero mode has been enabled. You will get a heart attack when the number reaches 0.")
        else
            HeartAttack_EndAtZero = false
            printInfo("Zero mode has been disabled.")
        end
    end
end

SlashCmdList.HEART_ATTACK_DEBUG = function(arg1)
    if (arg1 == "" or arg1 ~= "true" and arg1 ~= "false") then
        printWarning("Expected true or false but received: "..arg1)
    else
        if arg1 == "true" then
            HeartAttack_Debug = true
            printInfo("Debug has been enabled.")
        else
            HeartAttack_Debug = false
            printInfo("Debug has been disabled.")
        end
    end
end

local function register_events()
    f:RegisterEvent('PLAYER_STARTED_MOVING')
    f:RegisterEvent('PLAYER_STOPPED_MOVING')
    f:RegisterEvent('UNIT_COMBAT')
    --[[f:RegisterEvent('PLAYER_ALIVE') Commenting out PLAYER_ALIVE because it triggers when player turns to ghost as well.
    Assume revive from other people has magical properties that does not result in scaring.]]
    f:RegisterEvent('PLAYER_DEAD')
    f:RegisterEvent('PLAYER_UNGHOST')
    f:RegisterEvent('PLAYER_LEVEL_UP')
    f:RegisterEvent('PLAYER_MOUNT_DISPLAY_CHANGED')
    f:RegisterEvent('PLAYER_CONTROL_LOST')
    f:RegisterEvent('PLAYER_TARGET_CHANGED')
    f:RegisterEvent('PLAYER_STARTED_TURNING')
    f:RegisterEvent('PLAYER_STOPPED_TURNING')
    f:RegisterEvent('CHAT_MSG_SAY')
    f:RegisterEvent('CHAT_MSG_CHANNEL')
    f:RegisterEvent('CHAT_MSG_TEXT_EMOTE')
    f:RegisterEvent('CHAT_MSG_EMOTE')
    f:RegisterEvent('CHAT_MSG_GUILD')
    f:RegisterEvent('CHAT_MSG_INSTANCE_CHAT')
    f:RegisterEvent('CHAT_MSG_INSTANCE_CHAT_LEADER')
    f:RegisterEvent('CHAT_MSG_PARTY')
    f:RegisterEvent('CHAT_MSG_PARTY_LEADER')
    f:RegisterEvent('CHAT_MSG_RAID')
    f:RegisterEvent('CHAT_MSG_WHISPER_INFORM')
    f:RegisterEvent('CHAT_MSG_YELL')
    f:RegisterEvent('GOSSIP_SHOW')
    f:RegisterEvent('QUEST_GREETING')
    f:RegisterEvent('UNIT_SPELLCAST_SENT')
    f:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
    f:RegisterEvent('BANKFRAME_OPENED')
    f:RegisterEvent('AUCTION_HOUSE_SHOW')
    f:RegisterEvent('BAG_UPDATE')
    f:RegisterEvent('LEARNED_SPELL_IN_TAB')
end

local function unregister_events()
    f:UnregisterEvent('PLAYER_STARTED_MOVING')
    f:UnregisterEvent('PLAYER_STOPPED_MOVING')
    f:UnregisterEvent('UNIT_COMBAT')
    --f:RegisterEvent('PLAYER_ALIVE')
    f:UnregisterEvent('PLAYER_DEAD')
    f:UnregisterEvent('PLAYER_UNGHOST')
    f:UnregisterEvent('PLAYER_LEVEL_UP')
    f:UnregisterEvent('PLAYER_MOUNT_DISPLAY_CHANGED')
    f:UnregisterEvent('PLAYER_CONTROL_LOST')
    f:UnregisterEvent('PLAYER_TARGET_CHANGED')
    f:UnregisterEvent('PLAYER_STARTED_TURNING')
    f:UnregisterEvent('PLAYER_STOPPED_TURNING')
    f:UnregisterEvent('CHAT_MSG_SAY')
    f:UnregisterEvent('CHAT_MSG_CHANNEL')
    f:UnregisterEvent('CHAT_MSG_TEXT_EMOTE')
    f:UnregisterEvent('CHAT_MSG_EMOTE')
    f:UnregisterEvent('CHAT_MSG_GUILD')
    f:UnregisterEvent('CHAT_MSG_INSTANCE_CHAT')
    f:UnregisterEvent('CHAT_MSG_INSTANCE_CHAT_LEADER')
    f:UnregisterEvent('CHAT_MSG_PARTY')
    f:UnregisterEvent('CHAT_MSG_PARTY_LEADER')
    f:UnregisterEvent('CHAT_MSG_RAID')
    f:UnregisterEvent('CHAT_MSG_WHISPER_INFORM')
    f:UnregisterEvent('CHAT_MSG_YELL')
    f:UnregisterEvent('GOSSIP_SHOW')
    f:UnregisterEvent('QUEST_GREETING')
    f:UnregisterEvent('UNIT_SPELLCAST_SENT')
    f:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
    f:UnregisterEvent('BANKFRAME_OPENED')
    f:UnregisterEvent('AUCTION_HOUSE_SHOW')
    f:UnregisterEvent('BAG_UPDATE')
    f:UnregisterEvent('LEARNED_SPELL_IN_TAB')
end

--Main function to lower the value of HeartAttack_MaxVal every time the player does an action.
local function subtract_max_val(value)
    value = value or 1
    local max_val_copy = HeartAttack_MaxVal
    max_val_copy = max_val_copy - value
    HeartAttack_MaxVal = max_val_copy
    printDebug("Subtracted "..value.." from "..max_val_copy..".")
    --In case HeartAttack_MaxVal became 0 or less, initiate heart attack.
    if HeartAttack_MaxVal <= 0 then
        printDebug("HeartAttack_MaxVal reached 0. Overwriting roll_heart_attack_chance() with forced heart attack.")
        HA_Table.roll_heart_attack_chance(true)
    end
end

--Main function that determines whether a heart attack will occur and plays all the actions during heart attack event.
function HA_Table.roll_heart_attack_chance(overwrite)
    HeartAttack_EventLock = true
    overwrite = overwrite or false
    if overwrite == true then
        heart_attack_ticker:Cancel()
        heart_attack_ticker = nil
        HeartAttack_GameOver = true
        unregister_events()
    else
        local MaxVal = HeartAttack_MaxVal
        local random_number
        if MaxVal >= int32 then
            local X1 = math.random(1, int32)
            local X2 = math.ceil(MaxVal / int32)
            random_number = X1 * X2
        else
            random_number = math.random(1, MaxVal)
        end

        if random_number == MaxVal then
            heart_attack_ticker:Cancel()
            heart_attack_ticker = nil
            HeartAttack_GameOver = true
            unregister_events()
        else
            printDebug("Heart attack did not trigger. Subtract 1.")
            subtract_max_val()
        end
    end
    HeartAttack_EventLock = false
end

--[[For every 5 seconds walked, decrease HeartAttack_MaxVal by that much. Reset all values to nil to save memory. If for
 some reason, walk_start_time was nil, just subtract HeartAttack_MaxVal by 1]]
local function calculate_time_walked()
    local end_time = time()
    local division
    if walk_start_time ~= nil then
        local total = end_time - walk_start_time
        division = math.floor(total / 5)
        if division >= 1 then
            printDebug("PLAYER_STOPPED_MOVING: Walk end time: "..end_time..". Subtract "..division..".")
            subtract_max_val(division)
        else
            printDebug("PLAYER_STOPPED_MOVING: Time walked less than 5 seconds. Skip subtract.")
        end
        walk_start_time = nil
    else
        printDebug("PLAYER_STOPPED_MOVING: walk_start_time was nil. Subtract 1.")
        subtract_max_val()
    end
    stopped_walking_ticker = nil
end

--[[For every 10 seconds walked, decrease HeartAttack_MaxVal by that much. Reset all values to nil to save memory. If for
 some reason, walk_start_time was nil, just subtract HeartAttack_MaxVal by 1]]
local function calculate_time_turned()
    local end_time = time()
    local division
    if turn_start_time ~= nil then
        local total = end_time - turn_start_time
        division = math.floor(total / 10)
        if division >= 1 then
            printDebug("PLAYER_STOPPED_TURNING: Turn end time: "..end_time..". Subtract "..division..".")
            subtract_max_val(division)
        else
            printDebug("PLAYER_STOPPED_TURNING: Time turned less than 10 seconds. Skip subtract.")
        end
        turn_start_time = nil
    else
        printDebug("PLAYER_STOPPED_TURNING: Turn_start_time was nil. Subtract 1.")
        subtract_max_val()
    end
    stopped_turning_ticker = nil
end

--Divide damage taken by 10 and subtract that much from HeartAttack_MaxVal
local function calculate_damage_taken(damage_taken)
    if damage_taken ~= nil then
        local division = math.floor(damage_taken / 10)
        if division >= 1 then
            printDebug("UNIT_COMBAT: Subtract "..division..".")
            subtract_max_val(division)
        else
            printDebug("UNIT_COMBAT: Damage taken does not cross threshold. Skip subtract.")
        end
    else
        printDebug("UNIT_COMBAT: amount argument was nil. Subtract 1.")
        subtract_max_val()
    end
end

--Handles the logic for when the enter players the world (initial login or /reload).
function HA_Table.handle_player_entering_world()
    if HeartAttack_FirstTimeDone == nil then
        HeartAttack_FirstTimeDone = true            -- First time launch flag to determine if add-on launched first time
        HeartAttack_Debug = false                   -- Debug flag
        HeartAttack_EventLock = false               -- When the main function to determine if heart attack will occur runs, lock event collection
        HeartAttack_GameOver = false                -- Flag to check if the heart attack has occurred to stop any add-on activity
        HeartAttack_EndAtZero = false             -- Flag to check whether the user wants his odds printed
        HeartAttack_MaxVal = 99,999,999,999,999         -- Initial value for heart attack calculation. Gets smaller with each appropriate event triggered.
        HeartAttack_StartTime = time()              -- Save the initial start time of the add-on. Used at the very end to calculate how long the player lived.
        printInfo('First time? Type /hahelp for more information.')
    end
    --Every 10 minutes, trigger roll_heart_attack_chance to see if the player will experience a heart attack
    if not heart_attack_ticker then
        if HeartAttack_GameOver == false then
            player_guid = player_guid or UnitGUID("player") -- Save player GUID to detect player chatting
            heart_attack_ticker = C_Timer.NewTicker(600, HA_Table.roll_heart_attack_chance)
        end
    end
    register_events()
    C_Timer.After(5, function() initial_world_load = true end) -- Set initial_world_load to false after initial load to stop BAG_UPDATE spam when logging into a character
end

--[[If the player started walking, save current epoch seconds to walk_start_time. If stopped_walking_ticker was already
active, cancel it and set it to nil and do not reassign walk_start_time]]
function HA_Table.handle_player_started_moving()
    if not IsMounted() and not UnitIsDeadOrGhost("player") then
        if stopped_walking_ticker then
            stopped_walking_ticker:Cancel()
            stopped_walking_ticker = nil
        else
            walk_start_time = time()
            printDebug("PLAYER_STARTED_MOVING: walk_start_time set to ".. walk_start_time ..".")
        end
    end
end

--If the player stopped walking, start a ticker that will execute calculate_time_walked.
function HA_Table.handle_player_stopped_moving()
    if not IsMounted() and not UnitIsDeadOrGhost("player") then
        if not stopped_walking_ticker then
            stopped_walking_ticker = C_Timer.NewTicker(2.5, calculate_time_walked, 1)
        end
    end
end

--[[If the player started turning, save current epoch seconds to turn_start_time. If stopped_turning_ticker was already
active, cancel it and set it to nil and do not reassign turn_start_time]]
function HA_Table.handle_player_started_turning()
    if not IsMounted() and not UnitIsDeadOrGhost("player") then
        if stopped_turning_ticker then
            stopped_turning_ticker:Cancel()
            stopped_turning_ticker = nil
        else
            turn_start_time = time()
            printDebug("PLAYER_STARTED_TURNING: turn_start_time set to ".. turn_start_time ..".")
        end
    end
end

--If the player stopped turning, start a ticker that will execute calculate_time_turned.
function HA_Table.handle_player_stopped_turning()
    if not IsMounted() and not UnitIsDeadOrGhost("player") then
        if not stopped_turning_ticker then
            stopped_turning_ticker = C_Timer.NewTicker(2, calculate_time_turned, 1)
        end
    end
end

--If the player got hit, subtract HeartAttack_MaxVal by 1, otherwise by 2 if the hit was critical or crushing.
function HA_Table.handle_unit_combat(damage_taken, flagText)
    if flagText == nil or flagText == '' or flagText ~= 'GLANCING' then
        calculate_damage_taken(damage_taken)
    else
        calculate_damage_taken(damage_taken * 2)
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
        printDebug("PLAYER_UNGHOST: Player was dead for "..time_dead.." seconds. Subtract "..multiply..".")
        subtract_max_val(multiply)
        HeartAttack_DeadTime = nil
    else
        printDebug("PLAYER_UNGHOST: HeartAttack_DeadTime was nil. Subtract 20.")
        subtract_max_val(20)
    end
end

--If the player died, subtract HeartAttack_MaxVal by 10 and save current epoch seconds in case the player quits.
function HA_Table.handle_player_dead()
    HeartAttack_DeadTime = time()
    printDebug("PLAYER_DEAD: Player died. Set HeartAttack_DeadTime to "..HeartAttack_DeadTime..". Subtract 10.")
    subtract_max_val(10)
end

--If the player leveled up, take the new level and subtract it from HeartAttack_MaxVal.
function HA_Table.handle_player_level_up(level)
    printDebug("PLAYER_LEVEL_UP: Subtract "..level..".")
    subtract_max_val(level)
end

--If the player successfully casts a spell, subtract 1 from HeartAttack_MaxVal
function HA_Table.handle_spellcast_succeeded()
    printDebug("UNIT_SPELLCAST_SUCCEEDED: subtract 1.")
    subtract_max_val()
end

--If the player said something in chat, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_msg(chat_type)
    printDebug(chat_type..": Subtract 1.")
    subtract_max_val()
end

--If the player mounts or dismounts, subtract 1 from HeartAttack_MaxVal.
--If the player was affected by a crown control or used a taxi, subtract 1 from HeartAttack_MaxVal.
--If the player changed target, subtract 1 from HeartAttack_MaxVal.
--If the player talks to an NPC, subtract 1 from HeartAttack_MaxVal.
--If the player casts any instant or non-instant spells, whether they have finished, subtract 1 from HeartAttack_MaxVal.
--If the player learns a new spell or profession, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_common_event(event)
    printDebug(event..": Subtract 1.")
    subtract_max_val()
end

--If the player interacts with his bag, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_bag()
    if bag_lock == false then
        bag_lock = true
        printDebug("BAG_UPDATE: Subtract 1.")
        subtract_max_val()
    end
end

function f:OnEvent(event, arg1, arg2, arg3, arg4, _, _, _, _, _, _, _, arg12)
    --Initial load of AddOn when player logs in
    if event == 'PLAYER_ENTERING_WORLD' then HA_Table.handle_player_entering_world() end
    --Handling of all events that cause HeartAttack_MaxVal to lower as well as counting of chat messages to use during randomizer
    if HeartAttack_GameOver == false and HeartAttack_EventLock == false then
        if event == 'PLAYER_STARTED_MOVING' then HA_Table.handle_player_started_moving()
        elseif event == 'PLAYER_STOPPED_MOVING' then HA_Table.handle_player_stopped_moving()
        elseif event == 'UNIT_COMBAT' and arg1 == 'player' and arg2 == 'WOUND' then HA_Table.handle_unit_combat(arg4, arg3)
        elseif --[[event == 'PLAYER_ALIVE' or]] event == 'PLAYER_UNGHOST' then HA_Table.handle_player_alive()
        elseif event == 'PLAYER_DEAD' then HA_Table.handle_player_dead()
        elseif event == 'PLAYER_LEVEL_UP' then HA_Table.handle_player_level_up(arg1)
        elseif event == 'PLAYER_STARTED_TURNING' then HA_Table.handle_player_started_turning()
        elseif event == 'PLAYER_STOPPED_TURNING' then HA_Table.handle_player_stopped_turning()
        elseif event == 'UNIT_SPELLCAST_SUCCEEDED' and arg1 == 'player' then HA_Table.handle_spellcast_succeeded()
        elseif tContains(common_events, event) then HA_Table.handle_common_event(event)
        elseif tContains(chat_types, event) and arg12 == player_guid then HA_Table.handle_msg(event)
        --To avoid double BAG_UPDATE from moving items in the backpack, lock the event to capture only 1 event
        elseif event == 'BAG_UPDATE' and initial_world_load == true then HA_Table.handle_bag() C_Timer.After(0.1, function() bag_lock = false end)
        elseif event == 'LEARNED_SPELL_IN_TAB' and initial_world_load == true then HA_Table.handle_common_event(event) end
    end
end

f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:SetScript('OnEvent', f.OnEvent)