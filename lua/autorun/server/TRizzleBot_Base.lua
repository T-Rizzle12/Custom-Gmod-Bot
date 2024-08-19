-- TRizzleBot_Base.lua
-- Purpose: This is a base that can be modified to play other gamemodes
-- Author: T-Rizzle

-- Ok, so now need need to include the base class stuff here so nothing breaks on initialization.
include( "Path/TBotPath.lua" )
include( "Path/TBotPathFollower.lua" )
include( "Action/TBotBaseAction.lua" )

-- Now that we added the base class stuff we can add everything else!
-- First, lets add all the interfaces!
include( "Interface/TBotBody.lua" )
include( "Interface/TBotLocomotion.lua" )
include( "Interface/TBotKnownEntity.lua" )
include( "Interface/TBotVision.lua" )

-- Next the rest of the paths!
include( "Path/TBotChasePath.lua" )
include( "Path/TBotRetreatPath.lua" )

-- Finally, lets add all the actions!
include( "Action/TBotMainAction.lua" )
include( "Action/TBotTacticalMonitor.lua" )
include( "Action/TBotScenarioMonitor.lua" )
include( "Action/TBotDead.lua" )
include( "Action/TBotFollowOwner.lua" )
include( "Action/TBotFollowGroupLeader.lua" )
include( "Action/TBotHealPlayer.lua" )
include( "Action/TBotRetreatToCover.lua" )
include( "Action/TBotReloadInCover.lua" )
include( "Action/TBotRevivePlayer.lua" )
include( "Action/TBotSearchAndDestory.lua" )
include( "Action/TBotUseEntity.lua" )
--[[include( "Action/TBotBreakEntity.lua" ) -- NEEDTOVALIDATE: Currently, this is handled by the path system. I need to make sure this doesn't create issues!
include( "Action/TBotOpenDoor.lua" )]]

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
local PATH_USE_PORTAL			=	6
--local PATH_LADDER_MOUNT			=	6

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
local BotUpdateSkipCount	=	7 -- This is how many upkeep events must be skipped before another update event can be run. Used to be 2, but it made the addon very laggy at times!
local BotUpdateInterval		=	0

-- Setup the "global" weapon table
local TBotWeaponTable = {}

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
util.AddNetworkString( "TRizzleBotVGUIMenu" )

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
	local NewBotTable				=	NewBot:GetTable()
	
	NewBotTable.TRizzleBot				=	true -- Flag this as our bot so we don't control other bots, Only ours!
	NewBotTable.TBotOwner				=	ply -- Make the player who created the bot its "owner"
	NewBotTable.TBotPreferredWeapons	=	{} -- This is a list of the bot's preferred weapons.
	
	TBotSetFollowDist( ply, cmd, { args[ 1 ], args[ 2 ] } ) -- This is how close the bot will follow it's owner
	TBotSetDangerDist( ply, cmd, { args[ 1 ], args[ 3 ] } ) -- This is how far the bot can be from it's owner when in combat
	TBotSetMeleeDist( ply, cmd, { args[ 1 ], args[ 4 ] } ) -- If an enemy is closer than this, the bot will use its melee
	TBotSetPistolDist( ply, cmd, { args[ 1 ], args[ 5 ] } ) -- If an enemy is closer than this, the bot will use its pistol
	TBotSetShotgunDist( ply, cmd, { args[ 1 ], args[ 6 ] } ) -- If an enemy is closer than this, the bot will use its shotgun
	TBotSetRifleDist( ply, cmd, { args[ 1 ], args[ 7 ] } ) -- If an enemy is closer than this, the bot will use its rifle/smg
	TBotSetHealThreshold( ply, cmd, { args[ 1 ], args[ 8 ] } ) -- If the bot's health or a teammate's health drops below this and the bot is not in combat the bot will use its medkit
	TBotSetCombatHealThreshold( ply, cmd, { args[ 1 ], args[ 9 ] } ) -- If the bot's health drops below this and the bot is in combat the bot will use its medkit
	TBotSetPlayerModel( ply, cmd, { args[ 1 ], args[ 10 ] } ) -- This is the player model the bot will use
	TBotSpawnWithPreferredWeapons( ply, cmd, { args[ 1 ], args[ 11 ] } ) -- This checks if the bot should spawn with its preferred weapons
	
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

function TBotAddPreferredWeapon( ply, cmd, args )
	if !args[ 1 ] or !args[ 2 ] then return end
	
	local targetbot = args[ 1 ]
	local newWeapon = args[ 2 ]
	local weaponTable = GetTBotRegisteredWeapon( newWeapon )
	if table.IsEmpty( weaponTable ) then error( string.format( "[INFORMATION] The entered weapon (%s) has not been registered! Please register the weapon using the RegisterTBotWeapon command!", newWeapon ) ) end

	for k, bot in ipairs( player.GetAll() ) do
	
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
		
			bot.TBotPreferredWeapons[ newWeapon ] = true
			
		end
		
	end
	
end

function TBotRemovePreferredWeapon( ply, cmd, args )
	if !args[ 1 ] or !args[ 2 ] then return end
	
	local targetbot = args[ 1 ]
	local newWeapon = args[ 2 ]

	for k, bot in ipairs( player.GetAll() ) do
	
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
		
			bot.TBotPreferredWeapons[ newWeapon ] = nil
			
		end
		
	end
	
end

function TBotClearPreferredWeaponList( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]

	for k, bot in ipairs( player.GetAll() ) do
	
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
		
			bot.TBotPreferredWeapons = {}
			
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
	TBotSetMeleeDist( ply, cmd, args )
	TBotSetPistolDist( ply, cmd, args )
	TBotSetShotgunDist( ply, cmd, args )
	TBotSetRifleDist( ply, cmd, args )
	TBotSetHealThreshold( ply, cmd, args )
	TBotSetCombatHealThreshold( ply, cmd, args )
	TBotSpawnWithPreferredWeapons( ply, cmd, args )

end

-- This creates a TRizzleBot or registers a weapon using the parameters given in the client menu.
net.Receive( "TRizzleBotVGUIMenu", function( _, ply ) 

	local vguiType = net.ReadUInt( 1 )
	local CreateBot = 0
	local RegisterWeapon = 1

	if vguiType == CreateBot then
	
		local args = {}
		table.insert( args, net.ReadString() ) -- Name
		table.insert( args, net.ReadInt( 32 ) ) -- FollowDist
		table.insert( args, net.ReadInt( 32 ) ) -- DangerDist
		local weaponTable = net.ReadTable( true )
		table.insert( args, net.ReadInt( 32 ) ) -- MeleeDist
		table.insert( args, net.ReadInt( 32 ) ) -- PistolDist
		table.insert( args, net.ReadInt( 32 ) ) -- ShotgunDist
		table.insert( args, net.ReadInt( 32 ) ) -- RifleDist
		table.insert( args, net.ReadInt( 32 ) ) -- HealThreshold
		table.insert( args, net.ReadInt( 32 ) ) -- CombatHealThreshold
		table.insert( args, net.ReadString() ) -- PlayerModel
		table.insert( args, Either( net.ReadBool(), 1, 0 ) ) -- SpawnWithPreferredWeapons
		
		TBotCreate( ply, "TRizzleCreateBot", args )
		
		-- NOTE: Should I find the bot and manually add to the preferred weapon table instead?
		for k, weapon in ipairs( weaponTable ) do
		
			ply:ConCommand( string.format( "TBotAddPreferredWeapon %q %s", args[ 1 ], weapon ) )
			
		end
		
		return
		
	elseif vguiType == RegisterWeapon then
		
		local args = {}
		args.ClassName = net.ReadString()
		args.WeaponType = net.ReadString()
		args.ReloadsSingly = net.ReadBool()
		args.HasScope = net.ReadBool()
		args.HasSecondaryAttack = net.ReadBool()
		args.SecondaryAttackCooldown = net.ReadInt( 32 )
		args.MaxStoredAmmo = net.ReadInt( 32 )
		args.IgnoreAutomaticRange = net.ReadBool()
		
		RegisterTBotWeapon( args )
		
		return
	
	end
	
	error( "[WARNING]: Net Message TRizzleBotVGUIMenu was called with an invalid vgui type!" )
	
end)

concommand.Add( "TRizzleCreateBot" , TBotCreate , nil , "Creates a TRizzle Bot with the specified parameters. Example: TRizzleCreateBot <botname> <followdist> <dangerdist> <meleedist> <pistoldist> <shotgundist> <rifledist> <healthreshold> <combathealthreshold> <playermodel> <spawnwithpreferredweapons> Example2: TRizzleCreateBot Bot 200 300 80 1300 300 900 100 25 alyx 1" )
concommand.Add( "TBotSetFollowDist" , TBotSetFollowDist , nil , "Changes the specified bot's how close it should be to its owner. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetDangerDist" , TBotSetDangerDist , nil , "Changes the specified bot's how far the bot can be from its owner while in combat. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotAddPreferredWeapon" , TBotAddPreferredWeapon , nil , "Add a new weapon to the bot's preferred weapon list." )
concommand.Add( "TBotRemovePreferredWeapon" , TBotRemovePreferredWeapon , nil , "Removes a weapon from the bot's preferred weapon list." )
concommand.Add( "TBotClearPreferredWeaponList" , TBotClearPreferredWeaponList , nil , "Clears the entire bot's preferred weapon list." )
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
	
	-- TODO: Move most of this stuff into its own interfaces to reduce collision with other addons!!!!
	local botTable						=	self:GetTable() -- This is used so I don't have to keep dipping into C every time since it is VERY SLOW!
	botTable.buttonFlags					=	0 -- These are the buttons the bot is going to press.
	botTable.impulseFlags					=	0 -- This is the impuse command the bot is going to press.
	botTable.forwardMovement				=	0 -- This tells the bot to move either forward or backwards.
	botTable.strafeMovement					=	0 -- This tells the bot to move left or right.
	botTable.GroupLeader					=	nil -- If the bot's owner is dead, this bot will take charge in combat and leads other bots with the same "owner". 
	botTable.UseEnt							=	nil -- This is the entity this bot is trying to use.
	botTable.UseHoldTime					=	0 -- This is how long the bot should press its use key on UseEnt.
	botTable.StartedUse						=	false -- Has the bot started to press its use key on UseEnt.
	botTable.HoldPos						=	nil -- This is the position the bot will wait at.
	botTable.EnemyList						=	{} -- This is the list of enemies the bot knows about.
	botTable.AttackList						=	{} -- This is the list of entities the bot has been told to attack.
	botTable.AimForHead						=	false -- Should the bot aim for the head?
	botTable.TimeInCombat					=	0 -- This is how long the bot has been in combat.
	botTable.LastCombatTime					=	0 -- This is the last time the bot was in combat.
	botTable.BestWeapon						=	nil -- This is the weapon the bot currently wants to equip.
	botTable.MinEquipInterval				=	0 -- Throttles how often equipping is allowed.
	botTable.HealTarget						=	nil -- This is the player the bot is trying to heal.
	botTable.ReviveTarget					=	nil -- This is the player the bot is trying to revive. -- NOTE: This is only for incapacitation addons
	botTable.TRizzleBotBlindTime			=	0 -- This is how long the bot should be blind
	botTable.LastVisionUpdateTimestamp		=	0 -- This is the last time the bot updated its list of known enemies
	botTable.IsJumping						=	false -- Is the bot currently jumping?
	botTable.NextJump						=	0 -- This is the next time the bot is allowed to jump.
	botTable.HoldAttack						=	0 -- This is how long the bot should hold its attack button.
	botTable.HoldAttack2					=	0 -- This is how long the bot should hold its attack2 button.
	botTable.HoldReload						=	0 -- This is how long the bot should hold its reload button.
	botTable.HoldForward					=	0 -- This is how long the bot should hold its forward button.
	botTable.HoldBack						=	0 -- This is how long the bot should hold its back button.
	botTable.HoldLeft						=	0 -- This is how long the bot should hold its left button.
	botTable.HoldRight						=	0 -- This is how long the bot should hold its right button.
	botTable.HoldRun						=	0 -- This is how long the bot should hold its run button.
	botTable.HoldWalk						=	0 -- This is how long the bot should hold its walk button.
	botTable.HoldJump						=	0 -- This is how long the bot should hold its jump button.
	botTable.HoldCrouch						=	0 -- This is how long the bot should hold its crouch button.
	botTable.HoldUse						=	0 -- This is how long the bot should hold its use button.
	botTable.FullReload						=	false -- This tells the bot not to press its attack button until its current weapon is fully reloaded.
	botTable.FireWeaponInterval				=	0 -- Limits how often the bot presses its attack button.
	botTable.SecondaryInterval				=	0 -- Limits how often the bot uses its secondary attack.
	botTable.ReloadInterval					=	0 -- Limits how often the bot can press its reload button.
	botTable.ScopeInterval					=	0 -- Limits how often the bot can press its scope button.
	botTable.UseInterval					=	0 -- Limits how often the bot can press its use button.
	botTable.GrenadeInterval				=	0 -- Limits how often the bot will throw a grenade.
	botTable.ExplosiveInterval				=	0 -- Limits how often the bot will use explosive weapons.
	botTable.ImpulseInterval				=	0 -- Limits how often the bot can press any impuse command.
	botTable.Light							=	false -- Tells the bot if it should have its flashlight on or off.
	--self.LookYawVel					=	0 -- This is the current yaw velocity of the bot.
	--self.LookPitchVel				=	0 -- This is the current pitch velocity of the bot.
	botTable.AimErrorAngle					=	0 -- This is the current error the bot has while aiming.
	botTable.AimErrorRadius					=	0 -- This is the radius of the error the bot has while aiming.
	botTable.AimAdjustTimer					=	0 -- This is the next time the bot will update its aim error.
	botTable.LookTarget						=	vector_origin -- This is the position the bot is currently trying to look at.
	botTable.LookTargetSubject				=	nil -- This is the current entity the bot is trying to look at.
	botTable.LookTargetVelocity				=	0 -- Used to update subject tracking.
	botTable.LookTargetTrackingTimer		=	0 -- Used to update subject tracking.
	botTable.m_isLookingAroundForEnemies	=	true -- Is the bot looking around for enemies?
	--self.LookTargetState			=	NOT_LOOKING_AT_SPOT -- This is the bot's current look at state.
	botTable.IsSightedIn					=	false -- Is the bot looking at its current target.
	botTable.HasBeenSightedIn				=	false -- Has the bot looked at the current target.
	botTable.AnchorForward					=	vector_origin -- Used to simulate the bot recentering its vitural mouse.
	botTable.AnchorRepositionTimer			=	nil -- This is used to simulate the bot recentering its vitural mouse.
	botTable.PriorAngles					=	angle_zero	-- This was the bot's eye angles last UpdateAim.
	botTable.LookTargetExpire				=	0 -- This is how long the bot will look at the position the bot is currently trying to look at.
	botTable.LookTargetDuration				=	0 -- This is how long since the bot started looking at the target pos.
	--self.LookTargetTolerance		=	0 -- This is how close the bot must aim at LookTarget before starting LookTargetTimestamp.
	--self.LookTargetTimestamp		=	0 -- This is the timestamp the bot started staring at LookTarget.
	botTable.LookTargetPriority				=	TBotLookAtPriority.LOW_PRIORITY -- This is how important the position the bot is currently trying to look at is.
	botTable.HeadSteadyTimer				=	nil -- This checks if the bot is not rapidly turning to look somehwere else.
	botTable.CheckedEncounterSpots			=	{} -- This stores every encounter spot and when the spot was checked.
	botTable.PeripheralTimestamp			=	0 -- This limits how often UpdatePeripheralVision is run.
	botTable.NextEncounterTime				=	0 -- This is the next time the bot is allowed to look at another encounter spot.
	botTable.ApproachViewPosition			=	self:GetPos() -- This is the position used to compute approach points.
	botTable.ApproachPoints					=	{} -- This stores all the approach points leading to the bot.
	botTable.HidingSpot						=	nil -- This is the current hiding/sniper spot the bot wants to goto.
	botTable.HidingState					=	FINISHED_HIDING -- This is the current hiding state the bot is currently in.
	botTable.HideReason						=	NONE -- This is the bot's reason for hiding.
	botTable.NextHuntTime					=	CurTime() + 10 -- This is the next time the bot will pick a random sniper spot and look for enemies.
	botTable.HidingSpotInterval				=	0 -- Limits how often the bot can set its selected hiding spot.
	botTable.HideTime						=	0 -- This is how long the bot will stay at its current hiding spot.
	botTable.ReturnPos						=	nil -- This is the spot the will back to after hiding, "Example, If the bot went into cover to reload."
	botTable.Goal							=	nil -- The current path segment the bot is on.
	botTable.Path							=	{} -- The nodes converted into waypoints by our visiblilty checking.
	botTable.PathAge						=	0 -- This is how old the current bot's path is.
	botTable.IsJumpingAcrossGap				=	false -- Is the bot trying to jump over a gap.
	botTable.IsClimbingUpToLedge			=	false -- Is the bot trying to jump up to a ledge. 
	botTable.HasLeftTheGround				=	false -- Used by the bot check if it has left the ground while gap jumping and jumping up to a ledge.
	--self.CurrentSegment					=	1 -- This is the current segment the bot is on.
	botTable.SegmentCount					=	0 -- This is how many nodes the bot's current path has.
	botTable.LadderState					=	NO_LADDER -- This is the current ladder state of the bot.
	botTable.LadderInfo						=	nil -- This is the current ladder the bot is trying to use.
	botTable.LadderDismountGoal				=	nil -- This is the bot's goal once it reaches the end of its selected ladder.
	botTable.LadderTimer					=	0 -- This helps the bot leave the ladder state if it somehow gets stuck.
	botTable.MotionVector					=	Vector( 1.0, 0, 0 ) -- This is the bot's current movement as a vector.
	botTable.RepathTimer					=	CurTime() + 0.5 -- This will limit how often the path gets recreated.
	botTable.ChaseTimer						=	CurTime() + 0.5 -- This will limit how often the bot repaths while chasing something.
	botTable.AvoidTimer						=	0 -- Limits how often the bot avoid checks are run.
	botTable.IsStuck						=	false -- Is the bot stuck.
	botTable.StuckPos						=	self:GetPos() -- Used when checking if the bot is stuck or not.
	botTable.StuckTimer						=	CurTime() -- Used when checking if the bot is stuck or not.
	botTable.StillStuckTimer				=	0 -- Used to check if the bot is stuck.
	botTable.MoveRequestTimer				=	0 -- Used to check if the bot wants to move.
	botTable.TBotCurrentPath				=	nil -- This is the path path the bot was following.
	--self.WiggleTimer				=	0 -- This helps the bot get unstuck.
	--self.StuckJumpInterval			=	0 -- Limits how often the bot jumps when stuck.
	
	-- Delete old behavior interface on reset
	if botTable.TBotBehavior then
	
		botTable.TBotBehavior:Remove()
		botTable.TBotBehavior = nil
		
	end
	
	botTable.TBotBehavior = TBotBehavior( TBotMainAction(), "Base Behavior" ) -- This gets reset every time the bot's AI is reset!
	self:GetTBotVision():ForgetAllKnownEntities()
	self:TBotSetState( IDLE )
	self:ComputeApproachPoints()
	--self:TBotCreateThinking() -- Start our AI
	
end

