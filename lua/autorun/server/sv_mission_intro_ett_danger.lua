if not SERVER then return end

MissionIntro._ettDangerLevel = MissionIntro._ettDangerLevel or 0
MissionIntro._ettReinforcementsCalled = MissionIntro._ettReinforcementsCalled or false
MissionIntro._ettReinforcementsEta = MissionIntro._ettReinforcementsEta or 0
MissionIntro.EttPanelPersistEnabled = MissionIntro.EttPanelPersistEnabled ~= false

util.AddNetworkString("MissionIntro_EttDangerSync")
util.AddNetworkString("MissionIntro_EttPanelOpen")
util.AddNetworkString("MissionIntro_EttPanelAction")

local function MI_ShuffleTable(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function MissionIntro.GetEttPanels()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_ett_panel")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end
	return list
end

function MissionIntro.SyncEttPanels()
	local level = MissionIntro.GetEttDangerLevel()
	local called = MissionIntro._ettReinforcementsCalled == true
	local eta = tonumber(MissionIntro._ettReinforcementsEta) or 0

	for _, ent in ipairs(MissionIntro.GetEttPanels()) do
		ent:SetDangerLevel(level)
		ent:SetReinforcementsCalled(called)
		ent:SetReinforcementsEta(eta)
	end
end

function MissionIntro.BroadcastEttDangerSync()
	MissionIntro.SyncEttPanels()

	net.Start("MissionIntro_EttDangerSync")
		net.WriteFloat(MissionIntro.GetEttDangerLevel())
		net.WriteBool(MissionIntro._ettReinforcementsCalled == true)
		net.WriteFloat(tonumber(MissionIntro._ettReinforcementsEta) or 0)
	net.Broadcast()
end

function MissionIntro.ResetEttDanger(fullReset)
	MissionIntro._ettDangerLevel = 0
	timer.Remove("MissionIntro_EttReinforcements")

	if fullReset ~= false then
		MissionIntro._ettReinforcementsCalled = false
		MissionIntro._ettReinforcementsEta = 0
		for _, p in ipairs(player.GetAll()) do
			if IsValid(p) then
				p._missionIntroEttReinforceLocked = nil
			end
		end
	end

	if MissionIntro.BroadcastEttDangerSync then
		MissionIntro.BroadcastEttDangerSync()
	end
end

function MissionIntro.AddEttDanger(amount)
	if MissionIntro._ettReinforcementsCalled then
		return MissionIntro.GetEttDangerLevel()
	end

	local step = tonumber(amount)
	if step == nil then
		step = tonumber(MissionIntro.EttPanel and MissionIntro.EttPanel.death_step) or 12.5
	end

	local nextLevel = math.min(100, MissionIntro.GetEttDangerLevel() + step)
	if nextLevel == MissionIntro._ettDangerLevel then
		return nextLevel
	end

	MissionIntro._ettDangerLevel = nextLevel
	MissionIntro.BroadcastEttDangerSync()

	if nextLevel >= 100 then
		for _, ply in ipairs(player.GetAll()) do
			if MissionIntro.IsPttrbPlayer(ply) then
				local msg = MissionIntro.L and MissionIntro.L("ett_danger_max_hint") or "[ETT] ???????? 100%???????? E ?????"
				ply:ChatPrint(msg)
			end
		end
	end

	return nextLevel
end

function MissionIntro.CanCallEttReinforcements(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
	if not MissionIntro.IsPttrbPlayer(ply) then return false end
	if MissionIntro.GetEttDangerLevel() < 100 then return false end
	if MissionIntro._ettReinforcementsCalled then return false end
	if ply._missionIntroEttReinforceLocked then return false end
	return true
end

function MissionIntro.SpawnHammerfallReinforcementsFromDead()
	local cfg = MissionIntro.EttPanel or {}
	local minN = tonumber(cfg.reinforce_min) or 3
	local maxN = tonumber(cfg.reinforce_max) or 8

	local dead = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and not ply:Alive() then
			dead[#dead + 1] = ply
		end
	end

	if #dead == 0 then
		for _, ply in ipairs(player.GetAll()) do
			if MissionIntro.IsPttrbPlayer(ply) then
				local msg = MissionIntro.L and MissionIntro.L("ett_reinforce_no_dead") or "[ETT] ?????????????????"
				ply:ChatPrint(msg)
			end
		end
		-- ??????????????????????????????
		MissionIntro._ettReinforcementsEta = 0
		MissionIntro.BroadcastEttDangerSync()
		return false
	end

	MI_ShuffleTable(dead)

	local count = math.random(minN, math.min(maxN, #dead))
	local targets = {}
	for i = 1, count do
		targets[i] = dead[i]
	end

	for _, ply in ipairs(targets) do
		if IsValid(ply) and MissionIntro.PreparePlayerForSupportReinforce then
			MissionIntro.PreparePlayerForSupportReinforce(ply)
		end
	end

	local startList
	if MissionIntro.AssignRandomHammerfallRoles then
		startList = select(1, MissionIntro.AssignRandomHammerfallRoles(targets))
	else
		startList = targets
		for _, ply in ipairs(startList) do
			ply._missionIntroFaction = "hammerfall_squad"
		end
	end

	if #startList == 0 then return false end

	if MissionIntro.BroadcastFactionAlert then
		if not MissionIntro.ShouldBroadcastFaction or MissionIntro.ShouldBroadcastFaction("hammerfall_squad") then
			MissionIntro.BroadcastFactionAlert("hammerfall_squad", startList)
		end
	end

	if MissionIntro.BatchRespawnAndStartIntro then
		MissionIntro.BatchRespawnAndStartIntro(startList, { factionId = "hammerfall_squad" })
	end

	MsgN("[MissionIntro] ETT ?????? " .. #dead .. " ?????? " .. #startList .. " ???")
	return true
end

function MissionIntro.CallEttReinforcements(ply)
	if not MissionIntro.CanCallEttReinforcements(ply) then return false end

	local cfg = MissionIntro.EttPanel or {}
	local delay = tonumber(cfg.reinforce_delay) or 15

	MissionIntro._ettReinforcementsCalled = true
	MissionIntro._ettReinforcementsEta = CurTime() + delay
	ply._missionIntroEttReinforceLocked = true
	MissionIntro.BroadcastEttDangerSync()

	local startMsg = MissionIntro.L and MissionIntro.L("ett_reinforce_called", math.floor(delay)) or ("[ETT] ?????????? " .. math.floor(delay) .. " ?????")
	for _, p in ipairs(player.GetAll()) do
		if MissionIntro.IsPttrbPlayer(p) then
			p:ChatPrint(startMsg)
		end
	end

	timer.Create("MissionIntro_EttReinforcements", delay, 1, function()
		MissionIntro._ettReinforcementsEta = 0
		MissionIntro.SpawnHammerfallReinforcementsFromDead()
	end)

	return true
end

local function MI_ClearStaleIntroFactionOnSpawn(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local role = MissionIntro.GetPlayerGameRole and MissionIntro.GetPlayerGameRole(ply) or ""
	if role == "" then return end

	if MissionIntro.IsCivilianGameRole and MissionIntro.IsCivilianGameRole(role) then
		if MissionIntro.ClearPttrbRole then
			MissionIntro.ClearPttrbRole(ply)
		end
		if ply.SetNWString then
			ply:SetNWString("MissionIntro_FactionId", "")
		end
		ply._missionIntroFaction = nil
		ply._missionIntroEttReinforceLocked = nil
		if MissionIntro.ClearPlayerMissionIntroState then
			MissionIntro.ClearPlayerMissionIntroState(ply)
		end
		if MissionIntro.ClearForcedPlayerModel then
			MissionIntro.ClearForcedPlayerModel(ply)
		end
		return
	end

	if MissionIntro.IsPttrbGameRole and MissionIntro.IsPttrbGameRole(role) then
		if MissionIntro.AssignPttrbRole and MissionIntro.GetPttrbRole then
			MissionIntro.AssignPttrbRole(ply, MissionIntro.GetPttrbRole(ply))
		end
		ply._missionIntroFaction = "pttrb_squad"
		return
	end

	if MissionIntro.ResolveFactionIdFromGameRole then
		local liveFac = MissionIntro.ResolveFactionIdFromGameRole(role)
		if liveFac and ply._missionIntroFaction and ply._missionIntroFaction ~= liveFac then
			if MissionIntro.ClearPlayerMissionIntroState then
				MissionIntro.ClearPlayerMissionIntroState(ply)
			end
			ply._missionIntroFaction = liveFac
		end
	end
end

hook.Add("PlayerSpawn", "MissionIntro_EttClearStaleFaction", function(ply)
	timer.Simple(0, function()
		MI_ClearStaleIntroFactionOnSpawn(ply)
	end)
	timer.Simple(0.5, function()
		MI_ClearStaleIntroFactionOnSpawn(ply)
	end)
end)

hook.Add("PlayerDeath", "MissionIntro_EttDangerOnDeath", function(victim)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if #MissionIntro.GetEttPanels() == 0 then return end
	MissionIntro.AddEttDanger()
end)

local MI_RoundClearHooks = {
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
}

for _, hookName in ipairs(MI_RoundClearHooks) do
	hook.Add(hookName, "MissionIntro_ResetEttDanger", function()
		-- ????????????????????????
		MissionIntro.ResetEttDanger(false)
	end)
end

hook.Add("PreCleanupMap", "MissionIntro_ResetEttDanger", function()
	MissionIntro.ResetEttDanger(true)
	if MissionIntro.CacheEttPanelsBeforeCleanup then
		MissionIntro.CacheEttPanelsBeforeCleanup()
	end
end)

hook.Add("PlayerInitialSpawn", "MissionIntro_EttDangerSync", function(ply)
	timer.Simple(2, function()
		if not IsValid(ply) then return end
		net.Start("MissionIntro_EttDangerSync")
			net.WriteFloat(MissionIntro.GetEttDangerLevel())
			net.WriteBool(MissionIntro._ettReinforcementsCalled == true)
			net.WriteFloat(tonumber(MissionIntro._ettReinforcementsEta) or 0)
		net.Send(ply)
		MissionIntro.SyncEttPanels()
	end)
end)

-- ??? / ??
local function MI_PanelDir()
	return "rx_mission_intro/ett_panels"
end

function MissionIntro.GetEttPanelSavePath()
	return MI_PanelDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureEttPanelSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_PanelDir(), "DATA") then
		file.CreateDir(MI_PanelDir())
	end
end

function MissionIntro.CanSaveEttPanels()
	if MissionIntro.EttPanelPersistEnabled == false then return false end
	if MissionIntro._suppressEttPanelSave then return false end
	if MissionIntro._loadingEttPanels then return false end
	return true
end

function MissionIntro.ExportEttPanels()
	local data = {}
	for _, ent in ipairs(MissionIntro.GetEttPanels()) do
		data[#data + 1] = {
			pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
			ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		}
	end
	return data
end

function MissionIntro.ReadEttPanelsFromDisk()
	local path = MissionIntro.GetEttPanelSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not isstring(raw) or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteEttPanelsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureEttPanelSaveDir()
	file.Write(MissionIntro.GetEttPanelSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveEttPanelsToDisk()
	if not MissionIntro.CanSaveEttPanels() then return false end

	local data = MissionIntro.ExportEttPanels()
	MissionIntro.WriteEttPanelsToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_ett_panel"), MissionIntro.GetEttPanelSavePath())
	return true
end

function MissionIntro.CacheEttPanelsBeforeCleanup()
	MissionIntro._suppressEttPanelSave = true

	local live = MissionIntro.ExportEttPanels()
	local rows = (#live > 0) and live or MissionIntro.ReadEttPanelsFromDisk()
	MissionIntro._ettPanelPersistCache = rows

	MissionIntro.WriteEttPanelsToDisk(rows)
	MissionIntro.ServerMsg("log_cached", #rows, MissionIntro.L("log_entity_ett_panel"))
	return rows
end

function MissionIntro.LoadEttPanelsFromDisk(rows)
	if MissionIntro._loadingEttPanels then return end
	MissionIntro._loadingEttPanels = true

	rows = rows or MissionIntro.ReadEttPanelsFromDisk()

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_ett_panel")) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		if MissionIntro.CreateEttPanel then
			MissionIntro.CreateEttPanel(pos, ang, true)
		end
	end

	MissionIntro._loadingEttPanels = false
	MissionIntro.SyncEttPanels()
	MissionIntro.ServerMsg("log_loaded", #rows, MissionIntro.L("log_entity_ett_panel"), MissionIntro.GetEttPanelSavePath())
end

function MissionIntro.CreateEttPanel(pos, ang, silent)
	local ent = ents.Create("ent_mission_intro_ett_panel")
	if not IsValid(ent) then return nil end

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	MissionIntro.SyncEttPanels()

	if not silent and MissionIntro.SaveEttPanelsToDisk then
		MissionIntro.SaveEttPanelsToDisk()
	end

	return ent
end

function MissionIntro.RemoveAllEttPanels(save)
	MissionIntro._suppressEttPanelSave = true

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_ett_panel")) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressEttPanelSave = false

	if save ~= false and MissionIntro.SaveEttPanelsToDisk then
		MissionIntro.SaveEttPanelsToDisk()
	end
end

function MissionIntro.RequestSaveEttPanels()
	if not MissionIntro.CanSaveEttPanels() then return end
	timer.Simple(0, function()
		MissionIntro.SaveEttPanelsToDisk()
	end)
end

local function MI_ScheduleReloadEttPanels()
	timer.Create("MissionIntro_ReloadEttPanels", 1, 1, function()
		local rows = MissionIntro._ettPanelPersistCache
		if not rows or #rows == 0 then
			rows = MissionIntro.ReadEttPanelsFromDisk()
		end
		MissionIntro._ettPanelPersistCache = nil
		MissionIntro._suppressEttPanelSave = false

		if MissionIntro.LoadEttPanelsFromDisk then
			MissionIntro.LoadEttPanelsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadEttPanels", MI_ScheduleReloadEttPanels)

hook.Add("PostCleanupMap", "MissionIntro_ReloadEttPanels", function()
	MI_ScheduleReloadEttPanels()
end)

hook.Add("PostCleanup", "MissionIntro_ReloadEttPanels", MI_ScheduleReloadEttPanels)

net.Receive("MissionIntro_EttPanelAction", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local ent = net.ReadEntity()
	local action = net.ReadUInt(4) or 0

	if not IsValid(ent) or ent:GetClass() ~= "ent_mission_intro_ett_panel" then return end
	if not ent.CanUseDist or not ent:CanUseDist(ply) then return end

	if action == 2 then
		if not MissionIntro.IsPttrbPlayer or not MissionIntro.IsPttrbPlayer(ply) then
			local msg = MissionIntro.L and MissionIntro.L("ett_panel_pttrb_only") or "[ETT] ???????????????????"
			ply:ChatPrint(msg)
			return
		end
		if MissionIntro.CallEttReinforcements then
			MissionIntro.CallEttReinforcements(ply)
		end
	end
end)

hook.Add("EntityRemoved", "MissionIntro_SaveEttPanelsOnRemove", function(ent)
	if not ent or ent:GetClass() ~= "ent_mission_intro_ett_panel" then return end
	if MissionIntro._loadingEttPanels or MissionIntro._suppressEttPanelSave then return end
	if MissionIntro.RequestSaveEttPanels then
		MissionIntro.RequestSaveEttPanels()
	end
end)

hook.Add("ShutDown", "MissionIntro_SaveEttPanels", function()
	MissionIntro._suppressEttPanelSave = false
	if MissionIntro.SaveEttPanelsToDisk then
		MissionIntro.SaveEttPanelsToDisk()
	end
end)
