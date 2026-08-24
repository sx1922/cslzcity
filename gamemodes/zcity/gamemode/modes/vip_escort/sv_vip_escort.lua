MODE.name = "vipescort"

local MODE = MODE

util.AddNetworkString("vip_phase")
util.AddNetworkString("vip_roundend")
util.AddNetworkString("vip_role")

-- A VIP round must remain playable even when an optional weapon/armor addon is
-- absent.  Every grant is isolated so a single bad class cannot suppress the
-- rest of the role's starting equipment.
local function SafeGive(ply, class)
	if not IsValid(ply) or not isstring(class) or class == "" then return NULL end
	local ok, weapon = pcall(ply.Give, ply, class)
	if not ok then
		ErrorNoHalt("[VIP Escort] Give failed for " .. tostring(class) .. ": " .. tostring(weapon) .. "\n")
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
		ErrorNoHalt("[VIP Escort] armor failed for " .. ply:Nick() .. ": " .. tostring(result) .. "\n")
		return false
	end
	return result ~= false
end

local function SafeInventory(ply)
	if not IsValid(ply) then return end
	local ok, err = pcall(function()
		if hg.RenewInv then hg.RenewInv(ply) elseif hg.CreateInv then hg.CreateInv(ply) end
		local inv = ply:GetNetVar("Inventory", {}) or {}
		inv.Weapons = inv.Weapons or {}
		inv.Weapons["hg_sling"] = true
		inv.Weapons["hg_flashlight"] = true
		ply:SetNetVar("Inventory", inv)
	end)
	if not ok then
		ErrorNoHalt("[VIP Escort] inventory sync failed for " .. ply:Nick() .. ": " .. tostring(err) .. "\n")
	end
end

-- 启动时校验 Loadouts 中的武器类是否已注册，缺失则打印警告
timer.Simple(5, function()
	for name, loadout in pairs(MODE.Loadouts or {}) do
		for _, key in ipairs({"primary", "secondary", "melee"}) do
			local class = loadout[key]
			if isstring(class) and not weapons.Get(class) then
				print("[VIP Escort] 警告: Loadout '" .. name .. "' 的 " .. key .. " 武器类未注册: " .. class)
			end
		end
	end

	for _, med in ipairs(MODE.Medicine or {}) do
		if not weapons.Get(med) then
			print("[VIP Escort] 警告: 医疗物品类未注册: " .. med)
		end
	end
end)