--[[function BOT:TBotResetAI()
	
	-- TODO: Move most of this stuff into its own interfaces to reduce collision with other addons!!!!
	local botTable						=	self:GetTable() -- This is used so I don't have to keep dipping into C every time since it is VERY SLOW!
	botTable.buttonFlags					=	0 -- These are the buttons the bot is going to press.
	botTable.impulseFlags					=	0 -- This is the impuse command the bot is going to press.
	botTable.forwardMovement				=	0 -- This tells the bot to move either forward or backwards.
	botTable.strafeMovement					=	0 -- This tells the bot to move left or right.
	botTable.GroupLeader					=	nil -- If the bot's owner is dead, this bot will take charge in combat and leads other bots with the same "owner". 
	botTable.EnemyList						=	{} -- This is the list of enemies the bot knows about.
	botTable.AttackList						=	{} -- This is the list of entities the bot has been told to attack.
	botTable.AimForHead						=	false -- Should the bot aim for the head?
	botTable.TimeInCombat					=	0 -- This is how long the bot has been in combat.
	botTable.LastCombatTime					=	0 -- This is the last time the bot was in combat.
	botTable.BestWeapon						=	nil -- This is the weapon the bot currently wants to equip.
	botTable.MinEquipInterval				=	0 -- Throttles how often equipping is allowed.
	botTable.HoldAttack						=	0 -- This is how long the bot should hold its attack button.
	botTable.HoldAttack2					=	0 -- This is how long the bot should hold its attack2 button.
	botTable.HoldReload						=	0 -- This is how long the bot should hold its reload button.
	botTable.HoldForward					=	0 -- This is how long the bot should hold its forward button.
	botTable.HoldBack						=	0 -- This is how long the bot should hold its back button.
	botTable.HoldLeft						=	0 -- This is how long the bot should hold its left button.
	botTable.HoldRight						=	0 -- This is how long the bot should hold its right button.
	botTable.HoldRun						=	0 -- This is how long the bot should hold its run button.
	botTable.HoldWalk						=	0 -- This is how long the bot should hold its walk button.
	botTable.HoldJump						=	0 -- This is how long the bot should hold its jump button.
	botTable.HoldCrouch						=	0 -- This is how long the bot should hold its crouch button.
	botTable.HoldUse						=	0 -- This is how long the bot should hold its use button.
	botTable.FireWeaponInterval				=	0 -- Limits how often the bot presses its attack button.
	botTable.SecondaryInterval				=	0 -- Limits how often the bot uses its secondary attack.
	botTable.ReloadInterval					=	0 -- Limits how often the bot can press its reload button.
	botTable.ScopeInterval					=	0 -- Limits how often the bot can press its scope button.
	botTable.UseInterval					=	0 -- Limits how often the bot can press its use button.
	botTable.GrenadeInterval				=	0 -- Limits how often the bot will throw a grenade.
	botTable.ExplosiveInterval				=	0 -- Limits how often the bot will use explosive weapons.
	botTable.ImpulseInterval				=	0 -- Limits how often the bot can press any impuse command.
	botTable.Light							=	false -- Tells the bot if it should have its flashlight on or off.
	botTable.m_isLookingAroundForEnemies	=	true -- Is the bot looking around for enemies?
	botTable.CheckedEncounterSpots			=	{} -- This stores every encounter spot and when the spot was checked.
	botTable.PeripheralTimestamp			=	0 -- This limits how often UpdatePeripheralVision is run.
	botTable.NextEncounterTime				=	0 -- This is the next time the bot is allowed to look at another encounter spot.
	botTable.ApproachViewPosition			=	self:GetPos() -- This is the position used to compute approach points.
	botTable.ApproachPoints					=	{} -- This stores all the approach points leading to the bot.
	botTable.TBotCurrentPath				=	nil
	
	-- Delete old behavior interface on reset
	if botTable.TBotBehavior then
	
		botTable.TBotBehavior:Remove()
		
	end
	
	botTable.TBotBehavior = TBotBehavior( TBotMainAction(), "Base Behavior" ) -- This gets reset every time the bot's AI is reset!
	self:GetTBotVision():ForgetAllKnownEntities()
	self:TBotSetState( IDLE )
	self:ComputeApproachPoints()
	--self:TBotCreateThinking() -- Start our AI
	
end]]

-- Returns the bot's behavior interface.
-- TODO: Implement the new base functions into the addon's code!
function BOT:GetTBotBehavior()
	if !self:IsTRizzleBot() then return end

	local botTable = self:GetTable()
	if !botTable.TBotBehavior then
	
		botTable.TBotBehavior = TBotBehavior( TBotMainAction(), "Base Behavior" ) -- Create the behavior interface if its invalid or doesn't exist!
		
	end
	
	return botTable.TBotBehavior
	
end

-- Returns the bot's vision interface.
function BOT:GetTBotVision()
	if !self:IsTRizzleBot() then return end
	
	local botTable = self:GetTable()
	if !botTable.TBotVision then
	
		botTable.TBotVision = TBotVision( self )  -- Create the vision interface if its invalid or doesn't exist!
		
	end
	
	return botTable.TBotVision
	
end

-- Returns the bot's body interface.
function BOT:GetTBotBody()
	if !self:IsTRizzleBot() then return end
	
	local botTable = self:GetTable()
	if !botTable.TBotBody then
	
		botTable.TBotBody = TBotBody( self ) -- Create the body interface if its invalid or doesn't exist!
		
	end
	
	return botTable.TBotBody
	
end

-- Returns the bot's locomotion interface.
function BOT:GetTBotLocomotion()
	if !self:IsTRizzleBot() then return end
	
	local botTable = self:GetTable()
	if !botTable.TBotLocomotion then
	
		botTable.TBotLocomotion = TBotLocomotion( self ) -- Create the locomotion interface if its invalid or doesn't exist!
		
	end
	
	return botTable.TBotLocomotion
	
end

-- TODO: Move these somewhere else...
function BOT:SetCurrentPath( path )

	self.TBotCurrentPath = path
	
end

function BOT:GetCurrentPath()

	return self.TBotCurrentPath
	
end

hook.Add( "StartCommand" , "TRizzleBotAIHook" , function( bot , cmd )
	if !IsValid( bot ) or !bot:IsTRizzleBot() or navmesh.IsGenerating() then return end
	-- Make sure we can control this bot and its not a player.
	
	local botTable = bot:GetTable()
	cmd:SetButtons( botTable.buttonFlags )
	cmd:SetImpulse( botTable.impulseFlags )
	cmd:SetForwardMove( botTable.forwardMovement )
	cmd:SetSideMove( botTable.strafeMovement )
	cmd:SetUpMove( bit.band( botTable.buttonFlags, IN_JUMP ) == IN_JUMP and bot:GetRunSpeed() or 0 )
	
	local bestWeapon = botTable.BestWeapon
	if IsValid( bestWeapon ) and bestWeapon:IsWeapon() and bot:GetActiveWeapon() != bestWeapon then 
	
		cmd:SelectWeapon( bestWeapon )
		
	end
	
	botTable.impulseFlags = 0 -- WARNING: We must clear the impulseFlags after every call because if we don't the bot will spam call it until the next think!!!!
	
end)

function BOT:ResetCommand()

	local buttons			= 0
	local forwardmovement	= 0
	local strafemovement	= 0
	local botTable			= self:GetTable()
	
	if botTable.HoldAttack > CurTime() then buttons = bit.bor( buttons, IN_ATTACK ) end
	if botTable.HoldAttack2 > CurTime() then buttons = bit.bor( buttons, IN_ATTACK2 ) end
	if botTable.HoldReload > CurTime() then buttons = bit.bor( buttons, IN_RELOAD ) end
	if botTable.HoldForward > CurTime() then 
	
		buttons = bit.bor( buttons, IN_FORWARD )

		forwardmovement = 10000
	
	end
	if botTable.HoldBack > CurTime() then 
	
		buttons = bit.bor( buttons, IN_BACK )
		
		forwardmovement = -10000
		
	end
	if botTable.HoldLeft > CurTime() then 
	
		buttons = bit.bor( buttons, IN_MOVELEFT )
		
		strafemovement = -10000
		
	end
	if botTable.HoldRight > CurTime() then 
	
		buttons = bit.bor( buttons, IN_MOVERIGHT ) 
		
		strafemovement = 10000
		
	end
	if botTable.HoldRun > CurTime() then buttons = bit.bor( buttons, IN_SPEED ) end
	if botTable.HoldWalk > CurTime() then buttons = bit.bor( buttons, IN_WALK ) end
	if botTable.HoldJump > CurTime() then buttons = bit.bor( buttons, IN_JUMP ) end
	if botTable.HoldCrouch > CurTime() then buttons = bit.bor( buttons, IN_DUCK ) end
	if botTable.HoldUse > CurTime() then buttons = bit.bor( buttons, IN_USE ) end
	
	botTable.buttonFlags		= buttons
	botTable.forwardMovement	= forwardmovement
	botTable.strafeMovement		= strafemovement
	botTable.impulseFlags		= 0

end

function BOT:HandleButtons()

	local CanRun		=	!self:InVehicle()
	local ShouldJump	=	false
	local ShouldCrouch	=	false
	local ShouldRun		=	false
	local ShouldWalk	=	false
	local botTable		=	self:GetTable()
	
	local myArea = self:GetLastKnownArea()
	if IsValid( myArea ) then -- If there is no nav_mesh this will not run to prevent the addon from spamming errors
		
		if self:IsOnGround() and myArea:HasAttributes( NAV_MESH_JUMP ) then
			
			ShouldJump		=	true
			
		end
		
		if myArea:HasAttributes( NAV_MESH_CROUCH ) and ( !botTable.Goal or botTable.Goal.Type == PATH_ON_GROUND ) then
			
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
			
		--[[elseif IsValid( botTable.TBotOwner ) and botTable.TBotOwner:Alive() and ( !self:IsInCombat() or self:IsUnhealthy() ) and botTable.TBotOwner:GetPos():DistToSqr( self:GetPos() ) > botTable.DangerDist^2 then
		
			self:PressRun()
		
		elseif IsValid( botTable.GroupLeader ) and botTable.GroupLeader:Alive() and ( !self:IsInCombat() or self:IsUnhealthy() ) and botTable.GroupLeader:GetPos():DistToSqr( self:GetPos() ) > botTable.DangerDist^2 then
		
			self:PressRun()
		
		end]]
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
	
	local door = botTable.Door
	local breakable = botTable.Breakable
	if IsValid( breakable ) then
	
		if IsValid( botTable.HealTarget ) or !breakable:IsBreakable() or breakable:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) > 6400 or !self:IsAbleToSee( breakable ) then
		
			botTable.Breakable = nil
			return
			
		end
		
		self:AimAtPos( breakable:WorldSpaceCenter(), 0.5, TBotLookAtPriority.MAXIMUM_PRIORITY )
		
		if self:IsLookingAtPosition( breakable:WorldSpaceCenter() ) then
		
			local botWeapon = botTable.BestWeapon
			if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and botWeapon:GetClass() != "weapon_medkit" then
			
				if GetTBotRegisteredWeapon( botWeapon:GetClass() ).WeaponType == "Melee" then
				
					local rangeToShoot = self:GetShootPos():DistToSqr( breakable:WorldSpaceCenter() )
					local rangeToStand = self:GetPos():DistToSqr( breakable:WorldSpaceCenter() )
					
					-- If the breakable is on the ground and we are using a melee weapon
					-- we have to crouch in order to hit it
					if rangeToShoot <= 4900 and rangeToShoot > rangeToStand then
					
						self:PressCrouch()
						
					end
					
				end
			
				if CurTime() >= botTable.FireWeaponInterval and self:GetActiveWeapon() == botWeapon then
				
					self:PressPrimaryAttack()
					botTable.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )
					
					if !botWeapon:IsPrimaryClipEmpty() then
					
						botTable.ReloadInterval = CurTime() + 0.5
						
					end
					
				end
				
			else
			
				local bestWeapon		=	nil
				
				for k, weapon in ipairs( self:GetWeapons() ) do
		
					if IsValid( weapon ) and weapon:HasPrimaryAmmo() and weapon:IsTBotRegisteredWeapon() then 
					
						if !IsValid( bestWeapon ) or weapon:GetTBotDistancePriority() > bestWeapon:GetTBotDistancePriority() then
					
							bestWeapon = weapon
							minEquipInterval = Either( weaponType != "Melee", 5.0, 2.0 )
						
						end
						
					end
					
				end
				
				if IsValid( bestWeapon ) then
				
					botTable.BestWeapon = bestWeapon
					
				end
			
			end
			
		end
	
	elseif IsValid( door ) then 
	
		if !door:IsDoor() or door:IsDoorOpen() or door:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) > 10000 then 
		
			botTable.Door = nil
			return
			
		end
		
		self:AimAtPos( door:WorldSpaceCenter(), 0.5, TBotLookAtPriority.MAXIMUM_PRIORITY )
		
		if CurTime() >= botTable.UseInterval and self:IsLookingAtPosition( door:WorldSpaceCenter() ) then
			
			self:PressUse()
			botTable.UseInterval = CurTime() + 0.5
			
			if door:IsDoorLocked() then
			
				botTable.Door = nil
				return
				
			end
			
		end
		
	end
	
end

function BOT:PressPrimaryAttack( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_ATTACK )
	botTable.HoldAttack = CurTime() + holdTime

end

function BOT:ReleasePrimaryAttack()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_ATTACK ) )
	botTable.HoldAttack = 0
	
end

function BOT:PressSecondaryAttack( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_ATTACK2 )
	botTable.HoldAttack2 = CurTime() + holdTime

end

function BOT:ReleaseSecondaryAttack()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_ATTACK2 ) )
	botTable.HoldAttack2 = 0
	
end

function BOT:PressReload( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_RELOAD )
	botTable.HoldReload = CurTime() + holdTime

end

function BOT:ReleaseReload()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_RELOAD ) )
	botTable.HoldReload = 0
	
end

function BOT:PressForward( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0
	
	botTable.forwardMovement = 10000

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_FORWARD )
	botTable.HoldForward = CurTime() + holdTime
	
	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_BACK ) )
	botTable.HoldBack = 0

end

function BOT:ReleaseForward()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_FORWARD ) )
	botTable.HoldForward = 0
	
end

function BOT:PressBack( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0
	
	botTable.forwardMovement = -10000
	
	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_BACK )
	botTable.HoldBack = CurTime() + holdTime
	
	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_FORWARD ) )
	botTable.HoldForward = 0

end

function BOT:ReleaseBack()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_BACK ) )
	botTable.HoldBack = 0
	
end

function BOT:PressLeft( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0
	
	botTable.strafeMovement = -10000

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_MOVELEFT )
	botTable.HoldLeft = CurTime() + holdTime

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_MOVERIGHT ) )
	botTable.HoldRight = 0

end

function BOT:ReleaseLeft()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_MOVELEFT ) )
	botTable.HoldLeft = 0
	
end

function BOT:PressRight( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0
	
	botTable.strafeMovement = 10000

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_MOVERIGHT )
	botTable.HoldRight = CurTime() + holdTime
	
	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_MOVELEFT ) )
	botTable.HoldLeft = 0

end

function BOT:ReleaseRight()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_MOVERIGHT ) )
	botTable.HoldRight = 0
	
end

function BOT:PressRun( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_SPEED )
	botTable.HoldRun = CurTime() + holdTime

end

function BOT:ReleaseRun()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_SPEED ) )
	botTable.HoldRun = 0
	
end

function BOT:PressWalk( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_WALK )
	botTable.HoldWalk = CurTime() + holdTime

end

function BOT:ReleaseWalk()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_WALK ) )
	botTable.HoldWalk = 0
	
end

function BOT:PressJump( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0
	
	botTable.IsJumping = true
	botTable.NextJump = CurTime() + 0.5
	
	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_JUMP )
	botTable.HoldJump = CurTime() + holdTime
	
end

function BOT:ReleaseJump()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_JUMP ) )
	botTable.HoldJump = 0
	
end

function BOT:PressCrouch( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_DUCK )
	botTable.HoldCrouch = CurTime() + holdTime

end

function BOT:ReleaseCrouch()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_DUCK ) )
	botTable.HoldCrouch = 0
	
end

function BOT:PressUse( holdTime )
	local botTable = self:GetTable()
	holdTime = holdTime or -1.0

	botTable.buttonFlags = bit.bor( botTable.buttonFlags, IN_USE )
	botTable.HoldUse = CurTime() + holdTime

end

function BOT:ReleaseUse()
	local botTable = self:GetTable()

	botTable.buttonFlags = bit.band( botTable.buttonFlags, bit.bnot( IN_USE ) )
	botTable.HoldUse = 0
	
end

net.Receive( "TRizzleBotFlashlight", function( _, ply) 

	local tab = net.ReadTable()
	if !istable( tab ) or table.IsEmpty( tab ) then return end
	
	for bot, light in pairs( tab ) do
		local botTable = bot:GetTable()
		botTable.LastLight2 = botTable.LastLight2 or 0
	
		light = Vector(math.Round(light.x, 2), math.Round(light.y, 2), math.Round(light.z, 2))
		
		local lighton = light:IsZero() -- Vector( 0, 0, 0 )
		
		if lighton then
		
			botTable.LastLight2 = math.Clamp( botTable.LastLight2 + 1, 0, 3 )
			
		else
		
			botTable.LastLight2 = 0
		
		end
		
		botTable.Light = lighton and botTable.LastLight2 == 3
		
	end
end)

-- Returns if the player's flashlight is on!
-- NOTE: This was made so I could add compatbility with weapon mounted flashlights!
-- For now it only supports TFA mounted flashlights!
function BOT:TBotIsFlashlightOn()

	local wep = self:GetActiveWeapon()
	if !wep:IsWeapon() or !isfunction( wep.GetFlashlightEnabled ) or !isfunction( wep.GetStatL ) or wep:GetStatL( "FlashlightAttachment", 0 ) <= 0 then
	
		return self:FlashlightIsOn()
		
	end
	
	return wep:GetFlashlightEnabled()
	
end

-- Has the bot recently seen an enemy
function BOT:IsInCombat()
	
	return self.LastCombatTime + 5.0 > CurTime()
	
end

-- Has the bot not seen any enemies recently
function BOT:IsSafe()

	if self:IsInCombat() then
		
		return false
		
	end
	
	return self.LastCombatTime <= CurTime() - 15.0
	
end

--[[
Got this from TF2 Source Code, made some changes so it works for Lua

Returns the normalized verstion of the entered "angle".
]]
function math.AngleNormalize( angle )

	angle = math.fmod( angle, 360 )
	if angle > 180 then
	
		angle = angle - 360
		
	end
	if angle < -180 then
	
		angle = angle + 360
		
	end
	
	return angle

end

--[[
Got this from CS:GO Source Code, made some changes so it works for Lua

Returns the closest active player on the given team to the given position
This also returns to the distance the returned player is from said position.
]]
function util.GetClosestPlayer( pos, team )

	local closePlayer = nil
	local closeDistSq = math.huge
	
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
	local botTable = self:GetTable()
	if IsValid( myArea ) then
	
		botTable.ApproachPoints = {}
		-- For some reason if there is only once adjacent area no encounter spots will be created
		-- So I grab the single adjacent area instead and use its encounter and approach spots instead
		local spotEncounter = nil
		
		if myArea:GetAdjacentCount() == 1 then 
		
			spotEncounter = myArea:GetAdjacentAreas()[ 1 ]:GetSpotEncounters() 
			
		else
		
			spotEncounter = myArea:GetSpotEncounters()
			
		end
		
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
				
				table.insert( botTable.ApproachPoints, { Pos = approachPoint, Area = info.to } )
				
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
		local spotEncounter = nil
		
		if myArea:GetAdjacentCount() == 1 then 
		
			spotEncounter = myArea:GetAdjacentAreas()[ 1 ]:GetSpotEncounters() 
			
		else
		
			spotEncounter = myArea:GetSpotEncounters()
			
		end
		
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
	local botTable = self:GetTable()
	
	for k, spotTbl in ipairs( botTable.CheckedEncounterSpots ) do
	
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
	if #botTable.CheckedEncounterSpots < MAX_CHECKED_SPOTS then
	
		table.insert( botTable.CheckedEncounterSpots, { Pos = spot, TimeStamp = CurTime() } )
		
	else
	
		-- Replace the least recent spot.
		botTable.CheckedEncounterSpots[ leastRecent ].Pos = spot
		botTable.CheckedEncounterSpots[ leastRecent ].TimeStamp = CurTime()
	
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
	local botTable = self:GetTable()
	if deltaT < 0.00001 then
	
		return
		
	end
	
	local currentAngles = self:EyeAngles() + self:GetViewPunchAngles()
	
	-- track when our head is "steady"
	local isSteady = true
	
	local actualPitchRate = math.AngleDifference( currentAngles.x, botTable.PriorAngles.x )
	if math.abs( actualPitchRate ) > 100 * deltaT then
	
		isSteady = false
		
	else
	
		local actualYawRate = math.AngleDifference( currentAngles.y, botTable.PriorAngles.y )
		if math.abs( actualYawRate ) > 100 * deltaT then
		
			isSteady = false
			
		end
		
	end
	
	if isSteady then
	
		if !botTable.HeadSteadyTimer then
		
			botTable.HeadSteadyTimer = CurTime()
			
		end
		
	else
	
		botTable.HeadSteadyTimer = nil
		
	end
	
	botTable.PriorAngles = currentAngles
	
	-- if our current look-at has expired, don't change our aim further
	if botTable.HasBeenSightedIn and botTable.LookTargetExpire <= CurTime() then
	
		return
		
	end
	
	-- simulate limited range of mouse movements
	-- compute the angle change from center
	local forward = self:GetAimVector()
	local deltaAngle = math.deg( math.acos( forward:Dot( botTable.AnchorForward ) ) )
	if deltaAngle > 100 then
	
		botTable.AnchorRepositionTimer = CurTime() + ( math.Rand( 0.9, 1.1 ) * 0.3 )
		botTable.AnchorForward = forward
		
	end
	
	if botTable.AnchorRepositionTimer and botTable.AnchorRepositionTimer > CurTime() then
	
		return
		
	end
	
	botTable.AnchorRepositionTimer = nil
	
	local subject = botTable.LookTargetSubject
	if IsValid( subject ) then
	
		if botTable.LookTargetTrackingTimer <= CurTime() then
		
			local desiredLookTargetPos = self:GetTBotBehavior():SelectTargetPoint( self, subject )
			local errorVector = desiredLookTargetPos - botTable.LookTarget
			local Error = errorVector:Length()
			errorVector:Normalize()
			
			local trackingInterval = self:GetHeadAimTrackingInterval()
			if trackingInterval < deltaT then
			
				trackingInterval = deltaT
				
			end
			
			local errorVel = Error / trackingInterval
			
			botTable.LookTargetVelocity = ( errorVel * errorVector ) + subject:GetVelocity()
			
			botTable.LookTargetTrackingTimer = CurTime() + ( math.Rand( 0.8, 1.2 ) * trackingInterval )
			
		end
		
		botTable.LookTarget = botTable.LookTarget + deltaT * botTable.LookTargetVelocity
		
	end
	
	local to = botTable.LookTarget - self:GetShootPos()
	to:Normalize()
	
	local desiredAngles = to:Angle()
	local angles = Angle()
	
	local onTargetTolerance = 0.98
	local dot = forward:Dot( to )
	if dot > onTargetTolerance then
	
		botTable.IsSightedIn = true
		
		if !botTable.HasBeenSightedIn then
		
			botTable.HasBeenSightedIn = true
			
		end
		
	else
	
		botTable.IsSightedIn = false
		
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
	
	local targetDuration = CurTime() - botTable.LookTargetDuration
	if targetDuration < 0.25 then
	
		approachRate = approachRate * ( targetDuration / 0.25 )
		
	end
	
	--print( approachRate * deltaT )
	angles.y = math.ApproachAngle( currentAngles.y, desiredAngles.y, approachRate * deltaT )
	angles.x = math.ApproachAngle( currentAngles.x, desiredAngles.x, 0.5 * approachRate * deltaT )
	angles.z = 0
	
	-- back out "punch angle"
	angles = angles - self:GetViewPunchAngles()
	
	angles.x = math.AngleNormalize( angles.x )
	angles.y = math.AngleNormalize( angles.y )
	
	self:SetEyeAngles( angles )

