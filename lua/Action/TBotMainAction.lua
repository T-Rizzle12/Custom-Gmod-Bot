-- TBotMainAction.lua
-- Purpose: This is the TBotMainAction MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotMainActionMeta = {}

function TBotMainActionMeta:__index( key )

	-- Search the metatable.
	local val = TBotMainActionMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotMainAction()
	local tbotmainaction = TBotBaseAction()

	tbotmainaction.m_spawnPreferredWeaponsTimer = util.Timer()
	tbotmainaction.m_ammoRegenTimer = util.Timer()
	tbotmainaction.m_aimAdjustTimer = util.Timer()
	tbotmainaction.m_aimErrorAngle = 0.0
	tbotmainaction.m_aimErrorRadius = 0.0
	tbotmainaction.m_isWaitingForFullReload = false

	setmetatable( tbotmainaction, TBotMainActionMeta )

	return tbotmainaction

end

function TBotMainActionMeta:GetName()

	return "MainAction"
	
end

function TBotMainActionMeta:InitialContainedAction( me )

	return TBotTacticalMonitor()

end

function TBotMainActionMeta:OnStart( me, priorAction )

	self.m_aimErrorAngle = 0.0
	self.m_aimErrorRadius = 0.0
	self.m_isWaitingForFullReload = false

	-- If the bot is already dead at this point, make sure it's dead
	-- check for !Alive because the bot could be DYING
	if !me:Alive() then

		return self:ChangeTo( TBotDead(), "I'm actually dead" )

	end

	return self:Continue()

end

