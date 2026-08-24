MODE.name = "chainsaw_maniac"

local MODE = MODE

util.AddNetworkString("chainsaw_phase")
util.AddNetworkString("chainsaw_roundend")
util.AddNetworkString("chainsaw_roar")
util.AddNetworkString("chainsaw_charge")
util.AddNetworkString("chainsaw_role")

-- Loadouts are assembled from optional weapons/armor registered by other
-- addons.  A missing class must not abort the rest of the role setup (the old
-- code stopped after the first failing Give/AddArmor call, leaving players
-- with no usable starting items).
local function SafeGive(ply, class)
	if not IsValid(ply) or not isstring(class) or class == "" then return NULL end
	local ok, weapon = pcall(ply.Give, ply, class)
	if not ok then
		ErrorNoHalt("[chainsaw_maniac] Give failed for " .. tostring(class) .. ": " .. tostring(weapon) .. "\n")
		return NULL
	end
	return weapon or NULL
end

local function SafeArmor(ply, armor)
	if not IsValid(ply) or not hg or not hg.AddArmor or armor == nil then return false end
	local ok, result = pcall(hg.AddArmor, ply, armor)
	if not ok then
		ErrorNoHalt("[chainsaw_maniac] armor failed for " .. ply:Nick() .. ": " .. tostring(result) .. "\n")
		return false
	end
	return result ~= false
end

local function SyncInventory(ply)
	if not IsValid(ply) then return end
	pcall(function()
		if hg.CreateInv then hg.CreateInv(ply) end
		local inv = ply:GetNetVar("Inventory", {}) or {}
		inv.Weapons = inv.Weapons or {}
		inv.Weapons["hg_sling"] = true
		ply:SetNetVar("Inventory", inv)
	end)
end

local function HasWeapon(ply, class)
	if not IsValid(ply) or not isstring(class) then return false end
	local ok, result = pcall(ply.HasWeapon, ply, class)
	return ok and result == true
end

local function SendRoleState(ply)
	if not IsValid(ply) then return end
	local role = ply:GetNWVar("ManiacRole", "none") or "none"
	local weaponClass = ply:GetNWString("ManiacWeaponClass", "")
	net.Start("chainsaw_role")
		net.WriteString(role)
		net.WriteString(weaponClass)
	net.Send(ply)
end

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

