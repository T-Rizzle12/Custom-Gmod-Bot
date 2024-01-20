-- TRizzleBot_Base.lua
-- Purpose: This is a base that can be modified to play other gamemodes
-- Author: T-Rizzle

-- Grab the needed metatables
local BOT			=	FindMetaTable( "Player" )
local Ent			=	FindMetaTable( "Entity" )
local Wep			=	FindMetaTable( "Weapon" )
local Npc			=	FindMetaTable( "NPC" )
local Zone			=	FindMetaTable( "CNavArea" )
local Vec			=	FindMetaTable( "Vector" )

-- Setup path types
local PATH_ON_GROUND			=	0
local PATH_DROP_DOWN			=	1
local PATH_CLIMB_UP				=	2
local PATH_JUMP_OVER_GAP		=	3
local PATH_LADDER_UP			=	4
local PATH_LADDER_DOWN			=	5
--local PATH_LADDER_MOUNT			=	6

-- Setup lookatpriority level variables
local LOW_PRIORITY			=	0
local MEDIUM_PRIORITY		=	1
local HIGH_PRIORITY			=	2
local MAXIMUM_PRIORITY		=	3

-- Setup Bot States
local IDLE					=	0
local HIDE					=	1
local FOLLOW_OWNER			=	2
local FOLLOW_GROUP_LEADER	=	3
local USE_ENTITY			=	4
local HOLD_POSITION			=	5
local HEAL_PLAYER			=	6
local REVIVE_PLAYER			=	7

-- Setup lookat states
--local NOT_LOOKING_AT_SPOT	=	0
--local LOOK_TOWARDS_SPOT		=	1
--local LOOK_AT_SPOT			=	2

-- Setup bot hide reasons
local NONE					=	0
local RETREAT				=	1
local RELOAD_IN_COVER		=	2
local SEARCH_AND_DESTORY	=	3

-- Setup bot hiding states
local FINISHED_HIDING		=	0
local MOVE_TO_SPOT			=	1
local WAIT_AT_SPOT			=	2

-- Setup bot think variables
local BotUpdateSkipCount	=	2 -- This is how many upkeep events must be skipped before another update event can be run
local BotUpdateInterval		=	0

-- Setup vectors so they don't have to be created later
local HalfHumanHeight		=	Vector( 0, 0, 35.5 )

-- Setup ladder states
local NO_LADDER						=	0
local APPROACHING_ASCENDING_LADDER	=	1
local APPROACHING_DESCENDING_LADDER	=	2
local ASCENDING_LADDER				=	3
local DESCENDING_LADDER				=	4
local DISMOUNTING_LADDER_TOP		=	5
local DISMOUNTING_LADDER_BOTTOM		=	6

-- Setup net messages
util.AddNetworkString( "TRizzleBotFlashlight" )
util.AddNetworkString( "TRizzleCreateBotMenu" )

-- Setup addon cvars
local TBotSpawnTime = CreateConVar( "TBotSpawnTime", 6.0, FCVAR_NONE, "This is how long a bot must be dead before it can respawn.", 0 )
local TBotLookAheadRange = CreateConVar( "TBotLookAheadRange", 300.0, FCVAR_CHEAT, "This is the minimum range a movement goal must be along the bot's path.", 0 )
local TBotSaccadeSpeed = CreateConVar( "TBotSaccadeSpeed", 1000.0, FCVAR_CHEAT, "This is the maximum speed the bot can turn at.", 0 )
local TBotAimError = CreateConVar( "TBotAimError", 0.01, FCVAR_CHEAT, "This is the maximum aim error the bot can have. This only affects the bot while it is trying to aim at an enemy.", 0 )
local TBotGoalTolerance = CreateConVar( "TBotGoalTolerance", 25.0, FCVAR_CHEAT, "This is how close the bot must be to a goal in order to call it done.", 10 )
local TBotAttackNextBots = CreateConVar( "TBotAttackNextBots", 0.0, FCVAR_NONE, "If nonzero, bots will consider every nextbot to be it's enemy." )
local TBotAttackPlayers = CreateConVar( "TBotAttackPlayers", 0.0, FCVAR_NONE, "If nonzero, bots will consider every player who is not its Owner or have the same Owner as it an enemy." )
local TBotBallisticElevationRate = CreateConVar( "TBotBallisticElevationRate", 0.01, FCVAR_CHEAT, "When lobbing grenades at far away targets, this is the degree/range slope to raise our aim." )
local TBotCheaperClimbing = CreateConVar( "TBotCheaperClimbing", 0.0, FCVAR_CHEAT, "If nonzero, bots will skip the expensive ledge jumping checks, only set this nonzero if you have to as it may cause the bot to get stuck." )
local TBotRandomPaths = CreateConVar( "TBotRandomPaths", 0.0, FCVAR_CHEAT, "If nonzero, the bot will pick random paths when pathfinding to a goal. It is not recommended to use this." )

function TBotCreate( ply , cmd , args ) -- This code defines stats of the bot when it is created.  
	if !args[ 1 ] then error( "[INFORMATION] Please give a name for the bot!" ) end 
	if game.SinglePlayer() or player.GetCount() >= game.MaxPlayers() then error( "[INFORMATION] Cannot create new bot there are no avaliable player slots!" ) end
	
	local NewBot					=	player.CreateNextBot( args[ 1 ] ) -- Create the bot and store it in a varaible.
	
	NewBot.TRizzleBot				=	true -- Flag this as our bot so we don't control other bots, Only ours!
	NewBot.TBotOwner				=	ply -- Make the player who created the bot its "owner"
	
	TBotSetFollowDist( ply, cmd, { args[ 1 ], args[ 2 ] } ) -- This is how close the bot will follow it's owner
	TBotSetDangerDist( ply, cmd, { args[ 1 ], args[ 3 ] } ) -- This is how far the bot can be from it's owner when in combat
	TBotSetMelee( ply, cmd, { args[ 1 ], args[ 4 ] } ) -- This is the melee weapon the bot will use
	TBotSetPistol( ply, cmd, { args[ 1 ], args[ 5 ] } ) -- This is the pistol the bot will use
	TBotSetShotgun( ply, cmd, { args[ 1 ], args[ 6 ] } ) -- This is the shotgun the bot will use
	TBotSetRifle( ply, cmd, { args[ 1 ], args[ 7 ] } ) -- This is the rifle/smg the bot will use
	TBotSetGrenade( ply, cmd,{ args[ 1 ], args[ 8 ] } ) -- This is the grenade the bot will use
	TBotSetSniper( ply, cmd, { args[ 1 ], args[ 9 ], args[ 10 ] } ) -- This is the sniper the bot will use and does the sniper the bot is using have a scope
	TBotSetMeleeDist( ply, cmd, { args[ 1 ], args[ 11 ] } ) -- If an enemy is closer than this, the bot will use its melee
	TBotSetPistolDist( ply, cmd, { args[ 1 ], args[ 12 ] } ) -- If an enemy is closer than this, the bot will use its pistol
	TBotSetShotgunDist( ply, cmd, { args[ 1 ], args[ 13 ] } ) -- If an enemy is closer than this, the bot will use its shotgun
	TBotSetRifleDist( ply, cmd, { args[ 1 ], args[ 14 ] } ) -- If an enemy is closer than this, the bot will use its rifle/smg
	TBotSetHealThreshold( ply, cmd, { args[ 1 ], args[ 15 ] } ) -- If the bot's health or a teammate's health drops below this and the bot is not in combat the bot will use its medkit
	TBotSetCombatHealThreshold( ply, cmd, { args[ 1 ], args[ 16 ] } ) -- If the bot's health drops below this and the bot is in combat the bot will use its medkit
	TBotSetPlayerModel( ply, cmd, { args[ 1 ], args[ 17 ] } ) -- This is the player model the bot will use
	TBotSpawnWithPreferredWeapons( ply, cmd, { args[ 1 ], args[ 18 ] } ) -- This checks if the bot should spawn with its preferred weapons
	
	NewBot:TBotResetAI() -- Fully reset your bots AI.
	
end

function TBotSetFollowDist( ply, cmd, args ) -- Command for changing the bots "Follow" distance to something other than the default.  
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local followdist = tonumber( args[ 2 ] ) or 200
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.FollowDist = followdist
			
		end
		
	end

end

function TBotSetDangerDist( ply, cmd, args ) -- Command for changing the bots "Danger" distance to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local dangerdist = tonumber( args[ 2 ] ) or 300
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.DangerDist = dangerdist
			
		end
		
	end

end

function TBotSetMelee( ply, cmd, args ) -- Command for changing the bots melee to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local melee = args[ 2 ] != "nil" and args[ 2 ] or "weapon_crowbar"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Melee = melee
			
		end
		
	end

end

function TBotSetPistol( ply, cmd, args ) -- Command for changing the bots pistol to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local pistol = args[ 2 ] != "nil" and args[ 2 ] or "weapon_pistol"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Pistol = pistol
			
		end
		
	end

end

function TBotSetShotgun( ply, cmd, args ) -- Command for changing the bots shotgun to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local shotgun = args[ 2 ] != "nil" and args[ 2 ] or "weapon_shotgun"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Shotgun = shotgun
			
		end
		
	end

end

function TBotSetRifle( ply, cmd, args ) -- Command for changing the bots rifle to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] != "nil" and args[ 2 ] or "weapon_smg1"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Rifle = rifle
			
		end
		
	end

end

function TBotSetGrenade( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local grenade = args[ 2 ] != "nil" and args[ 2 ] or "weapon_frag"
	
	for k, bot in ipairs( player.GetAll() ) do
	
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
		
			bot.Grenade = grenade
			
		end
		
	end
	
end

function TBotSetSniper( ply, cmd, args ) -- Command for changing the bots sniper to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] != "nil" and args[ 2 ] or "weapon_crossbow"
	local hasScope = tonumber( args[ 3 ] ) or 1
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Sniper = rifle
			bot.SniperScope = tobool( hasScope )
			
		end
		
	end

end

function TBotSetMeleeDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local meleedist = tonumber( args[ 2 ] ) or 80
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.MeleeDist = meleedist
			
		end
		
	end

end

function TBotSetPistolDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local pistoldist = tonumber( args[ 2 ] ) or 1300
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.PistolDist = pistoldist
			
		end
		
	end

end

function TBotSetShotgunDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local shotgundist = tonumber( args[ 2 ] ) or 300
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.ShotgunDist = shotgundist
			
		end
		
	end

end

function TBotSetRifleDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifledist = tonumber( args[ 2 ] ) or 900
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.RifleDist = rifledist
			
		end
		
	end

end

function TBotSetHealThreshold( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local healthreshold = tonumber( args[ 2 ] ) or 100
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.HealThreshold = math.min( bot:GetMaxHealth(), healthreshold )
			
		end
		
	end

end

function TBotSetCombatHealThreshold( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local combathealthreshold = tonumber( args[ 2 ] ) or 25
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.CombatHealThreshold = math.min( bot:GetMaxHealth(), combathealthreshold )
			
		end
		
	end

end

function TBotSetPlayerModel( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local playermodel = tostring( args[ 2 ] ) or "kleiner"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot:SetModel( player_manager.TranslatePlayerModel( playermodel ) )
			bot.PlayerModel = playermodel
			bot.PlayerSkin = 0
			bot.PlayerBodyGroup = 0
			
		end
		
	end

end

function TBotSetModelSkin( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local skin = tonumber( args[ 2 ] ) or 0
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot:SetSkin( math.Round( skin ) )
			bot.PlayerSkin = math.Round( skin )
			
		end
		
	end
	
end

function TBotSetModelBodyGroup( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local typenum = tonumber( args[ 2 ] ) or 0
	local val = tonumber( args[ 3 ] ) or 0
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			local str = string.Explode( " ", bot:GetInfo( "cl_playerbodygroups" ) )
			if #str < typenum + 1 then for i = 1, typenum + 1 do str[ i ] = str[ i ] or 0 end end
			str[ typenum + 1 ] = math.Round( val )
			bot.PlayerBodyGroup = table.concat( str, " " )
			
			local groups = bot:GetInfo( "cl_playerbodygroups" )
			if groups == nil then groups = "" end
			local groups = string.Explode( " ", groups )
			for key = 0, bot:GetNumBodyGroups() - 1 do
				bot:SetBodygroup( key, tonumber( groups[ key + 1 ] ) or 0 )
			end
			
		end
		
	end
	
end

function TBotSpawnWithPreferredWeapons( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local spawnwithweapons = tonumber( args[ 2 ] ) or 1
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.SpawnWithWeapons = tobool( spawnwithweapons )
			
		end
		
	end

end

function TBotSetDefault( ply, cmd, args )
	if !args[ 1 ] then return end
	if args[ 2 ] then args[ 2 ] = nil end
	if args[ 3 ] then args[ 3 ] = nil end
	
	TBotSetFollowDist( ply, cmd, args )
	TBotSetDangerDist( ply, cmd, args )
	TBotSetMelee( ply, cmd, args )
	TBotSetPistol( ply, cmd, args )
	TBotSetShotgun( ply, cmd, args )
	TBotSetRifle( ply, cmd, args )
	TBotSetGrenade( ply, cmd, args )
	TBotSetSniper( ply, cmd, args )
	TBotSetMeleeDist( ply, cmd, args )
	TBotSetPistolDist( ply, cmd, args )
	TBotSetShotgunDist( ply, cmd, args )
	TBotSetRifleDist( ply, cmd, args )
	TBotSetHealThreshold( ply, cmd, args )
	TBotSetCombatHealThreshold( ply, cmd, args )
	TBotSpawnWithPreferredWeapons( ply, cmd, args )

end

-- This creates a TRizzleBot using the parameters given in the client menu.
net.Receive( "TRizzleCreateBotMenu", function( _, ply ) 

	local args = {}
	table.insert( args, net.ReadString() ) -- Name
	table.insert( args, net.ReadInt( 32 ) ) -- FollowDist
	table.insert( args, net.ReadInt( 32 ) ) -- DangerDist
	table.insert( args, net.ReadString() ) -- Melee
	table.insert( args, net.ReadString() ) -- Pistol
	table.insert( args, net.ReadString() ) -- Shotgun
	table.insert( args, net.ReadString() ) -- Rifle/SMG
	table.insert( args, net.ReadString() ) -- Grenade
	table.insert( args, net.ReadString() ) -- Sniper
	table.insert( args, Either( net.ReadBool(), 1, 0 ) ) -- Sniper has scope
	table.insert( args, net.ReadInt( 32 ) ) -- MeleeDist
	table.insert( args, net.ReadInt( 32 ) ) -- PistolDist
	table.insert( args, net.ReadInt( 32 ) ) -- ShotgunDist
	table.insert( args, net.ReadInt( 32 ) ) -- RifleDist
	table.insert( args, net.ReadInt( 32 ) ) -- HealThreshold
	table.insert( args, net.ReadInt( 32 ) ) -- CombatHealThreshold
	table.insert( args, net.ReadString() ) -- PlayerModel
	table.insert( args, Either( net.ReadBool(), 1, 0 ) ) -- SpawnWithPreferredWeapons
	
	TBotCreate( ply, "TRizzleCreateBot", args )

end)

concommand.Add( "TRizzleCreateBot" , TBotCreate , nil , "Creates a TRizzle Bot with the specified parameters. Example: TRizzleCreateBot <botname> <followdist> <dangerdist> <melee> <pistol> <shotgun> <rifle> <grenade> <sniper> <hasScope> <meleedist> <pistoldist> <shotgundist> <rifledist> <healthreshold> <combathealthreshold> <playermodel> <spawnwithpreferredweapons> Example2: TRizzleCreateBot Bot 200 300 weapon_crowbar weapon_pistol weapon_shotgun weapon_smg1 weapon_frag weapon_crossbow 1 80 1300 300 900 100 25 alyx 1" )
concommand.Add( "TBotSetFollowDist" , TBotSetFollowDist , nil , "Changes the specified bot's how close it should be to its owner. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetDangerDist" , TBotSetDangerDist , nil , "Changes the specified bot's how far the bot can be from its owner while in combat. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetMelee" , TBotSetMelee , nil , "Changes the specified bot's preferred melee weapon. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetPistol" , TBotSetPistol , nil , "Changes the specified bot's preferred pistol. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetShotgun" , TBotSetShotgun , nil , "Changes the specified bot's preferred shotgun. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetRifle" , TBotSetRifle , nil , "Changes the specified bot's preferred rifle/smg. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetGrenade" , TBotSetGrenade , nil , "Changes the specified bot's preferred grenade. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetSniper" , TBotSetSniper , nil , "Changes the specified bot's preferred sniper. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetMeleeDist" , TBotSetMeleeDist , nil , "Changes the distance for when the bot should use it's melee weapon. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetPistolDist" , TBotSetPistolDist , nil , "Changes the distance for when the bot should use it's pistol. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetShotgunDist" , TBotSetShotgunDist , nil , "Changes the distance for when the bot should use it's shotgun. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetRifleDist" , TBotSetRifleDist , nil , "Changes the distance for when the bot should use it's rifle/smg. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetHealThreshold" , TBotSetHealThreshold , nil , "Changes the amount of health the bot must have before it will consider using it's medkit on itself and its owner. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetCombatHealThreshold" , TBotSetCombatHealThreshold , nil , "Changes the amount of health the bot must have before it will consider using it's medkit on itself if it is in combat. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSpawnWithPreferredWeapons" , TBotSpawnWithPreferredWeapons , nil , "Can the bot spawn with its preferred weapons, set to 0 to disable. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetModelSkin" , TBotSetModelSkin , nil , "Changes the bot playermodel's skin to the number specified. If only the bot is specified the skin will revert back to the default." )
concommand.Add( "TBotSetModelBodyGroup" , TBotSetModelBodyGroup , nil , "Changes the bot playermodel's bodygroup to the number's specified. The first number selects the row and the second number sets the value. If only the bot and row is specified the row's value will revert back to the default. Nothing will happen of only the bot is specified." )
concommand.Add( "TBotSetPlayerModel" , TBotSetPlayerModel , nil , "Changes the bot playermodel to the model shortname specified. If only the bot is specified or the model shortname given is invalid the bot's player model will revert back to the default." )
concommand.Add( "TBotSetDefault" , TBotSetDefault , nil , "Set the specified bot's settings back to the default." )

-------------------------------------------------------------------|



function BOT:TBotResetAI()
	
	self.buttonFlags				=	0 -- These are the buttons the bot is going to press.
	self.impulseFlags				=	0 -- This is the impuse command the bot is going to press.
	self.forwardMovement			=	0 -- This tells the bot to move either forward or backwards.
	self.strafeMovement				=	0 -- This tells the bot to move left or right.
	self.GroupLeader				=	nil -- If the bot's owner is dead, this bot will take charge in combat and leads other bots with the same "owner". 
	self.UseEnt						=	nil -- This is the entity this bot is trying to use.
	self.UseHoldTime				=	0 -- This is how long the bot should press its use key on UseEnt.
	self.StartedUse					=	false -- Has the bot started to press its use key on UseEnt.
	self.HoldPos					=	nil -- This is the position the bot will wait at.
	self.EnemyList					=	{} -- This is the list of enemies the bot knows about.
	self.AttackList					=	{} -- This is the list of entities the bot has been told to attack.
	self.AimForHead					=	false -- Should the bot aim for the head?
	self.TimeInCombat				=	0 -- This is how long the bot has been in combat.
	self.LastCombatTime				=	0 -- This is the last time the bot was in combat.
	self.BestWeapon					=	nil -- This is the weapon the bot currently wants to equip.
	self.MinEquipInterval			=	0 -- Throttles how often equipping is allowed.
	self.HealTarget					=	nil -- This is the player the bot is trying to heal.
	self.ReviveTarget				=	nil -- This is the player the bot is trying to revive. -- NOTE: This is only for incapacitation addons
	self.TRizzleBotBlindTime		=	0 -- This is how long the bot should be blind
	self.LastVisionUpdateTimestamp	=	0 -- This is the last time the bot updated its list of known enemies
	self.IsJumping					=	false -- Is the bot currently jumping?
	self.NextJump					=	0 -- This is the next time the bot is allowed to jump.
	self.HoldAttack					=	0 -- This is how long the bot should hold its attack button.
	self.HoldAttack2				=	0 -- This is how long the bot should hold its attack2 button.
	self.HoldReload					=	0 -- This is how long the bot should hold its reload button.
	self.HoldForward				=	0 -- This is how long the bot should hold its forward button.
	self.HoldBack					=	0 -- This is how long the bot should hold its back button.
	self.HoldLeft					=	0 -- This is how long the bot should hold its left button.
	self.HoldRight					=	0 -- This is how long the bot should hold its right button.
	self.HoldRun					=	0 -- This is how long the bot should hold its run button.
	self.HoldWalk					=	0 -- This is how long the bot should hold its walk button.
	self.HoldJump					=	0 -- This is how long the bot should hold its jump button.
	self.HoldCrouch					=	0 -- This is how long the bot should hold its crouch button.
	self.HoldUse					=	0 -- This is how long the bot should hold its use button.
	self.FullReload					=	false -- This tells the bot not to press its attack button until its current weapon is fully reloaded.
	self.FireWeaponInterval			=	0 -- Limits how often the bot presses its attack button.
	self.ReloadInterval				=	0 -- Limits how often the bot can press its reload button.
	self.ScopeInterval				=	0 -- Limits how often the bot can press its scope button.
	self.UseInterval				=	0 -- Limits how often the bot can press its use button.
	self.GrenadeInterval			=	0 -- Limits how often the bot will throw a grenade.
	self.Light						=	false -- Tells the bot if it should have its flashlight on or off.
	--self.LookYawVel					=	0 -- This is the current yaw velocity of the bot.
	--self.LookPitchVel				=	0 -- This is the current pitch velocity of the bot.
	self.AimErrorAngle				=	0 -- This is the current error the bot has while aiming.
	self.AimErrorRadius				=	0 -- This is the radius of the error the bot has while aiming.
	self.AimAdjustTimer				=	0 -- This is the next time the bot will update its aim error.
	self.LookTarget					=	vector_origin -- This is the position the bot is currently trying to look at.
	self.LookTargetSubject			=	nil -- This is the current entity the bot is trying to look at.
	self.LookTargetVelocity			=	0 -- Used to update subject tracking.
	self.LookTargetTrackingTimer	=	0 -- Used to update subject tracking.
	--self.LookTargetState			=	NOT_LOOKING_AT_SPOT -- This is the bot's current look at state.
	self.IsSightedIn				=	false -- Is the bot looking at its current target.
	self.HasBeenSightedIn			=	false -- Has the bot looked at the current target.
	self.AnchorForward				=	vector_origin -- Used to simulate the bot recentering its vitural mouse.
	self.AnchorRepositionTimer		=	nil -- This is used to simulate the bot recentering its vitural mouse.
	self.PriorAngles				=	angle_zero	-- This was the bot's eye angles last UpdateAim.
	self.LookTargetExpire			=	0 -- This is how long the bot will look at the position the bot is currently trying to look at.
	self.LookTargetDuration			=	0 -- This is how long since the bot started looking at the target pos.
	--self.LookTargetTolerance		=	0 -- This is how close the bot must aim at LookTarget before starting LookTargetTimestamp.
	--self.LookTargetTimestamp		=	0 -- This is the timestamp the bot started staring at LookTarget.
	self.LookTargetPriority			=	LOW_PRIORITY -- This is how important the position the bot is currently trying to look at is.
	self.HeadSteadyTimer			=	nil -- This checks if the bot is not rapidly turning to look somehwere else.
	self.CheckedEncounterSpots		=	{} -- This stores every encounter spot and when the spot was checked.
	self.PeripheralTimestamp		=	0 -- This limits how often UpdatePeripheralVision is run.
	self.NextEncounterTime			=	0 -- This is the next time the bot is allowed to look at another encounter spot.
	self.ApproachViewPosition		=	self:GetPos() -- This is the position used to compute approach points.
	self.ApproachPoints				=	{} -- This stores all the approach points leading to the bot.
	self.HidingSpot					=	nil -- This is the current hiding/sniper spot the bot wants to goto.
	self.HidingState				=	FINISHED_HIDING -- This is the current hiding state the bot is currently in.
	self.HideReason					=	NONE -- This is the bot's reason for hiding.
	self.NextHuntTime				=	CurTime() + 10 -- This is the next time the bot will pick a random sniper spot and look for enemies.
	self.HidingSpotInterval			=	0 -- Limits how often the bot can set its selected hiding spot.
	self.HideTime					=	0 -- This is how long the bot will stay at its current hiding spot.
	self.ReturnPos					=	nil -- This is the spot the will back to after hiding, "Example, If the bot went into cover to reload."
	self.Goal						=	nil -- The current path segment the bot is on.
	self.Path						=	{} -- The nodes converted into waypoints by our visiblilty checking.
	self.PathAge					=	0 -- This is how old the current bot's path is.
	self.IsJumpingAcrossGap			=	false -- Is the bot trying to jump over a gap.
	self.IsClimbingUpToLedge		=	false -- Is the bot trying to jump up to a ledge. 
	self.HasLeftTheGround			=	false -- Used by the bot check if it has left the ground while gap jumping and jumping up to a ledge.
	--self.CurrentSegment				=	1 -- This is the current segment the bot is on.
	self.SegmentCount				=	0 -- This is how many nodes the bot's current path has.
	self.LadderState				=	NO_LADDER -- This is the current ladder state of the bot.
	self.LadderInfo					=	nil -- This is the current ladder the bot is trying to use.
	self.LadderDismountGoal			=	nil -- This is the bot's goal once it reaches the end of its selected ladder.
	self.LadderTimer				=	0 -- This helps the bot leave the ladder state if it somehow gets stuck.
	self.MotionVector				=	Vector( 1.0, 0, 0 ) -- This is the bot's current movement as a vector.
	self.RepathTimer				=	CurTime() + 0.5 -- This will limit how often the path gets recreated.
	self.ChaseTimer					=	CurTime() + 0.5 -- This will limit how often the bot repaths while chasing something.
	self.AvoidTimer					=	0 -- Limits how often the bot avoid checks are run.
	self.IsStuck					=	false -- Is the bot stuck.
	self.StuckPos					=	self:GetPos() -- Used when checking if the bot is stuck or not.
	self.StuckTimer					=	CurTime() -- Used when checking if the bot is stuck or not.
	self.StillStuckTimer			=	0 -- Used to check if the bot is stuck.
	self.MoveRequestTimer			=	0 -- Used to check if the bot wants to move.
	--self.WiggleTimer				=	0 -- This helps the bot get unstuck.
	--self.StuckJumpInterval			=	0 -- Limits how often the bot jumps when stuck.
	
	self:TBotSetState( IDLE )
	self:ComputeApproachPoints()
	--self:TBotCreateThinking() -- Start our AI
	
end


hook.Add( "StartCommand" , "TRizzleBotAIHook" , function( bot , cmd )
	if !IsValid( bot ) or !bot:Alive() or !bot:IsTRizzleBot() or navmesh.IsGenerating() then return end
	-- Make sure we can control this bot and its not a player.
	
	cmd:SetButtons( bot.buttonFlags )
	cmd:SetImpulse( bot.impulseFlags )
	cmd:SetForwardMove( bot.forwardMovement )
	cmd:SetSideMove( bot.strafeMovement )
	cmd:SetUpMove( bit.band( bot.buttonFlags, IN_JUMP ) == IN_JUMP and bot:GetRunSpeed() or 0 )
	
	if IsValid( bot.BestWeapon ) and bot.BestWeapon:IsWeapon() and bot:GetActiveWeapon() != bot.BestWeapon then 
	
		cmd:SelectWeapon( bot.BestWeapon )
		
	end
	
end)

function BOT:ResetCommand()

	local buttons			= 0
	local forwardmovement	= 0
	local strafemovement	= 0
	
	if self.HoldAttack > CurTime() then buttons = bit.bor( buttons, IN_ATTACK ) end
	if self.HoldAttack2 > CurTime() then buttons = bit.bor( buttons, IN_ATTACK2 ) end
	if self.HoldReload > CurTime() then buttons = bit.bor( buttons, IN_RELOAD ) end
	if self.HoldForward > CurTime() then 
	
		buttons = bit.bor( buttons, IN_FORWARD )

		forwardmovement = self:GetRunSpeed()
	
	end
	if self.HoldBack > CurTime() then 
	
		buttons = bit.bor( buttons, IN_BACK )
		
		forwardmovement = -self:GetRunSpeed()
		
	end
	if self.HoldLeft > CurTime() then 
	
		buttons = bit.bor( buttons, IN_MOVELEFT )
		
		strafemovement = -self:GetRunSpeed()
		
	end
	if self.HoldRight > CurTime() then 
	
		buttons = bit.bor( buttons, IN_MOVERIGHT ) 
		
		strafemovement = self:GetRunSpeed()
		
	end
	if self.HoldRun > CurTime() then buttons = bit.bor( buttons, IN_SPEED ) end
	if self.HoldWalk > CurTime() then buttons = bit.bor( buttons, IN_WALK ) end
	if self.HoldJump > CurTime() then buttons = bit.bor( buttons, IN_JUMP ) end
	if self.HoldCrouch > CurTime() then buttons = bit.bor( buttons, IN_DUCK ) end
	if self.HoldUse > CurTime() then buttons = bit.bor( buttons, IN_USE ) end
	
	self.buttonFlags		= buttons
	self.forwardMovement	= forwardmovement
	self.strafeMovement		= strafemovement
	self.impulseFlags		= 0

end

function BOT:HandleButtons()

	local CanRun		=	!self:InVehicle()
	local ShouldJump	=	false
	local ShouldCrouch	=	false
	local ShouldRun		=	false
	local ShouldWalk	=	false
	
	local myArea = self:GetLastKnownArea()
	if IsValid( myArea ) then -- If there is no nav_mesh this will not run to prevent the addon from spamming errors
		
		if self:IsOnGround() and myArea:HasAttributes( NAV_MESH_JUMP ) then
			
			ShouldJump		=	true
			
		end
		
		if myArea:HasAttributes( NAV_MESH_CROUCH ) and ( !self.Goal or self.Goal.Type == PATH_ON_GROUND ) then
			
			ShouldCrouch	=	true
			
		end
		
		if myArea:HasAttributes( NAV_MESH_RUN ) then
			
			ShouldRun		=	true
			ShouldWalk		=	false
			
		end
		
		if myArea:HasAttributes( NAV_MESH_WALK ) then
			
			CanRun			=	false
			ShouldWalk		=	true
			
		end
		
		if myArea:HasAttributes( NAV_MESH_STAIRS ) then -- The bot shouldn't jump while on stairs
		
			ShouldJump		=	false
		
		end
		
	end
	
	-- Run if we are too far from our owner or the navmesh tells us to
	if CanRun and self:GetSuitPower() > 20 then 
		
		if ShouldRun then
		
			self:PressRun()
			
		elseif IsValid( self.TBotOwner ) and self.TBotOwner:Alive() and ( !self:IsInCombat() or self:IsUnhealthy() ) and self.TBotOwner:GetPos():DistToSqr( self:GetPos() ) > self.DangerDist * self.DangerDist then
		
			self:PressRun()
		
		elseif IsValid( self.GroupLeader ) and self.GroupLeader:Alive() and ( !self:IsInCombat() or self:IsUnhealthy() ) and self.GroupLeader:GetPos():DistToSqr( self:GetPos() ) > self.DangerDist * self.DangerDist then
		
			self:PressRun()
		
		end
	
	end
	
	-- Walk if the navmesh tells us to
	if ShouldWalk then -- I might make the bot walk if near its owner
		
		self:PressWalk()
	
	end
	
	if ShouldJump and self:IsOnGround() then 
	
		self:PressJump()
		
	elseif ShouldCrouch or ( !self:IsOnGround() and !self:Is_On_Ladder() and self:WaterLevel() < 2 ) then 
	
		self:PressCrouch()
		
	end
	
	--local door = self:GetEyeTrace().Entity
	
	local door = self.Door
	local breakable = self.Breakable
	if IsValid( breakable ) then
	
		if IsValid( self.HealTarget ) or !breakable:IsBreakable() or breakable:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) > 6400 or !self:IsAbleToSee( breakable ) then
		
			self.Breakable = nil
			return
			
		end
		
		self:AimAtPos( breakable:WorldSpaceCenter(), 0.5, MAXIMUM_PRIORITY )
		
		if self:IsLookingAtPosition( breakable:WorldSpaceCenter() ) then
		
			if IsValid( self.BestWeapon ) and self.BestWeapon:IsWeapon() and self.BestWeapon:GetClass() != "weapon_medkit" then
			
				if self.BestWeapon:GetClass() == self.Melee then
				
					local rangeToShoot = self:GetShootPos():DistToSqr( breakable:WorldSpaceCenter() )
					local rangeToStand = self:GetPos():DistToSqr( breakable:WorldSpaceCenter() )
					
					-- If the breakable is on the ground and we are using a melee weapon
					-- we have to crouch in order to hit it
					if rangeToShoot <= 4900 and rangeToShoot > rangeToStand then
					
						self:PressCrouch()
						
					end
					
				end
			
				if CurTime() >= self.FireWeaponInterval and self:GetActiveWeapon() == self.BestWeapon then
				
					self:PressPrimaryAttack()
					self.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )
					
					if !self.BestWeapon:IsPrimaryClipEmpty() then
					
						self.ReloadInterval = CurTime() + 0.5
						
					end
					
				end
				
			else
			
				local bestWeapon		=	nil
				local pistol			=	self:GetWeapon( self.Pistol )
				local rifle				=	self:GetWeapon( self.Rifle )
				local shotgun			=	self:GetWeapon( self.Shotgun )
				local sniper			=	self:GetWeapon( self.Sniper )
				local melee				=	self:GetWeapon( self.Melee )
			
				if IsValid( pistol ) and pistol:HasPrimaryAmmo() then
					
					bestWeapon = pistol
					
				elseif IsValid( sniper ) and sniper:HasPrimaryAmmo() then
			
					bestWeapon = sniper
				
				end
				
				if IsValid( rifle ) and rifle:HasPrimaryAmmo() and !IsValid( bestWeapon ) then
				
					bestWeapon = rifle
					
				end
				
				if IsValid( shotgun ) and shotgun:HasPrimaryAmmo() and !IsValid( bestWeapon ) then
					
					bestWeapon = shotgun
					
				end
				
				if IsValid( melee ) and !IsValid( bestWeapon ) then

					bestWeapon = melee
					
				end
				
				if IsValid( bestWeapon ) then
				
					self.BestWeapon = bestWeapon
					
				end
			
			end
			
		end
	
	elseif IsValid( door ) then 
	
		if !door:IsDoor() or door:IsDoorOpen() or door:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) > 10000 then 
		
			self.Door = nil
			return
			
		end
		
		self:AimAtPos( door:WorldSpaceCenter(), 0.5, MAXIMUM_PRIORITY )
		
		if CurTime() >= self.UseInterval and self:IsLookingAtPosition( door:WorldSpaceCenter() ) then
			
			self:PressUse()
			self.UseInterval = CurTime() + 0.5
			
			if door:IsDoorLocked() then
			
				self.Door = nil
				return
				
			end
			
		end
		
	end
	
end

function BOT:PressPrimaryAttack( holdTime )
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_ATTACK )
	self.HoldAttack = CurTime() + holdTime

end

function BOT:ReleasePrimaryAttack()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_ATTACK ) )
	self.HoldAttack = 0
	
end

function BOT:PressSecondaryAttack( holdTime )
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_ATTACK2 )
	self.HoldAttack2 = CurTime() + holdTime

end

function BOT:ReleaseSecondaryAttack()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_ATTACK2 ) )
	self.HoldAttack2 = 0
	
end

function BOT:PressReload( holdTime )
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_RELOAD )
	self.HoldReload = CurTime() + holdTime

end

function BOT:ReleaseReload()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_RELOAD ) )
	self.HoldReload = 0
	
end

function BOT:PressForward( holdTime )
	holdTime = holdTime or -1.0
	
	self.forwardMovement = self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_FORWARD )
	self.HoldForward = CurTime() + holdTime
	
	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_BACK ) )
	self.HoldBack = 0

end

function BOT:ReleaseForward()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_FORWARD ) )
	self.HoldForward = 0
	
end

function BOT:PressBack( holdTime )
	holdTime = holdTime or -1.0
	
	self.forwardMovement = -self:GetRunSpeed()
	
	self.buttonFlags = bit.bor( self.buttonFlags, IN_BACK )
	self.HoldBack = CurTime() + holdTime
	
	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_FORWARD ) )
	self.HoldForward = 0

end

function BOT:ReleaseBack()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_BACK ) )
	self.HoldBack = 0
	
end

function BOT:PressLeft( holdTime )
	holdTime = holdTime or -1.0
	
	self.strafeMovement = -self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_MOVELEFT )
	self.HoldLeft = CurTime() + holdTime

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_MOVERIGHT ) )
	self.HoldRight = 0

end

function BOT:ReleaseLeft()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_MOVELEFT ) )
	self.HoldLeft = 0
	
end

function BOT:PressRight( holdTime )
	holdTime = holdTime or -1.0
	
	self.strafeMovement = self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_MOVERIGHT )
	self.HoldRight = CurTime() + holdTime
	
	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_MOVELEFT ) )
	self.HoldLeft = 0

end

function BOT:ReleaseRight()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_MOVERIGHT ) )
	self.HoldRight = 0
	
end

function BOT:PressRun( holdTime )
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_SPEED )
	self.HoldRun = CurTime() + holdTime

end

function BOT:ReleaseRun()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_SPEED ) )
	self.HoldRun = 0
	
end

function BOT:PressWalk( holdTime )
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_WALK )
	self.HoldWalk = CurTime() + holdTime

end

function BOT:ReleaseWalk()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_WALK ) )
	self.HoldWalk = 0
	
end

function BOT:PressJump( holdTime )
	holdTime = holdTime or -1.0
	
	self.IsJumping = true
	self.NextJump = CurTime() + 0.5
	
	self.buttonFlags = bit.bor( self.buttonFlags, IN_JUMP )
	self.HoldJump = CurTime() + holdTime
	
end

function BOT:ReleaseJump()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_JUMP ) )
	self.HoldJump = 0
	
end

function BOT:PressCrouch( holdTime )
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_DUCK )
	self.HoldCrouch = CurTime() + holdTime

end

function BOT:ReleaseCrouch()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_DUCK ) )
	self.HoldCrouch = 0
	
end

function BOT:PressUse( holdTime )
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_USE )
	self.HoldUse = CurTime() + holdTime

end

function BOT:ReleaseUse()

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_USE ) )
	self.HoldUse = 0
	
