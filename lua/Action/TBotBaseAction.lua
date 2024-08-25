-- TBotBaseAction.lua
-- Purpose: This is the TBotBaseAction MetaTable
-- Author: T-Rizzle

-- The possible consequences of an action
TBotActionResultType = {}
TBotActionResultType.CONTINUE		=	0 -- Continue executing this action next frame - nothing has changed
TBotActionResultType.CHANGE_TO		=	1 -- Change actions next frame
TBotActionResultType.SUSPEND_FOR	=	2 -- Put the current action on hold for the new action
TBotActionResultType.DONE			=	3 -- This action has finished, resume suspended action
TBotActionResultType.SUSTAIN		=	4 -- For use with event handlers - a way to say "It's important to keed doing what I'm doing"

-- Since behaviors can have several concurrent actions active, we ask
-- the topmost child action first, and if it defers, its parent, and so
-- on, until we get a definitive answer.
TBotQueryResultType = {}
TBotQueryResultType.ANSWER_NO			=	0
TBotQueryResultType.ANSWER_YES			=	1
TBotQueryResultType.ANSWER_UNDEFINED	=	2

-- When an event is processed, it returns this DESIRED result,
-- which may or MAY NOT happen, depending on other event results,
-- that occur simultaneously.
-- Do not assemble this yourself - use TryContinue(), TryChangeTo(), TryDone(), TryToSustain()
-- and TrySuspendFor() methods within Action.
TBotEventResultPriorityType = {}
TBotEventResultPriorityType.RESULT_NONE			=	0 -- No result
TBotEventResultPriorityType.RESULT_TRY			=	1 -- Use this result, or toss it out, either is ok
TBotEventResultPriorityType.RESULT_IMPORTANT	=	2 -- Try extra-hard to use this result
TBotEventResultPriorityType.RESULT_CRITICAL		=	3 -- This result must be used - emit an error if it can't be

-- Actions and Event processors return results derived from this class.
-- Do not assemble this yourself - use the Continue(), ChangeTo(), Done(), and SuspendFor()
-- methods within Action
local TBotActionResultMeta = {}

TBotActionResultMeta.__index = TBotActionResultMeta

function TBotActionResult( type, action, reason )
	local tbotactionresult = {}
	
	tbotactionresult.m_type = tonumber( type ) or TBotActionResultType.CONTINUE
	tbotactionresult.m_action = action
	tbotactionresult.m_reason = reason
	
	setmetatable( tbotactionresult, TBotActionResultMeta )
	
	return tbotactionresult

end

function TBotActionResultMeta:IsDone()

	return self.m_type == TBotActionResultType.DONE
	
end

function TBotActionResultMeta:IsContinue()

	return self.m_type == TBotActionResultType.CONTINUE
	
end

function TBotActionResultMeta:IsRequestingChange()

	return self.m_type == TBotActionResultType.CHANGE_TO or self.m_type == TBotActionResultType.SUSPEND_FOR or self.m_type == TBotActionResultType.DONE
	
end

function TBotActionResultMeta:GetTypeName()

	local type = self.m_type
	if type == TBotActionResultType.CHANGE_TO then
	
		return "CHANGE_TO"
		
	elseif type == TBotActionResultType.SUSPEND_FOR then
	
		return "SUSPEND_FOR"
		
	elseif type == TBotActionResultType.DONE then
	
		return "DONE"
		
	elseif type == TBotActionResultType.SUSTAIN then
	
		return "SUSTAIN"
		
	end
	
	return "CONTINUE"
	
end

-- This inherits from the Action Result class.
local TBotEventDesiredResultMeta = {}

