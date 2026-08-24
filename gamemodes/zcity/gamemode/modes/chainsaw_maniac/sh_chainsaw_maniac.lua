local MODE = MODE

MODE.name = "chainsaw_maniac"
MODE.PrintName = "电锯杀人魔"

MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.ForBigMaps = false
MODE.Chance = 0.03

MODE.ROUND_TIME = 600
MODE.start_time = 10
MODE.end_time = 8

MODE.Config = {
	SurvivalTime = 600,
	ManiacHealth = 3000,
	ManiacSpeedMul = 1.3,
	ManiacDamage = 120,
	ManiacRange = 120,
	ManiacAttackDelay = 1.0,
	RoarCooldown = 30,
	ChargeCooldown = 40,
	RageDuration = 5,
	RageSpeedMul = 1.2,
	RageDamageMul = 1.3,
	MinPlayers = 4
}

MODE.RoleNames = {
	maniac = "电锯杀人魔",
	survivor = "幸存者"
}

zb.Points.CHAINSAW_MANIAC = zb.Points.CHAINSAW_MANIAC or {}
zb.Points.CHAINSAW_MANIAC.Color = Color(180, 0, 0)
zb.Points.CHAINSAW_MANIAC.Name = "杀人魔出生点"

zb.Points.SURVIVOR_SPAWN = zb.Points.SURVIVOR_SPAWN or {}
zb.Points.SURVIVOR_SPAWN.Color = Color(0, 150, 200)
zb.Points.SURVIVOR_SPAWN.Name = "幸存者出生点"

MODE.ManiacLoadout = {
	melee = "weapon_chainsaw_maniac",
	armor = {"ent_armor_vest4", "ent_armor_helmet1"},
}

MODE.SurvivorLoadout = {
	melee = "weapon_melee",
	armor = {"ent_armor_vest2", "ent_armor_helmet2"},
	meds = {"weapon_medkit_sh", "weapon_tourniquet"},
	flashbang = "weapon_hg_flashbang_tpik",
	flashlight = "weapon_hg_motiontracker",
}

function MODE.GetRole(ply)
	if not ply or not IsValid(ply) or ply == Entity(0) then return "none" end
	local ok, result = pcall(function() return ply:GetNWVar("ManiacRole", "none") end)
	if ok then return result else return "none" end
end

function MODE.GetRoleName(role)
	local names = {
		maniac = "电锯杀人魔",
		survivor = "幸存者",
	}
	return names[role] or "观察者"
end
