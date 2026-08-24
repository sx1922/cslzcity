MissionIntro = MissionIntro or {}
MissionIntro._spawnRoundRobin = MissionIntro._spawnRoundRobin or {}

function MissionIntro.ResetSpawnRoundRobin()
	MissionIntro._spawnRoundRobin = {}
end

local function MI_MapFacilitySpawnFactionId(facId)
	if not isstring(facId) or facId == "" then return facId end
	if MissionIntro.GetFacilitySpawnFactionId and MissionIntro.IsFacilityFactionId
		and MissionIntro.IsFacilityFactionId(facId) then
		return MissionIntro.GetFacilitySpawnFactionId(facId) or facId
	end
	return facId
end

local function MI_ResolveSpawnFactionId(ply)
	if IsValid(ply) and MissionIntro.RXSendGetPlayerRoleKey and MissionIntro.RXSendGetRoleDef then
		local roleKey = MissionIntro.RXSendGetPlayerRoleKey(ply)
		if isstring(roleKey) and roleKey ~= "" then
			local def = MissionIntro.RXSendGetRoleDef(roleKey)
			if istable(def) and isstring(def.faction_id) and def.faction_id ~= ""
				and (not MissionIntro.PlayerHasExplicitSquadRole or not MissionIntro.PlayerHasExplicitSquadRole(ply)) then
				if not MissionIntro.IsFacilityFactionId or MissionIntro.IsFacilityFactionId(def.faction_id) then
					return MI_MapFacilitySpawnFactionId(def.faction_id)
				end
			end
		end
	end

	local facId = MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) or ""
	if not isstring(facId) or facId == "" then return facId end

	return MI_MapFacilitySpawnFactionId(facId)
end

