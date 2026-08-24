if not SERVER then return end

MissionIntro = MissionIntro or {}

MissionIntro.RXSendLockdownBroadcastDelay = 8
MissionIntro.RXSendSpawnNoticeDelay = 1
-- 封锁广播专用音效（勿改路径/勿换文件）
MissionIntro.RXSendLockdownSound = "mission_intro/shourongshixiao.mp3"

local RXSEND_EVAC_TIMER = "MissionIntro_RXSendEvacuation"
local RXSEND_ALPHA_TIMER = "MissionIntro_RXSendAlphaWarhead"
local RXSEND_ALPHA_FINAL_TIMER = "MissionIntro_RXSendAlphaWarheadFinal"
local RXSEND_ALPHA_DETONATE_TIMER = "MissionIntro_RXSendAlphaWarheadDetonate"
local RXSEND_ROUND_TIME_MIN = 0
local RXSEND_ROUND_TIME_MAX = 7200

CreateConVar("rxsend_round_time", "1200", FCVAR_ARCHIVE + FCVAR_NOTIFY, "RXsend 模式回合时长（秒，0=无限制）")

local function RXSEND_FormatTime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

local function RXSEND_ParseTimeArg(arg)
	if not isstring(arg) or arg == "" then return nil end

	local mins, secs = arg:match("^(%d+):(%d+)$")
	if mins and secs then
		return tonumber(mins) * 60 + tonumber(secs)
	end

	return tonumber(arg)
end

local function RXSEND_Notify(ply, msg)
	if isstring(msg) and msg ~= "" then
		MsgN(msg)
	end
	if IsValid(ply) then
		ply:ChatPrint(msg)
	end
end

function MissionIntro.RXSendGetConfiguredRoundTime()
	local cv = GetConVar("rxsend_round_time")
	if cv then
		local value = cv:GetInt()
		if value >= RXSEND_ROUND_TIME_MIN and value <= RXSEND_ROUND_TIME_MAX then
			return value
		end
	end

	return tonumber(MissionIntro.RXSendDefaultRoundTime) or 0
end

function MissionIntro.RXSendApplyRoundTimeToMode(seconds)
	seconds = math.floor(tonumber(seconds) or 0)
	if seconds ~= 0 and (seconds < RXSEND_ROUND_TIME_MIN or seconds > RXSEND_ROUND_TIME_MAX) then
		return false
	end

	if zb and istable(zb.modes) and istable(zb.modes.rxsend) then
		zb.modes.rxsend.ROUND_TIME = seconds
	end

	return true
end

function MissionIntro.RXSendSetRoundTime(seconds, opts)
	opts = opts or {}
	seconds = math.floor(tonumber(seconds) or 0)
	if seconds ~= 0 and (seconds < RXSEND_ROUND_TIME_MIN or seconds > RXSEND_ROUND_TIME_MAX) then
		return false, "invalid"
	end

	local cv = GetConVar("rxsend_round_time")
	if cv then
		cv:SetInt(seconds)
	end

	MissionIntro.RXSendApplyRoundTimeToMode(seconds)

	local applyLive = opts.applyLive ~= false
	if applyLive and zb and zb.CROUND == "rxsend" and hg and hg.UpdateRoundTime and isnumber(zb.ROUND_START) then
		hg.UpdateRoundTime(seconds, zb.ROUND_START, zb.ROUND_BEGIN or zb.ROUND_START)

		if not MissionIntro._rxSendEvacuationTriggered and MissionIntro.RXSendScheduleEvacuationSequence then
			MissionIntro.RXSendScheduleEvacuationSequence()
		end
		if not MissionIntro._rxSendAlphaWarheadTriggered
			and not MissionIntro._rxSendAlphaWarheadDetonated
			and MissionIntro.RXSendScheduleAlphaWarheadSequence then
			MissionIntro.RXSendScheduleAlphaWarheadSequence()
		end
		if not MissionIntro._rxSendAlphaWarheadFinalWarningTriggered
			and not MissionIntro._rxSendAlphaWarheadDetonated
			and MissionIntro.RXSendScheduleAlphaWarheadFinalWarning then
			MissionIntro.RXSendScheduleAlphaWarheadFinalWarning()
		end
	end

	return true, seconds
