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

-- Setup addon cvars
local TBotSpawnTime = CreateConVar( "TBotSpawnTime", 6.0, FCVAR_NONE, "This is how long a bot must be dead before it can respawn.", 0 )
local TBotLookAheadRange = CreateConVar( "TBotLookAheadRange", 300.0, FCVAR_CHEAT, "This is the minimum range a movement goal must be along the bot's path.", 0 )
local TBotSaccadeSpeed = CreateConVar( "TBotSaccadeSpeed", 1000.0, FCVAR_CHEAT, "This is the maximum speed the bot can turn at.", 0 )
local TBotAttackNextBots = CreateConVar( "TBotAttackNextBots", 0.0, FCVAR_NONE, "If nonzero, bots will consider every nextbot to be it's enemy." )
local TBotAttackPlayers = CreateConVar( "TBotAttackPlayers", 0.0, FCVAR_NONE, "If nonzero, bots will consider every player who is not its Owner or have the same Owner as it an enemy." )

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
	TBotSetSniper( ply, cmd, { args[ 1 ], args[ 8 ], args[ 9 ] } ) -- This is the sniper the bot will use and does the sniper the bot is using have a scope
	TBotSetMeleeDist( ply, cmd, { args[ 1 ], args[ 10 ] } ) -- If an enemy is closer than this, the bot will use its melee
	TBotSetPistolDist( ply, cmd, { args[ 1 ], args[ 11 ] } ) -- If an enemy is closer than this, the bot will use its pistol
	TBotSetShotgunDist( ply, cmd, { args[ 1 ], args[ 12 ] } ) -- If an enemy is closer than this, the bot will use its shotgun
	TBotSetRifleDist( ply, cmd, { args[ 1 ], args[ 13 ] } ) -- If an enemy is closer than this, the bot will use its rifle/smg
	TBotSetHealThreshold( ply, cmd, { args[ 1 ], args[ 14 ] } ) -- If the bot's health or a teammate's health drops below this and the bot is not in combat the bot will use its medkit
	TBotSetCombatHealThreshold( ply, cmd, { args[ 1 ], args[ 15 ] } ) -- If the bot's health drops below this and the bot is in combat the bot will use its medkit
	TBotSetPlayerModel( ply, cmd, { args[ 1 ], args[ 16 ] } ) -- This is the player model the bot will use
	TBotSpawnWithPreferredWeapons( ply, cmd, { args[ 1 ], args[ 17 ] } ) -- This checks if the bot should spawn with its preferred weapons
	
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
	local melee = args[ 2 ] or "weapon_crowbar"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Melee = melee
			
		end
		
	end

end

function TBotSetPistol( ply, cmd, args ) -- Command for changing the bots pistol to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local pistol = args[ 2 ] or "weapon_pistol"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Pistol = pistol
			
		end
		
	end

end

function TBotSetShotgun( ply, cmd, args ) -- Command for changing the bots shotgun to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local shotgun = args[ 2 ] or "weapon_shotgun"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Shotgun = shotgun
			
		end
		
	end

end

function TBotSetRifle( ply, cmd, args ) -- Command for changing the bots rifle to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] or "weapon_smg1"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and ( bot:Nick() == targetbot or string.lower( targetbot ) == "all" ) and bot.TBotOwner == ply then
			
			bot.Rifle = rifle
			
		end
		
	end

end

function TBotSetSniper( ply, cmd, args ) -- Command for changing the bots sniper to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] or "weapon_crossbow"
	local hasScope = args[ 3 ] or 1
	
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
	local playermodel = args[ 2 ] or "kleiner"
	
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
	TBotSetSniper( ply, cmd, args )
	TBotSetMeleeDist( ply, cmd, args )
	TBotSetPistolDist( ply, cmd, args )
	TBotSetShotgunDist( ply, cmd, args )
	TBotSetRifleDist( ply, cmd, args )
	TBotSetHealThreshold( ply, cmd, args )
	TBotSetCombatHealThreshold( ply, cmd, args )
	TBotSpawnWithPreferredWeapons( ply, cmd, args )

end

concommand.Add( "TRizzleCreateBot" , TBotCreate , nil , "Creates a TRizzle Bot with the specified parameters. Example: TRizzleCreateBot <botname> <followdist> <dangerdist> <melee> <pistol> <shotgun> <rifle> <sniper> <hasScope> <meleedist> <pistoldist> <shotgundist> <rifledist> <healthreshold> <combathealthreshold> <playermodel> <spawnwithpreferredweapons> Example2: TRizzleCreateBot Bot 200 300 weapon_crowbar weapon_pistol weapon_shotgun weapon_smg1 weapon_crossbow 1 80 1300 300 900 100 25 alyx 1" )
concommand.Add( "TBotSetFollowDist" , TBotSetFollowDist , nil , "Changes the specified bot's how close it should be to its owner. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetDangerDist" , TBotSetDangerDist , nil , "Changes the specified bot's how far the bot can be from its owner while in combat. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetMelee" , TBotSetMelee , nil , "Changes the specified bot's preferred melee weapon. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetPistol" , TBotSetPistol , nil , "Changes the specified bot's preferred pistol. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetShotgun" , TBotSetShotgun , nil , "Changes the specified bot's preferred shotgun. If only the bot is specified the value will revert back to the default." )
concommand.Add( "TBotSetRifle" , TBotSetRifle , nil , "Changes the specified bot's preferred rifle/smg. If only the bot is specified the value will revert back to the default." )
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
	self.EnemyList					=	{} -- This is the list of enemies the bot knows about.
	self.AimForHead					=	false -- Should the bot aim for the head?
	self.TimeInCombat				=	0 -- This is how long the bot has been in combat.
	self.LastCombatTime				=	0 -- This is the last time the bot was in combat.
	self.BestWeapon					=	nil -- This is the weapon the bot currently wants to equip.
	self.MinEquipInterval			=	0 -- Throttles how often equipping is allowed.
	self.HealTarget					=	nil -- This is the player the bot is trying to heal.
	self.TRizzleBotBlindTime		=	0 -- This is how long the bot should be blind
	self.LastVisionUpdateTimestamp	=	0 -- This is the last time the bot updated its list of known enemies
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
	self.Light						=	false -- Tells the bot if it should have its flashlight on or off.
	--self.LookYawVel					=	0 -- This is the current yaw velocity of the bot.
	--self.LookPitchVel				=	0 -- This is the current pitch velocity of the bot.
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
	--self.CurrentSegment				=	1 -- This is the current segment the bot is on.
	self.SegmentCount				=	0 -- This is how many nodes the bot's current path has.
	self.LadderState				=	NO_LADDER -- This is the current ladder state of the bot.
	self.LadderInfo					=	nil -- This is the current ladder the bot is trying to use.
	self.LadderDismountGoal			=	nil -- This is the bot's goal once it reaches the end of its selected ladder.
	self.LadderTimer				=	0 -- This helps the bot leave the ladder state if it somehow gets stuck.
	self.MotionVector				=	Vector( 1.0, 0, 0 ) -- This is the bot's current movement as a vector.
	self.RepathTimer				=	CurTime() + 0.5 -- This will limit how often the path gets recreated.
	self.AvoidTimer					=	0 -- Limits how often the bot avoid checks are run.
	self.WiggleTimer				=	0 -- This helps the bot get unstuck.
	self.StuckJumpInterval			=	0 -- Limits how often the bot jumps when stuck.
	
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
	cmd:SetUpMove( bit.band( bot.buttonFlags, IN_JUMP ) == IN_JUMP and bot:GetJumpPower() or 0 )
	
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
	
	if IsValid( self:GetLastKnownArea() ) then -- If there is no nav_mesh this will not run to prevent the addon from spamming errors
		
		if self:IsOnGround() and self:GetLastKnownArea():HasAttributes( NAV_MESH_JUMP ) then
			
			ShouldJump		=	true
			
		end
		
		if self:GetLastKnownArea():HasAttributes( NAV_MESH_CROUCH ) and ( !self.Goal or self.Goal.Type == PATH_ON_GROUND ) then
			
			ShouldCrouch	=	true
			
		end
		
		if self:GetLastKnownArea():HasAttributes( NAV_MESH_RUN ) then
			
			ShouldRun		=	true
			ShouldWalk		=	false
			
		end
		
		if self:GetLastKnownArea():HasAttributes( NAV_MESH_WALK ) then
			
			CanRun			=	false
			ShouldWalk		=	true
			
		end
		
		if self:GetLastKnownArea():HasAttributes( NAV_MESH_STAIRS ) then -- The bot shouldn't jump while on stairs
		
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
	
		self:PressCrouch( 0.3 )
		
	end
	
	--local door = self:GetEyeTrace().Entity
	
	if IsValid( self.Breakable ) then
	
		if IsValid( self.HealTarget ) or !self.Breakable:IsBreakable() or self.Breakable:WorldSpaceCenter():DistToSqr( self:GetPos() ) > 6400 or !self:IsAbleToSee( self.Breakable ) then
		
			self.Breakable = nil
			return
			
		end
		
		self:AimAtPos( self.Breakable:WorldSpaceCenter(), 0.5, MAXIMUM_PRIORITY )
		
		if self:IsLookingAtPosition( self.Breakable:WorldSpaceCenter() ) then
		
			if IsValid( self.BestWeapon ) and self.BestWeapon:IsWeapon() and self.BestWeapon:GetClass() != "weapon_medkit" then
			
				if self.BestWeapon:GetClass() == self.Melee then
				
					local rangeToShoot = self:GetShootPos():DistToSqr( self.Breakable:WorldSpaceCenter() )
					local rangeToStand = self:GetPos():DistToSqr( self.Breakable:WorldSpaceCenter() )
					
					-- If the breakable is on the ground and we are using a melee weapon
					-- we have to crouch in order to hit it
					if rangeToShoot <= 4900 and rangeToShoot > rangeToStand then
					
						self:PressCrouch()
						
					end
					
				end
			
				if CurTime() >= self.FireWeaponInterval and self:GetActiveWeapon() == self.BestWeapon then
				
					self:PressPrimaryAttack()
					self.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )
					
					if self.BestWeapon:UsesClipsForAmmo1() and self.BestWeapon:Clip1() > 0 then
					
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
	
	elseif IsValid( self.Door ) then 
	
		if !self.Door:IsDoor() or self.Door:IsDoorOpen() or self.Door:GetPos():DistToSqr( self:GetPos() ) > 6400 then 
		
			self.Door = nil
			return
			
		end
		
		self:AimAtPos( self.Door:WorldSpaceCenter(), 0.5, MAXIMUM_PRIORITY )
		
		if CurTime() >= self.UseInterval and self:IsLookingAtPosition( self.Door:WorldSpaceCenter() ) then
			
			self:PressUse()
			self.UseInterval = CurTime() + 0.5
			
		end
		
	end
	
