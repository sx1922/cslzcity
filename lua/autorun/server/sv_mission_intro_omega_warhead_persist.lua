if not SERVER then return end

MissionIntro = MissionIntro or {}

local CONSOLE_CLASS = MissionIntro.OmegaWarheadConsoleClass or "ent_mission_intro_omega_console"
local CANCEL_CLASS = MissionIntro.OmegaWarheadCancelClass or "ent_mission_intro_omega_cancel"

local function MI_OmegaRowsHaveData(rows)
	if not istable(rows) then return false end
	return #(rows.consoles or {}) > 0 or #(rows.cancels or {}) > 0
end

local function MI_Dir()
	return "rx_mission_intro/omega_warhead"
end

function MissionIntro.GetOmegaWarheadSavePath()
	return MI_Dir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureOmegaWarheadSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_Dir(), "DATA") then
		file.CreateDir(MI_Dir())
	end
end

function MissionIntro.CanSaveOmegaWarheadEntities()
	if MissionIntro.OmegaWarheadPersistEnabled == false then return false end
	if MissionIntro._suppressOmegaWarheadSave then return false end
	if MissionIntro._loadingOmegaWarheadEntities then return false end
	return true
end

local function MI_ExportClass(className, includeWarheadTime)
	local data = {}
	for _, ent in ipairs(ents.FindByClass(className)) do
		if not IsValid(ent) then continue end
		local row = {
			pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
			ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		}
		if includeWarheadTime and ent.GetWarheadTime then
			row.warhead_time = tonumber(ent:GetWarheadTime()) or 90
		end
		data[#data + 1] = row
	end
	return data
end

function MissionIntro.ExportOmegaWarheadEntities()
	return {
		consoles = MI_ExportClass(CONSOLE_CLASS, true),
		cancels = MI_ExportClass(CANCEL_CLASS, false),
	}
end

function MissionIntro.ReadOmegaWarheadEntitiesFromDisk()
	local path = MissionIntro.GetOmegaWarheadSavePath()
	if not file.Exists(path, "DATA") then
		return { consoles = {}, cancels = {} }
	end

	local raw = file.Read(path, "DATA")
	if not isstring(raw) or raw == "" then
		return { consoles = {}, cancels = {} }
	end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then
		return { consoles = {}, cancels = {} }
	end

	data.consoles = istable(data.consoles) and data.consoles or {}
	data.cancels = istable(data.cancels) and data.cancels or {}
	return data
end

function MissionIntro.WriteOmegaWarheadEntitiesToDisk(rows)
	rows = rows or { consoles = {}, cancels = {} }
	MissionIntro.EnsureOmegaWarheadSaveDir()
	file.Write(MissionIntro.GetOmegaWarheadSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveOmegaWarheadEntitiesToDisk()
	if not MissionIntro.CanSaveOmegaWarheadEntities() then return false end

	local data = MissionIntro.ExportOmegaWarheadEntities()
	MissionIntro.WriteOmegaWarheadEntitiesToDisk(data)
	MissionIntro.ServerMsg("log_omega_saved", #data.consoles, #data.cancels, MissionIntro.GetOmegaWarheadSavePath())
	return true
end

function MissionIntro.CacheOmegaWarheadEntitiesBeforeCleanup()
	local live = MissionIntro.ExportOmegaWarheadEntities()
	local rows = MI_OmegaRowsHaveData(live) and live or MissionIntro.ReadOmegaWarheadEntitiesFromDisk()

	MissionIntro._omegaWarheadPersistCache = rows
	if MissionIntro.OmegaWarheadPersistEnabled then
		MissionIntro.WriteOmegaWarheadEntitiesToDisk(rows)
	end
	MissionIntro.ServerMsg("log_omega_cached", #(rows.consoles or {}), #(rows.cancels or {}))

	return rows
end

local function MI_RemoveClass(className)
	for _, ent in ipairs(ents.FindByClass(className)) do
		if IsValid(ent) then ent:Remove() end
	end
end

function MissionIntro.CreateOmegaConsole(pos, ang, silent, warheadTime)
	local ent = ents.Create(CONSOLE_CLASS)
	if not IsValid(ent) then return nil end

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang, 2)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	if not IsValid(ent) then return nil end

	local wt = tonumber(warheadTime)
	if wt and table.HasValue({ 80, 90, 100, 110, 120 }, wt) and ent.SetWarheadTime then
		ent:SetWarheadTime(wt)
	end

	if not silent and MissionIntro.SaveOmegaWarheadEntitiesToDisk then
		MissionIntro.SaveOmegaWarheadEntitiesToDisk()
	end

	return ent
end

function MissionIntro.CreateOmegaCancel(pos, ang, silent)
	local ent = ents.Create(CANCEL_CLASS)
	if not IsValid(ent) then return nil end

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang, 2)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	if not IsValid(ent) then return nil end

	if not silent and MissionIntro.SaveOmegaWarheadEntitiesToDisk then
		MissionIntro.SaveOmegaWarheadEntitiesToDisk()
	end

	return ent
end

function MissionIntro.LoadOmegaWarheadEntitiesFromDisk(rows)
	if MissionIntro._loadingOmegaWarheadEntities then return end
	MissionIntro._loadingOmegaWarheadEntities = true
	MissionIntro._suppressOmegaWarheadSave = true

	rows = rows or MissionIntro.ReadOmegaWarheadEntitiesFromDisk()

	MI_RemoveClass(CONSOLE_CLASS)
	MI_RemoveClass(CANCEL_CLASS)

	for _, row in ipairs(rows.consoles or {}) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		MissionIntro.CreateOmegaConsole(pos, ang, true, row.warhead_time)
	end

	for _, row in ipairs(rows.cancels or {}) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		MissionIntro.CreateOmegaCancel(pos, ang, true)
	end

	MissionIntro._loadingOmegaWarheadEntities = false
	MissionIntro._suppressOmegaWarheadSave = false
	MissionIntro.ServerMsg("log_omega_loaded", #(rows.consoles or {}), #(rows.cancels or {}))
end

function MissionIntro.RemoveAllOmegaConsoles(save)
	MissionIntro._suppressOmegaWarheadSave = true
	MI_RemoveClass(CONSOLE_CLASS)
	MissionIntro._suppressOmegaWarheadSave = false
	if save ~= false and MissionIntro.SaveOmegaWarheadEntitiesToDisk then
		MissionIntro.SaveOmegaWarheadEntitiesToDisk()
	end
end

function MissionIntro.RemoveAllOmegaCancels(save)
	MissionIntro._suppressOmegaWarheadSave = true
	MI_RemoveClass(CANCEL_CLASS)
	MissionIntro._suppressOmegaWarheadSave = false
	if save ~= false and MissionIntro.SaveOmegaWarheadEntitiesToDisk then
		MissionIntro.SaveOmegaWarheadEntitiesToDisk()
	end
end

function MissionIntro.RequestSaveOmegaWarheadEntities()
	if not MissionIntro.CanSaveOmegaWarheadEntities() then return end
	timer.Simple(0, function()
		if not MissionIntro.CanSaveOmegaWarheadEntities() then return end
		if MissionIntro.SaveOmegaWarheadEntitiesToDisk then
			MissionIntro.SaveOmegaWarheadEntitiesToDisk()
		end
	end)
end

local function MI_ScheduleReloadOmegaWarhead()
	timer.Create("MissionIntro_ReloadOmegaWarhead", 0.5, 1, function()
		local rows = MissionIntro._omegaWarheadPersistCache
		if not MI_OmegaRowsHaveData(rows) then
			rows = MissionIntro.ReadOmegaWarheadEntitiesFromDisk()
		end
		MissionIntro._omegaWarheadPersistCache = nil
		MissionIntro.LoadOmegaWarheadEntitiesFromDisk(rows)
		MissionIntro._suppressOmegaWarheadSave = false
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadOmegaWarhead", MI_ScheduleReloadOmegaWarhead)
hook.Add("PostCleanupMap", "MissionIntro_ReloadOmegaWarhead", MI_ScheduleReloadOmegaWarhead)
hook.Add("PostCleanup", "MissionIntro_ReloadOmegaWarhead", MI_ScheduleReloadOmegaWarhead)

hook.Add("PreCleanupMap", "MissionIntro_CacheOmegaWarhead", function()
	MissionIntro._suppressOmegaWarheadSave = true
	if MissionIntro.CacheOmegaWarheadEntitiesBeforeCleanup then
		MissionIntro.CacheOmegaWarheadEntitiesBeforeCleanup()
	end
end)

hook.Add("ShutDown", "MissionIntro_SaveOmegaWarhead", function()
	MissionIntro._suppressOmegaWarheadSave = false
	local data = MissionIntro.ExportOmegaWarheadEntities and MissionIntro.ExportOmegaWarheadEntities()
	if not MI_OmegaRowsHaveData(data) then return end
	if MissionIntro.SaveOmegaWarheadEntitiesToDisk then
		MissionIntro.SaveOmegaWarheadEntitiesToDisk()
	end
end)

concommand.Add("mission_intro_omega_reload", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	if MissionIntro.LoadOmegaWarheadEntitiesFromDisk then
		MissionIntro.LoadOmegaWarheadEntitiesFromDisk()
	end
	if IsValid(ply) then
		ply:ChatPrint("[MissionIntro] 已从 data/" .. (MissionIntro.GetOmegaWarheadSavePath and MissionIntro.GetOmegaWarheadSavePath() or "?") .. " 重载欧米茄实体")
	end
end)
