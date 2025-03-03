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

	-- HACKHACK: We create our own IntervalTimer here, I should probably create a pull request and have this added to the base game.
	local intervalTimer = {}
	intervalTimer.m_timestamp = -1.0
	intervalTimer.Reset = function( self ) self.m_timestamp = CurTime() end
	intervalTimer.Start = function( self ) self.m_timestamp = CurTime() end
	intervalTimer.Invalidate = function( self ) self.m_timestamp = -1.0 end
	intervalTimer.HasStarted = function( self ) return self.m_timestamp > 0 end
	intervalTimer.GetElapsedTime = function( self ) return Either( self:HasStarted(), CurTime() - self.m_timestamp, 99999.9 ) end
	intervalTimer.IsLessThen = function( self, duration ) return CurTime() - self.m_timestamp < duration end
	intervalTimer.IsGreaterThen = function( self, duration ) return CurTime() - self.m_timestamp > duration end
	intervalTimer.__index = intervalTimer
	tbotfollowgroupleader.m_teleportTimer = intervalTimer
	
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

	self.m_teleportTimer:Invalidate()
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

	-- Repath every now and then to keep the path fresh
	if self.m_repathTimer:Elapsed() then
	
		self.m_repathTimer:Start( math.Rand( 3.0, 5.0 ) )
		self.m_chasePath:Invalidate()
		
	end
	
	self.m_chasePath:Update( me, groupLeader )

	-- Check if the bot is stuck or unable to path to the player
	local mover = me:GetTBotLocomotion()
	if !self.m_chasePath:IsValid() or mover:IsStuck() then
	
		if !self.m_teleportTimer:HasStarted() then
		
			self.m_teleportTimer:Start()
			
		end
		
		-- After 5 seconds the bot should attempt to teleport now!
		if self.m_teleportTimer:IsGreaterThen( 5.0 ) then
		
			local playerFOV = math.cos( 0.5 * owner:GetFOV() * math.pi / 180 )
			local navareas = navmesh.Find( owner:GetPos(), 2000, mover:GetMaxJumpHeight(), mover:GetMaxJumpHeight() )
			local lastKnownArea = owner:GetLastKnownArea()
			for _, area in ipairs( navareas ) do
			
				-- We don't want to teleport infront of the player as that would ruin the immersion a bit
				local teleportPos = area:GetCenter()
				if !area:IsPotentiallyVisible( lastKnownArea ) and !self:CanPlayerPotentiallySeeUsTeleport( owner, teleportPos ) then
				
					if !me:IsSpotOccupied( teleportPos ) then
					
						me:SetPos( teleportPos )
						mover:ClearStuckStatus()
						self.m_chasePath:Invalidate() -- Just in case the bot was stuck!
						break
						
					end
				
				end
			
			end
			
			self.m_teleportTimer:Invalidate()
		
		end
	
	elseif self.m_teleportTimer:HasStarted() then
	
		self.m_teleportTimer:Invalidate()
	
	end
	
	return self:Continue()

end

function TBotFollowGroupLeaderMeta:CanPlayerPotentiallySeeUsTeleport( player, pos, cosTolerance )

	cosTolerance = cosTolerance or math.cos( 0.5 * player:GetFOV() * math.pi / 180 )
	local to = pos - player:GetPos()
	local diff = player:GetAimVector():Dot( to )
	if diff < 0 then return false end
	
	local length = to:LengthSqr()
	
	return diff^2 > length * cosTolerance^2

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
