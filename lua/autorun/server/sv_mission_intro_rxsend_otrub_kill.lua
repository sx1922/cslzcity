-- RXsend 人类：Homigrad 昏迷（otrub）时直接 KillSilent，不走 9999 伤害 / 假死布娃娃
if not SERVER then return end

MissionIntro = MissionIntro or {}

local KILL_TIMER_PREFIX = "MissionIntro_RXSendOtrubKill_"

local function MI_RxActive()
	return MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive()
end

function MissionIntro.ShouldRXSendHumanOtrubKill(ply)
	if not MI_RxActive() then return false end
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end
	if MissionIntro.IsFacilityScpPlayer and MissionIntro.IsFacilityScpPlayer(ply) then return false end
	if MissionIntro.ShouldApplyFacilityScpGameplayRules
		and MissionIntro.ShouldApplyFacilityScpGameplayRules(ply) then
		return false
	end
	return true
end

local function MI_ClearFakeRagdoll(ply)
	if not IsValid(ply) then return end

	local rag = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply:GetNWEntity("FakeRagdoll")
	if IsValid(rag) then
		if rag._miRxDeathCorpse and not rag._miRxAllowRemove then return end
		rag.override = true
		rag:Remove()
	end

	ply.FakeRagdoll = nil
	ply.FakeRagdollOld = nil
	if hg and hg.ragdollFake then
		hg.ragdollFake[ply] = nil
	end
	ply:SetNWEntity("FakeRagdoll", NULL)
	ply:SetNWEntity("FakeRagdollOld", NULL)
end

local function MI_SuppressUnconsciousOrganism(ply)
	local org = ply.organism
	if not istable(org) then return end

	org.needotrub = false
	org.otrub = false
	org.needfake = false
	org.fake = false
end

function MissionIntro.MI_ExecuteRXSendOtrubKill(ply)
	if not MissionIntro.ShouldRXSendHumanOtrubKill(ply) then return false end
	if not IsValid(ply) or not ply:Alive() then return false end

	MI_SuppressUnconsciousOrganism(ply)
	MI_ClearFakeRagdoll(ply)

	if ply:Alive() then
		ply:KillSilent()
	end

	return not ply:Alive()
end

local function MI_ScheduleRXSendOtrubKill(ply)
	if not MissionIntro.ShouldRXSendHumanOtrubKill(ply) then return end
	if not IsValid(ply) or not ply:Alive() then return end
	if ply._miRxOtrubKillQueued then return end

	local tid = KILL_TIMER_PREFIX .. ply:EntIndex()
	if timer.Exists(tid) then return end

	ply._miRxOtrubKillQueued = true
	MI_SuppressUnconsciousOrganism(ply)

	timer.Create(tid, 0.05, 1, function()
		if IsValid(ply) then
			ply._miRxOtrubKillQueued = nil
		end
		if not IsValid(ply) or not ply:Alive() then return end
		MissionIntro.MI_ExecuteRXSendOtrubKill(ply)
	end)
end

hook.Add("HG_OnOtrub", "MissionIntro_RXSendOtrubKill", function(ply)
	if not MissionIntro.ShouldRXSendHumanOtrubKill(ply) then return end
	MI_ScheduleRXSendOtrubKill(ply)
end, -100)

-- 同帧内 homigrad 可能因 needfake 再进 Fake；排队处死期间禁止假死布娃娃
hook.Add("Org Think", "MissionIntro_RXSendOtrubKillSuppressFake", function(owner, org)
	if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
	if not owner._miRxOtrubKillQueued then return end
	if not MissionIntro.ShouldRXSendHumanOtrubKill(owner) then return end
	if not istable(org) then return end

	org.needotrub = false
	org.otrub = false
	org.needfake = false
	org.fake = false
end, -999)

hook.Add("Fake", "MissionIntro_RXSendOtrubKillBlockFake", function(ply)
	if IsValid(ply) and ply._miRxOtrubKillQueued and MissionIntro.ShouldRXSendHumanOtrubKill(ply) then
		MI_ClearFakeRagdoll(ply)
	end
end)

hook.Add("Ragdoll_Create", "MissionIntro_RXSendOtrubKillBlockFake", function(ply, ragdoll)
	if not IsValid(ply) or not ply:Alive() then return end
	if not ply._miRxOtrubKillQueued then return end
	if not MissionIntro.ShouldRXSendHumanOtrubKill(ply) then return end
	if IsValid(ragdoll) then
		ragdoll.override = true
		ragdoll:Remove()
	end
end)

hook.Add("PlayerSpawn", "MissionIntro_RXSendOtrubKillReset", function(ply)
	ply._miRxOtrubKillQueued = nil
	timer.Remove(KILL_TIMER_PREFIX .. ply:EntIndex())
end)

hook.Add("PlayerDisconnected", "MissionIntro_RXSendOtrubKillReset", function(ply)
	if not IsValid(ply) then return end
	ply._miRxOtrubKillQueued = nil
	timer.Remove(KILL_TIMER_PREFIX .. ply:EntIndex())
end)
