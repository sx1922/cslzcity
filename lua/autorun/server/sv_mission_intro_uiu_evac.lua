if not SERVER then return end

MissionIntro.UiuEvacPersistEnabled = MissionIntro.UiuEvacPersistEnabled ~= false

local function MI_EvacDir()
	return "rx_mission_intro/uiu_evacs"
end

function MissionIntro.GetUiuEvacSavePath()
	return MI_EvacDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureUiuEvacSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_EvacDir(), "DATA") then
		file.CreateDir(MI_EvacDir())
	end
end

function MissionIntro.GetUiuEvacEntities()
	return ents.FindByClass("ent_mission_intro_uiu_evac")
end

function MissionIntro.CanSaveUiuEvacs()
	if not MissionIntro.UiuEvacPersistEnabled then return false end
	if MissionIntro._loadingUiuEvacs then return false end
	if MissionIntro._suppressUiuEvacSave then return false end
	return true
end

function MissionIntro.ExportUiuEvacs()
	local out = {}
	for _, ent in ipairs(MissionIntro.GetUiuEvacEntities()) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		out[#out + 1] = {
			pos = { x = pos.x, y = pos.y, z = pos.z },
			ang = { p = ang.p, y = ang.y, r = ang.r },
			radius = ent.GetZoneRadius and ent:GetZoneRadius() or nil,
		}
	end
	return out
end

