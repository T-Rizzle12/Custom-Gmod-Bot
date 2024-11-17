-- TBotPathFollower.lua
-- Purpose: This is the TBotPathFollower MetaTable
-- Author: T-Rizzle

local BaseClass = FindMetaTable( "TBotPath" )

local TBotPathFollowerMeta = {}

function TBotPathFollowerMeta:__index( key )

	-- Search the metatable.
	local val = TBotPathFollowerMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

RegisterMetaTable( "TBotPathFollower", TBotPathFollowerMeta ) -- Register this class so other versions of the pathfinder can use it.

function TBotPathFollower()
	local tbotpathfollower = TBotPath() -- HACKHACK: We have to create a path object in order for it to have the stuff intialized....
	
	tbotpathfollower.m_goal = nil
	tbotpathfollower.m_avoidTimer = util.Timer()
	tbotpathfollower.m_avoidTimer:Reset()
	
	setmetatable( tbotpathfollower, TBotPathFollowerMeta )
	
	return tbotpathfollower

end

function TBotPathFollowerMeta:Invalidate()

	-- Extend
	BaseClass.Invalidate( self )
	
	self.m_goal = nil
	self.m_avoidTimer:Reset()
	
end

function TBotPathFollowerMeta:OnPathChanged( bot, result )

	self.m_goal = self:FirstSegment()

end

function TBotPathFollowerMeta:IsAtGoal( bot )

	local current		=	self:PriorSegment( self.m_goal )
	local toGoal		=	self.m_goal.pos - bot:GetPos()
	local mover			=	bot:GetTBotLocomotion()
	local body			=	bot:GetTBotBody()
	-- ALWAYS: Use 2D navigation, It helps by a large amount.
	
	if !current then
	
		-- passed goal
		return true
	
	elseif self.m_goal.type == TBotSegmentType.PATH_DROP_DOWN then
		
		local landing = self:NextSegment( self.m_goal )
		
		if !landing then
		
			-- passed goal or corrupt path
			return true
		
		-- did we reach the ground
		elseif bot:GetPos().z - landing.pos.z < bot:GetStepSize() then
			
			-- reached goal
			return true
			
		end
		
	elseif self.m_goal.type == TBotSegmentType.PATH_CLIMB_UP then
		
		local landing = self:NextSegment( self.m_goal )
		
		if !landing then
		
			-- passed goal or corrupt path
			return true
		
		elseif bot:GetPos().z > self.m_goal.pos.z + bot:GetStepSize() then
		
			return true
			
		end
	
	elseif self.m_goal.type == TBotSegmentType.PATH_USE_PORTAL then
	
		local destination = self.m_goal.destination
		
		if !IsValid( destination ) then
		
			-- passed goal or corrupt path
			return true
			
		elseif ( destination:GetPos() - bot:GetPos() ):AsVector2D():IsLengthLessThan( GetConVar( "TBotGoalTolerance" ):GetFloat() ) then
		
			return true
			
		end
	
	else
		
		local nextSegment = self:NextSegment( self.m_goal )
		
		if nextSegment then
		
			-- because the bot may be off the path, check if it crossed the plane of the goal
			-- check against average of current and next forward vectors
			local dividingPlane = nil
			
			if current.ladder then
			
				dividingPlane = self.m_goal.forward:AsVector2D()
				
			else
			
				dividingPlane = current.forward:AsVector2D() + self.m_goal.forward:AsVector2D()
			
			end
			
			if toGoal:AsVector2D():Dot( dividingPlane ) < 0.0001 and math.abs( toGoal.z ) < body:GetStandHullHeight() then
			
				if toGoal.z < bot:GetStepSize() and ( mover:IsPotentiallyTraversable( bot:GetPos(), nextSegment.pos ) and !mover:HasPotentialGap( bot:GetPos(), nextSegment.pos ) ) then
				
					return true
					
				end
				
			end
			
		end
		
		if toGoal:AsVector2D():IsLengthLessThan( GetConVar( "TBotGoalTolerance" ):GetFloat() ) then
		
			-- Reached goal
			return true
		
		end
		
	end
	
	return false
	
end

