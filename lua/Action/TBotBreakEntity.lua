-- TBotBreakEntity.lua
-- Purpose: This is the TBotBreakEntity MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotBreakEntityMeta = {}

function TBotBreakEntityMeta:__index( key )

	-- Search the metatable.
	local val = TBotBreakEntityMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotBreakEntity( breakable )
	local tbotbreakentity = TBotBaseAction()

	tbotbreakentity.m_breakable = breakable

	setmetatable( tbotbreakentity, TBotBreakEntityMeta )

	return tbotbreakentity

end

function TBotBreakEntityMeta:GetName()

	return "BreakEntity"
	
end

function TBotBreakEntityMeta:InitialContainedAction( me )

	return nil

end

function TBotBreakEntityMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotBreakEntityMeta:Update( me, interval )

	local botTable = me:GetTable()
	if !IsValid( self.m_breakable ) then
	
		botTable.m_breakable = nil
		return self:Done( "Entity was destroyed" )
		
	end
	
	if !self.m_breakable:IsBreakable() or self.m_breakable:NearestPoint( me:GetPos() ):DistToSqr( me:GetPos() ) > 6400 or !me:GetTBotVision():IsAbleToSee( self.m_breakable ) then
		
		botTable.m_breakable = nil
		return self:Done( "Entity is either not breakable, too far away, or out of our LOS" )
		
	end
	
	me:GetTBotBody():AimHeadTowards( self.m_breakable:WorldSpaceCenter(), TBotLookAtPriority.MAXIMUM_PRIORITY, 0.5 )
	
	if me:IsLookingAtPosition( self.m_breakable:WorldSpaceCenter() ) then
		
		local botWeapon = botTable.BestWeapon
		if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and botWeapon:GetClass() != "weapon_medkit" then
			
			if GetTBotRegisteredWeapon( botWeapon:GetClass() ).WeaponType == "Melee" then
				
				local rangeToShoot = me:GetShootPos():DistToSqr( self.m_breakable:WorldSpaceCenter() )
				local rangeToStand = me:GetPos():DistToSqr( self.m_breakable:WorldSpaceCenter() )
				
				-- If the breakable is on the ground and we are using a melee weapon
				-- we have to crouch in order to hit it
				if rangeToShoot <= 4900 and rangeToShoot > rangeToStand then
					
					me:PressCrouch()
					
				end
				
			end
			
			if botWeapon:IsPrimaryClipEmpty() then
				
				if CurTime() >= botTable.ReloadInterval and !me:IsReloading() then
				
					me:PressReload()
					botTable.ReloadInterval = CurTime() + 0.5
					
				end
				
			elseif CurTime() >= botTable.FireWeaponInterval and me:GetActiveWeapon() == botWeapon then
				
				me:PressPrimaryAttack()
				botTable.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )
				
			end
			
		else
			
			local bestWeapon		=	nil
			
			for k, weapon in ipairs( me:GetWeapons() ) do
		
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
	
	return self:Continue()

end

function TBotBreakEntityMeta:OnEnd( me, nextAction )

	return

end

function TBotBreakEntityMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotBreakEntityMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotBreakEntityMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_NO

end

-- Are we in a hurry?
function TBotBreakEntityMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_YES

end

-- Is it time to retreat?
function TBotBreakEntityMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_NO

end

-- Should we attack "them"
function TBotBreakEntityMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_NO

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotBreakEntityMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotBreakEntityMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotBreakEntityMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotBreakEntityMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end