-- Grab the needed metatables
local BOT			=	FindMetaTable( "Player" )
local Ent			=	FindMetaTable( "Entity" )
local Npc			=	FindMetaTable( "NPC" )
local Zone			=	FindMetaTable( "CNavArea" )
local Lad			=	FindMetaTable( "CNavLadder" )

-- Setup lookatpriority level variables
local LOW_PRIORITY			=	0
local MEDIUM_PRIORITY		=	1
local HIGH_PRIORITY			=	2
local MAXIMUM_PRIORITY		=	3

-- Setup bot hiding states
local FINISHED_HIDING		=	0
local MOVE_TO_SPOT			=	1
local WAIT_AT_SPOT			=	2

-- Setup bot think variables
local BotUpdateSkipCount	=	2 -- This is how many upkeep events must be skipped before another update event can be run
local BotUpdateInterval		=	0

-- Setup vectors so they don't have to be created later
local HalfHumanHeight		=	Vector( 0, 0, 35.5 )

-- Setup net messages
util.AddNetworkString( "TRizzleBotFlashlight" )

function TBotCreate( ply , cmd , args ) -- This code defines stats of the bot when it is created.  
	if !args[ 1 ] then error( "[WARNING] Please give a name for the bot!" ) end 
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
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.FollowDist = followdist
			break
		end
		
	end

end

function TBotSetDangerDist( ply, cmd, args ) -- Command for changing the bots "Danger" distance to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local dangerdist = tonumber( args[ 2 ] ) or 300
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.DangerDist = dangerdist
			break
		end
		
	end

end

function TBotSetMelee( ply, cmd, args ) -- Command for changing the bots melee to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local melee = args[ 2 ] or "weapon_crowbar"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.Melee = melee
			break
		end
		
	end

end

function TBotSetPistol( ply, cmd, args ) -- Command for changing the bots pistol to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local pistol = args[ 2 ] or "weapon_pistol"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.Pistol = pistol
			break
		end
		
	end

end

function TBotSetShotgun( ply, cmd, args ) -- Command for changing the bots shotgun to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local shotgun = args[ 2 ] or "weapon_shotgun"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.Shotgun = shotgun
			break
		end
		
	end

end

function TBotSetRifle( ply, cmd, args ) -- Command for changing the bots rifle to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] or "weapon_smg1"
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.Rifle = rifle
			break
		end
		
	end

end

function TBotSetSniper( ply, cmd, args ) -- Command for changing the bots sniper to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] or "weapon_crossbow"
	local hasScope = args[ 3 ] or 1
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.Sniper = rifle
			if hasScope == 0 then bot.SniperScope = false
			else bot.SniperScope = true end
			break
		end
		
	end

end

function TBotSetMeleeDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local meleedist = tonumber( args[ 2 ] ) or 80
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.MeleeDist = meleedist
			break
		end
		
	end

end

function TBotSetPistolDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local pistoldist = tonumber( args[ 2 ] ) or 1300
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.PistolDist = pistoldist
			break
		end
		
	end

end

function TBotSetShotgunDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local shotgundist = tonumber( args[ 2 ] ) or 300
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.ShotgunDist = shotgundist
			break
		end
		
	end

end

function TBotSetRifleDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifledist = tonumber( args[ 2 ] ) or 900
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot.RifleDist = rifledist
			break
		end
		
	end

end

function TBotSetHealThreshold( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local healthreshold = tonumber( args[ 2 ] ) or 100
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			if healthreshold > bot:GetMaxHealth() then healthreshold = bot:GetMaxHealth() end
			bot.HealThreshold = healthreshold
			break
		end
		
	end

end

function TBotSetCombatHealThreshold( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local combathealthreshold = tonumber( args[ 2 ] ) or 25
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			if combathealthreshold > bot:GetMaxHealth() then combathealthreshold = bot:GetMaxHealth() end
			bot.CombatHealThreshold = combathealthreshold
			break
		end
		
	end

end

function TBotSetPlayerModel( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local playermodel = args[ 2 ] or "kleiner"
	
	playermodel = player_manager.TranslatePlayerModel( playermodel )
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			bot:SetModel( playermodel )
			bot.PlayerModel = playermodel
			break
		end
		
	end

end

function TBotSpawnWithPreferredWeapons( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local spawnwithweapons = tonumber( args[ 2 ] ) or 1
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if bot:IsTRizzleBot() and bot:Nick() == targetbot and bot.TBotOwner == ply then
			
			if spawnwithweapons == 0 then bot.SpawnWithWeapons = false
			else bot.SpawnWithWeapons = true end
			break
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
concommand.Add( "TBotSetPlayerModel" , TBotSetPlayerModel , nil , "Changes the bot playermodel to the model shortname specified. If only the bot is specified or the model shortname given is invalid the bot's player model will revert back to the default." )
concommand.Add( "TBotSetDefault" , TBotSetDefault , nil , "Set the specified bot's settings back to the default." )

-------------------------------------------------------------------|



function BOT:TBotResetAI()
	
	self.buttonFlags				=	0 -- These are the buttons the bot is going to press.
	self.forwardMovement				=	0 -- This tells the bot to move either forward or backwards.
	self.strafeMovement				=	0 -- This tells the bot to move left or right.
	self.GroupLeader				=	nil -- If the bot's owner is dead, this bot will take charge in combat and leads other bots with the same "owner". 
	self.Enemy					=	nil -- This is the bot's current enemy.
	self.EnemyList					=	{} -- This is the list of enemies the bot knows about.
	self.NumVisibleEnemies				=	0 -- This is how many enemies are on the known enemy list that the bot can currently see.
	self.EnemyListAverageDistSqr			=	0 -- This is average distance of every enemy on the known enemy list.
	self.AimForHead					=	false -- Should the bot aim for the head?
	self.TimeInCombat				=	0 -- This is how long the bot has been in combat.
	self.LastCombatTime				=	0 -- This is the last time the bot was in combat.
	self.BestWeapon					=	nil -- This is the weapon the bot currently wants to equip.
	self.MinEquipInterval				=	0 -- Throttles how often equipping is allowed.
	self.HealTarget					=	nil -- This is the player the bot is trying to heal.
	self.TRizzleBotBlindTime			=	0 -- This is how long the bot should be blind
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
	self.ShouldReset				=	false -- This tells the bot to clear all buttons and movement.
	self.FullReload					=	false -- This tells the bot not to press its attack button until its current weapon is fully reloaded.
	self.FireWeaponInterval				=	0 -- Limits how often the bot presses its attack button.
	self.ReloadInterval				=	0 -- Limits how often the bot can press its reload button.
	self.ScopeInterval				=	0 -- Limits how often the bot can press its scope button.
	self.Light					=	false -- Tells the bot if it should have its flashlight on or off.
	self.LookTarget					=	false -- This is the position the bot is currently trying to look at.
	self.LookTargetTime				=	0 -- This is how long the bot will look at the position the bot is currently trying to look at.
	self.LookTargetPriority				=	LOW_PRIORITY -- This is how important the position the bot is currently trying to look at is.
	self.EncounterSpot				=	nil -- This is the bots current encounter spot.
	self.EncounterSpotLookTime			=	0 -- This is how long the bot should look at said encounter spot.
	self.NextEncounterTime				=	0 -- This is the next time the bot is allowed to look at another encounter spot.
	self.HidingSpot					=	nil -- This is the current hiding/sniper spot the bot wants to goto.
	self.HidingState				=	FINISHED_HIDING -- This is the current hiding state the bot is currently in.
	self.HideTime					=	0 -- This is how long the bot will stay at its current hiding spot.
	self.ReturnPos					=	nil -- This is the spot the will back to after hiding, "Example, If the bot went into cover to reload."
	self.Goal					=	nil -- The vector goal we want to get to.
	self.NavmeshNodes				=	{} -- The nodes given to us by the pathfinder.
	self.Path					=	nil -- The nodes converted into waypoints by our visiblilty checking.
	self.PathTime					=	CurTime() + 0.5 -- This will limit how often the path gets recreated.
	
	--self:TBotCreateThinking() -- Start our AI
	
end


hook.Add( "StartCommand" , "TRizzleBotAIHook" , function( bot , cmd )
	if !IsValid( bot ) or !bot:Alive() or !bot:IsTRizzleBot() then return end
	-- Make sure we can control this bot and its not a player.
	
	bot:ResetCommand( cmd )
	bot:UpdateAim()
	bot:TBotUpdateMovement( cmd )
	cmd:SetButtons( bot.buttonFlags )
	
	if IsValid( bot.BestWeapon ) and bot.BestWeapon:IsWeapon() and bot:GetActiveWeapon() != bot.BestWeapon then 
	
		cmd:SelectWeapon( bot.BestWeapon )
		
	end
	
end)

function BOT:ResetCommand( cmd )
	if !self.ShouldReset then return end

	cmd:ClearButtons() -- Clear the bots buttons. Shooting, Running , jumping etc...
	cmd:ClearMovement() -- For when the bot is moving around.
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
	self.forwardMovement		= forwardmovement
	self.strafeMovement		= strafemovement
	self.ShouldReset		= false

end

function BOT:HandleButtons()

	local CanRun		=	true
	local ShouldJump	=	false
	local ShouldCrouch	=	false
	local ShouldRun		=	false
	local ShouldWalk	=	false
	
	if IsValid( self.currentArea ) then -- If there is no nav_mesh this will not run to prevent the addon from spamming errors
		
		if self:IsOnGround() and self.currentArea:HasAttributes( NAV_MESH_JUMP ) then
			
			ShouldJump		=	true
			
		end
		
		if self.currentArea:HasAttributes( NAV_MESH_CROUCH ) then
			
			ShouldCrouch	=	true
			
		end
		
		if self.currentArea:HasAttributes( NAV_MESH_RUN ) then
			
			ShouldRun		=	true
			ShouldWalk		=	false
			
		end
		
		if self.currentArea:HasAttributes( NAV_MESH_WALK ) then
			
			CanRun			=	false
			ShouldWalk		=	true
			
		end
		
		if self.currentArea:HasAttributes( NAV_MESH_STAIRS ) then -- The bot shouldn't jump while on stairs
		
			ShouldJump		=	false
		
		end
		
	end
	
	-- Run if we are too far from our owner or the navmesh tells us to
	if CanRun and self:GetSuitPower() > 20 then 
		
		if ShouldRun then
		
			self:PressRun()
			
		elseif IsValid( self.TBotOwner ) and self.TBotOwner:Alive() and (self.TBotOwner:GetPos() - self:GetPos()):LengthSqr() > self.DangerDist * self.DangerDist then
		
			self:PressRun()
		
		elseif IsValid( self.GroupLeader ) and self.GroupLeader:Alive() and (self.GroupLeader:GetPos() - self:GetPos()):LengthSqr() > self.DangerDist * self.DangerDist then
		
			self:PressRun()
		
		end
	
	end
	
	-- Walk if the navmesh tells us to
	if ShouldWalk then -- I might make the bot walk if near its owner
		
		self:PressWalk()
	
	end
	
	if ShouldJump then 
	
		self:PressJump()
		
	elseif ShouldCrouch or ( !self:IsOnGround() and self:WaterLevel() < 2 ) then 
	
		self:PressCrouch( 0.3 )
		
	end
	
	if self:Is_On_Ladder() then
		
		self:PressForward()
		
	end
	
	local door = self:GetEyeTrace().Entity
	
	if self.ShouldUse and IsValid( door ) and door:IsDoor() and !door:IsDoorOpen() and (door:GetPos() - self:GetPos()):LengthSqr() < 6400 then 
	
		self:PressUse()
		
		self.ShouldUse = false 
		
	end
	
end

function BOT:PressPrimaryAttack( holdTime )
	if self.HoldAttack > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_ATTACK )
	self.HoldAttack = CurTime() + holdTime

end

function BOT:PressSecondaryAttack( holdTime )
	if self.HoldAttack2 > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_ATTACK2 )
	self.HoldAttack2 = CurTime() + holdTime

end

function BOT:PressReload( holdTime )
	if self.HoldReload > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_RELOAD )
	self.HoldReload = CurTime() + holdTime

end

function BOT:PressForward( holdTime )
	if self.HoldForward > CurTime() then return end
	holdTime = holdTime or 0.1
	
	self.forwardMovement = self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_FORWARD )
	self.HoldForward = CurTime() + holdTime

