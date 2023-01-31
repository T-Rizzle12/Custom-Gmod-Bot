local Player		=	FindMetaTable( "Player" )
Bot_Map_An_Bombs	=	{} -- All the currently planted bombs.


local RebelsInAction						=	0 
local CombinesInAction						=	0 -- Limit the amount of bots moving around to boost speed.
-- We can make the other bots find a nice hiding spot to guard and maybe slowdown their thinking a little.


local an_res_bot_goal						=	nil
local MeshConfirmed							=	false



CreateConVar( "an_bot_difficulty" , "1" , "FCVAR_NONE" , "How hard are the bots? 0 = Easy 1 = Normal 2 = Hard 3 = Expert" )
CreateConVar( "an_bot_shop_specials_chance" , "3" , "FCVAR_NONE" , "A 1 in this chance a bot will buy a special item." )
CreateConVar( "an_bot_shop_singles_chance" , "8" , "FCVAR_NONE" , "A 1 in this chance a bot will buy a single use item." )
CreateConVar( "an_bot_shop_secondarys_chance" , "5" , "FCVAR_NONE" , "A 1 in this chance a bot will buy a secondary weapon." )
CreateConVar( "an_bot_shop_melee_chance" , "20" , "FCVAR_NONE" , "A 1 in this chance a bot will buy a melee weapon." )
CreateConVar( "an_bot_allow_pistols" , "1" , "FCVAR_NONE" , "Can bots use pistols?" )
CreateConVar( "an_bot_allow_machine_and_rifles" , "1" , "FCVAR_NONE" , "Can bots use machine guns and rifles?" )
CreateConVar( "an_bot_allow_shotguns" , "1" , "FCVAR_NONE" , "Can bots use shotguns?" )
CreateConVar( "an_bot_allow_snipers" , "1" , "FCVAR_NONE" , "Can bots use snipers?" )
CreateConVar( "an_bot_allow_grenades" , "1" , "FCVAR_NONE" , "Can bots use grenades?" )
CreateConVar( "an_bot_allow_shop_melee" , "1" , "FCVAR_NONE" , "Can bots use melee weapons brought from the shop?" )
CreateConVar( "an_bot_blind" , "0" , "FCVAR_NONE" , "Bots will not target enemys with this enabled." )
CreateConVar( "an_bot_allow_shop_specials" , "1" , "FCVAR_NONE" , "Can bots use special weapons such as turrets and headcrab summoning kit for example." )
CreateConVar( "an_bot_fill_amount" , "0" , "FCVAR_NONE" , "Bots will fill up the server to this amount. Bots will get kicked when the server starts to get full and added back again to fill up the bot amount." )
CreateConVar( "an_bot_dont_shoot" , "0" , "FCVAR_NONE" , "Prevent bots from shooting." )
CreateConVar( "an_bot_zombie" , "0" , "FCVAR_NONE" , "Shuts off most of the bots AI but can still move." )


-- You can add support for any custom weapon here!
-- Simply define the CLASS name of the weapon, What team can have it and how to use it.

-- [ HANDLE TYPES ]

-- melee : Makes bots get close before using this.
-- gun : Bots will use it like a gun.
-- sniper : Bots will often find hiding spots to use this.
-- explosive : Bots will stay away from enemies while using this
-- shotgun : Force close range combat.
-- rifle : Bots will use this like it has accuracy ( Shooting slowly at long range and fast at short )
-- Single : Bots will use this at anyrange and fire 1 bullet before switching to another weapon. ( Used by grenades )

An_Bot_Shop_Items			=	{}

local BotWeaponList			=	{}
local BotShotGunList		=	{}
local BotGunList			=	{}
local BotGrenadeList		=	{}
local BotPistolList			=	{}
local BotMeleeList			=	{}
local BotSpecialsList		=	{}
local BotSnipersList		=	{}




local BotNames				=	{} -- Define your bots profiles here.
-- Skill 0 - 100 The higher that is the more expert the bot will be.
-- Teamwork 0 - 100 The higher this is the more the bot will plant the bomb,Defuse the bomb and camp at bombsites.
-- Name Whats the name of the bot.
-- Attack delay -- How long until we attack an enemy.
-- Fast attack delay -- If we have seen the enemy before this is how long until we shoot them.




local EasyBots				=	{
	
	{
		
		name				=	"Please_Dont_Shoot_Me!", -- The name
		skill				=	0, -- How good is this bot?
		teamwork			=	0, -- Teamwork?
		attackdelay			=	1.50, -- First time we see an enemy.
		reactiontime		=	0.50, -- When we see the same enemy again in a certain time.
		favouriteweapon		=	"zen_colour_grenade"
		
	},
	
	{
		
		name				=	"While_you_read_this_name_i_will_shoot_you.",
		skill				=	0,
		teamwork			=	10,
		attackdelay			=	1.25,
		reactiontime		=	0.50,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Happy_Chappie",
		skill				=	0,
		teamwork			=	20,
		attackdelay			=	1.25,
		reactiontime		=	0.50,
		favouriteweapon		=	"an_heart_gun"
		
	},
	
	{
		
		name				=	"My_name_is_nameless",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.50,
		reactiontime		=	0.50,
		favouriteweapon		=	"zen_flame_grenade"
		
	},
	
	{
		
		name				=	"SIR_DEFUSE_THE_BOMB!",
		skill				=	0,
		teamwork			=	35,
		attackdelay			=	1.25,
		reactiontime		=	0.50,
		favouriteweapon		=	"kit"
		
	},
	
	{
		
		name				=	"Crazy_Gamer",
		skill				=	0,
		teamwork			=	5,
		attackdelay			=	1.00,
		reactiontime		=	0.65,
		
	},
	
	{
		
		name				=	"TURRET!",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.50,
		reactiontime		=	0.35,
		favouriteweapon		=	"zen_team_turret" -- TURRET should use turrets!
		
	},
	
	{
		
		name				=	"I_forgot_my_name.",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.60,
		reactiontime		=	0.25,
		
	},
	
	{
		
		name				=	"Still_Alive",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.50,
		reactiontime		=	0.50,
		favouriteweapon		=	"an_heart_gun"
		
	},
	
	{
		
		name				=	"FRIENDLY FIRE!",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.50,
		reactiontime		=	0.50,
		
	},
	
	{
		
		name				=	"Sir Harmless",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.50,
		reactiontime		=	0.50,
		
	},
	
	{
		
		name				=	"I have a strange name!",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.00,
		reactiontime		=	0.50,
		
	},
	
	{
		
		name				=	"Alright, You Win!",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	2.00,
		reactiontime		=	0.75,
		favouriteweapon		=	"an_void_charm"
		
	},
	
	{
		
		name				=	"Here i am!",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.00,
		reactiontime		=	0.25,
		favouriteweapon		=	"weapon_ar2"
		
	},
	
	{
		
		name				=	"A very unlucky expert bot!",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	0.20,
		reactiontime		=	0.15,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Im Friendly! Well i was...",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.60,
		reactiontime		=	0.75,
		favouriteweapon		=	"weapon_smg1"
		
	},
	
	{
		
		name				=	"NEED BACKUP!",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.20,
		reactiontime		=	0.40,
		favouriteweapon		=	"weapon_smg1"
		
	},
	
	{
		
		name				=	"Brainless",
		skill				=	0,
		teamwork			=	5,
		attackdelay			=	1.10,
		reactiontime		=	0.40,
		favouriteweapon		=	"an_magic_stunner"
		
	},
	
	{
		
		name				=	"My name is soo long, By the time you have read this i probibly would of killed you but who knows.",
		skill				=	0,
		teamwork			=	5,
		attackdelay			=	1.50,
		reactiontime		=	0.35,
		favouriteweapon		=	"weapon_ar2"
		
	},
	
	{
		
		name				=	"Why is this my name?",
		skill				=	0,
		teamwork			=	0,
		attackdelay			=	1.30,
		reactiontime		=	0.50,
		favouriteweapon		=	"weapon_shotgun"
		
	},
	
}

local NormalBots			=	{
	
	{
		
		name				=	"Basher", -- The name
		skill				=	25, -- How good is this bot?
		teamwork			=	35, -- Teamwork?
		attackdelay			=	0.50, -- First time we see an enemy.
		reactiontime		=	0.20, -- When we see the same enemy again in a certain time.
		
	},
	
	{
		
		name				=	"Smasher",
		skill				=	30,
		teamwork			=	30,
		attackdelay			=	0.40,
		reactiontime		=	0.20,
		
	},
	
	{
		
		name				=	"An_Expert_Bot_With_A_Bad_Aim",
		skill				=	30,
		teamwork			=	45,
		attackdelay			=	0.40,
		reactiontime		=	0.30,
		
	},
	
	{
		
		name				=	"Dr.Breen",
		skill				=	28,
		teamwork			=	25,
		attackdelay			=	0.50,
		reactiontime		=	0.25,
		
	},
	
	{
		
		name				=	"Eli Vance",
		skill				=	25,
		teamwork			=	45,
		attackdelay			=	0.50,
		reactiontime		=	0.25,
		
	},
	
	{
		
		name				=	"Barney",
		skill				=	35,
		teamwork			=	30,
		attackdelay			=	0.40,
		reactiontime		=	0.20,
		
	},
	
	{
		
		name				=	"Dr.Kleiner",
		skill				=	25,
		teamwork			=	30,
		attackdelay			=	0.50,
		reactiontime		=	0.25,
		
	},
	
	{
		
		name				=	"Alyx Vance",
		skill				=	30,
		teamwork			=	35,
		attackdelay			=	0.40,
		reactiontime		=	0.25,
		
	},
	
	{
		
		name				=	"Slasher",
		skill				=	30,
		teamwork			=	30,
		attackdelay			=	0.30,
		reactiontime		=	0.30,
		
	},
	
	{
		
		name				=	"CrAzY",
		skill				=	25,
		teamwork			=	50,
		attackdelay			=	0.20,
		reactiontime		=	0.10,
		
	},
	
}

-- TODO: Need more hard bot names.
local HardBots				=	{
	
	{
		
		name				=	"Dagger",
		skill				=	65,
		teamwork			=	65,
		attackdelay			=	0.15,
		reactiontime		=	0.10,
		favouriteweapon		=	"weapon_357",
		
	},
	
	{
		
		name				=	"I__will_shoot_anything_that_moves",
		skill				=	70,
		teamwork			=	55,
		attackdelay			=	0.10,
		reactiontime		=	0.05,
		favouriteweapon		=	"an_flame_bullets_gun",
		
	},
	
	{
		
		name				=	"BANG!",
		skill				=	70,
		teamwork			=	60,
		attackdelay			=	0.10,
		reactiontime		=	0.08,
		favouriteweapon		=	"an_flame_bullets_gun",
		
	},
	
	{
		
		name				=	"I_see_you!",
		skill				=	65,
		teamwork			=	65,
		attackdelay			=	0.12,
		reactiontime		=	0.08,
		favouriteweapon		=	"weapon_357",
		
	},
	
	{
		
		name				=	"Stone",
		skill				=	70,
		teamwork			=	70,
		attackdelay			=	0.10,
		reactiontime		=	0.08,
		favouriteweapon		=	"an_flame_bullets_gun",
		
	},
	
	{
		
		name				=	"Metal",
		skill				=	65,
		teamwork			=	65,
		attackdelay			=	0.10,
		reactiontime		=	0.10,
		favouriteweapon		=	"weapon_357",
		
	},
	
	{
		
		name				=	"Poison",
		skill				=	65,
		teamwork			=	75,
		attackdelay			=	0.15,
		reactiontime		=	0.08,
		favouriteweapon		=	"weapon_357",
		
	},
	
	{
		
		name				=	"Hunter",
		skill				=	65,
		teamwork			=	75,
		attackdelay			=	0.15,
		reactiontime		=	0.08,
		favouriteweapon		=	"weapon_shotgun",
		
	},
	
	{
		
		name				=	"Acid",
		skill				=	65,
		teamwork			=	75,
		attackdelay			=	0.15,
		reactiontime		=	0.08,
		favouriteweapon		=	"an_flame_bullets_gun",
		
	},
	
}

-- 17 Expert bots
local ExpertBots			=	{
	
	{
		
		name				=	"Top_Secret_Bot", -- This bot will never spawn ingame is that strange?
		skill				=	200,
		teamwork			=	100,
		attackdelay			=	0.001,
		reactiontime		=	0.001,
		favouriteweapon		=	"precise_shooter",
		
	},
	
	{
		
		name				=	"Lava",
		skill				=	100,
		teamwork			=	90,
		attackdelay			=	0.05,
		reactiontime		=	0.02,
		favouriteweapon		=	"an_the_ultra_blast",
		
	},
	
	{
		
		name				=	"Nightmare",
		skill				=	100,
		teamwork			=	100,
		attackdelay			=	0.02,
		reactiontime		=	0.02,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Destroyer",
		skill				=	100,
		teamwork			=	95,
		attackdelay			=	0.05,
		reactiontime		=	0.02,
		favouriteweapon		=	"an_dark_plasma_grenade"
		
	},
	
	{
		
		name				=	"Nuclear_Bot",
		skill				=	95,
		teamwork			=	100,
		attackdelay			=	0.08,
		reactiontime		=	0.02,
		favouriteweapon		=	"weapon_rpg"
		
	},
	
	{
		
		name				=	"Crusher",
		skill				=	95,
		teamwork			=	100,
		attackdelay			=	0.05,
		reactiontime		=	0.05,
		favouriteweapon		=	"an_the_ultra_blast"
		
	},
	
	{
		
		name				=	"HEADSHOT!",
		skill				=	100,
		teamwork			=	90,
		attackdelay			=	0.02,
		reactiontime		=	0.02,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"EXTEMELY_Crazy_Bot",
		skill				=	95,
		teamwork			=	100,
		attackdelay			=	0.08,
		reactiontime		=	0.05,
		favouriteweapon		=	"weapon_357"
		
	},
	
	{
		
		name				=	"ZAP!",
		skill				=	110,
		teamwork			=	100,
		attackdelay			=	0.01,
		reactiontime		=	0.01,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Bullet",
		skill				=	95,
		teamwork			=	100,
		attackdelay			=	0.03,
		reactiontime		=	0.03,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"LaSeR",
		skill				=	100,
		teamwork			=	100,
		attackdelay			=	0.03,
		reactiontime		=	0.01,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Elite Murderer",
		skill				=	100,
		teamwork			=	100,
		attackdelay			=	0.03,
		reactiontime		=	0.01,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Precise Killer",
		skill				=	100,
		teamwork			=	100,
		attackdelay			=	0.02,
		reactiontime		=	0.02,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"An_easy_bot_that_is_really_lucky",
		skill				=	90,
		teamwork			=	100,
		attackdelay			=	0.05,
		reactiontime		=	0.04,
		favouriteweapon		=	"weapon_357"
		
	},
	
	
	{
		
		name				=	"Master Of Disaster",
		skill				=	95,
		teamwork			=	100,
		attackdelay			=	0.03,
		reactiontime		=	0.03,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"ExPlOsIvE",
		skill				=	95,
		teamwork			=	100,
		attackdelay			=	0.03,
		reactiontime		=	0.01,
		favouriteweapon		=	"an_the_ultra_blast"
		
	},
	
	{
		
		name				=	"Void",
		skill				=	105,
		teamwork			=	100,
		attackdelay			=	0.03,
		reactiontime		=	0.03,
		favouriteweapon		=	"an_dark_plasma_blaster"
		
	},
	
	{
		
		name				=	"A bot who has installed cheats.",
		skill				=	105,
		teamwork			=	100,
		attackdelay			=	0.03,
		reactiontime		=	0.03,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Brain Remover",
		skill				=	100,
		teamwork			=	95,
		attackdelay			=	0.02,
		reactiontime		=	0.02,
		favouriteweapon		=	"precise_shooter"
		
	},
	
	{
		
		name				=	"Before you read this name, You are dead",
		skill				=	105,
		teamwork			=	100,
		attackdelay			=	0.01,
		reactiontime		=	0.01,
		favouriteweapon		=	"precise_shooter"
		
	},
	
}


BotNames[ 1 ]				=	EasyBots
BotNames[ 2 ]				=	NormalBots
BotNames[ 3 ]				=	HardBots
BotNames[ 4 ]				=	ExpertBots

function AN_ADD_TO_BOT_LIST_INSTRUCTIONS( tab , list ) -- Nice and easy function to adding custom weapons to their lists.
	if !istable( tab ) or !isstring( list ) then return end
	
	if list == "pistol" then
		
		table.insert( BotPistolList , tab )
		
		return
	end
	
	if list == "shotgun" then
		
		table.insert( BotShotGunList , tab )
		
		return
	end
	
	if list == "grenade" then
		
		table.insert( BotGrenadeList , tab )
		
		return
	end
	
	if list == "gun" then
		
		table.insert( BotGunList , tab )
		
		return
	end
	
	if list == "melee" then
		
		table.insert( BotMeleeList , tab )
		
		return
	end
	
	if list == "special" then
		
		table.insert( BotSpecialsList , tab )
		
		return
	end
	
	if list == "sniper" then
		
		table.insert( BotSnipersList , tab )
		
		return
	end
	
	--table.insert( BotCustomWeaponList , tab )
	
end

-- Add melee weapons to the list so bots have something to fight with if all the allow weapon commands are 0



local function CreateNewAnFile()
	
	local Names		=	util.TableToJSON( BotNames , false ) 
	
	file.CreateDir( "absolute_nightmare" )
	
	file.Write( "absolute_nightmare/zen_an_bot_profile.txt" , Names )
	
end

local function GetAnBotFile()
	
	return util.JSONToTable( file.Read( "absolute_nightmare/zen_an_bot_profile.txt" , "DATA" ) )
	
end

local function ValidateAnBotFile()
	
	local Data	=	file.Read( "absolute_nightmare/zen_an_bot_profile.txt" , "DATA" )
	
	if !Data then CreateNewAnFile() return end
	Data		=	util.JSONToTable( Data )
	
	if !istable( Data ) then CreateNewAnFile() return end
	
	return true
end

