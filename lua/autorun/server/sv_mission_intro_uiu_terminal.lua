if not SERVER then return end

MissionIntro._uiuReinforceCalled = MissionIntro._uiuReinforceCalled or false
MissionIntro.UiuTerminalPersistEnabled = MissionIntro.UiuTerminalPersistEnabled ~= false

util.AddNetworkString("MissionIntro_UiuTerminalOpen")
util.AddNetworkString("MissionIntro_UiuTerminalAction")

local STATE = MissionIntro.UiuTerminalState or { locked = 0, ready = 1, hacking = 2, used = 3 }

local function MI_ShuffleTable(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

local function MI_TerminalDir()
	return "rx_mission_intro/uiu_terminals"
end

function MissionIntro.GetUiuTerminalSavePath()
	return MI_TerminalDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureUiuTerminalSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_TerminalDir(), "DATA") then
		file.CreateDir(MI_TerminalDir())
	end
end

function MissionIntro.GetUiuTerminals()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_terminal")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end
	return list
end

function MissionIntro.RefreshUiuTerminalStates()
	local unlocked = MissionIntro.IsUiuTerminalUnlocked and MissionIntro.IsUiuTerminalUnlocked()
	local used = MissionIntro._uiuReinforceCalled == true

	for _, ent in ipairs(MissionIntro.GetUiuTerminals()) do
		if not IsValid(ent) then continue end

		if used then
			if ent:GetTerminalState() == STATE.hacking then
				if ent.SetHacker then ent:SetHacker(NULL) end
				if ent.SetHackEndTime then ent:SetHackEndTime(0) end
				if ent.StopHackUseSound then ent:StopHackUseSound() end
			end
			ent:SetTerminalStateSafe(STATE.used)
		elseif ent:GetTerminalState() == STATE.hacking then
			continue
		elseif unlocked then
			ent:SetTerminalStateSafe(STATE.ready)
		else
			ent:SetTerminalStateSafe(STATE.locked)
		end
	end
end

function MissionIntro.ResetUiuTerminalMissionState()
	MissionIntro._uiuReinforceCalled = false
	if MissionIntro.RefreshUiuTerminalStates then
		MissionIntro.RefreshUiuTerminalStates()
	end
end

function MissionIntro.BroadcastUiuTerminalForceAlert()
	if not MissionIntro.BroadcastCustomAlert then return end

	local cfg = MissionIntro.UiuTerminal or {}
	local line1 = MissionIntro.L and MissionIntro.L("uiu_terminal_warn_line1")
		or "?? ????????????"
	local line2 = MissionIntro.L and MissionIntro.L("uiu_terminal_warn_line2")
		or "??????????"

	MissionIntro.BroadcastCustomAlert({
		title = "Z city",
		line1 = line1,
		line2 = line2,
		sound = cfg.alert_sound or "mission_intro/aa_shutdown_alert.mp3",
		accent = Color(220, 90, 70),
	}, { playSound = true, forceSoundDuringIntro = true })
end