end

net.Receive( "TRizzleBotFlashlight", function( _, ply) 

	local tab = net.ReadTable()
	if !istable( tab ) or table.IsEmpty( tab ) then return end
	
	for bot, light in pairs( tab ) do
		bot.LastLight2 = bot.LastLight2 or 0
	
		light = Vector(math.Round(light.x, 2), math.Round(light.y, 2), math.Round(light.z, 2))
		
		local lighton = light:IsZero() -- Vector( 0, 0, 0 )
		
		if lighton then
		
			bot.LastLight2 = math.Clamp( bot.LastLight2 + 1, 0, 3 )
			
		else
		
			bot.LastLight2 = 0
		
		end
		
		bot.Light = lighton and bot.LastLight2 == 3
		
	end
end)

-- Has the bot recently seen an enemy
function BOT:IsInCombat()
	
	return self.LastCombatTime + 5.0 > CurTime()
	
end

-- Has the bot not seen any enemies recently
function BOT:IsSafe()

	if self:IsInCombat() then
		
		return false
		
	end
	
	return self.LastCombatTime + 15.0 <= CurTime()
	
end

--[[
Got this from CS:GO Source Code, made some changes so it works for Lua

Returns the closest active player on the given team to the given position
This also returns to the distance the returned player is from said position.
]]
function util.GetClosestPlayer( pos, team )

	local closePlayer = nil
	local closeDistSq = 1000000000000
	
	for i = 1, game.MaxPlayers() do
	
		local player = Entity( i )
		
		if !IsValid( player ) then
		
			continue
			
		end
		
		if !player:Alive() then
		
			continue
			
		end
		
		if isnumber( team ) and player:Team() != team then
		
			continue
			
		end
		
		local playerOrigin = player:GetPos()
		local distSq = playerOrigin:DistToSqr( pos )
		if distSq < closeDistSq then
		
			closeDistSq = distSq
			closePlayer = player
			
		end
		
	end
	
	return closePlayer, math.sqrt( closeDistSq )
	
end

