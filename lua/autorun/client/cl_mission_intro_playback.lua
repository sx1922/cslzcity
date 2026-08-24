MissionIntro = MissionIntro or {}
MissionIntro.Active = MissionIntro.Active or nil
MissionIntro._introChan = MissionIntro._introChan or nil

if not MissionIntro.StopIntroAudio then
	function MissionIntro.StopIntroAudio()
		if IsValid(MissionIntro._introChan) then
			MissionIntro._introChan:Stop()
		end
		MissionIntro._introChan = nil
		hook.Remove("Think", "MissionIntro_AudioEnd")
	end
end

if not MissionIntro.WatchIntroAudioEnd then
	local function MI_IsChannelPlaying(chan)
		if not IsValid(chan) then return false end
		if chan.IsPlaying then return chan:IsPlaying() end
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
end

if not MissionIntro.HandoffIntroAudio then
	function MissionIntro.HandoffIntroAudio(st)
		if not st or not IsValid(st.introChan) then return end
		MissionIntro._introChan = st.introChan
		st.introChan = nil
		MissionIntro.WatchIntroAudioEnd()
	end
end

function MissionIntro.IsPlaying(ply)
	ply = ply or LocalPlayer()
	local st = MissionIntro.Active
	return st and st.ply == ply and not st.done
end

function MissionIntro.StopHUD()
	MissionIntro.Active = nil
	timer.Remove("MissionIntro_FacilityGalleryEnd")
	timer.Remove("MissionIntro_SecurityGalleryEnd")
	if MissionIntro.StopFacilityGallery then
		MissionIntro.StopFacilityGallery()
	elseif MissionIntro.StopFacilitySecurityGallery then
		MissionIntro.StopFacilitySecurityGallery()
	end
	if MissionIntro.DestroyEmblemImage then
		MissionIntro.DestroyEmblemImage()
	end
	MissionIntro._lastEmblemPath = nil
	hook.Remove("HUDPaint", "MissionIntro_Draw")
	hook.Remove("CreateMove", "MissionIntro_BlockMove")
	hook.Remove("PlayerBindPress", "MissionIntro_BlockBinds")
	hook.Remove("HUDShouldDraw", "MissionIntro_HideHUD")
end

function MissionIntro.StopLocal(stopAudio)
	if stopAudio then
		local st = MissionIntro.Active
		if st then
			MissionIntro.StopAudio(st)
		end
		MissionIntro.StopIntroAudio()
	end
	MissionIntro.StopHUD()
end

local function MI_CleanupHooks()
	MissionIntro.StopLocal(true)
end

local function MI_NewState(ent, forcedFactionId)
	if MissionIntro.DestroyEmblemImage then
		MissionIntro.DestroyEmblemImage()
	end

	local ply = LocalPlayer()
	if IsValid(ply) and isstring(forcedFactionId) and forcedFactionId ~= "" then
		ply._missionIntroFaction = forcedFactionId
	end

	local timeline = {}
	if MissionIntro.ShouldUseFacilityPhase3Intro and MissionIntro.ShouldUseFacilityPhase3Intro(LocalPlayer()) then
		if MissionIntro.BuildFacilityPhase3Timeline then
			timeline = MissionIntro.BuildFacilityPhase3Timeline(LocalPlayer()) or {}
		end
	elseif MissionIntro.BuildTimeline then
		timeline = MissionIntro.BuildTimeline(LocalPlayer()) or {}
	end
	table.sort(timeline, function(a, b)
		return (a.t or 0) < (b.t or 0)
	end)

	local ply = LocalPlayer()
	local factionId = isstring(forcedFactionId) and forcedFactionId or ""
	if factionId == "" then
		factionId = ply:GetNWString("MissionIntro_FactionId", "")
	end
	if factionId == "" and isstring(ply._missionIntroFaction) then
		factionId = ply._missionIntroFaction
	end
	if factionId == "" and MissionIntro.GetFactionId then
		factionId = MissionIntro.GetFactionId(ply) or MissionIntro.DefaultFaction
	end

	return {
		ent = ent,
		ply = ply,
		factionId = factionId,
		start = CurTime(),
		timeline = timeline,
		idx = 1,
		phase = 1,
		fade = 0,
		iconAlpha = 0,
		redLines = {},
		introLines = {},
		showDivider = false,
		introChan = nil,
		unlocked = false,
		hudAlpha = 255,
		done = false,
	}
end

