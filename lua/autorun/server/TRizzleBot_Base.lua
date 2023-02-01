local BOT						=	FindMetaTable( "Player" )
local Zone		=	FindMetaTable( "CNavArea" )
local Lad		=	FindMetaTable( "CNavLadder" )
local Open_List		=	{}
local Node_Data		=	{}



function TBotCreate( ply , cmd , args )
	if !args[ 1 ] then return end
	
	local NewBot				=	player.CreateNextBot( args[ 1 ] ) -- Create the bot and store it in a varaible.
	
	NewBot.IsTutorialBot		=	true -- Flag this as our bot so we don't control other bots, Only ours!
	NewBot.Owner		=	ply -- Make the player who created the bot its "owner"
	NewBot.FollowDist		=	200 -- This is how close the bot will follow it's owner
	NewBot.DangerDist		=	300 -- This is how far the bot can be from it's owner before it focuses only on following them
	NewBot.Jump		=	false -- If this is set to true the bot will jump
	NewBot.Crouch		=	false -- If this is set to true the bot will crouch
	NewBot.Use			=	false -- If this is set to true the bot use press its use key
	
	NewBot:TBotResetAI() -- Fully reset your bots AI.
	
end

concommand.Add( "TutorialCreateBot" , TBotCreate )


-------------------------------------------------------------------|



function BOT:TBotResetAI()
	
	self.Enemy				=	nil -- Refresh our enemy.
	self.NumEnemies			=	0 -- How many enemies do we currently see
	self.Jump			=	false -- Stop jumping
	self.Crouch			=	false -- Stop crouching
	self.Use			=	false -- Stop using
	
	self.Goal				=	nil -- The vector goal we want to get to.
	self.NavmeshNodes		=	{} -- The nodes given to us by the pathfinder
	self.Path				=	nil -- The nodes converted into waypoints by our visiblilty checking.
	self.PathTime			=	CurTime() + 1.0 -- This will limit how often the path gets recreated
	
	self:TBotCreateThinking() -- Start our AI
	
end


