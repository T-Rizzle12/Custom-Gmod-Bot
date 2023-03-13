local BOT		=	FindMetaTable( "Player" )
local Zone		=	FindMetaTable( "CNavArea" )
local Lad		=	FindMetaTable( "CNavLadder" )
local Open_List		=	{}
local Node_Data		=	{}
util.AddNetworkString( "TRizzleBotFlashlight" )

function TBotCreate( ply , cmd , args ) -- This code defines stats of the bot when it is created.  
	if !args[ 1 ] then return end 
	if game.SinglePlayer() or player.GetCount() >= game.MaxPlayers() then error( "Cannot create new bot there are no avaliable player slots!" ) end
	
	local NewBot				=	player.CreateNextBot( args[ 1 ] ) -- Create the bot and store it in a varaible.
	
	NewBot.IsTRizzleBot			=	true -- Flag this as our bot so we don't control other bots, Only ours!
	NewBot.Owner				=	ply -- Make the player who created the bot its "owner"
	NewBot.FollowDist			=	tonumber( args[ 2 ] ) or 200 -- This is how close the bot will follow it's owner
	NewBot.DangerDist			=	tonumber( args[ 3 ] ) or 300 -- This is how far the bot can be from it's owner when in combat
	NewBot.Melee				=	args[ 4 ] or "weapon_crowbar" -- This is the melee weapon the bot will use
	NewBot.Pistol				=	args[ 5 ] or "weapon_pistol" -- This is the pistol the bot will use
	NewBot.Shotgun				=	args[ 6 ] or "weapon_shotgun" -- This is the shotgun the bot will use
	NewBot.Rifle				=	args[ 7 ] or "weapon_smg1" -- This is the rifle/smg the bot will use
	NewBot.Sniper				=	args[ 8 ] or "weapon_crossbow" -- This is the sniper the bot will use
	NewBot.MeleeDist			=	tonumber( args[ 9 ] ) or 80 -- If an enemy is closer than this, the bot will use its melee
	NewBot.PistolDist			=	tonumber( args[ 10 ] ) or 1300 -- If an enemy is closer than this, the bot will use its pistol
	NewBot.ShotgunDist			=	tonumber( args[ 11 ] ) or 300 -- If an enemy is closer than this, the bot will use its shotgun
	NewBot.RifleDist			=	tonumber( args[ 12 ] ) or 900 -- If an enemy is closer than this, the bot will use its rifle
	NewBot.HealThreshold			=	tonumber( args[ 13 ] ) or 100 -- If the bot's health drops below this and the bot is not in combat the bot will use its medkit
	NewBot.CombatHealThreshold		=	tonumber( args[ 14 ] ) or 25 -- If the bot's health drops below this and the bot is not in combat the bot will use its medkit
	NewBot.PlayerModel			=	args[ 15 ] or "kleiner" -- This is the player model the bot will use
	
	local param2 = args[ 16 ] or 1
	TBotSpawnWithPreferredWeapons( ply, cmd, { args[ 1 ], param2 } )
	TBotSetPlayerModel( ply, cmd, { args[ 1 ], NewBot.PlayerModel } )
	NewBot:TBotResetAI() -- Fully reset your bots AI.
	
end

function TBotSetFollowDist( ply, cmd, args ) -- Command for changing the bots "Follow" distance to something other than the default.  
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local followdist = tonumber( args[ 2 ] ) or 200
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.FollowDist = followdist
			break
		end
		
	end

end

function TBotSetDangerDist( ply, cmd, args ) -- Command for changing the bots "Danger" distance to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local dangerdist = tonumber( args[ 2 ] ) or 300
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.DangerDist = dangerdist
			break
		end
		
	end

end

function TBotSetMelee( ply, cmd, args ) -- Command for changing the bots melee to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local melee = args[ 2 ] or "weapon_crowbar"
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.Melee = melee
			break
		end
		
	end

end

function TBotSetPistol( ply, cmd, args ) -- Command for changing the bots pistol to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local pistol = args[ 2 ] or "weapon_pistol"
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.Pistol = pistol
			break
		end
		
	end

end

function TBotSetShotgun( ply, cmd, args ) -- Command for changing the bots shotgun to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local shotgun = args[ 2 ] or "weapon_shotgun"
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.Shotgun = shotgun
			break
		end
		
	end

end

function TBotSetRifle( ply, cmd, args ) -- Command for changing the bots rifle to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] or "weapon_smg1"
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.Rifle = rifle
			break
		end
		
	end

end

function TBotSetSniper( ply, cmd, args ) -- Command for changing the bots sniper to something other than the default. 
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifle = args[ 2 ] or "weapon_crossbow"
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.Sniper = rifle
			break
		end
		
	end

end

function TBotSetMeleeDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local meleedist = tonumber( args[ 2 ] ) or 80
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.MeleeDist = meleedist
			break
		end
		
	end

end

function TBotSetPistolDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local pistoldist = tonumber( args[ 2 ] ) or 1300
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.PistolDist = pistoldist
			break
		end
		
	end

end

function TBotSetShotgunDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local shotgundist = tonumber( args[ 2 ] ) or 300
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.ShotgunDist = shotgundist
			break
		end
		
	end

end

