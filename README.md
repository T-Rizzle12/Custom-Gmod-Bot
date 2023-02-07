# Why I made this mod
I made this because I usually have to play Gmod alone and I also wanted to see what I could do with the nextbot system.

Special thanks to [Zenlenafelex [PSF]](https://steamcommunity.com/profiles/76561198976669728) for helping me with the pathfinding code for the bot.

# Important
This is a player bot so you will need to set the game to multiplayer and have a open player spot to create one.
This mod is also in Beta, there will be bugs, but constant updates with new features.

# Current Cvars
- CvarName, DefaultValue, CvarFlags, CvarDescription
- "TRizzleBot_Melee", "weapon_crowbar", FCVAR_NONE, "This is the melee weapon the bot will use."
- "TRizzleBot_Pistol", "weapon_pistol", FCVAR_NONE, "This is the pistol the bot will use."
- "TRizzleBot_Shotgun", "weapon_shotgun", FCVAR_NONE, "This is the shotgun the bot will use."
- "TRizzleBot_Rifle", "weapon_smg1", FCVAR_NONE, "This is the rifle/smg the bot will use."

# Current Commands
- CommandName, CommandParameters, Example
- "TRizzleCreateBot", botname, "TRizzleCreateBot Bot"

# Current Features
- The bot is a player bot
- The bot can use ladders
- The bot has smooth aiming
- The bot can open doors
- The bot supports most custom/modded weapons
- The bot will use its flashlight when in combat or the player they are following has it on
- The bot will attack any NPC that attacks them and its owner, "the player that created it."
- The bot, if it has a medkit, will heal itself and its owner

# Bot Cheats
I know what you are thinking, but these are needed to make the bot fun and easy to use.
- The bot will regenerate ammo for its weapons when not in combat, the regeneration of said ammo is not instant and will take some time

# Issues
- The bot dosen't know if a Nextbot is hostile or friendly, "they wont attack nextbots at all!"
- The bot doesn't know how to account for recoil on modded weapons
- The bot will lag the game if it can't find a path to its owner
- The bot can see behind it, "thankfully not through walls."
- The bot can open doors halfway across the map
- The bot can not jump across gaps

# Planned Features
- [ ] Get the bot to detect vehicles the bot's owner is in and make the bot enter said vehicle
- [ ] Optimize the pathfinding code
- [ ] Get the bot to detect Nextbots
- [ ] Add more convars, to make the bot more customizable. :)
- [ ] Allow players to change the bot's playermodel
- [ ] Get the bot to detect if its in the dark and turn on and off its flashlight
- [ ] Get the bot to detect and jump across gaps
