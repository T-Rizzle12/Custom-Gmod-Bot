-- TBotRetreatPath.lua
-- Purpose: This is the TBotRetreatPath MetaTable
-- Author: T-Rizzle

local BaseClass = FindMetaTable( "TBotPathFollower" )
local BaseClass2 = FindMetaTable( "TBotPath" )

local TBotRetreatPathMeta = {}

function TBotRetreatPathMeta:__index( key )

	-- Search the metatable.
	local val = TBotRetreatPathMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	-- Search the base base class.
	val = BaseClass2[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotRetreatPath()
	local tbotretreatpath = TBotPathFollower() -- HACKHACK: We have to create a path object in order for it to have the stuff intialized....
	
	tbotretreatpath.m_throttleTimer = util.Timer()
	tbotretreatpath.m_throttleTimer:Reset()
	tbotretreatpath.m_pathThreat = nil
	tbotretreatpath.m_pathThreatPos = Vector()
	
	setmetatable( tbotretreatpath, TBotRetreatPathMeta )
	
	return tbotretreatpath

end

function TBotRetreatPathMeta:GetMaxPathLength()

	return 1000.0
	
end

function TBotRetreatPathMeta:Invalidate()

	-- Path is gone, repath at earliest opportunity
	self.m_throttleTimer:Reset()
	self.m_pathThreat = nil
	
	-- Extend
	BaseClass.Invalidate( self )
	
end

-- Make the bot move.
function TBotRetreatPathMeta:Update( bot, threat, cost )
	
	if !IsValid( threat ) then
	
		return
		
	end
	
	-- If our path threat changed, repath immediately
	if threat != self.m_pathThreat then
	
		self:Invalidate()
		
	end
	
	-- Maintain path away from the threat
	self:RefreshPath( bot, threat, cost )
	
	-- Move along the path towards the threat
	BaseClass.Update( self, bot )
	
end

function TBotRetreatPathMeta:RefreshPath( bot, threat, cost )

	local botTable = bot:GetTable()
	local mover = bot:GetTBotLocomotion()
	if !IsValid( threat ) then
	
		return
		
	end
	
	-- Don't change our path if we're on a ladder
	if self:IsValid() and IsValid( bot ) and mover:IsUsingLadder() then
	
		return
		
	end
	
	local to = threat:GetPos() - bot:GetPos()
	
	local minTolerance = 0.0
	local toleranceRate = 0.33
	
	local tolerance = minTolerance + toleranceRate * to:Length()
	
	if !self:IsValid() or ( threat:GetPos() - self.m_pathThreatPos ):IsLengthGreaterThan( tolerance ) then
	
		if !self.m_throttleTimer:Elapsed() then
		
			-- Require a minimum time between repaths, as long as we have a path to follow
			return
			
		end
		
		-- Remember our path threat
		self.m_pathThreat = threat
		self.m_pathThreatPos = threat:GetPos()
		self:Invalidate() -- Clear the old path!
		
		local retreat = RetreatPathBuilder( bot, threat, self:GetMaxPathLength(), cost )
		
		local goalArea = retreat:ComputePath()
		
		if IsValid( goalArea ) then
		
			self:AssemblePrecomputedPath( bot, goalArea:GetCenter(), goalArea )
		
		else
		
			-- All adjacent areas are too far away - just move directly away from threat
			local to = threat:GetPos() - bot:GetPos()
		
			self:BuildTrivialPath( bot, bot:GetPos() - to )
		
		end
		
		self.m_throttleTimer:Start( 0.5 )
		
	end

end

local function TRizzleBotRangeCheckRetreat( info, area, fromArea, ladder, portal )
	
	local maxThreatRange = 500.0
	local dangerDensity = 1000.0
	
	local cost = 0.0
	if area:IsBlocked() then
	
		return -1.0
		
	end
	
	if !IsValid( fromArea ) then
	
		cost = 0.0
	
		if area:Contains( info.m_threat:GetPos() ) then
			
			cost = cost + ( dangerDensity * 10 )
			
		else
			
			local rangeToThreat = info.m_threat:GetPos():Distance( info.m_me:GetPos() )

			if rangeToThreat < maxThreatRange then
				
				cost = cost + ( dangerDensity * ( 1.0 - ( rangeToThreat / maxThreatRange ) ) )
				
			end
			
		end
	
		-- first area in path, only cost is danger
		return cost
		
	elseif fromArea:HasAttributes( NAV_MESH_JUMP ) and area:HasAttributes( NAV_MESH_JUMP ) then
	
		-- cannot actually walk in jump areas - disallow moving from jump area to jump area
		return -1.0
	
	else
	
		-- compute distance traveled along path so far
		local dist = 0
		
		if IsValid( ladder ) then 
		
			dist = ladder:GetLength()
			
		else
		
			dist = area:GetCenter():Distance( fromArea:GetCenter() )
			
		end
		
		-- If the portal is disabled then we can't use it!
		if IsValid( portal ) and portal:GetInternalVariable( "m_bDisabled" ) then
		
			return -1.0
			
		end
		
		local Height = fromArea:ComputeAdjacentConnectionHeightChange( area )
		local stepHeight = info.m_me:GetStepSize()
		
		-- Jumping is slower than ground movement.
		if !IsValid( ladder ) and !IsValid( portal ) and !fromArea:IsUnderwater() and Height > stepHeight then
			
			local maximumJumpHeight = info.m_me:GetTBotLocomotion():GetMaxJumpHeight()
			
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
			
			if fallDamage > 0.0 then
			
				-- if the fall would kill us, don't use it
				local deathFallMargin = 10.0
				if fallDamage + deathFallMargin >= info.m_me:Health() then
				
					return -1.0
					
				end
				
				local painTolerance = 25.0
				if info.m_me:IsUnhealthy() or fallDamage > painTolerance then
				
					-- cost is proportional to how much it hurts when we fall
					-- 10 points - not a big deal, 50 points - ouch
					dist	=	dist + ( 100 * fallDamage * fallDamage )
					
				end
			
			end
			
		end
		
		-- Crawling through a vent is very slow.
		-- NOTE: The cost is determined by the bot's crouch speed
		if area:HasAttributes( NAV_MESH_CROUCH ) then 
			
			local crouchPenalty = math.floor( 1 / info.m_me:GetCrouchedWalkSpeed() )
			
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
		
		cost = dist + fromArea:GetTotalCost()
		
		-- Add in danger cost due to threat
		-- Assume straight line between areas and find closest point
		-- to the threat along that line segment. The distance between
		-- the threat and closest point on the line is the danger cost.	
		
		-- path danger is CUMULATIVE
		local dangerCost = fromArea:GetCostSoFar()
		
		local t, Close = CalcClosestPointOnLineSegment( info.m_threat:GetPos(), area:GetCenter(), fromArea:GetCenter() )
		if t < 0.0 then
			
			Close = area:GetCenter()
			
		elseif t > 1.0 then
			
			Close = fromArea:GetCenter()
			
		end
		
		local rangeToThreat = info.m_threat:GetPos():Distance( Close ) -- Would it be better to compare distsqr instead?
		if rangeToThreat < maxThreatRange then
			
			local dangerFactor = 1.0 - ( rangeToThreat / maxThreatRange )
			dangerCost	=	dangerDensity * dangerFactor
			
		end
		
		--print( "Distance: " .. dist )
		--print( "Cost: " .. cost )
		
		return cost + dangerCost
		
	end
	
end

-- Build a path away from retreatFromArea up to retreatRange in length
local RetreatPathBuilderMeta = {}

RetreatPathBuilderMeta.__index = RetreatPathBuilderMeta

function RetreatPathBuilder( me, threat, retreatRange, costFunc )
	local retreatpathbuilder = {}
	
	retreatpathbuilder.m_me = me
	retreatpathbuilder.m_threat = threat
	retreatpathbuilder.m_retreatRange = retreatRange
	retreatpathbuilder.m_costFunc = costFunc or TRizzleBotRangeCheckRetreat
	
	setmetatable( retreatpathbuilder, RetreatPathBuilderMeta )
	
	return retreatpathbuilder
	
end

function RetreatPathBuilderMeta:ComputePath()

	local NORTH = 0
	local EAST = 1
	local SOUTH = 2
	local WEST = 3
	
	local LADDER_UP = 0
	local LADDER_DOWN = 1

	local GO_LADDER_UP = 4
	local GO_LADDER_DOWN = 5
	local GO_THROUGH_PORTAL = 6

	local startArea = self.m_me:GetLastKnownArea()
	if !IsValid( startArea ) then
	
		return
		
	end
	
	local retreatFromArea = navmesh.GetNearestNavArea( self.m_threat:GetPos() )
	if !IsValid( retreatFromArea ) then
	
		return
		
	end
	
	startArea:SetParent( nil, 9 )
	
	startArea:ClearSearchLists()
	
	local initCost = self.m_costFunc( self, startArea )
	if initCost < 0.0 then
	
		return false
		
	end
	
	startArea:SetTotalCost( initCost )
	
	startArea:AddToOpenList()
	
	-- Keep track of farthest away from the threat
	local farthestArea = nil
	local farthestRange = 0.0
	
	--
	-- Dijkstra's algorithm (since we don't know our goal).
	-- Build a path as far away from the retreat area as possible.
	-- Minimize total path length and danger.
	-- Maximize distance to threat of end of path.
	--
	while !startArea:IsOpenListEmpty() do
	
		local area = startArea:PopOpenList()
		
		area:AddToClosedList()
		
		--- don't consider blocked areas
		if area:IsBlocked() then
		
			continue
			
		end
		
		local adjacentAreas = {}
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( NORTH ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = NORTH, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( SOUTH ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = SOUTH, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( WEST ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = WEST, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetAdjacentAreasAtSide( EAST ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			table.insert( adjacentAreas, { area = it, how = EAST, ladder = nil } )
			
		end
		
		for k, it in ipairs( area:GetLaddersAtSide( LADDER_UP ) ) do
		
			local index = #adjacentAreas
			if IsValid( it:GetTopForwardArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopForwardArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
			if IsValid( it:GetTopLeftArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopLeftArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
			if IsValid( it:GetTopRightArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopRightArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
			if IsValid( it:GetTopBehindArea() ) and index < 64 then
			
				table.insert( adjacentAreas, { area = it:GetTopBehindArea(), how = GO_LADDER_UP, ladder = it } )
				
			end
			
		end
		
		for k, it in ipairs( area:GetLaddersAtSide( LADDER_DOWN ) ) do
		
			local index = #adjacentAreas
			if index >= 64 then
			
				break
				
			end
			
			if IsValid( it:GetBottomArea() ) then
			
				table.insert( adjacentAreas, { area = it:GetBottomArea(), how = GO_LADDER_DOWN, ladder = it } )
				
			end
			
		end
		
		for k, portalList in ipairs( area:GetPortals() ) do
		
			local index = #adjacentAreas 
			if index >= 64 then

				break
				
			end
			
			if IsValid( portalList.destination_cnavarea ) and IsValid( portalList.portal ) then
			
				table.insert( adjacentAreas, { area = portalList.destination_cnavarea, how = GO_THROUGH_PORTAL, portal = portalList.portal } )
			
			end
			
		end
		
		for i = 1, #adjacentAreas do
		
			local newArea = adjacentAreas[ i ].area
		
			-- only visit each area once
			if newArea:IsClosed() then
			
				continue
				
			end
			
			-- don't consider blocked areas
			if newArea:IsBlocked() then
			
				continue
				
			end
			
			-- don't use this area if it is out of range
			if ( newArea:GetCenter() - self.m_me:GetPos() ):IsLengthGreaterThan( self.m_retreatRange ) then
			
				continue
				
			end
			
			-- determine cost of traversing this area
			local newCost = self.m_costFunc( self, newArea, area, adjacentAreas[ i ].ladder, adjacentAreas[ i ].portal )
			
			-- don't use adjacent area if cost functor says it is a dead end
			if newCost < 0.0 then
			
				continue
				
			end
			
			if newArea:IsOpen() and newArea:GetTotalCost() <= newCost then
			
				-- we have already visited this area, and it has a better path
				continue
				
			else
			
				-- whether this area has been visited ot not, we now have a better path
				newArea:SetParent( area, adjacentAreas[ i ].how )
				newArea:SetTotalCost( newCost )
				
				-- use 'cost so far' to hold cumulative cost
				newArea:SetCostSoFar( newCost )
				
				-- tricky bit here - relying on OpenList being sorted by cost
				if newArea:IsOpen() then
				
					-- area already on open list, update the list to keep costs sorted
					newArea:UpdateOnOpenList()
					
				else
				
					newArea:AddToOpenList()
					
				end
				
				-- keep track of area farthest from threat
				local threatRange = newArea:GetCenter():Distance( self.m_threat:GetPos() )
				if threatRange > farthestRange then
				
					farthestArea = newArea
					farthestRange = threatRange
					
				end
				
			end
			
		end
		
	end
	
	return farthestArea

end