function TBotMainActionMeta:Update( me, interval )

	local botTable = me:GetTable()
	local threat = me:GetTBotVision():GetPrimaryKnownThreat()
	if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) and threat:IsVisibleRecently() then
	
		-- FIXME: Should this be somewhere else!?
		-- NEEDTOVALIDATE: This might have to be in the bot's main think function......
		botTable.LastCombatTime = CurTime() -- Update combat timestamp
		
	end
	
	-- Make sure our vision FOV matches the player's
	local vision = me:GetTBotVision()
	vision:SetFieldOfView( me:GetFOV() )
	
	if !me:IsInCombat() then

		local botWeapon = me:GetActiveWeapon()
		if IsValid( botWeapon ) and botWeapon:IsWeapon() then

			local weaponTable = GetTBotRegisteredWeapon( botWeapon:GetClass() )
			local weaponType = weaponTable.WeaponType
			if CurTime() >= botTable.ReloadInterval and !me:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:NeedsToReload() then

				me:PressReload()
				botTable.ReloadInterval = CurTime() + 0.5

			end

			if CurTime() >= botTable.ScopeInterval and weaponTable.HasScope and me:IsUsingScope() then

				me:PressSecondaryAttack()
				botTable.ScopeInterval = CurTime() + 1.0

			end

		end

		-- The bot will slowly regenerate ammo it has lost when not in combat
		-- The bot will quickly regenerate ammo once it is safe
		if me:IsSafe() or self.m_ammoRegenTimer:Elapsed() then
			
			self.m_ammoRegenTimer:Start( 1 )
			me:RestoreAmmo()

		end
	
	else
	
		local botWeapon = me:GetActiveWeapon()
		if IsValid( botWeapon ) and botWeapon:IsWeapon() then

			local weaponTable = GetTBotRegisteredWeapon( botWeapon:GetClass() )
			local weaponType = weaponTable.WeaponType
			if CurTime() >= botTable.ReloadInterval and !me:IsReloading() and botWeapon:GetClass() != "weapon_medkit" and botWeapon:NeedsToReload() then
	
				if weaponTable.ReloadsSingly and vision:GetKnownCount( nil, true, -1 ) <= 0 then
				
					me:PressReload()
					botTable.ReloadInterval = CurTime() + 0.5
				
				elseif botWeapon:Clip1() < ( botWeapon:GetMaxClip1() * 0.6 ) and vision:GetKnownCount( nil, false, -1 ) <= 0 then
				
					me:PressReload()
					botTable.ReloadInterval = CurTime() + 0.5
				
				end
			
			end
			
		end
	
	end
	
	-- NEEDTOVALIDATE: I have moved this into PathFollower. Should this be handled here instead?
	--[[if IsValid( botTable.m_breakable ) then
	
		return self:SuspendFor( TBotBreakEntity( botTable.m_breakable ), "Breaking entity in path" )
	
	elseif IsValid( botTable.m_door ) then
	
		return self:SuspendFor( TBotOpenDoor( botTable.m_door ), "Opening door in path" )
	
	end]]
	
	me:UpdateLookingAroundForEnemies()
	self:FireWeaponAtEnemy( me, threat )
	
	local tbotOwner = botTable.TBotOwner
	if IsValid( tbotOwner ) then

		if tbotOwner:InVehicle() and !me:InVehicle() then

			local vehicle = me:FindNearbySeat()

			-- FIXME: Now that we have the action system this should really be a ChangeTo an enter vehicle state.....
			if IsValid( vehicle ) then me:EnterVehicle( vehicle ) end -- I should make the bot press its use key instead of this hack

		end

		if !tbotOwner:InVehicle() and me:InVehicle() and CurTime() >= botTable.UseInterval then

			me:PressUse()
			botTable.UseInterval = CurTime() + 0.5

		end

	end

	-- Only check if we need to spawn in weapons every second since this creates lag if we don't
	if botTable.SpawnWithWeapons and self.m_spawnPreferredWeaponsTimer:Elapsed() then

		--[[bot:Give( bot.Pistol )
		bot:Give( bot.Shotgun )
		bot:Give( bot.Rifle )
		bot:Give( bot.Sniper )
		bot:Give( bot.Melee )
		bot:Give( "weapon_medkit" )
		if bot:IsSafe() then bot:Give( bot.Grenade ) end]] -- The bot should only spawn in its grenade if it feels safe.

		for weapon in pairs( botTable.TBotPreferredWeapons ) do

			local weaponTable = GetTBotRegisteredWeapon( weapon )
			if !table.IsEmpty( weaponTable ) and !me:HasWeapon( weapon ) then

				-- The bot should only spawn in its grenade if it feels safe.
				if me:IsSafe() or weaponTable.WeaponType != "Grenade" then

					-- NOTE: The give function only returns the CREATED weapon, as a result
					-- it will return NULL if the bot already owns the weapon
					local wep = me:Give( weapon )
					if IsValid( wep ) then
					
						local currentAmmo = me:GetAmmoCount( wep:GetPrimaryAmmoType() )
						local maxStoredAmmo = tonumber( weaponTable.MaxStoredAmmo )
						if isnumber( maxStoredAmmo ) then
						
							me:GiveAmmo( math.max( maxStoredAmmo - currentAmmo, 0 ), wep:GetPrimaryAmmoType(), true )
						
						else
						
							if wep:UsesClipsForAmmo1() then
							
								me:GiveAmmo( math.max( ( wep:GetMaxClip1() * 6 ) - currentAmmo, 0 ), wep:GetPrimaryAmmoType(), true )
								
							else
							
								me:GiveAmmo( math.max( 6 - currentAmmo, 0 ), wep:GetPrimaryAmmoType(), true )
							
							end
						
						end
						
					end

				end

			end

		end
		me:Give( "weapon_medkit" )
		
		self.m_spawnPreferredWeaponsTimer:Start( 1 )

	end

	if me:CanUseFlashlight() and botTable.ImpulseInterval <= CurTime() then

		if !me:TBotIsFlashlightOn() and botTable.Light and me:GetSuitPower() > 50 then

			botTable.impulseFlags = 100
			botTable.ImpulseInterval = CurTime() + 0.5
			--bot:Flashlight( true )

		elseif me:TBotIsFlashlightOn() and !botTable.Light then

			botTable.impulseFlags = 100
			botTable.ImpulseInterval = CurTime() + 0.5
			--bot:Flashlight( false )

		end

	end

	return self:Continue()