function TBotSetRifleDist( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local rifledist = tonumber( args[ 2 ] ) or 900
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			bot.RifleDist = rifledist
			break
		end
		
	end

end

function TBotSetHealThreshold( ply, cmd, args )
	if !args[ 1 ] then return end
	
	local targetbot = args[ 1 ]
	local healthreshold = tonumber( args[ 2 ] ) or 100
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
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
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
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
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
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
	
	for k, bot in ipairs( player.GetBots() ) do
		
		if bot.IsTRizzleBot and bot:Nick() == targetbot and bot.Owner == ply then
			
			if spawnwithweapons == 0 then bot.SpawnWithWeapons = false
			else bot.SpawnWithWeapons = true end
			break
		end
		
	end

end

function TBotSetDefault( ply, cmd, args )
	if !args[ 1 ] then return end
	if args[ 2 ] then args[ 2 ] = nil end
	
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

end

concommand.Add( "TRizzleCreateBot" , TBotCreate , nil , "Creates a TRizzle Bot with the specified parameters. Example: TRizzleCreateBot <botname> <followdist> <dangerdist> <melee> <pistol> <shotgun> <rifle> <sniper> <meleedist> <pistoldist> <shotgundist> <rifledist> <healthreshold> <combathealthreshold> <playermodel> Example2: TRizzleCreateBot Bot 200 300 weapon_crowbar weapon_pistol weapon_shotgun weapon_smg1 weapon_crossbow 80 1300 300 900 100 25 alyx" )
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
	
	self.Enemy				=	nil -- Refresh our enemy.
	self.EnemyList			=	{} -- This is the list of enemies the bot can see.
	self.TimeInCombat		=	0 -- This is how long the bot has been in combat
	self.LastCombatTime		=	0 -- This was how long ago the bot was in combat
	self.Jump				=	false -- Stop jumping
	self.NextJump				=	CurTime() -- This is the next time the bot is allowed to jump
	self.Crouch				=	false -- Stop crouching
	self.HoldCrouch				=	CurTime() -- This is how long the bot should hold its crouch button
	self.PressUse				=	false -- Stop using
	self.FullReload			        =	false -- Stop reloading
	self.Light				=	false -- Turn off the bot's flashlight
	self.Goal				=	nil -- The vector goal we want to get to.
	self.NavmeshNodes		        =	{} -- The nodes given to us by the pathfinder
	self.Path				=	nil -- The nodes converted into waypoints by our visiblilty checking.
	self.PathTime			        =	CurTime() + 1.0 -- This will limit how often the path gets recreated
	
	self:TBotCreateThinking() -- Start our AI
	
end


hook.Add( "StartCommand" , "TRizzleBotAIHook" , function( bot , cmd )
	if !IsValid( bot ) or !bot:IsBot() or !bot:Alive() or !bot.IsTRizzleBot then return end
	-- Make sure we can control this bot and its not a player.
	
	cmd:ClearButtons() -- Clear the bots buttons. Shooting, Running , jumping etc...
	cmd:ClearMovement() -- For when the bot is moving around.
	local buttons	=	0
	
	-- Better make sure they exist of course.
	if IsValid( bot.Enemy ) then
		
		local trace = util.TraceLine( { start = bot:EyePos(), endpos = bot.Enemy:EyePos() - Vector( 0, 0, 10 ), filter = bot, mask = TRACE_MASK_SHOT } )
		
		-- Turn and face our enemy!
		if trace.Entity == bot.Enemy and !bot:IsActiveWeaponRecoilHigh() then
		
			-- Can we aim the enemy's head?
			bot:AimAtPos( ( bot.Enemy:EyePos() - Vector( 0, 0, 10 ) ) )
		
		else
			
			-- If we can't aim at our enemy's head aim at the center of their body instead.
			bot:AimAtPos( bot.Enemy:WorldSpaceCenter() )
		
		end
		
		bot:SelectBestWeapon( cmd )
		
		local botWeapon = bot:GetActiveWeapon()
		
		if botWeapon:IsWeapon() and bot.FullReload and ( botWeapon:Clip1() >= botWeapon:GetMaxClip1() or bot:GetAmmoCount( botWeapon:GetPrimaryAmmoType() ) < botWeapon:GetMaxClip1() or botWeapon:GetClass() != bot.Shotgun ) then bot.FullReload = false end -- Fully reloaded :)
		
		if math.random(2) == 1 and botWeapon:IsWeapon() and !bot.FullReload and botWeapon:GetClass() != "weapon_medkit" and ( bot:GetEyeTraceNoCursor().Entity == bot.Enemy or bot:IsCursorOnTarget() or (bot.Enemy:GetPos() - bot:GetPos()):Length() < bot.MeleeDist ) then
			buttons = buttons + IN_ATTACK
		end
		
		if math.random(2) == 1 and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" and bot.CombatHealThreshold > bot:Health() then
			buttons = buttons + IN_ATTACK2
		end
		
		if math.random(2) == 1 and botWeapon:IsWeapon() and botWeapon:Clip1() == 0 then
			if botWeapon:GetClass() == bot.Shotgun then bot.FullReload = true end
			buttons = buttons + IN_RELOAD
		end
		
		cmd:SetButtons( bot:HandleButtons( buttons ) )
		bot:TBotUpdateMovement( cmd )
		
		if isvector( bot.Goal ) and (bot.Owner:GetPos() - bot.Goal):Length() < bot.FollowDist then
		
			bot:TBotUpdateMovement( cmd )
		
		elseif (bot.Owner:GetPos() - bot:GetPos()):Length() > bot.DangerDist then
			
			bot:TBotSetNewGoal( bot.Owner:GetPos() )
			
		end
		
	elseif IsValid( bot.Owner ) and bot.Owner:Alive() then
		
		-- If the bot is not in combat then the bot should check if any of its teammates need healing
		local healTarget = bot:TBotFindClosestTeammate()
		if IsValid( healTarget ) and bot:HasWeapon( "weapon_medkit" ) then
		
			buttons = buttons + bot:HealTeammates( cmd, healTarget )
			
		else
		
			bot:ReloadWeapons( cmd )
			local botWeapon = bot:GetActiveWeapon()
			if math.random(2) == 1 and botWeapon:IsWeapon() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:Clip1() < botWeapon:GetMaxClip1() then
				buttons = buttons + IN_RELOAD
			end
		end
			
		cmd:SetButtons( bot:HandleButtons( buttons ) )
		bot:TBotUpdateMovement( cmd )
		
		if isvector( bot.Goal ) and (bot.Owner:GetPos() - bot.Goal):Length() < bot.FollowDist then
			
			bot:TBotUpdateMovement( cmd )
		
		elseif (bot.Owner:GetPos() - bot:GetPos()):Length() > bot.FollowDist then
			
			bot:TBotSetNewGoal( bot.Owner:GetPos() )
		
		end
	end
	
end)

function BOT:HandleButtons( buttons )

	local Close		=	navmesh.GetNearestNavArea( self:GetPos() )
	
	if IsValid ( Close ) then -- If their is no nav_mesh this will not run to prevent the addon from spamming errors
		
		if Close:HasAttributes( NAV_MESH_JUMP ) then
			
			self.Jump		=	true
			
		end
		
		if Close:HasAttributes( NAV_MESH_CROUCH ) then
			
			self.Crouch		=	true
			
		end
		
	end
	
	-- Run if we are too far from our owner
	if (self.Owner:GetPos() - self:GetPos()):Length() > self.DangerDist and self:GetSuitPower() > 20 then 
		
		buttons = buttons + IN_SPEED 
	
	end
	
	if self.Crouch or !self:IsOnGround() or self.HoldCrouch > CurTime() then 
	
		buttons = buttons + IN_DUCK
		
		if self.Crouch or !self:IsOnGround() then self.HoldCrouch = CurTime() + 0.3 end
		self.Crouch = false
		
	end
	
	if self:Is_On_Ladder() then
		
		buttons = buttons + IN_FORWARD
		
		return buttons
		
	end
	
	if self.Jump and self.NextJump < CurTime() then 
	
		buttons = buttons + IN_JUMP 
		
		self.NextJump = CurTime() + 1.0 -- This cooldown is to prevent the bot from pressing and holding its jump button
		self.Jump = false 
		
	end
	
	local door = self:GetEyeTrace().Entity
	
	if self.PressUse and (door:GetPos() - self:GetPos()):Length() < 80 then 
	
		if IsDoor( door ) then door:Use(self, self, USE_ON, 0.0) end
		-- else door:Use(self, self, USE_TOGGLE, 0.0) end -- I might add a way for the bot to push buttons the player tells them to
		
		self.PressUse = false 
		
	end
	
	return buttons
	
end

net.Receive( "TRizzleBotFlashlight", function( _, ply) 

	local tab = net.ReadTable()
	if !istable( tab ) or table.IsEmpty( tab ) then return end
	
	for bot, light in pairs( tab ) do
	
		light = Vector(math.Round(light.x, 2), math.Round(light.y, 2), math.Round(light.z, 2))
		
		if light == vector_origin then -- Vector( 0, 0, 0 )
		
			bot.Light	=	true
			
		else
		
			bot.Light	=	false
			
		end
		
	end
end)

function BOT:IsInCombat()

	if IsValid ( self.Enemy ) then
	
		self.LastCombatTime = CurTime() + 5.0
		return true
		
	end
	
	if self.LastCombatTime > CurTime() then return true end
	
	return false
	
end

function BOT:AimAtPos( Pos )

	local currentAngles = self:EyeAngles() + self:GetViewPunchAngles()
	local targetPos = ( Pos - self:EyePos() ):GetNormalized()
	
	local lerp = FrameTime() * math.random(10, 20)
	
	local angles = LerpAngle( lerp, currentAngles, targetPos:Angle() )
	
	-- back out "punch angle"
	angles = angles - self:GetViewPunchAngles()

	self:SetEyeAngles( angles )
