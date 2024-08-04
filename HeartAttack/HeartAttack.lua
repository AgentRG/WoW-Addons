local HA_Table = {
    panel = CreateFrame("Frame", "HeartAttackSettings")
}
local category

--[[READ FIRST
If you would like to change the parameters of the mod (either by lowering the total possible playtime, or increasing
how often a chance of a heart attack roles, update the following values here to your desired number and reset the mod
in the options page.]]
local HA_MaxVal = 99999999999999 --Bigger number equals potentially longer game. 99999999999999 is the maximum possible value.
local HA_Frequency = 600 --How often to role for heart attack chance. Default is 600 seconds (10 minutes).

local f = CreateFrame('Frame', 'HeartAttack')
local walk_start_time
local turn_start_time
local stopped_walking_ticker
local stopped_turning_ticker
local initial_world_load
local initial_game_load = false
local bag_lock = false
local spell_lock = false
local heart_attack_ticker
local math = math
local int32 = 2147483647
local player_guid = UnitGUID("player") -- Save player GUID to detect player chat or emotes
local time = time
local tContains = tContains
local C_Timer = C_Timer
local chat_types = {'CHAT_MSG_SAY', 'CHAT_MSG_CHANNEL', 'CHAT_MSG_TEXT_EMOTE', 'CHAT_MSG_EMOTE', 'CHAT_MSG_GUILD',
                    'CHAT_MSG_INSTANCE_CHAT', 'CHAT_MSG_INSTANCE_CHAT_LEADER', 'CHAT_MSG_PARTY',
                    'CHAT_MSG_PARTY_LEADER', 'CHAT_MSG_RAID', 'CHAT_MSG_WHISPER_INFORM', 'CHAT_MSG_YELL'}
local common_events = {'PLAYER_MOUNT_DISPLAY_CHANGED', 'PLAYER_CONTROL_LOST', 'PLAYER_TARGET_CHANGED', 'GOSSIP_SHOW',
                       'QUEST_GREETING', 'AUCTION_HOUSE_SHOW', 'BANKFRAME_OPENED'}
local IsMounted = IsMounted
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
SLASH_HEART_ATTACK_HELP1 = "/hahelp"

local function printInfo(text) print("|cff00ffffInfo (HeartAttack): |cffffffff"..text) end
local function printWarning(text) print("|cffffff00Warning (HeartAttack): |cffffffff"..text) end
local function printDebug(text) if HeartAttack_GlobalTable.HeartAttack_Debug == true then print("|cff00ff00Debug (HeartAttack): |cffffffff"..text) end end

SlashCmdList.HEART_ATTACK_HELP = function()
    printInfo("The mod functions by rolling a chance for the player to experience a \"Heart Attack\" every 10 "..
            "minutes (unless Zero Mode is enabled). The chance of having one is determined by the player's activity"..
            " throughout the character's playtime. Additional settings for the mod can be found under Options →"..
            " AddOns → Heart Attack.")
end

--Options frame
local function create_interface()
    HA_Table.panel.name = "Heart Attack"

    local zeroMode = CreateFrame("CheckButton", nil, HA_Table.panel, "ChatConfigCheckButtonTemplate")
    zeroMode.Text:SetText("Enable Zero Mode")
    zeroMode:SetPoint("TOPLEFT", 8, -10)
    zeroMode.tooltip = "When enabled, the game will end when the player exhausts the number used for the game. Warning:"..
            " With the default value, the game can potentially take a long time with Zero Mode enabled."
    if HeartAttack_GlobalTable.HeartAttack_EndAtZero == true then
        zeroMode:SetChecked(true)
    else
        zeroMode:SetChecked(false)
    end
    zeroMode:SetScript("OnClick", function()
        local checkStatus = zeroMode:GetChecked()
        if checkStatus then
            HeartAttack_GlobalTable.HeartAttack_EndAtZero = true
            printInfo("Zero mode has been enabled. You will get a heart attack when the number reaches 0.")
        else
            HeartAttack_GlobalTable.HeartAttack_EndAtZero = false
            printInfo("Zero mode has been disabled.")
        end
    end)

    local debugButton = CreateFrame("CheckButton", nil, HA_Table.panel, "ChatConfigCheckButtonTemplate")
    debugButton.Text:SetText("Enable Debugger")
    debugButton:SetPoint("TOPLEFT", 8, -30)
    debugButton.tooltip = "Enable the debugger for event handling and other functions."
    if HeartAttack_GlobalTable.HeartAttack_Debug == true then
        debugButton:SetChecked(true)
    else
        debugButton:SetChecked(false)
    end
    debugButton:SetScript("OnClick", function()
        local checkStatus = debugButton:GetChecked()
        if checkStatus then
            HeartAttack_GlobalTable.HeartAttack_Debug = true
            printInfo("Debugger has been enabled.")
        else
            HeartAttack_GlobalTable.HeartAttack_Debug = false
            printInfo("Debugger has been disabled.")
        end
    end)

    local resetButton = CreateFrame("Button", nil, HA_Table.panel, "UIPanelButtonTemplate")
    resetButton:SetText("Reset Mod")
    resetButton:SetWidth(100)
    resetButton:SetPoint("TOPLEFT", 8, -55)
    resetButton:SetScript("OnClick", function()
        if heart_attack_ticker ~= nil then
            heart_attack_ticker:Cancel()
        end
        StaticPopupDialogs["HeartAttack"] = {
            text = "Are you sure you want to reset the mod? This will reset all values to default and start anew.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                HeartAttack_FirstTimeDone = true
                HeartAttack_GlobalTable = {}
                HeartAttack_GlobalTable.HeartAttack_Debug = false
                debugButton:SetChecked(false)
                HeartAttack_GlobalTable.HeartAttack_EndAtZero = false
                zeroMode:SetChecked(false)
                HeartAttack_GlobalTable.HeartAttack_EventLock = false
                HeartAttack_GlobalTable.HeartAttack_GameOver = false
                HeartAttack_GlobalTable.HeartAttack_MaxVal = HA_MaxVal
                HeartAttack_GlobalTable.HeartAttack_StartTime = time()
                HeartAttack_GlobalTable.HeartAttack_24HoursStart = time()
                heart_attack_ticker = nil
                if not heart_attack_ticker then
                    heart_attack_ticker = C_Timer.NewTicker(HA_Frequency, HA_Table.roll_heart_attack_chance)
                end
                printInfo("Add-on has been completely reset to initial parameters with new start time.")
            end,
            OnCancel = function()
                heart_attack_ticker = C_Timer.NewTicker(HA_Frequency, HA_Table.roll_heart_attack_chance)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = false
        }
        StaticPopup_Show("HeartAttack")
    end)

    local userNote = HA_Table.panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    userNote:SetPoint("TOPLEFT", 8, 0)
    userNote:SetPoint("BOTTOMRIGHT", -8, 0)
    userNote:SetJustifyH("LEFT")
    userNote:SetText("Note: If you'd like to change the length of the game, or how often the chance for a heart attack"..
            " roles, open the file HeartAttack/HeartAttack.lua in your text editor of choice and read line 3 that says"..
            " READ FIRST for instructions.")
    userNote:SetWordWrap(true)
    category = Settings.RegisterCanvasLayoutCategory(HA_Table.panel, HA_Table.panel.name, HA_Table.panel.name);
    category.ID = HA_Table.panel.name
    Settings.RegisterAddOnCategory(category);
end

function HeartAttack_OnAddonCompartmentClick()
    Settings.OpenToCategory(category.ID)
end

--Game Over frame
local function do_heart_attack()
    local time_played = time() - HeartAttack_GlobalTable.HeartAttack_StartTime
    local years = math.floor(time_played / 31536000)
    time_played = time_played - years * 31536000
    local months = math.floor(time_played / 2592000)
    time_played = time_played - months * 2592000
    local days = math.floor(time_played / 86400)
    time_played = time_played - days * 86400
    local hours = math.floor(time_played / 3600)
    time_played = time_played - hours * 3600
    local minutes = math.floor(time_played / 60)
    local seconds = time_played - minutes * 60
    local yearOrYears if years == 1 then yearOrYears = 'year' else yearOrYears = 'years' end
    local monthOrMonths if months == 1 then monthOrMonths = 'month' else monthOrMonths = 'months' end
    local dayOrDays if days == 1 then dayOrDays = 'day' else dayOrDays = 'days' end
    local hourOrHours if hours == 1 then hourOrHours = 'hour' else hourOrHours = 'hours' end
    local minuteOrMinutes if minutes == 1 then minuteOrMinutes = 'minute' else minuteOrMinutes = 'minutes' end
    local secondOrSeconds if seconds == 1 then secondOrSeconds = 'seconds' else secondOrSeconds = 'seconds' end

    PlaySoundFile("Interface\\AddOns\\HeartAttack\\Resources\\GameOverSound.mp3", "Master")
    local gameOverFrame = CreateFrame('Frame', 'HeartAttackGameOver', UIParent, 'BackdropTemplate')
    gameOverFrame:SetSize(450, 220)
    gameOverFrame:SetPoint("CENTER", 0, 0)
    gameOverFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    gameOverFrame:SetBackdropColor(0, 0, 0, 1)
    gameOverFrame:SetMovable(true)
    gameOverFrame:EnableMouse(true)
    gameOverFrame:SetResizable(false)
    gameOverFrame:SetScript("OnMouseDown", function(self)
        self:StartMoving()
    end)
    gameOverFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)
    local gameOverString = gameOverFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    gameOverString:SetPoint("TOP", 6, -10)
    gameOverString:SetFont("Fonts\\MORPHEUS.TTF", 30)
    gameOverString:SetTextColor(0.78, 0.61, 0.43, 1)
    gameOverString:SetText("Game Over")
    local description = gameOverFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    description:SetPoint("TOPLEFT", gameOverFrame, "TOPLEFT", 6, -50)
    description:SetPoint("BOTTOMRIGHT", gameOverFrame, "BOTTOMRIGHT", -6, 50)
    description:SetText("You suddenly feel a discomfort in your left side of the chest. You feel weak, light-headed,"..
            " and a shortness of breath mixed with cold sweat takes over you. You suffered a heart attack after "..
            "exploring Azeroth for "
            ..years.." "..yearOrYears..", "
            ..months.." "..monthOrMonths..", "
            ..days.." "..dayOrDays..", "
            ..hours.." "..hourOrHours..", "
            ..minutes.." "..minuteOrMinutes.." and "
            ..seconds.." "..secondOrSeconds.."."..
            "\n\nAlthough your life is now over (in this mod), you can always start anew through the AddOn options"..
            " page. The mod will now stop tracking character activity until reset."..
            "\n\nThanks for playing AgentRG's HeartAttack mod!")
    description:SetWordWrap(true)
    local closeButton = CreateFrame("Button", nil, gameOverFrame, "UIPanelButtonTemplate")
    closeButton:SetText("Close Prompt")
    closeButton:SetWidth(100)
    closeButton:SetPoint("BOTTOM", 0, 6)
    closeButton:SetScript("OnClick", function()
        PlaySoundFile(567407, "Master")
        gameOverFrame:Hide()
    end)
