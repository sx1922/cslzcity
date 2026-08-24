if not SERVER then return end

MissionIntro = MissionIntro or {}

local MI_PMS_LAST_RX = nil

function MissionIntro.SyncPlayerModelSelectorForRound()
	if not MissionIntro.HasPlayerModelSelector() then
		return MissionIntro.IsRXSendRound and MissionIntro.IsRXSendRound() or false
	end

	-- 强制模型由 Mission Intro 在 RXsend 分配；勿启用 PMS force（会按客户端 cl_playermodel 覆盖服务器 SetModel）。
	MissionIntro.SetPlayerModelSelectorCvar("sv_playermodel_selector_gamemodes", "0")
	MissionIntro.SetPlayerModelSelectorCvar("sv_playermodel_selector_instantly", "0")
	MissionIntro.SetPlayerModelSelectorCvar("sv_playermodel_selector_force", "0")

	return MissionIntro.IsRXSendRound and MissionIntro.IsRXSendRound() or false
end

local function MI_PMS_OnRoundMaybeChanged()
	if not MissionIntro.HasPlayerModelSelector() then
		timer.Remove("MissionIntro_PMS_RxSendPoll")
		return
	end

	local rx = MissionIntro.SyncPlayerModelSelectorForRound()
	if MI_PMS_LAST_RX == rx then return end
	MI_PMS_LAST_RX = rx

	if not ConVarExists("cl_playermodel_selector_force") then return end

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() then
			ply:SendLua([[if ConVarExists("cl_playermodel_selector_force") then GetConVar("cl_playermodel_selector_force"):SetString("0") end]])
		end
	end
end

hook.Add("Initialize", "MissionIntro_PMS_RxSendOnly", function()
	timer.Simple(0, MI_PMS_OnRoundMaybeChanged)
end)

hook.Add("InitPostEntity", "MissionIntro_PMS_RxSendOnly", function()
	timer.Simple(1, MI_PMS_OnRoundMaybeChanged)
end)

timer.Simple(0, function()
	if MissionIntro.HasPlayerModelSelector() then
		timer.Create("MissionIntro_PMS_RxSendPoll", 2, 0, MI_PMS_OnRoundMaybeChanged)
	end
end)

-- RXsend 内若 PMS/其他逻辑在 spawn 后改模，稍后重新套用 Mission Intro 分配。
hook.Add("PlayerSpawn", "MissionIntro_PMS_ReassertForcedModel", function(ply)
	if not MissionIntro.IsRXSendRound or not MissionIntro.IsRXSendRound() then return end
	if not MissionIntro.ShouldKeepForcedModel or not MissionIntro.ShouldKeepForcedModel(ply) then return end

	local function reassert()
		if not IsValid(ply) or not MissionIntro.ShouldKeepForcedModel(ply) then return end
		if MissionIntro.ClearPlayerMaterialOverrides then
			MissionIntro.ClearPlayerMaterialOverrides(ply)
		end
		if MissionIntro.ApplyForcedPlayerModel then
			MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
		end
	end

	timer.Simple(0.15, reassert)
	timer.Simple(0.35, reassert)
end)
