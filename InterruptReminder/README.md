# InterruptReminder

Highlight the class' interrupt abilities when the target is casting or channeling a spell that can
be interrupted. Useful for newer players learning their rotation, or those like me, who simply forget to cast their
interrupts.

## Features
* Real-time tracking of a target's spell casting and providing World of Warcraft's actionbar glow effect to spells
who's primarily function is to cause an interrupt. The spell being tracked are as followed:
  * Death Knight: Mind Freeze, Asphyxiate, Strangulate, Death Grip
  * Demon Hunter: Disrupt 
  * Druid: Skull Bash, Solar Beam 
  * Evoker: Quell 
  * Hunter: Counter Shot, 'Muzzle 
  * Mage: Counterspell 
  * Monk: Spear Hand Strike 
  * Paladin: Rebuke, Avenger's Shield 
  * Priest: Silence 
  * Rogue: Kick 
  * Shaman: Wind Shear 
  * Warlock: Spell Lock, Optical Blast, Axe Toss 
  * Warrior: Pummel

* Optional opt-in into additional tracking of any spell capable of applying a Crowd Control affect (also interrupting)
using `/irinit`
  * Doing so also enables an algorithm that tries to find any spell capable of causing a Crowd Control effect to the 
    target in the character's spellbook, as well as determining whether the current target is not a boss, thus being
    susceptible to Crowd Control effects.
    * Dev note: There's a bit of logic into determining whether the current target is a "boss". Outside of
    dungeons/raids, it is determined by their frame, but inside dungeons/raids, there's a lot more involved
    (see `IR_Table.is_target_a_boss()` in the Lua file for more information). If you come across a boss or a minion
    that cause a Crowd Control spell to glow incorrectly, please do let me know. 