-- This can become very expensive in large open navareas
-- there has to be some way to optimize this...
function BOT:UpdatePeripheralVision()

	-- Don't use this for now, it lags the game in certain situations
	if true or self:IsTRizzleBotBlind() then
	
		return
		
	end

	local peripheralUpdateInterval = 0.29
	if CurTime() - self.PeripheralTimestamp < peripheralUpdateInterval then
	
		return
		
	end
	
	--local startTime = SysTime()
	self.PeripheralTimestamp = CurTime()
	
	if IsValid( self:GetLastKnownArea() ) then
	
		local encounterPos = Vector()
		for key1, tbl in ipairs( self:GetLastKnownArea():GetSpotEncounters() ) do
		
			for key2, tbl2 in ipairs( tbl.spots ) do
			
				encounterPos.x = tbl2.pos.x
				encounterPos.y = tbl2.pos.y
				encounterPos.z = tbl2.pos.z + HalfHumanHeight.z
				
				if !self:IsAbleToSee( encounterPos, true ) then
				
					continue
					
				end
				
				self:SetEncounterSpotCheckTimestamp( tbl2.pos )
				
			end
			
		end
		
	end
	--print( "UpdatePeripheralVision RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	
end

-- Determine approach points from eye position and approach areas of current area
function BOT:ComputeApproachPoints()
	
	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	
	-- Compute encounter spots near the bot
	local myArea = self:GetLastKnownArea()
	if IsValid( myArea ) then
	
		self.ApproachPoints = {}
		-- For some reason if there is only once adjacent area no encounter spots will be created
		-- So I grab the single adjacent area instead and use its encounter and approach spots instead
		local spotEncounter = Either( myArea:GetAdjacentCount() == 1, myArea:GetAdjacentAreas()[ 1 ]:GetSpotEncounters(), myArea:GetSpotEncounters() )
		local eye = self:GetShootPos()
		
		local ap = Vector()
		local halfWidth = nil
		
		for k, info in ipairs( spotEncounter ) do
			
			if !IsValid( info.to ) or !IsValid( info.from ) then
				
				continue
				
			end
			
			if info.from_dir <= WEST then
			
				ap, halfWidth = info.from:ComputePortal( info.to, info.from_dir )
				ap.z = info.to:GetZ( ap )
				
			else
				
				ap = info.to:GetCenter()
				
			end
			
			local canSee, approachPoint = self:BendLineOfSight( eye, ap + HalfHumanHeight )
		
			if canSee then
				
				local ground = navmesh.GetGroundHeight( approachPoint )
				if ground then
					
					approachPoint.z = ground
					
				else
					
					approachPoint.z = ap.z
					
				end
				
				table.insert( self.ApproachPoints, { Pos = approachPoint, Area = info.to } )
				
			end
			
		end
	
	end

end

-- This returns a random encounter spot the bot can see
function BOT:ComputeEncounterSpot()
	
	-- Compute encounter spots near the bot
	local myArea = self:GetLastKnownArea()
	if IsValid( myArea ) then
	
		local EncounterSpots = {}
		-- For some reason if there is only once adjacent area no encounter spots will be created
		-- So I grab the single adjacent area instead and use its encounter and approach spots instead
		local spotEncounter = Either( myArea:GetAdjacentCount() == 1, myArea:GetAdjacentAreas()[ 1 ]:GetSpotEncounters(), myArea:GetSpotEncounters() )
		
		if istable( spotEncounter ) then
		
			for key, info in ipairs( spotEncounter ) do
			
				for key2, tbl in ipairs( info.spots ) do
				
					-- If we have seen this spot recently, we don't need to look at it.
					local checkTime = 10.0
					if CurTime() - self:GetEncounterSpotCheckTimestamp( tbl.pos ) <= checkTime then
					
						continue
						
					end
					
					table.insert( EncounterSpots, tbl.pos )
					
				end
				
			end
			
		end
		
		
		while #EncounterSpots > 0 do
		
			local spotIndex = math.random( #EncounterSpots )
			
			local canSee, encounterPos = self:BendLineOfSight( self:GetShootPos(), EncounterSpots[ spotIndex ] )
			
			-- BendLineOfSight allows the bot to adjust the encounter spot so the bot can see it.
			if canSee then
			
				local ground = navmesh.GetGroundHeight( encounterPos )
				if ground then 
				
					encounterPos.z = ground + HalfHumanHeight.z
					
				end
				
				self:SetEncounterSpotCheckTimestamp( EncounterSpots[ spotIndex ] )
				
				return encounterPos
				
			else
			
				table.remove( EncounterSpots, spotIndex )
			
			end
		
		end
	
	end
	
	return self:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward()

end

-- Return time when given spot was last checked
function BOT:GetEncounterSpotCheckTimestamp( spot )

	for k, spotTbl in ipairs( self.CheckedEncounterSpots ) do
	
		if spotTbl.Pos == spot then
		
			return spotTbl.TimeStamp
			
		end
		
	end
	
	return -999999.9
	
end

local MAX_CHECKED_SPOTS = 64
-- Set the timestamp of the given spot to now.
-- If the spot is not in the set, overwrite the least recently checked spot.
function BOT:SetEncounterSpotCheckTimestamp( spot )

	local leastRecent = 0
	local leastRecentTime = CurTime() + 1.0
	
	for k, spotTbl in ipairs( self.CheckedEncounterSpots ) do
	
		-- If the spot is in the set, just update the timestamp.
		if spotTbl.Pos == spot then
		
			spotTbl.TimeStamp = CurTime()
			return
			
		end
		
		-- Keep track of least recent spot
		if spotTbl.TimeStamp < leastRecentTime then
		
			leastRecentTime = spotTbl.TimeStamp
			leastRecent = k
			
		end
		
	end
	
	-- If there is room for more spots, append this one
	if #self.CheckedEncounterSpots < MAX_CHECKED_SPOTS then
	
		table.insert( self.CheckedEncounterSpots, { Pos = spot, TimeStamp = CurTime() } )
		
	else
	
		-- Replace the least recent spot.
		self.CheckedEncounterSpots[ leastRecent ].Pos = spot
		self.CheckedEncounterSpots[ leastRecent ].TimeStamp = CurTime()
	
	end
	
end

-- Deprecated: This system was based off of the CS:GO Bots, who
-- by the way have NO AIM TRACKING, The newer system is 10 times better
--[[function BOT:ComputeAngleLerp( currentAngles, targetAngles )

	local angleDiff = math.AngleDifference( targetAngles.y, currentAngles.y )
	if math.abs( angleDiff ) <= 3 then
	
		self.LookYawVel = 0
		currentAngles.y = LerpAngle( math.Clamp( FrameTime() * math.random(18, 20), 0.0, 1.0 ), currentAngles, targetAngles ).y
		
	else
	
		local accel = 150 * angleDiff - 30 * self.LookYawVel
		
		if accel > 3000 then
			accel = 3000
		elseif accel < -3000 then
			accel = -3000
		end
		
		self.LookYawVel = self.LookYawVel + ( FrameTime() * accel )
		currentAngles.y = currentAngles.y + ( FrameTime() * self.LookYawVel )
		
	end
	
	local angleDiff = math.AngleDifference( targetAngles.x, currentAngles.x )
	if math.abs( angleDiff ) <= 0 then
	
		self.LookPitchVel = 0
		currentAngles.x = targetAngles.x
		
	else
	
		local accel = 2 * 150 * angleDiff - 30 * self.LookPitchVel
		
		if accel > 3000 then
			accel = 3000
		elseif accel < -3000 then
			accel = -3000
		end
		
		self.LookPitchVel = self.LookPitchVel + ( FrameTime() * accel )
		currentAngles.x = currentAngles.x + ( FrameTime() * self.LookPitchVel )
		
	end
	
	if currentAngles.x < -89 then
		currentAngles.x = -89
	elseif currentAngles.x > 89 then
		currentAngles.x = 89
	end
	
	return currentAngles

end]]

-- Returns how often we should sample our target's position and
-- velocity to update our aim tracking, to allow realistic slop in tracking
-- NOTE: This can be used to make bots have better or worse aim tracking
function BOT:GetHeadAimTrackingInterval()
	
	return 0.05 -- For now make the bots act like expert TF2 bots!
	
	-- This is an example of different levels of aim tracking
	-- I could also make this skill dependent....
	--[[if "Expert" then
	
		return 0.05
		
	elseif "Hard" then
	
		return 0.1
	
	elseif "Normal" then
	
		return 0.25
		
	elseif "Easy" then
	
		return 1.0
	
	end]]
	
end

-- NOTE: This can be used to make bots have different aim speeds
function BOT:GetMaxHeadAngularVelocity()

	return TBotSaccadeSpeed:GetFloat()
	
end

-- This where the bot updates its current aim angles
function BOT:UpdateAim()
	if self:IsFrozen() then return end -- If we are frozen don't update our aim!!!!
	
	local deltaT = FrameTime()
	if deltaT < 0.00001 then
	
		return
		
	end
	
	local currentAngles = self:EyeAngles() + self:GetViewPunchAngles()
	
	-- track when our head is "steady"
	local isSteady = true
	
	local actualPitchRate = math.AngleDifference( currentAngles.x, self.PriorAngles.x )
	if math.abs( actualPitchRate ) > 100 * deltaT then
	
		isSteady = false
		
	else
	
		local actualYawRate = math.AngleDifference( currentAngles.y, self.PriorAngles.y )
		if math.abs( actualYawRate ) > 100 * deltaT then
		
			isSteady = false
			
		end
		
	end
	
	if isSteady then
	
		if !self.HeadSteadyTimer then
		
			self.HeadSteadyTimer = CurTime()
			
		end
		
	else
	
		self.HeadSteadyTimer = nil
		
	end
	
	self.PriorAngles = currentAngles
	
	-- if our current look-at has expired, don't change our aim further
	if self.HasBeenSightedIn and self.LookTargetExpire <= CurTime() then
	
		return
		
	end
	
	-- simulate limited range of mouse movements
	-- compute the angle change from center
	local forward = self:EyeAngles():Forward()
	local deltaAngle = math.deg( math.acos( forward:Dot( self.AnchorForward ) ) )
	if deltaAngle > 100 then
	
		self.AnchorRepositionTimer = CurTime() + ( math.Rand( 0.9, 1.1 ) * 0.3 )
		self.AnchorForward = forward
		
	end
	
	if self.AnchorRepositionTimer and self.AnchorRepositionTimer > CurTime() then
	
		return
		
	end
	
	self.AnchorRepositionTimer = nil
	
	local subject = self.LookTargetSubject
	if IsValid( subject ) then
	
		if self.LookTargetTrackingTimer <= CurTime() then
		
			local desiredLookTargetPos = self:SelectTargetPoint( subject )
			local errorVector = desiredLookTargetPos - self.LookTarget
			local Error = errorVector:Length()
			errorVector:Normalize()
			
			local trackingInterval = self:GetHeadAimTrackingInterval()
			if trackingInterval < deltaT then
			
				trackingInterval = deltaT
				
			end
			
			local errorVel = Error / trackingInterval
			
			self.LookTargetVelocity = ( errorVel * errorVector ) + subject:GetVelocity()
			
			self.LookTargetTrackingTimer = CurTime() + ( math.Rand( 0.8, 1.2 ) * trackingInterval )
			
		end
		
		self.LookTarget = self.LookTarget + deltaT * self.LookTargetVelocity
		
	end
	
	local to = self.LookTarget - self:GetShootPos()
	to:Normalize()
	
	local desiredAngles = to:Angle()
	local angles = Angle()
	
	local onTargetTolerance = 0.98
	local dot = forward:Dot( to )
	if dot > onTargetTolerance then
	
		self.IsSightedIn = true
		
		if !self.HasBeenSightedIn then
		
			self.HasBeenSightedIn = true
			
		end
		
	else
	
		self.IsSightedIn = false
		
	end
	
	-- rotate view at a rate proportional to how far we have to turn
	-- max rate if we need to turn around
	-- want first derivative continuity of rate as our aim hits to avoid pop
	local approachRate = self:GetMaxHeadAngularVelocity()
	
	local easeOut = 0.7
	if dot > easeOut then
	
		local t = math.Remap( dot, easeOut, 1.0, 1.0, 0.02 )
		approachRate = approachRate * math.sin( 1.57 * t )
		
	end
	
	local targetDuration = CurTime() - self.LookTargetDuration
	if targetDuration < 0.25 then
	
		approachRate = approachRate * ( targetDuration / 0.25 )
		
	end
	
	--print( approachRate * deltaT )
	angles.y = math.ApproachAngle( currentAngles.y, desiredAngles.y, approachRate * deltaT )
	angles.x = math.ApproachAngle( currentAngles.x, desiredAngles.x, 0.5 * approachRate * deltaT )
	angles.z = 0
	
	-- back out "punch angle"
	angles = angles - self:GetViewPunchAngles()
	
	angles.x = math.NormalizeAngle( angles.x )
	angles.y = math.NormalizeAngle( angles.y )
	
	self:SetEyeAngles( angles )

end

-- Given a subject, return the world space position we should aim at.
-- NOTE: This can be used to make the bot aim differently for certain situations
function BOT:SelectTargetPoint( subject )
	
	local myWeapon = self:GetActiveWeapon()
	if IsValid( myWeapon ) and myWeapon:IsWeapon() then
	
		if myWeapon:GetClass() == self.Grenade or myWeapon:GetClass() == "weapon_frag" or myWeapon:GetClass() == "weapon_handgrenade" then
		
			local toThreat = subject:GetPos() - self:GetPos()
			local threatRange = toThreat:Length()
			toThreat:Normalize()
			local elevationAngle = threatRange * TBotBallisticElevationRate:GetFloat()
			
			if elevationAngle > 45.0 then
			
				-- ballistic range maximum at 45 degrees - aiming higher would decrease the range
				elevationAngle = 45.0
				
			end
			
			local s, c = math.sin( elevationAngle * math.pi / 180 ), math.cos( elevationAngle * math.pi / 180 )
			
			if c > 0.0 then
			
				local elevation = threatRange * s / c
				return subject:WorldSpaceCenter() + Vector( 0, 0, elevation )
				
			end
			
		end
		
	end
	
	if self.AimAdjustTimer <= CurTime() then
	
		self.AimAdjustTimer = CurTime() + math.Rand( 0.5, 1.5 )
		
		self.AimErrorAngle = math.Rand( -math.pi, math.pi )
		self.AimErrorRadius = math.Rand( 0.0, TBotAimError:GetFloat() )
		
	end
	
	local toThreat = subject:GetPos() - self:GetPos()
	local threatRange = toThreat:Length()
	toThreat:Normalize()
	
	local s1 = math.sin( self.AimErrorRadius )
	local Error = threatRange * s1
	local side = toThreat:Cross( vector_up )
	
	local s, c = math.sin( self.AimErrorAngle ), math.cos( self.AimErrorAngle )
	
	if self.AimForHead and !self:IsActiveWeaponRecoilHigh() then
	
		return subject:GetHeadPos() + Error * s * vector_up + Error * c * side
		
	else
	
		return subject:WorldSpaceCenter() + Error * s * vector_up + Error * c * side
		
	end
	
end

-- Rotate body to face towards "target"
function BOT:FaceTowards( target )

	if !isvector( target ) then
	
		return
		
	end
	
	-- TODO: Get the bot to look up and down while swiming
	local look = self:GetShootPos()
	look.x = target.x
	look.y = target.y
	--[[local look = self:GetShootPos()
	local targetHeight = look.z - self:GetPos().z
	local ground = navmesh.GetGroundHeight( target )
	
	look.x = target.x
	look.y = target.y
	
	if ground then
	
		look.z = ground + targetHeight
		
	end]]
	
	self:AimAtPos( look, 0.1, LOW_PRIORITY )
	
end

function BOT:AimAtPos( Pos, Time, Priority )
	
	if !isvector( Pos ) then
	
		return
		
	end
	
	Time = tonumber( Time ) or 0.0
	Priority = tonumber( Priority ) or LOW_PRIORITY
	
	if Time <= 0.0 then
	
		Time = 0.1
		
	end
	
	if self.LookTargetPriority == Priority then
	
		if !self.HeadSteadyTimer or CurTime() - self.HeadSteadyTimer < 0.3 then
		
			return
			
		end
		
	end
	
	if self.LookTargetPriority > Priority and self.LookTargetExpire > CurTime() then
	
		return
		
	end
	
	self.LookTargetExpire = CurTime() + Time
	
	if ( self.LookTarget - Pos ):IsLengthLessThan( 1.0 ) then
	
		self.LookTargetPriority = Priority
		return
		
	end
	
	self.LookTarget				=	Pos
	self.LookTargetSubject		=	nil
	--self.LookTargetState		=	LOOK_TOWARDS_SPOT
	self.LookTargetDuration		=	CurTime()
	self.LookTargetPriority		=	Priority
	self.HasBeenSightedIn		=	false
	--self.LookTargetTolerance	=	angleTolerance
	
end

function BOT:AimAtEntity( Subject, Time, Priority )
	
	if !IsValid( Subject ) then
	
		return
		
	end
	
	Time = tonumber( Time ) or 0.0
	Priority = tonumber( Priority ) or LOW_PRIORITY
	
	if Time <= 0.0 then
	
		Time = 0.1
		
	end
	
	if self.LookTargetPriority == Priority then
	
		if !self.HeadSteadyTimer or CurTime() - self.HeadSteadyTimer < 0.3 then
		
			return
			
		end
		
	end
	
	if self.LookTargetPriority > Priority and self.LookTargetExpire > CurTime() then
	
		return
		
	end
	
	self.LookTargetExpire = CurTime() + Time
	
	if Subject == self.LookTargetSubject then
	
		self.LookTargetPriority = Priority
		return
		
	end
	
	self.LookTargetSubject		=	Subject
	--self.LookTargetState		=	LOOK_TOWARDS_SPOT
	self.LookTargetDuration		=	CurTime()
	self.LookTargetPriority		=	Priority
	self.HasBeenSightedIn		=	false
	--self.LookTargetTolerance	=	angleTolerance
	
end

-- Checks if the bot is currently using the scope of their active weapon
function BOT:IsUsingScope()
	
	return math.Round( self:GetFOV() ) < self:GetDefaultFOV()
	
end

-- Grabs the bot's default FOV
function BOT:GetDefaultFOV()

	return self:GetInternalVariable( "m_iDefaultFOV" )

end

-- Grabs the last time the bot died
function BOT:GetDeathTimestamp()
	
	return -self:GetInternalVariable( "m_flDeathTime" )

end

-- Width of bot's collision hull in XY plane
function BOT:GetHullWidth()

	local bottom, top = self:GetHull()

	return ( top.x * self:GetModelScale() ) - ( bottom.x * self:GetModelScale() )
	
end

-- Height of bot's collision hull based on posture
function BOT:GetHullHeight()

	if self:Crouching() then
	
		return self:GetCrouchHullHeight()
		
	end
	
	return self:GetStandHullHeight()
	
end

-- Height of bot's collision hull when standing
function BOT:GetStandHullHeight()

	local bottom, top = self:GetHull()
	
	return ( top.z * self:GetModelScale() ) - ( bottom.z * self:GetModelScale() )
	
end

-- Height of bot's collision hull when crouched
function BOT:GetCrouchHullHeight()

	local bottom, top = self:GetHullDuck()
	
	return ( top.z * self:GetModelScale() ) - ( bottom.z * self:GetModelScale() )
	
end

-- This checks if the bot is currently unhealthy
function BOT:IsUnhealthy()
	
	return self:Health() <= ( self:GetMaxHealth() * 0.4 )
	
end

-- This is only needed for some gamemodes as said gamemodes may do certain things with bots.
local oldIsBot = oldIsBot or BOT.IsBot
-- This makes the game and other addons think the player being controled is a bot.
--[[function BOT:IsBot()

	if oldIsBot( self ) or self:IsTRizzleBot() then
	
		return true
		
	end
	
	return false
	
end]]

-- This function checks if the player is a TRizzle Bot.
function BOT:IsTRizzleBot( onlyRealBots )
	onlyRealBots = onlyRealBots or false
	
	if onlyRealBots and oldIsBot( self ) and self.TRizzleBot then
	
		return true
		
	end
	
	return !onlyRealBots and self.TRizzleBot
	
end

local oldGetInfo = oldGetInfo or BOT.GetInfo
-- This allows me to set the bot's client convars.
function BOT:GetInfo( cVarName )

	if self:IsTRizzleBot( true ) then
	
		if cVarName == "fov_desired" then
		
			return tostring( "90.00" )
			
		elseif cVarName == "cl_playermodel" then
		
			return tostring( self.PlayerModel )
			
		elseif cVarName == "cl_playerskin" then
		
			return tostring( self.PlayerSkin )
		
		elseif cVarName == "cl_playerbodygroups" then
		
			return tostring( self.PlayerBodyGroup )
		
		elseif cVarName == "cl_tfa_ironsights_toggle" then
		
			return tostring( 1 )
		
		elseif cVarName == "tacrp_toggleaim" then
		
			return tostring( 1 )
		
		end
		
	end
	
	return oldGetInfo( self, cVarName )

end

local oldGetInfoNum = oldGetInfoNum or BOT.GetInfoNum
-- This allows me to set the bot's client convars.
function BOT:GetInfoNum( cVarName, default )

	if self:IsTRizzleBot( true ) then
	
		if cVarName == "fov_desired" then
		
			return tonumber( 90.00 ) or default
			
		elseif cVarName == "cl_playermodel" then
		
			return tonumber( self.PlayerModel ) or default
			
		elseif cVarName == "cl_playerskin" then
		
			return tonumber( self.PlayerSkin ) or default
		
		elseif cVarName == "cl_playerbodygroups" then
		
			return tonumber( self.PlayerBodyGroup ) or default
		
		elseif cVarName == "cl_tfa_ironsights_toggle" then
		
			return tonumber( 1 ) or default
		
		elseif cVarName == "tacrp_toggleaim" then
		
			return tonumber( 1 ) or default
		
		end
		
	end
	
	return oldGetInfoNum( self, cVarName, default )

end

-- Returns true if the player just fired their weapon
function BOT:DidPlayerJustFireWeapon()

	local weapon = self:GetActiveWeapon()
	return IsValid( weapon ) and weapon:IsWeapon() and weapon:GetNextPrimaryFire() > CurTime()
	
end

-- Got this from CS:GO Source Code, made some changes so it works for Lua
function BOT:IsActiveWeaponRecoilHigh()

	local angles = self:GetViewPunchAngles()
	local highRecoil = -1.5
	return angles.x < highRecoil
end

-- Checks if the bot's active weapon's clip is empty
function BOT:IsActiveWeaponClipEmpty()

	local activeWeapon = self:GetActiveWeapon()
	if !IsValid( activeWeapon ) or !activeWeapon:IsWeapon() then return false end
	
	return activeWeapon:IsPrimaryClipEmpty()
	
end

-- Checks if the bot's active weapon is automatic
function BOT:IsActiveWeaponAutomatic()
	
	local activeWeapon = self:GetActiveWeapon()
	if !IsValid( activeWeapon ) or !activeWeapon:IsWeapon() or activeWeapon:GetClass() == self.Grenade then return false end
	
	-- I have to tell the bot manually if a HL2 or HL:S is automatic
	-- since the method I used doesn't work on them
	if !activeWeapon:IsScripted() then
	
		local automaticWeapons = { weapon_crowbar = true, weapon_stunstick = true, weapon_smg1 = true, weapon_ar2 = true, weapon_crowbar_hl1 = true, weapon_mp5_hl1 = true, weapon_hornetgun = true, weapon_egon = true, weapon_gauss = true }
		
		-- I use tobool so this function always returns either true or false
		return tobool( automaticWeapons[ activeWeapon:GetClass() ] )
		
	end
	
	return tobool( activeWeapon.Primary.Automatic )
	
end

function BOT:IsInFieldOfView( pos )

	local fov = math.cos(0.5 * self:GetFOV() * math.pi / 180) -- I grab the bot's current FOV

	if IsValid( pos ) and IsEntity( pos ) then
	
		if self:PointWithinViewAngle( self:GetShootPos(), pos:WorldSpaceCenter(), self:GetAimVector(), fov ) then
		
			return true
			
		end
		
		return self:PointWithinViewAngle( self:GetShootPos(), pos:EyePos(), self:GetAimVector(), fov )
		
	elseif isvector( pos ) then
	
		return self:PointWithinViewAngle( self:GetShootPos(), pos, self:GetAimVector(), fov )
		
	end
	
	return false
	
end

-- For some reason IsAbleToSee doesn't work with player bots
function BOT:PointWithinViewAngle( pos, targetpos, lookdir, fov )
	
	local to = targetpos - pos
	local diff = lookdir:Dot( to )
	
	if diff < 0 then return false end
	
	local length = to:LengthSqr()
	
	return diff * diff > length * fov * fov
end

-- This filter will ignore Players, NPCS, and NextBots
function TBotTraceFilter( ent )
	
	if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end
	
	return true
	
end

-- This filter will ignore Players, NPCS, NextBots, Breakable Props, and Doors
function TBotTraversableFilter( ent )

	if ent:IsBreakable() or ent:IsDoor() then return false end
	
	return TBotTraceFilter( ent )
	
end

function BOT:IsLookingAtPosition( pos, angleTolerance )
	angleTolerance = angleTolerance or 20
	
	local idealAngles = ( pos - self:GetShootPos() ):Angle()
	local viewAngles = self:EyeAngles()
	
	local deltaYaw = math.NormalizeAngle( idealAngles.y - viewAngles.y )
	local deltaPitch = math.NormalizeAngle( idealAngles.x - viewAngles.x )
	
	if math.abs( deltaYaw ) < angleTolerance and math.abs( deltaPitch ) < angleTolerance then
	
		return true
		
	end
	
	return false
	
end

function BOT:IsLineOfFireClear( where )

	if IsValid( where ) and IsEntity( where ) then
	
		local trace = {}
		util.TraceLine( { start = self:GetShootPos(), endpos = where:GetHeadPos(), filter = TBotTraceFilter, mask = MASK_SHOT, output = trace } )
		
		if ( IsValid( trace.Entity ) and trace.Entity:IsBreakable() ) or !trace.Hit then
		
			return true
			
		end
		
		util.TraceLine( { start = self:GetShootPos(), endpos = where:WorldSpaceCenter(), filter = TBotTraceFilter, mask = MASK_SHOT, output = trace } )
		
		if IsValid( trace.Entity ) and trace.Entity:IsBreakable() then
		
			return true
			
		end
		
		return !trace.Hit
	
	elseif isvector( where ) then
	
		local trace = {}
		util.TraceLine( { start = self:GetShootPos(), endpos = where, filter = TBotTraceFilter, mask = MASK_SHOT, output = trace } )
		
		if IsValid( trace.Entity ) and trace.Entity:IsBreakable() then
		
			return true
			
		end
		
		return !trace.Hit
		
	end
	
	return false
	
end

-- Checks if the current position or entity can be seen by the target entity
function Ent:TBotVisible( pos )
	
	if IsValid( pos ) and IsEntity( pos ) then
		
		local trace = {}
		util.TraceLine( { start = self:EyePos(), endpos = pos:WorldSpaceCenter(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
	
		if trace.Fraction >= 1.0 or trace.Entity == pos or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true

		end
		
		util.TraceLine( { start = self:EyePos(), endpos = pos:EyePos(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
	
		if trace.Fraction >= 1.0 or trace.Entity == pos or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true
			
		end
		
	elseif isvector( pos ) then
		
		local trace = {}
		util.TraceLine( { start = self:EyePos(), endpos = pos, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
		
		return trace.Fraction >= 1.0
		
	end
	
	return false
	
end

function util.VecToYaw( vec )

	if vec.y == 0 and vec.x == 0 then
	
		return 0
		
	end
	
	local yaw = math.atan2( vec.y, vec.x )
	
	yaw = math.deg( yaw )
	
	if yaw < 0 then yaw = yaw + 360 end
	
	return yaw
	
end

function BOT:BendLineOfSight( eye, target, angleLimit )

	angleLimit = angleLimit or 135
	
	local result = {}
	util.TraceLine( { start = eye, endpos = target, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = result } )
	if result.Fraction == 1.0 and !result.StartSolid then
	
		return true, target
		
	end
	
	local to = target - eye
	local startAngle = util.VecToYaw( to )
	local length = to:Length2D()
	to:Normalize()
	
	local priorVisibleLength = { 0.0, 0.0 }
	
	local angleInc = 5.0
	local angle = angleInc
	
	while angle <= angleLimit do
	
		for side = 1, 2 do
		
			local actualAngle = Either( side == 2, startAngle + angle, startAngle - angle )
			
			local dx = math.cos( 3.141592 * actualAngle / 180 )
			local dy = math.sin( 3.141592 * actualAngle / 180 )
			
			local rotPoint = Vector( eye.x + length * dx, eye.y + length * dy, target.z )
			
			util.TraceLine( { start = eye, endpos = rotPoint, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = result } )
			
			if result.StartSolid then
			
				continue
				
			end
			
			local ray = rotPoint - eye
			local rayLength = ray:Length()
			ray:Normalize()
			local visibleLength = rayLength * result.Fraction
			
			local bendStepSize = 50
			
			local startLength = priorVisibleLength[ side ]
			local bendLength = startLength
			
			while bendLength <= visibleLength do
			
				local bendPoint = eye + bendLength * ray
				
				util.TraceLine( { start = bendPoint, endpos = target, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = result } )
				
				if result.Fraction == 1.0 and !result.StartSolid then
				
					bendPoint.z = eye.z + bendLength * to.z
					
					return true, bendPoint
					
				end
				
				bendLength = bendLength + bendStepSize
				
			end
			
			priorVisibleLength[ side ] = visibleLength
			
		end
		
		angle = angle + angleInc
		
	end
	
	return false
	
end

function BOT:UpdateVision()
	if ( ( engine.TickCount() + self:EntIndex() ) % 5 ) != 0 then return end -- This shouldn't run as often

	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() then
	
		self.EnemyList = {}
		return
		
	end

	self:UpdateKnownEntities()
	self.LastVisionUpdateTimestamp = CurTime()
	
end

-- Called when the bot sees another entity
-- NOTE: Can be used to make the bot react upon seeing an enemy
-- NOTE2: This is only called after the bot's reaction time has finished
function BOT:OnSight()

	-- We do nothing here in sandbox
	return
	
end

-- Called when the bot looses sight of another entity
-- NOTE: Can be used to make the bot react losing sight of an enemy
function BOT:OnLostSight()

	-- We do nothing here in sandbox
	return
	
end

-- This checks if the entered position in the bot's LOS
function BOT:IsAbleToSee( pos, checkFOV )
	if self:IsTRizzleBotBlind() then return false end

	if IsValid( pos ) and IsEntity( pos ) then
		-- we must check eyepos and worldspacecenter
		-- maybe in the future I can use body parts instead
		-- NOTE: Valve TF2 Bots seem to only use eyepos and worldspacecenter
		
		-- TODO: I should make the bot use IsPotentiallyVisible as this could save a lot of resources
		-- NOTE: I need a way to check the maximum computed distance to prevent false negatives
		--[[ Example:
		local myArea = self:GetLastKnownArea()
		local subjectArea = pos:GetLastKnownArea()
		if IsValid( myArea ) and IsValid( subjectArea ) then
			
			if myArea:IsPotentiallyVisible( subjectArea ) then
				
				return false
				
			end
			
		end]]
		
		if ( pos:GetPos() - self:GetPos() ):IsLengthGreaterThan( 6000 ) then
		
			return false
			
		end
		
		if self:IsHiddenByFog( self:GetShootPos():Distance( pos:WorldSpaceCenter() ) ) then
		
			return false
			
		end
		
		if checkFOV and !self:IsInFieldOfView( pos ) then
			
			return false
			
		end
		
		if !self:TBotVisible( pos ) then
		
			return false
			
		end
		
		return self:IsVisibleEntityNoticed( pos )

	elseif isvector( pos ) then
		
		if ( pos - self:GetPos() ):IsLengthGreaterThan( 6000 ) then
		
			return false
			
		end
		
		if self:IsHiddenByFog( self:GetShootPos():Distance( pos ) ) then
		
			return false
			
		end
		
		if checkFOV and !self:IsInFieldOfView( pos ) then
		
			return false
			
		end
		
		return self:TBotVisible( pos )
		
	end
	
	return false
end

local oldScreenFade = oldScreenFade or BOT.ScreenFade
-- Basic flashbang support!!!
function BOT:ScreenFade( flags, clr, fadeTime, fadeHold )

	if self:IsTRizzleBot() then

		self:TBotBlind( fadeHold )
		
	end
	
	oldScreenFade( self, flags, clr, fadeTime, fadeHold )
	
end

-- Blinds the bot for a specified amount of time
function BOT:TBotBlind( time )
	if !self:Alive() or !self:IsTRizzleBot() or time < ( self.TRizzleBotBlindTime - CurTime() ) then return end
	
	self.TRizzleBotBlindTime = CurTime() + time
	self:AimAtPos( self:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward(), 0.1, MAXIMUM_PRIORITY ) -- Make the bot fling its aim in a random direction upon becoming blind
end

-- Is the bot currently blind?
function BOT:IsTRizzleBotBlind()
	if !self:Alive() or !self:IsTRizzleBot() then return false end
	
	return self.TRizzleBotBlindTime > CurTime()
end

-- Is the bot the current group leader?
function BOT:IsGroupLeader()

	return self == self.GroupLeader

end

-- Got this from CS:GO Source Code, made some changes so it works for Lua
-- Checks if the bot can see the set range without the fog obscuring it
function BOT:IsHiddenByFog( range )

	if self:GetFogObscuredRatio( range ) >= 1.0 then
		return true
	end

	return false
end

-- Got this from CS:GO Source Code, made some changes so it works for Lua
-- This returns a number based on how obscured a position is, 0.0 not obscured and 1.0 completely obscured
function BOT:GetFogObscuredRatio( range )

	local fog = self:GetFogParams()
	
	if !IsValid( fog ) then 
		return 0.0
	end
	
	local enable = fog:GetInternalVariable( "m_fog.enable" )
	local startDist = fog:GetInternalVariable( "m_fog.start" )
	local endDist = fog:GetInternalVariable( "m_fog.end" )
	local maxdensity = fog:GetInternalVariable( "m_fog.maxdensity" )

	if !enable then
		return 0.0
	end

	if range <= startDist then
		return 0.0
	end

	if range >= endDist then
		return 1.0
	end

	local ratio = (range - startDist) / (endDist - startDist)
	ratio = math.min( ratio, maxdensity )
	return ratio
end

-- Finds and returns the master fog controller
function GetMasterFogController()
	
	for k, fogController in ipairs( ents.FindByClass( "env_fog_controller" ) ) do
		
		if IsValid( fogController ) then return fogController end
		
	end
	
	return nil
	
end

-- Finds the fog entity that is currently affecting a bot
function BOT:GetFogParams()

	local targetFog = nil
	local trigger = self:GetFogTrigger()
	
	if IsValid( trigger ) then
		
		targetFog = trigger
	end
	
	if !IsValid( targetFog ) and IsValid( GetMasterFogController() ) then
	
		targetFog = GetMasterFogController()
	end

	if IsValid( targetFog ) then
	
		return targetFog
	
	else
		
		return nil
		
	end

end

-- Got this from CS:GO Source Code, made some changes so it works for Lua
-- Tracks the last trigger_fog touched by this bot
function BOT:GetFogTrigger()

	local bestDist = 1000000000000
	local bestTrigger = nil

	for k, fogTrigger in ipairs( ents.FindByClass( "trigger_fog" ) ) do
	
		if IsValid( fogTrigger ) then
		
			local dist = self:GetPos():DistToSqr( fogTrigger:GetPos() )
			if dist < bestDist then
				bestDist = dist
				bestTrigger = fogTrigger
			end
		end
	end
	
	return bestTrigger
end

-- This will check if the bot's cursor is close the enemy the bot is fighting
function BOT:PointWithinCursor( target, targetpos )
	
	local pos = targetpos - self:GetShootPos()
	local diff = self:GetAimVector():Dot( pos:GetNormalized() )
	if diff < 0 then return false end
	
	-- Should I adjust EntWidth to be larger?
	local EntWidth = target:BoundingRadius() * 0.5
	local length = pos:Length()
	local fov = math.cos( math.atan( EntWidth / length ) )
	if diff <= fov then return false end
	
	-- This checks makes sure the bot won't attempt to shoot if the bullet will possibly hit a player
	-- This will not activate if the bot's current enemy is a player and the trace hits them
	local ply = self:GetEyeTrace().Entity
	if IsValid( ply ) and ply:IsPlayer() and ply != target then return false end
	
	-- This check makes sure the bot won't attempt to shoot if the bullet won't hit its target
	local trace = {}
	util.TraceLine( { start = self:GetShootPos(), endpos = targetpos, filter = self, mask = MASK_SHOT, output = trace } )
	local traceEntity = trace.Entity
	
	if IsValid( traceEntity ) then
	
		if traceEntity == target then
		
			return true
		
		elseif self:IsEnemy( traceEntity ) then
		
			return true
			
		elseif traceEntity:IsBreakable() then
		
			return true
			
		end
		
	end
	
	return trace.Fraction >= 1.0

end

function BOT:IsCursorOnTarget( target )

	if IsValid( target ) then
		
		-- Don't try to shoot through walls
		if !self:IsLineOfFireClear( target:GetHeadPos() ) then
		
			if !self:IsLineOfFireClear( target:WorldSpaceCenter() ) then
			
				return false
				
			end
			
		end
		
		-- This checks makes sure the bot won't attempt to shoot if the bullet will possibly hit a player
		-- This will not activate if the bot's current enemy is a player and the trace hits them
		local ply = self:GetEyeTrace().Entity
		if IsValid( ply ) and ply:IsPlayer() and ply != target then return false end
		
		return self.IsSightedIn and self.LookTargetSubject == target
		
		--return self:PointWithinCursor( target, self:SelectTargetPoint( target ) )
	
	end
	
	return false
end

-- This will select the best weapon based on the bot's current distance from its enemy
function BOT:SelectBestWeapon( target, enemydistsqr )
	if ( self.MinEquipInterval > CurTime() and !self:IsActiveWeaponClipEmpty() ) or ( !isnumber( enemydistsqr ) and !IsValid( target ) ) then return end
	
	enemydistsqr			=	enemydistsqr or target:GetPos():DistToSqr( self:GetPos() ) -- Only compute this once, there is no point in recomputing it multiple times as doing so is a waste of computer resources
	local oldBestWeapon 	= 	self.BestWeapon
	local minEquipInterval	=	0
	local bestWeapon		=	nil
	local pistol			=	self:GetWeapon( self.Pistol )
	local rifle				=	self:GetWeapon( self.Rifle )
	local shotgun			=	self:GetWeapon( self.Shotgun )
	local sniper			=	self:GetWeapon( self.Sniper )
	local grenade			=	self:GetWeapon( self.Grenade )
	local melee				=	self:GetWeapon( self.Melee )
	local medkit			=	self:GetWeapon( "weapon_medkit" )
	
	if IsValid( medkit ) and self.CombatHealThreshold > self:Health() and medkit:Clip1() >= 25 then
		
		-- The bot will heal themself if they get too injured during combat
		self.BestWeapon = medkit
	
	else
		-- I use multiple if statements instead of elseifs
		-- If an enemy is very far away, the bot should use its sniper
		if IsValid( sniper ) and sniper:HasPrimaryAmmo() then
			
			bestWeapon = sniper
			minEquipInterval = 5.0
			
		end
		
		-- If an enemy is far the bot, the bot should use its pistol
		if IsValid( pistol ) and pistol:HasPrimaryAmmo() and ( enemydistsqr < self.PistolDist * self.PistolDist or !IsValid( bestWeapon ) ) then
			
			bestWeapon = pistol
			minEquipInterval = 5.0
			
		end
		
		-- If an enemy gets too far but is still close, the bot should use its rifle
		if IsValid( rifle ) and rifle:HasPrimaryAmmo() and ( enemydistsqr < self.RifleDist * self.RifleDist or !IsValid( bestWeapon ) ) then
		
			bestWeapon = rifle
			minEquipInterval = 5.0
			
		end
		
		-- If an enemy gets close, the bot should use its shotgun
		if IsValid( shotgun ) and shotgun:HasPrimaryAmmo() and ( enemydistsqr < self.ShotgunDist * self.ShotgunDist or !IsValid( bestWeapon ) ) then
			
			bestWeapon = shotgun
			minEquipInterval = 5.0
			
		end
		
		if IsValid( grenade ) and self.GrenadeInterval <= CurTime() and enemydistsqr > 40000 and self:GetKnownCount( nil, true, -1 ) >= 5 then
		
			bestWeapon = grenade
			minEquipInterval = 5.0
			
		end
		
		-- If an enemy gets too close, the bot should use its melee
		if IsValid( melee ) and ( ( enemydistsqr < self.MeleeDist * self.MeleeDist and self:GetKnownCount( nil, true, -1 ) < 5 ) or !IsValid( bestWeapon ) ) then

			bestWeapon = melee
			minEquipInterval = 2.0
			
		end
		
		if IsValid( bestWeapon ) and oldBestWeapon != bestWeapon then 
			
			self.BestWeapon			= bestWeapon
			self.MinEquipInterval 	= CurTime() + minEquipInterval
			
			-- The bot should wait before throwing a grenade since some have a pull out animation
			if bestWeapon == grenade then
			
				self.FireWeaponInterval = CurTime() + 1.5
				
			end
			
		end
		
	end
	
end

-- This checks if the given weapon uses clips for its primary attack
function Wep:UsesClipsForAmmo1()

	return self:GetMaxClip1() > 0

end

-- This checks if the given weapon uses clips for its secondary attack
function Wep:UsesClipsForAmmo2()

	return self:GetMaxClip2() > 0

end

-- This checks if the weapon actually uses primary ammo
function Wep:UsesPrimaryAmmo()

	if self:GetPrimaryAmmoType() <= 0 then
	
		return false
		
	end
	
	return true

end

-- This checks if the weapon actually uses secondary ammo
function Wep:UsesSecondaryAmmo()

	if self:GetSecondaryAmmoType() <= 0 then
	
		return false
		
	end
	
	return true

end

-- This checks if the given weapon has any ammo for its primary attack
function Wep:HasPrimaryAmmo()

	if !self:UsesPrimaryAmmo() then
	
		return true
		
	end

	if self:UsesClipsForAmmo1() then
	
		if self:Clip1() > 0 then
		
			return true 
			
		end
		
	end
	
	if self:GetOwner():GetAmmoCount( self:GetPrimaryAmmoType() ) > 0 then
	
		return true
		
	end
	
	return false

end

-- This checks if the given weapon has any ammo for its secondary attack
function Wep:HasSecondaryAmmo()

	if !self:UsesSecondaryAmmo() then
	
		return true
		
	end

	if self:UsesClipsForAmmo2() then
	
		if self:Clip2() > 0 then
		
			return true 
			
		end
		
	end
	
	if self:GetOwner():GetAmmoCount( self:GetSecondaryAmmoType() ) > 0 then
	
		return true
		
	end
	
	return false

end

-- Checks if the weapon's primary clip is empty
function Wep:IsPrimaryClipEmpty()

	if !self:UsesClipsForAmmo1() then
	
		return false
		
	end
	
	return self:Clip1() <= 0
	
end

-- Checks if the weapon's secondary clip is empty
function Wep:IsSecondaryClipEmpty()

	if !self:UsesClipsForAmmo2() then
	
		return false
		
	end
	
	return self:Clip2() <= 0
	
end

-- Checks if this weapon needs to reload
function Wep:NeedsToReload()

	if !self:UsesClipsForAmmo1() then
	
		return false
		
	end
	
	if self:GetOwner():GetAmmoCount( self:GetPrimaryAmmoType() ) <= self:Clip1() then
	
		return false
		
	end
	
	return self:Clip1() < self:GetMaxClip1()
	
end

-- Checks if the bot is currently reloading
function BOT:IsReloading()

	local botWeapon = self:GetActiveWeapon()
	
	if IsValid( botWeapon ) and botWeapon:IsWeapon() then
	
		return botWeapon:GetInternalVariable( "m_bInReload" )
		
	end
	
	return false

end

-- The bot should reload weapons that need to be reloaded
function BOT:ReloadWeapons()
	
	local botWeapon = self:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:GetClass() != self.Melee and botWeapon:GetClass() != "weapon_medkit" and botWeapon:NeedsToReload() then return end
	
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle			=	self:GetWeapon( self.Rifle )
	local shotgun		=	self:GetWeapon( self.Shotgun )
	local sniper		=	self:GetWeapon( self.Sniper )
	
	if IsValid( sniper ) and sniper:NeedsToReload() then
		
		self.BestWeapon = sniper
		
	elseif IsValid( pistol ) and pistol:NeedsToReload() then
		
		self.BestWeapon = pistol
		
	elseif IsValid( rifle ) and rifle:NeedsToReload() then
		
		self.BestWeapon = rifle
		
	elseif IsValid( shotgun ) and shotgun:NeedsToReload() then
		
		self.BestWeapon = shotgun
		
	end
	
end

-- This is kind of a cheat, but the bot will only slowly recover ammo when not in combat
function BOT:RestoreAmmo()
	
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle			=	self:GetWeapon( self.Rifle )
	local shotgun		=	self:GetWeapon( self.Shotgun )
	local sniper		=	self:GetWeapon( self.Sniper )
	local grenade		=	self:GetWeapon( self.Grenade )
	local pistol_ammo
	local rifle_ammo
	local shotgun_ammo
	local sniper_ammo
	local grenade_ammo
	
	if IsValid( pistol ) then pistol_ammo		=	self:GetAmmoCount( pistol:GetPrimaryAmmoType() ) end
	if IsValid( rifle ) then rifle_ammo		=	self:GetAmmoCount( rifle:GetPrimaryAmmoType() ) end
	if IsValid( shotgun ) then shotgun_ammo		=	self:GetAmmoCount( shotgun:GetPrimaryAmmoType() ) end
	if IsValid( sniper ) then sniper_ammo		=	self:GetAmmoCount( sniper:GetPrimaryAmmoType() ) end
	if IsValid( grenade ) then grenade_ammo		=	self:GetAmmoCount( grenade:GetPrimaryAmmoType() ) end
	
	if isnumber( pistol_ammo ) and pistol:UsesPrimaryAmmo() and ( pistol:UsesClipsForAmmo1() and pistol_ammo < ( pistol:GetMaxClip1() * 6 ) or !pistol:UsesClipsForAmmo1() and pistol_ammo < 6 ) then
		
		self:GiveAmmo( 1, pistol:GetPrimaryAmmoType(), true )
		
	end
	
	if isnumber( rifle_ammo ) and rifle:UsesPrimaryAmmo() and ( rifle:UsesClipsForAmmo1() and rifle_ammo < ( rifle:GetMaxClip1() * 6 ) or !rifle:UsesClipsForAmmo1() and rifle_ammo < 6 ) then
		
		self:GiveAmmo( 1, rifle:GetPrimaryAmmoType(), true )
		
	end
	
	if isnumber( shotgun_ammo ) and shotgun:UsesPrimaryAmmo() and ( shotgun:UsesClipsForAmmo1() and shotgun_ammo < ( shotgun:GetMaxClip1() * 6 ) or !shotgun:UsesClipsForAmmo1() and shotgun_ammo < 6 ) then
		
		self:GiveAmmo( 1, shotgun:GetPrimaryAmmoType(), true )
		
	end
	
	if isnumber( sniper_ammo ) and sniper:UsesPrimaryAmmo() and ( sniper:UsesClipsForAmmo1() and sniper_ammo < ( sniper:GetMaxClip1() * 6 ) or !sniper:UsesClipsForAmmo1() and sniper_ammo < 6 ) then
		
		self:GiveAmmo( 1, sniper:GetPrimaryAmmoType(), true )
		
	end
	
	-- The bot wont regenerate ammo for their grenade unless they feel safe.
	if isnumber( grenade_ammo ) and self:IsSafe() and grenade:UsesPrimaryAmmo() and grenade_ammo < 6 then
	
		self:GiveAmmo( 1, grenade:GetPrimaryAmmoType(), true )
		
	end
	
end

-- Returns the position of the entity's head.
function Ent:GetHeadPos()

	local boneIndex = self:LookupBone("ValveBiped.Bip01_Head1")
	local headPos = self:GetPos()
	
	-- We attempt to grab the head of the Entity, this is the most reliable method to do so
	if isnumber( boneIndex ) then
	
		headPos = self:GetBoneMatrix( boneIndex ):GetTranslation()
		
	end
	
	-- If the model doesn't use the ValveBiped Bones, I can use OBB to find the head
	if headPos == self:GetPos() then
	
		headPos.z = headPos.z + self:OBBMaxs().z -- EyePos is unreliable on some Entity's and doesn't even return the actual head for said Entity's
	
		if headPos.z >= self:EyePos().z then -- EyePos may be reliable for this Entity
			
			headPos = self:EyePos()
	
		end
		
	end
	
	return headPos
	
end

function Ent:IsBreakable()
	if self:Health() < 1 then return false end

	local DAMAGE_YES = 2
	local BreakableList = { func_breakable = true, func_breakable_surf = true, func_physbox = true, prop_physics = true, prop_physics_multiplayer = true, func_pushable = true, prop_dynamic = true }

	if self:GetInternalVariable( "m_takedamage" ) == DAMAGE_YES then
		
		-- I use tobool so this function always returns either true or false
		return tobool( BreakableList[ self:GetClass() ] )
		
	end
	
	return false

end

function Ent:IsDoor()

	if (self:GetClass() == "func_door") or (self:GetClass() == "prop_door_rotating") or (self:GetClass() == "func_door_rotating") then
        
		return true
    
	end
	
	return false
	
end

function Ent:IsDoorLocked()
	if !self:IsDoor() then return false end
	
	return self:GetInternalVariable( "m_bLocked" )
	
end

function Ent:IsDoorOpen()

	if self:GetClass() == "func_door" or self:GetClass() == "func_door_rotating" then
        
		return self:GetInternalVariable( "m_toggle_state" ) == 0
    
	elseif self:GetClass() == "prop_door_rotating" then
	
		return self:GetInternalVariable( "m_eDoorState" ) != 0
	
	end
	
	return false
	
end

function BOT:FindGroupLeader()

	local CurrentLeader = self.GroupLeader
	if !IsValid( CurrentLeader ) or !CurrentLeader:Alive() then CurrentLeader = nil end -- Our current group leader is dead or invalid we should select another one.
	for k, bot in ipairs( player.GetAll() ) do
	
		if IsValid( bot ) and bot:Alive() and bot:IsTRizzleBot() and self != bot and self.TBotOwner == bot.TBotOwner and IsValid( bot.GroupLeader ) and bot.GroupLeader:Alive() then
		
			CurrentLeader = bot.GroupLeader
			break
		
		end
		
	end

	return CurrentLeader
	
end

-- This changes the bots active state to the one entered
function BOT:TBotSetState( newState )
	newState = math.Clamp( tonumber( newState ) or IDLE, IDLE, REVIVE_PLAYER ) -- This is a failsafe!

	self.TBotState = newState
	
end

-- This returns the current state of the bot
function BOT:GetTBotState()

	return self.TBotState
	
end

function BOT:TBotSetHidingSpot( spot, reason, time )
	reason = reason or RETREAT
	time = time or 10.0

	if isvector( spot ) then
	
		self.HidingSpot = spot
		self.HidingState = MOVE_TO_SPOT
		self.HideReason	= reason
		
		if reason == RELOAD_IN_COVER then 
		
			if isvector( time ) then
			
				self.ReturnPos = time
				
			else
			
				self.ReturnPos = self:GetPos()
				
			end
		
		else
		
			self.HideTime	= time 
			
		end
	
	end

end

-- Returns true if the bot is trying to hide
function BOT:IsHiding()

	if !isvector( self.HidingSpot ) or self.HideReason == NONE then
	
		return false
		
	end

	return self.HidingState != FINISHED_HIDING
	
end

-- Returns true if the bot is hiding and at its hiding spot.
function BOT:IsAtHidingSpot()

	if !self:IsHiding() then
	
		return false
		
	end
	
	return self.HidingState == WAIT_AT_SPOT

end

function BOT:IsNotMoving( minDuration )

	if !self.StillTimer then
	
		return false
		
	end

	return CurTime() - self.StillTimer >= minDuration
	
end

-- If and entity gets removed, clear it from the bot's attack list.
hook.Add( "EntityRemoved" , "TRizzleBotEntityRemoved" , function( ent, fullUpdate ) 

	for i = 1, game.MaxPlayers() do
	
		local bot = Entity( i )
	
		if IsValid( bot ) and bot:IsTRizzleBot() then
		
			bot.AttackList[ ent ] = nil
			
		end
		
	end

end)

-- When an NPC dies, it should be removed from the bot's known entity list.
-- This is also called for some nextbots.
hook.Add( "OnNPCKilled" , "TRizzleBotOnNPCKilled" , function( npc )

	for i = 1, game.MaxPlayers() do
	
		local bot = Entity( i )
	
		if IsValid( bot ) and bot:IsTRizzleBot() then
		
			bot:ForgetEntity( npc )
			bot.AttackList[ npc ] = nil
			
		end
		
	end

end)

-- When the bot dies, it seems to keep its weapons for some reason. This hook removes them when the bot dies.
-- This hook also checks if a player dies and removes said player from every bots known enemy list.
hook.Add( "PostPlayerDeath" , "TRizzleBotPostPlayerDeath" , function( ply )

	for i = 1, game.MaxPlayers() do
	
		local bot = Entity( i )
	
		if IsValid( bot ) and bot:IsTRizzleBot() then
		
			bot:ForgetEntity( ply )
			bot.AttackList[ ply ] = nil
			
		end
		
	end

	if IsValid( ply ) and ply:IsTRizzleBot() then
	
		ply:StripWeapons()
		
	end

end)

-- When a player leaves the server, every bot "owned" by the player should leave as well
hook.Add( "PlayerDisconnected" , "TRizzleBotPlayerLeave" , function( ply )
	
	if !ply:IsTRizzleBot( true ) then 
		
		for k, bot in ipairs( player.GetAll() ) do
		
			if IsValid( bot ) and bot:IsTRizzleBot() then 
			
				bot.AttackList[ ply ] = nil
				
				if bot.TBotOwner == ply then
			
					if bot:IsTRizzleBot( true ) then
					
						bot:Kick( "Owner " .. ply:Nick() .. " has left the server" )
						
					else
					
						bot.TBotOwner = bot
						
					end
					
				end
			
			end
		end
		
	end
	
end)

-- This is for certain functions that effect every bot with one call.
hook.Add( "Think" , "TRizzleBotThink" , function()
	
	-- The bots shouldn't do anything while navmesh is being analyzed and generated.
	if navmesh.IsGenerating() then
	
		return
		
	end
	
	BotUpdateInterval = ( BotUpdateSkipCount + 1 ) * FrameTime()
	--local startTime = SysTime()
	--ShowAllHidingSpots()
	
	-- This shouldn't run as often
	if ( engine.TickCount() % math.floor( ( 1 / engine.TickInterval() ) / 2 ) == 0 ) then
		local tab = player.GetHumans()
		if #tab > 0 then
			local ply = tab[ math.random( #tab ) ]
			
			net.Start( "TRizzleBotFlashlight" )
			net.Send( ply )
		end
	end
	
	for i = 1, game.MaxPlayers() do -- Is this cheaper than for k, bot in ipairs( player.GetBots() ) do
	
		local bot = Entity( i )
	
		if IsValid( bot ) and bot:IsTRizzleBot() then
			
			bot:UpdateAim()
			
			if ( ( engine.TickCount() + bot:EntIndex() ) % BotUpdateSkipCount ) == 0 then
			
				bot:ResetCommand() -- Clear all movement and buttons
				
				if !bot:Alive() then -- We do the respawning here since its better than relying on timers
			
					if ( !bot.NextSpawnTime or bot.NextSpawnTime <= CurTime() ) and bot:GetDeathTimestamp() > TBotSpawnTime:GetFloat() + 60.0 then -- Just incase something stops the bot from respawning, I force them to respawn anyway
					
						bot:Spawn()
						
					elseif ( !bot.NextSpawnTime or bot.NextSpawnTime <= CurTime() ) and bot:GetDeathTimestamp() > TBotSpawnTime:GetFloat() then -- I have to manually call the death think hook, or the bot won't respawn
						
						bot:PressPrimaryAttack()
						hook.Run( "PlayerDeathThink", bot )
					
					end
					
					continue -- We don't need to think while dead
					
				end
				
				bot:UpdateVision()
				-- This seems to lag the game
				bot:UpdatePeripheralVision()
				
				local speed = bot:GetVelocity():Length()
	
				if speed > 10.0 then
				
					bot.MotionVector = bot:GetVelocity() / speed
					
				end
				
				--if bot:GetCollisionGroup() != 5 then bot:SetCollisionGroup( 5 ) end -- Apparently the bot's default collisiongroup is set to 11 causing the bot not to take damage from melee enemies
				
				if !IsValid( bot.TBotOwner ) or !bot.TBotOwner:Alive() then	
					
					if ( ( engine.TickCount() + bot:EntIndex() ) % 5 ) == 0 then
						
						local CurrentLeader = bot:FindGroupLeader()
						if IsValid( CurrentLeader ) then
						
							bot.GroupLeader = CurrentLeader
							
						else
						
							bot.GroupLeader = bot
						
						end
						
					end
				
				--elseif IsValid( bot.GroupLeader ) then -- If the bot's owner is alive, the bot should clear its group leader and the hiding spot it was trying to goto
					
					--bot.GroupLeader	= nil
					--bot:ClearHidingSpot()
					
				end
				
				bot.ReviveTarget = bot:TBotFindReviveTarget()
				local threat = bot:GetPrimaryKnownThreat()
				if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
				
					if threat:IsVisibleInFOVNow() then
					
						bot:AimAtEntity( threat:GetEntity(), 1.0, HIGH_PRIORITY )
						
					else
					
						if bot:TBotVisible( threat:GetEntity() ) then
						
							local toThreat = threat:GetEntity():GetPos() - bot:GetPos()
							local threatRange = toThreat:Length()
							
							local s = math.sin( math.pi/6.0 )
							local Error = threatRange * s
							local imperfectAimSpot = threat:GetEntity():WorldSpaceCenter()
							imperfectAimSpot.x = imperfectAimSpot.x + math.Rand( -Error, Error )
							imperfectAimSpot.y = imperfectAimSpot.y + math.Rand( -Error, Error )
							
							bot:AimAtPos( imperfectAimSpot, 1.0, MEDIUM_PRIORITY )
							
						end
					
					end
					
				end
				
				local botWeapon = bot:GetActiveWeapon()
				if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) and threat:IsVisibleRecently() then
					
					bot.LastCombatTime = CurTime() -- Update combat timestamp
					
					local enemy = threat:GetEntity()
					local enemyDist = enemy:GetPos():DistToSqr( bot:GetPos() ) -- Grab the bot's current distance from their current enemy
					
					-- Should I limit how often this runs?
					local trace = {}
					util.TraceLine( { start = bot:GetShootPos(), endpos = enemy:GetHeadPos(), filter = bot, mask = MASK_SHOT, output = trace } )
					
					if trace.Entity == enemy then
						
						bot.AimForHead = true
						
					else
						
						bot.AimForHead = false
						
					end
					
					if IsValid( botWeapon ) and botWeapon:IsWeapon() then
					
						if bot.FullReload and ( !botWeapon:NeedsToReload() or botWeapon:GetClass() != bot.Shotgun ) then bot.FullReload = false end -- Fully reloaded :)
						
						if CurTime() >= bot.ScopeInterval and botWeapon:GetClass() == bot.Sniper and bot.SniperScope and !bot:IsUsingScope() then
						
							bot:PressSecondaryAttack()
							bot.ScopeInterval = CurTime() + 0.4
							bot.FireWeaponInterval = CurTime() + 0.4
						
						end
						
						if CurTime() >= bot.FireWeaponInterval and !bot:IsReloading() and !bot.FullReload and !botWeapon:IsPrimaryClipEmpty() and botWeapon:GetClass() != "weapon_medkit" and ( botWeapon:GetClass() != bot.Grenade or ( bot.GrenadeInterval <= CurTime() and botWeapon:GetNextPrimaryFire() <= CurTime() ) ) and ( botWeapon:GetClass() != bot.Melee or enemyDist <= bot.MeleeDist * bot.MeleeDist ) and bot:IsCursorOnTarget( enemy ) then
							
							bot:PressPrimaryAttack()
							
							-- The bot should throw a grenade then swap to another weapon
							if botWeapon:GetClass() == bot.Grenade and bot.GrenadeInterval <= CurTime() then
							
								bot.GrenadeInterval = CurTime() + 22.0
								bot.MinEquipInterval = CurTime() + 2.0
								
							end
							
							-- If the bot's active weapon is automatic the bot should just press and hold its attack button if their current enemy is close enough
							if bot:IsActiveWeaponAutomatic() and enemyDist < 160000 then
								
								bot.FireWeaponInterval = CurTime()
								
							elseif enemyDist < 640000 then
								
								bot.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )
								
							else
								
								bot.FireWeaponInterval = CurTime() + math.Rand( 0.3 , 0.7 )
								
							end
							
							-- Subtract system latency
							bot.FireWeaponInterval = bot.FireWeaponInterval - BotUpdateInterval
							
						end
						
						if CurTime() >= bot.FireWeaponInterval and botWeapon:GetClass() == "weapon_medkit" and bot.CombatHealThreshold > bot:Health() then
							
							bot:PressSecondaryAttack()
							bot.FireWeaponInterval = CurTime() + 0.5
							
						end
						
						if CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:IsPrimaryClipEmpty() then
							
							if botWeapon:GetClass() == bot.Shotgun then bot.FullReload = true end
							
							bot:PressReload()
							bot.ReloadInterval = CurTime() + 0.5
							
						end
						
						-- If an enemy gets too close and the bot is not using its melee weapon the bot should retreat backwards
						if !bot:IsPathValid() and botWeapon:GetClass() != bot.Melee and enemyDist < 10000 then
							
							local ground = navmesh.GetGroundHeight( bot:GetPos() - ( 30.0 * bot:EyeAngles():Forward() ) )
							
							-- Don't dodge if we will fall
							if ground and bot:GetPos().z - ground < bot:GetStepSize() then
								
								bot:PressBack()
								
							end
						
						end
						
					end
					
					bot:SelectBestWeapon( enemy, enemyDist )
				
				else
				
					if !bot:IsInCombat() then
					
						-- If the bot is not in combat then the bot should check if any of its teammates need healing
						bot.HealTarget = bot:TBotFindHealTarget()
						
						--[[if IsValid( bot.HealTarget ) and bot:HasWeapon( "weapon_medkit" ) then
						
							bot.BestWeapon = bot:GetWeapon( "weapon_medkit" )
							
							if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" then
								
								if CurTime() >= bot.FireWeaponInterval then 
								
									if bot.HealTarget == bot then
								
										bot:PressSecondaryAttack()
										bot.FireWeaponInterval = CurTime() + 0.5
									
									elseif bot:GetEyeTrace().Entity == bot.HealTarget then
								
										bot:PressPrimaryAttack()
										bot.FireWeaponInterval = CurTime() + 0.5
										
									end
									
								end
								
								if bot.HealTarget != bot then bot:AimAtPos( bot.HealTarget:WorldSpaceCenter(), 0.1, MEDIUM_PRIORITY ) end
								
							end
							
						else
						
							bot:ReloadWeapons()
							
						end]]
						
						-- Don't attempt to reload weapons while we are healing.
						if bot:GetTBotState() != HEAL_PLAYER then
						
							bot:ReloadWeapons()
							
						end
						
						if IsValid( botWeapon ) and botWeapon:IsWeapon() then 
							
							if CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:NeedsToReload() then
						
								bot:PressReload()
								bot.ReloadInterval = CurTime() + 0.5
								
							end
							
							if CurTime() >= bot.ScopeInterval and botWeapon:GetClass() == bot.Sniper and bot.SniperScope and bot:IsUsingScope() then
								
								bot:PressSecondaryAttack()
								bot.ScopeInterval = CurTime() + 1.0
								
							end
							
						end
						
						-- The bot will slowly regenerate ammo it has lost when not in combat
						-- The bot will quickly regenerate ammo once it is safe
						if bot:IsSafe() or ( ( engine.TickCount() + bot:EntIndex() ) % math.floor( 1 / engine.TickInterval() ) == 0 ) then
						
							bot:RestoreAmmo()
							
						end
						
					else
					
						if IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:NeedsToReload() and ( botWeapon:IsPrimaryClipEmpty() or ( botWeapon:GetClass() == bot.Shotgun and bot:GetKnownCount( nil, true, -1 ) <= 0 ) or ( botWeapon:Clip1() < ( botWeapon:GetMaxClip1() * 0.6 ) and #bot.EnemyList <= 0 ) ) then
						
							bot:PressReload()
							bot.ReloadInterval = CurTime() + 0.5
							
						end
						
					end
				
				end
				
				-- Here is the AI for GroupLeaders
				if IsValid( bot.GroupLeader ) then
					
					if bot:IsGroupLeader() then
					
						-- If the bot's group is being overwhelmed then they should retreat
						if !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and ( ( istbotknownentity( threat ) and threat:IsVisibleRecently() and bot:Health() < bot.CombatHealThreshold ) or bot:GetKnownCount( nil, true, bot.DangerDist ) >= 10 ) then
					
							bot.HidingSpotInterval = CurTime() + 0.5
							bot:TBotSetHidingSpot( bot:FindSpot( "far", { pos = bot:GetPos(), radius = 10000, stepdown = 1000, stepup = bot:GetMaxJumpHeight(), checksafe = 1, checkoccupied = 1, checklineoffire = 1 } ), RETREAT, 10.0 )
						
						elseif !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and bot:IsSafe() and bot.NextHuntTime <= CurTime() then
						
							bot.HidingSpotInterval = CurTime() + 0.5
							bot:TBotSetHidingSpot( bot:FindSpot( "random", { pos = bot:GetPos(), radius = math.random( 5000, 10000 ), stepdown = 1000, stepup = bot:GetMaxJumpHeight(), spotType = "sniper", checksafe = 0, checkoccupied = 1, checklineoffire = 0 } ), SEARCH_AND_DESTORY, 30.0 )
						
						end
					
					else
					
						-- If the bot needs to reload its active weapon it should find cover nearby and reload there
						if !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and istbotknownentity( threat ) and threat:IsVisibleRecently() and IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() != bot.Melee and botWeapon:IsPrimaryClipEmpty() and bot.GroupLeader:GetPos():DistToSqr( bot:GetPos() ) < bot.FollowDist * bot.FollowDist then

							bot.HidingSpotInterval = CurTime() + 0.5
							bot:TBotSetHidingSpot( bot:FindSpot( "near", { pos = bot:GetPos(), radius = 500, stepdown = 1000, stepup = bot:GetMaxJumpHeight(), checksafe = 1, checkoccupied = 1, checklineoffire = 1 } ), RELOAD_IN_COVER )

						end
					
					end
					
				elseif IsValid( bot.TBotOwner ) and bot.TBotOwner:Alive() then
					
					-- If the bot needs to reload its active weapon it should find cover nearby and reload there
					if !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and istbotknownentity( threat ) and threat:IsVisibleRecently() and IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() != bot.Melee and botWeapon:IsPrimaryClipEmpty() and bot.TBotOwner:GetPos():DistToSqr( bot:GetPos() ) < bot.FollowDist * bot.FollowDist then

						bot.HidingSpotInterval = CurTime() + 0.5
						bot:TBotSetHidingSpot( bot:FindSpot( "near", { pos = bot:GetPos(), radius = 500, stepdown = 1000, stepup = bot:GetMaxJumpHeight(), checksafe = 1, checkoccupied = 1, checklineoffire = 1 } ), RELOAD_IN_COVER )

					end
					
				end
				
				-- Here is where the bot sets its move goals based on what its doing!
				local botState = bot:GetTBotState()
				if botState == IDLE then
				
					bot:TBotIdleState()
					
				elseif botState == HIDE then
				
					bot:TBotHideState()
					
				elseif botState == FOLLOW_OWNER then
				
					bot:TBotFollowOwnerState()
					
				elseif botState == FOLLOW_GROUP_LEADER then
				
					bot:TBotFollowGroupLeaderState()
					
				elseif botState == USE_ENTITY then
				
					bot:TBotUseEntityState()
					
				elseif botState == HOLD_POSITION then
				
					bot:TBotHoldPositionState()
					
				elseif botState == HEAL_PLAYER then
				
					bot:TBotHealPlayerState()
					
				elseif botState == REVIVE_PLAYER then
				
					bot:TBotRevivePlayerState()
					
				end
				
				-- This is where the bot sets its move goals
				--[[if isvector( bot.HidingSpot ) then
					
					if bot.HidingState == MOVE_TO_SPOT then
						
						local spotDistSq = bot:GetPos():DistToSqr( bot.HidingSpot )
						-- When have reached our destination start the wait timer
						if spotDistSq <= 1024 then
							
							bot.HidingState = WAIT_AT_SPOT
							bot.HideTime = CurTime() + bot.HideTime
							
						-- If the bot finished reloading its active weapon it should clear its selected hiding spot!
						elseif bot.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or botWeapon:GetClass() == bot.Melee or !botWeapon:NeedsToReload() ) then
							
							bot:ClearHidingSpot()
							
						-- If the bot finds an enemy, it should clear its selected hiding spot
						elseif bot.HideReason == SEARCH_AND_DESTORY and bot:IsInCombat() then
						
							bot.NextHuntTime = CurTime() + 10
							bot:TBotClearPath()
							bot:ClearHidingSpot()
						
						-- If the bot has a hiding spot it should path there
						elseif bot.RepathTimer <= CurTime() and spotDistSq > 1024 then
					
							TRizzleBotPathfinderCheap( bot, bot.HidingSpot )
							--bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
							
						end
						
					elseif bot.HidingState == WAIT_AT_SPOT then
						
						-- If the bot has finished hiding, it should clear its selected hiding spot
						if ( bot.HideReason == RETREAT or bot.HideReason == SEARCH_AND_DESTORY ) and bot.HideTime <= CurTime() then
							
							bot.NextHuntTime = CurTime() + 20.0
							bot:ClearHidingSpot()
						
						-- If the bot has finished reloading its active weapon, it should clear its selected hiding spot
						elseif bot.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or botWeapon:GetClass() == bot.Melee or !botWeapon:NeedsToReload() ) then
						
							bot:ClearHidingSpot()
						
						-- If the bot's hiding spot is no longer safe, it should clear its selected hiding spot
						elseif !bot:IsSpotSafe( bot.HidingSpot + HalfHumanHeight ) then
						
							bot.NextHuntTime = CurTime() + 20.0
							bot:ClearHidingSpot()
						
						elseif !IsValid( bot:GetLastKnownArea() ) or !bot:GetLastKnownArea():HasAttributes( NAV_MESH_STAND ) then
							
							-- The bot should crouch once it reaches its selected hiding spot
							bot:PressCrouch()
						
						end
						
					end
					
					if bot.HideReason == RELOAD_IN_COVER and IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:NeedsToReload() then
					
						bot:PressReload()
						bot.ReloadInterval = CurTime() + 0.5
					
					end
				
				elseif IsValid( bot.UseEnt ) then
				
					if bot.UseHoldTime > CurTime() or !bot.StartedUse then
				
						local useEnt = bot:GetUseEntity()
						if bot.RepathTimer <= CurTime() and useEnt != bot.UseEnt then
							
							TRizzleBotPathfinderCheap( bot, bot.UseEnt:GetPos() )
							--bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
							
						elseif useEnt == bot.UseEnt then
							
							bot:PressUse()
							bot.RepathTimer = 0
							bot:TBotClearPath()
							
							if !bot.StartedUse then
							
								bot.StartedUse = true
								bot.UseHoldTime = CurTime() + bot.UseHoldTime
								
							end
						
						end
						
						if bot.UseEnt:GetPos():DistToSqr( bot:GetPos() ) <= 200^2 and bot:IsAbleToSee( bot.UseEnt ) then
							
							bot:AimAtPos( bot.UseEnt:WorldSpaceCenter(), 0.1, HIGH_PRIORITY )
							
						end
						
					else
					
						bot.UseEnt = nil
						bot.UseHoldTime = 0
						bot.StartedUse = false
						
					end
				
				elseif IsValid( bot.ReviveTarget ) and bot:GetKnownCount( nil, false, bot.DangerDist ) <= 5 then
				
					local reviveTargetDist = bot.ReviveTarget:GetPos():DistToSqr( bot:GetPos() )
					if reviveTargetDist > 80^2 or !bot:IsLineOfFireClear( bot.ReviveTarget ) then
						
						if !bot:IsPathValid() or ( bot.ChaseTimer <= CurTime() and bot:IsRepathNeeded( bot.ReviveTarget ) ) or bot.RepathTimer <= CurTime() then
						
							TRizzleBotPathfinderCheap( bot, bot.ReviveTarget:GetPos() )
							--bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
							bot.ChaseTimer = CurTime() + 0.5
							
						end
					
					elseif bot:IsPathValid() then
					
						bot:TBotClearPath()
					
					end
					
					if reviveTargetDist <= 100^2 and bot:IsAbleToSee( bot.ReviveTarget ) then
					
						bot:AimAtPos( bot.ReviveTarget:GetPos(), 0.1, HIGH_PRIORITY )
						
						if bot:IsLookingAtPosition( bot.ReviveTarget:GetPos() ) then
						
							bot:PressUse()
							
						end
					
					end
				
				elseif isvector( bot.HoldPos ) then
				
					local goalDist = bot:GetPos():DistToSqr( bot.HoldPos )
					if goalDist > TBotGoalTolerance:GetFloat()^2 then
					
						if bot.RepathTimer <= CurTime() then
							
							TRizzleBotPathfinderCheap( bot, bot.HoldPos )
							--bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
							
						end
						
					end
				
				elseif IsValid( bot.GroupLeader ) and !bot:IsGroupLeader() then
				
					local leaderDist = bot.GroupLeader:GetPos():DistToSqr( bot:GetPos() )
					if leaderDist > bot.FollowDist^2 then
						
						if !bot:IsPathValid() or ( bot.ChaseTimer <= CurTime() and bot:IsRepathNeeded( bot.GroupLeader ) ) or bot.RepathTimer <= CurTime() then
						
							TRizzleBotPathfinderCheap( bot, bot.GroupLeader:GetPos() )
							--bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
							bot.ChaseTimer = CurTime() + 0.5
							
						end
					
					elseif bot:IsPathValid() and bot:IsLineOfFireClear( bot.GroupLeader ) then -- Is this a good idea? and leaderDist <= ( bot.FollowDist / 2 )^2
					
						bot:TBotClearPath()
					
					end
					
				elseif IsValid( bot.TBotOwner ) and bot.TBotOwner:Alive() then
					
					local ownerDist = bot.TBotOwner:GetPos():DistToSqr( bot:GetPos() )
					if ownerDist > bot.FollowDist^2 then
						
						if !bot:IsPathValid() or ( bot.ChaseTimer <= CurTime() and bot:IsRepathNeeded( bot.TBotOwner ) ) or bot.RepathTimer <= CurTime() then
						
							TRizzleBotPathfinderCheap( bot, bot.TBotOwner:GetPos() )
							--bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
							bot.ChaseTimer = CurTime() + 0.5
							
						end
					
					elseif bot:IsPathValid() and bot:IsLineOfFireClear( bot.TBotOwner ) then -- Is this a good idea? and ownerDist <= ( bot.FollowDist / 2 )^2
					
						bot:TBotClearPath()
					
					end
					
				end]]
				
				-- The check CNavArea we are standing on.
				if !IsValid( bot.currentArea ) or !bot.currentArea:Contains( bot:GetPos() ) then
				
					bot.currentArea			=	navmesh.GetNearestNavArea( bot:GetPos(), true, 50, true )
					
				end
				
				if IsValid( bot.currentArea ) and bot.currentArea != bot.lastKnownArea then
				
					bot.lastKnownArea = bot.currentArea
					
				end
				
				local stillSpeed = 10.0
				if bot:GetVelocity():IsLengthLessThan( stillSpeed ) then
				
					if !bot.StillTimer then
					
						bot.StillTimer = CurTime()
						
					end
					
				else
				
					bot.StillTimer = nil
					
				end
				
				-- Update the bot's encounter and approach points
				if ( ( !bot:IsInCombat() and !bot:IsSafe() ) or bot:IsHiding() ) and bot.NextEncounterTime <= CurTime() then
				
					local minStillTime = 2.0
					if bot:IsAtHidingSpot() or bot:IsNotMoving( minStillTime ) then
						
						local recomputeApproachPointTolerance = 50.0
						if ( bot.ApproachViewPosition - bot:GetPos() ):IsLengthGreaterThan( recomputeApproachPointTolerance ) then
						
							bot:ComputeApproachPoints()
							bot.ApproachViewPosition = bot:GetPos()
						
						end
					
						if istable( bot.ApproachPoints ) and #bot.ApproachPoints > 0 then
					
							bot:AimAtPos( bot.ApproachPoints[ math.random( #bot.ApproachPoints ) ].Pos + HalfHumanHeight, 1.0, MEDIUM_PRIORITY )
							bot.NextEncounterTime = CurTime() + 2.0
							
						else
						
							bot:AimAtPos( bot:ComputeEncounterSpot(), 1.0, MEDIUM_PRIORITY )
							bot.NextEncounterTime = CurTime() + 2.0
						
						end
					
					else
					
						bot:AimAtPos( bot:ComputeEncounterSpot(), 1.0, MEDIUM_PRIORITY )
						bot.NextEncounterTime = CurTime() + 2.0
					
					end
				
				end
				
				-- Update the bot movement if they are pathing to a goal
				bot:TBotDebugWaypoints()
				bot:TBotUpdateMovement()
				bot:TBotUpdateLocomotion()
				bot:StuckMonitor()
				bot:DoorCheck()
				bot:BreakableCheck()
				
				if IsValid( bot.TBotOwner ) then
				
					if bot.TBotOwner:InVehicle() and !bot:InVehicle() then
					
						local vehicle = bot:FindNearbySeat()
						
						if IsValid( vehicle ) then bot:EnterVehicle( vehicle ) end -- I should make the bot press its use key instead of this hack
					
					end
					
					if !bot.TBotOwner:InVehicle() and bot:InVehicle() and CurTime() >= bot.UseInterval then
					
						bot:PressUse()
						bot.UseInterval = CurTime() + 0.5
					
					end
					
				end
				
				if bot.SpawnWithWeapons then
					
					bot:Give( bot.Pistol )
					bot:Give( bot.Shotgun )
					bot:Give( bot.Rifle )
					bot:Give( bot.Sniper )
					bot:Give( bot.Melee )
					bot:Give( "weapon_medkit" )
					if bot:IsSafe() then bot:Give( bot.Grenade ) end -- The bot should only spawn in its grenade if it feels safe.
					
				end
				
				if bot:CanUseFlashlight() and !bot:FlashlightIsOn() and bot.Light and bot:GetSuitPower() > 50 then
					
					bot.impulseFlags = 100
					bot:Flashlight( true )
					
				elseif bot:CanUseFlashlight() and bot:FlashlightIsOn() and !bot.Light then
					
					bot.impulseFlags = 100
					bot:Flashlight( false )
					
				end
				
				bot:HandleButtons()
				
			end
			
		end
		
	end

	--print( "Think RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	
end)

-- This is the bot's idle state
function BOT:TBotIdleState()

	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	local useEnt = self.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	local botReviveTarget = self.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, self.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	local botHoldPos = self.HoldPos
	if isvector( botHoldPos ) then
	
		self:TBotSetState( HOLD_POSITION )
		return
		
	end
	
	local botOwner = self.TBotOwner
	if IsValid( botOwner ) and botOwner:Alive() then
	
		self.GroupLeader = nil
		local ownerDist = botOwner:GetPos():DistToSqr( self:GetPos() )
		if ownerDist > self.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_OWNER )
			return
			
		end
	
	end
	
	local botLeader = self.GroupLeader
	if IsValid( botLeader ) and !self:IsGroupLeader() then
	
		local leaderDist = botLeader:GetPos():DistToSqr( self:GetPos() )
		if leaderDist > self.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_GROUP_LEADER )
			return
			
		end
		
	end
	
	-- These states should only become activate when we are not in combat.
	if !self:IsInCombat() then
	
		local botHealTarget = self.HealTarget
		if IsValid( botHealTarget ) and self:HasWeapon( "weapon_medkit" ) then
		
			self:TBotSetState( HEAL_PLAYER )
			return
			
		end
		
	end

end

-- This is the bot's hiding state
function BOT:TBotHideState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	if !self:IsHiding() then
	
		self:TBotSetState( IDLE )
		return
		
	end

	local botWeapon = self:GetActiveWeapon()
	local threat = self:GetPrimaryKnownThreat()
	if self.HidingState == MOVE_TO_SPOT then
	
		local spotDistSq = self:GetPos():DistToSqr( self.HidingSpot )
		-- When have reached our destination start the wait timer
		if spotDistSq <= 1024 then
			
			self.HidingState = WAIT_AT_SPOT
			self.HideTime = CurTime() + self.HideTime
		
		-- If the bot finished reloading its active weapon it should clear its selected hiding spot!
		elseif self.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or botWeapon:GetClass() == self.Melee or !botWeapon:NeedsToReload() ) then
		
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		-- If the bot finds an enemy, it should clear its selected hiding spot
		elseif self.HideReason == SEARCH_AND_DESTORY and self:IsInCombat() then
		
			self.NextHuntTime = CurTime() + 10
			self:TBotClearPath()
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		-- If the bot has a hiding spot it should path there
		elseif self.RepathTimer <= CurTime() and spotDistSq > 1024 then
		
			TRizzleBotPathfinderCheap( self, self.HidingSpot )
			--bot:TBotCreateNavTimer()
			self.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
		
		end
	
	elseif self.HidingState == WAIT_AT_SPOT then
		
		-- If the bot has finished hiding, it should clear its selected hiding spot
		if ( self.HideReason == RETREAT or self.HideReason == SEARCH_AND_DESTORY ) and self.HideTime <= CurTime() then
			
			self.NextHuntTime = CurTime() + 20.0
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		-- If the bot has finished reloading its active weapon, it should clear its selected hiding spot
		elseif self.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or botWeapon:GetClass() == self.Melee or !botWeapon:NeedsToReload() ) then
		
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
			
		-- If the bot's hiding spot is no longer safe, it should clear its selected hiding spot
		elseif !self:IsSpotSafe( self.HidingSpot + HalfHumanHeight ) then
		
			self.NextHuntTime = CurTime() + 20.0
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		elseif !IsValid( self:GetLastKnownArea() ) or !self:GetLastKnownArea():HasAttributes( NAV_MESH_STAND ) then
		
			-- The bot should crouch once it reaches its selected hiding spot
			self:PressCrouch()
		
		end
		
	end
	
	if self.HideReason == RELOAD_IN_COVER and IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() >= self.ReloadInterval and !self:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != self.Melee and botWeapon:NeedsToReload() then
		
		self:PressReload()
		self.ReloadInterval = CurTime() + 0.5
		
	end

end

-- This is the bot's use entity state
function BOT:TBotUseEntityState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	if self:IsHiding() then
	
		self.UseEnt = nil
		self.UseHoldTime = 0
		self.StartedUse = false
		self:TBotSetState( HIDE )
		return
		
	end

	local botUseEnt = self.UseEnt
	if !IsValid( botUseEnt ) or ( self.UseHoldTime <= CurTime() and self.StartedUse ) then
	
		self.UseEnt = nil
		self.UseHoldTime = 0
		self.StartedUse = false
		self:TBotSetState( IDLE )
		return
	
	end
	
	local useEnt = self:GetUseEntity()
	if self.RepathTimer <= CurTime() and useEnt != botUseEnt then
	
		TRizzleBotPathfinderCheap( self, self.UseEnt:GetPos() )
		--bot:TBotCreateNavTimer()
		self.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
	
	elseif useEnt == botUseEnt then
	
		self:PressUse()
		self.RepathTimer = 0
		self:TBotClearPath()
		
		if !self.StartedUse then
		
			self.StartedUse = true
			self.UseHoldTime = CurTime() + self.UseHoldTime
			
		end
	
	end
	
	if botUseEnt:GetPos():DistToSqr( self:GetPos() ) <= 200^2 and self:IsAbleToSee( botUseEnt ) then
		
		self:AimAtPos( botUseEnt:WorldSpaceCenter(), 0.1, HIGH_PRIORITY )
		
	end
	
end

-- This is the bot's revive player state
-- NOTE: This only used if the revive mod is installed
function BOT:TBotRevivePlayerState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than reviving someone.
	local useEnt = self.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	local botReviveTarget = self.ReviveTarget
	if !IsValid( botReviveTarget ) or self:GetKnownCount( nil, false, self.DangerDist ) > 5 then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local reviveTargetDist = botReviveTarget:GetPos():DistToSqr( self:GetPos() )
	if reviveTargetDist > 80^2 or !self:IsLineOfFireClear( botReviveTarget ) then
		
		if ( self.ChaseTimer <= CurTime() and ( !self:IsPathValid() or self:IsRepathNeeded( botReviveTarget ) ) ) or self.RepathTimer <= CurTime() then
			
			TRizzleBotPathfinderCheap( self, botReviveTarget:GetPos() )
			--bot:TBotCreateNavTimer()
			self.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
			self.ChaseTimer = CurTime() + 0.5
			
		end
		
	elseif self:IsPathValid() then
		
		self:TBotClearPath()
		
	end
	
	if reviveTargetDist <= 100^2 and self:IsAbleToSee( botReviveTarget ) then
		
		self:AimAtPos( botReviveTarget:GetPos(), 0.1, HIGH_PRIORITY )
		
		if self:IsLookingAtPosition( botReviveTarget:GetPos() ) then
		
			self:PressUse()
			
		end
	
	end

end

-- This is the bot's hold position state
function BOT:TBotHoldPositionState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than holding our current position.
	-- We will go back to holding the position set by our owner when we finish.
	local useEnt = self.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than holding where our owner told us.
	local botReviveTarget = self.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, self.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	local botHoldPos = self.HoldPos
	if !isvector( botHoldPos ) then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local goalDist = self:GetPos():DistToSqr( botHoldPos )
	if goalDist > TBotGoalTolerance:GetFloat()^2 then
		
		if self.RepathTimer <= CurTime() then
		
			TRizzleBotPathfinderCheap( self, botHoldPos )
			--bot:TBotCreateNavTimer()
			self.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
		
		end
	
	end
	
end

-- This is the bot's heal player state
function BOT:TBotHealPlayerState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than healing someone.
	-- We will go back to healing when we finish.
	local useEnt = self.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than healing someone.
	local botReviveTarget = self.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, self.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	-- Following our owner is more important than healing someone.
	local botOwner = self.TBotOwner
	if IsValid( botOwner ) and botOwner:Alive() then
	
		self.GroupLeader = nil
		local ownerDist = botOwner:GetPos():DistToSqr( self:GetPos() )
		if ownerDist > self.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_OWNER )
			return
			
		end
	
	end
	
	-- Following our group leader is more important than healing someone.
	local botLeader = self.GroupLeader
	if IsValid( botLeader ) and !self:IsGroupLeader() then
	
		local leaderDist = botLeader:GetPos():DistToSqr( self:GetPos() )
		if leaderDist > self.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_GROUP_LEADER )
			return
			
		end
		
	end
	
	-- The bot shouldn't heal while in combat.
	if self:IsInCombat() then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local botHealTarget = self.HealTarget
	if !IsValid( botHealTarget ) or !self:HasWeapon( "weapon_medkit" ) then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	self.BestWeapon = self:GetWeapon( "weapon_medkit" )
	
	local botWeapon = self:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" then
		
		if CurTime() >= self.FireWeaponInterval then 
			
			if botHealTarget == self then
			
				self:PressSecondaryAttack()
				self.FireWeaponInterval = CurTime() + 0.5
			
			elseif self:GetEyeTrace().Entity == botHealTarget then
				
				self:PressPrimaryAttack()
				self.FireWeaponInterval = CurTime() + 0.5
				
			end
			
		end
	
		if botHealTarget != self then self:AimAtPos( botHealTarget:WorldSpaceCenter(), 0.1, MEDIUM_PRIORITY ) end
	
	end
	
end

-- This is the bot's follow owner state.
function BOT:TBotFollowOwnerState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than following its owner.
	-- We will go back to following when we finish.
	local useEnt = self.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than following its owner.
	local botReviveTarget = self.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, self.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	-- Our owner has told us to wait at a set postion, its a higher priority than following them.
	local botHoldPos = self.HoldPos
	if isvector( botHoldPos ) then
	
		self:TBotSetState( HOLD_POSITION )
		return
		
	end
	
	local botOwner = self.TBotOwner
	if !IsValid( botOwner ) or !botOwner:Alive() then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local ownerDist = botOwner:GetPos():DistToSqr( self:GetPos() )
	if ownerDist > self.FollowDist^2 then
		
		if ( self.ChaseTimer <= CurTime() and ( !self:IsPathValid() or self:IsRepathNeeded( botOwner ) ) ) or self.RepathTimer <= CurTime() then
		
			TRizzleBotPathfinderCheap( self, botOwner:GetPos() )
			--bot:TBotCreateNavTimer()
			self.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
			self.ChaseTimer = CurTime() + 0.5
		
		end
	
	elseif self:IsPathValid() then 
	
		if self:IsLineOfFireClear( botOwner ) then -- Is this a good idea? and ownerDist <= ( bot.FollowDist / 2 )^2
	
			self:TBotClearPath()
			self:TBotSetState( IDLE )
			return
			
		end
	
	else
	
		self:TBotSetState( IDLE ) -- This is a fail safe, so we don't get stuck in this state!
		return
	
	end
	
end

-- This is the bot's follow group leader state.
function BOT:TBotFollowGroupLeaderState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than following our group leader.
	-- We will go back to following when we finish.
	local useEnt = self.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than following our group leader.
	local botReviveTarget = self.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, self.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	-- Our owner has told us to wait at a set postion, its a higher priority than following them.
	local botHoldPos = self.HoldPos
	if isvector( botHoldPos ) then
	
		self:TBotSetState( HOLD_POSITION )
		return
		
	end
	
	-- Our owner is alive and valid, we should follow them instead.
	local botOwner = self.TBotOwner
	if IsValid( botOwner ) and botOwner:Alive() then
	
		self.GroupLeader = nil
		self:TBotSetState( FOLLOW_OWNER )
		return
		
	end
	
	local botLeader = self.GroupLeader
	if !IsValid( botLeader ) or !botLeader:Alive() then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local leaderDist = botLeader:GetPos():DistToSqr( self:GetPos() )
	if leaderDist > self.FollowDist^2 then
		
		if ( self.ChaseTimer <= CurTime() and ( !self:IsPathValid() or self:IsRepathNeeded( botLeader ) ) ) or self.RepathTimer <= CurTime() then
		
			TRizzleBotPathfinderCheap( self, botLeader:GetPos() )
			--bot:TBotCreateNavTimer()
			self.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
			self.ChaseTimer = CurTime() + 0.5
		
		end
	
	elseif self:IsPathValid() then 
	
		if self:IsLineOfFireClear( botLeader ) then -- Is this a good idea? and leaderDist <= ( bot.FollowDist / 2 )^2
	
			self:TBotClearPath()
			self:TBotSetState( IDLE )
			return
			
		end
		
	else
	
		self:TBotSetState( IDLE ) -- This is a fail safe, so we don't get stuck in this state!
		return
	
	end
	
end

-- Bot chat commands are handled here.
hook.Add( "PlayerSay", "TRizzleBotPlayerSay", function( sender, text, teamChat ) 
	if !IsValid( sender ) then return end

	local textTable = string.Explode( " ", text )
	if !textTable[ 1 ] or !textTable[ 2 ] then return end
	for k, bot in ipairs( player.GetAll() ) do
	
		if IsValid( bot ) and bot:IsTRizzleBot() and sender == bot.TBotOwner and textTable[ 1 ] == bot:Nick() then
		
			local command = textTable[ 2 ]:lower()
			if command == "follow" then
			
				bot.UseEnt = nil
				bot.UseHoldTime = 0.0
				bot.StartedUse = false
				bot.HoldPos = nil
				
			elseif command == "hold" then
			
				local pos = sender:GetEyeTrace().HitPos
				local ground = navmesh.GetGroundHeight( pos )
				if ground then
				
					pos.z = ground
					
				end
				
				bot.HoldPos = pos
			
			elseif command == "wait" then
			
				local pos = bot:GetPos()
				local ground = navmesh.GetGroundHeight( pos )
				if ground then
				
					pos.z = ground
					
				end
			
				bot.HoldPos = pos
			
			elseif command == "use" then
			
				local useEnt = sender:GetEyeTrace().Entity
			
				if IsValid( useEnt ) and !useEnt:IsWorld() then
				
					bot.UseEnt = useEnt
					bot.StartedUse = false
					
					if textTable[ 3 ] then
					
						bot.UseHoldTime = tonumber( textTable[ 3 ] ) or 0.1
						
					else
					
						bot.UseHoldTime = 0.1
						
					end
					
				end
			
			elseif command == "attack" then
			
				local enemy = sender:GetEyeTrace().Entity
				
				if IsValid( enemy ) and !enemy:IsWorld() then
				
					bot:AddKnownEntity( enemy )
					bot.AttackList[ enemy ] = true
					
				end
			
			elseif command == "warp" then
			
				bot:SetPos( sender:GetEyeTrace().HitPos )
			
			end
		
		end
	
	end

end)

-- Reset their AI on spawn.
hook.Add( "PlayerSpawn" , "TRizzleBotSpawnHook" , function( ply )
	
	if ply:IsTRizzleBot() then
		
		ply:TBotResetAI() -- For some reason running the a timer for 0.0 seconds works, but if I don't use a timer nothing works at all
		--[[timer.Simple( 0.0 , function()
			
			if IsValid( ply ) and ply:Alive() then
				
				ply:SetModel( player_manager.TranslatePlayerModel( ply.PlayerModel ) )
				
			end
			
		end)]]
		
		-- This function seems kind of redundant
		--[[timer.Simple( 0.3 , function()
		
			if IsValid( ply ) and ply:Alive() then
				
				if ply.SpawnWithWeapons then
					
					if !ply:HasWeapon( ply.Pistol ) then ply:Give( ply.Pistol ) end
					if !ply:HasWeapon( ply.Shotgun ) then ply:Give( ply.Shotgun ) end
					if !ply:HasWeapon( ply.Rifle ) then ply:Give( ply.Rifle ) end
					if !ply:HasWeapon( ply.Sniper ) then ply:Give( ply.Sniper ) end
					if !ply:HasWeapon( ply.Melee ) then ply:Give( ply.Melee ) end
					if !ply:HasWeapon( "weapon_medkit" ) then ply:Give( "weapon_medkit" ) end
					
				end
				
				-- I may make it possible to edit the bot movement speed
				--ply:SetRunSpeed( 600 )
				--ply:SetWalkSpeed( 400 )
				--hook.Run( "SetPlayerSpeed", ply, 400, 600 )
				
			end
			
		end)]]
		
	end
	
end)

-- The main AI is here.
-- Deprecated: I have a newer think function, that is more responsive and optimized
--[[function BOT:TBotCreateThinking()
	
	local index		=	self:EntIndex()
	local timer_time	=	math.Rand( 0.08 , 0.15 )
	
	-- I used math.Rand as a personal preference, It just prevents all the timers being ran at the same time
	-- as other bots timers.
	timer.Create( "trizzle_bot_think" .. index , timer_time * 3 , 0 , function()
		
		if IsValid( self ) and self:Alive() and self.IsTRizzleBot then
			
			-- A quick condition statement to check if our enemy is no longer a threat.
			self:CheckCurrentEnemyStatus()
			self:TBotFindClosestEnemy()
			self:TBotCheckEnemyList()
			
			if !self:IsInCombat() then
			
				-- If the bot is not in combat then the bot should check if any of its teammates need healing
				self.HealTarget = self:TBotFindClosestTeammate()
				local botWeapon = self:GetActiveWeapon()
				if IsValid( self.HealTarget ) then
				
					self:SelectMedkit()
					
					if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" then
						
						if CurTime() > self.FireWeaponInterval and self.HealTarget == self then
						
							self.FireWeaponInterval = CurTime() + 0.5
							self:PressSecondaryAttack()
							
						elseif CurTime() > self.FireWeaponInterval and self:GetEyeTrace().Entity == self.HealTarget then
						
							self.FireWeaponInterval = CurTime() + 0.5
							self:PressPrimaryAttack()
							
						end
						
						if botWeapon:GetClass() == "weapon_medkit" and self.HealTarget != self then self:AimAtPos( self.HealTarget:WorldSpaceCenter(), CurTime() + 0.1, MEDIUM_PRIORITY ) end
						
					end
					
				else
				
					self:ReloadWeapons()
					
				end
				
				if IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() > self.ReloadInterval and !botWeapon:GetInternalVariable( "m_bInReload" ) and botWeapon:GetClass() != "weapon_medkit" and botWeapon:Clip1() < botWeapon:GetMaxClip1() then
					self:PressReload()
					self.ReloadInterval = CurTime() + 1.0
				end
				
				self:RestoreAmmo() 
				
			elseif IsValid( self.Enemy ) then
			
				local trace = util.TraceLine( { start = self:GetShootPos(), endpos = self.Enemy:EyePos(), filter = self, mask = MASK_SHOT } )
				
				if trace.Entity == self.Enemy then
					
					self.AimForHead = true
					
				else
					
					self.AimForHead = false
					
				end
				
				-- Turn and face our enemy!
				if self.AimForHead and !self:IsActiveWeaponRecoilHigh() then
				
					-- Can we aim the enemy's head?
					self:AimAtPos( self.Enemy:EyePos(), CurTime() + 0.1, HIGH_PRIORITY )
				
				else
					
					-- If we can't aim at our enemy's head aim at the center of their body instead.
					self:AimAtPos( self.Enemy:WorldSpaceCenter(), CurTime() + 0.1, HIGH_PRIORITY )
				
				end
				
				local botWeapon = self:GetActiveWeapon()
				
				if IsValid( botWeapon ) and botWeapon:IsWeapon() and self.FullReload and ( botWeapon:Clip1() >= botWeapon:GetMaxClip1() or self:GetAmmoCount( botWeapon:GetPrimaryAmmoType() ) <= botWeapon:Clip1() or botWeapon:GetClass() != self.Shotgun ) then self.FullReload = false end -- Fully reloaded :)
				
				if IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() > self.FireWeaponInterval and !botWeapon:GetInternalVariable( "m_bInReload" ) and !self.FullReload and botWeapon:GetClass() != "weapon_medkit" and ( self:GetEyeTraceNoCursor().Entity == self.Enemy or self:IsCursorOnTarget() or (self.Enemy:GetPos() - self:GetPos()):LengthSqr() < self.MeleeDist * self.MeleeDist ) then
					self:PressPrimaryAttack()
					self.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.4 )
				end
				
				if IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() > self.FireWeaponInterval and botWeapon:GetClass() == "weapon_medkit" and self.CombatHealThreshold > self:Health() then
					self:PressSecondaryAttack()
					self.FireWeaponInterval = CurTime() + 0.5
				end
				
				if IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() > self.ReloadInterval and !botWeapon:GetInternalVariable( "m_bInReload" ) and botWeapon:Clip1() == 0 then
					if botWeapon:GetClass() == self.Shotgun then self.FullReload = true end
					self:PressReload()
					self.ReloadInterval = CurTime() + 1.0
				end
				
				self:SelectBestWeapon()
			
			end
			
			if self.Owner:InVehicle() and !self:InVehicle() then
			
				local vehicle = self:FindNearbySeat()
				
				if IsValid( vehicle ) then self:EnterVehicle( vehicle ) end -- I should make the bot press its use key instead of this hack
			
			end
			
			if !self.Owner:InVehicle() and self:InVehicle() then
			
				self:ExitVehicle() -- Should I make the bot press its use key instead?
			
			end
			
			if self.SpawnWithWeapons then
				
				if !self:HasWeapon( self.Pistol ) then self:Give( self.Pistol ) end
				if !self:HasWeapon( self.Shotgun ) then self:Give( self.Shotgun ) end
				if !self:HasWeapon( self.Rifle ) then self:Give( self.Rifle ) end
				if !self:HasWeapon( self.Sniper ) then self:Give( self.Sniper ) end
				if !self:HasWeapon( self.Melee ) then self:Give( self.Melee ) end
				if !self:HasWeapon( "weapon_medkit" ) then self:Give( "weapon_medkit" ) end
				
			end
			
			-- I have to set the flashlight state because some addons have mounted flashlights and I can't check if they are on or not, "This will prevent the flashlight on and off spam"
			if self:CanUseFlashlight() and !self:FlashlightIsOn() and self.Light and self:GetSuitPower() > 50 then
				
				self:Flashlight( true )
				
			elseif self:CanUseFlashlight() and self:FlashlightIsOn() and !self.Light then
				
				self:Flashlight( false )
				
			end
			
			self:HandleButtons()
			
		else
			
			timer.Remove( "trizzle_bot_think" .. index ) -- We don't need to think while dead.
			
		end
		
	end)
	
end]]

-- Makes the bot react to damage taken by enemies
hook.Add( "PlayerHurt" , "TRizzleBotPlayerHurt" , function( victim, attacker )

	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() or !IsValid( attacker ) or !IsValid( victim ) or !victim:IsTRizzleBot() then return end
	
	if ( attacker:IsNPC() and attacker:IsAlive() ) or ( attacker:IsPlayer() and attacker:Alive() ) or ( attacker:IsNextBot() and attacker:Health() > 0 ) then
		
		if victim:IsEnemy( attacker ) then
		
			local known = victim:AddKnownEntity( attacker )
			
			if istbotknownentity( known ) then
			
				known:UpdatePosition()
				
			end
			
			if !victim:IsInCombat() then victim.LastCombatTime = CurTime() - 5.0 end
			
		end
		
	end

end)

-- Makes the bot react to sounds made by enemies
hook.Add( "EntityEmitSound" , "TRizzleBotEntityEmitSound" , function( soundTable )
	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() then return end
	
	for i = 1, game.MaxPlayers() do
	
		local bot = Entity( i )
		
		if !IsValid( bot ) or !bot:IsTRizzleBot() or !IsValid( soundTable.Entity ) and soundTable.Entity == bot then continue end
	
		if ( soundTable.Entity:IsNPC() and soundTable.Entity:IsAlive() ) or ( soundTable.Entity:IsPlayer() and soundTable.Entity:Alive() ) or ( soundTable.Entity:IsNextBot() and soundTable.Entity:Health() > 0 ) then 
		
			if bot:IsEnemy( soundTable.Entity ) and soundTable.Entity:GetPos():DistToSqr( bot:GetPos() ) < math.Clamp( ( 2500 * ( soundTable.SoundLevel / 100 ) )^2, 0, 6250000 ) then
			
				local known = bot:AddKnownEntity( soundTable.Entity )
				
				if istbotknownentity( known ) then
				
					known:UpdatePosition()
					
				end
			
				if !bot:IsInCombat() then bot.LastCombatTime = CurTime() - 5.0 end
				
			end
			
		end
		
	end
	
end)

-- Checks if the NPC is alive
function Npc:IsAlive()
	
	if self:GetNPCState() == NPC_STATE_DEAD then return false
	elseif self:GetInternalVariable( "m_lifeState" ) != 0 then return false 
	elseif self:Health() <= 0 then return false end
	
	return true
	
end

-- Checks if the target entity is the bot's enemy
function BOT:IsEnemy( target )
	if !IsValid( target ) or self == target then return false end
	
	if self.AttackList[ target ] then
	
		return true
	
	end
	
	if target:IsNPC() then
	
		if self:IsTRizzleBot() and IsValid( self.TBotOwner ) and target:Disposition( self.TBotOwner ) == D_HT then
		
			return true
			
		end
	
		return target:Disposition( self ) == D_HT
		
	end
	
	if target:IsNextBot() and TBotAttackNextBots:GetBool() then
	
		return true
		
	end
	
	if target:IsPlayer() and TBotAttackPlayers:GetBool() then
	
		if IsValid( self.TBotOwner ) or IsValid( target.TBotOwner ) then 
		
			if self.TBotOwner != target and target.TBotOwner != self and self.TBotOwner != target.TBotOwner then
		
				return true
				
			end
		
		else
		
			return true
		
		end
		
	end
	
	return false
	
end

-- Returns true if the bot's reaction time has elapsed
-- for the entered TBotKnownEntity
function BOT:IsAwareOf( known )

	return known:GetTimeSinceBecameKnown() >= self:GetMinRecognizeTime()
	
end

-- Returns the minimum amount of time before 
-- the bot can react to seeing an enemy
-- NOTE: This can be used to make bots react faster or slower to certain things
function BOT:GetMinRecognizeTime()

	return 0.2
	
	-- This is an example of different levels of reaction times
	-- I could also make this skill dependent....
	--[[if "Expert" then
	
		return 0.2
		
	elseif "Hard" then
	
		return 0.3
	
	elseif "Normal" then
	
		return 0.5
		
	elseif "Easy" then
	
		return 1.0
	
	end]]
	
end

function BOT:IsThreatAimingTowardMe( threat, cosTolerance )

	cosTolerance = cosTolerance or 0.8
	local to = self:GetPos() - threat:GetPos()
	local threatRange = to:Length()
	to:Normalize()
	local forward = Either( threat:IsPlayer() or threat:IsNPC(), threat:GetAimVector(), threat:EyeAngles():Forward() )
	
	if to:Dot( forward ) > cosTolerance then
	
		return true
		
	end
	
	return false
	
end

function BOT:IsThreatFiringAtMe( threat )

	if self:IsThreatAimingTowardMe( threat ) then
	
		if threat:IsNPC() and threat:GetEnemy() == self then
		
			return true
			
		end
		
		if threat:IsPlayer() and threat:DidPlayerJustFireWeapon() then
		
			return true
			
		end
		
	end
	
	return false
	
end

function BOT:GetPrimaryKnownThreat( onlyVisibleThreats )
	onlyVisibleThreats = onlyVisibleThreats or false

	if #self.EnemyList == 0 then
	
		return nil
		
	end
	
	local threat = nil
	local i = 1
	
	while i <= #self.EnemyList do
	
		local firstThreat = self.EnemyList[ i ]
		
		if self:IsAwareOf( firstThreat ) and !firstThreat:IsObsolete() and !self:IsIgnored( firstThreat:GetEntity() ) and self:IsEnemy( firstThreat:GetEntity() ) then
		
			if !onlyVisibleThreats or firstThreat:IsVisibleRecently() then
			
				threat = firstThreat
				break
				
			end
			
		end
		
		i = i + 1
		
	end
	
	if !threat then
	
		return nil
		
	end
	
	i = i + 1
	while i <= #self.EnemyList do
	
		local newThreat = self.EnemyList[ i ]
		
		if self:IsAwareOf( newThreat ) and !newThreat:IsObsolete() and !self:IsIgnored( newThreat:GetEntity() ) and self:IsEnemy( newThreat:GetEntity() ) then
		
			if !onlyVisibleThreats or newThreat:IsVisibleRecently() then
			
				threat = self:SelectMoreDangerousThreat( threat, newThreat )
				
			end
			
		end
		
		i = i + 1
		
	end
	
	return threat
	
end

function BOT:IsImmediateThreat( threat )

	if threat:GetEntity():IsNPC() and !threat:GetEntity():IsAlive() then
	
		return false
		
	end
	
	if threat:GetEntity():IsPlayer() and !threat:GetEntity():Alive() then
	
		return false
		
	end
	
	if threat:GetEntity():IsNextBot() and threat:GetEntity():Health() < 1 then
	
		return false
		
	end
	
	if !threat:IsVisibleRecently() then
	
		return false
		
	end
	
	-- If the threat can't hurt the bot, they aren't an immediate threat
	local trace = {}
	util.TraceLine( { start = self:GetShootPos(), endpos = threat:GetEntity():WorldSpaceCenter(), filter = self, mask = MASK_SHOT, output = trace } )
	if trace.Hit and trace.Entity != threat:GetEntity() then
	
		return false
		
	end
	
	local to = self:GetPos() - threat:GetLastKnownPosition()
	local threatRange = to:Length()
	to:Normalize()
	
	local nearbyRange = 500
	if threatRange < nearbyRange then
	
		-- Very near threats are always immediately dangerous
		return true
		
	end
	
	if self:IsThreatFiringAtMe( threat:GetEntity() ) then
	
		-- Distant threat firing on me - an immediate threat whether in my FOV or not
		return true
		
	end
	
	return false
	
end

function BOT:SelectCloserThreat( threat1, threat2 )

	local range1 = self:GetPos():DistToSqr( threat1:GetEntity():GetPos() )
	local range2 = self:GetPos():DistToSqr( threat2:GetEntity():GetPos() )
	
	if range1 < range2 then
	
		return threat1
		
	end
	
	return threat2
	
end

function BOT:SelectMoreDangerousThreat( threat1, threat2 )

	if !threat1 or threat1:IsObsolete() then
	
		if threat2 and !threat2:IsObsolete() then
		
			return threat2
			
		end
		
		return nil
		
	elseif !threat2 or threat2:IsObsolete() then
	
		return threat1
		
	end
	
	local closerThreat = self:SelectCloserThreat( threat1, threat2 )
	
	local botWeapon = self:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon == self.Melee then
	
		-- If the bot is using a melee weapon, they should pick the closest enemy!
		return closerThreat
		
	end
	
	local isImmediateThreat1 = self:IsImmediateThreat( threat1 )
	local isImmediateThreat2 = self:IsImmediateThreat( threat2 )
	
	if isImmediateThreat1 and !isImmediateThreat2 then
	
		return threat1
		
	elseif !isImmediateThreat1 and isImmediateThreat2 then
	
		return threat2
		
	elseif !isImmediateThreat1 and !isImmediateThreat2 then
	
		-- Neither threat is extremely dangerous - use closest
		return closerThreat
		
	end
	
	-- Both threats are immediately dangerous!
	-- Check if any are extremely dangerous
	
	-- Choose most recent attacker (assume an enemy firing their weapon at us has attacked us)
	if self:IsThreatFiringAtMe( threat1:GetEntity() ) then
	
		if self:IsThreatFiringAtMe( threat2:GetEntity() ) then
		
			-- Choose closest
			return closerThreat
			
		end
		
		return threat1
		
	elseif self:IsThreatFiringAtMe( threat2:GetEntity() ) then
	
		return threat2
		
	end
	
	-- Choose closest
	return closerThreat
	
end

function BOT:GetClosestKnown()

	local myPos = self:GetPos()
	local target = nil
	local closeRange = 1000000000000
	
	for k, known in ipairs( self.EnemyList ) do
	
		if !known:IsObsolete() and self:IsAwareOf( known ) then
		
			local rangeSq = known:GetLastKnownPosition():DistToSqr( myPos )
			
			if rangeSq < closeRange then
			
				target = known
				closeRange = rangeSq
				
			end
			
		end
		
	end
	
	return target
	
end

function BOT:GetKnown( entity )

	if !IsValid( entity ) then
	
		return nil
		
	end
	
	for k, known in ipairs( self.EnemyList ) do
	
		if IsValid( known:GetEntity() ) and known:GetEntity() == entity and !known:IsObsolete() then
		
			return known
			
		end
		
	end
	
end

function BOT:AddKnownEntity( entity )

	if !IsValid( entity ) or entity:IsWorld() then
	
		return
		
	end
	
	local known = TBotKnownEntity( entity )
	
	for k, known2 in ipairs( self.EnemyList ) do
	
		if istbotknownentity( known2 ) and known == known2 then
		
			return known2
			
		end
		
	end
	
	table.insert( self.EnemyList, known )
	return known
	
end

function BOT:ForgetEntity( forgetMe )

	if !IsValid( forgetMe ) then
	
		return
		
	end
	
	for k, known in ipairs( self.EnemyList ) do
	
		if IsValid( known:GetEntity() ) and known:GetEntity() == forgetMe then
		
			table.remove( self.EnemyList, k )
			return
			
		end
		
	end
	
end

function BOT:ForgetAllKnownEntities()

	self.EnemyList = {}
	
end

function BOT:GetKnownCount( team, onlyVisible, rangeLimit )

	local count = 0
	
	for k, known in ipairs( self.EnemyList ) do
	
		if !known:IsObsolete() and self:IsAwareOf( known ) and self:IsEnemy( known:GetEntity() ) then
		
			if !isnumber( team ) or !known:GetEntity():IsPlayer() or known:GetEntity():Team() == team then
			
				if !onlyVisible or known:IsVisibleRecently() then
				
					if rangeLimit < 0.0 or ( known:GetLastKnownPosition() - self:GetPos() ):IsLengthLessThan( rangeLimit ) then
					
						count = count + 1
						
					end
					
				end
				
			end
			
		end
		
	end
	
	return count
	
end

-- Returns whether the value is in given table,
-- but made to search through sequential tables instead
function table.HasValueSequential( t, val )

	for k, v in ipairs( t ) do
	
		if v == val then return true end
		
	end
	
	return false
	
end

function BOT:IsIgnored( subject )
	if !IsValid( subject ) then return true end

	if !self:IsEnemy( subject ) then
	
		-- don't ignore our friends
		return false
		
	end
	
	return false
	
end

function BOT:IsVisibleEntityNoticed( subject )

	if IsValid( subject ) and self:IsEnemy( subject ) then
	
		return true
		
	end

	return true

end

function BOT:UpdateKnownEntities()

	local visibleNow = {}
	local visibleNow2 = {}
	for k, pit in ipairs( ents.GetAll() ) do
	
		if IsValid( pit ) and pit != self then 
		
			if self.AttackList[ pit ] or ( pit:IsNPC() and pit:IsAlive() ) or ( pit:IsPlayer() and pit:Alive() ) or ( pit:IsNextBot() and pit:Health() > 0 ) then
				
				if !self:IsIgnored( pit ) and self:IsEnemy( pit ) and self:IsAbleToSee( pit, true ) then
				
					table.insert( visibleNow, pit )
					visibleNow2[ pit ] = true
					
				end
				
			end
			
		end
		
	end
	
	local i = 1
	while i <= #self.EnemyList do
	
		local known = self.EnemyList[ i ]
	
		if !IsValid( known:GetEntity() ) or known:IsObsolete() then
		
			table.remove( self.EnemyList, i )
			continue
			
		end
		
		-- NOTE: Valve reiterates through the list to check IsAbleToSee.....
		-- I choose to create both a table and a list so I don't have to do that. :)
		if tobool( visibleNow2[ known:GetEntity() ] ) then
		
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			
			-- Has our reaction time just elapsed?
			if CurTime() - known:GetTimeWhenBecameVisible() >= self:GetMinRecognizeTime() and self.LastVisionUpdateTimestamp - known:GetTimeWhenBecameVisible() < self:GetMinRecognizeTime() then
			
				self:OnSight( known:GetEntity() )
				
			end
			
		else
		
			if known:IsVisibleInFOVNow() then
			
				known:UpdateVisibilityStatus( false )
				self:OnLostSight( known:GetEntity() )
				
			end
			
			if !known:HasLastKnownPositionBeenSeen() then
			
				if self:IsAbleToSee( known:GetLastKnownPosition(), true ) then
				
					known:MarkLastKnownPositionAsSeen()
					
				end
				
			end
			
		end
		
		i = i + 1
		
	end
	
	i = 1
	while i <= #visibleNow do
	
		local j = 1
		while j <= #self.EnemyList do
		
			if visibleNow[ i ] == self.EnemyList[ j ]:GetEntity() then
			
				break
				
			end
			
			j = j + 1
			
		end
		
		if j > #self.EnemyList then
		
			local known = TBotKnownEntity( visibleNow[ i ] )
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			table.insert( self.EnemyList, known )
			
		end
		
		i = i + 1
		
	end
	
end

-- Heal any player or bot that is visible to us.
function BOT:TBotFindHealTarget()
	if ( ( engine.TickCount() + self:EntIndex() ) % 5 ) != 0 then return self.HealTarget end -- This shouldn't run as often
	
	local targetdistsqr			=	6400 -- This will allow the bot to select the closest teammate to it.
	local target				=	nil -- This is the closest teammate to the bot.
	
	--The bot should heal its owner and itself before it heals anyone else
	if IsValid( self.TBotOwner ) and self.TBotOwner:Alive() and self.TBotOwner:Health() < self.HealThreshold and self.TBotOwner:GetPos():DistToSqr( self:GetPos() ) < 6400 then return self.TBotOwner
	elseif self:Health() < self.HealThreshold then return self end

	for i = 1, game.MaxPlayers() do
	
		local ply = Entity( i )
		
		if IsValid( ply ) and ply:Alive() and ply:Health() < self.HealThreshold and self:IsAbleToSee( ply ) then -- The bot will heal any teammate that needs healing that we can actually see and are alive.
			
			local teammatedistsqr = ply:GetPos():DistToSqr( self:GetPos() )
			
			if teammatedistsqr < targetdistsqr then 
				target = ply
				targetdist = teammatedist
			end
		end
	end
	
	return target
	
end

-- Revive any player or bot that is visible to us.
function BOT:TBotFindReviveTarget()
	if ( ( engine.TickCount() + self:EntIndex() ) % 5 ) != 0 then return self.ReviveTarget end -- This shouldn't run as often
	if !isfunction( self.IsDowned ) or self:IsDowned() then return end -- This shouldn't run if the revive mod isn't installed or the bot is downed.
	
	local targetdistsqr			=	1000000000000 -- This will allow the bot to select the closest teammate to it.
	local target				=	nil -- This is the closest teammate to the bot.
	
	--The bot should revive its owner before it revives anyone else
	if IsValid( self.TBotOwner ) and self.TBotOwner:Alive() and self.TBotOwner:IsDowned() then return self.TBotOwner end

	for i = 1, game.MaxPlayers() do
	
		local ply = Entity( i )
		
		if IsValid( ply ) and ply != self and ply:Alive() and ply:IsDowned() then -- The bot will revive any teammate than need to be revived.
			
			local teammatedistsqr = ply:GetPos():DistToSqr( self:GetPos() )
			
			if teammatedistsqr < targetdistsqr then 
				target = ply
				targetdist = teammatedist
			end
		end
	end
	
	return target
	
end

function BOT:FindNearbySeat()
	if ( ( engine.TickCount() + self:EntIndex() ) % 5 ) != 0 then return end -- This shouldn't run as often
	
	local targetdistsqr			=	40000 -- This will allow the bot to select the closest vehicle to it.
	local target				=	nil -- This is the closest vehicle to the bot.
	
	for k, v in ipairs( ents.GetAll() ) do
		
		if IsValid( v ) and v:IsVehicle() and !IsValid( v:GetDriver() ) then -- The bot should enter the closest vehicle to it
			
			local vehicledistsqr = v:GetPos():DistToSqr( self:GetPos() )
			
			if vehicledistsqr < targetdistsqr then 
				target = v
				targetdistsqr = vehicledistsqr
			end
			
		end
		
	end
	
	return target
	
end

function BOT:DoorCheck()
	if !self:IsPathValid() then return end
	if ( ( engine.TickCount() + self:EntIndex() ) % 5 ) != 0 then return end -- This shouldn't run as often

	-- I will adjust this if any issues occur from it.
	local halfWidth = self:GetHullWidth() / 2.0
	for k, door in ipairs( ents.FindAlongRay( self:GetPos(), self.Goal.Pos, Vector( -halfWidth, -halfWidth, -halfWidth ), Vector( halfWidth, halfWidth, self:GetStandHullHeight() / 2.0 ) ) ) do
	
		if IsValid( door ) and door:IsDoor() and !door:IsDoorLocked() and !door:IsDoorOpen() and door:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) <= 10000 then
		
			self.Door = door
			break
			
		end
		
	end
	
end

function BOT:BreakableCheck()
	if !self:IsPathValid() then return end
	if ( ( engine.TickCount() + self:EntIndex() ) % 5 ) != 0 then return end -- This shouldn't run as often

	-- This could be unreliable in certain situations
	-- Used to use ents.FindInSphere( self:GetPos(), 30 )
	local halfWidth = self:GetHullWidth() / 2.0
	for k, breakable in ipairs( ents.FindAlongRay( self:GetPos(), self.Goal.Pos, Vector( -halfWidth, -halfWidth, -halfWidth ), Vector( halfWidth, halfWidth, self:GetStandHullHeight() / 2.0 ) ) ) do
	
		if IsValid( breakable ) and breakable:IsBreakable() and breakable:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) <= 6400 and self:IsAbleToSee( breakable ) then 
		
			self.Breakable = breakable
			break
			
		end
	
	end
	
end

function TRizzleBotRangeCheck( area , fromArea , ladder , bot , length )
	
	if !IsValid( fromArea ) then
	
		-- first area in path, no cost
		return 0
		
	elseif fromArea:HasAttributes( NAV_MESH_JUMP ) and area:HasAttributes( NAV_MESH_JUMP ) then
	
		-- cannot actually walk in jump areas - disallow moving from jump area to jump area
		return -1.0
	
	else
	
		-- compute distance traveled along path so far
		local dist = 0
		
		if IsValid( ladder ) then 
		
			dist = ladder:GetLength()
			
		elseif isnumber( length ) and length > 0 then
		
			-- optimization to avoid recomputing lengths
			dist = length
		
		else
		
			dist = area:GetCenter():Distance( fromArea:GetCenter() )
			
		end
		
		local Height	=	fromArea:ComputeAdjacentConnectionHeightChange( area )
		local stepHeight = Either( IsValid( bot ), bot:GetStepSize(), 18 )
		-- Jumping is slower than ground movement.
		if !IsValid( ladder ) and !fromArea:IsUnderwater() and Height > stepHeight then
			
			local maximumJumpHeight = Either( IsValid( bot ), bot:GetMaxJumpHeight(), 64 )
			if Height > maximumJumpHeight then
			
				return -1
			
			end
			
			--print( "Jump Height: " .. Height )
			dist	=	dist + ( dist * 2 )
			
		-- Falling is risky if the bot might take fall damage.
		elseif !area:IsUnderwater() and Height < -stepHeight then
			
			local fallDistance = -fromArea:ComputeGroundHeightChange( area )
			
			if IsValid( ladder ) and ladder:GetBottom().z < fromArea:GetCenter().z and ladder:GetBottom().z > area:GetCenter().z then
			
				fallDistance = ladder:GetBottom().z - area:GetCenter().z
				
			end
			
			--print( "Drop Height: " .. Height )
			local fallDamage = GetApproximateFallDamage( fallDistance )
			
			if fallDamage > 0.0 and IsValid( bot ) then
			
				-- if the fall would kill us, don't use it
				local deathFallMargin = 10.0
				if fallDamage + deathFallMargin >= bot:Health() then
				
					return -1.0
					
				end
				
				local painTolerance = 25.0
				if bot:IsUnhealthy() or fallDamage > painTolerance then
				
					-- cost is proportional to how much it hurts when we fall
					-- 10 points - not a big deal, 50 points - ouch
					dist	=	dist + ( 100 * fallDamage * fallDamage )
					
				end
			
			end
			
		end
		
		local preference = 1.0
		
		-- This isn't really needed for sandbox, but since this is a bot base I will leave this here.
		-- This will have certain cases where its not used.
		-- NOTE: If TBotRandomPaths is nonzero the bot will use this when pathfinding
		if TBotRandomPaths:GetBool() then
		
			-- this term causes the same bot to choose different routes over time,
			-- but keep the same route for a period in case of repaths
			local timeMod = math.floor( ( CurTime() / 10 ) + 1 )
			preference = 1.0 + 50.0 * ( 1.0 + math.cos( bot:EntIndex() * area:GetID() * timeMod ) )
			
		end
		
		-- Crawling through a vent is very slow.
		-- NOTE: The cost is determined by the bot's crouch speed
		if area:HasAttributes( NAV_MESH_CROUCH ) then 
			
			local crouchPenalty = Either( IsValid( bot ), math.floor( 1 / bot:GetCrouchedWalkSpeed() ), 5 )
			
			dist	=	dist + ( dist * crouchPenalty )
			
		end
		
		-- The bot should avoid this area unless alternatives are too dangerous or too far.
		if area:HasAttributes( NAV_MESH_AVOID ) then 
			
			dist	=	dist + ( dist * 20 )
			
		end
		
		-- We will try not to swim since it can be slower than running on land, it can also be very dangerous, Ex. "Acid, Lava, Etc."
		if area:IsUnderwater() then
		
			dist	=	dist + ( dist * 2 )
			
		end
		
		local cost	=	dist * preference
		
		--print( "Distance: " .. dist )
		--print( "Total Cost: " .. cost )
		
		return cost + fromArea:GetCostSoFar()
		
	end
	
end

function TRizzleBotRangeCheckRetreat( area , fromArea , ladder , bot , length , threat )
	
	local maxThreatRange = 500.0
	local dangerDensity = 1000.0
	
	if area:IsBlocked() then
	
		return -1.0
		
	end
	
	if !IsValid( fromArea ) then
	
		if IsValid( threat ) then
			
			if area:Contains( threat:GetPos() ) then
				
				return dangerDensity * 10
				
			else
				
				local rangeToThreat = threat:GetPos():Distance( bot:GetPos() )

				if rangeToThreat < maxThreatRange then
					
					return dangerDensity * ( 1.0 - ( rangeToThreat / maxThreatRange ) )
					
				end
				
			end
			
		end
	
		-- first area in path, no cost
		return 0
		
	elseif fromArea:HasAttributes( NAV_MESH_JUMP ) and area:HasAttributes( NAV_MESH_JUMP ) then
	
		-- cannot actually walk in jump areas - disallow moving from jump area to jump area
		return -1.0
	
	else
	
		-- compute distance traveled along path so far
		local dist = 0
		
		if IsValid( ladder ) then 
		
			dist = ladder:GetLength()
			
		elseif isnumber( length ) and length > 0 then
		
			-- optimization to avoid recomputing lengths
			dist = length
		
		else
		
			dist = area:GetCenter():Distance( fromArea:GetCenter() )
			
		end
		
		local Height	=	fromArea:ComputeAdjacentConnectionHeightChange( area )
		local stepHeight = Either( IsValid( bot ), bot:GetStepSize(), 18 )
		-- Jumping is slower than ground movement.
		if !IsValid( ladder ) and !fromArea:IsUnderwater() and Height > stepHeight then
			
			local maximumJumpHeight = Either( IsValid( bot ), bot:GetMaxJumpHeight(), 64 )
			if Height > maximumJumpHeight then
			
				return -1
			
			end
			
			--print( "Jump Height: " .. Height )
			dist	=	dist + ( dist * 2 )
			
		-- Falling is risky if the bot might take fall damage.
		elseif !area:IsUnderwater() and Height < -stepHeight then
			
			local fallDistance = -fromArea:ComputeGroundHeightChange( area )
			
			if IsValid( ladder ) and ladder:GetBottom().z < fromArea:GetCenter().z and ladder:GetBottom().z > area:GetCenter().z then
			
				fallDistance = ladder:GetBottom().z - area:GetCenter().z
				
			end
			
			--print( "Drop Height: " .. Height )
			local fallDamage = GetApproximateFallDamage( fallDistance )
			
			if fallDamage > 0.0 and IsValid( bot ) then
			
				-- if the fall would kill us, don't use it
				local deathFallMargin = 10.0
				if fallDamage + deathFallMargin >= bot:Health() then
				
					return -1.0
					
				end
				
				local painTolerance = 25.0
				if bot:IsUnhealthy() or fallDamage > painTolerance then
				
					-- cost is proportional to how much it hurts when we fall
					-- 10 points - not a big deal, 50 points - ouch
					dist	=	dist + ( 100 * fallDamage * fallDamage )
					
				end
			
			end
			
		end
		
		-- Add in danger cost due to threat
		-- Assume straight line between areas and find closest point
		-- to the threat along that line segment. The distance between
		-- the threat and closest point on the line is the danger cost.	
		
		if IsValid( threat ) then
		
			local t, Close = CalcClosestPointOnLineSegment( threat:GetPos(), area:GetCenter(), fromArea:GetCenter() )
			if t < 0.0 then
				
				Close = area:GetCenter()
				
			elseif t > 1.0 then
				
				Close = fromArea:GetCenter()
				
			end
			
			local rangeToThreat = threat:GetPos():Distance( Close )
			if rangeToThreat < maxThreatRange then
				
				local dangerFactor = 1.0 - ( rangeToThreat / maxThreatRange )
				dist	=	dist * ( dangerDensity * dangerFactor )
				
			end
			
		end
		
		-- Crawling through a vent is very slow.
		-- NOTE: The cost is determined by the bot's crouch speed
		if area:HasAttributes( NAV_MESH_CROUCH ) then 
			
			local crouchPenalty = Either( IsValid( bot ), math.floor( 1 / bot:GetCrouchedWalkSpeed() ), 5 )
			
			dist	=	dist + ( dist * crouchPenalty )
			
		end
		
		-- The bot should avoid this area unless alternatives are too dangerous or too far.
		if area:HasAttributes( NAV_MESH_AVOID ) then 
			
			dist	=	dist + ( dist * 20 )
			
		end
		
		-- We will try not to swim since it can be slower than running on land, it can also be very dangerous, Ex. "Acid, Lava, Etc."
		if area:IsUnderwater() then
		
			dist	=	dist + ( dist * 2 )
			
		end
		
		--print( "Distance: " .. dist )
		
		return dist + fromArea:GetCostSoFar()
		
	end
	
end

local mp_falldamage = GetConVar( "mp_falldamage" )
-- Got this from CS:GO Source Code, made some changes so it works for Lua
-- Returns approximately how much damage will will take from the given fall height
function GetApproximateFallDamage( height )
	
	-- CS:GO empirically discovered height values, this may return incorrect results for Gmod
	-- I made some changes based on some experiments, but they may not be accurate
	-- slope was 0.2178 and intercept was 26.0
	local slope = 0.2500
	local intercept = 60.0

	local damage = slope * height - intercept

	if damage <= 0.0 then
		return 0.0
	end
	
	if mp_falldamage:GetBool() then
		return damage
	end

	return 10.0
end

-- This is a hybrid version of pathfollower, it can use ladders and is very optimized
function TRizzleBotPathfinderCheap( bot, goal )
	
	bot:TBotClearPath()
	local NUM_TRAVERSE_TYPES = 9
	local start = bot:GetPos()
	local startArea = bot:GetLastKnownArea()
	if !IsValid( startArea ) then
	
		bot.Goal = bot:FirstSegment()
		return false
		
	end
	
	local maxDistanceToArea = 200
	local goalArea = navmesh.GetNearestNavArea( goal, true, maxDistanceToArea, true )
	
	if startArea == goalArea then
	
		BuildTrivialPath( bot, goal )
		return true
		
	end
	
	local pathEndPosition = Vector( goal )
	if IsValid( goalArea ) then
	
		pathEndPosition.z = goalArea:GetZ( pathEndPosition )
		
	else
		
		local ground = navmesh.GetGroundHeight( pathEndPosition )
		if ground then pathEndPosition.z = ground end
		
	end
	
	local pathResult, closestArea = NavAreaBuildPath( startArea, goalArea, Vector( goal ), bot )
	
	-- Failed?
	if !IsValid( closestArea ) then
	
		return false
		
	end
	
	--
	-- Build actual path by following parent links back from goal area
	--
	
	-- get count
	local count = 0
	local area = closestArea
	while IsValid( area ) do
	
		count = count + 1
		
		if area == startArea then
		
			-- startArea can be re-evaluated during the pathfind and given a parent
			break
			
		end
		
		area = area:GetParent()
		
	end
	
	if count == 0 then
	
		return false
		
	end
	
	if count == 1 then
	
		BuildTrivialPath( bot, goal )
		return pathResult
		
	end
	
	-- assemble path
	bot.SegmentCount = count
	area = closestArea
	while IsValid( area ) and count > 0 do
	
		bot.Path[ count ] = {}
		bot.Path[ count ].Area = area
		bot.Path[ count ].How = area:GetParentHow()
		bot.Path[ count ].Type = PATH_ON_GROUND
		
		area = area:GetParent()
		count = count - 1
		
	end
	
	-- append actual goal position
	bot.SegmentCount = bot.SegmentCount + 1
	bot.Path[ bot.SegmentCount ] = {}
	bot.Path[ bot.SegmentCount ].Area = closestArea
	bot.Path[ bot.SegmentCount ].Pos = pathEndPosition
	bot.Path[ bot.SegmentCount ].How = NUM_TRAVERSE_TYPES
	bot.Path[ bot.SegmentCount ].Type = PATH_ON_GROUND
	
	--[[for k,v in ipairs( bot.Path ) do
	
		if v.Area == startArea then
		
			print( "StartArea at " .. tostring( k ) )
		
		elseif v.Area == closestArea then
		
			print( "EndArea at " .. tostring( k ) )
			
		end
		
	end
	
	print( "SegmentCount: " .. tostring( bot.SegmentCount ) )
	print( "Bot Path Length: " .. tostring( #bot.Path ) )]]
	
	-- compute path positions
	if bot:ComputeNavmeshVisibility() == false then
	
		bot:TBotClearPath()
		bot.Goal = bot:FirstSegment()
		return false
		
	end
	
	PostProccess( bot )
	
	bot.Goal = bot:FirstSegment()
	
	return pathResult
	
end

-- This creates a path to chase the selected subject!
function TRizzleBotPathfinderChase( bot, subject )
	if !IsValid( bot ) or !IsValid( subject ) then return false end
	
	local pathTarget = TRizzleBotPredictSubjectPosition( bot, subject )
	return TRizzleBotPathfinderCheap( bot, pathTarget )

end

-- This creates a path to flee from the selected threat!
function TRizzleBotPathfinderRetreat( bot, threat )
	if !IsValid( bot ) or !IsValid( threat ) then return false end

	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	
	local LADDER_UP = 0
	local LADDER_DOWN = 1

	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5

	local startArea = bot:GetLastKnownArea()
	if !IsValid( startArea ) then
	
		return false
		
	end
	
	local retreatFromArea = navmesh.GetNearestNavArea( threat:GetPos() )
	if !IsValid( retreatFromArea ) then
	
		return false
		
	end
	
	startArea:SetParent( nil, 9 )
	
	startArea:ClearSearchLists()
	
	local initCost = TRizzleBotRangeCheckRetreat( startArea, nil, nil, bot, nil, threat )
	if initCost < 0.0 then
	
		return false
		
	end
	
	startArea:SetTotalCost( initCost )
	
	startArea:AddToOpenList()
	
	-- Keep track of farthest away from the threat
	local farthestArea = nil
	local farthestRange = 0.0
	
	--
	-- Dijkstra's algorithm (since we don't know our goal).
	-- Build a path as far away from the retreat area as possible.
	-- Minimize total path length and danger.
	-- Maximize distance to threat of end of path.
	--
	while !startArea:IsOpenListEmpty() do
	
		local area = startArea:PopOpenList()
		
		area:AddToClosedList()
		
		--- don't consider blocked areas
		if area:IsBlocked() then
		
			continue
			
		end
		
		local adjacentAreas = {}
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( NORTH ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = NORTH, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( SOUTH ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = SOUTH, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( WEST ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = WEST, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( EAST ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = EAST, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetLaddersAtSide( LADDER_UP ) ) do
		
			local index = #adjacentAreas
			if IsValid( it:GetTopForwardArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopForwardArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
			if IsValid( it:GetTopLeftArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopLeftArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
			if IsValid( it:GetTopRightArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopRightArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
			if IsValid( it:GetTopBehindArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopBehindArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
		end
		
		for k, it in ipairs( area:GetLaddersAtSide( LADDER_DOWN ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			if IsValid( it:GetBottomArea() ) then
			
				table.insert( adjacentAreas, { area = it:GetBottomArea(), how = GO_LADDER_DOWN, ladder = it } )
				
			end
			
		end
		
		for i = 1, #adjacentAreas do
		
			local newArea = adjacentAreas[ i ].area
		
			-- only visit each area once
			if newArea:IsClosed() then
			
				continue
				
			end
			
			-- don't consider blocked areas
			if newArea:IsBlocked() then
			
				continue
				
			end
			
			-- don't use this area if it is out of range
			if ( newArea:GetCenter() - bot:GetPos() ):IsLengthGreaterThan( 1000 ) then
			
				continue
				
			end
			
			-- determine cost of traversing this area
			local newCost = TRizzleBotRangeCheckRetreat( newArea, area, adjacentAreas[ i ].ladder, bot, nil, threat )
			
			-- don't use adjacent area if cost functor says it is a dead end
			if newCost < 0.0 then
			
				continue
				
			end
			
			if newArea:IsOpen() and newArea:GetTotalCost() <= newCost then
			
				-- we have already visited this area, and it has a better path
				continue
				
			else
			
				-- whether this area has been visited ot not, we now have a better path
				newArea:SetParent( area, adjacentAreas[ i ].how )
				newArea:SetTotalCost( newCost )
				
				-- use 'cost so far' to hold cumulative cost
				newArea:SetCostSoFar( newCost )
				
				-- tricky bit here - relying on OpenList being sorted by cost
				if newArea:IsOpen() then
				
					-- area already on open list, update the list to keep costs sorted
					newArea:UpdateOnOpenList()
					
				else
				
					newArea:AddToOpenList()
					
				end
				
				-- keep track of area farthest from threat
				local threatRange = newArea:GetCenter():Distance( threat:GetPos() )
				if threatRange > farthestRange then
				
					farthestArea = newArea
					farthestRange = threatRange
					
				end
				
			end
			
		end
		
	end
	
	if IsValid( farthestArea ) then
	
		TRizzleBotAssembleRetreatPath( bot, farthestArea:GetCenter(), farthestArea )
		return true
		
	end
	
	return false

end

-- INTERNAL: This is used internaly by TRizzleBotPathfinderRetreat, don't go complaning about having issues
-- with it if you use this function for other things!
function TRizzleBotAssembleRetreatPath( bot, goal, endArea )

	local start = bot:GetPos()
	local NUM_TRAVERSE_TYPES = 9
	
	-- get count
	local count = 0
	local area = endArea
	while IsValid( area ) do
	
		count = count + 1
		
		area = area:GetParent()
		
	end
	
	if count == 0 then
	
		return false
		
	end
	
	if count == 1 then
	
		BuildTrivialPath( bot, goal )
		return true
		
	end
	
	-- assemble path
	bot.SegmentCount = count
	area = endArea
	while IsValid( area ) and count > 0 do
	
		bot.Path[ count ] = {}
		bot.Path[ count ].Area = area
		bot.Path[ count ].How = area:GetParentHow()
		bot.Path[ count ].Type = PATH_ON_GROUND
		
		area = area:GetParent()
		count = count - 1
		
	end
	
	-- append actual goal position
	bot.SegmentCount = bot.SegmentCount + 1
	bot.Path[ bot.SegmentCount ] = {}
	bot.Path[ bot.SegmentCount ].Area = endArea
	bot.Path[ bot.SegmentCount ].Pos = goal
	bot.Path[ bot.SegmentCount ].How = NUM_TRAVERSE_TYPES
	bot.Path[ bot.SegmentCount ].Type = PATH_ON_GROUND
	
	--[[for k,v in ipairs( bot.Path ) do
	
		if v.Area == startArea then
		
			print( "StartArea at " .. tostring( k ) )
		
		elseif v.Area == closestArea then
		
			print( "EndArea at " .. tostring( k ) )
			
		end
		
	end
	
	print( "SegmentCount: " .. tostring( bot.SegmentCount ) )
	print( "Bot Path Length: " .. tostring( #bot.Path ) )]]
	
	-- compute path positions
	if bot:ComputeNavmeshVisibility() == false then
	
		bot:TBotClearPath()
		bot.Goal = bot:FirstSegment()
		return false
		
	end
	
	PostProccess( bot )
	
	bot.Goal = bot:FirstSegment()
	
	return true
	
end

-- This is used by TRizzleBotPathfinderChase to predict where the subject is moving to cut them off.
function TRizzleBotPredictSubjectPosition( bot, subject )

	local subjectPos = subject:GetPos()
	
	local to = subjectPos - bot:GetPos()
	to.z = 0.0
	local flRangeSq = to:LengthSqr()
	
	-- The bot shouldn't attempt to cut off their target if they are too far away!
	if flRangeSq > 500^2 then
	
		return subjectPos
		
	end
	
	local range = math.sqrt( flRangeSq )
	to = to / ( range + 0.0001 ) -- Avoid divide by zero
	
	-- Estimate time to reach subject, assuming maximum speed for now.....
	local leadTime = 0.5 + ( range / ( bot:GetRunSpeed() + 0.0001 ) )
	
	-- Estimate amount to lead the subject
	local leader = leadTime * subject:GetVelocity()
	lead.z = 0.0
	
	if to:Dot( lead ) < 0.0 then
	
		-- The subject is moving towards us - only pay attention
		-- to his perpendicular velocity for leading
		local to2D = to:AsVector2D()
		to2D:Normalize()
		
		local perp = Vector( -to2D.y, to2D.x )
		
		local enemyGroundSpeed = lead.x * perp.x + lead.y * perp.y
		
		lead.x = enemyGroundSpeed * perp.x
		lead.y = enemyGroundSpeed * perp.y
		
	end
	
	-- Computer our desired destination
	local pathTarget = subjectPos + lead
	
	-- Validate this destination
	
	-- Don't lead through walls
	if lead:LengthSqr() > 36.0 then
	
		local isTraversable, fraction = bot:IsPotentiallyTraversable( subjectPos, pathTarget )
		if !isTraversable then
		
			-- Tried to lead through an unwalkable area - clip to walkable space
			pathTarget = subjectPos + fraction * ( pathTarget - subjectPos )
			
		end
		
	end
	
	-- Don't lead over cliffs
	local leadArea = navmesh.GetNearestNavArea( pathTarget )
	
	if !IsValid( leadArea ) or leadArea:GetZ( pathTarget ) < pathTarget.z - bot:GetMaxJumpHeight() then
	
		-- Would fall off a cliff
		return subjectPos
		
	end
	
	return pathTarget

end

--[[
Got this from CS:GO Source Code, made some changes so it works for Lua

Find path from startArea to goalArea via an A* search, using supplied cost heuristic.
If cost functor returns -1 for an area, that area is considered a dead end.
This doesn't actually build a path, but the path is defined by following parent
pointers back from goalArea to startArea.
If 'goalArea' is NULL, will compute a path as close as possible to 'goalPos'.
If 'goalPos' is NULL, will use the center of 'goalArea' as the goal position.
If 'maxPathLength' is nonzero, path building will stop when this length is reached.
Returns true if a path exists.	
]]
function NavAreaBuildPath( startArea, goalArea, goalPos, bot, costFunc )
	
	local closestArea = startArea
	
	if !IsValid( startArea ) then
	
		return false, closestArea
		
	end
	
	startArea:SetParent( nil, 9 )
	
	if IsValid( goalArea ) and goalArea:IsBlocked() then
	
		goalArea = nil
		
	end
	
	if !IsValid( goalArea ) and !isvector( goalPos ) then
	
		return false, closestArea
		
	end
	
	if startArea == goalArea then
	
		return true, closestArea
		
	end
	
	local actualGoalPos = goalPos
	if !isvector( goalPos ) then
	
		actualGoalPos = goalArea:GetCenter()
		
	end
	
	startArea:ClearSearchLists()
	
	startArea:SetTotalCost( startArea:GetCenter():Distance( actualGoalPos ) )
	
	local initCost = TRizzleBotRangeCheck( startArea, nil, nil, bot )
	if initCost < 0.0 then
	
		return false, closestArea
		
	end
	
	startArea:SetCostSoFar( initCost )
	
	startArea:AddToOpenList()
	
	local closestAreaDist = startArea:GetTotalCost()
	
	startArea:UpdateOnOpenList()
	
	while !startArea:IsOpenListEmpty() do
		
		local Current	=	startArea:PopOpenList()
		
		if Current:IsBlocked() then
			
			continue
			
		end
		
		if Current == goalArea or ( !IsValid( goalArea ) and isvector( goalPos ) and Current:Contains( goalPos ) ) then
			
			closestArea = Current
			
			return true, closestArea
			
		end
		
		local searchWhere = 0
		
		local NORTH = 0
		local EAST = 1
		local SOUTH = 2
		local WEST = 3
		local NUM_DIRECTIONS = 4
		
		local AHEAD = 0
		local LEFT = 1
		local RIGHT = 2
		local BEHIND = 3
		
		local LADDER_UP = 0
		local LADDER_DOWN = 1
		
		local GO_LADDER_UP = 4
		local GO_LADDER_DOWN = 5
		
		local searchIndex = 1
		local dir = NORTH
		local ladderUp = true
		
		local floorList = Current:GetAdjacentAreasAtSide( NORTH )
		local ladderList = nil
		local ladderTopDir = 0
		local length = -1.0
		
		while ( true ) do
		
			local newArea = nil
			local how = nil
			local ladder = nil
		
			if searchWhere == 0 then
			
				if searchIndex > #floorList then
				
					dir = dir + 1
					
					if dir == NUM_DIRECTIONS then
					
						searchWhere = 1
						ladderList = Current:GetLaddersAtSide( LADDER_UP )
						searchIndex = 1
						ladderTopDir = AHEAD
						
					else
					
						floorList = Current:GetAdjacentAreasAtSide( dir )
						searchIndex = 1
						
					end
					
					continue
					
				end
				
				newArea = floorList[ searchIndex ]
				how = dir
				searchIndex = searchIndex + 1
				
			elseif searchWhere == 1 then
			
				if searchIndex > #ladderList then
					
					if !ladderUp then
						
						searchWhere = 2
						searchIndex = 1
						ladder = nil
						
					else
						
						ladderUp = false
						ladderList = Current:GetLaddersAtSide( LADDER_DOWN )
						searchIndex = 1
						
					end
					
					continue
					
				end
				
				if ladderUp then
				
					ladder = ladderList[ searchIndex ]
				
					if ladderTopDir == AHEAD then
					
						newArea = ladder:GetTopForwardArea()
						
					elseif ladderTopDir == LEFT then
					
						newArea = ladder:GetTopLeftArea()
						
					elseif ladderTopDir == RIGHT then
					
						newArea = ladder:GetTopRightArea()
						
					elseif ladderTopDir == BEHIND then
					
						newArea = ladder:GetTopBehindArea()
						
					else
					
						searchIndex = searchIndex + 1
						ladderTopDir = AHEAD
						continue
						
					end
					
					how = GO_LADDER_UP
					ladderTopDir = ladderTopDir + 1
				
				else
				
					ladder = ladderList[ searchIndex ]
					newArea = ladder:GetBottomArea()
					how = GO_LADDER_DOWN
					searchIndex = searchIndex + 1
					
				end
				
				if !IsValid( newArea ) then
				
					continue
					
				end
			
			else
			
				break
				
			end
		
			-- don't backtrack
			if newArea == Current:GetParent() then
			
				continue
				
			end
			
			-- self neighbor?
			if newArea == Current then
			
				continue
				
			end
			
			-- don't consider blocked areas
			if newArea:IsBlocked() then
			
				continue
				
			end
			
			local NewCostSoFar		=	TRizzleBotRangeCheck( newArea , Current , ladder , bot , length )
			
			-- inf really mess up this function up causing tough to track down hangs. If
			--  we get inf back, clamp it down to a really high number.
			if NewCostSoFar == math.huge then
			
				NewCostSoFar = 2^1023
				
			end
			
			-- check if the cost functor says this area is a dead-end
			if NewCostSoFar < 0 then
				
				continue
				
			end
			
			-- Safety check against a bogus functor. The cost of the path
			-- A...B, C should always be at least as big as the path A...B
			assert( NewCostSoFar >= Current:GetCostSoFar() )
			
			-- And now that we've asserted, let's be a bit more defensive.
			-- Make sure that any jump to a new area incurs some pathfinsing
			-- cost, to avoid us spinning our wheels over insignificant cost
			-- benefit, floating point precision bug, or busted cost functor.
			local minNewCostSoFar = Current:GetCostSoFar() * 1.00001 + 0.00001
			NewCostSoFar = math.max( NewCostSoFar, minNewCostSoFar )
			
			if ( newArea:IsOpen() or newArea:IsClosed() ) and newArea:GetCostSoFar() <= NewCostSoFar then
				
				-- this is a worse path - skip it
				continue
				
			else
				
				-- compute estimate of distance left to go 
				local distSq = ( newArea:GetCenter() - actualGoalPos ):LengthSqr()
				local newCostRemaining = Either( distSq > 0.0, math.sqrt( distSq ), 0.0 )
				
				-- track closest area to goal in case path fails
				if newCostRemaining < closestAreaDist then
				
					closestArea = newArea
					closestAreaDist = newCostRemaining
					
				end
				
				newArea:SetCostSoFar( NewCostSoFar )
				newArea:SetTotalCost( NewCostSoFar + newCostRemaining )
				
				if newArea:IsClosed() then
					
					newArea:RemoveFromClosedList()
					
				end
				
				if newArea:IsOpen() then
					
					-- area already on open list, update the list order to keep costs sorted
					newArea:UpdateOnOpenList()
					
				else
					
					newArea:AddToOpenList()
					
				end
				
				
				newArea:SetParent( Current, how )
			end
			
			
		end
		
		-- we have searched this area
		Current:AddToClosedList()
		
	end
	
	return false, closestArea

end

--[[
Got this from CS:GO Source Code, made some changes so it works for Lua

Compute distance between two areas. Return -1 if can't reach 'endArea' from 'startArea'.
]]
function NavAreaTravelDistance( startArea, endArea, bot )

	if !IsValid( startArea ) then
	
		return -1.0
		
	end
	
	if !IsValid( endArea ) then
	
		return -1.0
		
	end
	
	if startArea == endArea then
	
		return 0.0
		
	end
	
	-- compute path between areas using given cost heuristic
	if NavAreaBuildPath( startArea, endArea, nil, bot ) == false then
	
		return -1.0
		
	end
	
	-- compute distance along path
	local distance = 0.0
	local area = endArea
	while IsValid( area:GetParent() ) do
	
		distance = distance + area:GetCenter():Distance( area:GetParent():GetCenter() )
		
		area = area:GetParent()
		
		if area == startArea then
		
			break
			
		end
		
	end
	
	return distance
	
end

function TRizzleBotRetracePathCheap( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	
	local LADDER_UP = 0
	local LADDER_DOWN = 1
	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	local NUM_TRAVERSE_TYPES = 9
	
	local Trys			=	0 -- Backup! Prevent crashing.
	local NewPath	=	{}
	
	local Current	=	GoalNode
	local Parent 	=	GoalNode:GetParentHow()
	local StopLoop	=	false
	
	while ( !StopLoop and Trys < 50001 ) do
		
		if !IsValid( Current ) or Current == StartNode then 
		
			StopLoop = true
			Parent = NUM_TRAVERSE_TYPES
			
		end
		
		--print( Current )
		--print( Parent )
		
		if Parent == GO_LADDER_UP then
		
			local list = Current:GetParent():GetLaddersAtSide( LADDER_UP )
			--print( "Ladders: " .. #list )
			for k, ladder in ipairs( list ) do
				--print( "Top Area: " .. tostring( ladder:GetTopForwardArea() ) )
				--print( "TopLeft Area: " .. tostring( ladder:GetTopLeftArea() ) )
				--print( "TopRight Area: " .. tostring( ladder:GetTopRightArea() ) )
				--print( "TopBehind Area: " .. tostring( ladder:GetTopBehindArea() ) )
				if ladder:GetTopForwardArea() == Current or ladder:GetTopLeftArea() == Current or ladder:GetTopRightArea() == Current or ladder:GetTopBehindArea() == Current then
					
					NewPath[ #NewPath + 1 ] = { Area = Current, How = Parent, Ladder = ladder }
					break
					
				end
			end
			
		elseif Parent == GO_LADDER_DOWN then
		
			local list = Current:GetParent():GetLaddersAtSide( LADDER_DOWN )
			--print( "Ladders: " .. #list )
			for k, ladder in ipairs( list ) do
				--print( "Bottom Area: " .. tostring( ladder:GetBottomArea() ) )
				if ladder:GetBottomArea() == Current then
					
					NewPath[ #NewPath + 1 ] = { Area = Current, How = Parent, Ladder = ladder }
					break
					
				end
			end
		
		else
			
			NewPath[ #NewPath + 1 ] = { Area = Current, How = Parent }
			
		end
		
		Current		=	Current:GetParent()
		if IsValid( Current ) and !StopLoop then Parent		=	Current:GetParentHow() end
		
	end
	
	--NewPath[ #NewPath + 1 ] = { area = StartNode, how = NUM_TRAVERSE_TYPES }
	
	return NewPath
end

-- Deprecated: TRizzleBotPathfinderCheap automatically does this now
--[[function BOT:TBotSetNewGoal( NewGoal )
	if !isvector( NewGoal ) then error( "Bad argument #1 vector expected got " .. type( NewGoal ) ) end
	
	if self.PathTime < CurTime() then
	
		local ground = navmesh.GetGroundHeight( NewGoal )
		if ground then NewGoal.z = ground end
		
		self:TBotClearPath()
		self.Goal 				= 	NewGoal
		self.PathTime			=	CurTime() + 0.5
		self:TBotCreateNavTimer()
	end
	
end]]

function BOT:FirstSegment()

	return Either( self:IsPathValid(), self.Path[ 1 ], nil )
	
end

function BOT:LastSegment()

	return Either( self:IsPathValid(), self.Path[ self.SegmentCount ], nil )
	
end

function BOT:NextSegment( currentSegment )

	if !currentSegment or !self:IsPathValid() then
	
		return nil
		
	end
	
	local i = table.KeyFromValue( self.Path, currentSegment )
	if i < 0 or i > self.SegmentCount then
	
		return nil
		
	end
	
	return self.Path[ i + 1 ]
	
end

function BOT:PriorSegment( currentSegment )

	if !currentSegment or !self:IsPathValid() then
	
		return nil
		
	end
	
	local i = table.KeyFromValue( self.Path, currentSegment )
	if i <= 1 or i > self.SegmentCount then
	
		return nil
		
	end
	
	return self.Path[ i - 1 ]
	
end

function BOT:IsRepathNeeded( subject )
	if !IsValid( subject ) then return false end
	
	-- The closer we get, the more accurate out path needs to be.
	local to = subject:GetPos() - self:GetPos()
	local tolerance = 0.33 * to:Length()
	
	return ( subject:GetPos() - self:LastSegment().Pos ):IsLengthGreaterThan( tolerance )
	
end

function BOT:IsPathValid()

	return self.SegmentCount > 0
	
end

function BOT:TBotClearPath()

	self.Path = {}
	self.AvoidTimer = 0
	self.SegmentCount = 0
	self.Goal = nil
	self.PathAge = 0
	
end

function BOT:GetPathAge()

	return Either( isnumber( self.PathAge ), CurTime() - self.PathAge, 99999.9 )
	
end

-- This will compute the length of the path given
function GetPathLength( tbl, startArea, endArea )
	if isbool( tbl ) and tbl then return startArea:GetCenter():Distance( endArea:GetCenter() )
	elseif isbool( tbl ) and !tbl then return -1 end
	
	local totalDist = 0
	for k, v in ipairs( tbl ) do
		if !tbl[ k + 1 ] then break
		elseif !IsValid( v.Area ) or !IsValid( tbl[ k + 1 ].Area ) then return -1 end -- The table is either not a path or is corrupted
		
		totalDist = totalDist + v.Area:GetCenter():Distance( tbl[ k + 1 ].Area:GetCenter() )
	end
	
	return totalDist

end

local result = Vector()
-- Checks if the bot will cross enemy line of fire when attempting to move to the entered position
function BOT:IsCrossingLineOfFire( startPos, endPos )

	for k, known in ipairs( self.EnemyList ) do
	
		if !self:IsAwareOf( known ) or known:IsObsolete() or !self:IsEnemy( known:GetEntity() )then
		
			continue
			
		end
		
		local enemy = known:GetEntity()
		local viewForward = Either( enemy:IsPlayer() or enemy:IsNPC(), enemy:GetAimVector(), enemy:EyeAngles():Forward() )
		local target = enemy:WorldSpaceCenter() + 5000 * viewForward
		
		local IsIntersecting = false
		result:Zero()
		
		IsIntersecting, result = IsIntersecting2D( startPos, endPos, enemy:WorldSpaceCenter(), target )
		--print( "IsIntersecting: " .. IsIntersecting )
		--print( "Result: " .. result )
		if IsIntersecting then
		
			local loZ, hiZ = 0, 0
			
			if startPos.z < endPos.z then
			
				loZ = startPos.z 
				hiZ = endPos.z 
				
			else
			
				loZ = endPos.z 
				hiZ = startPos.z
			
			end
			
			if result.z >= loZ and result.z <= hiZ + 35.5 then return true end
		
		end
		
	end
	
	return false
	
end

--[[
 Got this from CS:GO Source Code, made some changes so it works for Lua
 
 Given two line segments: startA to endA, and startB to endB, return true if they intesect
 and put the intersection point in "result".
 Note that this computes the intersection of the 2D (x,y) projection of the line segments.
]]--
function IsIntersecting2D( startA, endA, startB, endB )

	local denom = (endA.x - startA.x) * (endB.y - startB.y) - (endA.y - startA.y) * (endB.x - startB.x)
	if demon == 0 then
	
		-- Parallel
		return false, result
	
	end
	
	local numS = (startA.y - startB.y) * (endB.x - startB.x) - (startA.x - startB.x) * (endB.y - startB.y)
	if numS == 0 then
	
		-- Coincident
		return true, result
		
	end
	
	local numT = (startA.y - startB.y) * (endA.x - startA.x) - (startA.x - startB.x) * (endA.y - startA.y)
	
	local s = numS / denom
	if s < 0.0 or s > 1.0 then
	
		-- Intersection is not within line segment of startA to endA
		return false, result
		
	end
	
	local t = numT / denom
	if t < 0.0 or t > 1.0 then
	
		-- Intersection is not within line segment of startB to endB
		return false, result
		
	end
	
	return true, startA + s * (endA - startA)
	
end

-- Checks if a hiding spot is already in use
function BOT:IsSpotOccupied( pos )

	local ply, distance = util.GetClosestPlayer( pos )
	
	if IsValid( ply ) and ply != self then
	
		if ply:IsTRizzleBot() and ply.HidingSpot == pos then return true -- Don't consider spots already selected by other bots
		elseif distance < 75 then return true end -- Don't consider spots if a bot or human player is already there

	end

	local trace = {}
	local size = self:GetHullWidth() / 2.0
	util.TraceHull( { start = pos, endpos = pos, maxs = Vector( size, size, self:GetCrouchHullHeight() ), mins = Vector( -size, -size, 0.0 ), mask = MASK_PLAYERSOLID, filter = SlasherBotTraceFilter, output = trace  } )
	-- Don't consider spots if there is a prop in the way.
	if trace.Fraction < 1.0 or trace.StartSolid then
	
		return true
		
	end

	return false

end

-- Checks if a hiding spot is safe to use
function BOT:IsSpotSafe( hidingSpot )

	for k, known in ipairs( self.EnemyList ) do
	
		if self:IsAwareOf( known ) and !known:IsObsolete() and self:IsEnemy( known:GetEntity() ) and known:GetEntity():TBotVisible( hidingSpot ) then return false end -- If one of the bot's enemies its aware of can see it the bot won't use it.
	
	end

	return true

end

-- Clears the selected bot's hiding spot
function BOT:ClearHidingSpot()

	self.HidingSpot = nil
	self.HidingState = FINISHED_HIDING
	self.HideReason	= NONE
	
	if isvector( self.ReturnPos ) then
		
		-- We only set the goal once just incase something else that is important, "following their owner," wants to move the bot
		TRizzleBotPathfinderCheap( self, self.ReturnPos )
		--self:TBotCreateNavTimer()
		self.ReturnPos = nil
		
	end

end

-- Returns a table of hiding spots.
function BOT:FindSpots( tbl, secondAttempt )

	--local startTime = SysTime()
	local tbl = tbl or {}

	tbl.pos				= tbl.pos				or self:WorldSpaceCenter()
	tbl.radius			= tbl.radius			or 1000
	tbl.stepdown		= tbl.stepdown			or 1000
	tbl.stepup			= tbl.stepup			or self:GetMaxJumpHeight()
	tbl.spotType		= tbl.spotType			or "hiding"
	tbl.checkoccupied	= tbl.checkoccupied		or 1
	tbl.checksafe		= tbl.checksafe			or 1
	tbl.checklineoffire	= tbl.checklineoffire	or 1

	-- Find a bunch of areas within this distance
	local areas = navmesh.Find( tbl.pos, tbl.radius, tbl.stepup, tbl.stepdown )

	local found = {}
	local found2 = {}
	
	--local startArea = navmesh.GetNearestNavArea( tbl.pos )
	--[[if !IsValid( startArea ) then
	
		return
		
	end]]

	-- In each area
	for _, area in ipairs( areas ) do

		-- This Area is marked as DONT HIDE, so lets ignore it
		if area:HasAttributes( NAV_MESH_DONT_HIDE ) then continue end
		
		-- get the spots
		local spots

		if ( tbl.spotType == "hiding" ) then 
		
			spots = area:GetHidingSpots() -- In Cover/basically a hiding spot, in a corner with good hard cover nearby
		
		elseif ( tbl.spotType == "sniper" ) then 
		
			spots = area:GetHidingSpots( 4 ) -- Perfect sniper spot, can see either very far, or a large area, or both
			
			-- If we didn't find any ideal sniper spots, look for "good" spots instead
			if !spots or #spots == 0 then
			
				spots = area:GetHidingSpots( 2 ) -- Good sniper spot, had at least one decent sniping corridor
				
			end
			
		end

		for k, vec in ipairs( spots ) do
			
			-- NOTE: NavAreaTravelDistance and NavAreaBuildPath is very expensive
			-- when called multiple times per frame, I need to find a better way to implement this.
			--local pathLength = NavAreaTravelDistance( startArea, area, self )
			-- For now I will do distance checks the same way Valve does it in CS:GO
			local pathLength = tbl.pos:Distance( vec )
			--print("Path Length: " .. pathLength )
			
			-- If the hiding spot is further than tbl.range, the bot shouldn't consider it
			if tbl.radius < pathLength then 
			
				continue
			
			-- If the spot is already in use by another player the bot shouldn't consider it
			elseif tobool( tbl.checkoccupied ) and self:IsSpotOccupied( vec ) then 
			
				continue
			
			-- If the spot is visible to enemies on the bot's known enemy list the bot shouldn't consider it
			elseif tobool( tbl.checksafe ) and !self:IsSpotSafe( vec + HalfHumanHeight ) then 
			
				continue
			
			-- If the bot has to cross line of fire to reach the spot the bot shouldn't consider it
			elseif tobool( tbl.checklineoffire ) and self:IsCrossingLineOfFire( tbl.pos, vec ) then 
			
				-- I add the hiding spots to a second table so if every hiding spot is crossing line of fire
				-- then the bot can consider them anyway.
				table.insert( found2, { vector = vec, distance = pathLength } )
				continue 
			
			end
			
			table.insert( found, { vector = vec, distance = pathLength } )

		end

	end
	
	if ( !found or #found == 0 ) and ( !found2 or #found2 == 0 ) and !secondAttempt then
	
		-- If we didn't find any hiding spots then look for sniper spots instead
		if tbl.spotType == "hiding" then
		
			tbl.spotType = "sniper"
			
			return self:FindSpots( tbl, true )
			
		-- If we didn't find any sniper spots then look for hiding spots instead
		elseif tbl.spotType == "sniper" then
		
			tbl.spotType = "hiding"
			
			return self:FindSpots( tbl, true )
			
		end
		
	end
	
	--print( "FindSpots RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	return Either( found and #found != 0, found, found2 )

end

-- Like FindSpots but only returns a vector
function BOT:FindSpot( type, options )

	local spots = self:FindSpots( options )
	if !spots or #spots == 0 then return end
	
	if type == "near" then

		table.SortByMember( spots, "distance", true )
		--print(spots[1].distance)
		return spots[1].vector

	end

	if type == "far" then

		table.SortByMember( spots, "distance", false )
		--print(spots[1].distance)
		return spots[1].vector

	end

	-- random
	return spots[ math.random( 1, #spots ) ].vector

end

-- A handy function for range checking.
local function IsVecCloseEnough( start , endpos , dist )
	
	return start:DistToSqr( endpos ) < dist * dist
	
end

local function CheckLOS( val , pos1 , pos2 )
	
	local Trace				=	util.TraceLine({
		
		start				=	pos1 + Vector( val , 0 , 0 ),
		endpos				=	pos2 + Vector( val , 0 , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	Trace					=	util.TraceLine({
		
		start				=	pos1 + Vector( -val , 0 , 0 ),
		endpos				=	pos2 + Vector( -val , 0 , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	
	Trace					=	util.TraceLine({
		
		start				=	pos1 + Vector( 0 , val , 0 ),
		endpos				=	pos2 + Vector( 0 , val , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	Trace					=	util.TraceLine({
		
		start				=	pos1 + Vector( 0 , -val , 0 ),
		endpos				=	pos2 + Vector( 0 , -val , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	return true
end

local function SendBoxedLine( pos1 , pos2 )
	if !isvector( pos1 ) or !isvector( pos2 ) then return false end
	
	local Trace				=	util.TraceLine({
		
		start				=	pos1 + Vector( 0 , 0 , 15 ),
		endpos				=	pos2 + Vector( 0 , 0 , 15 ),
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	for i = 1, 12 do
		
		if CheckLOS( 3 * i , pos1 , pos2 ) == false then return false end
		
	end
	
	local HullTrace			=	util.TraceHull({
		
		mins				=	Vector( -16 , -16 , 0 ),
		maxs				=	Vector( 16 , 16 , 71 ),
		
		start				=	position,
		endpos				=	position,
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if HullTrace.Hit then return false end
	
	return true
end


local dir			=	Vector()
-- Creates waypoints using the nodes.
function BOT:ComputeNavmeshVisibility()

	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	local LADDER_UP = 0
	local LADDER_DOWN = 1
	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	local NUM_TRAVERSE_TYPES = 9
	
	dir:Zero()
	
	if self.Path[ 1 ].Area:Contains( self:GetPos() ) then
	
		self.Path[ 1 ].Pos = self:GetPos()
		
	else
	
		self.Path[ 1 ].Pos = self.Path[ 1 ].Area:GetCenter()
		
	end
	
	self.Path[ 1 ].How = NUM_TRAVERSE_TYPES
	self.Path[ 1 ].Type = PATH_ON_GROUND
	
	local index = 2
	while index <= #self.Path do
		
		local from = self.Path[ index - 1 ]
		local to = self.Path[ index ]
		
		if to.How <= WEST then
		
			local CurrentNode	=	from.Area
			local NextNode		=	to.Area
			local NextHow		=	to.How
			
			to.Pos = CurrentNode:ComputeClosestPointInPortal( NextNode, from.Pos, NextHow )
			
			--to.Pos = AddDirectionVector( to.Pos, NextHow, 5.0 )
			to.Pos.z = CurrentNode:GetZ( to.Pos )
			
			--local expectedHeightDrop = CurrentNode:GetZ( from.Pos ) - NextNode:GetZ( to.Pos )
			
			local fromPos = Vector( from.Pos )
			fromPos.z = from.Area:GetZ( fromPos )
			
			local toPos = Vector( to.Pos )
			toPos.z = to.Area:GetZ( toPos )
			
			local groundNormal = from.Area:ComputeNormal()
			local alongPath = toPos - fromPos
			local expectedHeightDrop = -alongPath:Dot( groundNormal )
			--print( "Should Drop Down: " .. tostring( expectedHeightDrop > self:GetStepSize() ) )
			--print( "From Position: " .. tostring( from.Pos ))
			--print( "PathIndex: " .. tostring( index ) )
			--print( "To Position: " .. tostring( to.Pos ) )
			
			if expectedHeightDrop > self:GetStepSize() then
			
				--print("DROP")
				dir:Zero() -- This resets dir to Vector( 0, 0, 0 )
				
				if NextHow == NORTH then 
					dir.x = 0 
					dir.y = -1
				elseif NextHow == SOUTH then 
					dir.x = 0 
					dir.y = 1
				elseif NextHow == EAST then 
					dir.x = 1 
					dir.y = 0
				elseif NextHow == WEST then 
					dir.x = -1 
					dir.y = 0 
				end
				
				local inc = 10
				local maxPushDist = 2.0 * self:GetHullWidth()
				local halfWidth = self:GetHullWidth() / 2.0
				local hullHeight = self:GetCrouchHullHeight()
				
				local pushDist = 0
				while pushDist <= maxPushDist do
				
					local pos = to.Pos + Vector( pushDist * dir.x, pushDist * dir.y, 0 )
					local lowerPos = Vector( pos.x, pos.y, toPos.z )
					local ground = {}
					util.TraceHull( { start = pos, endpos = lowerPos, mins = Vector( -halfWidth, -halfWidth, 0 ), maxs = Vector( halfWidth, halfWidth, hullHeight ), mask = MASK_PLAYERSOLID, filter = TBotTraversableFilter, output = ground } )
					
					--print( "Ground Fraction: " .. tostring( ground.Fraction ) )
					--print( "Started Solid: " .. tostring( ground.StartSolid ) )
					--print( "Hit Entity: " .. tostring( ground.Entity ) )
					--print( "Hit World: " .. tostring( ground.HitWorld ) )
					--print( "Hit NonWorld: " .. tostring( ground.HitNonWorld ) )
					--print( "Hit NoDraw: " .. tostring( ground.HitNoDraw ) )
					if ground.Fraction >= 1.0 then
					
						break
						
					end
					
					pushDist = pushDist + inc
					
				end
				
				--print( "Push Distance: " .. tostring ( pushDist ) )
				local startDrop = Vector( to.Pos.x + ( pushDist * dir.x ), to.Pos.y + ( pushDist * dir.y ), to.Pos.z )
				local endDrop = Vector( startDrop.x, startDrop.y, NextNode:GetZ( to.Pos ) )
				
				local ground = navmesh.GetGroundHeight( startDrop )
				if ground and startDrop.z > ground + self:GetStepSize() then
				
					-- if "ground" is lower than the next segment along the path
					-- there is a chasm between - this is not a drop down
					local nextSegment = self:NextSegment( to )
					local ground2 = nil
					if nextSegment and IsValid( nextSegment.Area ) then
					
						ground2 = navmesh.GetGroundHeight( nextSegment.Area:GetCenter() )
						
					end
					
					if !ground2 or ground2 < ground + self:GetStepSize() then
					
						to.Pos = startDrop
						to.Type = PATH_DROP_DOWN
						
						endDrop.z = ground
						
						table.insert( self.Path, index + 1, { Pos = endDrop, Area = to.Area, How = to.How, Type = PATH_ON_GROUND } )
						self.SegmentCount = self.SegmentCount + 1
						index = index + 2
						continue
						
					end
				
				end
				
			end
			
		elseif to.How == GO_LADDER_UP then
		
			local list = from.Area:GetLaddersAtSide( LADDER_UP )
			--print( "Ladders: " .. #list )
			local i = 1
			while i <= #list do
				local ladder = list[ i ]
				--print( "Top Area: " .. tostring( ladder:GetTopForwardArea() ) )
				--print( "TopLeft Area: " .. tostring( ladder:GetTopLeftArea() ) )
				--print( "TopRight Area: " .. tostring( ladder:GetTopRightArea() ) )
				--print( "TopBehind Area: " .. tostring( ladder:GetTopBehindArea() ) )
				if IsValid( ladder ) and ( ladder:GetTopForwardArea() == to.Area or ladder:GetTopLeftArea() == to.Area or ladder:GetTopRightArea() == to.Area or ladder:GetTopBehindArea() == to.Area ) then
					
					to.Pos = self:ComputeLadderEndpoint( ladder, true )
					to.Type = PATH_LADDER_UP
					to.Ladder = ladder
					--table.insert( self.Path, index, { Pos = ladder:GetBottom() + ladder:GetNormal() * 2.0 * 16, How = GO_LADDER_UP, Type = PATH_LADDER_MOUNT } )
					--self.SegmentCount = self.SegmentCount + 1
					break
					
				end
				i = i + 1
			end
			
			-- for some reason we couldn't find the ladder
			if i > #list then
			
				return false
				
			end
			
		elseif to.How == GO_LADDER_DOWN then
		
			local list = from.Area:GetLaddersAtSide( LADDER_DOWN )
			--print( "Ladders: " .. #list )
			local i = 1
			while i <= #list do
				local ladder = list[ i ]
				--print( "Bottom Area: " .. tostring( ladder:GetBottomArea() ) )
				if IsValid( ladder ) and ladder:GetBottomArea() == to.Area then
					
					to.Pos = self:ComputeLadderEndpoint( ladder, false )
					to.Type = PATH_LADDER_DOWN
					to.Ladder = ladder
					--table.insert( self.Path, index, { Pos = ladder:GetTop() + ladder:GetNormal() * 2.0 * 16, How = GO_LADDER_DOWN, Type = PATH_LADDER_MOUNT } )
					--self.SegmentCount = self.SegmentCount + 1
					break
					
				end
				i = i + 1
			end
			
			-- for some reason we couldn't find the ladder
			if i > #list then
			
				return false
				
			end
			
		end
		
		index = index + 1
		continue
		
	end
	
	local index = 1
	while self.Path[ index + 1 ] do
		
		local from = self.Path[ index ]
		local to = self.Path[ index + 1 ]
		local CurrentNode = from.Area
		local NextNode = to.Area
		
		if from.How != NUM_TRAVERSE_TYPES and from.How > WEST then
		
			index = index + 1
			continue
			
		end
		
		if to.How > WEST or to.Type != PATH_ON_GROUND then
		
			index = index + 1
			continue
			
		end
		
		local closeTo = NextNode:GetClosestPointOnArea( from.Pos )
		local closeFrom = CurrentNode:GetClosestPointOnArea( closeTo )
		
		if ( closeFrom - closeTo ):AsVector2D():IsLengthGreaterThan( 1.9 * 25 ) and ( closeTo - closeFrom ):AsVector2D():IsLengthGreaterThan( 0.5 * math.abs( closeTo.z - closeFrom.z ) ) then
		
			local landingPos = NextNode:GetClosestPointOnArea( to.Pos )
			local launchPos = CurrentNode:GetClosestPointOnArea( landingPos )
			local forward = landingPos - launchPos
			forward:Normalize()
			local halfWidth = self:GetHullWidth() / 2.0
			
			to.Pos = landingPos + forward * halfWidth
			table.insert( self.Path, index + 1, { Pos = launchPos - forward * halfWidth, Type = PATH_JUMP_OVER_GAP } )
			self.SegmentCount = self.SegmentCount + 1
			index = index + 1
			--print( "GapJump" )
			
		
		elseif self:ShouldJump( closeFrom, closeTo ) then
		
			to.Pos = NextNode:GetCenter()
			
			local launchPos = CurrentNode:GetClosestPointOnArea( to.Pos )
			table.insert( self.Path, index + 1, { Pos = launchPos, Type = PATH_CLIMB_UP } )
			self.SegmentCount = self.SegmentCount + 1
			index = index + 1
			
		end
		
		index = index + 1
		
	end
	
	--table.insert( self.Path, { Pos = self.Goal, Type = PATH_ON_GROUND } )
	
end

-- Build trivial path when start and goal are in the same area
function BuildTrivialPath( bot, goal )

	local NUM_TRAVERSE_TYPES = 9
	local start = bot:GetPos()
	
	bot.SegmentCount = 0
	
	local startArea = navmesh.GetNearestNavArea( start )
	if !IsValid( startArea ) then
	
		return false
		
	end
	
	local goalArea = navmesh.GetNearestNavArea( goal )
	if !IsValid( goalArea ) then
	
		return false
		
	end
	
	bot.SegmentCount = 2
	
	bot.Path[ 1 ] = {}
	bot.Path[ 1 ].Area = startArea
	bot.Path[ 1 ].Pos = Vector( start.x, start.y, startArea:GetZ( start ) )
	bot.Path[ 1 ].How = NUM_TRAVERSE_TYPES
	bot.Path[ 1 ].Type = PATH_ON_GROUND
	
	bot.Path[ 2 ] = {}
	bot.Path[ 2 ].Area = goalArea
	bot.Path[ 2 ].Pos = Vector( goal.x, goal.y, goalArea:GetZ( goal ) )
	bot.Path[ 2 ].How = NUM_TRAVERSE_TYPES
	bot.Path[ 2 ].Type = PATH_ON_GROUND
	
	bot.Path[ 1 ].Forward = bot.Path[ 2 ].Pos - bot.Path[ 1 ].Pos
	bot.Path[ 1 ].Length = bot.Path[ 1 ].Forward:Length()
	bot.Path[ 1 ].Forward:Normalize()
	bot.Path[ 1 ].DistanceFromStart = 0.0
	
	bot.Path[ 2 ].Forward = bot.Path[ 1 ].Forward
	bot.Path[ 2 ].Length = 0.0
	bot.Path[ 2 ].DistanceFromStart = bot.Path[ 1 ].Length
	
	bot.Goal = bot:FirstSegment()
	
	return true
	
end

-- This is the post proccess of the path
function PostProccess( bot )
	
	bot.PathAge = CurTime()
	
	if bot.SegmentCount == 0 then 
	
		return 
		
	end
	
	if bot.SegmentCount == 1 then
	
		bot.Path[ 1 ].Forward = Vector()
		bot.Path[ 1 ].Length = 0.0
		bot.Path[ 1 ].DistanceFromStart = 0.0
		return
		
	end

	local distanceSoFar = 0.0
	local index = 1
	while bot.Path[ index + 1 ] do
	
		local from = bot.Path[ index ]
		local to = bot.Path[ index + 1 ]
		
		from.Forward = to.Pos - from.Pos
		from.Length = from.Forward:Length()
		from.Forward:Normalize()
		
		from.DistanceFromStart = distanceSoFar
		
		distanceSoFar = distanceSoFar + from.Length
		
		index = index + 1
		
	end
	
	bot.Path[ index ].Forward = bot.Path[ index - 1 ].Forward
	bot.Path[ index ].Length = 0.0
	bot.Path[ index ].DistanceFromStart = distanceSoFar
	
end

function AddDirectionVector( v, dir, amount )

	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3

	if dir == NORTH then v.y = v.y - amount
	elseif dir == SOUTH then v.y = v.y + amount
	elseif dir == EAST then v.x = v.x + amount
	elseif dir == WEST then v.x = v.x - amount end
	
	return v

end

function Vec:AsVector2D()

	return Vector( self.x, self.y, 0 )
	
end

function Vec:IsLengthGreaterThan( val )

	return self:LengthSqr() > val * val
	
end

function Vec:IsLengthLessThan( val )

	return self:LengthSqr() < val * val
	
end

-- Grabs the entered entity's last known nav area
-- TODO: Is there a way to grab this internaly?
function Ent:GetLastKnownArea()

	if self:IsPlayer() and self:IsTRizzleBot() then
	
		return self.lastKnownArea
		
	end
	
	return navmesh.GetNearestNavArea( self:GetPos(), true, 200, true )
	
end

-- The main navigation code ( Waypoint handler )
-- Deprecated: I have a better way of making the bot repath when needed
--[[function BOT:TBotNavigation()
	if !isvector( self.Goal ) then return end -- A double backup!
	if !IsValid( self:GetLastKnownArea() ) then return end -- The map has no navmesh.
	
	
	if !istable( self.Path ) or table.IsEmpty( self.Path ) then
		
		
		if self.BlockPathFind != true then
			
			
			self.Path				=	{} -- Reset that.
			
			-- Pathfollower is not only cheaper, but it can use ladders.
			TRizzleBotPathfinderCheap( self , self.Goal )
			
			-- Prevent spamming the pathfinder.
			self.BlockPathFind		=	true
			timer.Simple( 0.50 , function()
			
				if IsValid( self ) then
					
					self.BlockPathFind		=	false
				
				end
			
			end)
			
			
		end
		
		
	end
	
	self:CheckProgress()
	
end]]

function BOT:GetMotionVector()
	
	return self.MotionVector
	
end

function BOT:IsPotentiallyTraversable( from, to )

	if to.z - from.z > self:GetMaxJumpHeight() + 0.1 then
	
		local along = to - from
		along:Normalize()
		if along.z > 0.6 then
		
			return false, 0.0
			
		end
		
	end
	
	local probeSize = 0.25 * self:GetHullWidth()
	local probeZ = self:GetStepSize()
	
	local hullMin = Vector( -probeSize, -probeSize, probeZ )
	local hullMax = Vector( probeSize, probeSize, self:GetCrouchHullHeight() )
	
	local result = {}
	util.TraceHull( { start = from, endpos = to, maxs = hullMax, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )

	return result.Fraction >= 1.0 and !result.StartSolid, result.Fraction
	
end

function BOT:IsGap( pos, forward )

	local halfWidth = 1.0
	local hullHeight = 1.0
	
	local ground = {}
	util.TraceHull( { start = pos + Vector( 0, 0, self:GetStepSize() ), endpos = pos + Vector( 0, 0, -self:GetMaxJumpHeight() ), maxs = Vector( halfWidth, halfWidth, hullHeight ), mins = Vector( -halfWidth, -halfWidth, 0 ), filter = TBotTraceFilter, mask = MASK_PLAYERSOLID, output = ground } )
	
	--debugoverlay.SweptBox( pos + Vector( 0, 0, self:GetStepSize() ), pos + Vector( 0, 0, -self:GetMaxJumpHeight() ), Vector( -halfWidth, -halfWidth, 0 ), Vector( halfWidth, halfWidth, hullHeight ), Angle(), 5.0, Color( 255, 0, 0 ) )
	
	return ground.Fraction >= 1.0 and !ground.StartSolid
	
end

function BOT:HasPotentialGap( from, desiredTo )

	local _, traversableFraction = self:IsPotentiallyTraversable( from, desiredTo )
	
	local to = from + ( desiredTo - from ) * traversableFraction
	
	local forward = to - from
	local length = forward:Length()
	forward:Normalize()
	
	local step = self:GetHullWidth() / 2.0
	local pos = Vector( from )
	local delta = step * forward
	local t = 0.0
	while t < length + step do
		
		if self:IsGap( pos, forward ) then
		
			return true
			
		end
		
		t = t + step
		pos = pos + delta
		
	end
	
	return false
	
end

function BOT:CheckProgress()

	-- skip nearby goal points that are redundant to smooth path following motion
	local pSkipToGoal = nil
	if TBotLookAheadRange:GetFloat() > 0 then
	
		pSkipToGoal = self.Goal
		local myFeet = self:GetPos()
		while pSkipToGoal and pSkipToGoal[ "Type" ] == PATH_ON_GROUND and self:IsOnGround() do
		
			if ( pSkipToGoal[ "Pos" ] - myFeet ):IsLengthLessThan( TBotLookAheadRange:GetFloat() ) then
			
				-- goal is too close - step to next segment
				local nextSegment = self:NextSegment( pSkipToGoal )
				
				if !nextSegment or nextSegment[ "Type" ] != PATH_ON_GROUND then
					
					-- can't skip ahead to next segment - head towards current goal
					break
					
				end
				
				if IsValid( nextSegment[ "Area" ] ) and nextSegment[ "Area" ]:HasAttributes( NAV_MESH_PRECISE ) then
				
					-- We are being told to be precise here, so don't skip ahead here
					break
					
				end
				
				if nextSegment[ "Pos" ].z > myFeet.z + self:GetStepSize() then
				
					-- going uphill or up stairs tends to cause problems if we skip ahead, so don't
					break
					
				end
				
				--[[if self:GetMotionVector():Dot( nextSegment[ "Forward" ] ) <= 0.1 then
					
					-- don't skip sharp turns
					print( self:GetMotionVector():Dot( nextSegment[ "Forward" ] ) )
					
					break
					
				end]]
				
				--print( "IsPotentiallyTraversable: " .. tostring( self:IsPotentiallyTraversable( myFeet, nextSegment[ "Pos" ] ) ) )
				--print( "HasPotentialGap: " .. tostring( !self:HasPotentialGap( myFeet, nextSegment[ "Pos" ] ) ) )
				
				-- can we reach the next path segment directly
				if self:IsPotentiallyTraversable( myFeet, nextSegment[ "Pos" ] ) and !self:HasPotentialGap( myFeet, nextSegment[ "Pos" ] ) then
				
					pSkipToGoal = nextSegment
					
					--print( pSkipToGoal )
					
				else
					
					-- can't directly reach next segment - keep heading towards current goal
					break
					
				end
				
			else
			
				-- goal is farther than min lookahead
				break
				
			end
			
		end
		
		-- didn't find any goal to skip to
		if pSkipToGoal == self.Goal then
		
			pSkipToGoal = nil
			
		end
		
	end
	
	if self:IsAtGoal() then
	
		local nextSegment = Either( istable( pSkipToGoal ), pSkipToGoal, self:NextSegment( self.Goal ) )
	
		if !nextSegment then
			
			if self:IsOnGround() then
			
				self:TBotClearPath()
				
			end
			
			return false
			
		else
		
			self.Goal = nextSegment
		
		end
		
	end
	
	return true
	
end

function BOT:IsAtGoal()

	local current		=	self:PriorSegment( self.Goal )
	local toGoal		=	self.Goal.Pos - self:GetPos()
	-- ALWAYS: Use 2D navigation, It helps by a large amount.
	
	if !current then
	
		-- passed goal
		return true
	
	elseif self.Goal.Type == PATH_DROP_DOWN then
		
		local landing = self:NextSegment( self.Goal )
		
		if !landing then
		
			-- passed goal or corrupt path
			return true
		
		-- did we reach the ground
		elseif self:GetPos().z - landing.Pos.z < self:GetStepSize() then
			
			-- reached goal
			return true
			
		end
		
	elseif self.Goal.Type == PATH_CLIMB_UP then
		
		local landing = self:NextSegment( self.Goal )
		
		if !landing then
		
			-- passed goal or corrupt path
			return true
		
		elseif self:GetPos().z > self.Goal.Pos.z + self:GetStepSize() then
		
			return true
			
		end
	
	else
		
		local nextSegment = self:NextSegment( self.Goal )
		
		if nextSegment then
		
			-- because the bot may be off the path, check if it crossed the plane of the goal
			-- check against average of current and next forward vectors
			local dividingPlane = nil
			
			if current[ "Ladder" ] then
			
				dividingPlane = self.Goal[ "Forward" ]:AsVector2D()
				
			else
			
				dividingPlane = current[ "Forward" ]:AsVector2D() + self.Goal[ "Forward" ]:AsVector2D()
			
			end
			
			if toGoal:AsVector2D():Dot( dividingPlane ) < 0.0001 and math.abs( toGoal.z ) < self:GetStandHullHeight() then
			
				if toGoal.z < self:GetStepSize() and ( self:IsPotentiallyTraversable( self:GetPos(), nextSegment[ "Pos" ] ) and !self:HasPotentialGap( self:GetPos(), nextSegment[ "Pos" ] ) ) then
				
					return true
					
				end
				
			end
			
		end
		
		if toGoal:AsVector2D():IsLengthLessThan( TBotGoalTolerance:GetFloat() ) then
		
			-- Reached goal
			return true
		
		end
		
	end
	
	return false
	
end

function BOT:GetDesiredSpeed()

	local desiredSpeed = self:GetWalkSpeed()
	if self:KeyDown( IN_WALK ) then
	
		desiredSpeed = self:GetSlowWalkSpeed()
		
	elseif self:KeyDown( IN_SPEED ) and !self:Crouching() then
	
		desiredSpeed = self:GetRunSpeed()
		
	end
	
	if self:Is_On_Ladder() then
	
		return self:GetLadderClimbSpeed()
		
	end
	
	if self:Crouching() then
	
		desiredSpeed = desiredSpeed * self:GetCrouchedWalkSpeed()
		
	end
	
	return desiredSpeed
	
end

function BOT:OnStuck()

	self:PressJump()
	
	if math.random( 0, 100 ) < 50 then
	
		self:PressLeft()
		
	else
	
		self:PressRight()
		
	end
	
end

function BOT:ClearStuckStatus()

	self.IsStuck = false
	self.StuckPos = self:GetPos()
	self.StuckTimer = CurTime()
	
end

function BOT:StuckMonitor()

	-- a timer is needed to smooth over a few frames of inactivity due to state changes, etc.
	-- we only want to detect idle situations when the bot really doesn't "want" to move.
	if CurTime() - self.MoveRequestTimer > 0.25 then
	
		self.StuckPos = self:GetPos()
		self.StuckTimer = CurTime()
		return
		
	end
	
	-- We are not stuck if we are frozen!
	if self:IsFrozen() then
	
		self:ClearStuckStatus()
		return
		
	end
	
	if self.IsStuck then
	
		-- we are/were stuck - have we moved enough to consider ourselves "dislodged"
		if ( self.StuckPos - self:GetPos() ):IsLengthGreaterThan( 100 ) then
		
			self:ClearStuckStatus()
			
		else
		
			-- still stuck - periodically resend the event
			if self.StillStuckTimer <= CurTime() then
			
				self.StillStuckTimer = CurTime() + 1.0
				
				self:OnStuck()
				
			end
			
		end
		
		-- We have been stuck for too long, destroy the current path
		-- and the bot's current hiding spot.
		if CurTime() - self.StuckTimer > 10.0 then
		
			self:TBotClearPath()
			self:ClearHidingSpot()
			self:ClearStuckStatus()
			
		end
		
	else
	
		-- we're not stuck - yet
	
		if ( self.StuckPos - self:GetPos() ):IsLengthGreaterThan( 100 ) then
		
			-- we have moved - reset anchor
			self.StuckPos = self:GetPos()
			self.StuckTimer = CurTime()
			
		else
		
			-- within stuck range of anchor. if we've been here too long, we're stuck
			local minMoveSpeed = 0.1 * self:GetDesiredSpeed() + 0.1
			local escapeTime = 100 / minMoveSpeed
			if CurTime() - self.StuckTimer > escapeTime then
			
				-- we have taken too long - we're stuck
				self.IsStuck = true
				
				self:OnStuck()
				
			end
			
		end
	
	end
	
end

-- The navigation and navigation debugger for when a bot is stuck.
function BOT:TBotCreateNavTimer()
	
	local index			=	self:EntIndex()
	local Attempts		=	0
	local LastBotPos	=	self:GetPos()
	
	
	timer.Create( "trizzle_bot_nav" .. index , 0.09 , 0 , function()
		
		if IsValid( self ) and self:Alive() and self:IsTRizzleBot() and self:IsPathValid() then
			
			if self:Is_On_Ladder() then return end
			
			if self:GetVelocity():Length2DSqr() <= 225 or IsVecCloseEnough( LastBotPos:AsVector2D(), self:GetPos():AsVector2D(), 4 ) then
				
				if Attempts >= 5 then 
					
					self.AvoidTimer = CurTime() + 0.5
					if self.WiggleTimer > CurTime() then
					
						return
						
					end
					
					local wiggleDirection = math.random( 2 )
					self.WiggleTimer = CurTime() + math.Rand( 0.3, 0.5 )
					if wiggleDirection == 1 then
					
						local ground = navmesh.GetGroundHeight( self:GetPos() - ( 30.0 * self:EyeAngles():Right() ) )
						
						-- Don't move left if we will fall
						if ground and self:GetPos().z - ground < self:GetStepSize() then
						
							self:PressLeft( 0.3 )
						
						end
					
					elseif wiggleDirection == 2 then
					
						local ground = navmesh.GetGroundHeight( self:GetPos() + ( 30.0 * self:EyeAngles():Right() ) )
						
						-- Don't move right if we will fall
						if ground and self:GetPos().z - ground < self:GetStepSize() then
						
							self:PressRight( 0.3 )
						
						end
					
					--[[elseif wiggleDirection == 3 then
					
						local ground = navmesh.GetGroundHeight( self:GetPos() + ( 30.0 * self:EyeAngles():Forward() ) )
						
						-- Don't move forward if we will fall
						if ground and self:GetPos().z - ground < self:GetStepSize() then
						
							self:PressForward( 0.3 )
						
						end
					
					elseif wiggleDirection == 4 then
					
						local ground = navmesh.GetGroundHeight( self:GetPos() - ( 30.0 * self:EyeAngles():Forward() ) )
						
						-- Don't move back if we will fall
						if ground and self:GetPos().z - ground < self:GetStepSize() then
						
							self:PressBack( 0.3 )
						
						end]]
					
					end
					
					if self.StuckJumpInterval <= CurTime() then
					
						self:PressJump()
						self.StuckJumpInterval = CurTime() + math.Rand( 1.0, 2.0 )
					
					end
					
				end
				if Attempts == 10 then 
				
					TRizzleBotPathfinderCheap( self, self:LastSegment().Pos )
					self.RepathTimer = CurTime() + 0.5
					
				end
				if Attempts > 20 then 
				
					self:TBotClearPath()
					self:ClearHidingSpot()
					
				end
				Attempts = Attempts + 1
				
			else
				
				if Attempts > 0 then Attempts = Attempts - 1 end
				
			end
			
			LastBotPos = self:GetPos()
			
		else
			
			timer.Remove( "trizzlebot_nav" .. index )
			
		end
		
	end)
	
end

function VectorVectors( forward, right, up )
	
	local tmp = Vector()
	
	if math.abs( forward[ 1 ] ) < 1e-6 and math.abs( forward[ 2 ] ) < 1e-6 then
	
		right[ 1 ] = 0
		right[ 2 ] = -1
		right[ 3 ] = 0
		up[ 1 ] = -forward[ 3 ]
		up[ 2 ] = 0
		up[ 3 ] = 0
		
	else
	
		tmp[ 1 ] = 0
		tmp[ 2 ] = 0
		tmp[ 3 ] = 1.0
		right = forward:Cross( tmp )
		right:Normalize()
		up = right:Cross( forward )
		up:Normalize()
		
	end
	
end

-- Purpose: Draw a vertical arrow at a position
-- Got this from CS:GO Source Code, made some changes so it works for Lua
function debugoverlay.VertArrow( startPos, endPos, width, r, g, b, a, noDepthTest, flDuration )
	if !GetConVar( "developer" ):GetBool() then return end
	
	local lineDir = endPos - startPos
	lineDir:Normalize()
	local upVec = Vector()
	local sideDir = Vector()
	local radius = width / 2.0
	local arrowColor = Color( r, g, b, a )
	
	VectorVectors( lineDir, sideDir, upVec )
	
	local p1 = startPos - upVec * radius
	local p2 = endPos - lineDir * width - upVec * radius
	local p3 = endPos - lineDir * width - upVec * width
	local p4 = endPos
	local p5 = endPos - lineDir * width + upVec * width
	local p6 = endPos - lineDir * width + upVec * radius
	local p7 = startPos + upVec * radius
	
	-- Outline the arrow
	debugoverlay.Line( p1, p2, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p2, p3, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p3, p4, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p4, p5, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p5, p6, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p6, p7, flDuration, arrowColor, noDepthTest )
	
	if a > 0 then
	
		-- Fill us in with triangles
		debugoverlay.Triangle( p5, p4, p3, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p1, p7, p6, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p6, p2, p1, flDuration, arrowColor, noDepthTest )
		
		-- And backfaces
		debugoverlay.Triangle( p3, p4, p5, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p6, p7, p1, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p1, p2, p6, flDuration, arrowColor, noDepthTest )
		
	end
	
end

-- Purpose: Draw a horizontal arrow pointing in the specified direction
-- Got this from CS:GO Source Code, made some changes so it works for Lua
function debugoverlay.HorzArrow( startPos, endPos, width, r, g, b, a, noDepthTest, flDuration )
	if !GetConVar( "developer" ):GetBool() then return end

	local lineDir = endPos - startPos
	lineDir:Normalize()
	local sideDir
	local radius = width / 2.0
	local arrowColor = Color( r, g, b, a )
	
	sideDir = lineDir:Cross( vector_up )
	
	local p1 = startPos - sideDir * radius
	local p2 = endPos - lineDir * width - sideDir * radius
	local p3 = endPos - lineDir * width - sideDir * width
	local p4 = endPos
	local p5 = endPos - lineDir * width + sideDir * width
	local p6 = endPos - lineDir * width + sideDir * radius
	local p7 = startPos + sideDir * radius
	
	-- Outline the arrow
	debugoverlay.Line( p1, p2, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p2, p3, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p3, p4, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p4, p5, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p5, p6, flDuration, arrowColor, noDepthTest )
	debugoverlay.Line( p6, p7, flDuration, arrowColor, noDepthTest )
	
	if a > 0 then
	
		-- Fill us in with triangles
		debugoverlay.Triangle( p5, p4, p3, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p1, p7, p6, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p6, p2, p1, flDuration, arrowColor, noDepthTest )
		
		-- And backfaces
		debugoverlay.Triangle( p3, p4, p5, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p6, p7, p1, flDuration, arrowColor, noDepthTest )
		debugoverlay.Triangle( p1, p2, p6, flDuration, arrowColor, noDepthTest )
		
	end
	
end

-- A handy debugger for the waypoints.
-- Requires developer set to 1 in console
function BOT:TBotDebugWaypoints()
	if !self:IsPathValid() then return end
	if !GetConVar( "developer" ):GetBool() then return end
	
	--[[debugoverlay.Line( self.Path[ 1 ][ "Pos" ] , self:GetPos() + Vector( 0 , 0 , 44 ) , 0.08 , Color( 0 , 255 , 255 ) )
	debugoverlay.Sphere( self.Path[ 1 ][ "Pos" ] , 8 , 0.08 , Color( 0 , 255 , 255 ) , true )
	
	for k, v in ipairs( self.Path ) do
		
		if self.Path[ k + 1 ] then
			
			debugoverlay.Line( v[ "Pos" ] , self.Path[ k + 1 ][ "Pos" ] , 0.08 , Color( 255 , 255 , 0 ) )
			
		end
		
		debugoverlay.Sphere( v[ "Pos" ] , 8 , 0.08 , Color( 255 , 200 , 0 ) , true )
		
	end]]
	
	local s = self:FirstSegment()
	local i = 0
	while s do
		
		local nextNode = self:NextSegment( s )
		if !nextNode then
		
			break
			
		end
		
		local to = nextNode.Pos - s.Pos
		local horiz = math.max( math.abs( to.x ), math.abs( to.y ) )
		local vert = math.abs( to.z )
		
		-- PATH_ON_GROUND and PATH_LADDER_MOUNT
		local r, g, b = 255, 77, 0
		
		if s.Type == PATH_DROP_DOWN then
		
			r = 255
			g = 0
			b = 255
			
		elseif s.Type == PATH_CLIMB_UP then 
		
			r = 0
			g = 0
			b = 255
			
		elseif s.Type == PATH_JUMP_OVER_GAP then 
		
			r = 0
			g = 255
			b = 255
			
		elseif s.Type == PATH_LADDER_UP then 
		
			r = 0
			g = 255
			b = 0
			
		elseif s.Type == PATH_LADDER_DOWN then 
		
			r = 0
			g = 100
			b = 0
			
		end
		
		if IsValid( s.Ladder ) then
		
			debugoverlay.VertArrow( s.Ladder:GetBottom(), s.Ladder:GetTop(), 5.0, r, g, b, 255, true, 0.1 )
			
		else
		
			debugoverlay.Line( s.Pos, nextNode.Pos, 0.1, Color( r, g, b ), true )
			
		end
		
		local nodeLength = 25.0
		if horiz > vert then
		
			debugoverlay.HorzArrow( s.Pos, s.Pos + nodeLength * s.Forward, 5.0, r, g, b, 255, true, 0.1 )
			
		else
		
			debugoverlay.VertArrow( s.Pos, s.Pos + nodeLength * s.Forward, 5.0, r, g, b, 255, true, 0.1 )
			
		end
		
		debugoverlay.Text( s.Pos, tostring( i ), 0.1, true )
		
		s = nextNode
		i = i + 1
		
	end
	
end

function BOT:LadderUpdate()

	if self.LadderState != NO_LADDER then
	
		return true
		
	end
	
	if !IsValid( self.Goal.Ladder ) then
	
		if self:Is_On_Ladder() then
		
			local current = self:PriorSegment( self.Goal )
			if !current then
			
				return false
				
			end
			
			local s = current
			while s do
			
				if s != current and ( s.Pos - self:GetPos() ):AsVector2D():IsLengthGreaterThan( 50 ) then
				
					break
					
				end
				
				if IsValid( s.Ladder ) and s.How == GO_LADDER_DOWN and s.Ladder:GetLength() > self:GetMaxJumpHeight() then
				
					local destinationHeightDelta = s.Pos.z - self:GetPos().z
					if math.abs( destinationHeightDelta ) < self:GetMaxJumpHeight() then
					
						self.Goal = s
						break
						
					end
					
				end
				
				s = self:NextSegment( s )
				
			end
			
		end
	
		if !IsValid( self.Goal.Ladder ) then
		
			return false
		
		end
		
	end
	
	local mountRange = 25
	
	if self.Goal.Type == PATH_LADDER_UP then
	
		if self.LadderState == NO_LADDER and self:GetPos().z > self.Goal.Ladder:GetTop().z - self:GetStepSize() then
		
			self.Goal = self:NextSegment( self.Goal )
			return false
			
		end
		
		local to = ( self.Goal.Ladder:GetBottom() - self:GetPos() ):AsVector2D()
		
		self:AimAtPos( self.Goal.Ladder:GetTop() - 50 * self.Goal.Ladder:GetNormal() + Vector( 0, 0, self:GetCrouchHullHeight() ), 2.0, MAXIMUM_PRIORITY )
		
		local range = to:Length()
		to:Normalize()
		if range < 50 then
		
			local ladderNormal2D = self.Goal.Ladder:GetNormal():AsVector2D()
			local dot = ladderNormal2D:Dot( to )
			
			-- This was -0.9, but it caused issues with slanted ladders.
			-- -0.6 seems to fix this, but I don't know if any errors may occur from this change!
			if dot < -0.6 then
			
				self:Approach( self.Goal.Ladder:GetBottom() )
			
				if range < mountRange then
				
					self.LadderState = APPROACHING_ASCENDING_LADDER
					self.LadderInfo = self.Goal.Ladder
					self.LadderDismountGoal = self.Goal.Area
					
				end
				
			else
			
				local myPerp = Vector( -to.y, to.x, 0 )
				local ladderPerp2D = Vector( -ladderNormal2D.y, ladderNormal2D.x )
				
				local goal = self.Goal.Ladder:GetBottom()
				local alignRange = 50
				
				if dot < 0.0 then
				
					alignRange = mountRange + ( 1.0 + dot ) * ( alignRange - mountRange )
					
				end
				
				goal.x = goal.x - alignRange * to.x
				goal.y = goal.y - alignRange * to.y
				
				if to:Dot( ladderPerp2D ) < 0.0 then
				
					goal = goal + 10 * myPerp
					
				else
				
					goal = goal - 10 * myPerp
					
				end
				
				self:Approach( goal )
				
			end
			
			
		else
		
			return false
			
		end
		
	else
	
		if self:GetPos().z < self.Goal.Ladder:GetBottom().z + self:GetStepSize() then
		
			self.Goal = self:NextSegment( self.Goal )
			
		else
		
			local mountPoint = self.Goal.Ladder:GetTop() + 0.5 * self:GetHullWidth() * self.Goal.Ladder:GetNormal()
			local to = ( mountPoint - self:GetPos() ):AsVector2D()
			
			self:AimAtPos( self.Goal.Ladder:GetBottom() + 50 * self.Goal.Ladder:GetNormal() + Vector( 0, 0, self:GetCrouchHullHeight() ), 1.0, MAXIMUM_PRIORITY )
			
			local range = to:Length()
			to:Normalize()
			
			if range < mountRange or self:Is_On_Ladder() then
			
				self.LadderState = APPROACHING_DESCENDING_LADDER
				self.LadderInfo = self.Goal.Ladder
				self.LadderDismountGoal = self.Goal.Area
			
			else
			
				return false
				
			end
			
		end
		
	end
	
	return true
	
end

function BOT:AdjustPosture( moveGoal )

	local hullMin = self:GetHull()
	hullMin.z = hullMin.z + self:GetStepSize()
	
	local halfSize = self:GetHullWidth() / 2.0
	local standMaxs = Vector( halfSize, halfSize, self:GetStandHullHeight() )
	
	local moveDir = moveGoal - self:GetPos()
	local moveLength = moveDir:Length()
	moveDir:Normalize()
	local left = Vector( -moveDir.y, moveDir.x, 0 )
	local goal = self:GetPos() + moveLength * left:Cross( vector_up ):GetNormalized()
	
	local trace = {}
	util.TraceHull( { start = self:GetPos(), endpos = goal, maxs = standMaxs, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = trace } )
	
	if trace.Fraction >= 1.0 and !trace.StartSolid then
	
		return
		
	end
	
	local crouchMaxs = Vector( halfSize, halfSize, self:GetCrouchHullHeight() )
	util.TraceHull( { start = self:GetPos(), endpos = goal, maxs = crouchMaxs, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = trace } )
	
	if trace.Fraction >= 1.0 and !trace.StartSolid then
	
		self:PressCrouch()
		
	end
	
end

function BOT:Approach( pos )

	self.MoveRequestTimer = CurTime()
	
	self:AdjustPosture( pos )
	
	local forward = self:EyeAngles():Forward()
	forward.z = 0.0
	forward:Normalize()
	
	local right = Vector( forward.y, -forward.x, 0 )
	
	local to = pos - self:GetPos()
	to.z = 0.0
	to:Normalize()
	
	local ahead = to:Dot( forward )
	local side = to:Dot( right )
	
	if self:Is_On_Ladder() and self.LadderState != NO_LADDER and ( self.LadderState == ASCENDING_LADDER or self.LadderState == DESCENDING_LADDER ) then
		
		self:PressForward()
		
		if IsValid( self.LadderInfo ) then
			
			local posOnLadder = CalcClosestPointOnLine( self:GetPos(), self.LadderInfo:GetBottom(), self.LadderInfo:GetTop() )
			local alongLadder = self.LadderInfo:GetTop() - self.LadderInfo:GetBottom()
			alongLadder:Normalize()
			local rightLadder = alongLadder:Cross( self.LadderInfo:GetNormal() )
			local away = self:GetPos() - posOnLadder
			local Error = away:Dot( rightLadder )
			away:Normalize()
			
			--local tolerance = 5.0 + 0.25 * self:GetHullWidth()
			local tolerance = 0.25 * self:GetHullWidth()
			if math.abs( Error ) > tolerance then
			
				if away:Dot( rightLadder ) > 0.0 then
				
					self:PressLeft()
					
				else
					
					self:PressRight()
					
				end
				
			end
			
		end
		
	else
		
		if !self:InVehicle() then
		
			if ahead > 0.25 then
				
				self:PressForward()
				
			elseif ahead < -0.25 then
				
				self:PressBack()
				
			end
			
			if side <= -0.25 then
				
				self:PressLeft()
			
			elseif side >= 0.25 then
				
				self:PressRight()
				
			end
			
		else
			
			local currentVehicle = self:GetVehicle()
			if IsValid( currentVehicle ) then
				
				self:PressForward()
				
				local turnAngle = ( pos - currentVehicle:GetPos() ):Angle()
				local diff = math.AngleDifference( currentVehicle:GetAngles().y, turnAngle.y )
				if 15 < diff then
					
					self:PressRight()
					
				elseif 15 > diff then
					
					self:PressLeft()
					
				end
				
			end
			
		end
		
	end
	
end

function BOT:ApproachAscendingLadder()

	if !IsValid( self.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if self:GetPos().z >= self.LadderInfo:GetTop().z - self:GetStepSize() then
	
		self.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_TOP
		
	end
	
	if self:GetPos().z <= self.LadderInfo:GetBottom().z - self:GetMaxJumpHeight() then
	
		return NO_LADDER
		
	end
	
	self:FaceTowards( self.LadderInfo:GetBottom() )
	
	self:Approach( self.LadderInfo:GetBottom() )
	
	if self:Is_On_Ladder() then
	
		return ASCENDING_LADDER
		
	end
	
	return APPROACHING_ASCENDING_LADDER
	
end

function BOT:ApproachDescendingLadder()

	if !IsValid( self.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if self:GetPos().z <= self.LadderInfo:GetBottom().z + self:GetMaxJumpHeight() then
	
		self.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_BOTTOM
		
	end
	
	local mountPoint = self.LadderInfo:GetTop() + 0.25 * self:GetHullWidth() * self.LadderInfo:GetNormal()
	local to = mountPoint - self:GetPos()
	to.z = 0.0
	
	local mountRange = to:Length()
	to:Normalize()
	local moveGoal = nil
	
	if mountRange < 10.0 then
	
		moveGoal = self:GetPos() + 100 * self:GetMotionVector()
		
	else
	
		if to:Dot( self.LadderInfo:GetNormal() ) < 0.0 then
		
			moveGoal = self.LadderInfo:GetTop() - 100 * self.LadderInfo:GetNormal()
			
		else
		
			moveGoal = self.LadderInfo:GetTop() + 100 * self.LadderInfo:GetNormal()
			
		end
	
	end
	
	self:FaceTowards( moveGoal )
	
	self:Approach( moveGoal )
	
	if self:Is_On_Ladder() then
	
		return DESCENDING_LADDER
		
	end
	
	return APPROACHING_DESCENDING_LADDER
	
end	

function BOT:AscendLadder()

	if !IsValid( self.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if !self:Is_On_Ladder() then
	
		self.LadderInfo = nil
		return NO_LADDER
		
	end
	
	if self.LadderDismountGoal:HasAttributes( NAV_MESH_CROUCH ) then
	
		self:PressCrouch()
		
	end
	
	if self:GetPos().z >= self.LadderInfo:GetTop().z then
	
		self.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_TOP
		
	end
	
	local goal = self:GetPos() + 100 * ( -self.LadderInfo:GetNormal() + Vector( 0, 0, 2 ) )
	
	self:AimAtPos( goal, 0.1, MAXIMUM_PRIORITY )
	
	self:Approach( goal )
	
	return ASCENDING_LADDER
	
end

function BOT:DescendLadder()

	if !IsValid( self.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if !self:Is_On_Ladder() then
	
		self.LadderInfo = nil
		return NO_LADDER
		
	end
	
	if self:GetPos().z <= self.LadderInfo:GetBottom().z + self:GetStepSize() then
	
		self.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_BOTTOM
		
	end
	
	local goal = self:GetPos() + 100 * ( self.LadderInfo:GetNormal() + Vector( 0, 0, -2 ) )
	
	self:AimAtPos( goal, 0.1, MAXIMUM_PRIORITY )
	
	self:Approach( goal )
	
	return DESCENDING_LADDER
	
end

function BOT:DismountLadderTop()

	if !IsValid( self.LadderInfo ) or self.LadderTimer <= CurTime() then
	
		self.LadderInfo = nil
		return NO_LADDER
		
	end
	
	local toGoal = self.LadderDismountGoal:GetCenter() - self:GetPos()
	toGoal.z = 0.0
	local range = toGoal:Length()
	toGoal:Normalize()
	toGoal.z = 1.0
	
	self:AimAtPos( self:GetShootPos() + 100 * toGoal, 0.1, MAXIMUM_PRIORITY )
	
	self:Approach( self:GetPos() + 100 * toGoal )
	
	if self:GetLastKnownArea() == self.LadderDismountGoal and range < 10.0 then
	
		self.LadderInfo = nil
		return NO_LADDER
		
	elseif self.LadderDismountGoal == self.LadderInfo:GetTopBehindArea() and self:Is_On_Ladder() then
		
		self:PressJump()
		
	end
	
	return DISMOUNTING_LADDER_TOP
	
end

function BOT:DismountLadderBottom()

	if !IsValid( self.LadderInfo ) or self.LadderTimer <= CurTime() then
	
		self.LadderInfo = nil
		return NO_LADDER
		
	end
	
	if self:Is_On_Ladder() then
	
		self:PressJump()
		self.LadderInfo = nil
		
	end
	
	return NO_LADDER
	
end

function BOT:TraverseLadder()
	
	if self.LadderState == APPROACHING_ASCENDING_LADDER then
	
		self.LadderState = self:ApproachAscendingLadder()
		return true
		
	elseif self.LadderState == APPROACHING_DESCENDING_LADDER then
	
		self.LadderState = self:ApproachDescendingLadder()
		return true
	
	elseif self.LadderState == ASCENDING_LADDER then
	
		self.LadderState = self:AscendLadder()
		return true
	
	elseif self.LadderState == DESCENDING_LADDER then
	
		self.LadderState = self:DescendLadder()
		return true
	
	elseif self.LadderState == DISMOUNTING_LADDER_TOP then
	
		self.LadderState = self:DismountLadderTop()
		return true
	
	elseif self.LadderState == DISMOUNTING_LADDER_BOTTOM then
	
		self.LadderState = self:DismountLadderBottom()
		return true
	
	else
	
		self.LadderInfo = nil
		
		if self:Is_On_Ladder() then
		
			-- on ladder and don't want to be
			self:PressJump()
			
		end
		
		return false
		
	end
	
	return true

end	

function BOT:JumpOverGaps( goal, forward, right, goalRange )

	if !self:IsOnGround() or self:IsClimbingOrJumping() or self:IsAscendingOrDescendingLadder() then
	
		return false
		
	end
	
	if self:Crouching() then
	
		-- Can't jump if we're not standing
		return false
		
	end
	
	if !self.Goal then
	
		return false
		
	end
	
	local result
	local hullWidth = self:GetHullWidth()
	
	-- 'current' is the segment we are on/just passed over
	local current = self:PriorSegment( self.Goal )
	if !current then
	
		return false
		
	end
	
	local minGapJumpRange = 2.0 * hullWidth
	local gap
	
	if current.Type == PATH_JUMP_OVER_GAP then
	
		gap = current
		
	else
	
		local searchRange = goalRange
		local s = self.Goal
		while s do
		
			if searchRange > minGapJumpRange then
			
				break
				
			end
			
			if s.Type == PATH_JUMP_OVER_GAP then
			
				gap = s
				break
				
			end
			
			searchRange = searchRange + s.Length
			s = self:NextSegment( s )
			
		end
		
	end
	
	if gap then
	
		local halfWidth = hullWidth / 2.0
		
		if self:IsGap( self:GetPos() + halfWidth * gap.Forward, gap.Forward ) then
		
			-- There is a gap to jump over
			local landing = self:NextSegment( gap )
			if landing then
			
				self:JumpAcrossGap( landing.Pos, landing.Forward )
				
				-- If we're jumping over a gap, make sure our goal is the landing so we aim for it
				self.Goal = landing
				
				return true
				
			end
			
		end
		
	end
	
	return false
	
end

function BOT:Climbing( goal, forward, right, goalRange )

	local myArea = self:GetLastKnownArea()
	
	-- Use the 2D direction towards our goal
	local climbDirection = Vector( forward.x, forward.y, 0 )
	climbDirection:Normalize()
	
	-- We can't have this as large as our hull width, or we'll find ledges ahead of us
	-- that we will fall from when we climb up because our hull wont actually touch at the top.
	local ledgeLookAheadRange = self:GetHullWidth() - 1
	
	if !self:IsOnGround() or self:IsClimbingOrJumping() or self:IsAscendingOrDescendingLadder() then
	
		return false
		
	end
	
	if !self.Goal then
	
		return false
		
	end
	
	if TBotCheaperClimbing:GetBool() then
	
		-- Trust what the nav mesh tells us.
		-- We have been told not to do the expensive ledge-finding.
	
		if self.Goal.Type == PATH_CLIMB_UP then
		
			local afterClimb = self:NextSegment( self.Goal )
			if afterClimb and IsValid( afterClimb.Area ) then
			
				-- Find the closest point on climb-destination area
				local nearClimbGoal = afterClimb.Area:GetClosestPointOnArea( self:GetPos() )
				
				climbDirection = nearClimbGoal - self:GetPos()
				climbDirection.z = 0.0
				climbDirection:Normalize()
				
				if self:ClimbUpToLedge( nearClimbGoal, climbDirection, nil ) then
				
					return true
					
				end
				
			end
			
		end
		
		return false
		
	end
	
	-- If we're approaching a CLIMB_UP link, save off the height delta for it, and trust the nav *just* enough
	-- to climb up to that ledge and only that ledge.  We keep as large a tolerance as possible, to trust
	-- the nav as little as possible.  There's no valid way to have another CLIMB_UP link within crouch height,
	-- because we can't actually fit in between the two areas, so one climb is invalid.
	local climbUpLedgeHeightDelta = -1.0
	local ClimbUpToLedgeTolerance = self:GetCrouchHullHeight()
	
	if self.Goal.Type == PATH_CLIMB_UP then
	
		local afterClimb = self:NextSegment( self.Goal )
		if afterClimb and IsValid( afterClimb.Area ) then
		
			-- Find the closest point on climb-destination area
			local nearClimbGoal = afterClimb.Area:GetClosestPointOnArea( self:GetPos() )
			
			climbDirection = nearClimbGoal - self:GetPos()
			climbUpLedgeHeightDelta = climbDirection.z
			climbDirection.z = 0.0
			climbDirection:Normalize()
			
		end
		
	end
	
	-- Don't try to climb up stairs
	if ( IsValid( self.Goal.Area ) and self.Goal.Area:HasAttributes( NAV_MESH_STAIRS ) ) or ( IsValid( myArea ) and myArea:HasAttributes( NAV_MESH_STAIRS ) ) then
	
		return false
		
	end
	
	-- 'current' is the segment we are on/just passed over
	local current = self:PriorSegment( self.Goal )
	if !current then
	
		return false
		
	end
	
	-- If path segment immediately ahead of us is not obstructed, don't try to climb.
	-- This is required to try to avoid accidentally climbing onto valid high ledges when we really want to run UNDER them to our destination.
	-- We need to check "immediate" traversability to pay attention to breakable objects in our way that we should climb over.
	-- We also need to check traversability out to 2 * ledgeLookAheadRange in case our goal is just before a tricky ledge climb and once we pass the goal it will be too late.
	-- When we're in a CLIMB_UP segment, allow us to look for ledges - we know the destination ledge height, and will only grab the correct ledge.
	local toGoal = self.Goal.Pos - self:GetPos()
	toGoal:Normalize()
	
	if toGoal.z < 0.6 and !self.IsStuck and self.Goal.Type != PATH_CLIMB_UP and self:IsPotentiallyTraversable( self:GetPos(), self:GetPos() + 2.0 * ledgeLookAheadRange * toGoal ) then
	
		return false
		
	end
	
	-- Determine if we're approaching a planned climb.
	-- Start with current, the segment we are currently traversing.  Skip the distance check for that segment, because
	-- the pos is (hopefully) behind us.  And if it's a long path segment, it's already outside the climbLookAheadRange,
	-- and thus it would prevent us looking at m_goal and further for imminent planned climbs.
	local isPlannedClimbImminent = false
	local plannedClimbZ = 0.0
	local s = current
	while s do
	
		if s != current and ( s.Pos - self:GetPos() ):AsVector2D():IsLengthGreaterThan( 150 ) then
		
			break
			
		end
		
		if s.Type == PATH_CLIMB_UP then
		
			isPlannedClimbImminent = true
			
			local nextSegment = self:NextSegment( s )
			if nextSegment then
			
				plannedClimbZ = nextSegment.Pos.z
				
			end
			break
			
		end
		
		s = self:NextSegment( s )
		
	end
	
	local result = {}
	
	local hullWidth = self:GetHullWidth()
	local halfSize = hullWidth / 2.0
	local minHullHeight = self:GetCrouchHullHeight()
	local minLedgeHeight = self:GetStepSize() + 0.1
	
	local skipStepHeightHullMin = Vector( -halfSize, -halfSize, minLedgeHeight )
	
	-- Need to use minimum actual hull height here to catch porous fences and railings
	local skipStepHeightHullMax = Vector( halfSize, halfSize, minHullHeight + 0.1 )
	
	-- Find the highest height we can stand at our current location.
	-- Using the full width hull catches on small lips/ledges, so back up and try again.
	local ceilingFraction
	
	-- Instead of IsPotentiallyTraversable, we back up the same distance and use a second upward trace
	-- to see if that one finds a higher ceiling.  If so, we use that ceiling height, and use the
	-- backed-up feet position for the ledge finding traces.
	local feet = self:GetPos()
	local ceiling = feet + Vector( 0, 0, self:GetMaxJumpHeight() )
	util.TraceHull( { start = feet, endpos = ceiling, maxs = skipStepHeightHullMax, mins = skipStepHeightHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
	ceilingFraction = result.Fraction
	local isBackupTraceUsed = false
	if ceilingFraction < 1.0 or result.StartSolid then
	
		local backupTrace = {}
		local backupDistance = hullWidth * 0.25
		local backupFeet = feet - climbDirection * backupDistance
		local backupCeiling = backupFeet + Vector( 0, 0, self:GetMaxJumpHeight() )
		util.TraceHull( { start = backupFeet, endpos = backupCeiling, maxs = skipStepHeightHullMax, mins = skipStepHeightHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = backupTrace } )
		if !backupTrace.StartSolid and backupTrace.Fraction > ceilingFraction then
		
			result = backupTrace
			ceilingFraction = result.Fraction
			feet = backupFeet
			ceiling = backupCeiling
			isBackupTraceUsed = true
			
		end
		
	end
	
	local maxLedgeHeight = ceilingFraction * self:GetMaxJumpHeight()
	
	if maxLedgeHeight <= self:GetStepSize() then
	
		return false
		
	end
	
	-- Check for ledge climbs over things in our way.
	-- Even if we have a CLIMB_UP link in our path, we still need
	-- to find the actual ledge by tracing the local geometry.
	
	local climbHullMax = Vector( halfSize, halfSize, maxLedgeHeight )
	local ledgePos = Vector( feet ) -- to be computed below
	
	util.TraceHull( { start = feet, endpos = feet + climbDirection * ledgeLookAheadRange, maxs = climbHullMax, mins = skipStepHeightHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
	
	if result.Hit and !result.StartSolid then
	
		local obstacle = result.Entity
		
		-- EFL_DONTWALKON = 67108864 - NPCs should not walk on this entity
		if !result.HitNonWorld or ( IsValid( obstacle ) and !obstacle:IsDoor() and !obstacle:IsEFlagSet( 67108864 ) ) then
		
			-- The low hull sweep hit an obstacle - note how 'far in' this is
			local ledgeFrontWallDepth = ledgeLookAheadRange * result.Fraction
			
			local minLedgeDepth = self:GetHullWidth() / 2.0
			if self.Goal.Type == PATH_CLIMB_UP then
			
				-- Climbing up to a narrow nav area indicates a narrow ledge.  We need to reduce our minLedgeDepth
				-- here or our path will say we should climb but we'll forever fail to find a wide enough ledge.
				local afterClimb = self:NextSegment( self.Goal )
				if afterClimb and IsValid( afterClimb.Area ) then
				
					local depthVector = climbDirection * minLedgeDepth
					depthVector.z = 0.0
					if math.abs( depthVector.x ) > afterClimb.Area:GetSizeX() then
					
						depthVector.x = Either( depthVector.x > 0, afterClimb.Area:GetSizeX(), -afterClimb.Area:GetSizeX() )
						
					end
					if math.abs( depthVector.y ) > afterClimb.Area:GetSizeY() then
					
						depthVector.y = Either( depthVector.y > 0, afterClimb.Area:GetSizeY(), -afterClimb.Area:GetSizeY() )
						
					end
					
					minLedgeDepth = math.min( minLedgeDepth, depthVector:Length() )
					
				end
				
			end
			
			-- Find the ledge.  Start at the lowest jump we can make
			-- and step up until we find the actual ledge.  
			--
			-- The scan is limited to maxLedgeHeight in case our max 
			-- jump/climb height is so tall the highest horizontal hull 
			-- trace could be on the other side of the ceiling above us
			
			local ledgeHeight = minLedgeHeight
			local ledgeHeightIncrement = 0.5 * self:GetStepSize()
			
			local foundWall = false
			local foundLedge = false
			
			-- once we have found the ledge's front wall, we must look at least minLedgeDepth farther in to verify it is a ledge
			-- NOTE: This *must* be ledgeLookAheadRange since ledges are compared against the initial trace which was ledgeLookAheadRange deep
			local ledgeTopLookAheadRange = ledgeLookAheadRange
			
			local climbHullMin = Vector( -halfSize, -halfSize, 0.0 )
			climbHullMax.x = halfSize
			climbHullMax.y = halfSize
			climbHullMax.z = minHullHeight
			
			--local wallPos
			local wallDepth = 0.0
			
			local isLastIteration = false
			while true do
			
				-- trace forward to find the wall in front of us, or the empty space of the ledge above us
				util.TraceHull( { start = feet + Vector( 0, 0, ledgeHeight ), endpos = feet + Vector( 0, 0, ledgeHeight ) + climbDirection * ledgeTopLookAheadRange, maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
				
				local traceDepth = ledgeTopLookAheadRange * result.Fraction
				
				if !result.StartSolid then
				
					-- if trace reached minLedgeDepth farther, this is a potential ledge
					if foundWall then
					
						if ( traceDepth - ledgeFrontWallDepth ) > minLedgeDepth then
						
							local isUsable = true
							
							-- initialize ledgePos from result of last trace
							ledgePos = result.HitPos
							
							-- Find the actual ground level on the potential ledge
							-- Only trace back down to the previous ledge height trace. 
							-- The ledge can be no lower, or we would've found it in the last iteration.
							util.TraceHull( { start = ledgePos, endpos = ledgePos + Vector( 0, 0, -ledgeHeightIncrement ), maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
							
							ledgePos = result.HitPos
							
							-- if the whole trace is in solid, we're out of luck, but
							-- if the trace just started solid, 'ledgePos' should still be valid
							-- since the trace left the solid and then hit.
							-- if the trace hit nothing, the potential ledge is actually deeper in
							-- players can't stand on ground steeper than 0.7
							if result.AllSolid or !result.Hit or result.HitNormal.z < 0.7 then
							
								-- Not a usable ledge, try again
								isUsable = false
								
							else
							
								if climbUpLedgeHeightDelta > 0.0 then
								
									-- if we're climbing to a specific ledge via a CLIMB_UP link, only climb to that ledge.
									-- Do this only for the world (which includes static props) so we can still opportunistically
									-- climb up onto breakable railings and physics props.
									if result.HitNonWorld then
									
										local potentialLedgeHeight = result.HitPos.z - feet.z
										if math.abs( potentialLedgeHeight - climbUpLedgeHeightDelta ) > ClimbUpToLedgeTolerance then
										
											isUsable = false
											
										end
										
									end
									
								end
								
							end
							
							if isUsable then
							
								-- back up until we no longer are hitting the ledge to determine the
								-- exact ledge edge position
								local validLedgePos = Vector( ledgePos )
								local maxBackUp = hullWidth
								local backUpSoFar = 4.0
								local testPos = ledgePos
								
								while backUpSoFar < maxBackUp do
								
									testPos = testPos - 4.0 * climbDirection
									backUpSoFar = backUpSoFar + 4.0
									
									util.TraceHull( { start = testPos, endpos = testPos + Vector( 0, 0, -ledgeHeightIncrement ), maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
									
									if result.Hit and result.HitNormal.z >= 0.7 then
									
										-- We hit, this is closer to the actual ledge edge
										ledgePos = result.HitPos
										
									else
									
										-- Nothing but air or a steep slope below us, we have found the edge
										break
										
									end
									
								end
								
								-- We want ledgePos to be right on the edge itself, so move 
								-- it ahead by half of the hull width
								ledgePos = ledgePos + climbDirection * halfSize
								
								-- Make sure this doesn't embed us in the far wall if the ledge is narrow, since we would
								-- have backed up less than halfSize.
								local climbHullMinStep = Vector( climbHullMin ) -- Skip StepHeight for sloped ledges
								util.TraceHull( { start = validLedgePos, endpos = ledgePos, maxs = climbHullMax, mins = climbHullMinStep, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
								
								ledgePos = result.HitPos
								
								-- Now since ledgePos + StepHeight is valid, trace down to find ground on sloped ledges.
								util.TraceHull( { start = ledgePos + Vector( 0, 0, self:GetStepSize() ), endpos = ledgePos, maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
								
								if !result.StartSolid then
								
									ledgePos = result.HitPos
									
								end
								
							end
							
							if isUsable then
							
								-- Found a useable ledge here
								foundLedge = true
								break
								
							end
							
						end
						
					elseif result.Hit then
					
						-- this iteration hit the wall under the ledge, 
						-- meaning the next iteration that reaches far enough will be our ledge

						-- Since we know that our desired route is likely blocked (via the 
						-- IsTraversable check above) - any ledge we hit we must climb.

						-- found a valid ledge wall
						foundWall = true
						wallDepth = traceDepth
						
						-- make sure the subsequent traces are at least minLedgeDepth deeper than
						-- the wall we just found, or all ledge checks will fail
						local minTraceDepth = traceDepth + minLedgeDepth + 0.1
						
						if ledgeTopLookAheadRange < minTraceDepth then
						
							ledgeTopLookAheadRange = minTraceDepth
							
						end
						
					elseif ledgeHeight > self:GetCrouchHullHeight() and !isPlannedClimbImminent then
					
						-- We haven't hit anything yet, and we're already above our heads - no obstacle
						break
						
					end
					
				end
				
				ledgeHeight = ledgeHeight + ledgeHeightIncrement
				
				if ledgeHeight >= maxLedgeHeight then
					
					if isLastIteration then
						
						-- Tested at max height
						break
						
					end
					
					-- Check one more time at max jump height
					isLastIteration = true
					ledgeHeight = maxLedgeHeight
					
				end
				
			end
			
			if foundLedge then
			
				if !self:ClimbUpToLedge( ledgePos, climbDirection, obstacle ) then
				
					return false
					
				end
				
				return true
				
			end
		
		end
		
	end
	
	return false
	
end

function BOT:IsDiscontinuityAhead( type, range )

	if self.Goal then
	
		local current = self:PriorSegment( self.Goal )
		if current and current.Type == type then
		
			-- We're on the discontinuity now
			return true
			
		end
		
		local rangeSoFar = self.Goal.Pos:Distance( self:GetPos() )
		
		local s = self.Goal
		while s do
		
			if rangeSoFar >= range then
			
				break
				
			end
			
			if s.Type == type then
			
				return true
				
			end
			
			rangeSoFar = rangeSoFar + s.Length
			
			s = self:NextSegment( s )
			
		end
		
	end
	
	return false
	
end

function BOT:IsClimbPossible( obstacle )

	if self:IsPathValid() then
	
		if !self:IsDiscontinuityAhead( PATH_CLIMB_UP, 75 ) then
		
			-- Always allow climbing over moveable obstacles
			if IsValid( obstacle ) and !obstacle:IsWorld() then
			
				local physics = obstacle:GetPhysicsObject()
				if IsValid( physics ) and physics:IsMoveable() then
				
					-- Moveable physics object - climb over it
					return true
					
				end
				
			end
			
			if !self.IsStuck then
			
				-- we're not stuck - don't try to jump up yet
				return false
				
			end
			
		end
		
	end
	
	return true
	
end

function BOT:JumpAcrossGap( landingGoal, landingForward )

	self:PressJump()
	
	-- Face forward
	self:AimAtPos( landingGoal, 1.0, HIGH_PRIORITY )
	
	self.IsJumpingAcrossGap = true
	self.LandingGoal = landingGoal
	self.HasLeftTheGround = false
	
end

function BOT:ClimbUpToLedge( landingGoal, landingForward, obstacle )

	if !self:IsClimbPossible( obstacle ) then
	
		return false
		
	end
	
	self:PressJump()
	
	self.IsClimbingUpToLedge = true
	self.LandingGoal = landingGoal
	self.HasLeftTheGround = false
	
	return true
	
end

-- Make the bot move.
function BOT:TBotUpdateMovement()
	
	--local MovementAngle		=	self:EyeAngles()
	
	if self.Goal and self:IsPathValid() then
		
		--MovementAngle		=	( ( self.Path[ 1 ][ "Pos" ] + self:GetCurrentViewOffset() ) - self:GetShootPos() ):GetNormalized():Angle()
		
		--[[if isvector( self.Path[ 1 ][ "Check" ] ) then
			MovementAngle = ( ( self.Path[ 1 ][ "Check" ] + self:GetCurrentViewOffset() ) - self:GetShootPos() ):GetNormalized():Angle()
			
			local CheckIn2D			=	Vector( self.Path[ 1 ][ "Check" ].x , self.Path[ 1 ][ "Check" ].y , self:GetPos().z )
			
			if IsVecCloseEnough( self:GetPos() , CheckIn2D , 24 ) then
				
				self.Path[ 1 ][ "Check" ] = nil
				return
			end
			
			if SendBoxedLine( self:GetPos() , CheckIn2D ) == true then
			
				self.Path[ 1 ][ "Check" ] = nil
			end
		end]]
		
		if self:LadderUpdate() then
			
			-- we are traversing a ladder
			return
			
		end
		
		if self:CheckProgress() == false then
		
			return
			
		end
		
		-- TODO: Is this better than forcing the bot to jump?
		--[[if self:OnGround() and !self:Is_On_Ladder() and ( !IsValid( self.Goal.Area ) or !self.Goal.Area:HasAttributes( NAV_MESH_STAIRS ) ) and self.Goal.Type == PATH_JUMP_OVER_GAP then
			local SmartJump		=	util.TraceLine({
				
				start			=	self:GetPos(),
				endpos			=	self:GetPos() + Vector( 0 , 0 , -16 ),
				filter			=	self,
				mask			=	MASK_SOLID,
				collisiongroup	=	COLLISION_GROUP_DEBRIS
				
			})
			
			-- This tells the bot to jump if it detects a gap in the ground
			if SmartJump.Fraction >= 1.0 and !SmartJump.StartSolid then
				
				self:PressJump()

			end
			
			local aheadRay = Vector( self.Goal.Pos.x - self:GetPos().x, self.Goal.Pos.y - self:GetPos().y, 0 ):Normalize()
			local jumped = false
			
			if self:KeyDown( IN_SPEED ) then
			
				local farLookAheadRange = 80
				local stepAhead = self:GetPos() + farLookAheadRange * aheadRay
				stepAhead.z = stepAhead.z + HalfHumanHeight.z
				local ground, normal = navmesh.GetGroundHeight( stepAhead )
				if ground and isvector( normal ) then
				
					if normal.z > 0.9 and ( ground - self:GetPos().z ) < -64 then
					
						self:PressJump()
						jumped = true
						
					end
					
				end
				
			end
			
			if !jumped then
			
				local lookAheadRange = 30
				local stepAhead = self:GetPos() + lookAheadRange * aheadRay
				stepAhead.z = stepAhead.z + HalfHumanHeight.z
				local ground = navmesh.GetGroundHeight( stepAhead )
				if ground and ( ground - self:GetPos().z ) < -64 then
				
					self:PressJump()
					jumped = true
					
				end
				
			end
			
			if !jumped then
			
				local lookAheadRange = 10
				local stepAhead = self:GetPos() + lookAheadRange * aheadRay
				stepAhead.z = stepAhead.z + HalfHumanHeight.z
				local ground = navmesh.GetGroundHeight( stepAhead )
				if ground and ( ground - self:GetPos().z ) < -64 then
				
					self:PressJump()
					jumped = true
					
				end
				
			end
			
		end]]
		
		local forward = self.Goal.Pos - self:GetPos()
		
		if self.Goal.Type == PATH_CLIMB_UP then
		
			local nextSegment = self:NextSegment( self.Goal )
			if nextSegment then
			
				forward = nextSegment.Pos - self:GetPos()
				
			end
			
		end
		
		forward.z = 0.0
		local goalRange = forward:Length()
		forward:Normalize()
		
		local left = Vector( -forward.y, forward.x, 0 )
		
		if left:IsZero() then
		
			-- If left is zero, forward must also be - path follow failure
			self:TBotClearPath()
			return
			
		end
		
		forward = left:Cross( vector_up )
		
		left = vector_up:Cross( forward )
		
		-- Climb up ledges
		if !self:Climbing( self.Goal, forward, left, goalRange ) then
		
			-- A failed climb could mean an invalid path
			if !self:IsPathValid() then
			
				return
				
			end
			
			self:JumpOverGaps( self.Goal, forward, left, goalRange )
			
		end
		
		-- Event callbacks from the above climbs and jumps may invalidate the path
		if !self:IsPathValid() then
		
			return
			
		end
		
		local goalPos = Vector( self.Goal.Pos )
		forward = goalPos - self:GetPos()
		forward.z = 0.0
		local rangeToGoal = forward:Length()
		forward:Normalize()
		
		left.x = -forward.y
		left.y = forward.x
		left.z = 0.0
		
		if rangeToGoal > 50 or ( self.Goal and self.Goal.Type != PATH_CLIMB_UP ) then
			
			goalPos = self:TBotAvoid( goalPos, forward, left )
			
		end
		
		if self:IsOnGround() then
		
			self:FaceTowards( goalPos )
			
		end
		
		local CurrentArea = self.Goal.Area
		if IsValid( CurrentArea ) then
			
			if !CurrentArea:HasAttributes( NAV_MESH_STAIRS ) and CurrentArea:HasAttributes( NAV_MESH_JUMP ) then
			
				self:PressJump()
			
			elseif CurrentArea:HasAttributes( NAV_MESH_CROUCH ) and CurrentArea:GetClosestPointOnArea( self:GetPos() ):DistToSqr( self:GetPos() ) <= 2500 then
			
				self:PressCrouch()
			
			end
			
			if CurrentArea:HasAttributes( NAV_MESH_WALK ) then
			
				self:PressWalk()
				
			elseif CurrentArea:HasAttributes( NAV_MESH_RUN ) then
			
				self:PressRun()
				
			end
			
		end
		
		self:Approach( goalPos )
		
		-- Currently, Approach determines STAND or CROUCH. 
		-- Override this if we're approaching a climb or a jump
		if self.Goal and ( self.Goal.Type == PATH_CLIMB_UP or self.Goal.Type == PATH_JUMP_OVER_GAP ) then
		
			self:ReleaseCrouch()
			
		end
		
	--[[elseif isvector( self.Goal ) then
		
		--MovementAngle		=	( self.Goal - self:GetShootPos() ):GetNormalized():Angle()
		
		if self:OnGround() and ( !IsValid( self:GetLastKnownArea() ) or !self:GetLastKnownArea():HasAttributes( NAV_MESH_STAIRS ) ) then
			local SmartJump		=	util.TraceLine({
				
				start			=	self:GetPos(),
				endpos			=	self:GetPos() + Vector( 0 , 0 , -16 ),
				filter			=	self,
				mask			=	MASK_SOLID,
				collisiongroup	=	COLLISION_GROUP_DEBRIS
				
			})
			
			-- This tells the bot to jump if it detects a gap in the ground
			if !SmartJump.Hit then
				
				self:PressJump()

			end
		end
		
		local goalPos = Vector( self.Goal )
		local forward = goalPos - self:GetPos()
		forward.z = 0.0
		forward:Normalize()
		
		if self:ShouldJump( self:GetPos(), self.Goal ) then
		
			self:PressJump()
			
		else
			
			goalPos = self:TBotAvoid( goalPos, forward, Vector( -forward.y, forward.x, 0 ) )
		
		end
		
		forward = self:EyeAngles():Forward()
		forward.z = 0.0
		forward:Normalize()
		
		local right = Vector( forward.y, -forward.x, 0 )
		
		local to = goalPos - self:GetPos()
		to.z = 0.0
		to:Normalize()
		
		local ahead = to:Dot( forward )
		local side = to:Dot( right )
		
		if !self:InVehicle() then
		
			if ahead > 0.25 then
			
				self:PressForward()
				
			elseif ahead < -0.25 then
			
				self:PressBack()
				
			end
			
			if side <= -0.25 then
			
				self:PressLeft()
				
			elseif side >= 0.25 then
			
				self:PressRight()
				
			end
			
		else
			
			local currentVehicle = self:GetVehicle()
			if IsValid( currentVehicle ) then
			
				self:PressForward()
				
				local turnAngle = ( self.Goal - currentVehicle:GetPos() ):Angle()
				local diff = math.AngleDifference( currentVehicle:GetAngles().y, turnAngle.y )
				if 15 < diff then
				
					self:PressRight()
				
				elseif 15 > diff then
					
					self:PressLeft()
					
				end
				
			end
			
		end
		
		--self:PressForward()
		
		local GoalIn2D			=	Vector( self.Goal.x , self.Goal.y , self:GetPos().z )
		if IsVecCloseEnough( self:GetPos() , GoalIn2D , 32 ) then
			
			self:TBotClearPath() -- We have reached our goal!
			return
			
		end
		
		if self:IsOnGround() then self:FaceTowards( self.Goal )
		elseif self:Is_On_Ladder() then self:AimAtPos( self.Goal + self:GetCurrentViewOffset(), 0.1, MAXIMUM_PRIORITY ) end
		]]
	end
	
	--cmd:SetViewAngles( self:EyeAngles() )
	
end

function BOT:TBotUpdateLocomotion()

	if self:TraverseLadder() then
	
		return
		
	end

	if self.IsJumpingAcrossGap or self.IsClimbingUpToLedge then
		
		local toLanding = self.LandingGoal - self:GetPos()
		toLanding.z = 0.0
		toLanding:Normalize()
		
		if self.HasLeftTheGround then
			
			self:AimAtPos( self:GetShootPos() + 100 * toLanding, 0.25, MAXIMUM_PRIORITY )
			
			if self:IsOnGround() then
				
				-- Back on the ground - jump is complete
				self.IsClimbingUpToLedge = false
				self.IsJumpingAcrossGap = false
				
			end
			
		else
			-- Haven't left the ground yet - just starting the jump
			if !self:IsClimbingOrJumping() then
				
				self:PressJump()
				
			end
			
			if self.IsJumpingAcrossGap then
				
				self:PressRun()
				
			end
			
			if !self:IsOnGround() then
				
				-- Jump has begun
				self.HasLeftTheGround = true
				
			end
			
		end
		
		self:Approach( self.LandingGoal )
		
	end
	
end

function BOT:TBotAvoid( goalPos, forward, left )

	if self.AvoidTimer > CurTime() then
	
		return goalPos
		
	end

	self.AvoidTimer = CurTime() + 0.5
	
	if self:IsClimbingOrJumping() or !self:IsOnGround() then
	
		return goalPos
		
	end
	
	local area = self:GetLastKnownArea()
	if IsValid( area ) and area:HasAttributes( NAV_MESH_PRECISE ) then 
	
		return goalPos 
		
	end
	
	local size = self:GetHullWidth() / 4
	local offset = size + 2
	local range = Either( self:KeyDown( IN_SPEED ), 50, 30 )
	range = range * self:GetModelScale()
	local door = nil
	
	local hullMin = Vector( -size, -size, self:GetStepSize() + 0.1 )
	local hullMax = Vector( size, size, self:GetCrouchHullHeight() )
	--local nextStepHullMin = Vector( -size, -size, 2.0 * self:GetStepSize() + 0.1 )
	
	local leftFrom = self:GetPos() + offset * left
	local leftTo = leftFrom + range * forward
	local isLeftClear = true
	local leftAvoid = 0.0
	
	local result = {}
	util.TraceHull( { start = leftFrom, endpos = leftTo, maxs = hullMax, mins = hullMin, filter = self, mask = MASK_PLAYERSOLID, output = result } )
	if result.Fraction < 1.0 or result.StartSolid then
	
		if result.StartSolid then
		
			result.Fraction = 0.0
			
		end
		
		leftAvoid = math.Clamp( 1.0 - result.Fraction, 0.0, 1.0 )
		isLeftClear = false
		
		if result.HitNonWorld then
		
			door = result.Entity
			
		end
		
	end
	
	local rightFrom = self:GetPos() - offset * left
	local rightTo = rightFrom + range * forward
	local isRightClear = true
	local rightAvoid = 0.0
	
	util.TraceHull( { start = rightFrom, endpos = rightTo, maxs = hullMax, mins = hullMin, filter = self, mask = MASK_PLAYERSOLID, output = result } )
	if result.Fraction < 1.0 or result.StartSolid then
	
		if result.StartSolid then
		
			result.Fraction = 0.0
			
		end
		
		rightAvoid = math.Clamp( 1.0 - result.Fraction, 0.0, 1.0 )
		isRightClear = false
		
		if !IsValid( door ) and result.HitNonWorld then
		
			door = result.Entity
			
		end
		
	end
	
	if GetConVar( "developer" ):GetBool() then
		
		if isLeftClear then
		
			debugoverlay.SweptBox( leftFrom, leftTo, hullMin, hullMax, angle_zero, 0.1, Color( 0, 255, 0 ) )
			
		else
		
			debugoverlay.SweptBox( leftFrom, leftTo, hullMin, hullMax, angle_zero, 0.1, Color( 255, 0, 0 ) )
			
		end
		
		if isRightClear then
		
			debugoverlay.SweptBox( rightFrom, rightTo, hullMin, hullMax, angle_zero, 0.1, Color( 0, 255, 0 ) )
			
		else
		
			debugoverlay.SweptBox( rightFrom, rightTo, hullMin, hullMax, angle_zero, 0.1, Color( 255, 0, 0 ) )
			
		end
		
	end
	
	local adjustedGoal = goalPos
	
	if IsValid( door ) and !isLeftClear and !isRightClear then
	
		local forward = door:GetForward()
		local right = door:GetRight()
		local up = door:GetUp()
		
		local doorWidth = 100
		local doorEdge = door:GetPos() - doorWidth * right
		
		adjustedGoal.x = doorEdge.x
		adjustedGoal.y = doorEdge.y
		self.AvoidTimer = 0
		
	elseif !isLeftClear or !isRightClear then
	
		local avoidResult = 0.0
		if isLeftClear then
		
			avoidResult = -rightAvoid
			
		elseif isRightClear then
		
			avoidResult = leftAvoid
			
		else
		
			local equalTolerance = 0.01
			if math.abs( rightAvoid - leftAvoid ) < equalTolerance then
			
				return adjustedGoal
				
			elseif rightAvoid > leftAvoid then
			
				avoidResult = -rightAvoid
				
			else
			
				avoidResult = leftAvoid
				
			end
			
		end
		
		local avoidDir = 0.5 * forward - left * avoidResult
		avoidDir:Normalize()
		
		adjustedGoal = self:GetPos() + 100 * avoidDir
		
		self.AvoidTimer = 0
	
	end
	
	return adjustedGoal

end

function CalcClosestPointOnLineT( P, vLineA, vLineB )

	local vDir = vLineB - vLineA
	local div = vDir:Dot( vDir )
	if div < 0.00001 then
	
		return 0, vDir
		
	else
	
		return ( vDir:Dot( P ) - vDir:Dot( vLineA ) ) / div, vDir
		
	end
	
end

function CalcClosestPointOnLine( P, vLineA, vLineB )

	local t, vDir = CalcClosestPointOnLineT( P, vLineA, vLineB )

	return vLineA + vDir * t
end

local function NumberMidPoint( num1 , num2 )
	
	local sum = num1 + num2
	
	return sum / 2
	
end

function CalcClosestPointOnLineSegment( P, vLineA, vLineB )

	local t, vDir = CalcClosestPointOnLineT( P, vLineA, vLineB )
	t = math.Clamp( t, 0.0, 1.0 )
	
	return t, vLineA + vDir * t
	
end

function Zone:ComputePortal( TargetArea, dir )
	if !IsValid( TargetArea ) then return end
	
	local NORTH = 0 -- NORTH_WEST
	local EAST = 1 -- NORTH_EAST
	local SOUTH = 2 -- SOUTH_EAST
	local WEST = 3 -- SOUTH_WEST
	local center = Vector()
	local halfWidth = 0
	
	if dir == NORTH or dir == SOUTH then
		
		if dir == NORTH then
		
			center.y = self:GetCorner( NORTH ).y
			
		else
		
			center.y = self:GetCorner( SOUTH ).y 
			
		end
		
		local left = math.max( self:GetCorner( NORTH ).x, TargetArea:GetCorner( NORTH ).x )
		local right = math.min( self:GetCorner( SOUTH ).x, TargetArea:GetCorner( SOUTH ).x )
		
		if left < self:GetCorner( NORTH ).x then
		
			left = self:GetCorner( NORTH ).x
			
		elseif left > self:GetCorner( SOUTH ).x then
		
			left = self:GetCorner( SOUTH ).x
			
		end
		
		if right < self:GetCorner( NORTH ).x then
		
			right = self:GetCorner( NORTH ).x
			
		elseif right > self:GetCorner( SOUTH ).x then
		
			right = self:GetCorner( SOUTH ).x
			
		end
		
		center.x = NumberMidPoint( left, right )
		halfWidth = ( right - left ) / 2.0
		
	else
		
		if dir == WEST then
		
			center.x = self:GetCorner( NORTH ).x
			
		else
		
			center.x = self:GetCorner( SOUTH ).x
			
		end
		
		local top = math.max( self:GetCorner( NORTH ).y, TargetArea:GetCorner( NORTH ).y )
		local bottom = math.min( self:GetCorner( SOUTH ).y, TargetArea:GetCorner( SOUTH ).y )
		
		if top < self:GetCorner( NORTH ).y then
		
			top = self:GetCorner( NORTH ).y 
			
		elseif top > self:GetCorner( SOUTH ).y then
		
			top = self:GetCorner( SOUTH ).y
			
		end
		
		if bottom < self:GetCorner( NORTH ).y then
		
			bottom = self:GetCorner( NORTH ).y
			
		elseif bottom > self:GetCorner( SOUTH ).y then
		
			bottom = self:GetCorner( SOUTH ).y
			
		end
		
		center.y = NumberMidPoint( top, bottom )
		halfWidth = ( bottom - top ) / 2.0
		
	end
	
	center.z = self:GetZ( center )
	
	return center, halfWidth
	
end

function Zone:ComputeNormal( alternate )

	local NORTH_WEST = 0 
	local NORTH_EAST = 1
	local SOUTH_EAST = 2
	local SOUTH_WEST = 3
	local u, v = Vector(), Vector()
	
	if !alternate then
	
		u.x = self:GetCorner( SOUTH_EAST ).x - self:GetCorner( NORTH_WEST ).x
		u.y = 0.0
		u.z = self:GetCorner( NORTH_EAST ).z - self:GetCorner( NORTH_WEST ).z
		
		v.x = 0.0
		v.y = self:GetCorner( SOUTH_EAST ).y - self:GetCorner( NORTH_WEST ).y
		v.z = self:GetCorner( SOUTH_WEST ).z - self:GetCorner( NORTH_WEST ).z
		
	else
	
		u.x = self:GetCorner( NORTH_WEST ).x - self:GetCorner( SOUTH_EAST ).x
		u.y = 0.0
		u.z = self:GetCorner( SOUTH_WEST ).z - self:GetCorner( SOUTH_EAST ).z
		
		v.x = 0.0
		v.y = self:GetCorner( NORTH_WEST ).y - self:GetCorner( SOUTH_EAST ).y
		v.z = self:GetCorner( NORTH_EAST ).z - self:GetCorner( SOUTH_EAST ).z
		
	end
	
	local normal = u:Cross( v )
	normal:Normalize()
	return normal
end

function Zone:ComputeClosestPointInPortal( TargetArea, fromPos, dir )
	if !IsValid( TargetArea ) then return end
	
	local NORTH = 0 -- NORTH_WEST
	local EAST = 1 -- NORTH_EAST
	local SOUTH = 2 -- SOUTH_EAST
	local WEST = 3 -- SOUTH_WEST
	local margin = 25
	local closePos = Vector()
	
	if dir == NORTH or dir == SOUTH then
		
		if dir == NORTH then
		
			closePos.y = self:GetCorner( NORTH ).y
			
		else
		
			closePos.y = self:GetCorner( SOUTH ).y
			
		end
		
		local left = math.max( self:GetCorner( NORTH ).x, TargetArea:GetCorner( NORTH ).x )
		local right = math.min( self:GetCorner( SOUTH ).x, TargetArea:GetCorner( SOUTH ).x )
		
		local leftMargin = Either( TargetArea:IsEdge( WEST ), left + margin, left )
		local rightMargin = Either( TargetArea:IsEdge( EAST ), right - margin, right )
		
		if leftMargin > rightMargin then
		
			local mid = NumberMidPoint( left, right )
			leftMargin = mid
			rightMargin = mid
			
		end
		
		if fromPos.x < leftMargin then
		
			closePos.x = leftMargin
			
		elseif fromPos.x > rightMargin then
		
			closePos.x = rightMargin
			
		else
		
			closePos.x = fromPos.x
			
		end
		
	else
		
		if dir == WEST then
		
			closePos.x = self:GetCorner( NORTH ).x
			
		else
		
			closePos.x = self:GetCorner( SOUTH ).x
			
		end
		
		local top = math.max( self:GetCorner( NORTH ).y, TargetArea:GetCorner( NORTH ).y )
		local bottom = math.min( self:GetCorner( SOUTH ).y, TargetArea:GetCorner( SOUTH ).y )
		
		local topMargin = Either( TargetArea:IsEdge( NORTH ), top + margin, top )
		local bottomMargin = Either( TargetArea:IsEdge( SOUTH ), bottom - margin, bottom )
		
		if topMargin > bottomMargin then
		
			local mid = NumberMidPoint( top, bottom )
			topMargin = mid
			bottomMargin = mid
			
		end
		
		if fromPos.y < topMargin then
		
			closePos.y = topMargin
			
		elseif fromPos.y > bottomMargin then
		
			closePos.y = bottomMargin
			
		else
		
			closePos.y = fromPos.y
			
		end
		
	end
	
	closePos.z = self:GetZ( closePos )
	
	--print( "TargetArea: " .. tostring( TargetArea ) )
	--print( "FromPos: " .. tostring( fromPos ) )
	--print( "Direction: " .. tostring( dir ) )
	--print( "ClosePos: " .. tostring( closePos ) )
	
	return closePos
	
end

function Zone:IsEdge( dir )

	for k,area in ipairs( self:GetAdjacentAreasAtSide( dir ) ) do
	
		if area:IsConnectedAtSide( self, OppositeDirection( dir ) ) then
			
			return false
			
		end
		
	end
	
	return true
	
end

function OppositeDirection( dir )

	local NORTH = 0 
	local EAST = 1 
	local SOUTH = 2 
	local WEST = 3 

	if dir == NORTH then
	
		return SOUTH
		
	elseif dir == SOUTH then
	
		return NORTH
		
	elseif dir == EAST then
	
		return WEST
		
	elseif dir == WEST then
	
		return EAST
		
	end
	
	return NORTH

end

function Get_Direction( FirstArea , SecondArea )
	
	if FirstArea:GetSizeX() + FirstArea:GetSizeY() > SecondArea:GetSizeX() + SecondArea:GetSizeY() then
		
		return SecondArea:ComputeDirection( SecondArea:GetClosestPointOnArea( FirstArea:GetClosestPointOnArea( SecondArea:GetCenter() ) ) )
		
	else
		
		return FirstArea:ComputeDirection( FirstArea:GetClosestPointOnArea( SecondArea:GetClosestPointOnArea( FirstArea:GetCenter() ) ) )
		
	end
	
end

-- This checks if we should drop down to reach the next node
function BOT:ShouldDropDown( currentArea, nextArea )
	if !isvector( currentArea ) or !isvector( nextArea ) then return false end
	
	return currentArea.z - nextArea.z > self:GetStepSize()
	
end

-- This checks if we should jump to reach the next node
function BOT:ShouldJump( currentArea, nextArea )
	if !isvector( currentArea ) or !isvector( nextArea ) then return false end
	
	return nextArea.z - currentArea.z > self:GetStepSize()
	
end

function BOT:IsClimbingOrJumping()

	if !self.IsJumping then
	
		return false
		
	end
	
	if self.NextJump <= CurTime() and self:IsOnGround() then
	
		self.IsJumping = false
		return false
		
	end
	
	return true
	
end

function BOT:GetMaxJumpHeight()

	return 64
	
end

function BOT:IsAscendingOrDescendingLadder()

	if self.LadderState == ASCENDING_LADDER then
	
		return true
		
	elseif self.LadderState == DESCENDING_LADDER then
	
		return true
		
	elseif self.LadderState == DISMOUNTING_LADDER_TOP then
	
		return true
		
	elseif self.LadderState == DISMOUNTING_LADDER_BOTTOM then
	
		return true
		
	end
	
	return false
	
end

function BOT:Is_On_Ladder()
	
	if self:GetMoveType() == MOVETYPE_LADDER then
		
		return true
	end
	
	return false
end

function BOT:ComputeLadderEndpoint( ladder, isAscending )
	
	local result = {}
	local from
	local to

	if isAscending then
	
		-- find actual top in case the ladder penetrates the ceiling
		-- trace from our chest height at the ladder base
		from = ladder:GetBottom() + ladder:GetNormal() * HalfHumanHeight.z
		from.z = self:GetPos().z + HalfHumanHeight.z
		to = ladder:GetTop()
	
	else
	
		-- find actual bottom in case the ladder penetrates the floor
		-- trace from our chest height at the ladder top
		from = ladder:GetTop() + ladder:GetNormal() * HalfHumanHeight.z
		from.z = self:GetPos().z + HalfHumanHeight.z
		to = ladder:GetBottom()
	end

	util.TraceLine( { start = from, endpos = ladder:GetBottom(), mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )

	if result.Fraction == 1.0 then
		return to
	else
		to.z = from.z + result.Fraction * (to.z - from.z)
		return to
	end
end

--[[function Lad:Get_Closest_Point_Next( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		-- self:GetTop() - self:GetNormal() * 16 I need to make a function to detect which side the bot should approach the ladder
		return self:GetTop(), true
	end
	
	return self:GetBottom(), false
end

function Lad:Get_Closest_Point_Current( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		-- self:GetTop() - self:GetNormal() * 16 I need to make a function to detect which side the bot should approach the ladder
		return self:GetTop() - self:GetNormal() * 16, self:GetTop(), true
	end
	
	return self:GetBottom(), self:GetBottom() + self:GetNormal() * 2.0 * 16, false
end]]

-- This grabs every internal variable of the specified entity
function Test( ply )
	for k, v in pairs( ply:GetSaveTable( true ) ) do
		
		print( k .. ": " .. v )
		
	end 
end

-- I use this function to test function runtimes
function Test2( ply, ply2 )

	local startTime = SysTime()

	for i = 1, 256 do
	
		NavAreaBuildPath( navmesh.GetNearestNavArea( ply:GetPos() ), navmesh.GetNearestNavArea( ply2:GetPos() ), ply2:GetPos(), ply )
		
	end
	
	print( "NavAreaBuildPath RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	
end

-- This creates nav ladders on func_useableladders
function Test3( absMin, absMax, maxHeightAboveTopArea, ent )
	
	local NORTH = 0 
	local EAST = 1 
	local SOUTH = 2 
	local WEST = 3
	local NUM_DIRECTIONS = 4
	
	maxHeightAboveTopArea = tonumber( maxHeightAboveTopArea ) or 0.0
	
	local top = Vector( ( absMin.x + absMax.x ) / 2.0, ( absMin.y + absMax.y ) / 2.0, absMax.z )
	local bottom = Vector( top.x, top.y, absMin.z )
	local width
	
	-- determine facing - assumes "normal" runged ladder
	local xSize = absMax.x - absMin.x
	local ySize = absMax.y - absMin.y
	local normal = Vector()
	local dir = NUM_DIRECTIONS
	local result = {}
	if xSize > ySize then
	
		-- ladder is facing north or south - determine which way
		-- "pull in" traceline from bottom and top in case ladder abuts floor and/or ceiling
		local from = bottom + Vector( 0.0, 25.0, 12.5 )
		local to = top + Vector( 0.0, 25.0, -12.5 )
		
		util.TraceLine( { start = from, endpos = to, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
		if result.Fraction != 1.0 or result.StartSolid then
		
			--NORTH
			dir = NORTH
			normal = AddDirectionVector( normal, NORTH, 1.0 )
			local from2 = ( top + bottom ) * 0.5 + normal * 5.0
			local to2 = from2 - normal * 32.0
			
			local result2 = {}
			util.TraceLine( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
			if result2.Fraction != 1.0 then
			
				local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end
				
			end
			
		else
		
			--SOUTH
			dir = SOUTH
			normal = AddDirectionVector( normal, SOUTH, 1.0 )
			local from2 = ( top + bottom ) * 0.5 + normal * 5.0
			local to2 = from2 - normal * 32.0
			
			local result2 = {}
			util.TraceLine( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
			if result2.Fraction != 1.0 then
			
				local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end
				
			end
			
		end
		
		width = xSize
		
	else
	
		-- ladder is facing east or west - determine which way
		local from = bottom + Vector( 25.0, 0.0, 12.5 )
		local to = top + Vector( 25.0, 0.0, -12.5 )
		
		util.TraceLine( { start = from, endpos = to, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
		if result.Fraction != 1.0 or result.StartSolid then
		
			--WEST
			dir = WEST
			normal = AddDirectionVector( normal, WEST, 1.0 )
			local from2 = ( top + bottom ) * 0.5 + normal * 5.0
			local to2 = from2 - normal * 32.0
			
			local result2 = {}
			util.TraceLine( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
			if result2.Fraction != 1.0 then
			
				local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end
				
			end
			
		else
		
			--EAST
			dir = EAST
			normal = AddDirectionVector( normal, EAST, 1.0 )
			local from2 = ( top + bottom ) * 0.5 + normal * 5.0
			local to2 = from2 - normal * 32.0
			
			local result2 = {}
			util.TraceLine( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
			if result2.Fraction != 1.0 then
			
				local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end
				
			end
			
		end
		
		width = ySize
		
	end
	
	-- adjust top and bottom of ladder to make sure they are reachable
	-- (cs_office has a crate right in front of the base of a ladder)
	local along = top - bottom
	local length = along:Length()
	along:Normalize()
	local on, out = Vector(), Vector()
	local minLadderClearance = 32.0
	
	-- adjust bottom to bypass blockages
	local inc = 10.0
	local t = 0.0
	while t <= length do
	
		on = bottom + t * along
		
		out = on + normal * minLadderClearance
		
		util.TraceLine( { start = on, endpos = out, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
		if result.Fraction == 1.0 and !result.StartSolid then
		
			bottom = on
			break
			
		end
		
		t = t + inc
		
	end
	
	-- adjust top to bypass blockages
	t = 0.0
	while t <= length do
	
		on = top + t * along
		
		out = on + normal * minLadderClearance
		
		util.TraceLine( { start = on, endpos = out, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
		if result.Fraction == 1.0 and !result.StartSolid then
		
			top = on
			break
			
		end
		
		t = t + inc
		
	end
	
	normal:Zero()
	normal = AddDirectionVector( normal, dir, 1.0 )
	local from2 = ( top + bottom ) * 0.5 + normal * 5.0
	local to2 = from2 - normal * 32.0
	
	local result2 = {}
	util.TraceLine( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
	
	if result2.Fraction != 1.0 then
	
		local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
		if !climbableSurface then
		
			climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
			
		end
		if climbableSurface then
		
			normal = result2.HitNormal
			
		end
		
	end
	
	-- For some reason I can't really rely on the code above for
	-- the map slash_subway so I made some manual adjustments here.
	--[[if ent:EntIndex() == 93 then
	
		normal = Vector( 0.0, -1.0, 0.0 )
		
	elseif ent:EntIndex() == 594 then
	
		normal = Vector( 0.0, 1.0, 0.0 )
		
	elseif ent:EntIndex() == 601 then
	
		normal = Vector( 0.0, -1.0, 0.0 )
		
	elseif ent:EntIndex() == 606 then
	
		normal = Vector( 0.0, 1.0, 0.0 )
		top = top + Vector( 0.0, 0.0, -20 )
	
	end]]
	
	print( ent )
	print( top )
	print( bottom )
	print( width )
	print( normal )
	
	navmesh.CreateNavLadder( top, bottom, width, normal, maxHeightAboveTopArea )
	
end

concommand.Add( "experiment_auto_build_ladders" , Test4 , nil , "This creates nav ladders on func_useableladders. This is in beta and is very buggy!" )
concommand.Add( "experiment_create_ladder" , Test5 , nil , "Creates a CNavLadder with the specified parameters!" )
function Test4( ply, cmd, args )
	
	if BRANCH != "dev" then 
	
		if IsValid( ply ) then
		
			ply:ChatPrint( "This command only works on the dev branch for now..." ) 
			
		end
		
		return 
	
	end
	
	for k, ladder in ipairs( ents.FindByClass( "func_useableladder" ) ) do
	
		local bottom, top = ladder:GetCollisionBounds()
		bottom = ladder:LocalToWorld( bottom )
		top = ladder:LocalToWorld( top )
		
		Test3( bottom, top, 0, ladder )
		
	end
	
end

function Test5( ply, cmd, args )

	if BRANCH != "dev" then 
	
		if IsValid( ply ) then
		
			ply:ChatPrint( "This command only works on the dev branch for now..." ) 
			
		end
		
		return 
	
	end
	
	local top = Vector( args[ 1 ] )
	local bottom = Vector( args[ 2 ] )
	local width = tonumber( args[ 3 ] )
	local normal = Vector( args[ 4 ] )
	local maxHeightAboveTopArea = tonumber( args[ 5 ] ) or 0
	
	if !isvector( top ) then if IsValid( ply ) then ply:ChatPrint( "bad argument #1 to 'navmesh_create_ladder' (Vector expected got " .. type( top ) .. ")" ) end return
	elseif !isvector( bottom ) then if IsValid( ply ) then ply:ChatPrint( "bad argument #2 to 'navmesh_create_ladder' (Vector expected got " .. type( bottom ) .. ")" ) end return
	elseif !isnumber( width ) then if IsValid( ply ) then ply:ChatPrint( "bad argument #3 to 'navmesh_create_ladder' (number expected got " .. type( width ) .. ")" ) end return
	elseif !isvector( normal ) then if IsValid( ply ) then ply:ChatPrint( "bad argument #4 to 'navmesh_create_ladder' (Vector expected got " .. type( normal ) .. ")" ) end return end
	
	navmesh.CreateNavLadder( top, bottom, width, normal, maxHeightAboveTopArea )
	
end

-- Draws the hiding spots on debug overlay. This includes sniper/exposed spots too!
function ShowAllHidingSpots()

	for _, area in ipairs( navmesh.GetAllNavAreas() ) do

		area:DrawSpots()

	end

end
