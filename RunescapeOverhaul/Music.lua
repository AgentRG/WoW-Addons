local addonName, addonData = ...

local PlaySoundFile = PlaySoundFile
local string = string

-- Music sourced from @jaydubsmusic and @vartdalen on YouTube. All music rights belong to Jagex and other rightful owners.
local base = "Interface\\AddOns\\RunescapeOverhaul\\Resources\\Music\\"
local player_level_up = base .. "PlayerLeveUp\\"
local quest_complete = base .. "Quest\\"
local profession_level_up = base .. "ProfessionLevelUp\\"
local player_dead = base .. "PlayerDead\\"
local music_table = {
    ['Player'] = {
        player_level_up .. "attack_1.mp3", player_level_up .. "attack_2.mp3", player_level_up .. "defence_1.mp3",
        player_level_up .. "defence_2.mp3", player_level_up .. "hitpoints_1.mp3", player_level_up .. "hitpoints_2.mp3",
        player_level_up .. "magic_1.mp3", player_level_up .. "magic_2.mp3", player_level_up .. "prayer_1.mp3",
        player_level_up .. "prayer_2.mp3", player_level_up .. "ranged_1.mp3", player_level_up .. "ranged_2.mp3",
        player_level_up .. "strength_1.mp3", player_level_up .. "strength_2.mp3"
    },
    ['Profession'] = {
        profession_level_up .. "agility.mp3", profession_level_up .. "construction_1.mp3",
        profession_level_up .. "construction_2.mp3", profession_level_up .. "cooking_1.mp3",
        profession_level_up .. "cooking_2.mp3", profession_level_up .. "crafting_1.mp3",
        profession_level_up .. "crafting_2.mp3", profession_level_up .. "farming_1.mp3",
        profession_level_up .. "farming_2.mp3", profession_level_up .. "firemaking_1.mp3",
        profession_level_up .. "firemaking_2.mp3", profession_level_up .. "fishing_1.mp3",
        profession_level_up .. "fishing_2.mp3", profession_level_up .. "fletching_1.mp3",
        profession_level_up .. "fletching_2.mp3", profession_level_up .. "helblore_1.mp3",
        profession_level_up .. "helblore_2.mp3", profession_level_up .. "hunter_1.mp3",
        profession_level_up .. "hunter_2.mp3", profession_level_up .. "mining_1.mp3",
        profession_level_up .. "mining_2.mp3", profession_level_up .. "runecrafting_1.mp3",
        profession_level_up .. "runecrafting_2.mp3", profession_level_up .. "slayer_1.mp3",
        profession_level_up .. "slayer_2.mp3", profession_level_up .. "smithing_1.mp3",
        profession_level_up .. "smithing_2.mp3", profession_level_up .. "thieving_1.mp3",
        profession_level_up .. "thieving_2.mp3", profession_level_up .. "woodcutting_1.mp3",
        profession_level_up .. "woodcutting_2.mp3"
    },
    ['Quest'] = {
        quest_complete .. "quest_1.mp3", quest_complete .. "quest_2.mp3", quest_complete .. "quest_3.mp3"
    },
    ['Dead'] = {
        player_dead .. "Dead.mp3"
    }
}
local channel = 'Music'

local function return_random_song_from_table(array)
    local array_size = #music_table[array]
    return music_table[array][math.random(1, array_size)]
end

local function player_died_event()
    PlaySoundFile(return_random_song_from_table('Dead'), channel)
end

local function player_level_up_event()
    PlaySoundFile(return_random_song_from_table('Player'), channel)
end

local function quest_complete_event()
    PlaySoundFile(return_random_song_from_table('Quest'), channel)
end

local function profession_level_up_event()
    PlaySoundFile(return_random_song_from_table('Profession'), channel)
end

local function is_chat_message_level_up(message)
    return string.match(message, 'Your skill in')
end

local f = CreateFrame('Frame', 'RunescapeOverhaul_Music')
f:RegisterEvent('QUEST_TURNED_IN')
f:RegisterEvent('PLAYER_LEVEL_UP')
f:RegisterEvent('CHAT_MSG_SKILL')
f:RegisterEvent('PLAYER_DEAD')

function f:OnEvent(event, arg1)
    if event == 'PLAYER_DEAD' then
        player_died_event()
    end
    if event == 'PLAYER_LEVEL_UP' then
        player_level_up_event()
    end
    if event == 'QUEST_TURNED_IN' then
        quest_complete_event()
    end
    if event == 'CHAT_MSG_SKILL' then
        if is_chat_message_level_up(arg1) then
            profession_level_up_event()
        end
    end
end

f:SetScript('OnEvent', f.OnEvent)