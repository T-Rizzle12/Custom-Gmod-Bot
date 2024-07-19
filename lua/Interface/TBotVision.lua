-- TBotVision.lua
-- Purpose: This is the TBotVision MetaTable
-- Author: T-Rizzle

local TBotVisionMeta = {}

TBotVisionMeta.__index = TBotVisionMeta

function TBotVision( bot )
	local tbotvision = {}

	-- NEEDTOVALIDATE: Do we need these?
	--tbotvision.m_curInterval = engine.TickInterval()
	--tbotvision.m_lastUpdateTime = 0
	tbotvision.m_bot = bot
	tbotvision.m_scanTimer = util.Timer() -- For throttling update rate as needed!
	tbotvision.m_blindTimer = util.Timer()
	tbotvision.m_knownEntityVector = {} -- The set of enemies and friends we are aware of
	tbotvision.m_lastVisionUpdateTimestamp = 0

	setmetatable( tbotvision, TBotVisionMeta )

	tbotvision:Reset()

	return tbotvision

end

function TBotVisionMeta:Reset()

	--self.m_curInterval = engine.TickInterval()
	--self.m_lastUpdateTime = 0
	self.m_blindTimer:Reset()
	table.Empty( self.m_knownEntityVector )
	self.m_lastVisionUpdateTimestamp = 0
	self.m_primaryThreat = nil
	
	self:SetFieldOfView( 75 )
	
end

function TBotVisionMeta:GetBot()

	return self.m_bot

end

function TBotVisionMeta:GetPrimaryKnownThreat( onlyVisibleThreats )
	onlyVisibleThreats = onlyVisibleThreats or false

	local bot = self:GetBot()
	if #self.m_knownEntityVector == 0 then
	
		return nil
		
	end
	
	local threat = nil
	local i = 1
	
	while i <= #self.m_knownEntityVector do
	
		local firstThreat = self.m_knownEntityVector[ i ]
		
		if self:IsAwareOf( firstThreat ) and !firstThreat:IsObsolete() and !self:IsIgnored( firstThreat:GetEntity() ) and bot:IsEnemy( firstThreat:GetEntity() ) then
		
			if !onlyVisibleThreats or firstThreat:IsVisibleRecently() then
			
				threat = firstThreat
				break
				
			end
			
		end
		
		i = i + 1
		
	end
	
	if !threat then
	
		self.m_primaryThreat = nil
		return nil
		
	end
	
	i = i + 1
	while i <= #self.m_knownEntityVector do
	
		local newThreat = self.m_knownEntityVector[ i ]
		
		if self:IsAwareOf( newThreat ) and !newThreat:IsObsolete() and !self:IsIgnored( newThreat:GetEntity() ) and bot:IsEnemy( newThreat:GetEntity() ) then
		
			if !onlyVisibleThreats or newThreat:IsVisibleRecently() then
			
				threat = bot:GetTBotBehavior():SelectMoreDangerousThreat( bot, threat, newThreat )
				
			end
			
		end
		
		i = i + 1
		
	end
	
	self.m_primaryThreat = threat and threat:GetEntity() or nil
	
	return threat
	
end

function TBotVisionMeta:GetKnown( entity )

	if !IsValid( entity ) then
	
		return nil
		
	end
	
	for k, known in ipairs( self.m_knownEntityVector ) do
	
		if IsValid( known:GetEntity() ) and known:GetEntity() == entity and !known:IsObsolete() then
		
			return known
			
		end
		
	end
	
end

function TBotVisionMeta:GetClosestKnown()

	local myPos = self:GetBot():GetPos()
	local target = nil
	local closeRange = math.huge
	
	for k, known in ipairs( self.m_knownEntityVector ) do
	
		if !known:IsObsolete() and self:IsAwareOf( known ) then
		
			local rangeSq = known:GetLastKnownPosition():DistToSqr( myPos )
			
			if rangeSq < closeRange then
			
				target = known
				closeRange = rangeSq
				
			end
			
		end
		
	end
	
	return target
	
end

function TBotVisionMeta:GetKnown( entity )

	if !IsValid( entity ) then
	
		return nil
		
	end
	
	for k, known in ipairs( self.m_knownEntityVector ) do
	
		if IsValid( known:GetEntity() ) and known:GetEntity() == entity and !known:IsObsolete() then
		
			return known
			
		end
		
	end
	
end

function TBotVisionMeta:AddKnownEntity( entity )

	if !IsValid( entity ) or entity:IsWorld() then
	
		return
		
	end
	
	local known = TBotKnownEntity( entity )
	for k, known2 in ipairs( self.m_knownEntityVector ) do
	
		if istbotknownentity( known2 ) and known == known2 then
		
			return known2
			
		end
		
	end
	
	table.insert( self.m_knownEntityVector, known )
	return known
	
