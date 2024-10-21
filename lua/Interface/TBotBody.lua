-- TBotBody.lua
-- Purpose: This is the TBotBody MetaTable
-- Author: T-Rizzle

-- Setup lookatpriority level variables
TBotLookAtPriority = {}
TBotLookAtPriority.LOW_PRIORITY		=	0
TBotLookAtPriority.MEDIUM_PRIORITY	=	1
TBotLookAtPriority.HIGH_PRIORITY	=	2
TBotLookAtPriority.MAXIMUM_PRIORITY	=	3

local TBotBodyMeta = {}

TBotBodyMeta.__index = TBotBodyMeta

baseclass.Set( "TBotBody", TBotBodyMeta ) -- Register this class so we can derive this for other gamemodes.

function TBotBody( bot )
	local tbotbody = {}

	-- NEEDTOVALIDATE: Do we need these?
	--tbotbody.m_curInterval = engine.TickInterval()
	--tbotbody.m_lastUpdateTime = 0
	tbotbody.m_bot = bot
	tbotbody.m_lookAtPos = Vector() -- For throttling update rate as needed!
	tbotbody.m_lookAtSubject = nil -- The set of enemies and friends we are aware of
	tbotbody.m_lookAtVelocity = Vector()
	tbotbody.m_lookAtTrackingTimer = util.Timer()
	
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
	
	tbotbody.m_lookAtPriority = TBotLookAtPriority.LOW_PRIORITY
	tbotbody.m_lookAtExpireTimer = util.Timer()
	tbotbody.m_lookAtDurationTimer = setmetatable( {}, intervalTimer )
	tbotbody.m_isSightedIn = false
	tbotbody.m_hasBeenSightedIn = false
	tbotbody.m_headSteadyTimer = setmetatable( {}, intervalTimer )
	tbotbody.m_priorAngles = Angle()
	tbotbody.m_desiredAngles = Angle()
	
	tbotbody.m_anchorRepositionTimer = util.Timer()
	tbotbody.m_anchorForward = Vector()

	setmetatable( tbotbody, TBotBodyMeta )

	tbotbody:Reset()

	return tbotbody

end

function TBotBodyMeta:Reset()

	--self.m_curInterval = engine.TickInterval()
	--self.m_lastUpdateTime = 0
	self.m_lookAtPos:Zero()
	self.m_lookAtSubject = nil
	self.m_lookAtVelocity:Zero()
	self.m_lookAtExpireTimer:Reset()
	
	self.m_lookAtPriority = TBotLookAtPriority.LOW_PRIORITY
	self.m_lookAtExpireTimer:Reset()
	self.m_lookAtDurationTimer:Invalidate()
	self.m_isSightedIn = false
	self.m_hasBeenSightedIn = false
	self.m_headSteadyTimer:Invalidate()
	self.m_priorAngles:Zero()
	self.m_anchorRepositionTimer:Reset()
	self.m_anchorForward:Zero()
	
end

function TBotBodyMeta:GetBot()

	return self.m_bot

end

-- This is the same approach angle used in the source engine.
-- I got this from the TF2 Source Code, since this body code
-- is also from it as well.
function TBotBodyMeta:ApproachAngle( target, value, speed )

	target = target % 360
	value = value % 360
	
	local delta = target - value
	
	-- Speed is assumed to be positive
	if speed < 0 then
	
		speed = -speed
		
	end
	
	if delta < -180 then
	
		delta = delta + 360
		
	elseif delta > 180 then
	
		delta = delta - 360
		
	end
	
	if delta > speed then
	
		value = value + speed
		
	elseif delta < -speed then
	
		value = value - speed
		
	else
	
		value = target
		
	end
	
	return value

end

