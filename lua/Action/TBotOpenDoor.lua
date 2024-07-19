-- TBotOpenDoor.lua
-- Purpose: This is the TBotOpenDoor MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotOpenDoorMeta = {}

function TBotOpenDoorMeta:__index( key )

	-- Search the metatable.
	local val = TBotOpenDoorMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotOpenDoor( door )
	local tbotopendoor = TBotBaseAction()
	
	tbotopendoor.m_door = door

	setmetatable( tbotopendoor, TBotOpenDoorMeta )

	return tbotopendoor

end

function TBotOpenDoorMeta:GetName()

	return "OpenDoor"
	
end

function TBotOpenDoorMeta:InitialContainedAction( me )

	return nil

end

function TBotOpenDoorMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotOpenDoorMeta:Update( me, interval )

	local botTable = me:GetTable()
	if !IsValid( self.m_door ) then
	
		botTable.m_door = nil
		return self:Done( "Door is no longer valid" )
		
	end
	
	if !self.m_door:IsDoor() or self.m_door:IsDoorOpen() or self.m_door:NearestPoint( me:GetPos() ):DistToSqr( me:GetPos() ) > 10000 then 
		
		botTable.m_door = nil
		return self:Done( "Door is either not a door, is open, or too far away" )
		
	end
	
	me:GetTBotBody():AimHeadTowards( self.m_door:WorldSpaceCenter(), TBotLookAtPriority.MAXIMUM_PRIORITY, 0.5 )
	
	if CurTime() >= botTable.UseInterval and me:IsLookingAtPosition( self.m_door:WorldSpaceCenter() ) then
		
		me:PressUse()
		botTable.UseInterval = CurTime() + 0.5
		
		if self.m_door:IsDoorLocked() then
			
			botTable.m_door = nil
			return self:Done( "Door is locked and cannot be opened" )
			
		end
		
	end
	
	return self:Continue()

end

function TBotOpenDoorMeta:OnEnd( me, nextAction )

	return

end

function TBotOpenDoorMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotOpenDoorMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotOpenDoorMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotOpenDoorMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_YES

end

-- Is it time to retreat?
function TBotOpenDoorMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_NO

end

-- Should we attack "them"
function TBotOpenDoorMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_NO

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotOpenDoorMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotOpenDoorMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotOpenDoorMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotOpenDoorMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end