end

function BOT:UpdateLookingAroundForEnemies()

	if !self.m_isLookingAroundForEnemies then
	
		return
		
	end

	local vision = self:GetTBotVision()
	local body = self:GetTBotBody()
	local mover = self:GetTBotLocomotion()
	local threat = vision:GetPrimaryKnownThreat()
	local botTable = self:GetTable()
	if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
	
		if threat:IsVisibleInFOVNow() then
		
			body:AimHeadTowards( threat:GetEntity(), TBotLookAtPriority.HIGH_PRIORITY, 1.0 )
			
		else
		
			if vision:IsLineOfSightClear( threat:GetEntity() ) then
			
				local toThreat = threat:GetEntity():GetPos() - self:GetPos()
				local threatRange = toThreat:Length()
				
				local s = math.sin( math.pi/6.0 )
				local Error = threatRange * s
				local imperfectAimSpot = threat:GetEntity():WorldSpaceCenter()
				imperfectAimSpot.x = imperfectAimSpot.x + math.Rand( -Error, Error )
				imperfectAimSpot.y = imperfectAimSpot.y + math.Rand( -Error, Error )
				
				body:AimHeadTowards( imperfectAimSpot, TBotLookAtPriority.MEDIUM_PRIORITY, 1.0 )
				
			end
		
		end
		
		return
	
	end
	
	-- Update the bot's encounter and approach points
	if ( !self:IsInCombat() and !self:IsSafe() ) and botTable.NextEncounterTime <= CurTime() then
	
		local minStillTime = 2.0
		if mover:IsNotMoving( minStillTime ) then
			
			local recomputeApproachPointTolerance = 50.0
			if ( botTable.ApproachViewPosition - self:GetPos() ):IsLengthGreaterThan( recomputeApproachPointTolerance ) then
			
				self:ComputeApproachPoints()
				botTable.ApproachViewPosition = self:GetPos()
			
			end
		
			if istable( botTable.ApproachPoints ) and #botTable.ApproachPoints > 0 then
		
				body:AimHeadTowards( botTable.ApproachPoints[ math.random( #botTable.ApproachPoints ) ].Pos + HalfHumanHeight, TBotLookAtPriority.MEDIUM_PRIORITY, 1.0 )
				botTable.NextEncounterTime = CurTime() + 2.0
				
			else
			
				body:AimHeadTowards( self:ComputeEncounterSpot(), TBotLookAtPriority.MEDIUM_PRIORITY, 1.0 )
				botTable.NextEncounterTime = CurTime() + 2.0
			
			end
		
		else
		
			body:AimAtPos( self:ComputeEncounterSpot(), TBotLookAtPriority.MEDIUM_PRIORITY, 1.0 )
			botTable.NextEncounterTime = CurTime() + 2.0
		
		end
	
	end

end

-- Given a subject, return the world space position we should aim at.
-- NOTE: This can be used to make the bot aim differently for certain situations
function BOT:SelectTargetPoint( subject )
	
	local myWeapon = self:GetActiveWeapon()
	local botTable = self:GetTable()
	if IsValid( myWeapon ) and myWeapon:IsWeapon() then
	
		if GetTBotRegisteredWeapon( myWeapon:GetClass() ).WeaponType == "Grenade" then
		
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
	
	if botTable.AimAdjustTimer <= CurTime() then
	
		botTable.AimAdjustTimer = CurTime() + math.Rand( 0.5, 1.5 )
		
		botTable.AimErrorAngle = math.Rand( -math.pi, math.pi )
		botTable.AimErrorRadius = math.Rand( 0.0, TBotAimError:GetFloat() )
		
	end
	
	local toThreat = subject:GetPos() - self:GetPos()
	local threatRange = toThreat:Length()
	toThreat:Normalize()
	
	local s1 = math.sin( botTable.AimErrorRadius )
	local Error = threatRange * s1
	local side = toThreat:Cross( vector_up )
	
	local s, c = math.sin( botTable.AimErrorAngle ), math.cos( botTable.AimErrorAngle )
	
	if botTable.AimForHead and !self:IsActiveWeaponRecoilHigh() then
	
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
	
	self:AimAtPos( look, 0.1, TBotLookAtPriority.LOW_PRIORITY )
	
end

function BOT:AimAtPos( Pos, Time, Priority )
	
	local botTable = self:GetTable()
	if !isvector( Pos ) then
	
		return
		
	end
	
	Time = tonumber( Time ) or 0.0
	Priority = tonumber( Priority ) or TBotLookAtPriority.LOW_PRIORITY
	
	if Time <= 0.0 then
	
		Time = 0.1
		
	end
	
	if botTable.LookTargetPriority == Priority then
	
		if !botTable.HeadSteadyTimer or CurTime() - botTable.HeadSteadyTimer < 0.3 then
		
			return
			
		end
		
	end
	
	if botTable.LookTargetPriority > Priority and botTable.LookTargetExpire > CurTime() then
	
		return
		
	end
	
	botTable.LookTargetExpire = CurTime() + Time
	
	if ( botTable.LookTarget - Pos ):IsLengthLessThan( 1.0 ) then
	
		botTable.LookTargetPriority = Priority
		return
		
	end
	
	botTable.LookTarget				=	Pos
	botTable.LookTargetSubject		=	nil
	--self.LookTargetState		=	LOOK_TOWARDS_SPOT
	botTable.LookTargetDuration		=	CurTime()
	botTable.LookTargetPriority		=	Priority
	botTable.HasBeenSightedIn		=	false
	--self.LookTargetTolerance	=	angleTolerance
	
end

function BOT:AimAtEntity( Subject, Time, Priority )
	
	local botTable = self:GetTable()
	if !IsValid( Subject ) then
	
		return
		
	end
	
	Time = tonumber( Time ) or 0.0
	Priority = tonumber( Priority ) or TBotLookAtPriority.LOW_PRIORITY
	
	if Time <= 0.0 then
	
		Time = 0.1
		
	end
	
	if botTable.LookTargetPriority == Priority then
	
		if !botTable.HeadSteadyTimer or CurTime() - botTable.HeadSteadyTimer < 0.3 then
		
			return
			
		end
		
	end
	
	if botTable.LookTargetPriority > Priority and botTable.LookTargetExpire > CurTime() then
	
		return
		
	end
	
	botTable.LookTargetExpire = CurTime() + Time
	
	if Subject == botTable.LookTargetSubject then
	
		botTable.LookTargetPriority = Priority
		return
		
	end
	
	botTable.LookTargetSubject		=	Subject
	--self.LookTargetState		=	LOOK_TOWARDS_SPOT
	botTable.LookTargetDuration		=	CurTime()
	botTable.LookTargetPriority		=	Priority
	botTable.HasBeenSightedIn		=	false
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
	
	local botTable = self:GetTable()
	if onlyRealBots and oldIsBot( self ) and botTable.TRizzleBot then
	
		return true
		
	end
	
	return !onlyRealBots and botTable.TRizzleBot
	
end

local oldGetInfo = oldGetInfo or BOT.GetInfo
-- This allows me to set the bot's client convars.
-- cl_logofile this convars seems to be the player's selected spray, would overriding this do anything?
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
	if !IsValid( activeWeapon ) or !activeWeapon:IsWeapon() then return false end
	
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
	
	local deltaYaw = math.AngleNormalize( idealAngles.y - viewAngles.y )
	local deltaPitch = math.AngleNormalize( idealAngles.x - viewAngles.x )
	
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

	local botTable = self:GetTable()
	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() then
	
		botTable.EnemyList = {}
		return
		
	end

	self:UpdateKnownEntities()
	botTable.LastVisionUpdateTimestamp = CurTime()
	
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
		
		if self:IsHiddenByFog( self:GetShootPos():DistToSqr( pos:WorldSpaceCenter() ) ) then
		
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
		
		if self:IsHiddenByFog( self:GetShootPos():DistToSqr( pos ) ) then
		
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

		self:GetTBotVision():Blind( fadeHold, self:IsInCombat() )
		
	end
	
	oldScreenFade( self, flags, clr, fadeTime, fadeHold )
	
end

-- Blinds the bot for a specified amount of time
function BOT:TBotBlind( time )
	if !self:Alive() or !self:IsTRizzleBot() or time < ( self.TRizzleBotBlindTime - CurTime() ) then return end
	
	self.TRizzleBotBlindTime = CurTime() + time
	self:AimAtPos( self:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward(), 0.1, TBotLookAtPriority.MAXIMUM_PRIORITY ) -- Make the bot fling its aim in a random direction upon becoming blind
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
	local startDist = fog:GetInternalVariable( "m_fog.start" )^2
	local endDist = fog:GetInternalVariable( "m_fog.end" )^2
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
	
	if !IsValid( targetFog ) then 
	
		local masterFogController = GetMasterFogController()
		if IsValid( masterFogController ) then
	
			targetFog = masterFogController
		
		end
		
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

	local bestDist = math.huge
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

	local body = self:GetTBotBody()
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
		
		return body:IsHeadAimingOnTarget() and body.m_lookAtSubject == target
		
		--return self:PointWithinCursor( target, self:SelectTargetPoint( target ) )
	
	end
	
	return false
end

-- This will select the best weapon based on the bot's current distance from its enemy
function BOT:SelectBestWeapon( target, enemydistsqr )
	if ( self.MinEquipInterval > CurTime() and !self:IsActiveWeaponClipEmpty() ) or ( !isnumber( enemydistsqr ) and !IsValid( target ) ) then return end
	
	enemydistsqr			=	enemydistsqr or target:GetPos():DistToSqr( self:GetPos() ) -- Only compute this once, there is no point in recomputing it multiple times as doing so is a waste of computer resources
	local botTable			=	self:GetTable()
	local vision			=	self:GetTBotVision()
	local oldBestWeapon 	= 	botTable.BestWeapon
	local minEquipInterval	=	0
	local bestWeapon		=	nil
	--local pistol			=	self:GetWeapon( self.Pistol )
	--local rifle				=	self:GetWeapon( self.Rifle )
	--local shotgun			=	self:GetWeapon( self.Shotgun )
	--local sniper			=	self:GetWeapon( self.Sniper )
	--local grenade			=	self:GetWeapon( self.Grenade )
	--local melee				=	self:GetWeapon( self.Melee )
	--local medkit			=	self:GetWeapon( "weapon_medkit" )
	
	-- Deprecated: This is now handled by the Action system!
	--[[if IsValid( medkit ) and botTable.CombatHealThreshold > self:Health() and medkit:Clip1() >= 25 then
		
		-- The bot will heal themself if they get too injured during combat
		botTable.BestWeapon = medkit
	
	else]]
	
	-- FIXME: This really should be neater.....
	-- Maybe in its own function?
	local desiredWeaponType = "Sniper"
	local backupWeaponType = nil
	if enemydistsqr < botTable.PistolDist^2 then
		
		desiredWeaponType = "Pistol"
		
	end
	
	if enemydistsqr < botTable.RifleDist^2 then
	
		desiredWeaponType = "Rifle"
		
	end
	
	if enemydistsqr < botTable.ShotgunDist^2 then
		
		desiredWeaponType = "Shotgun"
		
	end
	
	local knownCount = vision:GetKnownCount( nil, true, -1 )
	if enemydistsqr > 200^2 and knownCount >= 5 then
		
		if botTable.GrenadeInterval <= CurTime() then
			
			backupWeaponType = desiredWeaponType
			desiredWeaponType = "Grenade"
			
		elseif botTable.ExplosiveInterval <= CurTime() then
			
			backupWeaponType = desiredWeaponType
			desiredWeaponType = "Explosive"
			
		end
		
	end
	
	if enemydistsqr < botTable.MeleeDist^2 and knownCount < 5 then
		
		desiredWeaponType = "Melee"
		--desiredRange = 1
		
	end
	
	local preferredWeapons = botTable.TBotPreferredWeapons
	for k, weapon in ipairs( self:GetWeapons() ) do
	
		if IsValid( weapon ) and weapon:HasPrimaryAmmo() and weapon:IsTBotRegisteredWeapon() then 
			
			local weaponType = GetTBotRegisteredWeapon( weapon:GetClass() ).WeaponType
			if !IsValid( bestWeapon ) or weaponType == desiredWeaponType or ( GetTBotRegisteredWeapon( bestWeapon:GetClass() ).WeaponType != desiredWeaponType and weapon:GetTBotDistancePriority( isstring( backupWeaponType ) and backupWeaponType or desiredWeaponType ) > bestWeapon:GetTBotDistancePriority( isstring( backupWeaponType ) and backupWeaponType or desiredWeaponType ) ) then -- and bestWeapon:GetTBotDistancePriority() != desiredWeaponDistance + 1 )
			
				bestWeapon = weapon
				minEquipInterval = Either( weaponType != "Melee", 5.0, 2.0 )
				
			end
			
			-- Found the weapon we wanted!
			if tobool( preferredWeapons[ weapon:GetClass() ] ) and weaponType == desiredWeaponType then
				
				break
				
			end
			
		end
		
	end
	
	if IsValid( bestWeapon ) and oldBestWeapon != bestWeapon then 
		
		botTable.BestWeapon			= bestWeapon
		botTable.MinEquipInterval 	= CurTime() + minEquipInterval
		
		-- The bot should wait before throwing a grenade since some have a pull out animation
		if GetTBotRegisteredWeapon( bestWeapon:GetClass() ).WeaponType == "Grenade" then
			
			local deployDuration = bestWeapon:SequenceDuration( bestWeapon:LookupSequence( ACT_VM_DRAW ) )
			if deployDuration < 0 then deployDuration = 0.0 end
			botTable.FireWeaponInterval = CurTime() + deployDuration
			--self.FireWeaponInterval = CurTime() + 1.5
			
		end
		
	end
	
	--end
	
end

local function TBotRegisterWeaponCommand( ply, cmd, args )
	if !isstring( args[ 1 ] ) then error( "bad argument #1 to 'TBotRegisterWeapon' (string expected got " .. type( args[ 1 ] ) .. ")" ) end

	RegisterTBotWeapon( { ClassName = args[ 1 ], WeaponType = args[ 2 ], HasScope = args[ 3 ], HasSecondaryAttack = args[ 4 ], SecondaryAttackCooldown = args[ 5 ], MaxStoredAmmo = args[ 6 ], IgnoreAutomaticRange = args[ 7 ], ReloadsSingly = args[ 8 ] } )

end
concommand.Add( "TBotRegisterWeapon", TBotRegisterWeaponCommand, nil, "Registers a new weapon for the bot! ClassName = <string>, WeaponType = <string>, HasScope = <bool>, HasSecondaryAttack = <bool>, SecondaryAttackCooldown = <Number>, MaxStoredAmmo = <Number>, -- NOTE: This is optional. The bot will assume 6 clips of ammo by default IgnoreAutomaticRange = <bool>, -- If the weapon is automatic always press and hold when firing regardless of distance from current enemy! ReloadsSingly = <bool> -- NOTE: This is optional. The bot will assume true for shotguns and false for everything else." )

-- This registers a new weapon for the bot!
-- Here are the parameters if you use a table:
--[[
	ClassName = <string>,
	WeaponType = <string>,
	ReloadsSingly = <bool>, -- NOTE: This is optional. The bot will assume true for shotguns and false for everything else.
    HasScope = <bool>,
    HasSecondaryAttack = <bool>,
    SecondaryAttackCooldown = <Number>,
    MaxStoredAmmo = <Number>, -- NOTE: This is optional. The bot will assume 6 clips of ammo by default!
	IgnoreAutomaticRange = <bool>, -- If the weapon is automatic always press and hold when firing regardless of distance from current enemy!
]]
-- NOTE: The bot will automatically check if a weapon is automatic or not!
-- Here is a list of avaliable weapon types:
-- Rifle: This is the default type and only affects what distance the bot uses this weapon.
-- Melee: The bot treats this weapon as a melee weapon and will only press its attack button when close to its enemy.
-- Pistol: This tells the bot to use this weapon at the pistol range.
-- Sniper: This tells the bot to use this weapon at the sniper range.
-- Shotgun: The bot will use this weapon up close and will fully reload the clip when its completely empty.
-- Explosive: The bot should not use this when an enemy is nearby and will not fire this weapon when too close to its selected enemy.
-- Grenade: The bot will assume the weapon is a grenade and use the grenade AI.
--
function RegisterTBotWeapon( newWeapon )
	if !istable( newWeapon ) then error( "bad argument #1 to 'RegisterTBotWeapon' (Table expected got " .. type( newWeapon ) .. ")" ) end

	if TBotWeaponTable[ newWeapon.ClassName ] then
		
		print( "[INFORMATION] Overriding already registered weapon!" )
		
	end
	
	TBotWeaponTable[ newWeapon.ClassName ] = { WeaponType = newWeapon.WeaponType or "Rifle", ReloadsSingly = newWeapon.ReloadsSingly or newWeapon.WeaponType == "Shotgun", HasScope = tobool( newWeapon.HasScope ), HasSecondaryAttack = tobool( newWeapon.HasSecondaryAttack ), SecondaryAttackCooldown = tonumber( newWeapon.SecondaryAttackCooldown ) or 30.0, MaxStoredAmmo = tonumber( newWeapon.MaxStoredAmmo ), IgnoreAutomaticRange = tobool( newWeapon.IgnoreAutomaticRange ) }

end

-- Register the default weapons!
RegisterTBotWeapon( { ClassName = "weapon_stunstick", WeaponType = "Melee" } )
RegisterTBotWeapon( { ClassName = "weapon_frag", WeaponType = "Grenade" } )
RegisterTBotWeapon( { ClassName = "weapon_crossbow", WeaponType = "Sniper", HasScope = true, MaxStoredAmmo = 12 } )
RegisterTBotWeapon( { ClassName = "weapon_rpg", WeaponType = "Explosive" } )
RegisterTBotWeapon( { ClassName = "weapon_crowbar", WeaponType = "Melee" } )
RegisterTBotWeapon( { ClassName = "weapon_shotgun", WeaponType = "Shotgun", HasSecondaryAttack = true, SecondaryAttackCooldown = 10.0 } )
RegisterTBotWeapon( { ClassName = "weapon_pistol", WeaponType = "Pistol" } )
RegisterTBotWeapon( { ClassName = "weapon_smg1", WeaponType = "Rifle" } )
RegisterTBotWeapon( { ClassName = "weapon_ar2", WeaponType = "Rifle", HasSecondaryAttack = true } )
RegisterTBotWeapon( { ClassName = "weapon_357", WeaponType = "Pistol" } )

-- Register Half-Life 1 weapons!
RegisterTBotWeapon( { ClassName = "weapon_handgrenade", WeaponType = "Grenade" } )
RegisterTBotWeapon( { ClassName = "weapon_mp5_hl1", WeaponType = "Rifle", HasSecondaryAttack = true } )
RegisterTBotWeapon( { ClassName = "weapon_shotgun_hl1", WeaponType = "Shotgun", HasSecondaryAttack = true,  SecondaryAttackCooldown = 10.0 } )
RegisterTBotWeapon( { ClassName = "weapon_hornetgun", WeaponType = "Rifle" } )
RegisterTBotWeapon( { ClassName = "weapon_357_hl1", WeaponType = "Pistol" } )
RegisterTBotWeapon( { ClassName = "weapon_rpg_hl1", WeaponType = "Explosive" } )
RegisterTBotWeapon( { ClassName = "weapon_glock_hl1", WeaponType = "Pistol" } )
RegisterTBotWeapon( { ClassName = "weapon_crossbow_hl1", WeaponType = "Sniper", HasScope = true, MaxStoredAmmo = 12 } )
RegisterTBotWeapon( { ClassName = "weapon_gauss", WeaponType = "Rifle", MaxStoredAmmo = 250 } )
RegisterTBotWeapon( { ClassName = "weapon_egon", WeaponType = "Rifle", MaxStoredAmmo = 250, IgnoreAutomaticRange = true } )
RegisterTBotWeapon( { ClassName = "weapon_crowbar_hl1", WeaponType = "Melee" } )

-- Returns a table with the registered weapon's info.
-- If the weapon is not registered it returns an empty table.
function GetTBotRegisteredWeapon( className )

	return TBotWeaponTable[ className ] or {}

end

-- Returns the table of every registered weapon for TRizzleBots.
function GetTBotWeaponTable()

	return TBotWeaponTable -- Should I return of copy of the table instead?
	
end

-- Returns true if the weapon is a registered weapon for TRizzleBots.
function Wep:IsTBotRegisteredWeapon()

	return tobool( TBotWeaponTable[ self:GetClass() ] )
	
end

-- Returns the preferred distance ranking of this weapon type.
-- NOTE: I don't like the name of this function, but oh well....
function GetTBotDistancePriority( weaponType, desiredWeaponType )
	if !isstring( weaponType ) then return -1 end

	local NO_PRIORITY = 0
	local MINIMUM_PRIORITY = 1
	local LOW_PRIORITY = 2
	local MEDIUM_PRIORITY = 3
	local HIGH_PRIORITY = 4
	local MAXIMUM_PRIORITY = 5
	
	local backupWeaponPriorities = { Sniper = MAXIMUM_PRIORITY, Pistol = HIGH_PRIORITY, Rifle = MEDIUM_PRIORITY, Shotgun = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }
	if desiredWeaponType == "Pistol" then
		
		backupWeaponPriorities = { Sniper = HIGH_PRIORITY, Rifle = MEDIUM_PRIORITY, Shotgun = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }
	
	elseif desiredWeaponType == "Rifle" then
	
		backupWeaponPriorities = { Pistol = HIGH_PRIORITY, Sniper = MEDIUM_PRIORITY, Shotgun = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }

	elseif desiredWeaponType == "Shotgun" then
		
		backupWeaponPriorities = { Rifle = HIGH_PRIORITY, Pistol = MEDIUM_PRIORITY, Sniper = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }
	
	elseif desiredWeaponType == "Melee" then
		
		backupWeaponPriorities = { Shotgun = HIGH_PRIORITY, Rifle = MEDIUM_PRIORITY, Pistol = LOW_PRIORITY, Sniper = MINIMUM_PRIORITY, Explosive = NO_PRIORITY, Grenade = NO_PRIORITY }
		
	end
	
	return backupWeaponPriorities[ weaponType ] or NO_PRIORITY

end

-- Returns the preferred distance ranking of this weapon.
-- NOTE: I don't like the name of this function, but oh well....
function Wep:GetTBotDistancePriority( desiredWeaponType )
	if !self:IsTBotRegisteredWeapon() then return -1 end

	local NO_PRIORITY = 0
	local MINIMUM_PRIORITY = 1
	local LOW_PRIORITY = 2
	local MEDIUM_PRIORITY = 3
	local HIGH_PRIORITY = 4
	local MAXIMUM_PRIORITY = 5
	local weaponTable = GetTBotRegisteredWeapon( self:GetClass() )
	local weaponType = weaponTable.WeaponType
	
	local backupWeaponPriorities = { Sniper = MAXIMUM_PRIORITY, Pistol = HIGH_PRIORITY, Rifle = MEDIUM_PRIORITY, Shotgun = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }
	if desiredWeaponType == "Pistol" then
		
		backupWeaponPriorities = { Sniper = HIGH_PRIORITY, Rifle = MEDIUM_PRIORITY, Shotgun = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }
	
	elseif desiredWeaponType == "Rifle" then
	
		backupWeaponPriorities = { Pistol = HIGH_PRIORITY, Sniper = MEDIUM_PRIORITY, Shotgun = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }

	elseif desiredWeaponType == "Shotgun" then
		
		backupWeaponPriorities = { Rifle = HIGH_PRIORITY, Pistol = MEDIUM_PRIORITY, Sniper = LOW_PRIORITY, Explosive = MINIMUM_PRIORITY, Grenade = MINIMUM_PRIORITY, Melee = NO_PRIORITY }
	
	elseif desiredWeaponType == "Melee" then
		
		backupWeaponPriorities = { Shotgun = HIGH_PRIORITY, Rifle = MEDIUM_PRIORITY, Pistol = LOW_PRIORITY, Sniper = MINIMUM_PRIORITY, Explosive = NO_PRIORITY, Grenade = NO_PRIORITY }
		
	end
	
	return backupWeaponPriorities[ weaponType ] or NO_PRIORITY

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
	local botTable = self:GetTable()
	if IsValid( botWeapon ) and botWeapon:GetClass() != "weapon_medkit" and botWeapon:NeedsToReload() then return end
	
	for k, weapon in ipairs( self:GetWeapons() ) do
	
		if IsValid( weapon ) and weapon:IsTBotRegisteredWeapon() and weapon:NeedsToReload() then
		
			botTable.BestWeapon = weapon
			break
			
		end
		
	end
	
end

-- This is kind of a cheat, but the bot will only slowly recover ammo when not in combat
function BOT:RestoreAmmo()
	
	for k, weapon in ipairs( self:GetWeapons() ) do
	
		local weapon_ammo
		if IsValid( weapon ) and weapon:IsTBotRegisteredWeapon() then weapon_ammo		=	self:GetAmmoCount( weapon:GetPrimaryAmmoType() ) end
		
		local weaponTable = GetTBotRegisteredWeapon( weapon:GetClass() )
		if isnumber( weapon_ammo ) and ( self:IsSafe() or weaponTable.WeaponType != "Grenade" ) and weapon:UsesPrimaryAmmo() then 
			
			local maxStoredAmmo = tonumber( weaponTable.MaxStoredAmmo )
			if isnumber( maxStoredAmmo ) and maxStoredAmmo > 0 then
				
				if weapon_ammo < maxStoredAmmo then
				
					self:GiveAmmo( 1, weapon:GetPrimaryAmmoType(), true )
					
				end
			
			elseif weapon:UsesClipsForAmmo1() and weapon_ammo < ( weapon:GetMaxClip1() * 6 ) or !weapon:UsesClipsForAmmo1() and weapon_ammo < 6 then
		
				self:GiveAmmo( 1, weapon:GetPrimaryAmmoType(), true )
				
			end
		
		end
		
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

	if self:GetClass() == "func_door" or self:GetClass() == "prop_door_rotating" or self:GetClass() == "func_door_rotating" then
        
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

	local botTable = self:GetTable()
	local CurrentLeader = botTable.GroupLeader
	if !IsValid( CurrentLeader ) or !CurrentLeader:Alive() then CurrentLeader = nil end -- Our current group leader is dead or invalid we should select another one.
	for k, bot in player.Iterator() do
	
		if IsValid( bot ) and bot:Alive() and bot:IsTRizzleBot() and self != bot then 
		
			local botTable2 = bot:GetTable()
			if botTable.TBotOwner == botTable2.TBotOwner and IsValid( botTable2.GroupLeader ) and botTable2.GroupLeader:Alive() then
		
				CurrentLeader = botTable2.GroupLeader
				break
				
			end
		
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
	time = tonumber( time ) or 10.0

	local botTable = self:GetTable()
	if isvector( spot ) then
	
		botTable.HidingSpot = spot
		botTable.HidingState = MOVE_TO_SPOT
		botTable.HideReason	= reason
		
		if reason == RELOAD_IN_COVER then 
		
			if isvector( time ) then
			
				botTable.ReturnPos = time
				
			else
			
				botTable.ReturnPos = self:GetPos()
				
			end
		
		else
		
			botTable.HideTime	= time 
			
		end
	
	end

end

-- Returns true if the bot is trying to hide
function BOT:IsHiding()

	local botTable = self:GetTable()
	if !isvector( botTable.HidingSpot ) or botTable.HideReason == NONE then
	
		return false
		
	end

	return botTable.HidingState != FINISHED_HIDING
	
end

-- Returns true if the bot is hiding and at its hiding spot.
function BOT:IsAtHidingSpot()

	if !self:IsHiding() then
	
		return false
		
	end
	
	return self.HidingState == WAIT_AT_SPOT

end

function BOT:IsNotMoving( minDuration )

	local botTable = self:GetTable()
	if !botTable.StillTimer then
	
		return false
		
	end

	return CurTime() - botTable.StillTimer >= minDuration
	
end

-- If and entity gets removed, clear it from the bot's attack list.
hook.Add( "EntityRemoved" , "TRizzleBotEntityRemoved" , function( ent, fullUpdate ) 

	for k, bot in player.Iterator() do
	
		if IsValid( bot ) and bot:IsTRizzleBot() then
		
			bot.AttackList[ ent ] = nil
			
		end
		
	end

end)

-- When an NPC dies, it should be removed from the bot's known entity list.
-- This is also called for some nextbots.
hook.Add( "OnNPCKilled" , "TRizzleBotOnNPCKilled" , function( npc )

	for k, bot in player.Iterator() do
	
		if IsValid( bot ) and bot:IsTRizzleBot() then
		
			bot:ForgetEntity( npc )
			bot.AttackList[ npc ] = nil
			
		end
		
	end

end)

-- When the bot dies, it seems to keep its weapons for some reason. This hook removes them when the bot dies.
-- This hook also checks if a player dies and removes said player from every bots known enemy list.
--[[hook.Add( "PostPlayerDeath" , "TRizzleBotPostPlayerDeath" , function( ply )

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

end)]]

-- When a player leaves the server, every bot "owned" by the player should leave as well
--[[hook.Add( "PlayerDisconnected" , "TRizzleBotPlayerLeave" , function( ply )
	
	if !ply:IsTRizzleBot( true ) then 
		
		for k, bot in player.Iterator() do
		
			local botTable = bot:GetTable()
			if IsValid( bot ) and bot:IsTRizzleBot() then 
			
				botTable.AttackList[ ply ] = nil
				
				if botTable.TBotOwner == ply then
			
					if bot:IsTRizzleBot( true ) then
					
						bot:Kick( "Owner " .. ply:Nick() .. " has left the server" )
						
					else
					
						botTable.TBotOwner = bot
						
					end
					
				end
			
			end
		end
		
	end
	
end)]]

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
	
	for k, bot in player.Iterator() do
	
		local botTable = bot:GetTable()
		if IsValid( bot ) and bot:IsTRizzleBot() then
			
			bot:GetTBotBody():Upkeep()
			bot:GetTBotLocomotion():Upkeep()
			--bot:UpdateAim()
			
			-- TODO: We need to a better way to limit how often the bot's update their AI!
			if ( ( engine.TickCount() + bot:EntIndex() ) % BotUpdateSkipCount ) == 0 then
			
				bot:ResetCommand() -- Clear all movement and buttons
				
				-- Deprecated: Respawning is now handled in the behavior interface!
				--[[if !bot:Alive() then -- We do the respawning here since its better than relying on timers
			
					if ( !botTable.NextSpawnTime or botTable.NextSpawnTime <= CurTime() ) and bot:GetDeathTimestamp() > TBotSpawnTime:GetFloat() + 60.0 then -- Just incase something stops the bot from respawning, I force them to respawn anyway
					
						bot:Spawn()
						
					elseif ( !botTable.NextSpawnTime or botTable.NextSpawnTime <= CurTime() ) and bot:GetDeathTimestamp() > TBotSpawnTime:GetFloat() then -- I have to manually call the death think hook, or the bot won't respawn
						
						bot:PressPrimaryAttack()
						hook.Run( "PlayerDeathThink", bot )
					
					end
					
					continue -- We don't need to think while dead
					
				end]]
				
				--bot:UpdateVision()
				-- This seems to lag the game
				bot:UpdatePeripheralVision() -- Should this be moved into the vision interface?
				
				-- Deprecated: This is handled in the locomotion interface
				local speed = bot:GetVelocity():Length()
	
				if speed > 10.0 then
				
					botTable.MotionVector = bot:GetVelocity() / speed
					
				end
				
				bot:GetTBotBehavior():Update( bot, engine.TickInterval() * BotUpdateSkipCount ) -- I think the update rate is correct?
				bot:GetTBotVision():Update( bot, engine.TickInterval() * BotUpdateSkipCount ) -- The vision interface doesn't use these, but just in case...
				bot:GetTBotLocomotion():Update( bot, engine.TickInterval() * BotUpdateSkipCount ) -- The locomotion interface doesn't use these, but just in case...
				--bot:TBotUpdateLocomotion()
				--bot:StuckMonitor()
				
				--if bot:GetCollisionGroup() != 5 then bot:SetCollisionGroup( 5 ) end -- Apparently the bot's default collisiongroup is set to 11 causing the bot not to take damage from melee enemies
				
				--[[if !IsValid( botTable.TBotOwner ) or !botTable.TBotOwner:Alive() then	
					
					if ( ( engine.TickCount() + bot:EntIndex() ) % 5 ) == 0 then
						
						local CurrentLeader = bot:FindGroupLeader()
						if IsValid( CurrentLeader ) then
						
							botTable.GroupLeader = CurrentLeader
							
						else
						
							botTable.GroupLeader = bot
						
						end
						
					end
				
				--elseif IsValid( bot.GroupLeader ) then -- If the bot's owner is alive, the bot should clear its group leader and the hiding spot it was trying to goto
					
					--bot.GroupLeader	= nil
					--bot:ClearHidingSpot()
					
				end
				
				botTable.ReviveTarget = bot:TBotFindReviveTarget()
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
					
					botTable.LastCombatTime = CurTime() -- Update combat timestamp
					
					local enemy = threat:GetEntity()
					local enemyDist = enemy:GetPos():DistToSqr( bot:GetPos() ) -- Grab the bot's current distance from their current enemy
					
					-- Should I limit how often this runs?
					local trace = {}
					util.TraceLine( { start = bot:GetShootPos(), endpos = enemy:GetHeadPos(), filter = bot, mask = MASK_SHOT, output = trace } )
					
					if trace.Entity == enemy then
						
						botTable.AimForHead = true
						
					else
						
						botTable.AimForHead = false
						
					end
					
					if IsValid( botWeapon ) and botWeapon:IsWeapon() then
						
						local weaponTable = GetTBotRegisteredWeapon( botWeapon:GetClass() )
						local weaponType = weaponTable.WeaponType
						if botTable.FullReload and ( !botWeapon:NeedsToReload() or weaponType != "Shotgun" ) then botTable.FullReload = false end -- Fully reloaded :)
						
						if CurTime() >= botTable.ScopeInterval and weaponTable.HasScope then 
						
							if !bot:IsUsingScope() and enemyDist >= 400^2 or bot:IsUsingScope() and enemyDist < 400^2 then
						
								bot:PressSecondaryAttack()
								botTable.ScopeInterval = CurTime() + 0.4
								botTable.FireWeaponInterval = CurTime() + 0.4
								
							end
						
						end
						
						if CurTime() >= botTable.FireWeaponInterval then 
						
							if !bot:IsReloading() and !botTable.FullReload and !botWeapon:IsPrimaryClipEmpty() and botWeapon:GetClass() != "weapon_medkit" then 
							
								if weaponTable.HasSecondaryAttack and botTable.SecondaryInterval <= CurTime() and enemyDist > 40000 and bot:GetKnownCount( nil, true, -1 ) >= 3 then
								
									bot:PressSecondaryAttack()
									botTable.SecondaryInterval = CurTime() + weaponTable.SecondaryAttackCooldown
									--bot.MinEquipInterval = CurTime() + 2.0
								
								elseif ( weaponType != "Grenade" or ( botTable.GrenadeInterval <= CurTime() and botWeapon:GetNextPrimaryFire() <= CurTime() ) ) and ( weaponType != "Melee" or enemyDist <= botTable.MeleeDist^2 ) and bot:IsCursorOnTarget( enemy ) then
							
									bot:PressPrimaryAttack()
									
									-- The bot should throw a grenade then swap to another weapon
									if weaponType == "Grenade" and botTable.GrenadeInterval <= CurTime() then
									
										botTable.GrenadeInterval = CurTime() + 22.0
										botTable.MinEquipInterval = CurTime() + 2.0
									
									elseif weaponType == "Explosive" and botTable.ExplosiveInterval <= CurTime() then
									
										botTable.ExplosiveInterval = CurTime() + 22.0
										botTable.MinEquipInterval = CurTime() + 2.0
									
									end
									
									-- If the bot's active weapon is automatic the bot should just press and hold its attack button if their current enemy is close enough
									if bot:IsActiveWeaponAutomatic() and ( enemyDist < 160000 or weaponTable.IgnoreAutomaticRange ) then
										
										botTable.FireWeaponInterval = CurTime()
										
									elseif enemyDist < 640000 then
										
										botTable.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )
										
									else
										
										botTable.FireWeaponInterval = CurTime() + math.Rand( 0.3 , 0.7 )
										
									end
									
									-- Subtract system latency
									botTable.FireWeaponInterval = botTable.FireWeaponInterval - BotUpdateInterval
									
								end
								
							elseif botWeapon:GetClass() == "weapon_medkit" and botTable.CombatHealThreshold > bot:Health() then
							
								bot:PressSecondaryAttack()
								botTable.FireWeaponInterval = CurTime() + 0.5
								
							end
							
						end
						
						if CurTime() >= botTable.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and weaponType != "Melee" and botWeapon:IsPrimaryClipEmpty() then
							
							if weaponType == "Shotgun" then botTable.FullReload = true end
							
							bot:PressReload()
							botTable.ReloadInterval = CurTime() + 0.5
							
						end
						
						-- If an enemy gets too close and the bot is not using its melee weapon the bot should retreat backwards
						if !bot:IsPathValid() and weaponType != "Melee" and enemyDist < 10000 then
							
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
						botTable.HealTarget = bot:TBotFindHealTarget()
						
						-- Don't attempt to reload weapons while we are healing.
						if bot:GetTBotState() != HEAL_PLAYER then
						
							bot:ReloadWeapons()
							
						end
						
						if IsValid( botWeapon ) and botWeapon:IsWeapon() then 
							
							local weaponTable = GetTBotRegisteredWeapon( botWeapon:GetClass() )
							local weaponType = weaponTable.WeaponType
							if CurTime() >= botTable.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and weaponType != "Melee" and botWeapon:NeedsToReload() then
						
								bot:PressReload()
								botTable.ReloadInterval = CurTime() + 0.5
								
							end
							
							if CurTime() >= botTable.ScopeInterval and weaponTable.HasScope and bot:IsUsingScope() then
								
								bot:PressSecondaryAttack()
								botTable.ScopeInterval = CurTime() + 1.0
								
							end
							
						end
						
						-- The bot will slowly regenerate ammo it has lost when not in combat
						-- The bot will quickly regenerate ammo once it is safe
						if bot:IsSafe() or ( ( engine.TickCount() + bot:EntIndex() ) % math.floor( 1 / engine.TickInterval() ) == 0 ) then
						
							bot:RestoreAmmo()
							
						end
						
					else
					
						if IsValid( botWeapon ) and botWeapon:IsWeapon() then 
						
							local weaponTable = GetTBotRegisteredWeapon( botWeapon:GetClass() )
							local weaponType = weaponTable.WeaponType
							if CurTime() >= botTable.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and weaponType != "Melee" and botWeapon:NeedsToReload() and ( botWeapon:IsPrimaryClipEmpty() or ( weaponType == "Shotgun" and bot:GetKnownCount( nil, true, -1 ) <= 0 ) or ( botWeapon:Clip1() < ( botWeapon:GetMaxClip1() * 0.6 ) and #botTable.EnemyList <= 0 ) ) then
						
								bot:PressReload()
								botTable.ReloadInterval = CurTime() + 0.5
								
							end
							
						end
						
					end
				
				end
				
				-- Here is the AI for GroupLeaders
				if IsValid( botTable.GroupLeader ) then
					
					if bot:IsGroupLeader() then
					
						-- If the bot's group is being overwhelmed then they should retreat
						if !isvector( botTable.HidingSpot ) and !bot:IsPathValid() and botTable.HidingSpotInterval <= CurTime() then 
						
							if ( istbotknownentity( threat ) and threat:IsVisibleRecently() and bot:Health() < bot.CombatHealThreshold ) or bot:GetKnownCount( nil, true, bot.DangerDist ) >= 10 then
					
								botTable.HidingSpotInterval = CurTime() + 0.5
								bot:TBotSetHidingSpot( bot:FindSpot( "far", { pos = bot:GetPos(), radius = 10000, stepdown = 1000, stepup = bot:GetMaxJumpHeight(), checksafe = 1, checkoccupied = 1, checklineoffire = 1 } ), RETREAT, 10.0 )
						
							elseif bot:IsSafe() and botTable.NextHuntTime <= CurTime() then
						
								botTable.HidingSpotInterval = CurTime() + 0.5
								bot:TBotSetHidingSpot( bot:FindSpot( "random", { pos = bot:GetPos(), radius = math.random( 5000, 10000 ), stepdown = 1000, stepup = bot:GetMaxJumpHeight(), spotType = "sniper", checksafe = 0, checkoccupied = 1, checklineoffire = 0 } ), SEARCH_AND_DESTORY, 30.0 )
						
							end
						
						end
					
					else
					
						-- If the bot needs to reload its active weapon it should find cover nearby and reload there
						if !isvector( botTable.HidingSpot ) and !bot:IsPathValid() and botTable.HidingSpotInterval <= CurTime() and istbotknownentity( threat ) and threat:IsVisibleRecently() and IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and TBotWeaponTable[ botWeapon:GetClass() ].WeaponType != "Melee" and botWeapon:IsPrimaryClipEmpty() and botTable.GroupLeader:GetPos():DistToSqr( bot:GetPos() ) < botTable.FollowDist^2 then

							botTable.HidingSpotInterval = CurTime() + 0.5
							bot:TBotSetHidingSpot( bot:FindSpot( "near", { pos = bot:GetPos(), radius = 500, stepdown = 1000, stepup = bot:GetMaxJumpHeight(), checksafe = 1, checkoccupied = 1, checklineoffire = 1 } ), RELOAD_IN_COVER )

						end
					
					end
					
				elseif IsValid( botTable.TBotOwner ) and botTable.TBotOwner:Alive() then
					
					-- If the bot needs to reload its active weapon it should find cover nearby and reload there
					if !isvector( botTable.HidingSpot ) and !bot:IsPathValid() and botTable.HidingSpotInterval <= CurTime() and istbotknownentity( threat ) and threat:IsVisibleRecently() and IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and TBotWeaponTable[ botWeapon:GetClass() ].WeaponType != "Melee" and botWeapon:IsPrimaryClipEmpty() and botTable.TBotOwner:GetPos():DistToSqr( bot:GetPos() ) < botTable.FollowDist^2 then

						botTable.HidingSpotInterval = CurTime() + 0.5
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
					
				end]]
				
				-- The check CNavArea we are standing on.
				if !IsValid( botTable.currentArea ) or !botTable.currentArea:Contains( bot:GetPos() ) then
				
					botTable.currentArea			=	navmesh.GetNearestNavArea( bot:GetPos(), true, 50, true )
					
				end
				
				if IsValid( botTable.currentArea ) and botTable.currentArea != botTable.lastKnownArea then
				
					botTable.lastKnownArea = botTable.currentArea
					
				end
				
				-- Deprecated: This is handled in the locomotion interface
				local stillSpeed = 10.0
				if bot:GetVelocity():IsLengthLessThan( stillSpeed ) then
				
					if !botTable.StillTimer then
					
						botTable.StillTimer = CurTime()
						
					end
					
				else
				
					botTable.StillTimer = nil
					
				end
				
				-- Update the bot's encounter and approach points
				--[[if ( ( !bot:IsInCombat() and !bot:IsSafe() ) or bot:IsHiding() ) and botTable.NextEncounterTime <= CurTime() then
				
					local minStillTime = 2.0
					if bot:IsAtHidingSpot() or bot:IsNotMoving( minStillTime ) then
						
						local recomputeApproachPointTolerance = 50.0
						if ( botTable.ApproachViewPosition - bot:GetPos() ):IsLengthGreaterThan( recomputeApproachPointTolerance ) then
						
							bot:ComputeApproachPoints()
							botTable.ApproachViewPosition = bot:GetPos()
						
						end
					
						if istable( botTable.ApproachPoints ) and #botTable.ApproachPoints > 0 then
					
							bot:AimAtPos( bot.ApproachPoints[ math.random( #botTable.ApproachPoints ) ].Pos + HalfHumanHeight, 1.0, MEDIUM_PRIORITY )
							botTable.NextEncounterTime = CurTime() + 2.0
							
						else
						
							bot:AimAtPos( bot:ComputeEncounterSpot(), 1.0, MEDIUM_PRIORITY )
							botTable.NextEncounterTime = CurTime() + 2.0
						
						end
					
					else
					
						bot:AimAtPos( bot:ComputeEncounterSpot(), 1.0, MEDIUM_PRIORITY )
						botTable.NextEncounterTime = CurTime() + 2.0
					
					end
				
				end
				
				-- Update the bot movement if they are pathing to a goal
				bot:TBotDebugWaypoints()
				bot:TBotUpdateMovement()
				bot:TBotUpdateLocomotion()
				bot:StuckMonitor()
				bot:DoorCheck()
				bot:BreakableCheck()
				
				local tbotOwner = botTable.TBotOwner
				if IsValid( tbotOwner ) then
				
					if tbotOwner:InVehicle() and !bot:InVehicle() then
					
						local vehicle = bot:FindNearbySeat()
						
						if IsValid( vehicle ) then bot:EnterVehicle( vehicle ) end -- I should make the bot press its use key instead of this hack
					
					end
					
					if !tbotOwner:InVehicle() and bot:InVehicle() and CurTime() >= botTable.UseInterval then
					
						bot:PressUse()
						botTable.UseInterval = CurTime() + 0.5
					
					end
					
				end
				
				-- Only check if we need to spawn in weapons every second since this creates lag if we don't
				if botTable.SpawnWithWeapons and ( ( engine.TickCount() + bot:EntIndex() ) % math.floor( 1 / engine.TickInterval() ) == 0 ) then
					
					bot:Give( bot.Pistol )
					bot:Give( bot.Shotgun )
					bot:Give( bot.Rifle )
					bot:Give( bot.Sniper )
					bot:Give( bot.Melee )
					bot:Give( "weapon_medkit" )
					if bot:IsSafe() then bot:Give( bot.Grenade ) end -- The bot should only spawn in its grenade if it feels safe.
					
					for weapon, _ in pairs( botTable.TBotPreferredWeapons ) do
					
						local weaponTable = GetTBotRegisteredWeapon( weapon )
						if !table.IsEmpty( weaponTable ) then
						
							-- The bot should only spawn in its grenade if it feels safe.
							if bot:IsSafe() or weaponTable.WeaponType != "Grenade" then
						
								bot:Give( weapon )
							
							end
							
						end
						
					end
					bot:Give( "weapon_medkit" )
					
				end]]
				
				--[[if bot:CanUseFlashlight() and botTable.ImpulseInterval <= CurTime() then
				
					if !bot:TBotIsFlashlightOn() and botTable.Light and bot:GetSuitPower() > 50 then
						
						botTable.impulseFlags = 100
						botTable.ImpulseInterval = CurTime() + 0.5
						--bot:Flashlight( true )
						
					elseif bot:TBotIsFlashlightOn() and !botTable.Light then
						
						botTable.impulseFlags = 100
						botTable.ImpulseInterval = CurTime() + 0.5
						--bot:Flashlight( false )
						
					end
					
				end]]
				
				--bot:HandleButtons()
				
			end
			
		end
		
	end

	--print( "Think RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	
end)

-- This is the bot's idle state
function BOT:TBotIdleState()

	local botTable = self:GetTable()
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	local useEnt = botTable.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	local botReviveTarget = botTable.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, self.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	local botHoldPos = botTable.HoldPos
	if isvector( botHoldPos ) then
	
		self:TBotSetState( HOLD_POSITION )
		return
		
	end
	
	local botOwner = botTable.TBotOwner
	if IsValid( botOwner ) and botOwner:Alive() then
	
		self.GroupLeader = nil
		local ownerDist = botOwner:GetPos():DistToSqr( self:GetPos() )
		if ownerDist > self.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_OWNER )
			return
			
		end
	
	end
	
	local botLeader = botTable.GroupLeader
	if IsValid( botLeader ) and !self:IsGroupLeader() then
	
		local leaderDist = botLeader:GetPos():DistToSqr( self:GetPos() )
		if leaderDist > self.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_GROUP_LEADER )
			return
			
		end
		
	end
	
	-- These states should only become activate when we are not in combat.
	if !self:IsInCombat() then
	
		local botHealTarget = botTable.HealTarget
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
	local botTable = self:GetTable()
	if !self:IsHiding() then
	
		self:TBotSetState( IDLE )
		return
		
	end

	local botWeapon = self:GetActiveWeapon()
	local threat = self:GetPrimaryKnownThreat()
	if botTable.HidingState == MOVE_TO_SPOT then
	
		local spotDistSq = self:GetPos():DistToSqr( botTable.HidingSpot )
		-- When have reached our destination start the wait timer
		if spotDistSq <= 1024 then
			
			botTable.HidingState = WAIT_AT_SPOT
			botTable.HideTime = CurTime() + botTable.HideTime
		
		-- If the bot finished reloading its active weapon it should clear its selected hiding spot!
		elseif botTable.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or !botWeapon:NeedsToReload() ) then
		
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		-- If the bot finds an enemy, it should clear its selected hiding spot
		elseif botTable.HideReason == SEARCH_AND_DESTORY and self:IsInCombat() then
		
			botTable.NextHuntTime = CurTime() + 10
			self:TBotClearPath()
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		-- If the bot has a hiding spot it should path there
		elseif botTable.RepathTimer <= CurTime() and spotDistSq > 1024 then
		
			TRizzleBotPathfinderCheap( self, botTable.HidingSpot )
			--bot:TBotCreateNavTimer()
			botTable.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
		
		end
	
	elseif botTable.HidingState == WAIT_AT_SPOT then
		
		-- If the bot has finished hiding, it should clear its selected hiding spot
		if ( botTable.HideReason == RETREAT or botTable.HideReason == SEARCH_AND_DESTORY ) and botTable.HideTime <= CurTime() then
			
			botTable.NextHuntTime = CurTime() + 20.0
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		-- If the bot has finished reloading its active weapon, it should clear its selected hiding spot
		elseif botTable.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or !botWeapon:NeedsToReload() ) then
		
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
			
		-- If the bot's hiding spot is no longer safe, it should clear its selected hiding spot
		elseif !self:IsSpotSafe( botTable.HidingSpot + HalfHumanHeight ) then
		
			botTable.NextHuntTime = CurTime() + 20.0
			self:ClearHidingSpot()
			self:TBotSetState( IDLE )
			return
		
		elseif !IsValid( self:GetLastKnownArea() ) or !self:GetLastKnownArea():HasAttributes( NAV_MESH_STAND ) then
		
			-- The bot should crouch once it reaches its selected hiding spot
			self:PressCrouch()
		
		end
		
	end
	
	if botTable.HideReason == RELOAD_IN_COVER and IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() >= botTable.ReloadInterval and !self:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:NeedsToReload() then
		
		self:PressReload()
		botTable.ReloadInterval = CurTime() + 0.5
		
	end

end

-- This is the bot's use entity state
function BOT:TBotUseEntityState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	local botTable = self:GetTable()
	if self:IsHiding() then
	
		botTable.UseEnt = nil
		botTable.UseHoldTime = 0
		botTable.StartedUse = false
		self:TBotSetState( HIDE )
		return
		
	end

	local botUseEnt = botTable.UseEnt
	if !IsValid( botUseEnt ) or ( botTable.UseHoldTime <= CurTime() and botTable.StartedUse ) then
	
		botTable.UseEnt = nil
		botTable.UseHoldTime = 0
		botTable.StartedUse = false
		self:TBotSetState( IDLE )
		return
	
	end
	
	local useEnt = self:GetUseEntity()
	if botTable.RepathTimer <= CurTime() and useEnt != botUseEnt then
	
		TRizzleBotPathfinderCheap( self, botTable.UseEnt:GetPos() )
		--bot:TBotCreateNavTimer()
		botTable.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
	
	elseif useEnt == botUseEnt then
	
		self:PressUse()
		botTable.RepathTimer = 0
		self:TBotClearPath()
		
		if !botTable.StartedUse then
		
			botTable.StartedUse = true
			botTable.UseHoldTime = CurTime() + botTable.UseHoldTime
			
		end
	
	end
	
	if botUseEnt:GetPos():DistToSqr( self:GetPos() ) <= 200^2 and self:IsAbleToSee( botUseEnt ) then
		
		self:AimAtPos( botUseEnt:WorldSpaceCenter(), 0.1, TBotLookAtPriority.HIGH_PRIORITY )
		
	end
	
end

-- This is the bot's revive player state
-- NOTE: This only used if the revive mod is installed
function BOT:TBotRevivePlayerState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	local botTable = self:GetTable()
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than reviving someone.
	local useEnt = botTable.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	local botReviveTarget = botTable.ReviveTarget
	if !IsValid( botReviveTarget ) or self:GetKnownCount( nil, false, botTable.DangerDist ) > 5 then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local reviveTargetDist = botReviveTarget:GetPos():DistToSqr( self:GetPos() )
	if reviveTargetDist > 80^2 or !self:IsLineOfFireClear( botReviveTarget ) then
		
		if ( botTable.ChaseTimer <= CurTime() and ( !self:IsPathValid() or self:IsRepathNeeded( botReviveTarget ) ) ) or botTable.RepathTimer <= CurTime() then
			
			TRizzleBotPathfinderCheap( self, botReviveTarget:GetPos() )
			--bot:TBotCreateNavTimer()
			botTable.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
			botTable.ChaseTimer = CurTime() + 0.5
			
		end
		
	elseif self:IsPathValid() then
		
		self:TBotClearPath()
		
	end
	
	if reviveTargetDist <= 100^2 and self:IsAbleToSee( botReviveTarget ) then
		
		self:AimAtPos( botReviveTarget:GetPos(), 0.1, TBotLookAtPriority.HIGH_PRIORITY )
		
		if self:IsLookingAtPosition( botReviveTarget:GetPos() ) then
		
			self:PressUse()
			
		end
	
	end

end

-- This is the bot's hold position state
function BOT:TBotHoldPositionState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	local botTable = self:GetTable()
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than holding our current position.
	-- We will go back to holding the position set by our owner when we finish.
	local useEnt = botTable.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than holding where our owner told us.
	local botReviveTarget = botTable.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, botTable.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	local botHoldPos = botTable.HoldPos
	if !isvector( botHoldPos ) then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local goalDist = self:GetPos():DistToSqr( botHoldPos )
	if goalDist > TBotGoalTolerance:GetFloat()^2 then
		
		if botTable.RepathTimer <= CurTime() then
		
			TRizzleBotPathfinderCheap( self, botHoldPos )
			--bot:TBotCreateNavTimer()
			botTable.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
		
		end
	
	end
	
end

-- This is the bot's heal player state
function BOT:TBotHealPlayerState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	local botTable = self:GetTable()
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than healing someone.
	-- We will go back to healing when we finish.
	local useEnt = botTable.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than healing someone.
	local botReviveTarget = botTable.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, botTable.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	-- Following our owner is more important than healing someone.
	local botOwner = botTable.TBotOwner
	if IsValid( botOwner ) and botOwner:Alive() then
	
		botTable.GroupLeader = nil
		local ownerDist = botOwner:GetPos():DistToSqr( self:GetPos() )
		if ownerDist > botTable.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_OWNER )
			return
			
		end
	
	end
	
	-- Following our group leader is more important than healing someone.
	local botLeader = botTable.GroupLeader
	if IsValid( botLeader ) and !self:IsGroupLeader() then
	
		local leaderDist = botLeader:GetPos():DistToSqr( self:GetPos() )
		if leaderDist > botTable.FollowDist^2 then
		
			self:TBotSetState( FOLLOW_GROUP_LEADER )
			return
			
		end
		
	end
	
	-- The bot shouldn't heal while in combat.
	if self:IsInCombat() then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local botHealTarget = botTable.HealTarget
	if !IsValid( botHealTarget ) or !self:HasWeapon( "weapon_medkit" ) then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	botTable.BestWeapon = self:GetWeapon( "weapon_medkit" )
	
	local botWeapon = self:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" then
		
		if CurTime() >= botTable.FireWeaponInterval then 
			
			if botHealTarget == self then
			
				self:PressSecondaryAttack()
				botTable.FireWeaponInterval = CurTime() + 0.5
			
			elseif self:GetEyeTrace().Entity == botHealTarget then
				
				self:PressPrimaryAttack()
				botTable.FireWeaponInterval = CurTime() + 0.5
				
			end
			
		end
	
		if botHealTarget != self then self:AimAtPos( botHealTarget:WorldSpaceCenter(), 0.1, TBotLookAtPriority.MEDIUM_PRIORITY ) end
	
	end
	
