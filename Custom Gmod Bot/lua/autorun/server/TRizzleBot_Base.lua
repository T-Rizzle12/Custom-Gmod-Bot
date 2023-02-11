local BOT		=	FindMetaTable( "Player" )
local Zone		=	FindMetaTable( "CNavArea" )
local Lad		=	FindMetaTable( "CNavLadder" )
local Open_List		=	{}
local Node_Data		=	{}
util.AddNetworkString( "TRizzleBotFlashlight" )

function TBotCreate( ply , cmd , args )
	if !args[ 1 ] then return end 
	
	local NewBot			=	player.CreateNextBot( args[ 1 ] ) -- Create the bot and store it in a varaible.
	
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
	NewBot.HealThreshold		=	tonumber( args[ 13 ] ) or 100 -- If the bot's health drops below this and the bot is not in combat the bot will use its medkit
	NewBot.CombatHealThreshold	=	tonumber( args[ 14 ] ) or 25 -- If the bot's health drops below this and the bot is not in combat the bot will use its medkit
	NewBot.PlayerModel			=	args[ 15 ] or "kleiner" -- This is the player model the bot will use
	NewBot.Jump					=	false -- If this is set to true the bot will jump
	NewBot.Crouch				=	false -- If this is set to true the bot will crouch
	NewBot.Use					=	false -- If this is set to true the bot will press its use key
	NewBot.LastCombatTime		=	CurTime() -- This was how long ago the bot was in combat
	
	NewBot:TBotResetAI() -- Fully reset your bots AI.
	
end

function TBotSetFollowDist( ply, cmd, args )
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

function TBotSetDangerDist( ply, cmd, args )
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

function TBotSetMelee( ply, cmd, args )
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

function TBotSetPistol( ply, cmd, args )
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

function TBotSetShotgun( ply, cmd, args )
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

function TBotSetRifle( ply, cmd, args )
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

function TBotSetSniper( ply, cmd, args )
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

concommand.Add( "TRizzleCreateBot" , TBotCreate , nil , "Creates a TRizzle Bot with the specified parameters. Example: TRizzleCreateBot <botname> <followdist> <dangerdist> <melee> <pistol> <shotgun> <rifle> <sniper> <meleedist> <pistoldist> <shotgundist> <rifledist> <healthreshold> <combathealthreshold> <playermodel> Example2: TRizzleCreateBot Bot 200 300 weapon_crowbar weapon_pistol weapon_shotgun weapon_smg1 80 1300 300 900 100 25 alyx" )
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
concommand.Add( "TBotSetPlayerModel" , TBotSetPlayerModel , nil , "Changes the bot playermodel to the model shortname specified. If only the bot is specified or the model shortname given is invalid the bot's player model will revert back to the default." )
concommand.Add( "TBotSetDefault" , TBotSetDefault , nil , "Set the specified bot's settings back to the default." )

-------------------------------------------------------------------|