end

local function RXSEND_PlayerInPlay(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end
	if ply._missionIntroEvacuated then return false end
	if ply:Alive() then return true end
	if IsValid(ply.FakeRagdoll) then return true end
	if hg and hg.GetCurrentCharacter then
		local ch = hg.GetCurrentCharacter(ply)
		if IsValid(ch) and ch ~= ply then return true end
	end
	if ply.organism and ply.organism.alive ~= false then return true end
	return false
end

local function RXSEND_MarkRoundEndHandled()
	MissionIntro._rxSendRoundEndHandled = true
	MissionIntro._rxSendAlphaWarheadDetonated = true
	MissionIntro._rxSendRoundEndKillDone = true
end

-- 阿尔法弹头：静默处死（与撤离一致），不用爆炸特效/范围伤害
local function RXSEND_ExecutePlayer(ply)
	if not RXSEND_PlayerInPlay(ply) then return false end

	if hg and hg.FakeUp then
		pcall(function() hg.FakeUp(ply, true, true) end)
	end
	if IsValid(ply.FakeRagdoll) then
		ply.FakeRagdoll:Remove()
		ply.FakeRagdoll = nil
	end
	if hg and hg.organism and hg.organism.Clear and ply.organism then
		pcall(function() hg.organism.Clear(ply.organism) end)
	end
	if ply.organism then
		ply.organism.alive = false
		if ply.organism.ooxygen then
			ply.organism.ooxygen = 0
		end
	end

	if hg and hg.GetCurrentCharacter then
		local ch = hg.GetCurrentCharacter(ply)
		if IsValid(ch) and ch ~= ply and ch:IsRagdoll() then
			ch:Remove()
		end
	end

	if ply:Alive() then
		ply:SetHealth(0)
		ply:KillSilent()
	end

	if ply:Alive() then
		local dmg = DamageInfo()
		dmg:SetDamage(99999)
		dmg:SetDamageType(DMG_GENERIC)
		dmg:SetAttacker(game.GetWorld())
		dmg:SetInflictor(game.GetWorld())
		ply:TakeDamageInfo(dmg)
	end
	if ply:Alive() then
		ply:Kill()
	end

	return true
end

local function RXSEND_ForEachActivePlayer(fn)
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() then
			fn(ply)
		end
	end
end

function MissionIntro.RXSendResetRoundEndFlags()
	MissionIntro._rxSendRoundEndHandled = false
	MissionIntro._rxSendEvacuationTriggered = false
	MissionIntro._rxSendAlphaWarheadTriggered = false
	MissionIntro._rxSendAlphaWarheadFinalWarningTriggered = false
	MissionIntro._rxSendAlphaWarheadDetonated = false
	MissionIntro._rxSendRoundEndKillDone = false
	if MissionIntro.RXSendResetRoundPause then
		MissionIntro.RXSendResetRoundPause()
	end
	MissionIntro._rxSendScarletPrayerActive = false
end

function MissionIntro.RXSendRescheduleRoundEndSequences()
	if not MissionIntro.RXSendScheduleRoundEndSequences then return end
	MissionIntro.RXSendCancelRoundEndSchedules()
	MissionIntro.RXSendScheduleRoundEndSequences({ reschedule = true })
end

function MissionIntro.RXSendExecuteAlphaWarheadDetonation()
	if MissionIntro._rxSendRoundEndHandled or MissionIntro._rxSendAlphaWarheadDetonated then
		return false
	end
	if not zb or zb.CROUND ~= "rxsend" then return false end

	RXSEND_MarkRoundEndHandled()
	MissionIntro.RXSendCancelRoundEndSchedules()

	local executed = 0

	RXSEND_ForEachActivePlayer(function(ply)
		if RXSEND_ExecutePlayer(ply) then
			executed = executed + 1
		end
	end)

	MsgN("[MissionIntro] RXsend 阿尔法弹头：已处死 ", executed, " 名在场玩家")

	return true
end

function MissionIntro.RXSendBroadcastSpawnNotice()
	if not MissionIntro.BroadcastCustomAlert then return false end

	local title = MissionIntro.L and MissionIntro.L("rxsend_broadcast_spawn_title") or "设施广播"
	local line1 = MissionIntro.L and MissionIntro.L("rxsend_broadcast_spawn_line1")
		or "请所有人注意 请......"

	MissionIntro.BroadcastCustomAlert({
		title = title,
		line1 = line1,
		line2 = "",
		accent = Color(200, 180, 80),
	}, {
		playSound = false,
		forceSoundDuringIntro = true,
	})

	return true
end

function MissionIntro.RXSendPlayLockdownSound()
	local snd = MissionIntro.RXSendLockdownSound or "mission_intro/shourongshixiao.mp3"
	if MissionIntro.BroadcastSoundToAll then
		MissionIntro.BroadcastSoundToAll(snd, { forceSoundDuringIntro = true })
	end
	return true
end

function MissionIntro.RXSendBroadcastLockdown(playSound)
	if not MissionIntro.BroadcastCustomAlert then return false end

	local title = MissionIntro.L and MissionIntro.L("rxsend_broadcast_title") or "Z city"
	local line1 = MissionIntro.L and MissionIntro.L("rxsend_broadcast_line1")
		or "设施内多个Euclid与Keter级SCP收容失效"
	local line2 = MissionIntro.L and MissionIntro.L("rxsend_broadcast_line2") or "设施已被封锁"

	MissionIntro.BroadcastCustomAlert({
		title = title,
		line1 = line1,
		line2 = line2,
		accent = Color(220, 48, 48),
	}, {
		playSound = playSound == true,
		forceSoundDuringIntro = true,
	})

	return true
end

function MissionIntro.RXSendScheduleLockdownBroadcast(delay)
	delay = tonumber(delay)
	if delay == nil then
		delay = tonumber(MissionIntro.RXSendLockdownBroadcastDelay) or 8
	end

	timer.Simple(math.max(0, delay), function()
		if zb.CROUND ~= "rxsend" then return end
		MissionIntro.RXSendBroadcastLockdown(false)
	end)
end

function MissionIntro.RXSendGetPlayingPlayers()
	local list = {}
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and ply:Team() ~= TEAM_SPECTATOR then
			list[#list + 1] = ply
		end
	end
	return list
end

function MissionIntro.RXSendPreparePlayersForRoleCard(players)
	for _, ply in ipairs(players or {}) do
		if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then continue end
		if MissionIntro.PreparePlayerForIntroWait then
			MissionIntro.PreparePlayerForIntroWait(ply)
		end
	end
end

function MissionIntro.RXSendSpawnPlayersAfterRoleCard(applySpawnFn)
	if zb.CROUND ~= "rxsend" then return false end

	local spawned = false
	for _, ply in player.Iterator() do
		if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then continue end
		if ply:GetNWString("RXSend_RoleKey", "") == "" and not ply.RXSendRoleKey then continue end

		if ply.SetupTeam then
			ply:SetupTeam(ply:Team())
		elseif hg and hg.CreateInv then
			hg.CreateInv(ply)
		end

		if MissionIntro.CompleteIntroSpawn then
			MissionIntro.CompleteIntroSpawn(ply)
		else
			ply:Spawn()
		end

		if isfunction(applySpawnFn) then
			applySpawnFn(ply)
		end

		if MissionIntro.UpdateAdminAliveState then
			MissionIntro.UpdateAdminAliveState(ply)
		end

		spawned = true
	end

	if spawned and MissionIntro.RXSendStartRoundIntro then
		timer.Simple(0.4, function()
			if zb.CROUND ~= "rxsend" then return end
			MissionIntro.RXSendStartRoundIntro(MissionIntro.RXSendGetPlayingPlayers())
		end)
	end

	return spawned
end

function MissionIntro.RXSendScheduleRoleCardSpawn(delay, applySpawnFn)
	delay = tonumber(delay)
	if delay == nil then
		delay = tonumber(MissionIntro.RXSendRoleCardEnd) or 8
	end

	timer.Simple(math.max(0, delay), function()
		if zb.CROUND ~= "rxsend" then return end
		MissionIntro.RXSendSpawnPlayersAfterRoleCard(applySpawnFn)
	end)

	MissionIntro.RXSendScheduleRoundEndSequences()
end

function MissionIntro.RXSendCancelRoundEndSchedules()
	MissionIntro.RXSendCancelEvacuationSchedule()
	MissionIntro.RXSendCancelAlphaWarheadSchedule()
end

function MissionIntro.RXSendScheduleRoundEndSequences(opts)
	opts = opts or {}
	local roundTime = tonumber(zb and zb.ROUND_TIME) or MissionIntro.RXSendGetConfiguredRoundTime() or 0
	if roundTime <= 0 then
		return
	end

	MissionIntro.RXSendScheduleEvacuationSequence(opts)
	MissionIntro.RXSendScheduleAlphaWarheadSequence(opts)
	MissionIntro.RXSendScheduleAlphaWarheadFinalWarning(opts)
end

function MissionIntro.RXSendGetRoundEndEventDelay(secondsBeforeEnd)
	local remaining = MissionIntro.RXSendGetRoundTimeRemaining and MissionIntro.RXSendGetRoundTimeRemaining()
	if remaining == nil then return nil end
	return math.max(0, remaining - (tonumber(secondsBeforeEnd) or 0))
end

function MissionIntro.RXSendCancelEvacuationSchedule()
	timer.Remove(RXSEND_EVAC_TIMER)
end

function MissionIntro.RXSendGetEvacuationTriggerDelay()
	return MissionIntro.RXSendGetRoundEndEventDelay(MissionIntro.RXSendEvacuationSecondsBeforeEnd or 210)
end

function MissionIntro.RXSendBroadcastEvacuation()
	if not MissionIntro.BroadcastCustomAlert then return false end

	local title = MissionIntro.L and MissionIntro.L("rxsend_evacuation_broadcast_title") or "设施广播"
	local line1 = MissionIntro.L and MissionIntro.L("rxsend_evacuation_broadcast_line1")
		or "注意！紧急疏散已开始，所有人员按标准撤离"

	MissionIntro.BroadcastCustomAlert({
		title = title,
		line1 = line1,
		line2 = "",
		accent = Color(220, 48, 48),
	}, {
		playSound = false,
		forceSoundDuringIntro = true,
	})

	local alertSound = MissionIntro.RXSendEvacuationAlertSound or "mission_intro/rxsend_evacuation_alert.mp3"
	local musicPath = MissionIntro.RXSendEvacuationMusic or "mission_intro/rxsend_evacuation_music.mp3"
	local soundOpts = { forceSoundDuringIntro = true }

	if MissionIntro.BroadcastSoundToAll then
		MissionIntro.BroadcastSoundToAll(alertSound, soundOpts)
	end
	if MissionIntro.BroadcastMusicToAll then
		MissionIntro.BroadcastMusicToAll(musicPath, soundOpts)
	end

	return true
end

function MissionIntro.RXSendTriggerEvacuationSequence()
	if zb.CROUND ~= "rxsend" then return false end
	if MissionIntro._rxSendEvacuationTriggered then return false end

	MissionIntro._rxSendEvacuationTriggered = true
	MissionIntro.RXSendBroadcastEvacuation()
	MsgN("[MissionIntro] RXsend 紧急疏散序列已触发")
	return true
end

function MissionIntro.RXSendScheduleEvacuationSequence(opts)
	opts = opts or {}

	MissionIntro.RXSendCancelEvacuationSchedule()
	if MissionIntro._rxSendEvacuationTriggered and opts.reschedule then
		return false
	end
	if not opts.reschedule then
		MissionIntro._rxSendEvacuationTriggered = false
	end

	if zb.CROUND ~= "rxsend" then return false end
	if MissionIntro._rxSendEvacuationTriggered then return false end

	local delay = MissionIntro.RXSendGetEvacuationTriggerDelay()
	if not delay then return false end
	timer.Create(RXSEND_EVAC_TIMER, delay, 1, function()
		if zb.CROUND ~= "rxsend" then return end
		MissionIntro.RXSendTriggerEvacuationSequence()
	end)

	MsgN("[MissionIntro] RXsend 紧急疏散已排程，", delay, " 秒后触发")
	return true
end

function MissionIntro.RXSendCancelAlphaWarheadSchedule()
	timer.Remove(RXSEND_ALPHA_TIMER)
	timer.Remove(RXSEND_ALPHA_FINAL_TIMER)
	timer.Remove(RXSEND_ALPHA_DETONATE_TIMER)
end

function MissionIntro.RXSendGetAlphaWarheadAlertDuration()
	local path = MissionIntro.RXSendAlphaWarheadAlertSound or "mission_intro/rxsend_alpha_warhead_start.mp3"
	local duration

	if SoundDuration then
		if util.PrecacheSound then
			util.PrecacheSound(path)
		end
		duration = SoundDuration(path)
	end

	if isnumber(duration) and duration > 0 then
		return duration
	end

	return tonumber(MissionIntro.RXSendAlphaWarheadAlertDurationFallback) or 90
end

function MissionIntro.RXSendGetAlphaWarheadDetonationDelay()
	return tonumber(MissionIntro.RXSendAlphaWarheadDetonationDelay)
		or tonumber(MissionIntro.RXSendAlphaWarheadAlertDurationFallback)
		or 90
end

function MissionIntro.RXSendGetAlphaWarheadTriggerDelay()
	return MissionIntro.RXSendGetRoundEndEventDelay(MissionIntro.RXSendAlphaWarheadSecondsBeforeEnd or 131)
end

function MissionIntro.RXSendBroadcastAlphaWarhead()
	if not MissionIntro.BroadcastCustomAlert then return false end

	local title = MissionIntro.L and MissionIntro.L("rxsend_alpha_warhead_broadcast_title") or "系统广播"
	local line1 = MissionIntro.L and MissionIntro.L("rxsend_alpha_warhead_broadcast_line1")
		or "警告！阿尔法核弹头引爆程序已启动"

	MissionIntro.BroadcastCustomAlert({
		title = title,
		line1 = line1,
		line2 = "",
		accent = Color(255, 96, 32),
	}, {
		playSound = false,
		forceSoundDuringIntro = true,
	})

	if MissionIntro.RXSendAlphaWarheadPlayAlertSound == true then
		local alertSound = MissionIntro.RXSendAlphaWarheadAlertSound or "mission_intro/rxsend_alpha_warhead_start.mp3"
		if MissionIntro.BroadcastSoundToAll then
			MissionIntro.BroadcastSoundToAll(alertSound, { forceSoundDuringIntro = true })
		end
	end

	return true
end

function MissionIntro.RXSendGetAlphaWarheadFinalWarningDelay()
	return MissionIntro.RXSendGetRoundEndEventDelay(MissionIntro.RXSendAlphaWarheadFinalWarningSecondsBeforeEnd or 34)
end

function MissionIntro.RXSendBroadcastAlphaWarheadFinalWarning()
	if not MissionIntro.BroadcastCustomAlert then return false end

	local title = MissionIntro.L and MissionIntro.L("rxsend_alpha_warhead_final_broadcast_title") or "设施广播"
	local line1 = MissionIntro.L and MissionIntro.L("rxsend_alpha_warhead_final_broadcast_line1")
		or "警告！阿尔法核弹头将在30秒后引爆"
	local line2 = MissionIntro.L and MissionIntro.L("rxsend_alpha_warhead_final_broadcast_line2")
		or "所有人员立刻撤离！"

	MissionIntro.BroadcastCustomAlert({
		title = title,
		line1 = line1,
		line2 = line2,
		accent = Color(255, 48, 48),
	}, {
		playSound = false,
		forceSoundDuringIntro = true,
	})

	if MissionIntro.RXSendAlphaWarheadPlayFinalWarningSound == true then
		local warnSound = MissionIntro.RXSendAlphaWarheadFinalWarningSound
			or "mission_intro/rxsend_alpha_warhead_final_warning.mp3"
		if MissionIntro.BroadcastSoundToAll then
			MissionIntro.BroadcastSoundToAll(warnSound, { forceSoundDuringIntro = true })
		end
	end

	return true
end

function MissionIntro.RXSendTriggerAlphaWarheadFinalWarning()
	if zb.CROUND ~= "rxsend" then return false end
	if MissionIntro._rxSendAlphaWarheadFinalWarningTriggered then return false end

	MissionIntro._rxSendAlphaWarheadFinalWarningTriggered = true
	MissionIntro.RXSendBroadcastAlphaWarheadFinalWarning()
	MsgN("[MissionIntro] RXsend 阿尔法弹头最终撤离警告已触发")
	return true
end

function MissionIntro.RXSendScheduleAlphaWarheadFinalWarning(opts)
	opts = opts or {}
	if MissionIntro._rxSendRoundEndHandled then return false end
	if MissionIntro._rxSendAlphaWarheadFinalWarningTriggered then return false end

	timer.Remove(RXSEND_ALPHA_FINAL_TIMER)

	if zb.CROUND ~= "rxsend" then return false end

	local delay = MissionIntro.RXSendGetAlphaWarheadFinalWarningDelay()
	if not delay then return false end

	timer.Create(RXSEND_ALPHA_FINAL_TIMER, delay, 1, function()
		if zb.CROUND ~= "rxsend" then return end
		MissionIntro.RXSendTriggerAlphaWarheadFinalWarning()
	end)

	MsgN("[MissionIntro] RXsend 阿尔法弹头最终撤离警告已排程，", delay, " 秒后触发")
	return true
end

function MissionIntro.RXSendScheduleAlphaWarheadDetonation(delay)
	timer.Remove(RXSEND_ALPHA_DETONATE_TIMER)
	delay = math.max(0.5, tonumber(delay) or 0)

	local remaining = MissionIntro.RXSendGetRoundTimeRemaining and MissionIntro.RXSendGetRoundTimeRemaining()
	if isnumber(remaining) and remaining > 0 then
		delay = math.min(delay, math.max(0.5, remaining - 0.25))
	end

	timer.Create(RXSEND_ALPHA_DETONATE_TIMER, delay, 1, function()
		if zb.CROUND ~= "rxsend" then return end
		MissionIntro.RXSendExecuteAlphaWarheadDetonation()
	end)
end

function MissionIntro.RXSendTriggerAlphaWarheadSequence()
	if zb.CROUND ~= "rxsend" then return false end
	if MissionIntro._rxSendAlphaWarheadTriggered then return false end

	MissionIntro._rxSendAlphaWarheadTriggered = true
	MissionIntro.RXSendBroadcastAlphaWarhead()

	local duration = MissionIntro.RXSendGetAlphaWarheadDetonationDelay()
	MissionIntro.RXSendScheduleAlphaWarheadDetonation(duration)
	MsgN("[MissionIntro] RXsend 阿尔法弹头弹窗已触发，", duration, " 秒后处死")
	return true
end

function MissionIntro.RXSendScheduleAlphaWarheadSequence(opts)
	opts = opts or {}
	if MissionIntro._rxSendRoundEndHandled then return false end
	if MissionIntro._rxSendAlphaWarheadTriggered and opts.reschedule then return false end

	MissionIntro.RXSendCancelAlphaWarheadSchedule()

	if zb.CROUND ~= "rxsend" then return false end
	if MissionIntro._rxSendAlphaWarheadTriggered then return false end

	local delay = MissionIntro.RXSendGetAlphaWarheadTriggerDelay()
	if not delay then return false end
	timer.Create(RXSEND_ALPHA_TIMER, delay, 1, function()
		if zb.CROUND ~= "rxsend" then return end
		MissionIntro.RXSendTriggerAlphaWarheadSequence()
	end)

	MsgN("[MissionIntro] RXsend 阿尔法弹头广播已排程，", delay, " 秒后触发")
	return true
end

hook.Add("Think", "MissionIntro_RXSendRoundTimeoutKill", function()
	if not MissionIntro.RXSendIsActive or not MissionIntro.RXSendIsActive() then return end
	if not zb or zb.ROUND_STATE ~= 1 then return end
	if MissionIntro._rxSendRoundEndHandled then return end

	local remaining = MissionIntro.RXSendGetRoundTimeRemaining and MissionIntro.RXSendGetRoundTimeRemaining()
	if remaining == nil or remaining > 0 then return end

	MissionIntro.RXSendExecuteAlphaWarheadDetonation()
end)

hook.Add("ZB_EndRound", "MissionIntro_RXSendRoundEndEvents", function()
	if not zb or zb.CROUND ~= "rxsend" then return end

	if MissionIntro.RXSendResetRoundEndFlags then
		MissionIntro.RXSendResetRoundEndFlags()
	end
	if MissionIntro.ResetScarletRitualState then
		MissionIntro.ResetScarletRitualState()
	end

	if not MissionIntro._rxSendRoundEndHandled and MissionIntro.RXSendExecuteAlphaWarheadDetonation then
		MissionIntro.RXSendExecuteAlphaWarheadDetonation()
	end

	if MissionIntro.RXSendCancelRoundEndSchedules then
		MissionIntro.RXSendCancelRoundEndSchedules()
	end
end)

hook.Add("ZB_StartRound", "MissionIntro_RXSendRoundPauseReset", function()
	if not zb or zb.CROUND ~= "rxsend" then return end
	if MissionIntro.RXSendResetRoundPause then
		MissionIntro.RXSendResetRoundPause()
	end
end)

hook.Add("ZB_PreRoundStart", "MissionIntro_RXSendRoundTime", function()
	local nextRound = zb and (zb.nextround or zb.CROUND) or ""
	if nextRound ~= "rxsend" then return end

	if MissionIntro.RXSendResetRoundEndFlags then
		MissionIntro.RXSendResetRoundEndFlags()
	end

	local roundTime = MissionIntro.RXSendGetConfiguredRoundTime()
	MissionIntro.RXSendApplyRoundTimeToMode(roundTime)
end)

hook.Add("Initialize", "MissionIntro_RXSendRoundTimeInit", function()
	timer.Simple(0, function()
		if MissionIntro.RXSendApplyRoundTimeToMode and MissionIntro.RXSendGetConfiguredRoundTime then
			MissionIntro.RXSendApplyRoundTimeToMode(MissionIntro.RXSendGetConfiguredRoundTime())
		end
	end)
end)

concommand.Add("rxsend_round_time", function(ply, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end

	local arg = args and args[1] or ""
	if arg == "" then
		local configured = MissionIntro.RXSendGetConfiguredRoundTime()
		local msg = configured <= 0
			and "[RXsend] 回合时间: 无限制"
			or ("[RXsend] 回合时间: " .. RXSEND_FormatTime(configured) .. " (" .. configured .. " 秒)")
		local remaining = MissionIntro.RXSendGetRoundTimeRemaining()
		if remaining ~= nil then
			msg = msg .. " | 本局剩余: " .. RXSEND_FormatTime(remaining)
		end
		RXSEND_Notify(ply, msg)
		return
	end

	local seconds = RXSEND_ParseTimeArg(arg)
	if not seconds then
		RXSEND_Notify(ply, "[RXsend] 用法: rxsend_round_time [秒数 | mm:ss]  （范围 " .. RXSEND_ROUND_TIME_MIN .. "–" .. RXSEND_ROUND_TIME_MAX .. "）")
		return
	end

	local ok = MissionIntro.RXSendSetRoundTime(seconds)
	if not ok then
		RXSEND_Notify(ply, "[RXsend] 无效时长，请输入 " .. RXSEND_ROUND_TIME_MIN .. "–" .. RXSEND_ROUND_TIME_MAX .. " 秒，或 mm:ss 格式。")
		return
	end

	local msg = "[RXsend] 回合时间已设为 " .. RXSEND_FormatTime(seconds) .. " (" .. seconds .. " 秒)"
	if zb and zb.CROUND == "rxsend" then
		msg = msg .. "，本局已同步"
	end
	RXSEND_Notify(ply, msg)
end)