end

-- This is the bot's follow owner state.
function BOT:TBotFollowOwnerState()

	-- The hiding state has the most priority so, only when the bot is done hiding 
	-- is when it should care about anything else.
	local botTable = self:GetTable()
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than following its owner.
	-- We will go back to following when we finish.
	local useEnt = botTable.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than following its owner.
	local botReviveTarget = botTable.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, botTable.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	-- Our owner has told us to wait at a set postion, its a higher priority than following them.
	local botHoldPos = botTable.HoldPos
	if isvector( botHoldPos ) then
	
		self:TBotSetState( HOLD_POSITION )
		return
		
	end
	
	local botOwner = botTable.TBotOwner
	if !IsValid( botOwner ) or !botOwner:Alive() then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local ownerDist = botOwner:GetPos():DistToSqr( self:GetPos() )
	if ownerDist > self.FollowDist^2 then
		
		if ( botTable.ChaseTimer <= CurTime() and ( !self:IsPathValid() or self:IsRepathNeeded( botOwner ) ) ) or botTable.RepathTimer <= CurTime() then
		
			TRizzleBotPathfinderCheap( self, botOwner:GetPos() )
			--bot:TBotCreateNavTimer()
			botTable.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
			botTable.ChaseTimer = CurTime() + 0.5
		
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
	local botTable = self:GetTable()
	if self:IsHiding() then
	
		self:TBotSetState( HIDE )
		return
		
	end
	
	-- Our owner has told us to use something, its a higher priority than following our group leader.
	-- We will go back to following when we finish.
	local useEnt = botTable.UseEnt
	if IsValid( useEnt ) then
	
		self:TBotSetState( USE_ENTITY )
		return
	
	end
	
	-- Reviving a player is more important than following our group leader.
	local botReviveTarget = botTable.ReviveTarget
	if IsValid( botReviveTarget ) and self:GetKnownCount( nil, false, botTable.DangerDist ) <= 5 then
	
		self:TBotSetState( REVIVE_PLAYER )
		return
		
	end
	
	-- Our owner has told us to wait at a set postion, its a higher priority than following them.
	local botHoldPos = botTable.HoldPos
	if isvector( botHoldPos ) then
	
		self:TBotSetState( HOLD_POSITION )
		return
		
	end
	
	-- Our owner is alive and valid, we should follow them instead.
	local botOwner = botTable.TBotOwner
	if IsValid( botOwner ) and botOwner:Alive() then
	
		botTable.GroupLeader = nil
		self:TBotSetState( FOLLOW_OWNER )
		return
		
	end
	
	local botLeader = botTable.GroupLeader
	if !IsValid( botLeader ) or !botLeader:Alive() then
	
		self:TBotSetState( IDLE )
		return
		
	end
	
	local leaderDist = botLeader:GetPos():DistToSqr( self:GetPos() )
	if leaderDist > self.FollowDist^2 then
		
		if ( botTable.ChaseTimer <= CurTime() and ( !self:IsPathValid() or self:IsRepathNeeded( botLeader ) ) ) or botTable.RepathTimer <= CurTime() then
		
			TRizzleBotPathfinderCheap( self, botLeader:GetPos() )
			--bot:TBotCreateNavTimer()
			botTable.RepathTimer = CurTime() + math.Rand( 3.0, 5.0 )
			botTable.ChaseTimer = CurTime() + 0.5
		
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
--[[hook.Add( "PlayerSay", "TRizzleBotPlayerSay", function( sender, text, teamChat ) 
	if !IsValid( sender ) then return end

	--local textTable = string.Explode( " ", text )
	--if !textTable[ 1 ] or !textTable[ 2 ] then return end
	for k, bot in player.Iterator() do
	
		if IsValid( bot ) and bot:IsTRizzleBot() and ( !teamChat or bot:Team() == sender:Team() ) then 
		
			local botTable = bot:GetTable()
			local startpos, endpos, botName = string.find( text, bot:Nick() )
			local textTable
			local command
			
			if isnumber( startpos ) and startpos == 1 then -- Only run the command if the bot name was said first!
			
				textTable = string.Explode( " ", string.sub( text, endpos + 1 ) ) -- Grab everything else after the name!
				table.remove( textTable, 1 ) -- Remove the unnecessary whitespace
				command = textTable[ 1 ]:lower()
			
			else
			
				startpos, endpos, botName = string.find( text:lower(), "bots" )
				if isnumber( startpos ) and startpos == 1 then -- Check to see if the player is commanding every bot!
				
					textTable = string.Explode( " ", string.sub( text, endpos + 1 ) ) -- Grab everything else after the name!
					table.remove( textTable, 1 ) -- Remove the unnecessary whitespace
					command = textTable[ 1 ]:lower()
					
				end
			
			end
			
			if sender == botTable.TBotOwner and isstring( command ) then
		
				if command == "follow" then
				
					botTable.UseEnt = nil
					botTable.UseHoldTime = 0.0
					botTable.StartedUse = false
					botTable.HoldPos = nil
					
				elseif command == "hold" then
				
					local pos = sender:GetEyeTrace().HitPos
					local ground = navmesh.GetGroundHeight( pos )
					if ground then
					
						pos.z = ground
						
					end
					
					botTable.HoldPos = pos
				
				elseif command == "wait" then
				
					local pos = bot:GetPos()
					local ground = navmesh.GetGroundHeight( pos )
					if ground then
					
						pos.z = ground
						
					end
				
					botTable.HoldPos = pos
				
				elseif command == "use" then
				
					local useEnt = sender:GetEyeTrace().Entity
				
					if IsValid( useEnt ) and !useEnt:IsWorld() then
					
						botTable.UseEnt = useEnt
						botTable.StartedUse = false
						botTable.UseHoldTime = tonumber( textTable[ 2 ] ) or 0.1
						
					end
				
				elseif command == "attack" then
				
					local enemy = sender:GetEyeTrace().Entity
					
					if IsValid( enemy ) and !enemy:IsWorld() then
					
						bot:AddKnownEntity( enemy )
						botTable.AttackList[ enemy ] = true
						
					end
				
				elseif command == "clear" and isstring( textTable[ 2 ] ) then
				
					if textTable[ 2 ]:lower() == "attack" then
					
						botTable.AttackList = {}
						
					end
				
				elseif command == "alert" then
				
					botTable.LastCombatTime = CurTime() - 5.0
				
				elseif command == "warp" then
				
					bot:SetPos( sender:GetEyeTrace().HitPos )
				
				end
				
			end
		
		end
	
	end

end)]]

