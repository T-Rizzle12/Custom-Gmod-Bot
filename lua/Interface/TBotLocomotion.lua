-- TBotLocomotion.lua
-- Purpose: This is the TBotLocomotion MetaTable
-- Author: T-Rizzle

TBotLadderState = {}
TBotLadderState.NO_LADDER						=	0
TBotLadderState.APPROACHING_ASCENDING_LADDER	=	1
TBotLadderState.APPROACHING_DESCENDING_LADDER	=	2
TBotLadderState.ASCENDING_LADDER				=	3
TBotLadderState.DESCENDING_LADDER				=	4
TBotLadderState.DISMOUNTING_LADDER_TOP			=	5
TBotLadderState.DISMOUNTING_LADDER_BOTTOM		=	6

local TBotLocomotionMeta = {}

TBotLocomotionMeta.__index = TBotLocomotionMeta

baseclass.Set( "TBotLocomotion", TBotLocomotionMeta ) -- Register this class so we can derive this for other gamemodes.

function TBotLocomotion( bot )
	local tbotlocomotion = {}

	-- NEEDTOVALIDATE: Do we need these?
	--tbotlocomotion.m_curInterval = engine.TickInterval()
	--tbotlocomotion.m_lastUpdateTime = 0
	tbotlocomotion.m_bot = bot
	tbotlocomotion.m_motionVector = Vector()
	tbotlocomotion.m_isStuck = false
	tbotlocomotion.m_stuckPos = Vector()
	tbotlocomotion.m_speed = 0.0
	tbotlocomotion.m_groundSpeed = 0.0
	tbotlocomotion.m_groundLocomotionVector = Vector()
	tbotlocomotion.m_isJumping = false
	tbotlocomotion.m_isClimbingUpToLedge = false
	tbotlocomotion.m_isJumpingAcrossGap = false
	tbotlocomotion.m_landingGoal = Vector()
	tbotlocomotion.m_hasLeftTheGround = false
	tbotlocomotion.m_jumpTimer = util.Timer()
	
	tbotlocomotion.m_ladderState = TBotLadderState.NO_LADDER
	tbotlocomotion.m_ladderInfo = nil
	tbotlocomotion.m_ladderDismountGoal = nil
	tbotlocomotion.m_ladderTimer = util.Timer()
	
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
	
	tbotlocomotion.m_stuckTimer = setmetatable( {}, intervalTimer )
	tbotlocomotion.m_moveRequestTimer = setmetatable( {}, intervalTimer )
	tbotlocomotion.m_stillTimer = setmetatable( {}, intervalTimer )
	tbotlocomotion.m_stillStuckTimer = util.Timer()

	setmetatable( tbotlocomotion, TBotLocomotionMeta )

	tbotlocomotion:Reset()

	return tbotlocomotion

end

function TBotLocomotionMeta:Reset()

	--self.m_curInterval = engine.TickInterval()
	--self.m_lastUpdateTime = 0
	self.m_isJumping = false
	self.m_isClimbingUpToLedge = false
	self.m_isJumpingAcrossGap = false
	self.m_hasLeftTheGround = false
	
	self.m_ladderState = TBotLadderState.NO_LADDER
	self.m_ladderInfo = nil
	self.m_ladderDismountGoal = nil
	self.m_ladderTimer:Reset()
	
	self.m_stillTimer:Invalidate()
	self.m_motionVector:Zero()
	self.m_motionVector.x = 1.0
	self.m_speed = 0.0
	self.m_groundSpeed = 0.0
	self.m_groundLocomotionVector:Zero()
	self.m_groundLocomotionVector.x = 1.0
	
	self.m_moveRequestTimer:Invalidate()
	self.m_isStuck = false
	self.m_stuckTimer:Invalidate()
	self.m_stuckPos:Zero()
	
end

function TBotLocomotionMeta:GetBot()

	return self.m_bot

end