hook.Add( "StartCommand" , "TutorialBotAIHook" , function( bot , cmd )
	if !IsValid( bot ) or !bot:IsBot() or !bot:Alive() or !bot.IsTutorialBot then return end
	-- Make sure we can control this bot and its not a player.
	
	cmd:ClearButtons() -- Clear the bots buttons. Shooting, Running , jumping etc...
	cmd:ClearMovement() -- For when the bot is moving around.
	
	
	-- Better make sure they exist of course.
	if IsValid( bot.Enemy ) then
		
		-- Instantly face our enemy!
		-- CHALLANGE: Can you make them turn smoothly?
		local lerp = math.random(0.4, 0.8)
		bot:SetEyeAngles( LerpAngle(lerp, bot:EyeAngles(), ( (bot.Enemy:GetPos() + Vector(0, 0, 25)) - bot:GetShootPos() ):GetNormalized():Angle() ) )
		
		if bot:HasWeapon( "weapon_pistol" ) and bot:GetWeapon( "weapon_pistol" ):HasAmmo() and (bot.Enemy:GetPos() - bot:GetPos()):Length() > 400 then
		
			-- If an enemy gets too far the bot should use its pistol
			cmd:SelectWeapon( bot:GetWeapon( "weapon_pistol" ) )
		
		elseif bot:HasWeapon( "weapon_shotgun" ) and bot:GetWeapon( "weapon_shotgun" ):HasAmmo() and (bot.Enemy:GetPos() - bot:GetPos()):Length() > 80 then
		
			-- If an enemy gets too far but is still close the bot should use its shotgun
			cmd:SelectWeapon( bot:GetWeapon( "weapon_shotgun" ) )
		
		elseif bot:HasWeapon( "weapon_crowbar" ) then
		
			-- If an enemy gets too close the bot should use its crowbar
			cmd:SelectWeapon( bot:GetWeapon( "weapon_crowbar" ) )
		
		end
		
		local buttons = 0
		local botWeapon = bot:GetActiveWeapon()
		if math.random(2) == 1 and bot:GetEyeTrace().Entity == bot.Enemy then
			buttons = buttons + IN_ATTACK
		end
		
		if math.random(2) == 1 and botWeapon:Clip1() == 0 then
			buttons = buttons + IN_RELOAD
		end
		
		if !bot:Is_On_Ladder() then
			if bot.Jump then 
				buttons = buttons + IN_JUMP 
				bot.Jump = false 
			end
			if bot.Crouch then 
				buttons = buttons + IN_DUCK 
				bot.Crouch = false 
			end
			if bot.Use then 
				buttons = buttons + IN_USE 
				bot.Use = false 
			end
		else
		
			buttons = buttons + IN_FORWARD
		
		end
		
		cmd:SetButtons( buttons )
		
		if isvector( bot.Goal ) and (bot.Owner:GetPos() - bot.Goal):Length() < 64 or isvector( bot.Goal ) and (bot.Enemy:GetPos() - bot.Goal):Length() < 64 then
			
			bot:TBotUpdateMovement( cmd )
			
		elseif bot:GetActiveWeapon():GetClass() == "weapon_crowbar" and (bot.Owner:GetPos() - bot:GetPos()):Length() < bot.DangerDist then
			
			bot:TBotSetNewGoal( bot.Enemy:GetPos() ) -- Only chase after targets if we are using a melee weapon.
			
		elseif (bot.Owner:GetPos() - bot:GetPos()):Length() > bot.DangerDist then
			
			bot:TBotSetNewGoal( bot.Owner:GetPos() )
			
		end
		
	elseif IsValid( bot.Owner ) and bot.Owner:Alive() then
		
		local buttons = 0
		local botWeapon = bot:GetActiveWeapon()
		if math.random(2) == 1 and botWeapon:Clip1() < botWeapon:GetMaxClip1() then
			buttons = buttons + IN_RELOAD
		end
		
		-- If the bot and bot's owner is not in combat then the bot should check if either their owner or they need to heal
		if bot:HasWeapon( "weapon_medkit" ) and (bot.Owner:GetPos() - bot:GetPos()):Length() < 80 and bot.Owner:Health() < bot.Owner:GetMaxHealth() then
		
			-- The bot should priortize healing its owner over themself
			local lerp = math.random(0.4, 0.8)
			bot:SetEyeAngles( LerpAngle(lerp, bot:EyeAngles(), ( (bot.Owner:GetPos() + Vector(0, 0, 25) ) - bot:GetShootPos() ):GetNormalized():Angle() ) )
			cmd:SelectWeapon( bot:GetWeapon( "weapon_medkit" ) )
			if math.random(2) == 1 then
				buttons = buttons + IN_ATTACK
			end
		elseif bot:HasWeapon( "weapon_medkit" ) and (bot.Owner:GetPos() - bot:GetPos()):Length() < 80 and bot:Health() < bot:GetMaxHealth() then
		
			-- The bot will heal themself if their owner has full health
			cmd:SelectWeapon( bot:GetWeapon( "weapon_medkit" ) )
			if math.random(2) == 1 then
				buttons = buttons + IN_ATTACK2
			end
		elseif bot:HasWeapon( "weapon_pistol" ) and bot:GetWeapon( "weapon_pistol" ):Clip1() < bot:GetWeapon( "weapon_pistol" ):GetMaxClip1() then
		
			-- The bot should reload weapons that need to be reloaded
			cmd:SelectWeapon( bot:GetWeapon( "weapon_pistol" ) )
		
		elseif bot:HasWeapon( "weapon_shotgun" ) and bot:GetWeapon( "weapon_shotgun" ):Clip1() < bot:GetWeapon( "weapon_shotgun" ):GetMaxClip1() then
		
			cmd:SelectWeapon( bot:GetWeapon( "weapon_shotgun" ) )
			
		end
		-- Possibly add support for the bot to heal nearby players?
		
		-- Run if we are too far from our owner
		if (bot.Owner:GetPos() - bot:GetPos()):Length() > bot.DangerDist then 
			buttons = buttons + IN_SPEED 
		end
		
		if !bot:Is_On_Ladder() then
			if bot.Jump then 
				buttons = buttons + IN_JUMP 
				bot.Jump = false 
			end
			if bot.Crouch then 
				buttons = buttons + IN_DUCK 
				bot.Crouch = false 
			end
			if bot.Use then 
				buttons = buttons + IN_USE 
				bot.Use = false 
			end
		else
		
			buttons = buttons + IN_FORWARD
		
		end
		
		cmd:SetButtons( buttons )
		
		if isvector( bot.Goal ) and (bot.Owner:GetPos() - bot.Goal):Length() < 64 then
			
			bot:TBotUpdateMovement( cmd ) -- Move when we need to.
			
		elseif (bot.Owner:GetPos() - bot:GetPos()):Length() > bot.FollowDist then
			
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
			if !IsValid( self.Enemy ) then self.Enemy		=	nil
			elseif self.Enemy:IsPlayer() and !self.Enemy:Alive() then self.Enemy		=	nil
			elseif !self.Enemy:Visible( self ) then self.Enemy		=	nil
			elseif self.Enemy:IsNPC() and self.Enemy:GetNPCState() == NPC_STATE_DEAD then self.Enemy		=	nil end
			
			self:TBotFindRandomEnemy()
			
		else
			
			timer.Remove( "tutorial_bot_think" .. index ) -- We don't need to think while dead.
			
		end
		
	end)
	