-- Reset their AI on spawn.
hook.Add( "PlayerSpawn" , "TRizzleBotSpawnHook" , function( ply )
	
	if ply:IsTRizzleBot() then
		
		ply:TBotResetAI()
		
	end
	
end)

-- Makes the bot react to damage taken by enemies
--[[hook.Add( "PlayerHurt" , "TRizzleBotPlayerHurt" , function( victim, attacker )

	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() or !IsValid( attacker ) or !IsValid( victim ) or !victim:IsTRizzleBot() then return end
	
	if ( attacker:IsNPC() and attacker:IsAlive() ) or ( attacker:IsPlayer() and attacker:Alive() ) or ( attacker:IsNextBot() and attacker:Health() > 0 ) then
		
		if victim:IsEnemy( attacker ) then
		
			local known = victim:AddKnownEntity( attacker )
			
			if istbotknownentity( known ) then
			
				known:UpdatePosition()
				
			end
			
			if !victim:IsInCombat() then victim.LastCombatTime = CurTime() + 5.0 end
			
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
			
				if !bot:IsInCombat() then bot.LastCombatTime = CurTime() + 5.0 end
				
			end
			
		end
		
	end
	
end)]]

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
	
	local botTable = self:GetTable()
	if botTable.AttackList[ target ] then
	
		return true
	
	end
	
	if target:IsNPC() then
	
		if self:IsTRizzleBot() and IsValid( botTable.TBotOwner ) and target:Disposition( botTable.TBotOwner ) == D_HT then
		
			return true
			
		end
	
		return target:Disposition( self ) == D_HT
		
	end
	
	if target:IsNextBot() and TBotAttackNextBots:GetBool() then
	
		return true
		
	end
	
	if target:IsPlayer() and TBotAttackPlayers:GetBool() then
	
		local targetTable = target:GetTable()
		if IsValid( botTable.TBotOwner ) or IsValid( targetTable.TBotOwner ) then 
		
			if botTable.TBotOwner != target and targetTable.TBotOwner != self and botTable.TBotOwner != targetTable.TBotOwner then
		
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
	local forward = nil
	if threat:IsPlayer() or threat:IsNPC() then 
	
		forward = threat:GetAimVector() 
		
	else
	
		forward = threat:EyeAngles():Forward()
		
	end
	
	if to:Dot( forward ) > cosTolerance then
	
		return true
		
	end
	
	return false
	