function TBotPathFollowerMeta:LadderUpdate( bot )

	local mover = bot:GetTBotLocomotion()
	local body = bot:GetTBotBody()
	if mover:IsUsingLadder() then
	
		return true
		
	end
	
	local GO_LADDER_DOWN = 5
	if !IsValid( self.m_goal.ladder ) then
	
		if mover:IsOnLadder() then
		
			local current = self:PriorSegment( self.m_goal )
			if !current then
			
				return false
				
			end
			
			local s = current
			while s do
			
				if s != current and ( s.pos - bot:GetPos() ):AsVector2D():IsLengthGreaterThan( 50 ) then
				
					break
					
				end
				
				if IsValid( s.ladder ) and s.how == GO_LADDER_DOWN and s.ladder:GetLength() > mover:GetMaxJumpHeight() then
				
					local destinationHeightDelta = s.pos.z - bot:GetPos().z
					if math.abs( destinationHeightDelta ) < mover:GetMaxJumpHeight() then
					
						self.m_goal = s
						break
						
					end
					
				end
				
				s = self:NextSegment( s )
				
			end
			
		end
	
		if !IsValid( self.m_goal.ladder ) then
		
			return false
		
		end
		
	end
	
	local GO_LADDER_UP = 4
	local mountRange = 25
	
	if self.m_goal.how == GO_LADDER_UP then
	
		if !mover:IsUsingLadder() and bot:GetPos().z > self.m_goal.ladder:GetTop().z - bot:GetStepSize() then
		
			self.m_goal = self:NextSegment( self.m_goal )
			return false
			
		end
		
		local to = ( self.m_goal.ladder:GetBottom() - bot:GetPos() ):AsVector2D()
		
		body:AimHeadTowards( self.m_goal.ladder:GetTop() - 50 * self.m_goal.ladder:GetNormal() + Vector( 0, 0, body:GetCrouchHullHeight() ), 2.0, TBotLookAtPriority.MAXIMUM_PRIORITY )
		
		local range = to:Length()
		to:Normalize()
		if range < 50 then
		
			local ladderNormal2D = self.m_goal.ladder:GetNormal():AsVector2D()
			local dot = ladderNormal2D:Dot( to )
			
			-- This was -0.9, but it caused issues with slanted ladders.
			-- -0.6 seems to fix this, but I don't know if any errors may occur from this change!
			if dot < -0.6 then
			
				mover:Approach( self.m_goal.ladder:GetBottom() )
			
				if range < mountRange then
				
					mover:ClimbLadder( self.m_goal.ladder, self.m_goal.area )
					
				end
				
			else
			
				local myPerp = Vector( -to.y, to.x, 0 )
				local ladderPerp2D = Vector( -ladderNormal2D.y, ladderNormal2D.x )
				
				local goal = self.m_goal.ladder:GetBottom()
				local alignRange = 50
				
				if dot < 0.0 then
				
					alignRange = mountRange + ( 1.0 + dot ) * ( alignRange - mountRange )
					
				end
				
				goal.x = goal.x - alignRange * to.x
				goal.y = goal.y - alignRange * to.y
				
				if to:Dot( ladderPerp2D ) < 0.0 then
				
					goal = goal + 10 * myPerp
					
				else
				
					goal = goal - 10 * myPerp
					
				end
				
				mover:Approach( goal )
				
			end
			
			
		else
		
			return false
			
		end
		
	else
	
		if bot:GetPos().z < self.m_goal.ladder:GetBottom().z + bot:GetStepSize() then
		
			self.m_goal = self:NextSegment( self.m_goal )
			
		else
		
			local mountPoint = self.m_goal.ladder:GetTop() + 0.5 * body:GetHullWidth() * self.m_goal.ladder:GetNormal()
			local to = ( mountPoint - bot:GetPos() ):AsVector2D()
			
			body:AimHeadTowards( self.m_goal.ladder:GetBottom() + 50 * self.m_goal.ladder:GetNormal() + Vector( 0, 0, body:GetCrouchHullHeight() ), 1.0, TBotLookAtPriority.MAXIMUM_PRIORITY )
			
			local range = to:Length()
			to:Normalize()
			
			if range < mountRange or mover:IsOnLadder() then
			
				mover:DescendLadder( self.m_goal.ladder, self.m_goal.area )
				
				self.m_goal = self:NextSegment( self.m_goal )
			
			else
			
				return false
				
			end
			
		end
		
	end
	
	return true
	
end

function TBotPathFollowerMeta:CheckProgress( bot )

	-- skip nearby goal points that are redundant to smooth path following motion
	local pSkipToGoal = nil
	local mover = bot:GetTBotLocomotion()
	if GetConVar( "TBotLookAheadRange" ):GetFloat() > 0 then
	
		pSkipToGoal = self.m_goal
		local myFeet = bot:GetPos()
		while pSkipToGoal and pSkipToGoal.type == TBotSegmentType.PATH_ON_GROUND and bot:IsOnGround() do
		
			if ( pSkipToGoal.pos - myFeet ):IsLengthLessThan( GetConVar( "TBotLookAheadRange" ):GetFloat() ) then
			
				-- goal is too close - step to next segment
				local nextSegment = self:NextSegment( pSkipToGoal )
				
				if !nextSegment or nextSegment.type != TBotSegmentType.PATH_ON_GROUND then
					
					-- can't skip ahead to next segment - head towards current goal
					break
					
				end
				
				if IsValid( nextSegment.area ) and nextSegment.area:HasAttributes( NAV_MESH_PRECISE ) then
				
					-- We are being told to be precise here, so don't skip ahead here
					break
					
				end
				
				if nextSegment.pos.z > myFeet.z + bot:GetStepSize() then
				
					-- going uphill or up stairs tends to cause problems if we skip ahead, so don't
					break
					
				end
				
				--[[if self:GetMotionVector():Dot( nextSegment[ "Forward" ] ) <= 0.1 then
					
					-- don't skip sharp turns
					print( self:GetMotionVector():Dot( nextSegment[ "Forward" ] ) )
					
					break
					
				end]]
				
				--print( "IsPotentiallyTraversable: " .. tostring( self:IsPotentiallyTraversable( myFeet, nextSegment[ "Pos" ] ) ) )
				--print( "HasPotentialGap: " .. tostring( !self:HasPotentialGap( myFeet, nextSegment[ "Pos" ] ) ) )
				
				-- can we reach the next path segment directly
				if mover:IsPotentiallyTraversable( myFeet, nextSegment.pos ) and !mover:HasPotentialGap( myFeet, nextSegment.pos ) then
				
					pSkipToGoal = nextSegment
					
					--print( pSkipToGoal )
					
				else
					
					-- can't directly reach next segment - keep heading towards current goal
					break
					
				end
				
			else
			
				-- goal is farther than min lookahead
				break
				
			end
			
		end
		
		-- didn't find any goal to skip to
		if pSkipToGoal == self.m_goal then
		
			pSkipToGoal = nil
			
		end
		
	end
	
	if self:IsAtGoal( bot ) then
	
		local nextSegment = Either( istable( pSkipToGoal ), pSkipToGoal, self:NextSegment( self.m_goal ) )
	
		if !nextSegment then
			
			if bot:IsOnGround() and self:GetAge() > 0.0 then
			
				self:Invalidate()
				
			end
			
			return false
			
		else
		
			self.m_goal = nextSegment
		
		end
		
	end
	
	return true
	
