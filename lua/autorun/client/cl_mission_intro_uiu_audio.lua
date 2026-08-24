if not CLIENT then return end

MissionIntro._uiuHackStartChan = MissionIntro._uiuHackStartChan or nil
MissionIntro._uiuHackCompleteChan = MissionIntro._uiuHackCompleteChan or nil
MissionIntro._uiuHackUseChan = MissionIntro._uiuHackUseChan or nil
MissionIntro._uiuHackPlayGen = MissionIntro._uiuHackPlayGen or 0
MissionIntro._aaClosingHackPlayGen = MissionIntro._aaClosingHackPlayGen or 0

local UIU_SOUND_PATHS = {
	"mission_intro/uiu_hack_start.mp3",
	"mission_intro/uiu_hack_complete.mp3",
	"mission_intro/uiu_hack_use.mp3",
}

local function MI_ResolveSoundPath(cfgKey, fallback)
	local cfg = MissionIntro.UiuComputer or {}
	local path = cfg[cfgKey] or fallback
	if not isstring(path) or path == "" then return nil end

	local candidates = { path }
	if path:sub(-4) == ".mp3" then
		candidates[#candidates + 1] = string.gsub(path, "%.mp3$", ".ogg")
		candidates[#candidates + 1] = string.gsub(path, "%.mp3$", ".wav")
	end

	for _, p in ipairs(candidates) do
		if file.Exists("sound/" .. p, "GAME") then
			return p
		end
	end

	return path
end

local function MI_IsAaClosingActive()
	if MissionIntro._aaClosingInProgress == true then return true end
	local eta = tonumber(MissionIntro._aaCiSpawnEta) or 0
	return eta > CurTime()
end

local function MI_PlayUseEmitFallback(path)
	local ply = LocalPlayer()
	if not IsValid(ply) or not isstring(path) or path == "" then return end
	local level = tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_use_level) or 85
	ply:StopSound(path)
	ply:EmitSound(path, level, 100, 1, CHAN_AUTO)
end

local function MI_StopChannel(chan)
	if chan == nil then return end
	pcall(function()
		chan:Stop()
	end)
end

local function MI_StopSoundPaths(force)
	if not force then
		local untilT = tonumber(MissionIntro._aaUiuSoundLockUntil) or 0
		if CurTime() < untilT then return end
	end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	for _, path in ipairs(UIU_SOUND_PATHS) do
		ply:StopSound(path)
		ply:StopSound("sound/" .. path)
	end
end

local function MI_ClearAaHackUseWatch()
	local timerName = MissionIntro._aaHackUseWatchTimer
	if isstring(timerName) then
		timer.Remove(timerName)
	end
	MissionIntro._aaHackUseWatchTimer = nil
	MissionIntro._aaHackUsePlaysRemaining = 0
end

function MissionIntro.ForceStopUiuHackSounds()
	MissionIntro._aaUiuSoundLockUntil = 0
	MissionIntro._uiuHackPlayGen = (MissionIntro._uiuHackPlayGen or 0) + 1
	MissionIntro._aaClosingHackPlayGen = (MissionIntro._aaClosingHackPlayGen or 0) + 1
	MI_ClearAaHackUseWatch()
	MI_StopChannel(MissionIntro._uiuHackStartChan)
	MI_StopChannel(MissionIntro._uiuHackCompleteChan)
	MI_StopChannel(MissionIntro._uiuHackUseChan)
	MissionIntro._uiuHackStartChan = nil
	MissionIntro._uiuHackCompleteChan = nil
	MissionIntro._uiuHackUseChan = nil
	MI_StopSoundPaths(true)
end

function MissionIntro.StopUiuHackStartSound()
	local untilT = tonumber(MissionIntro._aaUiuSoundLockUntil) or 0
	if CurTime() < untilT then return end
	local chan = MissionIntro._uiuHackStartChan
	MissionIntro._uiuHackStartChan = nil
	MI_StopChannel(chan)
end

function MissionIntro.StopUiuHackCompleteSound()
	local untilT = tonumber(MissionIntro._aaUiuSoundLockUntil) or 0
	if CurTime() < untilT then return end
	local chan = MissionIntro._uiuHackCompleteChan
	MissionIntro._uiuHackCompleteChan = nil
	MI_StopChannel(chan)
end

function MissionIntro.StopUiuHackUseSound()
	local untilT = tonumber(MissionIntro._aaUiuSoundLockUntil) or 0
	if CurTime() < untilT then return end
	local chan = MissionIntro._uiuHackUseChan
	MissionIntro._uiuHackUseChan = nil
	MI_StopChannel(chan)
end

function MissionIntro.StopAllUiuHackSounds()
	local untilT = tonumber(MissionIntro._aaUiuSoundLockUntil) or 0
	if CurTime() < untilT then return end
	MissionIntro.StopUiuHackStartSound()
	MissionIntro.StopUiuHackCompleteSound()
	MissionIntro.StopUiuHackUseSound()
	MI_StopSoundPaths(false)
end

local function MI_PlaySoundToEnd(pathKey, fallback, storeKey)
	local path = MI_ResolveSoundPath(pathKey, fallback)
	if not path then return end

	MissionIntro._uiuHackPlayGen = (MissionIntro._uiuHackPlayGen or 0) + 1
	local playId = MissionIntro._uiuHackPlayGen

	local vol = tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_volume) or 1

	sound.PlayFile("sound/" .. path, "noplay", function(chan, err)
		if playId ~= MissionIntro._uiuHackPlayGen then
			if IsValid(chan) then
				chan:Stop()
			end
			return
		end

		if not IsValid(chan) then
			if err then
				MsgN("[MissionIntro] UIU 音效失败: " .. tostring(err))
			end
			MI_PlayUseEmitFallback(path)
			return
		end

		if storeKey == "start" then
			MissionIntro._uiuHackStartChan = chan
		elseif storeKey == "use" then
			MissionIntro._uiuHackUseChan = chan
		else
			MissionIntro._uiuHackCompleteChan = chan
		end

		chan:SetVolume(vol)
		chan:Play()
	end)
