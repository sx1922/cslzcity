MissionIntro = MissionIntro or {}
MissionIntro.ActiveSessions = MissionIntro.ActiveSessions or {}

util.AddNetworkString("MissionIntro_Start")
util.AddNetworkString("MissionIntro_Finished")
util.AddNetworkString("MissionIntro_Unlock")
util.AddNetworkString("MissionIntro_ForceStop")
util.AddNetworkString("MissionIntro_Abort")
util.AddNetworkString("MissionIntro_AdminStart")

MissionIntro._introRewardLock = MissionIntro._introRewardLock or {}

local function MI_RewardLockKey(ply)
	if not IsValid(ply) then return nil end
	return ply:SteamID64() or ply:UniqueID()
end

local function MI_ClearTimers(ply)
	if not IsValid(ply) then return end
	local timerKey = MI_RewardLockKey(ply) or tostring(ply:EntIndex())
	timer.Remove("MissionIntro_Unlock_" .. timerKey)
	timer.Remove("MissionIntro_End_" .. timerKey)
	timer.Remove("MissionIntro_Reward_" .. timerKey)
	timer.Remove("MissionIntro_Unlock_" .. ply:EntIndex())
	timer.Remove("MissionIntro_End_" .. ply:EntIndex())
	timer.Remove("MissionIntro_Reward_" .. ply:EntIndex())
end

local function MI_AssignFacilityInline(ply, factionId)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	factionId = (MissionIntro.NormalizeFacilityFactionId and MissionIntro.NormalizeFacilityFactionId(factionId)) or factionId
	if not (MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId)) then
		return false
	end
	if MissionIntro.AssignFacilityFaction then
		return MissionIntro.AssignFacilityFaction(ply, factionId) == true
	end
	ply._missionIntroFaction = factionId
	if ply.SetNWString then
		ply:SetNWString("MissionIntro_FactionId", factionId)
	end
	return true
end