function BOT:TBotResetAI()
	
	self.Enemy				=	nil -- Refresh our enemy.
	self.EnemyList			=	{} -- This is the list of enemies the bot can see.
	self.Jump				=	false -- Stop jumping
	self.Crouch				=	false -- Stop crouching
	self.Use				=	false -- Stop using
	self.Light				=	false -- Turn off the bot's flashlight
	
	self.Goal				=	nil -- The vector goal we want to get to.
	self.NavmeshNodes		=	{} -- The nodes given to us by the pathfinder
	self.Path				=	nil -- The nodes converted into waypoints by our visiblilty checking.
	self.PathTime			=	CurTime() + 1.0 -- This will limit how often the path gets recreated
	
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
		
		-- Turn and face our enemy!
		local lerp = FrameTime() * math.random(8, 10)
		if util.QuickTrace( bot:GetShootPos(), bot.Enemy:GetPos() + Vector( 0, 0, 45 ), bot ).Entity == bot.Enemy then

            bot:SetEyeAngles( LerpAngle(lerp, bot:EyeAngles(), ( (bot.Enemy:GetPos() + Vector( 0, 0, 45 )) - bot:GetShootPos() ):GetNormalized():Angle() ) )

        else

            bot:SetEyeAngles( LerpAngle(lerp, bot:EyeAngles(), ( bot.Enemy:WorldSpaceCenter() - bot:GetShootPos() ):GetNormalized():Angle() ) )

        end
		
		if bot:HasWeapon( "weapon_medkit" ) and bot.CombatHealThreshold > bot:Health() then
		
			-- The bot will heal themself if they get too injured during combat
			cmd:SelectWeapon( bot:GetWeapon( "weapon_medkit" ) )
			if math.random(2) == 1 then
				buttons = buttons + IN_ATTACK2
			end
		elseif bot:HasWeapon( bot.Sniper ) and bot:GetWeapon( bot.Sniper ):HasAmmo() and ( (bot.Enemy:GetPos() - bot:GetPos()):Length() > bot.PistolDist or !bot:HasWeapon( bot.Pistol ) or !bot:GetWeapon( bot.Pistol ):HasAmmo() ) then
		
			-- If an enemy is very far away the bot should use its sniper
			cmd:SelectWeapon( bot:GetWeapon( bot.Sniper ) )
		
		elseif bot:HasWeapon( bot.Pistol ) and bot:GetWeapon( bot.Pistol ):HasAmmo() and ( (bot.Enemy:GetPos() - bot:GetPos()):Length() > bot.RifleDist or !bot:HasWeapon( bot.Rifle ) or !bot:GetWeapon( bot.Rifle ):HasAmmo() )then
		
			-- If an enemy is far the bot, the bot should use its pistol
			cmd:SelectWeapon( bot:GetWeapon( bot.Pistol ) )
		
		elseif bot:HasWeapon( bot.Rifle ) and bot:GetWeapon( bot.Rifle ):HasAmmo() and ( (bot.Enemy:GetPos() - bot:GetPos()):Length() > bot.ShotgunDist or !bot:HasWeapon( bot.Shotgun ) or !bot:GetWeapon( bot.Shotgun ):HasAmmo() ) then
		
			-- If an enemy gets too far but is still close the bot should use its rifle
			cmd:SelectWeapon( bot:GetWeapon( bot.Rifle ) )
		
		elseif bot:HasWeapon( bot.Shotgun ) and bot:GetWeapon( bot.Shotgun ):HasAmmo() and (bot.Enemy:GetPos() - bot:GetPos()):Length() > bot.MeleeDist then
		
			-- If an enemy gets too far but is still close the bot should use its shotgun
			cmd:SelectWeapon( bot:GetWeapon( bot.Shotgun ) )
		
		elseif bot:HasWeapon( bot.Melee ) then
		
			-- If an enemy gets too close the bot should use its melee
			cmd:SelectWeapon( bot:GetWeapon( bot.Melee ) )
		
		end
		
		local botWeapon = bot:GetActiveWeapon()
		if math.random(2) == 1 and bot:IsLineOfSightClear( bot.Enemy:GetPos() ) then
			buttons = buttons + IN_ATTACK
		end
		
		if math.random(2) == 1 and botWeapon:IsWeapon() and botWeapon:Clip1() == 0 then
			buttons = buttons + IN_RELOAD
		end
		
		buttons = bot:HandleButtons( buttons )
		
		cmd:SetButtons( buttons )
		bot:TBotUpdateMovement( cmd )
		
		if isvector( bot.Goal ) and (bot.Owner:GetPos() - bot.Goal):Length() < bot.FollowDist then
		
			bot:TBotUpdateMovement( cmd )
		
		elseif (bot.Owner:GetPos() - bot:GetPos()):Length() > bot.DangerDist then
			
			bot:TBotSetNewGoal( bot.Owner:GetPos() )
			
		end
		
	elseif IsValid( bot.Owner ) and bot.Owner:Alive() then
		
		local botWeapon = bot:GetActiveWeapon()
		if math.random(2) == 1 and botWeapon:IsWeapon() and botWeapon:Clip1() < botWeapon:GetMaxClip1() then
			buttons = buttons + IN_RELOAD
		end
		
		-- If the bot and bot's owner is not in combat then the bot should check if either their owner or they need to heal
		if bot:HasWeapon( "weapon_medkit" ) and (bot.Owner:GetPos() - bot:GetPos()):Length() < 80 and bot.Owner:Health() < bot.HealThreshold then
		
			-- The bot should priortize healing its owner over themself
			local lerp = FrameTime() * math.random(8, 10)
			bot:SetEyeAngles( LerpAngle(lerp, bot:EyeAngles(), ( bot.Owner:GetShootPos() - bot:GetShootPos() ):GetNormalized():Angle() ) )
			cmd:SelectWeapon( bot:GetWeapon( "weapon_medkit" ) )
			if math.random(2) == 1 then
				buttons = buttons + IN_ATTACK
			end
		elseif bot:HasWeapon( "weapon_medkit" ) and bot:Health() < bot.HealThreshold then
		
			-- The bot will heal themself if their owner has full health or is not close enough
			cmd:SelectWeapon( bot:GetWeapon( "weapon_medkit" ) )
			if math.random(2) == 1 then
				buttons = buttons + IN_ATTACK2
			end
		elseif bot:HasWeapon( bot.Sniper ) and bot:GetWeapon( bot.Sniper ):Clip1() < bot:GetWeapon( bot.Sniper ):GetMaxClip1() then
		
			-- The bot should reload weapons that need to be reloaded
			cmd:SelectWeapon( bot:GetWeapon( bot.Sniper ) )
		
		elseif bot:HasWeapon( bot.Pistol ) and bot:GetWeapon( bot.Pistol ):Clip1() < bot:GetWeapon( bot.Pistol ):GetMaxClip1() then
		
			cmd:SelectWeapon( bot:GetWeapon( bot.Pistol ) )
		
		elseif bot:HasWeapon( bot.Rifle ) and bot:GetWeapon( bot.Rifle ):Clip1() < bot:GetWeapon( bot.Rifle ):GetMaxClip1() then
		
			cmd:SelectWeapon( bot:GetWeapon( bot.Rifle ) )
			
		elseif bot:HasWeapon( bot.Shotgun ) and bot:GetWeapon( bot.Shotgun ):Clip1() < bot:GetWeapon( bot.Shotgun ):GetMaxClip1() then
		
			cmd:SelectWeapon( bot:GetWeapon( bot.Shotgun ) )
			
		end
		-- Possibly add support for the bot to heal nearby players?
		
		buttons = bot:HandleButtons( buttons )
		
		cmd:SetButtons( buttons )
		bot:TBotUpdateMovement( cmd )
		
		if isvector( bot.Goal ) and (bot.Owner:GetPos() - bot.Goal):Length() < bot.FollowDist then
			
			bot:TBotUpdateMovement( cmd )
		
		elseif (bot.Owner:GetPos() - bot:GetPos()):Length() > bot.FollowDist then
			
			bot:TBotSetNewGoal( bot.Owner:GetPos() )
		
		end
	end
	
	if bot:CanUseFlashlight() and !bot:FlashlightIsOn() and bot.Light and bot:GetSuitPower() > 50 then
		
		bot:Flashlight( true )
		
	elseif bot:CanUseFlashlight() and bot:FlashlightIsOn() and !bot.Light then
		
		bot:Flashlight( false )
		
	end
