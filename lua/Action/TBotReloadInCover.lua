-- TBotReloadInCover.lua
-- Purpose: This is the TBotReloadInCover MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotReloadInCoverMeta = {}

function TBotReloadInCoverMeta:__index( key )

	-- Search the metatable.
	local val = TBotReloadInCoverMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotReloadInCover( maxRange )
	maxRange = tonumber( maxRange ) or 1000
	local tbotreloadincover = TBotBaseAction()

	tbotreloadincover.m_path = TBotPathFollower()
	tbotreloadincover.m_repathTimer = util.Timer()
	tbotreloadincover.m_coverSpot = nil
	tbotreloadincover.m_maxRange = maxRange

	setmetatable( tbotreloadincover, TBotReloadInCoverMeta )

	return tbotreloadincover

end

function TBotReloadInCoverMeta:GetName()

	return "ReloadInCover"
	
end

function TBotReloadInCoverMeta:InitialContainedAction( me )

	return nil

end

function TBotReloadInCoverMeta:OnStart( me, priorAction )

	self.m_coverSpot = me:FindSpot( "near", { pos = me:GetPos(), radius = self.m_maxRange, stepdown = 1000, stepup = me:GetMaxJumpHeight(), checksafe = 1, checkoccupied = 1, checklineoffire = 1 } )
	
	if !isvector( self.m_coverSpot ) then
	
		return self:Done( "No cover available" )
		
	end
	
	return self:Continue()

end

function TBotReloadInCoverMeta:Update( me, interval )

	local botTable = me:GetTable()
	local threat = me:GetTBotVision():GetPrimaryKnownThreat( true )

	-- Attack while retreating
	if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
	
		me:SelectBestWeapon( threat:GetEntity() )
		
	end
	
	-- Reload while moving to cover
	local botWeapon = me:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and botWeapon:NeedsToReload() then
	
		if CurTime() >= botTable.ReloadInterval and !me:IsReloading() then

			me:PressReload()
			botTable.ReloadInterval = CurTime() + 0.5

		end
		
	else
	
		return self:Done( "We have finished reloading our weapon in cover" )
	
	end
	
	-- Move to cover, or stop if we've found opportunistic cover (no visible threats right now)
	local spotDist = me:GetPos():DistToSqr( self.m_coverSpot )
	if spotDist <= 32^2 or !threat then
	
		-- We are now in cover
		if threat then
		
			self.m_coverSpot = me:FindSpot( "near", { pos = me:GetPos(), radius = self.m_maxRange, stepdown = 1000, stepup = me:GetMaxJumpHeight(), checksafe = 1, checkoccupied = 1, checklineoffire = 1 } )
			
			if !isvector( self.m_coverSpot ) then
			
				return self:Done( "My cover is exposed, and there is no other cover available!" )
				
			end
			
		end
		
		-- Stay in cover while we fully reload
		-- Crouch while we are reloading
		-- NEEDTOVALIDATE: Should the bot crouch while reloading?
		me:PressCrouch()
		
	else
	
		-- Not in cover yet
		if self.m_repathTimer:Elapsed() then
		
			self.m_repathTimer:Start( math.Rand( 0.3, 0.5 ) )
			
			self.m_path:Compute( me, self.m_coverSpot )
			
		end
		
		self.m_path:Update( me )
		
	end
	
	return self:Continue()

end

function TBotReloadInCoverMeta:OnEnd( me, nextAction )

	return

end

function TBotReloadInCoverMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotReloadInCoverMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotReloadInCoverMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotReloadInCoverMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_YES

end

-- Is it time to retreat?
function TBotReloadInCoverMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotReloadInCoverMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotReloadInCoverMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotReloadInCoverMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotReloadInCoverMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotReloadInCoverMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end