end

-- If an entity gets removed, clear it from the bot's attack list.
function TBotMainActionMeta:EntityRemoved( me, ent, fullUpdate ) 
	if !IsValid( ent ) or ent == me then return self:TryContinue() end

	local botTable = me:GetTable()
	local attackList = botTable.AttackList or {}
	attackList[ ent ] = nil
	return self:TryContinue()

end

-- When an NPC dies, it should be removed from the bot's known entity list.
-- This is also called for some nextbots.
function TBotMainActionMeta:OnNPCKilled( me, npc )
	if !IsValid( npc ) then return self:TryContinue() end

	me:GetTBotVision():ForgetEntity( npc )
	me.AttackList[ npc ] = nil
	return self:TryContinue()

end

-- When the bot dies, it seems to keep its weapons for some reason. This hook removes them when the bot dies.
-- This hook also checks if a player dies and removes said player from every bots known enemy list.
function TBotMainActionMeta:PostPlayerDeath( me, ply )
	if !IsValid( ply ) then return self:TryContinue() end

	me:GetTBotVision():ForgetEntity( ply )
	me.AttackList[ ply ] = nil

	if me == ply then

		me:StripWeapons()
		return self:TryChangeTo( TBotDead(), TBotEventResultPriorityType.RESULT_CRITICAL, "I died!" )

	end

	return self:TryContinue()

end

function TBotMainActionMeta:PlayerDisconnected( me, ply )
	if !IsValid( ply ) or ply == me or ply:IsListenServerHost() then return self:TryContinue() end

	local botTable = me:GetTable()
	botTable.AttackList[ ply ] = nil

	if botTable.TBotOwner == ply then

		if me:IsTRizzleBot( true ) then

			me:Kick( string.format( "Owner s% has left the server", ply:Nick() ) )
			return self:TryDone( TBotEventResultPriorityType.RESULT_CRITICAL, "Ending main action since bot owner has left the game" )

		else

			botTable.TBotOwner = me

		end

	end

	return self:TryContinue()

end

function TBotMainActionMeta:PlayerSay( me, sender, text, teamChat )
	if !IsValid( sender ) then return self:TryContinue() end

	-- HACKHACK: PlayerCanSeePlayersChat is called after PlayerSay, so we call it to check if the bot can see the chat message.
	-- NEEDTOVALIDATE: Would it be better if I used the PlayerCanSeePlayersChat hook instead?
	if hook.Run( "PlayerCanSeePlayersChat", text, teamChat, me, sender ) then

		local botTable = me:GetTable()
		local startpos, endpos, botName = string.find( text, me:Nick() )
		local textTable
		local command

		if isnumber( startpos ) and startpos == 1 then -- Only run the command if the bot name was said first!

			textTable = string.Explode( " ", string.sub( text, endpos + 1 ) ) -- Grab everything else after the name!
			table.remove( textTable, 1 ) -- Remove the unnecessary whitespace
			command = textTable[ 1 ] and textTable[ 1 ]:lower()

		else

			startpos, endpos, botName = string.find( text:lower(), "bots" )
			if isnumber( startpos ) and startpos == 1 then -- Check to see if the player is commanding every bot!

				textTable = string.Explode( " ", string.sub( text, endpos + 1 ) ) -- Grab everything else after the name!
				table.remove( textTable, 1 ) -- Remove the unnecessary whitespace
				command = textTable[ 1 ] and textTable[ 1 ]:lower()

			end

		end

		if sender == botTable.TBotOwner and isstring( command ) then

			if command == "attack" then

				local enemy = sender:GetEyeTrace().Entity

				if IsValid( enemy ) and !enemy:IsWorld() then

					me:GetTBotVision():AddKnownEntity( enemy )
					botTable.AttackList[ enemy ] = true

				end

			elseif command == "clear" and isstring( textTable[ 2 ] ) then

				if textTable[ 2 ]:lower() == "attack" then

					botTable.AttackList = {}

				end

			elseif command == "alert" then

				botTable.LastCombatTime = CurTime() + 5.0

			elseif command == "warp" then

				me:SetPos( sender:GetEyeTrace().HitPos )

			end

		end

	end
	
	return self:TryContinue()