end)

function BOT:HandleButtons( buttons )

	local Close		=	navmesh.GetNearestNavArea( self:GetPos() )
	
	if !IsValid ( Close ) then -- If their is no nav_mesh this will run instead to prevent the addon from spamming errors
		
		-- Run if we are too far from our owner
		if self:IsOnGround() and !self.Crouch and (self.Owner:GetPos() - self:GetPos()):Length() > self.DangerDist then 
			buttons = buttons + IN_SPEED 
		end

		if self.Crouch or !self:IsOnGround() then 

			buttons = buttons + IN_DUCK

			timer.Simple( 0.3 , function()

				self.Crouch = false 

			end)

		end

		if self:Is_On_Ladder() then

			buttons = buttons + IN_FORWARD
			return buttons

		end

		if self.Jump then 

			buttons = buttons + IN_JUMP 
			self.Jump = false 

		end

		local door = self:GetEyeTrace().Entity

		if self.Use and IsDoor( door ) and (door:GetPos() - self:GetPos()):Length() < 80 then 

			door:Use(self, self, USE_TOGGLE, -1)
			self.Use = false 

		end

		return buttons
	
	end
	
	if Close:HasAttributes( NAV_MESH_JUMP ) then
		
		self.Jump		=	true
	end
	
	if Close:HasAttributes( NAV_MESH_CROUCH ) then
		
		self.Crouch		=	true
		
	end
	
	-- Run if we are too far from our owner
	if self:IsOnGround() and !self.Crouch and (self.Owner:GetPos() - self:GetPos()):Length() > self.DangerDist and self:GetSuitPower() > 20 then 
		buttons = buttons + IN_SPEED 
	end
	
	if self.Crouch or !self:IsOnGround() then 
	
		buttons = buttons + IN_DUCK
		
		timer.Simple( 0.3 , function()
			
			self.Crouch = false 
			
		end)
		
	end
	
	if self:Is_On_Ladder() then
		
		buttons = buttons + IN_FORWARD
		return buttons
		
	end
	
	if self.Jump then 
	
		buttons = buttons + IN_JUMP 
		self.Jump = false 
		
	end
	
	local door = self:GetEyeTrace().Entity
	
	if self.Use and IsDoor( door ) and (door:GetPos() - self:GetPos()):Length() < 80 then 
	
		door:Use(self, self, USE_TOGGLE, -1)
		self.Use = false 
		
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