end

-- Make the bot move.
function TBotPathFollowerMeta:Update( bot )
	
	bot:SetCurrentPath( self )
	
	local mover = bot:GetTBotLocomotion()
	if !self:IsValid() or !istable( self.m_goal ) then
		
		return
		
	end
	
	if self:LadderUpdate( bot ) then
	
		-- we are traversing a ladder
		return
		
	end
	
	if self:CheckProgress( bot ) == false then
		
		-- goal reached
		return
		
	end
	
	local forward = self.m_goal.pos - bot:GetPos()
	
	if self.m_goal.type == TBotSegmentType.PATH_CLIMB_UP then
		
		local nextSegment = self:NextSegment( self.m_goal )
		if nextSegment then
			
			forward = nextSegment.pos - bot:GetPos()
			
		end
		
	end
	
	forward.z = 0.0
	local goalRange = forward:Length()
	forward:Normalize()
	
	local left = Vector( -forward.y, forward.x, 0 )
	
	if left:IsZero() then
		
		-- If left is zero, forward must also be - path follow failure
		if self:GetAge() > 0.0 then
		
			self:Invalidate()
			
		end
		
		return
		
	end
	
	local normal = mover:GetGroundNormal()
	
	forward = left:Cross( normal )
	
	left = normal:Cross( forward )
	
	-- Climb up ledges
	if !self:Climbing( bot, self.m_goal, forward, left, goalRange ) then
		
		-- A failed climb could mean an invalid path
		if !self:IsValid() then
			
			return
			
		end
		
		self:JumpOverGaps( bot, self.m_goal, forward, left, goalRange )
		
	end
	
	-- Event callbacks from the above climbs and jumps may invalidate the path
	if !self:IsValid() then
		
		return
		
	end
	
	self:DoorCheck( bot )
	self:BreakableCheck( bot )
	
	-- If our movement goal is high above us, we must have fallen
	local myArea = bot:GetLastKnownArea()
	local isOnStairs = IsValid( myArea ) and myArea:HasAttributes( NAV_MESH_STAIRS ) or false
	local isUnderwater = IsValid( myArea ) and myArea:IsUnderwater() or false
	
	-- Limit too high distance to reasonable value for bots that can climb very high
	local tooHighDistance = mover:GetMaxJumpHeight()
	
	if !IsValid( self.m_goal.ladder ) and !IsValid( self.m_goal.portal ) and !mover:IsClimbingOrJumping() and !isOnStairs and !isUnderwater and self.m_goal.pos.z > bot:GetPos().z + tooHighDistance then
	
		local closeRange = 25.0
		local to = Vector( bot:GetPos().x - self.m_goal.pos.x, bot:GetPos().y - self.m_goal.pos.y )
		if mover:IsStuck() or to:IsLengthLessThan( closeRange ) then
		
			-- the goal is too high to reach
			
			-- check if we can reach the next segment, in case this was a "jump down" situation
			local nextSegment = self:NextSegment( self.m_goal )
			if mover:IsStuck() or !istable( nextSegment ) or ( nextSegment.pos.z - bot:GetPos().z > tooHighDistance ) or !mover:IsPotentiallyTraversable( bot:GetPos(), nextSegment.pos ) then
			
				if self:GetAge() > 0.0 then
				
					self:Invalidate()
					
				end
				
				mover:ClearStuckStatus()
				
				return
				
			end
			
		end
	
	end
	
	local goalPos = Vector( self.m_goal.pos )
	forward = goalPos - bot:GetPos()
	forward.z = 0.0
	local rangeToGoal = forward:Length()
	forward:Normalize()
	
	left.x = -forward.y
	left.y = forward.x
	left.z = 0.0
	
	if rangeToGoal > 50 or ( istable( self.m_goal ) and self.m_goal.type != TBotSegmentType.PATH_CLIMB_UP ) then
		
		goalPos = self:Avoid( bot, goalPos, forward, left )
		
	end
	
	if bot:IsOnGround() then
		
		mover:FaceTowards( goalPos )
		
	end
	
	local CurrentArea = self.m_goal.area
	if IsValid( CurrentArea ) then
		
		if !CurrentArea:HasAttributes( NAV_MESH_STAIRS ) and CurrentArea:HasAttributes( NAV_MESH_JUMP ) then
			
			bot:PressJump()
			
		elseif CurrentArea:HasAttributes( NAV_MESH_CROUCH ) and CurrentArea:GetClosestPointOnArea( bot:GetPos() ):DistToSqr( bot:GetPos() ) <= 2500 then
			
			bot:PressCrouch()
			
		end
		
		if CurrentArea:HasAttributes( NAV_MESH_WALK ) then
			
			bot:PressWalk()
			
		elseif CurrentArea:HasAttributes( NAV_MESH_RUN ) then
			
			bot:PressRun()
			
		end
		
	end
	
	mover:Approach( goalPos )
	self:Draw()
	
	-- Currently, Approach determines STAND or CROUCH. 
	-- Override this if we're approaching a climb or a jump
	if istable( self.m_goal ) and ( self.m_goal.type == TBotSegmentType.PATH_CLIMB_UP or self.m_goal.type == TBotSegmentType.PATH_JUMP_OVER_GAP ) then
		
		bot:ReleaseCrouch()
		
	end
	
end