end

--Main function to lower the value of HeartAttack_MaxVal every time the player does an action.
function HA_Table.subtract_max_val(value)
    value = value or 1
    local max_val_copy = HeartAttack_GlobalTable.HeartAttack_MaxVal
    max_val_copy = max_val_copy - value
    HeartAttack_GlobalTable.HeartAttack_MaxVal = max_val_copy
    printDebug("HA_Table.subtract_max_val("..value.."): Subtracted "..value.." from "..max_val_copy..".")
    --In case HeartAttack_MaxVal became 0 or less, initiate heart attack.
    if HeartAttack_GlobalTable.HeartAttack_MaxVal <= 0 then
        printDebug("HeartAttack_MaxVal reached 0. Overwriting HA_Table.roll_heart_attack_chance() with forced heart attack.")
        HA_Table.roll_heart_attack_chance(true)
    end
end

--Main function that determines whether a heart attack will occur and plays all the actions during heart attack event.
function HA_Table.roll_heart_attack_chance(overwrite)
    overwrite = overwrite or false
    HeartAttack_GlobalTable.HeartAttack_EventLock = true
    if overwrite == true then
        heart_attack_ticker:Cancel()
        heart_attack_ticker = nil
        HeartAttack_GlobalTable.HeartAttack_GameOver = true
        do_heart_attack()
    else
        if HeartAttack_GlobalTable.HeartAttack_EndAtZero == false then
            local MaxVal = HeartAttack_GlobalTable.HeartAttack_MaxVal
            local random_number
            if MaxVal >= int32 then
                local X1, X2, X3 = math.random(1, int32), math.ceil(MaxVal / int32), math.floor(MaxVal / int32)
                local option_1, option_2 = X1 * X2, X1 * X3
                local pick_one = math.random(1, 2)
                if pick_one == 1 then
                    random_number = option_1
                else
                    random_number = option_2
                end
            else
                random_number = math.random(1, MaxVal)
            end

            if random_number == MaxVal then
                heart_attack_ticker:Cancel()
                heart_attack_ticker = nil
                HeartAttack_GlobalTable.HeartAttack_GameOver = true
                do_heart_attack()
            else
                printDebug("Heart attack did not trigger. Subtract 1.")
                HA_Table.subtract_max_val()
            end
        else
            printDebug("Zero mode is enabled. Heart attack role chance did not happen. Subtract 1.")
            HA_Table.subtract_max_val()
        end
    end
    HeartAttack_GlobalTable.HeartAttack_EventLock = false
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
            HA_Table.subtract_max_val(division)
        else
            printDebug("PLAYER_STOPPED_MOVING: Time walked less than 5 seconds. Skip subtract.")
        end
        walk_start_time = nil
    else
        printDebug("PLAYER_STOPPED_MOVING: walk_start_time was nil. Subtract 1.")
        HA_Table.subtract_max_val()
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
            HA_Table.subtract_max_val(division)
        else
            printDebug("PLAYER_STOPPED_TURNING: Time turned less than 10 seconds. Skip subtract.")
        end
        turn_start_time = nil
    else
        printDebug("PLAYER_STOPPED_TURNING: Turn_start_time was nil. Subtract 1.")
        HA_Table.subtract_max_val()
    end
    stopped_turning_ticker = nil