function BOT:RestoreAmmo()
	
	-- This is kind of a cheat, but the bot will only slowly recover ammo when not in combat
	local pistol		=	self:GetWeapon( self.Pistol )
	local rifle			=	self:GetWeapon( self.Rifle )
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

function IsDoor( v )

	if (v:GetClass() == "func_door") or (v:GetClass() == "prop_door_rotating") or (v:GetClass() == "func_door_rotating") then
        
		return true
    
	end
	
	return false
	
end


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
		
		ply:TBotResetAI()
		timer.Simple( 0.03 , function()
			
			if IsValid( ply ) and ply:Alive() then
				
				ply:SetModel( ply.PlayerModel )
				
			end
			
		end)
		
	end
	
end)


-- The main AI is here.
function BOT:TBotCreateThinking()
	
	local index		=	self:EntIndex()
	
	-- I used math.Rand as a personal preference, It just prevents all the timers being ran at the same time
	-- as other bots timers.
	timer.Create( "trizzle_bot_think" .. index , math.Rand( 0.08 , 0.15 ) , 0 , function()
		
		if IsValid( self ) and self:Alive() then
			
			-- A quick condition statement to check if our enemy is no longer a threat.
			-- Most likely done best in its own function. But for now I will make it simple.
			if !IsValid( self.Enemy ) then self.Enemy							=	nil
			elseif self.Enemy:IsPlayer() and !self.Enemy:Alive() then self.Enemy				=	nil
			elseif !self.Enemy:Visible( self ) then self.Enemy						=	nil
			elseif self.Enemy:IsNPC() and self.Enemy:GetNPCState() == NPC_STATE_DEAD then self.Enemy	=	nil end
			
			self:TBotFindRandomEnemy()
			
			local tab = player.GetHumans()
			if #tab > 0 then
				local ply = table.Random(tab)
				
				net.Start( "TRizzleBotFlashlight" )
				net.Send( ply )
			end
			
			if !self:IsInCombat() then self:RestoreAmmo() end
			
		else
			
			timer.Remove( "trizzle_bot_think" .. index ) -- We don't need to think while dead.
			
		end
		
	end)
	
