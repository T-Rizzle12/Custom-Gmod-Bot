local BOT						=	FindMetaTable( "Player" )



function TBotCreate( ply , cmd , args )
	if !args[ 1 ] then return end
	
	local NewBot				=	player.CreateNextBot( args[ 1 ] ) -- Create the bot and store it in a varaible.
	
	NewBot.IsTutorialBot		=	true -- Flag this as our bot so we don't control other bots, Only ours!
	NewBot.Owner		=	ply -- Make the player who created the bot its "owner"
	NewBot.FollowDist		=	100 -- This is how close the bot will follow it's owner
	NewBot.DangerDist		=	300 -- This is how far the bot can be from it's owner before it focuses only on following them
	
	NewBot:TBotResetAI() -- Fully reset your bots AI.
	
end

concommand.Add( "TutorialCreateBot" , TBotCreate )


-------------------------------------------------------------------|



function BOT:TBotResetAI()
	
	self.Enemy				=	nil -- Refresh our enemy.
	
	self.Goal				=	nil -- The vector goal we want to get to.
	self.NavmeshNodes		=	{} -- The nodes given to us by the pathfinder
	self.Path				=	nil -- The nodes converted into waypoints by our visiblilty checking.
	
	self:TBotCreateThinking() -- Start our AI
	
end


hook.Add( "StartCommand" , "TutorialBotAIHook" , function( bot , cmd )
	if !IsValid( bot ) or !bot:IsBot() or !bot:Alive() or !bot.IsTutorialBot then return end
	-- Make sure we can control this bot and its not a player.
	
	cmd:ClearButtons() -- Clear the bots buttons. Shooting, Running , jumping etc...
	cmd:ClearMovement() -- For when the bot is moving around.
	
	-- Only using bot:HasWeapon() just for this example!
	if bot:HasWeapon( "weapon_crowbar" ) then
		
		-- Get the weapon entity by its class name, Then select it.
		cmd:SelectWeapon( bot:GetWeapon( "weapon_crowbar" ) )
		
	end
	
	
	
	-- Better make sure they exist of course.
	if IsValid( bot.Enemy ) then
		
		-- Attack and run
		cmd:SetButtons( bit.bor( IN_ATTACK , IN_SPEED ) )
		
		-- Instantly face our enemy!
		-- CHALLANGE: Can you make them turn smoothly?
		local lerp = FrameTime() * math.random(8, 10)
		bot:SetEyeAngles( LerpAngle(lerp, bot:GetShootPos(), ( bot.Enemy:GetShootPos() - bot:GetShootPos() ):GetNormalized():Angle() ) )
		
		if isvector( bot.Goal ) then
			
			bot:TBotUpdateMovement( cmd ) -- Move when we need to.
			
		else
			
			bot:TBotSetNewGoal( bot.Enemy:GetPos() )
			
		end
		
	elseif (IsValid(ply.Owner) and ply.Owner:Alive()) then
		local lerp = FrameTime() * math.random(8, 10)
		bot:SetEyeAngles(lerp, bot:GetShootPos(), ( bot.Owner:GetShootPos() - bot:GetShootPos() ):GetNormalized():Angle() ) )
		
		if isvector( bot.Goal ) then
			
			bot:TBotUpdateMovement( cmd ) -- Move when we need to.
			
		else
			
			bot:TBotSetNewGoal( bot.Owner:GetPos() )
			
		end
	end
	
	
end)







-- Just a simple way to respawn a bot.
hook.Add( "PlayerDeath" , "TutorialBotRespawn" , function( ply )
	
	if ply:IsBot() and ply.IsTutorialBot then 
		
		timer.Simple( 3 , function()
			
			if IsValid( ply ) then
				
				ply:Spawn()
				
			end
			
		end)
		
	end
	
end)

-- Reset their AI on spawn.
hook.Add( "PlayerSpawn" , "TutorialBotSpawnHook" , function( ply )
	
	if ply:IsBot() and ply.IsTutorialBot then
		
		ply:TBotResetAI()
		
	end
	
end)







