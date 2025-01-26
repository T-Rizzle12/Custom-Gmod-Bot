-- TRizzleBot_Base.lua
-- Purpose: This is a base that can be modified to play other gamemodes
-- Author: T-Rizzle

local UTIL_TRACELINE = util.TraceLine

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
--[[include( "Action/TBotMainAction.lua" )
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
include( "Action/TBotUseEntity.lua" )]]
-- I do this instead of manually incuding every file so I don't break anything
-- by forgeting to include a file!
local files = file.Find( "Action/*", "LUA" )
for _, action in ipairs( files ) do
	
	--print( action )
	if string.EndsWith( action, ".lua" ) then
		
		include( string.format( "Action/%s", action ) )
		
	end
	
end

-- Grab the needed metatables
local BOT			=	FindMetaTable( "Player" )
local Ent			=	FindMetaTable( "Entity" )
local Wep			=	FindMetaTable( "Weapon" )
local Npc			=	FindMetaTable( "NPC" )
local Nextbot		=	FindMetaTable( "NextBot" )
local Zone			=	FindMetaTable( "CNavArea" )
local Vec			=	FindMetaTable( "Vector" )

-- Setup bot think variables
local BotUpdateSkipCount	=	7 -- This is how many upkeep events must be skipped before another update event can be run. Used to be 2, but it made the addon very laggy at times!
local BotUpdateInterval		=	0

-- Setup the "global" weapon table
local TBotWeaponTable = {}

-- Setup vectors so they don't have to be created later
local HalfHumanHeight		=	Vector( 0, 0, 35.5 )

-- Setup net messages
util.AddNetworkString( "TRizzleBotFlashlight" )
util.AddNetworkString( "TRizzleBotVGUIMenu" )

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
		table.insert( args, net.ReadBool() and 1 or 0 ) -- SpawnWithPreferredWeapons
		
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
	botTable.AttackList						=	{} -- This is the list of entities the bot has been told to attack.
	botTable.AimForHead						=	false -- Should the bot aim for the head?
	botTable.TimeInCombat					=	0 -- This is how long the bot has been in combat.
	botTable.LastCombatTime					=	0 -- This is the last time the bot was in combat.
	botTable.BestWeapon						=	nil -- This is the weapon the bot currently wants to equip.
	botTable.MinEquipInterval				=	0 -- Throttles how often equipping is allowed.
	botTable.LastVisionUpdateTimestamp		=	0 -- This is the last time the bot updated its list of known enemies
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
	self:GetTBotVision():Reset()
	self:GetTBotBody():Reset()
	self:GetTBotLocomotion():Reset()
	self:ComputeApproachPoints()
	--self:TBotCreateThinking() -- Start our AI
	
end

