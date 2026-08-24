if not SERVER then return end

MissionIntro.RXSendEvacPersistEnabled = MissionIntro.RXSendEvacPersistEnabled ~= false

local function MI_EvacDir()
	return "rx_mission_intro/rxsend_evacs"
end

function MissionIntro.GetRXSendEvacSavePath()
	return MI_EvacDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureRXSendEvacSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_EvacDir(), "DATA") then
		file.CreateDir(MI_EvacDir())
	end
end

function MissionIntro.GetRXSendEvacEntities()
	return ents.FindByClass("ent_mission_intro_rxsend_evac")
end

function MissionIntro.CanSaveRXSendEvacs()
	if not MissionIntro.RXSendEvacPersistEnabled then return false end
	if MissionIntro._loadingRXSendEvacs then return false end
	if MissionIntro._suppressRXSendEvacSave then return false end
	return true
end

function MissionIntro.ExportRXSendEvacs()
	local out = {}
	for _, ent in ipairs(MissionIntro.GetRXSendEvacEntities()) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		out[#out + 1] = {
			pos = { x = pos.x, y = pos.y, z = pos.z },
			ang = { p = ang.p, y = ang.y, r = ang.r },
			radius = ent.GetZoneRadius and ent:GetZoneRadius() or nil,
			battle_team = ent.GetBattleTeam and ent:GetBattleTeam() or 1,
		}
	end
	return out
end

function MissionIntro.ReadRXSendEvacsFromDisk()
	if not MissionIntro.RXSendEvacPersistEnabled then return {} end

	local path = MissionIntro.GetRXSendEvacSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteRXSendEvacsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureRXSendEvacSaveDir()
	file.Write(MissionIntro.GetRXSendEvacSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveRXSendEvacsToDisk()
	if not MissionIntro.CanSaveRXSendEvacs() then return false end

	local data = MissionIntro.ExportRXSendEvacs()
	MissionIntro.WriteRXSendEvacsToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_rxsend_evac"), MissionIntro.GetRXSendEvacSavePath())
	return true
end

function MissionIntro.CacheRXSendEvacsBeforeCleanup()
	MissionIntro._suppressRXSendEvacSave = true

	local live = MissionIntro.ExportRXSendEvacs()
	local rows = (#live > 0) and live or MissionIntro.ReadRXSendEvacsFromDisk()
	MissionIntro._rxSendEvacPersistCache = rows

	if MissionIntro.RXSendEvacPersistEnabled then
		MissionIntro.WriteRXSendEvacsToDisk(rows)
	end

	return rows
end

function MissionIntro.CreateRXSendEvac(pos, ang, battleTeam, silent, zoneRadius)
	local ent = ents.Create("ent_mission_intro_rxsend_evac")
	if not IsValid(ent) then return nil end

	ent:SetPos(pos)
	ent:SetAngles(ang or angle_zero)
	ent:Spawn()
	ent:Activate()

	ent:SetBattleTeam(tonumber(battleTeam) == 0 and 0 or 1)
	if ent.SetEvacZoneRadius then
		ent:SetEvacZoneRadius(MissionIntro.ClampRXSendEvacRadius(zoneRadius))
	end

	if not silent and MissionIntro.SaveRXSendEvacsToDisk then
		MissionIntro.SaveRXSendEvacsToDisk()
	end

	return ent
end

function MissionIntro.LoadRXSendEvacsFromDisk(rows)
	if MissionIntro._loadingRXSendEvacs then return end
	MissionIntro._loadingRXSendEvacs = true

	rows = rows or MissionIntro.ReadRXSendEvacsFromDisk()

	for _, ent in ipairs(MissionIntro.GetRXSendEvacEntities()) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		MissionIntro.CreateRXSendEvac(pos, ang, tonumber(row.battle_team) or 1, true, tonumber(row.radius))
	end

	MissionIntro._loadingRXSendEvacs = false
	MissionIntro.ServerMsg("log_loaded", #rows, MissionIntro.L("log_entity_rxsend_evac"), MissionIntro.GetRXSendEvacSavePath())
end

function MissionIntro.RemoveAllRXSendEvacs(battleTeam, save)
	MissionIntro._suppressRXSendEvacSave = true

	for _, ent in ipairs(MissionIntro.GetRXSendEvacEntities()) do
		if not IsValid(ent) then continue end
		if battleTeam == nil or ent:GetBattleTeam() == battleTeam then
			ent:Remove()
		end
	end

	MissionIntro._suppressRXSendEvacSave = false

	if save ~= false and MissionIntro.SaveRXSendEvacsToDisk then
		MissionIntro.SaveRXSendEvacsToDisk()
	end
end

function MissionIntro.RequestSaveRXSendEvacs()
	if not MissionIntro.CanSaveRXSendEvacs() then return end
	timer.Simple(0, function()
		MissionIntro.SaveRXSendEvacsToDisk()
	end)
end

function MissionIntro.ExecuteRXSendEvacuation(ply, evacEnt)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply._missionIntroEvacuated = true

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
	else
		if hg and hg.FakeUp then
			pcall(function() hg.FakeUp(ply, true, true) end)
		end
		if IsValid(ply.FakeRagdoll) then
			ply.FakeRagdoll:Remove()
			ply.FakeRagdoll = nil
		end
		if ply.organism then
			ply.organism.alive = false
		end
		if ply:Alive() then
			ply:KillSilent()
		end
	end

	local msg = MissionIntro.L and MissionIntro.L("rxsend_evac_done") or "[RX] ????????????"
	ply:ChatPrint(msg)
	MsgN("[MissionIntro] RXsend ??: " .. ply:Nick())
end

local function MI_ScheduleReloadRXSendEvacs()
	timer.Create("MissionIntro_ReloadRXSendEvacs", 0.5, 1, function()
		local rows = MissionIntro._rxSendEvacPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadRXSendEvacsFromDisk()
		end
		MissionIntro._rxSendEvacPersistCache = nil
		if MissionIntro.LoadRXSendEvacsFromDisk then
			MissionIntro.LoadRXSendEvacsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadRXSendEvacs", MI_ScheduleReloadRXSendEvacs)

hook.Add("PostCleanupMap", "MissionIntro_ReloadRXSendEvacs", function()
	if MissionIntro.CacheRXSendEvacsBeforeCleanup then
		MissionIntro.CacheRXSendEvacsBeforeCleanup()
	end
	MI_ScheduleReloadRXSendEvacs()
end)

hook.Add("ShutDown", "MissionIntro_SaveRXSendEvacs", function()
	if MissionIntro.SaveRXSendEvacsToDisk then
		MissionIntro.SaveRXSendEvacsToDisk()
	end
end)
