-- TBotDead.lua
-- Purpose: This is the TBotDead MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotDeadMeta = {}

TBotDeadMeta.__index = setmetatable( TBotDeadMeta, BaseClass )

function TBotDead()
	local tbotdead = TBotBaseAction()

	-- HACKHACK: We create our own IntervalTimer here, I should probably create a pull request and have this added to the base game.
	local deadTimer = {}
	deadTimer.m_timestamp = -1.0
	deadTimer.Reset = function( self ) self.m_timestamp = CurTime() end
	deadTimer.Start = function( self ) self.m_timestamp = CurTime() end
	deadTimer.Invalidate = function( self ) self.m_timestamp = -1.0 end
	deadTimer.HasStarted = function( self ) return self.m_timestamp > 0 end
	deadTimer.GetElapsedTime = function( self ) return Either( self:HasStarted(), CurTime() - self.m_timestamp, 99999.9 ) end
	deadTimer.IsLessThen = function( self, duration ) return CurTime() - self.m_timestamp < duration end
	deadTimer.IsGreaterThen = function( self, duration ) return CurTime() - self.m_timestamp > duration end
	
	tbotdead.m_deadTimer = deadTimer

	setmetatable( tbotdead, TBotDeadMeta )

	return tbotdead

end

function TBotDeadMeta:GetName()

	return "Dead"
	
end

function TBotDeadMeta:InitialContainedAction( me )

	return nil

end

function TBotDeadMeta:OnStart( me, priorAction )

	self.m_deadTimer:Start()

	return self:Continue()

end

function TBotDeadMeta:Update( me, interval )

	local botTable = me:GetTable()
	if me:Alive() then
	
		-- How did this happen?
		return self:ChangeTo( TBotMainAction(), "This should not happen!" )
		
	end
	
	local nextSpawnTime = CurTime() - ( tonumber( botTable.NextSpawnTime ) or CurTime() )
	local nextSpawnConVar = GetConVar( "TBotSpawnTime" ):GetFloat()
	
	if self.m_deadTimer:IsGreaterThen( nextSpawnTime ) then
	
		-- Just incase something stops the bot from respawning, I force them to respawn anyway
		if self.m_deadTimer:IsGreaterThen( nextSpawnConVar + 60.0 ) then
		
			me:Spawn()
		
		-- I have to manually call the death think hook, or the bot won't respawn
		elseif self.m_deadTimer:IsGreaterThen( nextSpawnConVar ) then
		
			me:PressPrimaryAttack()
			hook.Run( "PlayerDeathThink", me )
			
		end
		
	end
	
	return self:Continue()

end

function TBotDeadMeta:OnEnd( me, nextAction )

	return

end

function TBotDeadMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotDeadMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotDeadMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotDeadMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotDeadMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotDeadMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotDeadMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotDeadMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotDeadMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotDeadMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end