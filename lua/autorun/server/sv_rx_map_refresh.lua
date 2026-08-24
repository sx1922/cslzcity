MissionIntro = MissionIntro or {}
local RX = MissionIntro.RXMapRefresh or {}
MissionIntro.RXMapRefresh = RX

util.AddNetworkString("MissionIntro_RXMapRefresh_Sync")

RX._loading = false
RX._suppressSave = false
RX._cache = nil

local function RX_CanSave()
	if not RX.PersistEnabled then return false end
	if RX._loading then return false end
	if RX._suppressSave then return false end
	return true
end

function RX.EnsureDataDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	local dir = RX.DataDir or "rx_mission_intro/map_refresh"
	if not file.IsDir(dir, "DATA") then
		file.CreateDir(dir)
	end
end

function RX.NormalizeClass(class)
	if not isstring(class) then return nil end
	class = string.Trim(class)
	if class == "" then return nil end
	return string.lower(class)
end

function RX.IsValidSpawnClass(class)
	class = RX.NormalizeClass(class)
	if not class then return false end

	if weapons.Get(class) then return true, class end
	if scripted_ents.GetStored(class) then return true, class end

	return false
end

function RX.ExportRows()
	local rows = RX.ReadFromDisk()
	local out = {}

	for i, row in ipairs(rows) do
		if not istable(row) or not istable(row.pos) then continue end
		out[#out + 1] = {
			id = i,
			class = row.class or "",
			pos = row.pos,
			ang = row.ang or { p = 0, y = 0, r = 0 },
		}
	end

	return out
end

function RX.SyncToPlayers(ply)
	local payload = RX.ExportRows()
	net.Start("MissionIntro_RXMapRefresh_Sync")
		net.WriteTable(payload)
	if IsValid(ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function RX.ReadFromDisk()
	if not RX.PersistEnabled then return {} end

	local path = RX.GetSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function RX.SaveToDisk(rows)
	if not RX_CanSave() then return false end

	RX.EnsureDataDir()
	rows = rows or RX.ReadFromDisk()

	local json = util.TableToJSON(rows, true)
	file.Write(RX.GetSavePath(), json)

	MissionIntro.RXMapMsg("log_rxmap_saved", #rows, RX.GetSavePath())
	RX.SyncToPlayers()
	return true
end

function RX.RequestSave()
	timer.Simple(0, function()
		RX.SaveToDisk()
	end)
end

function RX.RemoveSpawnedWorld()
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) and ent._rxMapRefresh then
			ent:Remove()
		end
	end
end

function RX.SpawnEntry(row, slotId)
	if not istable(row) then return nil end

	local ok, class = RX.IsValidSpawnClass(row.class)
	if not ok then return nil end

	local posTbl = row.pos or {}
	local angTbl = row.ang or {}
	local pos = Vector(tonumber(posTbl.x) or 0, tonumber(posTbl.y) or 0, tonumber(posTbl.z) or 0)
	local ang = Angle(tonumber(angTbl.p) or 0, tonumber(angTbl.y) or 0, tonumber(angTbl.r) or 0)

	local ent = ents.Create(class)
	if not IsValid(ent) then return nil end

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()

	-- Homigrad??????????????E ????
	if ent:IsWeapon() then
		ent.IsSpawned = true
		ent.init = true
	end

	ent._rxMapRefresh = slotId or true
	return ent
end

function RX.SpawnAllFromDisk(rows)
	rows = rows or RX.ReadFromDisk()
	RX._suppressSave = false
	RX.RemoveSpawnedWorld()

	RX._loading = true
	for i, row in ipairs(rows) do
		RX.SpawnEntry(row, i)
	end
	RX._loading = false

	MissionIntro.RXMapMsg("log_rxmap_loaded", #rows, RX.GetSavePath())
	RX.SyncToPlayers()
end

function RX.AddPlacement(class, pos, ang)
	local ok, normalized = RX.IsValidSpawnClass(class)
	if not ok then
		return false, "invalid_class"
	end

	local rows = RX.ReadFromDisk()
	rows[#rows + 1] = {
		class = normalized,
		pos = { x = pos.x, y = pos.y, z = pos.z },
		ang = { p = ang.p, y = ang.y, r = ang.r },
	}

	RX.SaveToDisk(rows)
	RX.SpawnEntry(rows[#rows], #rows)
	return true
end

function RX.RemoveNearest(pos, radius)
	radius = radius or RX.RemoveRadius or 96
	local rows = RX.ReadFromDisk()
	if #rows == 0 then return false end

	local bestIdx
	local bestDist = radius

	for i, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local rowPos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local dist = rowPos:Distance(pos)
		if dist <= bestDist then
			bestDist = dist
			bestIdx = i
		end
	end

	if not bestIdx then return false end

	table.remove(rows, bestIdx)
	RX.SaveToDisk(rows)
	RX.SpawnAllFromDisk(rows)
	return true
end

function RX.ClearAll(ply)
	RX._suppressSave = true
	RX.RemoveSpawnedWorld()
	RX._suppressSave = false
	RX.SaveToDisk({})
	if IsValid(ply) then
		ply:ChatPrint("[RX地图刷新] 已删除本图全部刷新点")
	end
	return true
end

local function RX_ScheduleReload()
	timer.Create("MissionIntro_RXMapRefresh_Reload", 0.5, 1, function()
		local rows = RX._cache
		if not rows then
			rows = RX.ReadFromDisk()
		end
		RX._cache = nil
		RX.SpawnAllFromDisk(rows)
	end)
end

hook.Add("InitPostEntity", "MissionIntro_RXMapRefresh_Load", RX_ScheduleReload)

hook.Add("PreCleanupMap", "MissionIntro_RXMapRefresh_Cache", function()
	RX._suppressSave = true
	RX._cache = RX.ReadFromDisk()
	MissionIntro.RXMapMsg("log_rxmap_cached", #(RX._cache or {}))
end)

hook.Add("PostCleanupMap", "MissionIntro_RXMapRefresh_Reload", RX_ScheduleReload)
hook.Add("PostCleanup", "MissionIntro_RXMapRefresh_Reload", RX_ScheduleReload)

hook.Add("ShutDown", "MissionIntro_RXMapRefresh_Save", function()
	RX._suppressSave = false
	RX.SaveToDisk()
end)

net.Receive("MissionIntro_RXMapRefresh_Sync", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if MissionIntro.CanManage and not MissionIntro.CanManage(ply) then return end
	RX.SyncToPlayers(ply)
end)

concommand.Add("rx_map_refresh_reload", function(ply)
	if IsValid(ply) and MissionIntro.CanManage and not MissionIntro.CanManage(ply) then return end
	RX.SpawnAllFromDisk()
end)

concommand.Add("rx_map_refresh_clear", function(ply)
	if IsValid(ply) and MissionIntro.CanManage and not MissionIntro.CanManage(ply) then return end
	RX.ClearAll(ply)
end)

hook.Add("PlayerCanPickupWeapon", "MissionIntro_RXMapRefresh_NoAutoPickup", function(ply, wep)
	if not IsValid(wep) or not wep._rxMapRefresh then return end
	if ply.force_pickup then return end
	-- ??Homigrad ??????? E????????????
	if not ply:KeyDown(IN_USE) then
		return false
	end
end)
