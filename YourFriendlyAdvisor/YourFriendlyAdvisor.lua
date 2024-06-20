-- Create the main frame for the companion
local companionFrame = CreateFrame("Frame", "CompanionFrame", UIParent)
companionFrame:SetSize(200, 400)
companionFrame:SetPoint("CENTER", UIParent, "CENTER")
companionFrame:SetMovable(true)
companionFrame:EnableMouse(true)
companionFrame:RegisterForDrag("LeftButton")
companionFrame:SetScript("OnDragStart", companionFrame.StartMoving)
companionFrame:SetScript("OnDragStop", companionFrame.StopMovingOrSizing)

-- Add a background texture to the frame
companionFrame.bg = companionFrame:CreateTexture(nil, "BACKGROUND")
companionFrame.bg:SetAllPoints(true)
companionFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)

-- Create the 3D model frame
local companionModel = CreateFrame("PlayerModel", "CompanionModel", companionFrame)
companionModel:SetSize(256, 256)
companionModel:SetPoint("CENTER", companionFrame, "CENTER")

-- Set up the model (change DisplayID to whatever you like)
local function SetupCompanionModel()
    companionModel:SetDisplayInfo(64478)  -- DisplayID for a goblin, for example
end

-- Event handling for companion actions
local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        SetupCompanionModel()
        local m = CreateFrame("PlayerModel", nil, UIParent)
        m:SetPoint("CENTER")
        m:SetSize(256, 256)
        m:SetDisplayInfo(21723) -- creature/murloccostume/murloccostume.m2
    elseif event == "ACHIEVEMENT_EARNED" then
        companionModel:SetAnimation(60)  -- Cheer animation
        print("Congratulations on your achievement!")
    elseif event == "PLAYER_REGEN_DISABLED" then
        print("Good luck in combat!")
    elseif event == "PLAYER_REGEN_ENABLED" then
        print("Great job in combat!")
    end
end

-- Register events
companionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
companionFrame:RegisterEvent("ACHIEVEMENT_EARNED")
companionFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
companionFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

companionFrame:SetScript("OnEvent", OnEvent)

-- Initialize the model when the addon loads
SetupCompanionModel()