function TBotPathFollowerMeta:DoorCheck( bot )
	if !self:IsValid() then return end

	-- I will adjust this if any issues occur from it.
	local body = bot:GetTBotBody()
	local halfWidth = body:GetHullWidth() / 2.0
	local botPos = bot:GetPos()
	local botTable = bot:GetTable()
	for k, door in ipairs( ents.FindAlongRay( botPos, self.m_goal.pos, Vector( -halfWidth, -halfWidth, -halfWidth ), Vector( halfWidth, halfWidth, body:GetStandHullHeight() / 2.0 ) ) ) do
	
		if IsValid( door ) and door:IsDoor() and !door:IsDoorLocked() and !door:IsDoorOpen() and door:NearestPoint( botPos ):DistToSqr( botPos ) <= 100^2 then
		
			body:AimHeadTowards( door:WorldSpaceCenter(), TBotLookAtPriority.MAXIMUM_PRIORITY, 0.5 )
	
			if CurTime() >= botTable.UseInterval and bot:IsLookingAtPosition( door:WorldSpaceCenter() ) then
				
				bot:PressUse()
				botTable.UseInterval = CurTime() + 0.5
				
			end
			
			break
			
		end
		
	end
	
end

function TBotPathFollowerMeta:BreakableCheck( bot )
	if !self:IsValid() then return end

	-- This could be unreliable in certain situations
	-- Used to use ents.FindInSphere( self:GetPos(), 30 )
	local body = bot:GetTBotBody()
	local halfWidth = body:GetHullWidth() / 2.0
	local botPos = bot:GetPos()
	local botTable = bot:GetTable()
	for k, breakable in ipairs( ents.FindAlongRay( botPos, self.m_goal.pos, Vector( -halfWidth, -halfWidth, -halfWidth ), Vector( halfWidth, halfWidth, body:GetStandHullHeight() / 2.0 ) ) ) do
	
		if IsValid( breakable ) and breakable:IsBreakable() and breakable:NearestPoint( botPos ):DistToSqr( botPos ) <= 80^2 and bot:IsAbleToSee( breakable ) then 
		
			body:AimHeadTowards( breakable:WorldSpaceCenter(), TBotLookAtPriority.MAXIMUM_PRIORITY, 0.5 )
	
			if bot:IsLookingAtPosition( breakable:WorldSpaceCenter() ) then
				
				local botWeapon = botTable.BestWeapon
				if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() and botWeapon:GetClass() != "weapon_medkit" then
					
					if GetTBotRegisteredWeapon( botWeapon:GetClass() ).WeaponType == "Melee" then
						
						local rangeToShoot = bot:GetShootPos():DistToSqr( breakable:WorldSpaceCenter() )
						local rangeToStand = bot:GetPos():DistToSqr( breakable:WorldSpaceCenter() )
						
						-- If the breakable is on the ground and we are using a melee weapon
						-- we have to crouch in order to hit it
						if rangeToShoot <= 4900 and rangeToShoot > rangeToStand then
							
							bot:PressCrouch()
							
						end
						
					end
					
					if botWeapon:IsPrimaryClipEmpty() then
						
						if CurTime() >= botTable.ReloadInterval and !bot:IsReloading() then
						
							bot:PressReload()
							botTable.ReloadInterval = CurTime() + 0.5
							
						end
						
					elseif CurTime() >= botTable.FireWeaponInterval and bot:GetActiveWeapon() == botWeapon then
						
						bot:PressPrimaryAttack()
						botTable.FireWeaponInterval = CurTime() + math.Rand( 0.15 , 0.25 )
						
					end
					
				else
					
					local bestWeapon = nil
					
					for k, weapon in ipairs( bot:GetWeapons() ) do
				
						if IsValid( weapon ) and weapon:HasPrimaryAmmo() and weapon:IsTBotRegisteredWeapon() then 
							
							if !IsValid( bestWeapon ) or weapon:GetTBotDistancePriority( "Pistol" ) > bestWeapon:GetTBotDistancePriority( "Pistol" ) then
							
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
			
			break
			
		end
	
	end
	
end