function TBotLocomotionMeta:Upkeep()
	
	local bot			=	self:GetBot()
	local CanRun		=	!bot:InVehicle()
	local ShouldJump	=	false
	local ShouldCrouch	=	false
	local ShouldRun		=	false
	local ShouldWalk	=	false
	local botPath		=	bot:GetCurrentPath()
	
	local myArea = bot:GetLastKnownArea()
	if IsValid( myArea ) then -- If there is no nav_mesh this will not run to prevent the addon from spamming errors
		
		if bot:IsOnGround() and myArea:HasAttributes( NAV_MESH_JUMP ) then
			
			ShouldJump		=	true
			
		end
		
		if myArea:HasAttributes( NAV_MESH_CROUCH ) and ( !botPath.m_goal or botPath.m_goal.type == TBotSegmentType.PATH_ON_GROUND ) then
			
			ShouldCrouch	=	true
			
		end
		
		if myArea:HasAttributes( NAV_MESH_RUN ) then
			
			ShouldRun		=	true
			ShouldWalk		=	false
			
		end
		
		if myArea:HasAttributes( NAV_MESH_WALK ) then
			
			CanRun			=	false
			ShouldWalk		=	true
			
		end
		
		if myArea:HasAttributes( NAV_MESH_STAIRS ) then -- The bot shouldn't jump while on stairs
		
			ShouldJump		=	false
		
		end
		
	end
	
	-- Run if the navmesh tells us to
	if CanRun and bot:GetSuitPower() > 20 then 
		
		if ShouldRun then
		
			bot:PressRun( 0.1 )
			
		end
	
	end
	
	-- Walk if the navmesh tells us to
	if ShouldWalk then
		
		bot:PressWalk( 0.1 )
	
	end
	
	if ShouldJump and bot:IsOnGround() then 
	
		bot:PressJump( 0.1 )
		
	elseif ShouldCrouch or ( !bot:IsOnGround() and !self:IsUsingLadder() and bot:WaterLevel() < 2 ) then 
	
		bot:PressCrouch( 0.1 )
		
	end

end

function TBotLocomotionMeta:Update()

	local bot = self:GetBot()
	if !self:TraverseLadder() then
	
		if self.m_isJumpingAcrossGap or self.m_isClimbingUpToLedge then
		
			local toLanding = self.m_landingGoal - bot:GetPos()
			toLanding.z = 0.0
			toLanding:Normalize()
			
			if self.m_hasLeftTheGround then
				
				bot:GetTBotBody():AimHeadTowards( bot:GetShootPos() + 100 * toLanding, TBotLookAtPriority.MAXIMUM_PRIORITY, 0.25 )
				
				if bot:IsOnGround() then -- bot:WaterLevel() >= 2
					
					-- Back on the ground - jump is complete
					self.m_isClimbingUpToLedge = false
					self.m_isJumpingAcrossGap = false
					
				end
				
			else
				-- Haven't left the ground yet - just starting the jump
				if !self:IsClimbingOrJumping() then
					
					self:Jump()
					
				end
				
				--local vel = bot:GetVelocity()
				if self.m_isJumpingAcrossGap then
					
					bot:PressRun()
					-- NEEDTOVALIDATE: Should I add this?
					-- Cheat and max our velocity in case we stopped at the edge of this gap
					--vel.x = bot:GetRunSpeed() * toLanding.x
					--vel.y = bot:GetRunSpeed() * toLanding.y
					-- leave vel.z unchanged
					
				end
				
				if !bot:IsOnGround() then
					
					-- Jump has begun
					self.m_hasLeftTheGround = true
					
				end
				
			end
			
			self:Approach( self.m_landingGoal )
			
		end
		
	end

	self:StuckMonitor()
	
	local vel = bot:GetVelocity()
	self.m_speed = vel:Length()
	self.m_groundSpeed = vel:AsVector2D():Length()
	
	local velocityThreshold = 10.0
	if self.m_speed > velocityThreshold then
	
		self.m_motionVector = vel / self.m_speed
		
		self.m_stillTimer:Invalidate()
	
	else
	
		if !self.m_stillTimer:HasStarted() then
		
			self.m_stillTimer:Start()
			
		end
	
	end
	
	if self.m_groundSpeed > velocityThreshold then
	
		self.m_groundLocomotionVector.x = vel.x / self.m_groundSpeed
		self.m_groundLocomotionVector.y = vel.y / self.m_groundSpeed
		self.m_groundLocomotionVector.z = 0.0
		
	end
	
