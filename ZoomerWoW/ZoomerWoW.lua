local gossip_frame = CreateFrame("Frame", "ZoomerWoW")
local ready = false
local quest_greeting = GreetingText
local mapping_table = {
    ['for'] = 'fr',
}


local function process_text(input_text)
    local result = {}
    for word in input_text:gmatch("[%w%p%d]+") do
        local replace = mapping_table[word]
        table.insert(result, replace or word)
    end
    return table.concat(result, ' ')
end

gossip_frame:RegisterEvent('ADDON_LOADED')
gossip_frame:RegisterEvent('GOSSIP_SHOW')
gossip_frame:RegisterEvent('QUEST_GREETING')
gossip_frame:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')

gossip_frame:SetScript('OnEvent', function(self, event, arg1)
    if event == 'GOSSIP_SHOW' or event == 'QUEST_GREETING' and ready then
        local text = C_GossipInfo.GetText()
        local processed_text = process_text(text)
        --quest_greeting:SetText(processed_text)
    end
    if event == 'PLAYER_INTERACTION_MANAGER_FRAME_SHOW' then
        print('ping')
    end
    if event == 'ADDON_LOADED' and arg1 == "ZoomerWoW" then
        ready = true
        gossip_frame:UnregisterEvent('ADDON_LOADED')
    end
end)