end

-- Got this from CS:GO Source Code, made some changes so it works for Lua
function BOT:IsActiveWeaponRecoilHigh()

	local angles = self:GetViewPunchAngles()
	local highRecoil = -1.5
	return (angles.x < highRecoil)
end

-- This will check if the bot's cursor is close the enemy the bot is fighting
function BOT:PointWithinViewAngle( targetpos )
	
	local trace = util.TraceLine( { start = self:WorldSpaceCenter(), endpos = targetpos, filter = self, mask = TRACE_MASK_SHOT } )
	
	if trace.Entity != self.Enemy then return false end
	
	local EntWidth = self.Enemy:BoundingRadius() * 0.5
	local pos = targetpos - self:EyePos()
	local fov = math.cos( math.atan( EntWidth / pos:Length() ) )
	local diff = self:GetAimVector():Dot( pos )
	
	local length = pos:LengthSqr()
	return diff * diff > length * fov * fov

end

function BOT:IsCursorOnTarget()

	if IsValid( self.Enemy ) then
		-- we must check eyepos and worldspacecenter
		-- maybe in the future add more points

		if self:PointWithinViewAngle( self.Enemy:WorldSpaceCenter() ) then
			return true
		end

		return self:PointWithinViewAngle( self.Enemy:EyePos() - Vector( 0, 0, 10 ) )
	
	end
end

function BOT:SelectBestWeapon( cmd )
	
	-- This will select the best weapon based on the bot's current distance from its enemy
	if self:HasWeapon( "weapon_medkit" ) and self.CombatHealThreshold > self:Health() then
		
		-- The bot will heal themself if they get too injured during combat
		cmd:SelectWeapon( self:GetWeapon( "weapon_medkit" ) )
		
	elseif self:HasWeapon( self.Sniper ) and self:GetWeapon( self.Sniper ):HasAmmo() and ( (self.Enemy:GetPos() - self:GetPos()):Length() > self.PistolDist or !self:HasWeapon( self.Pistol ) or !self:GetWeapon( self.Pistol ):HasAmmo() ) then
		
		-- If an enemy is very far away the bot should use its sniper
		cmd:SelectWeapon( self:GetWeapon( self.Sniper ) )
		
	elseif self:HasWeapon( self.Pistol ) and self:GetWeapon( self.Pistol ):HasAmmo() and ( (self.Enemy:GetPos() - self:GetPos()):Length() > self.RifleDist or !self:HasWeapon( self.Rifle ) or !self:GetWeapon( self.Rifle ):HasAmmo() )then
		
		-- If an enemy is far the bot, the bot should use its pistol
		cmd:SelectWeapon( self:GetWeapon( self.Pistol ) )
		
	elseif self:HasWeapon( self.Rifle ) and self:GetWeapon( self.Rifle ):HasAmmo() and ( (self.Enemy:GetPos() - self:GetPos()):Length() > self.ShotgunDist or !self:HasWeapon( self.Shotgun ) or !self:GetWeapon( self.Shotgun ):HasAmmo() ) then
		
		-- If an enemy gets too far but is still close the bot should use its rifle
		cmd:SelectWeapon( self:GetWeapon( self.Rifle ) )
		
	elseif self:HasWeapon( self.Shotgun ) and self:GetWeapon( self.Shotgun ):HasAmmo() and ( (self.Enemy:GetPos() - self:GetPos()):Length() > self.MeleeDist or !self:HasWeapon( self.Melee ) ) then
		
		-- If an enemy gets too far but is still close the bot should use its shotgun
		cmd:SelectWeapon( self:GetWeapon( self.Shotgun ) )
		
	elseif self:HasWeapon( self.Melee ) then
		
		-- If an enemy gets too close the bot should use its melee
		cmd:SelectWeapon( self:GetWeapon( self.Melee ) )
		
	end
end

function BOT:HealTeammates( cmd, healTarget )

	-- This is where the bot will heal themself, their owner, and their teammates when not in combat
	local botWeapon = self:GetActiveWeapon()
	if !botWeapon:IsWeapon() or botWeapon:GetClass() != "weapon_medkit" then cmd:SelectWeapon( self:GetWeapon( "weapon_medkit" ) ) end
	
	if math.random(2) == 1 and healTarget == self then return IN_ATTACK2 
	elseif healTarget == self then return 0 end
	
	local lerp = FrameTime() * math.random(8, 10)
	self:SetEyeAngles( LerpAngle(lerp, self:EyeAngles(), ( ( healTarget:GetShootPos() - Vector( 0, 0, 10 ) ) - self:GetShootPos() ):GetNormalized():Angle() ) )
	
	if math.random(2) == 1 and self:GetEyeTrace().Entity == healTarget then return IN_ATTACK end
	
	return 0 -- The bot has to spam click its mouse1 and mouse2 button inorder to heal so this is a backup to prevent this function from returning nil
	
end

function BOT:ReloadWeapons( cmd )
	
	-- The bot should reload weapons that need to be reloaded
	if self:HasWeapon( self.Sniper ) and self:GetWeapon( self.Sniper ):Clip1() < self:GetWeapon( self.Sniper ):GetMaxClip1() then
		
		cmd:SelectWeapon( self:GetWeapon( self.Sniper ) )
		
	elseif self:HasWeapon( self.Pistol ) and self:GetWeapon( self.Pistol ):Clip1() < self:GetWeapon( self.Pistol ):GetMaxClip1() then
		
		cmd:SelectWeapon( self:GetWeapon( self.Pistol ) )
		
	elseif self:HasWeapon( self.Rifle ) and self:GetWeapon( self.Rifle ):Clip1() < self:GetWeapon( self.Rifle ):GetMaxClip1() then
		
		cmd:SelectWeapon( self:GetWeapon( self.Rifle ) )
		
	elseif self:HasWeapon( self.Shotgun ) and self:GetWeapon( self.Shotgun ):Clip1() < self:GetWeapon( self.Shotgun ):GetMaxClip1() then
		
		cmd:SelectWeapon( self:GetWeapon( self.Shotgun ) )
		
	end
end

function BOT:RestoreAmmo()
	
	-- This is kind of a cheat, but the bot will only slowly recover ammo when not in combat
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle		=	self:GetWeapon( self.Rifle )
	local shotgun		=	self:GetWeapon( self.Shotgun )
	local sniper		=	self:GetWeapon( self.Sniper )
	local pistol_ammo	=	nil
	local rifle_ammo	=	nil
	local shotgun_ammo	=	nil
	local sniper_ammo	=	nil
	
	if IsValid ( pistol ) then pistol_ammo		=	self:GetAmmoCount( pistol:GetPrimaryAmmoType() ) end
	if IsValid ( rifle ) then rifle_ammo		=	self:GetAmmoCount( rifle:GetPrimaryAmmoType() ) end
	if IsValid ( shotgun ) then shotgun_ammo	=	self:GetAmmoCount( shotgun:GetPrimaryAmmoType() ) end
	if IsValid ( sniper ) then sniper_ammo		=	self:GetAmmoCount( sniper:GetPrimaryAmmoType() ) end
	
	if pistol_ammo != nil and self:HasWeapon( self.Pistol ) and pistol_ammo < 100 then
		
		self:GiveAmmo( 1, pistol:GetPrimaryAmmoType(), true )
		
	end
	
	if rifle_ammo != nil and self:HasWeapon( self.Rifle ) and rifle_ammo < 250 then
		
		self:GiveAmmo( 1, rifle:GetPrimaryAmmoType(), true )
		
	end
	
	if shotgun_ammo != nil and self:HasWeapon( self.Shotgun ) and shotgun_ammo < 60 then
		
		self:GiveAmmo( 1, shotgun:GetPrimaryAmmoType(), true )
		
	end
	
	if sniper_ammo != nil and self:HasWeapon( self.Sniper ) and sniper_ammo < 40 then
		
		self:GiveAmmo( 1, sniper:GetPrimaryAmmoType(), true )
		
	end
	
