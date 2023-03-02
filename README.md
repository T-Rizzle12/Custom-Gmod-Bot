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