end

function TBotMainActionMeta:EntityEmitSound( me, soundTable )
	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() then return self:TryContinue() end
	if !IsValid( soundTable.Entity ) or soundTable.Entity == me then return self:TryContinue() end
	
	local vision = me:GetTBotVision()
	if vision:IsValidTarget( soundTable.Entity ) and me:IsEnemy( soundTable.Entity ) then 
		
		if soundTable.Entity:GetPos():DistToSqr( me:GetPos() ) < math.Clamp( ( 2500 * ( soundTable.SoundLevel / 100 ) )^2, 0, 6250000 ) then
		
			local known = vision:AddKnownEntity( soundTable.Entity )
			
			if istbotknownentity( known ) then
				
				known:UpdatePosition()
				
			end
			
			if !me:IsInCombat() then me.LastCombatTime = CurTime() - 5.0 end
			
		end
		
	end
	
	return self:TryContinue()
	
end

function TBotMainActionMeta:PlayerHurt( me, victim, attacker )
	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() or !IsValid( attacker ) or !IsValid( victim ) or victim != me then return self:TryContinue() end
	
	local vision = me:GetTBotVision()
	if vision:IsValidTarget( attacker ) and me:IsEnemy( attacker ) then
		
		local known = vision:AddKnownEntity( attacker )
		
		if istbotknownentity( known ) then
			
			known:UpdatePosition()
			known:MarkTookDamageFromEnemy()
			
		end
		
		if !me:IsInCombat() then me.LastCombatTime = CurTime() - 5.0 end
		
	end
	
	return self:TryContinue()

end

function TBotMainActionMeta:OnEnd( me, nextAction )

	return

end

function TBotMainActionMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotMainActionMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotMainActionMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotMainActionMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotMainActionMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotMainActionMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_YES

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotMainActionMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

