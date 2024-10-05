local L = {}

local locale = GetLocale()

if locale == "enUS" then
    L["VERSION"] = "Version"
    L["SAVE_SPELLS"] = "Save Spells"
    L["CANCEL"] = "Cancel"
    L["ENABLE_DEBUGGER"] = "Enable Debugger"
    L["ENABLE_AUDIO_CUE"] = "Enable Audio Cue"
    L["PROC"] = "Proc"
    L["GLOW"] = "Glow"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Cast"
    L["RED"] = "Red"
    L["GREEN"] = "Green"
    L["BLUE"] = "Blue"
    L["ALPHA"] = "Alpha"
    L["LINES"] = "Lines"
    L["SCALE"] = "Scale"
    L["FREQUENCY"] = "Frequency"
    L["THICKNESS"] = "Thickness"
    L["UNSAVED_CHANGES"] = "You have unsaved changes!"
    L["ABOUT_MOD"] = "About the mod:\n\n" ..
            "• If the current mob is a boss, class interrupt spells will be highlighted instead of user selections.\n\n" ..
            "• The debugger is mainly for developer use. Enabling it will cause a lot of chat noise.\n\n" ..
            "• Please let the developer of any bugs you come across at either the GitHub repository, CurseForge or" ..
            " WoWInterface.\n\n" ..
            "• Please let the developer know if any spells are missing from the list of spells available for selection."
else
    L["VERSION"] = "Version"
    L["SAVE_SPELLS"] = "Save Spells"
    L["CANCEL"] = "Cancel"
    L["ENABLE_DEBUGGER"] = "Enable Debugger"
    L["ENABLE_AUDIO_CUE"] = "Enable Audio Cue"
    L["PROC"] = "Proc"
    L["GLOW"] = "Glow"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Cast"
    L["RED"] = "Red"
    L["GREEN"] = "Green"
    L["BLUE"] = "Blue"
    L["ALPHA"] = "Alpha"
    L["LINES"] = "Lines"
    L["SCALE"] = "Scale"
    L["FREQUENCY"] = "Frequency"
    L["THICKNESS"] = "Thickness"
    L["UNSAVED_CHANGES"] = "You have unsaved changes!"
    L["ABOUT_MOD"] = "About the mod:\n\n" ..
            "• If the current mob is a boss, class interrupt spells will be highlighted instead of user selections.\n\n" ..
            "• The debugger is mainly for developer use. Enabling it will cause a lot of chat noise.\n\n" ..
            "• Please let the developer of any bugs you come across at either the GitHub repository, CurseForge or" ..
            " WoWInterface.\n\n" ..
            "• Please let the developer know if any spells are missing from the list of spells available for selection."
end


InterruptReminder_Localization = L