end

function BOT:IsThreatFiringAtMe( threat )

	if self:IsThreatAimingTowardMe( threat ) then
	
		if threat:IsNPC() and threat:GetEnemy() == self and IsValid( threat:GetActiveWeapon() ) then
		
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

	local botTable = self:GetTable()
	if #botTable.EnemyList == 0 then
	
		return nil
		
	end
	
	local threat = nil
	local i = 1
	
	while i <= #botTable.EnemyList do
	
		local firstThreat = botTable.EnemyList[ i ]
		
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
	while i <= #botTable.EnemyList do
	
		local newThreat = botTable.EnemyList[ i ]
		
		if self:IsAwareOf( newThreat ) and !newThreat:IsObsolete() and !self:IsIgnored( newThreat:GetEntity() ) and self:IsEnemy( newThreat:GetEntity() ) then
		
			if !onlyVisibleThreats or newThreat:IsVisibleRecently() then
			
				threat = self:GetTBotBehavior():SelectMoreDangerousThreat( self, threat, newThreat )
				
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
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and GetTBotRegisteredWeapon( botWeapon:GetClass() ).WeaponType == "Melee" then
	
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
	local botTable = self:GetTable()
	for k, known2 in ipairs( botTable.EnemyList ) do
	
		if istbotknownentity( known2 ) and known == known2 then
		
			return known2
			
		end
		
	end
	
	table.insert( botTable.EnemyList, known )
	return known
	
end

function BOT:ForgetEntity( forgetMe )

	if !IsValid( forgetMe ) then
	
		return
		
	end
	
	local botTable = self:GetTable()
	for k, known in ipairs( botTable.EnemyList ) do
	
		if IsValid( known:GetEntity() ) and known:GetEntity() == forgetMe then
		
			table.remove( botTable.EnemyList, k )
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
	
	-- This entity was set not to render so we can't see it!
	if subject:GetNoDraw() then
	
		return true
		
	end
	
	return false
	
end

function BOT:IsVisibleEntityNoticed( subject )

	if IsValid( subject ) and self:IsEnemy( subject ) then
	
		return true
		
	end

	return true

end

-- This is used by the vision interface to check if the bot should consider the entered entity!
function BOT:IsValidVisionTarget( pit )

	if self.AttackList[ pit ] then 
	
		return true
		
	end
	
	if pit:IsNPC() and pit:IsAlive() then 
	
		return true
		
	end
	
	if pit:IsPlayer() and pit:Alive() then 
	
		return true
	
	end
	
	if pit:IsNextBot() and pit:Health() > 0 then
	
		return true
		
	end

	return false

end

function BOT:UpdateKnownEntities()

	local visibleNow = {}
	local visibleNow2 = {}
	local knownEntities = {}
	local botTable = self:GetTable()
	for k, pit in ents.Iterator() do
	
		if IsValid( pit ) and pit != self and self:IsValidVisionTarget( pit ) then 
		
			if !self:IsIgnored( pit ) and self:IsAbleToSee( pit, true ) then
				
				table.insert( visibleNow, pit )
				visibleNow2[ pit ] = true
				
			end
			
		end
		
	end
	
	local i = 1
	while i <= #botTable.EnemyList do
	
		local known = botTable.EnemyList[ i ]
	
		if !IsValid( known:GetEntity() ) or known:IsObsolete() then
		
			table.remove( botTable.EnemyList, i )
			continue
			
		end
		
		-- NOTE: I create a list of every entity already on the enemy list so we don't have loop again if we need to add something not on the list!
		knownEntities[ known:GetEntity() ] = true
		
		-- NOTE: Valve reiterates through the table to check IsAbleToSee.....
		-- I choose to create both a table and a list so I don't have to do that. :)
		if tobool( visibleNow2[ known:GetEntity() ] ) then
		
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			
			-- Has our reaction time just elapsed?
			if CurTime() - known:GetTimeWhenBecameVisible() >= self:GetMinRecognizeTime() and botTable.LastVisionUpdateTimestamp - known:GetTimeWhenBecameVisible() < self:GetMinRecognizeTime() then
			
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
	
		--[[local j = 1
		while j <= #botTable.EnemyList do
		
			if visibleNow[ i ] == botTable.EnemyList[ j ]:GetEntity() then
			
				break
				
			end
			
			j = j + 1
			
		end
		
		if j > #botTable.EnemyList then
		
			local known = TBotKnownEntity( visibleNow[ i ] )
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			table.insert( botTable.EnemyList, known )
			
		end]]
		
		-- NOTE: This is WAY faster than the code above since we don't have to iterate throught the entire known enemy list more than once!
		if !tobool( knownEntities[ visibleNow[ i ] ] ) then
		
			local known = TBotKnownEntity( visibleNow[ i ] )
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			table.insert( botTable.EnemyList, known )
			
		end
		
		i = i + 1
		
	end
	
end

-- Heal any player or bot that is visible to us.
function BOT:TBotFindHealTarget()
	if ( ( engine.TickCount() + self:EntIndex() ) % 5 ) != 0 then return self.HealTarget end -- This shouldn't run as often
	
	local targetdistsqr			=	6400 -- This will allow the bot to select the closest teammate to it.
	local target				=	nil -- This is the closest teammate to the bot.
	local botTable				=	self:GetTable()
	
	--The bot should heal its owner and itself before it heals anyone else
	local tbotOwner = botTable.TBotOwner
	if IsValid( tbotOwner ) and tbotOwner:Alive() and tbotOwner:Health() < botTable.HealThreshold and tbotOwner:GetPos():DistToSqr( self:GetPos() ) < 6400 then return tbotOwner
	elseif self:Health() < botTable.HealThreshold then return self end

	for i = 1, game.MaxPlayers() do
	
		local ply = Entity( i )
		
		if IsValid( ply ) and ply:Alive() and !self:IsEnemy( ply ) and ply:Health() < botTable.HealThreshold and self:IsAbleToSee( ply ) then -- The bot will heal any teammate that needs healing that we can actually see and are alive.
			
			local teammatedistsqr = ply:GetPos():DistToSqr( self:GetPos() )
			
			if teammatedistsqr < targetdistsqr then 
				target = ply
				targetdistsqr = teammatedistsqr
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
	local botTable				=	self:GetTable()
	
	--The bot should revive its owner before it revives anyone else
	local tbotOwner = botTable.TBotOwner
	if IsValid( tbotOwner ) and tbotOwner:Alive() and tbotOwner:IsDowned() then return tbotOwner end

	for i = 1, game.MaxPlayers() do
	
		local ply = Entity( i )
		
		if IsValid( ply ) and ply != self and ply:Alive() and !self:IsEnemy( ply ) and ply:IsDowned() then -- The bot will revive any teammate than need to be revived.
			
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
	
	for k, v in ents.Iterator() do
		
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
	local botTable = self:GetTable()
	for k, door in ipairs( ents.FindAlongRay( self:GetPos(), botTable.Goal.Pos, Vector( -halfWidth, -halfWidth, -halfWidth ), Vector( halfWidth, halfWidth, self:GetStandHullHeight() / 2.0 ) ) ) do
	
		if IsValid( door ) and door:IsDoor() and !door:IsDoorLocked() and !door:IsDoorOpen() and door:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) <= 10000 then
		
			botTable.Door = door
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
	local botTable = self:GetTable()
	for k, breakable in ipairs( ents.FindAlongRay( self:GetPos(), botTable.Goal.Pos, Vector( -halfWidth, -halfWidth, -halfWidth ), Vector( halfWidth, halfWidth, self:GetStandHullHeight() / 2.0 ) ) ) do
	
		if IsValid( breakable ) and breakable:IsBreakable() and breakable:NearestPoint( self:GetPos() ):DistToSqr( self:GetPos() ) <= 6400 and self:IsAbleToSee( breakable ) then 
		
			botTable.Breakable = breakable
			break
			
		end
	
	end
	
end

function TRizzleBotRangeCheck( area, fromArea, ladder, portal, bot, length )
	
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
		
		-- If the portal is disabled then we can't use it!
		if IsValid( portal ) and portal:GetInternalVariable( "m_bDisabled" ) then
		
			return -1.0
			
		end
		
		local Height	=	fromArea:ComputeAdjacentConnectionHeightChange( area )
		local stepHeight = 18
		if IsValid( bot ) then stepHeight = bot:GetStepSize() end
		
		-- Jumping is slower than ground movement.
		if !IsValid( ladder ) and !IsValid( portal ) and !fromArea:IsUnderwater() and Height > stepHeight then
			
			local maximumJumpHeight = 64
			if IsValid( bot ) then maximumJumpHeight = bot:GetMaxJumpHeight() end
			
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
			
			if IsValid( portal ) and portal:GetPos().z < fromArea:GetCenter().z and portal:GetPos().z > area:GetCenter().z then
			
				fallDistance = portal:GetPos().z - area:GetCenter().z
				
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
			
			local crouchPenalty = 5
			if IsValid( bot ) then crouchPenalty = math.floor( 1 / bot:GetCrouchedWalkSpeed() ) end
			
			dist	=	dist + ( dist * crouchPenalty )
			
		end
		
		-- If this area might damage us if we walk through it we should avoid it at all costs.
		if area:IsDamaging() then
		
			dist	=	dist + ( dist * 100.0 )
			
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

