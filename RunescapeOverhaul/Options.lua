local addonName, addonData = ...

function addonData:CreateOptionsInterface()
    local options_frame = CreateFrame("Frame", "RunescapeOverhaul_Options")
    options_frame.name = "Runescape Overhaul"
    local checkbox_table = {
        { name = 'Enable Fonts', tooltip = 'All fonts in the game will be converted to the Runescape font'
        , x = 8, flag = RO_Table.EnableFonts, func = function(boolean)
            RO_Table.EnableFonts = boolean
            if RO_Table.EnableFonts == true then
                addonData:Init_Fonts()
            end
            if RO_Table.EnableFonts == false then
                C_UI.Reload()
            end
        end },
        { name = 'Enable Sound Effects', tooltip = 'Will play sound effects when certain actions occur'..
                ' (i.e. player level up, player death)', x = 208, flag = RO_Table.EnableMusic, func = function(boolean)
            RO_Table.EnableMusic = boolean
        end },
    }
    for i = 1, #checkbox_table do
        local checkbox = CreateFrame("CheckButton", UIParent, options_frame, "ChatConfigCheckButtonTemplate")
        checkbox.tooltip = checkbox_table[i].tooltip
        checkbox.Text:SetText(checkbox_table[i].name)
        checkbox:SetPoint("TOPLEFT", checkbox_table[i].x, -10)
        checkbox:SetChecked(checkbox_table[i].flag)
        checkbox:SetScript("OnClick", function()
            checkbox_table[i].func(checkbox:GetChecked())
        end)
    end
    InterfaceOptions_AddCategory(options_frame, true)
end