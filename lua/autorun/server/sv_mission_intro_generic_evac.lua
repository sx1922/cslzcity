if not SERVER then return end

MissionIntro.GenericEvacPersistEnabled = MissionIntro.GenericEvacPersistEnabled ~= false

local function MI_EvacDir()
	return "rx_mission_intro/generic_evacs"
end

function MissionIntro.GetGenericEvacSavePath()
	return MI_EvacDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureGenericEvacSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_EvacDir(), "DATA") then
		file.CreateDir(MI_EvacDir())
	end
end

function MissionIntro.GetGenericEvacEntities()
	return ents.FindByClass("ent_mission_intro_generic_evac")
end

function MissionIntro.CanSaveGenericEvacs()
	if not MissionIntro.GenericEvacPersistEnabled then return false end
	if MissionIntro._loadingGenericEvacs then return false end
	if MissionIntro._suppressGenericEvacSave then return false end
	return true
end

function MissionIntro.ExportGenericEvacs()
	local out = {}
	for _, ent in ipairs(MissionIntro.GetGenericEvacEntities()) do
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

function MissionIntro.ReadGenericEvacsFromDisk()
	if not MissionIntro.GenericEvacPersistEnabled then return {} end

	local path = MissionIntro.GetGenericEvacSavePath()
	if not file.Exists(path, "DATA") then return {} end

	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end

	return data
end

function MissionIntro.WriteGenericEvacsToDisk(rows)
	rows = rows or {}
	MissionIntro.EnsureGenericEvacSaveDir()
	file.Write(MissionIntro.GetGenericEvacSavePath(), util.TableToJSON(rows, true))
	return true
end