function TRizzleBotRangeCheckRetreat( area, fromArea, ladder, portal, bot, length, threat )
	
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
		
		-- If the portal is disabled then we can't use it!
		if IsValid( portal ) and portal:GetInternalVariable( "m_bDisabled" ) then
		
			return -1.0
			
		end
		
		local Height	=	fromArea:ComputeAdjacentConnectionHeightChange( area )
		local stepHeight = 18
		if IsValid( bot ) then stepHeight = bot:GetStepSize() end
		
		-- Jumping is slower than ground movement.
		if !IsValid( ladder ) and !IsValid( portal ) and !fromArea:IsUnderwater() and Height > stepHeight then
			
			local maximumJumpHeight = 64
			if IsValid( bot ) then maximumJumpHeight = bot:GetMaxJumpHeight() end
			
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
			
			if IsValid( portal ) and portal:GetPos().z < fromArea:GetCenter().z and portal:GetPos().z > area:GetCenter().z then
			
				fallDistance = portal:GetPos().z - area:GetCenter().z
				
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
			
			local crouchPenalty = 5
			if IsValid( bot ) then crouchPenalty = math.floor( 1 / bot:GetCrouchedWalkSpeed() ) end
			
			dist	=	dist + ( dist * crouchPenalty )
			
		end
		
		-- If this area might damage us if we walk through it we should avoid it at all costs.
		if area:IsDamaging() then
		
			dist	=	dist + ( dist * 100.0 )
			
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
function TRizzleBotPathfinderCheap( bot, goal, costFunc )
	
	bot:TBotClearPath()
	local NUM_TRAVERSE_TYPES = 9
	local start = bot:GetPos()
	local startArea = bot:GetLastKnownArea()
	local botTable = bot:GetTable()
	if !IsValid( startArea ) then
	
		botTable.Goal = bot:FirstSegment()
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
	
	local pathResult, closestArea = NavAreaBuildPath( startArea, goalArea, Vector( goal ), bot, costFunc )
	
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
	botTable.SegmentCount = count
	area = closestArea
	while IsValid( area ) and count > 0 do
	
		botTable.Path[ count ] = {}
		botTable.Path[ count ].Area = area
		botTable.Path[ count ].How = area:GetParentHow()
		botTable.Path[ count ].Type = PATH_ON_GROUND
		
		area = area:GetParent()
		count = count - 1
		
	end
	
	-- append actual goal position
	botTable.SegmentCount = botTable.SegmentCount + 1
	botTable.Path[ botTable.SegmentCount ] = {}
	botTable.Path[ botTable.SegmentCount ].Area = closestArea
	botTable.Path[ botTable.SegmentCount ].Pos = pathEndPosition
	botTable.Path[ botTable.SegmentCount ].How = NUM_TRAVERSE_TYPES
	botTable.Path[ botTable.SegmentCount ].Type = PATH_ON_GROUND
	
	--[[for k,v in ipairs( botTable.Path ) do
	
		if v.Area == startArea then
		
			print( "StartArea at " .. tostring( k ) )
		
		elseif v.Area == closestArea then
		
			print( "EndArea at " .. tostring( k ) )
			
		end
		
	end
	
	print( "SegmentCount: " .. tostring( botTable.SegmentCount ) )
	print( "Bot Path Length: " .. tostring( #botTable.Path ) )]]
	
	-- compute path positions
	if bot:ComputeNavmeshVisibility() == false then
	
		bot:TBotClearPath()
		botTable.Goal = bot:FirstSegment()
		return false
		
	end
	
	PostProccess( bot )
	
	botTable.Goal = bot:FirstSegment()
	
	return pathResult
	
end

-- This creates a path to chase the selected subject!
function TRizzleBotPathfinderChase( bot, subject, costFunc )
	if !IsValid( bot ) or !IsValid( subject ) then return false end
	
	local pathTarget = TRizzleBotPredictSubjectPosition( bot, subject )
	return TRizzleBotPathfinderCheap( bot, pathTarget, costFunc )

end

-- This creates a path to flee from the selected threat!
function TRizzleBotPathfinderRetreat( bot, threat, costFunc )
	if !IsValid( bot ) or !IsValid( threat ) then return false end

	costFunc = costFunc or TRizzleBotRangeCheckRetreat

	bot:TBotClearPath()
	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	
	local LADDER_UP = 0
	local LADDER_DOWN = 1

	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	local GO_THROUGH_PORTAL = 6

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
	
	local initCost = costFunc( startArea, nil, nil, nil, bot, nil, threat )
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
		
		for k, portalList in ipairs( area:GetPortals() ) do
		
			local index = #adjacentAreas 
			if index >= 64 then

				break
				
			end
			
			if IsValid( portalList.destination_cnavarea ) and IsValid( portalList.portal ) then
			
				table.insert( adjacentAreas, { area = portalList.destination_cnavarea, how = GO_THROUGH_PORTAL, portal = portalList.portal } )
			
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
			local newCost = costFunc( newArea, area, adjacentAreas[ i ].ladder, adjacentAreas[ i ].portal, bot, nil, threat )
			
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
	local botTable = bot:GetTable()
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
	botTable.SegmentCount = count
	area = endArea
	while IsValid( area ) and count > 0 do
	
		botTable.Path[ count ] = {}
		botTable.Path[ count ].Area = area
		botTable.Path[ count ].How = area:GetParentHow()
		botTable.Path[ count ].Type = PATH_ON_GROUND
		
		area = area:GetParent()
		count = count - 1
		
	end
	
	-- append actual goal position
	botTable.SegmentCount = botTable.SegmentCount + 1
	botTable.Path[ botTable.SegmentCount ] = {}
	botTable.Path[ botTable.SegmentCount ].Area = endArea
	botTable.Path[ botTable.SegmentCount ].Pos = goal
	botTable.Path[ botTable.SegmentCount ].How = NUM_TRAVERSE_TYPES
	botTable.Path[ botTable.SegmentCount ].Type = PATH_ON_GROUND
	
	--[[for k,v in ipairs( botTable.Path ) do
	
		if v.Area == startArea then
		
			print( "StartArea at " .. tostring( k ) )
		
		elseif v.Area == closestArea then
		
			print( "EndArea at " .. tostring( k ) )
			
		end
		
	end
	
	print( "SegmentCount: " .. tostring( botTable.SegmentCount ) )
	print( "Bot Path Length: " .. tostring( #botTable.Path ) )]]
	
	-- compute path positions
	if bot:ComputeNavmeshVisibility() == false then
	
		bot:TBotClearPath()
		botTable.Goal = bot:FirstSegment()
		return false
		
	end
	
	PostProccess( bot )
	
	botTable.Goal = bot:FirstSegment()
	
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
	local lead = leadTime * subject:GetVelocity()
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
	costFunc = costFunc or TRizzleBotRangeCheck
	
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
	
	local initCost = costFunc( startArea, nil, nil, nil, bot )
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
		local GO_THROUGH_PORTAL = 6
		
		local searchIndex = 1
		local dir = NORTH
		local ladderUp = true
		
		local floorList = Current:GetAdjacentAreaDistances( NORTH )
		local ladderList = nil
		local portalList = nil
		local ladderTopDir = 0
		local length = -1.0
		
		--while ( true ) do
		while searchWhere >= 0 and searchWhere <= 2 do
		
			local newArea = nil
			local how = nil
			local ladder = nil
			local portal = nil
		
			if searchWhere == 0 then
			
				if searchIndex > #floorList then
				
					dir = dir + 1
					
					if dir == NUM_DIRECTIONS then
					
						searchWhere = 1
						ladderList = Current:GetLaddersAtSide( LADDER_UP )
						searchIndex = 1
						ladderTopDir = AHEAD
						
					else
					
						floorList = Current:GetAdjacentAreaDistances( dir )
						searchIndex = 1
						
					end
					
					continue
					
				end
				
				local floorConnect = floorList[ searchIndex ]
				newArea = floorConnect.area
				length = floorConnect.dist
				how = dir
				searchIndex = searchIndex + 1
				
			elseif searchWhere == 1 then
			
				if searchIndex > #ladderList then
					
					if !ladderUp then
						
						searchWhere = 2
						portalList = Current:GetPortals()
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
				
				length = -1.0
			
			elseif searchWhere == 2 then
			
				if searchIndex > #portalList then
				
					searchWhere = 3
					searchIndex = 1
					portal = nil
					
					continue
					
				end
				
				local portalConnect = portalList[ searchIndex ]
				newArea = portalConnect.destination_cnavarea
				length = portalConnect.distance
				portal = portalConnect.portal
				how = GO_THROUGH_PORTAL
				searchIndex = searchIndex + 1
				
				if !IsValid( newArea ) or !IsValid( portal ) then
				
					continue
					
				end
			
			end
			--else
			
				--length = -1.0
				--break
			
			--end
		
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
			
			local NewCostSoFar		=	costFunc( newArea, Current, ladder, portal, bot, length )
			
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
function NavAreaTravelDistance( startArea, endArea, bot, costFunc )

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
	if NavAreaBuildPath( startArea, endArea, nil, bot, costFunc ) == false then
	
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

local CNavAreaPortalCache = {}
function Zone:GetPortals()
	if CNavAreaPortalCache[ self ] then
	
		return CNavAreaPortalCache[ self ]
		
	end
	
	local portals = TRizzleBotGetPortals()
	local tbl = {}
	for k, v in ipairs( portals ) do
	
		if v.portal_cnavarea == self then
		
			table.insert( tbl, v )
			
		end
		
	end
	
	CNavAreaPortalCache[ self ] = tbl
	return CNavAreaPortalCache[ self ]
	
end

-- Returns every portal on the map, "trigger_teleport" and their linked destination!
function TRizzleBotGetPortals()
	local possiblePortals = ents.FindByClass( "trigger_teleport" )
	local portals = {}
	-- Table Structure:
	--[[
		portal = <Entity:trigger_teleport>
		portal_no = <Number>,
        portal_pos = <Vector>,
        portal_cnavarea = <CNavArea>,
        destination = <Entity:info_teleport_destination>,
        destination_pos = <Vector>,
        destination_cnavarea = <CNavArea>,
		distance = <Number>,
	]]
	for portal_no, portal in ipairs( possiblePortals ) do
		
		local portal_pos = portal:GetPos()
		local portal_cnavarea = navmesh.GetNearestNavArea( portal_pos )
		
		local dest_name = portal:GetInternalVariable( "target" )
		
		if !dest_name then
		
			continue
			
		end
		
		local destination = ents.FindByName( dest_name )[ 1 ]
		if !IsValid( destination ) then
		
			continue
			
		end
		
		local destination_pos = destination:GetPos()
		local destination_cnavarea = navmesh.GetNearestNavArea( destination_pos )
		
		local tbl = {}
		tbl.portal = portal
		tbl.portal_no = portal_no
		tbl.portal_cnavarea = portal_cnavarea
		tbl.destination = destination
		tbl.destination_pos = destination_pos
		tbl.destination_cnavarea = destination_cnavarea
		if IsValid( portal_cnavarea ) and IsValid( destination_cnavarea ) then
		
			tbl.distance = portal_cnavarea:GetCenter():Distance( destination_cnavarea:GetCenter() )
			
		end
		table.insert( portals, tbl )
		
	end
	
	return portals
	
end

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
	
	local botTable = self:GetTable()
	local i = table.KeyFromValue( botTable.Path, currentSegment )
	if i < 0 or i > botTable.SegmentCount then
	
		return nil
		
	end
	
	return botTable.Path[ i + 1 ]
	
end

function BOT:PriorSegment( currentSegment )

	if !currentSegment or !self:IsPathValid() then
	
		return nil
		
	end
	
	local botTable = self:GetTable()
	local i = table.KeyFromValue( botTable.Path, currentSegment )
	if i <= 1 or i > botTable.SegmentCount then
	
		return nil
		
	end
	
	return botTable.Path[ i - 1 ]
	
end

-- Checks if the bot should repath to follow its enterted pos or enemy!
function BOT:IsRepathNeeded( subject )
	if !IsValid( subject ) and !isvector( subject ) then return false end
	
	-- The closer we get, the more accurate out path needs to be.
	local subjectPos = isvector( subject ) and subject or subject:GetPos()
	local to = subjectPos - self:GetPos()
	local tolerance = 0.33 * to:Length()
	
	return ( subjectPos - self:LastSegment().Pos ):IsLengthGreaterThan( tolerance )
	
end

function BOT:IsPathValid()

	return self.SegmentCount > 0
	
end

function BOT:TBotClearPath()

	local botTable = self:GetTable()
	botTable.Path = {}
	botTable.AvoidTimer = 0
	botTable.SegmentCount = 0
	botTable.Goal = nil
	botTable.PathAge = 0
	
end

function BOT:GetPathAge()

	local botTable = self:GetTable()
	if isnumber( botTable.PathAge ) then
	
		return CurTime() - botTable.PathAge 
	
	end

	return 99999.9
	
end

local result = Vector()
-- Checks if the bot will cross enemy line of fire when attempting to move to the entered position
function BOT:IsCrossingLineOfFire( startPos, endPos )

	for k, known in ipairs( self.EnemyList ) do
	
		if !self:IsAwareOf( known ) or known:IsObsolete() or !self:IsEnemy( known:GetEntity() )then
		
			continue
			
		end
		
		local enemy = known:GetEntity()
		local viewForward = nil
		if enemy:IsPlayer() or enemy:IsNPC() then
		
			viewForward = enemy:GetAimVector()
		
		else
		
			viewForward = enemy:EyeAngles():Forward() 
		
		end
		
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
	
	local vision = self:GetTBotVision()
	for k, known in ipairs( vision.m_knownEntityVector ) do
	
		if !vision:IsAwareOf( known ) or known:IsObsolete() or !self:IsEnemy( known:GetEntity() )then
		
			continue
			
		end
		
		local enemy = known:GetEntity()
		local viewForward = nil
		if enemy:IsPlayer() or enemy:IsNPC() then
		
			viewForward = enemy:GetAimVector()
		
		else
		
			viewForward = enemy:EyeAngles():Forward() 
		
		end
		
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
	util.TraceHull( { start = pos, endpos = pos, maxs = Vector( size, size, self:GetCrouchHullHeight() ), mins = Vector( -size, -size, 0.0 ), mask = MASK_PLAYERSOLID, filter = TBotTraceFilter, output = trace  } )
	-- Don't consider spots if there is a prop in the way.
	if trace.Fraction < 1.0 or trace.StartSolid then
	
		return true
		
	end

	return false

end

-- Checks if a hiding spot is safe to use
function BOT:IsSpotSafe( hidingSpot )

	-- FIXME: Change this once the old addons are updated!!!
	for k, known in ipairs( self.EnemyList ) do
	
		if self:IsAwareOf( known ) and !known:IsObsolete() and self:IsEnemy( known:GetEntity() ) and known:GetEntity():TBotVisible( hidingSpot ) then return false end -- If one of the bot's enemies its aware of can see it the bot won't use it.
	
	end
	
	local vision = self:GetTBotVision()
	for k, known in ipairs( vision.m_knownEntityVector ) do
	
		if vision:IsAwareOf( known ) and !known:IsObsolete() and self:IsEnemy( known:GetEntity() ) and known:GetEntity():VisibleVec( hidingSpot ) then return false end -- If one of the bot's enemies its aware of can see it the bot won't use it.
	
	end

	return true

end

-- Clears the selected bot's hiding spot
function BOT:ClearHidingSpot()

	local botTable = self:GetTable()
	botTable.HidingSpot = nil
	botTable.HidingState = FINISHED_HIDING
	botTable.HideReason	= NONE
	
	if isvector( botTable.ReturnPos ) then
		
		-- We only set the goal once just incase something else that is important, "following their owner," wants to move the bot
		TRizzleBotPathfinderCheap( self, botTable.ReturnPos )
		--self:TBotCreateNavTimer()
		botTable.ReturnPos = nil
		
	end

end

-- Returns a table of hiding spots.
function BOT:FindSpots( tbl )

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
			local pathLength = tbl.pos:DistToSqr( vec )
			--print("Path Length: " .. pathLength )
			
			-- If the hiding spot is further than tbl.range, the bot shouldn't consider it
			if tbl.radius^2 < pathLength then 
			
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
	
	if ( !found or #found == 0 ) and ( !found2 or #found2 == 0 ) and !tbl.secondAttempt then
	
		-- If we didn't find any hiding spots then look for sniper spots instead
		if tbl.spotType == "hiding" then
		
			tbl.spotType = "sniper"
			tbl.secondAttempt = true
			
			return self:FindSpots( tbl )
			
		-- If we didn't find any sniper spots then look for hiding spots instead
		elseif tbl.spotType == "sniper" then
		
			tbl.spotType = "hiding"
			tbl.secondAttempt = true
			
			return self:FindSpots( tbl )
			
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
	local GO_THROUGH_PORTAL = 6
	local NUM_TRAVERSE_TYPES = 9
	local botTable = self:GetTable()
	
	dir:Zero()
	
	if botTable.Path[ 1 ].Area:Contains( self:GetPos() ) then
	
		botTable.Path[ 1 ].Pos = self:GetPos()
		
	else
	
		botTable.Path[ 1 ].Pos = botTable.Path[ 1 ].Area:GetCenter()
		
	end
	
	botTable.Path[ 1 ].How = NUM_TRAVERSE_TYPES
	botTable.Path[ 1 ].Type = PATH_ON_GROUND
	
	local hullWidth = self:GetHullWidth() + 5.0 -- Inflate hull width slightly as a safety margin!
	local stepHeight = self:GetStepSize()
	
	local index = 2
	while index <= #botTable.Path do
		
		local from = botTable.Path[ index - 1 ]
		local to = botTable.Path[ index ]
		
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
				local maxPushDist = 2.0 * hullWidth
				local halfWidth = hullWidth / 2.0
				local hullHeight = self:GetCrouchHullHeight()
				
				local pushDist = 0
				while pushDist <= maxPushDist do
				
					local pos = to.Pos + Vector( pushDist * dir.x, pushDist * dir.y, 0 )
					local lowerPos = Vector( pos.x, pos.y, toPos.z )
					local ground = {}
					util.TraceHull( { start = pos, endpos = lowerPos, mins = Vector( -halfWidth, -halfWidth, stepHeight ), maxs = Vector( halfWidth, halfWidth, hullHeight ), mask = MASK_PLAYERSOLID, filter = TBotTraversableFilter, output = ground } )
					
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
						
						table.insert( botTable.Path, index + 1, { Pos = endDrop, Area = to.Area, How = to.How, Type = PATH_ON_GROUND } )
						botTable.SegmentCount = botTable.SegmentCount + 1
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
		
		elseif to.How == GO_THROUGH_PORTAL then
		
			local list = from.Area:GetPortals()
			--print( "Portals: " .. #list )
			local i = 1
			while i <= #list do
				local portalList = list[ i ]
				--print( "Destination Area: " .. tostring( portalList.destination_cnavarea ) )
				if IsValid( portalList.destination_cnavarea ) and IsValid( portalList.portal ) and portalList.destination_cnavarea == to.Area then
				
					to.Pos = portalList.portal:GetPos()
					to.Type = PATH_USE_PORTAL
					to.Portal = portalList.portal
					to.Destination = portalList.destination
					break
					
				end
				i = i + 1
			end
			
			-- for some reason we couldn't find the portal
			if i > #list then
			
				return false
				
			end
			
		end
		
		index = index + 1
		continue
		
	end
	
	local index = 1
	while botTable.Path[ index + 1 ] do
		
		local from = botTable.Path[ index ]
		local to = botTable.Path[ index + 1 ]
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
			table.insert( botTable.Path, index + 1, { Pos = launchPos - forward * halfWidth, Type = PATH_JUMP_OVER_GAP } )
			botTable.SegmentCount = botTable.SegmentCount + 1
			index = index + 1
			--print( "GapJump" )
			
		
		elseif self:ShouldJump( closeFrom, closeTo ) then
		
			to.Pos = NextNode:GetCenter()
			
			local launchPos = CurrentNode:GetClosestPointOnArea( to.Pos )
			table.insert( botTable.Path, index + 1, { Pos = launchPos, Type = PATH_CLIMB_UP } )
			botTable.SegmentCount = botTable.SegmentCount + 1
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
	local botTable = bot:GetTable()
	
	botTable.SegmentCount = 0
	
	local startArea = navmesh.GetNearestNavArea( start )
	if !IsValid( startArea ) then
	
		return false
		
	end
	
	local goalArea = navmesh.GetNearestNavArea( goal )
	if !IsValid( goalArea ) then
	
		return false
		
	end
	
	botTable.SegmentCount = 2
	
	botTable.Path[ 1 ] = {}
	botTable.Path[ 1 ].Area = startArea
	botTable.Path[ 1 ].Pos = Vector( start.x, start.y, startArea:GetZ( start ) )
	botTable.Path[ 1 ].How = NUM_TRAVERSE_TYPES
	botTable.Path[ 1 ].Type = PATH_ON_GROUND
	
	botTable.Path[ 2 ] = {}
	botTable.Path[ 2 ].Area = goalArea
	botTable.Path[ 2 ].Pos = Vector( goal.x, goal.y, goalArea:GetZ( goal ) )
	botTable.Path[ 2 ].How = NUM_TRAVERSE_TYPES
	botTable.Path[ 2 ].Type = PATH_ON_GROUND
	
	botTable.Path[ 1 ].Forward = botTable.Path[ 2 ].Pos - botTable.Path[ 1 ].Pos
	botTable.Path[ 1 ].Length = botTable.Path[ 1 ].Forward:Length()
	botTable.Path[ 1 ].Forward:Normalize()
	botTable.Path[ 1 ].DistanceFromStart = 0.0
	
	botTable.Path[ 2 ].Forward = botTable.Path[ 1 ].Forward
	botTable.Path[ 2 ].Length = 0.0
	botTable.Path[ 2 ].DistanceFromStart = botTable.Path[ 1 ].Length
	
	botTable.Goal = bot:FirstSegment()
	
	return true
	
end

-- This is the post proccess of the path
function PostProccess( bot )
	
	local botTable = bot:GetTable()
	botTable.PathAge = CurTime()
	
	if botTable.SegmentCount == 0 then 
	
		return 
		
	end
	
	if botTable.SegmentCount == 1 then
	
		botTable.Path[ 1 ].Forward = Vector()
		botTable.Path[ 1 ].Length = 0.0
		botTable.Path[ 1 ].DistanceFromStart = 0.0
		return
		
	end

	local distanceSoFar = 0.0
	local index = 1
	while botTable.Path[ index + 1 ] do
	
		local from = botTable.Path[ index ]
		local to = botTable.Path[ index + 1 ]
		
		from.Forward = to.Pos - from.Pos
		from.Length = from.Forward:Length()
		from.Forward:Normalize()
		
		from.DistanceFromStart = distanceSoFar
		
		distanceSoFar = distanceSoFar + from.Length
		
		index = index + 1
		
	end
	
	botTable.Path[ index ].Forward = botTable.Path[ index - 1 ].Forward
	botTable.Path[ index ].Length = 0.0
	botTable.Path[ index ].DistanceFromStart = distanceSoFar
	
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
	local botTable = self:GetTable()
	if TBotLookAheadRange:GetFloat() > 0 then
	
		pSkipToGoal = botTable.Goal
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
	
		local nextSegment = Either( istable( pSkipToGoal ), pSkipToGoal, self:NextSegment( botTable.Goal ) )
	
		if !nextSegment then
			
			if self:IsOnGround() then
			
				self:TBotClearPath()
				
			end
			
			return false
			
		else
		
			botTable.Goal = nextSegment
		
		end
		
	end
	
	return true
	
end

function BOT:IsAtGoal()

	local botTable		=	self:GetTable()
	local current		=	self:PriorSegment( botTable.Goal )
	local toGoal		=	botTable.Goal.Pos - self:GetPos()
	-- ALWAYS: Use 2D navigation, It helps by a large amount.
	
	if !current then
	
		-- passed goal
		return true
	
	elseif botTable.Goal.Type == PATH_DROP_DOWN then
		
		local landing = self:NextSegment( botTable.Goal )
		
		if !landing then
		
			-- passed goal or corrupt path
			return true
		
		-- did we reach the ground
		elseif self:GetPos().z - landing.Pos.z < self:GetStepSize() then
			
			-- reached goal
			return true
			
		end
		
	elseif botTable.Goal.Type == PATH_CLIMB_UP then
		
		local landing = self:NextSegment( botTable.Goal )
		
		if !landing then
		
			-- passed goal or corrupt path
			return true
		
		elseif self:GetPos().z > botTable.Goal.Pos.z + self:GetStepSize() then
		
			return true
			
		end
	
	elseif botTable.Goal.Type == PATH_USE_PORTAL then
	
		local destination = botTable.Goal.Destination
		
		if !IsValid( destination ) then
		
			-- passed goal or corrupt path
			return true
			
		elseif ( destination:GetPos() - self:GetPos() ):AsVector2D():IsLengthLessThan( TBotGoalTolerance:GetFloat() ) then
		
			return true
			
		end
	
	else
		
		local nextSegment = self:NextSegment( botTable.Goal )
		
		if nextSegment then
		
			-- because the bot may be off the path, check if it crossed the plane of the goal
			-- check against average of current and next forward vectors
			local dividingPlane = nil
			
			if current[ "Ladder" ] then
			
				dividingPlane = botTable.Goal[ "Forward" ]:AsVector2D()
				
			else
			
				dividingPlane = current[ "Forward" ]:AsVector2D() + botTable.Goal[ "Forward" ]:AsVector2D()
			
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

	local botTable = self:GetTable()
	botTable.IsStuck = false
	botTable.StuckPos = self:GetPos()
	botTable.StuckTimer = CurTime()
	
end

function BOT:StuckMonitor()

	-- a timer is needed to smooth over a few frames of inactivity due to state changes, etc.
	-- we only want to detect idle situations when the bot really doesn't "want" to move.
	local botTable = self:GetTable()
	if CurTime() - botTable.MoveRequestTimer > 0.25 then
	
		botTable.StuckPos = self:GetPos()
		botTable.StuckTimer = CurTime()
		return
		
	end
	
	-- We are not stuck if we are frozen!
	if self:IsFrozen() then
	
		self:ClearStuckStatus()
		return
		
	end
	
	if botTable.IsStuck then
	
		-- we are/were stuck - have we moved enough to consider ourselves "dislodged"
		if ( botTable.StuckPos - self:GetPos() ):IsLengthGreaterThan( 100 ) then
		
			self:ClearStuckStatus()
			
		else
		
			-- still stuck - periodically resend the event
			if botTable.StillStuckTimer <= CurTime() then
			
				botTable.StillStuckTimer = CurTime() + 1.0
				
				self:OnStuck()
				
			end
			
		end
		
		-- We have been stuck for too long, destroy the current path
		-- and the bot's current hiding spot.
		if CurTime() - botTable.StuckTimer > 10.0 then
		
			self:TBotClearPath()
			self:ClearHidingSpot()
			self:ClearStuckStatus()
			
		end
		
	else
	
		-- we're not stuck - yet
	
		if ( botTable.StuckPos - self:GetPos() ):IsLengthGreaterThan( 100 ) then
		
			-- we have moved - reset anchor
			botTable.StuckPos = self:GetPos()
			botTable.StuckTimer = CurTime()
			
		else
		
			-- within stuck range of anchor. if we've been here too long, we're stuck
			local minMoveSpeed = 0.1 * self:GetDesiredSpeed() + 0.1
			local escapeTime = 100 / minMoveSpeed
			if CurTime() - botTable.StuckTimer > escapeTime then
			
				-- we have taken too long - we're stuck
				botTable.IsStuck = true
				
				self:OnStuck()
				
			end
			
		end
	
	end
	
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

	local botTable = self:GetTable()
	if botTable.LadderState != NO_LADDER then
	
		return true
		
	end
	
	if !IsValid( botTable.Goal.Ladder ) then
	
		if self:Is_On_Ladder() then
		
			local current = self:PriorSegment( botTable.Goal )
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
					
						botTable.Goal = s
						break
						
					end
					
				end
				
				s = self:NextSegment( s )
				
			end
			
		end
	
		if !IsValid( botTable.Goal.Ladder ) then
		
			return false
		
		end
		
	end
	
	local mountRange = 25
	
	if botTable.Goal.Type == PATH_LADDER_UP then
	
		if botTable.LadderState == NO_LADDER and self:GetPos().z > botTable.Goal.Ladder:GetTop().z - self:GetStepSize() then
		
			botTable.Goal = self:NextSegment( botTable.Goal )
			return false
			
		end
		
		local to = ( botTable.Goal.Ladder:GetBottom() - self:GetPos() ):AsVector2D()
		
		self:AimAtPos( botTable.Goal.Ladder:GetTop() - 50 * botTable.Goal.Ladder:GetNormal() + Vector( 0, 0, self:GetCrouchHullHeight() ), 2.0, TBotLookAtPriority.MAXIMUM_PRIORITY )
		
		local range = to:Length()
		to:Normalize()
		if range < 50 then
		
			local ladderNormal2D = botTable.Goal.Ladder:GetNormal():AsVector2D()
			local dot = ladderNormal2D:Dot( to )
			
			-- This was -0.9, but it caused issues with slanted ladders.
			-- -0.6 seems to fix this, but I don't know if any errors may occur from this change!
			if dot < -0.6 then
			
				self:Approach( botTable.Goal.Ladder:GetBottom() )
			
				if range < mountRange then
				
					botTable.LadderState = APPROACHING_ASCENDING_LADDER
					botTable.LadderInfo = botTable.Goal.Ladder
					botTable.LadderDismountGoal = botTable.Goal.Area
					
				end
				
			else
			
				local myPerp = Vector( -to.y, to.x, 0 )
				local ladderPerp2D = Vector( -ladderNormal2D.y, ladderNormal2D.x )
				
				local goal = botTable.Goal.Ladder:GetBottom()
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
	
		if self:GetPos().z < botTable.Goal.Ladder:GetBottom().z + self:GetStepSize() then
		
			botTable.Goal = self:NextSegment( botTable.Goal )
			
		else
		
			local mountPoint = botTable.Goal.Ladder:GetTop() + 0.5 * self:GetHullWidth() * botTable.Goal.Ladder:GetNormal()
			local to = ( mountPoint - self:GetPos() ):AsVector2D()
			
			self:AimAtPos( botTable.Goal.Ladder:GetBottom() + 50 * botTable.Goal.Ladder:GetNormal() + Vector( 0, 0, self:GetCrouchHullHeight() ), 1.0, TBotLookAtPriority.MAXIMUM_PRIORITY )
			
			local range = to:Length()
			to:Normalize()
			
			if range < mountRange or self:Is_On_Ladder() then
			
				botTable.LadderState = APPROACHING_DESCENDING_LADDER
				botTable.LadderInfo = botTable.Goal.Ladder
				botTable.LadderDismountGoal = botTable.Goal.Area
			
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

	local botTable = self:GetTable()
	botTable.MoveRequestTimer = CurTime()
	
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
	
	if self:Is_On_Ladder() and botTable.LadderState != NO_LADDER and ( botTable.LadderState == ASCENDING_LADDER or botTable.LadderState == DESCENDING_LADDER ) then
		
		self:PressForward()
		
		if IsValid( botTable.LadderInfo ) then
			
			local posOnLadder = CalcClosestPointOnLine( self:GetPos(), botTable.LadderInfo:GetBottom(), botTable.LadderInfo:GetTop() )
			local alongLadder = botTable.LadderInfo:GetTop() - botTable.LadderInfo:GetBottom()
			alongLadder:Normalize()
			local rightLadder = alongLadder:Cross( botTable.LadderInfo:GetNormal() )
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
				
				local currentAngles = currentVehicle:GetAngles()
				local turnPos = pos - currentVehicle:GetPos()
				turnPos.z = 0.0
				turnPos:Normalize()
				
				forward = currentVehicle:GetAngles():Forward()
				forward.z = 0.0
				forward:Normalize()
				
				right.x = forward.y
				right.y = -forward.x
				right.z = 0
				
				ahead = turnPos:Dot( forward )
				side = turnPos:Dot( right )
				
				if ahead < 0.05 then
				
					self:PressForward()
				
				elseif ahead > -0.05 then
				
					self:PressBack()
					side = -side
				
				end
				
				if 0.05 <= side then
					
					self:PressLeft()
					
				elseif 0.05 >= side then
					
					self:PressRight()
					
				end
				
			end
			
		end
		
	end
	
end

function BOT:ApproachAscendingLadder()

	local botTable = self:GetTable()
	if !IsValid( botTable.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if self:GetPos().z >= botTable.LadderInfo:GetTop().z - self:GetStepSize() then
	
		botTable.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_TOP
		
	end
	
	if self:GetPos().z <= botTable.LadderInfo:GetBottom().z - self:GetMaxJumpHeight() then
	
		return NO_LADDER
		
	end
	
	self:FaceTowards( botTable.LadderInfo:GetBottom() )
	
	self:Approach( botTable.LadderInfo:GetBottom() )
	
	if self:Is_On_Ladder() then
	
		return ASCENDING_LADDER
		
	end
	
	return APPROACHING_ASCENDING_LADDER
	
end

function BOT:ApproachDescendingLadder()

	local botTable = self:GetTable()
	if !IsValid( botTable.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if self:GetPos().z <= botTable.LadderInfo:GetBottom().z + self:GetMaxJumpHeight() then
	
		botTable.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_BOTTOM
		
	end
	
	local mountPoint = botTable.LadderInfo:GetTop() + 0.25 * self:GetHullWidth() * botTable.LadderInfo:GetNormal()
	local to = mountPoint - self:GetPos()
	to.z = 0.0
	
	local mountRange = to:Length()
	to:Normalize()
	local moveGoal = nil
	
	if mountRange < 10.0 then
	
		moveGoal = self:GetPos() + 100 * self:GetMotionVector()
		
	else
	
		if to:Dot( botTable.LadderInfo:GetNormal() ) < 0.0 then
		
			moveGoal = botTable.LadderInfo:GetTop() - 100 * botTable.LadderInfo:GetNormal()
			
		else
		
			moveGoal = botTable.LadderInfo:GetTop() + 100 * botTable.LadderInfo:GetNormal()
			
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

	local botTable = self:GetTable()
	if !IsValid( botTable.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if !self:Is_On_Ladder() then
	
		botTable.LadderInfo = nil
		return NO_LADDER
		
	end
	
	if botTable.LadderDismountGoal:HasAttributes( NAV_MESH_CROUCH ) then
	
		self:PressCrouch()
		
	end
	
	if self:GetPos().z >= botTable.LadderInfo:GetTop().z then
	
		botTable.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_TOP
		
	end
	
	local goal = self:GetPos() + 100 * ( -botTable.LadderInfo:GetNormal() + Vector( 0, 0, 2 ) )
	
	self:AimAtPos( goal, 0.1, TBotLookAtPriority.MAXIMUM_PRIORITY )
	
	self:Approach( goal )
	
	return ASCENDING_LADDER
	
end

function BOT:DescendLadder()

	local botTable = self:GetTable()
	if !IsValid( botTable.LadderInfo ) then
	
		return NO_LADDER
		
	end
	
	if !self:Is_On_Ladder() then
	
		botTable.LadderInfo = nil
		return NO_LADDER
		
	end
	
	if self:GetPos().z <= botTable.LadderInfo:GetBottom().z + self:GetStepSize() then
	
		botTable.LadderTimer = CurTime() + 2.0
		return DISMOUNTING_LADDER_BOTTOM
		
	end
	
	local goal = self:GetPos() + 100 * ( botTable.LadderInfo:GetNormal() + Vector( 0, 0, -2 ) )
	
	self:AimAtPos( goal, 0.1, TBotLookAtPriority.MAXIMUM_PRIORITY )
	
	self:Approach( goal )
	
	return DESCENDING_LADDER
	
end

function BOT:DismountLadderTop()

	local botTable = self:GetTable()
	if !IsValid( botTable.LadderInfo ) or botTable.LadderTimer <= CurTime() then
	
		botTable.LadderInfo = nil
		return NO_LADDER
		
	end
	
	local toGoal = botTable.LadderDismountGoal:GetCenter() - self:GetPos()
	toGoal.z = 0.0
	local range = toGoal:Length()
	toGoal:Normalize()
	toGoal.z = 1.0
	
	self:AimAtPos( self:GetShootPos() + 100 * toGoal, 0.1, TBotLookAtPriority.MAXIMUM_PRIORITY )
	
	self:Approach( self:GetPos() + 100 * toGoal )
	
	if self:GetLastKnownArea() == botTable.LadderDismountGoal and range < 10.0 then
	
		botTable.LadderInfo = nil
		return NO_LADDER
		
	elseif botTable.LadderDismountGoal == botTable.LadderInfo:GetTopBehindArea() and self:Is_On_Ladder() then
		
		self:PressJump()
		
	end
	
	return DISMOUNTING_LADDER_TOP
	
end

function BOT:DismountLadderBottom()

	local botTable = self:GetTable()
	if !IsValid( botTable.LadderInfo ) or botTable.LadderTimer <= CurTime() then
	
		botTable.LadderInfo = nil
		return NO_LADDER
		
	end
	
	if self:Is_On_Ladder() then
	
		self:PressJump()
		botTable.LadderInfo = nil
		
	end
	
	return NO_LADDER
	
end

function BOT:TraverseLadder()
	
	local botTable = self:GetTable()
	if botTable.LadderState == APPROACHING_ASCENDING_LADDER then
	
		botTable.LadderState = self:ApproachAscendingLadder()
		return true
		
	elseif botTable.LadderState == APPROACHING_DESCENDING_LADDER then
	
		botTable.LadderState = self:ApproachDescendingLadder()
		return true
	
	elseif botTable.LadderState == ASCENDING_LADDER then
	
		botTable.LadderState = self:AscendLadder()
		return true
	
	elseif botTable.LadderState == DESCENDING_LADDER then
	
		botTable.LadderState = self:DescendLadder()
		return true
	
	elseif botTable.LadderState == DISMOUNTING_LADDER_TOP then
	
		botTable.LadderState = self:DismountLadderTop()
		return true
	
	elseif botTable.LadderState == DISMOUNTING_LADDER_BOTTOM then
	
		botTable.LadderState = self:DismountLadderBottom()
		return true
	
	else
	
		botTable.LadderInfo = nil
		
		if self:Is_On_Ladder() then
		
			-- on ladder and don't want to be
			self:PressJump()
			
		end
		
		return false
		
	end
	
	return true

end	

function BOT:JumpOverGaps( goal, forward, right, goalRange )

	local botTable = self:GetTable()
	if !self:IsOnGround() or self:IsClimbingOrJumping() or self:IsAscendingOrDescendingLadder() then
	
		return false
		
	end
	
	if self:Crouching() then
	
		-- Can't jump if we're not standing
		return false
		
	end
	
	if !botTable.Goal then
	
		return false
		
	end
	
	local result
	local hullWidth = self:GetHullWidth()
	
	-- 'current' is the segment we are on/just passed over
	local current = self:PriorSegment( botTable.Goal )
	if !current then
	
		return false
		
	end
	
	local minGapJumpRange = 2.0 * hullWidth
	local gap
	
	if current.Type == PATH_JUMP_OVER_GAP then
	
		gap = current
		
	else
	
		local searchRange = goalRange
		local s = botTable.Goal
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
				botTable.Goal = landing
				
				return true
				
			end
			
		end
		
	end
	
	return false
	
end

function BOT:Climbing( goal, forward, right, goalRange )

	local myArea = self:GetLastKnownArea()
	local botTable = self:GetTable()
	
	-- Use the 2D direction towards our goal
	local climbDirection = Vector( forward.x, forward.y, 0 )
	climbDirection:Normalize()
	
	-- We can't have this as large as our hull width, or we'll find ledges ahead of us
	-- that we will fall from when we climb up because our hull wont actually touch at the top.
	local ledgeLookAheadRange = self:GetHullWidth() - 1
	
	if !self:IsOnGround() or self:IsClimbingOrJumping() or self:IsAscendingOrDescendingLadder() then
	
		return false
		
	end
	
	if !botTable.Goal then
	
		return false
		
	end
	
	if TBotCheaperClimbing:GetBool() then
	
		-- Trust what the nav mesh tells us.
		-- We have been told not to do the expensive ledge-finding.
	
		if botTable.Goal.Type == PATH_CLIMB_UP then
		
			local afterClimb = self:NextSegment( botTable.Goal )
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
	
	if botTable.Goal.Type == PATH_CLIMB_UP then
	
		local afterClimb = self:NextSegment( botTable.Goal )
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
	if ( IsValid( botTable.Goal.Area ) and botTable.Goal.Area:HasAttributes( NAV_MESH_STAIRS ) ) or ( IsValid( myArea ) and myArea:HasAttributes( NAV_MESH_STAIRS ) ) then
	
		return false
		
	end
	
	-- 'current' is the segment we are on/just passed over
	local current = self:PriorSegment( botTable.Goal )
	if !current then
	
		return false
		
	end
	
	-- If path segment immediately ahead of us is not obstructed, don't try to climb.
	-- This is required to try to avoid accidentally climbing onto valid high ledges when we really want to run UNDER them to our destination.
	-- We need to check "immediate" traversability to pay attention to breakable objects in our way that we should climb over.
	-- We also need to check traversability out to 2 * ledgeLookAheadRange in case our goal is just before a tricky ledge climb and once we pass the goal it will be too late.
	-- When we're in a CLIMB_UP segment, allow us to look for ledges - we know the destination ledge height, and will only grab the correct ledge.
	local toGoal = botTable.Goal.Pos - self:GetPos()
	toGoal:Normalize()
	
	if toGoal.z < 0.6 and !botTable.IsStuck and botTable.Goal.Type != PATH_CLIMB_UP and self:IsPotentiallyTraversable( self:GetPos(), self:GetPos() + 2.0 * ledgeLookAheadRange * toGoal ) then
	
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
			if botTable.Goal.Type == PATH_CLIMB_UP then
			
				-- Climbing up to a narrow nav area indicates a narrow ledge.  We need to reduce our minLedgeDepth
				-- here or our path will say we should climb but we'll forever fail to find a wide enough ledge.
				local afterClimb = self:NextSegment( botTable.Goal )
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

	local botTable = self:GetTable()
	if botTable.Goal then
	
		local current = self:PriorSegment( botTable.Goal )
		if current and current.Type == type then
		
			-- We're on the discontinuity now
			return true
			
		end
		
		local rangeSoFar = botTable.Goal.Pos:Distance( self:GetPos() )
		
		local s = botTable.Goal
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

	local botTable = self:GetTable()
	self:PressJump()
	
	-- Face forward
	self:AimAtPos( landingGoal, 1.0, TBotLookAtPriority.HIGH_PRIORITY )
	
	botTable.IsJumpingAcrossGap = true
	botTable.LandingGoal = landingGoal
	botTable.HasLeftTheGround = false
	
end

function BOT:ClimbUpToLedge( landingGoal, landingForward, obstacle )

	local botTable = self:GetTable()
	if !self:IsClimbPossible( obstacle ) then
	
		return false
		
	end
	
	self:PressJump()
	
	botTable.IsClimbingUpToLedge = true
	botTable.LandingGoal = landingGoal
	botTable.HasLeftTheGround = false
	
	return true
	
end

-- Make the bot move.
function BOT:TBotUpdateMovement()
	
	local botTable = self:GetTable()
	if botTable.Goal and self:IsPathValid() then
		
		if self:LadderUpdate() then
			
			-- we are traversing a ladder
			return
			
		end
		
		if self:CheckProgress() == false then
		
			return
			
		end
		
		local forward = botTable.Goal.Pos - self:GetPos()
		
		if botTable.Goal.Type == PATH_CLIMB_UP then
		
			local nextSegment = self:NextSegment( botTable.Goal )
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
		if !self:Climbing( botTable.Goal, forward, left, goalRange ) then
		
			-- A failed climb could mean an invalid path
			if !self:IsPathValid() then
			
				return
				
			end
			
			self:JumpOverGaps( botTable.Goal, forward, left, goalRange )
			
		end
		
		-- Event callbacks from the above climbs and jumps may invalidate the path
		if !self:IsPathValid() then
		
			return
			
		end
		
		local goalPos = Vector( botTable.Goal.Pos )
		forward = goalPos - self:GetPos()
		forward.z = 0.0
		local rangeToGoal = forward:Length()
		forward:Normalize()
		
		left.x = -forward.y
		left.y = forward.x
		left.z = 0.0
		
		if rangeToGoal > 50 or ( botTable.Goal and botTable.Goal.Type != PATH_CLIMB_UP ) then
			
			goalPos = self:TBotAvoid( goalPos, forward, left )
			
		end
		
		if self:IsOnGround() then
		
			self:FaceTowards( goalPos )
			
		end
		
		local CurrentArea = botTable.Goal.Area
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
		if botTable.Goal and ( botTable.Goal.Type == PATH_CLIMB_UP or botTable.Goal.Type == PATH_JUMP_OVER_GAP ) then
		
			self:ReleaseCrouch()
			
		end
		
	end
	
end

function BOT:TBotUpdateLocomotion()

	local botTable = self:GetTable()
	if self:TraverseLadder() then
	
		return
		
	end

	if botTable.IsJumpingAcrossGap or botTable.IsClimbingUpToLedge then
		
		local toLanding = botTable.LandingGoal - self:GetPos()
		toLanding.z = 0.0
		toLanding:Normalize()
		
		if botTable.HasLeftTheGround then
			
			self:AimAtPos( self:GetShootPos() + 100 * toLanding, 0.25, TBotLookAtPriority.MAXIMUM_PRIORITY )
			
			if self:IsOnGround() then
				
				-- Back on the ground - jump is complete
				botTable.IsClimbingUpToLedge = false
				botTable.IsJumpingAcrossGap = false
				
			end
			
		else
			-- Haven't left the ground yet - just starting the jump
			if !self:IsClimbingOrJumping() then
				
				self:PressJump()
				
			end
			
			if botTable.IsJumpingAcrossGap then
				
				self:PressRun()
				
			end
			
			if !self:IsOnGround() then
				
				-- Jump has begun
				botTable.HasLeftTheGround = true
				
			end
			
		end
		
		self:Approach( botTable.LandingGoal )
		
	end
	
end

function BOT:TBotAvoid( goalPos, forward, left )

	local botTable = self:GetTable()
	if botTable.AvoidTimer > CurTime() then
	
		return goalPos
		
	end

	botTable.AvoidTimer = CurTime() + 0.5
	
	if self:IsClimbingOrJumping() or !self:IsOnGround() or self:InVehicle() then
	
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
		botTable.AvoidTimer = 0
		
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
		
		botTable.AvoidTimer = 0
	
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

	local botTable = self:GetTable()
	if !botTable.IsJumping then
	
		return false
		
	end
	
	if botTable.NextJump <= CurTime() and self:IsOnGround() then
	
		botTable.IsJumping = false
		return false
		
	end
	
	return true
	
end

-- TODO: I should really make this dynamic?
-- Would this function work?
-- I would also have to make it account for the hl2 jump boost in game....
--[[function GetJumpHeight(ply)
    local g = GetConVar("sv_gravity"):GetFloat() * ply:GetGravity()
    local j = ply:GetJumpPower()

    j = j - g * 0.5 * engine.TickInterval() --source moment ¯\_(ツ)_/¯
    
    return math.Round(j * j / 2 / g / engine.TickInterval()) * engine.TickInterval() --clamp to tick rate
end]]
function BOT:GetMaxJumpHeight()

	return 64
	
end

function BOT:IsAscendingOrDescendingLadder()

	local botTable = self:GetTable()
	if botTable.LadderState == ASCENDING_LADDER then
	
		return true
		
	elseif botTable.LadderState == DESCENDING_LADDER then
	
		return true
		
	elseif botTable.LadderState == DISMOUNTING_LADDER_TOP then
	
		return true
		
	elseif botTable.LadderState == DISMOUNTING_LADDER_BOTTOM then
	
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

-- This grabs every internal variable of the specified entity
function Test( ply )
	for k, v in pairs( ply:GetSaveTable( true ) ) do
		
		print( k .. ": " .. v )
		
	end 
end

-- I use this function to test function runtimes
function Test2( ply, ply2, second )

	local startTime = SysTime()

	if !second then
	
		for i = 1, 256 do
		
			NavAreaBuildPath( navmesh.GetNearestNavArea( ply:GetPos() ), navmesh.GetNearestNavArea( ply2:GetPos() ), ply2:GetPos(), ply )
			
		end
		
		print( "NavAreaBuildPath RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
		
	else
	
		for i = 1, 256 do
		
			NavAreaTravelDistance( navmesh.GetNearestNavArea( ply:GetPos() ), navmesh.GetNearestNavArea( ply2:GetPos() ), ply )
			
		end
		
		print( "NavAreaTravelDistance RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
		
	end
	
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
			
				-- This doesn't seem to work with func_useableladders
				--[[local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end]]
				
				normal = result2.HitNormal
				
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
			
				-- This doesn't seem to work with func_useableladders
				--[[local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end]]
				
				normal = result2.HitNormal
				
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
			
				-- This doesn't seem to work with func_useableladders
				--[[local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end]]
				
				normal = result2.HitNormal
				
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
			
				-- This doesn't seem to work with func_useableladders
				--[[local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
				if !climbableSurface then
				
					climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
					
				end
				if climbableSurface then
				
					normal = result2.HitNormal
					
				end]]
				
				normal = result2.HitNormal
				
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
	
		-- This doesn't seem to work with func_useableladders
		--[[local climbableSurface = util.GetSurfaceData( result2.SurfaceProps ).climbable != 0
		if !climbableSurface then
		
			climbableSurface = ( bit.band( result2.Contents, CONTENTS_LADDER ) != 0 )
			
		end
		if climbableSurface then
		
			normal = result2.HitNormal
			
		end]]
		
		normal = result2.HitNormal
		
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
	
	if !isfunction( navmesh.CreateNavLadder ) then 
	
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

	if !isfunction( navmesh.CreateNavLadder ) then 
	
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

-- We call this once this addon has sucessfuly initialized, so other addons can override this one!
hook.Run( "TRizzleBotInitialized" )