function TBotBodyMeta:Upkeep()
	
	local deltaT = FrameTime()
	if deltaT < 0.00001 then
	
		return
		
	end
	
	local bot = self:GetBot()
	local botTable = bot:GetTable()
	-- If we are frozen don't update our aim!!!!
	if bot:IsFrozen() then 
	
		return 
		
	end 
	
	-- NOTE: This fixes a long time bug of where the bot would spin rapidly, sigh........
	-- HACKHACK: If we are in a vehicle, use local eye angles since its not affected by the vehicle's
	-- parent adjustment to the player's eye angles.
	local eyeAngles = bot:EyeAngles()
	local alternateForward = false
	if bot:InVehicle() then
	
		eyeAngles = bot:LocalEyeAngles()
		alternateForward = true
		
	end
	
	local currentAngles = eyeAngles + bot:GetViewPunchAngles()
	
	-- track when our head is "steady"
	local isSteady = true
	
	local actualPitchRate = math.AngleDifference( currentAngles.x, self.m_priorAngles.x )
	if math.abs( actualPitchRate ) > 100 * deltaT then
	
		isSteady = false
		
	else
	
		local actualYawRate = math.AngleDifference( currentAngles.y, self.m_priorAngles.y )
		if math.abs( actualYawRate ) > 100 * deltaT then
		
			isSteady = false
			
		end
		
	end
	
	if isSteady then
	
		if !self.m_headSteadyTimer:HasStarted() then
		
			self.m_headSteadyTimer:Start()
			
		end
		
	else
	
		self.m_headSteadyTimer:Invalidate()
		
	end
	
	self.m_priorAngles = currentAngles * 1
	
	-- if our current look-at has expired, don't change our aim further
	if self.m_hasBeenSightedIn and self.m_lookAtExpireTimer:Elapsed() then
	
		return
		
	end
	
	-- simulate limited range of mouse movements
	-- compute the angle change from center
	-- NOTE: We have to use the alternateForward with LocalEyeAngles or the bot will never get to the point of being m_isSightedIn
	local forward = alternateForward and eyeAngles:Forward() or bot:GetAimVector()
	local deltaAngle = math.deg( math.acos( forward:Dot( self.m_anchorForward ) ) )
	if deltaAngle > 100 then
	
		self.m_anchorRepositionTimer:Start( math.Rand( 0.9, 1.1 ) * 0.3 )
		self.m_anchorForward = forward
		
	end
	
	-- If we're currently recentering our "virtual mouse", wait
	if self.m_anchorRepositionTimer:Started() and !self.m_anchorRepositionTimer:Elapsed() then
	
		return
		
	end
	
	self.m_anchorRepositionTimer:Reset()
	
	local subject = self.m_lookAtSubject
	if IsValid( subject ) then
	
		if self.m_lookAtTrackingTimer:Elapsed() then
		
			local desiredLookAtPos = bot:GetTBotBehavior():SelectTargetPoint( bot, subject )
			desiredLookAtPos = desiredLookAtPos + self:GetHeadAimSubjectLeadTime() * subject:GetVelocity()
			
			local errorVector = desiredLookAtPos - self.m_lookAtPos
			local Error = errorVector:Length()
			errorVector:Normalize()
			
			local trackingInterval = self:GetHeadAimTrackingInterval()
			if trackingInterval < deltaT then
			
				trackingInterval = deltaT
				
			end
			
			local errorVel = Error / trackingInterval
			
			self.m_lookAtVelocity = ( errorVel * errorVector ) + subject:GetVelocity()
			
			self.m_lookAtTrackingTimer:Start( math.Rand( 0.8, 1.2 ) * trackingInterval )
			
		end
		
		self.m_lookAtPos = self.m_lookAtPos + deltaT * self.m_lookAtVelocity
		
	end
	
	local to = self.m_lookAtPos - bot:GetShootPos()
	to:Normalize()
	
	local desiredAngles = to:Angle()
	local angles = Angle()
	
	local onTargetTolerance = 0.98
	local dot = forward:Dot( to )
	if dot > onTargetTolerance then
	
		self.m_isSightedIn = true
		
		if !self.m_hasBeenSightedIn then
		
			self.m_hasBeenSightedIn = true
			
		end
		
	else
	
		self.m_isSightedIn = false
		
	end
	
	-- rotate view at a rate proportional to how far we have to turn
	-- max rate if we need to turn around
	-- want first derivative continuity of rate as our aim hits to avoid pop
	local approachRate = self:GetMaxHeadAngularVelocity()
	
	local easeOut = 0.7
	if dot > easeOut then
	
		local t = math.Remap( dot, easeOut, 1.0, 1.0, 0.02 )
		approachRate = approachRate * math.sin( 1.57 * t )
		
	end
	
	local targetDuration = self.m_lookAtDurationTimer:GetElapsedTime()
	if targetDuration < 0.25 then
	
		approachRate = approachRate * ( targetDuration / 0.25 )
		
	end
	
	--print( "Current Angles:", currentAngles )
	--print( "Desired Angles: ", desiredAngles )
	--print( approachRate * deltaT )
	--angles.y = math.ApproachAngle( currentAngles.y, desiredAngles.y, approachRate * deltaT )
	--angles.x = math.ApproachAngle( currentAngles.x, desiredAngles.x, 0.5 * approachRate * deltaT )
	angles.y = self:ApproachAngle( desiredAngles.y, currentAngles.y, approachRate * deltaT )
	angles.x = self:ApproachAngle( desiredAngles.x, currentAngles.x, 0.5 * approachRate * deltaT )
	angles.z = 0
	
	-- back out "punch angle"
	angles = angles - bot:GetViewPunchAngles()
	
	angles.x = math.AngleNormalize( angles.x )
	angles.y = math.AngleNormalize( angles.y )
	
	--print("Setting angles:", angles.x, angles.y, angles.z)
	bot:SetEyeAngles( angles )
	--local afterAngles = eyeAngles
	--print("Player angles after: ", afterAngles.x, afterAngles.y, afterAngles.z)

end

function TBotBodyMeta:Update()

	return
	
end