local function AlivePlayersOnTeam(team_)
	local tbl = {}
	for _, ply in ipairs(team.GetPlayers(team_)) do
		if ply:Alive() then tbl[#tbl + 1] = ply end
	end
	return tbl
end

local function SafeVecs(group)
	local pts = zb.GetMapPoints(group)
	if not pts then return {} end
	return zb.TranslatePointsToVectors(pts)
end

local function PickExtractPos()
	local vecs = SafeVecs("VIP_EXTRACT")
	if #vecs == 0 then vecs = SafeVecs("HOSTAGE_DELIVERY_ZONE") end
	if #vecs == 0 then vecs = SafeVecs("RandomSpawns") end
	if #vecs == 0 then vecs = {zb:GetRandomSpawn()} end
	return vecs[math.random(#vecs)]
end

local function SendVIPRolePacket(ply, role, displayName)
	if not IsValid(ply) then return end
	net.Start("vip_role")
		net.WriteString(role or "none")
		net.WriteString(displayName or MODE.RoleNames[role] or "观察者")
	net.Send(ply)
end

local function SetVIPRole(ply, role, displayName, color)
	if not IsValid(ply) then return end
	local saved = MODE.saved or {}
	MODE.saved = saved
	saved.Roles = saved.Roles or {}
	saved.Roles[ply] = role
	ply:SetNetVar("VIPRole", role)
	if displayName then
		zb.GiveRole(ply, displayName, color)
	end

	-- Do not rely solely on NWVar propagation: role assignment happens during
	-- the server-side equipment phase and can race the client's first HUD frame.
	SendVIPRolePacket(ply, role, displayName)
end

local function GetAssignedRole(ply)
	if not IsValid(ply) then return "none" end

	local saved = MODE.saved
	local role = saved and saved.Roles and saved.Roles[ply]
	if role == "vip" or role == "guard" or role == "guard_officer"
		or role == "assassin" or role == "assassin_officer" then
		return role
	end

	-- Preserve compatibility with a network-var-only state, but never map an
	-- unknown role to an assassin loadout by default.
	local networkRole = MODE.GetRole(ply)
	if networkRole == "vip" or networkRole == "guard" or networkRole == "guard_officer"
		or networkRole == "assassin" or networkRole == "assassin_officer" then
		return networkRole
	end

	if saved and ply == saved.VIP then return "vip" end
	if ply:Team() == 1 then return "guard" end
	if ply:Team() == 0 then return "assassin" end
	return "none"
end

local function GetLoadoutForPlayer(ply)
	local role = GetAssignedRole(ply)
	local loadoutNames = {
		vip = "vip",
		guard = "guard_soldier",
		guard_officer = "guard_officer",
		assassin = "assassin_soldier",
		assassin_officer = "assassin_officer"
	}
	local loadoutName = loadoutNames[role]

	if not loadoutName then
		ErrorNoHalt("[VIP Escort] refusing loadout for " .. tostring(IsValid(ply) and ply:Nick() or ply) .. ": unknown role\n")
		return nil
	end

	return MODE.Loadouts[loadoutName], role
end

local function GiveLoadout(ply, loadout)
	if not IsValid(ply) or not istable(loadout) or not isstring(loadout.primary) then
		return false
	end

	local function giveWeapon(class, ammoMult)
		if not isstring(class) then return NULL end

		local wep = SafeGive(ply, class)
		if not IsValid(wep) then
			ErrorNoHalt("[VIP Escort] 武器类不存在或发放失败: " .. class .. " (玩家: " .. ply:Nick() .. ")\n")
			return NULL
		end

		if ammoMult and wep.GetPrimaryAmmoType and wep:GetPrimaryAmmoType() >= 0 then
			local clip = math.max(wep:GetMaxClip1() or 1, 1)
			SafeAmmo(ply, clip * ammoMult, wep:GetPrimaryAmmoType())
		end

		return wep
	end

	SafeGive(ply, "weapon_hands_sh")

	local gun = giveWeapon(loadout.primary, loadout.ammo or 0)
	if IsValid(gun) then
		ply:SelectWeapon(gun:GetClass())
	end

	if loadout.secondary then
		giveWeapon(loadout.secondary, loadout.ammo2 or 2)
	end

	if loadout.armor then SafeArmor(ply, loadout.armor) end
	if isstring(loadout.melee) then giveWeapon(loadout.melee) end

	for _, med in ipairs(MODE.Medicine or {}) do
		giveWeapon(med)
	end

	SafeInventory(ply)

	return true
end

local function BroadcastPhase(phase)
	net.Start("vip_phase")
		net.WriteInt(phase, 4)
		net.WriteFloat(phase == 1 and MODE.saved.phase1End or MODE.saved.phase2End)
		net.WriteVector(MODE.saved.extractPos)
	net.Broadcast()
end

local function TeamSpawnVecs(team_)
	local vecs = SafeVecs(team_ == 0 and "HMCD_TDM_T" or "HMCD_TDM_CT")
	if #vecs == 0 then vecs = {zb:GetRandomSpawn()} end
	return vecs
end

local function RespawnDeadTeam(team_)
	local saved = MODE.saved
	if saved.winner then return end

	local dead = {}
	for _, ply in player.Iterator() do
		if ply:Team() ~= team_ then continue end
		if ply:Alive() then continue end
		if GetAssignedRole(ply) == "vip" then continue end

		local deathTime = saved.deathTimes and saved.deathTimes[ply]
		if deathTime and CurTime() - deathTime < MODE.Config.RespawnDelay then continue end

		dead[#dead + 1] = ply
	end

	if #dead == 0 then return end

	table.Shuffle(dead)
	local count = math.min(MODE.Config.RespawnCount, #dead)
	local spawnVecs = TeamSpawnVecs(team_)
	local respawned = {}

	for i = 1, count do
		local ply = dead[i]
		ply:Spawn()
		ply:SetPos(spawnVecs[math.random(#spawnVecs)])
		ply:SetLocalVelocity(vector_origin)

		local loadout = GetLoadoutForPlayer(ply)
		if loadout and not ply:HasWeapon(loadout.primary) then GiveLoadout(ply, loadout) end

		if saved.deathTimes then saved.deathTimes[ply] = nil end
		respawned[#respawned + 1] = ply:Nick()

		ply:EmitSound("items/suitchargeok1.wav")
	end

	PrintMessage(HUD_PRINTTALK, "[VIP Escort] 支援抵达！" .. table.concat(respawned, ", ") .. " 已重新投入战斗。")
end

function MODE:Intermission()
	game.CleanUpMap()
end

function MODE:GiveEquipment()
	local saved = MODE.saved or {}
	MODE.saved = saved
	saved.phase = 1
	saved.winner = nil
	saved.extracted = false
	saved.holdStart = nil
	saved.extractPos = PickExtractPos()
	saved.deathTimes = {}
	saved.Roles = {}
	saved.respawnNext = {[0] = CurTime() + MODE.Config.RespawnInterval, [1] = CurTime() + MODE.Config.RespawnInterval}

	local players = player.GetAll()
	table.Shuffle(players)

	local numPlayers = 0
	for _, ply in ipairs(players) do
		if ply:Team() ~= TEAM_SPECTATOR then
			numPlayers = numPlayers + 1
		end
	end

	local numGuards = math.ceil(numPlayers / 2)
	local guards, assassins = {}, {}
	if numPlayers < 2 then
		saved.winner = 0
		PrintMessage(HUD_PRINTTALK, "[VIP Escort] 玩家人数不足，回合已取消。")
		return
	end

	local guardIdx, assassinIdx = 0, 0
	for _, ply in ipairs(players) do
		if ply:Team() == TEAM_SPECTATOR then
			SetVIPRole(ply, "none")
			continue
		end
		if not ply:Alive() then ply:Spawn() end
		ply:StripWeapons()

		if guardIdx < numGuards then
			guardIdx = guardIdx + 1
			guards[guardIdx] = ply
			ply:SetupTeam(1)
			ply:SetPlayerClass("nationalguard")
			SetVIPRole(ply, "guard", "德军护卫", Color(0, 90, 190))
		else
			assassinIdx = assassinIdx + 1
			assassins[assassinIdx] = ply
			ply:SetupTeam(0)
			ply:SetPlayerClass("terrorist")
			SetVIPRole(ply, "assassin", "苏军刺客", Color(190, 0, 0))
		end
	end

	local vip = guards[math.random(#guards)]
	saved.VIP = vip
	SetVIPRole(vip, "vip", "VIP 目标", Color(255, 215, 0))

	local function pickOfficer(teamTbl, exclude)
		local tbl = {}
		for _, ply in ipairs(teamTbl) do
			if ply ~= exclude then tbl[#tbl + 1] = ply end
		end
		if #tbl == 0 then return nil end
		return tbl[math.random(#tbl)]
	end

	for i = 1, MODE.Config.OfficerCount do
		local officer = pickOfficer(guards, vip)
		if IsValid(officer) and officer ~= vip then
			SetVIPRole(officer, "guard_officer", "德军军官", Color(70, 150, 255))
		end

		if #assassins > 0 then
			officer = assassins[math.random(#assassins)]
			SetVIPRole(officer, "assassin_officer", "苏军军官", Color(255, 70, 70))
		end
	end

	-- Equip during intermission as well as RoundStart. This prevents a short
	-- no-weapon window and makes the mode resilient to late spawn hooks.
	for _, ply in ipairs(players) do
		if ply:Team() ~= TEAM_SPECTATOR then
			local loadout = GetLoadoutForPlayer(ply)
			if loadout then GiveLoadout(ply, loadout) end
		end
	end

	-- Repeat the authoritative role packet after loadouts have settled. This
	-- also covers clients that joined during the intermission transition.
	timer.Simple(0.2, function()
		if not MODE.saved or MODE.saved.winner then return end
		for _, ply in player.Iterator() do
			if ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then
				local role = GetAssignedRole(ply)
				SendVIPRolePacket(ply, role, MODE.RoleNames[role])
			end
		end
	end)
end

function MODE:RoundStart()
	local saved = MODE.saved or {}
	MODE.saved = saved

	if not IsValid(saved.VIP) or not saved.VIP:Alive() then
		local guards = AlivePlayersOnTeam(1)
		if #guards > 0 then
			saved.VIP = guards[math.random(#guards)]
			SetVIPRole(saved.VIP, "vip", "VIP 目标", Color(255, 215, 0))
		else
			saved.winner = 0
			return
		end
	end

	saved.phase1End = CurTime() + MODE.Config.SurvivalTime
	saved.phase2End = saved.phase1End + MODE.Config.ExtractTime

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local loadout = GetLoadoutForPlayer(ply)
		if loadout and not ply:HasWeapon(loadout.primary) then GiveLoadout(ply, loadout) end
	end
	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then
			local role = GetAssignedRole(ply)
			SendVIPRolePacket(ply, role, MODE.RoleNames[role])
		end
	end

	PrintMessage(HUD_PRINTTALK, "[VIP Escort] VIP 目标: " .. saved.VIP:Nick() .. " — 德军护卫需保护其存活 " .. math.floor(MODE.Config.SurvivalTime / 60) .. " 分钟，之后前往撤离点！")

	BroadcastPhase(1)
end

-- Mode hooks registered via the loader run BEFORE GM:PlayerSpawn finishes
-- (team assignment etc), so re-validate on a short delay instead of arming
-- the player immediately.
function MODE:PlayerSpawn(ply)
	timer.Simple(0.25, function()
		if not IsValid(ply) or not ply:Alive() then return end

		local saved = MODE.saved or {}
		if not saved.phase or saved.phase ~= 1 or saved.winner then return end
		if ply:Team() == TEAM_SPECTATOR then return end
		if GetAssignedRole(ply) == "none" then return end

		local loadout = GetLoadoutForPlayer(ply)
		if loadout and not ply:HasWeapon(loadout.primary) then
			GiveLoadout(ply, loadout)
		end
	end)
end

function MODE:RoundThink()
	local saved = MODE.saved or {}
	MODE.saved = saved
	saved.phase = saved.phase or 1
	saved.phase1End = saved.phase1End or math.huge
	saved.phase2End = saved.phase2End or math.huge
	saved.respawnNext = saved.respawnNext or {[0] = math.huge, [1] = math.huge}
	if saved.winner then return end

	if saved.phase == 1 then
		if CurTime() >= saved.phase1End then
			saved.phase = 2
			saved.phase2End = CurTime() + MODE.Config.ExtractTime
			PrintMessage(HUD_PRINTTALK, "[VIP Escort] 撤离阶段开始！护送 VIP 前往撤离点并停留 " .. MODE.Config.ExtractHold .. " 秒！")
			BroadcastPhase(2)
		end
		return
	end

	local vip = saved.VIP
	if IsValid(vip) and vip:Alive() then
		if vip:GetPos():Distance(saved.extractPos) <= MODE.Config.ExtractRadius then
			saved.holdStart = saved.holdStart or CurTime()
			if CurTime() - saved.holdStart >= MODE.Config.ExtractHold then
				saved.extracted = true
				saved.winner = 1
				PrintMessage(HUD_PRINTTALK, "[VIP Escort] VIP 成功撤离！德军护卫胜利！")
			end
		else
			saved.holdStart = nil
		end
	else
		saved.holdStart = nil
	end

	if CurTime() >= saved.phase2End then
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[VIP Escort] 时间耗尽，德军护卫成功守住 VIP！")
	end

	for team_ = 0, 1 do
		if CurTime() >= (saved.respawnNext[team_] or 0) then
			saved.respawnNext[team_] = CurTime() + MODE.Config.RespawnInterval
			RespawnDeadTeam(team_)
		end
	end
end

function MODE:ShouldRoundEnd()
	local saved = MODE.saved or {}
	MODE.saved = saved
	if saved.winner then return true end

	local vip = saved.VIP
	if not IsValid(vip) or not vip:Alive() then
		saved.winner = 0
		return true
	end

	if #AlivePlayersOnTeam(0) == 0 then
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[VIP Escort] 苏军刺客全灭，德军护卫胜利！")
		return true
	end

	return false
end

function MODE:PlayerDeath(victim, inflictor, attacker)
	local saved = MODE.saved
	if saved.winner then return end
	if victim == saved.VIP then
		saved.winner = 0
		PrintMessage(HUD_PRINTTALK, "[VIP Escort] VIP 阵亡！苏军刺客胜利！")
		return
	end

	if saved.deathTimes then
		saved.deathTimes[victim] = CurTime()
	end
end

function MODE:PlayerDisconnected(ply)
	local saved = MODE.saved
	if saved.winner then return end
	if ply ~= saved.VIP then return end

	local guards = AlivePlayersOnTeam(1)
	if #guards > 0 then
		local newVip = guards[math.random(#guards)]
		saved.VIP = newVip
		SetVIPRole(newVip, "vip", "VIP 目标", Color(255, 215, 0))
		PrintMessage(HUD_PRINTTALK, "[VIP Escort] 原 VIP 已离开，新任 VIP: " .. newVip:Nick())
	else
		saved.winner = 0
	end
end

function MODE:EndRound()
	local saved = MODE.saved
	local winner = saved.winner or 1
	local vip = IsValid(saved.VIP) and saved.VIP or NULL

	timer.Simple(2, function()
		net.Start("vip_roundend")
			net.WriteInt(winner, 8)
			net.WriteEntity(vip)
			net.WriteBool(saved.extracted or false)
		net.Broadcast()

		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end

			if ply:Team() == winner then
				ply:GiveExp(math.random(150, 200))
				ply:GiveSkill(math.Rand(0.2, 0.3))
			else
				ply:GiveExp(math.random(50, 80))
				ply:GiveSkill(math.Rand(0.05, 0.1))
			end

			if IsValid(vip) and ply == vip and winner == 1 then
				ply:GiveExp(200)
				ply:GiveSkill(0.3)
			end
		end
	end)
end

function MODE:CanLaunch()
	local activePlayers = 0
	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then
			activePlayers = activePlayers + 1
		end
	end
	return activePlayers >= MODE.Config.MinPlayers
end

function MODE:PlayerInitialSpawn(ply)
	local saved = MODE.saved
	if not saved or not saved.extractPos or saved.phase ~= 1 and saved.phase ~= 2 then return end
	if not IsValid(saved.VIP) then return end

	local phaseEnd = saved.phase == 1 and saved.phase1End or saved.phase2End
	if not phaseEnd then return end

	net.Start("vip_phase")
		net.WriteInt(saved.phase, 4)
		net.WriteFloat(phaseEnd)
		net.WriteVector(saved.extractPos)
	net.Send(ply)
	SendVIPRolePacket(ply, GetAssignedRole(ply), MODE.RoleNames[GetAssignedRole(ply)])
end

function MODE:GetTeamSpawn()
	return SafeVecs("HMCD_TDM_T"), SafeVecs("HMCD_TDM_CT")
end

return MODE