end

function TBotVisionMeta:ForgetEntity( forgetMe )

	if !IsValid( forgetMe ) then
	
		return
		
	end
	
	for k, known in ipairs( self.m_knownEntityVector ) do
	
		if IsValid( known:GetEntity() ) and known:GetEntity() == forgetMe then
		
			table.remove( self.m_knownEntityVector, k )
			return
			
		end
		
	end
	
end

function TBotVisionMeta:ForgetAllKnownEntities()

	table.Empty( self.m_knownEntityVector )
	
end

function TBotVisionMeta:GetKnownCount( team, onlyVisible, rangeLimit )

	local count = 0
	
	local bot = self:GetBot()
	for k, known in ipairs( self.m_knownEntityVector ) do
	
		if !known:IsObsolete() and self:IsAwareOf( known ) and bot:IsEnemy( known:GetEntity() ) then
		
			if !isnumber( team ) or !known:GetEntity():IsPlayer() or known:GetEntity():Team() == team then
			
				if !onlyVisible or known:IsVisibleRecently() then
				
					if rangeLimit < 0.0 or ( known:GetLastKnownPosition() - bot:GetPos() ):IsLengthLessThan( rangeLimit ) then
					
						count = count + 1
						
					end
					
				end
				
			end
			
		end
		
	end
	
	return count
	
end

-- This is used by the vision interface to check if the bot should consider the entered entity!
function TBotVisionMeta:IsValidTarget( pit )

	local bot = self:GetBot()
	local botTable = bot:GetTable()
	if botTable.AttackList[ pit ] then 
	
		return true
		
	end
	
	if pit:IsNPC() and pit:IsAlive() then 
	
		return true
		
	end
	
	if pit:IsPlayer() and pit:Alive() then 
	
		return true
	
	end
	
	if pit:IsNextBot() and pit:Health() > 0 then
	
		return true
		
	end

	return false

end

-- FIXME: This is the most expensive code in the addon, there has to be a way to optimze this!
function TBotVisionMeta:UpdateKnownEntities()

	local visibleNow = {}
	local visibleNow2 = {}
	local knownEntities = {}
	local bot = self:GetBot()
	for k, pit in ents.Iterator() do
	
		if IsValid( pit ) and pit != bot and self:IsValidTarget( pit ) then 
		
			if !self:IsIgnored( pit ) and self:IsAbleToSee( pit, true ) then
				
				table.insert( visibleNow, pit )
				visibleNow2[ pit ] = true
				
			end
			
		end
		
	end
	
	local i = 1
	while i <= #self.m_knownEntityVector do
	
		local known = self.m_knownEntityVector[ i ]
	
		if !IsValid( known:GetEntity() ) or known:IsObsolete() then
		
			table.remove( self.m_knownEntityVector, i ) -- FIXME: This may be very expesive if used multiple times, since it reindexes the table after removal!
			continue
			
		end
		
		-- NOTE: I create a list of every entity already on the enemy list so we don't have loop again if we need to add something not on the list!
		knownEntities[ known:GetEntity() ] = true
		
		-- NOTE: Valve reiterates through the table to check IsAbleToSee.....
		-- I choose to create both a table and a list so I don't have to do that. :)
		if tobool( visibleNow2[ known:GetEntity() ] ) then
		
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			
			-- Has our reaction time just elapsed?
			if CurTime() - known:GetTimeWhenBecameVisible() >= self:GetMinRecognizeTime() and self.m_lastVisionUpdateTimestamp - known:GetTimeWhenBecameVisible() < self:GetMinRecognizeTime() then
			
				self:OnSight( known:GetEntity() )
				
			end
			
		else
		
			if known:IsVisibleInFOVNow() then
			
				known:UpdateVisibilityStatus( false )
				self:OnLostSight( known:GetEntity() )
				
			end
			
			if !known:HasLastKnownPositionBeenSeen() then
			
				if self:IsAbleToSee( known:GetLastKnownPosition(), true ) then
				
					known:MarkLastKnownPositionAsSeen()
					
				end
				
			end
			
		end
		
		i = i + 1
		
	end
	
	for k, visibleEntity in ipairs( visibleNow ) do
	
		--[[local j = 1
		while j <= #botTable.EnemyList do
		
			if visibleNow[ i ] == botTable.EnemyList[ j ]:GetEntity() then
			
				break
				
			end
			
			j = j + 1
			
		end
		
		if j > #botTable.EnemyList then
		
			local known = TBotKnownEntity( visibleNow[ i ] )
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			table.insert( botTable.EnemyList, known )
			
		end]]
		
		-- NOTE: This is WAY faster than the code above since we don't have to iterate throught the entire known enemy list more than once!
		if !tobool( knownEntities[ visibleEntity ] ) then
		
			local known = TBotKnownEntity( visibleEntity )
			known:UpdatePosition()
			known:UpdateVisibilityStatus( true )
			table.insert( self.m_knownEntityVector, known )
			
		end
		
	end
	