function TBotPathFollowerMeta:Avoid( bot, goalPos, forward, left )

	if !self.m_avoidTimer:Elapsed() then
	
		return goalPos
		
	end

	self.m_avoidTimer:Start( 0.5 )
	
	local mover = bot:GetTBotLocomotion()
	if mover:IsClimbingOrJumping() or !bot:IsOnGround() or bot:InVehicle() then
	
		return goalPos
		
	end
	
	local area = bot:GetLastKnownArea()
	if IsValid( area ) and area:HasAttributes( NAV_MESH_PRECISE ) then 
	
		return goalPos 
		
	end
	
	local botCollision = bot:GetCollisionGroup()
	local body = bot:GetTBotBody()
	local size = body:GetHullWidth() / 4
	local offset = size + 2
	local range = Either( bot:KeyDown( IN_SPEED ), 50, 30 )
	range = range * bot:GetModelScale()
	local door = nil
	
	local hullMin = Vector( -size, -size, bot:GetStepSize() + 0.1 )
	local hullMax = Vector( size, size, body:GetCrouchHullHeight() )
	--local nextStepHullMin = Vector( -size, -size, 2.0 * self:GetStepSize() + 0.1 )
	
	-- This makes the bot walk through teammates if NoCollideWithTeammates is set to true!
	local botTeam = bot:Team()
	botTeam = botTeam >= 1 and botTeam or 0
	local avoidFilter = function( ent ) 
	
		if ent == bot then
		
			return false
			
		elseif ent:IsPlayer() then
		
			if 4 <= botTeam and ent:Team() == botTeam then
			
				if ent:GetNoCollideWithTeammates() and bot:GetNoCollideWithTeammates() then
				
					return false
					
				end
				
			end
		
		end
	
		return true 
		
	end
	
	local leftFrom = bot:GetPos() + offset * left
	local leftTo = leftFrom + range * forward
	local isLeftClear = true
	local leftAvoid = 0.0
	
	local result = {}
	util.TraceHull( { start = leftFrom, endpos = leftTo, maxs = hullMax, mins = hullMin, filter = avoidFilter, mask = MASK_PLAYERSOLID, collisiongroup = botCollision, output = result } )
	if result.Fraction < 1.0 or result.StartSolid then
	
		if result.StartSolid then
		
			result.Fraction = 0.0
			
		end
		
		leftAvoid = math.Clamp( 1.0 - result.Fraction, 0.0, 1.0 )
		isLeftClear = false
		
		if result.HitNonWorld then
		
			door = result.Entity
			
		end
		
	end
	
	local rightFrom = bot:GetPos() - offset * left
	local rightTo = rightFrom + range * forward
	local isRightClear = true
	local rightAvoid = 0.0
	
	util.TraceHull( { start = rightFrom, endpos = rightTo, maxs = hullMax, mins = hullMin, filter = avoidFilter, mask = MASK_PLAYERSOLID, collisiongroup = botCollision, output = result } )
	if result.Fraction < 1.0 or result.StartSolid then
	
		if result.StartSolid then
		
			result.Fraction = 0.0
			
		end
		
		rightAvoid = math.Clamp( 1.0 - result.Fraction, 0.0, 1.0 )
		isRightClear = false
		
		if !IsValid( door ) and result.HitNonWorld then
		
			door = result.Entity
			
		end
		
	end
	
	if GetConVar( "developer" ):GetBool() then
		
		if isLeftClear then
		
			debugoverlay.SweptBox( leftFrom, leftTo, hullMin, hullMax, angle_zero, 0.1, Color( 0, 255, 0 ) )
			
		else
		
			debugoverlay.SweptBox( leftFrom, leftTo, hullMin, hullMax, angle_zero, 0.1, Color( 255, 0, 0 ) )
			
		end
		
		if isRightClear then
		
			debugoverlay.SweptBox( rightFrom, rightTo, hullMin, hullMax, angle_zero, 0.1, Color( 0, 255, 0 ) )
			
		else
		
			debugoverlay.SweptBox( rightFrom, rightTo, hullMin, hullMax, angle_zero, 0.1, Color( 255, 0, 0 ) )
			
		end
		
	end
	
	local adjustedGoal = goalPos
	
	if IsValid( door ) and !isLeftClear and !isRightClear then
	
		local forward = door:GetForward()
		local right = door:GetRight()
		local up = door:GetUp()
		
		local doorWidth = 100
		local doorEdge = door:GetPos() - doorWidth * right
		
		adjustedGoal.x = doorEdge.x
		adjustedGoal.y = doorEdge.y
		self.m_avoidTimer:Reset()
		
	elseif !isLeftClear or !isRightClear then
	
		local avoidResult = 0.0
		if isLeftClear then
		
			avoidResult = -rightAvoid
			
		elseif isRightClear then
		
			avoidResult = leftAvoid
			
		else
		
			local equalTolerance = 0.01
			if math.abs( rightAvoid - leftAvoid ) < equalTolerance then
			
				return adjustedGoal
				
			elseif rightAvoid > leftAvoid then
			
				avoidResult = -rightAvoid
				
			else
			
				avoidResult = leftAvoid
				
			end
			
		end
		
		local avoidDir = 0.5 * forward - left * avoidResult
		avoidDir:Normalize()
		
		adjustedGoal = bot:GetPos() + 100 * avoidDir
		
		self.m_avoidTimer:Reset()
	
	end
	
	return adjustedGoal

end

