# Last Commando — playable alpha

## Mission

A lone commando survives a fictional military battlefield for ten active minutes.
Weapons fire automatically. Movement, XP collection, upgrade selection, and dodging
are the player's decisions. Extraction succeeds at 10:00 even if the command tank
survives. Death ends the run and opens the after-action report.

- Keyboard: WASD/arrows; Enter deploys; Escape pauses; 1–3 choose an upgrade.
- Mouse: drag the battlefield to move.
- Touch: floating joystick in the lower-left half; switch to the right in Settings.
- Opening upgrades or pause freezes the simulation. Resume has a brief countdown
  and clears old touch input.
- Save & Briefing preserves the deployment. Continue restores it paused, or restores
  the pending upgrade selection. Backgrounding and ten-second checkpoints also save.

## Weapons

| Level | Heavy machine gun | Tactical flamethrower | Artillery radio |
| --- | --- | --- | --- |
| 1 | 10 damage, .25s interval, 260 range | 5 damage/.2s, 70 range, 60° cone, 2s on/2s off | 80 damage, 48 radius, 8s cooldown |
| 2 | 13 damage | 7 damage/tick | 110 damage |
| 3 | .20s interval | 90 range | 60 radius |
| 4 | One additional pierced enemy | 4 damage/s burn, 3s duration | Two shells |
| 5 | 17 damage, 300 range | 90° cone, 1.5s cooling | 6.5s cooldown |
| 6 | .16s interval | 9 damage/tick, 3s firing | 140 damage, 68 radius |

Ammo Belt grants +10% machine-gun damage per rank. Pressurized Fuel grants +10%
flame range per rank. Signal Amplifier removes 10% of artillery's base cooldown
per rank. Supports cap at rank 2; weapons cap at rank 6.

A rank-6 weapon plus its matching rank-2 support becomes eligible for evolution.
Walk over a gold elite cache to evolve one eligible weapon. Unusable caches remain
on the battlefield. If several qualify, the order is machine gun, flame, artillery.

- **Cerberus Rotary Cannon:** two parallel bullets every .12s, three targets per
  bullet; hits slow enemies briefly. The command tank receives reduced slow.
- **Inferno Projector:** continuous flame, with three-second ground fires from
  burning kills. Overlapping fires do not stack; fire damage cannot chain fires.
- **Rolling Thunder:** five sequential artillery impacts through the target cluster.

Bullets gain 15% damage against burning enemies. Artillery gains 20% against burning
enemies and 15% against suppressed enemies, added together with a 35% maximum.

XP requirement is `8 + 18 × (player_level − 1)`. This was increased after full-run
simulation showed the original curve caused excessive upgrade interruptions.
The efficient invulnerable collection bot reaches roughly level 28; that is a
progression test, not a prediction of typical player performance.

## Wave schedule

| Minute | Ordinary spawn rate / active cap | New pressure |
| --- | --- | --- |
| 0–1 | 3/s / 80 | Infantry, rifles after 0:40 |
| 1–2 | 5/s / 120 | Rifle fans and surrounding infantry |
| 2–3 | 7/s / 170 | Position-locked rush attacks; elite captain at 2:30 |
| 3–4 | 9/s / 220 | Tank at 3:15; mortar at 3:40 |
| 4–5 | 11/s / 280 | Elite tank and cache at 4:20 |
| 5–6 | 13/s / 330 | Helicopter at 5:10; gapped strafe lines |
| 6–7 | 15/s / 380 | Elite helicopter and cache at 6:30 |
| 7–8 | 17/s / 430 | Combined pressure; elite captain at 7:40 |
| 8–9 | 19/s / 480 | Up to 3 ordinary tanks, 2 helicopters, 4 mortars; elite tank at 8:40 |
| 9–10 | 14/s / 500 | Command tank at 9:00; survive until extraction |

Large attacks share a scheduling budget. Ranged enemies must be visible before
starting an attack. Enemy projectile windups and mortar circles warn before damage;
only three hostile ground marks may coexist. Rushers lock a target position before
charging. Helicopter volleys reserve capacity for the complete pattern and leave a
gap. Friendly strikes use green markers; hostile markers use orange/red.

## Architecture

- `Battle`: fixed-step, render-independent simulation, seeded randomness, wave
  schedule, weapons, damage, progression, snapshot validation.
- `EntityPool`: fixed-capacity packed arrays, free slots, generation counters,
  reset-on-reuse. Limits: 500 enemies, 400 friendly bullets, 600 hostile bullets,
  250 pickup clusters.
- Spatial grid: 64-unit cells for targeting and collision candidates. Fast bullets
  use swept segment collision, and remember pierced target generations.
- `Battlefield`: immediate 2D drawing plus small generated pixel textures. No node,
  collision body, timer, or particle emitter per enemy. Visual effects have caps.
- `run.gd`: UI, touch ownership, lifecycle, input, save persistence, and presentation.
- `CombatAudio`: eight reusable sound voices with original synthesized effects.

Pool capacity never grows during a run. XP merges preserve value. Cosmetic effects
are capped separately. Simulation pauses during choices rather than accumulating
catch-up time. Saves use Godot Variant serialization without object deserialization,
validate their version and pool structure, and replace the destination atomically.

## Scope

This is a playable alpha, not a store-ready release. Art is original procedural
pixel art, with simple vehicle silhouettes and terrain. The battlefield is open;
terrain markings are decorative. Persistent unlocks, monetization, localization,
obstacle navigation, extensive content, physical-phone thermal profiling, and store
signing are outside this build. Balance still needs human playtesting.
