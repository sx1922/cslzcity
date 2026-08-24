zb = zb or {}
hg = hg or {}
zb.ROUND_STATE = zb.ROUND_STATE or 0
--0 = players can join, 1 = round is active, 2 = endround

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("loader.lua")
include("loader.lua")

local PLAYER = FindMetaTable("Player")
function PLAYER:CanSpawn()
	return ( CurrentRound and CurrentRound() and CurrentRound().CanSpawn and CurrentRound():CanSpawn(self)) or (zb.ROUND_STATE == 0)
end

util.AddNetworkString("ZB_SpectatePlayer")

function PLAYER:GiveEquipment(team_)
end

local default_spawns = {
	"info_player_deathmatch", "info_player_combine", "info_player_rebel",
	"info_player_counterterrorist", "info_player_terrorist", "info_player_axis",
	"info_player_allies", "gmod_player_start", "info_player_teamspawn",
	"ins_spawnpoint", "aoc_spawnpoint", "dys_spawn_point", "info_player_pirate",
	"info_player_viking", "info_player_knight", "diprip_start_team_blue", "diprip_start_team_red",
	"info_player_red", "info_player_blue", "info_player_coop", "info_player_human", "info_player_zombie",
	"info_player_zombiemaster", "info_player_fof", "info_player_desperado", "info_player_vigilante", "info_survivor_rescue"
}

local vecup = Vector(0, 0, 64)

local spawners = {}