function TBotPathFollowerMeta:Climbing( bot, goal, forward, right, goalRange )

	local myArea = bot:GetLastKnownArea()
	local body = bot:GetTBotBody()
	local mover = bot:GetTBotLocomotion()
	
	-- Use the 2D direction towards our goal
	local climbDirection = Vector( forward.x, forward.y, 0 )
	climbDirection:Normalize()
	
	-- We can't have this as large as our hull width, or we'll find ledges ahead of us
	-- that we will fall from when we climb up because our hull wont actually touch at the top.
	local ledgeLookAheadRange = body:GetHullWidth() - 1
	
	if !bot:IsOnGround() or mover:IsClimbingOrJumping() or mover:IsAscendingOrDescendingLadder() then
	
		return false
		
	end
	
	if !istable( self.m_goal ) then
	
		return false
		
	end
	
	if GetConVar( "TBotCheaperClimbing" ):GetBool() then
	
		-- Trust what the nav mesh tells us.
		-- We have been told not to do the expensive ledge-finding.
	
		if self.m_goal.type == TBotSegmentType.PATH_CLIMB_UP then
		
			local afterClimb = self:NextSegment( self.m_goal )
			if istable( afterClimb ) and IsValid( afterClimb.area ) then
			
				-- Find the closest point on climb-destination area
				local nearClimbGoal = afterClimb.area:GetClosestPointOnArea( bot:GetPos() )
				
				climbDirection = nearClimbGoal - bot:GetPos()
				climbDirection.z = 0.0
				climbDirection:Normalize()
				
				if mover:ClimbUpToLedge( nearClimbGoal, climbDirection, nil ) then
				
					return true
					
				end
				
			end
			
		end
		
		return false
		
	end
	
	-- If we're approaching a CLIMB_UP link, save off the height delta for it, and trust the nav *just* enough
	-- to climb up to that ledge and only that ledge.  We keep as large a tolerance as possible, to trust
	-- the nav as little as possible.  There's no valid way to have another CLIMB_UP link within crouch height,
	-- because we can't actually fit in between the two areas, so one climb is invalid.
	local climbUpLedgeHeightDelta = -1.0
	local ClimbUpToLedgeTolerance = body:GetCrouchHullHeight()
	
	if self.m_goal.type == TBotSegmentType.PATH_CLIMB_UP then
	
		local afterClimb = self:NextSegment( self.m_goal )
		if istable( afterClimb ) and IsValid( afterClimb.area ) then
		
			-- Find the closest point on climb-destination area
			local nearClimbGoal = afterClimb.area:GetClosestPointOnArea( bot:GetPos() )
			
			climbDirection = nearClimbGoal - bot:GetPos()
			climbUpLedgeHeightDelta = climbDirection.z
			climbDirection.z = 0.0
			climbDirection:Normalize()
			
		end
		
	end
	
	-- Don't try to climb up stairs
	if ( IsValid( self.m_goal.area ) and self.m_goal.area:HasAttributes( NAV_MESH_STAIRS ) ) or ( IsValid( myArea ) and myArea:HasAttributes( NAV_MESH_STAIRS ) ) then
	
		return false
		
	end
	
	-- 'current' is the segment we are on/just passed over
	local current = self:PriorSegment( self.m_goal )
	if !current then
	
		return false
		
	end
	
	-- If path segment immediately ahead of us is not obstructed, don't try to climb.
	-- This is required to try to avoid accidentally climbing onto valid high ledges when we really want to run UNDER them to our destination.
	-- We need to check "immediate" traversability to pay attention to breakable objects in our way that we should climb over.
	-- We also need to check traversability out to 2 * ledgeLookAheadRange in case our goal is just before a tricky ledge climb and once we pass the goal it will be too late.
	-- When we're in a CLIMB_UP segment, allow us to look for ledges - we know the destination ledge height, and will only grab the correct ledge.
	local toGoal = self.m_goal.pos - bot:GetPos()
	toGoal:Normalize()
	
	if toGoal.z < mover:GetTraversableSlopeLimit() and !mover:IsStuck() and self.m_goal.type != TBotSegmentType.PATH_CLIMB_UP and mover:IsPotentiallyTraversable( bot:GetPos(), bot:GetPos() + 2.0 * ledgeLookAheadRange * toGoal ) then
	
		return false
		
	end
	
	-- Determine if we're approaching a planned climb.
	-- Start with current, the segment we are currently traversing.  Skip the distance check for that segment, because
	-- the pos is (hopefully) behind us.  And if it's a long path segment, it's already outside the climbLookAheadRange,
	-- and thus it would prevent us looking at m_goal and further for imminent planned climbs.
	local isPlannedClimbImminent = false
	local plannedClimbZ = 0.0
	local s = current
	while s do
	
		if s != current and ( s.pos - bot:GetPos() ):AsVector2D():IsLengthGreaterThan( 150 ) then
		
			break
			
		end
		
		if s.type == TBotSegmentType.PATH_CLIMB_UP then
		
			isPlannedClimbImminent = true
			
			local nextSegment = self:NextSegment( s )
			if nextSegment then
			
				plannedClimbZ = nextSegment.pos.z
				
			end
			break
			
		end
		
		s = self:NextSegment( s )
		
	end
	
	local result = {}
	
	local hullWidth = body:GetHullWidth()
	local halfSize = hullWidth / 2.0
	local minHullHeight = body:GetCrouchHullHeight()
	local minLedgeHeight = bot:GetStepSize() + 0.1
	
	local skipStepHeightHullMin = Vector( -halfSize, -halfSize, minLedgeHeight )
	
	-- Need to use minimum actual hull height here to catch porous fences and railings
	local skipStepHeightHullMax = Vector( halfSize, halfSize, minHullHeight + 0.1 )
	
	-- Find the highest height we can stand at our current location.
	-- Using the full width hull catches on small lips/ledges, so back up and try again.
	local ceilingFraction
	
	-- Instead of IsPotentiallyTraversable, we back up the same distance and use a second upward trace
	-- to see if that one finds a higher ceiling.  If so, we use that ceiling height, and use the
	-- backed-up feet position for the ledge finding traces.
	local feet = bot:GetPos()
	local ceiling = feet + Vector( 0, 0, mover:GetMaxJumpHeight() )
	util.TraceHull( { start = feet, endpos = ceiling, maxs = skipStepHeightHullMax, mins = skipStepHeightHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
	ceilingFraction = result.Fraction
	local isBackupTraceUsed = false
	if ceilingFraction < 1.0 or result.StartSolid then
	
		local backupTrace = {}
		local backupDistance = hullWidth * 0.25
		local backupFeet = feet - climbDirection * backupDistance
		local backupCeiling = backupFeet + Vector( 0, 0, mover:GetMaxJumpHeight() )
		util.TraceHull( { start = backupFeet, endpos = backupCeiling, maxs = skipStepHeightHullMax, mins = skipStepHeightHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = backupTrace } )
		if !backupTrace.StartSolid and backupTrace.Fraction > ceilingFraction then
		
			result = backupTrace
			ceilingFraction = result.Fraction
			feet = backupFeet
			ceiling = backupCeiling
			isBackupTraceUsed = true
			
		end
		
	end
	
	local maxLedgeHeight = ceilingFraction * mover:GetMaxJumpHeight()
	
	if maxLedgeHeight <= bot:GetStepSize() then
	
		return false
		
	end
	
	-- Check for ledge climbs over things in our way.
	-- Even if we have a CLIMB_UP link in our path, we still need
	-- to find the actual ledge by tracing the local geometry.
	
	local climbHullMax = Vector( halfSize, halfSize, maxLedgeHeight )
	local ledgePos = Vector( feet ) -- to be computed below
	
	util.TraceHull( { start = feet, endpos = feet + climbDirection * ledgeLookAheadRange, maxs = climbHullMax, mins = skipStepHeightHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
	
	if result.Hit and !result.StartSolid then
	
		local obstacle = result.Entity
		
		-- EFL_DONTWALKON = 67108864 - NPCs should not walk on this entity
		if !result.HitNonWorld or ( IsValid( obstacle ) and !obstacle:IsDoor() and !obstacle:IsEFlagSet( 67108864 ) ) then
		
			-- The low hull sweep hit an obstacle - note how 'far in' this is
			local ledgeFrontWallDepth = ledgeLookAheadRange * result.Fraction
			
			local minLedgeDepth = body:GetHullWidth() / 2.0
			if self.m_goal.type == TBotSegmentType.PATH_CLIMB_UP then
			
				-- Climbing up to a narrow nav area indicates a narrow ledge.  We need to reduce our minLedgeDepth
				-- here or our path will say we should climb but we'll forever fail to find a wide enough ledge.
				local afterClimb = self:NextSegment( self.m_goal )
				if istable( afterClimb ) and IsValid( afterClimb.area ) then
				
					local depthVector = climbDirection * minLedgeDepth
					depthVector.z = 0.0
					if math.abs( depthVector.x ) > afterClimb.area:GetSizeX() then
					
						depthVector.x = Either( depthVector.x > 0, afterClimb.area:GetSizeX(), -afterClimb.area:GetSizeX() )
						
					end
					if math.abs( depthVector.y ) > afterClimb.area:GetSizeY() then
					
						depthVector.y = Either( depthVector.y > 0, afterClimb.area:GetSizeY(), -afterClimb.area:GetSizeY() )
						
					end
					
					minLedgeDepth = math.min( minLedgeDepth, depthVector:Length() )
					
				end
				
			end
			
			-- Find the ledge.  Start at the lowest jump we can make
			-- and step up until we find the actual ledge.  
			--
			-- The scan is limited to maxLedgeHeight in case our max 
			-- jump/climb height is so tall the highest horizontal hull 
			-- trace could be on the other side of the ceiling above us
			
			local ledgeHeight = minLedgeHeight
			local ledgeHeightIncrement = 0.5 * bot:GetStepSize()
			
			local foundWall = false
			local foundLedge = false
			
			-- once we have found the ledge's front wall, we must look at least minLedgeDepth farther in to verify it is a ledge
			-- NOTE: This *must* be ledgeLookAheadRange since ledges are compared against the initial trace which was ledgeLookAheadRange deep
			local ledgeTopLookAheadRange = ledgeLookAheadRange
			
			local climbHullMin = Vector( -halfSize, -halfSize, 0.0 )
			climbHullMax.x = halfSize
			climbHullMax.y = halfSize
			climbHullMax.z = minHullHeight
			
			--local wallPos
			local wallDepth = 0.0
			
			local isLastIteration = false
			while true do
			
				-- trace forward to find the wall in front of us, or the empty space of the ledge above us
				util.TraceHull( { start = feet + Vector( 0, 0, ledgeHeight ), endpos = feet + Vector( 0, 0, ledgeHeight ) + climbDirection * ledgeTopLookAheadRange, maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
				
				local traceDepth = ledgeTopLookAheadRange * result.Fraction
				
				if !result.StartSolid then
				
					-- if trace reached minLedgeDepth farther, this is a potential ledge
					if foundWall then
					
						if ( traceDepth - ledgeFrontWallDepth ) > minLedgeDepth then
						
							local isUsable = true
							
							-- initialize ledgePos from result of last trace
							ledgePos = result.HitPos
							
							-- Find the actual ground level on the potential ledge
							-- Only trace back down to the previous ledge height trace. 
							-- The ledge can be no lower, or we would've found it in the last iteration.
							util.TraceHull( { start = ledgePos, endpos = ledgePos + Vector( 0, 0, -ledgeHeightIncrement ), maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
							
							ledgePos = result.HitPos
							
							-- if the whole trace is in solid, we're out of luck, but
							-- if the trace just started solid, 'ledgePos' should still be valid
							-- since the trace left the solid and then hit.
							-- if the trace hit nothing, the potential ledge is actually deeper in
							-- players can't stand on ground steeper than 0.7
							if result.AllSolid or !result.Hit or result.HitNormal.z < 0.7 then
							
								-- Not a usable ledge, try again
								isUsable = false
								
							else
							
								if climbUpLedgeHeightDelta > 0.0 then
								
									-- if we're climbing to a specific ledge via a CLIMB_UP link, only climb to that ledge.
									-- Do this only for the world (which includes static props) so we can still opportunistically
									-- climb up onto breakable railings and physics props.
									if result.HitNonWorld then
									
										local potentialLedgeHeight = result.HitPos.z - feet.z
										if math.abs( potentialLedgeHeight - climbUpLedgeHeightDelta ) > ClimbUpToLedgeTolerance then
										
											isUsable = false
											
										end
										
									end
									
								end
								
							end
							
							if isUsable then
							
								-- back up until we no longer are hitting the ledge to determine the
								-- exact ledge edge position
								local validLedgePos = Vector( ledgePos )
								local maxBackUp = hullWidth
								local backUpSoFar = 4.0
								local testPos = ledgePos
								
								while backUpSoFar < maxBackUp do
								
									testPos = testPos - 4.0 * climbDirection
									backUpSoFar = backUpSoFar + 4.0
									
									util.TraceHull( { start = testPos, endpos = testPos + Vector( 0, 0, -ledgeHeightIncrement ), maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
									
									if result.Hit and result.HitNormal.z >= 0.7 then
									
										-- We hit, this is closer to the actual ledge edge
										ledgePos = result.HitPos
										
									else
									
										-- Nothing but air or a steep slope below us, we have found the edge
										break
										
									end
									
								end
								
								-- We want ledgePos to be right on the edge itself, so move 
								-- it ahead by half of the hull width
								ledgePos = ledgePos + climbDirection * halfSize
								
								-- Make sure this doesn't embed us in the far wall if the ledge is narrow, since we would
								-- have backed up less than halfSize.
								local climbHullMinStep = Vector( climbHullMin ) -- Skip StepHeight for sloped ledges
								util.TraceHull( { start = validLedgePos, endpos = ledgePos, maxs = climbHullMax, mins = climbHullMinStep, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
								
								ledgePos = result.HitPos
								
								-- Now since ledgePos + StepHeight is valid, trace down to find ground on sloped ledges.
								util.TraceHull( { start = ledgePos + Vector( 0, 0, bot:GetStepSize() ), endpos = ledgePos, maxs = climbHullMax, mins = climbHullMin, filter = TBotTraversableFilter, mask = MASK_PLAYERSOLID, output = result } )
								
								if !result.StartSolid then
								
									ledgePos = result.HitPos
									
								end
								
							end
							
							if isUsable then
							
								-- Found a useable ledge here
								foundLedge = true
								break
								
							end
							
						end
						
					elseif result.Hit then
					
						-- this iteration hit the wall under the ledge, 
						-- meaning the next iteration that reaches far enough will be our ledge

						-- Since we know that our desired route is likely blocked (via the 
						-- IsTraversable check above) - any ledge we hit we must climb.

						-- found a valid ledge wall
						foundWall = true
						wallDepth = traceDepth
						
						-- make sure the subsequent traces are at least minLedgeDepth deeper than
						-- the wall we just found, or all ledge checks will fail
						local minTraceDepth = traceDepth + minLedgeDepth + 0.1
						
						if ledgeTopLookAheadRange < minTraceDepth then
						
							ledgeTopLookAheadRange = minTraceDepth
							
						end
						
					elseif ledgeHeight > body:GetCrouchHullHeight() and !isPlannedClimbImminent then
					
						-- We haven't hit anything yet, and we're already above our heads - no obstacle
						break
						
					end
					
				end
				
				ledgeHeight = ledgeHeight + ledgeHeightIncrement
				
				if ledgeHeight >= maxLedgeHeight then
					
					if isLastIteration then
						
						-- Tested at max height
						break
						
					end
					
					-- Check one more time at max jump height
					isLastIteration = true
					ledgeHeight = maxLedgeHeight
					
				end
				
			end
			
			if foundLedge then
			
				if !mover:ClimbUpToLedge( ledgePos, climbDirection, obstacle ) then
				
					return false
					
				end
				
				return true
				
			end
		
		end
		
	end
	
	return false
	
end

function TBotPathFollowerMeta:JumpOverGaps( bot, goal, forward, right, goalRange )

	local body = bot:GetTBotBody()
	local mover = bot:GetTBotLocomotion()
	if !bot:IsOnGround() or mover:IsClimbingOrJumping() or mover:IsAscendingOrDescendingLadder() then
	
		return false
		
	end
	
	if bot:Crouching() then
	
		-- Can't jump if we're not standing
		return false
		
	end
	
	if !self.m_goal then
	
		return false
		
	end
	
	local result
	local hullWidth = body:GetHullWidth()
	
	-- 'current' is the segment we are on/just passed over
	local current = self:PriorSegment( self.m_goal )
	if !current then
	
		return false
		
	end
	
	local minGapJumpRange = 2.0 * hullWidth
	local gap
	
	if current.type == TBotSegmentType.PATH_JUMP_OVER_GAP then
	
		gap = current
		
	else
	
		local searchRange = goalRange
		local s = self.m_goal
		while s do
		
			if searchRange > minGapJumpRange then
			
				break
				
			end
			
			if s.type == TBotSegmentType.PATH_JUMP_OVER_GAP then
			
				gap = s
				break
				
			end
			
			searchRange = searchRange + s.length
			s = self:NextSegment( s )
			
		end
		
	end
	
	if gap then
	
		local halfWidth = hullWidth / 2.0
		
		if mover:IsGap( bot:GetPos() + halfWidth * gap.forward, gap.forward ) then
		
			-- There is a gap to jump over
			local landing = self:NextSegment( gap )
			if landing then
			
				mover:JumpAcrossGap( landing.pos, landing.forward )
				
				-- If we're jumping over a gap, make sure our goal is the landing so we aim for it
				self.m_goal = landing
				
				return true
				
			end
			
		end
		
	end
	
	return false
	
end

function TBotPathFollowerMeta:IsDiscontinuityAhead( bot, type, range )

	if istable( self.m_goal ) then
	
		local current = self:PriorSegment( self.m_goal )
		if istable( current ) and current.type == type then
		
			-- We're on the discontinuity now
			return true
			
		end
		
		local rangeSoFar = self.m_goal.pos:Distance( bot:GetPos() )
		
		local s = self.m_goal
		while s do
		
			if rangeSoFar >= range then
			
				break
				
			end
			
			if s.type == type then
			
				return true
				
			end
			
			rangeSoFar = rangeSoFar + s.length
			
			s = self:NextSegment( s )
			
		end
		
	end
	
	return false
	
end