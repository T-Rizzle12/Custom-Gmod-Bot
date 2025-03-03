-- TBotFollowerMonitor.lua
-- Purpose: This is the TBotFollowerMonitor MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotFollowerMonitorMeta = {}

function TBotFollowerMonitorMeta:__index( key )

	-- Search the metatable.
	local val = TBotFollowerMonitorMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotFollowerMonitor()
	local tbotfollowermonitor = TBotBaseAction()

	tbotfollowermonitor.m_path = TBotPathFollower()
	tbotfollowermonitor.m_repathTimer = util.Timer()
	tbotfollowermonitor.m_holdPos = nil
	tbotfollowermonitor.m_huntTimer = util.Timer()

	setmetatable( tbotfollowermonitor, TBotFollowerMonitorMeta )

	return tbotfollowermonitor

end

function TBotFollowerMonitorMeta:GetName()

	return "FollowerMonitor"
	
end

function TBotFollowerMonitorMeta:InitialContainedAction( me )

	return nil

end

function TBotFollowerMonitorMeta:OnStart( me, priorAction )

	return self:Continue()

end

local TBotGoalTolerance = GetConVar( "TBotGoalTolerance" )
function TBotFollowerMonitorMeta:Update( me, interval )

	local botTable = me:GetTable()
	if isvector( self.m_holdPos ) then
	
		local holdDist = self.m_holdPos:DistToSqr( me:GetPos() )
		if holdDist > TBotGoalTolerance:GetFloat()^2 then
			
			if self.m_repathTimer:Elapsed() then
			
				self.m_repathTimer:Start( math.Rand( 3.0, 5.0 ) )
			
				self.m_path:Compute( me, self.m_holdPos )
				
			end
			
			self.m_path:Update( me )
			
		end
		
	else
	
		if IsValid( botTable.TBotOwner ) and botTable.TBotOwner:Alive() then
		
			local ownerDist = botTable.TBotOwner:GetPos():DistToSqr( me:GetPos() )
			if ownerDist > botTable.FollowDist^2 then
		
				return self:SuspendFor( TBotFollowOwner(), "Moving to stay nearby our owner" )
				
			end
		
		else
		
			local newLeader = me:FindGroupLeader()
			botTable.GroupLeader = IsValid( newLeader ) and newLeader or me
			if IsValid( botTable.GroupLeader ) and botTable.GroupLeader:Alive() and !me:IsGroupLeader() then
		
				local leaderDist = botTable.GroupLeader:GetPos():DistToSqr( me:GetPos() )
				if leaderDist > botTable.FollowDist^2 then
			
					return self:SuspendFor( TBotFollowGroupLeader(), "Moving to stay nearby our group leader" )
				
				end
				
			end
		
		end
		
	end
	
	-- Group leader logic, YAY!
	if me:IsGroupLeader() then
	
		-- NEEDTOVALIDATE: Should I make the bot only search and destory when safe?
		if self.m_huntTimer:Elapsed() then
			
			return self:SuspendFor( TBotSearchAndDestory(), "Looking for possible targets" )
			
		end
	
	end

	return self:Continue()

end

function TBotFollowerMonitorMeta:player_say( me, data )
	local sender = Player( data.userid )
	if !IsValid( sender ) then return self:TryContinue() end

	local text = data.text
	local teamChat = tobool( data.teamonly )
	-- HACKHACK: PlayerCanSeePlayersChat is called after PlayerSay, so we call it to check if the bot can see the chat message.
	-- NEEDTOVALIDATE: Would it be better if I used the PlayerCanSeePlayersChat hook instead?
	if hook.Run( "PlayerCanSeePlayersChat", text, teamChat, me, sender ) then

		local botTable = me:GetTable()
		local botNamePattern = string.format( "^(%s) +(.*)$", me:Nick() )
		local textTable
		local _, command = string.match( text, botNamePattern )

		if isstring( command ) then -- Only run the command if the bot name was said first!

			textTable = string.Explode( " ", command ) -- Grab everything else after the name!
			command = textTable[ 1 ] and textTable[ 1 ]:lower() -- Make it case insenstive

		else

			local botsPattern = string.format( "^(%s) +(.*)$", "bots" )
			_, command = string.match( text:lower(), botsPattern )
			if isstring( command ) then -- Check to see if the player is commanding every bot!

				textTable = string.Explode( " ", command ) -- Grab everything else after the name!
				command = textTable[ 1 ] and textTable[ 1 ]:lower() -- Make it case insenstive

			end

		end

		if sender == botTable.TBotOwner and isstring( command ) then

			-- FIXME: There might be a better way of doing this.....
			if command == "follow" then
			
				self.m_holdPos = nil
			
			elseif command == "hold" then

				local pos = sender:GetEyeTrace().HitPos
				local ground = navmesh.GetGroundHeight( pos )
				if ground then

					pos.z = ground

				end

				self.m_holdPos = pos

				--return self:TryChangeTo( TBotHoldPosition( pos ), TBotEventResultPriorityType.RESULT_TRY, "Holding ordered postion" )

			elseif command == "wait" then

				local pos = me:GetPos()
				local ground = navmesh.GetGroundHeight( pos )
				if ground then

					pos.z = ground

				end

				self.m_holdPos = pos

				--return self:TryChangeTo( TBotHoldPosition( pos ), TBotEventResultPriorityType.RESULT_TRY, "Holding current postion" )
			
			end

		end

	end
	
	return self:TryContinue()

end

function TBotFollowerMonitorMeta:OnEnd( me, nextAction )

	return

end

function TBotFollowerMonitorMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotFollowerMonitorMeta:OnResume( me, interruptingAction )

	-- If the bot finsihed looking around for enemies then they should not do so again for a bit.
	if interruptingAction and interruptingAction:GetName() == "SearchAndDestory" then
	
		self.m_huntTimer:Start( math.random( 10, 30 ) )
		
	end

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotFollowerMonitorMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotFollowerMonitorMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotFollowerMonitorMeta:ShouldRetreat( me )

	-- If we our the group leader and we our overwhelmed or low health, we should retreat.
	local botTable = me:GetTable()
	if me:IsGroupLeader() and ( !IsValid( botTable.TBotOwner ) or !botTable.TBotOwner:Alive() ) and ( ( me:IsInCombat() and me:Health() < botTable.CombatHealThreshold ) or me:GetTBotVision():GetKnownCount( nil, true, botTable.DangerDist ) >= 10 ) then
	
		return TBotQueryResultType.ANSWER_YES
		
	end

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotFollowerMonitorMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotFollowerMonitorMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotFollowerMonitorMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotFollowerMonitorMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotFollowerMonitorMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end