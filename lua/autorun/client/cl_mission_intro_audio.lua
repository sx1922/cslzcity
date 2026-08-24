MissionIntro = MissionIntro or {}

MissionIntro._introChan = MissionIntro._introChan or nil

function MissionIntro.StopIntroAudio()
	if IsValid(MissionIntro._introChan) then
		MissionIntro._introChan:Stop()
	end
	MissionIntro._introChan = nil
	hook.Remove("Think", "MissionIntro_AudioEnd")
end

function MissionIntro.StopAudio(st)
	if st and IsValid(st.introChan) and st.introChan ~= MissionIntro._introChan then
		st.introChan:Stop()
		st.introChan = nil
	end
	if st and IsValid(st.bgm) then
		st.bgm:Stop()
		st.bgm = nil
	end
end

local function MI_ResolveTrackPath(ply, factionIdOverride)
	ply = ply or LocalPlayer()
	local path
	if MissionIntro.GetIntroTrack then
		path = MissionIntro.GetIntroTrack(ply, factionIdOverride)
	end
	if not path or path == "" then
		path = MissionIntro.Sounds and MissionIntro.Sounds.intro_track
	end
	if not path or path == "" then return nil end

	local candidates = { path }
	if path:sub(-4) == ".mp3" then
		candidates[#candidates + 1] = string.gsub(path, "%.mp3$", ".ogg")
		candidates[#candidates + 1] = string.gsub(path, "%.mp3$", ".wav")
	elseif path:sub(-4) == ".ogg" then
		candidates[#candidates + 1] = string.gsub(path, "%.ogg$", ".mp3")
		candidates[#candidates + 1] = string.gsub(path, "%.ogg$", ".wav")
	end

	for _, p in ipairs(candidates) do
		if file.Exists("sound/" .. p, "GAME") then
			return p
		end
	end

	return path
end

local function MI_IsChannelPlaying(chan)
	if not IsValid(chan) then return false end
	if chan.IsPlaying then
		return chan:IsPlaying()
	end
	local len = chan:GetLength() or 0
	if len <= 0 then return true end
	return (chan:GetTime() or 0) < (len - 0.05)
end

function MissionIntro.WatchIntroAudioEnd()
	hook.Add("Think", "MissionIntro_AudioEnd", function()
		local chan = MissionIntro._introChan
		if not IsValid(chan) then
			MissionIntro._introChan = nil
			hook.Remove("Think", "MissionIntro_AudioEnd")
			return
		end
		if not MI_IsChannelPlaying(chan) then
			MissionIntro._introChan = nil
			hook.Remove("Think", "MissionIntro_AudioEnd")
		end
	end)
end

function MissionIntro.HandoffIntroAudio(st)
	if not st or not IsValid(st.introChan) then return end
	MissionIntro._introChan = st.introChan
	st.introChan = nil
	MissionIntro.WatchIntroAudioEnd()
end

function MissionIntro.PlayIntroTrack(st, vol)
	local ply = (st and st.ply) or LocalPlayer()
	if MissionIntro.ShouldSkipIntroAudio and MissionIntro.ShouldSkipIntroAudio(ply) then
		return
	end
	local path = MI_ResolveTrackPath(ply, st and st.factionId)
	if not path then return end

	MissionIntro.StopIntroAudio()

	sound.PlayFile("sound/" .. path, "noplay", function(chan, err)
		if not IsValid(chan) then
			if err then
				MsgC(Color(255, 120, 120), "[MissionIntro] 音轨加载失败: ", tostring(err), " (", path, ")\n")
			end
			return
		end

		chan:SetVolume(vol or MissionIntro.IntroVolume or 0.9)
		chan:Play()
		MissionIntro._introChan = chan
		if st then st.introChan = chan end
		MissionIntro.WatchIntroAudioEnd()
	end)
end

function MissionIntro.PlayTypeClick()
	if MissionIntro.UseTypeSound == false then return end

	local paths = MissionIntro.TypeSoundPaths or {
		"buttons/button14.wav",
		"buttons/button15.wav",
	}

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	for _, p in ipairs(paths) do
		if file.Exists("sound/" .. p, "GAME") then
			ply:EmitSound(p, 75, math.random(98, 108), 0.12)
			return
		end
	end
end

function MissionIntro.TickTypeSound(line)
	if not line or line.done then return end
	local chars = line.chars or 0
	if chars <= (line._lastTypeSnd or 0) then return end

	local step = 2
	if MissionIntro.Active and MissionIntro.Active.useLightDraw then
		step = MissionIntro.FacilityTypeSoundStep or 1
	end

	if chars - (line._lastTypeSnd or 0) >= step then
		line._lastTypeSnd = chars
		MissionIntro.PlayTypeClick()
	end
end