end

-- NEEDTOVALIDATE: Currently the bot will crouch for far away obstacles,
-- should I add a max range limiter?
function TBotLocomotionMeta:AdjustPosture( moveGoal )

	local bot = self:GetBot()
	local feet = bot:GetPos()
	local body = bot:GetTBotBody()
	local hullMin = bot:GetHull()
	hullMin.z = hullMin.z + bot:GetStepSize()
	
	local halfSize = body:GetHullWidth() / 2.0
	local standMaxs = Vector( halfSize, halfSize, body:GetStandHullHeight() )
	
	local moveDir = moveGoal - feet
	local moveLength = moveDir:Length()
	moveDir:Normalize()
	local left = Vector( -moveDir.y, moveDir.x, 0 )
	local goal = feet + moveLength * left:Cross( vector_up ):GetNormalized()
	
	local trace = {}
	util.TraceHull( { start = feet, endpos = goal, maxs = standMaxs, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = trace } )
	
	if trace.Fraction >= 1.0 and !trace.StartSolid then
	
		return
		
	end
	
	local crouchMaxs = Vector( halfSize, halfSize, body:GetCrouchHullHeight() )
	util.TraceHull( { start = feet, endpos = goal, maxs = crouchMaxs, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = trace } )
	
	if trace.Fraction >= 1.0 and !trace.StartSolid then
	
		bot:PressCrouch()
		
	end
	
end

function TBotLocomotionMeta:Approach( pos )

	local bot = self:GetBot()
	local body = bot:GetTBotBody()
	local botTable = bot:GetTable()
	self.m_moveRequestTimer:Start()
	
	self:AdjustPosture( pos )
	
	local forward = bot:EyeAngles():Forward()
	forward.z = 0.0
	forward:Normalize()
	
	local right = Vector( forward.y, -forward.x, 0 )
	
	local to = pos - bot:GetPos()
	to.z = 0.0
	to:Normalize()
	
	local ahead = to:Dot( forward )
	local side = to:Dot( right )
	
	if self:IsOnLadder() and self:IsUsingLadder() and ( self.m_ladderState == TBotLadderState.ASCENDING_LADDER or self.m_ladderState == TBotLadderState.DESCENDING_LADDER ) then
		
		bot:PressForward()
		
		if IsValid( self.m_ladderInfo ) then
			
			local posOnLadder = CalcClosestPointOnLine( bot:GetPos(), self.m_ladderInfo:GetBottom(), self.m_ladderInfo:GetTop() )
			local alongLadder = self.m_ladderInfo:GetTop() - self.m_ladderInfo:GetBottom()
			alongLadder:Normalize()
			local rightLadder = alongLadder:Cross( self.m_ladderInfo:GetNormal() )
			local away = bot:GetPos() - posOnLadder
			local Error = away:Dot( rightLadder )
			away:Normalize()
			
			--local tolerance = 5.0 + 0.25 * self:GetHullWidth()
			local tolerance = 0.25 * body:GetHullWidth()
			if math.abs( Error ) > tolerance then
			
				if away:Dot( rightLadder ) > 0.0 then
				
					bot:PressLeft()
					
				else
					
					bot:PressRight()
					
				end
				
			end
			
		end
		
	else
		
		if !bot:InVehicle() then
		
			if ahead > 0.25 then
				
				bot:PressForward()
				
			elseif ahead < -0.25 then
				
				bot:PressBack()
				
			end
			
			if side <= -0.25 then
				
				bot:PressLeft()
			
			elseif side >= 0.25 then
				
				bot:PressRight()
				
			end
			
		else
			
			local currentVehicle = bot:GetVehicle()
			if IsValid( currentVehicle ) then
				
				local currentAngles = currentVehicle:GetAngles()
				local turnPos = pos - currentVehicle:GetPos()
				turnPos.z = 0.0
				turnPos:Normalize()
				
				forward = currentVehicle:GetAngles():Forward()
				forward.z = 0.0
				forward:Normalize()
				
				right.x = forward.y
				right.y = -forward.x
				right.z = 0
				
				ahead = turnPos:Dot( forward )
				side = turnPos:Dot( right )
				
				if ahead < 0.05 then
				
					bot:PressForward()
				
				elseif ahead > -0.05 then
				
					bot:PressBack()
					side = -side
				
				end
				
				if 0.05 <= side then
					
					bot:PressLeft()
					
				elseif 0.05 >= side then
					
					bot:PressRight()
					
				end
				
			end
			
		end
		
	end
	
