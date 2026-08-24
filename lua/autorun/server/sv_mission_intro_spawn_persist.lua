MissionIntro = MissionIntro or {}
MissionIntro.SpawnPersistEnabled = true

local function MI_SpawnDir()
	return "rx_mission_intro/spawns"
end

function MissionIntro.GetSpawnSavePath()
	return MI_SpawnDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureSpawnSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_SpawnDir(), "DATA") then
		file.CreateDir(MI_SpawnDir())
	end
end

function MissionIntro.CanSaveSpawnPoints()
	if not MissionIntro.SpawnPersistEnabled then return false end
	if MissionIntro._loadingSpawns then return false end
	if MissionIntro._suppressSpawnSave then return false end
	return true
end

function MissionIntro.ExportSpawnPoints()
	local out = {}

	if not MissionIntro.GetSpawnEntities then return out end

	for _, ent in ipairs(MissionIntro.GetSpawnEntities()) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		local faction = ""
		if ent.GetSpawnFaction then
			faction = ent:GetSpawnFaction() or ""
		end

		out[#out + 1] = {
			pos = { x = pos.x, y = pos.y, z = pos.z },
			ang = { p = ang.p, y = ang.y, r = ang.r },
			faction = faction,
		}
	end

	return out
end

function MissionIntro.SaveSpawnPointsToDisk()
	if not MissionIntro.CanSaveSpawnPoints() then return false end

	MissionIntro.EnsureSpawnSaveDir()

	local data = MissionIntro.ExportSpawnPoints()
	local json = util.TableToJSON(data, true)
	file.Write(MissionIntro.GetSpawnSavePath(), json)

	MsgN("[MissionIntro] 已保存 " .. #data .. " 个出生点 -> data/" .. MissionIntro.GetSpawnSavePath())
	return true
end

function MissionIntro.ReadSpawnPointsFromDisk()
	if not MissionIntro.SpawnPersistEnabled then return {} end

	local path = MissionIntro.GetSpawnSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.CreateSpawnPoint(pos, ang, silent, factionId)
	local ent = ents.Create("ent_mission_intro_spawn")
	if not IsValid(ent) then return nil end

	ent:SetPos(pos)
	ent:SetAngles(ang or angle_zero)

	local fac = MissionIntro.NormalizeSpawnFaction(factionId)
	if ent.SetSpawnFaction then
		ent:SetSpawnFaction(fac)
	end

	ent:Spawn()
	ent:Activate()

	if MissionIntro.RenumberSpawnPoints then
		MissionIntro.RenumberSpawnPoints()
	end

	if not silent then
		MissionIntro.SaveSpawnPointsToDisk()
	end

	return ent
end

function MissionIntro.RemoveAllSpawnPoints(save)
	MissionIntro._loadingSpawns = true
	MissionIntro._suppressSpawnSave = true

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_spawn")) do
		if IsValid(ent) then
			ent:Remove()
		end
	end

	MissionIntro._loadingSpawns = false
	MissionIntro._suppressSpawnSave = false

	if MissionIntro.RenumberSpawnPoints then
		MissionIntro.RenumberSpawnPoints()
	end

	if save ~= false then
		MissionIntro.SaveSpawnPointsToDisk()
	end
end

function MissionIntro.LoadSpawnPointsFromDisk(rows)
	if not MissionIntro.SpawnPersistEnabled then return end

	rows = rows or MissionIntro.ReadSpawnPointsFromDisk()

	MissionIntro._loadingSpawns = true
	MissionIntro._suppressSpawnSave = true

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_spawn")) do
		if IsValid(ent) then
			ent:Remove()
		end
	end

	for _, row in ipairs(rows) do
		if not istable(row) or not istable(row.pos) then continue end

		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local angTbl = row.ang or {}
		local ang = Angle(tonumber(angTbl.p) or 0, tonumber(angTbl.y) or 0, tonumber(angTbl.r) or 0)

		MissionIntro.CreateSpawnPoint(pos, ang, true, row.faction)
	end

	MissionIntro._loadingSpawns = false
	MissionIntro._suppressSpawnSave = false

	if MissionIntro.RenumberSpawnPoints then
		MissionIntro.RenumberSpawnPoints()
	end

	MsgN("[MissionIntro] 已加载 " .. #rows .. " 个出生点 <- data/" .. MissionIntro.GetSpawnSavePath())
end

local function MI_ScheduleReload()
	timer.Create("MissionIntro_ReloadSpawns", 0.5, 1, function()
		local rows = MissionIntro._spawnPersistCache
		if not rows or #rows == 0 then
			rows = MissionIntro.ReadSpawnPointsFromDisk()
		end
		MissionIntro._spawnPersistCache = nil
		MissionIntro.LoadSpawnPointsFromDisk(rows)
		if MissionIntro.ResetSpawnRoundRobin then
			MissionIntro.ResetSpawnRoundRobin()
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadSpawns", MI_ScheduleReload)

hook.Add("PreCleanupMap", "MissionIntro_KeepSpawns", function()
	MissionIntro._suppressSpawnSave = true
	MissionIntro._spawnPersistCache = MissionIntro.ReadSpawnPointsFromDisk()
	MsgN("[MissionIntro] 清图前已缓存 " .. #(MissionIntro._spawnPersistCache or {}) .. " 个出生点")
end)

hook.Add("PostCleanupMap", "MissionIntro_ReloadSpawns", MI_ScheduleReload)

hook.Add("PostCleanup", "MissionIntro_ReloadSpawns", MI_ScheduleReload)

hook.Add("ShutDown", "MissionIntro_SaveSpawns", function()
	MissionIntro._suppressSpawnSave = false
	MissionIntro.SaveSpawnPointsToDisk()
end)

function MissionIntro.RequestSaveSpawnPoints()
	timer.Simple(0, function()
		MissionIntro.SaveSpawnPointsToDisk()
	end)
end
