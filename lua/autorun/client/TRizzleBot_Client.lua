-- TRizzleBot_Client.lua
-- Purpose: This is a base that can be modified to play other gamemodes
-- Author: T-Rizzle

-- This is the flashlight check for the bots
net.Receive("TRizzleBotFlashlight", function()
    local flashlights = {}
    for _, ply in ipairs(player.GetAll()) do
        flashlights[ply] = render.GetLightColor(ply:EyePos())
    end

    net.Start("TRizzleBotFlashlight")
    net.WriteTable(flashlights)
    net.SendToServer()
end)

function TRizzleBotCreateMenu( ply, cmd, args )

	local Frame = vgui.Create( "DFrame" )
    Frame:SetPos( ScrW()/2-300, ScrH()/2-300 )
    Frame:SetSize( 600, 600 )
    Frame:SetTitle( "TRizzle Bot Creation Menu" )
    Frame:SetVisible( true )
    Frame:SetDraggable( true )
    Frame:ShowCloseButton( true )
    Frame:MakePopup()
    Frame.Paint = function(self,w,h)
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(0, 0, 255, 20)
		surface.DrawRect(0, 0, w, 30)

		surface.SetDrawColor(255, 255, 255, 20)
		surface.DrawRect(0, 30, 230, 570)
    end
	
	local DModelPanel = vgui.Create( "DModelPanel", Frame )
	DModelPanel:Dock( RIGHT )
	DModelPanel:SetSize( 370, 0 )
	DModelPanel:SetModel( "models/player/kleiner.mdl" )
	DModelPanel:SetAnimated( true )
	DModelPanel.Angles = angle_zero
	DModelPanel.DragMousePress = function( self )
		self.PressX, self.PressY = input.GetCursorPos()
		self.Pressed = true
	end
	DModelPanel.DragMouseRelease = function( self )
		self.Pressed = false
	end
	DModelPanel.LayoutEntity = function( self, ent )
		if self.bAnimated then self:RunAnimation() end
		
		if self.Pressed then
			local mx, my = input.GetCursorPos()
			self.Angles = self.Angles - Angle( 0, ( ( self.PressX or mx ) - mx ) / 2, 0 )
			
			self.PressX, self.PressY = mx, my
			
		end
		
		ent:SetAngles( self.Angles )
		
	end
	
	local DScrollPanel = vgui.Create( "DScrollPanel", Frame )
	DScrollPanel:Dock( LEFT )
	DScrollPanel:SetSize( 230, 0 )
	
	local label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Bot Name:" )
	
	local Name = vgui.Create( "DTextEntry", DScrollPanel )
	Name:Dock( TOP )
	Name:DockMargin( 0, 0, 0, 5 )
	Name:SetSize( 150, 20 )
	Name:SetPlaceholderText( "Bot" )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Follow Distance:" )
	
	local FollowDist = vgui.Create( "DNumberWang", DScrollPanel )
	FollowDist:Dock( TOP )
	FollowDist:DockMargin( 0, 0, 0, 5 )
	FollowDist:SetSize( 150, 20 )
	FollowDist:SetMax( math.huge )
	FollowDist:SetValue( 200 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Danger Distance:" )
	
	local DangerDist = vgui.Create( "DNumberWang", DScrollPanel )
	DangerDist:Dock( TOP )
	DangerDist:DockMargin( 0, 0, 0, 5 )
	DangerDist:SetSize( 150, 20 )
	DangerDist:SetMax( math.huge )
	DangerDist:SetValue( 300 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Melee Weapon:" )
	
	local Melee = vgui.Create( "DComboBox", DScrollPanel )
	Melee:Dock( TOP )
	Melee:DockMargin( 0, 0, 0, 5 )
	Melee:SetSize( 150, 20 )
	Melee:SetValue( "weapon_crowbar" )
	
	for k, wep in pairs( list.Get( "Weapon" ) ) do
	
		Melee:AddChoice( wep.ClassName )
		
	end
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Pistol:" )
	
	local Pistol = vgui.Create( "DComboBox", DScrollPanel )
	Pistol:Dock( TOP )
	Pistol:DockMargin( 0, 0, 0, 5 )
	Pistol:SetSize( 150, 20 )
	Pistol:SetText( "weapon_pistol" )
	
	for k, wep in pairs( list.Get( "Weapon" ) ) do
	
		Pistol:AddChoice( wep.ClassName )
		
	end
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Shotgun:" )
	
	local Shotgun = vgui.Create( "DComboBox", DScrollPanel )
	Shotgun:Dock( TOP )
	Shotgun:DockMargin( 0, 0, 0, 5 )
	Shotgun:SetSize( 150, 20 )
	Shotgun:SetValue( "weapon_shotgun" )
	
	for k, wep in pairs( list.Get( "Weapon" ) ) do
	
		Shotgun:AddChoice( wep.ClassName )
		
	end
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Rifle/SMG:" )
	
	local Rifle = vgui.Create( "DComboBox", DScrollPanel )
	Rifle:Dock( TOP )
	Rifle:DockMargin( 0, 0, 0, 5 )
	Rifle:SetSize( 150, 20 )
	Rifle:SetValue( "weapon_smg1" )
	
	for k, wep in pairs( list.Get( "Weapon" ) ) do
	
		Rifle:AddChoice( wep.ClassName )
		
	end
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Grenade:" )
	
	local Grenade = vgui.Create( "DComboBox", DScrollPanel )
	Grenade:Dock( TOP )
	Grenade:DockMargin( 0, 0, 0, 5 )
	Grenade:SetSize( 150, 20 )
	Grenade:SetValue( "weapon_frag" )
	
	for k, wep in pairs( list.Get( "Weapon" ) ) do
	
		Grenade:AddChoice( wep.ClassName )
		
	end
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Sniper:" )
	
	local Sniper = vgui.Create( "DComboBox", DScrollPanel )
	Sniper:Dock( TOP )
	Sniper:DockMargin( 0, 0, 0, 5 )
	Sniper:SetSize( 150, 20 )
	Sniper:SetValue( "weapon_crossbow" )
	
	for k, wep in pairs( list.Get( "Weapon" ) ) do
	
		Sniper:AddChoice( wep.ClassName )
		
	end
	
	local SniperScope = vgui.Create( "DCheckBoxLabel", DScrollPanel )
	SniperScope:Dock( TOP )
	SniperScope:DockMargin( 0, 0, 0, 5 )
	SniperScope:SetSize( 150, 20 )
	SniperScope:SetText( "Does the sniper have a scope?" )
	SniperScope:SetValue( true )
	SniperScope:SizeToContents()
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Melee Distance:" )
	
	local MeleeDist = vgui.Create( "DNumberWang", DScrollPanel )
	MeleeDist:Dock( TOP )
	MeleeDist:DockMargin( 0, 0, 0, 5 )
	MeleeDist:SetSize( 150, 20 )
	MeleeDist:SetMax( math.huge )
	MeleeDist:SetValue( 80 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Pistol Distance:" )
	
	local PistolDist = vgui.Create( "DNumberWang", DScrollPanel )
	PistolDist:Dock( TOP )
	PistolDist:DockMargin( 0, 0, 0, 5 )
	PistolDist:SetSize( 150, 20 )
	PistolDist:SetMax( math.huge )
	PistolDist:SetValue( 1300 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Shotgun Distance:" )
	
	local ShotgunDist = vgui.Create( "DNumberWang", DScrollPanel )
	ShotgunDist:Dock( TOP )
	ShotgunDist:DockMargin( 0, 0, 0, 5 )
	ShotgunDist:SetSize( 150, 20 )
	ShotgunDist:SetMax( math.huge )
	ShotgunDist:SetValue( 300 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Rifle/SMG Distance:" )
	
	local RifleDist = vgui.Create( "DNumberWang", DScrollPanel )
	RifleDist:Dock( TOP )
	RifleDist:DockMargin( 0, 0, 0, 5 )
	RifleDist:SetSize( 150, 20 )
	RifleDist:SetText( "Rifle/SMG Distance" )
	RifleDist:SetMax( math.huge )
	RifleDist:SetValue( 900 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Heal Threshold:" )
	
	local HealThreshold = vgui.Create( "DNumberWang", DScrollPanel )
	HealThreshold:Dock( TOP )
	HealThreshold:DockMargin( 0, 0, 0, 5 )
	HealThreshold:SetSize( 150, 20 )
	HealThreshold:SetMax( math.huge )
	HealThreshold:SetValue( 100 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Combat Heal Threshold:" )
	
	local CombatHealThreshold = vgui.Create( "DNumberWang", DScrollPanel )
	CombatHealThreshold:Dock( TOP )
	CombatHealThreshold:DockMargin( 0, 0, 0, 5 )
	CombatHealThreshold:SetSize( 150, 20 )
	CombatHealThreshold:SetMax( math.huge )
	CombatHealThreshold:SetValue( 25 )
	
	label = vgui.Create( "DLabel", DScrollPanel )
	label:Dock( TOP )
	label:DockMargin( 0, 0, 0, 5 )
	label:SetSize( 150, 20 )
	label:SetText( "Player Model:" )
	
	local PlayerModel = vgui.Create( "DComboBox", DScrollPanel )
	PlayerModel:Dock( TOP )
	PlayerModel:DockMargin( 0, 0, 0, 5 )
	PlayerModel:SetSize( 150, 20 )
	PlayerModel:SetText( "Player Model" )
	PlayerModel.OnSelect = function( self, index, value )
		DModelPanel:SetModel( player_manager.TranslatePlayerModel( value ) )
	end
	
	for name, model in pairs( player_manager.AllValidModels() ) do
	
		PlayerModel:AddChoice( name )
		
	end
	
	local SpawnWithPreferredWeapons = vgui.Create( "DCheckBoxLabel", DScrollPanel )
	SpawnWithPreferredWeapons:Dock( TOP )
	SpawnWithPreferredWeapons:DockMargin( 0, 0, 0, 5 )
	SpawnWithPreferredWeapons:SetSize( 150, 20 )
	SpawnWithPreferredWeapons:SetText( "Should the bot spawn with its weapons?" )
	SpawnWithPreferredWeapons:SetValue( true )
	SpawnWithPreferredWeapons:SizeToContents()
	
	local DButton = vgui.Create( "DButton", DScrollPanel )
	DButton:SetText( "Create Bot" )
	DButton:Dock( TOP )
	DButton:DockMargin( 0, 0, 0, 5 )
	DButton.DoClick = function( self )
		net.Start( "TRizzleCreateBotMenu" )
			net.WriteString( Name:GetValue() )
			net.WriteInt( FollowDist:GetValue(), 32 )
			net.WriteInt( DangerDist:GetValue(), 32 )
			net.WriteString( Melee:GetOptionText( Melee.selected ) or "weapon_crowbar" )
			net.WriteString( Pistol:GetOptionText( Pistol.selected ) or "weapon_pistol" )
			net.WriteString( Shotgun:GetOptionText( Shotgun.selected ) or "weapon_shotgun" )
			net.WriteString( Rifle:GetOptionText( Rifle.selected ) or "weapon_smg1" )
			net.WriteString( Grenade:GetOptionText( Grenade.selected ) or "weapon_frag" )
			net.WriteString( Sniper:GetOptionText( Sniper.selected ) or "weapon_crossbow" )
			net.WriteBool( SniperScope:GetChecked() )
			net.WriteInt( MeleeDist:GetValue(), 32 )
			net.WriteInt( PistolDist:GetValue(), 32 )
			net.WriteInt( ShotgunDist:GetValue(), 32 )
			net.WriteInt( RifleDist:GetValue(), 32 )
			net.WriteInt( HealThreshold:GetValue(), 32 )
			net.WriteInt( CombatHealThreshold:GetValue(), 32 )
			net.WriteString( PlayerModel:GetOptionText( PlayerModel.selected ) or "kleiner" )
			net.WriteBool( SpawnWithPreferredWeapons:GetChecked() )
		net.SendToServer()
		Frame:Close()
	end

end

concommand.Add( "TRizzleBotCreateMenu", TRizzleBotCreateMenu, nil, "Opens a derma menu that assists with creating a TRizzleBot." )