end



-- Target any player or bot that is visible to us.
function BOT:TBotFindRandomEnemy()
	local VisibleEnemies	=	{} -- So we can select a random enemy.
	local targetdist		=	10000 -- This will allow the bot to select the closest enemy to it.
	local target			=	nil -- This is the closest enemy to the bot.
	
	for k, v in ipairs( ents.GetAll() ) do
		
		if IsValid ( v ) and v:IsNPC() and v:GetNPCState() != NPC_STATE_DEAD and (v:GetEnemy() == self or v:GetEnemy() == self.Owner) then -- The bot should attack any NPC that is attacking them or their owner
			
			if v:Visible( self ) then -- Using Visible() as an example of why we should delay the thinking.
				
				VisibleEnemies[ #VisibleEnemies + 1 ]		=	v
				if (v:GetPos() - self:GetPos()):Length() < targetdist then 
					target = v
					targetdist = (v:GetPos() - self:GetPos()):Length()
				end
			end
			
		end
		
	end
	
	self.Enemy		=	target
	self.NumEnemies		=	#VisibleEnemies
	
end

function TutorialBotPathfinder( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if ( StartNode == GoalNode ) then return true end
	
	Prepare_Path_Find()
	
	StartNode:Add_To_Open_List()
	local Attempts		=	0 
	-- Backup Varaible! In case something goes wrong, The game will not get into an infinite loop.
	
	while( !table.IsEmpty( Open_List ) and Attempts < 6500 ) do
		Attempts		=	Attempts + 1
		
		local Current 	=	Get_Best_Node() -- Get the lowest FCost
		
		if ( Current == GoalNode ) then
			-- We found a path! Now lets retrace it.
			
			return TutorialBotRetracePath( StartNode, GoalNode ) -- Retrace the path and return the table of nodes.
		end
		
		for k, neighbor in ipairs( Current:Get_Connected_Areas() ) do
			local Height = 0
			
			if neighbor:Node_Get_Type() == 1 and Current:Node_Get_Type() == 1 then
				Height			=	Current:ComputeAdjacentConnectionHeightChange( neighbor ) 
				
				if Height > 64 then
					-- We can't jump that high.
					
					continue
				end
			end
			
			-- G + H = F
			local NewCostSoFar		=	Current:Get_G_Cost() + TutorialBotRangeCheck( Current , neighbor )
			
			if neighbor:Node_Is_Open() or neighbor:Node_Is_Closed() and neighbor:Get_G_Cost() <= NewCostSoFar then
					
				continue
					
			else
				neighbor:Set_G_Cost( NewCostSoFar )
				neighbor:Set_F_Cost( NewCostSoFar + TutorialBotRangeCheck( neighbor , GoalNode ) )
					
				if neighbor:Node_Is_Closed() then
						
					neighbor:Node_Remove_From_Closed_List()
						
				end
					
				neighbor:Node_Add_To_Open_List()
				
				-- Parenting of the nodes so we can trace the parents back later.
				neighbor:Set_Parent_Node( Current )
			end
			
		end
		
	end
	
	return false
end



function TutorialBotRangeCheck( FirstNode , SecondNode )
	-- Some helper errors.
	if !IsValid( FirstNode ) then error( "Bad argument #1 CNavArea or CNavLadder expected got " .. type( FirstNode ) ) end
	if !IsValid( FirstNode ) then error( "Bad argument #2 CNavArea or CNavLadder expected got " .. type( SecondNode ) ) end
	
	if FirstNode:Node_Get_Type() == 1 and SecondNode:Node_Get_Type() == 1 then
		return FirstNode:GetCenter():Distance( SecondNode:GetCenter() )
	end
	
	return SecondNode:GetLength()
end


function TutorialBotRetracePath( StartNode , GoalNode )
	
	local NodePath		=	{ GoalNode }
	
	local Current		=	GoalNode
	
	local Attempts		=	0
	
	while ( Current != StartNode and Attempts < 5001 ) do
		
		Attempts = Attempts + 1
		
		Current			=	CurrentNode:Get_Parent_Node()
		
		if Current:Node_Get_Type() == 1 then
		
			table.insert( NodePath , navmesh.GetNavAreaByID( Current:GetID() ) )
			
		else
		
			table.insert( NodePath , navmesh.GetNavLadderByID( Current:GetID() ) )
			
		end
	end
	
	
	return NodePath
end

function BOT:TBotSetNewGoal( NewGoal )
	if !isvector( NewGoal ) then error( "Bad argument #1 vector expected got " .. type( NewGoal ) ) end
	
	self.Goal				=	NewGoal
	if self.PathTime < CurTime() then
		self.Path				=	{}
		self.PathTime			=	CurTime() + 5.0
	end
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
		
		local NextNode		=	self.NavmeshNodes[ k + 1 ]
		
		if !IsValid( NextNode ) then
			
			self.Path[ #self.Path + 1 ]		=	self.Goal
			
			break
		end
		
		if NextNode:Node_Get_Type() == 2 then
		
			local CloseToStart		=	NextNode:Get_Closest_Point( LastVisPos )
			
			LastVisPos		=	CloseToStart
			
			self.Path[ #self.Path + 1 ]		=	NextNode
			
			continue
		end
		
		if CurrentNode:Node_Get_Type() == 2 then
		
			local CloseToEnd		=	CurrentNode:Get_Closest_Point( NextNode:GetCenter() )
			
			LastVisPos		=	CloseToEnd
			
			self.Path[ #self.Path + 1 ]		=	CurrentNode
			
			continue
		end
		
		-- The next area ahead's closest point to us.
		local NextAreasClosetPointToLastVisPos		=	NextNode:GetClosestPointOnArea( LastVisPos ) + Vector( 0 , 0 , 32 )
		local OurClosestPointToNextAreasClosestPointToLastVisPos	=	CurrentNode:GetClosestPointOnArea( NextAreasClosetPointToLastVisPos ) + Vector( 0 , 0 , 32 )
		
		-- If we are visible then we shall put the waypoint there.
		if SendBoxedLine( LastVisPos , OurClosestPointToNextAreasClosestPointToLastVisPos ) == true then
			
			LastVisPos						=	OurClosestPointToNextAreasClosestPointToLastVisPos
			self.Path[ #self.Path + 1 ]		=	OurClosestPointToNextAreasClosestPointToLastVisPos
			
			continue
		end
		
		
		
		
		self.Path[ #self.Path + 1 ]			=	CurrentNode:GetCenter()
		
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
		
		if self.Path[ 1 ] then
			
			local Waypoint2D		=	Vector( self.Path[ 1 ].x , self.Path[ 1 ].y , self:GetPos().z )
			-- ALWAYS: Use 2D navigation, It helps by a large amount.
			
			if self.Path[ 2 ] and IsVecCloseEnough( self:GetPos() , Waypoint2D , 600 ) and SendBoxedLine( self.Path[ 2 ] , self:GetPos() + Vector( 0 , 0 , 15 ) ) == true and self.Path[ 2 ].z - 20 <= Waypoint2D.z then
				
				table.remove( self.Path , 1 )
				
			elseif IsVecCloseEnough( self:GetPos() , Waypoint2D , 32 ) then
				
				table.remove( self.Path , 1 )
				
			end
			
		end
		
	end
	
	
end

-- The navigation and navigation debugger for when a bot is stuck.
function BOT:TBotCreateNavTimer()
	
	local index				=	self:EntIndex()
	local LastBotPos		=	self:GetPos()
	local Attempts		=	0
	
	
	timer.Create( "tutorialbot_nav" .. index , 0.09 , 0 , function()
		
		if IsValid( self ) and self:Alive() and isvector( self.Goal ) then
			
			self:TBotNavigation()
			
			self:TBotDebugWaypoints()
			
			LastBotPos		=	Vector( LastBotPos.x , LastBotPos.y , self:GetPos().z )
			
			if IsVecCloseEnough( self:GetPos() , LastBotPos , 2 ) then
				
				self.Jump	=	true
				self.Crouch	=	true
				self.Use	=	true
				
				if Attempts > 30 then self.Path	=	nil end
				if Attempts > 60 then self.Goal =	nil end
				Attempts = Attempts + 1
				-- TODO/Challange: Make the bot jump a few times, If that does not work. Then recreate the path.
				
			else
				Attempts = 0
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
	
	debugoverlay.Line( self.Path[ 1 ] , self:GetPos() + Vector( 0 , 0 , 44 ) , 0.08 , Color( 0 , 255 , 255 ) )
	debugoverlay.Sphere( self.Path[ 1 ] , 8 , 0.08 , Color( 0 , 255 , 255 ) , true )
	
	for k, v in ipairs( self.Path ) do
		
		if self.Path[ k + 1 ] then
			
			debugoverlay.Line( v , self.Path[ k + 1 ] , 0.08 , Color( 255 , 255 , 0 ) )
			
		end
		
		debugoverlay.Sphere( v , 8 , 0.08 , Color( 255 , 200 , 0 ) , true )
		
	end
	
end


-- Make the bot move.
function BOT:TBotUpdateMovement( cmd )
	if !isvector( self.Goal ) then return end
	
	if !istable( self.Path ) or table.IsEmpty( self.Path ) or isbool( self.NavmeshNodes ) then
		
		local MovementAngle		=	( self.Goal - self:GetPos() ):GetNormalized():Angle()
		local lerp = math.random(0.4, 1.0)
		
		cmd:SetViewAngles( MovementAngle )
		cmd:SetForwardMove( self:GetMaxSpeed() )
		if !IsValid( self.Enemy ) then self:SetEyeAngles( LerpAngle(lerp, self:EyeAngles(), ( self.Goal - self:GetPos() ):GetNormalized():Angle() ) ) end
		
		local GoalIn2D			=	Vector( self.Goal.x , self.Goal.y , self:GetPos().z )
		-- Optionaly you could convert this to 2D navigation as well if you like.
		-- I prefer not to.
		if IsVecCloseEnough( self:GetPos() , GoalIn2D , 32 ) then
			
			self.Goal			=		nil -- We have reached our goal!
			
		end
		
		return
	end
	
	if self.Path[ 1 ] then
		
		local MovementAngle		=	( self.Path[ 1 ] - self:GetPos() ):GetNormalized():Angle()
		local lerp = math.random(0.4, 1.0)
		
		cmd:SetViewAngles( MovementAngle )
		cmd:SetForwardMove( self:GetMaxSpeed() )
		if !IsValid ( self.Enemy ) then self:SetEyeAngles( LerpAngle(lerp, self:EyeAngles(), ( self.Path[ 1 ] - self:GetPos() ):GetNormalized():Angle() ) ) end
		
	end
	
end

-- Gives us the best node and removes it from the open list and puts it in the closed list.
function Get_Best_Node()
	
	local BestNode		=	Open_List[ Open_List ]
	
	Open_List[ #Open_List ]		=	nil
	
	Node_Data[ BestNode:Node_Get_Type() ][ BestNode:GetID() ][ "State" ]	=	false
	
	return BestNode
end

function Sort_Open_List()
	
	local SortedList	=	{}
	local HasDoneLoop	=	false
	
	local UnsortedList	=	{}
	
	-- List all the nodes in the table.
	UnsortedList[ 1 ]	=	Open_List[ #Open_List ]
	Open_List[ #Open_List ]			=	nil
	
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 2 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]		=	nil
		
	end
	
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 3 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]		=	nil
		
	end
	--[[
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 4 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]				=	nil
		
	end
	
	if IsValid( Open_List[ #Open_List ] ) then
		
		UnsortedList[ 5 ]	=	Open_List[ #Open_List ]
		Open_List[ #Open_List ]				=	nil
		
	end
	]]
	
	for k, v in ipairs( UnsortedList ) do
		if !IsValid( v ) then continue end
		
		if table.IsEmpty( SortedList ) then
			
			SortedList[ 1 ]		=	v
			
			continue
		end
		
		for j, y in ipairs( SortedList ) do
			
			if v == y then
				
				HasDoneLoop		=	true
				
				break
			end
			
			if v:Get_F_Cost() > y:Get_F_Cost() then
				
				if IsValid( SortedList[ j ] ) then
					
					if IsValid( SortedList[ j + 1 ] ) then
						
						SortedList[ j + 2 ]	=	SortedList[ j + 1 ]
						
					end
					
					SortedList[ j + 1 ]		=	SortedList[ j ]
					
				end
				
				SortedList[ j ]		=	v
				
				--table.insert( SortedList , j , v )
				
				HasDoneLoop		=	true
				
				break
			end
			
		end
		
		if HasDoneLoop == true then HasDoneLoop		=	false continue end
		
		SortedList[ #SortedList + 1 ]	=	v
		
	end
	
	-- Add back all the sorted nodes to the table
	for k, v in ipairs( SortedList ) do
		if !IsValid( v ) then return end
		
		Open_List[ #Open_List + 1 ]		=	v
		
	end
	
end

function Zone:Get_F_Cost()
	
	
	return Node_Data[ 1 ][ self:GetID() ][ "FCost" ]
end

function Lad:Get_F_Cost()
	
	
	return Node_Data[ 2 ][ self:GetID() ][ "FCost" ]
end

-- Store the F cost, And no only for optimization.We don't do G + H as doing that everytime will give the same answer.
function Zone:Set_F_Cost( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "FCost" ]	=	cost
	
end

function Lad:Set_F_Cost( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "FCost" ]	=	cost
	
end




function Zone:Set_G_Cost( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "GCost" ]	=	cost
	
end

function Lad:Set_G_Cost( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "GCost" ]	=	cost
	
end




function Zone:Set_H_Cost( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "HCost" ]	=	cost
	
end

function Lad:Set_H_Cost( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "HCost" ]	=	cost
	
end




function Zone:Get_G_Cost( cost )
	
	return Node_Data[ 1 ][ self:GetID() ][ "GCost" ]
end

function Lad:Get_G_Cost( cost )
	
	return Node_Data[ 2 ][ self:GetID() ][ "GCost" ]
end



function Zone:Get_H_Cost( cost )
	
	return Node_Data[ 1 ][ self:GetID() ][ "HCost" ]
end

function Lad:Get_H_Cost( cost )
	
	return Node_Data[ 2 ][ self:GetID() ][ "HCost" ]
end






function Zone:Set_Parent_Node( SecondNode )
	
	Node_Data[ 1 ][ self:GetID() ][ "ParentNode" ]	=	SecondNode
	
end

function Lad:Set_Parent_Node( SecondNode )
	
	Node_Data[ 2 ][ self:GetID() ][ "ParentNode" ]	=	SecondNode
	
end




function Zone:Get_Parent_Node()
	
	return Node_Data[ 1 ][ self:GetID() ][ "ParentNode" ]
end

function Lad:Get_Parent_Node()
	
	return Node_Data[ 2 ][ self:GetID() ][ "ParentNode" ]
end




-- Hmm, I think we need this for the reparenting.
function Zone:Get_Current_Path_Length()
	
	
	return Node_Data[ 1 ][ self:GetID() ][ "PathLen" ]
end

function Lad:Get_Current_Path_Length()
	
	
	return Node_Data[ 2 ][ self:GetID() ][ "PathLen" ]
end



function Zone:Set_Current_Path_Length( cost )
	
	Node_Data[ 1 ][ self:GetID() ][ "PathLen" ]		=	cost
	
end

function Lad:Set_Current_Path_Length( cost )
	
	Node_Data[ 2 ][ self:GetID() ][ "PathLen" ]		=	cost
	
end

-- Checking if a node is closed or open without iliteration.
function Zone:Node_Is_Closed()
	
	if Node_Data[ 1 ][ self:GetID() ][ "State" ] == false then return true end
	
	return false
end

function Lad:Node_Is_Closed()
	
	if Node_Data[ 2 ][ self:GetID() ][ "State" ] == false then return true end
	
	return false
end


function Zone:Node_Is_Open()
	
	if Node_Data[ 1 ][ self:GetID() ][ "State" ] == true then return true end
	
	return false
end

function Lad:Node_Is_Open()
	
	if Node_Data[ 2 ][ self:GetID() ][ "State" ] == true then return true end
	
	return false
end




-- Remove from the open list.
-- How to advoid iliteration?
function Zone:Node_Remove_From_Open_List()
	
	for k, v in ipairs( Open_List ) do
		
		if v == self then
			
			table.remove( Open_List , k )
			
			break
		end
		
	end
	
	Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

function Lad:Node_Remove_From_Open_List()
	
	for k, v in ipairs( Open_List ) do
		
		if v == self then
			
			table.remove( Open_List , k )
			
			break
		end
		
	end
	
	Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

-- Add a node to the list.
-- Fun fact! This would be the first time i have really added any optimization to the open list.
function Zone:Node_Add_To_Open_List()
	
	local OurCost		=		self:Get_F_Cost()
	
	Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	true
	
	Open_List[ #Open_List + 1 ]			=	self
	
	Sort_Open_List()
	
end

function Lad:Node_Add_To_Open_List()
	
	local OurCost		=		self:Get_F_Cost()
	
	Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	true
	
	Open_List[ #Open_List + 1 ]			=	self
	
	Sort_Open_List()
	
end







function Zone:Node_Remove_From_Closed_List()
	
	Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

function Lad:Node_Remove_From_Closed_List()
	
	Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

-- Prepare everything for a new path find.
function Prepare_Path_Find()
	
	Node_Data	=	{ {} , {} }
	Open_List	=	{}
	
	for k, v in ipairs( navmesh.GetAllNavAreas() ) do
		
		local Lads	=	v:GetLadders()
		
		if istable( Lads ) then
			
			for j, y in ipairs( Lads ) do
				
				Node_Data[ 2 ][ y:GetID() ]		=	{
					
					Node			=	y,
					GCost			=	0,
					HCost			=	0,
					FCost			=	0,
					ParentNode		=	nil,
					State			=	"Unset",
					PathLen			=	0
					
				}
				
			end
			
		end
		
		Node_Data[ 1 ][ v:GetID() ]		=	{
			
			Node			=	v,
			GCost			=	0,
			HCost			=	0,
			FCost			=	0,
			ParentNode		=	nil,
			State			=	"Unset",
			PathLen			=	0 -- Incase our path is shorter a different way!
			
		}
		
	end
	
end

-- Just like GetAdjacentAreas but a more advanced one.
-- For both ladders and CNavAreas.
function Zone:Get_Connected_Areas()
	
	local AllNodes		=	self:GetAdjacentAreas()
	
	local AllLadders	=	self:GetLadders()
	
	for k, v in ipairs( AllLadders ) do
		
		AllNodes[ #AllNodes + 1 ]	=	v
		
	end
	
	return AllNodes
end

function Lad:Get_Connected_Areas()
	
	local AllNodes		=	{}
	
	local TopLArea		=	self:GetTopLeftArea()
	if IsValid( TopLArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopLArea
		
	end
	
	
	local TopRArea		=	self:GetTopRightArea()
	if IsValid( TopRArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopRArea
		
	end
	
	
	local TopBArea		=	self:GetTopBehindArea()
	if IsValid( TopBArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopBArea
		
	end
	
	local TopFArea		=	self:GetTopForwardArea()
	if IsValid( TopFArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	TopFArea
		
	end
	
	local BArea		=	self:GetBottomArea()
	if IsValid( BArea ) then
		
		AllNodes[ #AllNodes + 1 ]	=	BArea
		
	end
	
	return AllNodes
end

function BOT:Is_On_Ladder()
	
	if self:GetMoveType() == MOVETYPE_LADDER then
		
		return true
	end
	
	return false
end

function Lad:Get_Closest_Point( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		
		return self:GetTop()
	end
	
	return self:GetBottom()
end

-- See if a node is an area : 1 or a ladder : 2
function Zone:Node_Get_Type()
	
	return 1
end

function Lad:Node_Get_Type()
	
	return 2
end