local function MI_BuildFacilityStartList(targets, factionId, admin)
	local startList = {}
	if not istable(targets) then return startList end

	for _, ply in ipairs(targets) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if MissionIntro.IsPlaying and MissionIntro.IsPlaying(ply) then continue end
		if MI_AssignFacilityInline(ply, factionId) then
			startList[#startList + 1] = ply
		end
	end

	if #startList == 0 and IsValid(admin) and admin:IsPlayer() then
		admin:ChatPrint("[MissionIntro] 设施入场失败: " .. tostring(factionId) .. "（0 名玩家）")
	end

	return startList
end

-- 批量入场：默认第三阶段再重生到出生点，过场期间观察者免疫伤害
function MissionIntro.BatchRespawnAndStartIntro(startList, opts)
	opts = opts or {}
	local stagger = tonumber(opts.stagger)
	if stagger == nil then
		stagger = tonumber(MissionIntro.BatchSpawnStagger) or 0
	end
	local modelDelay = tonumber(opts.modelDelay) or tonumber(MissionIntro.BatchSpawnModelDelay) or 0.22
	local introDelay = tonumber(opts.introDelay) or tonumber(MissionIntro.BatchSpawnIntroDelay) or 0.3
	local factionId = opts.factionId
	local respawnFn = opts.respawnFn
	local introOnly = opts.introOnly == true
	local delaySpawn = opts.delaySpawnUntilPhase3
	if delaySpawn == nil then
		delaySpawn = MissionIntro.ShouldDelaySpawnUntilPhase3 and MissionIntro.ShouldDelaySpawnUntilPhase3()
	end
	local spawnDelay = tonumber(opts.spawnDelay)
	if spawnDelay == nil and delaySpawn then
		spawnDelay = MissionIntro.GetIntroSpawnDelay and MissionIntro.GetIntroSpawnDelay() or 16
	end

	local players = {}
	local anyFacilityPhase3 = false
	local isFacilityBatch = MissionIntro.IsFacilityFactionId and isstring(factionId) and MissionIntro.IsFacilityFactionId(factionId)
	if factionId == "facility_science_batch" or factionId == "facility_qrf_batch" then
		isFacilityBatch = true
	end

	for _, ply in ipairs(startList or {}) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		-- 勿在此再 PreparePlayerForSupportReinforce：AdminStart / 增援流程已在
		-- AssignRandom*Roles 之前清过状态；此处再清会抹掉刚写入的 NtfRole/CiRole 等，
		-- GiveRewards 只能回落到默认 soldier 装备。
		if opts.prepareReinforce == true and MissionIntro.PreparePlayerForSupportReinforce then
			MissionIntro.PreparePlayerForSupportReinforce(ply)
		end
		ply._miPendingSpawn = nil
		ply._miIntroSpawnPending = nil
		if isFacilityBatch and MissionIntro.AssignFacilityFaction and isstring(factionId)
			and factionId ~= "facility_science_batch" and factionId ~= "facility_qrf_batch" then
			MissionIntro.AssignFacilityFaction(ply, factionId)
		elseif isFacilityBatch and MissionIntro.AssignFacilityFaction then
			local facId = MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply)
			if facId then
				MissionIntro.AssignFacilityFaction(ply, facId)
			end
		elseif isstring(factionId) and factionId ~= "" and MissionIntro.Factions and MissionIntro.Factions[factionId] then
			ply._missionIntroFaction = factionId
			if ply.SetNWString then
				ply:SetNWString("MissionIntro_FactionId", factionId)
			end
		end
		if MissionIntro.PrimeForcedSpawnModel then
			MissionIntro.PrimeForcedSpawnModel(ply)
		end
		if MissionIntro.ShouldUseFacilityPhase3Intro and MissionIntro.ShouldUseFacilityPhase3Intro(ply) then
			anyFacilityPhase3 = true
		end
		players[#players + 1] = ply
	end
	if #players == 0 then return end

	if anyFacilityPhase3 then
		delaySpawn = false
		spawnDelay = nil
	end

	local function doSpawn(ply)
		if not IsValid(ply) then return end
		if MissionIntro.PrimeForcedSpawnModel then
			MissionIntro.PrimeForcedSpawnModel(ply)
		end
		if MissionIntro.CompleteIntroSpawn then
			MissionIntro.CompleteIntroSpawn(ply, respawnFn)
		elseif isfunction(respawnFn) then
			respawnFn(ply)
		elseif MissionIntro.RespawnPlayer then
			MissionIntro.RespawnPlayer(ply)
		else
			ply:Spawn()
		end
		if MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply) and MissionIntro.ApplyForcedPlayerModel then
			MissionIntro.ApplyForcedPlayerModel(ply, { sync = true, spawnDirect = true })
		end
	end

	local function applyModel(ply)
		if MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply) then
			return
		end
		if IsValid(ply) and MissionIntro.ApplyForcedPlayerModel then
			MissionIntro.ApplyForcedPlayerModel(ply)
		end
	end

	local function startIntro(ply)
		if not IsValid(ply) then return end
		local facId = factionId
		if facId == "facility_science_batch" then
			facId = MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply)
			if not facId then
				local roleKey = ply:GetNWString("RXSend_RoleKey", "")
				if roleKey ~= "" and MissionIntro.RXSendGetRoleDef then
					local def = MissionIntro.RXSendGetRoleDef(roleKey)
					if def and isstring(def.faction_id) and def.faction_id ~= "" then
						facId = def.faction_id
					end
				end
			end
			if not facId then
				local facRole = ply:GetNWString("MissionIntro_FacilityRole", "")
				if facRole == "" and isstring(ply._missionIntroFacilityRole) then
					facRole = ply._missionIntroFacilityRole
				end
				if facRole ~= "" and MissionIntro.FacilityRoles and MissionIntro.FacilityRoles[facRole] then
					facId = MissionIntro.FacilityRoles[facRole].faction_id
				elseif facRole ~= "" and MissionIntro.FacilityFactionToRole then
					for fid, rk in pairs(MissionIntro.FacilityFactionToRole) do
						if rk == facRole then
							facId = fid
							break
						end
					end
				end
			end
			local isMtf = facId and MissionIntro.IsFacilityMtfFactionId and MissionIntro.IsFacilityMtfFactionId(facId)
			local isQrf = facId and MissionIntro.IsFacilityQrfFactionId and MissionIntro.IsFacilityQrfFactionId(facId)
			if not facId and not isMtf and not isQrf then
				facId = "facility_researcher"
			end
		elseif facId == "facility_qrf_batch" then
			facId = MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply)
			if not facId then
				local facRole = ply:GetNWString("MissionIntro_FacilityRole", "")
				if facRole == "" and isstring(ply._missionIntroFacilityRole) then
					facRole = ply._missionIntroFacilityRole
				end
				if facRole ~= "" and MissionIntro.FacilityRoles and MissionIntro.FacilityRoles[facRole] then
					facId = MissionIntro.FacilityRoles[facRole].faction_id
				elseif facRole ~= "" and MissionIntro.FacilityFactionToRole then
					for fid, rk in pairs(MissionIntro.FacilityFactionToRole) do
						if rk == facRole then
							facId = fid
							break
						end
					end
				end
			end
			if not facId then
				facId = "facility_qrf_soldier"
			end
		end
		if isFacilityBatch and isstring(facId) and facId ~= "" then
			MI_AssignFacilityInline(ply, facId)
		end
		if MissionIntro.StartIntro then
			MissionIntro.StartIntro(ply, nil, true, facId, {
				skipRespawn = introOnly,
				restart = introOnly,
			})
		end
	end

	if introOnly then
		timer.Simple(introDelay, function()
			for _, ply in ipairs(players) do
				startIntro(ply)
			end
		end)
		return
	end

	if delaySpawn and spawnDelay and spawnDelay > 0 then
		for _, ply in ipairs(players) do
			if MissionIntro.PreparePlayerForIntroWait then
				MissionIntro.PreparePlayerForIntroWait(ply)
			end
		end

		if stagger <= 0 then
			timer.Simple(introDelay, function()
				for _, ply in ipairs(players) do
					startIntro(ply)
				end
			end)
			return
		end

		local delay = 0
		for _, ply in ipairs(players) do
			timer.Simple(delay + introDelay, function()
				startIntro(ply)
			end)
			delay = delay + stagger
		end
		return
	end

	if stagger <= 0 then
		for _, ply in ipairs(players) do
			doSpawn(ply)
		end
		timer.Simple(modelDelay, function()
			for _, ply in ipairs(players) do
				applyModel(ply)
			end
		end)
		timer.Simple(introDelay, function()
			for _, ply in ipairs(players) do
				startIntro(ply)
			end
		end)
		return
	end

	local delay = 0
	for _, ply in ipairs(players) do
		timer.Simple(delay, function()
			doSpawn(ply)
			timer.Simple(modelDelay, function()
				applyModel(ply)
			end)
			timer.Simple(introDelay, function()
				startIntro(ply)
			end)
		end)
		delay = delay + stagger
	end