-- The main AI is here.
function BOT:TBotCreateThinking()
	
	local index		=	self:EntIndex()
	
	-- I used math.Rand as a personal preference, It just prevents all the timers being ran at the same time
	-- as other bots timers.
	timer.Create( "tutorial_bot_think" .. index , math.Rand( 0.08 , 0.15 ) , 0 , function()
		
		if IsValid( self ) and self:Alive() then
			
			-- A quick condition statement to check if our enemy is no longer a threat.
			-- Most likely done best in its own function. But for this tutorial we will make it simple.
			if !IsValid( self.Enemy ) or !self.Enemy:IsPlayer() or !self.Enemy:Alive() then
				
				self.Enemy		=	nil
				
			end
			
			self:TBotFindRandomEnemy()
			
		else
			
			timer.Remove( "tutorial_bot_think" .. index ) -- We don't need to think while dead.
			
		end
		
	end)
	
end



-- Target any player or bot that is visible to us.
function BOT:TBotFindRandomEnemy()
	if IsValid( self.Enemy ) then return end
	
	local VisibleEnemies	=	{} -- So we can select a random enemy.
	
	for k, v in ipairs( player.GetAll() ) do
		
		if v:Alive() and v != self then -- Make sure they are alive and we don't want to target ourself.
			
			if v:Visible( self ) then -- Using Visible() as an example of why we should delay the thinking.
				
				VisibleEnemies[ #VisibleEnemies + 1]		=	v
				
			end
			
		end
		
	end
	
	self.Enemy		=	VisibleEnemies[ #VisibleEnemies + 1]
	
end

function TutorialBotPathfinder( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if ( StartNode == GoalNode ) then return true end
	
	StartNode:ClearSearchLists() -- Clear the search lists ready for a new search.
	
	StartNode:SetCostSoFar( 0 ) -- Sets the cost so far. which is beleive is the GCost.
	
	StartNode:SetTotalCost( TutorialBotRangeCheck( StartNode , GoalNode ) ) -- Sets the total cost so far. which im quite sure is the FCost.
	
	StartNode:AddToOpenList()
	
	StartNode:UpdateOnOpenList()
	
	local FinalPath		=	{}
	
	local Attempts		=	0 
	-- Backup Varaible! In case something goes wrong, The game will not get into an infinite loop.
	
	while( !StartNode:IsOpenListEmpty() and Attempts < 6500 ) do
		Attempts		=	Attempts + 1
		
		local Current 	=	StartNode:PopOpenList() -- Get the lowest FCost
		
		if ( Current == GoalNode ) then
			-- We found a path! Now lets retrace it.
			
			
			return TutorialBotRetracePath( Current , FinalPath ) -- Retrace the path and return the table of nodes.
		end
		
		Current:AddToClosedList() -- We don't need to deal with this anymore.
		
		for k, neighbor in ipairs( Current:GetAdjacentAreas() ) do
			local Height			=	Current:ComputeAdjacentConnectionHeightChange( neighbor ) 
			
			if Height > 64 then
				-- We can't jump that high.
				
				continue
			end
			
			-- G + H = F
			local NewCostSoFar		=	Current:GetCostSoFar() + TutorialBotRangeCheck( Current , neighbor )
			
			if neighbor:IsOpen() or neighbor:IsClosed() and neighbor:GetCostSoFar() <= NewCostSoFar then
				
				continue
				
			else
				neighbor:SetCostSoFar( NewCostSoFar )
				neighbor:SetTotalCost( NewCostSoFar + TutorialBotRangeCheck( neighbor , GoalNode ) )
				
				if neighbor:IsClosed() then
					
					neighbor:RemoveFromClosedList()
					
				end
				
				if neighbor:IsOpen() then
					
					neighbor:UpdateOnOpenList()
					
				else
					
					neighbor:AddToOpenList()
					
				end
				
				-- Parenting of the nodes so we can trace the parents back later.
				FinalPath[ neighbor:GetId() ]		=	Current:GetID()
			end
			
		end
		
	end
	
	return false
end



function TutorialBotRangeCheck( FirstNode , SecondNode )
	-- Some helper errors.
	if !IsValid( FirstNode ) then error( "Bad argument #1 CNavArea expected got " .. type( FirstNode ) ) end
	if !IsValid( FirstNode ) then error( "Bad argument #2 CNavArea expected got " .. type( SecondNode ) ) end
	
	return FirstNode:GetCenter():Distance( SecondNode:GetCenter() )
end


function TutorialBotRetracePath( Current , FinalPath )
	
	local NodePath		=	{ Current }
	
	Current				=	Current:GetID()
	
	while ( FinalPath[ Current ] ) do
		
		Current			=	FinalPath[ Current ]
		table.insert( NodePath , navmesh.GetNavAreaByID( Current ) )
		
	end
	
	
	return NodePath
end

function BOT:TBotSetNewGoal( NewGoal )
	if !isvector( NewGoal ) then error( "Bad argument #1 vector expected got " .. type( NewGoal ) ) end
	
	self.Goal				=	NewGoal
	
	self:TBotCreateNavTimer()
	
end






-- A handy function for range checking.
local function IsVecCloseEnough( start , endpos , dist )
	
	return start:DistToSqr( endpos ) < dist * dist
	
end

local function CheckLOS( val , pos1 , pos2 )
	
	local Trace				=	util.TraceLine({
		
		start				=	pos1 + Vector( val , 0 , 0 ),
		endpos				=	pos2 + Vector( val , 0 , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	Trace					=	util.TraceLine({
		
		start				=	pos1 + Vector( -val , 0 , 0 ),
		endpos				=	pos2 + Vector( -val , 0 , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	
	Trace					=	util.TraceLine({
		
		start				=	pos1 + Vector( 0 , val , 0 ),
		endpos				=	pos2 + Vector( 0 , val , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	Trace					=	util.TraceLine({
		
		start				=	pos1 + Vector( 0 , -val , 0 ),
		endpos				=	pos2 + Vector( 0 , -val , 0 ),
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	return true
end

local function SendBoxedLine( pos1 , pos2 )
	
	for i = 1, 12 do
		
		if CheckLOS( 3 * i , pos1 , pos2 ) == false then return false end
		
	end
	
	return true
end


-- Creates waypoints using the nodes.
function BOT:ComputeNavmeshVisibility()
	
	self.Path				=	{}
	
	local LastVisPos		=	self:GetPos()
	
	for k, CurrentNode in ipairs( self.NavmeshNodes ) do
		-- You should also make sure that the nodes exist as this is called 0.03 seconds after the pathfind.
		-- For tutorial sakes ill keep this simple.
		
		local NextNode		=	self.NavmeshNodes[ CurrentNode:GetID() ]
		
		if !IsValid( NextNode ) then
			
			self.Path[ Current ]		=	self.Goal
			
			break
		end
		
		
		
		-- The next area ahead's closest point to us.
		local NextAreasClosetPointToLastVisPos		=	NextNode:GetClosestPointOnArea( LastVisPos ) + Vector( 0 , 0 , 32 )
		local OurClosestPointToNextAreasClosestPointToLastVisPos	=	CurrentNode:GetClosestPointOnArea( NextAreasClosetPointToLastVisPos ) + Vector( 0 , 0 , 32 )
		
		-- If we are visible then we shall put the waypoint there.
		if SendBoxedLine( LastVisPos , OurClosestPointToNextAreasClosestPointToLastVisPos ) == true then
			
			LastVisPos						=	OurClosestPointToNextAreasClosestPointToLastVisPos
			self.Path[ Current ]		=	OurClosestPointToNextAreasClosestPointToLastVisPos
			
			continue
		end
		
		
		
		
		self.Path[ Current ]			=	CurrentNode:GetCenter()
		
	end
	
end


-- The main navigation code ( Waypoint handler )
function BOT:TBotNavigation()
	if !isvector( self.Goal ) then return end -- A double backup!
	
	-- The CNavArea we are standing on.
	self.StandingOnNode			=	navmesh.GetNearestNavArea( self:GetPos() )
	if !IsValid( self.StandingOnNode ) then return end -- The map has no navmesh.
	
	
	if !istable( self.Path ) or !istable( self.NavmeshNodes ) or table.IsEmpty( self.Path ) or table.IsEmpty( self.NavmeshNodes ) then
		
		
		if self.BlockPathFind != true then
			
			
			-- Get the nav area that is closest to our goal.
			local TargetArea		=	navmesh.GetNearestNavArea( self.Goal )
			
			self.Path				=	{} -- Reset that.
			
			-- Find a path through the navmesh to our TargetArea
			self.NavmeshNodes		=	TutorialBotPathfinder( self.StandingOnNode , TargetArea )
			
			
			-- Prevent spamming the pathfinder.
			self.BlockPathFind		=	true
			timer.Simple( 0.25 , function()
				
				if IsValid( self ) then
					
					self.BlockPathFind		=	false
					
				end
				
			end)
			
			
			-- Give the computer some time before it does more expensive checks.
			timer.Simple( 0.03 , function()
				
				-- If we can get there and is not already there, Then we will compute the visiblilty.
				if IsValid( self ) and istable( self.NavmeshNodes ) then
					
					self.NavmeshNodes	=	table.Reverse( self.NavmeshNodes )
					
					self:ComputeNavmeshVisibility()
					
				end
				
			end)
			
			
			-- There is no way we can get there! Remove our goal.
			if self.NavmeshNodes == false then
				
				self.Goal		=	nil
				
				return
			end
			
			
		end
		
		
	end
	
	
	if istable( self.Path ) then
		
		if self.Path[ self.Goal ] then
			
			local Waypoint2D		=	Vector( self.Path[ self.Goal ].x , self.Path[ self.Goal ].y , self:GetPos().z )
			-- ALWAYS: Use 2D navigation, It helps by a large amount.
			
			if self.Path[ self.Goal ] and IsVecCloseEnough( self:GetPos() , Waypoint2D , 600 ) and SendBoxedLine( self.Path[ self.Goal ] , self:GetPos() + Vector( 0 , 0 , 15 ) ) == true and self.Path[ self.Goal ].z - 20 <= Waypoint2D.z then
				
				table.remove( self.Path , 1 )
				
			elseif IsVecCloseEnough( self:GetPos() , Waypoint2D , 24 ) then
				
				table.remove( self.Path , 1 )
				
			end
			
		end
		
	end
	
	
end

-- The navigation and navigation debugger for when a bot is stuck.
function BOT:TBotCreateNavTimer()
	
	local index				=	self:EntIndex()
	local LastBotPos		=	self:GetPos()
	
	
	timer.Create( "tutorialbot_nav" .. index , 0.09 , 0 , function()
		
		if IsValid( self ) and self:Alive() and isvector( self.Goal ) then
			
			self:TBotNavigation()
			
			self:TBotDebugWaypoints()
			
			LastBotPos		=	Vector( LastBotPos.x , LastBotPos.y , self:GetPos().z )
			
			if IsVecCloseEnough( self:GetPos() , LastBotPos , 2 ) then
				
				self.Path	=	nil
				-- TODO/Challange: Make the bot jump a few times, If that does not work. Then recreate the path.
				
			end
			LastBotPos		=	self:GetPos()
			
		else
			
			timer.Remove( "tutorialbot_nav" .. index )
			
		end
		
	end)
	
end



-- A handy debugger for the waypoints.
-- Requires developer set to 1 in console
function BOT:TBotDebugWaypoints()
	if !istable( self.Path ) then return end
	if table.IsEmpty( self.Path ) then return end
	
	debugoverlay.Line( self.Path[ self.Goal ] , self:GetPos() + Vector( 0 , 0 , 44 ) , 0.08 , Color( 0 , 255 , 255 ) )
	debugoverlay.Sphere( self.Path[ self.Goal ] , 8 , 0.08 , Color( 0 , 255 , 255 ) , true )
	
	for k, v in ipairs( self.Path ) do
		
		if self.Path[ k ] then
			
			debugoverlay.Line( v , self.Path[ k ] , 0.08 , Color( 255 , 255 , 0 ) )
			
		end
		
		debugoverlay.Sphere( v , 8 , 0.08 , Color( 255 , 200 , 0 ) , true )
		
	end
	
end


-- Make the bot move.
function BOT:TBotUpdateMovement( cmd )
	if !isvector( self.Goal ) then return end
	
	if !istable( self.Path ) or table.IsEmpty( self.Path ) or isbool( self.NavmeshNodes ) then
		
		local MovementAngle		=	( self.Goal - self:GetPos() ):GetNormalized():Angle()
		
		cmd:SetViewAngles( MovementAngle )
		cmd:SetForwardMove( 1000 )
		
		local GoalIn2D			=	Vector( self.Goal.x , self.Goal.y , self:GetPos().z )
		-- Optionaly you could convert this to 2D navigation as well if you like.
		-- I prefer not to.
		if IsVecCloseEnough( self:GetPos() , GoalIn2D , 32 ) then
			
			self.Goal			=		nil -- We have reached our goal!
			
		end
		
		return
	end
	
	if self.Path[ #self.Path ] then
		
		local MovementAngle		=	( self.Path[ self.Goal ] - self:GetPos() ):GetNormalized():Angle()
		
		cmd:SetViewAngles( MovementAngle )
		cmd:SetForwardMove( 1000 )
		
	end
	
end
