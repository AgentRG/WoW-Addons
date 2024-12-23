## v2.4.5
General Changes:

    Supporting latest TOC version

## v2.4.4
General Changes:

    Revamped logic that would find the spells in the action bar.
    Moved around when the mods global table is being generated.
    Added localization for Portuguese, Chinese, French, German, Italian, Spanish, Korea and Russian (Created using AI, hopefully no spellling mistakes).

Bug Fixes:

    Removed a talent from Demon Hunter that was mistaken for a spell.
    Added missing RaceIDs to the mod table when pulling race spells.
    Fixed duplicate spells appearing in the list of spells due to other addons requesting spell data.


## v2.4.3
Bug Fixes:

    Further fixed localization other than English by moving to ClassIds and RaceIds
    Added a localization to translate mod text into other languages in the future

## v2.4.2
Bug Fixes:

    Fixed the settings UI being stuck in a loop of generation.


## v2.4.1
Bug Fixes:

    Fixed not all spells loading on UI load.
    

## v2.4.0
New Addition:

    Migrated from smart spell lookup based on keywords to hardcoded spell IDs based on character class/race.
    The reasoning being that support for multiple languages would be impossibly difficult to support.

    Plus due to frequent updates, I often had to exclude specific spells that got picked up by the mod because they
    matched the lookup, but did not meet the correct criteria.

    Cataclysm version of the mod is still using the old lookup logic. I do not plan to update that version of the mod
    as I do not play classic enough (or at all) to see myself spending time supporting it, but I am looking for volunteers!

General Changes:
    
    Removed all code related to smart lookup of spells.
    Added add-on version number to bottom left of config window.
    Rewrote some parts in the about-mod section.
    

## v2.3.1
Bug Fixes:

    Fixed null exception for spells that the player character does not have unlocked.

## v2.3.0
General Changes:

    Migrated old functions used to gather information about spells to be gathered from C classes.

Bug Fixes:

    Fixed settings menu initialization.
    Fixed extraneous spell showing up for Evokers.

## v2.2.0
New Addition:
    
    Sound cue option is now available in the add-on options menu.
    Support for Classic Cataclysm (No ElvUI support with Cataclysm).

Bug Fixes:

    Humans never get any love. Fixed a bug that prevented the mod from being used for Human race.


## v2.1.1
General Changes:

    Removed Quaking Palm from the Monk class as it is a Pandaren racial skill.
    Added new slash command /irconfig to quickly access the options menu.

## v2.1.0
New Addition:

    Highlight configurator! Can now select different configurations for the highlight of spells.
    Three new highlight types for the spell highlight effect.
    New library to handle the highlighting of spells.

General Changes:

    Frontend optimization where possible and fixing some race conditions in the frontend.

## v2.0.1
New Addition:

    Support for ElvUI. Should work the same as WoW's default interface.
    Caching of action button locations for faster repeat access.
    Improved algorithm that finds extraneous spells for faster search.

Bug Fixes:

    Fixed Mage Counterspell not appearing in the options menu.
    Fixed nil exception when selected spells are empty.

## v2.0.0
New Addition:

    Options page! All backslash commands except for /irinfo have been removed and migrated to a per-character options page.
    The player can now select individual spells that should be highlighted when an interruptible spell is being cast by the target.

Bug Fixes:

    Fixed a bug where off-cooldown spells that are eligible to be highlighted just didn't highlight. Issue had to do with the data returned by GetSpellCooldown().

## v1.3.1
Bug Fixes:

    Fixed a bug where a non-attackable target would still trigger the interrupt reminder to highlight the buttons
    Fixed a bug where the Evoker's Beath of Eons would highlight when an interruptible ability was being cast 

## v1.3.0
New Addition:

    Added the ability to track Crowd Control spells as well using an algorithm to find all spells capable of inflicting
    a crowd control status effect. With that, also added several slash commands as well as a bunch of internal fuctions
    to determine whether the current target can be affected by a crowd control spell.

General Changes:

    Due to the optional support of Crowd Control spells, most of the add-on logic had to be rewritten from ground up.

Bug Fixes:

    Fixed a bug where moving an interrupt spell to another location would cause the glow effect to stop functioning correctly.

---

## v1.2.2
Fixed bug:

    When the target gets crowd controlled, the spell would stay highlighted
    When the target loses sight of player, the spell would stay highlighted
    If the target was channeling, the spell highlight would sometimes appear and disappear in a span of a second

General fixes:

    Rewrite on how the events are handled inside OnEvent (to avoid duplicate code)
    More documentation
---

## v1.2.1
Bug fixes:
1. Fixed bug where an NPE would be raised if the player did not have one of the interrupts unlocked on his character (oops)
2. Fixed a bug where interrupt handling would occur on friendly units (no highlights would occur still)

---

## v1.2.0
Bug fixes:

    Add-on will not get blocked anymore for trying to access blocked functions through the usage of LibButtonGlow-1.0
    When switching to a new target, it will now check if the target is in the process of casting and proceed to act accordingly
    If the player had multiple interrupts on his action bars, in some cases, the wrong button would get highlighted.

New addition:

    Now able to capture spells that are currently on cooldown and pass them to a callback handler. If the spell becomes available before the target's spellcast finishes, the ability will get highlighted.

General changes:

    Made all functions related to the add-on local rather than global
    Optimized the code to run more efficiently where possible
    Added documentation (for my own sanity)

---

## v1.1.1
1. Interface 100100 support

---

## v1.1.0
1. Added several missing interrupt spells
2. Optimized the for loop that scans the action bars for spells