function TBotBodyMeta:AimHeadTowards( lookAtPos, priority, duration )
	duration = tonumber( duration ) or 0.0
	priority = tonumber( priority ) or TBotLookAtPriority.LOW_PRIORITY
	
	if isvector( lookAtPos ) then
	
		if duration <= 0.0 then
		
			duration = 0.1
			
		end
		
		if self.m_lookAtPriority == priority then
		
			if !self:IsHeadSteady() or self:GetHeadSteadyDuration() < 0.3 then
			
				return
				
			end
			
		end
		
		if self.m_lookAtPriority > priority and !self.m_lookAtExpireTimer:Elapsed() then
		
			return
			
		end
		
		self.m_lookAtExpireTimer:Start( duration )
		
		-- If given the same point, just update priority
		if ( self.m_lookAtPos - lookAtPos ):IsLengthLessThan( 1.0 ) then
		
			self.m_lookAtPriority = priority
			return
			
		end
		
		self.m_lookAtPos = lookAtPos
		self.m_lookAtSubject = nil
		self.m_lookAtDurationTimer:Start()
		self.m_lookAtPriority = priority
		self.m_hasBeenSightedIn = false
		
	elseif IsValid( lookAtPos ) and IsEntity( lookAtPos ) then
	
		if duration <= 0.0 then
		
			duration = 0.1
			
		end
	
		if self.m_lookAtPriority == priority then
	
			if !self:IsHeadSteady() or self:GetHeadSteadyDuration() < 0.3 then
			
				return
				
			end
			
		end
		
		if self.m_lookAtPriority > priority and !self.m_lookAtExpireTimer:Elapsed() then
		
			return
			
		end
		
		self.m_lookAtExpireTimer:Start( duration )
		
		-- If given the same subject, just update priority
		if lookAtPos == self.m_lookAtSubject then
		
			self.m_lookAtPriority = priority
			return
			
		end
		
		self.m_lookAtSubject = lookAtPos
		self.m_lookAtDurationTimer:Start()
		self.m_lookAtPriority = priority
		self.m_hasBeenSightedIn = false
	
	end
	
end

-- Depreciatied: Use AimHeadTowards
function TBotBodyMeta:AimAtPos( Subject, Time, Priority )

	self:AimHeadTowards( Subject, Priority, Time )

end

-- Depreciatied: Use AimHeadTowards
function TBotBodyMeta:AimAtEntity( Subject, Time, Priority )
	
	self:AimHeadTowards( Subject, Priority, Time )
	
end

function TBotBodyMeta:IsHeadAimingOnTarget()

	return self.m_isSightedIn
	
end

function TBotBodyMeta:IsHeadSteady()

	return self.m_headSteadyTimer:HasStarted()
	
end

function TBotBodyMeta:GetHeadSteadyDuration()

	if self.m_headSteadyTimer:HasStarted() then
	
		return self.m_headSteadyTimer:GetElapsedTime()
		
	end

	return 0.0
	
end

function TBotBodyMeta:GetHeadAimSubjectLeadTime()

	return 0.0
	
end

-- Returns how often we should sample our target's position and
-- velocity to update our aim tracking, to allow realistic slop in tracking
-- NOTE: This can be used to make bots have better or worse aim tracking
function TBotBodyMeta:GetHeadAimTrackingInterval()
	
	return 0.05 -- For now make the bots act like expert TF2 bots!
	
	-- This is an example of different levels of aim tracking
	-- I could also make this skill dependent....
	--[[if "Expert" then
	
		return 0.05
		
	elseif "Hard" then
	
		return 0.1
	
	elseif "Normal" then
	
		return 0.25
		
	elseif "Easy" then
	
		return 1.0
	
	end]]
	
end

-- NOTE: This can be used to make bots have different aim speeds
function TBotBodyMeta:GetMaxHeadAngularVelocity()

	return GetConVar( "TBotSaccadeSpeed" ):GetFloat()
	
end

-- Width of bot's collision hull in XY plane
function TBotBodyMeta:GetHullWidth()

	local bot = self:GetBot()
	local bottom, top = bot:GetHull()

	return ( top.x * bot:GetModelScale() ) - ( bottom.x * bot:GetModelScale() )
	
end

-- Height of bot's collision hull based on posture
function TBotBodyMeta:GetHullHeight()

	if self:GetBot():Crouching() then
	
		return self:GetCrouchHullHeight()
		
	end
	
	return self:GetStandHullHeight()
	
end

-- Height of bot's collision hull when standing
function TBotBodyMeta:GetStandHullHeight()

	local bot = self:GetBot()
	local bottom, top = bot:GetHull()
	
	return ( top.z * bot:GetModelScale() ) - ( bottom.z * bot:GetModelScale() )
	
end

-- Height of bot's collision hull when crouched
function TBotBodyMeta:GetCrouchHullHeight()

	local bot = self:GetBot()
	local bottom, top = bot:GetHullDuck()
	
	return ( top.z * bot:GetModelScale() ) - ( bottom.z * bot:GetModelScale() )
	
end