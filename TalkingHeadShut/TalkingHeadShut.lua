local ready = false

local frame = CreateFrame("Frame", "TalkingHeadShut")
local ticker

local function stop_ticker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function close_talking_head()
    if TalkingHeadFrame.MainFrame.CloseButton:IsVisible() == true then
        TalkingHeadFrame.MainFrame.CloseButton:Click()
        stop_ticker()
    end
end

local function start_ticker()
    ticker = C_Timer.NewTicker(0, close_talking_head)
end

frame:RegisterEvent('TALKINGHEAD_REQUESTED')
frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', function(self, event, arg1)
    if event == 'ADDON_LOADED' and arg1 == 'TalkingHeadShut' then
        ready = true
        frame:UnregisterEvent('ADDON_LOADED')
    end
    if event == 'TALKINGHEAD_REQUESTED' and ready then
        start_ticker()
    end
end)