end

function MissionIntro.PlayUiuHackStartSound()
	MissionIntro.StopUiuHackCompleteSound()
	MissionIntro.StopUiuHackUseSound()
	MI_PlaySoundToEnd("sound_hack_start", "mission_intro/uiu_hack_start.mp3", "start")
end

function MissionIntro.PlayUiuHackCompleteSound()
	MissionIntro.StopUiuHackStartSound()
	MissionIntro.StopUiuHackUseSound()
	MI_PlaySoundToEnd("sound_hack_complete", "mission_intro/uiu_hack_complete.mp3", "complete")
end

function MissionIntro.PlayUiuHackUseSound()
	MissionIntro.StopUiuHackStartSound()
	MissionIntro.StopUiuHackCompleteSound()
	MI_ClearAaHackUseWatch()
	MI_PlaySoundToEnd("sound_hack_use", "mission_intro/uiu_hack_use.mp3", "use")
end

local function MI_ScheduleAaUseEnded(playId, chan, path, onEnded)
	local duration = 3

	if IsValid(chan) and chan.GetLength then
		local len = chan:GetLength()
		if len and len > 0 then
			duration = len
		end
	end

	local timerName = "MissionIntro_AaHackUseEnd_" .. playId .. "_" .. CurTime()
	MissionIntro._aaHackUseWatchTimer = timerName

	timer.Simple(duration, function()
		if playId ~= MissionIntro._aaClosingHackPlayGen then return end
		if MissionIntro._aaHackUseWatchTimer == timerName then
			MissionIntro._aaHackUseWatchTimer = nil
		end
		MissionIntro._uiuHackUseChan = nil
		if onEnded then onEnded() end
	end)
end

