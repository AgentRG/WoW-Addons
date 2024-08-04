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
        ['over with'] = 'ratioed',
        ['really use'] = 'crazy use',
        ['looking for you'] = 'malding',
        ['best friend'] = 'bestie',
        ['step forward'] = 'pull up',
        ['i understand'] = 'say less',
        ['call out'] = 'clapback',
        ["don't know"] = 'dunno',
        ['trying to'] = 'tryna',
        ['shut up'] = "quit yappin'",
        ['wrong with him'] = 'got bro down'
    },
    single_words = {
        ['i'] = 'ya boi',
        ['cross'] = 'hop',
        ['specialist'] = 'spesh',
        ['skills'] = 'skillz',
        ['skill'] = 'skillz',
        ["you'll"] = 'u',
        ['home'] = 'Ohio',
        ['place'] = 'Ohio',
        ['she'] = 'step-sister',
        ['places'] = 'Ohios',
        ['city'] = 'Ohio',
        ['village'] = 'gooncave',
        ['heaven'] = 'Kai Cenant',
        ['about'] = 'bout',
        ['stole'] = 'copped',
        ['stop'] = 'edge',
        ['archer'] = 'pogger',
        ['archers'] = 'poggers',
        ['stopping'] = 'edging',
        ['line'] = 'grind',
        ['courage'] = 'aura',
        ['mistake'] = 'cap',
        ['step'] = 'griddy',
        ['call'] = 'shill',
        ['honor'] = 'GOATED fr',
        ['horse'] = 'whip',
        ["he's"] = 'he be',
        ['family'] = 'fam',
        ['transform'] = 'glow up',
        ['transformation'] = 'glow up',
        ['master'] = 'CEO',
        ['professor'] = 'CEO',
        ['boss'] = 'CEO',
        ['soldier'] = 'simp',
        ['soldiers'] = 'simps',
        ['brothers'] = 'gooners',
        ['brother'] = 'gooner',
        ['trying'] = "tryin'",
        ['fan'] = 'stan',
        ['father'] = 'Alpha',
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
        ['awake'] = 'woke',
        ['extravagant'] = 'boujee',
        ['lie'] = 'cap',
        ['attractive'] = 'snack',
        ['loss'] = 'L',
        ['lose'] = 'L',
        ['losing'] = "L'ing",
        ["i'm"] = "i'ma",
        ['looking'] = "lookin'",
        ['king'] = 'short king',
        ['good'] = 'based',
        ['stylish'] = 'drip',
        ['*sigh*'] = 'sheesh',
        ['sigh'] = 'sheesh',
        ['rebels'] = 'rizzlers',
        ['rebellion'] = 'rizz-bellion',
        ['captured'] = 'copped',
        ['capture'] = 'cop',
        ['mad'] = 'living rent free in my head',
        ['yes'] = 'bet',
        ['offensive'] = 'big yikes',
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
        ['sister'] = 'step-sister',
        ['funny'] = 'sending me',
        ['amazing'] = 'slaps',
        ['amaze'] = 'slap',
        ['exceptional'] = "slappin'",
        ['delicious'] = "bussin'",
        ['suspicious'] = 'sus',
        ['suspect'] = 'sus',
        ['speaking'] = 'yapping',
        ['untrustworthy'] = 'sus',
        ['shady'] = 'sus',
        ['outfit'] = 'snatched',
        ['money'] = 'guap',
        ['gold'] = 'guap',
        ['small'] = 'smol',
        ['tiny'] = 'smol',
        ['greatest'] = 'G.O.A.T',
        ['hey'] = 'suh',
        ['impressive'] = 'banger',
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
        ['nice'] = 'chill',
        ['fierce'] = 'snatched',
        ['quite'] = 'low-key',
        ['go'] = 'goon',
        ['moderate'] = 'low-key',
        ['there'] = 'thar',
        ['my'] = 'ma',
        ['opinion'] = 'take',
        ['taking'] = 'thug-shaking',
        ['ouch'] = 'big yikes',
        ['dramatic'] = 'extra',
        ['positive'] = 'green flag',
        ['desire'] = 'goal',
        ['woman'] = 'girlboss',
        ['girl'] = 'gyatt',
        ['run'] = 'edge',
        ['running'] = 'edging',
        ['very'] = 'highkey',
        ['warning'] = 'red flag',
        ['kill'] = 'slay',
        ['ambush'] = 'mog',
        ['boy'] = 'femboy',
        ['mixed'] = 'maxxed',
        ['walked'] = 'griddied',
        ['friend'] = 'fam',
        ['have'] = 'haz',
        ['came'] = 'rizzed',
        ['welcome'] = 'yoooooo',
        ['allies'] = 'rizzlers',
        ['ally'] = 'rizzler',
        ['you'] = 'mew',
        ['the'] = 'thar',
        ['and'] = 'n',
        ['dad'] = 'daddy',
        ['damn'] = 'fanum',
        ['thief'] = 'beta',
        ['your'] = 'ur',
        ['safe'] = 'locked-in',
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
    if C_AddOns.IsAddOnLoaded("Immersion") == true then
        text = ImmersionFrame.TalkBox.TextFrame.Text:GetLine()
        frame = ImmersionFrame.TalkBox.TextFrame.Text
    else
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
    end
    if text ~= nil and frame ~= nil then
        text = process_text(text)
        frame:DisplayLine(text)
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