function MissionIntro.SaveGenericEvacsToDisk()
	if not MissionIntro.CanSaveGenericEvacs() then return false end

	local data = MissionIntro.ExportGenericEvacs()
	MissionIntro.WriteGenericEvacsToDisk(data)
	MsgN("[MissionIntro] 已保存 " .. #data .. " 个通用撤离点")
	return true
end

function MissionIntro.CacheGenericEvacsBeforeCleanup()
	MissionIntro._suppressGenericEvacSave = true

	local live = MissionIntro.ExportGenericEvacs()
	local rows = (#live > 0) and live or MissionIntro.ReadGenericEvacsFromDisk()
	MissionIntro._genericEvacPersistCache = rows

	if MissionIntro.GenericEvacPersistEnabled then
		MissionIntro.WriteGenericEvacsToDisk(rows)
	end

	MsgN("[MissionIntro] 清图前已缓存 " .. #rows .. " 个通用撤离点")
	return rows
end

function MissionIntro.ClampGenericEvacRadius(radius)
	local cfg = MissionIntro.GenericEvac or {}
	local minR = tonumber(cfg.min_zone_radius) or 64
	local maxR = tonumber(cfg.max_zone_radius) or 400
	return math.Clamp(tonumber(radius) or tonumber(cfg.default_zone_radius) or 130, minR, maxR)
end

function MissionIntro.CreateGenericEvac(pos, ang, silent, zoneRadius)
	local ent = ents.Create("ent_mission_intro_generic_evac")
	if not IsValid(ent) then return nil end

	ent:SetPos(pos)
	ent:SetAngles(ang or angle_zero)
	ent:Spawn()
	ent:Activate()

	if ent.SetEvacZoneRadius then
		ent:SetEvacZoneRadius(MissionIntro.ClampGenericEvacRadius(zoneRadius))
	end

	if not silent and MissionIntro.SaveGenericEvacsToDisk then
		MissionIntro.SaveGenericEvacsToDisk()
	end

	return ent
end
function MissionIntro.LoadGenericEvacsFromDisk(rows)
	if MissionIntro._loadingGenericEvacs then return end
	MissionIntro._loadingGenericEvacs = true

	rows = rows or MissionIntro.ReadGenericEvacsFromDisk()

	for _, ent in ipairs(MissionIntro.GetGenericEvacEntities()) do
		if IsValid(ent) then ent:Remove() end
	end

	for _, row in ipairs(rows) do
		if not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		MissionIntro.CreateGenericEvac(pos, ang, true, tonumber(row.radius))
	end

	MissionIntro._loadingGenericEvacs = false
	MsgN("[MissionIntro] 已加载 " .. #rows .. " 个通用撤离点")
end

function MissionIntro.RemoveAllGenericEvacs(save)
	MissionIntro._suppressGenericEvacSave = true

	for _, ent in ipairs(MissionIntro.GetGenericEvacEntities()) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressGenericEvacSave = false

	if save ~= false and MissionIntro.SaveGenericEvacsToDisk then
		MissionIntro.SaveGenericEvacsToDisk()
	end
end

function MissionIntro.RequestSaveGenericEvacs()
	if not MissionIntro.CanSaveGenericEvacs() then return end
	timer.Simple(0, function()
		MissionIntro.SaveGenericEvacsToDisk()
	end)
end

-- Homigrad / 入场 Freeze / 假死 ragdoll：通用与 UIU 撤离须与 RXsend 撤离同样收尾，否则 UIU(FBI) 会倒计时结束后卡死
function MissionIntro.FinalizePlayerEvacuation(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply:Freeze(false)
	ply._miIntroSpawnPending = nil

	if MissionIntro.ActiveSessions and MissionIntro.ActiveSessions[ply] then
		local sess = MissionIntro.ActiveSessions[ply]
		if sess and IsValid(sess.ent) then
			sess.ent._playingPly = nil
			if sess.ent.SetBusy then
				sess.ent:SetBusy(false)
			end
		end
		MissionIntro.ActiveSessions[ply] = nil
	end
	ply:SetNWBool("MissionIntro_IntroPlaying", false)

	if hg and hg.weaponInv and istable(ply.weaponInv) and isfunction(hg.weaponInv.Sync) then
		pcall(function()
			hg.weaponInv.Sync(ply)
		end)
	end

	if hg and hg.FakeUp then
		pcall(function()
			hg.FakeUp(ply, true, true)
		end)
	end

	if IsValid(ply.FakeRagdoll) then
		ply.FakeRagdoll:Remove()
	end
	ply.FakeRagdoll = nil
	ply.FakeRagdollOld = nil
	ply.OldRagdoll = nil
	if hg and hg.ragdollFake then
		hg.ragdollFake[ply] = nil
	end
	ply:SetNWEntity("FakeRagdoll", NULL)
	ply:SetNWEntity("FakeRagdollOld", NULL)

	if istable(ply.organism) then
		ply.organism.alive = false
	end
end

function MissionIntro.KillPlayerAfterEvacuation(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	MissionIntro.FinalizePlayerEvacuation(ply)

	if ply:Alive() then
		ply:KillSilent()
	end

	-- Homigrad 偶发拦 KillSilent：确保已撤离玩家脱离战斗
	if ply:Alive() then
		ply:SetMoveType(MOVETYPE_NOCLIP)
		ply:SetNotSolid(true)
		ply:GodEnable()
		if ply.Spectate then
			ply:Spectate(OBS_MODE_ROAMING)
		end
	end
end

function MissionIntro.ExecuteGenericEvacuation(ply, evacEnt)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if ply._missionIntroEvacuated then return end

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

	MissionIntro.KillPlayerAfterEvacuation(ply)

	ply._missionIntroEvacuated = true

	local msg = MissionIntro.L and MissionIntro.L("generic_evac_done") or "[RX] 撤离成功，你已离开设施。"
	ply:ChatPrint(msg)
	MsgN("[MissionIntro] 通用撤离: " .. ply:Nick())
end

local function MI_ScheduleReloadGenericEvacs()
	timer.Create("MissionIntro_ReloadGenericEvacs", 0.5, 1, function()
		local rows = MissionIntro._genericEvacPersistCache
		if not istable(rows) or #rows == 0 then
			rows = MissionIntro.ReadGenericEvacsFromDisk()
		end
		MissionIntro._genericEvacPersistCache = nil
		if MissionIntro.LoadGenericEvacsFromDisk then
			MissionIntro.LoadGenericEvacsFromDisk(rows)
		end
	end)
end

hook.Add("InitPostEntity", "MissionIntro_LoadGenericEvacs", MI_ScheduleReloadGenericEvacs)

hook.Add("PreCleanupMap", "MissionIntro_KeepGenericEvacs", function()
	if MissionIntro.CacheGenericEvacsBeforeCleanup then
		MissionIntro.CacheGenericEvacsBeforeCleanup()
	end
end)

hook.Add("PostCleanupMap", "MissionIntro_ReloadGenericEvacs", MI_ScheduleReloadGenericEvacs)
hook.Add("PostCleanup", "MissionIntro_ReloadGenericEvacs", MI_ScheduleReloadGenericEvacs)

hook.Add("ShutDown", "MissionIntro_SaveGenericEvacs", function()
	MissionIntro._suppressGenericEvacSave = false
	if MissionIntro.SaveGenericEvacsToDisk then
		MissionIntro.SaveGenericEvacsToDisk()
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_GenericEvacCancel", function(ply)
	for _, ent in ipairs(MissionIntro.GetGenericEvacEntities()) do
		if IsValid(ent) and ent:GetEvacuatingPlayer() == ply then
			ent:CancelEvac()
		end
	end
end)

hook.Add("PlayerDeath", "MissionIntro_GenericEvacCancel", function(ply)
	for _, ent in ipairs(MissionIntro.GetGenericEvacEntities()) do
		if IsValid(ent) and ent:GetEvacuatingPlayer() == ply then
			ent:CancelEvac()
		end
	end
end)
