-- SCP-912 特供武器：禁止地上拾取，携带者死亡时移除（服务端）
if not SERVER then return end

MissionIntro = MissionIntro or {}

local SCP912_CLASSES = MissionIntro.Scp912WeaponClasses or {
	"weapon_deagle_scp912",
	"weapon_m4a1_scp912",
	"weapon_sogknife_scp912",
}

local SCP912_LOOKUP = {}
for _, className in ipairs(SCP912_CLASSES) do
	SCP912_LOOKUP[className] = true
end

if not isfunction(MissionIntro.IsScp912WeaponClass) then
	function MissionIntro.IsScp912WeaponClass(className)
		return isstring(className) and SCP912_LOOKUP[className] == true
	end
end

if not isfunction(MissionIntro.IsScp912Weapon) then
	function MissionIntro.IsScp912Weapon(ent)
		return IsValid(ent) and ent:IsWeapon() and MissionIntro.IsScp912WeaponClass(ent:GetClass())
	end
end

function MissionIntro.AuthorizeScp912Weapon(wep, ply)
	if not MissionIntro.IsScp912Weapon(wep) or not IsValid(ply) then return end
	wep.NoLoot = true
	wep.NoDrop = true
	wep.bigNoDrop = true
	wep.init = nil
	wep.dontPickup = nil
	wep.IsSpawned = false
	wep._miScp912Authorized = ply
end

function MissionIntro.IsScp912GroundLoot(wep)
	if not MissionIntro.IsScp912Weapon(wep) then return false end
	if IsValid(wep:GetOwner()) and wep:GetOwner():IsPlayer() then return false end
	if IsValid(wep._miScp912Authorized) then return false end
	return wep.init == true or wep.IsSpawned == true or wep._miScp912LastOwner ~= nil
end

local function MI_MarkScp912GroundOnly(wep)
	if not MissionIntro.IsScp912Weapon(wep) then return end
	wep.NoLoot = true
	wep.NoDrop = true
	wep.bigNoDrop = true
	wep.dontPickup = true
	wep.init = true
	wep.IsSpawned = true
	wep._miScp912Authorized = nil
end

local function MI_RemoveScp912FromInventory(ply)
	if not IsValid(ply) then return end

	for _, className in ipairs(MissionIntro.Scp912WeaponClasses) do
		if ply:HasWeapon(className) then
			ply:StripWeapon(className)
		end
	end

	if hg and hg.weaponInv and istable(ply.weaponInv) then
		for _, slot in pairs(ply.weaponInv) do
			if istable(slot) then
				for i = #slot, 1, -1 do
					local wep = slot[i]
					if MissionIntro.IsScp912Weapon(wep) then
						if IsValid(wep) then
							wep:Remove()
						end
						table.remove(slot, i)
					end
				end
			end
		end
		if isfunction(hg.weaponInv.Sync) then
			hg.weaponInv.Sync(ply)
		end
	end
end

local function MI_RemoveScp912DroppedBy(ply)
	if not IsValid(ply) then return end
	for _, ent in ipairs(ents.GetAll()) do
		if MissionIntro.IsScp912Weapon(ent) and ent._miScp912LastOwner == ply then
			ent:Remove()
		end
	end
end

if isfunction(MissionIntro.GivePlayerWeapon) and not MissionIntro._miScp912GiveWrapped then
	local origGivePlayerWeapon = MissionIntro.GivePlayerWeapon
	MissionIntro._miScp912GiveWrapped = true
	function MissionIntro.GivePlayerWeapon(ply, className)
		local wep = origGivePlayerWeapon(ply, className)
		if IsValid(wep) and MissionIntro.IsScp912Weapon(wep) then
			MissionIntro.AuthorizeScp912Weapon(wep, ply)
		end
		return wep
	end
end

-- Q 菜单生成：直接给予，不落地
hook.Add("PlayerSpawnSWEP", "MissionIntro_Scp912PlayerSpawnSWEP", function(ply, class)
	if not IsValid(ply) or not MissionIntro.IsScp912WeaponClass(class) then return end
	timer.Simple(0, function()
		if not IsValid(ply) then return end
		if MissionIntro.GivePlayerWeapon then
			MissionIntro.GivePlayerWeapon(ply, class)
		else
			ply._missionIntroAllowWeaponGive = true
			local wep = ply:Give(class)
			ply._missionIntroAllowWeaponGive = nil
			if IsValid(wep) then
				MissionIntro.AuthorizeScp912Weapon(wep, ply)
			end
		end
	end)
	return false
end)

