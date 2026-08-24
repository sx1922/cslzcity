if not SERVER then return end

MissionIntro = MissionIntro or {}

local QRF_BROADCAST_COOLDOWN = 8

MissionIntro._qrfDeployCalled = MissionIntro._qrfDeployCalled or false

local function MI_ShuffleTable(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

local function MI_SyncQrfDeployCalled()
	SetGlobalBool("MissionIntro_QrfDeployCalled", MissionIntro._qrfDeployCalled == true)
end

function MissionIntro.ResetFacilityQrfDeployState()
	MissionIntro._qrfDeployCalled = false
	MI_SyncQrfDeployCalled()
end

function MissionIntro.CanCallFacilityQrfDeployment(caller)
	if not MissionIntro.RXSendIsActive or not MissionIntro.RXSendIsActive() then
		return false, "not_rxsend"
	end

	if MissionIntro._qrfDeployCalled then
		return false, "already"
	end

	if not MissionIntro.IsPlayerSiteDirector(caller) then
		return false, "not_director"
	end

	if not MissionIntro.IsFacilityQrfCallTimeReady() then
		return false, "too_early"
	end

	if MissionIntro.GetFacilityQrfEligibleDeadCount() < 1 then
		return false, "no_dead"
	end

	return true
end

function MissionIntro.CollectFacilityQrfDeadCandidates()
	local dead = {}
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if ply:Alive() then continue end
		if MissionIntro.IsPlaying and MissionIntro.IsPlaying(ply) then continue end
		dead[#dead + 1] = ply
	end

	MI_ShuffleTable(dead)
	return dead
end

function MissionIntro.DeployFacilityQrfSquad(caller)
	local ok, reason = MissionIntro.CanCallFacilityQrfDeployment(caller)
	if not ok then
		local key = "qrf_call_" .. tostring(reason or "failed")
		local msg = MissionIntro.L and MissionIntro.L(key)
			or ("[设施] 无法呼叫快速反应部队 (" .. tostring(reason) .. ")")
		return false, msg
	end

	local maxSize = tonumber(MissionIntro.FacilityQrfSquadSize) or 5
	local dead = MissionIntro.CollectFacilityQrfDeadCandidates()
	if #dead < 1 then
		local msg = MissionIntro.L and MissionIntro.L("qrf_call_no_dead")
			or "[设施] 无阵亡玩家，无法呼叫快速反应部队"
		return false, msg
	end

	local want = math.min(maxSize, #dead)
	local targets = {}
	for i = 1, want do
		targets[i] = dead[i]
	end

	local startList = select(1, MissionIntro.AssignFacilityQrfSquadFixedOrder(targets, caller))
	if not istable(startList) or #startList < 1 then
		local msg = MissionIntro.L and MissionIntro.L("qrf_call_failed")
			or "[设施] 快速反应部队派遣失败"
		return false, msg
	end

	MissionIntro._qrfDeployCalled = true
	MI_SyncQrfDeployCalled()

	if MissionIntro.BroadcastQrfDeploymentAlert then
		MissionIntro.BroadcastQrfDeploymentAlert(startList)
	end

	if MissionIntro.StartFacilityIntroBatch then
		MissionIntro.StartFacilityIntroBatch(startList, "facility_qrf_batch")
	end

	local msg = MissionIntro.L and MissionIntro.L("qrf_call_success", #startList)
		or ("[设施] 快速反应部队已派遣（" .. #startList .. " 人）")
	if IsValid(caller) and caller:IsPlayer() then
		caller:ChatPrint(msg)
	end
	PrintMessage(HUD_PRINTTALK, msg)

	MsgN("[MissionIntro] 设施主管呼叫快速反应部队 -> " .. #startList .. " 人")
	return true, msg
end

function MissionIntro.BroadcastQrfDeploymentAlert(introPlayers)
	if MissionIntro._qrfDeployBroadcastAt and (CurTime() - MissionIntro._qrfDeployBroadcastAt) < QRF_BROADCAST_COOLDOWN then
		return false
	end
	MissionIntro._qrfDeployBroadcastAt = CurTime()

	local data = MissionIntro.GetQrfDeploymentBroadcast and MissionIntro.GetQrfDeploymentBroadcast()
	if not istable(data) then return false end

	if MissionIntro.BroadcastCustomAlert then
		MissionIntro.BroadcastCustomAlert(data, {
			playSound = true,
			forceSoundDuringIntro = true,
		})
	end

	local count = istable(introPlayers) and #introPlayers or 0
	MsgN("[MissionIntro] 快速反应部队广播 -> 全服（入场 " .. count .. " 人；入场音效仅入场玩家播放）")
	return true
end

function MissionIntro.ShouldPlayQrfDeploymentBroadcast(factionId)
	if not MissionIntro.IsFacilityQrfFactionId then return false end
	return MissionIntro.IsFacilityQrfFactionId(factionId) == true
end

hook.Add("MissionIntro_AdminStartBroadcast", "MissionIntro_QrfDeployBroadcast", function(factionId, startList)
	if MissionIntro._qrfDeployCalled then return true end
	if not MissionIntro.ShouldPlayQrfDeploymentBroadcast(factionId) then return end
	if MissionIntro.BroadcastQrfDeploymentAlert then
		MissionIntro.BroadcastQrfDeploymentAlert(startList)
	end
	return true
end)

for _, hookName in ipairs({ "ZB_PreRoundStart", "ZB_EndRound", "RoundStart", "Breach_NewRound", "OnNewRound", "HMCD_NewRound", "HomigradRoundStart" }) do
	hook.Add(hookName, "MissionIntro_FacilityQrfDeployReset", function()
		MissionIntro.ResetFacilityQrfDeployState()
	end)
end

MI_SyncQrfDeployCalled()
