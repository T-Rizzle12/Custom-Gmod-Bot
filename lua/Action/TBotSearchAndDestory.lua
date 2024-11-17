-- TBotSearchAndDestory.lua
-- Purpose: This is the TBotSearchAndDestory MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotSearchAndDestoryMeta = {}

function TBotSearchAndDestoryMeta:__index( key )

	-- Search the metatable.
	local val = TBotSearchAndDestoryMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotSearchAndDestory( duration )
	duration = tonumber( duration ) or math.Rand( 30.0, 60.0 )
	local tbotsearchanddestory = TBotBaseAction()

	tbotsearchanddestory.m_path = TBotPathFollower()
	tbotsearchanddestory.m_huntTime = duration
	tbotsearchanddestory.m_goalArea = nil
	tbotsearchanddestory.m_repathTimer = util.Timer()
	tbotsearchanddestory.m_giveUpTimer = util.Timer( duration )

	setmetatable( tbotsearchanddestory, TBotSearchAndDestoryMeta )

	return tbotsearchanddestory

end

function TBotSearchAndDestoryMeta:GetName()

	return "SearchAndDestory"
	
end

function TBotSearchAndDestoryMeta:InitialContainedAction( me )

	return nil

end

function TBotSearchAndDestoryMeta:OnStart( me, priorAction )

	self:RecomputeSeekPath( me )
	self.m_giveUpTimer:Start( self.m_huntTime )

	return self:Continue()

end

function TBotSearchAndDestoryMeta:Update( me, interval )

	local botTable = me:GetTable()
	if self.m_giveUpTimer:Elapsed() then
	
		return self:Done( "Behavior duration elapsed" )
		
	end
	
	if IsValid( botTable.TBotOwner ) and botTable.TBotOwner:Alive() then
	
		return self:Done( "Our owner is valid and alive and we should follow them instead" )
		
	end
	
	local threat = me:GetTBotVision():GetPrimaryKnownThreat()
	if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) and threat:IsVisibleRecently() then
	
		return self:Done( "Found an enemy" )
		
	end
	
	-- Move towards our seek goal
	self.m_path:Update( me )
	
	if !self.m_path:IsValid() and self.m_repathTimer:Elapsed() then
	
		self.m_repathTimer:Start( 1.0 )
		
		self:RecomputeSeekPath( me )
		
	end
	
	return self:Continue()

end

function TBotSearchAndDestoryMeta:RecomputeSeekPath( me )

	local goalVector = navmesh.Find( me:GetPos(), math.huge, me:GetTBotLocomotion():GetMaxJumpHeight(), 1000 )
	
	if #goalVector == 0 then
	
		self.m_path:Invalidate()
		return
		
	end
	
	self.m_path:Compute( me, goalVector[ math.random( #goalVector ) ]:GetCenter() )
	
end

function TBotSearchAndDestoryMeta:OnEnd( me, nextAction )

	return

end

function TBotSearchAndDestoryMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotSearchAndDestoryMeta:OnResume( me, interruptingAction )

	self:RecomputeSeekPath( me )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotSearchAndDestoryMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotSearchAndDestoryMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotSearchAndDestoryMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotSearchAndDestoryMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotSearchAndDestoryMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotSearchAndDestoryMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotSearchAndDestoryMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotSearchAndDestoryMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end