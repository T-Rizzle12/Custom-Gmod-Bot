# Use
- Install this addon: place the Custom Gmod Bot folder (Unzip before use) in your gmod addons folder.
- Create at least a 2 player gmod server. This addon creates a "player" bot so you must have a open player spot because gmod will consider the bot a real player. 
- Create a bot using the TRizzleCreateBot Command. (See below)

This addon is on steam, you can download it there instead: https://steamcommunity.com/sharedfiles/filedetails/?id=2969405101

# Important [![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/dwyl/esta/issues) [![HitCount](https://hits.dwyl.com/T-Rizzle12/start-here.svg)](https://hits.dwyl.com/T-Rizzle12/Custom-Gmod-Bot)

This mod is in *Beta*, there will be bugs, but constant updates with new features and fixes.

Although you can just clone the repository. (I will put updates into a secondary branch before releasing it) I would suggest downloading the latest release, Thank You!

Special thanks to [Zenlenafelex [PSF]](https://steamcommunity.com/profiles/76561198976669728) for helping me with the pathfinding code for the bot.

## Why I made this mod
I made this because I usually have to play Gmod alone and I also wanted to see what I could do with the nextbot system.

# Commands
CommandName, CommandParameters, Example
- <code>TRizzleCreateBot</code> <code>botname</code> <code>followdist</code> <code>dangerdist</code> <code>melee</code> <code>pistol</code> <code>shotgun</code> <code>rifle</code> <code>sniper</code> <code>hasScope</code> <code>meleedist</code> <code>pistoldist</code> <code>shotgundist</code> <code>rifledist</code> <code>healthreshold</code> <code>combathealthreshold</code> <code>playermodel</code> <code>spawnwithpreferredweapons</code>
  - TRizzleCreateBot Bot 200 300 weapon_crowbar weapon_pistol weapon_shotgun weapon_smg1 weapon_crossbow 1 80 1300 300 900 100 25 alyx 1
- <code>TBotSetFollowDist</code> <code>targetbot</code> <code>followdist</code> 
  -  TBotSetFollowDist Bot 200
- <code>TBotSetDangerDist</code> <code>targetbot</code> <code>dangerdist</code> 
  - TBotSetDangerDist Bot 300
- <code>TBotSetMelee</code> <code>targetbot</code> <code>melee</code> 
  - TBotSetMelee Bot weapon_crowbar
- <code>TBotSetPistol</code> <code>targetbot</code>  <code>pistol</code>  
  - TBotSetPistol Bot weapon_pistol
- <code>TBotSetShotgun</code> <code>targetbot</code>  <code>shotgun</code>  
  - TBotSetShotgun Bot weapon_shotgun
- <code>TBotSetRifle</code> <code>targetbot</code>  <code>rifle</code>  
  - TBotSetRifle Bot weapon_smg1
- <code>TBotSetSniper</code> <code>targetbot</code>  <code>sniper</code> <code>1 or 0</code>  
  - TBotSetRifle Bot weapon_crossbow 1
- <code>TBotSetMeleeDist</code> <code>targetbot</code>  <code>meleedist</code>  
  - TBotSetMelee Bot 80
- <code>TBotSetPistolDist</code> <code>targetbot</code>  <code>pistoldist</code>  
  - TBotSetPistol Bot 1300
- <code>TBotSetShotgunDist</code> <code>targetbot</code>  <code>shotgundist</code>  
  - TBotSetShotgun Bot 300
- <code>TBotSetRifleDist</code> <code>targetbot</code>  <code>rifledist</code>  
  - TBotSetRifle Bot 900
- <code>TBotSetHealThreshold</code> <code>targetbot</code>  <code>healthreshold</code>  
  - TBotSetHealThreshold Bot 100
- <code>TBotSetCombatHealThreshold</code> <code>targetbot</code>  <code>combathealthreshold</code>  
  - TBotSetCombatHealThreshold Bot 25
- <code>TBotSetPlayerModel</code> <code>targetbot</code>  <code>playermodel</code>  
  - TBotSetRifle Bot alyx
- <code>TBotSpawnWithPreferredWeapons</code> <code>targetbot</code>  <code>1 or 0</code>  
  - TBotSpawnWithPreferredWeapons Bot 1
- <code>TBotSetDefault</code> <code>targetbot</code>  
  - TBotSetDefault Bot


# Current Features
- The bot is a player bot
- The bot can use ladders
- The bot has "smooth aiming" (Aim won't instantly aim at enemies) 
- The bot can open doors
- The bot has an LOS, "Line of Sight," and can't see behind itself
- The bot remembers enemies it has seen recently
- The bot can "hear" noises created by enemies
- The bot will use its flashlight when in a dark area
- The bot will attack any NPC that is hostile them and its "owner" (The player that created it)
- The bot, if it has a medkit, will heal itself and any players nearby it, although the bot's owner is prioritized.
- The bot can enter the vehicle the bot's owner is in. This includes most modded vehicles and chairs. See "Issues"
- Support for most custom/modded weapons. 

## Bot Cheats
I know what you are thinking, but these are needed to make the bot fun and easy to use.
- The bot will slowly regenerate ammo for its weapons when not in combat. This prevents the player from having to "give" the bot ammo or it having to be programed to "find" ammo. (Collect it from dead enemies)     

# Issues
- The bot doesn't know if a Nextbot is hostile or friendly, wont attack nextbots at all!
- The bot doesn’t know how to drive cars, basic support is planned.

# Planned Features
- [ ] Get the bot to detect Nextbots
