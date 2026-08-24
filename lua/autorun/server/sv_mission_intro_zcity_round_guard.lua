if not SERVER then return end

MissionIntro = MissionIntro or {}

-- Z City：间歇期(ROUND_STATE=0) KillPlayers 已重生一次；start_time 到期后再 RoundStart 全员重生。
-- 在间歇期跑 mission_intro 的 PlayerSpawn 重逻辑会与正式开局叠在一起，表现为「模式字幕约 5 秒后卡 30~60 秒」。

function MissionIntro.IsZCityIntermissionSpawn()
	return zb and isnumber(zb.ROUND_STATE) and zb.ROUND_STATE == 0
end

function MissionIntro.IsZCityActiveCombatRound()
	return zb and zb.ROUND_STATE == 1
end

-- 非设施/RXsend 的 PlayerSpawn 重逻辑：间歇期一律跳过
function MissionIntro.ShouldRunHeavyPlayerSpawnHooks(ply)
	if MissionIntro.IsZCityIntermissionSpawn() then
		return false
	end
	if MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive() then
		return true
	end
	if MissionIntro.ShouldRunFacilityScpRoundMaintenance
		and MissionIntro.ShouldRunFacilityScpRoundMaintenance() then
		return true
	end
	if IsValid(ply) and MissionIntro.ShouldApplySpawnArmor and MissionIntro.ShouldApplySpawnArmor(ply) then
		return true
	end
	if IsValid(ply) and MissionIntro.IsPlaying and MissionIntro.IsPlaying(ply) then
		return true
	end
	if IsValid(ply) and MissionIntro.ShouldKeepForcedModel and MissionIntro.ShouldKeepForcedModel(ply) then
		return true
	end
	return false
end

function MissionIntro.DeferZCityRoundWork(delay, fn)
	if not isfunction(fn) then return end
	timer.Simple(tonumber(delay) or 0, fn)
end

local MI_PROFILE_CVAR = CreateConVar(
	"mission_intro_round_profile",
	"0",
	FCVAR_ARCHIVE,
	"1=在控制台打印 Z City 回合切换各阶段耗时（排查开局卡顿）"
)

local function MI_ProfileRound(msg)
	if not MI_PROFILE_CVAR:GetBool() then return end
	MsgN(string.format("[MissionIntro][RoundProfile] %.3f  %s", SysTime(), msg))
end

hook.Add("ZB_PreRoundStart", "MissionIntro_DeferPreRoundScans", function()
	MissionIntro._miSkipFacilityTimersUntil = CurTime() + 6
end)
hook.Add("ZB_PreRoundStart", "MissionIntro_RoundProfile", function()
	MI_ProfileRound("ZB_PreRoundStart 模式=" .. tostring(zb and zb.nextround or zb.CROUND))
end)

hook.Add("ZB_StartRound", "MissionIntro_RoundProfile", function()
	MI_ProfileRound("ZB_StartRound 模式=" .. tostring(zb and zb.CROUND))
end)

hook.Add("ZB_EndRound", "MissionIntro_RoundProfile", function()
	MI_ProfileRound("ZB_EndRound")
end)

hook.Add("ZB_StartRound", "MissionIntro_DeferPostRoundSpawnCleanup", function()
	MissionIntro._miSkipFacilityTimersUntil = CurTime() + 4

	if MissionIntro.ShouldRunFacilityScpRoundMaintenance() then return end

	MissionIntro.DeferZCityRoundWork(0.05, function()
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) or not ply:IsPlayer() then continue end
			local hasStale = (MissionIntro.PlayerHasFacilityScpCredentials
				and MissionIntro.PlayerHasFacilityScpCredentials(ply))
				or ply:GetNWString("RXSend_RoleKey", "") ~= ""
				or ply:GetNWBool("MissionIntro_IsFacilityScp", false)
			if not hasStale then continue end
			if MissionIntro.ClearPlayerMissionIntroState then
				MissionIntro.ClearPlayerMissionIntroState(ply)
			elseif MissionIntro.ClearFacilityScpPlayerState then
				MissionIntro.ClearFacilityScpPlayerState(ply)
			end
		end
	end)
end)