-- Returns the bot's behavior interface.
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
	
		light = Vector( math.Round( light.x, 2 ), math.Round( light.y, 2 ), math.Round( light.z, 2 ) )
		
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
	
	for k, player in player.Iterator() do
		
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
	local vision = self:GetTBotVision()
	if true or vision:IsBlind() then
	
		return
		
	end

	local peripheralUpdateInterval = 0.29
	if CurTime() - self.PeripheralTimestamp < peripheralUpdateInterval then
	
		return
		
	end
	
	--local startTime = SysTime()
	self.PeripheralTimestamp = CurTime()
	
	local lastKnownArea = self:GetLastKnownArea()
	local encounterPos = Vector()
	if IsValid( lastKnownArea ) then
	
		encounterPos:Zero()
		for key1, tbl in ipairs( lastKnownArea:GetSpotEncounters() ) do
		
			for key2, tbl2 in ipairs( tbl.spots ) do
			
				encounterPos.x = tbl2.pos.x
				encounterPos.y = tbl2.pos.y
				encounterPos.z = tbl2.pos.z + HalfHumanHeight.z
				
				if !vision:IsAbleToSee( encounterPos, true ) then
				
					continue
					
				end
				
				self:SetEncounterSpotCheckTimestamp( tbl2.pos )
				
			end
			
		end
		
	end
	--print( "UpdatePeripheralVision RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	
end

-- Determine approach points from eye position and approach areas of current area
-- NEEDTOVALIDATE: Should this be in the vision interface instead?
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
-- NEEDTOVALIDATE: Should this be in the vision interface instead?
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
		
		for k, encounterSpot in RandomPairs( EncounterSpots ) do
			
			local canSee, encounterPos = self:BendLineOfSight( self:GetShootPos(), encounterSpot * 1 ) -- Mutiply encounterSpot by one since it will create a copy of it!
			
			-- BendLineOfSight allows the bot to adjust the encounter spot so the bot can see it.
			if canSee then
			
				local ground = navmesh.GetGroundHeight( encounterPos )
				if ground then 
				
					encounterPos.z = ground + HalfHumanHeight.z
					
				end
				
				self:SetEncounterSpotCheckTimestamp( encounterSpot )
				
				return encounterPos
				
			end
		
		end
	
	end
	
	-- If all else fails, just pick a random direction and look there!
	-- NEEDTOVALIDATE: I could create my own encounter spots instead.....
	return self:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward()

end

-- Return time when given spot was last checked
-- NEEDTOVALIDATE: Should this be in the vision interface instead?
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
-- NEEDTOVALIDATE: Should this be in the vision interface instead?
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

-- In TF2 bots, the function is in the bot table.....
-- Should I put it into TBotBody instead?
function BOT:UpdateLookingAroundForEnemies()

	local botTable = self:GetTable()
	if !botTable.m_isLookingAroundForEnemies then
	
		return
		
	end

	local vision = self:GetTBotVision()
	local body = self:GetTBotBody()
	local mover = self:GetTBotLocomotion()
	local threat = vision:GetPrimaryKnownThreat()
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
	if !IsValid( weapon ) or !weapon:IsWeapon() then
	
		return false
		
	end
	
	-- Some weapons don't use FireBullets, "Melee weapons," so we check GetNextPrimaryFire!
	-- This can be incorrect at times, but this makes the bot attack reloading players as well!
	-- NOTE: We add a 2.0 second buffer since if the weapon is automatic we might not notice the attack!
	if weapon:GetNextPrimaryFire() > ( CurTime() - 2.0 ) then
	
		return true
		
	end
	
	return false
	
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
	
	-- GetTBotRegisteredWeapon always returns a table, even for unregisted weapons
	local weaponInfo = GetTBotRegisteredWeapon( activeWeapon:GetClass() )
	if weaponInfo.IsAutomaticOverride != nil then
	
		return tobool( weaponInfo.IsAutomaticOverride )
	
	end
	
	-- I have to tell the bot manually if a HL2 or HL:S is automatic
	-- since the method I used doesn't work on them
	if !activeWeapon:IsScripted() then
	
		local automaticWeapons = { weapon_crowbar = true, weapon_stunstick = true, weapon_smg1 = true, weapon_ar2 = true, weapon_crowbar_hl1 = true, weapon_mp5_hl1 = true, weapon_hornetgun = true, weapon_egon = true, weapon_gauss = true }
		
		-- I use tobool so this function always returns either true or false
		return tobool( automaticWeapons[ activeWeapon:GetClass() ] )
		
	end
	
	return tobool( activeWeapon.Primary.Automatic )
	
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

-- NEEDTOVALIDATE: This is based off of the code in TF2 where the bot's are ok with
-- firing their weapons even if a teammate is in the way. I may have to change this....
function BOT:IsLineOfFireClear( where )

	if IsValid( where ) and IsEntity( where ) then
	
		local trace = {}
		UTIL_TRACELINE( { start = self:GetShootPos(), endpos = where:GetHeadPos(), filter = TBotTraceFilter, mask = MASK_SHOT, output = trace } )
		
		if ( IsValid( trace.Entity ) and ( trace.Entity:IsBreakable() or trace.Entity == where ) ) or !trace.Hit then
		
			return true
			
		end
		
		UTIL_TRACELINE( { start = self:GetShootPos(), endpos = where:WorldSpaceCenter(), filter = TBotTraceFilter, mask = MASK_SHOT, output = trace } )
		
		if IsValid( trace.Entity ) and trace.Entity:IsBreakable() then
		
			return true
			
		end
		
		return !trace.Hit or trace.Entity == where
	
	elseif isvector( where ) then
	
		local trace = {}
		UTIL_TRACELINE( { start = self:GetShootPos(), endpos = where, filter = TBotTraceFilter, mask = MASK_SHOT, output = trace } )
		
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
		UTIL_TRACELINE( { start = self:EyePos(), endpos = pos:WorldSpaceCenter(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
	
		if trace.Fraction >= 1.0 or trace.Entity == pos or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true

		end
		
		UTIL_TRACELINE( { start = self:EyePos(), endpos = pos:EyePos(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
	
		if trace.Fraction >= 1.0 or trace.Entity == pos or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true
			
		end
		
	elseif isvector( pos ) then
		
		local trace = {}
		UTIL_TRACELINE( { start = self:EyePos(), endpos = pos, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
		
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

-- NEEDTOVALIDATE: Should this be in the vision interface instead?
function BOT:BendLineOfSight( eye, target, angleLimit )
	angleLimit = angleLimit or 135
	
	local result = {}
	UTIL_TRACELINE( { start = eye, endpos = target, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = result } )
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
		
			local actualAngle = side == 2 and startAngle + angle or startAngle - angle
			
			local dx = math.cos( 3.141592 * actualAngle / 180 )
			local dy = math.sin( 3.141592 * actualAngle / 180 )
			
			local rotPoint = Vector( eye.x + length * dx, eye.y + length * dy, target.z )
			
			UTIL_TRACELINE( { start = eye, endpos = rotPoint, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = result } )
			
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
				
				UTIL_TRACELINE( { start = bendPoint, endpos = target, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = result } )
				
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

local oldScreenFade = oldScreenFade or BOT.ScreenFade
-- Basic flashbang support!!!
function BOT:ScreenFade( flags, clr, fadeTime, fadeHold )

	if self:IsTRizzleBot() then

		self:GetTBotVision():Blind( fadeHold, self:IsInCombat() )
		
	end
	
	oldScreenFade( self, flags, clr, fadeTime, fadeHold )
	
end

-- Is the bot the current group leader?
function BOT:IsGroupLeader()

	return self == self.GroupLeader

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
	UTIL_TRACELINE( { start = self:GetShootPos(), endpos = targetpos, filter = self, mask = MASK_SHOT, output = trace } )
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

-- NEEDTOVALIDATE: Should this be moved into one of the bots interfaces?
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
		
		-- Check if we are on target
		local body = self:GetTBotBody()
		if !body:IsHeadAimingOnTarget() then

			return false
			
		end
		
		-- Check to make sure we aren't trying to do something else such as climbing and jumping
		local mover = self:GetTBotLocomotion()
		if mover:IsUsingLadder() or mover:IsJumpingAcrossGap() or mover:IsClimbingUpToLedge() then
		
			return false
			
		end
		
		-- Actually, just returning true is fine now since we can check if the bot is doing something important!
		return true
		-- Make sure we are actually aiming at someone!
		--return IsValid( body.m_lookAtSubject )
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
	local bestWeaponInfo	=	nil
	
	-- Helper function that helps the bot decide if the new weapon is better than the old one!
	local function isNewWeaponBetterOption( newWeapon, newWeaponInfo, oldWeapon, oldWeaponInfo, desiredWeaponType, backupWeaponType, preferredWeapons )
	
		if !IsValid( oldWeapon ) then
		
			return true
			
		end
		
		if newWeaponInfo.WeaponType == desiredWeaponType and ( oldWeaponInfo.WeaponType != desiredWeaponType or tobool( preferredWeapons[ newWeapon:GetClass() ] ) ) then
		
			return true
			
		end
		
		local targetWeaponType = isstring( backupWeaponType ) and backupWeaponType or desiredWeaponType
		if oldWeaponInfo.WeaponType != desiredWeaponType and oldWeaponInfo.WeaponType != newWeaponInfo.WeaponType and newWeapon:GetTBotDistancePriority( targetWeaponType ) > oldWeapon:GetTBotDistancePriority( targetWeaponType ) then
		
			return true
		
		end
		
		return false
	
	end
	
	local desiredWeaponType, backupWeaponType = self:GetDesiredWeaponType( enemydistsqr, vision, botTable )
	local preferredWeapons = botTable.TBotPreferredWeapons
	for k, weapon in ipairs( self:GetWeapons() ) do
	
		if IsValid( weapon ) and weapon:HasPrimaryAmmo() and weapon:IsTBotRegisteredWeapon() then 
			
			local weaponInfo = GetTBotRegisteredWeapon( weapon:GetClass() )
			local weaponType = weaponInfo.WeaponType
			if isNewWeaponBetterOption( weapon, weaponInfo, bestWeapon, bestWeaponInfo, desiredWeaponType, backupWeaponType, preferredWeapons ) then -- and bestWeapon:GetTBotDistancePriority() != desiredWeaponDistance + 1 )
			
				bestWeapon = weapon
				minEquipInterval = weaponType != "Melee" and 5.0 or 2.0
				bestWeaponInfo = weaponInfo
				
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
		if bestWeaponInfo.WeaponType == "Grenade" then
			
			local deployDuration = bestWeapon:SequenceDuration( bestWeapon:SelectWeightedSequence( ACT_VM_DRAW ) )
			if deployDuration < 0 then deployDuration = 0.0 end
			botTable.FireWeaponInterval = CurTime() + deployDuration
			botTable.MinEquipInterval = botTable.MinEquipInterval + deployDuration
			--self.FireWeaponInterval = CurTime() + 1.5
			
		end
		
	end
	
	--end
	
end

function BOT:GetDesiredWeaponType( enemyDist, vision, botTable )
	enemyDist = tonumber( enemyDist ) or math.huge
	vision = vision or self:GetTBotVision()
	botTable = botTable or self:GetTable()

	local desiredWeaponType = "Sniper"
	local backupWeaponType = nil
	if enemyDist < botTable.PistolDist^2 then
		
		desiredWeaponType = "Pistol"
		
	end
	
	if enemyDist < botTable.RifleDist^2 then
	
		desiredWeaponType = "Rifle"
		
	end
	
	if enemyDist < botTable.ShotgunDist^2 then
		
		desiredWeaponType = "Shotgun"
		
	end
	
	local knownCount = vision:GetKnownCount( nil, true, -1 )
	if enemyDist > 200^2 and knownCount >= 5 then
		
		if botTable.GrenadeInterval <= CurTime() then
			
			backupWeaponType = desiredWeaponType
			desiredWeaponType = "Grenade"
			
		elseif botTable.ExplosiveInterval <= CurTime() then
			
			backupWeaponType = desiredWeaponType
			desiredWeaponType = "Explosive"
			
		end
		
	end
	
	if enemyDist < botTable.MeleeDist^2 and knownCount < 5 then
		
		desiredWeaponType = "Melee"
		--desiredRange = 1
		
	end
	
	return desiredWeaponType, backupWeaponType

end

local function TBotRegisterWeaponCommand( ply, cmd, args )
	if !isstring( args[ 1 ] ) then error( "bad argument #1 to 'TBotRegisterWeapon' (string expected got " .. type( args[ 1 ] ) .. ")" ) end

	RegisterTBotWeapon( { ClassName = args[ 1 ], WeaponType = args[ 2 ], HasScope = args[ 3 ], HasSecondaryAttack = args[ 4 ], SecondaryAttackCooldown = args[ 5 ], MaxStoredAmmo = args[ 6 ], IgnoreAutomaticRange = args[ 7 ], ReloadsSingly = args[ 8 ], IsAutomaticOverride = args[ 9 ] } )

end
concommand.Add( "TBotRegisterWeapon", TBotRegisterWeaponCommand, nil, "Registers a new weapon for the bot! ClassName = <string>, WeaponType = <string>, HasScope = <bool>, HasSecondaryAttack = <bool>, SecondaryAttackCooldown = <Number>, MaxStoredAmmo = <Number>, -- NOTE: This is optional. The bot will assume 6 clips of ammo by default IgnoreAutomaticRange = <bool>, -- If the weapon is automatic always press and hold when firing regardless of distance from current enemy! ReloadsSingly = <bool> -- NOTE: This is optional. The bot will assume true for shotguns and false for everything else. IsAutomaticOverride = <bool>, -- NOTE: This is optional and only needed if the bots don't detect the firemode correctly. The bot will attempt to automatically check if a weapon is automatic or not by default!" )

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
	IsAutomaticOverride = <bool>, -- NOTE: This is optional and only needed if the bots don't detect the firemode correctly. The bot will attempt to automatically check if a weapon is automatic or not by default!
]]
-- NOTE: The bot will automatically check if a weapon is automatic or not!
-- Here is a list of avaliable weapon types:
-- Rifle: This is the default type and only affects what distance the bot uses this weapon.
-- Melee: The bot treats this weapon as a melee weapon and will only press its attack button when close to its enemy.
-- Pistol: This tells the bot to use this weapon at the pistol range.
-- Sniper: This tells the bot to use this weapon at the sniper range.
-- Shotgun: This tells the bot to use this weapon at the shotgun range.
-- Explosive: The bot should not use this when an enemy is nearby and will not fire this weapon when too close to its selected enemy.
-- Grenade: The bot will assume the weapon is a grenade and use the grenade AI.
--
function RegisterTBotWeapon( newWeapon )
	if !istable( newWeapon ) then error( "bad argument #1 to 'RegisterTBotWeapon' (Table expected got " .. type( newWeapon ) .. ")" ) end

	if TBotWeaponTable[ newWeapon.ClassName ] then
		
		print( "[INFORMATION] Overriding already registered weapon!" )
		
	end
	
	-- HACKHACK: We have to do this here or the compiler ignores this if it was set to false.
	if newWeapon.IsAutomaticOverride != nil then
	
		newWeapon.IsAutomaticOverride = tobool( newWeapon.IsAutomaticOverride )
		
	end
	
	TBotWeaponTable[ newWeapon.ClassName ] = { WeaponType = newWeapon.WeaponType or "Rifle", ReloadsSingly = newWeapon.ReloadsSingly or newWeapon.WeaponType == "Shotgun", HasScope = tobool( newWeapon.HasScope ), HasSecondaryAttack = tobool( newWeapon.HasSecondaryAttack ), SecondaryAttackCooldown = tonumber( newWeapon.SecondaryAttackCooldown ) or 30.0, MaxStoredAmmo = tonumber( newWeapon.MaxStoredAmmo ), IgnoreAutomaticRange = tobool( newWeapon.IgnoreAutomaticRange ), IsAutomaticOverride = newWeapon.IsAutomaticOverride }

end

-- Register the default weapons!
RegisterTBotWeapon( { ClassName = "weapon_stunstick", WeaponType = "Melee" } )
RegisterTBotWeapon( { ClassName = "weapon_frag", WeaponType = "Grenade" } )
RegisterTBotWeapon( { ClassName = "weapon_crossbow", WeaponType = "Sniper", HasScope = true, MaxStoredAmmo = 12 } )
RegisterTBotWeapon( { ClassName = "weapon_rpg", WeaponType = "Explosive" } )
RegisterTBotWeapon( { ClassName = "weapon_crowbar", WeaponType = "Melee" } )
RegisterTBotWeapon( { ClassName = "weapon_shotgun", WeaponType = "Shotgun", HasSecondaryAttack = true, SecondaryAttackCooldown = 10.0 } )
RegisterTBotWeapon( { ClassName = "weapon_pistol", WeaponType = "Pistol" } )
RegisterTBotWeapon( { ClassName = "weapon_smg1", WeaponType = "Rifle", HasSecondaryAttack = true } )
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

local reloadActs = {
	[ACT_VM_RELOAD] = true,
	[ACT_VM_RELOAD2] = true,
	[ACT_SHOTGUN_RELOAD_START] = true,
	[ACT_SHOTGUN_RELOAD_FINISH] = true,
	[ACT_VM_RELOAD_SILENCED] = true,
	[ACT_VM_RELOAD_DEPLOYED] = true,
	[ACT_VM_RELOAD_IDLE] = true,
	[ACT_VM_RELOAD_EMPTY] = true
}

-- Checks if the bot is currently reloading
function BOT:IsReloading()

	local botWeapon = self:GetActiveWeapon()
	
	if IsValid( botWeapon ) and botWeapon:IsWeapon() then
	
		if botWeapon:GetInternalVariable( "m_bInReload" ) then
		
			return true
			
		end
		
	end
	
	-- FIXME: This doesn't work at times!
	-- HACKHACK: Some custom weapons don't set m_bInReload, aka use DefaultReload!
	-- We can use the bot's viewmodel to check if the bot is reloading or not!
	local botViewModel = self:GetViewModel()
	
	if IsValid( botViewModel ) then
	
		local seq = botViewModel:GetSequence()
		if isnumber( seq ) then
		
			local act = botViewModel:GetSequenceActivity( seq )
			if tobool( reloadActs[ act ] ) and !botViewModel:IsSequenceFinished() then
			
				return true
			
			end
			
		end
		
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
-- NEEDTOVALIDATE: Should I make a verstion of this to find the body as well?
function Ent:GetHeadPos()

	local boneIndex = self:LookupBone( "ValveBiped.Bip01_Head1" )
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

function Ent:IsExplosive()
	if self:Health() < 1 then return false end

	-- HACKHACK: GetInternalVariable doesn't work on the Explosive key values, so we have to do this instead. :(
	local explosiveKV = self:GetKeyValues()[ "ExplodeDamage" ]
	return explosiveKV and explosiveKV > 0 or false

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

-- Compute a pseudo random value (0-1) that stays consistent for the 
-- given period of time, but changes unpredictably each period.
function BOT:TransientlyConsistentRandomValue( period, seedValue )
	period = tonumber( period ) or 10.0
	seedValue = tonumber( seedValue ) or 0.0
	
	local area = self:GetLastKnownArea()
	if !IsValid( area ) then
	
		return 0.0
		
	end

	-- This term stays stable for 'period' seconds, then changes in an unpredictable way
	local timeMod = math.floor( CurTime() / period ) + 1
	return math.abs( math.cos( seedValue + ( self:EntIndex() * area:GetID() * timeMod ) ) )

end

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
			
			-- TODO: We need to a better way to limit how often the bot's update their AI!
			if ( ( engine.TickCount() + bot:EntIndex() ) % BotUpdateSkipCount ) == 0 then
			
				bot:ResetCommand() -- Clear all movement and buttons
				
				-- This seems to lag the game
				bot:UpdatePeripheralVision() -- Should this be moved into the vision interface?
				
				bot:GetTBotBehavior():Update( bot, engine.TickInterval() * BotUpdateSkipCount ) -- I think the update rate is correct?
				bot:GetTBotVision():Update( bot, engine.TickInterval() * BotUpdateSkipCount ) -- The vision interface doesn't use these, but just in case...
				bot:GetTBotLocomotion():Update( bot, engine.TickInterval() * BotUpdateSkipCount ) -- The locomotion interface doesn't use these, but just in case...
				
				-- The check CNavArea we are standing on.
				if !IsValid( botTable.currentArea ) or !botTable.currentArea:Contains( bot:GetPos() ) then
				
					botTable.currentArea			=	navmesh.GetNearestNavArea( bot:GetPos(), true, 50, true )
					
				end
				
				if IsValid( botTable.currentArea ) and botTable.currentArea != botTable.lastKnownArea then
				
					botTable.lastKnownArea = botTable.currentArea
					
				end
				
			end
			
		end
		
	end

	--print( "Think RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	
end)

-- Reset their AI on spawn.
hook.Add( "PlayerSpawn" , "TRizzleBotSpawnHook" , function( ply )
	
	if ply:IsTRizzleBot() then
		
		ply:TBotResetAI()
		
	end
	
end)

-- Checks if the NPC is alive
function Npc:IsAlive()
	
	if self:GetNPCState() == NPC_STATE_DEAD then return false
	elseif self:GetInternalVariable( "m_lifeState" ) != 0 then return false 
	elseif self:Health() <= 0 then return false end
	
	return true
	
end

function Nextbot:IsAlive()

	if self:Health() <= 0 then return false end
	
	return true

end

-- Checks if the target entity is the bot's enemy
-- TODO: Should this be moved into one of the bot's interfaces instead?
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
		
			if GAMEMODE.TeamBased then 
			
				if self:Team() != target:Team() and ( botTable.TBotOwner != target and targetTable.TBotOwner != self and botTable.TBotOwner != targetTable.TBotOwner ) then
			
					return true
					
				end
				
			elseif botTable.TBotOwner != target and targetTable.TBotOwner != self and botTable.TBotOwner != targetTable.TBotOwner then
		
				return true
				
			end
		
		else
		
			if GAMEMODE.TeamBased then 
			
				return self:Team() != target:Team()
				
			else
			
				return true
				
			end
		
		end
		
	end
	
	return false
	
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

-- Returns whether the value is in given table,
-- but made to search through sequential tables instead
function table.HasValueSequential( t, val )

	for k, v in ipairs( t ) do
	
		if v == val then return true end
		
	end
	
	return false
	
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
			assert( NewCostSoFar >= Current:GetCostSoFar(), Format( "NewCostSoFar was %i while fromArea CostSoFar was %i!", NewCostSoFar, Current:GetCostSoFar() ) )
			
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
				local distSq = newArea:GetCenter():DistToSqr( actualGoalPos )
				local newCostRemaining = distSq > 0.0 and math.sqrt( distSq ) or 0.0
				
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

local result = Vector()
-- Checks if the bot will cross enemy line of fire when attempting to move to the entered position
function BOT:IsCrossingLineOfFire( startPos, endPos )
	
	local vision = self:GetTBotVision()
	for k, known in ipairs( vision.m_knownEntityVector or {} ) do
	
		if !vision:IsAwareOf( known ) or known:IsObsolete() or !self:IsEnemy( known:GetEntity() ) then
		
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
	
	-- Don't consider spots if a bot or human player is already there
	if IsValid( ply ) and ply != self and distance < 75 then
	
		return true

	end

	local trace = {}
	local body = self:GetTBotBody()
	local size = body:GetHullWidth() / 2.0
	util.TraceHull( { start = pos, endpos = pos, maxs = Vector( size, size, body:GetCrouchHullHeight() ), mins = Vector( -size, -size, 0.0 ), mask = MASK_PLAYERSOLID, filter = TBotTraceFilter, output = trace  } )
	-- Don't consider spots if there is a prop in the way.
	if trace.Fraction < 1.0 or trace.StartSolid then
	
		return true
		
	end

	return false

end

-- Checks if a hiding spot is safe to use
function BOT:IsSpotSafe( hidingSpot )

	local vision = self:GetTBotVision()
	for k, known in ipairs( vision.m_knownEntityVector or {} ) do
	
		if vision:IsAwareOf( known ) and !known:IsObsolete() and self:IsEnemy( known:GetEntity() ) and known:GetEntity():VisibleVec( hidingSpot ) then return false end -- If one of the bot's enemies its aware of can see it the bot won't use it.
	
	end

	return true

end

-- Returns a table of hiding spots.
function BOT:FindSpots( tbl )

	--local startTime = SysTime()
	local mover = self:GetTBotLocomotion()
	local tbl = tbl or {}

	tbl.pos				= tbl.pos				or self:WorldSpaceCenter()
	tbl.radius			= tbl.radius			or 1000
	tbl.stepdown		= tbl.stepdown			or 1000
	tbl.stepup			= tbl.stepup			or mover:GetMaxJumpHeight()
	tbl.spotType		= tbl.spotType			or "hiding"
	tbl.checkoccupied	= tbl.checkoccupied		or 1
	tbl.checksafe		= tbl.checksafe			or 1
	tbl.checklineoffire	= tbl.checklineoffire	or 1

	-- Find a bunch of areas within this distance
	local areas = navmesh.Find( tbl.pos, tbl.radius, tbl.stepup, tbl.stepdown )

	local found = {}
	
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
			
				continue 
			
			end
			
			table.insert( found, { vector = vec, distance = pathLength } )

		end

	end
	
	if ( !found or #found == 0 ) and !tbl.secondAttempt then
	
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
	return found

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
	
	return navmesh.GetNearestNavArea( self:GetPos(), true, 200 )
	
end

function BOT:GetDesiredSpeed()

	local desiredSpeed = self:GetWalkSpeed()
	if self:KeyDown( IN_WALK ) then
	
		desiredSpeed = self:GetSlowWalkSpeed()
		
	elseif self:KeyDown( IN_SPEED ) and !self:Crouching() then
	
		desiredSpeed = self:GetRunSpeed()
		
	end
	
	local mover = self:GetTBotLocomotion()
	if mover:IsOnLadder() then
	
		return self:GetLadderClimbSpeed()
		
	end
	
	if self:Crouching() then
	
		desiredSpeed = desiredSpeed * self:GetCrouchedWalkSpeed()
		
	end
	
	return desiredSpeed
	
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
		
		local leftMargin = TargetArea:IsEdge( WEST ) and left + margin or left
		local rightMargin = TargetArea:IsEdge( EAST ) and right - margin or right
		
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
		
		local topMargin = TargetArea:IsEdge( NORTH ) and top + margin or top
		local bottomMargin = TargetArea:IsEdge( SOUTH ) and bottom - margin or bottom
		
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

	for k, area in ipairs( self:GetAdjacentAreasAtSide( dir ) ) do
	
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

	UTIL_TRACELINE( { start = from, endpos = ladder:GetBottom(), mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )

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
		
		UTIL_TRACELINE( { start = from, endpos = to, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
		if result.Fraction != 1.0 or result.StartSolid then
		
			--NORTH
			dir = NORTH
			normal = AddDirectionVector( normal, NORTH, 1.0 )
			local from2 = ( top + bottom ) * 0.5 + normal * 5.0
			local to2 = from2 - normal * 32.0
			
			local result2 = {}
			UTIL_TRACELINE( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
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
			UTIL_TRACELINE( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
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
		
		UTIL_TRACELINE( { start = from, endpos = to, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
		if result.Fraction != 1.0 or result.StartSolid then
		
			--WEST
			dir = WEST
			normal = AddDirectionVector( normal, WEST, 1.0 )
			local from2 = ( top + bottom ) * 0.5 + normal * 5.0
			local to2 = from2 - normal * 32.0
			
			local result2 = {}
			UTIL_TRACELINE( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
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
			UTIL_TRACELINE( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
			
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
		
		UTIL_TRACELINE( { start = on, endpos = out, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
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
		
		UTIL_TRACELINE( { start = on, endpos = out, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result } )
		
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
	UTIL_TRACELINE( { start = from2, endpos = to2, mask = MASK_PLAYERSOLID_BRUSHONLY, output = result2 } )
	
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

-- We have to put this into a timer since if we call it now there is a chance other addon's haven't loaded yet!
timer.Simple( 0.0, function()

	-- We call this once this addon has sucessfuly initialized, so other addons can override this one!
	hook.Run( "TRizzleBotInitialized" )
	
end)