function MissionIntro.IsPlayerSpectating(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	if isfunction(ply.IsSpectator) and ply:IsSpectator() then
		return true
	end

	if isfunction(ply.GetObserverMode) then
		local mode = ply:GetObserverMode()
		if mode and mode ~= OBS_MODE_NONE then
			return true
		end
	end

	if isfunction(ply.Team) then
		local tm = ply:Team()
		if tm == TEAM_SPECTATOR or tm == 1001 then
			return true
		end
	end

	return false
end

function MissionIntro.LeaveSpectator(ply)
	if not IsValid(ply) then return end

	if hook.Run("MissionIntro_LeaveSpectator", ply) == true then
		return
	end

	if isfunction(ply.UnSpectate) then
		ply:UnSpectate()
	end
	if isfunction(ply.SetObserverMode) then
		ply:SetObserverMode(OBS_MODE_NONE)
	end
end

function MissionIntro.GetSpawnEntities()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_spawn")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end
	table.sort(list, function(a, b)
		return a:EntIndex() < b:EntIndex()
	end)
	return list
end

function MissionIntro.RenumberSpawnPoints()
	local i = 1
	for _, ent in ipairs(MissionIntro.GetSpawnEntities()) do
		ent:SetSpawnIndex(i)
		i = i + 1
	end
end

function MissionIntro.FilterSpawnEntitiesForPlayer(ply)
	local all = MissionIntro.GetSpawnEntities()
	if #all == 0 then return all end

	local facId = MI_ResolveSpawnFactionId(ply)
	if not isstring(facId) or facId == "" then return all end

	local matched = {}
	local neutral = {}

	for _, ent in ipairs(all) do
		local entFac = ""
		if ent.GetSpawnFaction then
			entFac = MissionIntro.NormalizeSpawnFaction(ent:GetSpawnFaction())
		end
		if entFac == "" then
			neutral[#neutral + 1] = ent
		elseif entFac == facId then
			matched[#matched + 1] = ent
		end
	end

	if #matched > 0 then return matched end
	if #neutral > 0 then return neutral end

	return {}
end

function MissionIntro.PickSpawnPoint(ply)
	local fromHook = hook.Run("MissionIntro_PickSpawnPoint", ply)
	if fromHook ~= nil then return fromHook end

	local list = MissionIntro.FilterSpawnEntitiesForPlayer(ply)
	if #list == 0 then return nil end

	local facId = MI_ResolveSpawnFactionId(ply)
	if facId == "" then facId = "_any" end
	MissionIntro._spawnRoundRobin[facId] = (MissionIntro._spawnRoundRobin[facId] or 0) + 1
	local ent = list[(MissionIntro._spawnRoundRobin[facId] - 1) % #list + 1]
	if not IsValid(ent) then return nil end

	return {
		pos = ent:GetPos(),
		ang = ent:GetAngles(),
		ent = ent,
		faction = ent.GetSpawnFaction and ent:GetSpawnFaction() or "",
	}
end

local function MI_SpawnFactionMatchesPlayer(ply, spawnFaction)
	if not IsValid(ply) then return false end
	local wantFac = MI_ResolveSpawnFactionId(ply)
	if wantFac == "" then return true end

	local cachedFac = ""
	if isstring(spawnFaction) and spawnFaction ~= "" and MissionIntro.NormalizeSpawnFaction then
		cachedFac = MissionIntro.NormalizeSpawnFaction(spawnFaction)
	elseif spawnFaction == "" or spawnFaction == nil then
		return false
	end

	return cachedFac == "" or cachedFac == wantFac
end

function MissionIntro.GetMissionSpawnData(ply, cached)
	if istable(cached) and isvector(cached.pos) then
		if MI_SpawnFactionMatchesPlayer(ply, cached.faction) then
			return cached
		end
	end

	if MissionIntro.PickSpawnPoint then
		local picked = MissionIntro.PickSpawnPoint(ply)
		if istable(picked) and isvector(picked.pos) then
			return picked
		end
	end

	local wantFac = MI_ResolveSpawnFactionId(ply)
	if isstring(wantFac) and wantFac ~= "" then
		return nil
	end

	local entsList = MissionIntro.GetSpawnEntities and MissionIntro.GetSpawnEntities() or {}
	for _, ent in ipairs(entsList) do
		if not IsValid(ent) then continue end
		local fac = ""
		if ent.GetSpawnFaction and MissionIntro.NormalizeSpawnFaction then
			fac = MissionIntro.NormalizeSpawnFaction(ent:GetSpawnFaction())
		end
		if fac == "" then
			return {
				pos = ent:GetPos(),
				ang = ent:GetAngles(),
				ent = ent,
				faction = "",
			}
		end
	end

	if zb and zb.GetRandomSpawn then
		local pos = zb:GetRandomSpawn(ply)
		if isvector(pos) then
			return { pos = pos, ang = Angle(0, 0, 0) }
		end
	end

	return nil
end

local MI_SPAWN_HULL_MINS = Vector(-16, -16, 0)
local MI_SPAWN_HULL_MAXS = Vector(16, 16, 72)

function MissionIntro.FindSafeStandingPos(pos, ply)
	if not isvector(pos) then return Vector(0, 0, 8) end

	local filter = ply
	local tries = {
		pos + Vector(0, 0, 8),
		pos + Vector(0, 0, 16),
		pos + Vector(0, 0, 32),
		pos + Vector(0, 0, 64),
	}

	for _, test in ipairs(tries) do
		local tr = util.TraceHull({
			start = test,
			endpos = test,
			mins = MI_SPAWN_HULL_MINS,
			maxs = MI_SPAWN_HULL_MAXS,
			mask = MASK_PLAYERSOLID,
			filter = filter,
		})

		if not tr.StartSolid and not tr.AllSolid then
			return test
		end
	end

	local down = util.TraceHull({
		start = pos + Vector(0, 0, 96),
		endpos = pos - Vector(0, 0, 96),
		mins = MI_SPAWN_HULL_MINS,
		maxs = MI_SPAWN_HULL_MAXS,
		mask = MASK_PLAYERSOLID,
		filter = filter,
	})

	if down.Hit and not down.StartSolid then
		return down.HitPos + Vector(0, 0, 4)
	end

	return pos + Vector(0, 0, 16)
end

function MissionIntro.ApplySpawnTransform(ply, spawnData)
	if not IsValid(ply) then return false end

	if MissionIntro.GetMissionSpawnData then
		spawnData = MissionIntro.GetMissionSpawnData(ply, spawnData)
	end

	if not istable(spawnData) or not isvector(spawnData.pos) then return false end

	MissionIntro.LeaveSpectator(ply)

	local pos = spawnData.pos
	local ang = spawnData.ang or Angle(0, 0, 0)
	local safePos = MissionIntro.FindSafeStandingPos(pos, ply)

	ply:SetPos(safePos)
	ply:SetAngles(ang)
	ply:SetEyeAngles(Angle(0, ang.y, 0))

	return true
end

function MissionIntro.GetIntroSpawnDelay()
	local sched = MissionIntro.Schedule or {}
	if sched.spawn_at ~= nil then
		return math.max(0, tonumber(sched.spawn_at) or 0)
	end
	return math.max(0, tonumber(sched.unlock_at) or 16)
end

function MissionIntro.ShouldDelaySpawnUntilPhase3()
	return MissionIntro.DelaySpawnUntilPhase3 ~= false
end

function MissionIntro.PreparePlayerForIntroWait(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply._miIntroSpawnPending = true
	ply._miPendingSpawn = nil

	local function cachePendingSpawn(attempt)
		if not IsValid(ply) then return end

		local spawnEnts = MissionIntro.GetSpawnEntities and MissionIntro.GetSpawnEntities() or {}
		if #spawnEnts == 0 and (attempt or 0) < 15 then
			timer.Simple(0.1, function()
				cachePendingSpawn((attempt or 0) + 1)
			end)
			return
		end

		if MissionIntro.GetMissionSpawnData then
			ply._miPendingSpawn = MissionIntro.GetMissionSpawnData(ply, nil)
		elseif MissionIntro.PickSpawnPoint then
			ply._miPendingSpawn = MissionIntro.PickSpawnPoint(ply)
		end
	end

	cachePendingSpawn(0)

	if ply:Alive() then
		ply:KillSilent()
	end

	timer.Simple(0, function()
		if not IsValid(ply) then return end
		if ply.Spectate then
			ply:Spectate(OBS_MODE_ROAMING)
		end
	end)
end

function MissionIntro.CompleteIntroSpawn(ply, respawnFn)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply._miIntroSpawnPending = nil

	local sess = MissionIntro.ActiveSessions and MissionIntro.ActiveSessions[ply]
	if sess then
		sess.spawnPending = false
	end

	if MissionIntro.LeaveSpectator then
		MissionIntro.LeaveSpectator(ply)
	end

	if isfunction(respawnFn) then
		respawnFn(ply)
		if MissionIntro.UpdateAdminAliveState then
			MissionIntro.UpdateAdminAliveState(ply)
		end
		return true
	end

	if MissionIntro.RespawnPlayerAtMissionSpawn then
		local ok = MissionIntro.RespawnPlayerAtMissionSpawn(ply) == true
		if MissionIntro.UpdateAdminAliveState then
			MissionIntro.UpdateAdminAliveState(ply)
		end
		return ok
	end

	if MissionIntro.RespawnPlayer then
		MissionIntro.RespawnPlayer(ply)
		if MissionIntro.UpdateAdminAliveState then
			MissionIntro.UpdateAdminAliveState(ply)
		end
		return true
	end

	ply:Spawn()
	if MissionIntro.UpdateAdminAliveState then
		MissionIntro.UpdateAdminAliveState(ply)
	end
	return true
end

function MissionIntro.RespawnPlayerAtMissionSpawn(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	if hook.Run("MissionIntro_RespawnPlayer", ply) == true then
		return true
	end

	local spawnData = MissionIntro.GetMissionSpawnData(ply, ply._miPendingSpawn)
	if not istable(spawnData) or not isvector(spawnData.pos) then
		ply._miPendingSpawn = nil
		spawnData = MissionIntro.GetMissionSpawnData(ply, nil)
	end
	ply._miPendingSpawn = spawnData

	local function finishSpawn()
		if not IsValid(ply) then return end
		MissionIntro.LeaveSpectator(ply)
		if spawnData then
			MissionIntro.ApplySpawnTransform(ply, spawnData)
		end
		ply._miPendingSpawn = nil

		timer.Simple(0.22, function()
			if not IsValid(ply) then return end
			if MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply) and MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true, spawnDirect = true })
			elseif MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply)
			end
			if MissionIntro.UpdateAdminAliveState then
				MissionIntro.UpdateAdminAliveState(ply)
			end
		end)
	end

	MissionIntro.LeaveSpectator(ply)

	if MissionIntro.PrimeForcedSpawnModel then
		MissionIntro.PrimeForcedSpawnModel(ply)
	end

	if not ply:Alive() then
		ply:Spawn()
		if MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply) and MissionIntro.ApplyForcedPlayerModel then
			MissionIntro.ApplyForcedPlayerModel(ply, { sync = true, spawnDirect = true })
		end
		finishSpawn()
	else
		ply:KillSilent()
		timer.Simple(0, function()
			if not IsValid(ply) then return end
			MissionIntro.LeaveSpectator(ply)
			if MissionIntro.PrimeForcedSpawnModel then
				MissionIntro.PrimeForcedSpawnModel(ply)
			end
			ply:Spawn()
			if MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply) and MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true, spawnDirect = true })
			end
			finishSpawn()
		end)
	end

	return spawnData ~= nil
end

hook.Add("PlayerSpawn", "MissionIntro_MissionSpawnPoint", function(ply)
	local data = ply._miPendingSpawn
	if not data then return end

	local roundName = CurrentRound and CurrentRound().name or ""
	if roundName ~= "rxsend" and not ply._miIntroSpawnPending then
		ply._miPendingSpawn = nil
		return
	end

	timer.Simple(0, function()
		if IsValid(ply) and ply._miPendingSpawn then
			MissionIntro.ApplySpawnTransform(ply, ply._miPendingSpawn)
			ply._miPendingSpawn = nil
		end
	end)
end)
