-- TBotPath.lua
-- Purpose: This is where the bot's path types are defined.
-- Author: T-Rizzle

-- Path types!!!!!!
TBotSegmentType = {}
TBotSegmentType.PATH_ON_GROUND			=	0
TBotSegmentType.PATH_DROP_DOWN			=	1
TBotSegmentType.PATH_CLIMB_UP			=	2
TBotSegmentType.PATH_JUMP_OVER_GAP		=	3
TBotSegmentType.PATH_LADDER_UP			=	4
TBotSegmentType.PATH_LADDER_DOWN		=	5
TBotSegmentType.PATH_USE_PORTAL			=	6

-- OnPathChanged local enums
TBotOnPathChanged = {}
TBotOnPathChanged.COMPLETE_PATH			=	0
TBotOnPathChanged.PARTIAL_PATH			=	1
TBotOnPathChanged.NO_PATH				=	2

local TBotPathSegmentMeta = {}

TBotPathSegmentMeta.__index = TBotPathSegmentMeta

function TBotPathSegment()
	local tbotpathsegment = {}
	
	tbotpathsegment.area = nil -- The area along the path
	tbotpathsegment.how = 0 -- how to enter this area from the previous one
	tbotpathsegment.pos = Vector() -- Our movment goal position at this point in the path
	tbotpathsegment.ladder = nil -- If "how" referes to a ladder, this is it
	tbotpathsegment.portal = nil -- If "how" referes to a portal, this is it
	tbotpathsegment.destination = nil -- If "how" referes to a portal, this is its destination
	
	tbotpathsegment.type = TBotSegmentType.PATH_ON_GROUND -- how to traverse this segment of the path
	tbotpathsegment.forward = Vector() -- Unit vector along segment
	tbotpathsegment.length = 0 -- Length of this segment
	tbotpathsegment.distanceFromStart = 0 -- Distance of this node from the start of the Path
	setmetatable( tbotpathsegment, TBotPathSegmentMeta )
	
	return tbotpathsegment
	
end

local TBotPathMeta = {}

TBotPathMeta.__index = TBotPathMeta

RegisterMetaTable( "TBotPath", TBotPathMeta ) -- Register this class so other versions of the pathfinder can use it.

function TBotPath()
	local tbotpath = {}

	tbotpath.m_path = {}
	tbotpath.m_segmentCount = 0
	
	-- NEEDTOVALIDATE: Do we need this?
	--[[tbotpath.m_cursorPos = 0.0
	tbotpath.m_isCursorDataDirty = true
	tbotpath.m_cursorData = {}
	tbotpath.m_cursorData.segmentPrior = false]]
	
	-- HACKHACK: We create our own IntervalTimer here, I should probably create a pull request and have this added to the base game.
	local ageTimer = {}
	ageTimer.m_timestamp = -1.0
	ageTimer.Reset = function( self ) self.m_timestamp = CurTime() end
	ageTimer.Start = function( self ) self.m_timestamp = CurTime() end
	ageTimer.Invalidate = function( self ) self.m_timestamp = -1.0 end
	ageTimer.HasStarted = function( self ) return self.m_timestamp > 0 end
	ageTimer.GetElapsedTime = function( self ) return Either( self:HasStarted(), CurTime() - self.m_timestamp, 99999.9 ) end
	ageTimer.IsLessThen = function( self, duration ) return CurTime() - self.m_timestamp < duration end
	ageTimer.IsGreaterThen = function( self, duration ) return CurTime() - self.m_timestamp > duration end
	
	tbotpath.m_ageTimer = ageTimer
	tbotpath.m_ageTimer:Reset()
	tbotpath.m_subject = nil
	setmetatable( tbotpath, TBotPathMeta )
	
	return tbotpath
	
end

function istbotpath( obj )

	return getmetatable( obj ) == TBotPathMeta
	
end

function TBotPathMeta:GetLength()

	if self.m_segmentCount <= 0 then
	
		return 0.0
		
	end
	
	return self.m_path[ self.m_segmentCount ].distanceFromStart
	
end

function TBotPathMeta:IsValid()

	return self.m_segmentCount > 0
	
end

function TBotPathMeta:Invalidate()

	self.m_path = {}
	self.m_segmentCount = 0
	self.m_subject = nil
	
end

function TBotPathMeta:FirstSegment()
	if !self:IsValid() then return end
	
	return self.m_path[ 1 ]
	
