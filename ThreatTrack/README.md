# ThreatTrack
Keep track of all threat percentages through a display of a table of all units currently in-combat with the player, as
in, the unit in question is aware of the player's existence and considers him a threat to some degree.

## Features
* Provide a 360 degree coverage of all threat percentages surrounding the player.
* Units currently being tanked by the player are colored in green on the table.
* Threat percent tracking starts and stops at the start and end of combat.
* Allow the user the update how often the display should update (using slash command /ttset)

## Technical Overview
Threat percentage calculation can happen only one the unit in question is in the user's rendering FOV and only if the 
user has nameplates on enemies enabled. If the user is not looking at a unit he's in combat with or has nameplates
disabled, technically the calculation cannot happen using the provided API to the add-on developers. To accommodate for
that, the add-on will keep track of the old entry and append the percentage with a (*) sign to indicate that the unit
is not currently visible.