function TBotEventDesiredResultMeta:__index( key )

	-- Search the metatable.
	local val = TBotEventDesiredResultMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = TBotActionResultMeta[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotEventDesiredResult( type, action, priority, reason )
	local tboteventdesiredresult = TBotActionResult( type, action, reason )

	tboteventdesiredresult.m_priority = priority
	
	setmetatable( tboteventdesiredresult, TBotEventDesiredResultMeta )
	
	return tboteventdesiredresult

end

local TBotContextualQueryMeta = {}

TBotContextualQueryMeta.__index = TBotContextualQueryMeta

-- If the desired item was available right now, should we pick it up?
function TBotContextualQueryMeta:ShouldPickUp( me, item )

	return TBotQueryResultType.ANSWER_UNDEFINED
	
end

-- Are we in a hurry?
function TBotContextualQueryMeta:ShouldHurry( me )

	return TBotQueryResultType.ANSWER_UNDEFINED
	
end

-- Is it time to retreat?
function TBotContextualQueryMeta:ShouldRetreat( me )

	return TBotQueryResultType.ANSWER_UNDEFINED
	
end

-- Should we attack "them"
function TBotContextualQueryMeta:ShouldAttack( me, them )

	return TBotQueryResultType.ANSWER_UNDEFINED
	
end

-- NEEDTOVALIDATE: Do TRizzleBots even call this?
-- Return true if we should wait for 'blocker' that is across our path somewhere up ahead.
function TBotContextualQueryMeta:IsHindrance( me, blocker )

	return TBotQueryResultType.ANSWER_UNDEFINED
	
end

-- Given a subject, return the world space postion we should aim at.
function TBotContextualQueryMeta:SelectTargetPoint( me, subject )

	return Vector()
	
end

-- NEEDTOVALIDATE: Do we even need this?
-- Allow bot to approve of positions game movement tries to put him into.
-- This is most useful for bots derived from CBasePlayer that go through
-- the player movement system.
function TBotContextualQueryMeta:IsPositionAllowed( me, pos )

	return TBotQueryResultType.ANSWER_UNDEFINED
	
end

-- NOTE: threat1 and threat2 should be TBotKnownEntities
function TBotContextualQueryMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	return
	
end

local TBotBehaviorMeta = {}

function TBotBehaviorMeta:__index( key )

	-- Search the metatable.
	local val = TBotBehaviorMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = TBotContextualQueryMeta[ key ]
	if val != nil then return val end
	
	return nil
	
end

function TBotBehavior( initalAction, name )
	local tbotbehavior = {}
	
	tbotbehavior.m_name = name or ""
	tbotbehavior.m_action = initalAction
	tbotbehavior.m_me = nil
	tbotbehavior.m_deadActionVector = {}
	
	setmetatable( tbotbehavior, TBotBehaviorMeta )

	return tbotbehavior

end

-- NEEDTOVALIDATE: Do we need this?
TBotBehaviorMeta.__gc = function( self )

	if self.m_me and self.m_action then
	
		-- Allow all currently action actions to end
		self.m_action:InvokeOnEnd( self.m_me, self )
		self.m_me = nil
		
	end
	
	-- Dig down to the bottom of the action stack and delete
	-- that, so we don't leak action memory since action 
	-- destructors intentionally don't delete actions
	-- "buried" underneath them
	local bottomAction = self.m_action
	while bottomAction and bottomAction.m_buriedUnderMe do
	
		bottomAction = bottomAction.m_buriedUnderMe
	
	end
	
	if bottomAction then
	
		bottomAction:Remove() -- In the TF2 Source Code the action would be "deleted" here
		
	end
	
	-- Delete any dead Actions
	for k, action in ipairs( self.m_deadActionVector ) do
	
		action:Remove()
		
	end
	self.m_deadActionVector = nil
	
	
end

function TBotBehaviorMeta:Remove()

	if self.m_me and self.m_action then
	
		-- Allow all currently action actions to end
		self.m_action:InvokeOnEnd( self.m_me, self )
		self.m_me = nil
		
	end
	
	-- Dig down to the bottom of the action stack and delete
	-- that, so we don't leak action memory since action 
	-- destructors intentionally don't delete actions
	-- "buried" underneath them
	local bottomAction = self.m_action
	while bottomAction and bottomAction.m_buriedUnderMe do
	
		bottomAction = bottomAction.m_buriedUnderMe
	
	end
	
	if bottomAction then
	
		bottomAction:Remove() -- In the TF2 Source Code the action would be "deleted" here
		
	end
	
	-- Delete any dead Actions
	for k, action in ipairs( self.m_deadActionVector ) do
	
		action:Remove()
		
	end
	self.m_deadActionVector = {}
	
end

function TBotBehaviorMeta:Reset( action )

	if self.m_me and self.m_action then
	
		-- Allow all currently action actions to end
		self.m_action:InvokeOnEnd( self.m_me, self )
		self.m_me = nil
		
	end
	
	-- Find the "bottom" action (see comment in destructor)
	local bottomAction = self.m_action
	while bottomAction and bottomAction.m_buriedUnderMe do
	
		bottomAction = bottomAction.m_buriedUnderMe
	
	end
	
	if bottomAction then
	
		bottomAction:Remove() -- In the TF2 Source Code the action would be "deleted" here
		
	end
	
	-- Delete any dead Actions
	for k, action in ipairs( self.m_deadActionVector ) do
	
		action:Remove()
		
	end
	self.m_deadActionVector = {}
	
	self.m_action = action
	
end

function TBotBehaviorMeta:IsEmpty()

	return self.m_action == nil
	
end

function TBotBehaviorMeta:Update( me, interval )

	if !IsValid( me ) or self:IsEmpty() then
	
		return
		
	end
	
	self.m_me = me
	
	self.m_action = self.m_action:ApplyResult( me, self, self.m_action:InvokeUpdate( me, self, interval ) )
	
	--[[if false and GetConVar( "developer" ):GetBool() then
	
		-- TODO: Implement debug code from TF2 source code!
		
	end]]
	
	-- Delete any dead Actions
	for k, action in ipairs( self.m_deadActionVector ) do
	
		action:Remove()
		
	end
	self.m_deadActionVector = {}
	
end

function TBotBehaviorMeta:Resume( me )

	if !IsValid( me ) or self:IsEmpty() then
	
		return
		
	end
	
	self.m_action = self.m_action:ApplyResult( me, self, self.m_action:OnResume( me ) )
	
end

-- Use this method to destroy Actions used by this Behavior.
-- We cannot delete Actions in-line since Action updates can potentially
-- invoke event responders which will then use potentially deleted
-- Action pointers, causing memory corruption.
-- Instead, we will collect the dead Actions and delete them at the
-- end of Update().
function TBotBehaviorMeta:DestoryAction( dead )

	table.insert( self.m_deadActionVector, dead )
	
end

function TBotBehaviorMeta:GetName()

	return self.m_name
	
end

function TBotBehaviorMeta:FirstContainedResponder()

	return self.m_action
	
end

function TBotBehaviorMeta:NextContainedResponder( current )

	return
	
end

function TBotBehaviorMeta:ShouldPickUp( me, item )

	local result = TBotQueryResultType.ANSWER_UNDEFINED
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
			
				result = action:ShouldPickUp( me, item )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

function TBotBehaviorMeta:ShouldHurry( me )

	local result = TBotQueryResultType.ANSWER_UNDEFINED
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
			
				result = action:ShouldHurry( me )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

function TBotBehaviorMeta:ShouldRetreat( me )

	local result = TBotQueryResultType.ANSWER_UNDEFINED
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
			
				result = action:ShouldRetreat( me )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

function TBotBehaviorMeta:ShouldAttack( me, them )

	local result = TBotQueryResultType.ANSWER_UNDEFINED
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
			
				result = action:ShouldAttack( me, them )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

function TBotBehaviorMeta:IsHindrance( me, blocker )

	local result = TBotQueryResultType.ANSWER_UNDEFINED
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
			
				result = action:IsHindrance( me, blocker )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

function TBotBehaviorMeta:SelectTargetPoint( me, subject )

	local result = Vector()
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and result:IsZero() do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and result:IsZero() do
			
				result = action:SelectTargetPoint( me, subject )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

function TBotBehaviorMeta:IsPositionAllowed( me, pos )

	local result = TBotQueryResultType.ANSWER_UNDEFINED
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and result == TBotQueryResultType.ANSWER_UNDEFINED do
			
				result = action:IsPositionAllowed( me, pos )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

function TBotBehaviorMeta:SelectMoreDangerousThreat( me, threat1, threat2 )

	local result = nil
	
	if self.m_action then
	
		-- Find innermost child action
		local action = self.m_action
		while action.m_child do
		
			action = action.m_child
			
		end
		
		-- Work our way up the stack
		while action and !result do
		
			local containingAction = action.m_parent
			
			-- Work our way up the stack
			while action and !result do
			
				result = action:SelectMoreDangerousThreat( me, threat1, threat2 )
				action = action:GetActionBuriedUnderMe()
				
			end
			
			action = containingAction
			
		end
		
	end
	
	return result
	
end

local TBotBaseActionMeta = {}
local TBotActionTable = {} -- HACKHACK: We keep reference of every action created here to we can send them hook events!

function TBotBaseActionMeta:__index( key )

	-- Search the metatable.
	local val = TBotBaseActionMeta[ key ]
	if val != nil then return val end
	
	-- Search the base class.
	val = TBotContextualQueryMeta[ key ]
	if val != nil then return val end
	
	return nil
	
end

baseclass.Set( "TBotBaseAction", TBotBaseActionMeta ) -- Register this class so we can derive this for new actions.

function TBotBaseAction()
	local tbotbaseaction = {}
	
	tbotbaseaction.m_parent = nil
	tbotbaseaction.m_child = nil
	tbotbaseaction.m_buriedUnderMe = nil
	tbotbaseaction.m_coveringMe = nil
	tbotbaseaction.m_actor = nil
	tbotbaseaction.m_behavior = nil
	
	tbotbaseaction.m_isStarted = false
	tbotbaseaction.m_isSuspended = false
	
	setmetatable( tbotbaseaction, TBotBaseActionMeta )
	
	tbotbaseaction.m_eventResult = TBotEventDesiredResult( TBotActionResultType.CONTINUE, nil, TBotEventResultPriorityType.RESULT_NONE ) -- HACKHACK: For some reason this creates errors: tbotbaseaction:TryContinue( TBotEventResultPriorityType.RESULT_NONE )
	
	TBotActionTable[ tbotbaseaction ] = true -- Append to the action table so we send hook events to them!
	
	return tbotbaseaction

end

-- NEEDTOVALIDATE: Do we need this?
TBotBaseActionMeta.__gc = function( self )
	
	TBotActionTable[ self ] = nil -- Remove the action from the action table so it gets GC.
	
	if self.m_parent then
	
		-- If I'm my parents active child, update parent's pointer
		if self.m_parent.m_child == self then
		
			self.m_parent.m_child = self.m_buriedUnderMe
			
		end
		
	end
	
	-- Delete all my children.
	-- our m_child pointer always points to the topmost
	-- child in the stack, so work our way back thru the
	-- 'buried' children and delete them.
	local child, nextChild = self.m_child, nil
	while child do
	
		nextChild = child.m_buriedUnderMe
		child.m_buriedUnderMe = nil
		child:Remove()
		child = nextChild
		
	end
	
	if self.m_buriedUnderMe then
	
		-- We're going away, so my buried sibling is now on top
		
		self.m_buriedUnderMe.m_coveringMe = nil
		
	end
	
	-- Delete any actions stacked on top of me
	if self.m_coveringMe then
	
		-- Recurstion will march down on top of me
		self.m_coveringMe:Remove()
		self.m_coveringMe = nil
		
	end
	
	-- Delete any pending event result
	if self.m_eventResult.m_action then
	
		self.m_eventResult.m_action:Remove()
		self.m_eventResult.m_action = nil
		
	end
	
end

-- INTERNAL: This must be called before an action is removed!!!
function TBotBaseActionMeta:Remove()

	TBotActionTable[ self ] = nil -- Remove the action from the action table so it gets GC.

	if self.m_parent then
	
		-- If I'm my parents active child, update parent's pointer
		if self.m_parent.m_child == self then
		
			self.m_parent.m_child = self.m_buriedUnderMe
			
		end
		
	end
	
	-- Delete all my children.
	-- our m_child pointer always points to the topmost
	-- child in the stack, so work our way back thru the
	-- 'buried' children and delete them.
	local child, nextChild = self.m_child, nil
	while child do
	
		nextChild = child.m_buriedUnderMe
		child.m_buriedUnderMe = nil
		child:Remove()
		child = nextChild
		
	end
	
	if self.m_buriedUnderMe then
	
		-- We're going away, so my buried sibling is now on top
		
		self.m_buriedUnderMe.m_coveringMe = nil
		
	end
	
	-- Delete any actions stacked on top of me
	if self.m_coveringMe then
	
		-- Recurstion will march down on top of me
		self.m_coveringMe:Remove()
		self.m_coveringMe = nil
		
	end
	
	-- Delete any pending event result
	if self.m_eventResult.m_action then
	
		self.m_eventResult.m_action:Remove()
		self.m_eventResult.m_action = nil
		
	end
	
end

function TBotBaseActionMeta:GetName()

	return "BaseAction"
	
end

function TBotBaseActionMeta:GetActionBuriedUnderMe()

	return self.m_buriedUnderMe
	
end

function TBotBaseActionMeta:GetActionCoveringMe()

	return self.m_coveringMe
	
end

function TBotBaseActionMeta:IsOutOfScope()

	local under = self:GetActionBuriedUnderMe()
	while under do
	
		if under.m_eventResult.m_type == TBotActionResultType.CHANGE_TO or under.m_eventResult.m_type == TBotActionResultType.DONE then
		
			return true
			
		end
		
		under = under:GetActionBuriedUnderMe()
		
	end
	
	return false
	
end

function TBotBaseActionMeta:ProcessPendingEvents()

	-- If an event has requested a change, honor it
	if self.m_eventResult:IsRequestingChange() then
	
		local result = TBotActionResult( self.m_eventResult.m_type, self.m_eventResult.m_action, self.m_eventResult.m_reason )
		
		-- Clear even result in case this change is a suspend and we later resume this action
		self.m_eventResult = self:TryContinue( TBotEventResultPriorityType.RESULT_NONE )
		
		return result
		
	end
	
	-- Check for pending event changes buried in the stack
	local under = self:GetActionBuriedUnderMe()
	while under do
	
		if under.m_eventResult.m_type == TBotActionResultType.SUSPEND_FOR then
		
			-- Process this pending even in-place and push new Action on top of the stack
			local result = TBotActionResult( under.m_eventResult.m_type, under.m_eventResult.m_action, under.m_eventResult.m_reason )
			
			-- Clear event result in case this change is a suspend and we later resume this action
			under.m_eventResult = self:TryContinue( TBotEventResultPriorityType.RESULT_NONE )
			
			return result
			
		end
		
		under = under:GetActionBuriedUnderMe()
		
	end
	
	return self:Continue()
	
end

-- This registers a hook under the action system to be called for every action when it occurs.
-- FIXME: We keep reference of every action created here to we can send them hook events!
-- There has to be a better way of keeping track of every action......
function RegisterTBotActionHook( newHook )

	-- NOTE: If this is called again after the hook has already been created, there is nothing to worry about
	-- since it will just "override" the old hook function with the "new" one.
	hook.Add( newHook, "TBotAction" .. newHook, function( ... ) 
	
		for action, _ in pairs( TBotActionTable ) do
		
			action:ProcessHookEvent( newHook, ... )
			
		end
	
	end)
	
end

-- This unregisters a hook under the action system. This really should never be used, but then again who knows?
function UnRegisterTBotActionHook( oldHook )

	hook.Remove( oldHook, "TBotAction" .. oldHook )
	
end

-- Register some default events for the action system!
-- NOTE: You can add the register hook function to your custom actions.
RegisterTBotActionHook( "DoPlayerDeath" )
RegisterTBotActionHook( "PlayerDeath" )
RegisterTBotActionHook( "PostPlayerDeath" )
RegisterTBotActionHook( "PlayerSilentDeath" )
RegisterTBotActionHook( "EntityEmitSound" )
RegisterTBotActionHook( "EntityTakeDamage" )
RegisterTBotActionHook( "PlayerHurt" )
RegisterTBotActionHook( "PlayerSay" )
RegisterTBotActionHook( "PlayerSpawn" )
RegisterTBotActionHook( "OnPlayerJump" )
RegisterTBotActionHook( "OnPlayerHitGround" )
RegisterTBotActionHook( "EntityRemoved" )
RegisterTBotActionHook( "OnNPCKilled" )
RegisterTBotActionHook( "PlayerDisconnected" )

-- Register the TBot hooks from the Vision, Body, and Locomotion interfaces!
RegisterTBotActionHook( "TBotOnStuck" )
RegisterTBotActionHook( "TBotOnUnStuck" )
RegisterTBotActionHook( "TBotOnSight" )
RegisterTBotActionHook( "TBotOnLostSight" )

-- When a hook is called, this function sends that hook event to all actions.
-- Which allows them to respond to the event in their own way.
function TBotBaseActionMeta:ProcessHookEvent( method, ... )

	if !self.m_isStarted then
	
		return
		
	end
	
	local _action = self
	local _result = self:TryContinue( TBotEventResultPriorityType.RESULT_NONE )
	
	while _action do
	
		-- We have to make sure the hook function exists, which it should, or the game will create errors.
		--[[ Example:
		
			function ExampleActionMeta:PlayerHurt( me, victim, attacker, healthRemaining, damageTaken )
			
				-- NOTE: me is the bot who the action belongs too!!!!
				-- This allows the bot to respond when something happens!
				if me != victim and me:Team() == victim:Team() then
				
					print( "s%'s Teammate s% was attacked!!!!".format( me:Nick(), victim:Nick() ) )
					
				end
				
				-- WARNING: You must return an TBotEventDesiredResult or else unexpected errors can occur!!!
				-- You should either use TryContinue(), TryChangeTo(), TryDone(), TryToSustain(), or TrySuspendFor()
				return self:TryContinue()
			
			end
		
		]]
		-- HACKHACK: We check if the actor is vaild since when the server shuts down this creates errors.....
		local hookFunc = _action[ method ] -- We can't do _action.method since it won't be dynamic. :(
		if isfunction( hookFunc ) and IsValid( self.m_actor ) then
		
			_result = hookFunc( _action, self.m_actor, ... ) or _result
			
		end
		
		if _result and !_result:IsContinue() then
		
			break
			
		end
		
		_action = _action:GetActionBuriedUnderMe()
		
	end
	
	if _action then
	
		_action:StorePendingEventResult( _result, method )
		
	end
	
end

function TBotBaseActionMeta:StorePendingEventResult( result, eventName )

	if result:IsContinue() then
	
		return
		
	end
	
	if result.m_priority >= self.m_eventResult.m_priority then
	
		if self.m_eventResult.m_priority == TBotEventResultPriorityType.RESULT_CRITICAL then
		
			print( string.format( "%i: WARNING: %s::%s() RESULT_CRITICAL collision\n", CurTime(), self:GetName(), eventName or "" ) )
			
		end
		
		-- New result as important or more so - destory the replaced action
		if self.m_eventResult.m_action then
		
			self.m_eventResult.m_action:Remove()
			self.m_eventResult.m_action = nil
			
		end
		
		-- We keep the most recently processed event because this allows code to check history/state to
		-- do custom event collision handling. If we keep the first event at this priority and discard
		-- subsequent events (original behavior) there is no way to predict future collision resolutions (MSB).
		self.m_eventResult = result
		
	else
	
		-- New result is lower priority than previously stored result - discard it.
		if result.m_action then
		
			result.m_action:Remove()
			result.m_action = nil
			
		end
		
	end
	
end

function TBotBaseActionMeta:GetActor()

	return self.m_actor
	
end

function TBotBaseActionMeta:OnStart( me, priorAction )

	return self:Continue()
	
end

function TBotBaseActionMeta:Update( me, interval )

	return self:Continue()
	
end

function TBotBaseActionMeta:OnEnd( me, nextAction )

	return
	
end

function TBotBaseActionMeta:OnSuspend( me, interruptingAction )

	return self:Continue()
	
end

function TBotBaseActionMeta:OnResume( me, interruptingAction )

	return self:Continue()
	
end

function TBotBaseActionMeta:InitialContainedAction( me )

	return nil
	
end

function TBotBaseActionMeta:Continue()

	return TBotActionResult( TBotActionResultType.CONTINUE )
	
end

function TBotBaseActionMeta:ChangeTo( action, reason )

	return TBotActionResult( TBotActionResultType.CHANGE_TO, action, reason )
	
end

function TBotBaseActionMeta:SuspendFor( action, reason )

	self.m_eventResult = self:TryContinue( TBotEventResultPriorityType.RESULT_NONE )
	
	return TBotActionResult( TBotActionResultType.SUSPEND_FOR, action, reason )
	
end

function TBotBaseActionMeta:Done( reason )

	return TBotActionResult( TBotActionResultType.DONE, nil, reason )
	
end

function TBotBaseActionMeta:TryContinue( priority )

	return TBotEventDesiredResult( TBotActionResultType.CONTINUE, nil, tonumber( priority ) or TBotEventResultPriorityType.RESULT_TRY )
	
end

function TBotBaseActionMeta:TryChangeTo( action, priority, reason )

	return TBotEventDesiredResult( TBotActionResultType.CHANGE_TO, action, tonumber( priority ) or TBotEventResultPriorityType.RESULT_TRY, reason )
	
end

function TBotBaseActionMeta:TrySuspendFor( action, priority, reason )

	return TBotEventDesiredResult( TBotActionResultType.SUSPEND_FOR, action, tonumber( priority ) or TBotEventResultPriorityType.RESULT_TRY, reason )
	
end

function TBotBaseActionMeta:TryDone( priority, reason )

	return TBotEventDesiredResult( TBotActionResultType.DONE, nil, tonumber( priority ) or TBotEventResultPriorityType.RESULT_TRY, reason )
	
end

function TBotBaseActionMeta:TryToSustain( priority, reason )

	return TBotEventDesiredResult( TBotActionResultType.SUSTAIN, nil, tonumber( priority ) or TBotEventResultPriorityType.RESULT_TRY, reason )
	
end

function TBotBaseActionMeta:GetActiveChildAction()

	return self.m_child
	
end

function TBotBaseActionMeta:GetParentAction()

	return self.m_parent
	
end

function TBotBaseActionMeta:IsSupended()

	return self.m_isSuspended
	
end

function TBotBaseActionMeta:InvokeOnStart( me, behavior, priorAction, buriedUnderMeAction )

	-- These value must be vaild before invoking OnStart, in case an OnSuspend happens
	self.m_isStarted = true
	self.m_actor = me
	self.m_behavior = behavior
	
	-- Maintain parent/child relationship during transitions
	if priorAction then
	
		self.m_parent = priorAction.m_parent
		
	end
	
	if self.m_parent then
	
		-- Child pointer of an Action always points to the ACTIVE child
		-- parent pointers are set when child Actions are instantiated
		self.m_parent.m_child = self
		
	end
	
	-- Maintain stack pointers
	self.m_buriedUnderMe = buriedUnderMeAction
	if buriedUnderMeAction then
	
		buriedUnderMeAction.m_coveringMe = self
		
	end
	
	-- We are always on top of the stack. If our priorAction was buried, it cleared
	-- everything covering it when it ended (which happens before we start)
	self.m_coveringMe = nil
	
	-- Start the optional child action
	self.m_child = self:InitialContainedAction( me )
	if self.m_child then
	
		-- Define inital parent/child relationship
		self.m_child.m_parent = self
		
		self.m_child = self.m_child:ApplyResult( me, behavior, self:ChangeTo( self.m_child, "Starting child Action" ) )
		
	end
	
	result = self:OnStart( me, priorAction )
	
	return result
	
end

function TBotBaseActionMeta:InvokeUpdate( me, behavior, interval )

	-- An explicit "out of scope" check is needed here to prevent any
	-- pending events causing an out of scope action to linger
	if self:IsOutOfScope() then
	
		-- Exit self to make this action active and allow result to take effect on its next Update
		return self:Done( "Out of scope" )
		
	end
	
	if !self.m_isStarted then
	
		-- This Action has not yet begun - start it
		return self:ChangeTo( self, "Starting Action" )
		
	end
	
	local eventResult = self:ProcessPendingEvents()
	if !eventResult:IsContinue() then
	
		return eventResult
		
	end
	
	-- Update our child action first, since it has the most specific behavior
	if self.m_child then
	
		self.m_child = self.m_child:ApplyResult( me, behavior, self.m_child:InvokeUpdate( me, behavior, interval ) )
		
	end
	
	-- Update ourselves
	local result = self:Update( me, interval )
	
	return result
	
end

function TBotBaseActionMeta:InvokeOnEnd( me, behavior, nextAction )

	if !self.m_isStarted then
	
		-- We are not started (or never were)
		return
		
	end
	
	self.m_isStarted = false
	
	-- Tell child Action(s) to leave (but don't disturb the list itself)
	local child, nextChild = self.m_child, nil
	while child do
	
		nextChild = child.m_buriedUnderMe
		child:InvokeOnEnd( me, behavior, nextAction )
		child = nextChild
		
	end
	
	-- Leave ourself
	self:OnEnd( me, nextAction )
	
	-- Leave any Actions stacked on top of me
	if self.m_coveringMe then
	
		self.m_coveringMe:InvokeOnEnd( me, behavior, nextAction )
		
	end
	
end

function TBotBaseActionMeta:InvokeOnSuspend( me, behavior, interruptingAction )

	-- Suspend child Action
	if self.m_child then
	
		self.m_child = self.m_child:InvokeOnSuspend( me, behavior, interruptingAction )
		
	end
	
	self.m_isSuspended = true
	result = self:OnSuspend( me, interruptingAction )
	
	if result:IsDone() then
	
		-- We want to be replaced instead of suspended
		self:InvokeOnEnd( me, behavior )
		
		buried = self:GetActionBuriedUnderMe()
		
		behavior:DestoryAction( self )
		
		-- New Action on top of the stack
		return buried
		
	end
	
	-- We are still on top of the stack at this moment
	return self
	
end

function TBotBaseActionMeta:InvokeOnResume( me, behavior, interruptingAction )

	if !self.m_isSuspended then
	
		-- We were never suspended
		return self:Continue()
		
	end
	
	if self.m_eventResult:IsRequestingChange() then
	
		-- This action is not actually being Resumed, because a change
		-- is already pending from a prior event
		return self:Continue()
		
	end
	
	-- Resume ourselves
	self.m_isSuspended = false
	self.m_coveringMe = nil
	
	if self.m_parent then
	
		-- We are once again our parent's active child
		self.m_parent.m_child = self
		
	end
	
	-- Resume child Action
	if self.m_child then
	
		self.m_child = self.m_child:ApplyResult( me, behavior, self.m_child:InvokeOnResume( me, behavior, interruptingAction ) )
		
	end
	
	-- Actually resume ourselves
	local result = self:OnResume( me, interruptingAction )
	
	return result
	
end

function TBotBaseActionMeta:ApplyResult( me, behavior, result )

	local newAction = result.m_action
	
	-- Transition to new Action
	if result.m_type == TBotActionResultType.CHANGE_TO then
	
		if !newAction then
		
			print( "ERROR: Attemped CHANGE_TO to a NULL Action" )
			print( "Action: Attemped to CHANGE_TO to a NULL Action" )
			return self
			
		end
		
		-- We are done
		self:InvokeOnEnd( me, behavior, newAction )
		
		-- Start the new Action
		local startResult = newAction:InvokeOnStart( me, behavior, self, self.m_buriedUnderMe )
		
		-- Discard ended action
		if self != newAction then
		
			behavior:DestoryAction( self )
			
		end
		
		-- Apply result of starting the Action
		return newAction:ApplyResult( me, behavior, startResult )
	
	-- Temporarily suspend ourselves for the newAction, covering it on the stack
	elseif result.m_type == TBotActionResultType.SUSPEND_FOR then
	
		-- Interrupting Action always goes on the Top of the stack - find it
		local topAction = self
		while topAction.m_coveringMe do
		
			topAction = topAction.m_coveringMe
			
		end
		
		-- Suspend the Action we just covered up
		topAction = topAction:InvokeOnSuspend( me, behavior, newAction )
		
		-- Begin the interrupting Action.
		local startResult = newAction:InvokeOnStart( me, behavior, topAction, topAction )
		
		return newAction:ApplyResult( me, behavior, startResult )
		
	elseif result.m_type == TBotActionResultType.DONE then
	
		-- Resume buried action
		resumedAction = self.m_buriedUnderMe
		
		-- We are finished
		self:InvokeOnEnd( me, behavior, resumedAction )
		
		if !resumedAction then
		
			-- All Actions complete
			behavior:DestoryAction( self )
			return
			
		end
		
		-- Resume uncovered action
		local resumeResult = resumedAction:InvokeOnResume( me, behavior, self )
		
		-- Discard ended action
		behavior:DestoryAction( self )
		
		-- Apply result of OnResume()
		return resumedAction:ApplyResult( me, behavior, resumeResult )
	
	end
	
	-- CONTINUE and SUSTAIN
	-- No change, continue the current action next frame
	return self
	
end

function TBotBaseActionMeta:FirstContainedResponder()

	return self:GetActiveChildAction()
	
end

function TBotBaseActionMeta:NextContainedResponder( current )

	return
	
end