end

function MissionIntro.RespawnPlayer(ply)
	if MissionIntro.RespawnPlayerAtMissionSpawn then
		MissionIntro.RespawnPlayerAtMissionSpawn(ply)
		return
	end

	if not IsValid(ply) or not ply:IsPlayer() then return end
	if hook.Run("MissionIntro_RespawnPlayer", ply) == true then return end

	if MissionIntro.LeaveSpectator then
		MissionIntro.LeaveSpectator(ply)
	end

	if not ply:Alive() then
		ply:Spawn()
	else
		ply:KillSilent()
		timer.Simple(0, function()
			if IsValid(ply) then ply:Spawn() end
		end)
	end
end

function MissionIntro.IsPlaying(ply)
	return MissionIntro.ActiveSessions[ply] ~= nil
end

function MissionIntro.HasGivenIntroReward(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	local key = MI_RewardLockKey(ply)
	if key and MissionIntro._introRewardLock[key] then return true end

	if ply._missionIntroRewarded then return true end

	local sess = MissionIntro.ActiveSessions[ply]
	if sess and sess.rewardGiven then return true end

	return false
end

function MissionIntro.MarkIntroRewardGiven(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local key = MI_RewardLockKey(ply)
	if key then
		MissionIntro._introRewardLock[key] = CurTime()
	end

	ply._missionIntroRewarded = true

	local sess = MissionIntro.ActiveSessions[ply]
	if sess then
		sess.rewardGiven = true
	end
end

function MissionIntro.ClearIntroRewardLock(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local key = MI_RewardLockKey(ply)
	if key then
		MissionIntro._introRewardLock[key] = nil
	end

	ply._missionIntroRewarded = nil

	if MissionIntro.ClearForcedPlayerModel then
		MissionIntro.ClearForcedPlayerModel(ply)
	end
end

function MissionIntro.TryGiveRewards(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if MissionIntro.HasGivenIntroReward(ply) then return false end

	local sess = MissionIntro.ActiveSessions[ply]
	if not sess or sess.rewardGiven or sess._givingRewards then return false end

	sess._givingRewards = true

	local ok = false
	if IsValid(sess.ent) and sess.ent.GiveIntroReward then
		ok = sess.ent:GiveIntroReward(ply) == true
	elseif MissionIntro.GiveRewards then
		ok = MissionIntro.GiveRewards(ply) == true
	end

	sess._givingRewards = false

	if ok then
		MissionIntro.MarkIntroRewardGiven(ply)
		if sess then
			sess.rewardGiven = true
		end
	end

	return ok
end

-- 设施入场：重生后立刻发武器/物资，不等第三阶段字幕结束
function MissionIntro.GiveFacilityIntroRewardsImmediate(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if MissionIntro.HasGivenIntroReward(ply) then return false end
	if not (MissionIntro.ShouldUseFacilityPhase3Intro and MissionIntro.ShouldUseFacilityPhase3Intro(ply)) then
		return false
	end

	local sess = MissionIntro.ActiveSessions[ply]
	if sess and (sess.rewardGiven or sess._givingRewards) then return false end

	if sess then
		sess._givingRewards = true
	end

	local ok = MissionIntro.GiveRewards and MissionIntro.GiveRewards(ply) == true

	if sess then
		sess._givingRewards = false
		if ok then
			sess.rewardGiven = true
		end
	end

	return ok
end

local function MI_ScheduleFacilityIntroRewards(ply, delays)
	if not IsValid(ply) then return end
	for _, delay in ipairs(delays or { 0.12, 0.35 }) do
		timer.Simple(delay, function()
			if not IsValid(ply) then return end
			if MissionIntro.HasGivenIntroReward(ply) then return end
			if MissionIntro.GiveFacilityIntroRewardsImmediate then
				MissionIntro.GiveFacilityIntroRewardsImmediate(ply)
			elseif MissionIntro.TryGiveRewards then
				MissionIntro.TryGiveRewards(ply)
			end
		end)
	end
end

function MissionIntro.FinishIntro(ply, giveReward)
	if not IsValid(ply) then return end

	MI_ClearTimers(ply)
	ply._miIntroSpawnPending = nil
	ply:Freeze(false)

	if giveReward == true then
		MissionIntro.TryGiveRewards(ply)
	end

	local sess = MissionIntro.ActiveSessions[ply]
	if sess and IsValid(sess.ent) then
		sess.ent._playingPly = nil
		sess.ent:SetBusy(false)
	end

	MissionIntro.ActiveSessions[ply] = nil
	ply:SetNWBool("MissionIntro_IntroPlaying", false)
	if MissionIntro.UpdateAdminAliveState then
		MissionIntro.UpdateAdminAliveState(ply)
	end

	if MissionIntro.PlayerIsFacilityScpForWeapons and MissionIntro.PlayerIsFacilityScpForWeapons(ply) then
		if MissionIntro.SetFacilityScpPlayerFlag then
			MissionIntro.SetFacilityScpPlayerFlag(ply, true)
		end
		if MissionIntro.SyncFacilityScpPlayerFlag then
			MissionIntro.SyncFacilityScpPlayerFlag(ply)
		end
		if not (MissionIntro.IsFacilityScp912Player and MissionIntro.IsFacilityScp912Player(ply))
			and MissionIntro.EnforceFacilityScpWeaponWhitelist then
			MissionIntro.EnforceFacilityScpWeaponWhitelist(ply)
		end
		if MissionIntro.MI_ReinstallScpWeaponGuards then
			MissionIntro.MI_ReinstallScpWeaponGuards()
		end
	elseif MissionIntro.ShouldEnforceFacilityScpWeaponRules and MissionIntro.ShouldEnforceFacilityScpWeaponRules(ply) then
		if MissionIntro.SetFacilityScpPlayerFlag then
			MissionIntro.SetFacilityScpPlayerFlag(ply, true)
		end
		if not (MissionIntro.IsFacilityScp912Player and MissionIntro.IsFacilityScp912Player(ply))
			and MissionIntro.EnforceFacilityScpWeaponWhitelist then
			MissionIntro.EnforceFacilityScpWeaponWhitelist(ply)
		end
	end

	hook.Run("MissionIntro_AfterFinishIntro", ply)

	net.Start("MissionIntro_ForceStop")
	net.Send(ply)
end

function MissionIntro.StartIntro(ply, ent, skipBroadcast, forcedFactionId, opts)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	opts = opts or {}
	local skipRespawn = opts.skipRespawn == true

	if MissionIntro.IsPlaying(ply) then
		if opts.restart == true and MissionIntro.FinishIntro then
			MissionIntro.FinishIntro(ply, false)
		else
			return false
		end
	end

	if isstring(forcedFactionId) and forcedFactionId ~= "" and MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(forcedFactionId) then
		MI_AssignFacilityInline(ply, forcedFactionId)
	end

	local factionId = MissionIntro.ResolveIntroFactionId and MissionIntro.ResolveIntroFactionId(ply, forcedFactionId)
		or MissionIntro.DefaultFaction

	if not skipBroadcast and MissionIntro.BroadcastFactionAlert then
		if not (MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId))
			and (not MissionIntro.ShouldBroadcastFaction or MissionIntro.ShouldBroadcastFaction(factionId)) then
			MissionIntro.BroadcastFactionAlert(factionId, { ply })
		end
	end

	if MissionIntro.BuildTimeline then
		MissionIntro.BuildTimeline(ply)
	end

	local sched = MissionIntro.Schedule or {}
	local total = MissionIntro.TotalDuration or 24
	local unlockAt = sched.unlock_at or 16
	local rewardAt = sched.reward_at or unlockAt
	local facilityPhase3 = (MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId))
		or (MissionIntro.ShouldUseFacilityPhase3Intro and MissionIntro.ShouldUseFacilityPhase3Intro(ply))
	if facilityPhase3 then
		unlockAt = 0.05
		rewardAt = 0.15
	end
	local timerKey = MI_RewardLockKey(ply) or tostring(ply:EntIndex())

	MissionIntro.ClearIntroRewardLock(ply)

	local spawnPending = ply._miIntroSpawnPending == true
	if facilityPhase3 then
		spawnPending = false
	elseif MissionIntro.ShouldDelaySpawnUntilPhase3 and MissionIntro.ShouldDelaySpawnUntilPhase3() then
		spawnPending = true
	end

	MissionIntro.ActiveSessions[ply] = {
		ent = ent,
		rewardGiven = false,
		started = CurTime(),
		spawnPending = spawnPending,
		facilityPhase3 = facilityPhase3,
		factionId = factionId,
	}
	ply:SetNWBool("MissionIntro_IntroPlaying", true)

	if MissionIntro.RXSendSyncPlayerTeam then
		MissionIntro.RXSendSyncPlayerTeam(ply)
	end

	if facilityPhase3 then
		ply._miIntroSpawnPending = nil
		timer.Simple(0, function()
			if not IsValid(ply) then return end
			if MissionIntro.PrimeFacilitySpawnModel then
				MissionIntro.PrimeFacilitySpawnModel(ply)
			end
			local needSpawn = not skipRespawn or not ply:Alive() or MissionIntro.IsPlayerSpectatingForAdmin(ply)
			if needSpawn then
				if MissionIntro.CompleteIntroSpawn then
					MissionIntro.CompleteIntroSpawn(ply)
				elseif MissionIntro.RespawnPlayer then
					MissionIntro.RespawnPlayer(ply)
				else
					ply:Spawn()
				end
			elseif MissionIntro.LeaveSpectator then
				MissionIntro.LeaveSpectator(ply)
			end
			timer.Simple(0, function()
				if IsValid(ply) and MissionIntro.ApplyForcedPlayerModel then
					MissionIntro.ApplyForcedPlayerModel(ply, { sync = true, spawnDirect = true })
				end
			end)
			MI_ScheduleFacilityIntroRewards(ply, { 0.12, 0.35, 0.55 })
			if MissionIntro.UpdateAdminAliveState then
				MissionIntro.UpdateAdminAliveState(ply)
			end
		end)
	elseif MissionIntro.ShouldDelaySpawnUntilPhase3 and MissionIntro.ShouldDelaySpawnUntilPhase3() then
		if not ply._miIntroSpawnPending and MissionIntro.PreparePlayerForIntroWait then
			MissionIntro.PreparePlayerForIntroWait(ply)
		end
	end

	if MissionIntro.FreezePlayer then
		ply:Freeze(true)
	end

	local scarletRole = ""
	local hammerfallRole = ""
	if factionId == "scarlet_cultist" and MissionIntro.GetScarletRole then
		scarletRole = MissionIntro.GetScarletRole(ply) or ""
	elseif factionId == "hammerfall_squad" and MissionIntro.GetHammerfallRole then
		hammerfallRole = MissionIntro.GetHammerfallRole(ply) or ""
	elseif factionId == "hammerfall_maintenance" and MissionIntro.GetHammerfallMaintenanceRole then
		hammerfallRole = MissionIntro.GetHammerfallMaintenanceRole(ply) or ""
	end

	local sidRole = ""
	if factionId == "sid_squad" and MissionIntro.GetSidRole then
		sidRole = MissionIntro.GetSidRole(ply) or ""
	elseif factionId == "uiu_taskforce" and MissionIntro.GetUiuTfRole then
		sidRole = MissionIntro.GetUiuTfRole(ply) or ""
	end

	local pttrbRole = ""
	if factionId == "pttrb_squad" and MissionIntro.GetPttrbRole then
		pttrbRole = MissionIntro.GetPttrbRole(ply) or ""
	end

	net.Start("MissionIntro_Start")
		net.WriteBool(IsValid(ent))
		if IsValid(ent) then
			net.WriteEntity(ent)
		end
		net.WriteFloat(CurTime())
		net.WriteString(factionId or "")
		net.WriteString(scarletRole)
		net.WriteString(hammerfallRole)
		net.WriteString(sidRole)
		net.WriteString(pttrbRole)
	net.Send(ply)

	MI_ClearTimers(ply)

	timer.Create("MissionIntro_Unlock_" .. timerKey, unlockAt, 1, function()
		if not IsValid(ply) then return end

		local sess = MissionIntro.ActiveSessions[ply]
		if sess and sess.spawnPending and MissionIntro.CompleteIntroSpawn then
			if MissionIntro.PrimeForcedSpawnModel then
				MissionIntro.PrimeForcedSpawnModel(ply)
			end
			MissionIntro.CompleteIntroSpawn(ply)
			if MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply) then
				timer.Simple(0, function()
					if IsValid(ply) and MissionIntro.ApplyForcedPlayerModel then
						MissionIntro.ApplyForcedPlayerModel(ply, { sync = true, spawnDirect = true })
					end
				end)
			else
				timer.Simple(tonumber(MissionIntro.BatchSpawnModelDelay) or 0.22, function()
					if IsValid(ply) and MissionIntro.ApplyForcedPlayerModel then
						MissionIntro.ApplyForcedPlayerModel(ply)
					end
				end)
			end
		end

		ply:Freeze(false)
	end)

	timer.Create("MissionIntro_Reward_" .. timerKey, rewardAt, 1, function()
		if not IsValid(ply) then return end
		if MissionIntro.HasGivenIntroReward(ply) then return end
		MissionIntro.TryGiveRewards(ply)
	end)

	timer.Create("MissionIntro_End_" .. timerKey, total + 0.5, 1, function()
		if not IsValid(ply) then return end
		MissionIntro.FinishIntro(ply, false)
	end)

	return true
end

function MissionIntro.AdminStartPlayers(admin, targets, factionId)
	if not MissionIntro.CanManage(admin) then return false end
	if not istable(targets) or #targets == 0 then return false end

	for _, ply in ipairs(targets) do
		if IsValid(ply) and ply:IsPlayer() and MissionIntro.PreparePlayerForSupportReinforce then
			MissionIntro.PreparePlayerForSupportReinforce(ply)
		end
	end

	if isstring(factionId) and factionId ~= "" and MissionIntro.NormalizeSidFactionId then
		if not (MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId)) then
			factionId = MissionIntro.NormalizeSidFactionId(factionId)
		end
	end
	if isstring(factionId) and factionId ~= "" and MissionIntro.NormalizeUiuTaskforceFactionId then
		if not (MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId)) then
			factionId = MissionIntro.NormalizeUiuTaskforceFactionId(factionId)
		end
	end

	if MissionIntro.IsIndividualFacilityQrfFactionId and MissionIntro.IsIndividualFacilityQrfFactionId(factionId) then
		if IsValid(admin) and admin:IsPlayer() then
			admin:ChatPrint("[MissionIntro] 快速反应部队仅支持小队批量入场，请使用「快速反应部队 小队批量入场」")
		end
		return false
	end

	if isstring(factionId) and factionId ~= "" and factionId ~= "facility_science_batch" and factionId ~= "facility_qrf_batch" then
		local known = MissionIntro.Factions and MissionIntro.Factions[factionId]
		local facility = MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId)
		if not known and not facility then
			if IsValid(admin) and admin:IsPlayer() then
				admin:ChatPrint("[MissionIntro] 未知阵营: " .. tostring(factionId))
			end
			factionId = nil
		end
	end

	local startList = {}
	if factionId == "scarlet_cultist" and MissionIntro.AssignRandomScarletRoles then
		startList = select(1, MissionIntro.AssignRandomScarletRoles(targets))
	elseif factionId == "hammerfall_squad" and MissionIntro.AssignRandomHammerfallRoles then
		startList = select(1, MissionIntro.AssignRandomHammerfallRoles(targets))
	elseif factionId == "hammerfall_maintenance" and MissionIntro.AssignRandomHammerfallMaintenanceRoles then
		local skippedOverCap
		startList, _, _, skippedOverCap = MissionIntro.AssignRandomHammerfallMaintenanceRoles(targets)
		if skippedOverCap and skippedOverCap > 0 and IsValid(admin) and admin:IsPlayer() then
			admin:ChatPrint("[MissionIntro] 维修小队每批最多 3 人，已跳过 " .. skippedOverCap .. " 名玩家")
		end
	elseif factionId == "sid_squad" and MissionIntro.AssignRandomSidRoles then
		startList = select(1, MissionIntro.AssignRandomSidRoles(targets))
	elseif factionId == "uiu_taskforce" and MissionIntro.AssignRandomUiuTfRoles then
		startList = select(1, MissionIntro.AssignRandomUiuTfRoles(targets))
	elseif factionId == "pttrb_squad" and MissionIntro.AssignRandomPttrbRoles then
		local skippedOverCap
		startList, _, _, skippedOverCap = MissionIntro.AssignRandomPttrbRoles(targets)
		if skippedOverCap and skippedOverCap > 0 and IsValid(admin) and admin:IsPlayer() then
			admin:ChatPrint("[MissionIntro] ETT 每批最多 3 人，已跳过 " .. skippedOverCap .. " 名玩家")
		end
	elseif factionId == "mcd_squad" and MissionIntro.AssignMcdCaptainToPlayers then
		startList = MissionIntro.AssignMcdCaptainToPlayers(targets)
	elseif factionId == "ci_squad" and MissionIntro.AssignRandomCiRoles then
		startList = MissionIntro.AssignRandomCiRoles(targets)
	elseif factionId == "vdv_squad" and MissionIntro.AssignRandomVdvRoles then
		startList = MissionIntro.AssignRandomVdvRoles(targets)
	elseif factionId == "goc_squad" and MissionIntro.AssignRandomGocRoles then
		startList = MissionIntro.AssignRandomGocRoles(targets, admin)
	elseif factionId == "ntf_squad" and MissionIntro.AssignNtfSoldierToPlayers then
		startList = MissionIntro.AssignNtfSoldierToPlayers(targets)
	elseif factionId == "class_d_personnel" and MissionIntro.AssignRandomClassDRoles then
		startList = select(1, MissionIntro.AssignRandomClassDRoles(targets, admin))
	elseif factionId == "facility_science_batch" and MissionIntro.AssignFacilityScienceBatch then
		startList = MissionIntro.AssignFacilityScienceBatch(targets, admin)
	elseif factionId == "facility_qrf_batch" and MissionIntro.AssignFacilityQrfSquadBatch then
		startList = select(1, MissionIntro.AssignFacilityQrfSquadBatch(targets, admin))
		if IsValid(admin) and admin:IsPlayer() and #startList > 0 then
			admin:ChatPrint("[MissionIntro] 快速反应部队批量入场已开始（" .. #startList .. " 人）")
		end
	elseif factionId == "uiu_spy" then
		startList = (MissionIntro.AssignUiuSpyToPlayers and MissionIntro.AssignUiuSpyToPlayers(targets, admin))
			or MI_BuildFacilityStartList(targets, "uiu_spy", admin)
	elseif factionId == "dr_maynard" then
		startList = (MissionIntro.AssignDrMaynardToPlayers and MissionIntro.AssignDrMaynardToPlayers(targets, admin))
			or MI_BuildFacilityStartList(targets, "dr_maynard", admin)
	elseif factionId == "ci_spy" then
		startList = (MissionIntro.AssignCiSpyToPlayers and MissionIntro.AssignCiSpyToPlayers(targets, admin))
			or MI_BuildFacilityStartList(targets, "ci_spy", admin)
	elseif MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId) then
		startList = (MissionIntro.AssignFacilityPlayersForIntro and select(1, MissionIntro.AssignFacilityPlayersForIntro(targets, factionId, admin)))
			or MI_BuildFacilityStartList(targets, factionId, admin)
		if IsValid(admin) and admin:IsPlayer() and #startList > 0 then
			admin:ChatPrint("[MissionIntro] 设施入场已开始: " .. tostring(factionId))
		end
	else
		for _, ply in ipairs(targets) do
			if not IsValid(ply) or not ply:IsPlayer() then continue end
			if MissionIntro.IsPlaying(ply) then continue end
			if MissionIntro.ClearScarletRole then
				MissionIntro.ClearScarletRole(ply)
			end
			if MissionIntro.ClearHammerfallRole then
				MissionIntro.ClearHammerfallRole(ply)
			end
			if MissionIntro.ClearHammerfallMaintenanceRole then
				MissionIntro.ClearHammerfallMaintenanceRole(ply)
			end
			if MissionIntro.ClearSidRole then
				MissionIntro.ClearSidRole(ply)
			end
			if MissionIntro.ClearPttrbRole then
				MissionIntro.ClearPttrbRole(ply)
			end
			if MissionIntro.ClearMcdRole then
				MissionIntro.ClearMcdRole(ply)
			end
			if MissionIntro.ClearCiRole then
				MissionIntro.ClearCiRole(ply)
			end
			if MissionIntro.ClearVdvRole then
				MissionIntro.ClearVdvRole(ply)
			end
			if MissionIntro.ClearGocRole then
				MissionIntro.ClearGocRole(ply)
			end
			if MissionIntro.ClearFacilityRole then
				MissionIntro.ClearFacilityRole(ply)
			end
			startList[#startList + 1] = ply
		end
	end

	if #startList == 0 then return false end

	local broadcastFaction = factionId
	if (not isstring(broadcastFaction) or broadcastFaction == "") and IsValid(startList[1]) then
		broadcastFaction = MissionIntro.GetFactionId and MissionIntro.GetFactionId(startList[1]) or MissionIntro.DefaultFaction
	end
	if MissionIntro.BroadcastFactionAlert and isstring(broadcastFaction) and broadcastFaction ~= "" then
		local skipFacilityBroadcast = MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(broadcastFaction)
		if not skipFacilityBroadcast and (not MissionIntro.ShouldBroadcastFaction or MissionIntro.ShouldBroadcastFaction(broadcastFaction)) then
			MissionIntro.BroadcastFactionAlert(broadcastFaction, startList)
		end
	end

	if hook.Run("MissionIntro_AdminStartBroadcast", broadcastFaction, startList) ~= true then
		if MissionIntro.ShouldPlayQrfDeploymentBroadcast
			and MissionIntro.ShouldPlayQrfDeploymentBroadcast(broadcastFaction)
			and MissionIntro.BroadcastQrfDeploymentAlert then
			MissionIntro.BroadcastQrfDeploymentAlert(startList)
		end
	end

	if broadcastFaction == "scarlet_cultist" and MissionIntro.OnScarletBatchSpawned then
		MissionIntro.OnScarletBatchSpawned(startList)
	end

	if (broadcastFaction == "sid_squad" or broadcastFaction == "uiu_taskforce" or broadcastFaction == "uiu_spy") and MissionIntro.StartUiuComputerMission then
		timer.Simple(0.5, function()
			if MissionIntro.StartUiuComputerMission then
				MissionIntro.StartUiuComputerMission()
			end
		end)
	end

	local useFacilityBatch = isstring(factionId)
		and (
			factionId == "facility_science_batch"
			or factionId == "facility_qrf_batch"
			or (MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId))
		)

	if useFacilityBatch and MissionIntro.StartFacilityIntroBatch then
		MissionIntro.StartFacilityIntroBatch(startList, factionId)
	elseif MissionIntro.BatchRespawnAndStartIntro then
		MissionIntro.BatchRespawnAndStartIntro(startList, { factionId = factionId })
	end

	return true