function Player:AnFullResetAI()
	if !IsValid( self ) then return end
	
	self:ZEN_NEXTBOT_Clear_Nav()
	
	self.HidingSpot				=	nil
	self.Goal					=	nil
	
	self.SlowThink				=	0 -- An experiment optimization.
	self.HidingSpotList			=	{}
	self.EyeAngle				=	Angle( 0 , 0 , 0 )
	
	self.MainWeapon				=	nil
	
	if !istable( self.LastGoalPath ) then
		
		self.LastGoalPath	=	{}
		
	end
	
	timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
	
	self.Target_Bomb			=	nil
	self.Target_Goal			=	nil
	self.Target_Reactor			=	nil
	
	self.LastMainWeaponUsed		=	nil
	
	self.Target_Enemy			=	nil
	
	self.EnemysList				=	{}
	
	self.ExpertSlowDown			=	0
	
	self.BlockAttack			=	false
	
	self.GoalHasBomb			=	false
	
	self:AN_BOT_Clear_Enemy_Data()
	
	self.Target_Follow	=	nil
	timer.Remove( "an_bot_follow" .. self:EntIndex() )
	
	if self:GetTeam() == "AN_TEAM_COMBINE" then
		
		self:BOT_BLUE_Create_Think_Timer()
		
	elseif self:GetTeam() == "AN_TEAM_RESISTANCE" then
		
		self:BOT_RED_Create_Think_Timer()
		
	end
	
	timer.Simple( 1 , function() if IsValid( self ) then self.AIJustRefreshed = false end end) -- Delay path finding for precompured paths.
	
	local BotPrimarysList	=	{}
	local BotSecondarysList	=	{}
	local BotMeleesList		=	{}
	local BotSpecialsList	=	{}
	local BotVitalsList		=	{}
	
	for k, v in ipairs( An_Bot_Shop_Items ) do -- Sort the items into lists then pick a random item to buy.
		
		if v[ "botbuytype" ] == "primary" and self:AN_HAS_ENOUGH_CASH( v[ "cost" ] ) then
			
			table.insert( BotPrimarysList , v )
			
			continue
		end
		
		if v[ "botbuytype" ] == "secondary" and self:AN_HAS_ENOUGH_CASH( v[ "cost" ] ) then
			
			table.insert( BotSecondarysList , v )
			
			continue
		end
		
		if v[ "botbuytype" ] == "third" and self:AN_HAS_ENOUGH_CASH( v[ "cost" ] ) then
			
			table.insert( BotMeleesList , v )
			
			continue
		end
		
		if v[ "botbuytype" ] == "special" and self:AN_HAS_ENOUGH_CASH( v[ "cost" ] ) then
			
			table.insert( BotSpecialsList , v )
			
			continue
		end
		
		if v[ "botbuytype" ] == "vital" and self:AN_HAS_ENOUGH_CASH( v[ "cost" ] ) then
			
			table.insert( BotVitalsList , v )
			
			continue
		end
		
	end
	
	
	
	local SelectedPrimary = BotPrimarysList[ math.random( 1 , #BotPrimarysList ) ]
	
	if istable( SelectedPrimary ) then
		
		if !table.HasValue( BotWeaponList , SelectedPrimary[ "botinstructions" ] ) then
			
			table.insert( BotWeaponList , SelectedPrimary[ "botinstructions" ] )
			
		end
		
		self:FindAnItem( SelectedPrimary[ "class" ] , An_Round_Can_Buy )
		
	end
	
	local SelectedVital = BotVitalsList[ math.random( 1 , #BotVitalsList ) ]
	
	if istable( SelectedVital ) then
		
		self:FindAnItem( SelectedVital[ "class" ] , An_Round_Can_Buy )
		
	end
	
	if math.random( 1 , GetConVar( "an_bot_shop_secondarys_chance" ):GetInt() ) == 1 then
		
		local SelectedSecondary = BotSecondarysList[ math.random( 1 , #BotSecondarysList ) ]
		
		if istable( SelectedSecondary ) then
			
			if !table.HasValue( BotWeaponList , SelectedSecondary[ "botinstructions" ] ) then
				
				table.insert( BotWeaponList , SelectedSecondary[ "botinstructions" ] )
				
			end
			
			self:FindAnItem( SelectedSecondary[ "class" ] , An_Round_Can_Buy )
			
		end
		
	end
	
	if math.random( 1 , GetConVar( "an_bot_shop_melee_chance" ):GetInt() ) == 1 then
		
		local SelectedMelee = BotMeleesList[ math.random( 1 , #BotMeleesList ) ]
		
		if istable( SelectedMelee ) then
			
			if !table.HasValue( BotWeaponList , SelectedMelee[ "botinstructions" ] ) then
				
				table.insert( BotWeaponList , SelectedMelee[ "botinstructions" ] )
				
			end
			
			self:FindAnItem( SelectedMelee[ "class" ] , An_Round_Can_Buy )
			
		end
		
	end
	
	if math.random( 1 , GetConVar( "an_bot_shop_specials_chance" ):GetInt() ) == 1 then
		
		local SelectedSpec = BotSpecialsList[ math.random( 1 , #BotSpecialsList ) ]
		
		if istable( SelectedSpec ) then
			
			-- A quick way to add custom weapons to the bot selection menu.
			-- And yes it is done per bot but who cares its only done once when a bots AI is reset.
			if !table.HasValue( BotWeaponList , SelectedSpec[ "botinstructions" ] ) then
				
				table.insert( BotWeaponList , SelectedSpec[ "botinstructions" ] )
				
			end
			
			self:FindAnItem( SelectedSpec[ "class" ] , An_Round_Can_Buy )
			
			
		end
		
	end
	
	-- Skilled bots will buy defuse kits and armor all the time.
	if self.Profile[ "skill" ] >= 70 then
		
		self:FindAnItem( "armor" )
		self:FindAnItem( "kit" )
		
		-- Expert and hard bots select crowbars and stunsticks to run to the goals faster.
		if self:GetTeam() == "AN_TEAM_COMBINE" then
			
			self.SelectNextWeapon	=	"weapon_stunstick"
			
		else
			
			self.SelectNextWeapon	=	"weapon_crowbar"
			
		end
		
	end
	
	-- Bots will buy the favourite weapon if it exists in the profile.
	if isstring( self.Profile[ "favouriteweapon" ] ) then
		
		self:FindAnItem( self.Profile[ "favouriteweapon" ] )
		
		for k, v in ipairs( BotWeaponList ) do
			
			if isstring( v ) then continue end
			
			if v[ "name" ] == self.Profile[ "favouriteweapon" ] then
				
				self.MainWeapon		=	v
				
				break
			end
			
		end
		
	end
	
	timer.Simple( 0.05 , function()
		
		if !IsValid( self ) then return end
		
		local SingleUse	=	{}
		
		for k, v in ipairs( BotWeaponList ) do
			
			if isstring( v ) then continue end
			
			if self:HasWeapon( v[ "name" ] ) and v[ "name" ] != "weapon_frag" then
				
				if v[ "handletype" ] == "single" then
					
					SingleUse[ #SingleUse + 1 ] = v
					
				end
				
			end
			
		end
		
		self.MainWeapon = SingleUse[ math.random( 1 , #SingleUse ) ] -- Bots will spawn with grenades and one use items.
		
	end)
	
	
end



function An_Game_Reset_Bots( ply , cmd , name )
	
	for k, v in ipairs( player.GetBots() ) do
		
		if v.AN_BOT then
			
			v:AnFullResetAI()
			
			if !v:Alive() then
				
				v:Spawn()
				
			end
			
		end
		
	end
	
	print( "All BOTs AI reset." )
	
	if IsValid( ply ) then
		
		ply:ChatPrint( "All BOTs AI reset." )
		
	end
	
end


concommand.Add( "an_bot_all_reset_AI" , An_Game_Reset_Bots )


function An_Game_Create_Bot( ply , cmd , name )
	
	local Skill					=	GetConVar( "an_bot_difficulty" ):GetInt()
	
	if Skill < 1 then
		
		print( "WARNING: Bots difficulty level is set to a number less than 1 setting to easy bots" )
		
		GetConVar( "an_bot_difficulty" ):SetInt( 1 )
		
		Skill 		=	1
		
	end
	
	if Skill > 4 then
		
		print( "WARNING: Bots difficulty level is set to a number higher than 4 setting to expert bots" )
		
		GetConVar( "an_bot_difficulty" ):SetInt( 4 )
		
		Skill 		=	4 -- A fail safe.
		
	end
	
	if !game.SinglePlayer() and player.GetCount() < game.MaxPlayers() then
		
		if name and name[1] != nil then
			
			ValidateAnBotFile()
			
			for k, v in ipairs( player.GetBots() ) do
				
				if v:Nick() == tostring( name[1] ) then
					
					print( "The bot profile is already in use." )
					
					return
				end
				
			end
			
			local TheBotProfile			=	nil
			local ShouldBreakForLoop	=	false
			local BotProfiles			=	GetAnBotFile()
			
			for i = 1 , 4 do
				
				if ShouldBreakForLoop == true then
					
					break
				end
				
				for k, v in ipairs( BotProfiles[ i ] ) do
					
					if string.lower( v[ "name" ] ) == string.lower( tostring( name[1] ) ) then
						
						TheBotProfile		=	v
						
						ShouldBreakForLoop	=	true
						
						break
					end
					
				end
				
			end
			
			if TheBotProfile == nil then print( "The bot profile does not exist." ) return end
			
			-- TODO: Validate the profile incase someone typed errors in the file.
			-- I.E like they forgot to add skill and its not there.
			
			local AnBot				=	player.CreateNextBot( TheBotProfile[ "name" ] )
			
			AnBot.AN_BOT			=	true
			
			AnBot.Profile			=	TheBotProfile
			
			AnBot:AnFullResetAI()
			
			if isnumber( tonumber( name[ 2 ] ) ) then
				
				timer.Simple( 0.01 , function()
					
					if IsValid( AnBot ) then
						
						if tonumber( name[ 2 ] ) == 1 then
							
							AnBot:SetAnTeam( 1 )
							
						elseif tonumber( name[ 2 ] ) == 2 then
							
							AnBot:SetAnTeam( 2 )
							
						end
						
					end
					
				end)
				
			end
			
			if AnBot:Nick() == "Top_Secret_Bot" then
				
				local index 		=	AnBot:EntIndex()
				
				timer.Create( "an_classified_bot_skill" .. index , 3 , 0 , function()
					
					if IsValid( AnBot ) then
						
						if AnBot:Alive() then
							
							timer.Adjust( "an_classified_bot_skill" .. index , math.Rand( 0.50 , 3 ) )
							
							AnBot:EmitSound( Sound( "vo/k_lab/kl_dearme.wav" ) , 85 , math.random( 20 , 150 ) , 1 )
							
							AnBot:SetHealth( AnBot:Health() + math.random( 1 , 8 ) , 0 , AnBot:GetMaxHealth() + 400 )
							AnBot:SetArmor( math.Clamp( AnBot:Armor() + math.random( 1 , 10 ) , 0 , 250 ) )
							
							AnBot:SetPlayerColor( Vector( math.Rand( 0 , 1 ) , math.Rand( 0 , 1 ) , math.Rand( 0 , 1 ) ) )
							
							local AllPlys	=	{}
							
							for k, v in ipairs( player.GetAll() ) do
								
								if v:GetTeam() == AnBot:GetTeam() and v:Alive() and v:Health() < v:GetMaxHealth() + 100 then
									
									AllPlys[ #AllPlys + 1 ]		=	v
									
								end
								
							end
							
							if !table.IsEmpty( AllPlys ) then
								
								local RandomHelp	=	AllPlys[ math.random( 1 , #AllPlys ) ]
								local RandomHeal	=	math.random( 1 , 20 )
								
								if RandomHelp:IsPlayer() and !RandomHelp:IsBot() then
									
									RandomHelp:ChatPrint( "Top_Secret_Bot: Gave you " .. RandomHeal .. " health!" )
									
								end
								
								RandomHelp:SetHealth( RandomHelp:Health() + RandomHeal , 0 , RandomHelp:GetMaxHealth() + 100 )
								
							end
							
						end
						
					else
						
						timer.Remove( "an_classified_bot_skill" .. index )
						
					end
					
				end)
				
			end
			
		else
			
			ValidateAnBotFile()
			
			local Names		=	GetAnBotFile()
			
			if !istable( Names ) then print( "Something went wrong while creating a bot.Please try again." ) return end
			
			for y, j in ipairs( Names[ Skill ] ) do
				
				if j[ "name" ] == "Top_Secret_Bot" then -- We don't want this now do we.
					
					table.remove( Names[ Skill ] , y )
					
					break
				end
				
			end
			
			for k, v in ipairs( player.GetBots() ) do
				
				for y, j in ipairs( Names[ Skill ] ) do
					
					if v:Nick() == j[ "name" ] then
						
						table.remove( Names[ Skill ] , y )
						
					end
					
				end
				
			end
			
			if table.IsEmpty( Names[ Skill ] ) then print( "Sorry! All bot profiles are currently in use." ) return end
			
			local RandomProfile		=	Names[ Skill ][ math.random( 1 , #Names[ Skill ] ) ]
			
			local AnBot				=	player.CreateNextBot( RandomProfile[ "name" ] )
			
			AnBot.AN_BOT			=	true
			
			AnBot.Profile			=	RandomProfile -- Our profile for skill,Teamwork etc...
			
			AnBot:AnFullResetAI()
			
			if istable( name ) and isnumber( tonumber( name[ 2 ] ) ) then
				
				timer.Simple( 0.01 , function()
					
					if IsValid( AnBot ) then
						
						if tonumber( name[ 2 ] ) == 1 then
							
							AnBot:SetAnTeam( 1 )
							
						elseif tonumber( name[ 2 ] ) == 2 then
							
							AnBot:SetAnTeam( 2 )
							
						end
						
					end
					
				end)
				
			end
			
			-- We increase the bot fill amount when adding bots via the console,So bots don't get kicked!
			local AmountOfBots		=	0
			
			for k, v in ipairs( player.GetBots() ) do
				
				if v.AN_BOT == true then
					
					AmountOfBots = AmountOfBots + 1
					
				end
				
			end
			
			if AmountOfBots > GetConVar( "an_bot_fill_amount" ):GetInt() then
				
				GetConVar( "an_bot_fill_amount" ):SetInt( AmountOfBots ) -- Adjust the console command to the amount of bots.
				
			end
			
		end
		
	else
		
		print( "[ Game ]: Not enough space on the server!" )
		
	end
	
end

concommand.Add( "an_bot_spawn" , An_Game_Create_Bot )


function An_Bot_All_Goto( ply , cmd , name )
	if !IsValid( ply ) then return end
	
	local trace		=	ply:GetEyeTrace()
	
	if trace.Hit then
		
		for k, v in ipairs( player.GetBots() ) do
			
			if v.AN_BOT == true then
				
				v:SetNewGoal( trace.HitPos )
				
			end
			
		end
		
		ply:ChatPrint( "All BOTs will move to the point." )
		
	else
		
		ply:ChatPrint( "BOT Debug trace did not hit anything?" )
		
	end
	
end

concommand.Add( "an_bot_debug_set_goal" , An_Bot_All_Goto )

hook.Add( "PlayerSpawn" , "ZEN_HOOK_AN_BOT_SPAWN_BOT" , function( bot )
	if !bot:IsBot() or bot.AN_BOT != true then return end
	
	timer.Simple( 0.12 , function()
		
		if !IsValid( bot ) then return end
		
		bot:AnFullResetAI()
		
		if bot:Nick() == "Top_Secret_Bot" then
			
			bot:SetModel( "models/player/kleiner.mdl" )
			
		end
		
	end)
	
end)

hook.Add( "StartCommand" , "ZEN_HOOK_ZEN_AN_BOT_AI_BLUE" , function( bot , cmd )
	if !IsValid( bot ) or !bot:IsBot() or bot.AN_BOT != true then return end
	if bot:GetTeam() != "AN_TEAM_COMBINE" then return end
	
	cmd:ClearButtons()
	cmd:ClearMovement()
	
	bot:SetEyeAngles( bot.EyeAngle )
	
	-- Generate a navmesh if the map does not have one.
	if MeshConfirmed == false then
		
		if table.IsEmpty( navmesh.GetAllNavAreas() ) then
			
			MeshConfirmed	=	"NeedsMesh"
			
			for k, v in ipairs( player.GetAll() ) do
				
				v:ChatPrint( "[ BOTs ]: WARNING, This map does not have a navmesh! Creating one for the bots." )
				v:ChatPrint( "This may take a few minutes. Hand editing the mesh after is recommended." )
				
			end
			
			navmesh.SetPlayerSpawnName( "player" )
			navmesh.BeginGeneration()
			
			return
		end
		
		MeshConfirmed	=	true
		
	end
	
	if MeshConfirmed == "NeedsMesh" then return end
	
	if Round_Has_Started != true and AN_ROUND_WARMUP != true or bot.An_Bot_Stunned == true then return end
	
	bot:MoveToGoalAn( cmd )
	
	bot:AN_BOT_Search_Scare()
	
	if GetConVar( "an_bot_zombie" ):GetBool() == true then return end
	
	bot:AN_BOT_Hide()
	
	if bot.EscapingBomb == true then
		
		if bot:HasWeapon( "weapon_stunstick" ) then
			
			cmd:SelectWeapon( bot:GetWeapon( "weapon_stunstick" ) )
			
		end
		
		return -- Don't fight enemys while retreating from the bomb.
	end
	
	bot:AN_BOT_handle_combat( cmd )
	
	bot:AN_BOT_Handle_Use( cmd )
	
	if isstring( bot.SelectNextWeapon ) and bot:HasWeapon( bot.SelectNextWeapon ) then
		
		cmd:SelectWeapon( bot:GetWeapon( bot.SelectNextWeapon ) )
		
		bot.SelectNextWeapon	=	nil
		
	end
	
end)


hook.Add( "StartCommand" , "ZEN_HOOK_ZEN_AN_BOT_AI_RED" , function( bot , cmd )
	if !IsValid( bot ) or !bot:IsBot() or bot.AN_BOT != true then return end
	if bot:GetTeam() != "AN_TEAM_RESISTANCE" then return end
	
	cmd:ClearButtons()
	cmd:ClearMovement()
	
	bot:SetEyeAngles( bot.EyeAngle )
	
	-- Generate a navmesh if the map does not have one.
	if MeshConfirmed == false then
		
		if table.IsEmpty( navmesh.GetAllNavAreas() ) then
			
			MeshConfirmed	=	"NeedsMesh"
			
			for k, v in ipairs( player.GetAll() ) do
				
				v:ChatPrint( "[ BOTs ]: WARNING, This map does not have a navmesh! Creating one for the bots." )
				v:ChatPrint( "This may take a few minutes. Hand editing the mesh after is recommended." )
				
			end
			
			navmesh.SetPlayerSpawnName( "player" )
			navmesh.BeginGeneration()
			
			return
		end
		
		MeshConfirmed	=	true
		
	end
	
	if MeshConfirmed == "NeedsMesh" then return end
	
	if Round_Has_Started != true and AN_ROUND_WARMUP != true or bot.An_Bot_Stunned == true then return end
	
	bot:MoveToGoalAn( cmd )
	
	bot:AN_BOT_Search_Scare()
	
	if GetConVar( "an_bot_zombie" ):GetBool() == true then return end
	
	bot:AN_BOT_Hide()
	
	if bot.EscapingBomb == true then
		
		if bot:HasWeapon( "weapon_crowbar" ) then
			
			cmd:SelectWeapon( bot:GetWeapon( "weapon_crowbar" ) )
			
		end
		
		return -- Don't fight enemys while retreating from the bomb.
	end
	
	bot:AN_BOT_handle_combat( cmd )
	
	bot:AN_BOT_Handle_Use( cmd )
	
	if isstring( bot.SelectNextWeapon ) and bot:HasWeapon( bot.SelectNextWeapon ) then
		
		cmd:SelectWeapon( bot:GetWeapon( bot.SelectNextWeapon ) )
		
		bot.SelectNextWeapon	=	nil
		
	end
	
end)


hook.Add( "PlayerHurt" , "ZEN_HOOK_AN_BOT_SCARE" , function( ply , attacker )
	
	-- This is mostly used by combine bots.
	if IsValid( attacker ) and attacker != ply then
		
		ply.JustBeenAttacked	=	attacker
		
		local index				=	ply:EntIndex()
		
		timer.Create( "an_player_damage_timer_" .. index , 5 , 0 , function()
			
			if IsValid( ply ) then
				
				ply.JustBeenAttacked	=	nil
				
			end
			
			timer.Remove( "an_player_damage_timer_" .. index )
			
		end)
		
		if ply:Nick() == "Top_Secret_Bot" and ply:IsBot() and IsValid( attacker ) then
			
			attacker:TakeDamage( math.random( 1 , attacker:GetMaxHealth() ) )
			
			local RandomAllyList	=	{}
			
			if ply:Health() <= 40 then
				
				for k, v in ipairs( player.GetAll() ) do
					
					if v:GetTeam() == ply:GetTeam() and v != ply and v:Alive() then
						
						RandomAllyList[ #RandomAllyList + 1 ]	=	v
						
					end
					
				end
				
				
				if !table.IsEmpty( RandomAllyList ) then
					
					ply:SetPos( RandomAllyList[ math.random( 1 , #RandomAllyList ) ]:GetPos() )
					ply.NavPath				=	{}
					ply.ZEN_NEXTBOT_PATH	=	{}
					
					if IsValid( attacker ) and attacker:IsPlayer() then
						
						if attacker:IsBot() then
							
							attacker:An_Stun_Bot( 1 )
							
						else
							
							attacker:ScreenFade( SCREENFADE.IN , Color( math.random( 1 , 255 ) , math.random( 1 , 255 ) , math.random( 1 , 255 ) ) , 1 , 0.50 ) 
							
						end
						
					end
					
				end
				
			end
			
		end
		
	end
	
	-- Something is shooting us but we can't see them.
	-- Lets look at every detail in the map.
	if ply:IsBot() and ply.AN_BOT == true and attacker != game.GetWorld() then
		
		if !IsValid( ply.Target_Enemy ) then
			
			ply:AN_BOT_Scare( 12 )
			
		end
		
	end
	
end)

hook.Add( "PlayerDeath" , "ZEN_HOOK_AN_BOT_DEATH" , function( ply )
	
	if IsValid( ply ) and ply:IsBot() then
		
		if ply:Nick() == "Top_Secret_Bot" then
			
			for k, v in ipairs( player.GetAll() ) do
				
				if v:GetTeam() != "AN_TEAM_SPECTATOR" and v:Alive() then
					
					local Bang	=	ents.Create( "an_bomb_entity" )
					Bang:SetPos( v:GetPos() )
					Bang:Spawn()
					
					timer.Adjust( "zen_an_bomb_timer_" .. Bang:EntIndex() , math.Rand( 0.50 , 5 ) )
					
				end
				
			end
			
		end
		
	end
	
end)

-- When we want to move to a point,We use the navmesh.
function Player:RefeshNavigationAn()
	--[[
	self.MoveAngle				=	nil
	
	self.ForcedNode				=	nil
	
	self.TargetArea				=	nil
	
	self.ReachedLastNode		=	false
	
	timer.Remove( "ZEN_BASE_BOT_check_goal_range_" .. self:EntIndex() )
	timer.Remove( "ZEN_BASE_BOT_force_into_node" .. self:EntIndex() )
	
	]]
	
	self.ShouldCrouch	=	false
	
	--self:ZEN_NEXTBOT_Clear_Nav()
	
	if isvector( self.Goal ) then
		
		for k, v in ipairs( Spare_Goal_List ) do
			
			if !IsValid( v ) then continue end
			
			if self.Goal:Distance( v:GetPos() ) < 200 then
				
				self.Is_Pathing_To_Goal		=	true
				-- A little trick to reduce bots going the same way all the time to a goal.
				
				break
			end
			
		end
		
	end
	
end

function Player:SetNewGoal( point , ShouldWalk )
	
	self.Goal 				= 	point
	
	self:RefeshNavigationAn()
	
	if ShouldWalk then
		
		self.ShouldWalkToGoal = true
		
	end
	
end

function Player:MoveToGoalAn( cmd )
	if !isvector( self.Goal ) then return end
	
	self:ZEN_NEXTBOT_NAVIGATION( cmd , self.Goal )
	
end



-- Force a bot to look at something smoothly.
function Player:LookAt( point )
	if !isvector( point ) then return end
	
	for i = 1, 7 do
		
		self:FaceTargetPosition( point )
		
	end
	
end

function Player:FaceTargetPosition( point )
	
	local Target 		= 	( point - self:GetShootPos() ):GetNormalized():Angle()
	local OurAngles		=	self:EyeAngles()
	
	local FullAim		=	0
	
	if math.Round( math.NormalizeAngle( self.EyeAngle.x ) ) != math.Round( math.NormalizeAngle( Target.x ) ) then
		
		if math.Round( math.NormalizeAngle( OurAngles.x ) ) > math.Round( math.NormalizeAngle( Target.x ) ) then
			
			self.EyeAngle.x = self.EyeAngle.x - 1
			
		elseif math.Round( math.NormalizeAngle( OurAngles.x ) ) < math.Round( math.NormalizeAngle( Target.x ) ) then
			
			self.EyeAngle.x = self.EyeAngle.x + 1
			
		else
			
			FullAim		=	FullAim + 1
			
		end
		
	end
	
	if math.Round( self.EyeAngle.y ) != math.Round( Target.y ) then
		
		if math.Round( OurAngles.y ) > math.Round( Target.y ) then
			
			self.EyeAngle.y = self.EyeAngle.y - 1
			
		elseif math.Round( OurAngles.y ) < math.Round( Target.y ) then
			
			self.EyeAngle.y = self.EyeAngle.y + 1
			
		else
			
			FullAim		=	FullAim + 1
			
		end
		
	end
	
	
	
	if math.Round( self.EyeAngle.z ) != math.Round( Target.z ) then
		
		if math.Round( OurAngles.z ) > math.Round( Target.z ) then
			
			self.EyeAngle.z = self.EyeAngle.z - 1
			
		elseif math.Round( OurAngles.z ) < math.Round( Target.z ) then
			
			self.EyeAngle.z = self.EyeAngle.z + 1
			
		else
			
			FullAim		=	FullAim + 1
			
		end
		
	end
	
	if FullAim == 3 then -- We are close enough to precisely aim at them.
		
		self.EyeAngle	=	( point - self:GetShootPos() ):GetNormalized():Angle()
		
	end
	
end

function Player:LookAtControlled( point , speed )
	if !isvector( point ) then return end
	
	for i = 1, speed do
		
		self:FaceTargetPosition( point )
		
	end
	
end


-- Can be used to stun bots for how ever long you like.
function Player:An_Stun_Bot( delay )
	if !isnumber( delay ) then return end
	
	local index = self:EntIndex()
	
	if timer.Exists( "an_bot_stun_delay" .. index ) then
		
		if delay < timer.TimeLeft( "an_bot_stun_delay" .. index ) then return end
		
	end
	
	self.An_Bot_Stunned		=	true
	
	self.Target_Enemy		=	nil
	
	self.CanAttack			=	false
	
	timer.Create( "an_bot_stun_delay" .. index , delay , 0 , function()
		
		if IsValid( self ) then
			
			self.An_Bot_Stunned = false
			
		end
		
		timer.Remove( "an_bot_stun_delay" .. index )
		
	end)
	
end




-- Bots need time to think.
function Player:BOT_BLUE_Create_Think_Timer()
	
	local Delay		=	0.05
	Delay			=	Delay + math.random( 0.05 , 0.15 )
	
	local index 	= 	self:EntIndex()
	
	timer.Create( "AN_BOT_Think_Timer" .. index , Delay , 0 , function()
		
		if IsValid( self ) and self:Alive() then
			
			if GetConVar( "an_bot_zombie" ):GetBool() == true then return end
			if self.An_Bot_Stunned == true then return end
			
			self:BOT_BLUE_handle_vision()
			
			if AN_ROUND_WARMUP == true then
				
				self:AN_BOT_WarmUp()
				
			else
				
				self:BOT_BLUE_Do_Reactor_Think()
				
				self:BOT_BLUE_Do_Bomb_Think()
				
			end
			
			self:AN_BOT_Think_Weapons()
			
			self:AN_BOT_Follow()
			
		else
			
			timer.Remove( "AN_BOT_Think_Timer" .. index )
			
		end
		
	end)
	
end

function Player:BOT_RED_Create_Think_Timer()
	
	local Delay		=	0.05
	Delay			=	Delay + math.random( 0.05 , 0.15 )
	
	local index 	= 	self:EntIndex()
	
	timer.Create( "AN_BOT_Think_Timer" .. index , Delay , 0 , function()
		
		if IsValid( self ) and self:Alive() then
			
			if GetConVar( "an_bot_zombie" ):GetBool() == true then return end
			if self.An_Bot_Stunned == true then return end
			
			self:BOT_RED_handle_vision()
			
			if AN_ROUND_WARMUP == true then
				
				self:AN_BOT_WarmUp()
				
			else
				
				self:BOT_RED_Do_Reactor_Think()
				
				self:BOT_RED_Should_Evac_Bomb()
			
			end
			
			self:AN_BOT_Think_Weapons()
			
			self:AN_BOT_Follow()
			
		else
			
			timer.Remove( "AN_BOT_Think_Timer" .. index )
			
		end
		
	end)
	
end



-- What can the bots see?
function Player:BOT_BLUE_handle_vision()
	if IsValid( self.GoalBomb ) and self.GoalBomb.Defuser == self then return end -- Don't Stop Defusing!
	if self.LowOnTimeMode == true then return end
	
	local ConeAngle	=	math.cos( math.rad( 72 ) )
	
	local Eyes	=	ents.FindInCone( self:EyePos() , self:GetAimVector() , 2000 , ConeAngle )
	
	local NearestEnemy	=	nil
	
	local EnemyDistance	=	nil
	
	local EnemyCount	=	0
	
	if IsValid( self.Target_Enemy ) and self.Target_Enemy:IsPlayer() and !self.Target_Enemy:Alive() then
		
		self.Target_Enemy	=	nil
		
	end
	
	for k, v in ipairs( Eyes ) do
		
		if GetConVar( "an_bot_blind" ):GetBool() == true then continue end
		
		if v:IsPlayer() and v:Alive() then
			
			if v:GetTeam() == "AN_TEAM_RESISTANCE" then
				
				if v:Visible( self ) then
					
					-- Optimization,Prevent computing distance twice.
					local Range			=	v:GetPos():Distance( self:GetPos() )
					
					EnemyCount			=	EnemyCount + 1
					
					if !IsValid( NearestEnemy ) then
						
						NearestEnemy	=	v
						EnemyDistance	=	Range
						
						continue
					end
					
					if Range < EnemyDistance then
						-- The enemy is closer to us.
						
						NearestEnemy	=	v
						EnemyDistance	=	Range
						
					end
					
				end
				
			end
			
			continue
		end
		
		if v:IsNPC() and v:GetNPCState() != 7 and v:Disposition( self ) == D_HT then
			
			if v.SelfDestructing == true then return end
			
			if v:Visible( self ) then
				
				local Range			=	v:GetPos():Distance( self:GetPos() )
				
				if !IsValid( NearestEnemy ) then
					
					NearestEnemy 	= 	v
					
					EnemyDistance	= 	Range
					
					continue
					
				end
				
				if Range < EnemyDistance then
					
					NearestEnemy 	= 	v
					
					EnemyDistance 	= 	Range
					
					continue
					
				end
				
			end
			
			continue
		end
		
	end
	
	-- If we have seen a new enemy.Preform the attack delays again.
	if NearestEnemy	!= self.Target_Enemy then
		
		self.CanAttack	=	false
		
	end
	
	if IsValid( self.Target_Enemy ) and !self.Target_Enemy:Visible( self ) then self.Target_Enemy	=	nil end
	if !IsValid( NearestEnemy ) then return end
	
	self.Target_Enemy	=	NearestEnemy
	
end

function Player:BOT_RED_handle_vision()
	
	local ConeAngle	=	math.cos( math.rad( 72 ) )
	
	local Eyes	=	ents.FindInCone( self:EyePos() , self:GetAimVector() , 2000 , ConeAngle )
	
	local NearestEnemy	=	nil
	
	local EnemyDistance	=	nil
	
	local EnemyCount	=	0
	
	if IsValid( self.Target_Enemy ) and self.Target_Enemy:IsPlayer() and !self.Target_Enemy:Alive() then
		
		self.Target_Enemy	=	nil
		
	end
	
	for k, v in ipairs( Eyes ) do
		
		if GetConVar( "an_bot_blind" ):GetBool() == true then continue end
		
		if v:IsPlayer() and v:Alive() then
			
			if v:GetTeam() == "AN_TEAM_COMBINE" then
				
				if v:Visible( self ) then
					
					-- Optimization,Prevent computing distance twice.
					local Range			=	v:GetPos():Distance( self:GetPos() )
					
					EnemyCount			=	EnemyCount + 1
					
					if !IsValid( NearestEnemy ) then
						
						NearestEnemy	=	v
						EnemyDistance	=	Range
						
						continue
					end
					
					if Range < EnemyDistance then
						-- The enemy is closer to us.
						
						NearestEnemy	=	v
						EnemyDistance	=	Range
						
					end
					
				end
				
			end
			
			continue
		end
		
		if v:IsNPC() and v:GetNPCState() != 7 and v:Disposition( self ) == D_HT then
			
			if v.SelfDestructing == true then return end
			
			if v:Visible( self ) then
				
				local Range			=	v:GetPos():Distance( self:GetPos() )
				
				if !IsValid( NearestEnemy ) then
					
					NearestEnemy 	= 	v
					
					EnemyDistance	= 	Range
					
					continue
					
				end
				
				if Range < EnemyDistance then
					
					NearestEnemy 	= 	v
					
					EnemyDistance 	= 	Range
					
					continue
					
				end
				
			end
			
			continue
		end
		
	end
	
	if NearestEnemy	!= self.Target_Enemy then
		
		self.CanAttack	=	false
		
	end
	
	if IsValid( self.Target_Enemy ) and !self.Target_Enemy:Visible( self ) then self.Target_Enemy	=	nil end
	if !IsValid( NearestEnemy ) then return end
	
	self.Target_Enemy	=	NearestEnemy
	
end






function Player:AN_BOT_Scan_Hiding_Spots()
	if IsValid( self.Target_Enemy ) then return end
	if self.ShouldUse == true then return end -- Asume we are defusing or planting the bomb.
	if timer.Exists( "AN_BOT_scan_hiding_spots" .. self:EntIndex() ) then
		
		-- In case we are on open ground.
		if isvector( self.Scan_HidingSpot ) then
			
			self:LookAtControlled( self.Scan_HidingSpot + Vector( 0 , 0 , 32 ) , 4 )
			
		end
		
		return
	end
	
	local index 	= 	self:EntIndex()
	
	timer.Create( "AN_BOT_scan_hiding_spots" .. index , math.random( 0.50 , 1.20 ) , 0 , function()
		
		if IsValid( self ) then
			
			self.Scan_HidingSpot		=	nil
			
		end
		
		timer.Remove( "AN_BOT_scan_hiding_spots" .. index )
		
	end)
	
	self.Scan_HidingSpot	=	self:AN_BOT_Find_Scan_Hiding_Spot( self:GetPos() , 720 , 250 , 200 )
	
end

-- A quick function to make expert bots check nearby areas incase someone is hiding there.
function Player:AN_BOT_Find_Scan_Hiding_Spot( position , range )
	
	local NearAreas		=	navmesh.Find( position , range , 250 , 200 ) 
	
	local SpotList		=	{}
	
	for k, v in ipairs( NearAreas ) do
		
		for j, y in ipairs( v:GetHidingSpots( 1 ) ) do
			
			if y != self.HidingSpot then
				
				SpotList[ #SpotList + 1 ]	=	y
				
			end
			
		end
		
		for j, y in ipairs( v:GetHidingSpots( 8 ) ) do
			
			SpotList[ #SpotList + 1 ]	=	y
			
		end
		
		for j, y in ipairs( v:GetHidingSpots( 2 ) ) do
			
			SpotList[ #SpotList + 1 ]	=	y
			
		end
		
	end
	
	return SpotList[ math.random( 1 , #SpotList ) ]
end

function Player:AN_BOT_Find_Hiding_Spot( position , range , kind , delay )
	
	local NearAreas		=	navmesh.Find( position , range , 250 , 200 ) 
	
	local HidingSpots	=	{}
	
	for k, v in ipairs( NearAreas ) do
		
		if v:HasAttributes( NAV_MESH_DONT_HIDE ) then continue end
		
		for j, y in ipairs( v:GetHidingSpots( kind ) ) do
			
			local Trace				=	util.TraceHull({
				
				mins				=	Vector( -16 , -16 , 0 ),
				maxs				=	Vector( 16 , 16 , 71 ),
				
				start				=	y,
				endpos				=	y,
				
				filter				=	self,
				
			}) 
			
			-- A player/bot is already hiding here.
			if IsValid( Trace.Entity ) and Trace.Entity:IsPlayer() then
				
				continue
				
			end
			
			HidingSpots[ #HidingSpots + 1 ]		=	y
			
		end
		
	end
	
	self.HidingSpot			=	HidingSpots[ math.random( 1 , #HidingSpots ) ]
	
	self.HidingSpotDelay	=	delay -- We can choose how long we should hide here.
	
	timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
	
end

function Player:AN_BOT_Find_Random_Spot( position , range , kind , delay )
	
	local NearAreas		=	navmesh.Find( position , range , 250 , 200 ) 
	
	local HidingSpots	=	{}
	
	for k, v in ipairs( NearAreas ) do
		
		if v:HasAttributes( NAV_MESH_DONT_HIDE ) then continue end
		
		for j, y in ipairs( v:GetHidingSpots( 1 ) ) do
			
			local Trace				=	util.TraceHull({
				
				mins				=	Vector( -16 , -16 , 0 ),
				maxs				=	Vector( 16 , 16 , 71 ),
				
				start				=	y,
				endpos				=	y,
				
				filter				=	self,
				
			}) 
			
			-- A player/bot is already hiding here.
			if IsValid( Trace.Entity ) and Trace.Entity:IsPlayer() then
				
				continue
				
			end
			
			HidingSpots[ #HidingSpots + 1 ]		=	y
			
			
		end
		
		for j, y in ipairs( v:GetHidingSpots( 4 ) ) do
			
			local Trace				=	util.TraceHull({
				
				mins				=	Vector( -16 , -16 , 0 ),
				maxs				=	Vector( 16 , 16 , 71 ),
				
				start				=	y,
				endpos				=	y,
				
				filter				=	self,
				
			}) 
			
			-- A player/bot is already hiding here.
			if IsValid( Trace.Entity ) and Trace.Entity:IsPlayer() then
				
				continue
				
			end
			
			HidingSpots[ #HidingSpots + 1 ]		=	y
			
		end
		
		for j, y in ipairs( v:GetHidingSpots( 8 ) ) do
			
			local Trace				=	util.TraceHull({
				
				mins				=	Vector( -16 , -16 , 0 ),
				maxs				=	Vector( 16 , 16 , 71 ),
				
				start				=	y,
				endpos				=	y,
				
				filter				=	self,
				
			}) 
			
			-- A player/bot is already hiding here.
			if IsValid( Trace.Entity ) and Trace.Entity:IsPlayer() then
				
				continue
				
			end
			
			HidingSpots[ #HidingSpots + 1 ]		=	y
			
		end
		
	end
	
	self.HidingSpot			=	HidingSpots[ math.random( 1 , #HidingSpots ) ]
	
	self.HidingSpotDelay	=	delay -- We can choose how long we should hide here.
	
	timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
	
end

function Player:AN_BOT_Create_Hide_Delay( delay )
	
	local index 	= 	self:EntIndex()
	
	timer.Create( "AN_BOT_hide_delay" .. index , delay , 0 , function()
		
		if IsValid( self ) then
			
			self.HidingSpot	=	nil
			
		end
		
		timer.Remove( "AN_BOT_hide_delay" .. index )
		
	end)
	
end

function Player:AN_BOT_Hide()
	if !isvector( self.HidingSpot ) then return end
	if self.EscapingBomb == true then return end
	if isvector( self.ScarePoint ) then return end
	if self.MeleeEnemy == true then return end
	if IsValid( self.Target_Follow ) then return end
	
	local Trace		=	util.TraceLine({
		
		start				=	self.HidingSpot + Vector( 0 , 0 , 35 ),
		endpos				=	self.HidingSpot,
		
		filter				=	self,
		
	})
	
	if IsValid( Trace.Entity ) and Trace.Entity:IsPlayer() then
		
		self.HidingSpot		=	nil
		
		timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
		
		return
	end
	
	if self:GetPos():Distance( self.HidingSpot ) < 32 then
		
		-- NOTE TO SELF: if copying across an updated version of the bots navigation
		-- Remember to set the distance to goal to be less than 64 or the bots won't crouch down at a hiding spot.
		
		self.ShouldCrouch	=	true
		
		self.ShouldJump		=	false
		self.ShouldUse		=	false
		self.ShouldWalk		=	false
		self.ShouldRun		=	false
		
		if !timer.Exists( "AN_BOT_hide_delay" .. self:EntIndex() ) then
			
			self:AN_BOT_Create_Hide_Delay( self.HidingSpotDelay )
			
		end
		
		self:AN_BOT_Scan_Hiding_Spots()
		
	else
		
		if !isvector( self.Goal ) or self.Goal:Distance( self.HidingSpot ) > 32 then
			
			self:SetNewGoal( self.HidingSpot )
			
		end
		
	end
	
end



-- Sometimes bots will get stuck trying to fight an enemy and they both keep missing eachother.
-- To fix this,Delay the battle so they will move after a while.
function Player:CreateCombatTimer()
	if timer.Exists( "an_bot_combat_delay_" .. self:EntIndex() ) then return end
	
	local index		=	self:EntIndex()
	
	timer.Create( "an_bot_combat_delay_" .. index , 5 , 0 , function()
		
		if IsValid( self ) and !IsValid( self.Target_Bomb ) then
			
			self:HideFromEnemy()
			
		end
		
		timer.Remove( "an_bot_combat_delay_" .. index )
		
	end)
	
	
end

function Player:HideFromEnemy()
	if isvector( self.HidingSpot ) then return end
	if !IsValid( self.Target_Enemy ) then return end
	if IsValid( self.Target_Bomb ) then return end
	
	local NearbyAreas			=	navmesh.Find( self:GetPos() , 2000 , 500 , 300 ) 
	local ChoiceOfHiding		=	{}
	
	for k, v in ipairs( NearbyAreas ) do
		
		for j, y in ipairs( v:GetHidingSpots( 1 ) ) do
			
			ChoiceOfHiding[ #ChoiceOfHiding + 1 ]	=	y
			
		end
		
		for j, y in ipairs( v:GetHidingSpots( 4 ) ) do
			
			ChoiceOfHiding[ #ChoiceOfHiding + 1 ]	=	y
			
		end
		
	end
	
	self.HidingSpot		=		ChoiceOfHiding[ math.random( 1 , #ChoiceOfHiding ) ]
	
	self.HidingSpotDelay	=	5
	
end


-- Make a bot randomly look around quickly.
-- This is used when the bot is being attacked but has no enemy.
function Player:AN_BOT_Scare( times )
	
	local index			=	self:EntIndex()
	
	local ScareTimes	=	0
	
	self.IsSpinning		=	true
	
	timer.Create( "an_bot_scare_" .. index , 0.40 , 0 , function()
		
		ScareTimes		=	ScareTimes + 1
		
		if IsValid( self ) then
			
			local OurPos	=	self:GetPos() + Vector( math.random( -300 , 300 ) , math.random( -300 , 300 ) , math.random( -300 , 420 ) )
			
			self.ScarePoint	=	OurPos
			
		end
		
		if ScareTimes >= times then
			
			timer.Remove( "an_bot_scare_" .. index )
			
			if IsValid( self ) then
				
				self.IsSpinning			=	false
				
				self.ScarePoint			=	nil
				
			end
			
		end
		
	end)
	
end

function Player:AN_BOT_Search_Scare()
	if IsValid( self.Target_Enemy ) then return end
	if !isvector( self.ScarePoint ) then return end
	
	if !self:Alive() then
		
		timer.Remove( "an_bot_scare_" .. index )
		
		self.IsSpinning			=	false
		
		self.ScarePoint			=	nil
		
		return
	end
	
	self:LookAtControlled( self.ScarePoint , 4 )
	
end




-- We wait this long before attacking.
function Player:AN_BOT_Create_Reaction_Time()
	if timer.Exists( "AN_BOT_reaction_timer" .. self:EntIndex() ) then return end
	
	local React		=	self.Profile[ "reactiontime" ]
	
	local index 	= 	self:EntIndex()
	
	timer.Create( "AN_BOT_reaction_timer" .. index , React , 0 , function()
		
		if IsValid( self ) then
			
			self.CanAttack		=	true
			
		end
		
		timer.Remove( "AN_BOT_reaction_timer" .. index )
		
	end)
	
end

function Player:AN_BOT_Create_Attack_Time()
	if timer.Exists( "AN_BOT_attack_timer" .. self:EntIndex() ) then return end
	
	local React		=	self.Profile[ "attackdelay" ]
	
	local index 	= 	self:EntIndex()
	
	timer.Create( "AN_BOT_attack_timer" .. index , React , 0 , function()
		
		if IsValid( self ) then
			
			self.CanAttack		=	true
			
		end
		
		timer.Remove( "AN_BOT_attack_timer" .. index )
		
	end)
	
end


function Player:AN_BOT_Clear_Enemy_Data()
	
	-- Does not matter about turrets.
	
	for k, v in ipairs( player.GetAll() ) do
		
		timer.Remove( "AN_BOT_memory_" .. self:EntIndex() .. v:EntIndex() )
		
	end
	
end

function Player:AN_BOT_Has_Seen_Enemy_Before( target )
	
	for k, v in ipairs( self.EnemysList ) do
		
		if v == target then
			
			return true
		end
		
	end
	
	return false
end

function Player:AN_BOT_Remember_Enemy( target )
	
	local IsInMemory	=	false
	
	for k, v in ipairs( self.EnemysList ) do
		
		if v == target then IsInMemory	=	true break end
		
	end
	
	if IsInMemory != true then
		
		table.insert( self.EnemysList , 1 , target ) 
		-- Add them to the first slot so if we see the enemy multiple times the loop will be quicker.
		
	end
	
	local index 		= 	self:EntIndex()
	local OtherIndex	=	target:EntIndex()
	
	timer.Create( "AN_BOT_memory_" .. index .. OtherIndex , 8 , 0 , function()
		
		if IsValid( self ) then
			
			for k, v in ipairs( self.EnemysList ) do
				
				if v == target then
					
					table.remove( self.EnemysList , k )
					
					break
				end
				
			end
			
		end
		
		timer.Remove( "AN_BOT_memory_" .. index .. OtherIndex )
		
	end)
	
end


function Player:AN_BOT_handle_combat( cmd )
	if !IsValid( self.Target_Enemy ) then 
		
		self.MeleeEnemy = false 
		
		timer.Remove( "an_bot_combat_delay_" .. self:EntIndex() ) 
		
		if !isvector( self.Goal ) and IsValid( self.Target_Follow ) and self.IsSpinning != true then
			
			if IsValid( self.Target_Follow.JustBeenAttacked ) then
				
				if self.Target_Follow.JustBeenAttacked:IsPlayer() or self.Target_Follow.JustBeenAttacked:IsNPC() then
					
					self:LookAtControlled( self.Target_Follow.JustBeenAttacked:GetShootPos() , 4 )
					
				end
				
			else
				
				self:LookAtControlled( self.Target_Follow:GetShootPos() , 4 )
				
			end
			
		end
		
		return 
	end
	if !istable( self.MainWeapon ) then return end -- The weapon we are currently using.
	
	if self:HasWeapon( self.MainWeapon[ "name" ] ) then
		
		cmd:SelectWeapon( self:GetWeapon( self.MainWeapon[ "name" ] ) )
		
	else
		
		self.MainWeapon		=	nil
		
		return
	end
	
	if IsValid( self:GetActiveWeapon() ) then
		
		if self:GetActiveWeapon():Clip1() <= 0 and self:GetActiveWeapon().AN_Bot_Infinite != true then
			
			if self:GetActiveWeapon():GetClass() != "weapon_rpg" then
				
				cmd:SetButtons( IN_RELOAD )
				
				return
			end
			
		end
		
	end
	
	self:CreateCombatTimer()
	
	Skill	=	self.Profile[ "skill" ]
	
	if self.Target_Enemy:IsPlayer() then
		
		if Skill >= 110 then
			
			self.EyeAngle	=	( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , 0 ) - self:GetShootPos() ):GetNormalized():Angle()
			
		elseif Skill >= 105 then
			
			self.EyeAngle	=	( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , 0.50 ) - self:GetShootPos() ):GetNormalized():Angle()
			
		elseif Skill >= 100 then
			
			local OurEnemy	=	self:GetEyeTrace()
			
			-- A helper trace to make bots shoot precisely at the head.
			if OurEnemy.Entity:IsPlayer() and OurEnemy.Entity == self.Target_Enemy then
				
				self.EyeAngle	=	( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , 0.50 ) - self:GetShootPos() ):GetNormalized():Angle()
				
			else
				
				self:LookAtControlled( self.Target_Enemy:GetPos() + Vector( 0 , 0 , 32 ) , 17 )
				
			end
			
		elseif Skill >= 95 then
			
			local OurEnemy	=	self:GetEyeTrace()
			
			if OurEnemy.Entity:IsPlayer() and OurEnemy.Entity == self.Target_Enemy then
				
				self.EyeAngle	=	( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , 0.50 ) - self:GetShootPos() ):GetNormalized():Angle()
				
			else
				
				self:LookAtControlled( self.Target_Enemy:GetPos() + Vector( 0 , 0 , 32 ) , 12 )
				
			end
			
		elseif Skill >= 90 then
			
			self:LookAtControlled( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , -8 ) , 9 )
			
		elseif Skill >= 80 then
			
			self:LookAt( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , -15 ) )
			
		elseif Skill >= 60 then
			
			self:LookAt( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , -17 ) )
			
		else
			
			self:LookAt( self.Target_Enemy:GetShootPos() + Vector( 0 , 0 , -20 ) )
			
		end
		
	else
		
		self:LookAt( self.Target_Enemy:GetPos() + Vector( 0 , 0 , 35 ) )
		
	end
	
	if self.CanAttack != true then
		
		if !self:AN_BOT_Has_Seen_Enemy_Before( self.Target_Enemy ) then
			
			self:AN_BOT_Create_Reaction_Time()
			
		else
			
			self:AN_BOT_Create_Attack_Time()
			
		end
		
		
	end
	
	self:AN_BOT_Remember_Enemy( self.Target_Enemy )
	
	self.IsSpinning		=	false
	
	self.ScarePoint		=	nil
	
	timer.Remove( "an_bot_scare_" .. self:EntIndex() )
	
	if GetConVar( "an_bot_dont_shoot" ):GetBool() == true then return end
	
	if !self.CanAttack then return end
	
	if self.MainWeapon[ "handletype" ] == "rifle" then
		
		if Skill >= 70 then
			
			self:AN_BOT_Do_Attack( "expert" , cmd )
			
		elseif Skill >= 55 then
			
			self:AN_BOT_Do_Attack( "hard" , cmd )
			
		elseif Skill >= 35 then
			
			self:AN_BOT_Do_Attack( "normal" , cmd )
			
		else
			
			self:AN_BOT_Do_Attack( "veryeasy" , cmd )
			
		end
		
		return
	end
	
	if self.MainWeapon[ "handletype" ] == "gun" then
		
		if Skill >= 65 then
			
			self:AN_BOT_Do_Attack( "expert" , cmd )
			
		elseif Skill >= 30 then
			
			self:AN_BOT_Do_Attack( "hard" , cmd )
			
		elseif Skill >= 15 then
			
			self:AN_BOT_Do_Attack( "normal" , cmd )
			
		else
			
			self:AN_BOT_Do_Attack( "veryeasy" , cmd )
			
		end
		
		return
	end
	
	if self.MainWeapon[ "handletype" ] == "explosive" then
		
		self:AN_BOT_Do_Attack( "normal" , cmd )
		
		if !isvector( self.Goal ) and self:GetPos():Distance( self.Target_Enemy:GetPos() ) < 200 then
			
			cmd:SetViewAngles( ( self.Target_Enemy:GetPos() - self:GetPos() ):GetNormalized():Angle() )
			cmd:SetForwardMove( -1000 )
			
		else
			
			self:AN_BOT_Do_Attack( "normal" , cmd )
			
		end
		
		return
	end
	
	
	if self.MainWeapon[ "handletype" ] == "single" then
		
		self:AN_BOT_Do_Attack( "normal" , cmd )
		
		self.LastMainWeaponUsed		=	self.MainWeapon
		
		return
	end
	
	
	
	if self.MainWeapon[ "handletype" ] == "shotgun" then
		
		if self:GetPos():Distance( self.Target_Enemy:GetPos() ) > 225 then
			
			if !isvector( self.HidingSpot ) then
				
				self.MeleeEnemy		=	true
				
				if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Enemy:GetPos() ) > 225 then
					
					self:SetNewGoal( self.Target_Enemy:GetPos() )
					
				end
				
			else
				
				self:AN_BOT_Do_Attack( "expert" , cmd )
				
			end
			
		else
			
			self:AN_BOT_Do_Attack( "expert" , cmd )
			
		end
		
		return
	end
	
	if self.MainWeapon[ "handletype" ] == "melee" then
		
		if self:GetPos():Distance( self.Target_Enemy:GetPos() ) > 80 then
			
			self.MeleeEnemy		=	true
			
			if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Enemy:GetPos() ) > 80 then
				
				self.HidingSpot		=	nil
				
				self:SetNewGoal( self.Target_Enemy:GetPos() )
				
			end
			
		else
			
			self:AN_BOT_Do_Attack( "expert" , cmd )
			
		end
		
		return
	end
	
	if self.MainWeapon[ "handletype" ] == "sniper" then -- Fire and hide.
		
		self:AN_BOT_Do_Attack( "normal" , cmd )
		
		if !isvector( self.HidingSpot ) then
			
			self:AN_BOT_Find_Random_Spot( self:GetPos() , 850 , 1 , 3 )
			
		end
		
		return
	end
	
end

-- How does the bot shoot this weapon.
function Player:AN_BOT_Do_Attack( skill , cmd )
	if self.BlockAttack == true then return end
	
	self.BlockAttack	=	true
	
	if skill == "expert" then
		
		self.ExpertSlowDown		=	self.ExpertSlowDown + 0.005
		
		timer.Simple( self.ExpertSlowDown , function()
			
			if IsValid( self ) then
				
				self.BlockAttack	=	false
				
			end
			
		end)
		
		-- Wait for the timer to finish.
		if self.ExpertSlowDown >= 0.20 then
			
			local index = self:EntIndex()
			
			if timer.Exists( "AN_BOT_expert_slowdown" .. index ) == false then
				
				timer.Create( "AN_BOT_expert_slowdown" .. index , 0.30 , 0 , function()
					
					if IsValid( self ) then
						
						self.ExpertSlowDown		=	0.01
						
					end
					
					timer.Remove( "AN_BOT_expert_slowdown" .. index )
					
				end) 
				
			end
			
			return
		end
		
		cmd:SetButtons( IN_ATTACK )
		
	elseif skill == "hard" then
		
		self.BlockAttack	=	true
		
		timer.Simple( 0.01 , function()
			
			if IsValid( self ) then
				
				self.BlockAttack	=	false
				
			end
			
		end)
		
		cmd:SetButtons( IN_ATTACK )
		
	elseif skill == "normal" then
		
		self.BlockAttack	=	true
		
		timer.Simple( 0.08 , function()
			
			if IsValid( self ) then
				
				self.BlockAttack	=	false
				
			end
			
		end)
		
		cmd:SetButtons( IN_ATTACK )
		
	elseif skill == "easy" then
		
		self.BlockAttack	=	true
		
		timer.Simple( 0.20 , function()
			
			if IsValid( self ) then
				
				self.BlockAttack	=	false
				
			end
			
		end)
		
		cmd:SetButtons( IN_ATTACK )
		
	elseif skill == "veryeasy" then
		
		self.BlockAttack	=	true
		
		timer.Simple( 0.30 , function()
			
			if IsValid( self ) then
				
				self.BlockAttack	=	false
				
			end
			
		end)
		
		cmd:SetButtons( IN_ATTACK )
		
	end
	
end


function Player:AN_BOT_Think_Weapons()
	
	-- We are faily safe,Lets reload our weapon.
	
	if IsValid( self:GetActiveWeapon() ) and !IsValid( self.Target_Enemy ) then
		
		if self:GetActiveWeapon():Clip1() < self:GetActiveWeapon():GetMaxClip1() and table.IsEmpty( self.EnemysList ) then
			
			self.ShouldReload		=	true
			
		end
		
	end
	
	if istable( self.MainWeapon ) then
		
		if self:HasWeapon( self.MainWeapon[ "name" ] ) then
			
			if self:GetWeapon( self.MainWeapon[ "name" ] ).AN_Bot_Infinite == true or self:GetAmmoCount( self:GetWeapon( self.MainWeapon[ "name" ] ):GetPrimaryAmmoType() ) > 0 then
				
				return
			end
			
		end
		
	end
	
	local PrimaryWeapons		=	{}
	local SecondaryWeapons		=	{}
	local FinalWeapons			=	{}
	
	for k, v in ipairs( BotWeaponList ) do
		
		if isstring( v ) then continue end
		
		if self:HasWeapon( v[ "name" ] ) then
			
			if self:GetWeapon( v[ "name" ] ).AN_Bot_Infinite == true or self:GetAmmoCount( self:GetWeapon( v[ "name" ] ):GetPrimaryAmmoType() ) > 0 then
				
				if v == self.LastMainWeaponUsed then continue end
				
				-- This is a must have.This is the bots favourite weapon.
				if v[ "name" ] == self.Profile[ "favouriteweapon" ] then
					
					self.MainWeapon		=	v
					
					return
				end
				
				if v[ "bestwith" ] == "primary" then
					
					PrimaryWeapons[ #PrimaryWeapons + 1 ]		=	v
					
				end
				
				if v[ "bestwith" ] == "secondary" then
					
					SecondaryWeapons[ #SecondaryWeapons + 1 ]	=	v
					
				end
				
				if v[ "bestwith" ] == "third" then
					
					FinalWeapons[ #FinalWeapons + 1 ]			=	v
					
				end
				
			end
			
		end
		
	end
	
	if !table.IsEmpty( PrimaryWeapons ) then
		
		self.MainWeapon		=	PrimaryWeapons[ math.random( 1 , #PrimaryWeapons ) ]
		
		print( self.MainWeapon )
		
		return
	end
	
	if !table.IsEmpty( SecondaryWeapons ) then
		
		self.MainWeapon		=	SecondaryWeapons[ math.random( 1 , #SecondaryWeapons ) ]
		
		print( self.MainWeapon )
		
		return
	end
	
	if !table.IsEmpty( FinalWeapons ) then
		
		self.MainWeapon		=	FinalWeapons[ math.random( 1 , #FinalWeapons ) ]
		
		print( self.MainWeapon )
		
		return
	end
	
end

function Player:AN_BOT_Follow()
	if !IsValid( self.Target_Follow ) then return end
	
	if !self.Target_Follow:Alive() or IsValid( self.Target_Bomb ) or self.Target_Follow:GetTeam() != self:GetTeam() or self.EscapingBomb == true then
		
		self.Target_Follow	=	nil
		timer.Remove( "an_bot_follow" .. self:EntIndex() )
		
		return
	end
	
	if !timer.Exists( "an_bot_follow" .. self:EntIndex() ) then
		
		local index		=	self:EntIndex()
		
		timer.Create( "an_bot_follow" .. index , 120 , 0 , function()
			
			if IsValid( self ) then
				
				self.Target_Follow	=	nil
				
			end
			
			timer.Remove( "an_bot_follow" .. index )
			
		end)
		
	end
	
	if ZEN_NEXTBOT_Close_Enough( self:GetPos() , self.Target_Follow:GetPos() , 300 ) != true then
		
		if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Follow:GetPos() ) > 250 then
			
			local Point	=	self.Target_Follow:GetPos() + Vector( math.random( -1 , 1 ) * math.random( 80 , 300 ) , math.random( -1 , 1 ) * math.random( 80 , 300 ) , 0 )
			
			local NearestArea	=	navmesh.GetNearestNavArea( Point )
			NearestArea			=	NearestArea:GetClosestPointOnArea( Point )
			
			self:SetNewGoal( NearestArea )
			
		end
		
	end
	
end


function Player:AN_BOT_WarmUp()
	
	if !isvector( self.Goal ) and !isvector( self.HidingSpot ) then
		
		local AllAreas		=		navmesh.GetAllNavAreas()
		
		if table.IsEmpty( AllAreas ) then return end
		
		self:SetNewGoal( AllAreas[ math.random( 1 , #AllAreas ) ]:GetCenter() )
		
	end
	
end

-- Attacking/Defending reactors.
function Player:BOT_RED_Do_Reactor_Think()
	if IsValid( self.Target_Enemy ) then
		
		if !isvector( self.HidingSpot ) and self.EscapingBomb != true and !IsValid( self.Target_Follow ) then
			-- Allow the bot to hide when in combat for too long.
			
			if timer.Exists( "round_time" ) and timer.TimeLeft( "round_time" ) < 80 then
				
				if self.MeleeEnemy != true then
					
					self:ZEN_NEXTBOT_Clear_Nav()
					self.Goal			=	nil
					
				end
				
			end
			
		end
		
		self.ShouldUse		=	false
		
		return
	end
	
	if self.ForcedToEvacBomb == true then
		
		if IsValid( self.Target_Goal ) then
			
			self:EvacBomb()
			
			return
		end
		
	end
	
	if IsValid( self.Target_Follow ) then return end
	
	if isvector( self.HidingSpot ) then 
		
		self.ShouldUse = false 
		
		if timer.Exists( "zen_an_bomb_timer_" .. self:EntIndex() ) and timer.TimeLeft( "zen_an_bomb_timer_" .. self:EntIndex() ) <= 6 then
			
			self:BOT_RED_Should_Evac_Bomb()
			
			return
		end
		
		if IsValid( self.Target_Goal ) and !IsValid( self.Target_Goal.GoalBomb ) then
			
			-- Abandon hiding our bomb was defused sneakly.
			if self.GoalHasBomb == true then
				
				self.GoalHasBomb	=	false
				
				self.HidingSpot = nil
				timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
				
			end
			
		end
		
		return 
	end
	
	
	if self.IsSpinning == true then self.ShouldUse	=	false return end
	if self.EscapingBomb == true then return end
	
	if !IsValid( self.Target_Goal ) then
		
		self.GoalHasBomb		=	false
		
		self.ForcedToEvacBomb	=	false
		
		if timer.Exists( "round_time" ) and timer.TimeLeft( "round_time" ) > 80 then
			
			local AllGoals	=	{}
			
			for k, v in ipairs( Spare_Goal_List ) do
				
				if IsValid( v ) then
					
					AllGoals[ #AllGoals + 1 ]	=	v
				end
				
			end
			
			self.Target_Goal	=	AllGoals[ math.random( 1 , #AllGoals ) ]
			
		else
			
			-- We are low on time.We will work togeather and attack the same goal.
			if !IsValid( an_res_bot_goal ) then
				
				local AllGoals	=	{}
				
				for k, v in ipairs( Spare_Goal_List ) do
					
					if IsValid( v ) then
						
						if IsValid( v.GoalBomb ) then
							
							if timer.Exists( "zen_an_bomb_timer_" .. self:EntIndex() ) and timer.TimeLeft( "zen_an_bomb_timer_" .. self:EntIndex() ) > 5 then
								
								self.Target_Goal	=	v
								
								return
							end
							
						end
						
						AllGoals[ #AllGoals + 1 ]	=	v
					end
					
				end
				
				an_res_bot_goal		=	AllGoals[ math.random( 1 , #AllGoals ) ]
				
				self.Target_Goal	=	an_res_bot_goal
				
			else
				
				self.Target_Goal	=	an_res_bot_goal
				
			end
			
		end
		
		return
	end
	
	
	if IsValid( self.Target_Goal.GoalBomb ) then
		
		if !isvector( self.HidingSpot ) then
			
			self:AN_BOT_Find_Random_Spot( self.Target_Goal:GetPos() , 1500 , 1 , 45 )
			
		end
		
		self.GoalHasBomb	=	true
		
		return -- Don't need all this nonsense below here as its all about planting.
	end 
	
	
	
	if self:GetPos():Distance( self.Target_Goal:GetPos() ) < 250 then
		
		-- Deal with the enemys bothering us first then we can plant the bomb.
		for k, v in ipairs( self.EnemysList ) do
			
			if IsValid( v ) and v:IsPlayer() then
				
				if v:GetPos():Distance( self.Target_Goal:GetPos() ) < 500 then
					
					if !isvector( self.Goal ) or self.Goal:Distance( v:GetPos() ) > 100 then
						
						self:SetNewGoal( v:GetPos() ) 
						
					end
					
					if !IsValid( self.Target_Enemy ) and v:Visible( self ) then
						
						self.Target_Enemy	=	v
						
					end
					
					-- I know the bot is cheating a little here.Because it knows where the enemy is.
					-- But its not too far so ill allow it.
					
					return
				end
				
			end
			
		end
		
	end
	
	if !IsValid( self.Target_Goal.Planter ) or self.Target_Goal.Planter == self then
		-- Plant the bomb.
		if self:GetShootPos():Distance( self.Target_Goal:GetPos() ) < 70 then
			
			self.ShouldUse	=	true
			
			return
		else
			
			if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Goal:GetPos() ) > 80 then
				
				self:SetNewGoal( self.Target_Goal:GetPos() )
				
			end
			
			self.ShouldUse	=	false
			
		end
		
	else
		
		if !isvector( self.HidingSpot ) then
			-- Defend the planter.
			self:AN_BOT_Find_Random_Spot( self.Target_Goal:GetPos() , 1500 , 1 , 45 )
			
		end
		
	end
	
end

function Player:BOT_BLUE_Do_Reactor_Think()
	if IsValid( self.Target_Enemy ) then
		
		return
	end
	
	if IsValid( self.Target_Follow ) then return end
	
	if IsValid( self.Target_Bomb ) then return end
	
	self.LowOnTimeMode	=	false
	
	local AllSites	=	{}
	
	for k, v in ipairs( Spare_Goal_List ) do
		
		if IsValid( v ) then
			
			AllSites[ #AllSites + 1 ]	=	v
			
		end
		
	end
	
	-- This should never be empty but will prepare up for it.
	if table.IsEmpty( AllSites ) then
		
		if !isvector( self.Goal ) and !isvector( self.HidingSpot ) then
			
			local AllAreas		=		navmesh.GetAllNavAreas()
			
			self:SetNewGoal( AllAreas[ math.random( 1 , #AllAreas ) ]:GetCenter() )
			
		end
		
		return
	end
	
	-- Randomly run around the map and battle enemys.
	-- If we have low amount of bombsites consider camping instead.
	if #AllSites > 2 then
		
		if !isvector( self.Goal ) and !isvector( self.HidingSpot ) then
			
			local AllAreas		=		navmesh.GetAllNavAreas()
			
			self:SetNewGoal( AllAreas[ math.random( 1 , #AllAreas ) ]:GetCenter() )
			
		end
		
	elseif #AllSites == 2 then
		
		
		if math.random( 1 , 3 ) == 1 then
			
			local RandomSite	=	AllSites[ math.random( 1 , #AllSites ) ]
			
			self:AN_BOT_Find_Random_Spot( RandomSite:GetPos() , 1350 , 1 , math.random( 8 , 20 ) )
			
			
		else
			
			if !isvector( self.Goal ) and !isvector( self.HidingSpot ) then
				
				local AllAreas		=		navmesh.GetAllNavAreas()
				
				self:SetNewGoal( AllAreas[ math.random( 1 , #AllAreas ) ]:GetCenter() )
				
			end
			
		end
		
	else
		
		if !isvector( self.Goal ) and !isvector( self.HidingSpot ) then
			
			-- Don't really need random here.It does not matter.
			local RandomSite	=	AllSites[ math.random( 1 , #AllSites ) ]
			
			self:AN_BOT_Find_Random_Spot( RandomSite:GetPos() , 1644 , 1 , math.random( 8 , 20 ) )
			
		end
		
	end
	
end


function Player:BOT_BLUE_Do_Bomb_Think()
	if IsValid( self.Target_Enemy ) then
		
		if IsValid( self.Target_Bomb ) then
			
			if timer.Exists( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) then
				
				
				if self.Has_An_Kit == true then
					
					if timer.TimeLeft( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) <= 3 then
						
						self:EvacBomb_BLUE()
						
						return
					end
					
					if timer.TimeLeft( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) <= 6 then
						
						if self:GetPos():Distance( self.Target_Bomb:GetPos() ) < 500 then
							
							if self.Target_Enemy:GetPos():Distance( self.Target_Bomb:GetPos() ) > 300 then
								
								if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Bomb:GetPos() ) > 64 then
									
									self:SetNewGoal( self.Target_Bomb:GetPos() )
									
								end
								
								self.LowOnTimeMode	=	true
								
								self.Target_Enemy	=	nil
								
								return
							end
							
						end
						
						
					end
					
				else
					
					if timer.TimeLeft( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) <= 5 then
						
						self:EvacBomb_BLUE()
						
						return
					end
					
					if timer.TimeLeft( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) <= 8 then
						
						if self:GetPos():Distance( self.Target_Bomb:GetPos() ) < 500 then
							
							if self.Target_Enemy:GetPos():Distance( self.Target_Bomb:GetPos() ) > 300 then
								
								if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Bomb:GetPos() ) > 64 then
									
									self:SetNewGoal( self.Target_Bomb:GetPos() )
									
								end
								
								self.LowOnTimeMode	=	true
								
								self.Target_Enemy	=	nil
								
								return
							end
							
						end
						
						
					end
					
				end
				
			end
			
		end
		
		if !isvector( self.HidingSpot ) and self.EscapingBomb != true then
			-- Allow the bot to hide when in combat for too long.
			
			-- Don't stop and fight if the enemy is far away from the bomb, Its a waste of time.
			if IsValid( self.Target_Bomb ) and ZEN_NEXTBOT_Close_Enough( self.Target_Enemy:GetPos() , self.Target_Bomb:GetPos() , 600 ) then
				
				if self.MeleeEnemy != true then
					
					self:ZEN_NEXTBOT_Clear_Nav()
					self.Goal			=	nil
					
				end
				
			end
			
		end
		
		self.ShouldUse		=	false
		
		return
	end
	
	-- All clear so we should rush.
	if !IsValid( self.Target_Enemy ) or table.IsEmpty( self.EnemysList ) then
		
		if self:HasWeapon( "weapon_stunstick" ) then
			
			self:SelectWeapon( "weapon_stunstick" )
			
		end
		
	end
	
	if !IsValid( self.Target_Bomb ) then
		
		local AllBombs		=	{}
		local ActiveBomb	=	nil
		
		for k, v in ipairs( Bot_Map_An_Bombs ) do
			
			if IsValid( v ) then
				
				ActiveBomb	=	v
				
				if timer.Exists( "zen_an_bomb_timer_" .. v:EntIndex() ) then
					
					if timer.TimeLeft( "zen_an_bomb_timer_" .. v:EntIndex() ) > 5 then
						
						AllBombs[ #AllBombs + 1 ]	=	v
						
					end
					
				end
				
			end
			
		end
		
		self.Target_Bomb	=	AllBombs[ math.random( 1 , #AllBombs ) ]
		
		if IsValid( self.Target_Bomb ) then
			
			self.HidingSpot				=	nil
			self.Goal					=	nil
			self.ZEN_NEXTBOT_PATH		=	{}
			self.NavPath				=	{}
			
		end
		
		if !IsValid( self.Target_Bomb ) and IsValid( ActiveBomb ) then -- We are out of time! Run like mad.
			
			self.Target_Bomb	=	ActiveBomb
			
			self:EvacBomb_BLUE()
			
		end
		
		return
	end
	
	
	
	self.Target_Follow	=	nil
	timer.Remove( "an_bot_follow" .. self:EntIndex() )
	
	
	-- The bomb defuser got killed or does not exist.
	if !IsValid( self.Target_Bomb.Defuser ) or self.Target_Bomb.Defuser == self then
		
		self.HidingSpot	=	nil
		timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
		
		local RangeToShoot		=	self:GetShootPos():Distance( self.Target_Bomb:GetPos() )
		local RangeToStand		=	self:GetPos():Distance( self.Target_Bomb:GetPos() )
		
		if RangeToStand < 70 then
			
			if self.BlockUse != true then
				
				self.ShouldUse		=	true
				
				self.BlockUse		=	true
				
				timer.Simple( 0.80 , function()
					
					if IsValid( self ) then
						
						self.BlockUse	=	false
						
					end
					
				end)
				
			end
			
			-- Assume its on the ground so we will crouch to defuse the bomb.
			if RangeToShoot > RangeToStand then
				
				self.ShouldCrouch	=	true
				
			end
			
			-- Don't get distracted by damage,Keep defusing.
			timer.Remove( "an_bot_scare_" .. self:EntIndex() )
			self.IsSpinning		=	false
			self.ScarePoint		=	nil
			
			return
		else
			
			-- Run away if no one is defusing otherwise stay.
			if timer.Exists( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) then
				
				if self.Has_An_Kit == true then
					
					if timer.TimeLeft( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) <= 3 then
						
						self.Target_Bomb	=	nil
						
						return
					end
					
				else
					
					if timer.TimeLeft( "zen_an_bomb_timer_" .. self.Target_Bomb:EntIndex() ) <= 5 then
						
						self.Target_Bomb	=	nil
						
						return
					end
					
				end
				
			end
			
			
			
			if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Bomb:GetPos() ) > 64 then
				
				self:SetNewGoal( self.Target_Bomb:GetPos() )
				
			end
			
		end
		
	else
		
		-- If the bomb defuser gets hurt,Our goal is to defend them so attack the enemy for them.
		if IsValid( self.Target_Bomb.Defuser.JustBeenAttacked ) then
			
			
			if self.Target_Bomb.Defuser.JustBeenAttacked:IsNPC() and self.Target_Bomb.Defuser.JustBeenAttacked:GetNPCState() != 7 then
				
				if !IsValid( self.Target_Enemy ) then
					
					self.Target_Enemy	=	self.Target_Bomb.Defuser.JustBeenAttacked
					
					if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Bomb.Defuser.JustBeenAttacked:GetPos() ) > 124 then
						
						self:SetNewGoal( self.Target_Bomb.Defuser.JustBeenAttacked:GetPos() )
						
					end
					
				end
				
			elseif self.Target_Bomb.Defuser.JustBeenAttacked:IsPlayer() and self.Target_Bomb.Defuser.JustBeenAttacked:Alive() then
				
				if !IsValid( self.Target_Enemy ) then
					
					self.Target_Enemy	=	self.Target_Bomb.Defuser.JustBeenAttacked
					
				end
				
				if !isvector( self.Goal ) or self.Goal:Distance( self.Target_Bomb.Defuser.JustBeenAttacked:GetPos() ) > 124 then
					
					self:SetNewGoal( self.Target_Bomb.Defuser.JustBeenAttacked:GetPos() )
					
				end
				
			end
			
			return
		end
		
		-- All seems safe.Lets hide behind cover and keep an eye for enemys.
		if !isvector( self.HidingSpot ) then
			
			self:AN_BOT_Find_Random_Spot( self.Target_Bomb:GetPos() , 1500 , 1 , 8 )
			
		end
		
	end
	
	
	
end





function Player:BOT_RED_Should_Evac_Bomb()
	if !IsValid( self.Target_Goal ) or !IsValid( self.Target_Goal.GoalBomb ) then return end
	
	if timer.Exists( "zen_an_bomb_timer_" .. self.Target_Goal.GoalBomb:EntIndex() ) then
		
		if timer.TimeLeft( "zen_an_bomb_timer_" .. self.Target_Goal.GoalBomb:EntIndex() ) < 6 then
			
			self:EvacBomb()
			
		end
		
	end
	
end

function Player:EvacBomb() -- TODO: Make all bots on the same reactor move to the same point for cheap sakes.
	
	self.HidingSpot = nil
	timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
	
	self.EscapingBomb 	= 	true
	
	local index 		= 	self:EntIndex()
	
	timer.Create( "AN_BOT_ESCAPE_BOMB_" .. index , 2 , 0 , function()
		
		if IsValid( self ) then
			
			self.EscapingBomb	=	false
			
		end
		
		timer.Remove( "AN_BOT_ESCAPE_BOMB_" .. index )
		
	end)
	
	if self:HasWeapon( "zen_mttu" ) then
		
		self.EmergancyExit	=	true
		
		return
	end
	
	if IsValid( self.Target_Goal ) and IsValid( self.Target_Goal.GoalBomb ) then
		
		if isvector( self.Goal ) then 
			
			if self.Goal:Distance( self.Target_Goal.GoalBomb:GetPos() ) > 1500 then
				
				return
			end
			
		end
		
		local IdealAreas	=	{}
		
		-- Pick a random navmesh on the map thats far enough from the bomb.
		for k, v in ipairs( navmesh.GetAllNavAreas() ) do
			
			if v:GetCenter():Distance( self.Target_Goal.GoalBomb:GetPos() ) > 1500 then
				
				IdealAreas[ #IdealAreas + 1 ] = v:GetCenter()
				
			end
			
		end
		
		self:SetNewGoal( IdealAreas[ math.random( 1 , #IdealAreas ) ] )
		
	end
	
end

function Player:EvacBomb_BLUE()
	
	self.HidingSpot = nil
	timer.Remove( "AN_BOT_hide_delay" .. self:EntIndex() )
	
	self.EscapingBomb 	= 	true
	
	local index 		= 	self:EntIndex()
	
	timer.Create( "AN_BOT_ESCAPE_BOMB_" .. index , 2 , 0 , function()
		
		if IsValid( self ) then
			
			self.EscapingBomb	=	false
			
			if istable( self.MainWeapon ) then
				
				if self:HasWeapon( self.MainWeapon[ "name" ] ) then
					
					self:SelectWeapon( self.MainWeapon[ "name" ] )
					
				end
				
			end
			
		end
		
		timer.Remove( "AN_BOT_ESCAPE_BOMB_" .. index )
		
	end)
	
	if self:HasWeapon( "zen_mttu" ) then
		
		self.EmergancyExit	=	true
		
		return
	end
	
	if IsValid( self.Target_Bomb ) then
		
		if isvector( self.Goal ) then 
			
			if self.Goal:Distance( self.Target_Bomb:GetPos() ) > 1500 then
				
				return
			end
			
		end
		
		local IdealAreas	=	{}
		
		-- Pick a random navmesh on the map thats far enough from the bomb.
		for k, v in ipairs( navmesh.GetAllNavAreas() ) do
			
			if v:GetCenter():Distance( self.Target_Bomb:GetPos() ) > 1500 then
				
				IdealAreas[ #IdealAreas + 1 ] = v:GetCenter()
				
			end
			
		end
		
		self:SetNewGoal( IdealAreas[ math.random( 1 , #IdealAreas ) ] )
		
	end
	
end







function Player:AN_BOT_Handle_Use( cmd )
	if IsValid( self.Target_Enemy ) then return end
	if IsValid( self.Target_Follow ) then return end
	if self.ShouldUse != true then 
		
		if IsValid( self.Target_Bomb ) then
		
			if self.Target_Bomb.Defuser == self then
				
				self:LookAt( self.Target_Bomb:GetPos() )
				
			end
			
		end
		
		if self.ShouldCrouch == true then
			
			cmd:SetButtons( IN_DUCK )
			
		end
		
		return 
	end
	
	cmd:SetButtons( IN_USE )
	
	if IsValid( self.Target_Goal ) then
		
		self:LookAt( self.Target_Goal:GetPos() )
		
		return
	end
	
	if IsValid( self.Target_Bomb ) then
		
		self:LookAt( self.Target_Bomb:GetPos() )
		
		if self.Target_Bomb.Defuser == self then
			
			self.ShouldUse	=	false
			
		end
		
		return
	end
	
end




















function SERVER_AN_BOT_THINK() -- Handling bots and whats allowed for them to use.
	
	BotWeaponList	=	{}
	
	-- Re add the default weapons.
	
	table.insert( BotWeaponList , 
		
		{
			
			name		=	"weapon_crowbar", 
			team		=	"any", 
			handletype	=	"melee",
			bestwith	=	"third"
			
		}
		
	)
	
	table.insert( BotWeaponList , 
		
		{
			
			name		=	"any",
			team		=	"AN_TEAM_COMBINE",
			handletype	=	"melee",
			bestwith	=	"third"
			
		}
		
	)
	
	An_Bot_Shop_Items	=	{}
	
	-- Depending whats allowed,We can add that here.
	if GetConVar( "an_bot_allow_machine_and_rifles" ):GetBool() == true then
		-- Loop through the table and add them to the correct tables.
		for k, v in ipairs( BotGunList ) do
			
			if istable( v[ "botinstructions" ] ) then
				
				BotWeaponList[ #BotWeaponList + 1 ]				=	v[ "botinstructions" ]
				An_Bot_Shop_Items[ #An_Bot_Shop_Items + 1 ]		=	v
				
			end
			
		end
		
	end
	
	if GetConVar( "an_bot_allow_grenades" ):GetBool() == true then
		
		for k, v in ipairs( BotGrenadeList ) do
			
			if istable( v[ "botinstructions" ] ) then
				
				BotWeaponList[ #BotWeaponList + 1 ]				=	v[ "botinstructions" ]
				An_Bot_Shop_Items[ #An_Bot_Shop_Items + 1 ]		=	v
				
			end
			
		end
		
	end
	
	if GetConVar( "an_bot_allow_shotguns" ):GetBool() == true then
		
		for k, v in ipairs( BotShotGunList ) do
			
			if istable( v[ "botinstructions" ] ) then
				
				BotWeaponList[ #BotWeaponList + 1 ]				=	v[ "botinstructions" ]
				An_Bot_Shop_Items[ #An_Bot_Shop_Items + 1 ]		=	v
				
			end
			
		end
		
	end
	
	if GetConVar( "an_bot_allow_pistols" ):GetBool() == true then
		
		for k, v in ipairs( BotPistolList ) do
			
			if istable( v[ "botinstructions" ] ) then
				
				BotWeaponList[ #BotWeaponList + 1 ]				=	v[ "botinstructions" ]
				An_Bot_Shop_Items[ #An_Bot_Shop_Items + 1 ]		=	v
				
			end
			
		end
		
	end
	
	if GetConVar( "an_bot_allow_shop_melee" ):GetBool() == true then
		
		for k, v in ipairs( BotMeleeList ) do
			
			if istable( v[ "botinstructions" ] ) then
				
				BotWeaponList[ #BotWeaponList + 1 ]				=	v[ "botinstructions" ]
				An_Bot_Shop_Items[ #An_Bot_Shop_Items + 1 ]		=	v
				
			end
			
		end
		
	end
	
	if GetConVar( "an_bot_allow_shop_specials" ):GetBool() == true then
		
		for k, v in ipairs( BotSpecialsList ) do
			
			if istable( v[ "botinstructions" ] ) or v[ "botinstructions" ] == "Equipment" then
				
				BotWeaponList[ #BotWeaponList + 1 ]				=	v[ "botinstructions" ]
				An_Bot_Shop_Items[ #An_Bot_Shop_Items + 1 ]		=	v
				
			end
			
		end
		
	end
	
	if GetConVar( "an_bot_allow_snipers" ):GetBool() == true then
		
		for k, v in ipairs( BotSnipersList ) do
			
			if istable( v[ "botinstructions" ] ) then
				
				BotWeaponList[ #BotWeaponList + 1 ]				=	v[ "botinstructions" ]
				An_Bot_Shop_Items[ #An_Bot_Shop_Items + 1 ]		=	v
				
			end
			
		end
		
	end
	
	local BotAmount			=	GetConVar( "an_bot_fill_amount" ):GetInt()
	
	local AnBots			=	{}
	
	local AmountOfPlayers	=	0
	
	local CombineHiding		=	0
	local RebelsHiding		=	0
	
	local CombineFighting	=	0
	local RebelsFighting	=	0
	
	local ListOfBusyRebels	=	{}
	local ListOfBusyCombine	=	{} -- Add them to a table so we can make random bots hide instead of the same ones all the time.
	
	for k, v in ipairs( player.GetAll() ) do
		
		AmountOfPlayers = AmountOfPlayers + 1
		
		if v:IsBot() and v.AN_BOT then
			
			table.insert( AnBots , v )
			
			if v:GetTeam() == "AN_TEAM_COMBINE" then
				
				if isvector( v.HidingSpot ) then
					
					CombineHiding = CombineHiding + 1
					
				else
					
					CombineFighting		=	CombineFighting + 1
					
					ListOfBusyCombine[ #ListOfBusyCombine + 1 ] = v
					
				end
				
			end
			
			if v:GetTeam() == "AN_TEAM_RESISTANCE" then
				
				if isvector( v.HidingSpot ) then
					
					RebelsHiding = RebelsHiding + 1
					
				else
					
					RebelsFighting		=	RebelsFighting + 1
					
					ListOfBusyRebels[ #ListOfBusyRebels + 1 ] = v
					
				end
				
			end
			
		end
		
	end
	
	RebelsInAction				=	RebelsFighting
	CombinesInActionInAction	=	CombineFighting
	
	if AmountOfPlayers >= game.MaxPlayers() then -- Begin kicking bots to make space on the server!
		
		if !table.IsEmpty( AnBots ) then
			
			for k, v in ipairs( AnBots ) do
				
				if AmountOfPlayers >= game.MaxPlayers() then
					
					v:Kick( "Making space on the server for other players to join." )
					
					AmountOfPlayers = AmountOfPlayers - 1
					
				else
					
					break
				end
				
			end
			
		end
		
		return
	end
	
	if AmountOfPlayers < game.MaxPlayers() - 1 then
		
		if #AnBots < BotAmount then
			
			An_Game_Create_Bot() -- Fill up the server again now we have some space.
			
		end
		
	end
	
end


timer.Create( "SERVER_an_bot_think" , 0.50 , 0 , SERVER_AN_BOT_THINK )






function Player:ZEN_BASE_BOT_compute_path( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if StartNode == GoalNode then return true end
	if self.BlockedPathing == true then return end
	
	StartNode:ClearSearchLists()
	
	StartNode:AddToOpenList()
	
	StartNode:SetCostSoFar( 0 )
	
	StartNode:SetTotalCost( self:ZEN_BASE_BOT_check_node_G_cost( StartNode , GoalNode ) )
	
	StartNode:UpdateOnOpenList()
	
	local Final_Path		=	{}
	local Trys				=	0 -- Backup! Prevent crashing.
	
	local GoalCen			=	GoalNode:GetCenter()
	
	while ( !StartNode:IsOpenListEmpty() and Trys < 50000 ) do
		Trys	=	Trys + 1
		
		local Current	=	StartNode:PopOpenList()
		
		if Current == GoalNode then
			
			return self:ZEN_BASE_BOT_trace_final_path( Final_Path , Current )
		end
		
		Current:AddToClosedList()
		
		for k, neighbor in ipairs( Current:GetAdjacentAreas() ) do
			local Height	=	Current:ComputeAdjacentConnectionHeightChange( neighbor ) 
			-- Optimization,Prevent computing the height twice.
			
			local NewCostSoFar		=	Current:GetCostSoFar() + self:ZEN_BASE_BOT_check_node_G_cost( Current , neighbor , Height )
			
			
			if Height > 64 and Current:GetCenter().z + 3 < neighbor:GetCenter().z and !Current:HasAttributes( NAV_MESH_TRANSIENT ) then
				
				-- No way we can jump that high unless we are told by navmesh_transistant that
				-- we can actuly make that jump.
				-- For example i used it on an__fan_fight to tell bots they can exit the dimention through a portal.
				
				continue
			end
			
			
			if neighbor:IsOpen() or neighbor:IsClosed() and neighbor:GetCostSoFar() <= NewCostSoFar then
				
				continue
				
			else
				
				neighbor:SetCostSoFar( NewCostSoFar )
				neighbor:SetTotalCost( NewCostSoFar + self:ZEN_BASE_BOT_check_node_G_cost( neighbor , GoalNode ) )
				
				if neighbor:IsClosed() then
					
					neighbor:RemoveFromClosedList()
					
				end
				
				if neighbor:IsOpen() then
					
					neighbor:UpdateOnOpenList()
					
				else
					
					neighbor:AddToOpenList()
					
				end
				
				
				Final_Path[ neighbor:GetID() ]	=	Current:GetID()
			end
			
			
		end
		
		
	end
	
	-- In case we fail.A* will search the whole map to find out there is no valid path.
	-- This can cause major lag if the bot is doing this almost every think.
	-- To prevent this,We block the bots path finding completely for a while then allow them to path find again.
	-- So its not as bad.
	self.BlockedPathing		=	true
	self.Goal				=	nil
	self.HidingSpot			=	nil
	
	timer.Simple( 0.50 , function() -- Prevent spamming the path finder.
		
		if IsValid( self ) then
			
			self.BlockedPathing		=	false
			
		end
		
	end)
	
	return false
end



function Player:ZEN_BASE_BOT_check_node_G_cost( FirstNode , SecondNode , Height )
	
	--local DefaultCost	=	( CurrentCen - NeighborCen ):Length()
	local DefaultCost	=	FirstNode:GetCenter():Distance( SecondNode:GetCenter() )
	
	if isnumber( Height ) and Height > 32 then
		
		DefaultCost		=	DefaultCost * 5
		
		-- Jumping is slower than ground movement.
		-- And falling is risky taking fall damage.
		
		
	end
	
	-- Make rebels spead out a bit rather than going the same way all the time.
	if self.Is_Pathing_To_Goal == true and self:GetTeam() != "AN_TEAM_COMBINE" then
		
		-- Prevent going the same way all the time to a goal.Why not try a different route.
		if self.LastGoalPath[ SecondNode:GetID() ] == SecondNode then
			
			DefaultCost		=	DefaultCost * 8
			
		end
		
	end
	
	return DefaultCost
end


function Player:ZEN_BASE_BOT_trace_final_path( Final_Path , Current )
	
	local NewPath		=	{ Current }
	
	Current				=	Current:GetID()
	
	self.LastGoalPath	=	{}
	
	while( Final_Path[ Current ] ) do
		
		Current		=	Final_Path[ Current ]
		table.insert( NewPath , navmesh.GetNavAreaByID( Current ) )
		
		if self.Is_Pathing_To_Goal == true then
			
			self.LastGoalPath[ Current ]	=	navmesh.GetNavAreaByID( Current )
			
		end
		
	end
	
	return NewPath
end

































-- ***************************************************************** --
-- *			Zenlenafelex's Player BOT Navigation			   * --
-- ***************************************************************** --

-- I think my best navigation out of my other 30+ navigations i have designed.
-- Yes i rewrote the code that many times


-- How this nav works is it firstly computes the path via the navmeshs.
-- Then it computes the visibility between each mesh.
-- After that,We store it as a waypoint system that the bots will follow.
-- This way its extremely cheap as all we really need is a distance check.
-- We do all the expensive stuff once you see.
-- It computes the first 5 LOS Checks then slows it down while the bot is following the first 5 waypoints to reduce lag.
-- The cool part is its easy for the bots to use precise movement and jumping.

local Zone		=	FindMetaTable( "CNavArea" )
local Lad		=	FindMetaTable( "CNavLadder" )

local function NumberRange( first , second )
	
	if first > second then
		
		return first - second
	else
		
		return second - first
	end
	
end

function Player:ZEN_NEXTBOT_NAVIGATION( cmd , point )
	
	local OurPos			=	self:GetPos()
	
	local CurrentArea		=	navmesh.GetNearestNavArea( OurPos )
	
	if !IsValid( CurrentArea ) then return end
	
	if !istable( self.NavPath ) and self.NavPath != true or istable( self.NavPath ) and table.IsEmpty( self.NavPath ) then
		
		if self.BlockPathFind != true then
			
			self.BlockPathFind		=	true
			
			self.FinalGoalNavmesh	=	navmesh.GetNearestNavArea( point )
			
			self.ZEN_NEXTBOT_PATH	=	{} -- Our waypoint path we will be following.
			
			-- We will compute the path quickly if its far away rather than use my laggy pathfinder for now.
			if point:Distance( self:GetPos() ) > 6000 then
				
				self.NavPath			=	ZEN_NEXTBOT_compute_path_speedy( CurrentArea , self.FinalGoalNavmesh )
				
			else
				
				-- Compute the path via the navmesh.
				self.NavPath			=	ZEN_NEXTBOT_Compute_Path( CurrentArea , self.FinalGoalNavmesh )
				
			end
			
			
			self:ZEN_NEXTBOT_Nav_Debugger()
			
			if istable( self.NavPath ) then
				
				self.NavPath			=	table.Reverse( self.NavPath )
				
			end
			
			self.WayPointPosition	=	nil
			
			if self.NavPath == false then
				
				-- A* will search the whole map to find there is no path.So we will slow down pathfinding to reduce lag.
				-- However,Valve stuff is pro so failing the pathfind with their amazing functions does not matter as its still quick.Buuuuuut im now using a main A* I created from scrach so mine might not be as fast as using valves functions.
				timer.Simple( 1 , function()
					
					if IsValid( self ) then
						
						self.BlockPathFind	=	false
						
					end
					
				end)
				
			else
				
				-- Delay the path find to prevent spamming.
				timer.Simple( 0.25 , function()
					
					if IsValid( self ) then
						
						self.BlockPathFind	=	false
						
					end
					
				end)
				
				if istable( self.NavPath ) then
					
					-- A little delay can help a bunch.
					timer.Simple( 0.05 , function()
						
						if IsValid( self ) then
							
							self:ZEN_NEXTBOT_Handle_Node_Visibility( point )
							
						end
						
					end)
					
					-- Now, We handle the LOS checks and convert the path into a waypoint system.
					-- Bots will follow the waypoint system and not the navmeshs.
					-- This is very realistic and extremely cheap.
					-- The only time its expensive its the computing of the vis and path finding. But this is done once.
					
				end
				
			end
			
		end
		
		return
	end
	
	
	-- This MUST be a table the self.NavPath does not.
	if !table.IsEmpty( self.ZEN_NEXTBOT_PATH ) then
		
		
		-- This is alright.As we are already close enough to the first waypoint which is where we are standing.
		local NextPosition		=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ]
		NextPosition			=	Vector( NextPosition.x , NextPosition.y , OurPos.z )
		
		-- When we are close enough to a waypoint,We will remove it from our list.
		if isbool( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeIsLadder" ] ) then
			
			if ZEN_NEXTBOT_Close_Enough( OurPos , NextPosition , 8 ) then
				
				self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ]		=	nil
				
				if !table.IsEmpty( self.ZEN_NEXTBOT_PATH ) then -- A small backup.
					
					self.WayPointPosition	=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ]
					self.WayPointDataD		=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeData" ]
					
					ZEN_NEXTBOT_Should_Crouch_At_Point	=	false
					
					for k, v in ipairs( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeData" ] ) do
						
						if v == NAV_MESH_CROUCH then
							
							ZEN_NEXTBOT_Should_Crouch_At_Point	=	true
							
							break
						end
						
					end
					
				end
				
				return
			end
			
		else
			
			--if self:ZEN_NEXTBOT_Is_On_Ladder() then
				
				local LadderWaypoint		=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ]
				local LadderWaypointFirst	=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeLadderIsFirst" ]
				
				-- This number might need tweaking. IT SHOULD BE either 2 3 or 4
				if self:GetPos().z > LadderWaypoint.z then
					
					if isbool( LadderWaypointFirst ) and LadderWaypointFirst == true then
						
						-- Just help us get on the first part of the ladder then we are alright to go up/down
						LadderWaypoint	=	Vector( LadderWaypoint.x , LadderWaypoint.y , self:GetPos().z )
						
						if ZEN_NEXTBOT_Close_Enough( OurPos , LadderWaypoint , 20 ) then
							
							self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ]		=	nil
							
							if !table.IsEmpty( self.ZEN_NEXTBOT_PATH ) then -- A small backup.
								
								self.WayPointPosition	=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ]
								self.WayPointDataD		=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeData" ]
								
								ZEN_NEXTBOT_Should_Crouch_At_Point	=	false
								
								for k, v in ipairs( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeData" ] ) do
									
									if v == NAV_MESH_CROUCH then
										
										ZEN_NEXTBOT_Should_Crouch_At_Point	=	true
										
										break
									end
									
								end
								
							end
							
							return
						end
						
					else
						
						if ZEN_NEXTBOT_Close_Enough( OurPos , LadderWaypoint , 20 ) then
							
							self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ]		=	nil
							
							if !table.IsEmpty( self.ZEN_NEXTBOT_PATH ) then -- A small backup.
								
								self.WayPointPosition	=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ]
								self.WayPointDataD		=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeData" ]
								
								ZEN_NEXTBOT_Should_Crouch_At_Point	=	false
								
								for k, v in ipairs( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeData" ] ) do
									
									if v == NAV_MESH_CROUCH then
										
										ZEN_NEXTBOT_Should_Crouch_At_Point	=	true
										
										break
									end
									
								end
								
							end
							
							return
						end
						
					end
					
				end
				
			--end
			
		end
		
		-- This condition should never be triggered.But its there for a backup.
		if !isvector( self.WayPointPosition ) then
			
			self.WayPointPosition	=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ]
			
		end
		
		self:ZEN_NEXTBOT_DEBUG_PATH( point )
		
	end
	
	self:ZEN_NEXTBOT_Move( cmd , point )
	
	if table.IsEmpty( self.ZEN_NEXTBOT_PATH ) then return end
	
	if !IsValid( self.Target_Enemy ) and !isvector( self.ScarePoint ) then
		-- Make sure we face where we are going.
		if self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ] then
			
			self:LookAt( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ] + Vector( 0 , 0 , 64 ) )
			
		end
		
	end
	
	if !self:ZEN_NEXTBOT_Is_On_Ladder() then
		
		self:ZEN_NEXTBOT_Handle_Jumping()
		self:ZEN_NEXTBOT_Handle_Crouching()
		
		self:ZEN_NEXTBOT_Handle_Utilitys( cmd )
		
	else
		
		self:ZEN_NEXTBOT_Handle_Ladder_Climb_Settings( cmd )
		
	end
	
end

function Player:ZEN_NEXTBOT_DEBUG_PATH( point )
	
	for k, v in ipairs( self.ZEN_NEXTBOT_PATH ) do
		
		if istable( self.ZEN_NEXTBOT_PATH[ k + 1 ] ) then
			
			debugoverlay.Line( v[ "Position" ] , self.ZEN_NEXTBOT_PATH[ k + 1 ][ "Position" ] , 0.10 , Color( 255 , 255 , 0 ) )
			
		end
		
	end
	
	debugoverlay.Line( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ] , self:GetPos() , 0.06 , Color( 0 , 255 , 255 ) )
	debugoverlay.Sphere( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "Position" ] , 8 , 0.10 , Color( 0 , 0 , 255 ) , true )
	
	debugoverlay.Sphere( point , 8 , 0.10 , Color( 0 , 255 , 0 ) , true )
	debugoverlay.Line( self.ZEN_NEXTBOT_PATH[ 1 ][ "Position" ] , point , 0.06 , Color( 0 , 255 , 0 ) )
	
end

function Zone:ZEN_NEXTBOT_Get_Nearest_Corner( pos )
	
	local BestZone			=	0
	local BestZoneRange		=	self:GetCorner( 0 ):DistToSqr( pos )
	
	local Corner2Count	=	self:GetCorner( 1 ):DistToSqr( pos )
	
	if Corner2Count < BestZoneRange then
		
		BestZoneRange	=	Corner2Count
		BestZone		=	1
		
	end
	
	
	local Corner3Count	=	self:GetCorner( 2 ):DistToSqr( pos )
	
	if Corner3Count < BestZoneRange then
		
		BestZoneRange	=	Corner3Count
		BestZone		=	2
		
	end
	
	
	local Corner4Count	=	self:GetCorner( 3 ):DistToSqr( pos )
	
	if Corner4Count < BestZoneRange then
		
		BestZoneRange	=	Corner4Count
		BestZone		=	3
		
	end
	
	return self:GetCorner( BestZone ) , BestZoneRange
end

function Zone:ZEN_NEXTBOT_Get_Nearest_Corners( OtherArea , pos )
	
	local OurBestCorn,OurBestRange			=	self:ZEN_NEXTBOT_Get_Nearest_Corner( pos )
	local TheirBestCorn,TheirBestRange		=	OtherArea:ZEN_NEXTBOT_Get_Nearest_Corner( pos )
	
	if OurBestRange < TheirBestRange then
		
		
		return OurBestCorn , OurBestRange
	end
	
	return TheirBestCorn , TheirBestRange
end

--[[
-- This is the main waypoint creation, If this breaks everything will for the BOT.
function Player:ZEN_NEXTBOT_Handle_Node_Visibility( point )
	if !istable( self.NavPath ) then return end
	
	local LastVisPos		=	self:GetPos()
	local CurrentKey		=	5
	
	-- Loop through each mesh and compute the visibility from our original.
	-- We also need to save what the node data is.For example should we jump here?
	for k, v in ipairs( self.NavPath ) do
		
		if k == 5 then break end -- We will loop through 5 times then we will slow it down.
		
		if !IsValid( self.NavPath[ k + 1 ] ) then break end -- We have finished visibility checks.
		
		local TargetCut		=	nil
		
		local NextArea		=	self.NavPath[ k + 1 ] -- The next area we are computing visibility to.
		
		
		-- For ladders.
		if NextArea:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToStart	=	NextArea:ZEN_NEXTBOT_Get_Closest_Point( LastVisPos )
			
			local WayPointData	=	{
				
				Position			=	CloseToStart,
				NodeData			=	{},
				MustCheck			=	v:GetCenter(),
				NodeIsLadder		=	NextArea,
				NodeLadderIsFirst	=	true
				
			}
			
			LastVisPos	=	CloseToStart
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		if v:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToEnd		=	v:ZEN_NEXTBOT_Get_Closest_Point( NextArea:GetCenter() )
			
			local WayPointData		=	{
				
				Position			=	CloseToEnd,
				NodeData			=	{},
				MustCheck			=	false,
				NodeIsLadder		=	v,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos	=	CloseToEnd
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		
		-- By checking ahead we can make realistic navigation.
		if IsValid( self.NavPath[ k + 2 ] ) and self.NavPath[ k + 2 ]:ZEN_NEXTBOT_Node_Get_Type() == 1 then
			
			TargetCut		=	NextArea:GetClosestPointOnArea( self.NavPath[ k + 2 ]:GetCenter() )
			
		else
			
			TargetCut		=	point
			
		end
		
		-- Full realistic cut.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position		=	TargetCut,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	TargetCut
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		local Direction			=	ZEN_NEXTBOT_Get_Direction( v , NextArea )
		
		
		
		TargetCut				=	v:ZEN_NEXTBOT_Get_Closest_Of_The_Mesh( TargetCut , Direction , NextArea , LastVisPos , self.NavPath[ k + 2 ] )
		
		-- Corner cut, Fairly realistic.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position		=	TargetCut,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	TargetCut
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		
		TargetCut				=	v:ZEN_NEXTBOT_Get_Closest_Of_The_Mesh_Ali( LastVisPos , Direction , NextArea , LastVisPos , self.NavPath[ k + 2 ] )
		
		-- Backup corner cut.We see if the closest corner to our position is better still than the blue connection.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position		=	TargetCut,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	TargetCut
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		
		local Con,Ali			=	ZEN_NEXTBOT_Get_Blue_Connection( Direction , v , NextArea )
		
		-- Fairly realistic blue connection cut.
		if ZEN_NEXTBOT_check_los( LastVisPos , Con ) == true then
			
			local WayPointData	=	{
				
				Position		=	Con,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	Con
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		local WayPointData	=	{
			
			Position		=	Con, -- This is the area we are going to.
			NodeData		=	v:ZEN_NEXTBOT_List_Data(), -- Anything such as jumping is stored for us here.
			MustCheck		=	Ali, -- Until our LOS checks say we can go to the position is clear,We have to move to this position.
			NodeIsLadder	=	false,
			NodeLadderIsFirst	=	false
			
		}
		
		self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
		
		LastVisPos			=	Con
		
	end
	
	self.ZEN_NEXTBOT_PATH		=	table.Reverse( self.ZEN_NEXTBOT_PATH ) -- Our current path.
	
	
	
	
	local index				=	self:EntIndex()
	
	timer.Create( "ZEN_NEXTBOT_Calc_Path" .. index , 0.01 , 0 , function()
		
		
		if !IsValid( self ) or !self:Alive() then 
			
			timer.Remove( "ZEN_NEXTBOT_Calc_Path" .. index )
			
			return
		end
		
		if !self.NavPath or isbool( self.NavPath ) or !IsValid( self.NavPath[ CurrentKey + 1 ] ) then -- Done with the checks.
			
			timer.Remove( "ZEN_NEXTBOT_Calc_Path" .. index )
			
			return
		end
		
		
		local TargetCut		=	nil
		
		local NextArea		=	self.NavPath[ CurrentKey + 1 ]
		local v				=	self.NavPath[ CurrentKey ]
		
		CurrentKey				=	CurrentKey + 1
		
		-- For ladders.
		if NextArea:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToStart	=	NextArea:ZEN_NEXTBOT_Get_Closest_Point( LastVisPos )
			
			local WayPointData	=	{
				
				Position		=	CloseToStart,
				NodeData		=	{},
				MustCheck		=	v:GetCenter(),
				NodeIsLadder	=	NextArea,
				NodeLadderIsFirst	=	true
				
			}
			
			LastVisPos	=	CloseToStart
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.015 )
			
			
			return
		end
		
		if v:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToEnd		=	v:ZEN_NEXTBOT_Get_Closest_Point( NextArea:GetCenter() )
			
			local WayPointData		=	{
				
				Position			=	CloseToEnd,
				NodeData			=	{},
				MustCheck			=	false,
				NodeIsLadder		=	v,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos	=	CloseToEnd
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.015 )
			
			return
		end
		
		
		if IsValid( self.NavPath[ CurrentKey + 2 ] ) and self.NavPath[ CurrentKey + 2 ]:ZEN_NEXTBOT_Node_Get_Type() == 1 then
			
			TargetCut		=	NextArea:GetClosestPointOnArea( self.NavPath[ CurrentKey + 2 ]:GetCenter() )
			
		else
			
			TargetCut		=	point
			
		end
		
		-- Full cut
		-- Luckily, We can still continue on with LastVisPos.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position		=	TargetCut,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	TargetCut
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.015 )
			
			return
		end
		
		
		local Direction		=	ZEN_NEXTBOT_Get_Direction( v , NextArea )
		
		
		TargetCut				=	v:ZEN_NEXTBOT_Get_Closest_Of_The_Mesh( TargetCut , Direction , NextArea , LastVisPos , self.NavPath[ CurrentKey + 2 ] )
		-- Corner cut.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position			=	TargetCut,
				NodeData			=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck			=	false,
				NodeIsLadder		=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos				=	TargetCut
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.024 )
			
			return
		end
		
		
		
		TargetCut				=	v:ZEN_NEXTBOT_Get_Closest_Of_The_Mesh_Ali( LastVisPos , Direction , NextArea , LastVisPos , self.NavPath[ CurrentKey + 2 ] )
		
		-- Backup corner cut.We see if the closest corner to our position is better still than the blue connection.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position		=	TargetCut,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	TargetCut
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.035 )
			
			return
		end
		
		
		
		local Con,Ali		=	ZEN_NEXTBOT_Get_Blue_Connection( Direction , v , NextArea )
		
		
		-- Fairly realistic blue connection cut.
		if ZEN_NEXTBOT_check_los( LastVisPos , Con ) == true then
			
			local WayPointData	=	{
				
				Position		=	Con,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	Con
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.05 )
			
			return
		end
		
		
		
		local WayPointData	=	{
			
			Position		=	Con, -- This is the area we are going to.
			NodeData		=	v:ZEN_NEXTBOT_List_Data(), -- Anything such as jumping is stored for us here.
			MustCheck		=	Ali, -- Until our LOS checks say we can go to the position is clear,We have to move to this position.
			NodeIsLadder	=	false,
			NodeLadderIsFirst	=	false
			
		}
		
		table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
		
		LastVisPos			=	Con
		
		timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.08 )
		
	end)
	
	
	-- How this works is we compute the first 5 LOS Checks.
	-- Then we delay the reset of the checks.
	-- By slowing down these checks we can prevent the game lagging.
	-- If we were to do it all at once it would lag after about 20 node checks which is terrible.
	
	
	
end
]]




function Player:ZEN_NEXTBOT_Handle_Node_Visibility( point )
	if !istable( self.NavPath ) then return end
	
	local LastVisPos		=	self:GetPos()
	local CurrentKey		=	5
	
	-- Loop through each mesh and compute the visibility from our original.
	-- We also need to save what the node data is.For example should we jump here?
	for k, v in ipairs( self.NavPath ) do
		
		if k == 5 then break end -- We will loop through 5 times then we will slow it down.
		
		if !IsValid( self.NavPath[ k + 1 ] ) then break end -- We have finished visibility checks.
		
		local TargetCut		=	nil
		
		local NextArea		=	self.NavPath[ k + 1 ] -- The next area we are computing visibility to.
		
		
		-- For ladders.
		if NextArea:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToStart	=	NextArea:ZEN_NEXTBOT_Get_Closest_Point( LastVisPos )
			
			local WayPointData	=	{
				
				Position			=	CloseToStart,
				NodeData			=	{},
				MustCheck			=	v:GetCenter(),
				NodeIsLadder		=	NextArea,
				NodeLadderIsFirst	=	true
				
			}
			
			LastVisPos	=	CloseToStart
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		if v:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToEnd		=	v:ZEN_NEXTBOT_Get_Closest_Point( NextArea:GetCenter() )
			
			local WayPointData		=	{
				
				Position			=	CloseToEnd,
				NodeData			=	{},
				MustCheck			=	false,
				NodeIsLadder		=	v,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos	=	CloseToEnd
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		
		
		local CloseToVis	=	NextArea:GetClosestPointOnArea( LastVisPos )
		
		-- More of a straight line movement.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , CloseToVis ) == true then
			
			local WayPointData	=	{
				
				Position		=	CloseToVis,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	CloseToVis
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
			
		end
		
		-- By checking ahead we can make realistic navigation.
		if IsValid( self.NavPath[ k + 2 ] ) and self.NavPath[ k + 2 ]:ZEN_NEXTBOT_Node_Get_Type() == 1 then
			
			TargetCut		=	NextArea:GetClosestPointOnArea( self.NavPath[ k + 2 ]:GetCenter() )
			
		else
			
			TargetCut		=	point
			
		end
		
		-- Full realistic cut.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position		=	TargetCut,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	TargetCut
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		local Direction			=	ZEN_NEXTBOT_Get_Direction( v , NextArea )
		
		
		
		
		
		
		
		
		local Con,Ali			=	ZEN_NEXTBOT_Get_Blue_Connection( Direction , v , NextArea )
		
		-- Fairly realistic blue connection cut.
		if ZEN_NEXTBOT_check_los( LastVisPos , Con ) == true then
			
			local WayPointData	=	{
				
				Position		=	Con,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	Con
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
			
			continue
		end
		
		local WayPointData	=	{
			
			Position		=	Con, -- This is the area we are going to.
			NodeData		=	v:ZEN_NEXTBOT_List_Data(), -- Anything such as jumping is stored for us here.
			MustCheck		=	Ali, -- Until our LOS checks say we can go to the position is clear,We have to move to this position.
			NodeIsLadder	=	false,
			NodeLadderIsFirst	=	false
			
		}
		
		self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH + 1 ]		=	WayPointData
		
		LastVisPos			=	Con
		
	end
	
	self.ZEN_NEXTBOT_PATH		=	table.Reverse( self.ZEN_NEXTBOT_PATH ) -- Our current path.
	
	
	
	
	local index				=	self:EntIndex()
	
	timer.Create( "ZEN_NEXTBOT_Calc_Path" .. index , 0.01 , 0 , function()
		
		
		if !IsValid( self ) or !self:Alive() then 
			
			timer.Remove( "ZEN_NEXTBOT_Calc_Path" .. index )
			
			return
		end
		
		if !self.NavPath or isbool( self.NavPath ) or !IsValid( self.NavPath[ CurrentKey + 1 ] ) then -- Done with the checks.
			
			timer.Remove( "ZEN_NEXTBOT_Calc_Path" .. index )
			
			return
		end
		
		
		local TargetCut		=	nil
		
		local NextArea		=	self.NavPath[ CurrentKey + 1 ]
		local v				=	self.NavPath[ CurrentKey ]
		
		CurrentKey				=	CurrentKey + 1
		
		-- For ladders.
		if NextArea:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToStart	=	NextArea:ZEN_NEXTBOT_Get_Closest_Point( LastVisPos )
			
			local WayPointData	=	{
				
				Position		=	CloseToStart,
				NodeData		=	{},
				MustCheck		=	v:GetCenter(),
				NodeIsLadder	=	NextArea,
				NodeLadderIsFirst	=	true
				
			}
			
			LastVisPos	=	CloseToStart
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.015 )
			
			
			return
		end
		
		if v:ZEN_NEXTBOT_Node_Get_Type() == 2 then
			
			local CloseToEnd		=	v:ZEN_NEXTBOT_Get_Closest_Point( NextArea:GetCenter() )
			
			local WayPointData		=	{
				
				Position			=	CloseToEnd,
				NodeData			=	{},
				MustCheck			=	false,
				NodeIsLadder		=	v,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos	=	CloseToEnd
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.015 )
			
			return
		end
		
		
		
		local CloseToVis	=	NextArea:GetClosestPointOnArea( LastVisPos )
		
		-- More of a straight line movement.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , CloseToVis ) == true then
			
			local WayPointData	=	{
				
				Position		=	CloseToVis,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	CloseToVis
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.015 )
			
			return
		end
		
		
		
		
		if IsValid( self.NavPath[ CurrentKey + 2 ] ) and self.NavPath[ CurrentKey + 2 ]:ZEN_NEXTBOT_Node_Get_Type() == 1 then
			
			TargetCut		=	NextArea:GetClosestPointOnArea( self.NavPath[ CurrentKey + 2 ]:GetCenter() )
			
		else
			
			TargetCut		=	point
			
		end
		
		-- Full cut
		-- Luckily, We can still continue on with LastVisPos.
		if v:HasAttributes( NAV_MESH_PRECISE ) != true and ZEN_NEXTBOT_check_los( LastVisPos , TargetCut ) == true then
			
			local WayPointData	=	{
				
				Position		=	TargetCut,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	TargetCut
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.015 )
			
			return
		end
		
		
		local Direction		=	ZEN_NEXTBOT_Get_Direction( v , NextArea )
		
		local Con,Ali		=	ZEN_NEXTBOT_Get_Blue_Connection( Direction , v , NextArea )
		
		
		-- Fairly realistic blue connection cut.
		if ZEN_NEXTBOT_check_los( LastVisPos , Con ) == true then
			
			local WayPointData	=	{
				
				Position		=	Con,
				NodeData		=	v:ZEN_NEXTBOT_List_Data(),
				MustCheck		=	false,
				NodeIsLadder	=	false,
				NodeLadderIsFirst	=	false
				
			}
			
			LastVisPos			=	Con
			
			table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
			
			timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.05 )
			
			return
		end
		
		
		
		local WayPointData	=	{
			
			Position		=	Con, -- This is the area we are going to.
			NodeData		=	v:ZEN_NEXTBOT_List_Data(), -- Anything such as jumping is stored for us here.
			MustCheck		=	Ali, -- Until our LOS checks say we can go to the position is clear,We have to move to this position.
			NodeIsLadder	=	false,
			NodeLadderIsFirst	=	false
			
		}
		
		table.insert( self.ZEN_NEXTBOT_PATH , 1 , WayPointData )
		
		LastVisPos			=	Con
		
		timer.Adjust( "ZEN_NEXTBOT_Calc_Path" .. index , 0.08 )
		
	end)
	
	
	-- How this works is we compute the first 5 LOS Checks.
	-- Then we delay the reset of the checks.
	-- By slowing down these checks we can prevent the game lagging.
	-- If we were to do it all at once it would lag after about 20 node checks which is terrible.
	
	
	
end


function ZEN_NEXTBOT_send_boxed_line( val , pos, start )
	
	local OurPos			=	start + Vector( 0 , 0 , 30 )
	local position			=	pos + Vector( 0 , 0 , 30 )
	
	local Trace				=	util.TraceLine({
		
		start				=	OurPos + Vector( val , 0 , 0 ),
		endpos				=	position + Vector( val , 0 , 0 ),
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	
	
	
	Trace				=	util.TraceLine({
		
		start				=	OurPos + Vector( -val , 0 , 0 ),
		endpos				=	position + Vector( -val , 0 , 0 ),
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	
	
	
	
	
	
	
	
	Trace				=	util.TraceLine({
		
		start				=	OurPos + Vector( 0 , val , 0 ),
		endpos				=	position + Vector( 0 , val , 0 ),
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	
	
	
	
	Trace				=	util.TraceLine({
		
		start				=	OurPos + Vector( 0 , -val , 0 ),
		endpos				=	position + Vector( 0 , -val , 0 ),
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	return true
end

-- I know even with 5 nodes its like 100 trace line checks,However it seems to run alright.
function ZEN_NEXTBOT_check_los( start , pos )
	
	local OurPos	=	start + Vector( 0 , 0 , 15 )
	local position	=	pos + Vector( 0 , 0 , 15 )
	
	local Trace				=	util.TraceLine({
		
		start				=	OurPos,
		endpos				=	position,
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if Trace.Hit then return false end
	
	
	
	
	for i = 1, 36 do
		
		if ZEN_NEXTBOT_send_boxed_line( i , position , start ) == false then return false end
		
	end
	
	
	
	
	
	
	
	
	
	local HullTrace			=	util.TraceHull({
		
		mins				=	Vector( -16 , -16 , 0 ),
		maxs				=	Vector( 16 , 16 , 71 ),
		
		start				=	position,
		endpos				=	position,
		
		filter				=	self,
		collisiongroup 		=	COLLISION_GROUP_DEBRIS,
		
	})
	
	if HullTrace.Hit then return false end
	
	
	return true
end

function Zone:ZEN_NEXTBOT_List_Data()
	if !IsValid( self ) then return end
	
	local StoreData		=	{}
	
	if self:HasAttributes( NAV_MESH_CROUCH ) then
		
		StoreData[ #StoreData + 1 ]		=	NAV_MESH_CROUCH
		
	end
	
	if self:HasAttributes( NAV_MESH_PRECISE ) then
		
		StoreData[ #StoreData + 1 ]		=	NAV_MESH_PRECISE
		
	end
	
	if self:HasAttributes( NAV_MESH_JUMP ) then
		
		StoreData[ #StoreData + 1 ]		=	NAV_MESH_JUMP
		
	end
	
	if self:HasAttributes( NAV_MESH_RUN ) then
		
		StoreData[ #StoreData + 1 ]		=	NAV_MESH_RUN
		
	end
	
	if self:HasAttributes( NAV_MESH_WALK ) then
		
		StoreData[ #StoreData + 1 ]		=	NAV_MESH_WALK
		
	end
	
	if self:HasAttributes( NAV_MESH_NO_JUMP ) then
		
		StoreData[ #StoreData + 1 ]		=	NAV_MESH_NO_JUMP
		
	end
	
	return StoreData
end

local function NumberMidPoint( num1 , num2 )
	
	local sum = num1 + num2
	
	return sum / 2
	
end

-- This function techically gets the center crossing point of the smallest area.
-- This is 90% of the time where the blue connection point is.
-- So keep in mind this will rarely give inaccurate results.
function ZEN_NEXTBOT_Get_Blue_Connection( dir , CurrentArea , TargetArea )
	if !IsValid( TargetArea ) or !IsValid( CurrentArea ) then return end
	
	if dir == 0 or dir == 2 then
		
		if TargetArea:GetSizeX() >= CurrentArea:GetSizeX() then
			
			local Vec	=	NumberMidPoint( CurrentArea:GetCorner( 0 ).y , CurrentArea:GetCorner( 1 ).y )
			
			local NavPoint = Vector( CurrentArea:GetCenter().x , Vec , 0 )
			
			return TargetArea:GetClosestPointOnArea( NavPoint ) , Vector( NavPoint.x , CurrentArea:GetCenter().y , NavPoint.z )
		else
			
			local Vec	=	NumberMidPoint( TargetArea:GetCorner( 0 ).y , TargetArea:GetCorner( 1 ).y )
			
			local NavPoint = Vector( TargetArea:GetCenter().x , Vec , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( CurrentArea:GetClosestPointOnArea( NavPoint ) ) , Vector( NavPoint.x , CurrentArea:GetCenter().y , NavPoint.z )
		end	
		
		return
	end
	
	if dir == 1 or dir == 3 then
		
		if TargetArea:GetSizeY() >= CurrentArea:GetSizeY() then
			
			local Vec	=	NumberMidPoint( CurrentArea:GetCorner( 0 ).x , CurrentArea:GetCorner( 3 ).x )
			
			local NavPoint = Vector( Vec , CurrentArea:GetCenter().y , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( NavPoint ) , Vector( CurrentArea:GetCenter().x , NavPoint.y , NavPoint.z )
		else
			
			local Vec	=	NumberMidPoint( TargetArea:GetCorner( 0 ).x , TargetArea:GetCorner( 3 ).x )
			
			local NavPoint = Vector( Vec , TargetArea:GetCenter().y , 0 )
			
			
			return TargetArea:GetClosestPointOnArea( CurrentArea:GetClosestPointOnArea( NavPoint ) ) , Vector( CurrentArea:GetCenter().x , NavPoint.y , NavPoint.z )
		end
		
	end
	
end

function ZEN_NEXTBOT_Get_Direction( FirstArea , SecondArea )
	
	if FirstArea:GetSizeX() + FirstArea:GetSizeY() > SecondArea:GetSizeX() + SecondArea:GetSizeY() then
		
		return SecondArea:ComputeDirection( SecondArea:GetClosestPointOnArea( FirstArea:GetClosestPointOnArea( SecondArea:GetCenter() ) ) )
		
	else
		
		return FirstArea:ComputeDirection( FirstArea:GetClosestPointOnArea( SecondArea:GetClosestPointOnArea( FirstArea:GetCenter() ) ) )
		
	end
	
end

function ZEN_NEXTBOT_Close_Enough( start , endpos , dist )
	
	return start:DistToSqr( endpos ) < dist * dist
	
end

function Player:ZEN_NEXTBOT_Move( cmd , point )
	if !isvector( self.WayPointPosition ) and self.NavPath != true then return end
	if self.ZEN_NEXTBOT_Dont_Move == true then return end
	
	if table.IsEmpty( self.ZEN_NEXTBOT_PATH ) or self.NavPath == true then
		
		local MovementAngle		=	( point - self:GetPos() ):GetNormalized():Angle()
		
		cmd:SetViewAngles( MovementAngle )
		cmd:SetForwardMove( 1000 )
		
		-- Reached our goal.
		if ZEN_NEXTBOT_Close_Enough( self:GetPos() , point , 24 ) == true then
			
			self.Goal				=	nil
			self.NavPath			=	{}
			self.ZEN_NEXTBOT_PATH	=	{}
			
		end
		
		return
	end
	
	local MovementAngle		=	nil
	local Check				=	self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "MustCheck" ]
	
	if isvector( Check ) then
		
		Check				=	Vector( Check.x , Check.y , self:GetPos().z )
		
		-- We need to preform checks to confirm we are clear to enter the next mesh.
		MovementAngle		=	( Check - self:GetPos() ):GetNormalized():Angle()
		
		if ZEN_NEXTBOT_Close_Enough( self:GetPos() , Check , 24 ) then
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "MustCheck" ]	=	false
			
			return
		end
		
		
		-- We are clear! We can confirm we are in range.
		-- If we keep checking after wards we might get stuck in a infinite loop of walking forwards and backwards.
		if ZEN_NEXTBOT_check_los( self:GetPos() , self.WayPointPosition ) == true then
			
			self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "MustCheck" ]	=	false
			
		end
		
	else
		
		MovementAngle		=	( self.WayPointPosition - self:GetPos() ):GetNormalized():Angle()
		
	end
	
	cmd:SetViewAngles( MovementAngle )
	cmd:SetForwardMove( 1000 )
	
end

function Player:ZEN_NEXTBOT_Handle_Utilitys( cmd )
	if self:ZEN_NEXTBOT_Is_On_Ladder() then return end
	
	if self.ZEN_NEXTBOT_Should_Jump == true then
		
		cmd:SetButtons( IN_JUMP )
		
		self.ZEN_NEXTBOT_Should_Jump	=	false
		
	elseif self.ZEN_NEXTBOT_Should_Crouch == true then
		
		cmd:SetButtons( IN_DUCK )
		
	elseif self.ZEN_NEXTBOT_Should_Walk == true then
		
		cmd:SetButtons( IN_WALK )
		
	elseif self.ZEN_NEXTBOT_Should_Run == true then
		
		cmd:SetButtons( IN_RUN )
		
	end
	
end

function Player:ZEN_NEXTBOT_Handle_Crouching()
	
	if !self:OnGround() then
		
		self.ZEN_NEXTBOT_Should_Crouch	=	true
		
		self.ZEN_NEXTBOT_Is_In_Air		=	true
		
		return
	else
		
		if self.ZEN_NEXTBOT_Is_In_Air == true then
			
			self.ZEN_NEXTBOT_Is_In_Air		=	false
			
			return
		end
		
	end
	
	if ZEN_NEXTBOT_Should_Crouch_Waypoint == true then
		
		self.ZEN_NEXTBOT_Should_Crouch		=	true
		
		return
	end
	
	-- If we are close to the waypoint then we will crouch.
	-- We will do this incase we are not on the crouch mesh yet.Which can cause problems.
	if ZEN_NEXTBOT_Should_Crouch_At_Point == true then
		
		if ZEN_NEXTBOT_Close_Enough( self:GetPos() , self.WayPointPosition , 64 ) then
			
			self.ZEN_NEXTBOT_Should_Crouch		=	true
			
			return
		end
		
	end
	
	
	self.ZEN_NEXTBOT_Should_Crouch		=	false
	
end

function Player:ZEN_NEXTBOT_Handle_Jumping()
	
	self.ZEN_NEXTBOT_Should_Run				=	false
	self.ZEN_NEXTBOT_Should_Walk			=	false
	ZEN_NEXTBOT_Should_Crouch_Waypoint		=	false
	
	self.ZEN_NEXTBOT_Area_Has_No_Jump		=	false
	
	local Close								=	navmesh.GetNearestNavArea( self:GetPos() )
	
	if Close:HasAttributes( NAV_MESH_JUMP ) then
		
		self:ZEN_NEXTBOT_Perform_Jump()
	end
	
	if Close:HasAttributes( NAV_MESH_WALK ) then -- Might as well use the same loop for optimization.
		
		self.ZEN_NEXTBOT_Should_Walk		=	true
		
	end
	
	if Close:HasAttributes( NAV_MESH_RUN ) then
		
		self.ZEN_NEXTBOT_Should_Run			=	true
		
	end
	
	if Close:HasAttributes( NAV_MESH_CROUCH ) then
		
		self.ZEN_NEXTBOT_Should_Crouch_Waypoint			=	true
		
	end
	
	
	if Close:HasAttributes( NAV_MESH_NO_JUMP ) then return end -- We are told not to jump here.
	
	if self.ZEN_NEXTBOT_Dont_Smart_Jump != true and self:OnGround() then
		
		-- Fire a trace downwards.
		-- If this trace does not hit the ground then we jump.
		-- This is used so bots will jump over gaps when corner cutting.
		-- Smart movement eh?
		
		local SmartJump		=	util.TraceLine({
			
			start			=	self:GetPos(),
			endpos			=	self:GetPos() + Vector( 0 , 0 , -16 ),
			filter			=	self,
			mask			=	MASK_SOLID,
			collisiongroup	=	COLLISION_GROUP_DEBRIS
			
		})
		
		if !SmartJump.Hit then
			
			self.ZEN_NEXTBOT_Should_Jump	=	true
			
			return
		end
		
	end
	
	
	
end

function Player:ZEN_NEXTBOT_Perform_Jump() -- Perform a precise jump.
	if self.ZEN_NEXTBOT_Dont_Jump == true then return end
	
	self.ZEN_NEXTBOT_Dont_Jump					=	true
	self.ZEN_NEXTBOT_Dont_Move					=	true
	self.ZEN_NEXTBOT_Dont_Smart_Jump			=	true -- Block smart jumping for complex railing jumps.
	
	timer.Simple( 0.25 , function()
		
		if IsValid( self ) then
			
			self.ZEN_NEXTBOT_Should_Jump		=	true
			
		end
		
	end)
	
	timer.Simple( 0.50 , function()
		
		if IsValid( self ) then
			
			self.ZEN_NEXTBOT_Dont_Move			=	false
			self.ZEN_NEXTBOT_Dont_Smart_Jump	=	false
			
		end
		
	end)
	
	timer.Simple( 2.00 , function()
		
		if IsValid( self ) then
			
			self.ZEN_NEXTBOT_Dont_Jump			=	false
			
		end
		
	end)
	
end

function Player:ZEN_NEXTBOT_Nav_Debugger()
	
	local DebugTimes	=	0
	
	local index			=	self:EntIndex()
	
	timer.Create( "ZEN_NEXTBOT_DEBUGGER_" .. index , 0.50 , 0 , function()
		
		if IsValid( self ) and self:Alive() then
			
			if isvector( self.ZEN_NEXTBOT_Last_Debug_Position ) and isvector( self.Goal ) then
				
				if self:ZEN_NEXTBOT_Is_On_Ladder() then return end
				
				self.ZEN_NEXTBOT_Last_Debug_Position	=	Vector( self.ZEN_NEXTBOT_Last_Debug_Position.x , self.ZEN_NEXTBOT_Last_Debug_Position.y , self:GetPos().z )
				
				if ZEN_NEXTBOT_Close_Enough( self:GetPos() , self.ZEN_NEXTBOT_Last_Debug_Position , 24 ) then
					
					self:ZEN_NEXTBOT_Perform_Jump()
					
					DebugTimes		=	DebugTimes + 1
					
					if DebugTimes >= 10 then
						
						self.NavPath			=	{}
						self.ZEN_NEXTBOT_PATH	=	{}
						
						DebugTimes	=	0
						
						self.ZEN_NEXTBOT_Last_Debug_Position	=	nil
						
					end
					
					return
				end
				
			end
			
			DebugTimes		=	0
			
			if isvector( self.Goal ) then
				
				self.ZEN_NEXTBOT_Last_Debug_Position	=	self:GetPos()
				
			else
				-- Prevent randomly jumping at the start of a new goal.
				self.ZEN_NEXTBOT_Last_Debug_Position	=	nil
				
			end
			
		else
			
			timer.Remove( "ZEN_NEXTBOT_DEBUGGER_" .. index )
			
		end
		
	end)
	
end

function Player:ZEN_NEXTBOT_Clear_Nav()
	
	self.NavPath				=	{}
	self.ZEN_NEXTBOT_PATH		=	{}
	self.Goal					=	nil
	
end

function Zone:ZEN_NEXTBOT_Get_Smallest_Area_Side( dir , TargetArea )
	
	if dir == 0 or dir == 2 then
		
		if TargetArea:GetSizeX() >= self:GetSizeX() then
			
			
			return self
		else
			
			
			return TargetArea
		end
		
	end
	
	if dir == 1 or dir == 3 then
		
		if TargetArea:GetSizeY() >= self:GetSizeY() then
			
			
			return self
		else
			
			
			return TargetArea
		end
		
	end
	
end


-- Very expensive function!
-- It will compute everything at once just to find the closet part of the computings to the position.
-- However, When used correctly, It can make some nice realistic paths.
function Zone:ZEN_NEXTBOT_Get_Closest_Of_The_Mesh( pos , direction , nextarea , LastVisPos , OtherArea )
	
	local CloseToGoal		=	nil
	local RangeToGoal		=	nil
	
	-- Simular to how to get the blue connection.We use the smallest area as its easier.
	local Smallest						=	self:ZEN_NEXTBOT_Get_Smallest_Area_Side( direction , nextarea )
	local ClosestCorner,CornerRange		=	nil
	--[[
	local Con,Ali			=	ZEN_NEXTBOT_Get_Blue_Connection( direction , self , nextarea )
	
	CloseToGoal				=	Con
	RangeToGoal				=	Con:DistToSqr( pos )
	]]
	ClosestCorner,CornerRange		=	Smallest:ZEN_NEXTBOT_Get_Nearest_Corner( pos )
	
	
	--if CornerRange < RangeToGoal then
		
		CloseToGoal		=	ClosestCorner
		RangeToGoal		=	CornerRange
		
	--end
	
	
	return CloseToGoal,RangeToGoal
end

-- Same as above but it has to check first!
function Zone:ZEN_NEXTBOT_Get_Closest_Of_The_Mesh_Ali( pos , direction , nextarea , LastVisPos , OtherArea )
	local OurZ				=	pos.z
	pos						=	nextarea:GetClosestPointOnArea( pos )
	pos						=	Vector( pos.x , pos.y , OurZ )
	
	local CloseToGoal		=	nil
	local RangeToGoal		=	nil
	
	-- Simular to how to get the blue connection.We use the smallest area as its easier.
	local Smallest						=	self:ZEN_NEXTBOT_Get_Smallest_Area_Side( direction , nextarea )
	local ClosestCorner,CornerRange		=	nil
	
	local Con,Ali			=	ZEN_NEXTBOT_Get_Blue_Connection( direction , self , nextarea )
	
	CloseToGoal				=	Con
	RangeToGoal				=	Con:DistToSqr( pos )
	
	ClosestCorner,CornerRange		=	Smallest:ZEN_NEXTBOT_Get_Nearest_Corner( pos )
	
	
	if CornerRange < RangeToGoal and ZEN_NEXTBOT_check_los( ClosestCorner , pos ) == true then
		
		CloseToGoal		=	ClosestCorner
		RangeToGoal		=	CornerRange
		
	end
	
	
	return CloseToGoal,RangeToGoal
end

function Lad:ZEN_NEXTBOT_Get_Closest_Point( pos )
	
	local TopArea	=	self:GetTop():Distance( pos )
	local LowArea	=	self:GetBottom():Distance( pos )
	
	if TopArea < LowArea then
		
		return self:GetTop()
	end
	
	return self:GetBottom()
end

-- Are the devs at gmod lazy? I mean come on, This function is insanely useful.
-- Its the easiest thing to write on earth.
function Player:ZEN_NEXTBOT_Is_On_Ladder()
	
	if self:GetMoveType() == MOVETYPE_LADDER then
		
		return true
	end
	
	return false
end


function Player:ZEN_NEXTBOT_Handle_Ladder_Climb_Settings( cmd )
	if !self:ZEN_NEXTBOT_Is_On_Ladder() then return end
	
	if isbool( self.ZEN_NEXTBOT_PATH[ #self.ZEN_NEXTBOT_PATH ][ "NodeIsLadder" ] ) then
		
		cmd:SetButtons( IN_JUMP )
		
		return
	end
	
	if self:GetPos().z < self.WayPointPosition.z then
		
		self:ZEN_NEXTBOT_Climb_Ladder_Up( cmd )
		
		return
	end
	
	if self:GetPos().z > self.WayPointPosition.z then
		
		self:ZEN_NEXTBOT_Climb_Ladder_Down( cmd )
		
		return
	end
	
end

function Player:ZEN_NEXTBOT_Climb_Ladder_Up( cmd )
	
	self:LookAt( self.WayPointPosition )
	
	cmd:SetButtons( IN_FORWARD )
	
end

function Player:ZEN_NEXTBOT_Climb_Ladder_Down( cmd )
	
	self:LookAt( self.WayPointPosition )
	
	cmd:SetButtons( IN_FORWARD )
	
end





-- ***************************************************************** --
-- *			Zenlenafelex's Player BOT PathFinder			   * --
-- ***************************************************************** --



-- As my main A* Is not the most optimized i will use the default functions gmod has for long distance pathfinding.
-- The only problem with mine is if it has to search the whole map for a impossible to reach node,It will take at least 2 seconds.

local ZEN_NEXTBOT_Node_Data		=	{}
local ZEN_NEXTBOT_Open_List		=	{}
ZEN_NEXTBOT_NODES_COMPUTED		=	0



-- Just like GetAdjacentAreas but a more advanced one.
-- For both ladders and CNavAreas.
function Zone:ZEN_NEXTBOT_Get_Connected_Areas()
	
	local AllNodes		=	self:GetAdjacentAreas()
	
	local AllLadders	=	self:GetLadders()
	
	for k, v in ipairs( AllLadders ) do
		
		AllNodes[ #AllNodes + 1 ]	=	v
		
	end
	
	return AllNodes
end

function Lad:ZEN_NEXTBOT_Get_Connected_Areas()
	
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




-- See if a node is an area : 1 or a ladder : 2
function Zone:ZEN_NEXTBOT_Node_Get_Type()
	
	return 1
end

function Lad:ZEN_NEXTBOT_Node_Get_Type()
	
	return 2
end





function Zone:ZEN_NEXTBOT_Get_F_Cost()
	
	
	return ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "FCost" ]
end

function Lad:ZEN_NEXTBOT_Get_F_Cost()
	
	
	return ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "FCost" ]
end






-- Store the F cost, And no only for optimization.We don't do G + H as doing that everytime will give the same answer.
function Zone:ZEN_NEXTBOT_Set_F_Cost( cost )
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "FCost" ]	=	cost
	
end

function Lad:ZEN_NEXTBOT_Set_F_Cost( cost )
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "FCost" ]	=	cost
	
end




function Zone:ZEN_NEXTBOT_Set_G_Cost( cost )
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "GCost" ]	=	cost
	
end

function Lad:ZEN_NEXTBOT_Set_G_Cost( cost )
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "GCost" ]	=	cost
	
end




function Zone:ZEN_NEXTBOT_Set_H_Cost( cost )
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "HCost" ]	=	cost
	
end

function Lad:ZEN_NEXTBOT_Set_H_Cost( cost )
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "HCost" ]	=	cost
	
end




function Zone:ZEN_NEXTBOT_Get_G_Cost( cost )
	
	return ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "GCost" ]
end

function Lad:ZEN_NEXTBOT_Get_G_Cost( cost )
	
	return ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "GCost" ]
end



function Zone:ZEN_NEXTBOT_Get_H_Cost( cost )
	
	return ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "HCost" ]
end

function Lad:ZEN_NEXTBOT_Get_H_Cost( cost )
	
	return ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "HCost" ]
end






function Zone:ZEN_NEXTBOT_Set_Parent_Node( SecondNode )
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "ParentNode" ]	=	SecondNode
	
end

function Lad:ZEN_NEXTBOT_Set_Parent_Node( SecondNode )
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "ParentNode" ]	=	SecondNode
	
end




function Zone:ZEN_NEXTBOT_Get_Parent_Node()
	
	return ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "ParentNode" ]
end

function Lad:ZEN_NEXTBOT_Get_Parent_Node()
	
	return ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "ParentNode" ]
end




-- Hmm, I think we need this for the reparenting.
function Zone:ZEN_NEXTBOT_Get_Current_Path_Length()
	
	
	return ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "PathLen" ]
end

function Lad:ZEN_NEXTBOT_Get_Current_Path_Length()
	
	
	return ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "PathLen" ]
end



function Zone:ZEN_NEXTBOT_Set_Current_Path_Length( cost )
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "PathLen" ]		=	cost
	
end

function Lad:ZEN_NEXTBOT_Set_Current_Path_Length( cost )
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "PathLen" ]		=	cost
	
end





-- Handles the G and H cost.
function Zone:ZEN_NEXTBOT_Calc_Range( SecondNode , Height )
	
	if SecondNode:ZEN_NEXTBOT_Node_Get_Type() == 1 then
		
		local TotalCost		=	0
		
		-- This will give slightly slower paths after searching 2000 nodes but it will help the computer speed up a bit.
		-- This is good for when A* is finding a path to an unreachable node.
		if ZEN_NEXTBOT_NODES_COMPUTED <= 1250 then
			
			TotalCost		=	self:GetClosestPointOnArea( SecondNode:GetCenter() ):Distance( SecondNode:GetCenter() )
			
		else
			
			TotalCost		=	self:GetCenter():Distance( SecondNode:GetCenter() )
			
		end
		
		-- Crouching and jumping is slow.
		if SecondNode:HasAttributes( NAV_MESH_JUMP ) then
			
			TotalCost	=	TotalCost * 5
			
		end
		
		if SecondNode:HasAttributes( NAV_MESH_CROUCH ) then
			
			TotalCost	=	TotalCost * 8
			
		end
		
		if isnumber( Height ) and Height > 15 then
			
			TotalCost	=	TotalCost * 4
			
		end
		--[[
		if SecondNode:GetSizeX() < 100 then
			
			TotalCost	=	TotalCost * 1.20
			
		end
		
		if SecondNode:GetSizeY() < 100 then
			
			TotalCost	=	TotalCost * 1.20
			
		end
		]]
		return TotalCost
	end
	
	return SecondNode:GetLength()
end

function Lad:ZEN_NEXTBOT_Calc_Range( SecondNode )
	
	
	return self:GetLength()
end




-- Checking if a node is closed or open without iliteration.
function Zone:ZEN_NEXTBOT_Node_Is_Closed()
	
	if ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "State" ] == false then return true end
	
	return false
end

function Lad:ZEN_NEXTBOT_Node_Is_Closed()
	
	if ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "State" ] == false then return true end
	
	return false
end


function Zone:ZEN_NEXTBOT_Node_Is_Open()
	
	if ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "State" ] == true then return true end
	
	return false
end

function Lad:ZEN_NEXTBOT_Node_Is_Open()
	
	if ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "State" ] == true then return true end
	
	return false
end




-- Remove from the open list.
-- How to advoid iliteration?
function Zone:ZEN_NEXTBOT_Node_Remove_From_Open_List()
	
	for k, v in ipairs( ZEN_NEXTBOT_Open_List ) do
		
		if v == self then
			
			table.remove( ZEN_NEXTBOT_Open_List , k )
			
			break
		end
		
	end
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

function Lad:ZEN_NEXTBOT_Node_Remove_From_Open_List()
	
	for k, v in ipairs( ZEN_NEXTBOT_Open_List ) do
		
		if v == self then
			
			table.remove( ZEN_NEXTBOT_Open_List , k )
			
			break
		end
		
	end
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end



-- Add a node to the list.
-- Fun fact! This would be the first time i have really added any optimization to the open list.
function Zone:ZEN_NEXTBOT_Node_Add_To_Open_List()
	
	local OurCost		=		self:ZEN_NEXTBOT_Get_F_Cost()
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	true
	
	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List + 1 ]			=	self
	
	ZEN_NEXTBOT_Sort_Open_List()
	
end

function Lad:ZEN_NEXTBOT_Node_Add_To_Open_List()
	
	local OurCost		=		self:ZEN_NEXTBOT_Get_F_Cost()
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	true
	
	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List + 1 ]			=	self
	
	ZEN_NEXTBOT_Sort_Open_List()
	
end







function Zone:ZEN_NEXTBOT_Node_Remove_From_Closed_List()
	
	ZEN_NEXTBOT_Node_Data[ 1 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end

function Lad:ZEN_NEXTBOT_Node_Remove_From_Closed_List()
	
	ZEN_NEXTBOT_Node_Data[ 2 ][ self:GetID() ][ "State" ]	=	"Unset"
	
end




-- Gives us the best node and removes it from the open list and puts it in the closed list.
function ZEN_NEXTBOT_Get_Best_Node()
	
	local BestNode		=	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]
	
	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]		=	nil
	
	ZEN_NEXTBOT_Node_Data[ BestNode:ZEN_NEXTBOT_Node_Get_Type() ][ BestNode:GetID() ][ "State" ]	=	false
	
	return BestNode
end



-- Hmm, Have i found a TOP SECRET way to do this?
-- It seems i don't even need a binary heap in the slightest.
-- As we add nodes we sort them.
-- Its alright for the nodes 5 keys or so below us as they can be messy as they like.
-- Because the moment we get to those nodes.It will sort them again.
-- So rather than having to iliterate through the entire open list.
-- All we are doing is iliterating through 5 or so nodes.Each time we add a node to the open list.
-- So for example.
-- If i add 3 nodes it will iliterate 15 times.
-- But if i had a 100 nodes already in the list it will have to iliterate 100 times just to find the node with the lowest F cost.
-- I would rather iliterate 15 times for 3 nodes rather than 300 times if the open list had 100 nodes.

-- ( TEST 1 Results )
-- Without my method here. It would lag for about 15 ms and searched 500 nodes.

-- ( TEST 2 Results )
-- With my method here.It would lag for about 13 ms and beable to search 1700 nodes.

-- So as you can see we have greatly improved the optimization.

-- ( EXPERIMENT 1 )
-- Now, Hmmm,What could be causing the other lag? The mass amount of iliterating to sort the list? Or maybe its calcuations.Lets knock out the calcuations to see what we get.

-- ( EXPERIMENT 1 Results )
-- Nope, It was the ReParenting.
-- It was ReParenting when it does not need to.
-- For example. The map had 481 nodes, and it searched 4715 nodes.
-- Now i have fixed it its searched 481 nodes.


function ZEN_NEXTBOT_Sort_Open_List()
	
	local SortedList	=	{}
	local HasDoneLoop	=	false
	
	local UnsortedList	=	{}
	
	-- List all the nodes in the table.
	UnsortedList[ 1 ]	=	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]
	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]			=	nil
	
	if IsValid( ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ] ) then
		
		UnsortedList[ 2 ]	=	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]
		ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]		=	nil
		
	end
	
	if IsValid( ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ] ) then
		
		UnsortedList[ 3 ]	=	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]
		ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]		=	nil
		
	end
	--[[
	if IsValid( ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ] ) then
		
		UnsortedList[ 4 ]	=	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]
		ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]				=	nil
		
	end
	
	if IsValid( ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ] ) then
		
		UnsortedList[ 5 ]	=	ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]
		ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List ]				=	nil
		
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
			
			if v:ZEN_NEXTBOT_Get_F_Cost() > y:ZEN_NEXTBOT_Get_F_Cost() then
				
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
		
		ZEN_NEXTBOT_Open_List[ #ZEN_NEXTBOT_Open_List + 1 ]		=	v
		
	end
	
end


-- Prepare everything for a new path find.
function ZEN_NEXTBOT_Prepare_Path_Find()
	
	ZEN_NEXTBOT_Node_Data	=	{ {} , {} }
	ZEN_NEXTBOT_Open_List	=	{}
	
	for k, v in ipairs( navmesh.GetAllNavAreas() ) do
		
		local Lads	=	v:GetLadders()
		
		if istable( Lads ) then
			
			for j, y in ipairs( Lads ) do
				
				ZEN_NEXTBOT_Node_Data[ 2 ][ y:GetID() ]		=	{
					
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
		
		ZEN_NEXTBOT_Node_Data[ 1 ][ v:GetID() ]		=	{
			
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

function ZEN_NEXTBOT_Compute_Path( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if ( StartNode == GoalNode ) then return true end
	
	ZEN_NEXTBOT_Prepare_Path_Find()
	
	StartNode:ZEN_NEXTBOT_Node_Add_To_Open_List()
	ZEN_NEXTBOT_NODES_COMPUTED	=	0

	while ( !table.IsEmpty( ZEN_NEXTBOT_Open_List ) and ZEN_NEXTBOT_NODES_COMPUTED < 5000 ) do
		ZEN_NEXTBOT_NODES_COMPUTED	=	ZEN_NEXTBOT_NODES_COMPUTED + 1
		
		local CurrentNode	=	ZEN_NEXTBOT_Get_Best_Node()
		
		
		if ( CurrentNode == GoalNode ) then
			
			return ZEN_NEXTBOT_Trace_Back_Path( StartNode , GoalNode )
		end
		
		
		for k, Neighbor in ipairs( CurrentNode:ZEN_NEXTBOT_Get_Connected_Areas() ) do
			local NewCostSoFar		=	0
			-- Optimization, Prevent computing the height twice.
			local Height			=	0
			local CurrentToNeigh	=	0
			
			
			if Neighbor:ZEN_NEXTBOT_Node_Get_Type() == 1 and CurrentNode:ZEN_NEXTBOT_Node_Get_Type() == 1 then
				
				if Neighbor:HasAttributes( NAV_MESH_TRANSIENT ) then
					
					local tr				=	util.TraceLine({
						
						start				=	Neighbor:GetCenter(),
						endpos				=	Neighbor:GetCenter() + Vector( 0 , 0 , -20 ),
						mask				=	MASK_SOLID,
						collisiongroup		=	COLLISION_GROUP_DEBRIS
						
					})
					
					if !tr.Hit then
						
						-- Looks like part of the map has collapsed, Like a bridge that breaks for example.
						continue
						
					end
					
				end
				
				Height			=	CurrentNode:ComputeAdjacentConnectionHeightChange( Neighbor )
				
				CurrentToNeigh	=	CurrentNode:ZEN_NEXTBOT_Calc_Range( Neighbor , Height )
				
				NewCostSoFar	=	CurrentNode:ZEN_NEXTBOT_Get_G_Cost() + CurrentToNeigh
				
				if CurrentNode:GetCenter().z + 8 < Neighbor:GetCenter().z then
					
					if Height > 64 then
						-- We can not jump that high.
						continue
						
					end
					
				end
				
			else
				
				CurrentToNeigh	=	CurrentNode:ZEN_NEXTBOT_Calc_Range( Neighbor )
				
				NewCostSoFar	=	CurrentNode:ZEN_NEXTBOT_Get_G_Cost() + CurrentToNeigh
				
			end
			
			
			
			if Neighbor:ZEN_NEXTBOT_Node_Is_Open() or Neighbor:ZEN_NEXTBOT_Node_Is_Closed() and CurrentNode:ZEN_NEXTBOT_Get_G_Cost() <= NewCostSoFar then
				
				continue
				
			else
				Neighbor:ZEN_NEXTBOT_Set_G_Cost( NewCostSoFar )
				Neighbor:ZEN_NEXTBOT_Set_F_Cost( NewCostSoFar + Neighbor:ZEN_NEXTBOT_Calc_Range( GoalNode ) )
				
				if Neighbor:ZEN_NEXTBOT_Node_Is_Closed() then
					
					Neighbor:ZEN_NEXTBOT_Node_Remove_From_Closed_List()
					
				end
				
				Neighbor:ZEN_NEXTBOT_Node_Add_To_Open_List()
				
				Neighbor:ZEN_NEXTBOT_Set_Parent_Node( CurrentNode )
				
			end
			
			
		end
		
	end
	
	return false
end


function ZEN_NEXTBOT_Trace_Back_Path( StartNode , GoalNode )
	
	local Final_Path	=	{ GoalNode }
	
	local CurrentNode	=	GoalNode
	
	local TraceAttempts	=	0
	
	while ( CurrentNode != StartNode and TraceAttempts < 5001 ) do
		
		TraceAttempts	=	TraceAttempts + 1
		
		CurrentNode		=	CurrentNode:ZEN_NEXTBOT_Get_Parent_Node()
		
		if CurrentNode:ZEN_NEXTBOT_Node_Get_Type() == 1 then
			
			table.insert( Final_Path , navmesh.GetNavAreaByID( CurrentNode:GetID() ) )
			
		else
			
			table.insert( Final_Path , navmesh.GetNavLadderByID( CurrentNode:GetID() ) )
			
		end
		
	end
	
	return Final_Path
end



-- This is the secondary A* Its used for long distance pathfinding as its quicker.
-- Its also the most accurate and stable.
-- However. It has just one problem.
-- It can not use ladders.

-- \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ --
function ZEN_NEXTBOT_compute_path_speedy( StartNode , GoalNode )
	if !IsValid( StartNode ) or !IsValid( GoalNode ) then return false end
	if StartNode == GoalNode then return true end
	
	StartNode:ClearSearchLists()
	
	StartNode:AddToOpenList()
	
	StartNode:SetCostSoFar( 0 )
	
	StartNode:SetTotalCost( ZEN_NEXTBOT_check_node_G_cost_speedy( StartNode , GoalNode ) )
	
	StartNode:UpdateOnOpenList()
	
	local Final_Path		=	{}
	local Trys				=	0 -- Backup! Prevent crashing.
	
	local GoalCen			=	GoalNode:GetCenter()
	
	while ( !StartNode:IsOpenListEmpty() and Trys < 50000 ) do
		Trys	=	Trys + 1
		
		local Current	=	StartNode:PopOpenList()
		
		if Current == GoalNode then
			
			return ZEN_NEXTBOT_BOT_trace_final_path_speedy( Final_Path , Current )
		end
		
		Current:AddToClosedList()
		
		for k, neighbor in ipairs( Current:GetAdjacentAreas() ) do
			local Height	=	Current:ComputeAdjacentConnectionHeightChange( neighbor ) 
			-- Optimization,Prevent computing the height twice.
			
			local NewCostSoFar		=	Current:GetCostSoFar() + ZEN_NEXTBOT_check_node_G_cost_speedy( Current , neighbor , Height )
			
			
			if Height > 64 and Current:GetCenter().z + 3 < neighbor:GetCenter().z and !Current:HasAttributes( NAV_MESH_TRANSIENT ) then
				
				-- No way we can jump that high unless we are told by navmesh_transistant that
				-- we can actuly make that jump.
				-- For example i used it on an__fan_fight to tell bots they can exit the dimention through a portal.
				
				continue
			end
			
			if neighbor:HasAttributes( NAV_MESH_TRANSIENT ) then
				
				local tr				=	util.TraceLine({
					
					start				=	neighbor:GetCenter(),
					endpos				=	neighbor:GetCenter() + Vector( 0 , 0 , -20 ),
					mask				=	MASK_SOLID,
					collisiongroup		=	COLLISION_GROUP_DEBRIS
					
				})
				
				if !tr.Hit then
					
					-- Looks like part of the map has collapsed, Like a bridge that breaks for example.
					continue
					
				end
				
			end
			
			
			if neighbor:IsOpen() or neighbor:IsClosed() and neighbor:GetCostSoFar() <= NewCostSoFar then
				
				continue
				
			else
				
				neighbor:SetCostSoFar( NewCostSoFar )
				neighbor:SetTotalCost( NewCostSoFar + ZEN_NEXTBOT_check_node_G_cost_speedy( neighbor , GoalNode ) )
				
				if neighbor:IsClosed() then
					
					neighbor:RemoveFromClosedList()
					
				end
				
				if neighbor:IsOpen() then
					
					neighbor:UpdateOnOpenList()
					
				else
					
					neighbor:AddToOpenList()
					
				end
				
				
				Final_Path[ neighbor:GetID() ]	=	Current:GetID()
			end
			
			
		end
		
		
	end
	
	
	return false
end


function ZEN_NEXTBOT_check_node_G_cost_speedy( FirstNode , SecondNode , Height )
	
	--local DefaultCost	=	( CurrentCen - NeighborCen ):Length()
	local DefaultCost	=	FirstNode:GetCenter():Distance( SecondNode:GetCenter() )
	
	if isnumber( Height ) and Height > 32 then
		
		DefaultCost		=	DefaultCost * 5
		
		-- Jumping is slower than ground movement.
		-- And falling is risky taking fall damage.
		
		
	end
	
	-- Jump nodes however,We find slightly easier to jump with.Its more recommended than jumping without them.
	if SecondNode:HasAttributes( NAV_MESH_JUMP ) then 
		
		DefaultCost	=	DefaultCost * 3.50
		
	end
	
	
	-- Crawling through a vent is very slow.
	if SecondNode:HasAttributes( NAV_MESH_CROUCH ) then 
		
		DefaultCost	=	DefaultCost * 7
		
	end
	
	-- We are less interested in smaller nodes as it can make less realistic paths.
	-- Also its easy to get stuck on them.
	if SecondNode:GetSizeY() <= 50 then
		
		DefaultCost		=	DefaultCost * 3
		
	end
	
	if SecondNode:GetSizeX() <= 50 then
		
		DefaultCost		=	DefaultCost * 3
		
	end
	
	
	return DefaultCost
end


function ZEN_NEXTBOT_BOT_trace_final_path_speedy( Final_Path , Current )
	
	local NewPath	=	{ Current }
	
	Current			=	Current:GetID()
	
	while( Final_Path[ Current ] ) do
		
		Current		=	Final_Path[ Current ]
		table.insert( NewPath , navmesh.GetNavAreaByID( Current ) )
		
	end
	
	return NewPath
end

-- \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ --

































