end

function TBotPathMeta:LastSegment()
	if !self:IsValid() then return end

	return self.m_path[ self.m_segmentCount ]
	
end

function TBotPathMeta:GetStartPosition()
	if !self:IsValid() then return Vector() end
	
	return self.m_path[ 1 ].pos
	
end

function TBotPathMeta:GetEndPosition()
	if !self:IsValid() then return Vector() end
	
	return self.m_path[ self.m_segmentCount ].pos
	
end

function TBotPathMeta:NextSegment( currentSegment )

	if !currentSegment or !self:IsValid() then
	
		return nil
		
	end
	
	local i = table.KeyFromValue( self.m_path, currentSegment )
	if i < 0 or i > self.m_segmentCount then
	
		return nil
		
	end
	
	return self.m_path[ i + 1 ]
	
end

function TBotPathMeta:PriorSegment( currentSegment )

	if !currentSegment or !self:IsValid() then
	
		return nil
		
	end
	
	local i = table.KeyFromValue( self.m_path, currentSegment )
	if i <= 1 or i > self.m_segmentCount then
	
		return nil
		
	end
	
	return self.m_path[ i - 1 ]
	
end

function TBotPathMeta:GetSubject()

	return self.m_subject
	
end

-- NEEDTOVALIDATE: Do I even need this?
function TBotPathMeta:GetCurrentGoal()

	return nil
	
end

function TBotPathMeta:GetAge()

	return self.m_ageTimer:GetElapsedTime()
	
end

