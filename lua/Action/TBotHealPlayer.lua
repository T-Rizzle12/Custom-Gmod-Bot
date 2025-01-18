-- TBotHealPlayer.lua
-- Purpose: This is the TBotHealPlayer MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotHealPlayerMeta = {}

function TBotHealPlayerMeta:__index( key )

	-- Search the metatable.
	local val = TBotHealPlayerMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotHealPlayer( healTarget )
	local tbothealplayer = TBotBaseAction()

	tbothealplayer.m_healTarget = healTarget
	tbothealplayer.m_chasePath = TBotChasePath()

	setmetatable( tbothealplayer, TBotHealPlayerMeta )

	return tbothealplayer

end

function TBotHealPlayerMeta:GetName()

	return "HealPlayer"
	
end

function TBotHealPlayerMeta:InitialContainedAction( me )

	return nil

end

function TBotHealPlayerMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotHealPlayerMeta:Update( me, interval )

	local botTable = me:GetTable()
	self.m_healTarget = self:FindHealTarget( me ) or self.m_healTarget -- Make sure we pick the closest player to heal!
	if !IsValid( self.m_healTarget ) or !self.m_healTarget:Alive() or !me:HasWeapon( "weapon_medkit" ) then
	
		return self:Done( "Our heal target is invalid or dead" )
		
	end
	
	if self.m_healTarget:Health() >= botTable.HealThreshold or self.m_healTarget:Health() >= self.m_healTarget:GetMaxHealth() then
	
		return self:Done( "Our heal target was healed to the heal threshold" )
		
	end
	
	-- If we are healing ourself in combat, finish when we hit the combat heal threshold or our health is getting low....
	local threat = me:GetTBotVision():GetPrimaryKnownThreat( true )
	if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
	
		if self.m_healTarget == me then 
		
			if me:Health() >= botTable.CombatHealThreshold then
	
				return self:Done( "We healed past the combat heal threshold and should go back to fighting" )
				
			end
			
		else
		
			if me:IsUnhealthy() then
			
				return self:Done( "Our health is getting low, so we should focus on fighting" )
				
			end
			
		end
		
	end
	
	-- Move closer to our heal target before attempting to heal them!
	local healTargetDist = me:GetPos():DistToSqr( self.m_healTarget:GetPos() )
	if healTargetDist > 75^2 or !me:IsLineOfFireClear( self.m_healTarget ) then
	
		-- Attack any enemies we know about while moving to heal our selected target!
		if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
		
			me:SelectBestWeapon( threat:GetEntity() )
			
		end
		
		self.m_chasePath:Update( me, self.m_healTarget ) -- Repathing is handled in chase path!
		
	else
		
		botTable.BestWeapon = me:GetWeapon( "weapon_medkit" )
		local botWeapon = me:GetActiveWeapon()
		if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() == "weapon_medkit" then
			
			if CurTime() >= botTable.FireWeaponInterval then 
				
				if self.m_healTarget == me then
				
					me:PressSecondaryAttack()
					botTable.FireWeaponInterval = CurTime() + 0.5
				
				elseif me:GetEyeTrace().Entity == self.m_healTarget then
					
					me:PressPrimaryAttack()
					botTable.FireWeaponInterval = CurTime() + 0.5
					
				end
				
			end
		
			-- NOTE: This has to be maximum priority to override aiming at enemies
			if self.m_healTarget != me then me:GetTBotBody():AimHeadTowards( self.m_healTarget, TBotLookAtPriority.MAXIMUM_PRIORITY, 1.0 ) end	
		end
		
	end
	
	return self:Continue()

end

function TBotHealPlayerMeta:FindHealTarget( me )
	
	local botTable				=	me:GetTable()
	local targetdistsqr			=	tonumber( botTable.FollowDist ) or 200 -- This will allow the bot to select the closest teammate to it.
	targetdistsqr				=	targetdistsqr^2 -- This is ugly, but I don't have much of a choice.....
	local target				=	nil -- This is the closest teammate to the bot.
	
	--The bot should heal its owner and itself before it heals anyone else
	local tbotOwner = botTable.TBotOwner
	if IsValid( tbotOwner ) and tbotOwner:Alive() and tbotOwner:Health() < botTable.HealThreshold and tbotOwner:Health() < tbotOwner:GetMaxHealth() and tbotOwner:GetPos():DistToSqr( me:GetPos() ) < targetdistsqr then return tbotOwner
	elseif ( me:Health() < botTable.CombatHealThreshold or ( me:Health() < botTable.HealThreshold and !me:IsInCombat() ) ) and me:Health() < me:GetMaxHealth() then return me end

	local searchPos = IsValid( tbotOwner ) and tbotOwner:Alive() and tbotOwner:GetPos() or me:GetPos()
	local vision = me:GetTBotVision()
	for k, ply in player.Iterator() do
	
		if IsValid( ply ) and ply:Alive() and !me:IsEnemy( ply ) and ply:Health() < botTable.HealThreshold and ply:Health() < ply:GetMaxHealth() and vision:IsAbleToSee( ply ) then -- The bot will heal any teammate that needs healing that we can actually see and are alive.
			
			local teammatedistsqr = ply:GetPos():DistToSqr( searchPos )
			
			if teammatedistsqr < targetdistsqr then 
				target = ply
				targetdistsqr = teammatedistsqr
			end
		end
	end
	
	return target
	
end

function TBotHealPlayerMeta:OnEnd( me, nextAction )

	return

end

function TBotHealPlayerMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotHealPlayerMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotHealPlayerMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotHealPlayerMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_YES

end

-- Is it time to retreat?
function TBotHealPlayerMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_NO

end

-- Should we attack "them"
function TBotHealPlayerMeta:ShouldAttack( me, them )

	-- Only attack if we are not using the medkit!
	local botWeapon = me:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:GetClass() != "weapon_medkit" then
	
		return TBotQueryResultType.ANSWER_YES
		
	end

	return TBotQueryResultType.ANSWER_NO

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotHealPlayerMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotHealPlayerMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotHealPlayerMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotHealPlayerMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end