local MODE = MODE

MODE.name = "nationalguard"
MODE.PrintName = "国民警卫队行动"

MODE.LootSpawn = false
MODE.GuiltDisabled = false
MODE.ForBigMaps = true
MODE.Chance = 0.02

MODE.GracePeriod = 10

MODE.ROUND_TIME = 900
MODE.start_time = 15
MODE.end_time = 10

MODE.Config = {
	SurvivalTime = 900,
	MinPlayers = 6,
	GuardToRioterRatio = 0.33,
	CommanderEnabled = true,
	CurfewEnabled = true,
	CurfewSpeed = 100,
	MartialLawEnabled = true,
	SupplyDropInterval = 180,
	CommanderOrderCooldown = 20,
	RiotLevelRate = 0.08,
	RiotLevelThreshold = 100,
	ArrestEnabled = true,
	MartialLawThreshold = 75,
}

MODE.RoleNames = {
	commander = "指挥官",
	guardsman = "步枪兵",
	medic = "医疗兵",
	engineer = "工兵",
	marksman = "精确射手",
	rioter = "暴徒",
	agitator = "煽动者",
	saboteur = "破坏者",
	sniper = "狙击手",
}

zb.Points.NG_GUARD_SPAWN = zb.Points.NG_GUARD_SPAWN or {}
zb.Points.NG_GUARD_SPAWN.Color = Color(0, 100, 200)
zb.Points.NG_GUARD_SPAWN.Name = "警卫队出生点"

zb.Points.NG_RIOTER_SPAWN = zb.Points.NG_RIOTER_SPAWN or {}
zb.Points.NG_RIOTER_SPAWN.Color = Color(180, 50, 0)
zb.Points.NG_RIOTER_SPAWN.Name = "暴徒出生点"

zb.Points.NG_CHECKPOINT = zb.Points.NG_CHECKPOINT or {}
zb.Points.NG_CHECKPOINT.Color = Color(0, 200, 100)
zb.Points.NG_CHECKPOINT.Name = "检查站"

zb.Points.NG_SUPPLY_DROP = zb.Points.NG_SUPPLY_DROP or {}
zb.Points.NG_SUPPLY_DROP.Color = Color(255, 200, 0)
zb.Points.NG_SUPPLY_DROP.Name = "空投点"

zb.Points.NG_OBJECTIVE = zb.Points.NG_OBJECTIVE or {}
zb.Points.NG_OBJECTIVE.Color = Color(200, 0, 200)
zb.Points.NG_OBJECTIVE.Name = "战略目标"

MODE.GuardLoadouts = {
	commander = {
		primary = "weapon_m16a2manohota",
		secondary = "weapon_m1911",
		melee = "weapon_sogknife",
		armor = {"ent_armor_vest4", "ent_armor_helmet1"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_walkie_talkie", "weapon_hg_motiontracker"},
	},
	guardsman = {
		primary = "weapon_m16a2manohota",
		secondary = "weapon_p22",
		melee = "weapon_sogknife",
		armor = {"ent_armor_vest3", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_hg_tonfa", "weapon_handcuffs", "weapon_handcuffs_key", "weapon_hg_flashbang_tpik", "weapon_walkie_talkie"},
	},
	medic = {
		primary = "weapon_mp5",
		secondary = "weapon_p22",
		melee = "weapon_sogknife",
		armor = {"ent_armor_vest3", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_medkit_sh", "weapon_tourniquet", "weapon_bloodbag", "weapon_walkie_talkie"},
	},
	engineer = {
		primary = "weapon_m4a1",
		secondary = "weapon_p22",
		melee = "weapon_sogknife",
		armor = {"ent_armor_vest3", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_hg_pipebomb_tpik", "weapon_hg_molotov_tpik", "weapon_hammer", "weapon_walkie_talkie"},
	},
	marksman = {
		primary = "weapon_m14",
		secondary = "weapon_p22",
		melee = "weapon_sogknife",
		armor = {"ent_armor_vest3", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_walkie_talkie"},
	},
}

MODE.RioterLoadouts = {
	rioter = {
		primary = "weapon_akm",
		secondary = "weapon_makarov",
		melee = "weapon_hatchet",
		armor = {"ent_armor_vest2", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_hg_molotov_tpik", "weapon_hg_pipebomb_tpik", "weapon_hg_flashbang_tpik"},
	},
	agitator = {
		primary = "weapon_akm",
		secondary = "weapon_makarov",
		melee = "weapon_hatchet",
		armor = {"ent_armor_vest2", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_hg_molotov_tpik", "weapon_hg_smokenade_tpik", "weapon_walkie_talkie"},
	},
	saboteur = {
		primary = "weapon_ak74u",
		secondary = "weapon_makarov",
		melee = "weapon_hatchet",
		armor = {"ent_armor_vest2", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_hg_pipebomb_tpik", "weapon_breachcharge", "weapon_hg_grenade_tpik"},
	},
	sniper = {
		primary = "weapon_svd",
		secondary = "weapon_makarov",
		melee = "weapon_hatchet",
		armor = {"ent_armor_vest2", "ent_armor_helmet2"},
		ammo = 3,
		ammo2 = 2,
		special = {"weapon_hg_smokenade_tpik", "weapon_hg_motiontracker"},
	},
}

-- Everyone receives only a basic bandage; the medic keeps the full medical
-- kit in its profession-specific special list so roles do not overlap.
MODE.Medicine = {"weapon_bandage_sh"}

function MODE.GetRole(ply)
	if not ply or not IsValid(ply) or ply == Entity(0) then return "none" end
	local ok, result = pcall(function() return ply:GetNetVar("NGRole", "none") end)
	if ok then return result else return "none" end
end

function MODE.GetRoleName(role)
	local names = {
		commander = "指挥官",
		guardsman = "步枪兵",
		medic = "医疗兵",
		engineer = "工兵",
		marksman = "精确射手",
		rioter = "暴徒",
		agitator = "煽动者",
		saboteur = "破坏者",
		sniper = "狙击手",
	}
	return names[role] or "观察者"
end

function MODE.GetTeamName(team)
	return team == 1 and "国民警卫队" or "叛乱分子"
end

function MODE.GetTeamColor(team)
	return team == 1 and Color(0, 100, 200) or Color(180, 50, 0)
end