end

--Divide damage taken by 10 and subtract that much from HeartAttack_MaxVal
local function calculate_damage_taken(damage_taken)
    if damage_taken ~= nil then
        local division = math.floor(damage_taken / 10)
        if division >= 1 then
            printDebug("UNIT_COMBAT: Subtract "..division..".")
            HA_Table.subtract_max_val(division)
        else
            printDebug("UNIT_COMBAT: Damage taken does not cross threshold. Skip subtract.")
        end
    else
        printDebug("UNIT_COMBAT: amount argument was nil. Subtract 1.")
        HA_Table.subtract_max_val()
    end
end

--For every 24 hours passed, subtract x for hours passed from HeartAttack_MaxVal
local function calculate_24_hours_passed()
    if HeartAttack_GlobalTable.HeartAttack_24HoursStart ~= nil then
        local end_time = time()
        local hours_passed = end_time - HeartAttack_GlobalTable.HeartAttack_24HoursStart
        if hours_passed >= 86400 then
            hours_passed = math.floor(hours_passed / 86400)
            if hours_passed >= 0 then
                printDebug(hours_passed.." has passed since last check. Subtract "..hours_passed..".")
                HA_Table.subtract_max_val(hours_passed)
                HeartAttack_GlobalTable.HeartAttack_24HoursStart = end_time
            end
        end
    else
        printDebug("HeartAttack_24HoursStart was nil.")
        HeartAttack_GlobalTable.HeartAttack_24HoursStart = time()
    end