end

function TBotVisionMeta:Update()

	-- This adds significantly to bot's reaction times
	--[[if !self.m_scanTimer:Elapsed() then
	
		return
		
	end
	
	self.m_scanTimer:Start( 0.5 * self:GetMinRecognizeTime() )]]
	
	if GetConVar( "ai_ignoreplayers" ):GetBool() or GetConVar( "ai_disabled" ):GetBool() then
	
		table.Empty( self.m_knownEntityVector )
		return
		
	end
	
	self:UpdateKnownEntities()
	
	self.m_lastVisionUpdateTimestamp = CurTime()
	
end

-- Returns true if the bot's reaction time has elapsed
-- for the entered TBotKnownEntity
function TBotVisionMeta:IsAwareOf( known )

	return known:GetTimeSinceBecameKnown() >= self:GetMinRecognizeTime()
	
end

function TBotVisionMeta:IsVisibleEntityNoticed( subject )

	local bot = self:GetBot()
	if IsValid( subject ) and bot:IsEnemy( subject ) then
	
		return true
		
	end

	return true

end

function TBotVisionMeta:IsIgnored( subject )
	if !IsValid( subject ) then return true end

	if !self:GetBot():IsEnemy( subject ) then
	
		-- don't ignore our friends
		return false
		
	end
	
	-- This entity was set not to render so we can't see it!
	if subject:GetNoDraw() then
	
		return true
		
	end
	
	return false
	
end

-- Returns the minimum amount of time before 
-- the bot can react to seeing an enemy
-- NOTE: This can be used to make bots react faster or slower to certain things
function TBotVisionMeta:GetMinRecognizeTime()

	return 0.2
	
	-- This is an example of different levels of reaction times
	-- I could also make this skill dependent....
	--[[if "Expert" then
	
		return 0.2
		
	elseif "Hard" then
	
		return 0.3
	
	elseif "Normal" then
	
		return 0.5
		
	elseif "Easy" then
	
		return 1.0
	
	end]]
	
end

-- Called when the bot sees another entity
-- NOTE: Can be used to make the bot react upon seeing an enemy
-- NOTE2: This is only called after the bot's reaction time has finished
function TBotVisionMeta:OnSight( seen )

	-- We call a hook so that the Action system can respond to these events as well!
	hook.Run( "TBotOnSight", self:GetBot(), seen )

	-- We do nothing here in sandbox
	return
	
end

-- Called when the bot looses sight of another entity
-- NOTE: Can be used to make the bot react losing sight of an enemy
function TBotVisionMeta:OnLostSight( seen )

	-- We call a hook so that the Action system can respond to these events as well!
	hook.Run( "TBotOnLostSight", self:GetBot(), seen )

	-- We do nothing here in sandbox
	return
	
end

function TBotVisionMeta:SetFieldOfView( horizAngle )

	self.m_FOV = horizAngle
	self.m_cosHalfFOV = math.cos( 0.5 * horizAngle * math.pi / 180 )
	
end

function TBotVisionMeta:IsInFieldOfView( pos )

	local bot = self:GetBot()
	if IsValid( pos ) and IsEntity( pos ) then
	
		if self:PointWithinViewAngle( bot:GetShootPos(), pos:WorldSpaceCenter(), bot:GetAimVector(), self.m_cosHalfFOV ) then
		
			return true
			
		end
		
		return self:PointWithinViewAngle( bot:GetShootPos(), pos:EyePos(), bot:GetAimVector(), self.m_cosHalfFOV )
		
	elseif isvector( pos ) then
	
		return self:PointWithinViewAngle( bot:GetShootPos(), pos, bot:GetAimVector(), self.m_cosHalfFOV )
		
	end
	
	return false
	
end

function TBotVisionMeta:PointWithinViewAngle( pos, targetpos, lookdir, fov )
	
	local to = targetpos - pos
	local diff = lookdir:Dot( to )
	
	if diff < 0 then return false end
	
	local length = to:LengthSqr()
	
	return diff * diff > length * fov * fov
	
end

