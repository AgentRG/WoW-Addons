local gossip_frame = CreateFrame("Frame", "ZoomerWoW")
local ready = false
local mapping_table = {
    multi_words = {
        ["i'm going to"] = 'finna',
        ['i am going to'] = 'finna',
        ["doesn't lie"] = 'no cap',
        ['sitting back'] = 'sip tea',
        ['i am'] = "i'ma",
        ['for real'] = 'fr',
        ['show off'] = 'flex',
        ['are the'] = 'be',
        ['really use'] = 'crazy use',
        ['i understand'] = 'say less',
        ['call out'] = 'clapback',
        ['trying to'] = 'tryna'
    },
    single_words = {
        ['i'] = 'ya boi',
        ['specialist'] = 'spesh',
        ['skills'] = 'skillz',
        ['skill'] = 'skillz',
        ["you'll"] = 'u',
        ['about'] = 'bout',
        ["he's"] = 'he be',
        ['family'] = 'fam',
        ['transform'] = 'glow up',
        ['transformation'] = 'glow up',
        ['master'] = 'CEO',
        ['professor'] = 'CEO',
        ['boss'] = 'CEO',
        ['fan'] = 'stan',
        ['please'] = 'plz',
        ['stalker'] = 'stan',
        ['observer'] = 'stan',
        ['win'] = 'W',
        ['victory'] = 'W',
        ['excellent'] = 'dank',
        ['awesome'] = 'dank',
        ['great'] = 'dank',
        ['left'] = 'ghosted',
        ['leave'] = 'ghost',
        ['jealous'] = 'salty',
        ['jealously'] = 'saltiness',
        ['awful'] = 'big yikes',
        ['bad'] = 'big yikes',
        ['evil'] = 'big yikes',
        ['embarrassed'] = 'big yikes',
        ['fancy'] = 'boujee',
        ['extravagant'] = 'boujee',
        ['lie'] = 'cap',
        ['attractive'] = 'snack',
        ['loss'] = 'L',
        ['lose'] = 'L',
        ['losing'] = "L'ing",
        ["i'm"] = "i'ma",
        ['looking'] = "lookin'",
        ['good'] = 'bop',
        ['stylish'] = 'drip',
        ['*sigh*'] = 'sheesh',
        ['sigh'] = 'sheesh',
        ['mad'] = 'living rent free in my head',
        ['yes'] = 'bet',
        ['agree'] = 'bet',
        ['agreed'] = 'bet',
        ['okay'] = 'bet',
        ['mood'] = 'vibe',
        ['energy'] = 'vibe',
        ['nerves'] = 'several seats',
        ['fight'] = 'catch these hands',
        ['trick'] = 'finesse',
        ['manipulate'] = 'finesse',
        ['charismatic'] = 'main character',
        ['charm'] = 'rizz',
        ['charisma'] = 'main character syndrome',
        ['sister'] = 'sis',
        ['brother'] = 'bro',
        ['funny'] = 'sending me',
        ['amazing'] = 'slaps',
        ['amaze'] = 'slap',
        ['exceptional'] = "slappin'",
        ['delicious'] = "bussin'",
        ['suspicious'] = 'sus',
        ['suspect'] = 'sus',
        ['untrustworthy'] = 'sus',
        ['shady'] = 'sus',
        ['outfit'] = 'snatched',
        ['money'] = 'guap',
        ['gold'] = 'guap',
        ['small'] = 'smol',
        ['tiny'] = 'smol',
        ['greatest'] = 'G.O.A.T',
        ['hey'] = 'suh',
        ['hello'] = 'suh',
        ['family'] = 'fam',
        ['embarrassing '] = 'big yikes',
        ['kill'] = 'ded',
        ['amusing'] = 'I oop',
        ['hope'] = 'let him cook',
        ['insult'] = 'l+ratio',
        ['hot'] = 'lit',
        ['mutual'] = 'moot',
        ['person'] = 'NPC',
        ['freak'] = 'NPC',
        ['wild'] = 'out of pocket',
        ['crazy'] = 'out of pocket',
        ['extreme'] = 'out of pocket',
        ['shocked'] = 'shook',
        ['surprised'] = 'shook',
        ['bothered'] = 'shook',
        ['happiness'] = 'sksksk',
        ['acceptable'] = 'valid',
        ['throw'] = 'yeet',
        ['uncool'] = 'cheugy',
        ['fierce'] = 'snatched',
        ['quite'] = 'low-key',
        ['moderate'] = 'low-key',
        ['there'] = 'thar',
        ['my'] = 'ma',
        ['opinion'] = 'take',
        ['ouch'] = 'big yikes',
        ['dramatic'] = 'extra',
        ['positive'] = 'green flag',
        ['desire'] = 'goal',
        ['woman'] = 'girlboss',
        ['very'] = 'highkey',
        ['warning'] = 'red flag',
        ['kill'] = 'slay',
        ['friend'] = 'fam',
        ['have'] = 'haz',
        ['welcome'] = 'yoooooo',
        ['you'] = 'ya',
        ['and'] = 'n',
        ['your'] = 'ur',
        ['are'] = 'be',
        ['sad'] = 'salty',
        ['grieve'] = 'salty'
    }
}

