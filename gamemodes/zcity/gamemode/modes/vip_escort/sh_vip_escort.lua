local MODE = MODE

MODE.name = "vipescort"
MODE.PrintName = "VIP Escort"

MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.ForBigMaps = false
MODE.Chance = 0.05

MODE.ROUND_TIME = 1020
MODE.start_time = 10
MODE.end_time = 8

MODE.Config = {
	SurvivalTime = 720,
	ExtractTime = 300,
	ExtractRadius = 300,
	ExtractHold = 3,
	MinPlayers = 6,
	OfficerCount = 1,
	RespawnInterval = 500,
	RespawnCount = 3,
	RespawnDelay = 20
}

MODE.RoleNames = {
	vip = "VIP 目标",
	guard = "德军护卫",
	guard_officer = "德军军官",
	assassin = "苏军刺客",
	assassin_officer = "苏军军官"
}

zb.Points.VIP_EXTRACT = zb.Points.VIP_EXTRACT or {}
zb.Points.VIP_EXTRACT.Color = Color(255, 215, 0)
zb.Points.VIP_EXTRACT.Name = "VIP Extract"

MODE.Loadouts = {
	guard_soldier = {
		primary = "weapon_kar98",
		secondary = "weapon_hk_usp",
		melee = "weapon_melee",
		armor = {"ent_armor_helmet1", "ent_armor_vest4"},
		ammo = 3,
		ammo2 = 2
	},
	guard_officer = {
		primary = "weapon_kar98",
		secondary = "weapon_hk_usp",
		melee = "weapon_melee",
		armor = {"ent_armor_helmet1", "ent_armor_vest4"},
		ammo = 3,
		ammo2 = 2
	},
	assassin_soldier = {
		primary = "weapon_mosin",
		melee = "weapon_melee",
		armor = {"ent_armor_helmet7", "ent_armor_vest4"},
		ammo = 3
	},
	assassin_officer = {
		primary = "weapon_mosin",
		secondary = "weapon_glock17",
		melee = "weapon_melee",
		armor = {"ent_armor_helmet7", "ent_armor_vest4"},
		ammo = 3,
		ammo2 = 2
	},
	vip = {
		primary = "weapon_kar98",
		secondary = "weapon_hk_usp",
		melee = "weapon_melee",
		armor = {"ent_armor_helmet1", "ent_armor_vest3"},
		ammo = 3,
		ammo2 = 2
	}
}

MODE.Medicine = {"weapon_medkit_sh", "weapon_tourniquet"}

function MODE.GetRole(ply)
	if not ply or not IsValid(ply) or ply == Entity(0) then return "none" end
	local ok, result = pcall(function() return ply:GetNWVar("VIPRole", "none") end)
	if ok then return result else return "none" end
end

function MODE.GetRoleName(role)
	return MODE.RoleNames[role] or "观察者"
end
