MODE.name = "gwars"
MODE.PrintName = "维德私人俱乐部 VS 第聂伯河帮"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 600

MODE.Chance = 0.02

MODE.GracePeriod = 5

MODE.OverideSpawnPos = true
MODE.LootSpawn = false

function MODE:CanLaunch()
	return true
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

util.AddNetworkString("gwars_start")
util.AddNetworkString("gwars_nationalguard")
function MODE:Intermission()
	game.CleanUpMap()

	self.VIDEPoints = {}
	table.CopyFromTo(zb.GetMapPoints("VIDE_CLUB"), self.VIDEPoints)
	self.DNIEPERPoints = {}
	table.CopyFromTo(zb.GetMapPoints("DNIEPER_GANG"), self.DNIEPERPoints)
	self.NGPoints = {}
	table.CopyFromTo(zb.GetMapPoints("NATIONAL_GUARD"), self.NGPoints)

	for _, ply in player.Iterator() do
		ply:SetupTeam(ply:Team())
	end

	net.Start("gwars_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local alive = self:CheckAlivePlayers()
	local videAlive = #(alive[0] or {}) > 0
	local dnieperAlive = #(alive[1] or {}) > 0
	local ngAlive = #(alive[2] or {}) > 0

	if ngAlive and not videAlive and not dnieperAlive then
		return true, 2
	end
	if videAlive and not dnieperAlive and not ngAlive then
		return true, 0
	end
	if dnieperAlive and not videAlive and not ngAlive then
		return true, 1
	end

	local endround, winner = zb:CheckWinner(alive)
	if endround then
		return true, winner
	end

	return false
end

function MODE:BoringRoundFunction()
	timer.Simple(2, function()
		PrintMessage(HUD_PRINTTALK, "国防军清理完毕，行动结束。")
	end)
end

local nationalGuardDeployed = false

function MODE:RoundStart()
	nationalGuardDeployed = false
end

local videWeapons = {
	"weapon_ar15",
	"weapon_m4a1",
	"weapon_hk416",
	"weapon_sr25",
	"weapon_svd",
	"weapon_sg552",
}

local dnieperWeapons = {
	"weapon_akm",
	"weapon_ak74",
	"weapon_ak74u",
	"weapon_remington870",
	"weapon_saiga12",
	"weapon_m590a1",
	"weapon_doublebarrel_short",
	"weapon_ppsh41",
}

local ngWeapons = {
	"weapon_ar15",
	"weapon_hk416",
	"weapon_m4a1",
	"weapon_scar",
	"weapon_aug",
	"weapon_sg552",
}

local videArmor = {
	{"ent_armor_vest4", "ent_armor_helmet1"},
	{"ent_armor_vest4", "ent_armor_helmet3"},
}

local dnieperArmor = {
	{"ent_armor_vest2", "ent_armor_helmet2"},
	{"ent_armor_vest3", "ent_armor_helmet2"},
}

local ngArmor = {
	{"ent_armor_vest4", "ent_armor_helmet1"},
	{"ent_armor_vest4", "ent_armor_helmet4"},
}

local ngExtras = {
	"weapon_medkit_sh",
	"weapon_tourniquet",
	"weapon_hg_flashbang_tpik",
	"weapon_hg_smokenade_tpik",
	"weapon_walkie_talkie",
	"weapon_hands_sh",
}

function MODE:GiveEquipment()
	self.VIDEPoints = {}
	table.CopyFromTo(zb.GetMapPoints("VIDE_CLUB"), self.VIDEPoints)
	self.DNIEPERPoints = {}
	table.CopyFromTo(zb.GetMapPoints("DNIEPER_GANG"), self.DNIEPERPoints)
	self.NGPoints = {}
	table.CopyFromTo(zb.GetMapPoints("NATIONAL_GUARD"), self.NGPoints)

	timer.Simple(0.1, function()
		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 0 then
				ply:SetPlayerClass("bloodz")
				zb.GiveRole(ply, "维德私人俱乐部", Color(180, 120, 0))
				ply:SetNetVar("CurPluv", "pluvred")

				local wep = ply:Give(videWeapons[math.random(#videWeapons)])
				ply:GiveAmmo(wep:GetMaxClip1() * 3, wep:GetPrimaryAmmoType())
				hg.AddArmor(ply, videArmor[math.random(#videArmor)])
				ply:Give("weapon_medkit_sh")
				ply:Give("weapon_tourniquet")
				ply:Give("weapon_fentanyl")

			else
				ply:SetPlayerClass("groove")
				zb.GiveRole(ply, "第聂伯河帮", Color(0, 150, 200))
				ply:SetNetVar("CurPluv", "pluvgreen")

				local wep = ply:Give(dnieperWeapons[math.random(#dnieperWeapons)])
				ply:GiveAmmo(wep:GetMaxClip1() * 3, wep:GetPrimaryAmmoType())
				hg.AddArmor(ply, dnieperArmor[math.random(#dnieperArmor)])
				ply:Give("weapon_bandage_sh")
				ply:Give("weapon_tourniquet")
				ply:Give("weapon_adrenaline")
			end

			local hands = ply:Give("weapon_hands_sh")
			ply:SelectWeapon("weapon_hands_sh")

			timer.Simple(0.1, function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
	if nationalGuardDeployed then return end

	if CurTime() - (zb.ROUND_BEGIN or CurTime()) >= 180 then
		nationalGuardDeployed = true

		local deadPlayers = {}
		for _, ply in player.Iterator() do
			if not ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
				table.insert(deadPlayers, ply)
			end
		end

		if #deadPlayers == 0 then return end

		table.Shuffle(deadPlayers)
		local count = math.min(6, #deadPlayers)

		local spawnPos = self.NGPoints and #self.NGPoints > 0 and self.NGPoints[1].pos
			or self.TPoints and #self.TPoints > 0 and self.TPoints[1].pos
			or zb:GetRandomSpawn()

		net.Start("gwars_nationalguard")
		net.Broadcast()

		for i = 1, count do
			local ply = deadPlayers[i]

			ply:Spawn()
			ply:SetTeam(2)

			if not spawnPos then
				spawnPos = ply:GetPos()
			else
				hg.tpPlayer(spawnPos, ply, i, 0)
			end

			ply:SetPlayerClass("swat")
			zb.GiveRole(ply, "国防军", Color(40, 40, 120))

			local gun = ply:Give(ngWeapons[math.random(#ngWeapons)])
			ply:GiveAmmo(gun:GetMaxClip1() * 4, gun:GetPrimaryAmmoType(), true)

			hg.AddArmor(ply, ngArmor[math.random(#ngArmor)])

			for _, extra in ipairs(ngExtras) do
				ply:Give(extra)
			end

			local hands = ply:Give("weapon_hands_sh")
			ply:SelectWeapon("weapon_hands_sh")
		end

		PrintMessage(HUD_PRINTTALK, "[国防军] 国防军介入！清除所有敌对武装力量！")
	end
end

function MODE:GetTeamSpawn()
	local videVecs = zb.TranslatePointsToVectors(zb.GetMapPoints("VIDE_CLUB"))
	local dnieperVecs = zb.TranslatePointsToVectors(zb.GetMapPoints("DNIEPER_GANG"))

	if #videVecs == 0 then
		videVecs = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T"))
	end
	if #dnieperVecs == 0 then
		dnieperVecs = zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
	end

	return videVecs, dnieperVecs
end

util.AddNetworkString("gwars_roundend")
function MODE:EndRound()
	timer.Simple(2, function()
		net.Start("gwars_roundend")
		net.Broadcast()
	end)

	local alive = self:CheckAlivePlayers()
	local videAlive = #(alive[0] or {}) > 0
	local dnieperAlive = #(alive[1] or {}) > 0
	local ngAlive = #(alive[2] or {}) > 0

	local winner = 3
	if ngAlive and not videAlive and not dnieperAlive then winner = 2
	elseif videAlive and not dnieperAlive and not ngAlive then winner = 0
	elseif dnieperAlive and not videAlive and not ngAlive then winner = 1
	end

	for _, ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(50, 80))
			ply:GiveSkill(math.Rand(0.15, 0.25))
		else
			ply:GiveSkill(-math.Rand(0.05, 0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
end

return MODE