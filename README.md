# Important
This is a "player" bot so you will need to set the game to multiplayer and have a open player spot to create one.

This mod is in Beta, there will be bugs, but constant updates with new features and fixes.

Although you can now clone the repository, "I will put updates into a secondary branch before releasing it," I would suggest downloading the latest release, Thank You!

## Why I made this mod
I made this because I usually have to play Gmod alone and I also wanted to see what I could do with the nextbot system.

Special thanks to [Zenlenafelex [PSF]](https://steamcommunity.com/profiles/76561198976669728) for helping me with the pathfinding code for the bot.

# Current Commands
- CommandName, CommandParameters, Example
- "TRizzleCreateBot", "botname" "followdist" "dangerdist" "melee" "pistol" "shotgun" "rifle" "sniper" "meleedist" "pistoldist" "shotgundist" "rifledist" "healthreshold" "combathealthreshold" "playermodel" "spawnwithpreferredweapons", TRizzleCreateBot Bot 200 300 weapon_crowbar weapon_pistol weapon_shotgun weapon_smg1 weapon_crossbow 80 1300 300 900 100 25 alyx 1
- "TBotSetFollowDist", "targetbot" "followdist", TBotSetFollowDist Bot 200
- "TBotSetDangerDist", "targetbot" "dangerdist", TBotSetDangerDist Bot 300
- "TBotSetMelee", "targetbot" "melee", TBotSetMelee Bot weapon_crowbar
- "TBotSetPistol", "targetbot" "pistol", TBotSetPistol Bot weapon_pistol
- "TBotSetShotgun", "targetbot" "shotgun", TBotSetShotgun Bot weapon_shotgun
- "TBotSetRifle", "targetbot" "rifle", TBotSetRifle Bot weapon_smg1
- "TBotSetSniper", "targetbot" "sniper", TBotSetRifle Bot weapon_crossbow
- "TBotSetMeleeDist", "targetbot" "meleedist", TBotSetMelee Bot weapon_crowbar
- "TBotSetPistolDist", "targetbot" "pistoldist", TBotSetPistol Bot weapon_pistol
- "TBotSetShotgunDist", "targetbot" "shotgundist", TBotSetShotgun Bot weapon_shotgun
- "TBotSetRifleDist", "targetbot" "rifledist", TBotSetRifle Bot weapon_smg1
- "TBotSetHealThreshold", "targetbot" "healthreshold", TBotSetRifle Bot 100
- "TBotSetCombatHealThreshold", "targetbot" "combathealthreshold", TBotSetRifle Bot 25
- "TBotSetPlayerModel", "targetbot" "playermodel", TBotSetRifle Bot alyx
- "TBotSpawnWithPreferredWeapons", "targetbot" "1 or 0" TBotSpawnWithPreferredWeapons Bot 1
- "TBotSetDefault", "targetbot", TBotSetDefault Bot


# Current Features
- The bot is a player bot
- The bot can use ladders
- The bot has smooth aiming
- The bot can open doors
- The bot will use its flashlight when in a dark area
- The bot will attack any NPC that is hostile them and its "owner." (The player that created it)
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