end

function BOT:PressBack( holdTime )
	if self.HoldBack > CurTime() then return end
	holdTime = holdTime or 0.1
	
	self.forwardMovement = -self:GetRunSpeed()
	
	self.buttonFlags = bit.bor( self.buttonFlags, IN_BACK )
	self.HoldBack = CurTime() + holdTime

end

function BOT:PressLeft( holdTime )
	if self.HoldLeft > CurTime() then return end
	holdTime = holdTime or 0.1
	
	self.strafeMovement = -self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_MOVELEFT )
	self.HoldLeft = CurTime() + holdTime

end

function BOT:PressRight( holdTime )
	if self.HoldRight > CurTime() then return end
	holdTime = holdTime or 0.1
	
	self.strafeMovement = self:GetRunSpeed()

	self.buttonFlags = bit.bor( self.buttonFlags, IN_MOVERIGHT )
	self.HoldRight = CurTime() + holdTime

end

function BOT:PressRun( holdTime )
	if self.HoldRun > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_SPEED )
	self.HoldRun = CurTime() + holdTime

end

function BOT:PressWalk( holdTime )
	if self.HoldWalk > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_WALK )
	self.HoldWalk = CurTime() + holdTime

end

function BOT:PressJump( holdTime )
	if self.NextJump > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_JUMP )
	self.HoldJump = CurTime() + holdTime
	self.NextJump = CurTime() + holdTime + 0.5 -- This cooldown is to prevent the bot from pressing and holding its jump button

end

function BOT:PressCrouch( holdTime )
	if self.HoldCrouch > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_DUCK )
	self.HoldCrouch = CurTime() + holdTime

end

function BOT:PressUse( holdTime )
	if self.HoldUse > CurTime() then return end
	holdTime = holdTime or 0.1

	self.buttonFlags = bit.bor( self.buttonFlags, IN_USE )
	self.HoldUse = CurTime() + holdTime

end

net.Receive( "TRizzleBotFlashlight", function( _, ply) 

	local tab = net.ReadTable()
	if !istable( tab ) or table.IsEmpty( tab ) then return end
	
	for bot, light in pairs( tab ) do
	
		light = Vector(math.Round(light.x, 2), math.Round(light.y, 2), math.Round(light.z, 2))
		
		bot.Light = light:IsZero() -- Vector( 0, 0, 0 )
		
	end
end)

-- Has the bot recently seen an enemy
function BOT:IsInCombat()

	if IsValid( self.Enemy ) then
	
		return true
		
	end
	
	return self.LastCombatTime > CurTime()
	
end

-- Has the bot not seen any enemies recently
function BOT:IsSafe()

	if IsValid( self.Enemy ) then
	
		return false
		
	end
	
	return self.LastCombatTime + 10.0 < CurTime()
	
end

-- This where the bot updates its current aim angles
function BOT:UpdateAim()
	if !IsValid( self.Enemy ) and ( !isvector( self.EncounterSpot ) or self.EncounterSpotLookTime < CurTime() ) and ( !isvector( self.LookTarget ) or self.LookTargetTime < CurTime() ) then return end
	
	local currentAngles = self:EyeAngles() + self:GetViewPunchAngles()
	local angles = currentAngles -- This is a backup just incase
	local lerp = math.Clamp( FrameTime() * math.random(8, 10), 0, 1 ) -- I clamp the value so the bot doesn't aim past where it is trying to look at. Is math.random at a good number?
	
	-- Turn and face our enemy if we have one.
	if !self:IsTRizzleBotBlind() and IsValid( self.Enemy ) then
		
		local AimPos = nil
		
		-- Turn and face our enemy!
		if self.AimForHead and !self:IsActiveWeaponRecoilHigh() then
		
			-- Can we aim at the enemy's head?
			AimPos = self.Enemy:EyePos()
		
		else
		
			-- If we can't aim at our enemy's head aim at the center of their body instead.
			AimPos = self.Enemy:WorldSpaceCenter()
		
		end
		
		local targetPos = ( AimPos - self:GetShootPos() ):GetNormalized()
		
		angles = LerpAngle( lerp, currentAngles, targetPos:Angle() )
		
	-- The bot will only look at encounter spots if its current look at priority is set to low
	elseif !self:IsTRizzleBotBlind() and ( self.LookTargetPriority <= LOW_PRIORITY or self.LookTargetTime < CurTime() ) and isvector( self.EncounterSpot ) and self.EncounterSpotLookTime > CurTime() then
	
		local targetPos = ( self.EncounterSpot - self:GetShootPos() ):GetNormalized()
		
		angles = LerpAngle( lerp, currentAngles, targetPos:Angle() )
	
	-- The bot will look at its current look target
	elseif isvector( self.LookTarget ) and self.LookTargetTime > CurTime() then
	
		local targetPos = ( self.LookTarget - self:GetShootPos() ):GetNormalized()
		
		angles = LerpAngle( lerp, currentAngles, targetPos:Angle() )

	end
	
	-- back out "punch angle"
	angles = angles - self:GetViewPunchAngles()
	
	self:SetEyeAngles( angles )

end

function BOT:AimAtPos( Pos, Time, Priority )
	if !isvector( Pos ) or Time < CurTime() or ( self.LookTargetPriority > Priority and CurTime() < self.LookTargetTime ) then return end
	
	self.LookTarget				=	Pos
	self.LookTargetTime			=	Time
	self.LookTargetPriority		=	Priority
	
end

function BOT:SetEncounterLookAt( Pos, Time )
	if !isvector( Pos ) or Time < CurTime() and self.NextEncounterTime < CurTime() then return end 
	
	self.EncounterSpot			=	Pos
	self.EncounterSpotLookTime	=	Time
	self.NextEncounterTime		=	Time + 2.0

end

-- Checks if the bot is currently using the scope of their active weapon
function BOT:IsUsingScope()
	
	return self:GetFOV() < self:GetDefaultFOV()
	
end

-- Grabs the bot's default FOV
function BOT:GetDefaultFOV()

	return self:GetInternalVariable( "m_iDefaultFOV" )

end

-- Grabs the last time the bot died
function BOT:GetDeathTimestamp()
	
	return -self:GetInternalVariable( "m_flDeathTime" )

end

-- This function checks if the player is a TRizzle Bot.
function BOT:IsTRizzleBot( onlyRealBots )
	onlyRealBots = onlyRealBots or false
	
	if onlyRealBots and self:IsBot() and self.TRizzleBot then
		return true
	end
	
	return !onlyRealBots and self.TRizzleBot
	
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
	
	pos = targetpos - pos
	local diff = lookdir:Dot(pos)
	
	if diff < 0 then return false end
	if self:IsHiddenByFog( pos:Length() ) then return false end
	
	local length = pos:LengthSqr()
	return diff * diff > length * fov * fov
end

-- This filter will ignore Players, NPCS, and NextBots
function TBotTraceFilter( ent )
	
	if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end
	
	return true
	
end

