local HA_Table = {}

local f = CreateFrame('Frame', 'HeartAttack')
local walk_start_time
local turn_start_time
local stopped_walking_ticker
local stopped_turning_ticker
local heart_attack_ticker
local player_guid
local time = time
local tContains = tContains
local chat_types = {'CHAT_MSG_SAY', 'CHAT_MSG_CHANNEL', 'CHAT_MSG_TEXT_EMOTE', 'CHAT_MSG_EMOTE', 'CHAT_MSG_GUILD',
                    'CHAT_MSG_INSTANCE_CHAT', 'CHAT_MSG_INSTANCE_CHAT_LEADER', 'CHAT_MSG_PARTY',
                    'CHAT_MSG_PARTY_LEADER', 'CHAT_MSG_RAID', 'CHAT_MSG_WHISPER_INFORM', 'CHAT_MSG_YELL'}
local IsMounted = IsMounted
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
SLASH_HEART_ATTACK_HELP1 = "/hahelp"
SLASH_HEART_ATTACK_DEBUG1 = "/hadebug"
SLASH_HEART_ATTACK_RESET1 = "/hareset"

local function printInfo(text) print("|cff00ffffInfo (HeartAttack): |cffffffff"..text) end
local function printWarning(text) print("|cffffff00Warning (HeartAttack): |cffffffff"..text) end
local function printDebug(text) if HeartAttack_Debug then print("|cff00ff00Debug (HeartAttack): |cffffffff"..text) end end

SlashCmdList.HEART_ATTACK_RESET = function()
    HeartAttack_FirstTimeDone = true
    HeartAttack_Debug = false
    HeartAttack_GameOver = false
    HeartAttack_MaxVal = 9223372036854775807
    HeartAttack_StartTime = time()
    printInfo("Add-on has been completely reset to initial parameters with new start time.")
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

--Main function to lower the value of HeartAttack_MaxVal every time the player does an action.
local function subtract_max_val(value)
    value = value or 1
    local max_val_copy = HeartAttack_MaxVal
    max_val_copy = max_val_copy - value
    HeartAttack_MaxVal = max_val_copy
    printDebug("Subtracted "..value.." from "..max_val_copy..".")
    --In case HeartAttack_MaxVal became 0 or less, initiate heart attack.
    if HeartAttack_MaxVal <= 0 then
        HA_Table.do_heart_attack(true)
        printDebug("HeartAttack_MaxVal reached 0. Overwriting do_heart_attack() with forced heart attack.")
    end
end

--Main function that determines whether a heart attack will occur and plays all the actions during heart attack event.
function HA_Table.do_heart_attack(overwrite)
    overwrite = overwrite or false
    local test = 'wow'
    if test == 'owo' then
        heart_attack_ticker:Cancel()
        heart_attack_ticker = nil
        HeartAttack_GameOver = true
    else
        printDebug("Heart attack did not trigger. Subtract 1.")
        subtract_max_val()
    end
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

--Handles the logic for when the enter players the world (initial login or /reload).
function HA_Table.handle_player_entering_world()
    player_guid = player_guid or UnitGUID("player") -- Save player GUID to detect player actions during combat or chat
    if HeartAttack_FirstTimeDone == nil then
        HeartAttack_FirstTimeDone = true            -- First time launch flag to determine if add-on launched first time
        HeartAttack_Debug = false                   -- Debug flag
        HeartAttack_GameOver = false                -- Flag to check if the heart attack has occurred to stop any add-on activity
        HeartAttack_MaxVal = 9223372036854775807    -- Initial value for heart attack calculation. Gets smaller with each appropriate event triggered.
        HeartAttack_StartTime = time()              -- Save the initial start time of the add-on. Used at the very end to calculate how long the player lived.
        printInfo('First time? Type /hahelp for more information.')
    end
    --Every hour, trigger do_heart_attack to see if the player will experience a heart attack
    if not heart_attack_ticker then
        if HeartAttack_GameOver == false then
            heart_attack_ticker = C_Timer.NewTicker(3600, HA_Table.do_heart_attack)
        end
    end
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
function HA_Table.handle_unit_combat(flagText)
    if flagText == nil or flagText == '' or flagText ~= 'GLANCING' then
        printDebug("UNIT_COMBAT: Player hit without flag. Subtract 1.")
        subtract_max_val()
    else
        printDebug("UNIT_COMBAT: Player hit with flag. Subtract 2.")
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

--If the player mounts or dismounts, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_mount_display_change()
    printDebug("PLAYER_MOUNT_DISPLAY_CHANGED: Subtract 1.")
    subtract_max_val()
end

--If the player was affected by a crown control or used a taxi, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_player_control_lost()
    printDebug("PLAYER_CONTROL_LOST: Subtract 1.")
    subtract_max_val()
end

--If the player changed target, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_player_target_changed()
    printDebug("PLAYER_TARGET_CHANGED: Subtract 1.")
    subtract_max_val()
end

--If the player said something in /say, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_msg(chat_type)
    printDebug(chat_type..": Subtract 1.")
    subtract_max_val()
end

--If the player talks to an NPC, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_npc(talk_type)
    printDebug(talk_type..": Subtract 1.")
    subtract_max_val()
end

--If the player casts any instant or non-instant spells, whether they have finished, subtract_max_val 1 from HeartAttack_MaxVal.
function HA_Table.handle_unit_spellcast_sent()
    printDebug("UNIT_SPELLCAST_SENT: Subtract 1.")
    subtract_max_val()
end

function f:OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
    if event == 'PLAYER_ENTERING_WORLD' then HA_Table.handle_player_entering_world() end
    if HeartAttack_GameOver == false then
        if event == 'PLAYER_STARTED_MOVING' then HA_Table.handle_player_started_moving() end
        if event == 'PLAYER_STOPPED_MOVING' then HA_Table.handle_player_stopped_moving() end
        if event == 'UNIT_COMBAT' and arg1 == 'player' and arg2 == 'WOUND' then HA_Table.handle_unit_combat(arg3) end
        if --[[event == 'PLAYER_ALIVE' or]] event == 'PLAYER_UNGHOST' then HA_Table.handle_player_alive() end
        if event == 'PLAYER_DEAD' then HA_Table.handle_player_dead() end
        if event == 'PLAYER_LEVEL_UP' then HA_Table.handle_player_level_up(arg1) end
        if event == 'PLAYER_MOUNT_DISPLAY_CHANGED' then HA_Table.handle_mount_display_change() end
        if event == 'PLAYER_CONTROL_LOST' then HA_Table.handle_player_control_lost() end
        if event == 'PLAYER_TARGET_CHANGED' then HA_Table.handle_player_target_changed() end
        if event == 'PLAYER_STARTED_TURNING' then HA_Table.handle_player_started_turning() end
        if event == 'PLAYER_STOPPED_TURNING' then HA_Table.handle_player_stopped_turning() end
        if tContains(chat_types, event) then HA_Table.handle_msg(event) end
        if event == 'GOSSIP_SHOW' or event == 'QUEST_GREETING' then HA_Table.handle_npc(event) end
        if event == 'UNIT_SPELLCAST_SENT' then HA_Table.handle_unit_spellcast_sent() end
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
f:SetScript('OnEvent', f.OnEvent)