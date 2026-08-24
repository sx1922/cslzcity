MissionIntro = MissionIntro or {}

if not SERVER then return end

local function scpWarheadMsg(ply, key)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	local text = MissionIntro.L and MissionIntro.L(key) or key
	ply:ChatPrint(text)
end

local function scpWarheadRxSendActive()
	return MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive()
end

hook.Add("SCPWarhead_CanStartCountdown", "MissionIntro_RXSendGOC", function(ply)
	local canStart, denyKey = MissionIntro.RXSendCanStartOmegaWarhead and MissionIntro.RXSendCanStartOmegaWarhead()
	if not canStart then
		scpWarheadMsg(ply, denyKey or "scp_warhead_rxsend_only")
		return false
	end

	if not MissionIntro.IsGocPlayer(ply) then
		scpWarheadMsg(ply, "scp_warhead_goc_only_start")
		return false
	end

	if MissionIntro.RXSendSyncEndgameRoundPause then
		MissionIntro.RXSendSyncEndgameRoundPause()
	end

	if MissionIntro.RXSendCancelAlphaWarheadSchedule then
		MissionIntro.RXSendCancelAlphaWarheadSchedule()
	end

	scpWarheadMsg(ply, "scp_warhead_omega_started")
end)

hook.Add("SCPWarhead_Detonated", "MissionIntro_RXSendOmega", function()
	if MissionIntro.RXSendCancelAlphaWarheadSchedule then
		MissionIntro.RXSendCancelAlphaWarheadSchedule()
	end
	if MissionIntro.RXSendSyncEndgameRoundPause then
		MissionIntro.RXSendSyncEndgameRoundPause()
	end
end)

hook.Add("SCPWarhead_CanCancelDetonation", "MissionIntro_RXSendGOC", function(ply)
	if not scpWarheadRxSendActive() then
		scpWarheadMsg(ply, "scp_warhead_rxsend_only")
		return false
	end

	if MissionIntro.IsGocPlayer(ply) then
		scpWarheadMsg(ply, "scp_warhead_goc_cannot_cancel")
		return false
	end

	if not IsValid(ply) or not ply:IsPlayer() then
		return false
	end

	timer.Simple(0, function()
		if MissionIntro.RXSendSyncEndgameRoundPause then
			MissionIntro.RXSendSyncEndgameRoundPause()
		end
	end)
end)
