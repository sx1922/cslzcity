if not SERVER then return end

MissionIntro._aaDangerLevel = MissionIntro._aaDangerLevel or 0
MissionIntro._aaSystemShutdown = MissionIntro._aaSystemShutdown or false
MissionIntro._aaClosingInProgress = MissionIntro._aaClosingInProgress or false
MissionIntro._aaClosingStarter = MissionIntro._aaClosingStarter or nil
MissionIntro._aaCiSpawnEta = MissionIntro._aaCiSpawnEta or 0
MissionIntro._aaCiSpawnTriggered = MissionIntro._aaCiSpawnTriggered or false
MissionIntro._aaCiAlly = MissionIntro._aaCiAlly or nil
MissionIntro.AaPanelPersistEnabled = MissionIntro.AaPanelPersistEnabled ~= false

util.AddNetworkString("MissionIntro_AaPanelSync")
util.AddNetworkString("MissionIntro_AaPanelOpen")
util.AddNetworkString("MissionIntro_AaPanelAction")
util.AddNetworkString("MissionIntro_AaHoldSync")
util.AddNetworkString("MissionIntro_AaHoldAbort")
util.AddNetworkString("MissionIntro_AaCiAllySync")

local function MI_ShuffleTable(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function MissionIntro.GetAaPanels()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_aa_panel")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end
	return list
end

function MissionIntro.SyncAaPanels()
	local level = MissionIntro.GetAaDangerLevel()
	local active = MissionIntro.IsAaSystemActive()
	local eta = tonumber(MissionIntro._aaCiSpawnEta) or 0

	for _, ent in ipairs(MissionIntro.GetAaPanels()) do
		ent:SetDangerLevel(level)
		ent:SetAaActive(active)
		ent:SetCiSpawnEta(eta)
	end
end

function MissionIntro.BroadcastAaPanelSync()
	MissionIntro.SyncAaPanels()

	net.Start("MissionIntro_AaPanelSync")
		net.WriteFloat(MissionIntro.GetAaDangerLevel())
		net.WriteBool(MissionIntro.IsAaSystemActive())
		net.WriteFloat(tonumber(MissionIntro._aaCiSpawnEta) or 0)
		net.WriteBool(MissionIntro._aaCiSpawnTriggered == true)
		net.WriteBool(MissionIntro._aaClosingInProgress == true)
		net.WriteEntity(IsValid(MissionIntro._aaClosingStarter) and MissionIntro._aaClosingStarter or NULL)
	net.Broadcast()
end

function MissionIntro.BroadcastAaCiAllySync()
	local ally = MissionIntro.GetAaCiAllyPlayer and MissionIntro.GetAaCiAllyPlayer() or MissionIntro._aaCiAlly

	net.Start("MissionIntro_AaCiAllySync")
		net.WriteBool(IsValid(ally))
		if IsValid(ally) then
			net.WriteEntity(ally)
		end
	net.Broadcast()
end

function MissionIntro.SetAaCiAlly(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	MissionIntro._aaCiAlly = ply
	ply:SetNWString("MissionIntro_AaCiAlly", "1")
	MissionIntro.BroadcastAaCiAllySync()
	return true
end

function MissionIntro.ClearAaCiAlly()
	local ally = MissionIntro._aaCiAlly
	if not IsValid(ally) and MissionIntro.GetAaCiAllyPlayer then
		ally = MissionIntro.GetAaCiAllyPlayer()
	end

	if IsValid(ally) then
		ally:SetNWString("MissionIntro_AaCiAlly", "")
	end

	MissionIntro._aaCiAlly = nil
	MissionIntro.BroadcastAaCiAllySync()
end

function MissionIntro.ResetAaPanelState(fullReset)
	MissionIntro._aaDangerLevel = 0
	timer.Remove("MissionIntro_AaCiSpawn")
	MissionIntro.ClearAaShutdownHold("reset")
	MissionIntro.ClearAaCiAlly()

	if fullReset ~= false then
		if MissionIntro._aaClosingInProgress and MissionIntro.GetAaPanels then
			local panels = MissionIntro.GetAaPanels()
			if #panels > 0 and IsValid(panels[1]) and MissionIntro.StopAaClosingHackAudio then
				MissionIntro.StopAaClosingHackAudio(panels[1])
			end
		end
		MissionIntro._aaSystemShutdown = false
		MissionIntro._aaClosingInProgress = false
		MissionIntro._aaClosingStarter = nil
		MissionIntro._aaCiSpawnEta = 0
		MissionIntro._aaCiSpawnTriggered = false
	end

	if MissionIntro.BroadcastAaPanelSync then
		MissionIntro.BroadcastAaPanelSync()
	end
end

function MissionIntro.AddAaDanger(amount)
	if MissionIntro._aaSystemShutdown or MissionIntro._aaClosingInProgress then
		return MissionIntro.GetAaDangerLevel()
	end

	local step = tonumber(amount)
	if step == nil then
		step = MissionIntro.GetAaDeathStep()
	end

	local nextLevel = math.min(100, MissionIntro.GetAaDangerLevel() + step)
	if nextLevel == MissionIntro._aaDangerLevel then
		return nextLevel
	end

	MissionIntro._aaDangerLevel = nextLevel
	MissionIntro.BroadcastAaPanelSync()

	return nextLevel
end

function MissionIntro.GetPlayersInRange(pos, range)
	local out = {}
	local r2 = (tonumber(range) or 15) ^ 2
	if not isvector(pos) then return out end

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and ply:GetPos():DistToSqr(pos) <= r2 then
			out[#out + 1] = ply
		end
	end

	return out
end

function MissionIntro.SendUiuHackAudioNear(pos, action, range)
	if not MissionIntro.SendUiuHackAudio then return end
	local cfg = MissionIntro.AaPanel or {}
	for _, ply in ipairs(MissionIntro.GetPlayersInRange(pos, range or cfg.uiu_sound_range or 30)) do
		MissionIntro.SendUiuHackAudio(ply, action)
	end
end

function MissionIntro.BroadcastAaHoldSync()
	local hold = MissionIntro._aaShutdownHold

	net.Start("MissionIntro_AaHoldSync")
		net.WriteBool(hold ~= nil)
		if hold then
			net.WriteEntity(hold.holder)
			net.WriteEntity(hold.ent)
			net.WriteFloat(tonumber(hold.endAt) or 0)
			net.WriteUInt(hold.mode == "abort" and 2 or 1, 2)
		end
	net.Broadcast()
end

function MissionIntro.BroadcastAaShutdownWarning()
	if not MissionIntro.BroadcastCustomAlert then return end

	local cfg = MissionIntro.AaPanel or {}

	MissionIntro.BroadcastCustomAlert({
		title = "Z city",
		line1 = MissionIntro.L and MissionIntro.L("aa_warn_line1") or "??????????????",
		line2 = MissionIntro.L and MissionIntro.L("aa_warn_line2") or "?????????",
		sound = cfg.alert_sound or "mission_intro/aa_shutdown_alert.mp3",
		accent = Color(220, 90, 70),
	}, { playSound = true, forceSoundDuringIntro = true })
end

function MissionIntro.ClearAaShutdownHold(reason)
	local hold = MissionIntro._aaShutdownHold
	if not hold then return false end

	local pos = IsValid(hold.ent) and hold.ent:GetPos() or nil
	MissionIntro._aaShutdownHold = nil

	if pos and hold.mode ~= "abort" then
		MissionIntro.SendUiuHackAudioNear(pos, 3)
	end

	MissionIntro.BroadcastAaHoldSync()

	if reason == "aborted" and IsValid(hold.holder) then
		net.Start("MissionIntro_AaHoldAbort")
		net.Send(hold.holder)
	end

	return true
end

function MissionIntro.BeginAaPanelHold(ply, ent, mode)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
	if not IsValid(ent) then return false end
	mode = mode or "close"

	if mode == "close" then
		if MissionIntro._aaSystemShutdown or MissionIntro._aaClosingInProgress then return false end
		if MissionIntro.GetAaDangerLevel() < 100 then return false end
	elseif mode == "abort" then
		if not MissionIntro._aaClosingInProgress then return false end
	else
		return false
	end

	local need = MissionIntro.GetAaPanelHoldDuration and MissionIntro.GetAaPanelHoldDuration(mode) or 5

	if MissionIntro._aaShutdownHold then
		local h = MissionIntro._aaShutdownHold
		if h.mode == mode and IsValid(h.holder) and h.holder == ply and IsValid(h.ent) and h.ent:EntIndex() == ent:EntIndex() then
			h.startAt = CurTime()
			h.endAt = CurTime() + need
			MissionIntro.BroadcastAaHoldSync()
			return true
		end
		return false
	end

	MissionIntro._aaShutdownHold = {
		holder = ply,
		ent = ent,
		mode = mode,
		startAt = CurTime(),
		endAt = CurTime() + need,
	}

	MissionIntro.BroadcastAaHoldSync()
	return true
end

function MissionIntro.BeginAaShutdownHold(ply, ent)
	return MissionIntro.BeginAaPanelHold(ply, ent, "close")
end

function MissionIntro.BeginAaAbortHold(ply, ent)
	return MissionIntro.BeginAaPanelHold(ply, ent, "abort")
end

function MissionIntro.StartAaClosingHackAudio(ent)
	if not IsValid(ent) then return end

	local cfg = MissionIntro.AaPanel or {}
	local range = tonumber(cfg.uiu_sound_range) or 30
	local pos = ent:GetPos()

	local usePath = (MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_hack_use) or "mission_intro/uiu_hack_use.mp3"
	ent:EmitSound(usePath, 75, 100, 0.95, CHAN_STATIC)

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and ply:GetPos():DistToSqr(pos) <= range * range then
			if MissionIntro.SendUiuHackAudio then
				MissionIntro.SendUiuHackAudio(ply, 4)
			end
		end
	end
end

function MissionIntro.StopAaClosingHackAudio(ent)
	if MissionIntro.BroadcastUiuHackAudioStopAll then
		MissionIntro.BroadcastUiuHackAudioStopAll()
	elseif MissionIntro.SendUiuHackAudioNear then
		local pos
		if IsValid(ent) then
			pos = ent:GetPos()
		else
			local panels = MissionIntro.GetAaPanels()
			if #panels > 0 and IsValid(panels[1]) then
				pos = panels[1]:GetPos()
			end
		end
		if pos then
			MissionIntro.SendUiuHackAudioNear(pos, 3, 4096)
		end
	end

	if IsValid(ent) then
		local usePath = (MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_hack_use) or "mission_intro/uiu_hack_use.mp3"
		ent:StopSound(usePath)
	end
end

function MissionIntro.TryAbortAaShutdownFromUse(ply, ent)
	if MissionIntro._aaClosingInProgress then return false end

	local hold = MissionIntro._aaShutdownHold
	if not hold or hold.mode ~= "close" or not IsValid(hold.ent) or not IsValid(hold.holder) then return false end
	if hold.ent:EntIndex() ~= ent:EntIndex() then return false end
	if ply == hold.holder then return false end
	if ent.CanUseDist and not ent:CanUseDist(ply) then return false end

	return MissionIntro.AbortAaShutdownHold(ply) == true
end

function MissionIntro.AbortAaShutdownHold(ply)
	local hold = MissionIntro._aaShutdownHold
	if not hold or hold.mode ~= "close" then return false end
	if IsValid(ply) and IsValid(hold.holder) and ply == hold.holder then
		return false
	end

	MissionIntro.ClearAaShutdownHold("aborted")

	local msgAll = MissionIntro.L and MissionIntro.L("aa_shutdown_blocked") or "[??] ?????????"
	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:IsPlayer() then
			p:ChatPrint(msgAll)
		end
	end

	if IsValid(ply) then
		local msgYou = MissionIntro.L and MissionIntro.L("aa_shutdown_abort_you") or "[??] ????????????"
		ply:ChatPrint(msgYou)
	end

	return true
end

function MissionIntro.AbortAaClosingSequence(ply)
	if not MissionIntro._aaClosingInProgress then return false end

	local panels = MissionIntro.GetAaPanels()
	local ent = panels[1]

	MissionIntro.ClearAaCiAlly()
	MissionIntro._aaClosingInProgress = false
	MissionIntro._aaClosingStarter = nil
	MissionIntro._aaCiSpawnEta = 0
	MissionIntro._aaShutdownHold = nil
	timer.Remove("MissionIntro_AaCiSpawn")

	if IsValid(ent) and MissionIntro.StopAaClosingHackAudio then
		MissionIntro.StopAaClosingHackAudio(ent)
	end

	MissionIntro.BroadcastAaHoldSync()
	MissionIntro.BroadcastAaPanelSync()

	local msgAll = MissionIntro.L and MissionIntro.L("aa_shutdown_blocked") or "[??] ?????????"
	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:IsPlayer() then
			p:ChatPrint(msgAll)
		end
	end

	if IsValid(ply) then
		local msgYou = MissionIntro.L and MissionIntro.L("aa_shutdown_abort_you") or "[??] ????????????"
		ply:ChatPrint(msgYou)
	end

	return true
end

function MissionIntro.BeginAaClosingSequence(ply, ent)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if not IsValid(ent) then return false end
	if MissionIntro._aaClosingInProgress or MissionIntro._aaSystemShutdown then return false end
	if MissionIntro.GetAaDangerLevel() < 100 then return false end

	local cfg = MissionIntro.AaPanel or {}
	local delay = tonumber(cfg.ci_spawn_delay) or 60

	MissionIntro._aaClosingInProgress = true
	MissionIntro._aaClosingStarter = ply
	MissionIntro._aaCiSpawnEta = CurTime() + delay
	MissionIntro._aaShutdownHold = nil

	MissionIntro.BroadcastAaHoldSync()
	MissionIntro.BroadcastAaPanelSync()

	timer.Simple(0.1, function()
		if not MissionIntro._aaClosingInProgress then return end

		if MissionIntro.BroadcastAaShutdownWarning then
			MissionIntro.BroadcastAaShutdownWarning()
		end

		if MissionIntro.StartAaClosingHackAudio then
			MissionIntro.StartAaClosingHackAudio(ent)
		end
	end)

	local msg = MissionIntro.L and MissionIntro.L("aa_shutdown_confirmed", math.floor(delay)) or ("[??] ????????" .. math.floor(delay) .. " ???????")
	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:IsPlayer() then
			p:ChatPrint(msg)
		end
	end

	timer.Remove("MissionIntro_AaCiSpawn")
	timer.Create("MissionIntro_AaCiSpawn", delay, 1, function()
		if MissionIntro.FinishAaShutdown then
			MissionIntro.FinishAaShutdown(ent)
		end
	end)

	return true
end

function MissionIntro.FinishAaShutdown(ent)
	if not MissionIntro._aaClosingInProgress then return false end

	local starter = MissionIntro._aaClosingStarter

	MissionIntro._aaClosingInProgress = false
	MissionIntro._aaSystemShutdown = true
	MissionIntro._aaCiSpawnEta = 0
	MissionIntro.BroadcastAaPanelSync()

	if IsValid(starter) and starter:IsPlayer() and MissionIntro.SetAaCiAlly then
		MissionIntro.SetAaCiAlly(starter)
	end

	if MissionIntro.SpawnCiFromDeadAfterAaShutdown then
		MissionIntro.SpawnCiFromDeadAfterAaShutdown()
	end

	return true
end

function MissionIntro.SpawnVdvFromDeadAfterAaShutdown()
	if MissionIntro._aaCiSpawnTriggered then return false end

	local cfg = MissionIntro.AaPanel or {}
	local maxSpawn = MissionIntro.VdvMaxSpawnCount or MissionIntro.CiMaxSpawnCount or 5
	local want = math.min(maxSpawn, math.max(1, tonumber(cfg.ci_spawn_count) or maxSpawn))

	local ally = MissionIntro.GetAaCiAllyPlayer and MissionIntro.GetAaCiAllyPlayer() or nil

	local dead = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and not ply:Alive() then
			if IsValid(ally) and ply == ally then continue end
			dead[#dead + 1] = ply
		end
	end

	if #dead == 0 then
		local msg = MissionIntro.L and MissionIntro.L("aa_vdv_no_dead") or "[??] ?????????? VDV?"
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply:IsPlayer() then
				ply:ChatPrint(msg)
			end
		end
		return false
	end

	MI_ShuffleTable(dead)

	local targets = {}
	for i = 1, math.min(want, #dead) do
		targets[i] = dead[i]
	end

	for _, ply in ipairs(targets) do
		if IsValid(ply) and MissionIntro.PreparePlayerForSupportReinforce then
			MissionIntro.PreparePlayerForSupportReinforce(ply)
		end
	end

	local startList
	if MissionIntro.AssignRandomVdvRoles then
		startList = MissionIntro.AssignRandomVdvRoles(targets)
	else
		startList = targets
		for _, ply in ipairs(startList) do
			ply._missionIntroFaction = "vdv_squad"
		end
	end

	if #startList == 0 then return false end

	MissionIntro._aaCiSpawnTriggered = true
	MissionIntro._aaCiSpawnEta = 0
	MissionIntro.ClearAaShutdownHold("complete")
	MissionIntro.BroadcastAaPanelSync()

	if MissionIntro.BroadcastFactionAlert then
		if not MissionIntro.ShouldBroadcastFaction or MissionIntro.ShouldBroadcastFaction("vdv_squad") then
			MissionIntro.BroadcastFactionAlert("vdv_squad", startList)
		end
	end

	if MissionIntro.BatchRespawnAndStartIntro then
		MissionIntro.BatchRespawnAndStartIntro(startList, { factionId = "vdv_squad" })
	end

	local panels = MissionIntro.GetAaPanels()
	if #panels > 0 and IsValid(panels[1]) then
		if MissionIntro.StopAaClosingHackAudio then
			MissionIntro.StopAaClosingHackAudio(panels[1])
		end
		MissionIntro.SendUiuHackAudioNear(panels[1]:GetPos(), 2, (MissionIntro.AaPanel or {}).uiu_sound_range or 30)
	end

	MissionIntro.ServerMsg("log_aa_vdv_reinforce", #startList)
	return true
end

function MissionIntro.SpawnCiFromDeadAfterAaShutdown()
	return MissionIntro.SpawnVdvFromDeadAfterAaShutdown()
end

hook.Add("PlayerDeath", "MissionIntro_AaDangerOnDeath", function(victim)
	if not IsValid(victim) or not victim:IsPlayer() then return end

	if MissionIntro.IsAaCiAllyPlayer and MissionIntro.IsAaCiAllyPlayer(victim) then
		MissionIntro.ClearAaCiAlly()
	end

	if #MissionIntro.GetAaPanels() == 0 then return end
	MissionIntro.AddAaDanger()
end)

hook.Add("PlayerDisconnected", "MissionIntro_AaCiAllyCleanup", function(ply)
	if MissionIntro.IsAaCiAllyPlayer and MissionIntro.IsAaCiAllyPlayer(ply) then
		MissionIntro.ClearAaCiAlly()
	end
end)

local MI_RoundClearHooks = {
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
}

for _, hookName in ipairs(MI_RoundClearHooks) do
	hook.Add(hookName, "MissionIntro_ResetAaPanel", function()
		MissionIntro.ResetAaPanelState(false)
	end)
end

hook.Add("PreCleanupMap", "MissionIntro_ResetAaPanel", function()
	MissionIntro.ResetAaPanelState(true)
	if MissionIntro.CacheAaPanelsBeforeCleanup then
		MissionIntro.CacheAaPanelsBeforeCleanup()
	end
end)

hook.Add("PlayerInitialSpawn", "MissionIntro_AaPanelSync", function(ply)
	timer.Simple(2, function()
		if not IsValid(ply) then return end
		net.Start("MissionIntro_AaPanelSync")
			net.WriteFloat(MissionIntro.GetAaDangerLevel())
			net.WriteBool(MissionIntro.IsAaSystemActive())
			net.WriteFloat(tonumber(MissionIntro._aaCiSpawnEta) or 0)
			net.WriteBool(MissionIntro._aaCiSpawnTriggered == true)
			net.WriteBool(MissionIntro._aaClosingInProgress == true)
			net.WriteEntity(IsValid(MissionIntro._aaClosingStarter) and MissionIntro._aaClosingStarter or NULL)
		net.Send(ply)

		local hold = MissionIntro._aaShutdownHold
		net.Start("MissionIntro_AaHoldSync")
			net.WriteBool(hold ~= nil)
			if hold then
				net.WriteEntity(hold.holder)
				net.WriteEntity(hold.ent)
				net.WriteFloat(tonumber(hold.endAt) or 0)
				net.WriteUInt(hold.mode == "abort" and 2 or 1, 2)
			end
		net.Send(ply)

		MissionIntro.SyncAaPanels()

		if MissionIntro.BroadcastAaCiAllySync then
			MissionIntro.BroadcastAaCiAllySync()
		end
	end)
end)

local function MI_PanelDir()
	return "rx_mission_intro/aa_panels"
end

function MissionIntro.GetAaPanelSavePath()
	return MI_PanelDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureAaPanelSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_PanelDir(), "DATA") then
		file.CreateDir(MI_PanelDir())
	end
end

function MissionIntro.CanSaveAaPanels()
	if MissionIntro.AaPanelPersistEnabled == false then return false end
	if MissionIntro._suppressAaPanelSave then return false end
	if MissionIntro._loadingAaPanels then return false end
	return true
end

function MissionIntro.ExportAaPanels()
	local data = {}
	for _, ent in ipairs(MissionIntro.GetAaPanels()) do
		data[#data + 1] = {
			pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
			ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		}
	end
	return data
end

function MissionIntro.ReadAaPanelsFromDisk()
	local path = MissionIntro.GetAaPanelSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not isstring(raw) or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteAaPanelsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureAaPanelSaveDir()
	file.Write(MissionIntro.GetAaPanelSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveAaPanelsToDisk()
	if not MissionIntro.CanSaveAaPanels() then return false end

	local data = MissionIntro.ExportAaPanels()
	MissionIntro.WriteAaPanelsToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_aa_panel"), MissionIntro.GetAaPanelSavePath())
	return true
end

function MissionIntro.CacheAaPanelsBeforeCleanup()
	MissionIntro._suppressAaPanelSave = true

	local live = MissionIntro.ExportAaPanels()
	local rows = (#live > 0) and live or MissionIntro.ReadAaPanelsFromDisk()
	MissionIntro._aaPanelPersistCache = rows

	MissionIntro.WriteAaPanelsToDisk(rows)
	MissionIntro.ServerMsg("log_cached", #rows, MissionIntro.L("log_entity_aa_panel"))
	return rows
end

function MissionIntro.LoadAaPanelsFromDisk(rows)
	if MissionIntro._loadingAaPanels then return end
	MissionIntro._loadingAaPanels = true

	rows = rows or MissionIntro.ReadAaPanelsFromDisk()

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_aa_panel")) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		if MissionIntro.CreateAaPanel then
			MissionIntro.CreateAaPanel(pos, ang, true)
		end
	end

	MissionIntro._loadingAaPanels = false
	MissionIntro.SyncAaPanels()
	MissionIntro.ServerMsg("log_loaded", #rows, MissionIntro.L("log_entity_aa_panel"), MissionIntro.GetAaPanelSavePath())
end

function MissionIntro.CreateAaPanel(pos, ang, silent)
	local ent = ents.Create("ent_mission_intro_aa_panel")
	if not IsValid(ent) then
		MissionIntro.ServerMsg("log_create_entity_failed", "ent_mission_intro_aa_panel（请 lua_refresh 或换图）")
		return nil
	end

	local mdl = MissionIntro.GetAaPanelModel and MissionIntro.GetAaPanelModel() or "models/props_combine/masterinterface.mdl"
	ent:SetModel(mdl)

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang, MissionIntro.GetAaSpawnSurfaceOffset and MissionIntro.GetAaSpawnSurfaceOffset())
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	if not IsValid(ent) then return nil end

	MissionIntro.SyncAaPanels()

	if not silent and MissionIntro.SaveAaPanelsToDisk then
		MissionIntro.SaveAaPanelsToDisk()
	end

	return ent
end

function MissionIntro.RemoveAllAaPanels(save)
	MissionIntro._suppressAaPanelSave = true

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_aa_panel")) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressAaPanelSave = false

	if save ~= false and MissionIntro.SaveAaPanelsToDisk then
		MissionIntro.SaveAaPanelsToDisk()
	end
end

function MissionIntro.RequestSaveAaPanels()
	if not MissionIntro.CanSaveAaPanels() then return end
	timer.Simple(0, function()
		MissionIntro.SaveAaPanelsToDisk()
	end)
end

local function MI_ScheduleReloadAaPanels()
	timer.Create("MissionIntro_ReloadAaPanels", 0.5, 1, function()
		local rows = MissionIntro._aaPanelPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadAaPanelsFromDisk()
		end
		MissionIntro._aaPanelPersistCache = nil
		if MissionIntro.LoadAaPanelsFromDisk then
			MissionIntro.LoadAaPanelsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadAaPanels", MI_ScheduleReloadAaPanels)
hook.Add("PostCleanupMap", "MissionIntro_ReloadAaPanels", MI_ScheduleReloadAaPanels)
hook.Add("PostCleanup", "MissionIntro_ReloadAaPanels", MI_ScheduleReloadAaPanels)

net.Receive("MissionIntro_AaPanelAction", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local ent = net.ReadEntity()
	if not IsValid(ent) or ent:GetClass() ~= "ent_mission_intro_aa_panel" then return end
	if not ent.CanUseDist or not ent:CanUseDist(ply) then return end

	local action = net.ReadUInt(4) or 0

	if action == 1 then
		local ok = MissionIntro.BeginAaShutdownHold and MissionIntro.BeginAaShutdownHold(ply, ent)
		if not ok then
			net.Start("MissionIntro_AaHoldAbort")
			net.Send(ply)
		end
		return
	end

	if action == 5 then
		local ok = MissionIntro.BeginAaAbortHold and MissionIntro.BeginAaAbortHold(ply, ent)
		if not ok then
			net.Start("MissionIntro_AaHoldAbort")
			net.Send(ply)
		end
		return
	end

	if action == 2 then
		local hold = MissionIntro._aaShutdownHold

		if not hold or hold.holder ~= ply or not IsValid(hold.ent) or hold.ent:EntIndex() ~= ent:EntIndex() then
			return
		end

		local mode = hold.mode or "close"
		local need = MissionIntro.GetAaPanelHoldDuration and MissionIntro.GetAaPanelHoldDuration(mode) or 5
		if CurTime() < (tonumber(hold.endAt) or 0) - 0.15 then
			local msgKey = (mode == "abort") and "aa_abort_hold_fail" or "aa_shutdown_hold_fail"
			local msg = MissionIntro.L and MissionIntro.L(msgKey) or "[??] ???? 5 ????"
			ply:ChatPrint(msg)
			return
		end

		if mode == "abort" then
			MissionIntro._aaShutdownHold = nil
			MissionIntro.BroadcastAaHoldSync()
			if MissionIntro.AbortAaClosingSequence then
				MissionIntro.AbortAaClosingSequence(ply)
			end
			return
		end

		if MissionIntro._aaClosingInProgress or MissionIntro._aaSystemShutdown then
			return
		end

		if MissionIntro.GetAaDangerLevel() < 100 then
			local msg = MissionIntro.L and MissionIntro.L("aa_danger_not_ready", MissionIntro.GetAaDangerLevel()) or "[??] ??????? 100%?"
			ply:ChatPrint(msg)
			return
		end

		MissionIntro._aaShutdownHold = nil
		MissionIntro.BroadcastAaHoldSync()

		if MissionIntro.BeginAaClosingSequence then
			MissionIntro.BeginAaClosingSequence(ply, ent)
		end
		return
	end

	if action == 3 then
		if not MissionIntro._aaClosingInProgress and MissionIntro.AbortAaShutdownHold then
			MissionIntro.AbortAaShutdownHold(ply)
		end
		return
	end

	if action == 4 then
		local hold = MissionIntro._aaShutdownHold
		if hold and hold.holder == ply then
			MissionIntro.ClearAaShutdownHold("cancelled")
			local msg = MissionIntro.L and MissionIntro.L("aa_shutdown_cancelled") or "[??] ????????"
			ply:ChatPrint(msg)
		end
	end
end)

hook.Add("EntityRemoved", "MissionIntro_SaveAaPanelsOnRemove", function(ent)
	if not ent or ent:GetClass() ~= "ent_mission_intro_aa_panel" then return end
	if MissionIntro._loadingAaPanels or MissionIntro._suppressAaPanelSave then return end
	if MissionIntro.RequestSaveAaPanels then
		MissionIntro.RequestSaveAaPanels()
	end
end)

hook.Add("ShutDown", "MissionIntro_SaveAaPanels", function()
	MissionIntro._suppressAaPanelSave = false
	if MissionIntro.SaveAaPanelsToDisk then
		MissionIntro.SaveAaPanelsToDisk()
	end
end)
