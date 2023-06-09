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