-- TBotFollowGroupLeader.lua
-- Purpose: This is the TBotFollowGroupLeader MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotFollowGroupLeaderMeta = {}

function TBotFollowGroupLeaderMeta:__index( key )

	-- Search the metatable.
	local val = TBotFollowGroupLeaderMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotFollowGroupLeader()
	local tbotfollowgroupleader = TBotBaseAction()

	tbotfollowgroupleader.m_chasePath = TBotChasePath()
	tbotfollowgroupleader.m_repathTimer = util.Timer( math.Rand( 3.0, 5.0 ) )

	setmetatable( tbotfollowgroupleader, TBotFollowGroupLeaderMeta )

	return tbotfollowgroupleader

end

function TBotFollowGroupLeaderMeta:GetName()

	return "FollowGroupLeader"
	
end

function TBotFollowGroupLeaderMeta:InitialContainedAction( me )

	return nil

end

function TBotFollowGroupLeaderMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotFollowGroupLeaderMeta:Update( me, interval )

	local botTable = me:GetTable()
	local owner = botTable.TBotOwner
	local groupLeader = botTable.GroupLeader
	if !IsValid( groupLeader ) or !groupLeader:Alive() then
	
		return self:Done( "Our group leader is either invalid or dead" )
		
	end
	
	if IsValid( owner ) and owner:Alive() then
	
		return self:Done( "Our owner is valid and alive and we should follow them instead" )
		
	end
	
	local leaderDist = groupLeader:GetPos():DistToSqr( me:GetPos() )
	if leaderDist <= botTable.FollowDist^2 and me:IsLineOfFireClear( groupLeader ) then
	
		return self:Done( "We are close enough to our group leader" )
		
	end

	-- Sprint if we are too far from our group leader!
	if leaderDist > botTable.DangerDist^2 then
	
		me:PressRun()
	
	-- Slow walk if we are close enough and our group leader is slow walking.
	elseif groupLeader:KeyDown( IN_WALK ) then
	
		me:PressWalk()
	
	end

	self.m_chasePath:Update( me, groupLeader )
	
	if self.m_repathTimer:Elapsed() then
	
		self.m_repathTimer:Start( math.Rand( 3.0, 5.0 ) )
		
		-- Don't recreate the path if Update just recomputed it.
		if self.m_chasePath:GetAge() > 0.0 then
		
			self.m_chasePath:Invalidate()
			
		end
		
	end

	return self:Continue()

end

function TBotFollowGroupLeaderMeta:OnEnd( me, nextAction )

	return

end

function TBotFollowGroupLeaderMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotFollowGroupLeaderMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotFollowGroupLeaderMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotFollowGroupLeaderMeta:ShouldHurry( me )

	-- The bot should be in a hurry if its too far from its group leader!
	local botTable = me:GetTable()
	local groupLeader = botTable.GroupLeader
	local leaderDist = groupLeader:GetPos():DistToSqr( me:GetPos() )
	if leaderDist > botTable.DangerDist^2 then
	
		return TBotQueryResultType.ANSWER_YES
		
	end

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotFollowGroupLeaderMeta:ShouldRetreat( me )

	-- The bot should not retreat if its too far from its group leader!
	local botTable = me:GetTable()
	local groupLeader = botTable.GroupLeader
	local leaderDist = groupLeader:GetPos():DistToSqr( me:GetPos() )
	if leaderDist > botTable.DangerDist^2 then
	
		return TBotQueryResultType.ANSWER_NO
		
	end

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotFollowGroupLeaderMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotFollowGroupLeaderMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotFollowGroupLeaderMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotFollowGroupLeaderMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotFollowGroupLeaderMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end