local MODE = MODE

util.AddNetworkString("ng_phase")
util.AddNetworkString("ng_roundend")
util.AddNetworkString("ng_supply_drop")
util.AddNetworkString("ng_checkpoint")
util.AddNetworkString("ng_martial_law")
util.AddNetworkString("ng_curfew")
util.AddNetworkString("ng_arrest")
util.AddNetworkString("ng_commander_order")
util.AddNetworkString("ng_riot_level")
util.AddNetworkString("ng_role")

-- Mode equipment contains optional weapon/armor classes.  Protect each item
-- independently so one missing addon cannot cancel the whole role loadout.
local function SafeGive(ply, class)
	if not IsValid(ply) or not isstring(class) or class == "" then return NULL end
	local ok, weapon = pcall(ply.Give, ply, class)
	if not ok then
		ErrorNoHalt("[nationalguard] Give failed for " .. tostring(class) .. ": " .. tostring(weapon) .. "\n")
		return NULL
	end
	return weapon or NULL
end

local function SafeAmmo(ply, amount, ammoType)
	if not IsValid(ply) or not isnumber(amount) or not isnumber(ammoType) or ammoType < 0 then return end
	pcall(ply.GiveAmmo, ply, math.max(math.floor(amount), 0), ammoType, true)
end

local function SafeArmor(ply, armor)
	if not IsValid(ply) or not hg or not hg.AddArmor or armor == nil then return false end
	local ok, result = pcall(hg.AddArmor, ply, armor)
	if not ok then
		ErrorNoHalt("[nationalguard] armor failed for " .. ply:Nick() .. ": " .. tostring(result) .. "\n")
		return false
	end
	return result ~= false
end

local function SyncInventory(ply)
	if not IsValid(ply) then return end
	timer.Simple(0.15, function()
		if not IsValid(ply) then return end
		pcall(function()
			if hg.CreateInv then hg.CreateInv(ply) end
			local inv = ply:GetNetVar("Inventory", {}) or {}
			inv.Weapons = inv.Weapons or {}
			inv.Weapons["hg_sling"] = true
			inv.Weapons["hg_flashlight"] = true
			ply:SetNetVar("Inventory", inv)
		end)
	end)
end

local function SafeVecs(group)
	local pts = zb.GetMapPoints(group)
	if not pts then return {} end
	return zb.TranslatePointsToVectors(pts)
end