hook.Add("PlayerCanPickupWeapon", "MissionIntro_Scp912NoGroundPickup", function(ply, wep)
	if not MissionIntro.IsScp912GroundLoot(wep) then return end
	if IsValid(ply) and ply._missionIntroAllowWeaponGive then return end
	return false
end, 1000)

hook.Add("WeaponEquip", "MissionIntro_Scp912Equip", function(wep, ply)
	if not MissionIntro.IsScp912Weapon(wep) or not IsValid(ply) or not ply:IsPlayer() then return end
	MissionIntro.AuthorizeScp912Weapon(wep, ply)
end)

hook.Add("PlayerDroppedWeapon", "MissionIntro_Scp912Dropped", function(ply, wep)
	if not MissionIntro.IsScp912Weapon(wep) then return end
	wep._miScp912LastOwner = ply
	MI_MarkScp912GroundOnly(wep)
end)

local function MI_Scp912DeathCleanup(ply)
	if not IsValid(ply) then return end

	ply._miWasScp912Death = ply._miWasScp912Death
		or (MissionIntro.IsFacilityScp912Player and MissionIntro.IsFacilityScp912Player(ply) == true)

	if MissionIntro.BlockScp912WeaponLoadout then
		MissionIntro.BlockScp912WeaponLoadout(ply)
	elseif MissionIntro.CancelScp912WeaponLoadout then
		MissionIntro.CancelScp912WeaponLoadout(ply)
	end

	ply._miKnifeDashSpeedActive = nil
	ply._miKnifePreWalk = nil
	ply._miKnifePreRun = nil
	ply._miKnifePreSlow = nil
	ply._miKnifePreCrouch = nil
	ply:SetNWFloat("MI_KnifeDashBuffEnd", 0)

	if istable(ply.organism) then
		ply.organism.superfighter = false
		ply.organism.needfake = false
		ply.organism.fake = false
	end

	MI_RemoveScp912FromInventory(ply)
	if ply._miWasScp912Death and MissionIntro.RemovePlayerCorpseImmediately then
		MissionIntro.RemovePlayerCorpseImmediately(ply, nil)
	end
	timer.Simple(0, function()
		if IsValid(ply) then
			MI_RemoveScp912DroppedBy(ply)
		end
	end)
end

hook.Add("PlayerDeath", "MissionIntro_Scp912RemoveOnDeath", MI_Scp912DeathCleanup, 100)

hook.Add("PlayerSilentDeath", "MissionIntro_Scp912RemoveOnDeath", MI_Scp912DeathCleanup, 100)

-- 伤害 / 冲刺逻辑集中在此，避免 SWEP 文件重复 hook.Add 导致叠加
local SCP912_M4 = "weapon_m4a1_scp912"
local SCP912_DEAGLE = "weapon_deagle_scp912"
local SCP912_KNIFE = "weapon_sogknife_scp912"
local SCP912_DASH_MOVE_MUL = 1.5

local function MI_Scp912GetVictim(ply, ent)
	if IsValid(ply) and ply:IsPlayer() then return ply end
	if IsValid(ent) and ent:IsPlayer() then return ent end
	if hg and hg.RagdollOwner and IsValid(ent) then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:IsPlayer() then return owner end
	end
	return nil
end