end

--Handles the logic for when the enter players the world (initial login or /reload).
function HA_Table.handle_player_entering_world()
    initial_world_load = false
    if HeartAttack_FirstTimeDone == nil then
        HeartAttack_GlobalTable = {}
        HeartAttack_GlobalTable.HeartAttack_Debug = false                   -- Debug flag
        HeartAttack_GlobalTable.HeartAttack_EventLock = false               -- When the main function to determine if heart attack will occur runs, lock event collection
        HeartAttack_GlobalTable.HeartAttack_GameOver = false                -- Flag to check if the heart attack has occurred to stop any add-on activity
        HeartAttack_GlobalTable.HeartAttack_EndAtZero = false               -- Flag to check whether the user wants his odds printed
        HeartAttack_GlobalTable.HeartAttack_MaxVal = HA_MaxVal              -- Initial value for heart attack calculation. Gets smaller with each appropriate event triggered.
        HeartAttack_GlobalTable.HeartAttack_StartTime = time()              -- Save the initial start time of the add-on. Used at the very end to calculate how long the player lived.
        HeartAttack_GlobalTable.HeartAttack_24HoursStart = time()           -- Used for natural degradation of HeartAttack_MaxVal
        HeartAttack_FirstTimeDone = true                                    -- First time launch flag to determine if add-on launched first time
        printInfo('First time? Type /hahelp for more information.')
    end
    --Every 10 minutes, trigger roll_heart_attack_chance to see if the player will experience a heart attack
    if not heart_attack_ticker then
        if HeartAttack_GlobalTable.HeartAttack_GameOver == false then
            heart_attack_ticker = C_Timer.NewTicker(HA_Frequency, HA_Table.roll_heart_attack_chance)
        end
    end
    calculate_24_hours_passed()
    if initial_game_load == false then
        create_interface()
        initial_game_load = true
    end
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
    if HeartAttack_GlobalTable.HeartAttack_DeadTime ~= nil then
        local dead_time = HeartAttack_GlobalTable.HeartAttack_DeadTime
        local time_dead = revive_time - dead_time
        local multiply = math.floor(time_dead * 1.15)
        printDebug("PLAYER_UNGHOST: Player was dead for "..time_dead.." seconds. Subtract "..multiply..".")
        HA_Table.subtract_max_val(multiply)
        HeartAttack_GlobalTable.HeartAttack_DeadTime = nil
    else
        printDebug("PLAYER_UNGHOST: HeartAttack_DeadTime was nil. Subtract 20.")
        HA_Table.subtract_max_val(20)
    end
