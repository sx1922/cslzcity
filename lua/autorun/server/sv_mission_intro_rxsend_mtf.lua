if not SERVER then return end

MissionIntro = MissionIntro or {}

local REFRESH_TIMER = "MissionIntro_RXSendMtfSiteDirectorRefresh"
local REFRESH_INTERVAL = 2

local function RX_MtfRoundReady()
	if not MissionIntro.RXSendIsActive or not MissionIntro.RXSendIsActive() then return false end
	if not zb or zb.CROUND ~= "rxsend" then return false end

	local roundStart = tonumber(zb.ROUND_START or zb.ROUND_BEGIN) or 0
	if roundStart <= 0 then return false end

	local cardEnd = tonumber(MissionIntro.RXSendRoleCardEnd) or 8
	return CurTime() >= roundStart + cardEnd
end

function MissionIntro.RXSendCanRefreshSiteDirector()
	if not RX_MtfRoundReady() then return false end
	if MissionIntro.RXSendCountPlayingPlayers() < (tonumber(MissionIntro.RXSendMtfSiteDirectorMinPlayers) or 15) then
		return false
	end
	if MissionIntro.RXSendFindActiveSiteDirector() then
		return false
	end
	return true
end

function MissionIntro.RXSendDeploySiteDirector(ply, opts)
	opts = opts or {}
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.RXSendApplyRoleToPlayer then return false end
	if not MissionIntro.RXSendApplyRoleToPlayer(ply, "site_director") then return false end

	local function applySpawn(target)
		if not IsValid(target) or not target:Alive() then return end
		if MissionIntro.PickSpawnPoint and MissionIntro.ApplySpawnTransform then
			local sp = MissionIntro.PickSpawnPoint(target)
			if sp then
				MissionIntro.ApplySpawnTransform(target, sp)
			end
		end
	end

	if opts.skipIntro == true then
		if MissionIntro.CompleteIntroSpawn then
			MissionIntro.CompleteIntroSpawn(ply, applySpawn)
		else
			ply:Spawn()
			applySpawn(ply)
		end
		if MissionIntro.RXSendGiveLoadout then
			timer.Simple(0.25, function()
				if IsValid(ply) and MissionIntro.RXSendIsActive() then
					MissionIntro.RXSendGiveLoadout(ply)
					if MissionIntro.SyncHudRoleDisplay then
						MissionIntro.SyncHudRoleDisplay(ply)
					end
				end
			end)
		end
	else
		if MissionIntro.BatchRespawnAndStartIntro then
			MissionIntro.BatchRespawnAndStartIntro({ ply }, {
				factionId = "facility_mtf_site_director",
				respawnFn = applySpawn,
			})
		elseif MissionIntro.CompleteIntroSpawn then
			MissionIntro.CompleteIntroSpawn(ply, applySpawn)
		else
			ply:Spawn()
			applySpawn(ply)
		end
	end

	return true
end

function MissionIntro.RXSendRefreshSiteDirectorIfNeeded()
	if not MissionIntro.RXSendCanRefreshSiteDirector() then return false end

	local ply = MissionIntro.RXSendPickSiteDirectorCandidate()
	if not IsValid(ply) then return false end

	return MissionIntro.RXSendDeploySiteDirector(ply) == true
end

local function RX_ScheduleMtfRefreshThink()
	if timer.Exists(REFRESH_TIMER) then return end

	timer.Create(REFRESH_TIMER, REFRESH_INTERVAL, 0, function()
		if not MissionIntro.RXSendIsActive or not MissionIntro.RXSendIsActive() then
			timer.Remove(REFRESH_TIMER)
			return
		end
		MissionIntro.RXSendRefreshSiteDirectorIfNeeded()
	end)
end

hook.Add("ZB_PreRoundStart", "MissionIntro_RXSendMtfSiteDirectorReset", function()
	timer.Remove(REFRESH_TIMER)
end)

hook.Add("ZB_EndRound", "MissionIntro_RXSendMtfSiteDirectorStop", function()
	timer.Remove(REFRESH_TIMER)
end)

hook.Add("Think", "MissionIntro_RXSendMtfSiteDirectorRoundStart", function()
	if not RX_MtfRoundReady() then return end
	RX_ScheduleMtfRefreshThink()
	hook.Remove("Think", "MissionIntro_RXSendMtfSiteDirectorRoundStart")
end)

hook.Add("PlayerInitialSpawn", "MissionIntro_RXSendMtfSiteDirectorJoin", function(ply)
	timer.Simple(3, function()
		if IsValid(ply) then
			MissionIntro.RXSendRefreshSiteDirectorIfNeeded()
		end
	end)
end)

hook.Add("PlayerDisconnected", "MissionIntro_RXSendMtfSiteDirectorLeave", function()
	timer.Simple(1, function()
		MissionIntro.RXSendRefreshSiteDirectorIfNeeded()
	end)
end)