function MissionIntro.SpawnUiuReinforcements(triggerPly, opts)
	opts = opts or {}
	if MissionIntro._uiuReinforceCalled then return false, "already" end

	local reinforceFaction = "uiu_taskforce"
	local cfg = MissionIntro.UiuTerminal or {}
	local minN = tonumber(cfg.reinforce_min) or 4
	local maxN = tonumber(cfg.reinforce_max) or 7
	if minN > maxN then minN, maxN = maxN, minN end

	local dead = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and not ply:Alive() then
			dead[#dead + 1] = ply
		end
	end

	if #dead == 0 then
		local msg = MissionIntro.L and MissionIntro.L("uiu_terminal_no_dead")
			or "[UIU] ?????????????"
		if IsValid(triggerPly) then
			triggerPly:ChatPrint(msg)
		end
		return false, "no_dead"
	end

	MI_ShuffleTable(dead)

	local cap = #dead
	local want
	if cap < minN then
		want = cap
	else
		want = math.random(minN, math.min(maxN, cap))
	end

	local targets = {}
	for i = 1, want do
		targets[i] = dead[i]
	end

	for _, ply in ipairs(targets) do
		if IsValid(ply) and MissionIntro.PreparePlayerForSupportReinforce then
			MissionIntro.PreparePlayerForSupportReinforce(ply)
		end
	end

	local startList
	if MissionIntro.AssignRandomUiuTfRoles then
		startList = select(1, MissionIntro.AssignRandomUiuTfRoles(targets))
	else
		startList = targets
		for _, ply in ipairs(startList) do
			ply._missionIntroFaction = reinforceFaction
		end
	end

	if not istable(startList) or #startList == 0 then
		return false, "assign_failed"
	end

	MissionIntro._uiuReinforceCalled = true

	-- ????????????+ ?? HUD????????Z city ???? BeginUiuTerminalForceHack ????
	if opts.skipBroadcast ~= true and MissionIntro.BroadcastFactionAlert then
		if not MissionIntro.ShouldBroadcastFaction or MissionIntro.ShouldBroadcastFaction(reinforceFaction) then
			MissionIntro.BroadcastFactionAlert(reinforceFaction, startList)
		end
	end

	if MissionIntro.BatchRespawnAndStartIntro then
		MissionIntro.BatchRespawnAndStartIntro(startList, { factionId = reinforceFaction })
	end

	if opts.skipBroadcast ~= true and MissionIntro.BroadcastMissionCompleteAlerts then
		MissionIntro.BroadcastMissionCompleteAlerts()
	end

	if MissionIntro.RefreshUiuTerminalStates then
		MissionIntro.RefreshUiuTerminalStates()
	end

	if MissionIntro.SyncUiuComputerProgress then
		MissionIntro.SyncUiuComputerProgress()
	end

	local pos = IsValid(triggerPly) and triggerPly:GetPos() or nil
	if pos and not opts.skipHackAudio and MissionIntro.SendUiuHackAudioNear then
		MissionIntro.SendUiuHackAudioNear(pos, 2, (MissionIntro.UiuComputer or {}).uiu_sound_range or 30)
	end

	MsgN(string.format("[MissionIntro] UIU ??????? %d ???? %d??? %d?%d?", #startList, #dead, minN, maxN))
	return true, startList
end

function MissionIntro.IsUiuTerminalHacking()
	for _, ent in ipairs(MissionIntro.GetUiuTerminals()) do
		if IsValid(ent) and ent:GetTerminalState() == STATE.hacking then
			return true, ent
		end
	end
	return false
end

function MissionIntro.BeginUiuTerminalForceHack(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then return false end
	if not MissionIntro.IsUiuSpyPlayer(ply) then return false end
	if not MissionIntro._uiuMissionActive then return false end
	if MissionIntro._uiuReinforceCalled then return false end

	local st = ent:GetTerminalState()
	if st ~= STATE.ready and st ~= STATE.locked then return false end
	if MissionIntro.IsUiuTerminalHacking() then
		ply:ChatPrint("[UIU] ??????????")
		return false
	end

	local dur = MissionIntro.GetUiuTerminalForceHackDuration()
	ent:SetTerminalStateSafe(STATE.hacking)
	ent:SetHacker(ply)
	ent:SetHackEndTime(CurTime() + dur)

	-- ? 2 ????????? UIU ?????
	MissionIntro.BroadcastUiuTerminalForceAlert()

	if IsValid(ply) then
		ply:ChatPrint(string.format("[UIU] ??????? %d ?", math.ceil(dur)))
	end

	return true
end

function MissionIntro.CallUiuReinforcements(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then return false end
	if not MissionIntro.IsUiuSpyPlayer(ply) then return false end
	if not MissionIntro.IsUiuTerminalUnlocked() then return false end
	if ent:GetTerminalState() ~= STATE.ready then return false end

	local ok, reason = MissionIntro.SpawnUiuReinforcements(ply, { skipHackAudio = true })
	if not ok then
		return false, reason
	end

	if IsValid(ply) then
		local msg = MissionIntro.L and MissionIntro.L("uiu_terminal_reinforce_ok")
			or "[UIU] UIU ????????"
		ply:ChatPrint(msg)
	end

	return true
end

function MissionIntro.OnUiuTerminalForceHackComplete(ent, ply)
	if MissionIntro.BroadcastUiuHackAudioStopToUiu then
		MissionIntro.BroadcastUiuHackAudioStopToUiu()
	end

	local ok = MissionIntro.SpawnUiuReinforcements(ply, { skipHackAudio = true })
	if ok and IsValid(ply) then
		local msg = MissionIntro.L and MissionIntro.L("uiu_terminal_reinforce_ok")
			or "[UIU] UIU ????????"
		ply:ChatPrint(msg)
	end
end

function MissionIntro.OnUiuTerminalHackCancelled(ent)
	if MissionIntro.BroadcastUiuHackAudioStopToUiu then
		MissionIntro.BroadcastUiuHackAudioStopToUiu()
	end
end

function MissionIntro.OpenUiuTerminalMenuForPlayer(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then return end

	net.Start("MissionIntro_UiuTerminalOpen")
		net.WriteEntity(ent)
		net.WriteBool(MissionIntro.IsUiuTerminalUnlocked and MissionIntro.IsUiuTerminalUnlocked() or false)
	net.Send(ply)
end

function MissionIntro.OnUiuComputerMissionReadyForTerminal()
	if MissionIntro.RefreshUiuTerminalStates then
		MissionIntro.RefreshUiuTerminalStates()
	end

	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.IsUiuSpyPlayer and MissionIntro.IsUiuSpyPlayer(ply) then
			local msg = MissionIntro.L and MissionIntro.L("uiu_terminal_unlocked")
				or "[UIU] ???????? UIU ???????????????"
			ply:ChatPrint(msg)
		end
	end
end

net.Receive("MissionIntro_UiuTerminalAction", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

	local ent = net.ReadEntity()
	local mode = net.ReadUInt(2)
	if not IsValid(ent) or ent:GetClass() ~= "ent_mission_intro_uiu_terminal" then return end
	if not ent.CanUseDist or not ent:CanUseDist(ply) then return end

	if mode == 1 then
		MissionIntro.CallUiuReinforcements(ply, ent)
	elseif mode == 2 then
		MissionIntro.BeginUiuTerminalForceHack(ply, ent)
	end
end)

function MissionIntro.ExportUiuTerminals()
	local out = {}
	for _, ent in ipairs(MissionIntro.GetUiuTerminals()) do
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

function MissionIntro.CanSaveUiuTerminals()
	if not MissionIntro.UiuTerminalPersistEnabled then return false end
	if MissionIntro._loadingUiuTerminals then return false end
	if MissionIntro._suppressUiuTerminalSave then return false end
	return true
end

function MissionIntro.ReadUiuTerminalsFromDisk()
	if not MissionIntro.UiuTerminalPersistEnabled then return {} end

	local path = MissionIntro.GetUiuTerminalSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteUiuTerminalsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureUiuTerminalSaveDir()
	file.Write(MissionIntro.GetUiuTerminalSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveUiuTerminalsToDisk()
	if not MissionIntro.CanSaveUiuTerminals() then return false end

	local data = MissionIntro.ExportUiuTerminals()
	MissionIntro.WriteUiuTerminalsToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_uiu_terminal"), MissionIntro.GetUiuTerminalSavePath())
	return true
end

function MissionIntro.CacheUiuTerminalsBeforeCleanup()
	MissionIntro._suppressUiuTerminalSave = true

	local live = MissionIntro.ExportUiuTerminals()
	local rows = (#live > 0) and live or MissionIntro.ReadUiuTerminalsFromDisk()
	MissionIntro._uiuTerminalPersistCache = rows

	if MissionIntro.UiuTerminalPersistEnabled then
		MissionIntro.WriteUiuTerminalsToDisk(rows)
	end

	MissionIntro.ServerMsg("log_cached", #rows, MissionIntro.L("log_entity_uiu_terminal"))
	return rows
end

function MissionIntro.LoadUiuTerminalsFromDisk(rows)
	if MissionIntro._loadingUiuTerminals then return end
	MissionIntro._loadingUiuTerminals = true

	rows = rows or MissionIntro.ReadUiuTerminalsFromDisk()

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_terminal")) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end

		if MissionIntro.CreateUiuTerminal then
			MissionIntro.CreateUiuTerminal(pos, ang, true)
		end
	end

	MissionIntro._loadingUiuTerminals = false
	if MissionIntro.RefreshUiuTerminalStates then
		MissionIntro.RefreshUiuTerminalStates()
	end
	MissionIntro.ServerMsg("log_loaded", #rows, MissionIntro.L("log_entity_uiu_terminal"), MissionIntro.GetUiuTerminalSavePath())
end

function MissionIntro.CreateUiuTerminal(pos, ang, silent)
	local ent = ents.Create("ent_mission_intro_uiu_terminal")
	if not IsValid(ent) then return nil end

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	if not silent and MissionIntro.SaveUiuTerminalsToDisk then
		MissionIntro.SaveUiuTerminalsToDisk()
	end

	return ent
end

function MissionIntro.RemoveAllUiuTerminals(save)
	MissionIntro._suppressUiuTerminalSave = true

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_terminal")) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressUiuTerminalSave = false

	if save ~= false and MissionIntro.SaveUiuTerminalsToDisk then
		MissionIntro.SaveUiuTerminalsToDisk()
	end
end

function MissionIntro.RequestSaveUiuTerminals()
	if not MissionIntro.CanSaveUiuTerminals() then return end
	timer.Simple(0, function()
		MissionIntro.SaveUiuTerminalsToDisk()
	end)
end

local function MI_ScheduleReloadUiuTerminals()
	timer.Create("MissionIntro_ReloadUiuTerminals", 0.5, 1, function()
		local rows = MissionIntro._uiuTerminalPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadUiuTerminalsFromDisk()
		end
		MissionIntro._uiuTerminalPersistCache = nil
		if MissionIntro.LoadUiuTerminalsFromDisk then
			MissionIntro.LoadUiuTerminalsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadUiuTerminals", MI_ScheduleReloadUiuTerminals)

hook.Add("PreCleanupMap", "MissionIntro_KeepUiuTerminals", function()
	if MissionIntro.CacheUiuTerminalsBeforeCleanup then
		MissionIntro.CacheUiuTerminalsBeforeCleanup()
	end
end)

hook.Add("PostCleanupMap", "MissionIntro_ReloadUiuTerminals", MI_ScheduleReloadUiuTerminals)
hook.Add("PostCleanup", "MissionIntro_ReloadUiuTerminals", MI_ScheduleReloadUiuTerminals)

hook.Add("ShutDown", "MissionIntro_SaveUiuTerminals", function()
	MissionIntro._suppressUiuTerminalSave = false
	if MissionIntro.SaveUiuTerminalsToDisk then
		MissionIntro.SaveUiuTerminalsToDisk()
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_UiuTerminalCancelHack", function(ply)
	for _, ent in ipairs(MissionIntro.GetUiuTerminals()) do
		if IsValid(ent) and ent:GetHacker() == ply and ent:GetTerminalState() == STATE.hacking then
			ent:CancelForceHack()
		end
	end
end)