-- Creates waypoints using the nodes.
function TBotPathMeta:ComputeNavmeshVisibility( bot, start )
	if self.m_segmentCount == 0 then return false end

	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	local LADDER_UP = 0
	local LADDER_DOWN = 1
	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	local GO_THROUGH_PORTAL = 6
	local NUM_TRAVERSE_TYPES = 9
	local botTable = bot:GetTable()
	local body = bot:GetTBotBody()
	local mover = bot:GetTBotLocomotion()
	local dir = Vector()
	
	if self.m_path[ 1 ].area:Contains( start ) then
	
		self.m_path[ 1 ].pos = start
		
	else
	
		self.m_path[ 1 ].pos = self.m_path[ 1 ].area:GetCenter()
		
	end
	
	self.m_path[ 1 ].how = NUM_TRAVERSE_TYPES
	self.m_path[ 1 ].type = TBotSegmentType.PATH_ON_GROUND
	
	local hullWidth = 1.0
	local stepHeight = 18
	
	if IsValid( bot ) then
	
		hullWidth = body:GetHullWidth() + 5.0 -- Inflate hull width slightly as a safety margin!
		stepHeight = bot:GetStepSize()
	
	end
	
	local index = 2
	while index <= self.m_segmentCount do
		
		local from = self.m_path[ index - 1 ]
		local to = self.m_path[ index ]
		
		if to.how <= WEST then
		
			local CurrentNode	=	from.area
			local NextNode		=	to.area
			local Nexthow		=	to.how
			
			to.pos = CurrentNode:ComputeClosestPointInPortal( NextNode, from.pos, Nexthow )
			
			--to.Pos = AddDirectionVector( to.Pos, Nexthow, 5.0 )
			to.pos.z = CurrentNode:GetZ( to.pos )
			
			--local expectedHeightDrop = CurrentNode:GetZ( from.Pos ) - NextNode:GetZ( to.Pos )
			
			local fromPos = Vector( from.pos )
			fromPos.z = from.area:GetZ( fromPos )
			
			local toPos = Vector( to.pos )
			toPos.z = to.area:GetZ( toPos )
			
			local groundNormal = from.area:ComputeNormal()
			local alongPath = toPos - fromPos
			local expectedHeightDrop = -alongPath:Dot( groundNormal )
			--print( "Should Drop Down: " .. tostring( expectedHeightDrop > self:GetStepSize() ) )
			--print( "From Position: " .. tostring( from.Pos ))
			--print( "PathIndex: " .. tostring( index ) )
			--print( "To Position: " .. tostring( to.Pos ) )
			
			if expectedHeightDrop > stepHeight then
			
				--print("DROP")
				dir:Zero() -- This resets dir to Vector( 0, 0, 0 )
				
				if Nexthow == NORTH then 
					dir.x = 0 
					dir.y = -1
				elseif Nexthow == SOUTH then 
					dir.x = 0 
					dir.y = 1
				elseif Nexthow == EAST then 
					dir.x = 1 
					dir.y = 0
				elseif Nexthow == WEST then 
					dir.x = -1 
					dir.y = 0 
				end
				
				local inc = 10
				local maxPushDist = 2.0 * hullWidth
				local halfWidth = hullWidth / 2.0
				local hullHeight = body and body:GetCrouchHullHeight() or 1.0
				
				local pushDist = 0
				while pushDist <= maxPushDist do
				
					local pos = to.pos + Vector( pushDist * dir.x, pushDist * dir.y, 0 )
					local lowerPos = Vector( pos.x, pos.y, toPos.z )
					local ground = {}
					util.TraceHull( { start = pos, endpos = lowerPos, mins = Vector( -halfWidth, -halfWidth, stepHeight ), maxs = Vector( halfWidth, halfWidth, hullHeight ), mask = MASK_PLAYERSOLID, filter = TBotTraversableFilter, output = ground } )
					
					--print( "Ground Fraction: " .. tostring( ground.Fraction ) )
					--print( "Started Solid: " .. tostring( ground.StartSolid ) )
					--print( "Hit Entity: " .. tostring( ground.Entity ) )
					--print( "Hit World: " .. tostring( ground.HitWorld ) )
					--print( "Hit NonWorld: " .. tostring( ground.HitNonWorld ) )
					--print( "Hit NoDraw: " .. tostring( ground.HitNoDraw ) )
					if ground.Fraction >= 1.0 then
					
						break
						
					end
					
					pushDist = pushDist + inc
					
				end
				
				--print( "Push Distance: " .. tostring ( pushDist ) )
				local startDrop = Vector( to.pos.x + ( pushDist * dir.x ), to.pos.y + ( pushDist * dir.y ), to.pos.z )
				local endDrop = Vector( startDrop.x, startDrop.y, NextNode:GetZ( to.pos ) )
				
				local ground = navmesh.GetGroundHeight( startDrop )
				if ground and startDrop.z > ground + stepHeight then
				
					-- if "ground" is lower than the next segment along the path
					-- there is a chasm between - this is not a drop down
					local nextSegment = self:NextSegment( to )
					local ground2 = nil
					if nextSegment and IsValid( nextSegment.area ) then
					
						ground2 = navmesh.GetGroundHeight( nextSegment.area:GetCenter() )
						
					end
					
					if !ground2 or ground2 < ground + stepHeight then
					
						to.pos = startDrop
						to.type = TBotSegmentType.PATH_DROP_DOWN
						
						endDrop.z = ground
						
						local newSegment = TBotPathSegment()
						newSegment.pos = endDrop
						newSegment.area = to.area
						newSegment.how = to.how
						newSegment.type = TBotSegmentType.PATH_ON_GROUND
						
						table.insert( self.m_path, index + 1, newSegment )
						self.m_segmentCount = self.m_segmentCount + 1
						index = index + 2
						continue
						
					end
				
				end
				
			end
			
		elseif to.how == GO_LADDER_UP then
		
			local list = from.area:GetLaddersAtSide( LADDER_UP )
			--print( "Ladders: " .. #list )
			local i = 1
			while i <= #list do
				local ladder = list[ i ]
				--print( "Top Area: " .. tostring( ladder:GetTopForwardArea() ) )
				--print( "TopLeft Area: " .. tostring( ladder:GetTopLeftArea() ) )
				--print( "TopRight Area: " .. tostring( ladder:GetTopRightArea() ) )
				--print( "TopBehind Area: " .. tostring( ladder:GetTopBehindArea() ) )
				if IsValid( ladder ) and ( ladder:GetTopForwardArea() == to.area or ladder:GetTopLeftArea() == to.area or ladder:GetTopRightArea() == to.area or ladder:GetTopBehindArea() == to.area ) then
					
					to.pos = ladder:GetBottom() + ladder:GetNormal() * 2.0 * ( hullWidth / 2.0 )
					to.type = TBotSegmentType.PATH_LADDER_UP
					to.ladder = ladder
					--table.insert( self.Path, index, { Pos = ladder:GetBottom() + ladder:GetNormal() * 2.0 * 16, how = GO_LADDER_UP, Type = TBotSegmentType.PATH_LADDER_MOUNT } )
					--self.SegmentCount = self.SegmentCount + 1
					break
					
				end
				i = i + 1
			end
			
			-- for some reason we couldn't find the ladder
			if i > #list then
			
				return false
				
			end
			
		elseif to.how == GO_LADDER_DOWN then
		
			local list = from.area:GetLaddersAtSide( LADDER_DOWN )
			--print( "Ladders: " .. #list )
			local i = 1
			while i <= #list do
				local ladder = list[ i ]
				--print( "Bottom Area: " .. tostring( ladder:GetBottomArea() ) )
				if IsValid( ladder ) and ladder:GetBottomArea() == to.area then
					
					to.pos = ladder:GetTop() - ladder:GetNormal() * 2.0 * ( hullWidth / 2.0 )
					to.type = TBotSegmentType.PATH_LADDER_DOWN
					to.ladder = ladder
					--table.insert( self.Path, index, { Pos = ladder:GetTop() + ladder:GetNormal() * 2.0 * 16, how = GO_LADDER_DOWN, Type = TBotSegmentType.PATH_LADDER_MOUNT } )
					--self.SegmentCount = self.SegmentCount + 1
					break
					
				end
				i = i + 1
			end
			
			-- for some reason we couldn't find the ladder
			if i > #list then
			
				return false
				
			end
		
		elseif to.how == GO_THROUGH_PORTAL then
		
			local list = from.area:GetPortals()
			--print( "Portals: " .. #list )
			local i = 1
			while i <= #list do
				local portalList = list[ i ]
				--print( "Destination Area: " .. tostring( portalList.destination_cnavarea ) )
				if IsValid( portalList.destination_cnavarea ) and IsValid( portalList.portal ) and portalList.destination_cnavarea == to.area then
				
					to.pos = portalList.portal:GetPos()
					to.type = TBotSegmentType.PATH_USE_PORTAL
					to.portal = portalList.portal
					to.destination = portalList.destination
					break
					
				end
				i = i + 1
			end
			
			-- for some reason we couldn't find the portal
			if i > #list then
			
				return false
				
			end
			
		end
		
		index = index + 1
		continue
		
	end
	
	local index = 1
	while index < self.m_segmentCount do
		
		local from = self.m_path[ index ]
		local to = self.m_path[ index + 1 ]
		local CurrentNode = from.area
		local NextNode = to.area
		
		if from.how != NUM_TRAVERSE_TYPES and from.how > WEST then
		
			index = index + 1
			continue
			
		end
		
		if to.how > WEST or to.type != TBotSegmentType.PATH_ON_GROUND then
		
			index = index + 1
			continue
			
		end
		
		local closeTo = NextNode:GetClosestPointOnArea( from.pos )
		local closeFrom = CurrentNode:GetClosestPointOnArea( closeTo )
		
		if ( closeFrom - closeTo ):AsVector2D():IsLengthGreaterThan( 1.9 * 25 ) and ( closeTo - closeFrom ):AsVector2D():IsLengthGreaterThan( 0.5 * math.abs( closeTo.z - closeFrom.z ) ) then
		
			local landingPos = NextNode:GetClosestPointOnArea( to.pos )
			local launchPos = CurrentNode:GetClosestPointOnArea( landingPos )
			local forward = landingPos - launchPos
			forward:Normalize()
			local halfWidth = hullWidth / 2.0
			
			to.pos = landingPos + forward * halfWidth
			
			local newSegment = TBotPathSegment()
			newSegment.area = from.area
			newSegment.how = from.how
			newSegment.pos = launchPos - forward * halfWidth
			newSegment.type = TBotSegmentType.PATH_JUMP_OVER_GAP
			
			table.insert( self.m_path, index + 1, newSegment )
			self.m_segmentCount = self.m_segmentCount + 1
			index = index + 1
			--print( "GapJump" )
			
		
		elseif bot:ShouldJump( closeFrom, closeTo ) then
		
			to.pos = NextNode:GetCenter()
			
			local launchPos = CurrentNode:GetClosestPointOnArea( to.pos )
			
			local newSegment = TBotPathSegment()
			newSegment.area = from.area
			newSegment.how = from.how
			newSegment.pos = launchPos
			newSegment.type = TBotSegmentType.PATH_CLIMB_UP
			
			table.insert( self.m_path, index + 1, newSegment )
			self.m_segmentCount = self.m_segmentCount + 1
			index = index + 1
			
		end
		
		index = index + 1
		
	end
	
	--table.insert( self.Path, { Pos = self.Goal, Type = TBotSegmentType.PATH_ON_GROUND } )
	
	return true
	
end

-- Build trivial path when start and goal are in the same area
function TBotPathMeta:BuildTrivialPath( bot, goal )

	local NUM_TRAVERSE_TYPES = 9
	local start = bot:GetPos()
	local botTable = bot:GetTable()
	
	self.m_segmentCount = 0
	
	local startArea = navmesh.GetNearestNavArea( start )
	if !IsValid( startArea ) then
	
		return false
		
	end
	
	local goalArea = navmesh.GetNearestNavArea( goal )
	if !IsValid( goalArea ) then
	
		return false
		
	end
	
	self.m_segmentCount = 2
	
	self.m_path[ 1 ] = TBotPathSegment()
	self.m_path[ 1 ].area = startArea
	self.m_path[ 1 ].pos = Vector( start.x, start.y, startArea:GetZ( start ) )
	self.m_path[ 1 ].how = NUM_TRAVERSE_TYPES
	self.m_path[ 1 ].type = TBotSegmentType.PATH_ON_GROUND
	
	self.m_path[ 2 ] = TBotPathSegment()
	self.m_path[ 2 ].area = goalArea
	self.m_path[ 2 ].pos = Vector( goal.x, goal.y, goalArea:GetZ( goal ) )
	self.m_path[ 2 ].how = NUM_TRAVERSE_TYPES
	self.m_path[ 2 ].type = TBotSegmentType.PATH_ON_GROUND
	
	self.m_path[ 1 ].forward = self.m_path[ 2 ].pos - self.m_path[ 1 ].pos
	self.m_path[ 1 ].length = self.m_path[ 1 ].forward:Length()
	self.m_path[ 1 ].forward:Normalize()
	self.m_path[ 1 ].distanceFromStart = 0.0
	
	self.m_path[ 2 ].forward = self.m_path[ 1 ].forward
	self.m_path[ 2 ].length = 0.0
	self.m_path[ 2 ].distanceFromStart = self.m_path[ 1 ].length
	
	self:OnPathChanged( bot, TBotOnPathChanged.COMPLETE_PATH )
	
	return true
	
end

-- A handy debugger for the waypoints.
-- Requires developer set to 1 in console
function TBotPathMeta:Draw()
	if !self:IsValid() then return end
	if !GetConVar( "developer" ):GetBool() then return end
	
	--[[debugoverlay.Line( self.Path[ 1 ][ "Pos" ] , self:GetPos() + Vector( 0 , 0 , 44 ) , 0.08 , Color( 0 , 255 , 255 ) )
	debugoverlay.Sphere( self.Path[ 1 ][ "Pos" ] , 8 , 0.08 , Color( 0 , 255 , 255 ) , true )
	
	for k, v in ipairs( self.Path ) do
		
		if self.Path[ k + 1 ] then
			
			debugoverlay.Line( v[ "Pos" ] , self.Path[ k + 1 ][ "Pos" ] , 0.08 , Color( 255 , 255 , 0 ) )
			
		end
		
		debugoverlay.Sphere( v[ "Pos" ] , 8 , 0.08 , Color( 255 , 200 , 0 ) , true )
		
	end]]
	
	local s = self:FirstSegment()
	local i = 0
	while s do
		
		local nextNode = self:NextSegment( s )
		if !nextNode then
		
			break
			
		end
		
		local to = nextNode.pos - s.pos
		local horiz = math.max( math.abs( to.x ), math.abs( to.y ) )
		local vert = math.abs( to.z )
		
		-- TBotSegmentType.PATH_ON_GROUND and TBotSegmentType.PATH_LADDER_MOUNT
		local r, g, b = 255, 77, 0
		
		if s.type == TBotSegmentType.PATH_DROP_DOWN then
		
			r = 255
			g = 0
			b = 255
			
		elseif s.type == TBotSegmentType.PATH_CLIMB_UP then 
		
			r = 0
			g = 0
			b = 255
			
		elseif s.type == TBotSegmentType.PATH_JUMP_OVER_GAP then 
		
			r = 0
			g = 255
			b = 255
			
		elseif s.type == TBotSegmentType.PATH_LADDER_UP then 
		
			r = 0
			g = 255
			b = 0
			
		elseif s.type == TBotSegmentType.PATH_LADDER_DOWN then 
		
			r = 0
			g = 100
			b = 0
			
		end
		
		if IsValid( s.ladder ) then
		
			debugoverlay.VertArrow( s.ladder:GetBottom(), s.ladder:GetTop(), 5.0, r, g, b, 255, true, 0.1 )
			
		else
		
			debugoverlay.Line( s.pos, nextNode.pos, 0.1, Color( r, g, b ), true )
			
		end
		
		local nodeLength = 25.0
		if horiz > vert then
		
			debugoverlay.HorzArrow( s.pos, s.pos + nodeLength * s.forward, 5.0, r, g, b, 255, true, 0.1 )
			
		else
		
			debugoverlay.VertArrow( s.pos, s.pos + nodeLength * s.forward, 5.0, r, g, b, 255, true, 0.1 )
			
		end
		
		debugoverlay.Text( s.pos, tostring( i ), 0.1, true )
		
		s = nextNode
		i = i + 1
		
	end
	
end

-- This is the post proccess of the path
function TBotPathMeta:PostProcess()
	
	self.m_ageTimer:Start()
	
	if self.m_segmentCount == 0 then 
	
		return 
		
	end
	
	if self.m_segmentCount == 1 then
	
		self.m_path[ 1 ].forward = Vector()
		self.m_path[ 1 ].length = 0.0
		self.m_path[ 1 ].distanceFromStart = 0.0
		return
		
	end

	local distanceSoFar = 0.0
	local index = 1
	while index < self.m_segmentCount do
	
		local from = self.m_path[ index ]
		local to = self.m_path[ index + 1 ]
		
		from.forward = to.pos - from.pos
		from.length = from.forward:Length()
		from.forward:Normalize()
		
		from.distanceFromStart = distanceSoFar
		
		distanceSoFar = distanceSoFar + from.length
		
		index = index + 1
		
	end
	
	self.m_path[ index ].forward = self.m_path[ index - 1 ].forward
	self.m_path[ index ].length = 0.0
	self.m_path[ index ].distanceFromStart = distanceSoFar
	
end

function TBotPathMeta:OnPathChanged( bot, result )

	-- We do nothing here by default.

end

local function TRizzleBotRangeCheck( area, fromArea, ladder, portal, bot, length )
	
	if !IsValid( fromArea ) then
	
		-- first area in path, no cost
		return 0
		
	elseif fromArea:HasAttributes( NAV_MESH_JUMP ) and area:HasAttributes( NAV_MESH_JUMP ) then
	
		-- cannot actually walk in jump areas - disallow moving from jump area to jump area
		return -1.0
	
	else
	
		-- compute distance traveled along path so far
		local dist = 0
		
		if IsValid( ladder ) then 
		
			dist = ladder:GetLength()
			
		elseif isnumber( length ) and length > 0 then
		
			-- optimization to avoid recomputing lengths
			dist = length
		
		else
		
			dist = area:GetCenter():Distance( fromArea:GetCenter() )
			
		end
		
		-- If the portal is disabled then we can't use it!
		if IsValid( portal ) and portal:GetInternalVariable( "m_bDisabled" ) then
		
			return -1.0
			
		end
		
		local Height	=	fromArea:ComputeAdjacentConnectionHeightChange( area )
		local stepHeight = 18
		if IsValid( bot ) then stepHeight = bot:GetStepSize() end
		
		-- Jumping is slower than ground movement.
		if !IsValid( ladder ) and !IsValid( portal ) and !fromArea:IsUnderwater() and Height > stepHeight then
			
			local maximumJumpHeight = 64
			if IsValid( bot ) then maximumJumpHeight = bot:GetTBotLocomotion():GetMaxJumpHeight() end
			
			if Height > maximumJumpHeight then
			
				return -1
			
			end
			
			--print( "Jump Height: " .. Height )
			dist	=	dist + ( dist * 2 )
			
		-- Falling is risky if the bot might take fall damage.
		elseif !area:IsUnderwater() and Height < -stepHeight then
			
			local fallDistance = -fromArea:ComputeGroundHeightChange( area )
			
			if IsValid( ladder ) and ladder:GetBottom().z < fromArea:GetCenter().z and ladder:GetBottom().z > area:GetCenter().z then
			
				fallDistance = ladder:GetBottom().z - area:GetCenter().z
				
			end
			
			if IsValid( portal ) and portal:GetPos().z < fromArea:GetCenter().z and portal:GetPos().z > area:GetCenter().z then
			
				fallDistance = portal:GetPos().z - area:GetCenter().z
				
			end
			
			--print( "Drop Height: " .. Height )
			local fallDamage = GetApproximateFallDamage( fallDistance )
			
			if fallDamage > 0.0 and IsValid( bot ) then
			
				-- if the fall would kill us, don't use it
				local deathFallMargin = 10.0
				if fallDamage + deathFallMargin >= bot:Health() then
				
					return -1.0
					
				end
				
				local painTolerance = 25.0
				if bot:IsUnhealthy() or fallDamage > painTolerance then
				
					-- cost is proportional to how much it hurts when we fall
					-- 10 points - not a big deal, 50 points - ouch
					dist	=	dist + ( 100 * fallDamage * fallDamage )
					
				end
			
			end
			
		end
		
		local preference = 1.0
		
		-- This isn't really needed for sandbox, but since this is a bot base I will leave this here.
		-- This will have certain cases where its not used.
		-- NOTE: If TBotRandomPaths is nonzero the bot will use this when pathfinding
		if GetConVar( "TBotRandomPaths" ):GetBool() then
		
			-- this term causes the same bot to choose different routes over time,
			-- but keep the same route for a period in case of repaths
			local timeMod = math.floor( ( CurTime() / 10 ) + 1 )
			preference = 1.0 + 50.0 * ( 1.0 + math.cos( bot:EntIndex() * area:GetID() * timeMod ) )
			
		end
		
		-- Crawling through a vent is very slow.
		-- NOTE: The cost is determined by the bot's crouch speed
		if area:HasAttributes( NAV_MESH_CROUCH ) then 
			
			local crouchPenalty = 5
			if IsValid( bot ) then crouchPenalty = math.floor( 1 / bot:GetCrouchedWalkSpeed() ) end
			
			dist	=	dist + ( dist * crouchPenalty )
			
		end
		
		-- If this area might damage us if we walk through it we should avoid it at all costs.
		if area:IsDamaging() then
		
			dist	=	dist + ( dist * 100.0 )
			
		end
		
		-- The bot should avoid this area unless alternatives are too dangerous or too far.
		if area:HasAttributes( NAV_MESH_AVOID ) then 
			
			dist	=	dist + ( dist * 20 )
			
		end
		
		-- We will try not to swim since it can be slower than running on land, it can also be very dangerous, Ex. "Acid, Lava, Etc."
		if area:IsUnderwater() then
		
			dist	=	dist + ( dist * 2 )
			
		end
		
		local cost	=	dist * preference
		
		--print( "Distance: " .. dist )
		--print( "Total Cost: " .. cost )
		
		return cost + fromArea:GetCostSoFar()
		
	end
	
end

-- This is a hybrid version of pathfollower, it can use ladders and is very optimized
function TBotPathMeta:Compute( bot, goal, costFunc )
	costFunc = costFunc or TRizzleBotRangeCheck
	
	self:Invalidate()
	
	local NUM_TRAVERSE_TYPES = 9
	local start = bot:GetPos()
	local startArea = bot:GetLastKnownArea()
	local botTable = bot:GetTable()
	if !IsValid( startArea ) then
	
		self:OnPathChanged( bot, TBotOnPathChanged.NO_PATH )
		return false
		
	end
	
	local maxDistanceToArea = 200
	local goalArea = navmesh.GetNearestNavArea( goal, true, maxDistanceToArea, true )
	
	if startArea == goalArea then
	
		self:BuildTrivialPath( bot, goal )
		return true
		
	end
	
	local pathEndPosition = Vector( goal )
	if IsValid( goalArea ) then
	
		pathEndPosition.z = goalArea:GetZ( pathEndPosition )
		
	else
		
		local ground = navmesh.GetGroundHeight( pathEndPosition )
		if ground then pathEndPosition.z = ground end
		
	end
	
	local pathResult, closestArea = NavAreaBuildPath( startArea, goalArea, Vector( goal ), bot, costFunc )
	
	-- Failed?
	if !IsValid( closestArea ) then
	
		return false
		
	end
	
	--
	-- Build actual path by following parent links back from goal area
	--
	
	-- get count
	local count = 0
	local area = closestArea
	while IsValid( area ) do
	
		count = count + 1
		
		if area == startArea then
		
			-- startArea can be re-evaluated during the pathfind and given a parent
			break
			
		end
		
		area = area:GetParent()
		
	end
	
	if count == 0 then
	
		return false
		
	end
	
	if count == 1 then
	
		self:BuildTrivialPath( bot, goal )
		return pathResult
		
	end
	
	-- assemble path
	self.m_segmentCount = count
	area = closestArea
	while IsValid( area ) and count > 0 do
	
		self.m_path[ count ] = TBotPathSegment()
		self.m_path[ count ].area = area
		self.m_path[ count ].how = area:GetParentHow()
		self.m_path[ count ].type = TBotSegmentType.PATH_ON_GROUND
		
		area = area:GetParent()
		count = count - 1
		
	end
	
	-- append actual goal position
	self.m_segmentCount = self.m_segmentCount + 1
	self.m_path[ self.m_segmentCount ] = TBotPathSegment()
	self.m_path[ self.m_segmentCount ].area = closestArea
	self.m_path[ self.m_segmentCount ].pos = pathEndPosition
	self.m_path[ self.m_segmentCount ].how = NUM_TRAVERSE_TYPES
	self.m_path[ self.m_segmentCount ].type = TBotSegmentType.PATH_ON_GROUND
	
	--[[for k,v in ipairs( botTable.Path ) do
	
		if v.Area == startArea then
		
			print( "StartArea at " .. tostring( k ) )
		
		elseif v.Area == closestArea then
		
			print( "EndArea at " .. tostring( k ) )
			
		end
		
	end
	
	print( "SegmentCount: " .. tostring( botTable.SegmentCount ) )
	print( "Bot Path Length: " .. tostring( #botTable.Path ) )]]
	
	-- compute path positions
	if self:ComputeNavmeshVisibility( bot, start ) == false then
	
		self:Invalidate()
		self:OnPathChanged( bot, TBotOnPathChanged.NO_PATH )
		return false
		
	end
	
	self:PostProcess()
	
	self:OnPathChanged( bot, pathResult and TBotOnPathChanged.COMPLETE_PATH or TBotOnPathChanged.PARTIAL_PATH )
	
	return pathResult
	
end

-- INTERNAL: This is used internaly by TRizzleBotPathfinderRetreat, don't go complaning about having issues
-- with it if you use this function for other things!
function TBotPathMeta:AssemblePrecomputedPath( bot, goal, endArea )

	local start = bot:GetPos()
	local botTable = bot:GetTable()
	local NUM_TRAVERSE_TYPES = 9
	
	-- get count
	local count = 0
	local area = endArea
	while IsValid( area ) do
	
		count = count + 1
		
		area = area:GetParent()
		
	end
	
	if count == 0 then
	
		return
		
	end
	
	if count == 1 then
	
		self:BuildTrivialPath( bot, goal )
		return
		
	end
	
	-- assemble path
	self.m_segmentCount = count
	area = endArea
	while IsValid( area ) and count > 0 do
	
		self.m_path[ count ] = TBotPathSegment()
		self.m_path[ count ].area = area
		self.m_path[ count ].how = area:GetParentHow()
		self.m_path[ count ].type = TBotSegmentType.PATH_ON_GROUND
		
		area = area:GetParent()
		count = count - 1
		
	end
	
	-- append actual goal position
	self.m_segmentCount = self.m_segmentCount + 1
	self.m_path[ self.m_segmentCount ] = TBotPathSegment()
	self.m_path[ self.m_segmentCount ].area = endArea
	self.m_path[ self.m_segmentCount ].pos = goal
	self.m_path[ self.m_segmentCount ].how = NUM_TRAVERSE_TYPES
	self.m_path[ self.m_segmentCount ].type = TBotSegmentType.PATH_ON_GROUND
	
	--[[for k,v in ipairs( botTable.Path ) do
	
		if v.Area == startArea then
		
			print( "StartArea at " .. tostring( k ) )
		
		elseif v.Area == closestArea then
		
			print( "EndArea at " .. tostring( k ) )
			
		end
		
	end
	
	print( "SegmentCount: " .. tostring( botTable.SegmentCount ) )
	print( "Bot Path Length: " .. tostring( #botTable.Path ) )]]
	
	-- compute path positions
	if self:ComputeNavmeshVisibility( bot, start ) == false then
	
		self:Invalidate()
		self:OnPathChanged( bot, TBotOnPathChanged.NO_PATH )
		return
		
	end
	
	self:PostProcess()
	
	self:OnPathChanged( bot, TBotOnPathChanged.COMPLETE_PATH )
	
end