function MissionIntro.ReadUiuEvacsFromDisk()
	if not MissionIntro.UiuEvacPersistEnabled then return {} end

	local path = MissionIntro.GetUiuEvacSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteUiuEvacsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureUiuEvacSaveDir()
	file.Write(MissionIntro.GetUiuEvacSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveUiuEvacsToDisk()
	if not MissionIntro.CanSaveUiuEvacs() then return false end

	local data = MissionIntro.ExportUiuEvacs()
	MissionIntro.WriteUiuEvacsToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_uiu_evac"), MissionIntro.GetUiuEvacSavePath())
	return true
end

function MissionIntro.CacheUiuEvacsBeforeCleanup()
	MissionIntro._suppressUiuEvacSave = true

	local live = MissionIntro.ExportUiuEvacs()
	local rows = (#live > 0) and live or MissionIntro.ReadUiuEvacsFromDisk()
	MissionIntro._uiuEvacPersistCache = rows

	if MissionIntro.UiuEvacPersistEnabled then
		MissionIntro.WriteUiuEvacsToDisk(rows)
	end

	MissionIntro.ServerMsg("log_cached", #rows, MissionIntro.L("log_entity_uiu_evac"))
	return rows
end

function MissionIntro.ClampUiuEvacRadius(radius)
	local cfg = MissionIntro.UiuEvac or {}
	local minR = tonumber(cfg.min_zone_radius) or 64
	local maxR = tonumber(cfg.max_zone_radius) or 400
	return math.Clamp(tonumber(radius) or tonumber(cfg.default_zone_radius) or 130, minR, maxR)
end

function MissionIntro.CreateUiuEvac(pos, ang, silent, zoneRadius)
	local ent = ents.Create("ent_mission_intro_uiu_evac")
	if not IsValid(ent) then return nil end

	if MissionIntro.AlignEntityOnTracedSurface then
		MissionIntro.AlignEntityOnTracedSurface(ent, pos, ang)
	else
		ent:SetPos(pos)
		ent:SetAngles(ang or angle_zero)
		ent:Spawn()
		ent:Activate()
	end

	if ent.SetEvacZoneRadius then
		ent:SetEvacZoneRadius(MissionIntro.ClampUiuEvacRadius(zoneRadius))
	end

	if not silent and MissionIntro.SaveUiuEvacsToDisk then
		MissionIntro.SaveUiuEvacsToDisk()
	end

	return ent
end

function MissionIntro.LoadUiuEvacsFromDisk(rows)
	if MissionIntro._loadingUiuEvacs then return end
	MissionIntro._loadingUiuEvacs = true

	rows = rows or MissionIntro.ReadUiuEvacsFromDisk()

	for _, ent in ipairs(MissionIntro.GetUiuEvacEntities()) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		local radius = tonumber(row.radius)
		MissionIntro.CreateUiuEvac(pos, ang, true, radius)
	end

	MissionIntro._loadingUiuEvacs = false
	MissionIntro.ServerMsg("log_loaded", #rows, MissionIntro.L("log_entity_uiu_evac"), MissionIntro.GetUiuEvacSavePath())
end

function MissionIntro.RemoveAllUiuEvacs(save)
	MissionIntro._suppressUiuEvacSave = true

	for _, ent in ipairs(MissionIntro.GetUiuEvacEntities()) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressUiuEvacSave = false

	if save ~= false and MissionIntro.SaveUiuEvacsToDisk then
		MissionIntro.SaveUiuEvacsToDisk()
	end
end

function MissionIntro.RequestSaveUiuEvacs()
	if not MissionIntro.CanSaveUiuEvacs() then return end
	timer.Simple(0, function()
		MissionIntro.SaveUiuEvacsToDisk()
	end)
end

function MissionIntro.ExecuteUiuEvacuation(ply, evacEnt)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply._missionIntroEvacuated = true
	ply._missionIntroUiuEvacEligible = false

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

	if MissionIntro.ClearPlayerMissionIntroState then
		MissionIntro.ClearPlayerMissionIntroState(ply)
	end

	if MissionIntro.KillPlayerAfterEvacuation then
		MissionIntro.KillPlayerAfterEvacuation(ply)
	elseif ply:Alive() then
		ply:KillSilent()
	end

	ply:ChatPrint("[UIU] ????????????")
	MsgN("[MissionIntro] UIU ??: " .. ply:Nick())
end

local function MI_ScheduleReloadUiuEvacs()
	timer.Create("MissionIntro_ReloadUiuEvacs", 0.5, 1, function()
		local rows = MissionIntro._uiuEvacPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadUiuEvacsFromDisk()
		end
		MissionIntro._uiuEvacPersistCache = nil
		if MissionIntro.LoadUiuEvacsFromDisk then
			MissionIntro.LoadUiuEvacsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadUiuEvacs", MI_ScheduleReloadUiuEvacs)

hook.Add("PreCleanupMap", "MissionIntro_KeepUiuEvacs", function()
	if MissionIntro.CacheUiuEvacsBeforeCleanup then
		MissionIntro.CacheUiuEvacsBeforeCleanup()
	end
end)

hook.Add("PostCleanupMap", "MissionIntro_ReloadUiuEvacs", MI_ScheduleReloadUiuEvacs)
hook.Add("PostCleanup", "MissionIntro_ReloadUiuEvacs", MI_ScheduleReloadUiuEvacs)

hook.Add("ShutDown", "MissionIntro_SaveUiuEvacs", function()
	MissionIntro._suppressUiuEvacSave = false
	if MissionIntro.SaveUiuEvacsToDisk then
		MissionIntro.SaveUiuEvacsToDisk()
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_UiuEvacCancel", function(ply)
	for _, ent in ipairs(MissionIntro.GetUiuEvacEntities()) do
		if IsValid(ent) and ent:GetEvacuatingPlayer() == ply then
			ent:CancelEvac()
		end
	end
end)

hook.Add("PlayerDeath", "MissionIntro_UiuEvacCancel", function(ply)
	for _, ent in ipairs(MissionIntro.GetUiuEvacEntities()) do
		if IsValid(ent) and ent:GetEvacuatingPlayer() == ply then
			ent:CancelEvac()
		end
	end

	if IsValid(ply) and ply:IsPlayer() and not ply._missionIntroEvacuated then
		ply._missionIntroUiuEvacEligible = false
		if MissionIntro.SyncUiuComputerProgress then
			MissionIntro.SyncUiuComputerProgress(ply)
		end
	end
end)

for _, hookName in ipairs({ "RoundStart", "Breach_NewRound", "OnNewRound", "HMCD_NewRound", "HomigradRoundStart" }) do
	hook.Add(hookName, "MissionIntro_ResetEvacuated", function()
		for _, ply in ipairs(player.GetAll()) do
			ply._missionIntroEvacuated = nil
			ply._missionIntroUiuEvacEligible = nil
		end
	end)
end

hook.Add("PlayerSpawn", "MissionIntro_UiuEvacResync", function(ply)
	if not MissionIntro._uiuMissionActive or not MissionIntro.SyncUiuComputerProgress then return end
	timer.Simple(0, function()
		if IsValid(ply) then
			MissionIntro.SyncUiuComputerProgress(ply)
		end
	end)
end)