local function process_text(input_text)

    local function ignore_punctuation(word)
        return word:gsub("%p", "")
    end

    local lower_text = input_text:lower()

    local function split(str)
        local words = {}
        for word in str:gmatch("%S+") do
            table.insert(words, word)
        end
        return words
    end

    local original_words = split(input_text)
    local words = split(lower_text)
    local result = ""
    local words_changed = {}

    local i = 1
    while i <= #words do
        if i < #words then
            local pair = ignore_punctuation(words[i]) .. " " .. ignore_punctuation(words[i + 1])
            if mapping_table['multi_words'][pair] then
                result = result .. mapping_table['multi_words'][pair] .. " "
                words_changed[i] = true
                words_changed[i + 1] = true
                i = i + 2
            else
                result = result .. original_words[i] .. " "
                i = i + 1
            end
        else
            result = result .. original_words[i] .. " "
            i = i + 1
        end
    end

    local text_after_multi_words_swap = split(result)
    result = ""

    for _, word in ipairs(text_after_multi_words_swap) do
        local current_word = ignore_punctuation(word):lower()
        if not words_changed[i] and mapping_table['single_words'][current_word] then
            result = result .. mapping_table['single_words'][current_word] .. " "
        else
            result = result .. word .. " "
        end
    end

    return result:sub(1, -2) -- Remove trailing space
end

local function get_process_set_text()
    local text
    local frame
    if GreetingText:IsVisible() then
        text = GreetingText:GetText()
        frame = GreetingText
    elseif GossipFrame.GreetingPanel:IsVisible() then
        text = C_GossipInfo.GetText()
        local parentFrame = GossipFrame.GreetingPanel.ScrollBox.ScrollTarget
        for _, region in ipairs({parentFrame:GetChildren()}) do
            if region:GetObjectType() == 'Frame' then
                for _, region_2 in ipairs({region:GetRegions()}) do
                    if region_2:GetObjectType() == "FontString" and region_2:GetText() then
                        frame = region_2
                        break
                    end
                end
            end
        end
    elseif QuestInfoDescriptionText:IsVisible() then
        text = QuestInfoDescriptionText:GetText()
        frame = QuestInfoDescriptionText
    end
    if text ~= nil and frame ~= nil then
        text = process_text(text)
        frame:SetText(text)
    end
end


gossip_frame:RegisterEvent('ADDON_LOADED')
gossip_frame:RegisterEvent('GOSSIP_SHOW')
gossip_frame:RegisterEvent('QUEST_GREETING')
gossip_frame:RegisterEvent('QUEST_DETAIL')
gossip_frame:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')

gossip_frame:SetScript('OnEvent', function(_, event, arg1)
    if event == 'GOSSIP_SHOW' or event == 'QUEST_GREETING' or (event == 'PLAYER_INTERACTION_MANAGER_FRAME_SHOW'
            and (arg1 == 3 or arg1 == 4)) or event == 'QUEST_DETAIL' and ready then
        get_process_set_text()
    end
    if event == 'ADDON_LOADED' and arg1 == "ZoomerWoW" then
        ready = true
        gossip_frame:UnregisterEvent('ADDON_LOADED')
    end
end)