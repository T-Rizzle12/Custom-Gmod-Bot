-- TBotRevivePlayer.lua
-- Purpose: This is the TBotRevivePlayer MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotRevivePlayerMeta = {}

function TBotRevivePlayerMeta:__index( key )

	-- Search the metatable.
	local val = TBotRevivePlayerMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotRevivePlayer( reviveTarget )
	local tbotreviveplayer = TBotBaseAction()

	tbotreviveplayer.m_reviveTarget = reviveTarget
	tbotreviveplayer.m_chasePath = TBotChasePath()

	setmetatable( tbotreviveplayer, TBotRevivePlayerMeta )

	return tbotreviveplayer

end

function TBotRevivePlayerMeta:GetName()

	return "RevivePlayer"
	
end

function TBotRevivePlayerMeta:InitialContainedAction( me )

	return nil

end

function TBotRevivePlayerMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotRevivePlayerMeta:Update( me, interval )

	local botTable = me:GetTable()
	self.m_reviveTarget = self:FindReviveTarget( me ) -- Make sure we pick the closest player to revive!
	if !IsValid( self.m_reviveTarget ) or !self.m_reviveTarget:Alive() then
	
		return self:Done( "Our revive target is invalid or dead" )
		
	end
	
	if me:GetTBotVision():GetKnownCount( nil, false, botTable.DangerDist ) > 5 then
	
		return self:Done( "There are too many enemies nearby, we should kill them first" )
		
	end
	
	if !self.m_reviveTarget:IsDowned() then
	
		return self:Done( "We have sucessfully revived the target player" )
		
	end
	
	-- Move closer to our revive target before attempting to revive them!
	local reviveTargetDist = me:GetPos():DistToSqr( self.m_reviveTarget:GetPos() )
	if reviveTargetDist > 75^2 or !me:IsLineOfFireClear( self.m_reviveTarget ) then
	
		self.m_chasePath:Update( me, self.m_reviveTarget ) -- Repathing is handled in chase path!
		
	else
		
		me:GetTBotBody():AimHeadTowards( self.m_reviveTarget:GetPos(), TBotLookAtPriority.MAXIMUM_PRIORITY, 1.0 )
		
		if me:IsLookingAtPosition( self.m_reviveTarget:GetPos() ) then
		
			me:PressUse()
			
		end
		
	end
	
	return self:Continue()

end

function TBotRevivePlayerMeta:FindReviveTarget( me )
	if !isfunction( me.IsDowned ) or me:IsDowned() then return end -- This shouldn't run if the revive mod isn't installed or the bot is downed.
	
	local targetdistsqr			=	math.huge -- This will allow the bot to select the closest teammate to it.
	local target				=	nil -- This is the closest teammate to the bot.
	local botTable				=	me:GetTable()
	
	--The bot should revive its owner before it revives anyone else
	local tbotOwner = botTable.TBotOwner
	if IsValid( tbotOwner ) and tbotOwner:Alive() and tbotOwner:IsDowned() then return tbotOwner end

	for k, ply in player.Iterator() do
	
		if IsValid( ply ) and ply != me and ply:Alive() and !me:IsEnemy( ply ) and ply:IsDowned() then -- The bot will revive any teammate than need to be revived.
			
			local teammatedistsqr = ply:GetPos():DistToSqr( me:GetPos() )
			
			if teammatedistsqr < targetdistsqr then 
				target = ply
				targetdist = teammatedist
			end
			
		end
		
	end
	
	return target
	
end

function TBotRevivePlayerMeta:OnEnd( me, nextAction )

	return

end

function TBotRevivePlayerMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotRevivePlayerMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotRevivePlayerMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotRevivePlayerMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_YES

end

-- Is it time to retreat?
function TBotRevivePlayerMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_NO

end

-- Should we attack "them"
function TBotRevivePlayerMeta:ShouldAttack( me, them )

	-- Only attack if we are not currently near our revive target!
	if me:GetPos():DistToSqr( self.m_reviveTarget:GetPos() ) >= 80^2 then
	
		return TBotQueryResultType.ANSWER_YES
		
	end

	return TBotQueryResultType.ANSWER_NO

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotRevivePlayerMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotRevivePlayerMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotRevivePlayerMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotRevivePlayerMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end