end

-- I should make this use the Entity MetaTable
function IsDoor( v )

	if (v:GetClass() == "func_door") or (v:GetClass() == "prop_door_rotating") or (v:GetClass() == "func_door_rotating") then
        
		return true
    
	end
	
	return false
	
end


-- When a player leaves the server, every bot "owned" by the player should leave as well
hook.Add( "PlayerDisconnected" , "TRizzleBotPlayerLeave" , function( ply )
	
	if !ply:IsBot() and !ply.IsTRizzleBot then 
		
		for k, bot in ipairs( player.GetBots() ) do
		
			if bot.IsTRizzleBot and bot.Owner == ply then
			
				bot:Kick( "Owner " .. ply:Nick() .. " has left the server" )
			
			end
		end
		
	end
	
end)

-- Just a simple way to respawn a bot.
hook.Add( "PostPlayerDeath" , "TRizzleBotRespawn" , function( ply )
	
	if ply:IsBot() and ply.IsTRizzleBot then 
		
		timer.Simple( 3 , function()
			
			if IsValid( ply ) and !ply:Alive() then
				
				ply:Spawn()
				
			end
			
		end)
		
	end
	
end)

-- Reset their AI on spawn.
hook.Add( "PlayerSpawn" , "TRizzleBotSpawnHook" , function( ply )
	
	if ply:IsBot() and ply.IsTRizzleBot then
		
		ply:TBotResetAI() -- For some reason running the a time for 0.0 seconds works, but if I don't use a timer nothing works at all
		timer.Simple( 0.0 , function()
			
			if IsValid( ply ) and ply:Alive() then
				
				ply:SetModel( ply.PlayerModel )
				
				if ply.SpawnWithWeapons then
					
					if !ply:HasWeapon( ply.Pistol ) then ply:Give( ply.Pistol ) end
					if !ply:HasWeapon( ply.Shotgun ) then ply:Give( ply.Shotgun ) end
					if !ply:HasWeapon( ply.Rifle ) then ply:Give( ply.Rifle ) end
					if !ply:HasWeapon( ply.Sniper ) then ply:Give( ply.Sniper ) end
					if !ply:HasWeapon( ply.Melee ) then ply:Give( ply.Melee ) end
					if !ply:HasWeapon( "weapon_medkit" ) then ply:Give( "weapon_medkit" ) end
					
				end
				
				-- For some reason the bot's run and walk speed is slower than a human player
				ply:SetRunSpeed( ply.Owner:GetRunSpeed() )
				ply:SetWalkSpeed( ply.Owner:GetWalkSpeed() )
				
			end
			
		end)
		
	end
	
end)

-- Checks if its current enemy is still alive and still visible to the bot
function BOT:IsCurrentEnemyAlive()
	
	if !IsValid( self.Enemy ) then self.Enemy							=	nil
	elseif self.Enemy:IsPlayer() and !self.Enemy:Alive() then self.Enemy				=	nil -- Just incase the bot's enemy is set to a player even though the bot should only target NPCS and "hopefully" NEXTBOTS 
	elseif !self.Enemy:Visible( self ) then self.Enemy						=	nil
	elseif self.Enemy:IsNPC() and ( self.Enemy:GetNPCState() == NPC_STATE_DEAD or (self.Enemy:Disposition( self ) != D_HT and self.Enemy:Disposition( self.Owner ) != D_HT) ) then self.Enemy	=	nil
	elseif GetConVar( "ai_ignoreplayers" ):GetInt() != 0 or GetConVar( "ai_disabled" ):GetInt() != 0 then	self.Enemy	=	nil end
	
end

function BOT:FindNearbySeat()
	
	local targetdist			=	200 -- This will allow the bot to select the closest vehicle to it.
	local target				=	nil -- This is the closest vehicle to the bot.
	
	for k, v in ipairs( ents.GetAll() ) do
		
		if IsValid ( v ) and v:IsVehicle() and v:GetDriver() == NULL then -- The bot should enter the closest vehicle to it
			
			local vehicledist = (v:GetPos() - self:GetPos()):Length()
			
			if vehicledist < targetdist then 
				target = v
				targetdist = vehicledist
			end
			
		end
		
	end
	
	return target
	
end

-- The main AI is here.
function BOT:TBotCreateThinking()
	
	local index		=	self:EntIndex()
	
	-- I used math.Rand as a personal preference, It just prevents all the timers being ran at the same time
	-- as other bots timers.
	timer.Create( "trizzle_bot_think" .. index , math.Rand( 0.08 , 0.15 ) , 0 , function()
		
		if IsValid( self ) and self:Alive() then
			
			-- A quick condition statement to check if our enemy is no longer a threat.
			self:IsCurrentEnemyAlive()
			
			if GetConVar( "ai_ignoreplayers" ):GetInt() == 0 and GetConVar( "ai_disabled" ):GetInt() == 0 then self:TBotFindClosestEnemy() end
			
			local tab = player.GetHumans()
			if #tab > 0 then
				local ply = table.Random(tab)
				
				net.Start( "TRizzleBotFlashlight" )
				net.Send( ply )
			end
			
			if self:IsInCombat() and self.TimeInCombat < 30 then 
				
				self.TimeInCombat = self.TimeInCombat + 0.15
				
			elseif !self:IsInCombat() then
				
				if self.TimeInCombat > 0 then self.TimeInCombat = self.TimeInCombat - 0.15 end
				self:RestoreAmmo() 
				
			end
			
			if self.SpawnWithWeapons then
				
				if !self:HasWeapon( self.Pistol ) then self:Give( self.Pistol ) end
				if !self:HasWeapon( self.Shotgun ) then self:Give( self.Shotgun ) end
				if !self:HasWeapon( self.Rifle ) then self:Give( self.Rifle ) end
				if !self:HasWeapon( self.Sniper ) then self:Give( self.Sniper ) end
				if !self:HasWeapon( self.Melee ) then self:Give( self.Melee ) end
				if !self:HasWeapon( "weapon_medkit" ) then self:Give( "weapon_medkit" ) end
				
			end
			
			if self.Owner:InVehicle() and !self:InVehicle() then
			
				local vehicle = self:FindNearbySeat()
				
				if IsValid( vehicle ) then self:EnterVehicle( vehicle ) end -- I should make the bot press its use key instead of this hack
			
			end
			
			if !self.Owner:InVehicle() and self:InVehicle() then
			
				self:ExitVehicle() -- Should I make the bot press its use key instead?
			
			end
			
			-- I have to set the flashlight state because some addons have mounted flashlights and I can't check if they are on or not, "This will prevent the flashlight on and off spam"
			if self:CanUseFlashlight() and !self:FlashlightIsOn() and self.Light and self:GetSuitPower() > 50 then
				
				self:Flashlight( true )
				
			elseif self:CanUseFlashlight() and self:FlashlightIsOn() and !self.Light then
				
				self:Flashlight( false )
				
			end
			
		else
			
			timer.Remove( "trizzle_bot_think" .. index ) -- We don't need to think while dead.
			
		end
		
	end)
	
