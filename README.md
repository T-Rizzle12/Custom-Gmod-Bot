 # Important
This is a "player" bot so you will need to set the game to multiplayer and have a open player spot to create one.

This mod is in Beta, there will be bugs, but constant updates with new features and fixes.

Although you can just clone the repository. (I will put updates into a secondary branch before releasing it) I would suggest downloading the latest release, Thank You!

## Why I made this mod
I made this because I usually have to play Gmod alone and I also wanted to see what I could do with the nextbot system.

Special thanks to [Zenlenafelex [PSF]](https://steamcommunity.com/profiles/76561198976669728) for helping me with the pathfinding code for the bot.

# Current Commands
CommandName, CommandParameters, Example
- <code>TRizzleCreateBot</code> <code>botname</code> <code>followdist</code> <code>dangerdist</code> <code>melee</code> <code>pistol</code> <code>shotgun</code> <code>rifle</code> <code>sniper</code> <code>meleedist</code> <code>pistoldist</code> <code>shotgundist</code> <code>rifledist</code> <code>healthreshold</code> <code>combathealthreshold</code> <code>playermodel</code> <code>spawnwithpreferredweapons</code>
  - TRizzleCreateBot Bot 200 300 weapon_crowbar weapon_pistol weapon_shotgun weapon_smg1 weapon_crossbow 80 1300 300 900 100 25 alyx 1
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
- <code>TBotSetSniper</code> <code>targetbot</code>  <code>sniper</code>  
  - TBotSetRifle Bot weapon_crossbow
- <code>TBotSetMeleeDist</code> <code>targetbot</code>  <code>meleedist</code>  
  - TBotSetMelee Bot weapon_crowbar
- <code>TBotSetPistolDist</code> <code>targetbot</code>  <code>pistoldist</code>  
  - TBotSetPistol Bot weapon_pistol
- <code>TBotSetShotgunDist</code> <code>targetbot</code>  <code>shotgundist</code>  
  - TBotSetShotgun Bot weapon_shotgun
- <code>TBotSetRifleDist</code> <code>targetbot</code>  <code>rifledist</code>  
  - TBotSetRifle Bot weapon_smg1
- <code>TBotSetHealThreshold</code> <code>targetbot</code>  <code>healthreshold</code>  
  - TBotSetRifle Bot 100
- <code>TBotSetPlayerModel</code> <code>targetbot</code>  <code>playermodel</code>  
  - TBotSetRifle Bot alyx
- <code>TBotSpawnWithPreferredWeapons</code> <code>targetbot</code>  <code>1 or 0</code>  
  - TBotSpawnWithPreferredWeapons Bot 1
- <code>TBotSetDefault</code> <code>targetbot</code>  
  - TBotSetDefault Bot


# Current Features
- The bot is a player bot
- The bot can use ladders
- The bot has "smooth aiming"
- The bot can open doors
- The bot will use its flashlight when in a dark area
- The bot will attack any NPC that is hostile them and its "owner" (The player that created it)
- The bot, if it has a medkit, will heal itself and any players nearby it, although the bot's owner is prioritized.
- The bot can enter the vehicle the bot's owner is in. This includes most modded vehicles and chairs. See "Issues"
- Support for most custom/modded weapons, see "Issues" for more information. 

# Bot Cheats
I know what you are thinking, but these are needed to make the bot fun and easy to use.
- The bot will slowly regenerate ammo for its weapons when not in combat. This prevents the player from having to "give" the bot ammo or it having to be programed to "find" ammo. (Collect it from dead enemies)     

# Issues
- The bot doesn't know if a Nextbot is hostile or friendly, wont attack nextbots at all!
- The bot doesn't account for recoil on modded weapons.
- The bot will lag the game if it can't find a path to its owner.
- The bot doesn’t know how to drive cars.

# Planned Features
- [x] ~~Get the bot to detect vehicles the bot's owner is in and make the bot enter said vehicle~~
- [ ] Optimize the pathfinding code
- [ ] Get the bot to detect Nextbots
- [x] ~~Add more convars, to make the bot more customizable. :)~~
- [x] ~~Allow players to change the bot's playermodel~~
- [x] ~~Get the bot to detect if its in the dark and turn on and off its flashlight~~
- [x] ~~Get the bot to detect and jump across gaps~~
