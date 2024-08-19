-- TBotChasePath.lua
-- Purpose: This is the TBotChasePath MetaTable
-- Author: T-Rizzle

local BaseClass = FindMetaTable( "TBotPathFollower" )
local BaseClass2 = FindMetaTable( "TBotPath" )

-- Local chase variables
local LEAD_SUBJECT = 0
local DONT_LEAD_SUBJECT = 1

local TBotChasePathMeta = {}

function TBotChasePathMeta:__index( key )

	-- Search the metatable.
	local val = TBotChasePathMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	-- Search the base base class.
	val = BaseClass2[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotChasePath( chaseHow )
	local tbotchasepath = TBotPathFollower() -- HACKHACK: We have to create a path object in order for it to have the stuff intialized....
	
	tbotchasepath.m_failTimer = util.Timer()
	tbotchasepath.m_failTimer:Reset()
	tbotchasepath.m_throttleTimer = util.Timer()
	tbotchasepath.m_throttleTimer:Reset()
	tbotchasepath.m_lifetimeTimer = util.Timer()
	tbotchasepath.m_lifetimeTimer:Reset()
	tbotchasepath.m_lastPathSubject = nil
	tbotchasepath.m_chaseHow = tonumber( chaseHow ) or LEAD_SUBJECT
	
	setmetatable( tbotchasepath, TBotChasePathMeta )
	
	return tbotchasepath

end

function TBotChasePathMeta:GetLeadRadius()

	return 500.0
	
end

function TBotChasePathMeta:GetLifeTime()

	return 0.0
	
end

function TBotChasePathMeta:Invalidate()

	-- Path is gone, repath at earliest opportunity
	self.m_throttleTimer:Reset()
	self.m_lifetimeTimer:Reset()
	
	-- Extend
	BaseClass.Invalidate( self )
	
end

-- Make the bot move.
function TBotChasePathMeta:Update( bot, subject, cost, pPredictedSubjectPos )
	
	-- Maintain path to the subject
	self:RefreshPath( bot, subject, cost, pPredictedSubjectPos )
	
	-- Move along the path towards the threat
	-- HACKHACK: For some reason we have to call __index.
	BaseClass.Update( self, bot )
	
end

function TBotChasePathMeta:IsRepathNeeded( bot, subject )

	-- The closer we get, the more accurate out path needs to be.
	local to = subject:GetPos() - bot:GetPos()
	
	local minTolerance = 0.0
	local toleranceRate = 0.33
	
	local tolerance = minTolerance + toleranceRate * to:Length()
	
	return ( subject:GetPos() - self:GetEndPosition() ):IsLengthGreaterThan( tolerance )

end

function TBotChasePathMeta:RefreshPath( bot, subject, cost, pPredictedSubjectPos )

	local botTable = bot:GetTable()
	local mover = bot:GetTBotLocomotion()
	
	-- Don't change our path if we're on a ladder
	if self:IsValid() and mover:IsUsingLadder() then
	
		self.m_throttleTimer:Start( 1.0 )
		return
		
	end
	
	if !IsValid( subject ) then
	
		return
		
	end
	
	if !self.m_failTimer:Elapsed() then
	
		return
		
	end
	
	-- If our path subject changed, repath immediately
	if subject != self.m_lastPathSubject then
	
		self:Invalidate()
		
		-- New subject, fresh attempt
		self.m_failTimer:Reset()
		
	end
	
	if self:IsValid() and !self.m_throttleTimer:Elapsed() then
	
		-- Require a minimum time between repaths, as long as we have a path to follow
		return
		
	end
	
	if self:IsValid() and self.m_lifetimeTimer:Started() and self.m_lifetimeTimer:Elapsed() then
	
		-- This path's lifetime has elapsed
		self:Invalidate()
		
	end
	
	if !self:IsValid() or self:IsRepathNeeded( bot, subject ) then
		
		-- the situation has changed - try a new path
		local isPath = false
		local pathTarget = subject:GetPos()
		
		if self.m_chaseHow == LEAD_SUBJECT then
		
			pathTarget = isvector( pPredictedSubjectPos ) and pPredictedSubjectPos or self:PredictSubjectPostion( bot, subject )
			isPath = self:Compute( bot, pathTarget, cost )
			
		else
		
			isPath = self:Compute( bot, pathTarget, cost )
			
		end
		
		if isPath then
		
			self.m_lastPathSubject = subject
			
			self.m_throttleTimer:Start( 0.5 )
			
			-- Track the lifetime of this new path
			local lifetime = self:GetLifeTime()
			if lifetime > 0.0 then
			
				self.m_lifetimeTimer:Start( lifetime )
				
			else
			
				self.m_lifetimeTimer:Reset()
				
			end
			
		else
		
			self.m_failTimer:Start( 0.005 * bot:GetPos():Distance( subject:GetPos() ) )
			
			self:Invalidate()
			
		end
		
	end

end

-- This is used by chase pathfinder to predict where the subject is moving to cut them off.
function TBotChasePathMeta:PredictSubjectPostion( bot, subject )

	local subjectPos = subject:GetPos()
	local mover = bot:GetTBotLocomotion()
	
	local to = subjectPos - bot:GetPos()
	to.z = 0.0
	local flRangeSq = to:LengthSqr()
	
	-- The bot shouldn't attempt to cut off their target if they are too far away!
	if flRangeSq > self:GetLeadRadius()^2 then
	
		return subjectPos
		
	end
	
	local range = math.sqrt( flRangeSq )
	to = to / ( range + 0.0001 ) -- Avoid divide by zero
	
	-- Estimate time to reach subject, assuming maximum speed for now.....
	local leadTime = 0.5 + ( range / ( bot:GetRunSpeed() + 0.0001 ) )
	
	-- Estimate amount to lead the subject
	local lead = leadTime * subject:GetVelocity()
	lead.z = 0.0
	
	if to:Dot( lead ) < 0.0 then
	
		-- The subject is moving towards us - only pay attention
		-- to his perpendicular velocity for leading
		local to2D = to:AsVector2D()
		to2D:Normalize()
		
		local perp = Vector( -to2D.y, to2D.x )
		
		local enemyGroundSpeed = lead.x * perp.x + lead.y * perp.y
		
		lead.x = enemyGroundSpeed * perp.x
		lead.y = enemyGroundSpeed * perp.y
		
	end
	
	-- Computer our desired destination
	local pathTarget = subjectPos + lead
	
	-- Validate this destination
	
	-- Don't lead through walls
	if lead:LengthSqr() > 36.0 then
	
		local isTraversable, fraction = mover:IsPotentiallyTraversable( subjectPos, pathTarget )
		if !isTraversable then
		
			-- Tried to lead through an unwalkable area - clip to walkable space
			pathTarget = subjectPos + fraction * ( pathTarget - subjectPos )
			
		end
		
	end
	
	-- Don't lead over cliffs
	local leadArea = navmesh.GetNearestNavArea( pathTarget )
	
	if !IsValid( leadArea ) or leadArea:GetZ( pathTarget ) < pathTarget.z - mover:GetMaxJumpHeight() then
	
		-- Would fall off a cliff
		return subjectPos
		
	end
	
	return pathTarget

end