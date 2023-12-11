local addonName, addonData = ...

local core = CreateFrame("Frame", "RunescapeOverhaul_Core")

core:RegisterEvent('ADDON_LOADED')
core:SetScript('OnEvent', function(self, event, name)
    if event == 'ADDON_LOADED' and name == 'RunescapeOverhaul' then
        if not RO_Table then
            RO_Table = {}
            RO_Table.EnableFonts = false
            RO_Table.EnableMusic = false
        end
        if RO_Table.EnableFonts == true then
            addonData:Init_Fonts()
        end
        addonData:CreateOptionsInterface()
    end
end)