local function PickManiacSpawn()
	local vecs = SafeVecs("CHAINSAW_MANIAC")
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_T") end
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_CT") end
	if #vecs == 0 then vecs = {zb:GetRandomSpawn()} end
	return vecs[math.random(#vecs)]
end

local function PickSurvivorSpawn()
	local vecs = SafeVecs("SURVIVOR_SPAWN")
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_CT") end
	if #vecs == 0 then vecs = SafeVecs("HMCD_TDM_T") end
	if #vecs == 0 then vecs = SafeVecs("RandomSpawns") end
	if #vecs == 0 then vecs = {zb:GetRandomSpawn()} end
	return vecs[math.random(#vecs)]
end

local function GiveManiacLoadout(ply)
	SafeGive(ply, "weapon_hands_sh")

	local weaponClass
	local candidates = {MODE.ManiacLoadout.melee, "weapon_melee", "weapon_hg_axe", "weapon_hatchet"}
	for _, class in ipairs(candidates) do
		if HasWeapon(ply, class) then
			weaponClass = class
			break
		end
		local gun = SafeGive(ply, class)
		if IsValid(gun) then
			weaponClass = gun:GetClass()
			break
		end
	end
	if weaponClass then
		ply:SetNWString("ManiacWeaponClass", weaponClass)
		pcall(ply.SelectWeapon, ply, weaponClass)
	else
		ply:SetNWString("ManiacWeaponClass", "")
		ErrorNoHalt("[chainsaw_maniac] no melee weapon registered for " .. ply:Nick() .. "\n")
	end

	SafeArmor(ply, MODE.ManiacLoadout.armor)
	SyncInventory(ply)
	SendRoleState(ply)
end

local function GiveSurvivorLoadout(ply)
	SafeGive(ply, "weapon_hands_sh")

	local gun = SafeGive(ply, MODE.SurvivorLoadout.melee)
	if IsValid(gun) then
		ply:SelectWeapon(gun:GetClass())
	end

	SafeArmor(ply, MODE.SurvivorLoadout.armor)

	for _, med in ipairs(MODE.SurvivorLoadout.meds or {}) do
		SafeGive(ply, med)
	end
	SafeGive(ply, MODE.SurvivorLoadout.flashbang)
	SafeGive(ply, MODE.SurvivorLoadout.flashlight)
	SyncInventory(ply)
	SendRoleState(ply)
end

local function BroadcastPhase(phase, phaseEnd)
	net.Start("chainsaw_phase")
		net.WriteInt(phase, 4)
		net.WriteFloat(phaseEnd)
	net.Broadcast()
end

local function SetupManiac(ply)
	ply:SetNWVar("ManiacRole", "maniac")
	zb.GiveRole(ply, "电锯杀人魔", Color(180, 0, 0))
	ply:SetNWInt("Maniac_MaxHealth", MODE.Config.ManiacHealth)
	ply:SetHealth(MODE.Config.ManiacHealth)
	ply:SetMaxHealth(MODE.Config.ManiacHealth)

	local ws = 200 * MODE.Config.ManiacSpeedMul
	local rs = 350 * MODE.Config.ManiacSpeedMul
	ply:SetWalkSpeed(ws)
	ply:SetRunSpeed(rs)

	ply:SetNWBool("Maniac_NoPush", true)
	ply:SetNWFloat("Maniac_RoarCooldown", 0)
	ply:SetNWFloat("Maniac_ChargeCooldown", 0)
	ply:SetNWFloat("Maniac_RageEnd", 0)

	GiveManiacLoadout(ply)
end

local function SetupSurvivor(ply)
	ply:SetNWVar("ManiacRole", "survivor")
	zb.GiveRole(ply, "幸存者", Color(0, 150, 200))
	GiveSurvivorLoadout(ply)
end

function MODE:Intermission()
	game.CleanUpMap()
end

function MODE:GiveEquipment()
	local saved = MODE.saved or {}
	MODE.saved = saved
	saved.phase = 1
	saved.winner = nil
	saved.holdStart = nil
	saved.deathTimes = {}
	saved.maniacRage = {}

	local players = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply:Team() ~= TEAM_SPECTATOR then
			players[#players + 1] = ply
		else
			ply:SetNWVar("ManiacRole", "none")
		end
	end
	table.Shuffle(players)

	local numPlayers = #players

	if numPlayers < MODE.Config.MinPlayers then return end

	local maniac = players[1]
	local survivors = {}
	for i = 2, #players do
		survivors[#survivors + 1] = players[i]
	end

	saved.maniac = maniac

	for _, ply in ipairs(players) do
		if not ply:Alive() then ply:Spawn() end
		ply:StripWeapons()
		if ply == maniac then
			ply:SetupTeam(0)
			ply:SetPlayerClass("terrorist")
			SetupManiac(ply)
			ply:SetPos(PickManiacSpawn())
		else
			ply:SetupTeam(1)
			ply:SetPlayerClass("nationalguard")
			SetupSurvivor(ply)
			ply:SetPos(PickSurvivorSpawn())
		end
	end

	saved.phase1End = CurTime() + MODE.Config.SurvivalTime
	-- The mode can enter RoundStart a few ticks after equipment assignment;
	-- repeat the personalized role message so the killer does not miss it.
	timer.Simple(0.2, function()
		if not MODE.saved or MODE.saved.winner then return end
		for _, ply in player.Iterator() do
			if ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then SendRoleState(ply) end
		end
	end)
end

function MODE:RoundStart()
	local saved = MODE.saved or {}
	MODE.saved = saved

	if not IsValid(saved.maniac) or not saved.maniac:Alive() then
		local survivors = AlivePlayersOnTeam(1)
		if #survivors > 0 then
			saved.maniac = survivors[math.random(#survivors)]
			saved.maniac:SetupTeam(0)
			saved.maniac:SetPlayerClass("terrorist")
			SetupManiac(saved.maniac)
		else
			saved.winner = 1
			return
		end
	end

	saved.phase1End = CurTime() + MODE.Config.SurvivalTime
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then continue end
		if ply == saved.maniac then
			GiveManiacLoadout(ply)
		else
			GiveSurvivorLoadout(ply)
		end
	end

	BroadcastPhase(1, saved.phase1End)
	for _, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR and ply:Alive() then SendRoleState(ply) end
	end
	PrintMessage(HUD_PRINTTALK, "[电锯杀人魔] 杀人魔: " .. saved.maniac:Nick() .. " — 幸存者需存活 " .. math.floor(MODE.Config.SurvivalTime / 60) .. " 分钟！")
end

-- Mode hooks registered via the loader run BEFORE GM:PlayerSpawn finishes,
-- so re-validate on a short delay instead of arming the player immediately.
function MODE:PlayerSpawn(ply)
	timer.Simple(0.25, function()
		if not IsValid(ply) or not ply:Alive() then return end

		local saved = MODE.saved or {}
		if not saved.phase or saved.phase ~= 1 or saved.winner then return end
		if ply:Team() == TEAM_SPECTATOR then return end

		if IsValid(saved.maniac) and ply == saved.maniac then
			GiveManiacLoadout(ply)
		else
			GiveSurvivorLoadout(ply)
		end
	end)
end

function MODE:RoundThink()
	local saved = MODE.saved or {}
	MODE.saved = saved
	saved.phase1End = saved.phase1End or math.huge
	if saved.winner then return end
	if IsValid(saved.maniac) and saved.maniac:Alive()
		and CurTime() >= (saved.maniacRepairAt or 0)
		and not (HasWeapon(saved.maniac, "weapon_chainsaw_maniac") or HasWeapon(saved.maniac, "weapon_melee") or HasWeapon(saved.maniac, "weapon_hg_axe") or HasWeapon(saved.maniac, "weapon_hatchet")) then
		-- Late PlayerSpawn/inventory hooks can strip weapons after the initial
		-- grant.  Repair the maniac's melee slot on the next server tick.
		saved.maniacRepairAt = CurTime() + 1
		GiveManiacLoadout(saved.maniac)
	end

	if CurTime() >= saved.phase1End then
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[电锯杀人魔] 时间耗尽，幸存者获胜！")
		return
	end

	if not IsValid(saved.maniac) or not saved.maniac:Alive() then
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[电锯杀人魔] 杀人魔已被击杀，幸存者获胜！")
		return
	end

	if #AlivePlayersOnTeam(1) == 0 then
		saved.winner = 0
		PrintMessage(HUD_PRINTTALK, "[电锯杀人魔] 幸存者全灭，杀人魔获胜！")
		return
	end
end

function MODE:ShouldRoundEnd()
	local saved = MODE.saved or {}
	MODE.saved = saved
	if saved.winner then return true end
	return false
end

local function TryManiacRoar(ply)
	if CurTime() < (ply:GetNWFloat("Maniac_RoarCooldown", 0)) then return false end
	ply:SetNWFloat("Maniac_RoarCooldown", CurTime() + MODE.Config.RoarCooldown)

	net.Start("chainsaw_roar")
		net.WriteEntity(ply)
	net.Broadcast()

	for _, vic in ipairs(AlivePlayersOnTeam(1)) do
		if vic:GetPos():Distance(ply:GetPos()) <= 800 then
			vic:SetNWFloat("Maniac_FearEnd", CurTime() + 3)
			vic:SetWalkSpeed(vic:GetWalkSpeed() * 0.5)
			vic:SetRunSpeed(vic:GetRunSpeed() * 0.5)
			timer.Simple(3, function()
				if IsValid(vic) then
					vic:SetWalkSpeed(200)
					vic:SetRunSpeed(350)
				end
			end)
		end
	end

	ply:EmitSound("npc/stalker/go_alert2a.wav", 100, 70)
	return true
end

local function TryManiacCharge(ply)
	if CurTime() < (ply:GetNWFloat("Maniac_ChargeCooldown", 0)) then return false end
	ply:SetNWFloat("Maniac_ChargeCooldown", CurTime() + MODE.Config.ChargeCooldown)

	net.Start("chainsaw_charge")
		net.WriteEntity(ply)
	net.Broadcast()

	local oldWS = ply:GetWalkSpeed()
	local oldRS = ply:GetRunSpeed()
	ply:SetWalkSpeed(oldWS * 2.5)
	ply:SetRunSpeed(oldRS * 2.5)
	ply:SetNWBool("Maniac_Charging", true)

	timer.Simple(5, function()
		if IsValid(ply) then
			ply:SetWalkSpeed(oldWS)
			ply:SetRunSpeed(oldRS)
			ply:SetNWBool("Maniac_Charging", false)
		end
	end)

	ply:EmitSound("npc/stalker/go_alert2a.wav", 100, 100)
	return true
end

function MODE:PlayerDeath(victim, inflictor, attacker)
	local saved = MODE.saved
	if saved.winner then return end

	if victim == saved.maniac then
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[电锯杀人魔] 杀人魔已被击杀，幸存者获胜！")
		return
	end

	if attacker == saved.maniac and IsValid(attacker) then
		local rageEnd = CurTime() + MODE.Config.RageDuration
		attacker:SetNWFloat("Maniac_RageEnd", rageEnd)
		attacker:SetWalkSpeed(attacker:GetWalkSpeed() * MODE.Config.RageSpeedMul)
		attacker:SetRunSpeed(attacker:GetRunSpeed() * MODE.Config.RageSpeedMul)

		timer.Simple(MODE.Config.RageDuration, function()
			if IsValid(attacker) then
				attacker:SetWalkSpeed(200 * MODE.Config.ManiacSpeedMul)
				attacker:SetRunSpeed(350 * MODE.Config.ManiacSpeedMul)
			end
		end)

		PrintMessage(HUD_PRINTTALK, "[电锯杀人魔] 杀人魔进入狂暴状态！")
	end

	if saved.deathTimes then
		saved.deathTimes[victim] = CurTime()
	end
end

function MODE:PlayerDisconnected(ply)
	local saved = MODE.saved
	if saved.winner then return end
	if ply ~= saved.maniac then return end

	local survivors = AlivePlayersOnTeam(1)
	if #survivors == 0 then
		saved.winner = 0
	else
		saved.winner = 1
		PrintMessage(HUD_PRINTTALK, "[电锯杀人魔] 杀人魔已离开，幸存者获胜！")
	end
end

function MODE:KeyPress(ply, key)
	local saved = MODE.saved
	if not saved or ply ~= saved.maniac or not IsValid(ply) or not ply:Alive() then return end

	if key == IN_GRENADE1 then
		TryManiacRoar(ply)
	elseif key == IN_GRENADE2 then
		TryManiacCharge(ply)
	end
end

function MODE:EndRound()
	local saved = MODE.saved
	local winner = saved.winner or 1
	local maniac = IsValid(saved.maniac) and saved.maniac or NULL

	timer.Simple(2, function()
		net.Start("chainsaw_roundend")
			net.WriteInt(winner, 8)
			net.WriteEntity(maniac)
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
	local saved = MODE.saved
	if not saved or not saved.phase or saved.phase ~= 1 then return end
	if not IsValid(saved.maniac) then return end

	net.Start("chainsaw_phase")
		net.WriteInt(saved.phase, 4)
		net.WriteFloat(saved.phase1End)
	net.Send(ply)
	SendRoleState(ply)
end

function MODE:GetTeamSpawn()
	return SafeVecs("HMCD_TDM_T"), SafeVecs("HMCD_TDM_CT")
end

hook.Add("EntityTakeDamage", "Maniac_NoPush", function(target, dmg)
	local round = CurrentRound and CurrentRound()
	if not round or round.name ~= MODE.name then return end
	if not IsValid(target) then return end
	if target:GetNWBool("Maniac_NoPush", false) then
		dmg:SetDamageForce(vector_origin)
	end
end)

hook.Add("Think", "Maniac_MeleeOverride", function()
	local round = CurrentRound and CurrentRound()
	if not round or round.name ~= MODE.name then return end

	for _, ply in ipairs(AlivePlayersOnTeam(0)) do
		if not IsValid(ply) or not ply:Alive() then continue end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then continue end
		if not wep.ismelee and wep:GetClass() ~= "weapon_melee" then continue end
		local rageMul = CurTime() < ply:GetNWFloat("Maniac_RageEnd", 0) and MODE.Config.RageDamageMul or 1
		-- weapon_melee and its derived weapons use DamagePrimary/AttackLen;
		-- changing only Primary.Damage (the old code) had no gameplay effect.
		wep.DamagePrimary = MODE.Config.ManiacDamage * rageMul
		wep.DamageSecondary = math.max(1, MODE.Config.ManiacDamage * 0.25 * rageMul)
		wep.AttackLen1 = MODE.Config.ManiacRange
		wep.AttackLen2 = math.max(40, MODE.Config.ManiacRange * 0.6)
		wep.Primary.Damage = wep.DamagePrimary
		wep.Primary.Range = MODE.Config.ManiacRange
		wep.Primary.Delay = MODE.Config.ManiacAttackDelay
		wep.Secondary.Damage = wep.DamageSecondary
		wep.ManiacModified = true

		if SERVER then
			wep:SetNextPrimaryFire(CurTime() + 0.1)
		end
	end
end)

return MODE