end

net.Receive("MissionIntro_AdminStart", function(_, admin)
	if not MissionIntro.CanManage(admin) then return end

	local count = net.ReadUInt(8)
	local keys = {}

	for _ = 1, count do
		local key = net.ReadString()
		if isstring(key) and key ~= "" then
			keys[#keys + 1] = key
		end
	end

	local targets = MissionIntro.ResolvePlayersFromTargetKeys and MissionIntro.ResolvePlayersFromTargetKeys(keys) or {}

	if #targets == 0 and count > 0 and IsValid(admin) and admin:IsPlayer() then
		admin:ChatPrint("[MissionIntro] 未找到勾选玩家（可能已断线），请重新勾选后再试")
		return
	end

	local factionId = net.ReadString() or ""
	if factionId == "" then factionId = nil end

	MissionIntro.AdminStartPlayers(admin, targets, factionId)
end)

net.Receive("MissionIntro_Unlock", function(_, ply)
	if not IsValid(ply) then return end
	ply:Freeze(false)
end)

net.Receive("MissionIntro_Finished", function(_, ply)
	if not IsValid(ply) then return end

	net.ReadEntity()

	if MissionIntro.ActiveSessions[ply] then
		MissionIntro.FinishIntro(ply, false)
	end
end)

net.Receive("MissionIntro_Abort", function(_, ply)
	MissionIntro.FinishIntro(ply, false)
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro")) do
		if ent._playingPly == ply then
			ent._playingPly = nil
			ent:SetBusy(false)
		end
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_Cleanup", function(ply)
	MissionIntro.FinishIntro(ply, false)
end)

hook.Add("PlayerDeath", "MissionIntro_FinishIntroOnDeath", function(victim)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if MissionIntro.ActiveSessions[victim] then
		MissionIntro.FinishIntro(victim, false)
	end
end)

hook.Add("EntityTakeDamage", "MissionIntro_PendingSpawnProtect", function(target, dmginfo)
	if not IsValid(target) or not target:IsPlayer() then return end

	if target._miIntroSpawnPending then
		if dmginfo then dmginfo:SetDamage(0) end
		return true
	end

	local sess = MissionIntro.ActiveSessions[target]
	if sess and sess.spawnPending then
		if dmginfo then dmginfo:SetDamage(0) end
		return true
	end
end)