end

function BOT:PressPrimaryAttack( holdTime )
	if self.HoldAttack > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_ATTACK )
	self.HoldAttack = CurTime() + holdTime

end

function BOT:PressSecondaryAttack( holdTime )
	if self.HoldAttack2 > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_ATTACK2 )
	self.HoldAttack2 = CurTime() + holdTime

end

function BOT:PressReload( holdTime )
	if self.HoldReload > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_RELOAD )
	self.HoldReload = CurTime() + holdTime

end

function BOT:PressForward( holdTime )
	if self.HoldForward > CurTime() then return end
	holdTime = holdTime or -1.0
	
	self.forwardMovement = self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_FORWARD )
	self.HoldForward = CurTime() + holdTime
	
	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_BACK ) )
	self.HoldBack = CurTime()

end

function BOT:PressBack( holdTime )
	if self.HoldBack > CurTime() then return end
	holdTime = holdTime or -1.0
	
	self.forwardMovement = -self:GetRunSpeed()
	
	self.buttonFlags = bit.bor( self.buttonFlags, IN_BACK )
	self.HoldBack = CurTime() + holdTime
	
	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_FORWARD ) )
	self.HoldForward = CurTime()

end

function BOT:PressLeft( holdTime )
	if self.HoldLeft > CurTime() then return end
	holdTime = holdTime or -1.0
	
	self.strafeMovement = -self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_MOVELEFT )
	self.HoldLeft = CurTime() + holdTime

	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_MOVERIGHT ) )
	self.HoldRight = CurTime()

end

function BOT:PressRight( holdTime )
	if self.HoldRight > CurTime() then return end
	holdTime = holdTime or -1.0
	
	self.strafeMovement = self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_MOVERIGHT )
	self.HoldRight = CurTime() + holdTime
	
	self.buttonFlags = bit.band( self.buttonFlags, bit.bnot( IN_MOVELEFT ) )
	self.HoldLeft = CurTime()

end

function BOT:PressRun( holdTime )
	if self.HoldRun > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_SPEED )
	self.HoldRun = CurTime() + holdTime

end

function BOT:PressWalk( holdTime )
	if self.HoldWalk > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_WALK )
	self.HoldWalk = CurTime() + holdTime

end

function BOT:PressJump( holdTime )
	if self.NextJump > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_JUMP )
	self.HoldJump = CurTime() + holdTime
	
	-- This cooldown is to prevent the bot from pressing and holding its jump button
	if holdTime < 0.0 then
	
		self.NextJump = CurTime() + 0.5
	
	else
		
		self.NextJump = self.HoldJump + 0.5

	end
	
end

function BOT:PressCrouch( holdTime )
	if self.HoldCrouch > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_DUCK )
	self.HoldCrouch = CurTime() + holdTime

end

function BOT:PressUse( holdTime )
	if self.HoldUse > CurTime() then return end
	holdTime = holdTime or -1.0

	self.buttonFlags = bit.bor( self.buttonFlags, IN_USE )
	self.HoldUse = CurTime() + holdTime

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
	if IsValid( self:GetLastKnownArea() ) then
	
		self.ApproachPoints = {}
		-- For some reason if there is only once adjacent area no encounter spots will be created
		-- So I grab the single adjacent area instead and use its encounter and approach spots instead
		local spotEncounter = Either( self:GetLastKnownArea():GetAdjacentCount() == 1, self:GetLastKnownArea():GetAdjacentAreas()[ 1 ]:GetSpotEncounters(), self:GetLastKnownArea():GetSpotEncounters() )
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
	if IsValid( self:GetLastKnownArea() ) then
	
		local EncounterSpots = {}
		-- For some reason if there is only once adjacent area no encounter spots will be created
		-- So I grab the single adjacent area instead and use its encounter and approach spots instead
		local spotEncounter = Either( self:GetLastKnownArea():GetAdjacentCount() == 1, self:GetLastKnownArea():GetAdjacentAreas()[ 1 ]:GetSpotEncounters(), self:GetLastKnownArea():GetSpotEncounters() )
		
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
	
	return 0.0
	
	-- This is an example of different levels of aim tracking
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
	
	local Subject = self.LookTargetSubject
	if IsValid( Subject ) then
	
		if self.LookTargetTrackingTimer <= CurTime() then
		
			local desiredLookTargetPos = nil
			
			if self.AimForHead and !self:IsActiveWeaponRecoilHigh() then
			
				desiredLookTargetPos = Subject:GetHeadPos()
				
			else
			
				desiredLookTargetPos = Subject:WorldSpaceCenter()
				
			end
			
			local errorVector = desiredLookTargetPos - self.LookTarget
			local Error = errorVector:Length()
			errorVector:Normalize()
			
			local trackingInterval = self:GetHeadAimTrackingInterval()
			if trackingInterval < deltaT then
			
				trackingInterval = deltaT
				
			end
			
			local errorVel = Error / trackingInterval
			
			self.LookTargetVelocity = ( errorVel * errorVector ) + Subject:GetVelocity()
			
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
	
		self.IsSightedIn = true
		
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

