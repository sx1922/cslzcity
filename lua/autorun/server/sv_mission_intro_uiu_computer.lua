if not SERVER then return end

MissionIntro._uiuMissionActive = MissionIntro._uiuMissionActive or false
MissionIntro._uiuMissionComplete = MissionIntro._uiuMissionComplete or false
MissionIntro._uiuHackedCount = MissionIntro._uiuHackedCount or 0
MissionIntro.UiuComputerPersistEnabled = MissionIntro.UiuComputerPersistEnabled ~= false

util.AddNetworkString("MissionIntro_UiuComputerSync")
util.AddNetworkString("MissionIntro_UiuTakeover")
util.AddNetworkString("MissionIntro_UiuHackAudio")
util.AddNetworkString("MissionIntro_UiuHackUseSound")

local SCREEN = MissionIntro.UiuComputerScreen or { off = 0, white = 1, green = 2, red = 3 }

local UIU_AUDIO_STOP = 3
local UIU_AUDIO_START = 1
local UIU_AUDIO_COMPLETE = 2
local UIU_AUDIO_USE = 4

function MissionIntro.SendUiuHackAudio(ply, action)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	net.Start("MissionIntro_UiuHackAudio")
		net.WriteUInt(action, 3)
	net.Send(ply)
end

function MissionIntro.BroadcastUiuHackAudioToUiu(action)
	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.ShouldShowUiuComputerHud and MissionIntro.ShouldShowUiuComputerHud(ply) then
			MissionIntro.SendUiuHackAudio(ply, action)
		end
	end
end

function MissionIntro.BroadcastUiuHackAudioStopToUiu()
	MissionIntro.BroadcastUiuHackAudioToUiu(UIU_AUDIO_STOP)
end

function MissionIntro.StopUiuHackAudioForPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	MissionIntro.SendUiuHackAudio(ply, UIU_AUDIO_STOP)
end

function MissionIntro.BroadcastUiuHackAudioStopAll()
	for _, ply in ipairs(player.GetAll()) do
		MissionIntro.SendUiuHackAudio(ply, UIU_AUDIO_STOP)
	end
end

local function MI_ComputerDir()
	return "rx_mission_intro/uiu_computers"
end

function MissionIntro.GetUiuComputerSavePath()
	return MI_ComputerDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureUiuComputerSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_ComputerDir(), "DATA") then
		file.CreateDir(MI_ComputerDir())
	end
end

function MissionIntro.GetUiuComputers()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_computer")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end
	return list
end

function MissionIntro.CountUiuComputersByState(state)
	local n = 0
	for _, ent in ipairs(MissionIntro.GetUiuComputers()) do
		if ent:GetScreenState() == state then
			n = n + 1
		end
	end
	return n
end

local function MI_GetUiuEscapeText()
	local cfg = MissionIntro.UiuComputer or {}
	if isstring(cfg.escape_text) and cfg.escape_text ~= "" then
		return cfg.escape_text
	end
	if MissionIntro.L then
		return MissionIntro.L("uiu_escape_line")
	end
	return "????????????????????????!"
end

local function MI_GetUiuLockdownText()
	local cfg = MissionIntro.UiuComputer or {}
	if isstring(cfg.lockdown_text) and cfg.lockdown_text ~= "" then
		return cfg.lockdown_text
	end
	if MissionIntro.L then
		return MissionIntro.L("uiu_lockdown_line")
	end
	return "??????????"
end