local function getRandSpawn()
	spawners = {}

	if #zb.GetMapPoints( "Spawnpoint" ) > 0 then
		for k, v in RandomPairs(zb.GetMapPoints( "Spawnpoint" )) do
			spawners[#spawners + 1] = v.pos
		end
	else
		for i, ent in RandomPairs(ents.FindByClass("info_player_start")) do
			spawners[#spawners + 1] = ent:GetPos()
		end
		
		for i, str in ipairs(default_spawns) do
			for k, v in RandomPairs(ents.FindByClass(str)) do
				spawners[#spawners + 1] = v:GetPos()
			end
		end

		--[[for k, v in ipairs(navmesh.GetAllNavAreas()) do
			local Randompos = v:GetCenter()
			local SpawnPos = Randompos + vecup

			spawners[#spawners + 1] = SpawnPos
		end--]]
	end
end

getRandSpawn()

hook.Add("InitPostEntity", "OwOmooooove", function()
	getRandSpawn()
end)

hook.Add("ZB_PreRoundStart", "reset_spawns", function()
	zb.ctspawn = nil
	zb.tspawn = nil
end)

function zb:GetTeamSpawn(ply)
	local team_ = ply:Team()

	local team0spawns, team1spawns = CurrentRound():GetTeamSpawn()
	
	if !team0spawns or !next(team0spawns) then
		team0spawns = {zb:GetRandomSpawn()}
	end

	if !team1spawns or !next(team1spawns) then
		team1spawns = {zb:GetRandomSpawn()}
	end

	local pos
	
	if team_ == 0 then
		if !zb.tspawn then
			zb.tspawn = table.Random(team0spawns)
			pos = zb.tspawn
		else
			pos = hg.tpPlayer(zb.tspawn, ply, math.Clamp(ply:EntIndex() % 24 + 1, 1, 24), 0)
		end

		return pos
	else
		if !zb.ctspawn then
			zb.ctspawn = table.Random(team1spawns)
			pos = zb.ctspawn
		else
			pos = hg.tpPlayer(zb.ctspawn, ply, math.Clamp(ply:EntIndex() % 24 + 1, 1, 24), 0)
		end

		return pos
	end

	ErrorNoHalt("TEAM SPAWN COULDN'T BE FOUND. INVALID TEAM")

	return team0spawns[1]
end

local check_playerspawns = function(SpawnPos, ply, tolerance)
	if !ply:Alive() then return true end
	
	local usedPos = ply:GetPos()

	local checkdist = (1024 / (math.pow(2, tolerance)))
	if usedPos:DistToSqr(SpawnPos) < checkdist * checkdist then
		return false
	end
	
	return true
end

function zb:GetRandomSpawn(target, spawns)
	if !spawns or table.IsEmpty(spawns) then
		spawns = spawners
	end
	
	return zb:FurthestFromEveryone(spawns, player.GetAll(), check_playerspawns)
end

function zb:FurthestFromEveryone(chooseTbl, restrictTbl, func, iStart, iEnd)
	if not chooseTbl or table.IsEmpty(chooseTbl) then
		chooseTbl = spawners
	end

	if not restrictTbl then
		restrictTbl = player.GetAll()

		func = check_playerspawns
	end
	
	for tolerance = (iStart or 1), (iEnd or 5) do
		for i, SpawnPos in RandomPairs(chooseTbl) do
			if not SpawnPos then continue end
			
			local allow

			for _, value in ipairs(restrictTbl) do
				allow = func(SpawnPos, value, tolerance)
				if allow == false then break end
			end
			
			if allow then
				return SpawnPos
			end
		end
	end
	
	local SpawnPos = table.Random(chooseTbl)
	
	return SpawnPos
end

function PLAYER:GetRandomSpawn()
	local spawnPos = zb:GetRandomSpawn(self)
	
	if not spawnPos then return end
	
	self:SetPos(spawnPos)
end

function GM:PlayerSelectSpawn(ply, transition)
end

local function PlayerSelectSpawn(ply, transition)
	if CurrentRound().randomSpawns then
		local randSpawn = zb:GetRandomSpawn()
		ply:SetPos(randSpawn)

		return
	end

	local spawnPos = zb:GetTeamSpawn(ply)

	if not spawnPos then
		local randSpawn = zb:GetRandomSpawn()
		ply:SetPos(randSpawn)
	else
		ply:SetPos(spawnPos)
	end
end

function PLAYER:SetupTeam(team_)
	self:SetTeam(team_)
	
	hg.CreateInv(self)
	-- Normal GM:PlayerSpawn does not emit the custom "Player Spawn" event
	-- used by the inventory addon. Initialize armor state here so mode
	-- loadouts can safely call hg.AddArmor immediately after SetupTeam.
	self.armors = self:GetNetVar("Armor", {}) or {}
	self.armors_health = self.armors_health or {}
	if self.SyncArmor then self:SyncArmor() end

	PlayerSelectSpawn(self)
end

function GM:PlayerSpawn(ply)
    ply:SuppressHint("OpeningMenu")
    ply:SuppressHint("Annoy1")
    ply:SuppressHint("Annoy2")

    -- Engine respawn wipes every weapon and this gamemode never runs the
    -- standard PlayerLoadout flow, so any spawn outside a mode's equip window
    -- would leave the player completely empty-handed. Always guarantee the
    -- fists weapon before any early return below (fake-ragdoll recovery etc).
    if SERVER and IsValid(ply) and not ply:HasWeapon("weapon_hands_sh") then
        ply:Give("weapon_hands_sh")
    end

    -- OverrideSpawn is a short-lived guard used by fake-ragdoll recovery. If
    -- an exception interrupted recovery, do not let the stale global flag
    -- permanently disable every later player spawn.
    if OverrideSpawn then
        if OverrideSpawnAt and CurTime() - OverrideSpawnAt > 5 then
            OverrideSpawn = nil
            OverrideSpawnAt = nil
        else
            return
        end
    end

    ply.viewmode = 3
    ply:UnSpectate()
    ply:SetMoveType(MOVETYPE_WALK)

	-- PlayerSpawn is the native lifecycle hook; the inventory addon also has a
	-- custom "Player Spawn" hook, which is not guaranteed to run for a plain
	-- ply:Spawn().  Initialize both states here so armor grants from any mode
	-- are safe even during police/respawn paths.
	if hg and hg.CreateInv then pcall(hg.CreateInv, ply) end
	ply.armors = ply:GetNetVar("Armor", {}) or {}
	ply.armors_health = {}
	if ply.SyncArmor then pcall(ply.SyncArmor, ply) end

    if ply.initialspawn then
        ply:KillSilent()
        ply:SetTeam(1001)
        ply.initialspawn = nil
        return
    end

    if CurrentRound() and not CurrentRound().OverrideSpawn then
        ply:SetTeam(1001)
        ApplyAppearance(ply,nil,nil,nil,true)
        ply:SetTeam(zb:BalancedChoice(0, 1))
    end

end

function GM:PlayerDisconnected(ply)
	local mode = CurrentRound()
	if mode and mode.PlayerDisconnected then
		mode:PlayerDisconnected(ply)
	end
end

RunConsoleCommand("mp_show_voice_icons", "0")

local hullscale = Vector(1, 1, 1)

util.AddNetworkString("ZB_ChooseSpecPly")

net.Receive("ZB_ChooseSpecPly",function(len,ply)
	if ply:Alive() then return end
	
	local key = net.ReadInt(32)
	local tbl = zb:CheckAlive()
	
	if #tbl == 0 then return end
	
	ply.chosenspect = ply.chosenspect and isnumber(ply.chosenspect) and ply.chosenspect or 1
	ply.viewmode = ply.viewmode or 1
	
	ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
	
	if key == IN_ATTACK then
		ply.chosenspect = ply.chosenspect + 1
		if ply.chosenspect > #tbl then ply.chosenspect = 1 end
		
		net.Start("ZB_SpectatePlayer")
		net.WriteEntity(tbl[ply.chosenspect] or NULL)
		net.WriteEntity(tbl[ply.chosenspect == 1 and #tbl or ply.chosenspect - 1] or NULL)
		net.WriteInt(ply.viewmode, 4)
		net.Send(ply)
	end

	if key == IN_ATTACK2 then
		ply.chosenspect = ply.chosenspect - 1
		if ply.chosenspect < 1 then ply.chosenspect = #tbl end
		
		net.Start("ZB_SpectatePlayer")
		net.WriteEntity(tbl[ply.chosenspect] or NULL)
		net.WriteEntity(tbl[ply.chosenspect == #tbl and 1 or ply.chosenspect + 1] or NULL)
		net.WriteInt(ply.viewmode, 4)
		net.Send(ply)
	end

	if key == IN_RELOAD then
		ply.viewmode = (ply.viewmode % 3) + 1  
		
		net.Start("ZB_SpectatePlayer")
		net.WriteEntity(tbl[ply.chosenspect] or NULL)
		net.WriteEntity(tbl[ply.chosenspect == 1 and #tbl or ply.chosenspect - 1] or NULL)
		net.WriteInt(ply.viewmode, 4)
		net.Send(ply)
	end
	
	ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
	ply.chosenSpectEntity = tbl[ply.chosenspect]
	
	if ply.lastSpectTarget ~= ply.chosenSpectEntity then
		ply.lastSpectTarget = ply.chosenSpectEntity
	end
end)

hook.Add("SetupPlayerVisibility", "spectPVS", function(ply, viewent)
	if ply:Alive() then return end

	local entity = ply.chosenSpectEntity

	if IsValid(entity) and !entity:TestPVS(ply) then
		AddOriginToPVS(entity:GetPos())
	end
end)

hook.Add("PlayerDeathThink", "spectNetwork", function(ply)
	if ply:Alive() then return end
	//ply:Spectate(OBS_MODE_ROAMING)

	local ent = ply.chosenSpectEntity or player.GetAll()[1]
	if IsValid(ply) then
		ply:SetNWEntity("spect", ent)
		ply:SetNWInt("viewmode", ply.viewmode or 1)
		if IsValid(ent) then
			if ent.organism and ply.viewmode == 1 then
				if (ply.netsendtime or 0) < CurTime() then
					ply.netsendtime = CurTime() + 1

					hg.send_organism(ent.organism, ply)
				end
			end
			local entr = hg.GetCurrentCharacter(ent)
			local pos = ent:GetPos()
			
			if ply.viewmode ~= 3 then
				local currentPos = ply:GetPos()
				local targetPos = pos
				local distance = currentPos:Distance(targetPos)
				
				if distance > 100 or ply.lastSpectTarget ~= ent then
					ply:SetPos(targetPos)
					ply.lastSpectTarget = ent
				end
			end
			--print(ply:GetPos())
		end
		
		if ply.viewmode == 3 then
			if ply:GetMoveType() ~= MOVETYPE_NOCLIP then
				ply:SetMoveType(MOVETYPE_NOCLIP)
			end
			if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
				ply:Spectate(OBS_MODE_ROAMING)
			end
		else
			if ply:GetMoveType() == MOVETYPE_NOCLIP then
				ply:SetMoveType(MOVETYPE_WALK)
			end
		end
	end
end)

function GM:PlayerDeathThink(ply)
	if not ply:CanSpawn() then return false end
end

function GM:PlayerDeath(ply, inflictor, attacker)
	ply.lastSpectTarget = nil
	ply.chosenSpectEntity = nil
	
	ply:Spectate(OBS_MODE_ROAMING)
	ply:SetHull(-hullscale,hullscale)
	ply:SetHullDuck(-hullscale,hullscale)
	

	ply.chosenspect = ply:EntIndex()
	ply.viewmode = 1 
	
	timer.Simple(0.1, function()
		if IsValid(ply) and not ply:Alive() then
			local alivePlayers = zb:CheckAlive()
			if #alivePlayers > 0 then
				ply.chosenSpectEntity = alivePlayers[1]
				ply.chosenspect = 1
			end
		end
	end)

	local mode = CurrentRound()
	if mode and mode.PlayerDeath then
		mode:PlayerDeath(ply, inflictor, attacker)
	end
end

hg.addbot = hg.addbot or false

function GM:PlayerInitialSpawn(ply)
	ply.initialspawn = true

	if #player.GetAll() == 1 then
		RunConsoleCommand("bot")
		hg.addbot = true
		-- 不再强制结束回合：首个玩家/机器人进服时 zb:EndRound() 会打断正常回合循环，
		-- 造成每次换图后第一局被“自动结束”。低人数由 PreRound 的人数门槛自行处理。
	end

	if #player.GetHumans() > 1 and hg.addbot then
		for i,bot in pairs(player.GetListByName("bot")) do
			RunConsoleCommand("kick",bot:Name())
		end
		hg.addbot = false
	end

	local mode = CurrentRound()
	if mode and mode.PlayerInitialSpawn then
		mode:PlayerInitialSpawn(ply)
	end
end

-- 引擎菜单按键转发给当前模式：F1=帮助 F2=队伍 F3=商店(tdm购买菜单) F4=备用
-- 用 hook 而非 GM 方法，防止其他插件覆盖 GAMEMODE.ShowSpareX 后商店再次失效
local spareForwards = { "ShowHelp", "ShowTeam", "ShowSpare1", "ShowSpare2" }
for _, fname in ipairs(spareForwards) do
	hook.Add(fname, "ZC_ForwardToMode_" .. fname, function(ply)
		local m = CurrentRound()
		if m and m[fname] then return m[fname](m, ply) end
	end)
end

function GM:IsSpawnpointSuitable( pl, spawnpointent, bMakeSuitable )
	return true
end

util.AddNetworkString("ZB_SpecMode")
net.Receive("ZB_SpecMode",function(len,ply)
	local bool = net.ReadBool()

	local enable = !hook.Run("ZB_JoinSpectators", ply)

	if enable and bool and ply:Team() != TEAM_SPECTATOR then if ply:Alive() then ply:Kill() end ply:SetTeam(TEAM_SPECTATOR) PrintMessage(HUD_PRINTTALK,ply:Name().." 加入了观战。") 
	elseif ply:Team() != 1 then
		ply:SetTeam(1) PrintMessage(HUD_PRINTTALK,ply:Name().." 加入了游戏。")  
	end
end)

--[[
local tbl = {}
local maps = file.Find( "maps/*.bsp", "GAME" )

for _, map in ipairs( maps ) do
	map = map:sub( 1, -5 )
	table.insert( tbl, map )
end

for i, map in ipairs(ents.FindByClass("coop_mapend")) do
	if table.HasValue(tbl, map.map) then
		print(map.map)
	end
end
--]]

util.AddNetworkString("updtime")

function hg.UpdateRoundTime(time, time2, time3)
	zb.ROUND_TIME = time or zb.ROUND_TIME
	zb.ROUND_START = time2 or zb.ROUND_START or CurTime()
	zb.ROUND_BEGIN = time3 or zb.ROUND_BEGIN or CurTime() + 5
	net.Start("updtime")
	net.WriteFloat(zb.ROUND_TIME)
	net.WriteFloat(zb.ROUND_START)
	net.WriteFloat(zb.ROUND_BEGIN)
	net.Broadcast()
end

local function getspawnpos()
    local tab = {}
    local tbl = ents.FindByClass("info_player_start")
    for k, v in pairs(tbl) do
        if not v:HasSpawnFlags(1) then continue end
        tab[#tab + 1] = v:GetPos()
    end
    return tab[1] or tbl[1]:GetPos()
end

local maps = {}

hook.Add("PostCleanupMap","changelevel_generate",function()
	if CurrentRound().name != "coop" then return end
	local player_pos = getspawnpos()
    local dist = 0
    local map
    
    local maps = {}
    for i, map in pairs(ents.FindByClass("trigger_changelevel")) do
        local min, max = map:WorldSpaceAABB()
        local tdmlPos = max - ((max - min) / 2)

        maps[map] = tdmlPos
    end
    
    for ent, pos in pairs(maps) do
		if ent.map == game.GetMap() then continue end
        local dist2 = pos:Distance(player_pos)
        --print(dist,dist2,ent.map,pos,player_pos)
        if dist2 > dist then
            dist = dist2
            map = ent
        end
    end--выбираем самый дальний ченджлевел

    if not IsValid(map) then map = select(2, table.Random(maps)) end
    
    print("Next map is: "..map.map)

    local min, max = map:WorldSpaceAABB()
    local tdmlPos = max - ((max - min) / 2)
    local tdml = ents.Create("coop_mapend")
    tdml:SetPos(tdmlPos)
	tdml:SetAngles(map:GetAngles())
    tdml.min = min
    tdml.max = max
    tdml.map = map.map
    tdml:Spawn()
    tdml:Activate()
	--map:Remove()
end)

function GM:EntityKeyValue( ent, key, value )

	if ( ( ent:GetClass() == "trigger_changelevel" ) && ( key == "map" ) ) then
		ent.map = value
		ent:AddEFlags(2)
		ent:AddFlags(2)
		--[[
		maps[ent] = true
		
		timer.Create("fuckmapchanges",4,1,function()
			local random_player = table.Random(player.GetAll())
			if not IsValid(random_player) then return end
			local player_pos = random_player:GetPos()
			local dist = 0
			local map
			
			for ent, i in pairs(maps) do
				--print(ent.map,i)
				local dist2 = ent:GetPos():Distance(player_pos)
				if dist2 > dist then
					dist = dist2
					map = ent
				end
			end--выбираем самый дальний ченджлевел
			print("Next map is: "..map.map)
			if not map then map = maps[1] end

			local min, max = map:WorldSpaceAABB()
			tdmlPos = max - ((max - min) / 2)
			local tdml = ents.Create("coop_mapend")
			tdml:SetPos(tdmlPos)
			tdml.min = min
			tdml.max = max
			tdml.map = map.map
			tdml:Spawn()
			tdml:Activate()

			maps = {}
		end)--]]
	end

	if ( ent:GetClass() == "npc_combine_s" ) then
		ent:SetLagCompensated(true)
	end

	if ( ( ent:GetClass() == "npc_combine_s" ) && ( key == "additionalequipment" ) && ( value == "weapon_shotgun" ) ) then
	
		ent:SetSkin( 1 )
	
	end

end

hook.Add("CanProperty", "AntiExploit", function(ply, property, ent)
	if(!ply:IsAdmin())then
		return false
	end
end)
