if not SERVER then return end

MissionIntro = MissionIntro or {}

util.AddNetworkString("MissionIntro_FSP_Chat")

local function PA_Cfg()
	return MissionIntro.FacilityStatusPanel or MissionIntro.FacilityPA or {}
end

local function MI_PADir()
	return "rx_mission_intro/facility_pa"
end

function MissionIntro.GetFacilityPAs()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_facility_status_panel")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end
	return list
end

function MissionIntro.GetFacilityPASavePath()
	return MI_PADir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureFacilityPASaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_PADir(), "DATA") then
		file.CreateDir(MI_PADir())
	end
end

function MissionIntro.CanSaveFacilityPAs()
	if MissionIntro.FacilityPAPersistEnabled == false then return false end
	if MissionIntro._suppressFacilityPASave then return false end
	if MissionIntro._loadingFacilityPAs then return false end
	return true
end

function MissionIntro.ExportFacilityPAs()
	local data = {}
	for _, ent in ipairs(MissionIntro.GetFacilityPAs()) do
		data[#data + 1] = {
			pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
			ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		}
	end
	return data
end

function MissionIntro.ReadFacilityPAsFromDisk()
	local path = MissionIntro.GetFacilityPASavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not isstring(raw) or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteFacilityPAsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureFacilityPASaveDir()
	file.Write(MissionIntro.GetFacilityPASavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveFacilityPAsToDisk()
	if not MissionIntro.CanSaveFacilityPAs() then return false end

	local data = MissionIntro.ExportFacilityPAs()
	MissionIntro.WriteFacilityPAsToDisk(data)
	MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_facility_pa"), MissionIntro.GetFacilityPASavePath())
	return true
end

function MissionIntro.CacheFacilityPAsBeforeCleanup()
	MissionIntro._suppressFacilityPASave = true

	local pa = MissionIntro.GetActiveFacilityPA and MissionIntro.GetActiveFacilityPA()
	if IsValid(pa) then
		pa:SetPAActive(false)
		pa:SetOperator(NULL)
		MissionIntro._activeFacilityPA = nil
	end

	local live = MissionIntro.ExportFacilityPAs()
	local rows = (#live > 0) and live or MissionIntro.ReadFacilityPAsFromDisk()
	MissionIntro._facilityPAPersistCache = rows

	MissionIntro.WriteFacilityPAsToDisk(rows)
	MissionIntro.ServerMsg("log_cached", #rows, MissionIntro.L("log_entity_facility_pa"))

	MissionIntro._suppressFacilityPASave = false
	return rows
end

function MissionIntro.RemoveLegacyFacilityPAEntities()
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_facility_pa")) do
		if IsValid(ent) then ent:Remove() end
	end
end

function MissionIntro.LoadFacilityPAsFromDisk(rows)
	if MissionIntro._loadingFacilityPAs then return end
	MissionIntro._loadingFacilityPAs = true
	MissionIntro._suppressFacilityPASave = true

	rows = rows or MissionIntro.ReadFacilityPAsFromDisk()

	MissionIntro.RemoveLegacyFacilityPAEntities()

	-- ???????????????????????????
	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end

		local tooClose = false
		for _, existing in ipairs(ents.FindByClass("ent_mission_intro_facility_status_panel")) do
			if IsValid(existing) and existing:GetPos():DistToSqr(pos) < 64 * 64 then
				tooClose = true
				break
			end
		end

		if not tooClose and MissionIntro.CreateFacilityStatusPanel then
			MissionIntro.CreateFacilityStatusPanel(pos, ang, true)
		end
	end

	MissionIntro._loadingFacilityPAs = false
	MissionIntro._suppressFacilityPASave = false
	if #rows > 0 then
		MissionIntro.ServerMsg("log_loaded_migrated", #rows, MissionIntro.L("log_entity_facility_pa"))
	end
end

function MissionIntro.RemoveAllFacilityPAs(save)
	MissionIntro._suppressFacilityPASave = true

	if IsValid(MissionIntro._activeFacilityPA) then
		MissionIntro._activeFacilityPA = nil
	end

	if MissionIntro.RemoveLegacyFacilityPAEntities then
		MissionIntro.RemoveLegacyFacilityPAEntities()
	end

	MissionIntro._suppressFacilityPASave = false

	if save ~= false and MissionIntro.SaveFacilityPAsToDisk then
		MissionIntro.SaveFacilityPAsToDisk()
	end
end

function MissionIntro.RequestSaveFacilityPAs()
	if not MissionIntro.CanSaveFacilityPAs then return end
	timer.Simple(0, function()
		if MissionIntro.SaveFacilityPAsToDisk then
			MissionIntro.SaveFacilityPAsToDisk()
		end
	end)
end

function MissionIntro.GetActiveFacilityPA()
	local ent = MissionIntro._activeFacilityPA
	if IsValid(ent) and ent:GetPAActive() then
		return ent
	end
	return nil
end

function MissionIntro.IsPlayerNearFacilityPA(ply, ent, radius)
	if not IsValid(ply) or not IsValid(ent) then return false end
	radius = tonumber(radius) or 158
	return ply:GetPos():DistToSqr(ent:GetPos()) <= radius * radius
end

function MissionIntro.FacilityPA_GetMicSpeakers(ent)
	local speakers = {}
	if not IsValid(ent) or not ent:GetPAActive() then return speakers end

	local op = ent:GetOperator()
	if IsValid(op) and op:Alive() then
		speakers[op] = true
	end

	local radius = tonumber(PA_Cfg().mic_radius) or 158
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and ply:Alive() and not speakers[ply] then
			if MissionIntro.IsPlayerNearFacilityPA(ply, ent, radius) then
				speakers[ply] = true
			end
		end
	end
	return speakers
end

function MissionIntro.FacilityPA_TimerId(ent)
	if not IsValid(ent) then return "" end
	return "MissionIntro_FSP_PA_" .. ent:EntIndex()
end

function MissionIntro.FacilityPA_ClearTimer(ent)
	if not IsValid(ent) then return end
	timer.Remove(MissionIntro.FacilityPA_TimerId(ent))
end

function MissionIntro.FacilityPA_BroadcastText(speaker, text)
	if not IsValid(speaker) then return end

	text = string.Trim(tostring(text or ""))
	if text == "" then return end
	if string.sub(text, 1, 1) == "!" or string.sub(text, 1, 1) == "/" then return end

	net.Start("MissionIntro_FSP_Chat")
		net.WriteEntity(speaker)
		net.WriteString(text)
	net.Broadcast()
end

function MissionIntro.FacilityPA_Deactivate(ent, reason)
	if not IsValid(ent) then return end
	if not ent:GetPAActive() then return end

	local op = ent:GetOperator()
	local cfg = PA_Cfg()

	ent:SetPAActive(false)
	ent:SetOperator(NULL)
	ent:SetPAEndAt(0)
	ent:SetPACooldownUntil(CurTime() + (tonumber(cfg.pa_cooldown) or 30))
	MissionIntro._activeFacilityPA = nil
	MissionIntro.FacilityPA_ClearTimer(ent)

	local snd = cfg.pa_stop_sound or cfg.stop_sound or "mission_intro/facility_pa_stop.mp3"
	if MissionIntro.BroadcastSoundToAll then
		MissionIntro.BroadcastSoundToAll(snd, { forceSoundDuringIntro = true })
	end

	if reason == "timeout" and IsValid(op) then
		local maxDur = tonumber(cfg.pa_max_duration) or 20
		op:ChatPrint("[????] ???????? " .. tostring(maxDur) .. " ??")
	end
end

function MissionIntro.FacilityPA_Activate(ent, ply)
	if not IsValid(ent) or not IsValid(ply) then return false, "????" end

	local cfg = PA_Cfg()
	local cdUntil = ent.GetPACooldownUntil and ent:GetPACooldownUntil() or 0
	if CurTime() < cdUntil then
		return false, string.format("[????] ??? %.0f ?", math.max(0, cdUntil - CurTime()))
	end

	local old = MissionIntro.GetActiveFacilityPA()
	if IsValid(old) and old ~= ent then
		MissionIntro.FacilityPA_Deactivate(old)
	end

	local maxDur = math.max(1, tonumber(cfg.pa_max_duration) or 20)
	ent:SetPAActive(true)
	ent:SetOperator(ply)
	ent:SetPAEndAt(CurTime() + maxDur)
	MissionIntro._activeFacilityPA = ent

	MissionIntro.FacilityPA_ClearTimer(ent)
	timer.Create(MissionIntro.FacilityPA_TimerId(ent), maxDur, 1, function()
		if IsValid(ent) and ent:GetPAActive() then
			MissionIntro.FacilityPA_Deactivate(ent, "timeout")
		end
	end)

	local snd = cfg.pa_start_sound or cfg.start_sound or "mission_intro/facility_pa_start.mp3"
	if MissionIntro.BroadcastSoundToAll then
		MissionIntro.BroadcastSoundToAll(snd, { forceSoundDuringIntro = true })
	end

	ply:ChatPrint("[????] ???????? " .. tostring(maxDur) .. " ?????????????")
	return true
end

hook.Add("HG_PlayerCanHearPlayersVoice", "MissionIntro_FacilityPA", function(listener, speaker)
	local pa = MissionIntro.GetActiveFacilityPA()
	if not IsValid(pa) then return end
	if not IsValid(listener) or not IsValid(speaker) then return end
	if listener == speaker then return false end

	local speakers = MissionIntro.FacilityPA_GetMicSpeakers(pa)
	if not speakers[speaker] then return end

	return true, false
end)

hook.Add("PlayerDisconnected", "MissionIntro_FacilityPA", function(ply)
	local pa = MissionIntro.GetActiveFacilityPA()
	if not IsValid(pa) then return end
	if pa:GetOperator() == ply then
		MissionIntro.FacilityPA_Deactivate(pa)
	end
end)

hook.Add("PlayerSay", "MissionIntro_FacilityPA_Text", function(ply, text, teamChat)
	if teamChat then return end

	local pa = MissionIntro.GetActiveFacilityPA()
	if not IsValid(pa) then return end

	local speakers = MissionIntro.FacilityPA_GetMicSpeakers(pa)
	if not speakers[ply] then return end

	text = string.Trim(tostring(text or ""))
	if text == "" then return end
	if string.sub(text, 1, 1) == "!" or string.sub(text, 1, 1) == "/" then return end

	if MissionIntro.FacilityPA_BroadcastText then
		MissionIntro.FacilityPA_BroadcastText(ply, text)
	end

	return ""
end)

hook.Add("InitPostEntity", "MissionIntro_RemoveLegacyFacilityPA", function()
	if MissionIntro.RemoveLegacyFacilityPAEntities then
		MissionIntro.RemoveLegacyFacilityPAEntities()
	end
end)

local function MI_ScheduleReloadFacilityPAs()
	timer.Create("MissionIntro_ReloadFacilityPAs", 0.5, 1, function()
		if MissionIntro.RemoveLegacyFacilityPAEntities then
			MissionIntro.RemoveLegacyFacilityPAEntities()
		end
		local rows = MissionIntro._facilityPAPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadFacilityPAsFromDisk()
		end
		MissionIntro._facilityPAPersistCache = nil
		if MissionIntro.LoadFacilityPAsFromDisk then
			MissionIntro.LoadFacilityPAsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadFacilityPAs", MI_ScheduleReloadFacilityPAs)
hook.Add("PostCleanupMap", "MissionIntro_ReloadFacilityPAs", MI_ScheduleReloadFacilityPAs)
hook.Add("PostCleanup", "MissionIntro_ReloadFacilityPAs", MI_ScheduleReloadFacilityPAs)

hook.Add("PreCleanupMap", "MissionIntro_CacheFacilityPAs", function()
	if MissionIntro.CacheFacilityPAsBeforeCleanup then
		MissionIntro.CacheFacilityPAsBeforeCleanup()
	end
end)

hook.Add("ShutDown", "MissionIntro_SaveFacilityPAs", function()
	MissionIntro._suppressFacilityPASave = false
	if MissionIntro.SaveFacilityPAsToDisk then
		MissionIntro.SaveFacilityPAsToDisk()
	end
end)