end

function TBotLocomotionMeta:IsClimbPossible( me, obstacle )

	local path = me:GetCurrentPath()
	if path then
	
		if !path:IsDiscontinuityAhead( me, TBotSegmentType.PATH_CLIMB_UP, 75 ) then
		
			-- Always allow climbing over moveable obstacles
			if IsValid( obstacle ) and !obstacle:IsWorld() then
			
				local physics = obstacle:GetPhysicsObject()
				if IsValid( physics ) and physics:IsMoveable() then
				
					-- Moveable physics object - climb over it
					return true
					
				end
				
			end
			
			if !self:IsStuck() then
			
				-- we're not stuck - don't try to jump up yet
				return false
				
			end
			
		end
		
	end
	
	return true
	
end

function TBotLocomotionMeta:ClimbUpToLedge( landingGoal, landingForward, obstacle )

	local bot = self:GetBot()
	if !self:IsClimbPossible( bot, obstacle ) then
	
		return false
		
	end
	
	self:Jump()
	
	self.m_isClimbingUpToLedge = true
	self.m_landingGoal = landingGoal
	self.m_hasLeftTheGround = false
	
	return true
	
end

function TBotLocomotionMeta:JumpAcrossGap( landingGoal, landingForward )

	local bot = self:GetBot()
	self:Jump()
	
	-- Face forward
	bot:GetTBotBody():AimHeadTowards( landingGoal, TBotLookAtPriority.HIGH_PRIORITY, 1.0 )
	
	self.m_isJumpingAcrossGap = true
	self.m_landingGoal = landingGoal
	self.m_hasLeftTheGround = false
	
end

function TBotLocomotionMeta:Jump()

	self.m_isJumping = true
	self.m_jumpTimer:Start( 0.5 )
	
	self:GetBot():PressJump()
	
end

function TBotLocomotionMeta:IsClimbingOrJumping()

	if !self.m_isJumping then
	
		return false
		
	end
	
	if self.m_jumpTimer:Elapsed() and self:GetBot():IsOnGround() then
	
		self.m_isJumping = false
		return false
		
	end
	
	return true

end

function TBotLocomotionMeta:IsClimbingUpToLedge()

	return self.m_isClimbingUpToLedge
	
end

function TBotLocomotionMeta:IsJumpingAcrossGap()

	return self.m_isJumpingAcrossGap
	
end

function TBotLocomotionMeta:ClimbLadder( ladder, dismountGoal )

	self.m_ladderState = TBotLadderState.APPROACHING_ASCENDING_LADDER
	self.m_ladderInfo = ladder
	self.m_ladderDismountGoal = dismountGoal
	
end

function TBotLocomotionMeta:DescendLadder( ladder, dismountGoal )

	self.m_ladderState = TBotLadderState.APPROACHING_DESCENDING_LADDER
	self.m_ladderInfo = ladder
	self.m_ladderDismountGoal = dismountGoal
	
end

function TBotLocomotionMeta:IsUsingLadder()

	return self.m_ladderState != TBotLadderState.NO_LADDER
	
end

function TBotLocomotionMeta:GetGroundNormal()

	return vector_up * 1 -- Vector( 0, 0, 1.0 )
	
end