end



-- Target any hostile NPCS that is visible to us.
function BOT:TBotFindClosestEnemy()
	local VisibleEnemies		=	{} -- This is how many enemies the bot can see. Currently not used......yet
	local targetdist			=	10000 -- This will allow the bot to select the closest enemy to it.
	local target				=	self.Enemy -- This is the closest enemy to the bot.
	
	for k, v in ipairs( ents.GetAll() ) do
		
		if IsValid ( v ) and v:IsNPC() and v:GetNPCState() != NPC_STATE_DEAD and (v:Disposition( self ) == D_HT or v:Disposition( self.Owner ) == D_HT) then -- The bot should attack any NPC that is hostile to them or their owner. D_HT means hostile/hate
			
			if v:Visible( self ) then
				local enemydist = (v:GetPos() - self:GetPos()):Length()
				VisibleEnemies[ #VisibleEnemies + 1 ]		=	v
				if enemydist < targetdist then 
					target = v
					targetdist = enemydist
				end
			end
			
		end
		
	end
	
	self.Enemy		=	target
	self.EnemyList		=	VisibleEnemies
	
end

-- Heal any player or bot that is visible to us.
function BOT:TBotFindClosestTeammate()
	local targetdist			=	80 -- This will allow the bot to select the closest teammate to it.
	local target				=	nil -- This is the closest teammate to the bot.
	
	--The bot should heal its owner and itself before it heals anyone else
	if IsValid( self.Owner ) and self.Owner:Alive() and self.Owner:Health() < self.HealThreshold and (self.Owner:GetPos() - self:GetPos()):Length() < 80 then return self.Owner
	elseif self:Health() < self.HealThreshold then return self end

	for k, v in ipairs( player.GetAll() ) do
		
		if IsValid ( v ) and v:Health() < self.HealThreshold then -- The bot will heal any teammate that needs healing.
			
			if v:Visible( self ) and v:Alive() then -- Make sure we can actually see them and they are alive.
				local teammatedist = (v:GetPos() - self:GetPos()):Length()
				if teammatedist < targetdist then 
					target = v
					targetdist = teammatedist
				end
			end
			
		end
		
	end
	
	return target
	
end

function TRizzleBotPathfinder( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if ( StartNode == GoalNode ) then return true end
	
	Prepare_Path_Find()
	
	StartNode:Node_Add_To_Open_List()
	
	local Attempts		=	0 
	-- Backup Varaible! In case something goes wrong, The game will not get into an infinite loop.
	
	while( !table.IsEmpty( Open_List ) and Attempts < 5000 ) do
		Attempts		=	Attempts + 1
		
		local Current 	=	Get_Best_Node() -- Get the lowest FCost
		
		if ( Current == GoalNode ) then
			-- We found a path! Now lets retrace it.
			
			return TRizzleBotRetracePath( StartNode, GoalNode ) -- Retrace the path and return the table of nodes.
		end
		
		for k, neighbor in ipairs( Current:Get_Connected_Areas() ) do
			local Height = 0
			
			if neighbor:Node_Get_Type() == 1 and Current:Node_Get_Type() == 1 then
				Height			=	Current:ComputeAdjacentConnectionHeightChange( neighbor )
				
				if !Current:IsUnderwater() and !neighbor:IsUnderwater() and -Height < 200 and Height > 58 then
					-- We can't jump that high.
					
					continue
				end
			end
			
			-- G + H = F
			local NewCostSoFar		=	Current:Get_G_Cost() + TRizzleBotRangeCheck( Current , neighbor , Height )
			
			if neighbor:Node_Is_Open() or neighbor:Node_Is_Closed() and neighbor:Get_G_Cost() <= NewCostSoFar then
				
				continue
				
			else
				neighbor:Set_G_Cost( NewCostSoFar )
				neighbor:Set_F_Cost( NewCostSoFar + TRizzleBotRangeCheck( neighbor , GoalNode ) )
				
				if neighbor:Node_Is_Closed() then
					
					neighbor:Node_Remove_From_Closed_List()
					
				end
				
				neighbor:Node_Add_To_Open_List()
				
				-- Parenting of the nodes so we can trace the parents back later.
				neighbor:Set_Parent_Node( Current )
			end
			
		end
		
	end
	
	return false
end



function TRizzleBotRangeCheck( FirstNode , SecondNode , Ladder , Height )
	-- Some helper errors.
	if !IsValid( FirstNode ) then error( "Bad argument #1 CNavArea or CNavLadder expected got " .. type( FirstNode ) ) end
	if !IsValid( FirstNode ) then error( "Bad argument #2 CNavArea or CNavLadder expected got " .. type( SecondNode ) ) end
	
	if FirstNode:Node_Get_Type() == 2 then return FirstNode:GetLength()
	elseif SecondNode:Node_Get_Type() == 2 then return SecondNode:GetLength() end
	
	if Ladder then return Ladder:GetLength() end
	
	DefaultCost = FirstNode:GetCenter():Distance( SecondNode:GetCenter() )
	
	if isnumber( Height ) and Height > 32 then
		
		DefaultCost		=	DefaultCost * 3
		-- Jumping is slower than ground movement.
		
	end
	
	if isnumber( Height ) and -Height > 32 then
	
		DefaultCost		=	DefaultCost + ( math.abs( Height ) * 1.5 )
		-- Falling is risky and the bot might take fall damage.
		
	end
	
	-- Crawling through a vent is very slow.
	if SecondNode:HasAttributes( NAV_MESH_CROUCH ) then 
		
		DefaultCost	=	DefaultCost * 7
		
	end
	
	-- The bot should avoid this area unless alternatives are too dangerous or too far.
	if SecondNode:HasAttributes( NAV_MESH_AVOID ) then 
		
		DefaultCost	=	DefaultCost * 8
		
	end
	
	-- We will try not to swim since it can be slower than running on land, it can also be very dangerous, Ex. "Acid, Lava, Etc."
	if SecondNode:IsUnderwater() then
	
		DefaultCost		=	DefaultCost * 2
		
	end
	
	return DefaultCost
end


function TRizzleBotRetracePath( StartNode , GoalNode )
	
	local NodePath		=	{ GoalNode }
	
	local Current		=	GoalNode
	
	local Attempts		=	0
	
	while ( Current != StartNode and Attempts < 5001 ) do
		
		Attempts = Attempts + 1
		
		Current			=	Current:Get_Parent_Node()
		
		NodePath[ #NodePath + 1 ]	=	Current
		
	end
	
	
	return NodePath
end

-- This is a cheaper version of the pathfinder, their is only one problem though, it can't use ladders :(
function TRizzleBotPathfinderCheap( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if StartNode == GoalNode then return true end
	
	StartNode:ClearSearchLists()
	
	StartNode:AddToOpenList()
	
	StartNode:SetCostSoFar( 0 )
	
	StartNode:SetTotalCost( TRizzleBotRangeCheck( StartNode , GoalNode ) )
	
	StartNode:UpdateOnOpenList()
	
	local Final_Path		=	{}
	local Trys			=	0 -- Backup! Prevent crashing.
	local GoalCen			=	GoalNode:GetCenter()
	
	while ( !StartNode:IsOpenListEmpty() and Trys < 50000 ) do
		Trys	=	Trys + 1
		
		local Current	=	StartNode:PopOpenList()
		
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
				
				if newArea == nil then
				
					continue
					
				end
			
			else
			
				break
				
			end
		
			if newArea == area then 
			
				continue
				
			end
			
			local Height	=	Current:ComputeAdjacentConnectionHeightChange( newArea )
			-- Optimization,Prevent computing the height twice.
			
			local NewCostSoFar		=	Current:GetCostSoFar() + TRizzleBotRangeCheck( Current , newArea , ladder , Height )
			
			if ladder != nil then Height = 0 end
			
			if !Current:IsUnderwater() and !newArea:IsUnderwater() and -Height < 200 and Height > 58 then
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
	
	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	
	local Trys			=	0 -- Backup! Prevent crashing.
	
	local NewPath	=	{ GoalNode }
	
	local Current	=	GoalNode
	
	while( Current:GetParent() != StartNode and Trys < 50001 ) do
	
		Current		=	Current:GetParent()
		Parent		=	Current:GetParentHow()
		
		--print( Current )
		--print( Parent )
		
		if Parent == GO_LADDER_UP or Parent == GO_LADDER_DOWN then
		
			local list = Current:GetLadders()
			print( "Ladders: " .. #list )
			for k, ladder in ipairs( list ) do
				print( ladder:GetTopForwardArea() )
				print( ladder:GetTopLeftArea() )
				print( ladder:GetTopRightArea() )
				print( ladder:GetTopBehindArea() )
				if ladder:GetTopForwardArea() == Current or ladder:GetTopLeftArea() == Current or ladder:GetTopRightArea() == Current or ladder:GetTopBehindArea() == Current or ladder:GetBottomArea() == Current then
				
					NewPath[ #NewPath + 1 ] = ladder
					break
					
				end
			end
		else
			
			NewPath[ #NewPath + 1 ] = Current
			
		end
		
	end
	
	return NewPath
end

function BOT:TBotSetNewGoal( NewGoal )
	if !isvector( NewGoal ) then error( "Bad argument #1 vector expected got " .. type( NewGoal ) ) end
	
	if self.PathTime < CurTime() then
		self.Goal				=	NewGoal
		self.Path				=	{}
		self.PathTime			=	CurTime() + 1.0
	end
	self:TBotCreateNavTimer()
	
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
	
	for i = 1, 12 do
		
		if CheckLOS( 3 * i , pos1 , pos2 ) == false then return false end
		
	end
	
	return true
end

-- Creates waypoints using the nodes.
function BOT:ComputeNavmeshVisibility()
	
	self.Path				=	{}
	
	local LastVisPos		=	self:GetPos()
	
	for k, CurrentNode in ipairs( self.NavmeshNodes ) do
		-- I should also make sure that the nodes exist as this is called 0.03 seconds after the pathfind.
		
		local NextNode		=	self.NavmeshNodes[ k + 1 ]
		
		if !IsValid( NextNode ) then
			
			self.Path[ #self.Path + 1 ]		=	{ Pos = self.Goal, IsLadder = false }
			
			break
		end
		
		if NextNode:Node_Get_Type() == 2 then
		
			local CloseToStart		=	NextNode:Get_Closest_Point( LastVisPos )
			
			LastVisPos		=	CloseToStart
			
			self.Path[ #self.Path + 1 ]		=	{ Pos = CloseToStart, IsLadder = true, LadderUp = NextNode:ClimbUpLadder( LastVisPos ) }
			
			continue
		end
		
		if CurrentNode:Node_Get_Type() == 2 then
		
			local CloseToEnd		=	CurrentNode:Get_Closest_Point( NextNode:GetCenter() )
			
			LastVisPos		=	CloseToEnd
			
			self.Path[ #self.Path + 1 ]		=	{ Pos = CloseToEnd, IsLadder = true, LadderUp = CurrentNode:ClimbUpLadder( NextNode:GetCenter() ) }
			
			continue
		end
		
		-- The next area ahead's closest point to us.
		local NextAreasClosetPointToLastVisPos		=	NextNode:GetClosestPointOnArea( LastVisPos ) + Vector( 0 , 0 , 32 )
		local OurClosestPointToNextAreasClosestPointToLastVisPos	=	CurrentNode:GetClosestPointOnArea( NextAreasClosetPointToLastVisPos ) + Vector( 0 , 0 , 32 )
		
		-- If we are visible then we shall put the waypoint there.
		if SendBoxedLine( LastVisPos , OurClosestPointToNextAreasClosestPointToLastVisPos ) == true then
			
			LastVisPos						=	OurClosestPointToNextAreasClosestPointToLastVisPos
			self.Path[ #self.Path + 1 ]		=	{ Pos = OurClosestPointToNextAreasClosestPointToLastVisPos, IsLadder = false }
			
			continue
		end
		
		local area, connection = Get_Blue_Connection( CurrentNode, NextNode )
		
		--self.Path[ #self.Path + 1 ]			=	{ Pos = connection, IsLadder = false }
		self.Path[ #self.Path + 1 ]			=	{ Pos = area, IsLadder = false }
		
		LastVisPos							=	area
		
	end
	
end


-- The main navigation code ( Waypoint handler )
function BOT:TBotNavigation()
	if !isvector( self.Goal ) then return end -- A double backup!
	
	-- The CNavArea we are standing on.
	self.StandingOnNode			=	navmesh.GetNearestNavArea( self:GetPos() )
	if !IsValid( self.StandingOnNode ) then return end -- The map has no navmesh.
	
	
	if !istable( self.Path ) or !istable( self.NavmeshNodes ) or table.IsEmpty( self.Path ) or table.IsEmpty( self.NavmeshNodes ) then
		
		
		if self.BlockPathFind != true then
			
			
			-- Get the nav area that is closest to our goal.
			local TargetArea		=	navmesh.GetNearestNavArea( self.Goal )
			
			self.Path				=	{} -- Reset that.
			
			-- We will compute the path quickly if its far away rather than use my laggy pathfinder for now.
			--[[if self.Goal:Distance( self:GetPos() ) > 6000 or true then
				
				self.NavmeshNodes			=	TRizzleBotPathfinderCheap( self.StandingOnNode , TargetArea )
				
			else
				-- Find a path through the navmesh to our TargetArea
				self.NavmeshNodes		=	TRizzleBotPathfinder( self.StandingOnNode , TargetArea )
			
			end]]
			
			-- Pathfollower is not only cheaper, but it can use ladders.
			self.NavmeshNodes		=	TRizzleBotPathfinderCheap( self.StandingOnNode , TargetArea )
			
			-- There is no way we can get there! Remove our goal.
			if self.NavmeshNodes == false then
				
				-- In case we fail. A* will search the whole map to find out there is no valid path.
				-- This can cause major lag if the bot is doing this almost every think.
				-- To prevent this, We block the bots pathfinding completely for a while before allowing them to pathfind again.
				-- So its not as bad.
				self.BlockPathFind		        =	true
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
			
			if !self.Path[ 1 ][ "IsLadder" ] and self.Path[ 2 ] and !self.Path[ 2 ][ "IsLadder" ] and IsVecCloseEnough( self:GetPos() , Waypoint2D , 600 ) and SendBoxedLine( self.Path[ 2 ][ "Pos" ] , self:GetPos() + Vector( 0 , 0 , 15 ) ) == true and self.Path[ 2 ][ "Pos" ].z - 20 <= Waypoint2D.z then
				
				table.remove( self.Path , 1 )
				
			elseif !self.Path[ 1 ][ "IsLadder" ] and IsVecCloseEnough( self:GetPos() , Waypoint2D , 24 ) then
				
				table.remove( self.Path , 1 )
				
			elseif self.Path[ 1 ][ "IsLadder" ] and self.Path[ 1 ][ "LadderUp" ] and self:GetPos().z >= self.Path[ 1 ][ "Pos" ].z then
				
				table.remove( self.Path , 1 )
				
			elseif self.Path[ 1 ][ "IsLadder" ] and !self.Path[ 1 ][ "LadderUp" ] and self:GetPos().z <= self.Path[ 1 ][ "Pos" ].z then
			
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
	
	local index				=	self:EntIndex()
	local LastBotPos		=	self:GetPos()
	local Attempts			=	0
	
	
	timer.Create( "trizzle_bot_nav" .. index , 0.09 , 0 , function()
		
		if IsValid( self ) and self:Alive() and isvector( self.Goal ) then
			
			self:TBotNavigation()
			
			self:TBotDebugWaypoints()
			
			LastBotPos		=	Vector( LastBotPos.x , LastBotPos.y , self:GetPos().z )
			
			if IsVecCloseEnough( self:GetPos() , LastBotPos , 2 ) then
				
				self.Jump	=	true
				self.PressUse	=	true
				
				if Attempts > 10 then self.Path	=	nil end
				if Attempts > 20 then self.Goal =	nil end
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
	if !isvector( self.Goal ) then return end
	
	if !istable( self.Path ) or table.IsEmpty( self.Path ) or isbool( self.NavmeshNodes ) then
		
		local MovementAngle		=	( self.Goal - self:GetPos() ):GetNormalized():Angle()
		local lerp = FrameTime() * math.random(4, 6)
		local dropDown = IsDropDown( self:GetPos(), self.Goal )
		
		if self:OnGround() and !dropDown then
			local SmartJump		=	util.TraceLine({
				
				start			=	self:GetPos(),
				endpos			=	self:GetPos() + Vector( 0 , 0 , -16 ),
				filter			=	self,
				mask			=	MASK_SOLID,
				collisiongroup	=	COLLISION_GROUP_DEBRIS
				
			})
			
			-- This tells the bot to jump if it detects a gap in the ground
			if !SmartJump.Hit then
				
				self.Jump	=	true

			end
		end
		
		cmd:SetViewAngles( MovementAngle )
		cmd:SetForwardMove( 1000 )
		if !IsValid( self.Enemy ) or self:Is_On_Ladder() then self:SetEyeAngles( LerpAngle(lerp, self:EyeAngles(), ( self.Goal - self:GetPos() ):GetNormalized():Angle() ) ) end
		
		local GoalIn2D			=	Vector( self.Goal.x , self.Goal.y , self:GetPos().z )
		if IsVecCloseEnough( self:GetPos() , GoalIn2D , 32 ) then
			
			self.Goal			=		nil -- We have reached our goal!
			
		end
		
		return
	end
	
	if self.Path[ 1 ] then
		
		local MovementAngle		=	( self.Path[ 1 ][ "Pos" ] - self:GetPos() ):GetNormalized():Angle()
		local lerp = FrameTime() * math.random(4, 6)
		local dropDown = false
		
		if self.Path[ 2 ] then dropDown = IsDropDown( self.Path[ 1 ][ "Pos" ], self.Path[ 2 ][ "Pos" ] ) end
		
		if self:OnGround() and !dropDown and !self.Path[ 1 ][ "IsLadder" ] then
			local SmartJump		=	util.TraceLine({
				
				start			=	self:GetPos(),
				endpos			=	self:GetPos() + Vector( 0 , 0 , -16 ),
				filter			=	self,
				mask			=	MASK_SOLID,
				collisiongroup	        =	COLLISION_GROUP_DEBRIS
				
			})
			
			-- This tells the bot to jump if it detects a gap in the ground
			if !SmartJump.Hit then
				
				self.Jump	=	true

			end
		end
		
		local TargetArea		=	navmesh.GetNearestNavArea( self.Path[ 1 ][ "Pos" ] )
		
		if IsValid( TargetArea ) and TargetArea:HasAttributes( NAV_MESH_CROUCH ) then self.Crouch = true end
		if IsValid( TargetArea ) and TargetArea:HasAttributes( NAV_MESH_JUMP ) then self.Jump = true end
		
		cmd:SetViewAngles( MovementAngle )
		cmd:SetForwardMove( 1000 )
		if !IsValid ( self.Enemy ) or self:Is_On_Ladder() or self.Path[ 1 ][ "IsLadder" ] then self:SetEyeAngles( LerpAngle(lerp, self:EyeAngles(), ( self.Path[ 1 ][ "Pos" ] - self:GetPos() ):GetNormalized():Angle() ) ) end
		
	end
	
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
	
	if dir == 0 or dir == 2 then
		
		if TargetArea:GetSizeX() >= CurrentArea:GetSizeX() then
			
			local Vec	=	NumberMidPoint( CurrentArea:GetCorner( 0 ).y , CurrentArea:GetCorner( 1 ).y )
			
			local NavPoint = Vector( CurrentArea:GetCenter().x , Vec , 0 )
			
			return TargetArea:GetClosestPointOnArea( NavPoint ), Vector( NavPoint.x , CurrentArea:GetCenter().y , NavPoint.z )
		else
			
			local Vec	=	NumberMidPoint( TargetArea:GetCorner( 0 ).y , TargetArea:GetCorner( 1 ).y )
			
			local NavPoint = Vector( TargetArea:GetCenter().x , Vec , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( CurrentArea:GetClosestPointOnArea( NavPoint ) ), Vector( NavPoint.x , CurrentArea:GetCenter().y , NavPoint.z )
		end	
		
		return
	end
	
	if dir == 1 or dir == 3 then
		
		if TargetArea:GetSizeY() >= CurrentArea:GetSizeY() then
			
			local Vec	=	NumberMidPoint( CurrentArea:GetCorner( 0 ).x , CurrentArea:GetCorner( 3 ).x )
			
			local NavPoint = Vector( Vec , CurrentArea:GetCenter().y , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( NavPoint ), Vector( CurrentArea:GetCenter().x , NavPoint.y , NavPoint.z )
		else
			
			local Vec	=	NumberMidPoint( TargetArea:GetCorner( 0 ).x , TargetArea:GetCorner( 3 ).x )
			
			local NavPoint = Vector( Vec , TargetArea:GetCenter().y , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( CurrentArea:GetClosestPointOnArea( NavPoint ) ), Vector( CurrentArea:GetCenter().x , NavPoint.y , NavPoint.z )
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

-- Gives us the best node and removes it from the open list and puts it in the closed list.
function Get_Best_Node()
	
	local BestNode		=	Open_List[ #Open_List ]
	
	Open_List[ #Open_List ]		=	nil
	
	Node_Data[ BestNode:Node_Get_Type() ][ BestNode:GetID() ][ "State" ]	=	false
	
	return BestNode
end

function Sort_Open_List()
	
	local SortedList	=	{}
	local HasDoneLoop	=	false
	local UnsortedList	=	{}
	
	-- List all the nodes in the table.
	UnsortedList[ 1 ]	=	Open_List[ #Open_List ]
	Open_List[ #Open_List ]			=	nil
	
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 2 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]		=	nil
		
	end
	
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 3 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]		=	nil
		
	end

	--[[if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 4 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]				=	nil
		
	end
	
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 5 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]				=	nil
		
	end]]
	
	
	for k, v in ipairs( UnsortedList ) do
		if !IsValid( v ) then continue end
		
		if table.IsEmpty( SortedList ) then
			
			SortedList[ 1 ]		=	v
			
			continue
		end
		
		for j, y in ipairs( SortedList ) do
			
			if v == y then
				
				HasDoneLoop		=	true
				
				break
			end
			
			if v:Get_F_Cost() > y:Get_F_Cost() then
				
				if IsValid( SortedList[ j ] ) then
					
					if IsValid( SortedList[ j + 1 ] ) then
						
						SortedList[ j + 2 ]	=	SortedList[ j + 1 ]
						
					end
					
					SortedList[ j + 1 ]		=	SortedList[ j ]
					
				end
				
				SortedList[ j ]		=	v
				
				--table.insert( SortedList , j , v )
				
				HasDoneLoop		=	true
				
				break
			end
			
		end
		
		if HasDoneLoop == true then HasDoneLoop		=	false continue end
		
		SortedList[ #SortedList + 1 ]	=	v
		
	end
	
	-- Add back all the sorted nodes to the table
	for k, v in ipairs( SortedList ) do
		if !IsValid( v ) then return end
		
		Open_List[ #Open_List + 1 ]		=	v
		
	end
	
end

-- This checks if the next area is a dropdown, ( An area we can't jump back up to )
function IsDropDown( currentArea, nextArea )
	
	return nextArea.z - currentArea.z > 58 -- This can return incorrect results, I need a better way to check for this
	
end

function Zone:Get_F_Cost()
	
	
	return Node_Data[ 1 ][ self:GetID() ][ "FCost" ]
end

function Lad:Get_F_Cost()
	
	
	return Node_Data[ 2 ][ self:GetID() ][ "FCost" ]
end

-- Store the F cost, And no only for optimization.We don't do G + H as doing that everytime will give the same answer.
function Zone:Set_F_Cost( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "FCost" ]	=	cost
	
end

function Lad:Set_F_Cost( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "FCost" ]	=	cost
	
end




function Zone:Set_G_Cost( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "GCost" ]	=	cost
	
end

function Lad:Set_G_Cost( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "GCost" ]	=	cost
	
end

function Zone:Get_G_Cost( cost )
	
	return Node_Data[ 1 ][ self:GetID() ][ "GCost" ]
end

function Lad:Get_G_Cost( cost )
	
	return Node_Data[ 2 ][ self:GetID() ][ "GCost" ]
end

function Zone:Set_Parent_Node( SecondNode )
	
	Node_Data[ 1 ][ self:GetID() ][ "ParentNode" ]	=	SecondNode
	
end

function Lad:Set_Parent_Node( SecondNode )
	
	Node_Data[ 2 ][ self:GetID() ][ "ParentNode" ]	=	SecondNode
	
end




function Zone:Get_Parent_Node()
	
	return Node_Data[ 1 ][ self:GetID() ][ "ParentNode" ]
end

function Lad:Get_Parent_Node()
	
	return Node_Data[ 2 ][ self:GetID() ][ "ParentNode" ]
end

-- Checking if a node is closed or open without iliteration.
function Zone:Node_Is_Closed()
	
	if Node_Data[ 1 ][ self:GetID() ][ "State" ] == false then return true end
	
	return false
end

function Lad:Node_Is_Closed()
	
	if Node_Data[ 2 ][ self:GetID() ][ "State" ] == false then return true end
	
	return false
end


function Zone:Node_Is_Open()
	
	if Node_Data[ 1 ][ self:GetID() ][ "State" ] == true then return true end
	
	return false
end

function Lad:Node_Is_Open()
	
	if Node_Data[ 2 ][ self:GetID() ][ "State" ] == true then return true end
	
	return false
end




-- Remove from the open list.
-- How to advoid iliteration?
function Zone:Node_Remove_From_Open_List()
	
	for k, v in ipairs( Open_List ) do
		
		if v == self then
			
			table.remove( Open_List , k )
			
			break
		end
		
	end
	
	Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

function Lad:Node_Remove_From_Open_List()
	
	for k, v in ipairs( Open_List ) do
		
		if v == self then
			
			table.remove( Open_List , k )
			
			break
		end
		
	end
	
	Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

-- Add a node to the list.
-- Fun fact! This would be the first time I have really added any optimization to the open list.
function Zone:Node_Add_To_Open_List()
	
	local OurCost		=		self:Get_F_Cost()
	
	Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	true
	
	Open_List[ #Open_List + 1 ]			=	self
	
	Sort_Open_List()
	
end

function Lad:Node_Add_To_Open_List()
	
	local OurCost		=		self:Get_F_Cost()
	
	Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	true
	
	Open_List[ #Open_List + 1 ]			=	self
	
	Sort_Open_List()
	
end

function Zone:Node_Remove_From_Closed_List()
	
	Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

function Lad:Node_Remove_From_Closed_List()
	
	Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

-- Prepare everything for a new path find.
-- I might have a way to use this to optimize the open list
function Prepare_Path_Find()
	
	Node_Data	=	{ {} , {} }
	Open_List	=	{}
	
	for k, v in ipairs( navmesh.GetAllNavAreas() ) do
		
		local Lads	=	v:GetLadders()
		
		if istable( Lads ) then
			
			for j, y in ipairs( Lads ) do
				
				Node_Data[ 2 ][ y:GetID() ]		=	{
					
					GCost			=	0,
					FCost			=	0,
					ParentNode		=	nil,
					State			=	"Unset",
					
				}
				
			end
			
		end
		
		Node_Data[ 1 ][ v:GetID() ]		=	{
			
			GCost			=	0,
			FCost			=	0,
			ParentNode		=	nil,
			State			=	"Unset",
			
		}
		
	end
	
end

-- Just like GetAdjacentAreas but a more advanced one.
-- For both ladders and CNavAreas.
function Zone:Get_Connected_Areas()
	
	local AllNodes		=	self:GetAdjacentAreas()
	
	local AllLadders	=	self:GetLadders()
	
	for k, v in ipairs( AllLadders ) do
		
		AllNodes[ #AllNodes + 1 ]	=	v
		
	end
	
	return AllNodes
end

function Lad:Get_Connected_Areas()
	
	local AllNodes		=	{}
	
	local TopLArea		=	self:GetTopLeftArea()
	if IsValid( TopLArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopLArea
		
	end
	
	
	local TopRArea		=	self:GetTopRightArea()
	if IsValid( TopRArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopRArea
		
	end
	
	
	local TopBArea		=	self:GetTopBehindArea()
	if IsValid( TopBArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopBArea
		
	end
	
	local TopFArea		=	self:GetTopForwardArea()
	if IsValid( TopFArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopFArea
		
	end
	
	local BArea		=	self:GetBottomArea()
	if IsValid( BArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	BArea
		
	end
	
	return AllNodes
end

function BOT:Is_On_Ladder()
	
	if self:GetMoveType() == MOVETYPE_LADDER then
		
		return true
	end
	
	return false
end

function Lad:Get_Closest_Point( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		
		return self:GetTop()
	end
	
	return self:GetBottom()
end

function Lad:ClimbUpLadder( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		
		return true
	end
	
	return false
end

-- See if a node is an area : 1 or a ladder : 2
function Zone:Node_Get_Type()
	
	return 1
end

function Lad:Node_Get_Type()
	
	return 2
end