function TBotVisionMeta:IsLookingAtPosition( pos, angleTolerance )
	angleTolerance = angleTolerance or 20
	
	local idealAngles = ( pos - self:GetShootPos() ):Angle()
	local viewAngles = self:EyeAngles()
	
	local deltaYaw = math.AngleNormalize( idealAngles.y - viewAngles.y )
	local deltaPitch = math.AngleNormalize( idealAngles.x - viewAngles.x )
	
	if math.abs( deltaYaw ) < angleTolerance and math.abs( deltaPitch ) < angleTolerance then
	
		return true
		
	end
	
	return false
	
end

-- Checks if the current position or entity can be seen by the target entity
function TBotVisionMeta:IsLineOfSightClear( pos )
	
	local bot = self:GetBot()
	if IsValid( pos ) and IsEntity( pos ) then
		
		local trace = {}
		util.TraceLine( { start = bot:EyePos(), endpos = pos:WorldSpaceCenter(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
	
		if trace.Fraction >= 1.0 or trace.Entity == pos or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true

		end
		
		util.TraceLine( { start = bot:EyePos(), endpos = pos:EyePos(), filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
	
		if trace.Fraction >= 1.0 or trace.Entity == pos or ( pos:IsPlayer() and trace.Entity == pos:GetVehicle() ) then
			
			return true
			
		end
		
	elseif isvector( pos ) then
		
		local trace = {}
		util.TraceLine( { start = bot:EyePos(), endpos = pos, filter = TBotTraceFilter, mask = MASK_VISIBLE_AND_NPCS, output = trace } )
		
		return trace.Fraction >= 1.0
		
	end
	
	return false
	
end

-- This checks if the entered position in the bot's LOS
function TBotVisionMeta:IsAbleToSee( pos, checkFOV )
	if self:IsBlind() then return false end

	local bot = self:GetBot()
	local botPos = bot:GetPos()
	if IsValid( pos ) and IsEntity( pos ) then
		-- we must check eyepos and worldspacecenter
		-- maybe in the future I can use body parts instead
		-- NOTE: Valve TF2 Bots seem to only use eyepos and worldspacecenter
		
		-- TODO: I should make the bot use IsPotentiallyVisible as this could save a lot of resources
		-- NOTE: I need a way to check the maximum computed distance to prevent false negatives
		--[[ Example:
		local myArea = self:GetLastKnownArea()
		local subjectArea = pos:GetLastKnownArea()
		if IsValid( myArea ) and IsValid( subjectArea ) then
			
			if myArea:IsPotentiallyVisible( subjectArea ) then
				
				return false
				
			end
			
		end]]
		
		if ( pos:GetPos() - bot:GetPos() ):IsLengthGreaterThan( 6000 ) then
		
			return false
			
		end
		
		if bot:IsHiddenByFog( bot:GetShootPos():Distance( pos:WorldSpaceCenter() ) ) then
		
			return false
			
		end
		
		if checkFOV and !self:IsInFieldOfView( pos ) then
			
			return false
			
		end
		
		if !self:IsLineOfSightClear( pos ) then
		
			return false
			
		end
		
		return self:IsVisibleEntityNoticed( pos )

	elseif isvector( pos ) then
		
		if ( pos - bot:GetPos() ):IsLengthGreaterThan( 6000 ) then
		
			return false
			
		end
		
		if bot:IsHiddenByFog( bot:GetShootPos():Distance( pos ) ) then
		
			return false
			
		end
		
		if checkFOV and !self:IsInFieldOfView( pos ) then
		
			return false
			
		end
		
		return self:IsLineOfSightClear( pos )
		
	end
	
	return false
end

-- Blinds the bot for a specified amount of time
function TBotVisionMeta:Blind( time, flingAim )
	
	local bot = self:GetBot()
	if !bot:Alive() or !bot:IsTRizzleBot() or time < ( self.m_blindTimer.endtime - CurTime() ) then 
	
		return 
		
	end
	
	self.m_blindTimer:Start( time )
	
	-- FIXME: Remake this after I implement the body interface!!!!
	if flingAim then
	
		bot:GetTBotBody():AimHeadTowards( bot:GetShootPos() + 1000 * Angle( math.random( -30, 30 ), math.random( -180, 180 ), 0 ):Forward(), TBotLookAtPriority.MAXIMUM_PRIORITY, 0.1 ) -- Make the bot fling its aim in a random direction upon becoming blind
	
	end

end

-- Is the bot currently blind?
function TBotVisionMeta:IsBlind()

	local bot = self:GetBot()
	if !bot:Alive() or !bot:IsTRizzleBot() then 
	
		return false 
		
	end
	
	return !self.m_blindTimer:Elapsed()
	
end