function TBotMainActionMeta:FireWeaponAtEnemy( me, threat )

	local botTable = me:GetTable()
	if !me:Alive() then

		return

	end

	local botWeapon = me:GetActiveWeapon()
	if !IsValid( botWeapon ) or !botWeapon:IsWeapon() then

		return

	end

	local weaponTable = GetTBotRegisteredWeapon( botWeapon:GetClass() )
	local weaponType = weaponTable.WeaponType
	if weaponTable.ReloadsSingly then

		if botWeapon:IsPrimaryClipEmpty() then

			self.m_isWaitingForFullReload = true

		end

		if self.m_isWaitingForFullReload then

			if botWeapon:NeedsToReload() then

				if CurTime() >= botTable.ReloadInterval and !me:IsReloading() then

					me:PressReload()
					botTable.ReloadInterval = CurTime() + 0.5

				end

				return

			end

			-- We are fully reloaded
			self.m_isWaitingForFullReload = false

		end
	
	else
	
		self.m_isWaitingForFullReload = false
	
	end

	-- If our primary clip is empty, stop attacking so we can reload!
	if botWeapon:IsPrimaryClipEmpty() and botWeapon:HasPrimaryAmmo() then
	
		if CurTime() >= botTable.ReloadInterval and !me:IsReloading() then

			me:PressReload()
			botTable.ReloadInterval = CurTime() + 0.5
			
		end
		
		return

	end

	local vision = me:GetTBotVision()
	threat = threat or vision:GetPrimaryKnownThreat()
	if !istbotknownentity( threat ) or !IsValid( threat:GetEntity() ) or !threat:IsVisibleRecently() then

		return

	end

	if me:GetTBotBehavior():ShouldAttack( me, threat ) == TBotQueryResultType.ANSWER_NO then
	
		return
		
	end

	local enemy = threat:GetEntity()
	local enemyDist = enemy:GetPos():DistToSqr( me:GetPos() ) -- Grab the bot's current distance from their current enemy

	me:SelectBestWeapon( enemy, enemyDist ) -- FIXME: This should be somewhere else......

	-- Should I limit how often this runs?
	-- NEEDTOVALIDATE: Should this be in SelectTargetPoint instead?
	local trace = {}
	util.TraceLine( { start = me:GetShootPos(), endpos = enemy:GetHeadPos(), filter = me, mask = MASK_SHOT, output = trace } )

	if trace.Entity == enemy then

		botTable.AimForHead = true

	else

		botTable.AimForHead = false

	end

	if CurTime() >= botTable.ScopeInterval and weaponTable.HasScope then

		if !me:IsUsingScope() and enemyDist >= 400^2 or me:IsUsingScope() and enemyDist < 400^2 then

			me:PressSecondaryAttack()
			botTable.ScopeInterval = CurTime() + 0.4
			botTable.FireWeaponInterval = CurTime() + 0.4

		end

	end

	if CurTime() >= botTable.FireWeaponInterval and me:IsCursorOnTarget( enemy ) then

		if weaponTable.HasSecondaryAttack and botTable.SecondaryInterval <= CurTime() and enemyDist > 400^2 and botWeapon:HasSecondaryAmmo() and vision:GetKnownCount( nil, true, -1 ) >= 3 then

			me:PressSecondaryAttack()
			botTable.SecondaryInterval = CurTime() + weaponTable.SecondaryAttackCooldown
			--bot.MinEquipInterval = CurTime() + 2.0

		elseif ( weaponType != "Grenade" or ( botTable.GrenadeInterval <= CurTime() and botWeapon:GetNextPrimaryFire() <= CurTime() ) ) and ( weaponType != "Melee" or enemyDist <= botTable.MeleeDist^2 ) then

			me:PressPrimaryAttack()

			-- The bot should throw a grenade then swap to another weapon
			if weaponType == "Grenade" and botTable.GrenadeInterval <= CurTime() then

				botTable.GrenadeInterval = CurTime() + 22.0
				botTable.MinEquipInterval = CurTime() + 2.0

			elseif weaponType == "Explosive" and botTable.ExplosiveInterval <= CurTime() then

				botTable.ExplosiveInterval = CurTime() + 22.0
				botTable.MinEquipInterval = CurTime() + 2.0

			end

			-- If the bot's active weapon is automatic the bot should just press and hold its attack button if their current enemy is close enough
			if me:IsActiveWeaponAutomatic() and ( enemyDist < 400^2 or weaponTable.IgnoreAutomaticRange ) then

				botTable.FireWeaponInterval = CurTime()

			elseif enemyDist < 800^2 then

				botTable.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )

			else

				botTable.FireWeaponInterval = CurTime() + math.Rand( 0.3 , 0.7 )

			end

			-- Subtract system latency
			-- FIXME: I need to grab the update interval for this!!!!
			--botTable.FireWeaponInterval = botTable.FireWeaponInterval - BotUpdateInterval

		end
		
	end

end