local function MI_SendUiuComputerSync(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local goal = MissionIntro.GetUiuComputerGoal()
	local hacked = MissionIntro._uiuHackedCount or (MissionIntro.CountUiuHackableRed and MissionIntro.CountUiuHackableRed() or MissionIntro.CountUiuComputersByState(SCREEN.red))
	local showHud = MissionIntro.ShouldShowUiuComputerHud and MissionIntro.ShouldShowUiuComputerHud(ply) or false
	local showEvacMarkers = MissionIntro.ShouldShowUiuEvacMarkers and MissionIntro.ShouldShowUiuEvacMarkers(ply) or false

	net.Start("MissionIntro_UiuComputerSync")
		net.WriteBool(MissionIntro._uiuMissionActive)
		net.WriteBool(MissionIntro._uiuMissionComplete)
		net.WriteBool(showHud)
		net.WriteUInt(hacked, 8)
		net.WriteUInt(goal, 8)
		net.WriteBool(showEvacMarkers)
		net.WriteBool(MissionIntro.IsUiuTerminalUnlocked and MissionIntro.IsUiuTerminalUnlocked() or false)
		net.WriteBool(MissionIntro._uiuReinforceCalled == true)
	net.Send(ply)
end

function MissionIntro.SyncUiuComputerProgress(target)
	MissionIntro._uiuHackedCount = MissionIntro.CountUiuHackableRed and MissionIntro.CountUiuHackableRed() or MissionIntro.CountUiuComputersByState(SCREEN.red)

	if IsValid(target) and target:IsPlayer() then
		MI_SendUiuComputerSync(target)
		return
	end

	for _, ply in ipairs(player.GetAll()) do
		MI_SendUiuComputerSync(ply)
	end
end

function MissionIntro.SendMissionCompleteAlert(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local cfg = MissionIntro.UiuComputer or {}
	local dur = tonumber(cfg.takeover_duration) or 10
	local text = MI_GetUiuLockdownText()

	if MissionIntro.ShouldShowUiuComputerHud and MissionIntro.ShouldShowUiuComputerHud(ply) then
		text = MI_GetUiuEscapeText()
	end

	net.Start("MissionIntro_UiuTakeover")
		net.WriteString(text)
		net.WriteFloat(dur)
	net.Send(ply)
end

function MissionIntro.BroadcastMissionCompleteAlerts()
	for _, ply in ipairs(player.GetAll()) do
		MissionIntro.SendMissionCompleteAlert(ply)
	end
end

function MissionIntro.ResetUiuComputersToOff()
	for _, ent in ipairs(MissionIntro.GetUiuComputers()) do
		if not IsValid(ent) then continue end
		if ent.SetHackable then
			ent:SetHackable(false)
		end
		if ent.SetScreenStateSafe then
			ent:SetScreenStateSafe(SCREEN.off)
		end
	end
end

function MissionIntro.AssignUiuHackableComputers()
	local computers = MissionIntro.GetUiuComputers()
	local goal = MissionIntro.GetUiuComputerGoal()
	local pool = {}

	for _, ent in ipairs(computers) do
		if not IsValid(ent) then continue end
		if ent.SetHackable then
			ent:SetHackable(false)
		end
		pool[#pool + 1] = ent
	end

	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end

	local pick = math.min(goal, #pool)
	for i = 1, pick do
		if pool[i].SetHackable then
			pool[i]:SetHackable(true)
		end
		if pool[i].ApplyScreenColor then
			pool[i]:ApplyScreenColor()
		end
	end

	for i = pick + 1, #pool do
		if pool[i].ApplyScreenColor then
			pool[i]:ApplyScreenColor()
		end
	end

	MissionIntro._uiuHackableCount = pick
	return pick, #pool
end

function MissionIntro.ActivateUiuComputersWhite()
	for _, ent in ipairs(MissionIntro.GetUiuComputers()) do
		if not IsValid(ent) then continue end
		if ent:GetScreenState() == SCREEN.red then continue end
		if ent.SetScreenStateSafe then
			ent:SetScreenStateSafe(SCREEN.white)
		end
	end
end

function MissionIntro.StartUiuComputerMission()
	local computers = MissionIntro.GetUiuComputers()
	local goal = MissionIntro.GetUiuComputerGoal()

	MissionIntro._uiuMissionActive = true
	MissionIntro._uiuMissionComplete = false
	MissionIntro._uiuHackedCount = 0
	MissionIntro._uiuHackStartSoundPlayed = false

	if MissionIntro.ResetUiuTerminalMissionState then
		MissionIntro.ResetUiuTerminalMissionState()
	end

	for _, ent in ipairs(computers) do
		if IsValid(ent) and ent.SetScreenStateSafe then
			ent:SetScreenStateSafe(SCREEN.white)
			ent:SetHacker(NULL)
			ent:SetHackEndTime(0)
		end
	end

	local pick, total = MissionIntro.AssignUiuHackableComputers()

	if total < goal then
		MsgN("[MissionIntro] ??: ?? UIU ??? " .. total .. " ?????? " .. goal .. " ??????????")
	end

	MsgN("[MissionIntro] UIU ????: ??? " .. pick .. " / " .. total .. " ????")

	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.ShouldShowUiuComputerHud and MissionIntro.ShouldShowUiuComputerHud(ply) then
			ply:ChatPrint("[UIU] ??? " .. total .. " ?????? " .. pick .. " ?????")
		end
	end

	MissionIntro.SyncUiuComputerProgress()
end

function MissionIntro.StopUiuComputerMission()
	MissionIntro._uiuMissionActive = false
	MissionIntro._uiuHackStartSoundPlayed = false
	MissionIntro.BroadcastUiuHackAudioStopAll()
	MissionIntro.ResetUiuComputersToOff()
	if MissionIntro.ResetUiuTerminalMissionState then
		MissionIntro.ResetUiuTerminalMissionState()
	end
	MissionIntro.SyncUiuComputerProgress()
end

local UIU_MISSION_FACTIONS = {
	uiu_spy = true,
	uiu_taskforce = true,
	sid_squad = true,
}

function MissionIntro.ShouldRunUiuComputerMission()
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end

		if MissionIntro.IsUiuSpyPlayer and MissionIntro.IsUiuSpyPlayer(ply) then
			return true
		end

		if MissionIntro.RXSendGetPlayerRoleKey and MissionIntro.RXSendGetPlayerRoleKey(ply) == "uiu_spy" then
			return true
		end

		local fac = ply._missionIntroFaction or ply:GetNWString("MissionIntro_FactionId", "")
		if UIU_MISSION_FACTIONS[fac] then
			return true
		end
	end

	return false
end

function MissionIntro.TryStartUiuComputerMissionIfNeeded()
	if MissionIntro._uiuMissionActive then return false end
	if not MissionIntro.ShouldRunUiuComputerMission() then return false end
	MissionIntro.StartUiuComputerMission()
	return true
end

function MissionIntro.CheckUiuComputerMissionComplete()
	if MissionIntro._uiuMissionComplete then return end
	if not MissionIntro._uiuMissionActive then return end

	local goal = MissionIntro.GetUiuComputerGoal()
	local hacked = MissionIntro.CountUiuHackableRed and MissionIntro.CountUiuHackableRed() or MissionIntro.CountUiuComputersByState(SCREEN.red)

	if hacked < goal then
		MissionIntro.SyncUiuComputerProgress()
		return
	end

	MissionIntro._uiuMissionComplete = true
	MissionIntro._uiuHackedCount = hacked
	MissionIntro.BroadcastUiuHackAudioToUiu(UIU_AUDIO_COMPLETE)
	MissionIntro.SyncUiuComputerProgress()

	if MissionIntro.OnUiuComputerMissionReadyForTerminal then
		MissionIntro.OnUiuComputerMissionReadyForTerminal()
	end

	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.ShouldShowUiuEvacMarkers and MissionIntro.ShouldShowUiuEvacMarkers(ply) then
			local evacN = #(MissionIntro.GetUiuEvacEntities and MissionIntro.GetUiuEvacEntities() or ents.FindByClass("ent_mission_intro_uiu_evac"))
			local msg = MissionIntro.L and MissionIntro.L("uiu_evac_marked") or "[UIU] ???????????????"
			if evacN > 0 then
				msg = msg .. "?" .. evacN .. " ??"
			end
			ply:ChatPrint(msg)
		end
	end

	MsgN("[MissionIntro] UIU ?????? (" .. hacked .. "/" .. goal .. ")")
end

function MissionIntro.OnUiuComputerHackComplete(ent)
	if not MissionIntro._uiuHackStartSoundPlayed then
		MissionIntro._uiuHackStartSoundPlayed = true
		MissionIntro.BroadcastUiuHackAudioToUiu(UIU_AUDIO_START)
	end
	MissionIntro.CheckUiuComputerMissionComplete()
end

function MissionIntro.OnUiuComputerHackCancelled(ent)
	MissionIntro.SyncUiuComputerProgress()
end

function MissionIntro.OnUiuComputerHackStarted(ent, ply)
	MissionIntro.SyncUiuComputerProgress()
end

function MissionIntro.OnUiuComputerRemoved(ent)
	timer.Simple(0, function()
		if MissionIntro._uiuMissionActive then
			MissionIntro.CheckUiuComputerMissionComplete()
		end
		MissionIntro.SyncUiuComputerProgress()
	end)
end

function MissionIntro.ExportUiuComputers()
	local out = {}
	for _, ent in ipairs(MissionIntro.GetUiuComputers()) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		out[#out + 1] = {
			pos = { x = pos.x, y = pos.y, z = pos.z },
			ang = { p = ang.p, y = ang.y, r = ang.r },
		}
	end
	return out
end

function MissionIntro.CanSaveUiuComputers()
	if not MissionIntro.UiuComputerPersistEnabled then return false end
	if MissionIntro._loadingUiuComputers then return false end
	if MissionIntro._suppressUiuComputerSave then return false end
	return true
end

function MissionIntro.ReadUiuComputersFromDisk()
	if not MissionIntro.UiuComputerPersistEnabled then return {} end

	local path = MissionIntro.GetUiuComputerSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteUiuComputersToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureUiuComputerSaveDir()
	file.Write(MissionIntro.GetUiuComputerSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveUiuComputersToDisk()
	if not MissionIntro.CanSaveUiuComputers() then return false end

	local data = MissionIntro.ExportUiuComputers()
	MissionIntro.WriteUiuComputersToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_uiu_computer"), MissionIntro.GetUiuComputerSavePath())
	return true
end

function MissionIntro.CacheUiuComputersBeforeCleanup()
	MissionIntro._suppressUiuComputerSave = true

	local live = MissionIntro.ExportUiuComputers()
	local rows = (#live > 0) and live or MissionIntro.ReadUiuComputersFromDisk()
	MissionIntro._uiuComputerPersistCache = rows

	if MissionIntro.UiuComputerPersistEnabled then
		MissionIntro.WriteUiuComputersToDisk(rows)
	end

	MissionIntro.ServerMsg("log_cached", #rows, MissionIntro.L("log_entity_uiu_computer"))
	return rows
end

function MissionIntro.LoadUiuComputersFromDisk(rows)
	if MissionIntro._loadingUiuComputers then return end
	MissionIntro._loadingUiuComputers = true

	rows = rows or MissionIntro.ReadUiuComputersFromDisk()

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_computer")) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end

		if MissionIntro.CreateUiuComputer then
			MissionIntro.CreateUiuComputer(pos, ang, true)
		end
	end

	MissionIntro._loadingUiuComputers = false
	MissionIntro.ServerMsg("log_loaded", #rows, MissionIntro.L("log_entity_uiu_computer"), MissionIntro.GetUiuComputerSavePath())
end

function MissionIntro.CreateUiuComputer(pos, ang, silent)
	local ent = ents.Create("ent_mission_intro_uiu_computer")
	if not IsValid(ent) then return nil end

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	if not silent and MissionIntro.SaveUiuComputersToDisk then
		MissionIntro.SaveUiuComputersToDisk()
	end

	return ent
end

function MissionIntro.RemoveAllUiuComputers(save)
	MissionIntro._suppressUiuComputerSave = true

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_computer")) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressUiuComputerSave = false

	if save ~= false and MissionIntro.SaveUiuComputersToDisk then
		MissionIntro.SaveUiuComputersToDisk()
	end
end

function MissionIntro.RequestSaveUiuComputers()
	if not MissionIntro.CanSaveUiuComputers() then return end
	timer.Simple(0, function()
		MissionIntro.SaveUiuComputersToDisk()
	end)
end

local function MI_ScheduleReloadUiuComputers()
	timer.Create("MissionIntro_ReloadUiuComputers", 0.5, 1, function()
		local rows = MissionIntro._uiuComputerPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadUiuComputersFromDisk()
		end
		MissionIntro._uiuComputerPersistCache = nil
		if MissionIntro.LoadUiuComputersFromDisk then
			MissionIntro.LoadUiuComputersFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadUiuComputers", MI_ScheduleReloadUiuComputers)

hook.Add("PreCleanupMap", "MissionIntro_KeepUiuComputers", function()
	if MissionIntro.CacheUiuComputersBeforeCleanup then
		MissionIntro.CacheUiuComputersBeforeCleanup()
	end
end)

hook.Add("PostCleanupMap", "MissionIntro_ReloadUiuComputers", MI_ScheduleReloadUiuComputers)

hook.Add("PostCleanup", "MissionIntro_ReloadUiuComputers", MI_ScheduleReloadUiuComputers)

hook.Add("ShutDown", "MissionIntro_SaveUiuComputers", function()
	MissionIntro._suppressUiuComputerSave = false
	if MissionIntro.SaveUiuComputersToDisk then
		MissionIntro.SaveUiuComputersToDisk()
	end
end)

hook.Add("PlayerInitialSpawn", "MissionIntro_UiuComputerSync", function(ply)
	timer.Simple(2, function()
		if IsValid(ply) and MissionIntro.SyncUiuComputerProgress then
			MissionIntro.SyncUiuComputerProgress(ply)
		end
	end)
end)

hook.Add("PlayerDeath", "MissionIntro_UiuStopHackAudio", function(ply)
	if MissionIntro.StopUiuHackAudioForPlayer then
		MissionIntro.StopUiuHackAudioForPlayer(ply)
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_UiuStopHackAudio", function(ply)
	if MissionIntro.StopUiuHackAudioForPlayer then
		MissionIntro.StopUiuHackAudioForPlayer(ply)
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_UiuComputerCancelHack", function(ply)
	for _, ent in ipairs(MissionIntro.GetUiuComputers()) do
		if IsValid(ent) and ent:GetHacker() == ply and ent:GetScreenState() == SCREEN.green then
			ent:CancelHack()
		end
	end
end)

hook.Add("MissionIntro_RXSendIntermissionDone", "MissionIntro_UiuComputerRxsend", function()
	if not MissionIntro.RXSendIsActive or not MissionIntro.RXSendIsActive() then return end

	timer.Simple(0, function()
		if not MissionIntro.RXSendIsActive or not MissionIntro.RXSendIsActive() then return end
		if MissionIntro.TryStartUiuComputerMissionIfNeeded then
			MissionIntro.TryStartUiuComputerMissionIfNeeded()
		end
	end)
end)

concommand.Add("mission_intro_uiu_start", function(ply)
	if IsValid(ply) and MissionIntro.CanManage and not MissionIntro.CanManage(ply) then return end
	MissionIntro.StartUiuComputerMission()
	if IsValid(ply) then
		ply:ChatPrint("[MissionIntro] UIU ???????")
	end
end)

concommand.Add("mission_intro_uiu_stop", function(ply)
	if IsValid(ply) and MissionIntro.CanManage and not MissionIntro.CanManage(ply) then return end
	MissionIntro.StopUiuComputerMission()
	if IsValid(ply) then
		ply:ChatPrint("[MissionIntro] UIU ???????")
	end
end)
