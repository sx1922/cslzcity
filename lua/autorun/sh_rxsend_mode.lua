MissionIntro = MissionIntro or {}

MissionIntro.RXSendModeName = "rxsend"
MissionIntro.RXSendClassDPerScience = 3
MissionIntro.RXSendDoctorPerScience = 3
MissionIntro.RXSendResearchersPerSenior = 3
MissionIntro.RXSendUiuMinPlayers = 9
MissionIntro.RXSendMaynardMinPlayers = 12
MissionIntro.RXSendScpMinPlayers = 12
MissionIntro.RXSendScpMax = 1
MissionIntro.RXSendScpRandomRoles = { "scp_062de", "scp_0762", "scp_912" }
MissionIntro.RXSendCiMinPlayers = 9
MissionIntro.RXSendMtfSiteDirectorMinPlayers = 15
-- D 级 floor((人数+1)/3)；切皮每局最多 1 名；较旧 D 级公式削减的名额→安保，再削减的名额→科研池
MissionIntro.RXSendClassDPerFour = false
MissionIntro.RXSendClassDPerFiveDouble = true
MissionIntro.RXSendClassDPersonnelRatio = 0.75
MissionIntro.RXSendClassDImpostorMax = 1
MissionIntro.RXSendSecurityPerFour = false
MissionIntro.RXSendSecurityPerFive = true

-- 身份卡片：开局第 5 秒渐入黑屏，约 3 秒后淡出并出生（与封锁广播同时）
MissionIntro.RXSendRoleCardStart = 5
MissionIntro.RXSendRoleCardEnd = 8
MissionIntro.RXSendRoleCardFadeIn = 0.85
MissionIntro.RXSendRoleCardFadeOut = 0.85

-- 回合结束前 3:30 触发紧急疏散广播与背景音乐
MissionIntro.RXSendEvacuationSecondsBeforeEnd = 210
MissionIntro.RXSendEvacuationMusic = "mission_intro/rxsend_evacuation_music.mp3"
MissionIntro.RXSendEvacuationAlertSound = "mission_intro/rxsend_evacuation_alert.mp3"

-- 回合结束前 2:11 触发阿尔法弹头弹窗与音效；至回合结束静默处死
MissionIntro.RXSendAlphaWarheadSecondsBeforeEnd = 131
MissionIntro.RXSendAlphaWarheadPlayAlertSound = true
MissionIntro.RXSendAlphaWarheadAlertSound = "mission_intro/rxsend_alpha_warhead_start.mp3"
MissionIntro.RXSendAlphaWarheadDetonationDelay = 131
MissionIntro.RXSendAlphaWarheadAlertDurationFallback = 131

-- 回合结束前 34 秒：最终撤离警告弹窗与音效
MissionIntro.RXSendAlphaWarheadFinalWarningSecondsBeforeEnd = 34
MissionIntro.RXSendAlphaWarheadPlayFinalWarningSound = true
MissionIntro.RXSendAlphaWarheadFinalWarningSound = "mission_intro/rxsend_alpha_warhead_final_warning.mp3"

-- 默认回合时长（秒）；运行时可由 rxsend_round_time 指令/ConVar 覆盖
MissionIntro.RXSendDefaultRoundTime = 1200

MissionIntro.RXSendEvac = {
	evac_duration = 0.1,
	default_zone_radius = 130,
	min_zone_radius = 64,
	max_zone_radius = 400,
	facility_open_seconds_before_end = 30,
	ci_open_seconds_before_end = 20,
}

MissionIntro.RXSendTeams = {
	ci_alliance = 0,
	facility = 1,
	scarlet = 2,
	uiu = 3,
	mcd = 4,
}

MissionIntro.RXSendTeamNames = {
	[0] = "混沌同盟",
	[1] = "基金会",
	[2] = "猩红",
	[3] = "UIU",
	[4] = "MC&D",
}

MissionIntro.RXSendBattleTeamByFaction = {
	class_d_personnel = 0,
	ci_spy = 0,
	dr_maynard = 0,
	ci_squad = 0,
	vdv_squad = 0,
	goc_squad = 0,
	facility_researcher = 1,
	facility_doctor = 1,
	facility_senior_scientist = 1,
	facility_ethics = 1,
	classd_impostor = 1,
	facility_security_rookie = 1,
	facility_security_officer = 1,
	facility_security_sergeant = 1,
	facility_security_warden = 1,
	facility_security_captain = 1,
	facility_mtf_site_director = 1,
	hammerfall_squad = 1,
	hammerfall_maintenance = 1,
	ntf_squad = 1,
	pttrb_squad = 1,
	scarlet_cultist = 2,
	uiu_spy = 3,
	uiu_taskforce = 3,
	mcd_squad = 4,
	facility_scp_062de = 2,
	facility_scp_0762 = 2,
	facility_scp_912 = 2,
}

function MissionIntro.RXSendIsActive()
	return zb and zb.CROUND == (MissionIntro.RXSendModeName or "rxsend")
end

function MissionIntro.GetZCityRoundMode()
	if not zb then return "" end
	return zb.CROUND or zb.nextround or ""
end

function MissionIntro.GetZCityUpcomingMode()
	if not zb then return "" end
	return zb.nextround or zb.CROUND or ""
end

-- RXsend / 设施 SCP 回合维护；hmcd 等普通模式勿跑全员 Strip/Clear（会在开局字幕时卡死）
function MissionIntro.ShouldRunFacilityScpRoundMaintenance(modeName)
	modeName = isstring(modeName) and modeName or MissionIntro.GetZCityRoundMode()
	if modeName == "" then return false end
	if MissionIntro.ShouldModeUseFacilityScpRoles and MissionIntro.ShouldModeUseFacilityScpRoles(modeName) then
		return true
	end
	return modeName == (MissionIntro.RXSendModeName or "rxsend")
end