-- Given a subject, return the world space postion we should aim at.
function TBotMainActionMeta:SelectTargetPoint( me, subject )

	local myWeapon = me:GetActiveWeapon()
	local botTable = me:GetTable()
	if IsValid( myWeapon ) and myWeapon:IsWeapon() then

		if GetTBotRegisteredWeapon( myWeapon:GetClass() ).WeaponType == "Grenade" then

			local toThreat = subject:GetPos() - me:GetPos()
			local threatRange = toThreat:Length()
			toThreat:Normalize()
			local elevationAngle = threatRange * GetConVar( "TBotBallisticElevationRate" ):GetFloat()

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

	if self.m_aimAdjustTimer:Elapsed() then

		self.m_aimAdjustTimer:Start( math.Rand( 0.5, 1.5 ) )

		self.m_aimErrorAngle = math.Rand( -math.pi, math.pi )
		self.m_aimErrorRadius = math.Rand( 0.0, GetConVar( "TBotAimError" ):GetFloat() )

	end

	local toThreat = subject:GetPos() - me:GetPos()
	local threatRange = toThreat:Length()
	toThreat:Normalize()

	local s1 = math.sin( self.m_aimErrorRadius )
	local Error = threatRange * s1
	local side = toThreat:Cross( vector_up )

	local s, c = math.sin( self.m_aimErrorAngle ), math.cos( self.m_aimErrorAngle )

	if botTable.AimForHead and !me:IsActiveWeaponRecoilHigh() then

		return subject:GetHeadPos() + Error * s * vector_up + Error * c * side

	else

		return subject:WorldSpaceCenter() + Error * s * vector_up + Error * c * side

	end

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotMainActionMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotMainActionMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	if !threat1 or threat1:IsObsolete() then

		if threat2 and !threat2:IsObsolete() then

			return threat2

		end

		return nil

	elseif !threat2 or threat2:IsObsolete() then

		return threat1

	end

	local closerThreat = self:SelectCloserThreat( me, threat1, threat2 )

	local botWeapon = me:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and GetTBotRegisteredWeapon( botWeapon:GetClass() ).WeaponType == "Melee" then

		-- If the bot is using a melee weapon, they should pick the closest enemy!
		return closerThreat

	end

	local isImmediateThreat1 = self:IsImmediateThreat( me, threat1 )
	local isImmediateThreat2 = self:IsImmediateThreat( me, threat2 )

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
	if me:IsThreatFiringAtMe( threat1:GetEntity() ) then

		if me:IsThreatFiringAtMe( threat2:GetEntity() ) then

			-- Choose closest
			return closerThreat

		end

		return threat1

	elseif me:IsThreatFiringAtMe( threat2:GetEntity() ) then

		return threat2

	end

	-- Choose closest
	return closerThreat

end

function TBotMainActionMeta:SelectCloserThreat( me, threat1, threat2 )

	local range1 = me:GetPos():DistToSqr( threat1:GetEntity():GetPos() )
	local range2 = me:GetPos():DistToSqr( threat2:GetEntity():GetPos() )

	if range1 < range2 then

		return threat1

	end

	return threat2

end

function TBotMainActionMeta:IsImmediateThreat( me, threat )

	local enemy = threat:GetEntity()
	if enemy:IsNPC() and !enemy:IsAlive() then

		return false

	end

	if enemy:IsPlayer() and !enemy:Alive() then

		return false

	end

	if enemy:IsNextBot() and enemy:Health() < 1 then

		return false

	end

	-- NEEDTOVALIDATE: Should I move this below the range and trace check,
	-- because this seems to cause the bot not to attack enemies behind them at times....
	if !threat:IsVisibleRecently() and !threat:TookDamageFromRecently() then

		return false

	end

	-- If the threat can't hurt the bot, they aren't an immediate threat
	local trace = {}
	util.TraceLine( { start = me:GetShootPos(), endpos = enemy:WorldSpaceCenter(), filter = me, mask = MASK_SHOT, output = trace } )
	if trace.Hit and trace.Entity != enemy then

		return false

	end

	local to = me:GetPos() - threat:GetLastKnownPosition()
	local threatRange = to:Length() -- Should this be LengthSqr instead?
	to:Normalize()

	local nearbyRange = 500
	if threatRange < nearbyRange then

		-- Very near threats are always immediately dangerous
		return true

	end

	if me:IsThreatFiringAtMe( enemy ) then

		-- Distant threat firing on me - an immediate threat whether in my FOV or not
		return true

	end

	return false

end