-- Rotate body to face towards "target"
function BOT:FaceTowards( target )

	if !isvector( target ) then
	
		return
		
	end
	
	local look = Vector( target.x, target.y, self:GetShootPos().z )
	
	self:AimAtPos( look, 0.1, LOW_PRIORITY )
	
end

function BOT:AimAtPos( Pos, Time, Priority )
	
	if !isvector( Pos ) or !isnumber( Time ) or !isnumber( Priority ) then
	
		return
		
	end
	
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
	
	if !IsValid( Subject ) or !isnumber( Time ) or !isnumber( Priority ) then
	
		return
		
	end
	
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
local oldIsBot = BOT.IsBot
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

local oldGetInfo = BOT.GetInfo
-- This allows me to set the bot's client convars.
function BOT:GetInfo( cVarName )

	if self:IsTRizzleBot( true ) then
	
		if cVarName == "cl_playermodel" then
		
			return tostring( self.PlayerModel )
			
		elseif cVarName == "cl_playerskin" then
		
			return tostring( self.PlayerSkin )
		
		elseif cVarName == "cl_playerbodygroups" then
		
			return tostring( self.PlayerBodyGroup )
		
		end
		
	end
	
	return oldGetInfo( self, cVarName )

end

local oldGetInfoNum = BOT.GetInfoNum
-- This allows me to set the bot's client convars.
function BOT:GetInfoNum( cVarName, default )

	if self:IsTRizzleBot( true ) then
	
		if cVarName == "cl_playermodel" then
		
			return tonumber( self.PlayerModel ) or default
			
		elseif cVarName == "cl_playerskin" then
		
			return tonumber( self.PlayerSkin ) or default
		
		elseif cVarName == "cl_playerbodygroups" then
		
			return tonumber( self.PlayerBodyGroup ) or default
		
		end
		
	end
	
	return oldGetInfoNum( self, cVarName, default )

end

-- Got this from CS:GO Source Code, made some changes so it works for Lua
function BOT:IsActiveWeaponRecoilHigh()

	local angles = self:GetViewPunchAngles()
	local highRecoil = -1.5
	return angles.x < highRecoil
end

-- Checks if the bot's active weapon is automatic
function BOT:IsActiveWeaponAutomatic()
	
	local activeWeapon = self:GetActiveWeapon()
	if !IsValid( activeWeapon ) or !activeWeapon:IsWeapon() or !activeWeapon:IsScripted() then return false end
	
	return activeWeapon.Primary.Automatic
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