end

--If the player died, subtract HeartAttack_MaxVal by 10 and save current epoch seconds in case the player quits.
function HA_Table.handle_player_dead()
    HeartAttack_GlobalTable.HeartAttack_DeadTime = time()
    printDebug("PLAYER_DEAD: Player died. Set HeartAttack_DeadTime to "..HeartAttack_GlobalTable.HeartAttack_DeadTime..". Subtract 10.")
    HA_Table.subtract_max_val(100)
end

--If the player leveled up, take the new level and subtract it from HeartAttack_MaxVal.
function HA_Table.handle_player_level_up(level)
    printDebug("PLAYER_LEVEL_UP: Subtract "..level..".")
    HA_Table.subtract_max_val(level)
end

--If the player successfully casts a spell, subtract 1 from HeartAttack_MaxVal
function HA_Table.handle_spellcast_succeeded()
    printDebug("UNIT_SPELLCAST_SUCCEEDED: subtract 1.")
    HA_Table.subtract_max_val(5)
end

--If the player said something in chat, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_msg(chat_type)
    printDebug(chat_type..": Subtract 1.")
    HA_Table.subtract_max_val()
end

--If the player mounts or dismounts, subtract 1 from HeartAttack_MaxVal.
--If the player was affected by a crown control or used a taxi, subtract 1 from HeartAttack_MaxVal.
--If the player changed target, subtract 1 from HeartAttack_MaxVal.
--If the player talks to an NPC, subtract 1 from HeartAttack_MaxVal.
--If the player casts any instant or non-instant spells, whether they have finished, subtract 1 from HeartAttack_MaxVal.
--If the player learns a new spell or profession, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_common_event(event)
    printDebug(event..": Subtract 1.")
    HA_Table.subtract_max_val(2)
