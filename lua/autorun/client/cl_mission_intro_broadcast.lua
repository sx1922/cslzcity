MissionIntro = MissionIntro or {}
MissionIntro._broadcastPanel = MissionIntro._broadcastPanel or nil
MissionIntro._broadcastSound = MissionIntro._broadcastSound or nil
MissionIntro._broadcastMusicSound = MissionIntro._broadcastMusicSound or nil

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 18, weight = weight or 600 })
	end
	return "DermaDefault"
end

local function MI_DrawBroadcastPanel(self, pw, ph, cfg, titleText, line1, line2, bodyText, titleCol, bodyCol)
	local fontTitle = MI_Font(cfg.font_title or 28, 700)
	local fontLine1 = MI_Font(cfg.font_line1 or 23, 600)
	local fontLine2 = MI_Font(cfg.font_line2 or 20, 500)
	local fontBody = MI_Font(cfg.font_body or 19, 500)
	local gap = cfg.line_gap or 34
	local x = 22
	local y = 14

	draw.SimpleText(titleText, fontTitle, x, y, titleCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + gap

	if isstring(bodyText) and bodyText ~= "" then
		if cfg.body_wrap ~= false then
			draw.DrawText(bodyText, fontBody, x, y, bodyCol, TEXT_ALIGN_LEFT)
		else
			draw.SimpleText(bodyText, fontBody, x, y, bodyCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		return
	end

	if line1 ~= "" then
		draw.SimpleText(line1, fontLine1, x, y, bodyCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		y = y + gap
	end
	if line2 ~= "" then
		draw.SimpleText(line2, fontLine2, x, y, bodyCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

local function MI_StopBroadcastSound()
	if IsValid(MissionIntro._broadcastSound) then
		MissionIntro._broadcastSound:Stop()
	end
	MissionIntro._broadcastSound = nil
end

local function MI_StopBroadcastMusic()
	if IsValid(MissionIntro._broadcastMusicSound) then
		MissionIntro._broadcastMusicSound:Stop()
	end
	MissionIntro._broadcastMusicSound = nil
end

local function MI_ResolveBroadcastSoundPath(path)
	if not isstring(path) or path == "" then return nil end

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

local function MI_EmitBroadcastFallback(path, volume)
	local ply = LocalPlayer()
	if not IsValid(ply) or not isstring(path) or path == "" then return end
	ply:StopSound(path)
	ply:EmitSound(path, 100, 100, volume or 0.95, CHAN_AUTO)
end

function MissionIntro.PlayBroadcastSoundPath(path, volume)
	if not CLIENT then return false end
	if not isstring(path) or path == "" then return false end

	local cfg = MissionIntro.Broadcast or {}
	volume = tonumber(volume) or cfg.volume or 0.95
	local resolved = MI_ResolveBroadcastSoundPath(path)

	if not file.Exists("sound/" .. resolved, "GAME") then
		MsgC(Color(255, 120, 120), "[MissionIntro] 找不到警报音效: sound/", tostring(resolved), " （请运行 tools/install_aa_assets.bat）\n")
		return false
	end

	MI_StopBroadcastSound()

	sound.PlayFile("sound/" .. resolved, "noplay", function(chan, err)
		if not IsValid(chan) then
			MsgC(Color(255, 120, 120), "[MissionIntro] 警报 PlayFile 失败: ", tostring(err or "?"), "，尝试 EmitSound\n")
			MI_EmitBroadcastFallback(resolved, volume)
			return
		end

		chan:SetVolume(volume)
		chan:Play()
		MissionIntro._broadcastSound = chan
	end)

	return true
end

function MissionIntro.PlayBroadcastMusicPath(path, volume)
	if not CLIENT then return false end
	if not isstring(path) or path == "" then return false end

	local cfg = MissionIntro.Broadcast or {}
	volume = tonumber(volume) or cfg.music_volume or 0.75
	local resolved = MI_ResolveBroadcastSoundPath(path)

	if not file.Exists("sound/" .. resolved, "GAME") then
		MsgC(Color(255, 120, 120), "[MissionIntro] 找不到背景音乐: sound/", tostring(resolved), "\n")
		return false
	end

	MI_StopBroadcastMusic()

	sound.PlayFile("sound/" .. resolved, "noplay", function(chan, err)
		if not IsValid(chan) then
			MsgC(Color(255, 120, 120), "[MissionIntro] 背景音乐 PlayFile 失败: ", tostring(err or "?"), "\n")
			return
		end

		chan:SetVolume(volume)
		chan:Play()
		MissionIntro._broadcastMusicSound = chan
	end)

	return true
end

local function MI_PlayBroadcastSound(factionId)
	local cfg = MissionIntro.Broadcast or {}
	local path = cfg.sound

	if isstring(factionId) and factionId ~= "" and MissionIntro.GetFactionBroadcast then
		local facData = MissionIntro.GetFactionBroadcast(factionId)
		if istable(facData) and isstring(facData.sound) and facData.sound ~= "" then
			path = facData.sound
		end
	end

	if not isstring(path) or path == "" then return end

	MissionIntro.PlayBroadcastSoundPath(path, cfg.volume or 0.95)
end

local function MI_DestroyBroadcastPanel()
	if IsValid(MissionIntro._broadcastPanel) then
		MissionIntro._broadcastPanel:Remove()
	end
	MissionIntro._broadcastPanel = nil
end

function MissionIntro.ShowFactionBroadcast(factionId, playSound)
	if not CLIENT then return end

	local facData = MissionIntro.GetFactionBroadcast and MissionIntro.GetFactionBroadcast(factionId)
	if not facData then return end

	local cfg = MissionIntro.Broadcast or {}
	MI_DestroyBroadcastPanel()

	local facNoSound = istable(facData) and facData.no_sound == true

	local soundForIntro = MissionIntro.FactionBroadcastSoundForIntro
		and MissionIntro.FactionBroadcastSoundForIntro(factionId)

	if playSound ~= false and not facNoSound then
		if not soundForIntro and MissionIntro.IsPlaying and MissionIntro.IsPlaying() then
			playSound = false
		end
	end

	if playSound ~= false and not facNoSound then
		MI_PlayBroadcastSound(factionId)
	end

	local side = facData.side or "right"
	local margin = cfg.margin or 24
	local marginBottom = cfg.margin_bottom or (margin + 48)
	local w, h = cfg.panel_w or 580, cfg.panel_h or 168
	local scrW, scrH = ScrW(), ScrH()
	local targetX = (side == "left") and margin or (scrW - w - margin)
	local startX = (side == "left") and (-w - 20) or (scrW + 20)
	local targetY = scrH - h - marginBottom

	local pnl = vgui.Create("DPanel")
	pnl:SetSize(w, h)
	pnl:SetPos(startX, targetY)
	pnl:SetAlpha(0)
	pnl._fadeStart = CurTime()
	pnl._fadeIn = cfg.fade_in or 0.35
	pnl._fadeOut = cfg.fade_out or 0.45
	pnl._duration = cfg.duration or 7
	pnl._targetX = targetX
	pnl._startX = startX
	pnl._side = side

	local borderCol = cfg.border_color or Color(255, 255, 255, 255)
	local bgCol = cfg.panel_bg or Color(8, 10, 14, 215)
	local titleCol = cfg.title_color or Color(255, 255, 255, 255)
	local bodyCol = cfg.body_color or Color(235, 238, 242, 255)
	local accentCol = facData.accent or borderCol

	local titleText = facData.title or "Z city 警告"
	local line1 = facData.line1 or ""
	local line2 = facData.line2 or ""
	local bodyText = facData.body or ""

	pnl.Paint = function(self, pw, ph)
		draw.RoundedBox(6, 0, 0, pw, ph, bgCol)
		surface.SetDrawColor(borderCol.r, borderCol.g, borderCol.b, borderCol.a or 255)
		surface.DrawOutlinedRect(0, 0, pw, ph, 2)

		surface.SetDrawColor(accentCol.r, accentCol.g, accentCol.b, 90)
		surface.DrawRect(10, 10, 4, ph - 20)

		MI_DrawBroadcastPanel(self, pw, ph, cfg, titleText, line1, line2, bodyText, titleCol, bodyCol)
	end

	MissionIntro._broadcastPanel = pnl

	pnl.Think = function(self)
		local elapsed = CurTime() - (self._fadeStart or CurTime())
		local total = self._duration or 7
		local fadeIn = self._fadeIn or 0.35
		local fadeOut = self._fadeOut or 0.45
		local hold = math.max(0, total - fadeIn - fadeOut)

		local alpha = 255
		local x = self._targetX or 0

		if elapsed < fadeIn then
			local t = elapsed / fadeIn
			alpha = math.floor(255 * t)
			x = Lerp(t, self._startX or 0, self._targetX or 0)
		elseif elapsed < fadeIn + hold then
			alpha = 255
			x = self._targetX or 0
		elseif elapsed < total then
			local t = (elapsed - fadeIn - hold) / fadeOut
			alpha = math.floor(255 * (1 - t))
			x = Lerp(t, self._targetX or 0, self._startX or 0)
		else
			MI_DestroyBroadcastPanel()
			return
		end

		self:SetAlpha(alpha)
		self:SetPos(x, targetY)
	end
end

function MissionIntro.ShowCustomBroadcast(data, playSound, forceDuringIntro)
	if not CLIENT or not istable(data) then return end

	local cfg = MissionIntro.Broadcast or {}
	MI_DestroyBroadcastPanel()

	if playSound ~= false and not forceDuringIntro then
		if MissionIntro.IsPlaying and MissionIntro.IsPlaying() then
			playSound = false
		end
	end

	if playSound == true and isstring(data.sound) and data.sound ~= "" then
		MissionIntro.PlayBroadcastSoundPath(data.sound, cfg.volume or 0.95)
	end

	local side = data.side or "right"
	local margin = cfg.margin or 24
	local marginBottom = cfg.margin_bottom or (margin + 48)
	local w = tonumber(data.panel_w) or cfg.panel_w or 580
	local h = tonumber(data.panel_h) or cfg.panel_h or 168
	local drawCfg = {
		font_title = data.font_title or cfg.font_title,
		font_line1 = data.font_line1 or cfg.font_line1,
		font_line2 = data.font_line2 or cfg.font_line2,
		font_body = data.font_body or cfg.font_body,
		line_gap = data.line_gap or cfg.line_gap,
		body_wrap = cfg.body_wrap,
	}

	local scrW, scrH = ScrW(), ScrH()
	local targetX = (side == "left") and margin or (scrW - w - margin)
	local startX = (side == "left") and (-w - 20) or (scrW + 20)
	local targetY = scrH - h - marginBottom

	local pnl = vgui.Create("DPanel")
	pnl:SetSize(w, h)
	pnl:SetPos(startX, targetY)
	pnl:SetAlpha(0)
	pnl._fadeStart = CurTime()
	pnl._fadeIn = cfg.fade_in or 0.35
	pnl._fadeOut = cfg.fade_out or 0.45
	pnl._duration = data.duration or cfg.duration or 15
	pnl._targetX = targetX
	pnl._startX = startX
	pnl._side = side

	local borderCol = cfg.border_color or Color(255, 255, 255, 255)
	local bgCol = cfg.panel_bg or Color(8, 10, 14, 215)
	local titleCol = cfg.title_color or Color(255, 255, 255, 255)
	local bodyCol = cfg.body_color or Color(235, 238, 242, 255)
	local accentCol = data.accent or borderCol

	local titleText = data.title or "Z city"
	local line1 = data.line1 or ""
	local line2 = data.line2 or ""
	local bodyText = data.body or ""

	pnl.Paint = function(self, pw, ph)
		draw.RoundedBox(6, 0, 0, pw, ph, bgCol)
		surface.SetDrawColor(borderCol.r, borderCol.g, borderCol.b, borderCol.a or 255)
		surface.DrawOutlinedRect(0, 0, pw, ph, 2)
		surface.SetDrawColor(accentCol.r, accentCol.g, accentCol.b, 90)
		surface.DrawRect(10, 10, 4, ph - 20)
		MI_DrawBroadcastPanel(self, pw, ph, drawCfg, titleText, line1, line2, bodyText, titleCol, bodyCol)
	end

	MissionIntro._broadcastPanel = pnl

	pnl.Think = function(self)
		local elapsed = CurTime() - (self._fadeStart or CurTime())
		local total = self._duration or 15
		local fadeIn = self._fadeIn or 0.35
		local fadeOut = self._fadeOut or 0.45
		local hold = math.max(0, total - fadeIn - fadeOut)

		local alpha = 255
		local x = self._targetX or 0

		if elapsed < fadeIn then
			local t = elapsed / fadeIn
			alpha = math.floor(255 * t)
			x = Lerp(t, self._startX or 0, self._targetX or 0)
		elseif elapsed < fadeIn + hold then
			alpha = 255
			x = self._targetX or 0
		elseif elapsed < total then
			local t = (elapsed - fadeIn - hold) / fadeOut
			alpha = math.floor(255 * (1 - t))
			x = Lerp(t, self._targetX or 0, self._startX or 0)
		else
			MI_DestroyBroadcastPanel()
			return
		end

		self:SetAlpha(alpha)
		self:SetPos(x, targetY)
	end
end

net.Receive("MissionIntro_Broadcast", function()
	local factionId = net.ReadString() or ""
	local playSound = net.ReadBool()
	MissionIntro.ShowFactionBroadcast(factionId, playSound)
end)

net.Receive("MissionIntro_BroadcastCustom", function()
	local data = {
		title = net.ReadString() or "",
		line1 = net.ReadString() or "",
		line2 = net.ReadString() or "",
		accent = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)),
		sound = net.ReadString() or "",
	}
	local playSound = net.ReadBool()
	local forceDuringIntro = net.ReadBool()
	MissionIntro.ShowCustomBroadcast(data, playSound, forceDuringIntro)
end)

net.Receive("MissionIntro_BroadcastSound", function()
	local soundPath = net.ReadString() or ""
	local forceDuringIntro = net.ReadBool()
	if soundPath == "" then return end
	if not forceDuringIntro and MissionIntro.IsPlaying and MissionIntro.IsPlaying() then return end
	if MissionIntro.PlayBroadcastSoundPath then
		MissionIntro.PlayBroadcastSoundPath(soundPath)
	end
end)

net.Receive("MissionIntro_StopBroadcastSound", function()
	MI_StopBroadcastSound()
end)

net.Receive("MissionIntro_BroadcastMusic", function()
	local soundPath = net.ReadString() or ""
	local forceDuringIntro = net.ReadBool()
	local volume = net.ReadFloat()
	if soundPath == "" then return end
	if not forceDuringIntro and MissionIntro.IsPlaying and MissionIntro.IsPlaying() then return end
	if MissionIntro.PlayBroadcastMusicPath then
		if volume >= 0 then
			MissionIntro.PlayBroadcastMusicPath(soundPath, volume)
		else
			MissionIntro.PlayBroadcastMusicPath(soundPath)
		end
	end
end)

concommand.Add("mission_intro_test_aa_alert", function()
	MissionIntro.ShowCustomBroadcast({
		title = "Z city",
		line1 = "警告 设施终端遭到强行骇入修改",
		line2 = "所有武装人员立刻阻止",
		sound = (MissionIntro.UiuTerminal and MissionIntro.UiuTerminal.alert_sound) or "mission_intro/aa_shutdown_alert.mp3",
		accent = Color(220, 90, 70),
	}, true, true)
end)

concommand.Add("mission_intro_test_broadcast", function(_, _, args)
	local fid = args[1] or "scarlet_cultist"
	local withSound = true
	if args[2] == "0" or args[2] == "mute" then
		withSound = false
	end
	MissionIntro.ShowFactionBroadcast(fid, withSound)
end)
