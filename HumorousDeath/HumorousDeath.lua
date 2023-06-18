SLASH_HUMOROUS_DEATH_DEBUG1 = "/hddebug"
SLASH_HUMOROUS_DEATH_ROTATE1 = "/hdsetrotate"
SLASH_HUMOROUS_DEATH_RANDOM1 = "/hdsetrandom"

-- Table from which the add-on retrieves and stores all runtime data.
local HD_Table = {}
HD_Table.SoundHandlerID = nil
HD_Table.SoundFileCollection = {'WiiTheme', 'DarkSouls3', 'TheyDrewFirstBlood', 'FinalFantasy7GameOver',
                                'GameOverYeah', 'GTAVWasted', 'HalfLife2DeathSound', 'ChaosTheoryGameOver',
                                'LegoYodaDeathSound', 'FrodoNoooo', 'MajorasMaskGameOver', 'AliensGameOverMan',
                                'MarioGameOver', 'MassEffect2CriticalMissionFailure', 'OSRSYouAreDeadMusic',
                                'PacmanDeath', 'RobloxOof', 'SnakeSnakeSnaaaake', 'TF2HeavyYouAreDead', 'BoTWGameOver',
                                'CCCComboBreaker', 'DeuxExJensen', 'NoSequelForYou', 'DonkeyKongCountryGameOver',
                                'FortniteDowned', 'HaloAnnouncerSkillIssue', 'LeonDeathSound', 'HankHillBwaaa',
                                'MK3Fatality', 'MTGVTheyPlayedAFiddle', 'MW2MissionFailed', 'SimpsonsDoh', 'RyuKO',
                                'ObiwanSmarter', 'ScoutImDead', 'SuperSmashBrosKO', 'SuperMarioWorldGameOver',
                                'YouFailedTeamFortress2', 'OmaeWaMouShindeiru', 'AmongUsKill', 'Shazbot',
                                'FamilyGuyShhAhh', 'UnrealTournamentHeadshot'}
HD_Table.TotalNumberOfFiles = #HD_Table.SoundFileCollection
local RandomInt
local LastTenRandom = {}
local f = CreateFrame('Frame', 'HumorousDeath')
local PlaySoundFile = PlaySoundFile
local StopSound = StopSound


local function printInfo(text) print("|cff00ffffInfo (HumorousDeath): |cffffffff"..text) end


-- Slash command to print the contents of HD_Table excluding functions and static content. Used for debugging. Also prints the current HumorousDeath_IterateInt.
SlashCmdList.HUMOROUS_DEATH_DEBUG = function()
    for j, k in pairs(HD_Table) do
        if type(k) ~= "function" and j ~= 'SoundFileCollection' then
            if type(k) == "table" then
                print(j, '(Table)')
                for o, p in pairs(k) do
                    print(' '..o, p)
                end
            else
                print(j, k)
            end
        end
    end
    if HumorousDeath_Setting == 0 then
        print("Current Humorous Death Setting: Rotate")
        print("Next sound file to be played is file #"..HumorousDeath_IterateInt.." with the name \""..HD_Table.SoundFileCollection[HumorousDeath_IterateInt]..".mp3.\"")
    elseif HumorousDeath_Setting == 1 then
        print("Current Humorous Death Setting: Random")
        print("Next sound file to be played is file #".. RandomInt .." with the name \""..HD_Table.SoundFileCollection[RandomInt]..".mp3.\"")
    end
end

-- Set sound rotation to incremental
SlashCmdList.HUMOROUS_DEATH_ROTATE = function()
    HumorousDeath_Setting = 0
    LastTenRandom = {}
    printInfo("Changed sound setting to rotation. Sound files will play incrementally.")
end

-- Set sound rotation to random
SlashCmdList.HUMOROUS_DEATH_RANDOM = function()
    HumorousDeath_Setting = 1
    RandomInt = math.random(1, HD_Table.TotalNumberOfFiles)
    table.insert(LastTenRandom, RandomInt)
    printInfo("Changed sound setting to random. Sound files will play randomly.")
end

-- Plays the next sound file in the list and iterates global variable by one. If all the current global variable is past
-- the list of files, set it back to 1.
function HD_Table.handle_player_dying()
    if HumorousDeath_Setting == 0 then
        HD_Table.SoundHandlerID = select(2, PlaySoundFile("Interface\\AddOns\\HumorousDeath\\Resources\\".. HD_Table.SoundFileCollection[HumorousDeath_IterateInt] ..".mp3", "Master"))
        HumorousDeath_IterateInt = HumorousDeath_IterateInt + 1
        if HumorousDeath_IterateInt > HD_Table.TotalNumberOfFiles then HumorousDeath_IterateInt = 1 end
    elseif HumorousDeath_Setting == 1 then
        HD_Table.SoundHandlerID = select(2, PlaySoundFile("Interface\\AddOns\\HumorousDeath\\Resources\\".. HD_Table.SoundFileCollection[RandomInt] ..".mp3", "Master"))
        RandomInt = math.random(1, HD_Table.TotalNumberOfFiles)
        while tContains(LastTenRandom, RandomInt) do
            RandomInt = math.random(1, HD_Table.TotalNumberOfFiles)
        end
        table.insert(LastTenRandom, RandomInt)
        if #LastTenRandom == 11 then
            table.remove(LastTenRandom, 1)
        end
    end
end


-- Stop the sound from playing once the player has revived
function HD_Table.handle_player_revived()
    local soundHandle = HD_Table.SoundHandlerID
    if soundHandle ~= nil and type(soundHandle) == 'number' then
        StopSound(HD_Table.SoundHandlerID)
        HD_Table.SoundHandlerID = nil
    end
end


-- Handles the logic for when the enter players the world (initial login or /reload).
function HD_Table.handle_player_entering_world()
    if HumorousDeath_IterateInt == nil then
        HumorousDeath_IterateInt = 1
        HumorousDeath_Setting = 0
    end
    if HumorousDeath_Setting == 1 then
        RandomInt = math.random(1, HD_Table.TotalNumberOfFiles)
        table.insert(LastTenRandom, RandomInt)
    end
end


function f:OnEvent(event)
    if event == 'PLAYER_DEAD' then HD_Table.handle_player_dying() end
    if event == 'PLAYER_ALIVE' then HD_Table.handle_player_revived() end
    if event == 'PLAYER_ENTERING_WORLD' then HD_Table.handle_player_entering_world() end
end


f:RegisterEvent('PLAYER_DEAD')
f:RegisterEvent('PLAYER_ALIVE')
f:RegisterEvent('PLAYER_ENTERING_WORLD')
f:SetScript('OnEvent', f.OnEvent)