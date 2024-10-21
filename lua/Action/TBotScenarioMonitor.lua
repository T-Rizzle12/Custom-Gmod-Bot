-- TBotScenarioMonitor.lua
-- Purpose: This is the TBotScenarioMonitor MetaTable
-- Author: T-Rizzle

DEFINE_BASECLASS( "TBotBaseAction" )

local TBotScenarioMonitorMeta = {}

function TBotScenarioMonitorMeta:__index( key )

	-- Search the metatable.
	local val = TBotScenarioMonitorMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = BaseClass[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotScenarioMonitor()
	local tbotscenariomonitor = TBotBaseAction()

	tbotscenariomonitor.m_path = TBotPathFollower()
	tbotscenariomonitor.m_repathTimer = util.Timer()
	tbotscenariomonitor.m_holdPos = nil
	tbotscenariomonitor.m_healTimer = util.Timer()
	tbotscenariomonitor.m_huntTimer = util.Timer()

	setmetatable( tbotscenariomonitor, TBotScenarioMonitorMeta )

	return tbotscenariomonitor

end

function TBotScenarioMonitorMeta:GetName()

	return "ScenarioMonitor"
	
end

function TBotScenarioMonitorMeta:InitialContainedAction( me )

	return nil

end

function TBotScenarioMonitorMeta:OnStart( me, priorAction )

	return self:Continue()

end

function TBotScenarioMonitorMeta:Update( me, interval )

	local botTable = me:GetTable()
	-- NEEDTOVALIDATE: Should this be its own action?
	if !isvector( self.m_holdPos ) then
	
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
	
	-- Go and reload every weapon in our inventory!
	-- NEEDTOVALIDATE: Should this be below the heal and revive checks?
	if !me:IsInCombat() then
	
		me:ReloadWeapons()
		
	end
	
	if self.m_healTimer:Elapsed() then
	
		self.m_healTimer:Start( math.Rand( 0.3, 0.5 ) )
		
		local reviveTarget = self:FindReviveTarget( me )
		if IsValid( reviveTarget ) and me:GetTBotVision():GetKnownCount( nil, false, botTable.DangerDist ) <= 5 then
		
			return self:SuspendFor( TBotRevivePlayer( reviveTarget ), "Reviving downed player" )
			
		end
		
		if !me:IsInCombat() then
		
			local healTarget = self:FindHealTarget( me )
			if IsValid( healTarget ) and me:HasWeapon( "weapon_medkit" ) then
		
				return self:SuspendFor( TBotHealPlayer( healTarget ), "Healing injured player" )
			
			end
			
		end
		
	end

	-- NEEDTOVALIDATE: Should this be its own action?
	if isvector( self.m_holdPos ) then
	
		local holdDist = self.m_holdPos:DistToSqr( me:GetPos() )
		if holdDist > GetConVar( "TBotGoalTolerance" ):GetFloat()^2 then
			
			if self.m_repathTimer:Elapsed() then
			
				self.m_repathTimer:Start( math.Rand( 3.0, 5.0 ) )
			
				self.m_path:Compute( me, self.m_holdPos )
				
			end
			
			self.m_path:Update( me )
			
		end
		
	end

	return self:Continue()

end

function TBotScenarioMonitorMeta:FindHealTarget( me )
	
	local botTable				=	me:GetTable()
	local targetdistsqr			=	tonumber( botTable.FollowDist ) or 200 -- This will allow the bot to select the closest teammate to it.
	targetdistsqr				=	targetdistsqr^2 -- This is ugly, but I don't have much of a choice.....
	local target				=	nil -- This is the closest teammate to the bot.
	
	--The bot should heal its owner and itself before it heals anyone else
	local tbotOwner = botTable.TBotOwner
	if IsValid( tbotOwner ) and tbotOwner:Alive() and tbotOwner:Health() < botTable.HealThreshold and tbotOwner:Health() < tbotOwner:GetMaxHealth() and tbotOwner:GetPos():DistToSqr( me:GetPos() ) < targetdistsqr then return tbotOwner
	elseif me:Health() < botTable.HealThreshold and me:Health() < me:GetMaxHealth() then return me end

	local searchPos = IsValid( tbotOwner ) and tbotOwner:Alive() and tbotOwner:GetPos() or me:GetPos()
	for k, ply in player.Iterator() do
	
		if IsValid( ply ) and ply:Alive() and !me:IsEnemy( ply ) and ply:Health() < botTable.HealThreshold and ply:Health() < ply:GetMaxHealth() and me:IsAbleToSee( ply ) then -- The bot will heal any teammate that needs healing that we can actually see and are alive.
			
			local teammatedistsqr = ply:GetPos():DistToSqr( searchPos )
			
			if teammatedistsqr < targetdistsqr then 
				target = ply
				targetdistsqr = teammatedistsqr
			end
		end
	end
	
	return target
	
end

function TBotScenarioMonitorMeta:FindReviveTarget( me )
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

function TBotScenarioMonitorMeta:PlayerSay( me, sender, text, teamChat )
	if !IsValid( sender ) then return self:TryContinue() end

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
			
			elseif command == "use" then

				local useEnt = sender:GetEyeTrace().Entity

				if IsValid( useEnt ) and !useEnt:IsWorld() then

					return self:TrySuspendFor( TBotUseEntity( useEnt, tonumber( textTable[ 2 ] ) or 0.1 ), TBotEventResultPriorityType.RESULT_IMPORTANT, "Going to use the ordered entity" )

				end

			end

		end

	end
	
	return self:TryContinue()

end

function TBotScenarioMonitorMeta:OnEnd( me, nextAction )

	return

end

function TBotScenarioMonitorMeta:OnSuspend( me, interruptingAction )

	return self:Continue()

end

function TBotScenarioMonitorMeta:OnResume( me, interruptingAction )

	-- If the bot finsihed looking around for enemies then they should not do so again for a bit.
	if interruptingAction and interruptingAction:GetName() == "SearchAndDestory" then
	
		self.m_huntTimer:Start( math.random( 20, 30 ) )
		
	end

	return self:Continue()

end

-- If the desired item was available right now, should we pick it up?
function TBotScenarioMonitorMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Are we in a hurry?
function TBotScenarioMonitorMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Is it time to retreat?
function TBotScenarioMonitorMeta:ShouldRetreat( me )

	-- If we our the group leader and we our overwhelmed or low health, we should retreat.
	local botTable = me:GetTable()
	if me:IsGroupLeader() and ( !IsValid( botTable.TBotOwner ) or !botTable.TBotOwner:Alive() ) and ( ( me:IsInCombat() and me:Health() < botTable.CombatHealThreshold ) or me:GetTBotVision():GetKnownCount( nil, true, botTable.DangerDist ) >= 10 ) then
	
		return TBotQueryResultType.ANSWER_YES
		
	end

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Should we attack "them"
function TBotScenarioMonitorMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotScenarioMonitorMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- Given a subject, return the world space postion we should aim at.
function TBotScenarioMonitorMeta:SelectTargetPoint( me, subject )

	return Vector()

end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotScenarioMonitorMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED

end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotScenarioMonitorMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return

end