local function MI_GetRedLine(st, index)
	for _, ln in ipairs(st.redLines) do
		if ln.index == index then return ln end
	end
	local ln = { index = index, text = "", chars = 0, active = false, speed = 20, done = false }
	st.redLines[#st.redLines + 1] = ln
	return ln
end

local function MI_GetIntroLine(st, index, text)
	for _, ln in ipairs(st.introLines) do
		if ln.index == index then return ln end
	end
	local ln = { index = index, text = text or "", chars = 0, started = false, speed = 20, done = false }
	st.introLines[#st.introLines + 1] = ln
	return ln
end

local function MI_TickTyping(line)
	if line.done then return end
	if not line.started then
		line.started = true
		line.startedAt = CurTime()
	end
	local maxC = utf8.len(line.text) or #line.text
	line.chars = math.min(maxC, math.floor((CurTime() - (line.startedAt or CurTime())) * (line.speed or 20)))
	if line.chars >= maxC then
		line.done = true
	end
	MissionIntro.TickTypeSound(line)
end

local function MI_UnlockPlayer(st)
	if st.unlocked then return end
	st.unlocked = true
	hook.Remove("CreateMove", "MissionIntro_BlockMove")
	hook.Remove("PlayerBindPress", "MissionIntro_BlockBinds")

	if IsValid(st.ent) then
		net.Start("MissionIntro_Unlock")
			net.WriteEntity(st.ent)
		net.SendToServer()
	end
end

local function MI_Finish(st, notifyServer, stopAudio)
	if not st or st.finished then return end
	st.finished = true
	st.done = true

	if stopAudio then
		MissionIntro.StopAudio(st)
		MissionIntro.StopIntroAudio()
	else
		MissionIntro.HandoffIntroAudio(st)
	end

	MissionIntro.StopHUD()

	if notifyServer then
		net.Start("MissionIntro_Finished")
		if IsValid(st.ent) then
			net.WriteEntity(st.ent)
		else
			net.WriteEntity(Entity(0))
		end
		net.SendToServer()
	end
end

local function MI_AdvanceEvents(st)
	local elapsed = math.max(0, CurTime() - st.start)

	while st.idx <= #st.timeline do
		local ev = st.timeline[st.idx]
		if (ev.t or 0) > elapsed then break end

		if ev.type == "intro_audio" then
			MissionIntro.PlayIntroTrack(st, ev.volume)
		elseif ev.type == "phase" then
			st.phase = ev.phase or st.phase
		elseif ev.type == "icon" then
			st.iconAlpha = 0
			st.iconFadeTarget = 255
			st.iconFadeStart = CurTime()
			st.iconFadeDur = ev.dur or 0.5
		elseif ev.type == "red_line" then
			local ln = MI_GetRedLine(st, ev.index or 1)
			ln.text = ev.text or ""
			ln.speed = ev.speed or 20
			ln.chars = 0
			ln.active = true
			ln.done = false
			ln.started = false
			ln._lastTypeSnd = 0
		elseif ev.type == "clear_red" then
			st.redLines = {}
		elseif ev.type == "divider" then
			st.showDivider = ev.show ~= false
		elseif ev.type == "intro_line" then
			if isstring(ev.text) and ev.text ~= "" then
				local ln = MI_GetIntroLine(st, ev.index or 1, ev.text)
				ln.text = ev.text
				ln.speed = ev.speed or 20
				ln.chars = 0
				ln.started = false
				ln.done = false
				ln._lastTypeSnd = 0
			end
		elseif ev.type == "player_unlock" then
			MI_UnlockPlayer(st)
		elseif ev.type == "fade" then
			st.fadeTarget = ev.alpha or 0
			st.fadeDur = ev.dur or 1
			st.fadeStart = CurTime()
			st.fadeFrom = st.fade
		elseif ev.type == "hud_alpha" then
			st.hudAlpha = ev.alpha or 255
		elseif ev.type == "hud_fade" then
			st.hudFadeTarget = ev.alpha or 0
			st.hudFadeDur = ev.dur or 2
			st.hudFadeStart = CurTime()
			st.hudFadeFrom = st.hudAlpha or 255
		elseif ev.type == "end" then
			st.reachedEnd = true
		end

		st.idx = st.idx + 1
	end

	if st.iconFadeStart then
		local ft = math.Clamp((CurTime() - st.iconFadeStart) / (st.iconFadeDur or 0.5), 0, 1)
		st.iconAlpha = Lerp(ft, 0, st.iconFadeTarget or 255)
		if ft >= 1 then st.iconFadeStart = nil end
	end

	if st.fadeStart then
		local ft = math.Clamp((CurTime() - st.fadeStart) / (st.fadeDur or 1), 0, 1)
		st.fade = Lerp(ft, st.fadeFrom or 0, st.fadeTarget or 0)
		if ft >= 1 then st.fadeStart = nil end
	end

	if st.hudFadeStart then
		local ft = math.Clamp((CurTime() - st.hudFadeStart) / (st.hudFadeDur or 2), 0, 1)
		st.hudAlpha = Lerp(ft, st.hudFadeFrom or 255, st.hudFadeTarget or 0)
		if ft >= 1 then st.hudFadeStart = nil end
	end

	for _, ln in ipairs(st.redLines) do
		if ln.active and not ln.done then MI_TickTyping(ln) end
	end

	for _, ln in ipairs(st.introLines) do
		if not ln.done then MI_TickTyping(ln) end
	end
end

hook.Add("Think", "MissionIntro_Advance", function()
	local st = MissionIntro.Active
	if not st or st.finished then return end

	MI_AdvanceEvents(st)

	local total = MissionIntro.TotalDuration or 24
	if st.reachedEnd or (CurTime() - st.start) >= total then
		MI_Finish(st, true, false)
	end
end)

local function MI_Draw()
	local st = MissionIntro.Active
	if not st or st.finished then return end

	local ok, err = pcall(MissionIntro.DrawFrame, st, st.hudAlpha or 255)
	if not ok then
		MsgC(Color(255, 80, 80), "[MissionIntro] 绘制错误: ", tostring(err), "\n")
		MI_Finish(st, true, false)
	end
end

hook.Add("PlayerBindPress", "MissionIntro_BlockBinds", function(cmd)
	local st = MissionIntro.Active
	if not st or st.done or st.unlocked then return end
	if cmd == "+attack" or cmd == "+attack2" or cmd == "+jump" or cmd == "+duck" then return true end
end)

hook.Add("CreateMove", "MissionIntro_BlockMove", function(cmd)
	local st = MissionIntro.Active
	if not st or st.done or st.unlocked then return end
	cmd:ClearButtons()
	cmd:ClearMovement()
end)

hook.Add("HUDShouldDraw", "MissionIntro_HideHUD", function(name)
	local st = MissionIntro.Active
	if not st or st.done or st.unlocked then return end
	if not MissionIntro.HideHUDUntilUnlock then return end
	if name == "CHudChat" then return end
	return false
end)

hook.Add("Think", "MissionIntro_Failsafe", function()
	local st = MissionIntro.Active
	if not st then return end
	local limit = (MissionIntro.TotalDuration or 24) + 8
	if (CurTime() - st.start) > limit then
		MI_Finish(st, true, false)
	end
end)

net.Receive("MissionIntro_Start", function()
	local hasEnt = net.ReadBool()
	local ent = hasEnt and net.ReadEntity() or nil
	net.ReadFloat()
	local factionId = net.ReadString() or ""
	local scarletRole = net.ReadString() or ""
	local hammerfallRole = net.ReadString() or ""
	local sidRole = net.ReadString() or ""
	local pttrbRole = net.ReadString() or ""

	local ply = LocalPlayer()
	if IsValid(ply) then
		if factionId ~= "" then
			ply._missionIntroFaction = factionId
		else
			ply._missionIntroFaction = nil
		end

		if MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId) then
			if MissionIntro.GetFacilityRoleKeyFromFaction then
				local roleKey = MissionIntro.GetFacilityRoleKeyFromFaction(factionId)
				if roleKey then
					ply._missionIntroFacilityRole = roleKey
				end
			end
			if MissionIntro.ClearScarletRole then MissionIntro.ClearScarletRole(ply) end
			if MissionIntro.ClearHammerfallRole then MissionIntro.ClearHammerfallRole(ply) end
			if MissionIntro.ClearSidRole then MissionIntro.ClearSidRole(ply) end
			if MissionIntro.ClearUiuTfRole then MissionIntro.ClearUiuTfRole(ply) end
			if MissionIntro.ClearMcdRole then MissionIntro.ClearMcdRole(ply) end
			if MissionIntro.ClearCiRole then MissionIntro.ClearCiRole(ply) end
		elseif factionId == "scarlet_cultist" and scarletRole ~= "" and MissionIntro.AssignScarletRole then
			MissionIntro.AssignScarletRole(ply, scarletRole)
		elseif MissionIntro.ClearScarletRole then
			MissionIntro.ClearScarletRole(ply)
		end

		if factionId == "hammerfall_squad" and hammerfallRole ~= "" and MissionIntro.AssignHammerfallRole then
			if MissionIntro.ClearCiRole then MissionIntro.ClearCiRole(ply) end
			MissionIntro.AssignHammerfallRole(ply, hammerfallRole)
		elseif factionId == "hammerfall_maintenance" and hammerfallRole ~= "" and MissionIntro.AssignHammerfallMaintenanceRole then
			if MissionIntro.ClearCiRole then MissionIntro.ClearCiRole(ply) end
			MissionIntro.AssignHammerfallMaintenanceRole(ply, hammerfallRole)
		elseif MissionIntro.ClearHammerfallRole then
			MissionIntro.ClearHammerfallRole(ply)
		end
		if factionId ~= "hammerfall_maintenance" and MissionIntro.ClearHammerfallMaintenanceRole then
			MissionIntro.ClearHammerfallMaintenanceRole(ply)
		end

		if factionId == "sid_squad" and sidRole ~= "" and MissionIntro.AssignSidRole then
			MissionIntro.AssignSidRole(ply, sidRole)
		elseif factionId == "uiu_taskforce" and sidRole ~= "" and MissionIntro.AssignUiuTfRole then
			if MissionIntro.ClearSidRole then MissionIntro.ClearSidRole(ply) end
			MissionIntro.AssignUiuTfRole(ply, sidRole)
		elseif MissionIntro.ClearSidRole then
			MissionIntro.ClearSidRole(ply)
		end
		if factionId ~= "uiu_taskforce" and MissionIntro.ClearUiuTfRole then
			MissionIntro.ClearUiuTfRole(ply)
		end

		if factionId == "pttrb_squad" and pttrbRole ~= "" and MissionIntro.AssignPttrbRole then
			MissionIntro.AssignPttrbRole(ply, pttrbRole)
		elseif MissionIntro.ClearPttrbRole then
			MissionIntro.ClearPttrbRole(ply)
		end
	end

	if MissionIntro.DestroyEmblemImage then
		MissionIntro.DestroyEmblemImage()
	end

	if MissionIntro.Active then
		MI_Finish(MissionIntro.Active, false, true)
	end

	if not IsValid(ent) then
		ent = nil
	end

	MissionIntro.Active = MI_NewState(ent, factionId)
	if MissionIntro.Active and factionId ~= "" then
		MissionIntro.Active.factionId = factionId
		if MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId) then
			if MissionIntro.BuildFacilityPhase3Timeline then
				MissionIntro.Active.timeline = MissionIntro.BuildFacilityPhase3Timeline(ply) or {}
				table.sort(MissionIntro.Active.timeline, function(a, b)
					return (a.t or 0) < (b.t or 0)
				end)
				MissionIntro.Active.phase = 3
				MissionIntro.Active.unlocked = true
			end
			if MissionIntro.CacheIntroDrawState then
				MissionIntro.CacheIntroDrawState(MissionIntro.Active)
			end
		end
		MissionIntro.Active.scarletRole = scarletRole ~= "" and scarletRole or nil
		MissionIntro.Active.hammerfallRole = hammerfallRole ~= "" and hammerfallRole or nil
		MissionIntro.Active.pttrbRole = pttrbRole ~= "" and pttrbRole or nil
	end
	if MissionIntro.ShowFacilityGallery and MissionIntro.IsFacilityGalleryFactionId and MissionIntro.IsFacilityGalleryFactionId(factionId) then
		MissionIntro.ShowFacilityGallery(factionId, ply)
	end
	hook.Add("HUDPaint", "MissionIntro_Draw", MI_Draw)
end)

net.Receive("MissionIntro_ForceStop", function()
	if MissionIntro.StopFacilityGallery then
		MissionIntro.StopFacilityGallery()
	elseif MissionIntro.StopFacilitySecurityGallery then
		MissionIntro.StopFacilitySecurityGallery()
	end
	MissionIntro.StopHUD()
end)

concommand.Add("mission_intro_debug", function()
	if MissionIntro.Active then
		MI_Finish(MissionIntro.Active, false, true)
		return
	end
	local tr = LocalPlayer():GetEyeTrace()
	local ent = IsValid(tr.Entity) and tr.Entity or LocalPlayer()
	MissionIntro.Active = MI_NewState(ent)
	hook.Add("HUDPaint", "MissionIntro_Draw", MI_Draw)
end)

concommand.Add("mission_intro_stop", function()
	if MissionIntro.Active then
		MI_Finish(MissionIntro.Active, true, true)
	else
		MissionIntro.StopIntroAudio()
		MissionIntro.StopHUD()
	end
	net.Start("MissionIntro_Abort")
	net.SendToServer()
end)

hook.Add("ShutDown", "MissionIntro_Cleanup", MI_CleanupHooks)
