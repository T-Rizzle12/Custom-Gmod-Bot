-- TBotKnownEntity.lua
-- Purpose: This is the TBotKnownEntity MetaTable
-- Author: T-Rizzle

local TBotKnownEntityMeta = {}

TBotKnownEntityMeta.__index = TBotKnownEntityMeta

baseclass.Set( "TBotKnownEntity", TBotKnownEntityMeta ) -- Register this class so we can derive this for other gamemodes.

function TBotKnownEntity( who )
	local tbotknownentity = {}

	tbotknownentity.m_who = who
	tbotknownentity.m_whenLastSeen = -1.0
	tbotknownentity.m_whenLastBecameVisible = -1.0
	tbotknownentity.m_isVisible = false
	tbotknownentity.m_whenBecameKnown = CurTime()
	tbotknownentity.m_hasLastKnownPositionBeenSeen = false
	tbotknownentity.m_lastKnownPosition = nil
	tbotknownentity.m_lastKnownArea = nil
	tbotknownentity.m_whenLastKnown = CurTime()
	tbotknownentity.m_lastTimeTookDamageFromEnemy = -1.0
	setmetatable( tbotknownentity, TBotKnownEntityMeta )
	
	tbotknownentity:UpdatePosition()
	
	return tbotknownentity
	
end

function istbotknownentity( obj )

	return getmetatable( obj ) == TBotKnownEntityMeta
	
end

function TBotKnownEntityMeta:__eq( other )

	if !IsValid( self:GetEntity() ) or !istbotknownentity( other ) or !IsValid( other:GetEntity() ) then
	
		return false
		
	end
	
	return self:GetEntity() == other:GetEntity()
	
end

-- NEEDTOVALIDATE: Do we even need this?
function TBotKnownEntityMeta:Destroy()

	self.m_who = nil
	self.m_isVisible = false
	
end

function TBotKnownEntityMeta:GetEntity()

	return self.m_who
	
end

function TBotKnownEntityMeta:UpdatePosition()

	if IsValid( self.m_who ) then
	
		self.m_lastKnownPosition = self.m_who:GetPos()
		self.m_lastKnownArea = self.m_who:GetLastKnownArea()
		self.m_whenLastKnown = CurTime()
		
	end
	
end

function TBotKnownEntityMeta:GetLastKnownPosition()

	return self.m_lastKnownPosition
	
end

function TBotKnownEntityMeta:HasLastKnownPositionBeenSeen()

	return self.m_hasLastKnownPositionBeenSeen
	
end

function TBotKnownEntityMeta:MarkLastKnownPositionAsSeen()

	self.m_hasLastKnownPositionBeenSeen = true
	
end

function TBotKnownEntityMeta:GetLastKnownArea()

	return self.m_lastKnownArea
	
end

function TBotKnownEntityMeta:GetTimeSinceLastKnown()

	return CurTime() - self.m_whenLastKnown
	
end

function TBotKnownEntityMeta:GetTimeSinceBecameKnown()

	return CurTime() - self.m_whenBecameKnown
	
end

function TBotKnownEntityMeta:UpdateVisibilityStatus( visible )

	if visible then
	
		if !self.m_isVisible then
		
			self.m_whenLastBecameVisible = CurTime()
			
		end
		
		self.m_whenLastSeen = CurTime()
		
	end
	
	self.m_isVisible = visible
	
end

function TBotKnownEntityMeta:IsVisibleInFOVNow()

	return self.m_isVisible
	
end

function TBotKnownEntityMeta:IsVisibleRecently()

	if self.m_isVisible then
	
		return true
		
	end
	
	if self:WasEverVisible() and self:GetTimeSinceLastSeen() < 3.0 then
	
		return true
		
	end
	
	return false
	
end

function TBotKnownEntityMeta:GetTimeSinceBecameVisible()

	return CurTime() - self.m_whenLastBecameVisible
	
end

function TBotKnownEntityMeta:GetTimeWhenBecameVisible()

	return self.m_whenLastBecameVisible
	
end

function TBotKnownEntityMeta:GetTimeSinceLastSeen()

	return CurTime() - self.m_whenLastSeen
	
end

function TBotKnownEntityMeta:WasEverVisible()

	return self.m_whenLastSeen > 0.0
	
end

function TBotKnownEntityMeta:MarkTookDamageFromEnemy()

	self.m_lastTimeTookDamageFromEnemy = CurTime()
	
end

function TBotKnownEntityMeta:GetLastTimeSinceTookDamageFromEnemy()

	return CurTime() - self.m_lastTimeTookDamageFromEnemy
	
end

function TBotKnownEntityMeta:TookDamageFromRecently()
	if self.m_lastTimeTookDamageFromEnemy <= 0.0 then return false end
	
	return self:GetLastTimeSinceTookDamageFromEnemy() < 3.0
	
end
	

function TBotKnownEntityMeta:IsObsolete()

	if !IsValid( self:GetEntity() ) or self:GetTimeSinceLastKnown() > 10.0 then
	
		return true
		
	end
	
	local entity = self:GetEntity()
	if entity:IsPlayer() and !entity:Alive() then
	
		return true
		
	end
	
	if entity:IsNPC() and !entity:IsAlive() then
	
		return true
		
	end
	
	if entity:IsNextBot() and entity:Health() < 1 then
	
		return true
		
	end
	
	return false
	
end

function TBotKnownEntityMeta:Is( who )

	if !IsValid( self:GetEntity() ) or !IsValid( who ) then
	
		return false
		
	end
	
	return self:GetEntity() == who
	
end