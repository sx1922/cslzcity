if not SERVER then return end

MissionIntro = MissionIntro or {}

util.AddNetworkString("MissionIntro_FSP_Open")
util.AddNetworkString("MissionIntro_FSP_Action")

local function MI_Dir()
	return "rx_mission_intro/facility_status_panel"
end

function MissionIntro.GetFacilityStatusPanels()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_facility_status_panel")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end
	return list
end

function MissionIntro.GetFacilityStatusPanelSavePath()
	return MI_Dir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureFacilityStatusPanelSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_Dir(), "DATA") then
		file.CreateDir(MI_Dir())
	end
end

function MissionIntro.CanSaveFacilityStatusPanels()
	if MissionIntro.FacilityStatusPanelPersistEnabled == false then return false end
	if MissionIntro._suppressFacilityStatusPanelSave then return false end
	if MissionIntro._loadingFacilityStatusPanels then return false end
	return true
end

function MissionIntro.ExportFacilityStatusPanels()
	local data = {}
	for _, ent in ipairs(MissionIntro.GetFacilityStatusPanels()) do
		data[#data + 1] = {
			pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
			ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		}
	end
	return data
end

function MissionIntro.ReadFacilityStatusPanelsFromDisk()
	local path = MissionIntro.GetFacilityStatusPanelSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not isstring(raw) or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteFacilityStatusPanelsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureFacilityStatusPanelSaveDir()
	file.Write(MissionIntro.GetFacilityStatusPanelSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveFacilityStatusPanelsToDisk()
	if not MissionIntro.CanSaveFacilityStatusPanels() then return false end

	local data = MissionIntro.ExportFacilityStatusPanels()
	MissionIntro.WriteFacilityStatusPanelsToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_status_panel"), MissionIntro.GetFacilityStatusPanelSavePath())
	return true
end

function MissionIntro.CacheFacilityStatusPanelsBeforeCleanup()
	MissionIntro._suppressFacilityStatusPanelSave = true

	if IsValid(MissionIntro._activeFacilityPA) then
		MissionIntro._activeFacilityPA = nil
	end

	for _, ent in ipairs(MissionIntro.GetFacilityStatusPanels()) do
		if IsValid(ent) and ent.GetPAActive and ent:GetPAActive() then
			ent:SetPAActive(false)
			ent:SetOperator(NULL)
		end
	end

	local live = MissionIntro.ExportFacilityStatusPanels()
	local rows = (#live > 0) and live or MissionIntro.ReadFacilityStatusPanelsFromDisk()
	MissionIntro._facilityStatusPanelPersistCache = rows

	MissionIntro.WriteFacilityStatusPanelsToDisk(rows)
	MissionIntro.ServerMsg("log_cached", #rows, MissionIntro.L("log_entity_status_panel"))

	MissionIntro._suppressFacilityStatusPanelSave = false
	return rows
end

function MissionIntro.CreateFacilityStatusPanel(pos, ang, silent, mountNormal)
	local ent = ents.Create("ent_mission_intro_facility_status_panel")
	if not IsValid(ent) then
		MissionIntro.ServerMsg("log_create_entity_failed", "ent_mission_intro_facility_status_panel")
		return nil
	end

	local cfg = MissionIntro.FacilityStatusPanel or {}
	ent:SetModel(cfg.model or "models/props/cs_office/tv_plasma.mdl")

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang, 2)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	if not IsValid(ent) then return nil end

	if not silent and MissionIntro.SaveFacilityStatusPanelsToDisk then
		MissionIntro.SaveFacilityStatusPanelsToDisk()
	end

	return ent
end

function MissionIntro.LoadFacilityStatusPanelsFromDisk(rows)
	if MissionIntro._loadingFacilityStatusPanels then return end
	MissionIntro._loadingFacilityStatusPanels = true
	MissionIntro._suppressFacilityStatusPanelSave = true

	rows = rows or MissionIntro.ReadFacilityStatusPanelsFromDisk()

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_facility_status_panel")) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		if MissionIntro.CreateFacilityStatusPanel then
			MissionIntro.CreateFacilityStatusPanel(pos, ang, true)
		end
	end

	MissionIntro._loadingFacilityStatusPanels = false
	MissionIntro._suppressFacilityStatusPanelSave = false
	MissionIntro.ServerMsg("log_loaded", #rows, MissionIntro.L("log_entity_status_panel"), MissionIntro.GetFacilityStatusPanelSavePath())
end

function MissionIntro.RemoveAllFacilityStatusPanels(save)
	MissionIntro._suppressFacilityStatusPanelSave = true

	if IsValid(MissionIntro._activeFacilityPA) then
		MissionIntro._activeFacilityPA = nil
	end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_facility_status_panel")) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressFacilityStatusPanelSave = false

	if save ~= false and MissionIntro.SaveFacilityStatusPanelsToDisk then
		MissionIntro.SaveFacilityStatusPanelsToDisk()
	end
end

function MissionIntro.RequestSaveFacilityStatusPanels()
	if not MissionIntro.CanSaveFacilityStatusPanels then return end
	timer.Simple(0, function()
		if MissionIntro.SaveFacilityStatusPanelsToDisk then
			MissionIntro.SaveFacilityStatusPanelsToDisk()
		end
	end)
end

local function MI_ScheduleReloadFacilityStatusPanels()
	timer.Create("MissionIntro_ReloadFacilityStatusPanels", 0.5, 1, function()
		local rows = MissionIntro._facilityStatusPanelPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadFacilityStatusPanelsFromDisk()
		end
		MissionIntro._facilityStatusPanelPersistCache = nil
		if MissionIntro.LoadFacilityStatusPanelsFromDisk then
			MissionIntro.LoadFacilityStatusPanelsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadFacilityStatusPanels", MI_ScheduleReloadFacilityStatusPanels)
hook.Add("PostCleanupMap", "MissionIntro_ReloadFacilityStatusPanels", MI_ScheduleReloadFacilityStatusPanels)
hook.Add("PostCleanup", "MissionIntro_ReloadFacilityStatusPanels", MI_ScheduleReloadFacilityStatusPanels)

hook.Add("PreCleanupMap", "MissionIntro_CacheFacilityStatusPanels", function()
	if MissionIntro.CacheFacilityStatusPanelsBeforeCleanup then
		MissionIntro.CacheFacilityStatusPanelsBeforeCleanup()
	end
end)

hook.Add("ShutDown", "MissionIntro_SaveFacilityStatusPanels", function()
	MissionIntro._suppressFacilityStatusPanelSave = false
	if MissionIntro.SaveFacilityStatusPanelsToDisk then
		MissionIntro.SaveFacilityStatusPanelsToDisk()
	end
end)

net.Receive("MissionIntro_FSP_Action", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

	local ent = net.ReadEntity()
	local action = net.ReadUInt(4)
	if not IsValid(ent) or ent:GetClass() ~= "ent_mission_intro_facility_status_panel" then return end
	if not ent.CanUseDist or not ent:CanUseDist(ply) then return end

	if action == 1 then
		if MissionIntro.FacilityPA_Activate then
			local ok, msg = MissionIntro.FacilityPA_Activate(ent, ply)
			if not ok and isstring(msg) and msg ~= "" then
				ply:ChatPrint(msg)
			end
		end
	elseif action == 2 then
		if not ent:GetPAActive() then return end
		if ent:GetOperator() ~= ply and not ply:IsAdmin() then return end
		if MissionIntro.FacilityPA_Deactivate then
			MissionIntro.FacilityPA_Deactivate(ent)
		end
	elseif action == 3 then
		if MissionIntro.DeployFacilityQrfSquad then
			local ok, msg = MissionIntro.DeployFacilityQrfSquad(ply)
			if not ok and isstring(msg) and msg ~= "" then
				ply:ChatPrint(msg)
			end
		end
	end
end)