end



-- Target any player or bot that is visible to us.
function BOT:TBotFindRandomEnemy()
	local VisibleEnemies		=	{} -- This is how many enemies the bot can see. Currently not used......yet
	local targetdist			=	10000 -- This will allow the bot to select the closest enemy to it.
	local target				=	self.Enemy -- This is the closest enemy to the bot.
	
	for k, v in ipairs( ents.GetAll() ) do
		
		if IsValid ( v ) and v:IsNPC() and v:GetNPCState() != NPC_STATE_DEAD and (v:GetEnemy() == self or v:GetEnemy() == self.Owner) then -- The bot should attack any NPC that is attacking them or their owner
			
			if v:Visible( self ) then
				
				VisibleEnemies[ #VisibleEnemies + 1 ]		=	v
				if (v:GetPos() - self:GetPos()):Length() < targetdist then 
					target = v
					targetdist = (v:GetPos() - self:GetPos()):Length()
				end
			end
			
		end
		
	end
	
	self.Enemy		=	target
	self.NumEnemies		=	VisibleEnemies
	
end

function TRizzleBotPathfinder( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if ( StartNode == GoalNode ) then return true end
	
	Prepare_Path_Find()
	
	StartNode:Node_Add_To_Open_List()
	local Attempts		=	0 
	-- Backup Varaible! In case something goes wrong, The game will not get into an infinite loop.
	
	while( !table.IsEmpty( Open_List ) and Attempts < 6500 ) do
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
				
				if Height > 64 then
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



function TRizzleBotRangeCheck( FirstNode , SecondNode , Height )
	-- Some helper errors.
	if !IsValid( FirstNode ) then error( "Bad argument #1 CNavArea or CNavLadder expected got " .. type( FirstNode ) ) end
	if !IsValid( FirstNode ) then error( "Bad argument #2 CNavArea or CNavLadder expected got " .. type( SecondNode ) ) end
	
	if FirstNode:Node_Get_Type() == 2 then return FirstNode:GetLength()
	elseif SecondNode:Node_Get_Type() == 2 then return SecondNode:GetLength() end
	
	DefaultCost = FirstNode:GetCenter():Distance( SecondNode:GetCenter() )
	
	if isnumber( Height ) and Height > 32 then
		
		DefaultCost		=	DefaultCost * 5
		
		-- Jumping is slower than ground movement.
		-- And falling is risky taking fall damage.
		
		
	end
	
	-- Jump nodes however,We find slightly easier to jump with.Its more recommended than jumping without them.
	if SecondNode:HasAttributes( NAV_MESH_JUMP ) then 
		
		DefaultCost	=	DefaultCost * 3.50
		
	end
	
	
	-- Crawling through a vent is very slow.
	if SecondNode:HasAttributes( NAV_MESH_CROUCH ) then 
		
		DefaultCost	=	DefaultCost * 7
		
	end
	
	-- We are less interested in smaller nodes as it can make less realistic paths.
	-- Also its easy to get stuck on them.
	if SecondNode:GetSizeY() <= 50 then
		
		DefaultCost		=	DefaultCost * 3
		
	end
	
	if SecondNode:GetSizeX() <= 50 then
		
		DefaultCost		=	DefaultCost * 3
		
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
		
		if Current:Node_Get_Type() == 1 then
		
			table.insert( NodePath , navmesh.GetNavAreaByID( Current:GetID() ) )
			
		else
		
			table.insert( NodePath , navmesh.GetNavLadderByID( Current:GetID() ) )
			
		end
	end
	
	
	return NodePath
end

function BOT:TBotSetNewGoal( NewGoal )
	if !isvector( NewGoal ) then error( "Bad argument #1 vector expected got " .. type( NewGoal ) ) end
	
	self.Goal				=	NewGoal
	if self.PathTime < CurTime() then
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
			
			self.Path[ #self.Path + 1 ]		=	self.Goal
			
			break
		end
		
		if NextNode:Node_Get_Type() == 2 then
		
			local CloseToStart		=	NextNode:Get_Closest_Point( LastVisPos )
			
			LastVisPos		=	CloseToStart
			
			self.Path[ #self.Path + 1 ]		=	CloseToStart
			
			continue
		end
		
		if CurrentNode:Node_Get_Type() == 2 then
		
			local CloseToEnd		=	CurrentNode:Get_Closest_Point( NextNode:GetCenter() )
			
			LastVisPos		=	CloseToEnd
			
			self.Path[ #self.Path + 1 ]		=	CloseToEnd
			
			continue
		end
		
		-- The next area ahead's closest point to us.
		local NextAreasClosetPointToLastVisPos		=	NextNode:GetClosestPointOnArea( LastVisPos ) + Vector( 0 , 0 , 32 )
		local OurClosestPointToNextAreasClosestPointToLastVisPos	=	CurrentNode:GetClosestPointOnArea( NextAreasClosetPointToLastVisPos ) + Vector( 0 , 0 , 32 )
		
		-- If we are visible then we shall put the waypoint there.
		if SendBoxedLine( LastVisPos , OurClosestPointToNextAreasClosestPointToLastVisPos ) == true then
			
			LastVisPos						=	OurClosestPointToNextAreasClosestPointToLastVisPos
			self.Path[ #self.Path + 1 ]		=	OurClosestPointToNextAreasClosestPointToLastVisPos
			
			continue
		end
		
		
		
		
		self.Path[ #self.Path + 1 ]			=	CurrentNode:GetCenter()
		
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
			
			-- Find a path through the navmesh to our TargetArea
			self.NavmeshNodes		=	TRizzleBotPathfinder( self.StandingOnNode , TargetArea )
			
			
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
			
			
			-- There is no way we can get there! Remove our goal.
			if self.NavmeshNodes == false then
				
				self.Goal		=	nil
				
				return
			end
			
			
		end
		
		
	end
	
	
	if istable( self.Path ) then
		
		if self.Path[ 1 ] then
			
			local Waypoint2D		=	Vector( self.Path[ 1 ].x , self.Path[ 1 ].y , self:GetPos().z )
			-- ALWAYS: Use 2D navigation, It helps by a large amount.
			
			if self.Path[ 2 ] and IsVecCloseEnough( self:GetPos() , Waypoint2D , 600 ) and SendBoxedLine( self.Path[ 2 ] , self:GetPos() + Vector( 0 , 0 , 15 ) ) == true and self.Path[ 2 ].z - 20 >= Waypoint2D.z then
				
				table.remove( self.Path , 1 )
				
			elseif IsVecCloseEnough( self:GetPos() , Waypoint2D , 32 ) then
				
				table.remove( self.Path , 1 )
				
			end
			
		end
		
	end
	
	
end

-- The navigation and navigation debugger for when a bot is stuck.
function BOT:TBotCreateNavTimer()
	
	local index				=	self:EntIndex()
	local LastBotPos		=	self:GetPos()
	local Attempts		=	0
	
	
	timer.Create( "trizzle_bot_nav" .. index , 0.09 , 0 , function()
		
		if IsValid( self ) and self:Alive() and isvector( self.Goal ) then
			
			self:TBotNavigation()
			
			self:TBotDebugWaypoints()
			
			LastBotPos		=	Vector( LastBotPos.x , LastBotPos.y , self:GetPos().z )
			
			if IsVecCloseEnough( self:GetPos() , LastBotPos , 2 ) then
				
				self.Jump	=	true
				self.Use	=	true
				
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
	
	debugoverlay.Line( self.Path[ 1 ] , self:GetPos() + Vector( 0 , 0 , 44 ) , 0.08 , Color( 0 , 255 , 255 ) )
	debugoverlay.Sphere( self.Path[ 1 ] , 8 , 0.08 , Color( 0 , 255 , 255 ) , true )
	
	for k, v in ipairs( self.Path ) do
		
		if self.Path[ k + 1 ] then
			
			debugoverlay.Line( v , self.Path[ k + 1 ] , 0.08 , Color( 255 , 255 , 0 ) )
			
		end
		
		debugoverlay.Sphere( v , 8 , 0.08 , Color( 255 , 200 , 0 ) , true )
		
	end
	
end

-- Make the bot move.
function BOT:TBotUpdateMovement( cmd )
	if !isvector( self.Goal ) then return end
	
	if !istable( self.Path ) or table.IsEmpty( self.Path ) or isbool( self.NavmeshNodes ) then
		
		local MovementAngle		=	( self.Goal - self:GetPos() ):GetNormalized():Angle()
		local lerp = FrameTime() * math.random(1, 4)
		
		if self:OnGround() and self.Goal.z >= self:GetPos().z then
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
		
		local MovementAngle		=	( self.Path[ 1 ] - self:GetPos() ):GetNormalized():Angle()
		local lerp = FrameTime() * math.random(1, 4)
		
		if self:OnGround() and self.Path[ 1 ].z >= self:GetPos().z then
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
		if !IsValid ( self.Enemy ) or self:Is_On_Ladder() then self:SetEyeAngles( LerpAngle(lerp, self:EyeAngles(), ( self.Path[ 1 ] - self:GetPos() ):GetNormalized():Angle() ) ) end
		
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
	--[[
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 4 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]				=	nil
		
	end
	
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 5 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]				=	nil
		
	end
	]]
	
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




function Zone:Set_H_Cost( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "HCost" ]	=	cost
	
end

function Lad:Set_H_Cost( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "HCost" ]	=	cost
	
end




function Zone:Get_G_Cost( cost )
	
	return Node_Data[ 1 ][ self:GetID() ][ "GCost" ]
end

function Lad:Get_G_Cost( cost )
	
	return Node_Data[ 2 ][ self:GetID() ][ "GCost" ]
end



function Zone:Get_H_Cost( cost )
	
	return Node_Data[ 1 ][ self:GetID() ][ "HCost" ]
end

function Lad:Get_H_Cost( cost )
	
	return Node_Data[ 2 ][ self:GetID() ][ "HCost" ]
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




-- Hmm, I think we need this for the reparenting.
function Zone:Get_Current_Path_Length()
	
	
	return Node_Data[ 1 ][ self:GetID() ][ "PathLen" ]
end

function Lad:Get_Current_Path_Length()
	
	
	return Node_Data[ 2 ][ self:GetID() ][ "PathLen" ]
end



function Zone:Set_Current_Path_Length( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "PathLen" ]		=	cost
	
end

function Lad:Set_Current_Path_Length( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "PathLen" ]		=	cost
	
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
-- Fun fact! This would be the first time i have really added any optimization to the open list.
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
					
					Node			=	y,
					GCost			=	0,
					HCost			=	0,
					FCost			=	0,
					ParentNode		=	nil,
					State			=	"Unset",
					PathLen			=	0
					
				}
				
			end
			
		end
		
		Node_Data[ 1 ][ v:GetID() ]		=	{
			
			Node			=	v,
			GCost			=	0,
			HCost			=	0,
			FCost			=	0,
			ParentNode		=	nil,
			State			=	"Unset",
			PathLen			=	0 -- Incase our path is shorter a different way!
			
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

-- See if a node is an area : 1 or a ladder : 2
function Zone:Node_Get_Type()
	
	return 1
end

function Lad:Node_Get_Type()
	
	return 2
end