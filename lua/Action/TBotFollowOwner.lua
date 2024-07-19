-- TBotFollowOwner.lua
-- Purpose: This is the TBotFollowOwner MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotFollowOwnerMeta = {}

function TBotFollowOwnerMeta:__index( key )

	-- Search the metatable.
	local val = TBotFollowOwnerMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotFollowOwner()
	local tbotfollowowner = TBotBaseAction()

	tbotfollowowner.m_chasePath = TBotChasePath()
	tbotfollowowner.m_repathTimer = util.Timer( math.Rand( 3.0, 5.0 ) )

	setmetatable( tbotfollowowner, TBotFollowOwnerMeta )

	return tbotfollowowner

end

function TBotFollowOwnerMeta:GetName()

	return "FollowOwner"
	
end

function TBotFollowOwnerMeta:InitialContainedAction( me )

	return nil

end

function TBotFollowOwnerMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotFollowOwnerMeta:Update( me, interval )

	local botTable = me:GetTable()
	local owner = botTable.TBotOwner
	if !IsValid( owner ) or !owner:Alive() then
	
		return self:Done( "Our owner is either invalid or dead" )
		
	end
	
	local ownerDist = owner:GetPos():DistToSqr( me:GetPos() )
	if ownerDist <= botTable.FollowDist^2 and me:IsLineOfFireClear( owner ) then
	
		return self:Done( "We are close enough to our owner" )
		
	end

	-- Sprint if we are too far from our owner!
	if ownerDist > botTable.DangerDist^2 then
	
		me:PressRun()
	
	-- Slow walk if we are close enough and our owner is slow walking.
	elseif owner:KeyDown( IN_WALK ) then
	
		me:PressWalk()
	
	end

	self.m_chasePath:Update( me, owner )
	
	if self.m_repathTimer:Elapsed() then
	
		self.m_repathTimer:Start( math.Rand( 3.0, 5.0 ) )
		
		-- Don't recreate the path if Update just recomputed it.
		if self.m_chasePath:GetAge() > 0.0 then
		
			self.m_chasePath:Invalidate()
			
		end
		
	end

	return self:Continue()

end

function TBotFollowOwnerMeta:OnEnd( me, nextAction )

	return

end

function TBotFollowOwnerMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotFollowOwnerMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotFollowOwnerMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotFollowOwnerMeta:ShouldHurry( me )

	-- The bot should be in a hurry if its too far from its owner!
	local botTable = me:GetTable()
	local owner = botTable.TBotOwner
	local ownerDist = owner:GetPos():DistToSqr( me:GetPos() )
	if ownerDist > botTable.DangerDist^2 then
	
		return TBotQueryResultType.ANSWER_YES
		
	end

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotFollowOwnerMeta:ShouldRetreat( me )

	-- The bot should not retreat if its too far from its owner!
	local botTable = me:GetTable()
	local owner = botTable.TBotOwner
	local ownerDist = owner:GetPos():DistToSqr( me:GetPos() )
	if ownerDist > botTable.DangerDist^2 then
	
		return TBotQueryResultType.ANSWER_NO
		
	end

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotFollowOwnerMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotFollowOwnerMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotFollowOwnerMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotFollowOwnerMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotFollowOwnerMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end