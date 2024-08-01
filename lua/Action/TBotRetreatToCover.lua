-- TBotRetreatToCover.lua
-- Purpose: This is the TBotRetreatToCover MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotRetreatToCoverMeta = {}

function TBotRetreatToCoverMeta:__index( key )

	-- Search the metatable.
	local val = TBotRetreatToCoverMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotRetreatToCover( hideDuration, actionToChangeToOnceCoverReached, maxRange )
	hideDuration = tonumber( hideDuration ) or -1.0
	maxRange = tonumber( maxRange ) or 1000
	local tbotretreattocover = TBotBaseAction()

	if actionToChangeToOnceCoverReached then
	
		hideDuration = -1.0
		
	end

	tbotretreattocover.m_path = TBotPathFollower()
	tbotretreattocover.m_repathTimer = util.Timer()
	tbotretreattocover.m_coverArea = nil
	tbotretreattocover.m_waitInCoverTimer = util.Timer()
	tbotretreattocover.m_hideDuration = hideDuration
	tbotretreattocover.m_maxRange = maxRange
	tbotretreattocover.m_actionToChangeToOnceCoverReached = actionToChangeToOnceCoverReached

	setmetatable( tbotretreattocover, TBotRetreatToCoverMeta )

	return tbotretreattocover

end

function TBotRetreatToCoverMeta:GetName()

	return "RetreatToCover"
	
end

function TBotRetreatToCoverMeta:InitialContainedAction( me )

	return nil

end

function TBotRetreatToCoverMeta:OnStart( me, priorAction )

	self.m_coverArea = self:FindCoverArea( me )
	
	if !IsValid( self.m_coverArea ) then
	
		return self:Done( "No cover available" )
		
	end
	
	if self.m_hideDuration < 0.0 then
	
		self.m_hideDuration = math.Rand( 1, 2 )
		
	end
	
	self.m_waitInCoverTimer:Start( self.m_hideDuration )

	return self:Continue()

end

function TBotRetreatToCoverMeta:Update( me, interval )

	local botTable = me:GetTable()
	local threat = me:GetTBotVision():GetPrimaryKnownThreat( true )
	
	if self:ShouldRetreat( me ) == TBotQueryResultType.ANSWER_NO then
	
		return self:Done( "No longer need to retreat" )
		
	end

	-- Attack while retreating
	if istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
	
		me:SelectBestWeapon( threat:GetEntity() )
		
	end
	
	-- Reload while moving to cover
	local isDoingAFullReload = false
	local botWeapon = me:GetActiveWeapon()
	if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsTBotRegisteredWeapon() then
	
		local weaponTable = GetTBotRegisteredWeapon( botWeapon:GetClass() )
		if weaponTable.ReloadsSingly and botWeapon:NeedsToReload() then
		
			if CurTime() >= botTable.ReloadInterval and !me:IsReloading() then

				me:PressReload()
				botTable.ReloadInterval = CurTime() + 0.5

			end
			isDoingAFullReload = true
			
		end
		
	end
	
	-- Move to cover, or stop if we've found opportunistic cover (no visible threats right now)
	if me:GetLastKnownArea() == self.m_coverArea or !threat then
	
		-- We are now in cover
		if threat then
		
			self.m_coverArea = self:FindCoverArea( me )
			
			if !IsValid( self.m_coverArea ) then
			
				return self:Done( "My cover is exposed, and there is no other cover available!" )
				
			end
			
		end
		
		if self.m_actionToChangeToOnceCoverReached then
		
			return self:ChangeTo( self.m_actionToChangeToOnceCoverReached, "Doing given action now that I'm in cover" )
			
		end
		
		-- Stay in cover while we fully reload
		if isDoingAFullReload then
		
			return self:Continue()
			
		end
		
		if self.m_waitInCoverTimer:Elapsed() then
		
			return self:Done( "Been in cover long enough" )
			
		end
		
	else
	
		-- Not in cover yet
		self.m_waitInCoverTimer:Start( self.m_hideDuration )
		
		if self.m_repathTimer:Elapsed() then
		
			self.m_repathTimer:Start( math.Rand( 0.3, 0.5 ) )
			
			self.m_path:Compute( me, self.m_coverArea:GetCenter() )
			
		end
		
		self.m_path:Update( me )
		
	end
	
	return self:Continue()

end

function TBotRetreatToCoverMeta:FindCoverArea( me )

	local search = {}
	local minExposureCount = 9999
	local knownEntities = me:GetTBotVision().m_knownEntityVector
	
	for k, area in ipairs( navmesh.Find( me:GetPos(), self.m_maxRange, me:GetStepSize(), 1000 ) ) do

		local m_exposedThreatCount = 0
		for _, known in ipairs( knownEntities ) do
		
			local threatArea = known:GetLastKnownArea()
			if IsValid( threatArea ) and me:IsEnemy( known:GetEntity() ) then
			
				if area:IsPotentiallyVisible( threatArea ) then
				
					m_exposedThreatCount = m_exposedThreatCount + 1
					
				end
				
			end
			
		end
		
		if m_exposedThreatCount <= minExposureCount then
		
			-- This area is at least as good as already found cover
			if m_exposedThreatCount < minExposureCount then
			
				-- This area is better than already found cover - throw out list and start over
				table.Empty( search )
				minExposureCount = m_exposedThreatCount
				
			end
			
			table.insert( search, area )
			
		end
		
	end
	
	if #search == 0 then
	
		return
		
	end
	
	-- Pick a random areas so bots don't pick the same spot every time! 
	-- They all have the same level of safety.
	return search[ math.random( #search ) ]

end

function TBotRetreatToCoverMeta:OnEnd( me, nextAction )

	return

end

function TBotRetreatToCoverMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotRetreatToCoverMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotRetreatToCoverMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotRetreatToCoverMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_YES

end

-- Is it time to retreat?
function TBotRetreatToCoverMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotRetreatToCoverMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotRetreatToCoverMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotRetreatToCoverMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotRetreatToCoverMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotRetreatToCoverMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end