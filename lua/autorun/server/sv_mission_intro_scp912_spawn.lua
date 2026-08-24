-- SCP-912：分批发放特供武器，勿与 EnforceFacilityScpWeaponWhitelist 同时 Give（会卡死）
if not SERVER then return end

MissionIntro = MissionIntro or {}

-- 等 homigrad player_spawn / SCP 特质 timer 跑完再发枪
local SCP912_DELAYED_WEAPONS = {
	{ delay = 1.0, class = "weapon_m4a1_scp912" },
	{ delay = 1.8, class = "weapon_deagle_scp912" },
	{ delay = 2.6, class = "weapon_sogknife_scp912" },
}

local function MI_StripScp912Weapons(ply)
	if not IsValid(ply) then return end
	for _, className in ipairs(MissionIntro.Scp912WeaponClasses or {}) do
		if ply:HasWeapon(className) then
			ply:StripWeapon(className)
		end
	end
end

local function MI_Scp912NeedsWeaponLoadout(ply)
	for _, step in ipairs(SCP912_DELAYED_WEAPONS) do
		if not ply:HasWeapon(step.class) then
			return true
		end
	end
	return false
end

local function MI_ShouldGiveScp912WeaponLoadout(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
	if ply._miScp912LoadoutBlocked then return false end

	if MissionIntro.ShouldEnforceFacilityScpWeaponRules then
		if not MissionIntro.ShouldEnforceFacilityScpWeaponRules(ply) then return false end
	elseif MissionIntro.IsFacilityScpContextValidForPlayer then
		if not MissionIntro.IsFacilityScpContextValidForPlayer(ply) then return false end
	end

	if not MissionIntro.IsFacilityScp912Player or not MissionIntro.IsFacilityScp912Player(ply) then
		return false
	end

	if MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive() then
		local roleKey = MissionIntro.RXSendGetPlayerRoleKey and MissionIntro.RXSendGetPlayerRoleKey(ply) or ""
		if roleKey ~= "" and roleKey ~= "scp_912" then
			return false
		end
	end

	return true
end

function MissionIntro.CancelScp912WeaponLoadout(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	ply._miScp912LoadoutGen = (ply._miScp912LoadoutGen or 0) + 1
	ply._miScp912DelayedWeaponsScheduled = nil
	ply._miScp912WeaponsReady = nil
end

function MissionIntro.BlockScp912WeaponLoadout(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	ply._miScp912LoadoutBlocked = true
	MissionIntro.CancelScp912WeaponLoadout(ply)
	MI_StripScp912Weapons(ply)
end

function MissionIntro.ScheduleScp912WeaponLoadout(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not MI_ShouldGiveScp912WeaponLoadout(ply) then return end
	if ply._miScp912DelayedWeaponsScheduled then return end

	ply._miScp912LoadoutBlocked = nil
	ply._miScp912DelayedWeaponsScheduled = true
	local loadoutGen = (ply._miScp912LoadoutGen or 0)

	for _, step in ipairs(SCP912_DELAYED_WEAPONS) do
		timer.Simple(step.delay, function()
			if not IsValid(ply) or not ply:Alive() then return end
			if ply._miScp912LoadoutBlocked then return end
			if (ply._miScp912LoadoutGen or 0) ~= loadoutGen then return end
			if not MI_ShouldGiveScp912WeaponLoadout(ply) then return end
			if ply:HasWeapon(step.class) then return end

			ply._missionIntroAllowWeaponGive = true
			local wep
			if MissionIntro.GivePlayerWeapon then
				wep = MissionIntro.GivePlayerWeapon(ply, step.class)
			else
				wep = ply:Give(step.class)
			end
			ply._missionIntroAllowWeaponGive = nil

			if IsValid(wep) and MissionIntro.AuthorizeScp912Weapon then
				MissionIntro.AuthorizeScp912Weapon(wep, ply)
			end
			if MissionIntro.ApplyFacilityScpWeaponNoDrop then
				MissionIntro.ApplyFacilityScpWeaponNoDrop(ply)
			end
		end)
	end

	timer.Simple(SCP912_DELAYED_WEAPONS[#SCP912_DELAYED_WEAPONS].delay + 0.5, function()
		if not IsValid(ply) or ply._miScp912LoadoutBlocked then return end
		if (ply._miScp912LoadoutGen or 0) ~= loadoutGen then return end
		if not MI_ShouldGiveScp912WeaponLoadout(ply) then return end
		ply._miScp912WeaponsReady = true
	end)
end

hook.Add("MissionIntro_GiveRewards", "MissionIntro_Scp912StaggerWeapons", function(ply)
	if not MissionIntro.IsFacilityScp912Player or not MissionIntro.IsFacilityScp912Player(ply) then return end
	-- 新一轮正式入场：解除上一命死亡封锁
	ply._miScp912LoadoutBlocked = nil
	if not MI_ShouldGiveScp912WeaponLoadout(ply) then return end
	MissionIntro.ScheduleScp912WeaponLoadout(ply)
end)

-- 仅在同一条命内 homigrad 清枪后补发；死亡后 _miScp912LoadoutBlocked 阻止重发
hook.Add("PlayerSpawn", "MissionIntro_Scp912StaggerWeapons", function(ply)
	if MissionIntro.ShouldRunHeavyPlayerSpawnHooks and not MissionIntro.ShouldRunHeavyPlayerSpawnHooks(ply) then
		return
	end
	timer.Simple(0.2, function()
		if not IsValid(ply) or not ply:Alive() then return end

		if ply._miScp912LoadoutBlocked or not MI_ShouldGiveScp912WeaponLoadout(ply) then
			if ply._miScp912LoadoutBlocked then
				MissionIntro.CancelScp912WeaponLoadout(ply)
				MI_StripScp912Weapons(ply)
			end
			return
		end

		if not MissionIntro.HasGivenIntroReward or not MissionIntro.HasGivenIntroReward(ply) then return end
		if not MI_Scp912NeedsWeaponLoadout(ply) then return end
		if ply._miScp912DelayedWeaponsScheduled then return end

		MissionIntro.ScheduleScp912WeaponLoadout(ply)
	end)
end)

hook.Add("PlayerSpawn", "MissionIntro_Scp912ClearLoadoutBlock", function(ply)
	if not IsValid(ply) then return end
	if ply._miScp912LoadoutBlocked then
		MissionIntro.CancelScp912WeaponLoadout(ply)
		MI_StripScp912Weapons(ply)
	end
end)