end

--If the player interacts with his bag, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_bag()
    if bag_lock == false then
        bag_lock = true
        printDebug("BAG_UPDATE: Subtract 1.")
        HA_Table.subtract_max_val()
    end
end

--If the player sent a spell, subtract 1 from HeartAttack_MaxVal.
function HA_Table.handle_spellcast_sent()
    if spell_lock == false then
        spell_lock = true
        f:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
        printDebug("UNIT_SPELLCAST_SENT: subtract 1.")
    HA_Table.subtract_max_val(5)
    end
end

function f:OnEvent(event, arg1, arg2, arg3, arg4, _, _, _, _, _, _, _, arg12)
    --Initial load of AddOn when player logs in
    if event == 'PLAYER_ENTERING_WORLD' then HA_Table.handle_player_entering_world() end
    --Handling of all events that cause HeartAttack_MaxVal to lower as well as counting of chat messages to use during randomizer
    if HeartAttack_GlobalTable ~= nil and
            HeartAttack_GlobalTable.HeartAttack_GameOver ~= nil and
            HeartAttack_GlobalTable.HeartAttack_GameOver == false and
            HeartAttack_GlobalTable.HeartAttack_EventLock == false then
        if event == 'PLAYER_STARTED_MOVING' then HA_Table.handle_player_started_moving()
        elseif event == 'PLAYER_STOPPED_MOVING' then HA_Table.handle_player_stopped_moving()
        elseif event == 'UNIT_COMBAT' and arg1 == 'player' and arg2 == 'WOUND' then HA_Table.handle_unit_combat(arg4, arg3)
        elseif --[[event == 'PLAYER_ALIVE' or]] event == 'PLAYER_UNGHOST' then HA_Table.handle_player_alive()
        elseif event == 'PLAYER_DEAD' then HA_Table.handle_player_dead()
        elseif event == 'PLAYER_LEVEL_UP' then HA_Table.handle_player_level_up(arg1)
        elseif event == 'PLAYER_STARTED_TURNING' then HA_Table.handle_player_started_turning()
        elseif event == 'PLAYER_STOPPED_TURNING' then HA_Table.handle_player_stopped_turning()
        elseif event == 'UNIT_SPELLCAST_SUCCEEDED' and initial_world_load and arg1 == 'player' then HA_Table.handle_spellcast_succeeded()
        elseif tContains(common_events, event) then HA_Table.handle_common_event(event)
        elseif tContains(chat_types, event) and arg12 == player_guid then HA_Table.handle_msg(event)
        --To avoid double BAG_UPDATE from moving items in the backpack, lock the event to capture only 1 event
        elseif event == 'BAG_UPDATE' and initial_world_load then HA_Table.handle_bag() C_Timer.After(0.1, function() bag_lock = false end)
        --To avoid instant spell casts being counted twice, unregister UNIT_SPELLCAST_SUCCEEDED and then register it shortly after
        elseif event == 'UNIT_SPELLCAST_SENT' then HA_Table.handle_spellcast_sent()
            C_Timer.After(0.1, function() spell_lock = false f:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED') end)
        elseif event == 'LEARNED_SPELL_IN_TAB' and initial_world_load then HA_Table.handle_common_event(event) end
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
f:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
f:RegisterEvent('BANKFRAME_OPENED')
f:RegisterEvent('AUCTION_HOUSE_SHOW')
f:RegisterEvent('BAG_UPDATE')
f:RegisterEvent('LEARNED_SPELL_IN_TAB')
f:SetScript('OnEvent', f.OnEvent)
