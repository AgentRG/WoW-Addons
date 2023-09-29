local TT_Table = {}
local percentage = {}
local oldPercentage = {}
local friendlyNameplates = {}
local enemyNameplates = {}
local oldEnemyNameplates = {}
local guidTable = {}
local notTanking = {}
local bossInserts
local previousNumGroupMembers
local player = 'player'
local party = 'party'
local raid = 'raid'
local na = 'N/A'
local unknown = 'unknown'
local two_decimal_format = '%.2f'
local skullIcon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
local updateTableTicker
SLASH_THREAT_TRACK_HELP1 = "/tthelp"
SLASH_THREAT_TRACK_SET1 = "/ttset"

SlashCmdList.THREAT_TRACK_HELP = function()
    print("/ttset {seconds}: Set how often the display should update in seconds (/ttset 2).")
end

SlashCmdList.THREAT_TRACK_SET = function(arg1)
    if (arg1 == "" or arg1:find("%D")) then
        print("|cffffff00Warning (ThreatTrack): |cffffffff Seconds passed are invalid. Expected an integer but received: "..arg1)
    else
        local number = tonumber(arg1)
        if number >= 0 then
            number = tonumber(arg1)
            ThreatTrack_seconds = number
            if number == 0 then
                print("|cff00ffffInfo (ThreatTrack): |cffffffff Updated the seconds to update the percentage table to be real time (0 seconds).")
            else
                print("|cff00ffffInfo (ThreatTrack): |cffffffff Updated the seconds to update the percentage table to every "..number.." seconds.")
            end
        else
            print("|cffffff00Warning (ThreatTrack): |cffffffff Something went wrong! Please let the creator know what you typed in for seconds.")
        end
    end
end

local f = CreateFrame('Frame', 'ThreatTrack', UIParent, 'BackdropTemplate')

local function calculate_threat_percentage_difference_between_player_and_friendly(playerThreat, friendlyThreat)
    return tonumber(string.format(two_decimal_format, playerThreat / friendlyThreat * 100))
end

