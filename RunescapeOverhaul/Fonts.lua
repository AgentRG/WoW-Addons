local addonName, addonData = ...

-- Global font names taken from https://www.wowinterface.com/forums/showthread.php?t=55149
-- Runescape font taken from Runelite client GitHub repo https://github.com/runelite/runelite/tree/master/runelite-client/src/main/resources/net/runelite/client/ui
function addonData:Init_Fonts()
    local newFont = "Interface\\AddOns\\RunescapeOverhaul\\Resources\\Fonts\\runescape.ttf"

    STANDARD_TEXT_FONT          = newFont
    UNIT_NAME_FONT              = newFont
    DAMAGE_TEXT_FONT            = newFont
    NAMEPLATE_FONT              = newFont
    NAMEPLATE_SPELLCAST_FONT    = newFont

    local ForcedFontSize = {10, 14, 20, 64, 64}

    local BlizFontObjects = {

        -- Fonts.xml

        -- These five fonts use the fixedSize argument, causing an incorrect font size return, so input our own sizes (ForcedFontSize)
        SystemFont_NamePlateCastBar, SystemFont_NamePlateFixed, SystemFont_LargeNamePlateFixed, SystemFont_World, SystemFont_World_ThickOutline,

        SystemFont_Outline_Small, SystemFont_Outline, SystemFont_InverseShadow_Small, SystemFont_Med2, SystemFont_Med3, SystemFont_Shadow_Med3,
        SystemFont_Huge1, SystemFont_Huge1_Outline, SystemFont_OutlineThick_Huge2, SystemFont_OutlineThick_Huge4, SystemFont_OutlineThick_WTF,
        NumberFont_GameNormal, NumberFont_Shadow_Small, NumberFont_OutlineThick_Mono_Small, NumberFont_Shadow_Med, NumberFont_Normal_Med,
        NumberFont_Outline_Med, NumberFont_Outline_Large, NumberFont_Outline_Huge, Fancy22Font, QuestFont_Huge, QuestFont_Outline_Huge,
        QuestFont_Super_Huge, QuestFont_Super_Huge_Outline, SplashHeaderFont, Game11Font, Game12Font, Game13Font, Game13FontShadow,
        Game15Font, Game18Font, Game20Font, Game24Font, Game27Font, Game30Font, Game32Font, Game36Font, Game48Font, Game48FontShadow,
        Game60Font, Game72Font, Game11Font_o1, Game12Font_o1, Game13Font_o1, Game15Font_o1, QuestFont_Enormous, DestinyFontLarge,
        CoreAbilityFont, DestinyFontHuge, QuestFont_Shadow_Small, MailFont_Large, SpellFont_Small, InvoiceFont_Med, InvoiceFont_Small,
        Tooltip_Med, Tooltip_Small, AchievementFont_Small, ReputationDetailFont, FriendsFont_Normal, FriendsFont_Small, FriendsFont_Large,
        FriendsFont_UserText, GameFont_Gigantic, ChatBubbleFont, Fancy16Font, Fancy18Font, Fancy20Font, Fancy24Font, Fancy27Font, Fancy30Font,
        Fancy32Font, Fancy48Font, SystemFont_NamePlate, SystemFont_LargeNamePlate,

        -- SharedFonts.xml

        SystemFont_Tiny2, SystemFont_Tiny, SystemFont_Shadow_Small, SystemFont_Small, SystemFont_Small2, SystemFont_Shadow_Small2, SystemFont_Shadow_Med1_Outline,
        SystemFont_Shadow_Med1, QuestFont_Large, SystemFont_Large, SystemFont_Shadow_Large_Outline, SystemFont_Shadow_Med2, SystemFont_Shadow_Large,
        SystemFont_Shadow_Large2, SystemFont_Shadow_Huge1, SystemFont_Huge2, SystemFont_Shadow_Huge2, SystemFont_Shadow_Huge3, SystemFont_Shadow_Outline_Huge3,
        SystemFont_Shadow_Outline_Huge2, SystemFont_Med1, SystemFont_WTF2, SystemFont_Outline_WTF2,
        GameTooltipHeader, System_IME,
    }

    for i, FontObject in pairs(BlizFontObjects) do
        local _, oldSize, oldStyle  = FontObject:GetFont()
        FontObject:SetFont(newFont, ForcedFontSize[i] or oldSize, oldStyle)
    end

    BlizFontObjects = nil
end