function MissionIntro.RXSendGetPlayerRoleKey(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return "" end
	return ply.RXSendRoleKey or ply:GetNWString("RXSend_RoleKey", "") or ""
end

function MissionIntro.RXSendPlayerHasAssignedRole(ply)
	if not MissionIntro.RXSendIsActive() then return false end
	local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
	return roleKey ~= "" and MissionIntro.RXSendGetRoleDef(roleKey) ~= nil
end

-- 返回 CI 同盟 kind（dr/ci_spy）、false（RX 科研/安保等明确不是同盟）、nil（无 RX 角色键，走阵营 NW）
function MissionIntro.RXSendGetCiAllyRoleOverride(ply)
	if not MissionIntro.RXSendIsActive() then return nil end

	local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
	if roleKey == "" then return nil end

	if roleKey == "dr_maynard" then return "dr" end
	if roleKey == "ci_spy" then return "ci_spy" end

	local def = MissionIntro.RXSendGetRoleDef and MissionIntro.RXSendGetRoleDef(roleKey)
	if def then return false end

	return nil
end

function MissionIntro.RXSendGetClassdImpostorOverride(ply)
	if not MissionIntro.RXSendPlayerHasAssignedRole(ply) then return nil end
	return MissionIntro.RXSendGetPlayerRoleKey(ply) == "classd_impostor"
end

function MissionIntro.RXSendGetUiuSpyOverride(ply)
	if not MissionIntro.RXSendPlayerHasAssignedRole(ply) then return nil end
	return MissionIntro.RXSendGetPlayerRoleKey(ply) == "uiu_spy"
end

-- RX 模式用同阵营名单弹窗，不再绘制描边/框
function MissionIntro.ShouldUseRxsendTeamPanel()
	return MissionIntro.RXSendIsActive()
end

function MissionIntro.ShouldShowRxsendTeamPanel()
	if not MissionIntro.ShouldUseRxsendTeamPanel() then
		return false
	end

	local state = zb and zb.ROUND_STATE
	if state == 3 then
		return false
	end

	if CLIENT then
		local ply = LocalPlayer()
		if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR or not ply:Alive() then
			return false
		end
		if not MissionIntro.RXSendShouldShowAllyPanel(ply) then
			return false
		end

		local roundStart = zb and (zb.ROUND_START or zb.ROUND_BEGIN) or 0
		if roundStart > 0 then
			local cardEnd = tonumber(MissionIntro.RXSendRoleCardEnd) or 8
			if CurTime() < roundStart + cardEnd and MissionIntro.RXSendGetPlayerRoleKey(ply) == "" then
				if not MissionIntro.RXSendPanelIsChaosReinforcement or not MissionIntro.RXSendPanelIsChaosReinforcement(ply) then
					return false
				end
			end
		end
	end

	return true
end

-- 旧描边 / 旧版同盟名单框：仅 RXsend 用新情报面板；其它子模式一律不画
function MissionIntro.ShouldDrawAllyGlows()
	return false
end

function MissionIntro.GetZCityPlayerName(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return "?"
	end

	if ply.SteamName then
		local steamName = ply:SteamName()
		if isstring(steamName) and steamName ~= "" then
			return steamName
		end
	end

	return ply:Nick() or "?"
end

function MissionIntro.GetVirtualPlayerName(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return ""
	end

	local virtual = ""
	if ply.GetPlayerName then
		virtual = ply:GetPlayerName() or ""
	end
	if virtual == "" then
		virtual = ply:GetNWString("PlayerName", "") or ""
	end

	return virtual
end

-- 情报弹窗名单：Steam/真实名 + 游戏内虚拟名
function MissionIntro.GetIntelPanelPlayerName(ply)
	local realName = MissionIntro.GetZCityPlayerName(ply)
	local virtualName = MissionIntro.GetVirtualPlayerName(ply)

	if isstring(virtualName) and virtualName ~= "" and virtualName ~= realName then
		return realName .. "（" .. virtualName .. "）"
	end

	return realName
end

MissionIntro.RXSendTeamPanelColors = {
	[0] = Color(72, 220, 110),
	[1] = Color(72, 130, 210),
	[2] = Color(220, 72, 96),
	[3] = Color(72, 160, 255),
	[4] = Color(160, 96, 255),
}

MissionIntro.RXSendAllyPanelMeta = {
	class_d = {
		title = "混沌情报",
		subtitle = "CI 间谍 · Dr.梅纳德 · D级切皮",
		color = Color(72, 220, 110),
	},
	ci_spy = {
		title = "混沌情报",
		subtitle = "Dr.梅纳德 · D级切皮",
		color = Color(72, 220, 110),
	},
	dr_maynard = {
		title = "混沌情报",
		subtitle = "D级切皮 · CI 间谍",
		color = Color(72, 220, 110),
	},
	uiu = {
		title = "UIU 联络",
		subtitle = "UIU 间谍",
		color = Color(72, 160, 255),
	},
}

function MissionIntro.RXSendGetPanelFactionId(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return ""
	end

	if MissionIntro.GetStoredFacilityFactionId then
		local fac = MissionIntro.GetStoredFacilityFactionId(ply)
		if isstring(fac) and fac ~= "" then
			return fac
		end
	end

	return ply:GetNWString("MissionIntro_FactionId", "") or ""
end

-- RX 情报只认「当前仍有效的分配」：死亡清阵营后不再用残留的 RXSend_RoleKey 显示上一世名单
function MissionIntro.RXSendRestorePanelAssignment(ply)
	if not SERVER or not MissionIntro.RXSendIsActive() then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
	if roleKey == "" then
		if MissionIntro.RXSendPanelIsChaosReinforcement and MissionIntro.RXSendPanelIsChaosReinforcement(ply) then
			ply:SetNWBool("RXSend_TeamPanelHide", false)
			if MissionIntro.RXSendSyncBattleTeamNW then
				MissionIntro.RXSendSyncBattleTeamNW(ply)
			end
		end
		return
	end

	local def = MissionIntro.RXSendGetRoleDef(roleKey)
	if not def then return end

	if roleKey == "class_d_personnel" then
		local saved = ply:GetNWString("RXSend_PanelClassDRole", "")
		if saved ~= "" and MissionIntro.AssignClassDRole then
			MissionIntro.AssignClassDRole(ply, saved)
		elseif MissionIntro.AssignFacilityFaction then
			MissionIntro.AssignFacilityFaction(ply, "class_d_personnel")
		end
	elseif def.faction_id and MissionIntro.AssignFacilityFaction then
		MissionIntro.AssignFacilityFaction(ply, def.faction_id)
	elseif def.faction_id then
		ply._missionIntroFaction = def.faction_id
		ply:SetNWString("MissionIntro_FactionId", def.faction_id)
	end

	ply:SetNWBool("RXSend_TeamPanelHide", false)
	if MissionIntro.RXSendSyncBattleTeamNW then
		MissionIntro.RXSendSyncBattleTeamNW(ply)
	end
end

function MissionIntro.RXSendPanelIsCiSpy(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.RXSendIsActive() then
		return MissionIntro.RXSendGetPanelFactionId(ply) == "ci_spy"
	end
	if MissionIntro.RXSendGetPlayerRoleKey(ply) == "ci_spy" then return true end
	return MissionIntro.RXSendGetPanelFactionId(ply) == "ci_spy"
end

function MissionIntro.RXSendPanelIsDrMaynard(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.RXSendIsActive() then
		return MissionIntro.RXSendGetPanelFactionId(ply) == "dr_maynard"
	end
	if MissionIntro.RXSendGetPlayerRoleKey(ply) == "dr_maynard" then return true end
	return MissionIntro.RXSendGetPanelFactionId(ply) == "dr_maynard"
end

function MissionIntro.RXSendPanelIsClassDImpostor(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.RXSendIsActive() then
		return MissionIntro.RXSendGetPanelFactionId(ply) == "classd_impostor"
	end
	if MissionIntro.RXSendGetPlayerRoleKey(ply) == "classd_impostor" then return true end
	return MissionIntro.RXSendGetPanelFactionId(ply) == "classd_impostor"
end

function MissionIntro.RXSendPanelIsRealClassD(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.RXSendPanelIsClassDImpostor(ply) then return false end

	if MissionIntro.RXSendIsActive() then
		local fac = MissionIntro.RXSendGetPanelFactionId(ply)
		if fac == "class_d_personnel" then return true end
		return ply:GetNWString("MissionIntro_ClassDRole", "") ~= ""
	end

	local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
	if roleKey == "class_d_personnel" then return true end

	local fac = MissionIntro.RXSendGetPanelFactionId(ply)
	if fac == "class_d_personnel" then return true end
	if ply:GetNWString("MissionIntro_ClassDRole", "") ~= "" then return true end

	return false
end

function MissionIntro.RXSendPanelIsCiArmy(ply)
	if not IsValid(ply) then return false end
	return MissionIntro.RXSendGetPanelFactionId(ply) == "ci_squad"
end

function MissionIntro.RXSendPanelIsVdvSquad(ply)
	if not IsValid(ply) then return false end
	return MissionIntro.RXSendGetPanelFactionId(ply) == "vdv_squad"
end

function MissionIntro.RXSendPanelIsChaosReinforcement(ply)
	if not IsValid(ply) then return false end
	local fac = MissionIntro.RXSendGetPanelFactionId(ply)
	return fac == "ci_squad" or fac == "vdv_squad"
end

function MissionIntro.RXSendPanelHasChaosIntel(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.RXSendPanelIsRealClassD(ply) then return true end
	if MissionIntro.RXSendPanelIsClassDImpostor(ply) then return true end
	return MissionIntro.RXSendPanelIsChaosReinforcement(ply)
end

function MissionIntro.RXSendPanelIsUiuSpy(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.RXSendIsActive() then
		return MissionIntro.RXSendGetPanelFactionId(ply) == "uiu_spy"
	end
	if MissionIntro.RXSendGetPlayerRoleKey(ply) == "uiu_spy" then return true end
	return MissionIntro.RXSendGetPanelFactionId(ply) == "uiu_spy"
end

function MissionIntro.RXSendPanelIsUiuAllyViewer(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.RXSendPanelIsUiuSpy(ply) then return false end

	local fac = MissionIntro.RXSendGetPanelFactionId(ply)
	if fac == "sid_squad" then return true end
	if MissionIntro.NormalizeUiuTaskforceFactionId and MissionIntro.NormalizeUiuTaskforceFactionId(fac) == "uiu_taskforce" then
		return true
	end
	if MissionIntro.IsSidSpawnPlayer and MissionIntro.IsSidSpawnPlayer(ply) then return true end
	if MissionIntro.IsUiuTaskforcePlayer and MissionIntro.IsUiuTaskforcePlayer(ply) then return true end

	return false
end

-- 谁可以看到同盟名单弹窗（仅 RXsend 回合）
function MissionIntro.RXSendGetAllyPanelViewerKind(ply)
	if not MissionIntro.RXSendIsActive() then
		return nil
	end
	if not IsValid(ply) or not ply:IsPlayer() then
		return nil
	end

	if MissionIntro.RXSendPanelHasChaosIntel(ply) then
		return "class_d"
	end
	if MissionIntro.RXSendPanelIsCiSpy(ply) then
		return "ci_spy"
	end
	if MissionIntro.RXSendPanelIsDrMaynard(ply) then
		return "dr_maynard"
	end
	if MissionIntro.RXSendPanelIsUiuAllyViewer(ply) then
		return "uiu"
	end

	return nil
end

function MissionIntro.RXSendShouldShowAllyPanel(ply)
	if not MissionIntro.RXSendIsActive() then
		return false
	end
	return MissionIntro.RXSendGetAllyPanelViewerKind(ply) ~= nil
end

function MissionIntro.RXSendIsAllyPanelTarget(viewer, target)
	if not IsValid(viewer) or not IsValid(target) or viewer == target then
		return false
	end
	if not MissionIntro.RXSendIsPlayerActiveForTeamPanel(target) then
		return false
	end

	local vk = MissionIntro.RXSendGetAllyPanelViewerKind(viewer)
	if vk == "class_d" then
		if MissionIntro.RXSendPanelIsCiSpy(target) then return true end
		if MissionIntro.RXSendPanelIsDrMaynard(target) then return true end
		if MissionIntro.RXSendPanelIsClassDImpostor(target) then return true end
	elseif vk == "ci_spy" then
		if MissionIntro.RXSendPanelIsDrMaynard(target) then return true end
		if MissionIntro.RXSendPanelIsClassDImpostor(target) then return true end
	elseif vk == "dr_maynard" then
		if MissionIntro.RXSendPanelIsClassDImpostor(target) then return true end
		if MissionIntro.RXSendPanelIsCiSpy(target) then return true end
	elseif vk == "uiu" then
		if MissionIntro.RXSendPanelIsUiuSpy(target) then return true end
	end

	return false
end

function MissionIntro.RXSendGetAllyPanelEntries(ply)
	local kind = MissionIntro.RXSendGetAllyPanelViewerKind(ply)
	if not kind then
		return {}, nil
	end

	local list = {}
	for _, other in ipairs(player.GetAll()) do
		if not MissionIntro.RXSendIsAllyPanelTarget(ply, other) then continue end

		list[#list + 1] = {
			ply = other,
			name = MissionIntro.GetIntelPanelPlayerName(other),
		}
	end

	table.sort(list, function(a, b)
		return a.name < b.name
	end)

	return list, kind
end

function MissionIntro.RXSendComputeBattleTeam(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return 1
	end

	local fac = ""
	if MissionIntro.GetStoredFacilityFactionId then
		fac = MissionIntro.GetStoredFacilityFactionId(ply) or ""
	end
	if fac == "" then
		fac = ply:GetNWString("MissionIntro_FactionId", "") or ply._missionIntroFaction or ""
	end

	local mapped = MissionIntro.RXSendBattleTeamByFaction[fac]
	if isnumber(mapped) then
		return mapped
	end

	if MissionIntro.Factions and MissionIntro.Factions[fac] then
		if fac == "scarlet_cultist" then return 2 end
		if fac == "hammerfall_squad" or fac == "hammerfall_maintenance" or fac == "pttrb_squad" then return 1 end
		if fac == "uiu_taskforce" then return 3 end
		if fac == "mcd_squad" then return 4 end
		if fac == "ci_squad" or fac == "vdv_squad" or fac == "goc_squad" then return 0 end
	end

	local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
	if roleKey ~= "" then
		local def = MissionIntro.RXSendGetRoleDef(roleKey)
		if def and isnumber(def.team) then
			return def.team
		end
	end

	return 1
end

function MissionIntro.RXSendSyncBattleTeamNW(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then
		return
	end

	local team = MissionIntro.RXSendComputeBattleTeam(ply)
	ply.RXSendBattleTeam = team
	ply:SetNWInt("RXSend_BattleTeam", team)
end

function MissionIntro.RXSendIsPlayerActiveForTeamPanel(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return false
	end
	if ply:Team() == TEAM_SPECTATOR then
		return false
	end
	if ply:GetNWBool("RXSend_TeamPanelHide", false) then
		return false
	end
	if not ply:Alive() then
		return false
	end
	return true
end

function MissionIntro.RXSendGetBattleTeam(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return 1
	end

	if CLIENT then
		local nw = ply:GetNWInt("RXSend_BattleTeam", -1)
		if nw >= 0 and nw <= 4 then
			return nw
		end
	end

	if SERVER and isnumber(ply.RXSendBattleTeam) then
		return ply.RXSendBattleTeam
	end

	return MissionIntro.RXSendComputeBattleTeam(ply)
end

function MissionIntro.RXSendGetTeammates(ply)
	return MissionIntro.RXSendGetAllyPanelEntries(ply)
end

function MissionIntro.RXSendClearPlayerRoundState(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return end

	ply.RXSendRoleKey = nil
	ply:SetNWString("RXSend_RoleKey", "")
	ply:SetNWString("RXSend_RoleDisplay", "")
	ply:SetNWString("RXSend_Objective", "")
	ply:SetNWInt("RXSend_BattleTeam", -1)
	ply:SetNWBool("RXSend_TeamPanelHide", true)
	ply.RXSendBattleTeam = nil
	ply._missionIntroEvacuated = nil

	if MissionIntro.ClearPlayerMissionIntroState then
		MissionIntro.ClearPlayerMissionIntroState(ply)
	end

	if MissionIntro.ClearClassDRole then
		MissionIntro.ClearClassDRole(ply)
	end
end

-- 仅清除 RX 回合角色键（死亡换阵营 / 增援入场时避免 HUD 仍显示上一身份）
function MissionIntro.ClearRxsendRoundRoleAssignment(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return end

	ply.RXSendRoleKey = nil
	ply:SetNWString("RXSend_RoleKey", "")
	ply:SetNWString("RXSend_RoleDisplay", "")
	ply:SetNWString("RXSend_Objective", "")
	ply:SetNWString("RXSend_PanelClassDRole", "")
end

function MissionIntro.RXSendHudRoleMatchesAssignment(ply, roleKey)
	if not IsValid(ply) or not isstring(roleKey) or roleKey == "" then return false end

	local def = MissionIntro.RXSendGetRoleDef and MissionIntro.RXSendGetRoleDef(roleKey)
	if not def then return false end

	local facId = ""
	if MissionIntro.GetFactionId then
		facId = MissionIntro.GetFactionId(ply) or ""
	end
	if facId == "" then
		facId = ply:GetNWString("MissionIntro_FactionId", "") or ply._missionIntroFaction or ""
	end
	if facId == "" then return false end

	if def.faction_id and facId == def.faction_id then
		return true
	end

	if roleKey == "class_d_personnel" then
		if facId == "class_d_personnel" then return true end
		if MissionIntro.IsClassDPersonnelPlayer and MissionIntro.IsClassDPersonnelPlayer(ply) then
			return true
		end
	end

	return false
end

function MissionIntro.RXSendSyncPlayerTeam(ply)
	if not SERVER or not MissionIntro.RXSendIsActive() then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local team = MissionIntro.RXSendComputeBattleTeam(ply)
	ply:SetTeam(team)
	MissionIntro.RXSendSyncBattleTeamNW(ply)
end

MissionIntro.RXSendRoleDefs = {
	researcher = {
		faction_id = "facility_researcher",
		team = 1,
		display = "科研人员",
		color = Color(72, 130, 210),
		objective = "活着逃出设施",
		max = nil,
	},
	doctor = {
		faction_id = "facility_doctor",
		team = 1,
		display = "医生",
		color = Color(90, 180, 220),
		objective = "活着逃出设施并救助你的同伴",
		max = nil,
	},
	senior_scientist = {
		faction_id = "facility_senior_scientist",
		team = 1,
		display = "高级科学家",
		color = Color(100, 150, 230),
		objective = "活着逃出设施",
		max = nil,
	},
	ethics = {
		faction_id = "facility_ethics",
		team = 1,
		display = "道德伦理检查官",
		color = Color(120, 120, 200),
		objective = "活着逃出设施",
		max = 1,
	},
	classd_impostor = {
		faction_id = "classd_impostor",
		team = 1,
		display = "D级人员（伪装者）",
		color = Color(220, 140, 60),
		objective = "逃离设施，并与混沌分裂者合作！",
	},
	class_d_personnel = {
		faction_id = "class_d_personnel",
		team = 0,
		display = "D级人员",
		color = Color(220, 140, 60),
		objective = "逃离设施，并与混沌分裂者合作！",
	},
	uiu_spy = {
		faction_id = "uiu_spy",
		team = 3,
		display = "UIU 特异事故处间谍",
		color = Color(40, 40, 48),
		objective = "呼叫UIU特工小组，避免任何不必要的致命武力",
	},
	dr_maynard = {
		faction_id = "dr_maynard",
		team = 0,
		display = "Dr. 梅纳德博士",
		color = Color(72, 200, 96),
		objective = "入侵防空系统，呼叫混沌分裂者空降部队，并尽可能协助D级人员与混沌分裂者间谍",
	},
	ci_spy = {
		faction_id = "ci_spy",
		team = 0,
		display = "混沌分裂者 间谍",
		color = Color(72, 200, 96),
		objective = "暗中协助 D 级与 Dr. 梅纳德，呼叫混沌分裂者空降部队",
	},
	security_rookie = {
		faction_id = "facility_security_rookie",
		team = 1,
		display = "安保菜鸟",
		color = Color(196, 64, 64),
		objective = "保护科研与防范间谍",
	},
	security_officer = {
		faction_id = "facility_security_officer",
		team = 1,
		display = "安保警员",
		color = Color(196, 64, 64),
		objective = "保护科研与防范间谍",
	},
	security_sergeant = {
		faction_id = "facility_security_sergeant",
		team = 1,
		display = "安保中士",
		color = Color(196, 64, 64),
		objective = "保护科研与防范间谍",
	},
	security_warden = {
		faction_id = "facility_security_warden",
		team = 1,
		display = "安保典狱长",
		color = Color(196, 64, 64),
		objective = "保护科研与防范间谍",
	},
	security_captain = {
		faction_id = "facility_security_captain",
		team = 1,
		display = "安保上尉",
		color = Color(196, 64, 64),
		objective = "保护科研与防范间谍",
	},
	site_director = {
		faction_id = "facility_mtf_site_director",
		team = 1,
		display = "设施主管",
		color = Color(30, 90, 168),
		objective = "坚守设施，疏散科研，消灭未知单位与设施共存亡！",
		max = 1,
	},
	scp_062de = {
		faction_id = "facility_scp_062de",
		team = 2,
		display = "SCP-062-DE",
		color = Color(190, 190, 190, 255),
		objective = "突破收容，清除设施内人员",
		max = 1,
	},
	scp_0762 = {
		faction_id = "facility_scp_0762",
		team = 2,
		display = "SCP-076-2",
		color = Color(190, 190, 190, 255),
		objective = "突破收容，清除设施内人员",
		max = 1,
	},
	scp_912 = {
		faction_id = "facility_scp_912",
		team = 2,
		display = "SCP-912",
		color = Color(190, 190, 190, 255),
		objective = "突破收容，清除设施内人员",
		max = 1,
	},
}

local SCIENCE_ROLE_KEYS = { "doctor", "senior_scientist", "researcher" }
local SECURITY_RANK_KEYS = {
	"security_rookie",
	"security_officer",
	"security_sergeant",
	"security_warden",
	"security_captain",
}

local function RX_Shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function RX_Take(pool)
	if #pool == 0 then return nil end
	return table.remove(pool, 1)
end

function MissionIntro.RXSendPickSecurityRank(captainUsed)
	local pool = {}
	for _, key in ipairs(SECURITY_RANK_KEYS) do
		if key == "security_captain" and captainUsed then continue end
		pool[#pool + 1] = key
	end
	if #pool == 0 then
		pool = { "security_rookie", "security_officer", "security_sergeant", "security_warden" }
	end
	local pick = pool[math.random(#pool)]
	if pick == "security_captain" then
		return pick, true
	end
	return pick, captainUsed
end

local function RX_LegacyClassDSlots(numPlayers)
	return math.max(0, math.floor(numPlayers * 2 / 5))
end

function MissionIntro.RXSendCountSecurity(numPlayers)
	if MissionIntro.RXSendSecurityPerFive == true then
		local base = math.max(0, math.floor(numPlayers / 5))
		if MissionIntro.RXSendClassDPerFiveDouble == true then
			local trimmed = RX_LegacyClassDSlots(numPlayers) - MissionIntro.RXSendCountClassD(numPlayers)
			return base + math.max(0, trimmed)
		end
		return base
	end
	if MissionIntro.RXSendSecurityPerFour ~= false then
		return math.max(0, math.floor(numPlayers / 4))
	end
	local per = tonumber(MissionIntro.RXSendSecurityPerPlayers) or 10
	if numPlayers < 4 or per <= 0 then return 0 end
	return math.max(1, math.ceil(numPlayers / per))
end

function MissionIntro.RXSendCountClassD(numPlayers)
	if MissionIntro.RXSendClassDPerFiveDouble == true then
		return math.max(0, math.floor((numPlayers + 1) / 3))
	end
	if MissionIntro.RXSendClassDPerFour ~= false then
		return math.max(0, math.floor(numPlayers / 4))
	end
	local per = tonumber(MissionIntro.RXSendClassDPerScience) or 3
	if per <= 0 or numPlayers <= 0 then return 0 end
	return math.floor(numPlayers / per)
end

function MissionIntro.RXSendCountMaynard(numPlayers)
	if numPlayers < (tonumber(MissionIntro.RXSendMaynardMinPlayers) or 12) then return 0 end
	return 1
end

function MissionIntro.RXSendCountScp(numPlayers)
	if numPlayers < (tonumber(MissionIntro.RXSendScpMinPlayers) or 12) then return 0 end
	return math.min(1, math.max(1, tonumber(MissionIntro.RXSendScpMax) or 1))
end

function MissionIntro.RXSendRefillScpRoleDeck()
	local deck = {}
	for _, roleKey in ipairs(MissionIntro.RXSendScpRandomRoles or {}) do
		if isstring(roleKey) and roleKey ~= "" and MissionIntro.RXSendGetRoleDef(roleKey) then
			deck[#deck + 1] = roleKey
		end
	end

	if #deck == 0 then
		deck = { "scp_062de", "scp_0762", "scp_912" }
	end

	RX_Shuffle(deck)
	MissionIntro._rxSendScpRoleDeck = deck
	return deck
end

function MissionIntro.RXSendPickRandomScpRole()
	local deck = MissionIntro._rxSendScpRoleDeck
	if not istable(deck) or #deck == 0 then
		deck = MissionIntro.RXSendRefillScpRoleDeck()
	end

	local roleKey = table.remove(deck, 1)
	if not isstring(roleKey) or roleKey == "" or not MissionIntro.RXSendGetRoleDef(roleKey) then
		return MissionIntro.RXSendRefillScpRoleDeck()[1] or "scp_062de"
	end

	return roleKey
end

function MissionIntro.RXSendCountCi(numPlayers)
	if numPlayers < (tonumber(MissionIntro.RXSendCiMinPlayers) or 9) then return 0 end
	return 1
end

function MissionIntro.RXSendCountSiteDirector(numPlayers)
	if numPlayers < (tonumber(MissionIntro.RXSendMtfSiteDirectorMinPlayers) or 15) then return 0 end
	return 1
end

function MissionIntro.RXSendCountPlayingPlayers()
	local n = 0
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and ply:Team() ~= TEAM_SPECTATOR then
			n = n + 1
		end
	end
	return n
end

local RX_SITE_DIRECTOR_PROMOTE_ROLES = {
	security_rookie = true,
	security_officer = true,
	security_sergeant = true,
	security_warden = true,
	security_captain = true,
	researcher = true,
	doctor = true,
	senior_scientist = true,
}

function MissionIntro.RXSendFindActiveSiteDirector()
	if not MissionIntro.RXSendIsActive() then return nil end

	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if ply._missionIntroEvacuated then continue end

		local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
		local inPlay = ply:Alive() or (IsValid(ply.FakeRagdoll) and ply._missionIntroEvacuated ~= true)

		if roleKey == "site_director" and inPlay then
			return ply
		end

		local facId = MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply)
			or ply:GetNWString("MissionIntro_FactionId", "")
		if facId == "facility_mtf_site_director" and inPlay then
			return ply
		end
	end

	return nil
end

function MissionIntro.RXSendPickSiteDirectorCandidate(exclude)
	exclude = exclude or {}
	local candidates = {}

	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if exclude[ply] then continue end
		if ply._missionIntroEvacuated then continue end
		if not ply:Alive() then continue end

		local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
		if roleKey == "site_director" then continue end
		if roleKey == "uiu_spy" or roleKey == "dr_maynard" or roleKey == "ci_spy" then continue end
		if MissionIntro.IsFacilityScpRoleKey and MissionIntro.IsFacilityScpRoleKey(roleKey) then continue end
		if roleKey == "class_d_personnel" or roleKey == "classd_impostor" or roleKey == "ethics" then continue end

		if roleKey == "" then continue end
		if not RX_SITE_DIRECTOR_PROMOTE_ROLES[roleKey] then continue end

		candidates[#candidates + 1] = ply
	end

	if #candidates == 0 then return nil end
	return candidates[math.random(#candidates)]
end

function MissionIntro.RXSendCountDoctors(trueScience)
	local per = tonumber(MissionIntro.RXSendDoctorPerScience) or 3
	if per <= 0 or trueScience <= 0 then return 0 end
	return math.floor(trueScience / per)
end

-- 医生之外：每 3 名科研人员配 1 名高研
function MissionIntro.RXSendCountSeniors(remainingScience)
	local per = tonumber(MissionIntro.RXSendResearchersPerSenior) or 3
	if per <= 0 or remainingScience <= 0 then return 0 end
	return math.floor(remainingScience / (per + 1))
end

-- 有 D 级槽位时最多 1 名切皮（25% 概率），其余槽位均为真 D 级；因 D 级总数减少空出的名额进科研池
local function RX_SplitClassDSlots(classdSlots)
	if classdSlots <= 0 then
		return 0, 0
	end

	local ratio = tonumber(MissionIntro.RXSendClassDPersonnelRatio) or 0.75
	local impostorSlots = 0
	if math.random() >= ratio then
		impostorSlots = 1
	end

	return classdSlots - impostorSlots, impostorSlots
end

function MissionIntro.RXSendAllocateRoles(players)
	players = players or {}
	local pool = {}
	for _, ply in ipairs(players) do
		if IsValid(ply) and ply:IsPlayer() then
			pool[#pool + 1] = ply
		end
	end

	RX_Shuffle(pool)
	local numPlayers = #pool
	local assignments = {}
	local counts = {}

	local function assign(ply, roleKey)
		if not IsValid(ply) then return end
		assignments[ply] = roleKey
		counts[roleKey] = (counts[roleKey] or 0) + 1
	end

	local ethicsSlots = math.min(1, numPlayers)
	for _ = 1, ethicsSlots do
		assign(RX_Take(pool), "ethics")
	end

	if numPlayers >= (tonumber(MissionIntro.RXSendUiuMinPlayers) or 9) then
		assign(RX_Take(pool), "uiu_spy")
	end

	local ciSlots = MissionIntro.RXSendCountCi(numPlayers)
	for _ = 1, ciSlots do
		assign(RX_Take(pool), "ci_spy")
	end

	local maynardSlots = MissionIntro.RXSendCountMaynard(numPlayers)
	for _ = 1, maynardSlots do
		assign(RX_Take(pool), "dr_maynard")
	end

	local scpSlots = MissionIntro.RXSendCountScp(numPlayers)
	for _ = 1, scpSlots do
		assign(RX_Take(pool), MissionIntro.RXSendPickRandomScpRole())
	end

	local siteDirectorSlots = MissionIntro.RXSendCountSiteDirector(numPlayers)
	for _ = 1, siteDirectorSlots do
		assign(RX_Take(pool), "site_director")
	end

	local securitySlots = MissionIntro.RXSendCountSecurity(numPlayers)
	local captainUsed = false
	for _ = 1, securitySlots do
		local rankKey
		rankKey, captainUsed = MissionIntro.RXSendPickSecurityRank(captainUsed)
		assign(RX_Take(pool), rankKey)
	end

	local classdSlots = MissionIntro.RXSendCountClassD(numPlayers)
	local personnelSlots, impostorSlots = RX_SplitClassDSlots(classdSlots)
	for _ = 1, personnelSlots do
		assign(RX_Take(pool), "class_d_personnel")
	end
	for _ = 1, impostorSlots do
		assign(RX_Take(pool), "classd_impostor")
	end

	local sciencePool = #pool
	local doctorSlots = MissionIntro.RXSendCountDoctors(sciencePool)
	local afterDoctors = math.max(0, sciencePool - doctorSlots)
	local seniorSlots = MissionIntro.RXSendCountSeniors(afterDoctors)
	local researcherSlots = math.max(0, afterDoctors - seniorSlots)

	for _ = 1, doctorSlots do
		assign(RX_Take(pool), "doctor")
	end

	for _ = 1, seniorSlots do
		assign(RX_Take(pool), "senior_scientist")
	end

	for _ = 1, researcherSlots do
		assign(RX_Take(pool), "researcher")
	end

	while #pool > 0 do
		assign(RX_Take(pool), "researcher")
	end

	return assignments, counts, numPlayers
end

function MissionIntro.RXSendGetRoleDef(roleKey)
	return MissionIntro.RXSendRoleDefs and MissionIntro.RXSendRoleDefs[roleKey]
end

function MissionIntro.RXSendApplyRoleToPlayer(ply, roleKey, classDRoleId)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end

	local def = MissionIntro.RXSendGetRoleDef(roleKey)
	if not def then return false end

	if MissionIntro.ClearPlayerMissionIntroState then
		MissionIntro.ClearPlayerMissionIntroState(ply)
	end

	if MissionIntro.ClearClassDRole then
		MissionIntro.ClearClassDRole(ply)
	end

	ply.RXSendRoleKey = roleKey
	ply:SetNWString("RXSend_RoleKey", roleKey)
	ply:SetNWString("RXSend_RoleDisplay", def.display or "")
	ply:SetNWString("RXSend_Objective", def.objective or "")

	if MissionIntro.RXSendSyncPlayerTeam then
		MissionIntro.RXSendSyncPlayerTeam(ply)
	elseif isnumber(def.team) then
		ply:SetTeam(def.team)
	end

	if roleKey == "class_d_personnel" then
		if isstring(classDRoleId) and classDRoleId ~= "" and MissionIntro.AssignClassDRole then
			MissionIntro.AssignClassDRole(ply, classDRoleId)
		elseif MissionIntro.AssignRandomClassDRoleForPlayer then
			MissionIntro.AssignRandomClassDRoleForPlayer(ply)
		end
		local savedClassD = ply:GetNWString("MissionIntro_ClassDRole", "")
		if savedClassD ~= "" then
			ply:SetNWString("RXSend_PanelClassDRole", savedClassD)
		end
		if MissionIntro.GetClassDRoleData then
			local classData = MissionIntro.GetClassDRoleData(ply)
			if classData then
				local display = classData.role_label or classData.title or def.display
				ply:SetNWString("RXSend_RoleDisplay", display)
				if MissionIntro.SyncHudRoleDisplay then
					MissionIntro.SyncHudRoleDisplay(ply)
				elseif zb and zb.GiveRole then
					zb.GiveRole(ply, display, def.color or color_white)
				end
			end
		end
	elseif MissionIntro.AssignFacilityFaction and def.faction_id then
		MissionIntro.AssignFacilityFaction(ply, def.faction_id)
	elseif def.faction_id then
		ply._missionIntroFaction = def.faction_id
		ply:SetNWString("MissionIntro_FactionId", def.faction_id)
	end

	if MissionIntro.IsFacilityScpRoleKey and MissionIntro.IsFacilityScpRoleKey(roleKey) then
		if MissionIntro.SetFacilityScpPlayerFlag then
			MissionIntro.SetFacilityScpPlayerFlag(ply, true)
		end
		if MissionIntro.ApplyFacilityScpTraits then
			MissionIntro.ApplyFacilityScpTraits(ply)
		end
		if MissionIntro.ScheduleFacilityScpSpawnArmorRefresh then
			MissionIntro.ScheduleFacilityScpSpawnArmorRefresh(ply)
		end
	end

	if zb and zb.GiveRole then
		if MissionIntro.SyncHudRoleDisplay then
			MissionIntro.SyncHudRoleDisplay(ply)
		else
			zb.GiveRole(ply, def.display, def.color or color_white)
		end
	end

	if MissionIntro.ClearIntroRewardLock then
		MissionIntro.ClearIntroRewardLock(ply)
	end

	if SERVER then
		ply:SetNWBool("RXSend_TeamPanelHide", false)
		if MissionIntro.RXSendSyncBattleTeamNW then
			MissionIntro.RXSendSyncBattleTeamNW(ply)
		end
	end

	return true
end

function MissionIntro.RXSendGiveLoadout(ply)
	if not SERVER or not IsValid(ply) then return false end
	if not MissionIntro.TryGiveRewards then return false end
	return MissionIntro.TryGiveRewards(ply) == true
end

function MissionIntro.RXSendAssignAllPlayers(players)
	if not SERVER then return {} end

	local assignments = MissionIntro.RXSendAllocateRoles(players)
	local classDPlayers = {}

	for ply, roleKey in pairs(assignments) do
		if roleKey == "class_d_personnel" then
			classDPlayers[#classDPlayers + 1] = ply
		else
			MissionIntro.RXSendApplyRoleToPlayer(ply, roleKey)
		end
	end

	if #classDPlayers > 0 then
		RX_Shuffle(classDPlayers)
		local deck = MissionIntro.BuildClassDRoleDeck and MissionIntro.BuildClassDRoleDeck(#classDPlayers) or {}
		for i, ply in ipairs(classDPlayers) do
			MissionIntro.RXSendApplyRoleToPlayer(ply, "class_d_personnel", deck[i])
		end
	end

	return assignments
end

local function RX_ResolveFacilityIntroFactionId(ply)
	if not IsValid(ply) then return nil end

	local fac = MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply)
		or ply:GetNWString("MissionIntro_FactionId", "")
	if fac == "" then return nil end

	if MissionIntro.IsFacilityMtfFactionId and MissionIntro.IsFacilityMtfFactionId(fac) then
		return fac
	end

	if MissionIntro.IsFacilityQrfFactionId and MissionIntro.IsFacilityQrfFactionId(fac) then
		return fac
	end

	local roleKey = (MissionIntro.RXSendGetPlayerRoleKey and MissionIntro.RXSendGetPlayerRoleKey(ply))
		or ply:GetNWString("RXSend_RoleKey", "")
	if roleKey ~= "" and MissionIntro.RXSendGetRoleDef then
		local def = MissionIntro.RXSendGetRoleDef(roleKey)
		if def and isstring(def.faction_id) and def.faction_id ~= "" then
			return def.faction_id
		end
	end

	return fac
end

function MissionIntro.RXSendStartRoundIntro(players)
	if not SERVER then return false end

	local scienceList = {}
	local mtfLists = {}
	local qrfList = {}
	local scpByFaction = {}

	for _, ply in ipairs(players or {}) do
		if not IsValid(ply) or not ply:IsPlayer() or ply:Team() == TEAM_SPECTATOR then continue end
		local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
		if MissionIntro.IsFacilityScpRoleKey and MissionIntro.IsFacilityScpRoleKey(roleKey) then
			local facId = RX_ResolveFacilityIntroFactionId(ply) or "facility_scp_062de"
			scpByFaction[facId] = scpByFaction[facId] or {}
			scpByFaction[facId][#scpByFaction[facId] + 1] = ply
			continue
		end

		local fac = RX_ResolveFacilityIntroFactionId(ply)
		if not fac then continue end

		if MissionIntro.IsFacilityMtfFactionId and MissionIntro.IsFacilityMtfFactionId(fac) then
			mtfLists[fac] = mtfLists[fac] or {}
			mtfLists[fac][#mtfLists[fac] + 1] = ply
		elseif MissionIntro.IsFacilityQrfFactionId and MissionIntro.IsFacilityQrfFactionId(fac) then
			qrfList[#qrfList + 1] = ply
		else
			scienceList[#scienceList + 1] = ply
		end
	end

	local started = false

	for facId, scpList in pairs(scpByFaction) do
		if #scpList > 0 and MissionIntro.BatchRespawnAndStartIntro then
			MissionIntro.BatchRespawnAndStartIntro(scpList, {
				factionId = facId,
				introOnly = true,
			})
			started = true
		end
	end

	if #scienceList > 0 and MissionIntro.BatchRespawnAndStartIntro then
		MissionIntro.BatchRespawnAndStartIntro(scienceList, {
			factionId = "facility_science_batch",
			introOnly = true,
		})
		started = true
	end

	if #qrfList > 0 and MissionIntro.BatchRespawnAndStartIntro then
		MissionIntro.BatchRespawnAndStartIntro(qrfList, {
			factionId = "facility_qrf_batch",
			introOnly = true,
		})
		started = true
	end

	for facId, list in pairs(mtfLists) do
		if #list > 0 and MissionIntro.BatchRespawnAndStartIntro then
			MissionIntro.BatchRespawnAndStartIntro(list, {
				factionId = facId,
				introOnly = true,
			})
			started = true
		end
	end

	if started then return true end

	if MissionIntro.StartFacilityIntroBatch and #scienceList > 0 then
		return MissionIntro.StartFacilityIntroBatch(scienceList, "facility_science_batch") == true
	end

	return false
end