local function merge_two_tables(table_one, table_two)
    for i = 1, #table_two do
        table_one[#table_one + 1] = table_two[i]
    end
    return table_one
end

local function sort_percentage_table()
    if #percentage > 1 then
        table.sort(percentage, function(k1, k2)
            if k1.percent ~= nil and k2.percent ~= nil and k1.real_number == true and k2.real_number == true then
                return k1.percent > k2.percent
            end
        end)
        -- Push all N/A to the bottom of the table. Push all units currently being tanked to the beginning of the table
        for i = 1, #percentage do
            if percentage[i].percent == na then
                local element = percentage[i]
                table.remove(percentage, i)
                percentage[#percentage + 1] = element
            elseif percentage[i].tanking == true then
                local element = percentage[i]
                table.remove(percentage, i)
                table.insert(percentage, 1, element)
            end
        end
    end
end

local function isnan(value)
    return value ~= value
end

local function isinf(value)
    return value == math.huge
end

local function find_row_by_guid(table, target_guid)
    for _, row in ipairs(table) do
        if row.guid == target_guid then
            return row
        end
    end
    return nil
end

---[[
---FRONTEND STUFF STARTS HERE
---]]

--- Main frame
f:SetSize(240, 50)
f:SetPoint("CENTER", 0, 0)
f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
f:SetBackdropColor(0, 0, 0, 0.5)
f:SetMovable(true)
f:EnableMouse(true)
f:SetResizable(true)
f:SetResizeBounds(240, 50)

--- Vertical divider line
local vertical_line = f:CreateLine()
vertical_line:SetColorTexture(0.78, 0.61, 0.43, 1)
vertical_line:SetThickness(0.9)
vertical_line:SetStartPoint("TOPRIGHT", -59, -3)
vertical_line:SetEndPoint("BOTTOMRIGHT", -59, 3)

--- Horizontal divider line
local horizontal_line = f:CreateLine()
horizontal_line:SetColorTexture(0.78, 0.61, 0.43, 1)
horizontal_line:SetThickness(1)
horizontal_line:SetStartPoint("TOPLEFT", 3, -25)
horizontal_line:SetEndPoint("TOPRIGHT", -3, -25)

--- Resize
local resizeButton = CreateFrame("Button", nil, f)
resizeButton:EnableMouse("true")
resizeButton:SetPoint("BOTTOMRIGHT")
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetScript("OnMouseDown", function(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end)
resizeButton:SetScript("OnMouseUp", function(self)
    self:GetParent():StopMovingOrSizing("BOTTOMRIGHT")
end)

--- Frame dragging
f:SetScript("OnMouseDown", function(self)
    self:StartMoving()
end)
f:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
end)

--- Unit Name Header
local unitNameHeader = f:CreateFontString(nil, "ARTWORK", "GameFontWhite")
unitNameHeader:SetPoint("TOPLEFT", 6, -10)
unitNameHeader:SetText("Unit Name")

--- Unit Threat % Header
local threatPercentHeader = f:CreateFontString(nil, "ARTWORK", "GameFontWhite")
threatPercentHeader:SetPoint("TOPRIGHT", -6, -10)
threatPercentHeader:SetText("Threat %")

--- Tooltip for why there's a clear icon when GUID table populates
local function show_tooltip()
    GameTooltip:SetOwner(f, "ANCHOR_CURSOR")
    GameTooltip:AddLine("Clear GUID Collection")
    GameTooltip:Show()
end

local function hide_tooltip() GameTooltip:Hide() end

--- Button to clear the GUID table if it's too large for user's comfort
local clearGuidButton = CreateFrame("Button", nil, f)
clearGuidButton:Hide()
clearGuidButton:Disable()
clearGuidButton:EnableMouse("true")
clearGuidButton:SetPoint("TOPRIGHT", -62, -7)
clearGuidButton:SetSize(16, 16)
clearGuidButton:SetNormalTexture("Interface\\common\\voicechat-muted")
clearGuidButton:SetScript("OnClick", function()
    guidTable = {}
    enemyNameplates = {}
    unitNameHeader:SetText("Unit Name")
    clearGuidButton:Hide()
    clearGuidButton:Disable()
end)
clearGuidButton:SetScript("OnEnter", show_tooltip)
clearGuidButton:SetScript("OnLeave", hide_tooltip)

--- Frontend code that handles ingesting percentage and showing it to the user
local unitNameFramePool = {}
local percentFramePool = {}
local bossTexturePool = {}

local function get_frames_to_load()
    for i = 1, #percentage do
        if unitNameFramePool[i] == nil then
            unitNameFramePool[#unitNameFramePool + 1] = { frame = f:CreateFontString(nil, "ARTWORK", "GameFontWhite") }
        end
        if percentFramePool[i] == nil then
            percentFramePool[#percentFramePool + 1] = { frame = f:CreateFontString(nil, "ARTWORK", "GameFontWhite") }
        end
        if bossTexturePool[i] == nil then
            bossTexturePool[#bossTexturePool + 1] = { frame = f:CreateTexture(nil) }
            bossTexturePool[i].frame:SetTexture(skullIcon)
            bossTexturePool[i].frame:SetSize(10, 10)
        end
    end
end

local function clear_display()
    for i = 1, #unitNameFramePool do
        local unitName = unitNameFramePool[i].frame
        local percent = percentFramePool[i].frame
        local boss = bossTexturePool[i].frame
        unitName:SetTextColor(1, 1, 1, 1)
        percent:SetTextColor(1, 1, 1, 1)
        unitName:Hide()
        percent:Hide()
        boss:Hide()
    end
end

local function get_table_size(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

local function update_display()
    get_frames_to_load()
    clear_display()

    local y = -30
    local frame_height_limit = math.floor(f:GetHeight() - 10)
    -- Making a local copy of the percentage table in case it was set to null by backend mid-iteration
    local percentageTable = percentage

    for i = 1, #percentageTable do
        if math.abs(y) >= frame_height_limit then
            break
        end
        local unitNameFrame = unitNameFramePool[i].frame
        local percentFrame = percentFramePool[i].frame
        local bossFrame = bossTexturePool[i].frame
        percentFrame:SetPoint("TOPRIGHT", -6, y)
        if percentageTable[i].name ~= nil and percentageTable[i].percent ~= nil then
            if percentageTable[i].tanking == true then
                unitNameFrame:SetTextColor(0, 1, 0, 1)
                percentFrame:SetTextColor(0, 1, 0, 1)
            end
            unitNameFrame:SetText(percentageTable[i].name)
            if percentageTable[i].visible == false then
                if percentageTable[i].percent ~= na then
                    percentFrame:SetText(percentageTable[i].percent .. "%*")
                else
                    percentFrame:SetText(percentageTable[i].percent .. "*")
                end
            else
                if percentageTable[i].percent ~= na then
                    percentFrame:SetText(percentageTable[i].percent .. "%")
                else
                    percentFrame:SetText(percentageTable[i].percent)
                end
            end
            percentFrame:Show()
            -- If the unit is a boss, show the skull target icon next to his name on the table
            if tContains(ThreatTrack_currentBossList, percentageTable[i].name) then
                bossFrame:SetPoint("TOPLEFT", 6, y)
                unitNameFrame:SetPoint("TOPLEFT", 17, y)
                bossFrame:Show()
            else
                unitNameFrame:SetPoint("TOPLEFT", 6, y)
            end
            unitNameFrame:Show()
            y = y - 15
        end
    end
end

---[[
---BACKEND STUFF STARTS HERE
---]]
--Get the current map Id and get the bosses for zone, if there are any.
local function generate_boss_list()
    local encounters = C_EncounterJournal.GetEncountersOnMap(C_Map.GetBestMapForUnit(player)) or {}
    bossInserts = 0
    for _, encounter in pairs(encounters) do
        for i = 1, 9 do
            local name = select(2, EJ_GetCreatureInfo(i, encounter.encounterID))
            if name then
                ThreatTrack_currentBossList[#ThreatTrack_currentBossList + 1] = name
                bossInserts = bossInserts + 1
            else
                break
            end
        end
    end
end

--So the table will not keep expanding forever, limit the maximum to 50 saved bosses
local function truncate_boss_list()
    local inserts = bossInserts
    if #ThreatTrack_currentBossList >= 50 then
        for _ = 1, inserts do
            table.remove(ThreatTrack_currentBossList, 1)
        end
    end
end

--[[Sometimes when switching between zones in a single zone, a previous boss encounter is captured. Since only one
mention of the boss is needed, removing duplicates so as to not reach the table limit too fast]]
local function remove_boss_duplicates()
    local hash = {}
    local res = {}

    for _, v in ipairs(ThreatTrack_currentBossList) do
        if (not hash[v]) then
            res[#res + 1] = v
            hash[v] = true
        end
    end
    ThreatTrack_currentBossList = res
end

local function is_player_in_group_or_raid()
    local currentGroupNum = GetNumGroupMembers()
    if currentGroupNum ~= 0 then
        if IsInRaid() then
            return 1
        elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            return 0
        elseif IsInGroup() then
            return 0
        end
    else
        return nil
    end
end

local function get_enemy_nameplates()
    local guidCopy = guidTable
    for _, unitData in pairs(guidCopy) do
        local unitGuid = unitData[1]
        local unitToken = UnitTokenFromGUID(unitGuid)
        local unitName = unitData[2]

        if enemyNameplates[unitGuid] ~= nil then
            if unitToken ~= nil then
                if UnitAffectingCombat(unitToken) then
                    enemyNameplates[unitGuid] = {guid = oldEnemyNameplates[unitGuid].guid, nameplate = unitToken, name = oldEnemyNameplates[unitGuid].name, visible = true, combat = true}
                else
                    enemyNameplates[unitGuid] = {guid = oldEnemyNameplates[unitGuid].guid, nameplate = unitToken, name = oldEnemyNameplates[unitGuid].name, visible = true, combat = false}
                end
            else
                enemyNameplates[unitGuid] = {guid = oldEnemyNameplates[unitGuid].guid, nameplate = unitToken, name = oldEnemyNameplates[unitGuid].name, visible = false, combat = oldEnemyNameplates[unitGuid].combat}
            end
        else
            if unitToken ~= nil then
                if UnitAffectingCombat(unitToken) then
                    enemyNameplates[unitGuid] = { guid = unitGuid, nameplate = unitToken, name = unitName, visible = true, combat = true }
                else
                    enemyNameplates[unitGuid] = { guid = unitGuid, nameplate = unitToken, name = unitName, visible = true, combat = false }
                end
            else
                enemyNameplates[unitGuid] = { guid = unitGuid, nameplate = unitToken, name = unitName, visible = false, combat = unknown }
            end
        end
    end
    oldEnemyNameplates = enemyNameplates
end

local function get_group_nameplates()
    local groupType
    if is_player_in_group_or_raid() == 0 then
        groupType = party
    else
        groupType = raid
    end
    local currentGroupNum = GetNumGroupMembers()
    if previousNumGroupMembers == currentGroupNum and next(friendlyNameplates) ~= nil then
        return
    else
        friendlyNameplates = {}
        for i = 1, currentGroupNum do
            local unit = groupType .. i
            if UnitAffectingCombat(unit) then
                friendlyNameplates[#friendlyNameplates + 1] = { unit = unit }
            end
        end
        previousNumGroupMembers = currentGroupNum
    end
end

local function find_percent_based_on_current_tanker_of_nameplate()
    for i = 1, #notTanking do
        for j = 1, #friendlyNameplates do
            local isTanking, _, _, _, threatValue = UnitDetailedThreatSituation(friendlyNameplates[j].unit, notTanking[i].nameplate)
            if isTanking == true then
                local percent = calculate_threat_percentage_difference_between_player_and_friendly(notTanking[i].threatValue, threatValue)
                if type(percent) == "number" and not isnan(percent) --[[NaN check]] and not isinf(percent) --[[Infinite check]] then
                    percentage[#percentage + 1] = { guid = notTanking[i].guid, name = notTanking[i].name, percent = percent, real_number = true }
                else
                    percentage[#percentage + 1] = { guid = notTanking[i].guid, name = notTanking[i].name, percent = "N/A", real_number = false }
                end
                break
            end
        end
    end
end

local function generate_already_tanking_and_not_tanking_tables()
    get_enemy_nameplates()
    get_group_nameplates()
    percentage = {}
    notTanking = {}
    local unseenEnemies = {}
    local alreadyTanking = {}
    local localNotTanking = {}
    local nameplates = enemyNameplates
    for _, unitData in pairs(nameplates) do
        if unitData.visible == true and unitData.combat == true then
            local isTanking, _, _, _, threatValue = UnitDetailedThreatSituation(player, unitData.nameplate)
            if isTanking == true then
                alreadyTanking[#alreadyTanking + 1] = { guid = unitData.guid, name = unitData.name, percent = 100.00, tanking = true, real_number = true, visible = true }
            elseif isTanking == false then
                localNotTanking[#localNotTanking + 1] = { guid = unitData.guid, nameplate = unitData.nameplate, name = unitData.name, threatValue = threatValue, visible = true }
            end
        elseif unitData.visible == false and unitData.combat == true then
            local previous_record = find_row_by_guid(oldPercentage, unitData.guid)
            if previous_record ~= nil then
                unseenEnemies[#unseenEnemies + 1] = { guid = previous_record.guid, name = previous_record.name, percent = previous_record.percent, tanking = previous_record.tanking, real_number = previous_record.real_number, visible = false }
            end
        end
    end
    notTanking = localNotTanking
    find_percent_based_on_current_tanker_of_nameplate()
    merge_two_tables(percentage, alreadyTanking)
    merge_two_tables(percentage, unseenEnemies)
    oldPercentage = percentage
    sort_percentage_table()
    update_display()
end

local function track_threat()
    generate_already_tanking_and_not_tanking_tables()
end

local function stop_backend_ticker()
    if updateTableTicker then
        updateTableTicker:Cancel()
        updateTableTicker = nil
    end
end

local function start_backend_ticker()
    if not updateTableTicker then
        updateTableTicker = C_Timer.NewTicker(ThreatTrack_seconds, track_threat)
    end
end

---[[
---EVENT HANDLING HERE
---]]
function TT_Table.handle_player_entering_world()
    local areEnemyNameplatesEnabled = C_CVar.GetCVar("nameplateShowEnemies")
    if areEnemyNameplatesEnabled == '0' then
        print("|cffffff00Warning (ThreatTrack): |cffffffff Detected that enemy nameplates are disabled! This add-on will not function with enemy nameplates disabled. Enable enemy nameplates by going to Options>Interface>Enemy Unit Nameplate.")
    end
    previousNumGroupMembers = 0
    guidTable = {}
    enemyNameplates = {}
    if ThreatTrack_currentBossList == nil then
        ThreatTrack_currentBossList = {}
    end
    if ThreatTrack_seconds == nil then
        ThreatTrack_seconds = 1
    end
end

function TT_Table.handle_player_entering_combat()
    start_backend_ticker()
end

function TT_Table.handle_player_leaving_combat()
    enemyNameplates = {}
    friendlyNameplates = {}
    percentage = {}
    notTanking = {}
    stop_backend_ticker()
    clear_display()
end

function TT_Table.handle_zone_change()
    generate_boss_list()
    remove_boss_duplicates()
    truncate_boss_list()
end

function TT_Table.handle_nameplate_added(nameplate)
    local unitGuid = UnitGUID(nameplate)
    if guidTable[unitGuid] == nil then
        if UnitCanAttack(player, nameplate) and UnitExists(nameplate) and UnitIsUnit(nameplate, nameplate) then
            local unitName = UnitName(nameplate)
            guidTable[unitGuid] = { unitGuid, unitName }
            unitNameHeader:SetText("Unit Name: Tracking (" .. get_table_size(guidTable) .. ")")
            if clearGuidButton:GetButtonState() == 'DISABLED' then
                clearGuidButton:Enable()
                clearGuidButton:Show()
            end
        end
    end
end

function TT_Table.handle_combat_log()
    local _, subevent, _, _, _, _, _, unitGuid = CombatLogGetCurrentEventInfo()
    if subevent == 'UNIT_DIED' or subevent == 'UNIT_DESTROYED' or subevent == 'UNIT_DISSIPATES' then
        guidTable[unitGuid] = nil
        enemyNameplates[unitGuid] = nil

        local tableSize = get_table_size(guidTable)

        if tableSize > 0 then
            unitNameHeader:SetText("Unit Name: Tracking (" .. tableSize .. ")")
        else
            unitNameHeader:SetText("Unit Name")
            clearGuidButton:Hide()
            clearGuidButton:Disable()
        end
    end
end

function f:OnEvent(event, arg1)
    if event == 'PLAYER_REGEN_DISABLED' then
        TT_Table.handle_player_entering_combat()
    end
    if event == 'PLAYER_REGEN_ENABLED' then
        TT_Table.handle_player_leaving_combat()
    end
    if event == 'PLAYER_ENTERING_WORLD' then
        TT_Table.handle_player_entering_world()
    end
    if event == 'ZONE_CHANGED' or event == 'ZONE_CHANGED_NEW_AREA' or event == 'ZONE_CHANGED_INDOORS' then
        TT_Table.handle_zone_change()
    end
    if event == 'NAME_PLATE_UNIT_ADDED' then
        TT_Table.handle_nameplate_added(arg1)
    end
    if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        TT_Table.handle_combat_log()
    end
end

f:RegisterEvent('PLAYER_REGEN_DISABLED')
f:RegisterEvent('PLAYER_REGEN_ENABLED')
f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:RegisterEvent('ZONE_CHANGED')
f:RegisterEvent('ZONE_CHANGED_NEW_AREA')
f:RegisterEvent('ZONE_CHANGED_INDOORS')
f:RegisterEvent('NAME_PLATE_UNIT_ADDED')
f:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
f:SetScript('OnEvent', f.OnEvent)