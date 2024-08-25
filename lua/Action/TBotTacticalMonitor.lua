-- TBotTacticalMonitor.lua
-- Purpose: This is the TBotTacticalMonitor MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotTacticalMonitorMeta = {}

function TBotTacticalMonitorMeta:__index( key )

	-- Search the metatable.
	local val = TBotTacticalMonitorMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotTacticalMonitor()
	local tbottacticalmonitor = TBotBaseAction()

	tbottacticalmonitor.m_maintainTimer = util.Timer()

	setmetatable( tbottacticalmonitor, TBotTacticalMonitorMeta )

	return tbottacticalmonitor

end

function TBotTacticalMonitorMeta:GetName()

	return "TaticalMonitor"
	
end

function TBotTacticalMonitorMeta:InitialContainedAction( me )

	return TBotScenarioMonitor()

end

function TBotTacticalMonitorMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotTacticalMonitorMeta:Update( me, interval )

	local botTable = me:GetTable()
	local shouldRetreat = me:GetTBotBehavior():ShouldRetreat( me )
	if shouldRetreat == TBotQueryResultType.ANSWER_YES then
	
		return self:SuspendFor( TBotRetreatToCover(), "Backing off" )
		
	elseif shouldRetreat != TBotQueryResultType.ANSWER_NO then
	
		local botWeapon = me:GetActiveWeapon()
		local threat = me:GetTBotVision():GetPrimaryKnownThreat( true )
		if IsValid( botWeapon ) and botWeapon:IsWeapon() and botWeapon:IsPrimaryClipEmpty() and istbotknownentity( threat ) and IsValid( threat:GetEntity() ) then
		
			return self:SuspendFor( TBotReloadInCover( 1000 ), "Moving to cover to reload" ) -- Used to be botTable.FollowDist, but it caused issues if the follow dist was small.....
			
		end
		
	end
	
	local isAvailable = me:GetTBotBehavior():ShouldHurry( me ) != TBotQueryResultType.ANSWER_YES
	
	-- Take cover and heal ourselves if our health is low, unless we're in a big hurry
	if isAvailable and self.m_maintainTimer:Elapsed() then
	
		self.m_maintainTimer:Start( math.Rand( 0.3, 0.5 ) )
		
		local isHurt = me:Health() < botTable.CombatHealThreshold
		if isHurt then
		
			return self:SuspendFor( TBotRetreatToCover( -1.0, TBotHealPlayer( me ), 1000 ), "Moving to cover to heal" ) -- Used to be botTable.FollowDist, but it caused issues if the follow dist was small.....
			
		end
		
	end

	return self:Continue()

end

function TBotTacticalMonitorMeta:OnEnd( me, nextAction )

	return

end

function TBotTacticalMonitorMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotTacticalMonitorMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotTacticalMonitorMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotTacticalMonitorMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotTacticalMonitorMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotTacticalMonitorMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotTacticalMonitorMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotTacticalMonitorMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotTacticalMonitorMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotTacticalMonitorMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end