-- Checks if the current position or entity can be seen by the target entity
function Ent:TBotVisible( pos )
	
	if IsValid( pos ) and IsEntity( pos ) then
		
		local trace = util.TraceLine( { start = self:EyePos(), endpos = pos:WorldSpaceCenter(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
	
		if trace.Fraction == 1.0 or trace.Entity == pos or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true

		end
		
		local trace2 = util.TraceLine( { start = self:EyePos(), endpos = pos:EyePos(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
	
		if trace2.Fraction == 1.0 or trace2.Entity == pos or ( pos:IsPlayer() and trace2.Entity == pos:GetVehicle() ) then
			
			return true
			
		end
		
	elseif isvector( pos ) then
		
		local trace = util.TraceLine( { start = self:EyePos(), endpos = pos, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
		
		return trace.Fraction == 1.0
		
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

	angleLimit = angleLimit or 180
	
	local result = util.TraceLine( { start = eye, endpos = target, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
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
			
			result = util.TraceLine( { start = eye, endpos = rotPoint, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
			
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
				
				result = util.TraceLine( { start = bendPoint, endpos = target, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
				
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

-- This checks if the entered position in the bot's LOS
function BOT:IsAbleToSee( pos, checkFOV )
	if self:IsTRizzleBotBlind() then return false end

	local fov = math.cos(0.5 * self:GetFOV() * math.pi / 180) -- I grab the bot's current FOV

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
		
		if checkFOV and !self:PointWithinViewAngle( self:GetShootPos(), pos:WorldSpaceCenter(), self:GetAimVector(), fov ) and !self:PointWithinViewAngle( self:GetShootPos(), pos:EyePos(), self:GetAimVector(), fov ) then
			
			return false
			
		end
		
		return self:TBotVisible( pos )

	elseif isvector( pos ) then
		
		if ( pos - self:GetPos() ):IsLengthGreaterThan( 6000 ) then
		
			return false
			
		end
		
		if self:IsHiddenByFog( self:GetShootPos():Distance( pos ) ) then
		
			return false
			
		end
		
		if checkFOV and !self:PointWithinViewAngle( self:GetShootPos(), pos, self:GetAimVector(), fov ) then
		
			return false
			
		end
		
		return self:TBotVisible( pos )
		
	end
	
	return false
end

-- Blinds the bot for a specified amount of time
function BOT:TBotBlind( time )
	if !IsValid( self ) or !self:Alive() or !self:IsTRizzleBot() or time < ( self.TRizzleBotBlindTime - CurTime() ) then return end
	
	self.TRizzleBotBlindTime = CurTime() + time
	self:AimAtPos( self:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward(), 0.1, MAXIMUM_PRIORITY ) -- Make the bot fling its aim in a random direction upon becoming blind
end

-- Is the bot currently blind?
function BOT:IsTRizzleBotBlind()
	if !IsValid( self ) or !self:Alive() or !self:IsTRizzleBot() then return false end
	
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
	local trace = util.TraceLine( { start = self:GetShootPos(), endpos = targetpos, filter = self, mask = MASK_SHOT } )
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
		
		if self.AimForHead and !self:IsActiveWeaponRecoilHigh() then
		
			return self:PointWithinCursor( target, target:GetHeadPos() )
		
		end

		return self:PointWithinCursor( target, target:WorldSpaceCenter() )
	
	end
	
	return false
end

-- This will select the best weapon based on the bot's current distance from its enemy
function BOT:SelectBestWeapon( target )
	if self.MinEquipInterval > CurTime() or !IsValid( target ) then return end
	
	local enemydistsqr		=	target:GetPos():DistToSqr( self:GetPos() ) -- Only compute this once, there is no point in recomputing it multiple times as doing so is a waste of computer resources
	local oldBestWeapon 	= 	self.BestWeapon
	local minEquipInterval	=	0
	local bestWeapon		=	nil
	local pistol			=	self:GetWeapon( self.Pistol )
	local rifle				=	self:GetWeapon( self.Rifle )
	local shotgun			=	self:GetWeapon( self.Shotgun )
	local sniper			=	self:GetWeapon( self.Sniper )
	local melee				=	self:GetWeapon( self.Melee )
	local medkit			=	self:GetWeapon( "weapon_medkit" )
	
	if IsValid( medkit ) and self.CombatHealThreshold > self:Health() and medkit:Clip1() >= 25 then
		
		-- The bot will heal themself if they get too injured during combat
		self:SelectMedkit()
	
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
		
		-- If an enemy gets too close, the bot should use its melee
		if IsValid( melee ) and ( ( enemydistsqr < self.MeleeDist * self.MeleeDist and self:GetKnownCount( nil, true, -1 ) < 5 ) or !IsValid( bestWeapon ) ) then

			bestWeapon = melee
			minEquipInterval = 2.0
			
		end
		
		if IsValid( bestWeapon ) and oldBestWeapon != bestWeapon then 
			
			self.BestWeapon			= bestWeapon
			self.MinEquipInterval 	= CurTime() + minEquipInterval
			
		end
		
	end
	
end

function BOT:SelectMedkit()

	if self:HasWeapon( "weapon_medkit" ) then self.BestWeapon = self:GetWeapon( "weapon_medkit" ) end
	
end

-- This checks if the given weapon uses clips for its primary attack
function Wep:UsesClipsForAmmo1()

	return self:GetMaxClip1() != -1

end

-- This checks if the given weapon uses clips for its secondary attack
function Wep:UsesClipsForAmmo2()

	return self:GetMaxClip2() != -1

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
	if IsValid( botWeapon ) and botWeapon:GetClass() != bot.Melee and botWeapon:GetClass() != "weapon_medkit" and botWeapon:UsesPrimaryAmmo() and botWeapon:UsesClipsForAmmo1() and botWeapon:Clip1() < botWeapon:GetMaxClip1() then return end
	
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle			=	self:GetWeapon( self.Rifle )
	local shotgun		=	self:GetWeapon( self.Shotgun )
	local sniper		=	self:GetWeapon( self.Sniper )
	
	if IsValid( sniper ) and sniper:UsesPrimaryAmmo() and sniper:UsesClipsForAmmo1() and sniper:Clip1() < sniper:GetMaxClip1() then
		
		self.BestWeapon = sniper
		
	elseif IsValid( pistol ) and pistol:UsesPrimaryAmmo() and pistol:UsesClipsForAmmo1() and pistol:Clip1() < pistol:GetMaxClip1() then
		
		self.BestWeapon = pistol
		
	elseif IsValid( rifle ) and rifle:UsesPrimaryAmmo() and rifle:UsesClipsForAmmo1() and rifle:Clip1() < rifle:GetMaxClip1() then
		
		self.BestWeapon = rifle
		
	elseif IsValid( shotgun ) and shotgun:UsesPrimaryAmmo() and shotgun:UsesClipsForAmmo1() and shotgun:Clip1() < shotgun:GetMaxClip1() then
		
		self.BestWeapon = shotgun
		
	end
	
end

-- This is kind of a cheat, but the bot will only slowly recover ammo when not in combat
function BOT:RestoreAmmo()
	
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle			=	self:GetWeapon( self.Rifle )
	local shotgun		=	self:GetWeapon( self.Shotgun )
	local sniper		=	self:GetWeapon( self.Sniper )
	local pistol_ammo
	local rifle_ammo
	local shotgun_ammo
	local sniper_ammo
	
	if IsValid( pistol ) then pistol_ammo		=	self:GetAmmoCount( pistol:GetPrimaryAmmoType() ) end
	if IsValid( rifle ) then rifle_ammo		=	self:GetAmmoCount( rifle:GetPrimaryAmmoType() ) end
	if IsValid( shotgun ) then shotgun_ammo		=	self:GetAmmoCount( shotgun:GetPrimaryAmmoType() ) end
	if IsValid( sniper ) then sniper_ammo		=	self:GetAmmoCount( sniper:GetPrimaryAmmoType() ) end
	
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
		
		if BreakableList[ self:GetClass() ] then
		
			return true
			
		end
		
	end
	
	return false

end

function Ent:IsDoor()

	if (self:GetClass() == "func_door") or (self:GetClass() == "prop_door_rotating") or (self:GetClass() == "func_door_rotating") then
        
		return true
    
	end
	
	return false
	
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

-- When the bot dies, it seems to keep its weapons for some reason. This hook removes them when the bot dies.
hook.Add( "PostPlayerDeath" , "TRizzleBotPostPlayerDeath" , function( ply )

	if IsValid( ply ) and ply:IsTRizzleBot() then
	
		ply:StripWeapons()
		
	end

end)

-- When a player leaves the server, every bot "owned" by the player should leave as well
hook.Add( "PlayerDisconnected" , "TRizzleBotPlayerLeave" , function( ply )
	
	if !ply:IsTRizzleBot( true ) then 
		
		for k, bot in ipairs( player.GetAll() ) do
		
			if IsValid( bot ) and bot:IsTRizzleBot( true ) and bot.TBotOwner == ply then
			
				bot:Kick( "Owner " .. ply:Nick() .. " has left the server" )
			
			elseif IsValid( bot ) and bot:IsTRizzleBot() and bot.TBotOwner == ply then
			
				bot.TBotOwner = bot
			
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
				
				elseif IsValid( bot.GroupLeader ) then -- If the bot's owner is alive, the bot should clear its group leader and the hiding spot it was trying to goto
					
					bot.GroupLeader	= nil
					bot:ClearHidingSpot()
					
				end
				
				local threat = bot:GetPrimaryKnownThreat()
				if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
				
					if threat:IsVisibleInFOVNow() then
					
						bot:AimAtEntity( enemy, 1.0, HIGH_PRIORITY )
						
					else
					
						if bot:TBotVisible( threat:GetEntity() ) then
						
							local toThreat = threat:GetEntity():GetPos() - bot:GetPos()
							local threatRange = toThreat:Length()
							
							local s = math.sin( math.pi/6.0 )
							local Error = threatRange * s
							local imperfectAimSpot = threat:GetEntity():WorldSpaceCenter()
							imperfectAimSpot.x = imperfectAimSpot.x + math.Rand( -Error, Error )
							imperfectAimSpot.y = imperfectAimSpot.y + math.Rand( -Error, Error )
							
							bot:AimAtPos( imperfectAimSpot, 1.0, HIGH_PRIORITY )
							
						end
					
					end
					
				end
				
				local botWeapon = bot:GetActiveWeapon()
				if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) and threat:IsVisibleRecently() then
					
					bot.LastCombatTime = CurTime() -- Update combat timestamp
					
					local enemy = threat:GetEntity()
					local enemyDist = enemy:GetPos():DistToSqr( bot:GetPos() ) -- Grab the bot's current distance from their current enemy
					
					-- Should I limit how often this runs?
					local trace = util.TraceLine( { start = bot:GetShootPos(), endpos = enemy:GetHeadPos(), filter = bot, mask = MASK_SHOT } )
					
					if trace.Entity == enemy then
						
						bot.AimForHead = true
						
					else
						
						bot.AimForHead = false
						
					end
					
					if IsValid( botWeapon ) and botWeapon:IsWeapon() then
					
						if bot.FullReload and ( !botWeapon:UsesPrimaryAmmo() or !botWeapon:UsesClipsForAmmo1() or botWeapon:Clip1() >= botWeapon:GetMaxClip1() or bot:GetAmmoCount( botWeapon:GetPrimaryAmmoType() ) <= botWeapon:Clip1() or botWeapon:GetClass() != bot.Shotgun ) then bot.FullReload = false end -- Fully reloaded :)
						
						if CurTime() >= bot.ScopeInterval and botWeapon:GetClass() == bot.Sniper and bot.SniperScope and !bot:IsUsingScope() then
						
							bot:PressSecondaryAttack( 1.0 )
							bot.ScopeInterval = CurTime() + 0.4
							bot.FireWeaponInterval = CurTime() + 0.4
						
						end
						
						if CurTime() >= bot.FireWeaponInterval and !bot:IsReloading() and !bot.FullReload and botWeapon:GetClass() != "weapon_medkit" and ( botWeapon:GetClass() != bot.Melee or enemyDist <= bot.MeleeDist * bot.MeleeDist ) and bot:IsCursorOnTarget( enemy ) then
							
							bot:PressPrimaryAttack()
							
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
						
						if CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:UsesPrimaryAmmo() and botWeapon:UsesClipsForAmmo1() and botWeapon:Clip1() == 0 then
							
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
					
					bot:SelectBestWeapon( enemy )
				
				else
				
					if !bot:IsInCombat() then
					
						-- If the bot is not in combat then the bot should check if any of its teammates need healing
						bot.HealTarget = bot:TBotFindHealTarget()
						
						if IsValid( bot.HealTarget ) and bot:HasWeapon( "weapon_medkit" ) then
						
							bot:SelectMedkit()
							
							if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" then
								
								if CurTime() >= bot.FireWeaponInterval and bot.HealTarget == bot then
								
									bot:PressSecondaryAttack()
									bot.FireWeaponInterval = CurTime() + 0.5
									
								elseif CurTime() >= bot.FireWeaponInterval and bot:GetEyeTrace().Entity == bot.HealTarget then
								
									bot:PressPrimaryAttack()
									bot.FireWeaponInterval = CurTime() + 0.5
									
								end
								
								if bot.HealTarget != bot then bot:AimAtPos( bot.HealTarget:WorldSpaceCenter(), 0.1, MEDIUM_PRIORITY ) end
								
							end
							
						else
						
							bot:ReloadWeapons()
							
						end
						
						if IsValid( botWeapon ) and botWeapon:IsWeapon() then 
							
							if CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:UsesPrimaryAmmo() and botWeapon:UsesClipsForAmmo1() and botWeapon:Clip1() < botWeapon:GetMaxClip1() then
						
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
					
						if IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:UsesPrimaryAmmo() and botWeapon:UsesClipsForAmmo1() and ( botWeapon:Clip1() == 0 or ( botWeapon:GetClass() == bot.Shotgun and botWeapon:Clip1() < botWeapon:GetMaxClip1() and bot:GetKnownCount( nil, true, -1 ) <= 0 ) or ( botWeapon:Clip1() < ( botWeapon:GetMaxClip1() * 0.6 ) and #bot.EnemyList <= 0 ) ) then
						
							bot:PressReload()
							bot.ReloadInterval = CurTime() + 0.5
							
						end
						
					end
				
				end
				
				-- Here is the AI for GroupLeaders
				if IsValid( bot.GroupLeader ) then
					
					if bot:IsGroupLeader() then
					
						-- If the bot's group is being overwhelmed then they should retreat
						if !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and ( ( istbotknownentity( threat ) and IsValid( threat:GetEntity() ) and threat:IsVisibleRecently() and bot:Health() < bot.CombatHealThreshold ) or bot:GetKnownCount( nil, true, bot.DangerDist ) >= 10 ) then
					
							bot.HidingSpot = bot:FindSpot( "far", { pos = bot:GetPos(), radius = 10000, stepdown = 1000, stepup = 64, checksafe = 1, checkoccupied = 1, checklineoffire = 1 } )
							bot.HidingSpotInterval = CurTime() + 0.5
							
							if isvector( bot.HidingSpot ) then
								
								bot.HidingState = MOVE_TO_SPOT
								bot.HideReason	= RETREAT
								bot.HideTime	= 10.0
								
							end
						
						elseif !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and bot:IsSafe() and bot.NextHuntTime < CurTime() then
						
							bot.HidingSpot = bot:FindSpot( "random", { pos = bot:GetPos(), radius = math.random( 5000, 10000 ), stepdown = 1000, stepup = 64, spotType = "sniper", checksafe = 0, checkoccupied = 1, checklineoffire = 0 } )
							bot.HidingSpotInterval = CurTime() + 0.5
							
							if isvector( bot.HidingSpot ) then
								
								bot.HidingState = MOVE_TO_SPOT
								bot.HideReason	= SEARCH_AND_DESTORY
								bot.HideTime	= 30.0
								
							end
						
						end
					
					else
					
						-- If the bot needs to reload its active weapon it should find cover nearby and reload there
						if !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and istbotknownentity( threat ) and IsValid( threat:GetEntity() ) and threat:IsVisibleRecently() and IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() != bot.Melee and botWeapon:UsesPrimaryAmmo() and botWeapon:UsesClipsForAmmo1() and botWeapon:Clip1() == 0 and bot.GroupLeader:GetPos():DistToSqr( bot:GetPos() ) < bot.FollowDist * bot.FollowDist then

							bot.HidingSpot = bot:FindSpot( "near", { pos = bot:GetPos(), radius = 500, stepdown = 1000, stepup = 64, checksafe = 1, checkoccupied = 1, checklineoffire = 1 } )
							bot.HidingSpotInterval = CurTime() + 0.5
							
							if isvector( bot.HidingSpot ) then
								
								bot.HidingState = MOVE_TO_SPOT
								bot.HideReason	= RELOAD_IN_COVER
								bot.ReturnPos	= bot:GetPos()
								
							end

						end
					
					end
					
				elseif IsValid( bot.TBotOwner ) and bot.TBotOwner:Alive() then
					
					-- If the bot needs to reload its active weapon it should find cover nearby and reload there
					if !isvector( bot.HidingSpot ) and !bot:IsPathValid() and bot.HidingSpotInterval <= CurTime() and istbotknownentity( threat ) and IsValid( threat:GetEntity() ) and threat:IsVisibleRecently() and IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() != bot.Melee and botWeapon:UsesPrimaryAmmo() and botWeapon:UsesClipsForAmmo1() and botWeapon:Clip1() == 0 and bot.TBotOwner:GetPos():DistToSqr( bot:GetPos() ) < bot.FollowDist * bot.FollowDist then

						bot.HidingSpot = bot:FindSpot( "near", { pos = bot:GetPos(), radius = 500, stepdown = 1000, stepup = 64, checksafe = 1, checkoccupied = 1, checklineoffire = 1 } )
						bot.HidingSpotInterval = CurTime() + 0.5
						
						if isvector( bot.HidingSpot ) then
							
							bot.HidingState = MOVE_TO_SPOT
							bot.HideReason	= RELOAD_IN_COVER
							bot.ReturnPos	= bot:GetPos()
							
						end

					end
					
				end
				
				-- This is where the bot sets its move goals
				if isvector( bot.HidingSpot ) then
					
					if bot.HidingState == MOVE_TO_SPOT then
						
						-- When have reached our destination start the wait timer
						if bot:GetPos():DistToSqr( bot.HidingSpot ) <= 1024 then
							
							bot.HidingState = WAIT_AT_SPOT
							bot.HideTime = CurTime() + bot.HideTime
							
						-- If the bot finished reloading its active weapon it should clear its selected hiding spot!
						elseif bot.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or !botWeapon:UsesPrimaryAmmo() or !botWeapon:UsesClipsForAmmo1() or ( botWeapon:GetClass() == bot.Melee or botWeapon:Clip1() >= botWeapon:GetMaxClip1() or bot:GetAmmoCount( botWeapon:GetPrimaryAmmoType() ) <= botWeapon:Clip1() ) ) then
							
							bot:ClearHidingSpot()
							
						-- If the bot finds an enemy, it should clear its selected hiding spot
						elseif bot.HideReason == SEARCH_AND_DESTORY and bot:IsInCombat() then
						
							bot.NextHuntTime = CurTime() + 10
							bot:TBotClearPath()
							bot:ClearHidingSpot()
						
						-- If the bot has a hiding spot it should path there
						elseif !bot:IsPathValid() and bot.RepathTimer <= CurTime() and bot:GetPos():DistToSqr( bot.HidingSpot ) > 1024 then
					
							TRizzleBotPathfinderCheap( bot, bot.HidingSpot )
							bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + 0.5
							
						end
						
					elseif bot.HidingState == WAIT_AT_SPOT then
						
						-- If the bot has finished hiding, it should clear its selected hiding spot
						if ( bot.HideReason == RETREAT or bot.HideReason == SEARCH_AND_DESTORY ) and bot.HideTime <= CurTime() then
							
							bot.NextHuntTime = CurTime() + 20.0
							bot:ClearHidingSpot()
						
						-- If the bot has finished reloading its active weapon, it should clear its selected hiding spot
						elseif bot.HideReason == RELOAD_IN_COVER and ( !IsValid( botWeapon ) or !botWeapon:UsesPrimaryAmmo() or !botWeapon:UsesClipsForAmmo1() or ( botWeapon:GetClass() == bot.Melee or botWeapon:Clip1() >= botWeapon:GetMaxClip1() or bot:GetAmmoCount( botWeapon:GetPrimaryAmmoType() ) <= botWeapon:Clip1() ) ) then
						
							bot:ClearHidingSpot()
						
						-- If the bot's hiding spot is no longer safe, it should clear its selected hiding spot
						elseif !bot:IsSpotSafe( bot.HidingSpot ) then
						
							bot.NextHuntTime = CurTime() + 20.0
							bot:ClearHidingSpot()
						
						elseif !IsValid( bot:GetLastKnownArea() ) or !bot:GetLastKnownArea():HasAttributes( NAV_MESH_STAND ) then
							
							-- The bot should crouch once it reaches its selected hiding spot
							bot:PressCrouch()
						
						end
						
					end
					
					if bot.HideReason == RELOAD_IN_COVER and IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() >= bot.ReloadInterval and !bot:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:UsesPrimaryAmmo() and botWeapon:UsesClipsForAmmo1() and botWeapon:Clip1() < botWeapon:GetMaxClip1() then
					
						bot:PressReload()
						bot.ReloadInterval = CurTime() + 0.5
					
					end
					
				elseif IsValid( bot.GroupLeader ) and !bot:IsGroupLeader() then
				
					if bot:IsPathValid() and bot.GroupLeader:GetPos():DistToSqr( bot:LastSegment().Pos ) > bot.FollowDist * bot.FollowDist or !bot:IsPathValid() and bot.GroupLeader:GetPos():DistToSqr( bot:GetPos() ) > bot.FollowDist * bot.FollowDist then
						
						if bot.RepathTimer <= CurTime() then
						
							TRizzleBotPathfinderCheap( bot, bot.GroupLeader:GetPos() )
							bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + 0.5
							
						end
						
					end
					
				elseif IsValid( bot.TBotOwner ) and bot.TBotOwner:Alive() then
					
					if bot:IsPathValid() and bot.TBotOwner:GetPos():DistToSqr( bot:LastSegment().Pos ) > bot.FollowDist * bot.FollowDist or !bot:IsPathValid() and bot.TBotOwner:GetPos():DistToSqr( bot:GetPos() ) > bot.FollowDist * bot.FollowDist then
			
						if bot.RepathTimer <= CurTime() then
						
							TRizzleBotPathfinderCheap( bot, bot.TBotOwner:GetPos() )
							bot:TBotCreateNavTimer()
							bot.RepathTimer = CurTime() + 0.5
							
						end
						
					end
					
				end
				
				-- The check CNavArea we are standing on.
				if !IsValid( bot.currentArea ) or !bot.currentArea:Contains( bot:GetPos() ) then
				
					bot.currentArea			=	navmesh.GetNearestNavArea( bot:GetPos(), true, 50, true )
					
				end
				
				if IsValid( bot.currentArea ) and bot.currentArea != bot:GetLastKnownArea() then
				
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
							
						end
					
					else
					
						bot:AimAtPos( bot:ComputeEncounterSpot(), 1.0, MEDIUM_PRIORITY )
						bot.NextEncounterTime = CurTime() + 2.0
					
					end
				
				end
				
				-- Update the bot movement if they are pathing to a goal
				if bot:IsPathValid() then
			
					bot:TBotDebugWaypoints()
					bot:TBotUpdateMovement()
					bot:DoorCheck()
					bot:BreakableCheck()
					
				end
				
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
		
			victim:AddKnownEntity( attacker )
			
			if victim:IsSafe() then victim.LastCombatTime = CurTime() - 5.0 end
			
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
			
				bot:AddKnownEntity( soundTable.Entity )
			
				if bot:IsSafe() then bot.LastCombatTime = CurTime() - 5.0 end
				
			end
			
		end
		
	end
	
end)

-- Checks if the NPC is alive
function Npc:IsAlive()
	if !IsValid( self ) then return false end
	
	if self:GetNPCState() == NPC_STATE_DEAD then return false
	elseif self:GetInternalVariable( "m_lifeState" ) != 0 then return false 
	elseif self:Health() <= 0 then return false end
	
	return true
	
end

-- Checks if the target entity is the bot's enemy
function BOT:IsEnemy( target )
	if !IsValid( self ) or !IsValid( target ) or self == target then return false end
	
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

function BOT:IsAwareOf( known )

	return known:GetTimeSinceBecameKnown() >= 0.2
	
end

function BOT:GetPrimaryKnownThreat( onlyVisibleThreats )

	if #self.EnemyList == 0 then
	
		return nil
		
	end
	
	local threat = nil
	local i = 1
	
	while i <= #self.EnemyList do
	
		local firstThreat = self.EnemyList[ i ]
		
		if self:IsAwareOf( firstThreat ) and !firstThreat:IsObsolete() and self:IsEnemy( firstThreat:GetEntity() ) then
		
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
		
		if self:IsAwareOf( newThreat ) and !newThreat:IsObsolete() and self:IsEnemy( newThreat:GetEntity() ) then
		
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
	local trace = util.TraceLine( { start = self:GetShootPos(), endpos = threat:GetEntity():WorldSpaceCenter(), filter = self, mask = MASK_SHOT } )
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
	
	return false
	
end

function BOT:SelectCloserThreat( threat1, threat2 )

	local range1 = self:GetPos():DistToSqr( threat1:GetLastKnownPosition() )
	local range2 = self:GetPos():DistToSqr( threat2:GetLastKnownPosition() )
	
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
	-- NOTE: This isn't needed for sandbox so we will just pick the closest instead
	
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
	
	if !table.HasValueSequential( self.EnemyList, known ) then
	
		table.insert( self.EnemyList, known )
		
	end
	
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
	
		if !known:IsObsolete() and self:IsAwareOf( known ) then
		
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

function BOT:UpdateKnownEntities()

	local visibleNow = {}
	for k, pit in ipairs( ents.GetAll() ) do
	
		if IsValid( pit ) then 
		
			if ( pit:IsNPC() and pit:IsAlive() ) or ( pit:IsPlayer() and pit:Alive() ) or ( pit:IsNextBot() and pit:Health() > 0 ) then
				
				if self:IsEnemy( pit ) and self:IsAbleToSee( pit, true ) then
				
					table.insert( visibleNow, pit )
					
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
		
		-- NOTE: For some reason this is the same way valve does it.....
		if table.HasValueSequential( visibleNow, known:GetEntity() ) then
		
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			
		else
		
			if known:IsVisibleInFOVNow() then
			
				known:UpdateVisibilityStatus( false )
				
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
	
		if IsValid( door ) and door:IsDoor() and !door:IsDoorOpen() and door:GetPos():DistToSqr( self:GetPos() ) <= 6400 then
		
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
	
		if IsValid( breakable ) and breakable:IsBreakable() and breakable:WorldSpaceCenter():DistToSqr( self:GetPos() ) <= 6400 and self:IsAbleToSee( breakable ) then 
		
			self.Breakable = breakable
			break
			
		end
	
	end
	
end

function TRizzleBotRangeCheck( area , fromArea , ladder , bot )
	if !IsValid( area ) then return -1 end
	
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
			
		else
		
			dist = area:GetCenter():Distance( fromArea:GetCenter() )
			
		end
		
		local Height	=	fromArea:ComputeAdjacentConnectionHeightChange( area )
		local stepHeight = Either( IsValid( bot ), bot:GetStepSize(), 18 )
		-- Jumping is slower than ground movement.
		if !IsValid( ladder ) and !fromArea:IsUnderwater() and Height > stepHeight then
			
			if Height > 64 then
			
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
		--[[
		-- This will have certain cases where its not used.
		if true then
		
			-- this term causes the same bot to choose different routes over time,
			-- but keep the same route for a period in case of repaths
			local timeMod = math.floor( ( CurTime() / 10 ) + 1 )
			preference = 1.0 + 50.0 * ( 1.0 + math.cos( bot:EntIndex() * area:GetID() * timeMod ) )
			
		end]]
		
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
	
	local pathEndPosition = goal
	if IsValid( goalArea ) then
	
		pathEndPosition.z = goalArea:GetZ( pathEndPosition )
		
	else
		
		local ground = navmesh.GetGroundHeight( pathEndPosition )
		if ground then pathEndPosition.z = ground end
		
	end
	
	local pathResult, closestArea = NavAreaBuildPath( startArea, goalArea, goal, bot )
	
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
function NavAreaBuildPath( startArea, goalArea, goalPos, bot )
	
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
	
	local actualGoalPos = Either( isvector( goalPos ), goalPos, goalArea:GetCenter() )
	
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
			
			local NewCostSoFar		=	TRizzleBotRangeCheck( newArea , Current , ladder , bot )
			
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

function BOT:IsPathValid()

	return self.SegmentCount > 0
	
end

function BOT:TBotClearPath()

	self.Path = {}
	self.AvoidTimer = 0
	self.SegmentCount = 0
	self.Goal = nil
	
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


local result = Vector()
-- Checks if the bot will cross enemy line of fire when attempting to move to the entered position
function BOT:IsCrossingLineOfFire( startPos, endPos )

	for k, known in ipairs( self.EnemyList ) do
	
		if !self:IsAwareOf( known ) or known:IsObsolete() then
		
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

-- Checks if a hiding spot is already in use
function BOT:IsSpotOccupied( pos )

	local ply, distance = util.GetClosestPlayer( pos )
	
	if IsValid( ply ) and ply != self then
	
		if ply:IsTRizzleBot() and ply.HidingSpot == pos then return true -- Don't consider spots already selected by other bots
		elseif distance < 75 then return true end -- Don't consider spots if a bot or human player is already there

	end

	return false

end

-- Checks if a hiding spot is safe to use
function BOT:IsSpotSafe( hidingSpot )

	for k, known in pairs( self.EnemyList ) do
	
		if self:IsAwareOf( known ) and !known:IsObsolete() and known:GetEntity():TBotVisible( hidingSpot ) then return false end -- If one of the bot's enemies its aware of can see it the bot won't use it.
	
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
		self:TBotCreateNavTimer()
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
	tbl.stepup			= tbl.stepup			or 64
	tbl.spotType		= tbl.spotType			or "hiding"
	tbl.checkoccupied	= tbl.checkoccupied		or 1
	tbl.checksafe		= tbl.checksafe			or 1
	tbl.checklineoffire	= tbl.checklineoffire	or 1

	-- Find a bunch of areas within this distance
	local areas = navmesh.Find( tbl.pos, tbl.radius, tbl.stepdown, tbl.stepup )

	local found = {}
	
	local startArea = navmesh.GetNearestNavArea( tbl.pos )
	if !IsValid( startArea ) then
	
		return
		
	end

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
			
				continue 
			
			end
			
			table.insert( found, { vector = vec, distance = pathLength } )

		end

	end
	
	if ( !found or #found == 0 ) and !secondAttempt then
	
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
	while index < #self.Path do
		
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
					local ground = util.TraceHull( { start = pos, endpos = pos + Vector( 0, 0, -self:GetStepSize() ), mins = Vector( -halfWidth, -halfWidth, 0 ), maxs = Vector( halfWidth, halfWidth, hullHeight ), mask = MASK_PLAYERSOLID, filter = TBotTraversableFilter } )
					
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
				
					to.Pos = startDrop
					to.Type = PATH_DROP_DOWN
					
					endDrop.z = ground
					
					table.insert( self.Path, index + 1, { Pos = endDrop, Area = to.Area, How = to.How, Type = PATH_ON_GROUND } )
					self.SegmentCount = self.SegmentCount + 1
					index = index + 2
					continue
				end
				
			end
			
			index = index + 1
			
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
			
			index = index + 1
			continue
			
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
			
			index = index + 1
			continue
			
		end
		
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
	
	return navmesh.GetNearestNavArea( self:GetPos(), true, 50, true )
	
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

	if to.z - from.z > 64.1 then
	
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
	
	local result = util.TraceHull( { start = from, endpos = to, maxs = hullMax, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID } )

	return result.Fraction >= 1.0 and !result.StartSolid, result.Fraction
	
end

function BOT:IsGap( pos, forward )

	local halfWidth = 1.0
	local hullHeight = 1.0
	
	local ground = util.TraceHull( { start = pos + Vector( 0, 0, self:GetStepSize() ), endpos = pos + Vector( 0, 0, -64 ), maxs = Vector( halfWidth, halfWidth, hullHeight ), mins = Vector( -halfWidth, -halfWidth, 0 ), filter = TBotTraceFilter, mask = MASK_PLAYERSOLID } )
	
	--debugoverlay.SweptBox( pos + Vector( 0, 0, self:GetStepSize() ), pos + Vector( 0, 0, -64 ), Vector( -halfWidth, -halfWidth, 0 ), Vector( halfWidth, halfWidth, hullHeight ), Angle(), 5.0, Color( 255, 0, 0 ) )
	
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

	if self:IsPathValid() then
		
		if self.Goal then
			
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
				
				-- Is 10 too small of a goal tolerance?
				if ( self.Goal.Type == PATH_ON_GROUND or self.Goal.Type == PATH_JUMP_OVER_GAP ) and toGoal:AsVector2D():IsLengthLessThan( 10 ) then
					
					if self.Goal.Type == PATH_JUMP_OVER_GAP then
					
						nextSegment = self:NextSegment( self.Goal )
						if nextSegment then
						
							self:AimAtPos( nextSegment.Pos + self:GetCurrentViewOffset(), 0.1, MAXIMUM_PRIORITY )
							
						end
				
						self:PressJump()
						
					end
					
					return true
					
				end
				
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
				
				if IsValid( s.Ladder ) and s.How == GO_LADDER_DOWN and s.Ladder:GetLength() > 64 then
				
					local destinationHeightDelta = s.Pos.z - self:GetPos().z
					if math.abs( destinationHeightDelta ) < 64 then
					
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
			
			if dot < -0.9 then
			
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
	local goal = self:GetPos() + moveLength * left:Cross( vector_up ):Normalize()
	
	local trace = util.TraceHull( { start = self:GetPos(), endpos = goal, maxs = standMaxs, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID } )
	
	if trace.Fraction >= 1.0 and !trace.StartSolid then
	
		return
		
	end
	
	local crouchMaxs = Vector( halfSize, halfSize, self:GetCrouchHullHeight() )
	local trace = util.TraceHull( { start = self:GetPos(), endpos = goal, maxs = crouchMaxs, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID } )
	
	if trace.Fraction >= 1.0 and !trace.StartSolid then
	
		self:PressCrouch()
		
	end
	
end

function BOT:Approach( pos )
	
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
			
			if self.WiggleTimer <= CurTime() then
				
				if side <= -0.25 then
				
					self:PressLeft()
					
				elseif side >= 0.25 then
					
					self:PressRight()
					
				end
				
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
	
	if self:GetPos().z <= self.LadderInfo:GetBottom().z - 64 then
	
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
	
	if self:GetPos().z <= self.LadderInfo:GetBottom().z + 64 then
	
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
		return false
		
	end
	
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
			self:TraverseLadder()
			return
			
		end
		
		if self:CheckProgress() == false then
		
			return
			
		end
		
		-- TODO: Is this better than forcing the bot to jump?
		if self:OnGround() and !self:Is_On_Ladder() and ( !IsValid( self.Goal.Area ) or !self.Goal.Area:HasAttributes( NAV_MESH_STAIRS ) ) and self.Goal.Type == PATH_JUMP_OVER_GAP then
			--[[local SmartJump		=	util.TraceLine({
				
				start			=	self:GetPos(),
				endpos			=	self:GetPos() + Vector( 0 , 0 , -16 ),
				filter			=	self,
				mask			=	MASK_SOLID,
				collisiongroup	=	COLLISION_GROUP_DEBRIS
				
			})
			
			-- This tells the bot to jump if it detects a gap in the ground
			if SmartJump.Fraction >= 1.0 and !SmartJump.StartSolid then
				
				self:PressJump()

			end]]
			
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
			
			--[[if !jumped then
			
				local lookAheadRange = 30
				local stepAhead = self:GetPos() + lookAheadRange * aheadRay
				stepAhead.z = stepAhead.z + HalfHumanHeight.z
				local ground = navmesh.GetGroundHeight( stepAhead )
				if ground and ( ground - self:GetPos().z ) < -64 then
				
					self:PressJump()
					jumped = true
					
				end
				
			end]]
			
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
			
		end
		
		if IsValid( self.Goal.Area ) then
		
			local CurrentArea = self.Goal.Area
			
			if !CurrentArea:HasAttributes( NAV_MESH_STAIRS ) and ( CurrentArea:HasAttributes( NAV_MESH_JUMP ) or ( self.Goal.Type == PATH_CLIMB_UP and self:GetPos():DistToSqr( self.Goal.Pos ) <= 2500 ) ) then
			
				self:PressJump()
			
			elseif CurrentArea:HasAttributes( NAV_MESH_CROUCH ) and self.Goal.Type != PATH_CLIMB_UP and self.Goal.Type != PATH_JUMP_OVER_GAP and self:GetPos():DistToSqr( self.Goal.Pos ) <= 2500 and !self:ShouldJump( self:GetPos(), self.Goal.Pos ) then
			
				self:PressCrouch()
			
			end
			
			if CurrentArea:HasAttributes( NAV_MESH_WALK ) then
			
				self:PressWalk()
				
			elseif CurrentArea:HasAttributes( NAV_MESH_RUN ) then
			
				self:PressRun()
				
			end
			
		end
		
		if self.Goal.Type == PATH_CLIMB_UP and self:GetPos():DistToSqr( self.Goal.Pos ) <= 2500 then
		
			self:PressJump()
			
		end
		
		local goalPos = Vector( self.Goal.Pos )
		local forward = goalPos - self:GetPos()
		forward.z = 0.0
		forward:Normalize()
		
		if self.Goal.Type != PATH_CLIMB_UP then
			
			goalPos = self:TBotAvoid( goalPos, forward, Vector( -forward.y, forward.x, 0 ) )
			
		end
		
		if self:IsOnGround() then
		
			self:FaceTowards( goalPos )
			
		end
		
		self:Approach( goalPos )
		
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

function BOT:TBotAvoid( goalPos, forward, left )

	if self.AvoidTimer > CurTime() then
	
		return goalPos
		
	end

	self.AvoidTimer = CurTime() + 0.5
	local adjustedGoal = goalPos
	
	if !self:IsOnGround() or ( IsValid( self:GetLastKnownArea() ) and self:GetLastKnownArea():HasAttributes( NAV_MESH_PRECISE ) ) then return adjustedGoal end
	
	local size = self:GetHullWidth() / 4
	local offset = size + 2
	local range = Either( self:KeyDown( IN_SPEED ), 50, 30 )
	local door = nil
	
	local hullMin = Vector( -size, -size, self:GetStepSize() + 0.1 )
	local hullMax = Vector( size, size, self:GetCrouchHullHeight() )
	--local nextStepHullMin = Vector( -size, -size, 2.0 * self:GetStepSize() + 0.1 )
	
	local leftFrom = self:GetPos() + offset * left
	local leftTo = leftFrom + range * forward
	local isLeftClear = true
	local leftAvoid = 0.0
	
	local result = util.TraceHull( { start = leftFrom, endpos = leftTo, maxs = hullMax, mins = hullMin, filter = self, mask = MASK_PLAYERSOLID } )
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
	
	result = util.TraceHull( { start = rightFrom, endpos = rightTo, maxs = hullMax, mins = hullMin, filter = self, mask = MASK_PLAYERSOLID } )
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


function Zone:ComputePortal( TargetArea, dir )
	if !IsValid( TargetArea ) or !IsValid( self ) then return end
	
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
	if !IsValid( TargetArea ) or !IsValid( self ) then return end
	
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

function BOT:Is_On_Ladder()
	
	if self:GetMoveType() == MOVETYPE_LADDER then
		
		return true
	end
	
	return false
end

function BOT:ComputeLadderEndpoint( ladder, isAscending )
	
	local result
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

	result = util.TraceLine( { start = from, endpos = ladder:GetBottom(), mask = MASK_PLAYERSOLID_BRUSHONLY } )

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

-- Draws the hiding spots on debug overlay. This includes sniper/exposed spots too!
function ShowAllHidingSpots()

	for _, area in ipairs( navmesh.GetAllNavAreas() ) do

		area:DrawSpots()

	end

end
