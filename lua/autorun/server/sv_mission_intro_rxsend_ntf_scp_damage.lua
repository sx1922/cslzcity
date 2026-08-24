-- RXsend：九尾狐 P90 — 对人类 45/发，对 SCP 100/发
-- Homigrad 弹药表会覆盖 SWEP.Primary.Damage；且 FacilityScpBlastMitigation（-20）会把有甲 SCP 压到 25。
-- 本 hook 必须用 priority < -20（如 -25）在减伤之后执行，否则 110/100 都不会生效。
if not SERVER then return end

MissionIntro = MissionIntro or {}

local NTF_P90 = "weapon_p90_ntf"
local NTF_P90_DAMAGE = 45
local NTF_SCP_DAMAGE = 100

local function MI_RxActive()
	return MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive()
end

function MissionIntro.IsNtfP90BulletDamage(dmgInfo)
	if not dmgInfo or not dmgInfo:IsDamageType(DMG_BULLET) then return false end

	local inf = dmgInfo:GetInflictor()
	if IsValid(inf) and inf:GetClass() == NTF_P90 then return true end

	local att = dmgInfo:GetAttacker()
	if IsValid(att) and att:IsPlayer() then
		local wep = att:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == NTF_P90 then return true end
	end

	if IsValid(inf) and inf:IsPlayer() then
		local wep = inf:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == NTF_P90 then return true end
	end

	return false
end

local function MI_GetVictimPlayer(ply, ent)
	if IsValid(ply) and ply:IsPlayer() then return ply end
	if IsValid(ent) and ent:IsPlayer() then return ent end
	if hg and hg.RagdollOwner and IsValid(ent) then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:IsPlayer() then return owner end
	end
	return nil
end

local function MI_VictimIsFacilityScp(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if MissionIntro.ShouldFacilityScpImmuneZcityDebuffs then
		return MissionIntro.ShouldFacilityScpImmuneZcityDebuffs(ply) == true
	end
	if MissionIntro.IsFacilityScpPlayer then
		return MissionIntro.IsFacilityScpPlayer(ply) == true
	end
	return false
end

hook.Add("PreHomigradDamage", "MissionIntro_NtfP90ScpDamage", function(ply, dmgInfo, hitgroup, ent)
	if not MI_RxActive() then return end
	if not MissionIntro.IsNtfP90BulletDamage(dmgInfo) then return end

	local victim = MI_GetVictimPlayer(ply, ent)
	local dmg = MI_VictimIsFacilityScp(victim) and NTF_SCP_DAMAGE or NTF_P90_DAMAGE
	dmgInfo:SetDamage(dmg)
end, -25)
