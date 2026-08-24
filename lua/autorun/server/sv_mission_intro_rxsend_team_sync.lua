if not SERVER then return end

MissionIntro = MissionIntro or {}

local function MI_SyncAllRxsendBattleTeams()
	if not MissionIntro.RXSendIsActive() then return end
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() then
			if MissionIntro.RXSendSyncBattleTeamNW then
				MissionIntro.RXSendSyncBattleTeamNW(ply)
			end
		end
	end
end

hook.Add("PlayerSpawn", "MissionIntro_RxsendTeamPanelSpawn", function(ply)
	if not MissionIntro.RXSendIsActive() then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply:SetNWBool("RXSend_TeamPanelHide", false)
	timer.Simple(0, function()
		if IsValid(ply) and MissionIntro.RXSendIsActive() and MissionIntro.RXSendSyncBattleTeamNW then
			MissionIntro.RXSendSyncBattleTeamNW(ply)
		end
	end)

	if MissionIntro.SyncHudRoleDisplay then
		timer.Simple(0.2, function()
			if IsValid(ply) and ply:Alive() and MissionIntro.SyncHudRoleDisplay then
				MissionIntro.SyncHudRoleDisplay(ply)
			end
		end)
	end
end)

hook.Add("PlayerDeath", "MissionIntro_RxsendTeamPanelDeath", function(ply)
	if not MissionIntro.RXSendIsActive() then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply:SetNWBool("RXSend_TeamPanelHide", true)
	if MissionIntro.ClearRxsendRoundRoleAssignment then
		MissionIntro.ClearRxsendRoundRoleAssignment(ply)
	end
	MI_SyncAllRxsendBattleTeams()
end)

hook.Add("Fake Up", "MissionIntro_RxsendTeamPanelFakeUp", function(ply)
	if not MissionIntro.RXSendIsActive() then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if MissionIntro.RXSendRestorePanelAssignment then
		MissionIntro.RXSendRestorePanelAssignment(ply)
	else
		ply:SetNWBool("RXSend_TeamPanelHide", false)
		if MissionIntro.RXSendSyncBattleTeamNW then
			MissionIntro.RXSendSyncBattleTeamNW(ply)
		end
	end

	if MissionIntro.SyncHudRoleDisplay then
		timer.Simple(0.15, function()
			if IsValid(ply) and ply:Alive() and MissionIntro.SyncHudRoleDisplay then
				MissionIntro.SyncHudRoleDisplay(ply)
			end
		end)
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_RxsendTeamPanelDisconnect", function(ply)
	if not MissionIntro.RXSendIsActive() then return end
	if not IsValid(ply) then return end
	ply:SetNWBool("RXSend_TeamPanelHide", true)
end)

hook.Add("MissionIntro_FacilityFactionAssigned", "MissionIntro_RxsendTeamPanelFaction", function(ply)
	if not MissionIntro.RXSendIsActive() then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply:SetNWBool("RXSend_TeamPanelHide", false)
	if MissionIntro.RXSendSyncPlayerTeam then
		MissionIntro.RXSendSyncPlayerTeam(ply)
	elseif MissionIntro.RXSendSyncBattleTeamNW then
		MissionIntro.RXSendSyncBattleTeamNW(ply)
	end
	if MissionIntro.SyncHudRoleDisplay then
		timer.Simple(0.1, function()
			if IsValid(ply) then
				MissionIntro.SyncHudRoleDisplay(ply)
			end
		end)
	end
	MI_SyncAllRxsendBattleTeams()
end)

timer.Create("MissionIntro_RxsendTeamPanelResync", 0.5, 0, function()
	if not MissionIntro.RXSendIsActive() then return end
	MI_SyncAllRxsendBattleTeams()
end)