local function MI_Scp912VictimIsScp(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if MissionIntro.PlayerIsFacilityScpForWeapons then
		return MissionIntro.PlayerIsFacilityScpForWeapons(ply) == true
	end
	if MissionIntro.ShouldFacilityScpImmuneZcityDebuffs then
		return MissionIntro.ShouldFacilityScpImmuneZcityDebuffs(ply) == true
	end
	return false
end

local function MI_Scp912IsWeaponDamage(dmgInfo, className)
	if not dmgInfo then return false end
	local inf = dmgInfo:GetInflictor()
	if IsValid(inf) and inf:GetClass() == className then return true end
	local att = dmgInfo:GetAttacker()
	if IsValid(att) and att:IsPlayer() then
		local wep = att:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == className then return true end
	end
	return false
end

local function MI_Scp912ResetHitCounters(ply)
	if not IsValid(ply) then return end
	ply._miM4Scp912Hits = nil
	ply._miDeagleScp912Hits = nil
end

hook.Add("PlayerSpawn", "MissionIntro_Scp912ResetHitCounters", MI_Scp912ResetHitCounters)
hook.Add("PlayerDeath", "MissionIntro_Scp912ResetHitCounters", MI_Scp912ResetHitCounters)

hook.Add("PreHomigradDamage", "MissionIntro_Scp912M4FiveTap", function(ply, dmgInfo, hitgroup, ent)
	if not MI_Scp912IsWeaponDamage(dmgInfo, SCP912_M4) then return end
	if not dmgInfo:IsDamageType(DMG_BULLET) then return end

	local victim = MI_Scp912GetVictim(ply, ent)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if MI_Scp912VictimIsScp(victim) then return end

	victim._miM4Scp912Hits = (victim._miM4Scp912Hits or 0) + 1
	if victim._miM4Scp912Hits >= 5 then
		victim._miM4Scp912Hits = nil
		dmgInfo:SetDamage(9999)
	else
		dmgInfo:SetDamage(math.min(dmgInfo:GetDamage(), 10))
	end
end)

hook.Add("PreHomigradDamage", "MissionIntro_Scp912DeagleFourTap", function(ply, dmgInfo, hitgroup, ent)
	if not MI_Scp912IsWeaponDamage(dmgInfo, SCP912_DEAGLE) then return end
	if not dmgInfo:IsDamageType(DMG_BULLET) then return end

	local victim = MI_Scp912GetVictim(ply, ent)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if MI_Scp912VictimIsScp(victim) then return end

	victim._miDeagleScp912Hits = (victim._miDeagleScp912Hits or 0) + 1
	if victim._miDeagleScp912Hits >= 4 then
		victim._miDeagleScp912Hits = nil
		dmgInfo:SetDamage(9999)
	else
		dmgInfo:SetDamage(math.min(dmgInfo:GetDamage(), 12))
	end
end)

function MI_Scp912ExecuteKill(victim, attacker, wep)
	victim = MI_Scp912GetVictim(victim, victim)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if not victim:Alive() then return end
	if MI_Scp912VictimIsScp(victim) then return end

	local dmg = DamageInfo()
	dmg:SetDamage(99999)
	dmg:SetAttacker(IsValid(attacker) and attacker or victim)
	dmg:SetInflictor(IsValid(wep) and wep or victim)
	dmg:SetDamageType(DMG_SLASH)
	victim:TakeDamageInfo(dmg)

	if victim:Alive() then
		victim:Kill()
	end
end

hook.Add("PreHomigradDamage", "MissionIntro_Scp912KnifeInstantKill", function(ply, dmgInfo, hitgroup, ent)
	if not MI_Scp912IsWeaponDamage(dmgInfo, SCP912_KNIFE) then return end

	local victim = MI_Scp912GetVictim(ply, ent)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if MI_Scp912VictimIsScp(victim) then return end

	dmgInfo:SetDamage(99999)

	local attacker = dmgInfo:GetAttacker()
	local inf = dmgInfo:GetInflictor()
	timer.Simple(0, function()
		if not IsValid(victim) or not victim:Alive() then return end
		MI_Scp912ExecuteKill(victim, attacker, inf)
	end)
end)

local function MI_Scp912CapturePreDashSpeeds(ply)
	if ply._miKnifePreWalk then return end

	if MissionIntro.PlayerNeedsScpMoveSpeedControl and MissionIntro.PlayerNeedsScpMoveSpeedControl(ply) then
		if MissionIntro.ApplyFacilityScpMoveSpeed then
			MissionIntro.ApplyFacilityScpMoveSpeed(ply)
		end
		if MissionIntro.GetFacilityScpMoveSpeeds then
			local walk, run, slow = MissionIntro.GetFacilityScpMoveSpeeds(ply)
			ply._miKnifePreWalk = walk
			ply._miKnifePreRun = run
			ply._miKnifePreSlow = slow
			ply._miKnifePreCrouch = slow
			return
		end
	end

	ply._miKnifePreWalk = ply:GetWalkSpeed()
	ply._miKnifePreRun = ply:GetRunSpeed()
	ply._miKnifePreSlow = ply:GetSlowWalkSpeed()
	ply._miKnifePreCrouch = ply:GetCrouchedWalkSpeed()
end

function MI_SogKnifeApplyDashSpeed(ply)
	if not IsValid(ply) then return end

	MI_Scp912CapturePreDashSpeeds(ply)

	local walk = math.max(1, math.floor((ply._miKnifePreWalk or 100) * SCP912_DASH_MOVE_MUL))
	local run = math.max(1, math.floor((ply._miKnifePreRun or 350) * SCP912_DASH_MOVE_MUL))
	local slow = math.max(1, math.floor((ply._miKnifePreSlow or 60) * SCP912_DASH_MOVE_MUL))
	local crouch = math.max(1, math.floor((ply._miKnifePreCrouch or slow) * SCP912_DASH_MOVE_MUL))

	ply:SetWalkSpeed(walk)
	ply:SetRunSpeed(run)
	ply:SetSlowWalkSpeed(slow)
	ply:SetCrouchedWalkSpeed(crouch)
	ply.CurrentSpeed = run
	ply._miKnifeDashSpeedActive = true
end

local function MI_Scp912SheathKnife(ply)
	if not IsValid(ply) then return end
	for _, wep in ipairs(ply:GetWeapons()) do
		if IsValid(wep) and wep:GetClass() == SCP912_KNIFE and wep.SheathKnife then
			wep:SheathKnife()
		end
	end
end

local function MI_Scp912ClearDashSpeed(ply)
	if not IsValid(ply) then return end
	if CurTime() < ply:GetNWFloat("MI_KnifeDashBuffEnd", 0) then return end

	MI_Scp912SheathKnife(ply)

	if MissionIntro.PlayerNeedsScpMoveSpeedControl and MissionIntro.PlayerNeedsScpMoveSpeedControl(ply) then
		if MissionIntro.ApplyFacilityScpMoveSpeed then
			MissionIntro.ApplyFacilityScpMoveSpeed(ply)
		end
		if MissionIntro.EnforceFacilityScpMoveSpeed then
			MissionIntro.EnforceFacilityScpMoveSpeed(ply)
		end
	else
		ply:SetWalkSpeed(ply._miKnifePreWalk or ply:GetWalkSpeed())
		ply:SetRunSpeed(ply._miKnifePreRun or ply:GetRunSpeed())
		ply:SetSlowWalkSpeed(ply._miKnifePreSlow or ply:GetSlowWalkSpeed())
		ply:SetCrouchedWalkSpeed(ply._miKnifePreCrouch or ply:GetCrouchedWalkSpeed())
		ply.CurrentSpeed = ply:GetWalkSpeed()
	end

	ply._miKnifeDashSpeedActive = nil
	ply._miKnifePreWalk = nil
	ply._miKnifePreRun = nil
	ply._miKnifePreSlow = nil
	ply._miKnifePreCrouch = nil
	ply:SetNWFloat("MI_KnifeDashBuffEnd", 0)
end

hook.Add("Player Think", "MissionIntro_Scp912KnifeDashSpeed", function(ply)
	if not IsValid(ply) or not ply:Alive() then return end

	if CurTime() < ply:GetNWFloat("MI_KnifeDashBuffEnd", 0) then
		MI_SogKnifeApplyDashSpeed(ply)
	elseif ply._miKnifeDashSpeedActive then
		MI_Scp912ClearDashSpeed(ply)
	end
end)

hook.Add("Org Think", "MissionIntro_Scp912KnifeDashSpeedOrg", function(owner)
	if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
	if CurTime() >= owner:GetNWFloat("MI_KnifeDashBuffEnd", 0) then return end
	MI_SogKnifeApplyDashSpeed(owner)
end, 1001)