-- Checks if the current position or entity can be seen by the target entity
function Ent:TBotVisible( pos )
	
	if IsValid( pos ) and IsEntity( pos ) then
		
		local trace = util.TraceLine( { start = self:EyePos(), endpos = pos:WorldSpaceCenter(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
	
		if trace.Fraction >= 1.0 or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true

		end
		
		local trace2 = util.TraceLine( { start = self:EyePos(), endpos = pos:EyePos(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
	
		if trace2.Fraction >= 1.0 or ( pos:IsPlayer() and trace2.Entity == pos:GetVehicle() ) then
			
			return true
			
		end
		
	elseif isvector( pos ) then
		
		local trace = util.TraceLine( { start = self:EyePos(), endpos = pos, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS } )
		
		return trace.Fraction >= 1.0
		
	end
	
	return false
	
end

-- This checks if the entered position in the bot's LOS
function BOT:IsAbleToSee( pos )
	if self:IsTRizzleBotBlind() then return false end

	local fov = math.cos(0.5 * self:GetFOV() * math.pi / 180) -- I grab the bot's current FOV

	if IsValid( pos ) and IsEntity( pos ) then
		-- we must check eyepos and worldspacecenter
		-- maybe in the future add more points

		if self:PointWithinViewAngle(self:GetShootPos(), pos:WorldSpaceCenter(), self:GetAimVector(), fov) then
			
			return true
			
		end
		
		return self:PointWithinViewAngle(self:GetShootPos(), pos:EyePos(), self:GetAimVector(), fov)

	elseif isvector( pos ) then
	
		return self:PointWithinViewAngle(self:GetShootPos(), pos, self:GetAimVector(), fov)
		
	end
	
	return false
end

-- Blinds the bot for a specified amount of time
function BOT:TBotBlind( time )
	if !IsValid( self ) or !self:Alive() or !self:IsTRizzleBot() or time < ( self.TRizzleBotBlindTime - CurTime() ) then return end
	
	self.TRizzleBotBlindTime = CurTime() + time
	self:AimAtPos( self:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward(), CurTime() + 0.5, MAXIMUM_PRIORITY ) -- Make the bot fling its aim in a random direction upon becoming blind
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

	local bestDist = 100000 * 100000
	local bestTrigger = nil

	for k, fogTrigger in ipairs( ents.FindByClass( "trigger_fog" ) ) do
	
		if IsValid( fogTrigger ) then
		
			local dist = self:WorldSpaceCenter():DistToSqr( fogTrigger:WorldSpaceCenter() )
			if dist < bestDist then
				bestDist = dist
				bestTrigger = fogTrigger
			end
		end
	end
	
	return bestTrigger
end

-- This will check if the bot's cursor is close the enemy the bot is fighting
function BOT:PointWithinCursor( targetpos )
	
	local pos = targetpos - self:GetShootPos()
	local diff = self:GetAimVector():Dot( pos )
	if diff < 0 then return false end
	
	local EntWidth = self.Enemy:BoundingRadius() * 0.5
	local fov = math.cos( math.atan( EntWidth / pos:Length() ) )
	
	local length = pos:LengthSqr()
	if diff * diff <= length * fov * fov then return false end
	
	-- This checks makes sure the bot won't attempt to shoot if the bullet will possibly hit a player
	-- This will not activate if the bot's current enemy is a player and the trace hits them
	local ply = self:GetEyeTrace().Entity
	if IsValid( ply ) and ply:IsPlayer() and ply != self.Enemy then return false end
	
	-- This check makes sure the bot won't attempt to shoot if the bullet wont hit its target
	local trace = util.TraceLine( { start = self:GetShootPos(), endpos = targetpos, filter = self, mask = MASK_SHOT } )
	return trace.Entity == self.Enemy or trace.Fraction >= 1.0

end

function BOT:IsCursorOnTarget()

	if IsValid( self.Enemy ) then
		-- we must check eyepos and worldspacecenter
		-- maybe in the future add more points

		if self:PointWithinCursor( self.Enemy:WorldSpaceCenter() ) then
			return true
		end

		return self:PointWithinCursor( self.Enemy:EyePos() )
	
	end
	
	return false
end

function BOT:SelectBestWeapon()
	if self.MinEquipInterval > CurTime() then return end
	
	-- This will select the best weapon based on the bot's current distance from its enemy
	local enemydistsqr	=	(self.Enemy:GetPos() - self:GetPos()):LengthSqr() -- Only compute this once, there is no point in recomputing it multiple times as doing so is a waste of computer resources
	local oldBestWeapon 	= 	self.BestWeapon
	local minEquipInterval	=	0
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle		=	self:GetWeapon( self.Rifle )
	local shotgun		=	self:GetWeapon( self.Shotgun )
	local sniper		=	self:GetWeapon( self.Sniper )
	local melee		=	self:GetWeapon( self.Melee )
	
	if self:HasWeapon( "weapon_medkit" ) and self.CombatHealThreshold > self:Health() then
		
		-- The bot will heal themself if they get too injured during combat
		self:SelectMedkit()
		return
	else
		-- I use multiple if statements instead of elseifs
		if IsValid( sniper ) and sniper:HasAmmo() then
			
			-- If an enemy is very far away, the bot should use its sniper
			self.BestWeapon = sniper
			minEquipInterval = 5.0
		end
		
		if IsValid( pistol ) and pistol:HasAmmo() and ( enemydistsqr < self.PistolDist * self.PistolDist or !IsValid( bestWeapon ) ) then
			
			-- If an enemy is far the bot, the bot should use its pistol
			self.BestWeapon = pistol
			minEquipInterval = 5.0
		end
		
		if IsValid( rifle ) and rifle:HasAmmo() and ( enemydistsqr < self.RifleDist * self.RifleDist or !IsValid( bestWeapon ) ) then
		
			-- If an enemy gets too far but is still close, the bot should use its rifle
			self.BestWeapon = rifle
			minEquipInterval = 5.0
		end
		
		if IsValid( shotgun ) and shotgun:HasAmmo() and ( enemydistsqr < self.ShotgunDist * self.ShotgunDist or !IsValid( bestWeapon ) ) then
			
			-- If an enemy gets close, the bot should use its shotgun
			self.BestWeapon = shotgun
			minEquipInterval = 5.0
		end
		
		if IsValid( melee ) and ( enemydistsqr < self.MeleeDist * self.MeleeDist or !IsValid( bestWeapon ) ) then

			-- If an enemy gets too close, the bot should use its melee
			self.BestWeapon = melee
			minEquipInterval = 2.0
		end
		
		if IsValid( bestWeapon ) and oldBestWeapon != bestWeapon then 
			
			self.MinEquipInterval = CurTime() + minEquipInterval
			
		end
		
	end
	
end

function BOT:SelectMedkit()

	if self:HasWeapon( "weapon_medkit" ) then self.BestWeapon = self:GetWeapon( "weapon_medkit" ) end
	
end

function BOT:ReloadWeapons()
	
	-- The bot should reload weapons that need to be reloaded
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle		=	self:GetWeapon( self.Rifle )
	local shotgun		=	self:GetWeapon( self.Shotgun )
	local sniper		=	self:GetWeapon( self.Sniper )
	
	if IsValid( sniper ) and sniper:Clip1() < sniper:GetMaxClip1() then
		
		self.BestWeapon = sniper
		
	elseif IsValid( pistol ) and pistol:Clip1() < pistol:GetMaxClip1() then
		
		self.BestWeapon = pistol
		
	elseif IsValid( rifle ) and rifle:Clip1() < rifle:GetMaxClip1() then
		
		self.BestWeapon = rifle
		
	elseif IsValid( shotgun ) and shotgun:Clip1() < shotgun:GetMaxClip1() then
		
		self.BestWeapon = shotgun
		
	end
	
end

function BOT:RestoreAmmo()
	
	-- This is kind of a cheat, but the bot will only slowly recover ammo when not in combat
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle		=	self:GetWeapon( self.Rifle )
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
	
	if isnumber( pistol_ammo ) and pistol_ammo < ( pistol:GetMaxClip1() * 6 ) then
		
		self:GiveAmmo( 1, pistol:GetPrimaryAmmoType(), true )
		
	end
	
	if isnumber( rifle_ammo ) and rifle_ammo < ( rifle:GetMaxClip1() * 6 ) then
		
		self:GiveAmmo( 1, rifle:GetPrimaryAmmoType(), true )
		
	end
	
	if isnumber( shotgun_ammo ) and shotgun_ammo < ( shotgun:GetMaxClip1() * 6 ) then
		
		self:GiveAmmo( 1, shotgun:GetPrimaryAmmoType(), true )
		
	end
	
	if isnumber( sniper_ammo ) and sniper_ammo < ( sniper:GetMaxClip1() * 6 ) then
		
		self:GiveAmmo( 1, sniper:GetPrimaryAmmoType(), true )
		
	end
	
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

-- When a player leaves the server, every bot "owned" by the player should leave as well
hook.Add( "PlayerDisconnected" , "TRizzleBotPlayerLeave" , function( ply )
	
	if !ply:IsTRizzleBot( true ) then 
		
		for k, bot in ipairs( player.GetAll() ) do
		
			if IsValid( bot ) and bot:IsTRizzleBot( true ) and bot.TBotOwner == ply then
			
				bot:Kick( "Owner " .. ply:Nick() .. " has left the server" )
			
			end
		end
		
	end
	
end)

-- This is for certain functions that effect every bot with one call.
hook.Add( "Think" , "TRizzleBotThink" , function()
	
	BotUpdateInterval = ( BotUpdateSkipCount + 1 ) * FrameTime()
	--local startTime = SysTime()
	--ShowAllHidingSpots()
	
	-- This shouldn't run as often
	if ( engine:TickCount() % math.floor( 1 / engine.TickInterval() ) == 0 ) then
		local tab = player.GetHumans()
		if #tab > 0 then
			local ply = table.Random(tab)
			
			net.Start( "TRizzleBotFlashlight" )
			net.Send( ply )
		end
	end
	
	for k, bot in ipairs( player.GetAll() ) do
	
		if IsValid( bot ) and bot:IsTRizzleBot() then
			
			if ( ( engine:TickCount() + bot:EntIndex() ) % BotUpdateSkipCount ) == 0 then
			
				bot.ShouldReset = true -- Clear all movement and buttons
				
				if !bot:Alive() then -- We do the respawning here since its better than relying on timers
			
					if bot:GetDeathTimestamp() > 6.0 then -- The bot seems to only be able to respawn if I manually call the Spawn() function
						
						bot:Spawn()
						
					end
					
					continue -- We don't need to think while dead
					
				end
			
				-- A quick condition statement to check if our enemy is no longer a threat.
				bot:CheckCurrentEnemyStatus()
				bot:TBotFindClosestEnemy()
				bot:TBotCheckEnemyList()
				
				bot:SetCollisionGroup( 5 ) -- Apparently the bot's default collisiongroup is set to 11 causing the bot not to take damage from melee enemies
				
				local botWeapon = bot:GetActiveWeapon()
				if !IsValid( bot.TBotOwner ) or !bot.TBotOwner:Alive() then	
					
					local CurrentLeader = bot:FindGroupLeader()
					if IsValid( CurrentLeader ) then
					
						bot.GroupLeader = CurrentLeader
						
					else
					
						bot.GroupLeader = bot
					
					end
				
				elseif IsValid( bot.GroupLeader ) then -- If the bot's owner is alive, the bot should clear its group leader and the hiding spot it was trying to goto
					
					bot.GroupLeader	= nil
					bot.HidingSpot = nil
					bot.HidingState = FINISHED_HIDING
					
				end
				
				if IsValid( bot.Enemy ) then
					
					bot.LastCombatTime = CurTime() + 5.0 -- Update combat timestamp
					
					local enemyDist = (bot.Enemy:GetPos() - bot:GetPos()):LengthSqr() -- Grab the bot's current distance from their current enemy
					
					-- Should I limit how often this runs?
					local trace = util.TraceLine( { start = bot:GetShootPos(), endpos = bot.Enemy:EyePos(), filter = bot, mask = MASK_SHOT } )
					
					if trace.Entity == bot.Enemy or trace.Fraction <= 1.0 then
						
						bot.AimForHead = true
						
					else
						
						bot.AimForHead = false
						
					end
					
					if IsValid( botWeapon ) and botWeapon:IsWeapon() then
					
						if bot.FullReload and ( botWeapon:Clip1() >= botWeapon:GetMaxClip1() or bot:GetAmmoCount( botWeapon:GetPrimaryAmmoType() ) <= botWeapon:Clip1() or botWeapon:GetClass() != bot.Shotgun ) then bot.FullReload = false end -- Fully reloaded :)
						
						if CurTime() > bot.FireWeaponInterval and !botWeapon:GetInternalVariable( "m_bInReload" ) and !bot.FullReload and botWeapon:GetClass() != "weapon_medkit" and bot:IsCursorOnTarget() then
							
							bot:PressPrimaryAttack()
							
							-- If the bot's active weapon is automatic the bot should just press and hold its attack button if their current enemy is close enough
							if bot:IsActiveWeaponAutomatic() and enemyDist < 160000 then
								
								bot.FireWeaponInterval = CurTime()
								
							else
								
								bot.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.4 )
								
							end
							
						end
						
						if CurTime() > bot.FireWeaponInterval and botWeapon:GetClass() == "weapon_medkit" and bot.CombatHealThreshold > bot:Health() then
							
							bot:PressSecondaryAttack()
							bot.FireWeaponInterval = CurTime() + 0.5
							
						end
						
						if CurTime() > bot.ScopeInterval and botWeapon:GetClass() == bot.Sniper and bot.SniperScope and !bot:IsUsingScope() then
						
							bot:PressSecondaryAttack( 1.0 )
							bot.ScopeInterval = CurTime() + 1.1
						
						end
						
						if CurTime() > bot.ReloadInterval and !botWeapon:GetInternalVariable( "m_bInReload" ) and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:Clip1() == 0 then
							
							if botWeapon:GetClass() == bot.Shotgun then bot.FullReload = true end
							
							bot:PressReload()
							bot.ReloadInterval = CurTime() + 0.5
							
						end
						
						-- If an enemy gets too close and the bot is not using its melee weapon the bot should retreat backwards
						if !isvector( bot.Goal ) and botWeapon:GetClass() != bot.Melee and enemyDist < 6400 then
							
							local ground = navmesh.GetGroundHeight( bot:GetPos() - ( 30.0 * bot:EyeAngles():Forward() ) )
							
							-- Don't dodge if we will fall
							if ground and bot:GetPos().z - ground < bot:GetStepSize() then
								
								bot:PressBack()
								
							end
						
						end
						
					end
					
					bot:SelectBestWeapon()
				
				else
				
					if !bot:IsInCombat() then
					
						-- If the bot is not in combat then the bot should check if any of its teammates need healing
						bot.HealTarget = bot:TBotFindClosestTeammate()
						
						if IsValid( bot.HealTarget ) and bot:HasWeapon( "weapon_medkit" ) then
						
							bot:SelectMedkit()
							
							if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" then
								
								if CurTime() > bot.FireWeaponInterval and bot.HealTarget == bot then
								
									bot:PressSecondaryAttack()
									bot.FireWeaponInterval = CurTime() + 0.5
									
								elseif CurTime() > bot.FireWeaponInterval and bot:GetEyeTrace().Entity == bot.HealTarget then
								
									bot:PressPrimaryAttack()
									bot.FireWeaponInterval = CurTime() + 0.5
									
								end
								
								if bot.HealTarget != bot then bot:AimAtPos( bot.HealTarget:WorldSpaceCenter(), CurTime() + 0.1, MEDIUM_PRIORITY ) end
								
							end
							
						else
						
							bot:ReloadWeapons()
							
						end
						
						-- If the bot doen't feel safe it should look around for possible enemies
						if !bot:IsSafe() and bot.NextEncounterTime < CurTime() then
						
							bot:SetEncounterLookAt( bot:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward(), CurTime() + 1.0 )
						
						end
						
						if IsValid( botWeapon ) and botWeapon:IsWeapon() then 
							
							if CurTime() > bot.ReloadInterval and !botWeapon:GetInternalVariable( "m_bInReload" ) and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and botWeapon:Clip1() < botWeapon:GetMaxClip1() then
						
								bot:PressReload()
								bot.ReloadInterval = CurTime() + 0.5
								
							end
							
							if CurTime() > bot.ScopeInterval and botWeapon:GetClass() == bot.Sniper and bot.SniperScope and bot:IsUsingScope() then
						
								bot:PressSecondaryAttack()
								bot.ScopeInterval = CurTime() + 0.5
								
							end
							
						end
						
						bot:RestoreAmmo()
						
					else
					
						if IsValid( botWeapon ) and botWeapon:IsWeapon() and CurTime() > bot.ReloadInterval and !botWeapon:GetInternalVariable( "m_bInReload" ) and botWeapon:GetClass() != "weapon_medkit" and botWeapon:GetClass() != bot.Melee and bot.NumVisibleEnemies <= 0 and ( ( botWeapon:GetClass() == bot.Shotgun and botWeapon:Clip1() < botWeapon:GetMaxClip1() ) or botWeapon:Clip1() < ( botWeapon:GetMaxClip1() * 0.6 ) ) then
						
							bot:PressReload()
							bot.ReloadInterval = CurTime() + 0.5
							
						end
						
					end
				
				end
				
				-- Here is the AI for GroupLeaders
				if IsValid( bot.GroupLeader ) and bot:IsGroupLeader() then
				
					-- If the bot's group is being overwhelmed then they should retreat
					if !isvector( bot.HidingSpot ) and !isvector( bot.Goal ) and ( IsValid( bot.Enemy ) and bot:Health() < bot.CombatHealThreshold or ( bot.NumVisibleEnemies >= 10 and bot.EnemyListAverageDistSqr < bot.DangerDist * bot.DangerDist ) ) then
				
						bot.HidingSpot = bot:FindSpot( "far", { pos = bot:GetPos(), radius = 10000, stepdown = 200, stepup = 64 } )
						
						if isvector( bot.HidingSpot ) then
							
							bot.HidingState = MOVE_TO_SPOT
							bot.HideTime = 5.0
							
						end
					
					end
					
				elseif IsValid( bot.GroupLeader ) and !bot:IsGroupLeader() then
					
					-- If the bot needs to reload its active weapon it should find cover nearby and reload there
					if !isvector( bot.HidingSpot ) and !isvector( bot.Goal ) and IsValid( bot.Enemy ) and IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() != bot.Melee and botWeapon:Clip1() == 0 and (bot.GroupLeader:GetPos() - bot:GetPos()):LengthSqr() < bot.FollowDist * bot.FollowDist then

						bot.HidingSpot = bot:FindSpot( "near", { pos = bot:GetPos(), radius = bot.FollowDist, stepdown = 200, stepup = 64 } )
						
						if isvector( bot.HidingSpot ) then
							
							bot.HidingState = MOVE_TO_SPOT
							bot.HideTime = 3.0
							bot.ReturnPos = bot:GetPos()
							
						end

					end
					
				elseif IsValid( bot.TBotOwner ) and bot.TBotOwner:Alive() then
					
					-- If the bot needs to reload its active weapon it should find cover nearby and reload there
					if !isvector( bot.HidingSpot ) and !isvector( bot.Goal ) and IsValid( bot.Enemy ) and botWeapon:GetClass() != bot.Melee and botWeapon:Clip1() == 0 and (bot.TBotOwner:GetPos() - bot:GetPos()):LengthSqr() < bot.FollowDist * bot.FollowDist then

						bot.HidingSpot = bot:FindSpot( "near", { pos = bot:GetPos(), radius = bot.FollowDist, stepdown = 200, stepup = 64 } )
						
						if isvector( bot.HidingSpot ) then
							
							bot.HidingState = MOVE_TO_SPOT
							bot.HideTime = 3.0
							bot.ReturnPos = bot:GetPos()
							
						end

					end
					
				end
				
				-- This is where the bot sets its move goals
				if isvector( bot.HidingSpot ) then
					
					-- When have reached our destination start the wait timer
					if bot.HidingState == MOVE_TO_SPOT and (bot:GetPos() - bot.HidingSpot):LengthSqr() < 32 * 32 then
				
						bot.HidingState = WAIT_AT_SPOT
						bot.HideTime = CurTime() + bot.HideTime
					
					-- If the bot has finished hiding or its hiding spot is no longer safe, it should clear its selected hiding spot
					elseif bot.HidingState == WAIT_AT_SPOT then
						
						if bot.HideTime < CurTime() or !bot:IsSpotSafe( bot.HidingSpot ) then -- Is bot.NumVisibleEnemies > 0 more efficent and cheaper?
							
							bot.HidingSpot = nil
							bot.HidingState = FINISHED_HIDING
							
							if isvector( bot.ReturnPos ) then
								
								-- We only set the goal once just incase something else that is important, "following their owner," wants to move the bot
								bot:TBotSetNewGoal( bot.ReturnPos )
								bot.ReturnPos = nil
								
							end
							
						else
							
							-- The bot should crouch once it reaches its selected hiding spot
							bot:PressCrouch()
						
						end
						
					-- If the bot has a hiding spot it should path there
					elseif !isvector( bot.Goal ) and (bot:GetPos() - bot.HidingSpot):LengthSqr() > 32 * 32 then
					
						bot:TBotSetNewGoal( bot.HidingSpot )
						
					end
					
				elseif IsValid( bot.GroupLeader ) and !bot:IsGroupLeader() then
				
					if isvector( bot.Goal ) and (bot.GroupLeader:GetPos() - bot.Goal):LengthSqr() > bot.FollowDist * bot.FollowDist or !isvector( bot.Goal ) and (bot.GroupLeader:GetPos() - bot:GetPos()):LengthSqr() > bot.FollowDist * bot.FollowDist then
			
						bot:TBotSetNewGoal( bot.GroupLeader:GetPos() )
						
					end
					
				elseif IsValid( bot.TBotOwner ) and bot.TBotOwner:Alive() then
					
					if isvector( bot.Goal ) and (bot.TBotOwner:GetPos() - bot.Goal):LengthSqr() > bot.FollowDist * bot.FollowDist or !isvector( bot.Goal ) and (bot.TBotOwner:GetPos() - bot:GetPos()):LengthSqr() > bot.FollowDist * bot.FollowDist then
			
						bot:TBotSetNewGoal( bot.TBotOwner:GetPos() )
						
					end
					
				end
				
				-- The check CNavArea we are standing on.
				if !bot.currentArea or !bot.currentArea:Contains( bot:GetPos() ) then
				
					bot.currentArea			=	navmesh.GetNearestNavArea( bot:GetPos() )
					
				end
				
				-- Update the bot movement if they are pathing to a goal
				if isvector( bot.Goal ) then
			
					bot:TBotNavigation()
					bot:TBotDebugWaypoints()
					
				end
				
				if bot.TBotOwner:InVehicle() and !bot:InVehicle() then
				
					local vehicle = bot:FindNearbySeat()
					
					if IsValid( vehicle ) then bot:EnterVehicle( vehicle ) end -- I should make the bot press its use key instead of this hack
				
				end
				
				if !bot.TBotOwner:InVehicle() and bot:InVehicle() then
				
					bot:PressUse()
				
				end
				
				if bot.SpawnWithWeapons then
					
					if !bot:HasWeapon( bot.Pistol ) then bot:Give( bot.Pistol )
					elseif !bot:HasWeapon( bot.Shotgun ) then bot:Give( bot.Shotgun )
					elseif !bot:HasWeapon( bot.Rifle ) then bot:Give( bot.Rifle )
					elseif !bot:HasWeapon( bot.Sniper ) then bot:Give( bot.Sniper )
					elseif !bot:HasWeapon( bot.Melee ) then bot:Give( bot.Melee )
					elseif !bot:HasWeapon( "weapon_medkit" ) then bot:Give( "weapon_medkit" ) end
					
				end
				
				-- I have to set the flashlight state because some addons have mounted flashlights and I can't check if they are on or not, "This will prevent the flashlight on and off spam"
				if bot:CanUseFlashlight() and !bot:FlashlightIsOn() and bot.Light and bot:GetSuitPower() > 50 then
					
					bot:Flashlight( true )
					
				elseif bot:CanUseFlashlight() and bot:FlashlightIsOn() and !bot.Light then
					
					bot:Flashlight( false )
					
				end
				
				bot:HandleButtons()
				
			end
			
		end
		
	end

	--print( "RunTime: " .. tostring( SysTime() - startTime ) .. " Seconds" )
	
end)

-- Reset their AI on spawn.
hook.Add( "PlayerSpawn" , "TRizzleBotSpawnHook" , function( ply )
	
	if ply:IsTRizzleBot() then
		
		ply:TBotResetAI() -- For some reason running the a timer for 0.0 seconds works, but if I don't use a timer nothing works at all
		timer.Simple( 0.0 , function()
			
			if IsValid( ply ) and ply:Alive() then
				
				ply:SetModel( ply.PlayerModel )
				
			end
			
		end)
		
		timer.Simple( 0.3 , function()
		
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
			
		end)
		
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

	if !IsValid( attacker ) or !IsValid( victim ) or !victim:IsTRizzleBot() or attacker:IsPlayer() then return end
	
	if attacker:IsNPC() and !victim.EnemyList[ attacker:GetCreationID() ] and attacker:IsAlive() and ( attacker:IsEnemy( victim ) or attacker:IsEnemy( victim.TBotOwner ) ) then

		victim.EnemyList[ attacker:GetCreationID() ]		=	{ Enemy = attacker, LastSeenTime = CurTime() + 10.0 }
	
	end

end)

-- Makes the bot react to sounds made by enemies
hook.Add( "EntityEmitSound" , "TRizzleBotEntityEmitSound" , function( soundTable )
	
	for k, bot in ipairs( player.GetAll() ) do
		
		if !IsValid( bot ) or !bot:IsTRizzleBot() or !IsValid( soundTable.Entity ) or soundTable.Entity:IsPlayer() or soundTable.Entity == bot then continue end
	
		if soundTable.Entity:IsNPC() and !bot.EnemyList[ soundTable.Entity:GetCreationID() ] and soundTable.Entity:IsAlive() and ( soundTable.Entity:IsEnemy( bot ) or soundTable.Entity:IsEnemy( bot.TBotOwner ) ) and (soundTable.Entity:GetPos() - bot:GetPos()):LengthSqr() < ( ( 1000 * ( soundTable.SoundLevel / 100 ) ) * ( 1000 * ( soundTable.SoundLevel / 100 ) ) ) then
			
			bot.EnemyList[ soundTable.Entity:GetCreationID() ]		=	{ Enemy = soundTable.Entity, LastSeenTime = CurTime() + 10.0 }
			
		end
		
	end
	
	return
end)

-- Checks if the NPC is alive
function Npc:IsAlive()
	if !IsValid( self ) then return false end
	
	if self:GetNPCState() == NPC_STATE_DEAD then return false
	elseif self:GetInternalVariable( "m_lifeState" ) != 0 then return false 
	elseif self:Health() <= 0 then return false end
	
	return true
	
end

-- Checks if the target entity is the NPC's enemy
function Npc:IsEnemy( target )
	if !IsValid( self ) or !IsValid( target ) then return false end
	
	return self:Disposition( target ) == D_HT
	
end

-- Checks if its current enemy is still alive and still visible to the bot
function BOT:CheckCurrentEnemyStatus()
	
	if !IsValid( self.Enemy ) then 
		
		self.Enemy = nil
		
	elseif self.Enemy:IsPlayer() and !self.Enemy:Alive() then 
		
		self.Enemy = nil -- Just incase the bot's enemy is set to a player even though the bot should only target NPCS and "hopefully" NEXTBOTS 
		
	elseif self:IsTRizzleBotBlind() or !self.Enemy:TBotVisible( self ) or self:IsHiddenByFog( self:GetShootPos():Distance( self.Enemy:EyePos() ) ) then 
		
		self.Enemy = nil
		
	elseif self.Enemy:IsNPC() and ( !self.Enemy:IsAlive() or ( !self.Enemy:IsEnemy( self ) and !self.Enemy:IsEnemy( self.TBotOwner ) ) ) then 
		
		self.Enemy = nil
		
	elseif GetConVar( "ai_ignoreplayers" ):GetInt() != 0 or GetConVar( "ai_disabled" ):GetInt() != 0 then 
		
		self.Enemy = nil 
	
	end
	
end

-- This checks every enemy on the bot's Known Enemy List and checks to see if they are alive, visible, and valid
function BOT:TBotCheckEnemyList()
	if ( ( engine:TickCount() + self:EntIndex() ) % 5 ) != 0 then return end -- This shouldn't run as often
	--print( table.Count( self.EnemyList ) )
	
	local numVisibleEnemies = 0
	local averageDistSqr = 0
	for k, v in pairs( self.EnemyList ) do
		
		-- I don't think I have to use this
		--local enemy = self.EnemyList[ k ][ "Enemy" ]
		--local lastSeenTime = self.EnemyList[ k ][ "LastSeenTime" ]
		
		--print( k )
		--print( v )
		
		if !IsValid( v.Enemy ) then
			
			self.EnemyList[ k ] = nil
			continue
			
		elseif v.Enemy:IsPlayer() and !v.Enemy:Alive() then 
			
			self.EnemyList[ k ] = nil -- Just incase the bot's enemy is set to a player even though the bot should only target NPCS and "hopefully" NEXTBOTS
			continue
			
		elseif v.Enemy:IsNPC() and ( !v.Enemy:IsAlive() or ( !v.Enemy:IsEnemy( self ) and !v.Enemy:IsEnemy( self.TBotOwner ) ) ) then 
			
			self.EnemyList[ k ] = nil
			continue
			
		elseif GetConVar( "ai_ignoreplayers" ):GetInt() != 0 or GetConVar( "ai_disabled" ):GetInt() != 0 then 
			
			self.EnemyList[ k ] = nil
			continue
			
		elseif ( self:IsTRizzleBotBlind() or !v.Enemy:TBotVisible( self ) or self:IsHiddenByFog( self:GetShootPos():Distance( v.Enemy:EyePos() ) ) ) and v.LastSeenTime < CurTime() then 
			
			self.EnemyList[ k ] = nil
			continue
		
		elseif !self:IsTRizzleBotBlind() and v.Enemy:TBotVisible( self ) and !self:IsHiddenByFog( self:GetShootPos():Distance( v.Enemy:EyePos() ) ) then 
		
			self.EnemyList[ k ][ "LastSeenTime" ] = CurTime() + 10.0
			
			numVisibleEnemies	= 	numVisibleEnemies + 1
			averageDistSqr		=	averageDistSqr + v.Enemy:GetPos():DistToSqr( self:GetPos() )
			
		end
		
	end
	
	self.NumVisibleEnemies			=	numVisibleEnemies
	self.EnemyListAverageDistSqr	=	averageDistSqr / numVisibleEnemies
	
end

-- Target any hostile NPCS that is visible to us.
function BOT:TBotFindClosestEnemy()
	if self:IsTRizzleBotBlind() then return end -- The bot is blind
	if ( ( engine:TickCount() + self:EntIndex() ) % 5 ) != 0 then return end -- This shouldn't run as often
	if GetConVar( "ai_ignoreplayers" ):GetInt() != 0 or GetConVar( "ai_disabled" ):GetInt() != 0 then return end
	
	local VisibleEnemies		=	self.EnemyList -- This is the list of enemies the bot knows about.
	local targetdistsqr			=	100000000 -- This will allow the bot to select the closest enemy to it.
	local target				=	self.Enemy -- This is the closest enemy to the bot.
	
	for k, v in ipairs( ents.GetAll() ) do
		
		if IsValid( v ) and v:IsNPC() and v:IsAlive() and ( v:IsEnemy( self ) or v:IsEnemy( self.TBotOwner ) ) then -- The bot should attack any NPC that is hostile to them or their owner. D_HT means hostile/hate
			
			local enemydistsqr = (v:GetPos() - self:GetPos()):LengthSqr()
			if self:IsAbleToSee( v ) and v:TBotVisible( self ) then
				
				if !VisibleEnemies[ v:GetCreationID() ] then VisibleEnemies[ v:GetCreationID() ]		=	{ Enemy = v, LastSeenTime = CurTime() + 10.0 } end -- We grab the entity's Creation ID because the will never be the same as any other entity.
				
				if enemydistsqr < targetdistsqr then 
					target = v
					targetdistsqr = enemydistsqr
				end
				
			elseif VisibleEnemies[ v:GetCreationID() ] and v:TBotVisible( self ) and !self:IsHiddenByFog( self:GetShootPos():Distance( v:EyePos() ) ) then
				
				if ( !IsValid( target ) or enemydistsqr < 40000 ) and enemydistsqr < targetdistsqr then 
					target = v
					targetdistsqr = enemydistsqr
				end
			
			end
		end
		
	end
	
	self.Enemy			=	target
	self.EnemyList		=	VisibleEnemies
	
end

-- Heal any player or bot that is visible to us.
function BOT:TBotFindClosestTeammate()
	local targetdistsqr			=	6400 -- This will allow the bot to select the closest teammate to it.
	local target				=	nil -- This is the closest teammate to the bot.
	
	--The bot should heal its owner and itself before it heals anyone else
	if IsValid( self.TBotOwner ) and self.TBotOwner:Alive() and self.TBotOwner:Health() < self.HealThreshold and (self.TBotOwner:GetPos() - self:GetPos()):LengthSqr() < 6400 then return self.TBotOwner
	elseif self:Health() < self.HealThreshold then return self end

	for k, v in ipairs( player.GetAll() ) do
		
		if IsValid( v ) and v:Alive() and v:Health() < self.HealThreshold and !self:IsTRizzleBotBlind() and v:TBotVisible( self ) then -- The bot will heal any teammate that needs healing that we can actually see and are alive.
			
			local teammatedistsqr = (v:GetPos() - self:GetPos()):LengthSqr()
			
			if teammatedistsqr < targetdistsqr then 
				target = v
				targetdist = teammatedist
			end
		end
	end
	
	return target
	
end

function BOT:FindNearbySeat()
	
	local targetdistsqr			=	40000 -- This will allow the bot to select the closest vehicle to it.
	local target				=	nil -- This is the closest vehicle to the bot.
	
	for k, v in ipairs( ents.GetAll() ) do
		
		if IsValid( v ) and v:IsVehicle() and !IsValid( v:GetDriver() ) then -- The bot should enter the closest vehicle to it
			
			local vehicledistsqr = (v:GetPos() - self:GetPos()):LengthSqr()
			
			if vehicledistsqr < targetdistsqr then 
				target = v
				targetdistsqr = vehicledistsqr
			end
			
		end
		
	end
	
	return target
	
end

function TRizzleBotRangeCheck( FirstNode , SecondNode , Ladder , Height )
	-- Some helper errors.
	if !IsValid( FirstNode ) then error( "Bad argument #1 CNavArea expected got " .. type( FirstNode ) ) end
	if !IsValid( FirstNode ) then error( "Bad argument #2 CNavArea expected got " .. type( SecondNode ) ) end
	
	if Ladder then return Ladder:GetLength() end
	
	local DefaultCost = FirstNode:GetCenter():Distance( SecondNode:GetCenter() )
	local EditedCost = DefaultCost
	
	-- Jumping is slower than ground movement.
	if isnumber( Height ) and Height > 32 then
		
		EditedCost		=	EditedCost + ( DefaultCost * 5 )
		
	end
	
	-- Falling is risky if the bot might take fall damage.
	if isnumber( Height ) and -Height > 32 then
	
		EditedCost		=	EditedCost + ( DefaultCost * GetApproximateFallDamage( math.abs( Height ) ) )
		
	end
	
	-- Crawling through a vent is very slow.
	if SecondNode:HasAttributes( NAV_MESH_CROUCH ) then 
		
		EditedCost	=	EditedCost + ( DefaultCost * 8 )
		
	end
	
	-- The bot should avoid this area unless alternatives are too dangerous or too far.
	if SecondNode:HasAttributes( NAV_MESH_AVOID ) then 
		
		EditedCost	=	EditedCost + ( DefaultCost * 20 )
		
	end
	
	-- We will try not to swim since it can be slower than running on land, it can also be very dangerous, Ex. "Acid, Lava, Etc."
	if SecondNode:IsUnderwater() then
	
		EditedCost		=	EditedCost + ( DefaultCost * 2 )
		
	end
	
	return EditedCost
end

-- Got this from CS:GO Source Code, made some changes so it works for Lua
-- Returns approximately how much damage will will take from the given fall height
function GetApproximateFallDamage( height )
	
	-- CS:GO empirically discovered height values, this may return incorrect results for Gmod
	local slope = 0.2178
	local intercept = 26.0

	local damage = slope * height - intercept

	if damage < 0.0 then
		return 0.0
	end

	return damage
end

-- This is a hybrid version of pathfollower, it can use ladders and is very optimized
function TRizzleBotPathfinderCheap( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) or GoalNode:IsBlocked() then return false end
	if StartNode == GoalNode then return true end
	
	StartNode:ClearSearchLists()
	
	StartNode:AddToOpenList()
	
	StartNode:SetCostSoFar( 0 )
	
	StartNode:SetTotalCost( TRizzleBotRangeCheck( StartNode , GoalNode ) )
	
	StartNode:UpdateOnOpenList()
	
	local Trys			=	0 -- Backup! Prevent crashing.
	
	while ( !StartNode:IsOpenListEmpty() and Trys < 50000 ) do
		Trys	=	Trys + 1
		
		local Current	=	StartNode:PopOpenList()
		
		if Current:IsBlocked() then
			
			continue
			
		end
		
		if Current == GoalNode then
			
			return TRizzleBotRetracePathCheap( StartNode , GoalNode )
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
		
			if newArea == Current or newArea:IsBlocked() then 
			
				continue
				
			end
			
			local Height	=	Current:ComputeAdjacentConnectionHeightChange( newArea )
			-- Optimization,Prevent computing the height twice.
			
			local NewCostSoFar		=	Current:GetCostSoFar() + TRizzleBotRangeCheck( newArea , Current , ladder , Height )
			
			if !IsValid( ladder ) and !Current:IsUnderwater() and !newArea:IsUnderwater() and -Height < 200 and Height > 64 then
				-- We can't jump that high.
				
				continue
			end
			
			
			if ( newArea:IsOpen() or newArea:IsClosed() ) and newArea:GetCostSoFar() <= NewCostSoFar then
				
				continue
				
			else
				
				newArea:SetCostSoFar( NewCostSoFar )
				newArea:SetTotalCost( NewCostSoFar + TRizzleBotRangeCheck( newArea , GoalNode ) )
				
				if newArea:IsClosed() then
					
					newArea:RemoveFromClosedList()
					
				end
				
				if newArea:IsOpen() then
					
					newArea:UpdateOnOpenList()
					
				else
					
					newArea:AddToOpenList()
					
				end
				
				
				newArea:SetParent( Current, how )
			end
			
			
		end
		
		Current:AddToClosedList()
		
	end
	
	
	return false
end

function TRizzleBotRetracePathCheap( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	
	local LADDER_UP = 0
	local LADDER_DOWN = 1
	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	local NUM_TRAVERSE_TYPES = 9
	
	local Trys			=	0 -- Backup! Prevent crashing.
	-- I need to check if this works
	local NewPath	=	{}
	--local NewPath	=	{ GoalNode }
	
	local Current	=	GoalNode
	local Parent 	=	NUM_TRAVERSE_TYPES
	local StopLoop	=	false
	
	while( !StopLoop and Trys < 50001 ) do
		
		if !IsValid( Current ) or Current == StartNode then 
		
			StopLoop = true
			Parent = NUM_TRAVERSE_TYPES
			
		end
		
		--print( Current )
		--print( Parent )
		
		if Parent == GO_LADDER_UP then
		
			local list = Current:GetParent():GetLaddersAtSide( LADDER_UP )
			--print( "Ladders: " .. #list )
			for k, Ladder in ipairs( list ) do
				--print( "Top Area: " .. tostring( Ladder:GetTopForwardArea() ) )
				--print( "TopLeft Area: " .. tostring( Ladder:GetTopLeftArea() ) )
				--print( "TopRight Area: " .. tostring( Ladder:GetTopRightArea() ) )
				--print( "TopBehind Area: " .. tostring( Ladder:GetTopBehindArea() ) )
				if Ladder:GetTopForwardArea() == Current or Ladder:GetTopLeftArea() == Current or Ladder:GetTopRightArea() == Current or Ladder:GetTopBehindArea() == Current then
					
					NewPath[ #NewPath + 1 ] = { area = Current, how = Parent, ladder = Ladder }
					break
					
				end
			end
			
		elseif Parent == GO_LADDER_DOWN then
		
			local list = Current:GetParent():GetLaddersAtSide( LADDER_DOWN )
			--print( "Ladders: " .. #list )
			for k, Ladder in ipairs( list ) do
				--print( "Bottom Area: " .. tostring( Ladder:GetBottomArea() ) )
				if Ladder:GetBottomArea() == Current then
					
					NewPath[ #NewPath + 1 ] = { area = Current, how = Parent, ladder = Ladder }
					break
					
				end
			end
		
		else
			
			NewPath[ #NewPath + 1 ] = { area = Current, how = Parent }
			
		end
		
		Current		=	Current:GetParent()
		if IsValid( Current ) and !StopLoop then Parent		=	Current:GetParentHow() end
		
	end
	
	--NewPath[ #NewPath + 1 ] = { area = StartNode, how = NUM_TRAVERSE_TYPES }
	
	return NewPath
end

function BOT:TBotSetNewGoal( NewGoal )
	if !isvector( NewGoal ) then error( "Bad argument #1 vector expected got " .. type( NewGoal ) ) end
	
	if self.PathTime < CurTime() then
		self.Goal				=	NewGoal
		self.Path				=	{}
		self.PathTime			=	CurTime() + 0.5
		self:TBotCreateNavTimer()
	end
	
end

-- This will compute the length of the path given
function GetPathLength( tbl, startArea, endArea )
	if isbool( tbl ) and tbl then return startArea:GetCenter():Distance( endArea:GetCenter() )
	elseif isbool( tbl ) and !tbl then return -1 end
	
	local totalDist = 0
	for k, v in ipairs( tbl ) do
		if !tbl[ k + 1 ] then break
		elseif !IsValid( v.area ) or !IsValid( tbl[ k + 1 ].area ) then return -1 end -- The table is either not a path or is corrupted
		
		totalDist = totalDist + v.area:GetCenter():Distance( tbl[ k + 1 ].area:GetCenter() )
	end
	
	return totalDist

end

-- Checks if a hiding spot is already in use
function BOT:IsSpotOccupied( pos )

	for k, ply in ipairs( player.GetAll() ) do
		
		if IsValid( ply ) and ply != self then
		
			if ply:GetPos():DistToSqr(pos) < 75 * 75 then return true -- Don't consider spots if a bot or human player is already there
			elseif ply:IsTRizzleBot() and ply.HidingSpot == pos then return true end -- Don't consider spots already selected by other bots
	
		end
		
	end

	return false

end

-- Checks if a hiding spot is safe to use
function BOT:IsSpotSafe( pos )

	for k, v in pairs( self.EnemyList ) do
	
		if IsValid( v ) and v:TBotVisible( pos ) then return false end -- If one of the bot's enemies its aware of can see it the bot won't use it.
	
	end

	return true

end

-- Returns a table of hiding spots.
function BOT:FindSpots( tbl )

	local tbl = tbl or {}

	tbl.pos			= tbl.pos			or self:WorldSpaceCenter()
	tbl.radius		= tbl.radius		or 1000
	tbl.stepdown	= tbl.stepdown		or 200
	tbl.stepup		= tbl.stepup		or 64
	tbl.type		= tbl.type			or "hiding"
	tbl.checkoccupied	= tbl.checkoccupied		or true
	tbl.checksafe		= tbl.checksafe			or true

	-- Find a bunch of areas within this distance
	local areas = navmesh.Find( tbl.pos, tbl.radius, tbl.stepdown, tbl.stepup )

	local found = {}
	
	local startArea = navmesh.GetNearestNavArea( tbl.pos )

	-- In each area
	for _, area in ipairs( areas ) do

		-- get the spots
		local spots

		if ( tbl.type == "hiding" ) then spots = area:GetHidingSpots() -- In Cover/basically a hiding spot, in a corner with good hard cover nearby
		elseif ( tbl.type == "sniper" ) then spots = area:GetHidingSpots( 4 ) end -- Perfect sniper spot, can see either very far, or a large area, or both

		for k, vec in ipairs( spots ) do

			local endArea = navmesh.GetNearestNavArea( vec )
			local tempPath = TRizzleBotPathfinderCheap( startArea, endArea )
			local tempPathLength = GetPathLength( tempPath, startArea, endArea )
			
			if tempPathLength < 0 or tbl.radius < tempPathLength then continue -- If the bot can't path to a hiding spot or its further than tbl.range, the bot shouldn't consider it
			elseif ( tbl.checkoccupied and self:IsSpotOccupied( vec ) ) or ( tbl.checksafe and !self:IsSpotSafe( vec ) ) then continue end -- If the spot is already in use by another player or the spot is visible to enemies on the bot's known enemy list, the bot shouldn't consider it
			table.insert( found, { vector = vec, distance = tempPathLength } )

		end

	end

	return found

end

-- Like FindSpots but only returns a vector
function BOT:FindSpot( type, options )

	local spots = self:FindSpots( options )
	if ( !spots or #spots == 0 ) then return end

	if ( type == "near" ) then

		table.SortByMember( spots, "distance", true )
		return spots[1].vector

	end

	if ( type == "far" ) then

		table.SortByMember( spots, "distance", false )
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

-- Creates waypoints using the nodes.
function BOT:ComputeNavmeshVisibility()
	
	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	
	self.Path				=	{}
	
	local LastVisPos		=	self:GetPos()
	local dir			=	Vector( 0, 0, 0 )
	
	for k, v in ipairs( self.NavmeshNodes ) do
		-- I should also make sure that the nodes exist as this is called 0.03 seconds after the pathfind.
		
		local CurrentNode	=	v.area
		local currentIndex	=	#self.Path
		
		if !self.NavmeshNodes[ k + 1 ] or !self.NavmeshNodes[ k + 1 ].area or !self.NavmeshNodes[ k + 1 ].how then
			
			self.Path[ #self.Path + 1 ]		=	{ Pos = self.Goal, IsLadder = false, IsDropDown = false }
			
			break
		end
		
		local NextNode		=	self.NavmeshNodes[ k + 1 ].area
		local NextHow		=	self.NavmeshNodes[ k + 1 ].how
		
		if self.NavmeshNodes[ k + 1 ].ladder then
		
			local NextLadder = self.NavmeshNodes[ k + 1 ].ladder
			-- May not need this anymore
			--local LadderNode, ClimbUp		=	self.NavmeshNodes[ k + 1 ].ladder:Get_Closest_Point_Next( LastVisPos )
			
			if NextHow == GO_LADDER_UP then 
				
				self.Path[ currentIndex + 1 ]		=	{ Pos = NextLadder:GetBottom() + NextLadder:GetNormal() * 2.0 * 16, IsLadder = false, IsDropDown = false }
				self.Path[ currentIndex + 2 ]		=	{ Pos = NextLadder:GetTop(), IsLadder = true, LadderUp = true }
				LastVisPos				=	NextLadder:GetTop()
				
			else
				
				self.Path[ currentIndex + 1 ]		=	{ Pos = NextLadder:GetTop() + NextLadder:GetNormal() * 2.0 * 16, IsLadder = false, IsDropDown = false }
				self.Path[ currentIndex + 2 ]		=	{ Pos = NextLadder:GetBottom(), IsLadder = true, LadderUp = false }
				LastVisPos				=	NextLadder:GetBottom()
				
			end
			
			
			
			continue
		end
		
		--[[if v.ladder then
		
			local CloseToEnd, LadderNode, ClimbUp		=	v.ladder:Get_Closest_Point_Current( NextNode:GetCenter() )
			
			LastVisPos		=	CloseToEnd
			
			self.Path[ currentIndex + 1 ]		=	{ Pos = CloseToEnd, IsLadder = true, LadderUp = ClimbUp }
			self.Path[ currentIndex + 2 ]		=	{ Pos = LadderNode, IsLadder = true, LadderUp = ClimbUp }
			
			continue
		end]]
		
		local connection, area = Get_Blue_Connection( CurrentNode, NextNode )
		
		--print( "Should Drop Down: " .. tostring( self:ShouldDropDown( LastVisPos, connection ) ) )
		--print( "LastVisPos: " .. tostring( LastVisPos ))
		--print( "Area: " .. tostring( area ) )
		--print( "Connection: " .. tostring( connection ) )
		
		-- We don't need to compute the dropdown points if the next area is marked as a jump area
		-- as it causes the bot to get stuck.
		if self:ShouldDropDown( LastVisPos, connection ) and !NextNode:HasAttributes( NAV_MESH_JUMP ) then
		
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
			
			connection.x = connection.x + ( 25.0 * dir.x )
			connection.y = connection.y + ( 25.0 * dir.y )
			
			-- Should I set this to area and use connection as the second part of the drop down?
			self.Path[ currentIndex + 1 ]			=	{ Pos = connection, IsLadder = false, Check = area, IsDropDown = true }
			
			connection.z = NextNode:GetZ( LastVisPos )
			
			self.Path[ currentIndex + 2 ]			=	{ Pos = connection, IsLadder = false, IsDropDown = true }
			
			LastVisPos							=	connection
			
			continue
		end
		
		self.Path[ #self.Path + 1 ]			=	{ Pos = connection, IsLadder = false, Check = area, IsDropDown = false }
		
		LastVisPos							=	connection
		
	end
	
end


-- The main navigation code ( Waypoint handler )
function BOT:TBotNavigation()
	if !isvector( self.Goal ) then return end -- A double backup!
	if !IsValid( self.currentArea ) then return end -- The map has no navmesh.
	
	
	if !istable( self.Path ) or !istable( self.NavmeshNodes ) or table.IsEmpty( self.Path ) or table.IsEmpty( self.NavmeshNodes ) then
		
		
		if self.BlockPathFind != true then
			
			
			-- Get the nav area that is closest to our goal.
			local TargetArea		=	navmesh.GetNearestNavArea( self.Goal )
			
			self.Path				=	{} -- Reset that.
			
			-- Pathfollower is not only cheaper, but it can use ladders.
			self.NavmeshNodes		=	TRizzleBotPathfinderCheap( self.currentArea , TargetArea )
			
			-- There is no way we can get there! Remove our goal.
			if self.NavmeshNodes == false then
				
				-- In case we fail. A* will search the whole map to find out there is no valid path.
				-- This can cause major lag if the bot is doing this almost every think.
				-- To prevent this, We block the bots pathfinding completely for a while before allowing them to pathfind again.
				-- So its not as bad.
				self.BlockPathFind		=	true
				self.Goal				=	nil
				
				timer.Simple( 1.0 , function() -- Prevent spamming the path finder.
					
					if IsValid( self ) then
						
						self.BlockPathFind		=	false
						
					end
					
				end)
				
			else
			
				-- Prevent spamming the pathfinder.
				self.BlockPathFind		=	true
				timer.Simple( 0.50 , function()
					
					if IsValid( self ) then
						
						self.BlockPathFind		=	false
						
					end
					
				end)
				
				
				-- Give the computer some time before it does more expensive checks.
				timer.Simple( 0.03 , function()
					
					-- If we can get there and is not already there, Then we will compute the visiblilty.
					if IsValid( self ) and istable( self.NavmeshNodes ) then
						
						self.NavmeshNodes	=	table.Reverse( self.NavmeshNodes )
						
						self:ComputeNavmeshVisibility()
						
					end
					
				end)
				
			end
			
		end
		
		
	end
	
	
	if istable( self.Path ) then
		
		if self.Path[ 1 ] then
			
			local Waypoint2D		=	Vector( self.Path[ 1 ][ "Pos" ].x , self.Path[ 1 ][ "Pos" ].y , self:GetPos().z )
			-- ALWAYS: Use 2D navigation, It helps by a large amount.
			
			if !self.Path[ 1 ][ "IsLadder" ] and !self.Path[ 1 ][ "IsDropDown" ] and IsVecCloseEnough( self:GetPos() , Waypoint2D , 24 ) then
				
				table.remove( self.Path , 1 )
				
			elseif !self.Path[ 1 ][ "IsLadder" ] and self.Path[ 1 ][ "IsDropDown" ] and self:GetPos().z <= self.Path[ 1 ][ "Pos" ].z + self:GetStepSize() then
				
				table.remove( self.Path , 1 )
				
			elseif self.Path[ 1 ][ "IsLadder" ] and self.Path[ 1 ][ "LadderUp" ] and self:GetPos().z >= self.Path[ 1 ][ "Pos" ].z then
				
				--[[if self.Path[ 2 ] and !self.Path[ 2 ][ "IsLadder" ] then
					self:PressJump()
				end]]
				
				table.remove( self.Path , 1 )
				
			elseif self.Path[ 1 ][ "IsLadder" ] and !self.Path[ 1 ][ "LadderUp" ] and self:GetPos().z <= self.Path[ 1 ][ "Pos" ].z + self:GetStepSize() then
			
				--[[if self.Path[ 2 ] and !self.Path[ 2 ][ "IsLadder" ] then
					self:PressJump()
				end]]
				
				table.remove( self.Path , 1 )
			
			end
			--[[elseif IsVecCloseEnough( self:GetPos() , Waypoint2D , 8 ) then -- This is a backup this should never happen
			
				table.remove( self.Path , 1 )
			
			end]]
			
		end
		
	end
	
	
end

-- The navigation and navigation debugger for when a bot is stuck.
function BOT:TBotCreateNavTimer()
	
	local index			=	self:EntIndex()
	local LastBotPos	=	self:GetPos()
	local Attempts		=	0
	
	
	timer.Create( "trizzle_bot_nav" .. index , 0.09 , 0 , function()
		
		if IsValid( self ) and self:Alive() and isvector( self.Goal ) then
			
			if self:Is_On_Ladder() then return end
			
			LastBotPos		=	Vector( LastBotPos.x , LastBotPos.y , self:GetPos().z )
			
			if IsVecCloseEnough( self:GetPos() , LastBotPos , 2 ) then
				
				self:PressJump()
				self.ShouldUse	=	true
				
				if Attempts == 10 then self.Path	=	nil end
				if Attempts > 20 then self.Goal 	=	nil end
				Attempts = Attempts + 1
				
			else
				Attempts = 0
			end
			LastBotPos		=	self:GetPos()
			
		else
			
			timer.Remove( "trizzlebot_nav" .. index )
			
		end
		
	end)
	
end



-- A handy debugger for the waypoints.
-- Requires developer set to 1 in console
function BOT:TBotDebugWaypoints()
	if !istable( self.Path ) then return end
	if table.IsEmpty( self.Path ) then return end
	
	debugoverlay.Line( self.Path[ 1 ][ "Pos" ] , self:GetPos() + Vector( 0 , 0 , 44 ) , 0.08 , Color( 0 , 255 , 255 ) )
	debugoverlay.Sphere( self.Path[ 1 ][ "Pos" ] , 8 , 0.08 , Color( 0 , 255 , 255 ) , true )
	
	for k, v in ipairs( self.Path ) do
		
		if self.Path[ k + 1 ] then
			
			debugoverlay.Line( v[ "Pos" ] , self.Path[ k + 1 ][ "Pos" ] , 0.08 , Color( 255 , 255 , 0 ) )
			
		end
		
		debugoverlay.Sphere( v[ "Pos" ] , 8 , 0.08 , Color( 255 , 200 , 0 ) , true )
		
	end
	
end

-- Make the bot move.
function BOT:TBotUpdateMovement( cmd )
	
	local MovementAngle		=	self:EyeAngles()
	
	if isvector( self.Goal ) and ( !istable( self.Path ) or table.IsEmpty( self.Path ) or isbool( self.NavmeshNodes ) ) then
		
		MovementAngle		=	( self.Goal - self:GetPos() ):GetNormalized():Angle()
		
		if self:OnGround() then
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
		
		self:PressForward()
		
		if self:Is_On_Ladder() then self:AimAtPos( self.Goal + HalfHumanHeight, CurTime() + 0.1, MAXIMUM_PRIORITY )
		else self:AimAtPos( self.Goal + HalfHumanHeight, CurTime() + 0.1, LOW_PRIORITY ) end
		
		local GoalIn2D			=	Vector( self.Goal.x , self.Goal.y , self:GetPos().z )
		if IsVecCloseEnough( self:GetPos() , GoalIn2D , 32 ) then
			
			self.Goal			=		nil -- We have reached our goal!
			
		end
		
	elseif isvector( self.Goal ) and self.Path[ 1 ] then
		
		MovementAngle		=	( self.Path[ 1 ][ "Pos" ] - self:GetPos() ):GetNormalized():Angle()
		
		if isvector( self.Path[ 1 ][ "Check" ] ) then
			MovementAngle = ( self.Path[ 1 ][ "Check" ] - self:GetPos() ):GetNormalized():Angle()
			
			local CheckIn2D			=	Vector( self.Path[ 1 ][ "Check" ].x , self.Path[ 1 ][ "Check" ].y , self:GetPos().z )
			
			if IsVecCloseEnough( self:GetPos() , CheckIn2D , 24 ) then
				
				self.Path[ 1 ][ "Check" ] = nil
				return
			end
			
			if SendBoxedLine( self:GetPos() , CheckIn2D ) == true then
			
				self.Path[ 1 ][ "Check" ] = nil
			end
		end
		
		if self:OnGround() and !self.Path[ 1 ][ "IsLadder" ] and !self.Path[ 1 ][ "IsDropDown" ] then
			local SmartJump		=	util.TraceLine({
				
				start			=	self:GetPos(),
				endpos			=	self:GetPos() + Vector( 0 , 0 , -16 ),
				filter			=	self,
				mask			=	MASK_SOLID,
				collisiongroup	        =	COLLISION_GROUP_DEBRIS
				
			})
			
			-- This tells the bot to jump if it detects a gap in the ground
			if !SmartJump.Hit then
				
				self:PressJump()

			end
		end
		
		self:PressForward()
		
		if self:Is_On_Ladder() or self.Path[ 1 ][ "IsLadder" ] then self:AimAtPos( self.Path[ 1 ][ "Pos" ] + HalfHumanHeight, CurTime() + 0.1, MAXIMUM_PRIORITY )
		else self:AimAtPos( self.Path[ 1 ][ "Pos" ] + HalfHumanHeight, CurTime() + 0.1, LOW_PRIORITY ) end
		
	end
	
	cmd:SetViewAngles( MovementAngle )
	cmd:SetForwardMove( self.forwardMovement )
	cmd:SetSideMove( self.strafeMovement )
	
end

local function NumberMidPoint( num1 , num2 )
	
	local sum = num1 + num2
	
	return sum / 2
	
end

-- This function techically gets the center crossing point of the smallest area.
-- This is 90% of the time where the blue connection point is.
-- So keep in mind this will rarely give inaccurate results.
function Get_Blue_Connection( CurrentArea , TargetArea )
	if !IsValid( TargetArea ) or !IsValid( CurrentArea ) then return end
	local dir = Get_Direction( CurrentArea , TargetArea )
	
	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	
	if dir == NORTH or dir == SOUTH then
		
		if TargetArea:GetSizeX() >= CurrentArea:GetSizeX() then
			
			local Vec	=	NumberMidPoint( CurrentArea:GetCorner( NORTH ).y , CurrentArea:GetCorner( EAST ).y )
			
			local NavPoint = Vector( CurrentArea:GetCenter().x , Vec , 0 )
			
			return TargetArea:GetClosestPointOnArea( NavPoint ), Vector( NavPoint.x , CurrentArea:GetCenter().y , CurrentArea:GetZ( NavPoint ) )
		else
			
			local Vec	=	NumberMidPoint( TargetArea:GetCorner( NORTH ).y , TargetArea:GetCorner( EAST ).y )
			
			local NavPoint = Vector( TargetArea:GetCenter().x , Vec , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( CurrentArea:GetClosestPointOnArea( NavPoint ) ), Vector( NavPoint.x , CurrentArea:GetCenter().y , CurrentArea:GetZ( NavPoint ) )
		end	
		
		return
	end
	
	if dir == EAST or dir == WEST then
		
		if TargetArea:GetSizeY() >= CurrentArea:GetSizeY() then
			
			local Vec	=	NumberMidPoint( CurrentArea:GetCorner( NORTH ).x , CurrentArea:GetCorner( WEST ).x )
			
			local NavPoint = Vector( Vec , CurrentArea:GetCenter().y , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( NavPoint ), Vector( CurrentArea:GetCenter().x , NavPoint.y , CurrentArea:GetZ( NavPoint ) )
		else
			
			local Vec	=	NumberMidPoint( TargetArea:GetCorner( NORTH ).x , TargetArea:GetCorner( WEST ).x )
			
			local NavPoint = Vector( Vec , TargetArea:GetCenter().y , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( CurrentArea:GetClosestPointOnArea( NavPoint ) ), Vector( CurrentArea:GetCenter().x , NavPoint.y , CurrentArea:GetZ( NavPoint ) )
		end
		
	end
	
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
	if !currentArea or !nextArea then return false end
	
	return currentArea.z - nextArea.z > self:GetStepSize()
	
end

-- This checks if we should jump to reach the next node
function BOT:ShouldJump( currentArea, nextArea )
	if !currentArea or !nextArea then return false end
	
	return nextArea.z - currentArea.z > self:GetStepSize()
	
end

function BOT:Is_On_Ladder()
	
	if self:GetMoveType() == MOVETYPE_LADDER then
		
		return true
	end
	
	return false
end

function Lad:Get_Closest_Point_Next( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		-- self:GetTop() - self:GetNormal() * 16 I need to make a function to detect which side the bot should approach the ladder
		return self:GetTop(), true
	end
	
	return self:GetBottom(), false
end

--[[function Lad:Get_Closest_Point_Current( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		-- self:GetTop() - self:GetNormal() * 16 I need to make a function to detect which side the bot should approach the ladder
		return self:GetTop() - self:GetNormal() * 16, self:GetTop(), true
	end
	
	return self:GetBottom(), self:GetBottom() + self:GetNormal() * 2.0 * 16, false
end]]

-- See if a node is an area : 1 or a ladder : 2
function Zone:Node_Get_Type()
	
	return 1
end

function Lad:Node_Get_Type()
	
	return 2
end


-- This grabs every internal variable of the specified entity
function Test( ply )
	for k, v in pairs( ply:GetSaveTable( true ) ) do
		
		print( k )
		print( v )
		
	end 
end

-- Draws the hiding spots on debug overlay. This includes sniper/exposed spots too!
function ShowAllHidingSpots()

	for _, area in ipairs( navmesh.GetAllNavAreas() ) do

		area:DrawSpots()

	end

end
