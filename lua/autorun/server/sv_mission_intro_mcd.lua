if not SERVER then return end

MissionIntro = MissionIntro or {}
MissionIntro._mcdEmployerEvacuated = MissionIntro._mcdEmployerEvacuated or false
MissionIntro._mcdRadioUsed = MissionIntro._mcdRadioUsed or false
MissionIntro.McdPersistEnabled = MissionIntro.McdPersistEnabled ~= false

util.AddNetworkString("MissionIntro_McdDispatchMsg")
util.AddNetworkString("MissionIntro_McdEmployerEvacuated")
util.AddNetworkString("MissionIntro_McdEvacProgress")
util.AddNetworkString("MissionIntro_McdRadioPickupMsg")
util.AddNetworkString("MissionIntro_McdEmployerDied")
util.AddNetworkString("MissionIntro_McdClearHints")
util.AddNetworkString("MissionIntro_McdEmployerSync")

MissionIntro._mcdEmployer = MissionIntro._mcdEmployer or NULL
MissionIntro._mcdEmployerDead = MissionIntro._mcdEmployerDead or false

local function MI_ShuffleTable(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function MI_PanelDir(sub)
	return "rx_mission_intro/mcd_" .. sub
end

function MissionIntro.GetMcdSavePath(kind)
	return MI_PanelDir(kind) .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureMcdSaveDir(kind)
	if not file.IsDir("rx_mission_intro", "DATA") then file.CreateDir("rx_mission_intro") end
	local dir = MI_PanelDir(kind)
	if not file.IsDir(dir, "DATA") then file.CreateDir(dir) end
end

function MissionIntro.WriteMcdRows(kind, rows)
	MissionIntro.EnsureMcdSaveDir(kind)
	file.Write(MissionIntro.GetMcdSavePath(kind), util.TableToJSON(rows or {}, true))
end

function MissionIntro.ReadMcdRows(kind)
	local path = MissionIntro.GetMcdSavePath(kind)
	if not file.Exists(path, "DATA") then return {} end
	local raw = file.Read(path, "DATA")
	if not isstring(raw) or raw == "" then return {} end
	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end
	return data
end

local function MI_ExportEntities(className, extra)
	local data = {}
	for _, ent in ipairs(ents.FindByClass(className)) do
		if not IsValid(ent) then continue end
		local row = {
			pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
			ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		}
		if extra then extra(ent, row) end
		data[#data + 1] = row
	end
	return data
end

function MissionIntro.GetMcdSpawns()
	local list = {}
	if not MissionIntro.GetSpawnEntities then return list end

	for _, ent in ipairs(MissionIntro.GetSpawnEntities()) do
		if not IsValid(ent) then continue end
		local fac = ""
		if ent.GetSpawnFaction then
			fac = MissionIntro.NormalizeSpawnFaction and MissionIntro.NormalizeSpawnFaction(ent:GetSpawnFaction()) or (ent:GetSpawnFaction() or "")
		end
		if fac == "mcd_squad" then
			list[#list + 1] = ent
		end
	end

	return list
end

function MissionIntro.SyncMcdEmployerNetwork()
	local employer = MissionIntro.GetMcdEmployer()
	local ent = IsValid(employer) and employer or NULL

	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p.SetNWEntity then
			p:SetNWEntity("MissionIntro_McdEmployer", ent)
		end
	end

	net.Start("MissionIntro_McdEmployerSync")
		net.WriteEntity(ent)
	net.Broadcast()
end

function MissionIntro.SetMcdEmployer(ply)
	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) then continue end
		p._missionIntroIsEmployer = false
		if p.SetNWBool then
			p:SetNWBool("MissionIntro_IsEmployer", false)
		end
	end

	if IsValid(ply) and ply:IsPlayer() then
		ply._missionIntroIsEmployer = true
		if ply.SetNWBool then
			ply:SetNWBool("MissionIntro_IsEmployer", true)
		end
		MissionIntro._mcdEmployer = ply
		MissionIntro._mcdEmployerSid64 = ply:SteamID64()
		MissionIntro.SyncMcdEmployerNetwork()
		return true
	end

	MissionIntro._mcdEmployer = NULL
	MissionIntro._mcdEmployerSid64 = nil
	MissionIntro.SyncMcdEmployerNetwork()
	return false
end

function MissionIntro.GetMcdEmployer()
	if IsValid(MissionIntro._mcdEmployer) then return MissionIntro._mcdEmployer end

	local sid64 = MissionIntro._mcdEmployerSid64
	if isstring(sid64) and sid64 ~= "" then
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply:SteamID64() == sid64 then
				MissionIntro._mcdEmployer = ply
				ply._missionIntroIsEmployer = true
				if ply.SetNWBool then
					ply:SetNWBool("MissionIntro_IsEmployer", true)
				end
				return ply
			end
		end
	end

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:GetNWBool("MissionIntro_IsEmployer", false) then
			MissionIntro._mcdEmployer = ply
			MissionIntro._mcdEmployerSid64 = ply:SteamID64()
			return ply
		end
	end

	return NULL
end

function MissionIntro.GetMcdEvacs()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_mcd_evac")) do
		if IsValid(ent) then list[#list + 1] = ent end
	end
	return list
end

function MissionIntro.GetMcdRadios()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_mcd_radio")) do
		if IsValid(ent) then list[#list + 1] = ent end
	end
	return list
end

function MissionIntro.PickMcdSpawnData()
	local spawns = MissionIntro.GetMcdSpawns()
	if #spawns == 0 then return nil end
	local ent = spawns[math.random(#spawns)]
	return { pos = ent:GetPos(), ang = ent:GetAngles() }
end

function MissionIntro.RespawnPlayerAtMcdSpawn(ply)
	if MissionIntro.RespawnPlayerAtMissionSpawn then
		return MissionIntro.RespawnPlayerAtMissionSpawn(ply)
	end
	if MissionIntro.RespawnPlayer then
		MissionIntro.RespawnPlayer(ply)
	end
	return false
end

function MissionIntro.SaveMcdPlaced(kind)
	if MissionIntro._suppressMcdSave then return false end
	if kind == "evac" then
		MissionIntro.WriteMcdRows("evacs", MI_ExportEntities("ent_mission_intro_mcd_evac", function(ent, row)
			row.radius = ent.GetEvacZoneRadius and ent:GetEvacZoneRadius() or nil
		end))
	elseif kind == "radio" then
		MissionIntro.WriteMcdRows("radios", MI_ExportEntities("ent_mission_intro_mcd_radio"))
	end
	return true
end

function MissionIntro.CacheMcdWorldBeforeCleanup()
	MissionIntro._suppressMcdSave = true
	MissionIntro._mcdPersistCache = {
		evacs = MI_ExportEntities("ent_mission_intro_mcd_evac", function(ent, row)
			row.radius = ent.GetEvacZoneRadius and ent:GetEvacZoneRadius() or nil
		end),
		radios = MI_ExportEntities("ent_mission_intro_mcd_radio"),
	}
	if #MissionIntro._mcdPersistCache.evacs == 0 then
		MissionIntro._mcdPersistCache.evacs = MissionIntro.ReadMcdRows("evacs")
	end
	if #MissionIntro._mcdPersistCache.radios == 0 then
		MissionIntro._mcdPersistCache.radios = MissionIntro.ReadMcdRows("radios")
	end
	MissionIntro.WriteMcdRows("evacs", MissionIntro._mcdPersistCache.evacs)
	MissionIntro.WriteMcdRows("radios", MissionIntro._mcdPersistCache.radios)
	MissionIntro.ServerMsg("log_mcd_cached")
end

local function MI_RemoveClass(className)
	for _, ent in ipairs(ents.FindByClass(className)) do
		if IsValid(ent) then ent:Remove() end
	end
end

function MissionIntro.LoadMcdWorld(rows)
	if MissionIntro._loadingMcdWorld then return end
	MissionIntro._loadingMcdWorld = true

	rows = rows or {}
	MI_RemoveClass("ent_mission_intro_mcd_evac")
	MI_RemoveClass("ent_mission_intro_mcd_radio")

	-- ?? MC&D ??????????????
	for _, row in ipairs(rows.spawns or {}) do
		if not istable(row.pos) then continue end
		local pos = Vector(row.pos.x, row.pos.y, row.pos.z)
		local ang = Angle(0, row.ang and row.ang.y or 0, 0)
		if MissionIntro.CreateSpawnPoint then
			MissionIntro.CreateSpawnPoint(pos, ang, true, "mcd_squad")
		end
	end
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_mcd_spawn")) do
		if not IsValid(ent) then continue end
		if MissionIntro.CreateSpawnPoint then
			MissionIntro.CreateSpawnPoint(ent:GetPos(), ent:GetAngles(), true, "mcd_squad")
		end
		ent:Remove()
	end

	for _, row in ipairs(rows.evacs or {}) do
		if not istable(row.pos) then continue end
		local pos = Vector(row.pos.x, row.pos.y, row.pos.z)
		local ang = Angle(0, row.ang and row.ang.y or 0, 0)
		local radius = tonumber(row.radius)
		if MissionIntro.CreateMcdEvac then MissionIntro.CreateMcdEvac(pos, ang, radius, true) end
	end

	for _, row in ipairs(rows.radios or {}) do
		if not istable(row.pos) then continue end
		local pos = Vector(row.pos.x, row.pos.y, row.pos.z)
		local ang = Angle(0, row.ang and row.ang.y or 0, 0)
		if MissionIntro.CreateMcdRadio then MissionIntro.CreateMcdRadio(pos, ang, true) end
	end

	MissionIntro._loadingMcdWorld = false
	MissionIntro._suppressMcdSave = false
	MissionIntro.ServerMsg("log_mcd_loaded")
end

function MissionIntro.CreateMcdSpawn(pos, ang, silent)
	if MissionIntro.CreateSpawnPoint then
		return MissionIntro.CreateSpawnPoint(pos, ang, silent, "mcd_squad")
	end
	return nil
end

function MissionIntro.CreateMcdEvac(pos, ang, radius, silent)
	local ent = ents.Create("ent_mission_intro_mcd_evac")
	if not IsValid(ent) then return nil end
	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end
	if radius and ent.SetEvacZoneRadius then ent:SetEvacZoneRadius(radius) end
	if not silent then MissionIntro.SaveMcdPlaced("evac") end
	return ent
end

function MissionIntro.CreateMcdRadio(pos, ang, silent)
	local ent = ents.Create("ent_mission_intro_mcd_radio")
	if not IsValid(ent) then return nil end
	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end
	if not silent then MissionIntro.SaveMcdPlaced("radio") end
	return ent
end

function MissionIntro.RemoveAllMcd(kind, save)
	MissionIntro._suppressMcdSave = true
	if kind == "spawn" then
		for _, ent in ipairs(MissionIntro.GetMcdSpawns()) do
			if IsValid(ent) then ent:Remove() end
		end
		if MissionIntro.RequestSaveSpawnPoints then MissionIntro.RequestSaveSpawnPoints() end
	end
	if kind == "evac" or not kind then MI_RemoveClass("ent_mission_intro_mcd_evac") end
	if kind == "radio" or not kind then MI_RemoveClass("ent_mission_intro_mcd_radio") end
	MissionIntro._suppressMcdSave = false
	if save ~= false then
		if kind == "evac" then MissionIntro.WriteMcdRows("evacs", {})
		elseif kind == "radio" then MissionIntro.WriteMcdRows("radios", {})
		elseif not kind then
			MissionIntro.WriteMcdRows("evacs", {})
			MissionIntro.WriteMcdRows("radios", {})
		end
	end
end

function MissionIntro.ExecuteMcdEvacuation(ply, evacEnt)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.CanMcdPlayerEvacuate(ply) then return false end

	local wasEmployer = MissionIntro.IsEmployerPlayer(ply)
	ply._missionIntroMcdEvacuated = true

	for _, wep in ipairs(ply:GetWeapons()) do
		if IsValid(wep) then
			ply:StripWeapon(wep:GetClass())
		end
	end
	ply:StripWeapons()
	ply:StripAmmo()

	if MissionIntro.StripPlayerModelExtras then
		MissionIntro.StripPlayerModelExtras(ply)
	end

	for _, child in ipairs(ply:GetChildren()) do
		if IsValid(child) and child ~= ply then
			local class = child:GetClass() or ""
			if class ~= "predicted_viewmodel" and class ~= "viewmodel" then
				child:Remove()
			end
		end
	end

	if wasEmployer and MissionIntro.SetMcdEmployer then
		MissionIntro.SetMcdEmployer(nil)
	end

	if MissionIntro.ClearPlayerMissionIntroState then
		MissionIntro.ClearPlayerMissionIntroState(ply)
	end

	if ply:Alive() then
		ply:KillSilent()
	end

	if wasEmployer then
		ply:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_employer_evac_done") or "[MC&D] ????????")
	else
		ply:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_mcd_evac_done") or "[MC&D] ?????")
	end

	MsgN("[MissionIntro] MC&D ??: " .. ply:Nick())

	if MissionIntro.ClearMcdClientHints then
		for _, p in ipairs(player.GetAll()) do
			if MissionIntro.IsMcdPlayer(p) then
				MissionIntro.ClearMcdClientHints(p)
			end
		end
	end

	return true
end

function MissionIntro.ClearMcdClientHints(target)
	net.Start("MissionIntro_McdClearHints")
	if IsValid(target) and target:IsPlayer() then
		net.Send(target)
	else
		net.Broadcast()
	end
end

function MissionIntro.BroadcastMcdEmployerEvacuated()
	net.Start("MissionIntro_McdEmployerEvacuated")
	net.Broadcast()
	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.IsMcdPlayer(ply) then
			local msg = MissionIntro.L and MissionIntro.L("mcd_employer_evacuated_hint") or "[MC&D] ????????"
			ply:ChatPrint(msg)
		end
	end
end

function MissionIntro.ResetMcdRoundState(clearEmployer)
	MissionIntro._mcdEmployerEvacuated = false
	MissionIntro._mcdEmployerDead = false
	MissionIntro._mcdRadioUsed = false

	if clearEmployer and MissionIntro.SetMcdEmployer then
		MissionIntro.SetMcdEmployer(nil)
	end

	for _, ply in ipairs(player.GetAll()) do
		ply._missionIntroMcdEvacuated = nil
	end

	if MissionIntro.SyncMcdEmployerNetwork then
		MissionIntro.SyncMcdEmployerNetwork()
	end

	if MissionIntro.ClearMcdClientHints then
		MissionIntro.ClearMcdClientHints()
	end
end

function MissionIntro.BroadcastMcdEmployerDied()
	if MissionIntro._mcdEmployerDead then return end

	MissionIntro._mcdEmployerDead = true

	if MissionIntro.SetMcdEmployer then
		MissionIntro.SetMcdEmployer(nil)
	end

	net.Start("MissionIntro_McdEmployerDied")
	net.Broadcast()

	local msg = MissionIntro.L and MissionIntro.L("mcd_employer_died_hint") or "[MC&D] ???????????"
	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.IsMcdPlayer(ply) then
			ply:ChatPrint(msg)
		end
	end
end

local function MI_WasEmployerAtDeath(ply)
	if not IsValid(ply) then return false end
	if ply:GetNWBool("MissionIntro_IsEmployer", false) then return true end
	if ply._missionIntroIsEmployer == true then return true end
	if MissionIntro._mcdEmployer == ply then return true end
	return false
end

function MissionIntro.IsMcdReinforceCandidate(ply)
	if not IsValid(ply) or not ply:IsPlayer() or ply:Alive() then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end

	local fromHook = hook.Run("MissionIntro_IsMcdReinforceCandidate", ply)
	if fromHook == false then return false end
	if fromHook == true then return true end

	return true
end

function MissionIntro.SpawnMcdReinforcementsFromDead(caller)
	local cfg = MissionIntro.Mcd or {}
	local minN = tonumber(cfg.reinforce_min) or 1
	local maxN = tonumber(cfg.reinforce_max) or 3

	if #MissionIntro.GetMcdSpawns() == 0 then
		if IsValid(caller) then
			caller:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_no_spawn") or "[MC&D] ??????????????")
		end
		return false
	end

	local dead = {}
	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.IsMcdReinforceCandidate(ply) then
			dead[#dead + 1] = ply
		end
	end

	if #dead == 0 then
		if IsValid(caller) then
			caller:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_no_dead") or "[MC&D] ???????????")
		end
		return false
	end

	MI_ShuffleTable(dead)
	local count = math.min(maxN, math.max(minN, math.random(minN, math.min(maxN, #dead))))
	local targets = {}
	for i = 1, count do targets[i] = dead[i] end

	for _, ply in ipairs(targets) do
		if IsValid(ply) and MissionIntro.PreparePlayerForSupportReinforce then
			MissionIntro.PreparePlayerForSupportReinforce(ply)
		end
	end

	local startList = MissionIntro.AssignMcdCaptainToPlayers and MissionIntro.AssignMcdCaptainToPlayers(targets) or targets
	if #startList == 0 then return false end

	MissionIntro._mcdRadioUsed = true
	local msg = MissionIntro.L and MissionIntro.L("mcd_dispatch_msg") or "?????????????????"
	net.Start("MissionIntro_McdDispatchMsg")
		net.WriteString(msg)
	net.Broadcast()

	for _, ply in ipairs(startList) do
		if not IsValid(ply) then continue end
		if MissionIntro.AssignMcdRole then
			MissionIntro.AssignMcdRole(ply, "captain")
		else
			ply._missionIntroFaction = "mcd_squad"
			ply:SetNWString("MissionIntro_FactionId", "mcd_squad")
		end
	end

	if MissionIntro.BatchRespawnAndStartIntro then
		MissionIntro.BatchRespawnAndStartIntro(startList, {
			factionId = "mcd_squad",
			respawnFn = MissionIntro.RespawnPlayerAtMcdSpawn,
		})
	end

	MissionIntro.ServerMsg("log_mcd_round_start", #startList)
	return true
end

function MissionIntro.AssignMcdEmployerFromRadio(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if MissionIntro.IsMcdPlayer and MissionIntro.IsMcdPlayer(ply) then return false end
	if not MissionIntro.SetMcdEmployer then return false end

	local prev = MissionIntro.GetMcdEmployer()
	MissionIntro.SetMcdEmployer(ply)

	if not IsValid(prev) or prev ~= ply then
		ply:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_employer_auto_radio") or "[MC&D] ????????????? MC&D ????")
	end

	return true
end

function MissionIntro.TryUseMcdRadio(ply, ent)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	local canUse = hook.Run("MissionIntro_CanUseMcdRadio", ply, ent)
	if canUse == false then return false end

	if MissionIntro.IsMcdPlayer and MissionIntro.IsMcdPlayer(ply) then
		ply:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_radio_mcd_no_need") or "[MC&D] ??????????")
		return false
	end

	if MissionIntro._mcdRadioUsed then
		ply:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_radio_used") or "[MC&D] ?????????????")
		return false
	end

	if MissionIntro.SpawnMcdReinforcementsFromDead(ply) then
		MissionIntro.AssignMcdEmployerFromRadio(ply)
		return true
	end

	return false
end

local function MI_ScheduleReloadMcd()
	timer.Create("MissionIntro_ReloadMcdWorld", 1, 1, function()
		local rows = MissionIntro._mcdPersistCache
		if not rows or (not rows.evacs and not rows.radios) then
			rows = {
				spawns = MissionIntro.ReadMcdRows("spawns"),
				evacs = MissionIntro.ReadMcdRows("evacs"),
				radios = MissionIntro.ReadMcdRows("radios"),
			}
		end
		MissionIntro._mcdPersistCache = nil
		MissionIntro.LoadMcdWorld(rows)
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadMcdWorld", MI_ScheduleReloadMcd)

hook.Add("PreCleanupMap", "MissionIntro_KeepMcdWorld", function()
	MissionIntro.CacheMcdWorldBeforeCleanup()
end)

hook.Add("PostCleanupMap", "MissionIntro_ReloadMcdWorld", function()
	if MissionIntro.ResetMcdRoundState then
		MissionIntro.ResetMcdRoundState(true)
	end
	MI_ScheduleReloadMcd()
end)

hook.Add("PostCleanup", "MissionIntro_ReloadMcdWorldAlt", MI_ScheduleReloadMcd)

hook.Add("EntityRemoved", "MissionIntro_SaveMcdOnRemove", function(ent)
	if not ent then return end
	local class = ent:GetClass()
	if MissionIntro._suppressMcdSave or MissionIntro._loadingMcdWorld then return end
	if class == "ent_mission_intro_mcd_evac" then
		timer.Simple(0, function() MissionIntro.SaveMcdPlaced("evac") end)
	elseif class == "ent_mission_intro_mcd_radio" then
		timer.Simple(0, function() MissionIntro.SaveMcdPlaced("radio") end)
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_McdEvacCancel", function(ply)
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_mcd_evac")) do
		if IsValid(ent) and ent.GetEvacuatingPlayer and ent:GetEvacuatingPlayer() == ply then
			ent:CancelEvac()
		end
	end
end)

hook.Add("PlayerDeath", "MissionIntro_McdEvacCancel", function(ply)
	if MI_WasEmployerAtDeath(ply) and MissionIntro.BroadcastMcdEmployerDied then
		MissionIntro.BroadcastMcdEmployerDied()
	end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_mcd_evac")) do
		if IsValid(ent) and ent.GetEvacuatingPlayer and ent:GetEvacuatingPlayer() == ply then
			ent:CancelEvac()
		end
	end
end)

for _, hookName in ipairs({ "RoundStart", "Breach_NewRound", "OnNewRound", "HMCD_NewRound", "HomigradRoundStart" }) do
	hook.Add(hookName, "MissionIntro_ResetMcdEvacuated", function()
		if MissionIntro.ResetMcdRoundState then
			MissionIntro.ResetMcdRoundState()
		end
	end)
end

hook.Add("PlayerDisconnected", "MissionIntro_McdEmployerDisconnect", function(ply)
	if MI_WasEmployerAtDeath(ply) and MissionIntro.BroadcastMcdEmployerDied then
		MissionIntro.BroadcastMcdEmployerDied()
	end
end)

hook.Add("PlayerInitialSpawn", "MissionIntro_McdEmployerSyncJoin", function(ply)
	timer.Simple(0, function()
		if IsValid(ply) and MissionIntro.SyncMcdEmployerNetwork then
			MissionIntro.SyncMcdEmployerNetwork()
		end
	end)
end)

hook.Add("PlayerSpawn", "MissionIntro_McdClearEvacFlag", function(ply)
	if not IsValid(ply) then return end
	ply._missionIntroMcdEvacuated = nil

	timer.Simple(0, function()
		if not IsValid(ply) then return end
		local sid64 = MissionIntro._mcdEmployerSid64
		if not isstring(sid64) or sid64 == "" or ply:SteamID64() ~= sid64 then return end

		MissionIntro._mcdEmployer = ply
		ply._missionIntroIsEmployer = true
		if ply.SetNWBool then
			ply:SetNWBool("MissionIntro_IsEmployer", true)
		end
		if MissionIntro.SyncMcdEmployerNetwork then
			MissionIntro.SyncMcdEmployerNetwork()
		end
	end)
end)

hook.Add("ShutDown", "MissionIntro_SaveMcdWorld", function()
	MissionIntro._suppressMcdSave = false
	MissionIntro.SaveMcdPlaced("evac")
	MissionIntro.SaveMcdPlaced("radio")
end)