local function MI_PlayAaHackUseOnce(playId, onEnded)
	local path = MI_ResolveSoundPath("sound_hack_use", "mission_intro/uiu_hack_use.mp3")
	if not path then
		if onEnded then onEnded() end
		return
	end

	local vol = tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_volume) or 1

	sound.PlayFile("sound/" .. path, "noplay", function(chan, err)
		if playId ~= MissionIntro._aaClosingHackPlayGen then
			if IsValid(chan) then
				chan:Stop()
			end
			return
		end

		if not IsValid(chan) then
			if err then
				MsgN("[MissionIntro] UIU 音效失败: " .. tostring(err))
			end
			MI_PlayUseEmitFallback(path)
			if onEnded then
				timer.Simple(3, function()
					if playId ~= MissionIntro._aaClosingHackPlayGen then return end
					onEnded()
				end)
			end
			return
		end

		MissionIntro._uiuHackUseChan = chan
		chan:SetVolume(vol)
		chan:Play()

		MI_ScheduleAaUseEnded(playId, chan, path, onEnded)
	end)
end

function MissionIntro.PlayAaClosingHackUseSound()
	MissionIntro.StopUiuHackStartSound()
	MissionIntro.StopUiuHackCompleteSound()
	MI_ClearAaHackUseWatch()

	MissionIntro._aaClosingHackPlayGen = (MissionIntro._aaClosingHackPlayGen or 0) + 1
	local playId = MissionIntro._aaClosingHackPlayGen
	MissionIntro._aaHackUsePlaysRemaining = 2

	local function playNext()
		if playId ~= MissionIntro._aaClosingHackPlayGen then return end
		if (MissionIntro._aaHackUsePlaysRemaining or 0) <= 0 then return end

		MissionIntro._aaHackUsePlaysRemaining = MissionIntro._aaHackUsePlaysRemaining - 1

		MI_PlayAaHackUseOnce(playId, function()
			if playId ~= MissionIntro._aaClosingHackPlayGen then return end
			if not MI_IsAaClosingActive() then return end
			if (MissionIntro._aaHackUsePlaysRemaining or 0) > 0 then
				playNext()
			end
		end)
	end

	playNext()
end

net.Receive("MissionIntro_UiuHackAudio", function()
	local action = net.ReadUInt(3)

	if action == 1 then
		local lockFor = 45
		local eta = tonumber(MissionIntro._aaCiSpawnEta) or 0
		if MissionIntro._aaClosingInProgress and eta > CurTime() then
			lockFor = (eta - CurTime()) + 10
		end
		MissionIntro._aaUiuSoundLockUntil = math.max(tonumber(MissionIntro._aaUiuSoundLockUntil) or 0, CurTime() + lockFor)
		MissionIntro.PlayUiuHackStartSound()
	elseif action == 2 then
		MissionIntro.PlayUiuHackCompleteSound()
	elseif action == 4 then
		local lockFor = 45
		local eta = tonumber(MissionIntro._aaCiSpawnEta) or 0
		if MissionIntro._aaClosingInProgress and eta > CurTime() then
			lockFor = (eta - CurTime()) + 10
		end
		MissionIntro._aaUiuSoundLockUntil = math.max(tonumber(MissionIntro._aaUiuSoundLockUntil) or 0, CurTime() + lockFor)
		if MissionIntro.PlayAaClosingHackUseSound then
			MissionIntro.PlayAaClosingHackUseSound()
		else
			MissionIntro.PlayUiuHackUseSound()
		end
	elseif action == 3 then
		MissionIntro.ForceStopUiuHackSounds()
	end
end)

hook.Add("ShutDown", "MissionIntro_UiuAudioStop", function()
	MissionIntro.ForceStopUiuHackSounds()
end)

local MI_ClientAudioRoundHooks = {
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
}

for _, hookName in ipairs(MI_ClientAudioRoundHooks) do
	hook.Add(hookName, "MissionIntro_UiuAudioStop", function()
		MissionIntro.ForceStopUiuHackSounds()
	end)
end
