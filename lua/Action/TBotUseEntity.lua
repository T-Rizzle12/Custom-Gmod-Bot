-- TBotUseEntity.lua
-- Purpose: This is the TBotUseEntity MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotUseEntityMeta = {}

function TBotUseEntityMeta:__index( key )

	-- Search the metatable.
	local val = TBotUseEntityMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotUseEntity( useEnt, holdTime )
	holdTime = tonumber( holdTime ) or 0.1
	local tbotuseentity = TBotBaseAction()

	tbotuseentity.m_path = TBotPathFollower()
	tbotuseentity.m_repathTimer = util.Timer()
	tbotuseentity.m_useEnt = useEnt
	tbotuseentity.m_startedUse = false
	tbotuseentity.m_holdTime = holdTime
	tbotuseentity.m_holdTimer = util.Timer()

	setmetatable( tbotuseentity, TBotUseEntityMeta )

	return tbotuseentity

end

function TBotUseEntityMeta:GetName()

	return "UseEntity"
	
end

function TBotUseEntityMeta:InitialContainedAction( me )

	return nil

end

function TBotUseEntityMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotUseEntityMeta:Update( me, interval )

	local botTable = me:GetTable()
	if !IsValid( self.m_useEnt ) then
	
		return self:Done( "Target entity was invalid" )
		
	end
	
	if self.m_startedUse and self.m_holdTimer:Elapsed() then
	
		return self:Done( "We have finished using the target entity" )
		
	end
	
	local useEnt = me:GetUseEntity()
	if useEnt != self.m_useEnt then
	
		if self.m_repathTimer:Elapsed() then
		
			self.m_repathTimer:Start( math.Rand( 3.0, 5.0 ) )
			
			self.m_path:Compute( me, self.m_useEnt:GetPos() )
			
		end
		
		self.m_path:Update( me )
	
	else
	
		me:PressUse()
	
		if !self.m_startedUse then
		
			self.m_startedUse = true
			self.m_holdTimer:Start( self.m_holdTime )
			
		end
	
	end
	
	if self.m_useEnt:GetPos():DistToSqr( me:GetPos() ) <= 200^2 and me:GetTBotVision():IsAbleToSee( self.m_useEnt ) then
		
		me:GetTBotBody():AimHeadTowards( self.m_useEnt:WorldSpaceCenter(), TBotLookAtPriority.HIGH_PRIORITY, 0.1 )
		
	end
	
	return self:Continue()

end

function TBotUseEntityMeta:PlayerSay( me, sender, text, teamChat )
	if !IsValid( sender ) then return self:TryContinue() end

	-- HACKHACK: PlayerCanSeePlayersChat is called after PlayerSay, so we call it to check if the bot can see the chat message.
	-- NEEDTOVALIDATE: Would it be better if I used the PlayerCanSeePlayersChat hook instead?
	if hook.Run( "PlayerCanSeePlayersChat", text, teamChat, me, sender ) then

		local botTable = me:GetTable()
		local startpos, endpos, botName = string.find( text, me:Nick() )
		local textTable
		local command

		if isnumber( startpos ) and startpos == 1 then -- Only run the command if the bot name was said first!

			textTable = string.Explode( " ", string.sub( text, endpos + 1 ) ) -- Grab everything else after the name!
			table.remove( textTable, 1 ) -- Remove the unnecessary whitespace
			command = textTable[ 1 ]:lower()

		else

			startpos, endpos, botName = string.find( text:lower(), "bots" )
			if isnumber( startpos ) and startpos == 1 then -- Check to see if the player is commanding every bot!

				textTable = string.Explode( " ", string.sub( text, endpos + 1 ) ) -- Grab everything else after the name!
				table.remove( textTable, 1 ) -- Remove the unnecessary whitespace
				command = textTable[ 1 ]:lower()

			end

		end

		if sender == botTable.TBotOwner and isstring( command ) then

			if command == "follow" then

				return self:TryDone( TBotEventResultPriorityType.RESULT_IMPORTANT, "We were ordered to follow our owner" )

			end

		end

	end
	
	return self:TryContinue()

end

function TBotUseEntityMeta:OnEnd( me, nextAction )

	return

end

function TBotUseEntityMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotUseEntityMeta:OnResume( me, interruptingAction )

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotUseEntityMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotUseEntityMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_YES

end

-- Is it time to retreat?
function TBotUseEntityMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_NO

end

-- Should we attack "them"
function TBotUseEntityMeta:ShouldAttack( me, them )

	-- Don't attack while we are using the ordered entity!
	if self.m_startedUse then
	
		return TBotQueryResultType.ANSWER_NO
		
	end

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotUseEntityMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotUseEntityMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotUseEntityMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotUseEntityMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end