local function PickGuardSpawn()
	local vecs = SafeVecs("NG_GUARD_SPAWN")
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_CT") end
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_T") end
	if #vecs == 0 then vecs = {zb:GetRandomSpawn()} end
	return vecs[math.random(#vecs)]
end

local function PickRioterSpawn()
	local vecs = SafeVecs("NG_RIOTER_SPAWN")
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_T") end
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_CT") end
	if #vecs == 0 then vecs = {zb:GetRandomSpawn()} end
	return vecs[math.random(#vecs)]
end

local function GiveLoadout(ply, loadout)
	if not IsValid(ply) or not istable(loadout) or not isstring(loadout.primary) then
		return false
	end

	SafeGive(ply, "weapon_hands_sh")

	local gun = SafeGive(ply, loadout.primary)
	if IsValid(gun) then
		SafeAmmo(ply, gun:GetMaxClip1() * (loadout.ammo or 0), gun:GetPrimaryAmmoType())
		pcall(ply.SelectWeapon, ply, gun:GetClass())
	end

	if loadout.secondary then
		local pistol = SafeGive(ply, loadout.secondary)
		if IsValid(pistol) then
			SafeAmmo(ply, pistol:GetMaxClip1() * (loadout.ammo2 or 2), pistol:GetPrimaryAmmoType())
		end
	end

	if loadout.armor then SafeArmor(ply, loadout.armor) end
	if isstring(loadout.melee) then SafeGive(ply, loadout.melee) end

	for _, item in ipairs(loadout.special or {}) do
		SafeGive(ply, item)
	end

	for _, med in ipairs(MODE.Medicine or {}) do
		SafeGive(ply, med)
	end

	-- Run after the custom "Player Spawn" inventory hook; it otherwise resets
	-- the weapon registry just after this function returns.
	SyncInventory(ply)

	return true
end

local function BroadcastPhase(phase, phaseEnd, data)
		net.Start("ng_phase")
		net.WriteInt(phase, 4)
		net.WriteFloat(phaseEnd or 0)
		if data then
			net.WriteTable(data)
		end
	net.Broadcast()
end

-- NWVars remain available as a persistent fallback, but role assignment takes
-- place during the equipment phase and can race the client's first HUD frame.
-- This packet is the authoritative client-facing role state.
local function SendRoleState(ply)
	if not IsValid(ply) then return end

	local saved = MODE.saved
	local role = saved and saved.Roles and saved.Roles[ply]
	if not role then role = MODE.GetRole(ply) end
	role = isstring(role) and role ~= "" and role or "none"

	local roleName = MODE.GetRoleName and MODE.GetRoleName(role)
		or MODE.RoleNames and MODE.RoleNames[role]
		or "观察者"
	local teamID = ply:GetNWVar("NGTeam", 2)
	if not isnumber(teamID) then teamID = 2 end

	net.Start("ng_role")
		net.WriteString(role)
		net.WriteString(roleName)
		net.WriteInt(teamID, 3)
		net.WriteBool(ply:GetNWBool("IsCommander", role == "commander"))
	net.Send(ply)
end

local function BroadcastRiotLevel()
	local saved = MODE.saved
	local level = math.Clamp(math.floor(saved.riotLevel or 0), 0, 100)
	local martial = saved.martialLaw or false
	if saved.lastBroadcastRiotLevel == level and saved.lastBroadcastMartialLaw == martial then return end
	saved.lastBroadcastRiotLevel = level
	saved.lastBroadcastMartialLaw = martial
	net.Start("ng_riot_level")
		net.WriteUInt(level, 7)
		net.WriteBool(martial)
	net.Broadcast()
end

local function PickCommander(guards)
	if #guards == 0 then return nil end
	table.sort(guards, function(a, b)
		local rankA = a:GetNWString("PlayerName", "")
		local rankB = b:GetNWString("PlayerName", "")
		return rankA > rankB
	end)
	return guards[1]
end

local function AlivePlayersOnTeam(team)
	local tbl = {}
	for _, ply in ipairs(team.GetPlayers(team)) do
		if ply:Alive() then tbl[#tbl + 1] = ply end
	end
	return tbl
end

local function DoSupplyDrop()
	local vecs = SafeVecs("NG_SUPPLY_DROP")
	if #vecs == 0 then return end
	local pos = vecs[math.random(#vecs)]

	net.Start("ng_supply_drop")
		net.WriteVector(pos)
	net.Broadcast()

	PrintMessage(HUD_PRINTTALK, "[国民警卫队] 物资空投已抵达！")

	timer.Simple(5, function()
		if zb.CROUND ~= MODE.name then return end
		local crate = ents.Create("ent_supply_crate")
		if not IsValid(crate) then
			-- The optional custom crate is not present on every server build;
			-- use a regular physics crate so the configured supply drop still
			-- produces a usable world object.
			crate = ents.Create("prop_physics")
			if IsValid(crate) then
				crate:SetModel("models/props_junk/wood_crate001a.mdl")
				crate:SetNWBool("NGSupplyCrate", true)
			end
		end
		if IsValid(crate) then
			crate:SetPos(pos + Vector(0,0,50))
			crate:Spawn()
		end
	end)
end

local function SetupGuard(ply, role)
	MODE.saved.Roles = MODE.saved.Roles or {}
	MODE.saved.Roles[ply] = role
	ply:SetNWVar("NGRole", role)
	ply:SetNWVar("NGTeam", 1)
	ply:SetNWBool("IsCommander", role == "commander")
	zb.GiveRole(ply, MODE.GetRoleName(role), Color(0, 100, 200))

	local loadout = MODE.GuardLoadouts[role] or MODE.GuardLoadouts.guardsman
	GiveLoadout(ply, loadout)

	if role == "commander" then
		ply:ChatPrint("你是指挥官！按F3打开指挥面板，可呼叫空投/炮击/下达命令。")
	end
end

local RioterRandomWeapons = {
	"weapon_hg_molotov_tpik",
	"weapon_pocketknife",
	"weapon_hg_bottle",
	"weapon_brick",
	"weapon_hg_axe",
}

-- 暴徒随机获得一件武器，构造对应的装备表
local function BuildRioterLoadout(ply)
	local weapon = ply.NGRioterWeapon or RioterRandomWeapons[math.random(#RioterRandomWeapons)]
	ply.NGRioterWeapon = weapon
	local loadout = table.Copy(MODE.RioterLoadouts.rioter)
	loadout.primary = weapon
	loadout.secondary = nil
	loadout.melee = nil
	return loadout
end

local function SetupRioter(ply, role)
	MODE.saved.Roles = MODE.saved.Roles or {}
	MODE.saved.Roles[ply] = role
	ply:SetNWVar("NGRole", role)
	ply:SetNWVar("NGTeam", 0)
	ply:SetNWBool("IsCommander", false)
	zb.GiveRole(ply, MODE.GetRoleName(role), Color(180, 50, 0))

	if role == "rioter" then
		GiveLoadout(ply, BuildRioterLoadout(ply))
	else
		local loadout = MODE.RioterLoadouts[role] or MODE.RioterLoadouts.rioter
		GiveLoadout(ply, loadout)
	end
end

function MODE:Intermission()
	game.CleanUpMap()
	self.saved = self.saved or {}
	self.saved.riotLevel = 0
	self.saved.martialLaw = false
	self.saved.curfew = false
	self.saved.checkpoints = {}
	self.saved.objectives = {}
end

function MODE:GiveEquipment()
	local saved = self.saved or {}
	self.saved = saved
	saved.riotLevel = 0
	saved.martialLaw = false
	saved.curfew = false
	saved.commander = nil
	saved.Roles = {}
	saved.checkpoints = {}
	saved.nextSupplyDrop = MODE.Config.SupplyDropInterval > 0 and CurTime() + MODE.Config.SupplyDropInterval or math.huge
	saved.lastThink = CurTime()
	saved.commanderNextOrder = 0
	saved.lastBroadcastRiotLevel = nil
	saved.lastBroadcastMartialLaw = nil
	saved.winner = nil

	local players = player.GetAll()
	table.Shuffle(players)

	local numPlayers = 0
	for _, ply in ipairs(players) do
		if ply:Team() ~= TEAM_SPECTATOR then numPlayers = numPlayers + 1 end
	end

	local numGuards = math.max(math.ceil(numPlayers * MODE.Config.GuardToRioterRatio), 1)
	local guards, rioters = {}, {}

	local guardIdx, rioterIdx = 0, 0
	for _, ply in ipairs(players) do
		if ply:Team() == TEAM_SPECTATOR then
			ply:SetNWVar("NGRole", "none")
			ply:SetNWVar("NGTeam", 2)
			ply:SetNWBool("IsCommander", false)
			SendRoleState(ply)
		else
			if not ply:Alive() then ply:Spawn() end
			ply:StripWeapons()
			if guardIdx < numGuards then
				guardIdx = guardIdx + 1
				guards[guardIdx] = ply
				ply:SetupTeam(1)
				ply:SetPlayerClass("nationalguard")
			else
				rioterIdx = rioterIdx + 1
				rioters[rioterIdx] = ply
				ply:SetupTeam(0)
				ply:SetPlayerClass("terrorist")
			end
		end
	end

	if MODE.Config.CommanderEnabled and #guards > 0 then
		saved.commander = PickCommander(guards)
		saved.commander:SetNWBool("IsCommander", true)
	end

	local roles = {"guardsman", "medic", "engineer", "marksman"}
	local roleIdx = 1
	for _, ply in ipairs(guards) do
		if ply == saved.commander then
			SetupGuard(ply, "commander")
		else
			local role = roles[roleIdx]
			roleIdx = roleIdx % #roles + 1
			SetupGuard(ply, role)
		end
		ply:SetPos(PickGuardSpawn())
	end

	local riotRoles = {"rioter", "agitator", "saboteur", "sniper"}
	local riotRoleIdx = 1
	for _, ply in ipairs(rioters) do
		local role = riotRoles[riotRoleIdx]
		riotRoleIdx = riotRoleIdx % #riotRoles + 1
		SetupRioter(ply, role)
		ply:SetPos(PickRioterSpawn())
	end

	saved.phase1End = CurTime() + MODE.Config.SurvivalTime
	BroadcastPhase(1, saved.phase1End)
	BroadcastRiotLevel()
	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then
			SendRoleState(ply)
		end
	end
	PrintMessage(HUD_PRINTTALK, "[国民警卫队] 行动开始！警卫队保护秩序，暴徒制造混乱。")

	-- Repeat after spawn/equipment hooks have settled. This closes the small
	-- NWVar replication window at round start without changing any assignment.
	timer.Simple(0.2, function()
		if zb.CROUND ~= MODE.name or not MODE.saved or MODE.saved.winner then return end
		for _, ply in player.Iterator() do
			if ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then
				SendRoleState(ply)
			end
		end
	end)
end

local function EquipRoleLoadout(ply, saved)
	local role = saved.Roles and saved.Roles[ply]
	if not role then return end

	if role == "rioter" then
		-- 暴徒的随机武器需要单独处理
		local weapon = ply.NGRioterWeapon or RioterRandomWeapons[math.random(#RioterRandomWeapons)]
		ply.NGRioterWeapon = weapon
		if not ply:HasWeapon(weapon) then
			SafeGive(ply, weapon)
		end
		return
	end

	local loadout = MODE.GuardLoadouts[role] or MODE.RioterLoadouts[role]
	if loadout and not ply:HasWeapon(loadout.primary) then
		GiveLoadout(ply, loadout)
	end
end

function MODE:RoundStart()
	local saved = self.saved or {}
	self.saved = saved
	saved.phase1End = CurTime() + MODE.Config.SurvivalTime
	BroadcastPhase(1, saved.phase1End)
	-- GiveEquipment normally runs after players are spawned. Re-validate once
	-- at round start so a late spawn cannot leave a role unarmed.
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then continue end
		EquipRoleLoadout(ply, saved)
		SendRoleState(ply)
	end
end

-- Mode hooks registered via the loader run BEFORE GM:PlayerSpawn finishes,
-- so re-validate on a short delay instead of arming the player immediately.
function MODE:PlayerSpawn(ply)
	timer.Simple(0.25, function()
		if not IsValid(ply) or not ply:Alive() then return end

		local saved = MODE.saved or {}
		if saved.winner then return end
		if not saved.Roles or not saved.Roles[ply] then return end
		if ply:Team() == TEAM_SPECTATOR then return end

		EquipRoleLoadout(ply, saved)
		SendRoleState(ply)
	end)
end

function MODE:RoundThink()
	local saved = self.saved or {}
	self.saved = saved
	saved.riotLevel = saved.riotLevel or 0
	saved.lastThink = saved.lastThink or CurTime()
	saved.phase1End = saved.phase1End or math.huge
	if saved.winner then return end

	if MODE.Config.CommanderEnabled and (not IsValid(saved.commander) or not saved.commander:Alive()) then
		saved.winner = 0
		PrintMessage(HUD_PRINTTALK, "[国民警卫队] 指挥官阵亡，暴徒获胜！")
		return
	end

	if #AlivePlayersOnTeam(0) == 0 then
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[国民警卫队] 所有暴徒被清除，警卫队获胜！")
		return
	end

	if CurTime() >= saved.phase1End then
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[国民警卫队] 时间耗尽，秩序恢复，警卫队获胜！")
		return
	end

	local now = CurTime()
	local delta = math.Clamp(now - (saved.lastThink or now), 0, 0.25)
	saved.lastThink = now
	saved.riotLevel = math.min((saved.riotLevel or 0) + delta * (MODE.Config.RiotLevelRate or 0), 100)

	if MODE.Config.MartialLawEnabled and not saved.martialLaw
		and saved.riotLevel >= MODE.Config.MartialLawThreshold then
		saved.martialLaw = true
		net.Start("ng_martial_law")
			net.WriteBool(true)
		net.Broadcast()
		PrintMessage(HUD_PRINTTALK, "[国民警卫队] 暴乱度达到阈值，已进入戒严状态！")
	end
	BroadcastRiotLevel()
	if saved.riotLevel >= MODE.Config.RiotLevelThreshold then
		saved.winner = 0
		PrintMessage(HUD_PRINTTALK, "[国民警卫队] 暴乱度爆表，秩序崩溃，暴徒获胜！")
		return
	end

	if MODE.Config.SupplyDropInterval > 0 and now >= (saved.nextSupplyDrop or math.huge) then
		saved.nextSupplyDrop = now + MODE.Config.SupplyDropInterval
		DoSupplyDrop()
	end
end

function MODE:ShouldRoundEnd()
	local saved = self.saved or {}
	self.saved = saved
	if saved.winner then return true end

	if MODE.Config.CommanderEnabled and (not IsValid(saved.commander) or not saved.commander:Alive()) then return true end
	if #AlivePlayersOnTeam(0) == 0 then return true end
	if CurTime() >= saved.phase1End then return true end
	if saved.riotLevel >= MODE.Config.RiotLevelThreshold then return true end

	return false
end

function MODE:PlayerDeath(victim, inflictor, attacker)
	local saved = self.saved
	if saved.winner then return end

	if attacker and attacker:IsPlayer() and attacker:GetNWVar("NGTeam") == 1 and victim:GetNWVar("NGTeam") == 0 then
		saved.riotLevel = math.max(saved.riotLevel - 5, 0)
	elseif attacker and attacker:IsPlayer() and attacker:GetNWVar("NGTeam") == 0 and victim:GetNWVar("NGTeam") == 1 then
		saved.riotLevel = math.min(saved.riotLevel + 8, 100)
	end
	BroadcastRiotLevel()

	if victim == saved.commander then
		saved.winner = 0
		PrintMessage(HUD_PRINTTALK, "[国民警卫队] 指挥官阵亡，暴徒获胜！")
	end
end

function MODE:PlayerDisconnected(ply)
	local saved = self.saved
	if saved.winner then return end
	if MODE.Config.CommanderEnabled and ply == saved.commander then
		saved.winner = 0
		PrintMessage(HUD_PRINTTALK, "[国民警卫队] 指挥官离开，暴徒获胜！")
	end
end

function MODE:EndRound()
	local saved = self.saved
	local winner = saved.winner or 1
	local commander = IsValid(saved.commander) and saved.commander or NULL

	timer.Simple(2, function()
		net.Start("ng_roundend")
			net.WriteInt(winner, 8)
			net.WriteEntity(commander)
		net.Broadcast()

		for _, ply in player.Iterator() do
			if ply:Team() ~= TEAM_SPECTATOR then
				if ply:GetNWVar("NGTeam") == winner then
					ply:GiveExp(math.random(150, 200))
					ply:GiveSkill(math.Rand(0.2, 0.3))
				else
					ply:GiveExp(math.random(50, 80))
					ply:GiveSkill(math.Rand(0.05, 0.1))
				end
			end
		end
	end)
end

function MODE:CanLaunch()
	local activePlayers = 0
	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then activePlayers = activePlayers + 1 end
	end
	return activePlayers >= MODE.Config.MinPlayers
end

function MODE:PlayerInitialSpawn(ply)
	local saved = self.saved
	if not saved or not saved.phase1End then return end

	net.Start("ng_phase")
	net.WriteInt(1, 4)
	net.WriteFloat(saved.phase1End)
	net.Send(ply)
	SendRoleState(ply)

	net.Start("ng_riot_level")
		net.WriteUInt(math.Clamp(math.floor(saved.riotLevel or 0), 0, 100), 7)
		net.WriteBool(saved.martialLaw or false)
	net.Send(ply)
	net.Start("ng_curfew")
		net.WriteBool(saved.curfew or false)
	net.Send(ply)
end

function MODE:GetTeamSpawn()
	return SafeVecs("NG_RIOTER_SPAWN"), SafeVecs("NG_GUARD_SPAWN")
end

net.Receive("ng_commander_order", function(len, ply)
	if not MODE.Config.CommanderEnabled or not IsValid(ply) or not ply:Alive() then return end
	if not ply:GetNWBool("IsCommander", false) then return end
	if CurTime() < (MODE.saved.commanderNextOrder or 0) then
		ply:ChatPrint("指挥命令仍在冷却中。")
		return
	end
	local orderType = net.ReadInt(4)
	local pos = net.ReadVector()
	MODE.saved.commanderNextOrder = CurTime() + (MODE.Config.CommanderOrderCooldown or 20)

	if orderType == 1 then
		if MODE.Config.SupplyDropInterval <= 0 then return end
		DoSupplyDrop()
		PrintMessage(HUD_PRINTTALK, "[指挥官] 请求空投补给！")
	elseif orderType == 2 then
		PrintMessage(HUD_PRINTTALK, "[指挥官] 请求炮火支援！")
	elseif orderType == 3 then
		if not MODE.Config.MartialLawEnabled then return end
		MODE.saved.martialLaw = true
		net.Start("ng_martial_law")
			net.WriteBool(true)
		net.Broadcast()
		PrintMessage(HUD_PRINTTALK, "[指挥官] 宣布戒严令！全员武力升级！")
	elseif orderType == 4 then
		if not MODE.Config.CurfewEnabled then return end
		MODE.saved.curfew = true
		net.Start("ng_curfew")
			net.WriteBool(true)
		net.Broadcast()
		PrintMessage(HUD_PRINTTALK, "[指挥官] 宣布宵禁！全员限制移动！")
	end
end)

hook.Add("PlayerUse", "NG_Arrest", function(ply, ent)
	if IsValid(ent) and ent:GetNWBool("NGSupplyCrate", false) then
		ent:Remove()
		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_tourniquet")
		ply:GiveAmmo(30, game.GetAmmoID("SMG1"), true)
		ply:ChatPrint("你打开了补给箱，获得医疗用品和弹药。")
		return false
	end
	if not MODE.Config.ArrestEnabled then return end
	if not IsValid(ent) or not ent:IsPlayer() then return end
	if ply:GetNWVar("NGTeam") ~= 1 then return end
	if ent:GetNWVar("NGTeam") ~= 0 then return end
	if ent:GetNWBool("Arrested", false) then return end
	if not ply:HasWeapon("weapon_handcuffs") then return end
	if not ply:KeyDown(IN_SPEED) then return end

	local target = ent
	local targetRole = MODE.saved.Roles and MODE.saved.Roles[target] or MODE.GetRole(target)
	local oldWalkSpeed = target:GetWalkSpeed()
	local oldRunSpeed = target:GetRunSpeed()
	target:SetNWBool("Arrested", true)
	target:SetWalkSpeed(50)
	target:SetRunSpeed(50)
	target:StripWeapons()
	target:Give("weapon_hands_sh")

	PrintMessage(HUD_PRINTTALK, "[国民警卫队] " .. target:Nick() .. " 被 " .. ply:Nick() .. " 逮捕！")
	MODE.saved.riotLevel = math.max(MODE.saved.riotLevel - 10, 0)

	timer.Simple(30, function()
		if IsValid(target) then
			target:SetNWBool("Arrested", false)
			target:SetWalkSpeed(oldWalkSpeed)
			target:SetRunSpeed(oldRunSpeed)
			if targetRole == "rioter" then
				GiveLoadout(target, BuildRioterLoadout(target))
			else
				GiveLoadout(target, MODE.RioterLoadouts[targetRole] or MODE.RioterLoadouts.rioter)
			end
		end
	end)
end)

hook.Add("SetupMove", "NG_CurfewMovement", function(ply, mv)
	if zb.CROUND ~= MODE.name or not MODE.saved or not MODE.saved.curfew then return end
	if ply:Team() ~= 0 or not ply:Alive() then return end
	local speed = MODE.Config.CurfewSpeed or 100
	mv:SetMaxSpeed(speed)
	mv:SetMaxClientSpeed(speed)
end)

return MODE