function TBotLocomotionMeta:FaceTowards( target )

	if !isvector( target ) then
	
		return
		
	end
	
	-- TODO: Get the bot to look up and down while swiming
	local bot = self:GetBot()
	--[[local look = bot:GetShootPos()
	look.x = target.x
	look.y = target.y]]
	local look = bot:GetShootPos() * 1
	local targetHeight = bot:GetCurrentViewOffset().z
	local ground = navmesh.GetGroundHeight( target )
	
	look.x = target.x
	look.y = target.y
	
	if ground then
	
		look.z = ground + targetHeight
		
	end
	
	bot:GetTBotBody():AimHeadTowards( look, TBotLookAtPriority.LOW_PRIORITY, 0.1 )

end

function TBotLocomotionMeta:IsPotentiallyTraversable( from, to )

	if to.z - from.z > self:GetMaxJumpHeight() + 0.1 then
	
		local along = to - from
		along:Normalize()
		if along.z > 0.6 then
		
			return false, 0.0
			
		end
		
	end
	
	local bot = self:GetBot()
	local body = bot:GetTBotBody()
	local probeSize = 0.25 * body:GetHullWidth()
	local probeZ = bot:GetStepSize()
	
	local hullMin = Vector( -probeSize, -probeSize, probeZ )
	local hullMax = Vector( probeSize, probeSize, body:GetCrouchHullHeight() )
	
	local result = {}
	util.TraceHull( { start = from, endpos = to, maxs = hullMax, mins = hullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )

	return result.Fraction >= 1.0 and !result.StartSolid, result.Fraction
	
end

function TBotLocomotionMeta:IsGap( pos, forward )

	local halfWidth = 1.0
	local hullHeight = 1.0
	
	local ground = {}
	util.TraceHull( { start = pos + Vector( 0, 0, self:GetBot():GetStepSize() ), endpos = pos + Vector( 0, 0, -self:GetMaxJumpHeight() ), maxs = Vector( halfWidth, halfWidth, hullHeight ), mins = Vector( -halfWidth, -halfWidth, 0 ), filter = TBotTraceFilter, mask = MASK_PLAYERSOLID, output = ground } )
	
	--debugoverlay.SweptBox( pos + Vector( 0, 0, self:GetStepSize() ), pos + Vector( 0, 0, -self:GetMaxJumpHeight() ), Vector( -halfWidth, -halfWidth, 0 ), Vector( halfWidth, halfWidth, hullHeight ), Angle(), 5.0, Color( 255, 0, 0 ) )
	
	return ground.Fraction >= 1.0 and !ground.StartSolid
	
end

function TBotLocomotionMeta:HasPotentialGap( from, desiredTo )

	local _, traversableFraction = self:IsPotentiallyTraversable( from, desiredTo )
	
	local to = from + ( desiredTo - from ) * traversableFraction
	
	local forward = to - from
	local length = forward:Length()
	forward:Normalize()
	
	local body = self:GetBot():GetTBotBody()
	local step = body:GetHullWidth() / 2.0
	local pos = Vector( from )
	local delta = step * forward
	local t = 0.0
	while t < length + step do
		
		if self:IsGap( pos, forward ) then
		
			return true
			
		end
		
		t = t + step
		pos = pos + delta
		
	end
	
	return false
	
end

-- TODO: Move this code into the Main Action!!!!
function TBotLocomotionMeta:OnStuck()

	local bot = self:GetBot()
	hook.Run( "TBotOnStuck", bot ) -- We call a hook so that the Action system can respond to these events as well!
	bot:PressJump()
	
	if math.random( 0, 100 ) < 50 then
	
		bot:PressLeft()
		
	else
	
		bot:PressRight()
		
	end
	
end

function TBotLocomotionMeta:OnUnStuck()

	hook.Run( "TBotOnUnStuck", self:GetBot() ) -- We call a hook so that the Action system can respond to these events as well!
	return

end

function TBotLocomotionMeta:ClearStuckStatus()

	if self:IsStuck() then
	
		self.m_isStuck = false
		
		self:OnUnStuck()
		
	end

	self.m_stuckPos = self:GetBot():GetPos()
	self.m_stuckTimer:Start()
	
end

function TBotLocomotionMeta:StuckMonitor()

	-- a timer is needed to smooth over a few frames of inactivity due to state changes, etc.
	-- we only want to detect idle situations when the bot really doesn't "want" to move.
	local bot = self:GetBot()
	local botTable = bot:GetTable()
	if self.m_moveRequestTimer:IsGreaterThen( 0.25 ) then
	
		self.m_stuckPos = bot:GetPos()
		self.m_stuckTimer:Start()
		return
		
	end
	
	-- We are not stuck if we are frozen!
	if bot:IsFrozen() then
	
		self:ClearStuckStatus()
		return
		
	end
	
	if self:IsStuck() then
	
		-- we are/were stuck - have we moved enough to consider ourselves "dislodged"
		if ( self.m_stuckPos - bot:GetPos() ):IsLengthGreaterThan( 100 ) then
		
			self:ClearStuckStatus()
			
		else
		
			-- still stuck - periodically resend the event
			if self.m_stillStuckTimer:Elapsed() then
			
				self.m_stillStuckTimer:Start( 1.0 )
				
				self:OnStuck()
				
			end
			
		end
		
		-- We have been stuck for too long, destroy the current path
		-- and the bot's current hiding spot.
		if self.m_stuckTimer:IsGreaterThen( 10.0 ) then
		
			-- NEEDTOVALIDATE: Should this be somewhere else?
			local path = bot:GetCurrentPath()
			if path and path:GetAge() > 0.0 then
			
				path:Invalidate()
				
			end
			
			self:ClearStuckStatus()
			
		end
		
	else
	
		-- we're not stuck - yet
	
		if ( self.m_stuckPos - bot:GetPos() ):IsLengthGreaterThan( 100 ) then
		
			-- we have moved - reset anchor
			self.m_stuckPos = bot:GetPos()
			self.m_stuckTimer:Start()
			
		else
		
			-- within stuck range of anchor. if we've been here too long, we're stuck
			local minMoveSpeed = 0.1 * bot:GetDesiredSpeed() + 0.1
			local escapeTime = 100 / minMoveSpeed
			if self.m_stuckTimer:IsGreaterThen( escapeTime ) then
			
				-- we have taken too long - we're stuck
				self.m_isStuck = true
				
				self:OnStuck()
				
			end
			
		end
	
	end
	
end

function TBotLocomotionMeta:IsNotMoving( minDuration )

	if !self.m_stillTimer:HasStarted() then
	
		return false
		
	end

	return self.m_stillTimer:IsGreaterThen( minDuration )
	
end

function TBotLocomotionMeta:GetGroundSpeed()

	return self.m_groundSpeed
	
end

function TBotLocomotionMeta:GetGroundMotionVector()

	return self.m_groundLocomotionVector
	
end

function TBotLocomotionMeta:GetSpeed()

	return self.m_speed
	
end

function TBotLocomotionMeta:GetMotionVector()

	return self.m_motionVector
	
end

function TBotLocomotionMeta:GetTraversableSlopeLimit()

	return 0.6
	
end

function TBotLocomotionMeta:IsStuck()

	return self.m_isStuck
	
end

function TBotLocomotionMeta:GetStuckDuration()

	if self:IsStuck() then
	
		return self.m_stuckTimer:GetElapsedTime()
		
	end
	
	return 0.0
	
end

-- TODO: I should really make this dynamic?
-- Would this function work?
-- I would also have to make it account for the hl2 jump boost in game....
--[[function GetJumpHeight(ply)
    local g = GetConVar("sv_gravity"):GetFloat() * ply:GetGravity()
    local j = ply:GetJumpPower()

    j = j - g * 0.5 * engine.TickInterval() --source moment ¯\_(ツ)_/¯
    
    return math.Round(j * j / 2 / g / engine.TickInterval()) * engine.TickInterval() --clamp to tick rate
end]]
function TBotLocomotionMeta:GetMaxJumpHeight()

	return 64
	
end

function TBotLocomotionMeta:IsOnLadder()
	
	local bot = self:GetBot()
	return bot:GetMoveType() == MOVETYPE_LADDER

end

function TBotLocomotionMeta:TraverseLadder()
	
	local bot = self:GetBot()
	if self.m_ladderState == TBotLadderState.APPROACHING_ASCENDING_LADDER then
	
		self.m_ladderState = self:ApproachAscendingLadder()
		return true
		
	elseif self.m_ladderState == TBotLadderState.APPROACHING_DESCENDING_LADDER then
	
		self.m_ladderState = self:ApproachDescendingLadder()
		return true
	
	elseif self.m_ladderState == TBotLadderState.ASCENDING_LADDER then
	
		self.m_ladderState = self:AscendLadder()
		return true
	
	elseif self.m_ladderState == TBotLadderState.DESCENDING_LADDER then
	
		self.m_ladderState = self:DescendLadder()
		return true
	
	elseif self.m_ladderState == TBotLadderState.DISMOUNTING_LADDER_TOP then
	
		self.m_ladderState = self:DismountLadderTop()
		return true
	
	elseif self.m_ladderState == TBotLadderState.DISMOUNTING_LADDER_BOTTOM then
	
		self.m_ladderState = self:DismountLadderBottom()
		return true
	
	else
	
		self.m_ladderInfo = nil
		
		if self:IsOnLadder() then
		
			-- on ladder and don't want to be
			bot:PressJump()
			
		end
		
		return false
		
	end
	
	return true

end

function TBotLocomotionMeta:ApproachAscendingLadder()

	local bot = self:GetBot()
	if !IsValid( self.m_ladderInfo ) then
	
		return TBotLadderState.NO_LADDER
		
	end
	
	if bot:GetPos().z >= self.m_ladderInfo:GetTop().z - bot:GetStepSize() then
	
		self.m_ladderTimer:Start( 2.0 )
		return TBotLadderState.DISMOUNTING_LADDER_TOP
		
	end
	
	if bot:GetPos().z <= self.m_ladderInfo:GetBottom().z - self:GetMaxJumpHeight() then
	
		return TBotLadderState.NO_LADDER
		
	end
	
	self:FaceTowards( self.m_ladderInfo:GetBottom() )
	
	self:Approach( self.m_ladderInfo:GetBottom() )
	
	if self:IsOnLadder() then
	
		return TBotLadderState.ASCENDING_LADDER
		
	end
	
	return TBotLadderState.APPROACHING_ASCENDING_LADDER
	
end

function TBotLocomotionMeta:ApproachDescendingLadder()

	local bot = self:GetBot()
	if !IsValid( self.m_ladderInfo ) then
	
		return TBotLadderState.NO_LADDER
		
	end
	
	if bot:GetPos().z <= self.m_ladderInfo:GetBottom().z + self:GetMaxJumpHeight() then
	
		self.m_ladderTimer:Start( 2.0 )
		return TBotLadderState.DISMOUNTING_LADDER_BOTTOM
		
	end
	
	local mountPoint = self.m_ladderInfo:GetTop() + 0.25 * self:GetHullWidth() * self.m_ladderInfo:GetNormal()
	local to = mountPoint - bot:GetPos()
	to.z = 0.0
	
	local mountRange = to:Length()
	to:Normalize()
	local moveGoal = nil
	
	if mountRange < 10.0 then
	
		moveGoal = bot:GetPos() + 100 * self:GetMotionVector()
		
	else
	
		if to:Dot( self.m_ladderInfo:GetNormal() ) < 0.0 then
		
			moveGoal = self.m_ladderInfo:GetTop() - 100 * self.m_ladderInfo:GetNormal()
			
		else
		
			moveGoal = self.m_ladderInfo:GetTop() + 100 * self.m_ladderInfo:GetNormal()
			
		end
	
	end
	
	self:FaceTowards( moveGoal )
	
	self:Approach( moveGoal )
	
	if self:IsOnLadder() then
	
		return TBotLadderState.DESCENDING_LADDER
		
	end
	
	return TBotLadderState.APPROACHING_DESCENDING_LADDER
	
end	

function TBotLocomotionMeta:AscendLadder()

	local bot = self:GetBot()
	if !IsValid( self.m_ladderInfo ) then
	
		return TBotLadderState.NO_LADDER
		
	end
	
	if !self:IsOnLadder() then
	
		self.m_ladderInfo = nil
		return TBotLadderState.NO_LADDER
		
	end
	
	if self.m_ladderDismountGoal:HasAttributes( NAV_MESH_CROUCH ) then
	
		bot:PressCrouch()
		
	end
	
	if bot:GetPos().z >= self.m_ladderInfo:GetTop().z then
	
		self.m_ladderTimer:Start( 2.0 )
		return TBotLadderState.DISMOUNTING_LADDER_TOP
		
	end
	
	local goal = bot:GetPos() + 100 * ( -self.m_ladderInfo:GetNormal() + Vector( 0, 0, 2 ) )
	
	bot:GetTBotBody():AimHeadTowards( goal, TBotLookAtPriority.MAXIMUM_PRIORITY, 0.1 )
	
	self:Approach( goal )
	
	return TBotLadderState.ASCENDING_LADDER
	
end

function TBotLocomotionMeta:DescendLadder()

	local bot = self:GetBot()
	if !IsValid( self.m_ladderInfo ) then
	
		return TBotLadderState.NO_LADDER
		
	end
	
	if !self:IsOnLadder() then
	
		self.m_ladderInfo = nil
		return TBotLadderState.NO_LADDER
		
	end
	
	if bot:GetPos().z <= self.m_ladderInfo:GetBottom().z + bot:GetStepSize() then
	
		self.m_ladderTimer:Start( 2.0 )
		return TBotLadderState.DISMOUNTING_LADDER_BOTTOM
		
	end
	
	local goal = bot:GetPos() + 100 * ( self.m_ladderInfo:GetNormal() + Vector( 0, 0, -2 ) )
	
	bot:GetTBotBody():AimHeadTowards( goal, TBotLookAtPriority.MAXIMUM_PRIORITY, 0.1 )
	
	self:Approach( goal )
	
	return TBotLadderState.DESCENDING_LADDER
	
end

function TBotLocomotionMeta:DismountLadderTop()

	local bot = self:GetBot()
	if !IsValid( self.m_ladderInfo ) or self.m_ladderTimer:Elapsed() then
	
		self.m_ladderInfo = nil
		return TBotLadderState.NO_LADDER
		
	end
	
	local toGoal = self.m_ladderDismountGoal:GetCenter() - bot:GetPos()
	toGoal.z = 0.0
	local range = toGoal:Length()
	toGoal:Normalize()
	toGoal.z = 1.0
	
	bot:GetTBotBody():AimHeadTowards( bot:GetShootPos() + 100 * toGoal, TBotLookAtPriority.MAXIMUM_PRIORITY, 0.1 )
	
	self:Approach( bot:GetPos() + 100 * toGoal )
	
	if self.m_ladderDismountGoal == self.m_ladderInfo:GetTopBehindArea() and self:IsOnLadder() then
		
		bot:PressJump()
		
	elseif bot:GetLastKnownArea() == self.m_ladderDismountGoal and range < 10.0 then
	
		self.m_ladderInfo = nil
		return TBotLadderState.NO_LADDER
		
	end
	
	return TBotLadderState.DISMOUNTING_LADDER_TOP
	
end

function TBotLocomotionMeta:DismountLadderBottom()

	local bot = self:GetBot()
	if !IsValid( self.m_ladderInfo ) or self.m_ladderTimer:Elapsed() then
	
		self.m_ladderInfo = nil
		return TBotLadderState.NO_LADDER
		
	end
	
	if self:IsOnLadder() then
	
		bot:PressJump()
		self.m_ladderInfo = nil
		
	end
	
	return TBotLadderState.NO_LADDER
	
end

function TBotLocomotionMeta:IsAscendingOrDescendingLadder()

	if self.m_ladderState == TBotLadderState.ASCENDING_LADDER then
	
		return true
		
	elseif self.m_ladderState == TBotLadderState.DESCENDING_LADDER then
	
		return true
		
	elseif self.m_ladderState == TBotLadderState.DISMOUNTING_LADDER_TOP then
	
		return true
		
	elseif self.m_ladderState == TBotLadderState.DISMOUNTING_LADDER_BOTTOM then
	
		return true
		
	end
	
	return false
	
end