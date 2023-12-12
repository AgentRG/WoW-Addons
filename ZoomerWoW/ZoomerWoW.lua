local gossip_frame = CreateFrame("Frame", "ZoomerWoW")
local ready = false
local quest_greeting = GreetingText
local mapping_table = {
    ['family'] = 'fam',
    ['transform'] = 'glow up',
    ['transformation'] = 'glow up',
    ['master'] = 'CEO',
    ['professor'] = 'CEO',
    ['boss'] = 'CEO',
    ['fan'] = 'stan',
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
    ["i'm going to"] = 'finna',
    ['i am going to'] = 'finna',
    ['lie'] = 'cap',
    ["doesn't lie"] = 'no cap',
    ['attractive'] = 'snack',
    ['sitting back'] = 'sip tea',
    ['loss'] = 'L',
    ['losing'] = "L'ing",
    ["i'm"] = "i'ma",
    ['i am'] = "i'ma",
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
    ['for real'] = 'fr',
    ['show off'] = 'flex',
    ['positive'] = 'green flag',
    ['desire'] = 'goal',
    ['woman'] = 'girlboss',
    ['very'] = 'highkey',
    ['warning'] = 'red flag',
    ['kill'] = 'slay',
    ['friend'] = 'fam',
    ['have'] = 'haz'
}

local function process_text(input_text)
    local result = {}
    for word in input_text:gmatch("[%w%p]+") do
        local original_word = word:gsub("[%p]*$", "")
        local replace = mapping_table[string.lower(original_word)]
        local replaced_word = replace or original_word
        local final_word = replaced_word .. word:match("[%p]*$")
        table.insert(result, final_word)
    end
    return table.concat(result, ' ')
end

gossip_frame:RegisterEvent('ADDON_LOADED')
gossip_frame:RegisterEvent('GOSSIP_SHOW')
gossip_frame:RegisterEvent('QUEST_GREETING')
gossip_frame:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')

gossip_frame:SetScript('OnEvent', function(self, event, arg1)
    if event == 'GOSSIP_SHOW' or event == 'QUEST_GREETING' or (event == 'PLAYER_INTERACTION_MANAGER_FRAME_SHOW.3'
            and (arg1 == 3 or arg1 == 4)) and ready then
        local text = quest_greeting:GetText()
        local processed_text = process_text(text)
        quest_greeting:SetText(processed_text)
    end
    if event == 'ADDON_LOADED' and arg1 == "ZoomerWoW" then
        ready = true
        gossip_frame:UnregisterEvent('ADDON_LOADED')
    end
end)