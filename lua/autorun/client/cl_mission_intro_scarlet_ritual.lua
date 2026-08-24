if not CLIENT then return end

MissionIntro._scarletRitualHUD = MissionIntro._scarletRitualHUD or { phase = 0, endAt = 0 }

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 18, weight = weight or 600 })
	end
	return "DermaDefault"
end

local MI_SCARLET_EMBLEM_STATE = { factionId = "scarlet_cultist" }

local function MI_ScarletEmblemPixelSize(kind)
	local cfg = MissionIntro.ScarletRitual or {}
	local scrH = ScrH()

	if kind == "summon" then
		local base = tonumber(cfg.summon_emblem_size) or 200
		return math.Clamp(math.max(base, scrH * 0.2), 160, 280)
	end

	local base = tonumber(cfg.pray_emblem_size) or 168
	return math.Clamp(math.max(base, scrH * 0.17), 140, 240)
end

local function MI_DrawScarletEmblemSquare(cx, cy, pixelSize, alpha)
	if not MissionIntro.DrawFactionEmblem then return false end

	local radius = pixelSize * 0.5
	MissionIntro.DrawFactionEmblem(cx, cy, radius, alpha or 255, MI_SCARLET_EMBLEM_STATE)
	return true
end

local function MI_GetActiveScarletBooks()
	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_scarlet_book")) do
		if not IsValid(ent) then continue end
		if ent.GetBookDestroyed and ent:GetBookDestroyed() then continue end
		if ent.GetRitualDone and ent:GetRitualDone() then continue end
		list[#list + 1] = ent
	end
	return list
end

local function MI_EaseOutCubic(t)
	t = math.Clamp(t, 0, 1)
	return 1 - (1 - t) ^ 3
end

local function MI_DestroyScarletKingPopup()
	if IsValid(MissionIntro._scarletKingPopupPanel) then
		MissionIntro._scarletKingPopupPanel:Remove()
	end
	MissionIntro._scarletKingPopupPanel = nil
end

function MissionIntro.ShowScarletKingArrivalPopup()
	MI_DestroyScarletKingPopup()

	local cfg = MissionIntro.ScarletRitual or {}
	local holdDur = tonumber(cfg.king_popup_duration) or 10
	local slideDur = tonumber(cfg.king_popup_slide) or 0.45
	local total = holdDur + slideDur * 2

	local scrW, scrH = ScrW(), ScrH()
	local panelW = math.Clamp(math.floor(scrW * 0.34), 320, 460)
	local panelH = math.Clamp(math.floor(scrH * 0.16), 118, 168)
	local margin = 24
	local targetX = margin
	local startX = -panelW - 32
	local targetY = math.floor((scrH - panelH) * 0.42)

	local line1 = MissionIntro.L and MissionIntro.L("ritual_king_line1") or "猩红之王降临"
	local line2 = MissionIntro.L and MissionIntro.L("ritual_king_line2") or "这个维度完蛋了！"

	local pnl = vgui.Create("DPanel")
	pnl:SetSize(panelW, panelH)
	pnl:SetPos(startX, targetY)
	pnl:SetAlpha(0)
	pnl._animStart = CurTime()
	pnl._slideDur = slideDur
	pnl._holdDur = holdDur
	pnl._total = total
	pnl._targetX = targetX
	pnl._startX = startX
	pnl._targetY = targetY

	local bgCol = Color(12, 4, 8, 228)
	local borderCol = Color(255, 48, 64, 255)
	local line1Col = Color(255, 56, 72, 255)
	local line2Col = Color(255, 200, 200, 255)
	local emblemSize = math.Clamp(panelH - 28, 72, 96)

	pnl.Paint = function(self, pw, ph)
		draw.RoundedBox(8, 0, 0, pw, ph, bgCol)
		surface.SetDrawColor(borderCol.r, borderCol.g, borderCol.b, borderCol.a)
		surface.DrawOutlinedRect(0, 0, pw, ph, 2)

		surface.SetDrawColor(255, 32, 48, 70)
		surface.DrawRect(10, 10, 4, ph - 20)

		local emblemX = 18 + emblemSize * 0.5
		local emblemY = ph * 0.5
		MI_DrawScarletEmblemSquare(emblemX, emblemY, emblemSize, self:GetAlpha() or 255)

		local textX = 22 + emblemSize + 8
		draw.SimpleText(line1, MI_Font(math.Clamp(ph * 0.22, 24, 32), 800), textX, ph * 0.32, line1Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(line2, MI_Font(math.Clamp(ph * 0.16, 18, 24), 600), textX, ph * 0.62, line2Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	pnl.Think = function(self)
		local elapsed = CurTime() - (self._animStart or CurTime())
		local slideDur = self._slideDur or 0.45
		local holdDur = self._holdDur or 10
		local total = self._total or (holdDur + slideDur * 2)

		if elapsed >= total then
			MI_DestroyScarletKingPopup()
			return
		end

		local alpha = 255
		local x = self._targetX or 0

		if elapsed < slideDur then
			local t = MI_EaseOutCubic(elapsed / slideDur)
			alpha = math.floor(255 * t)
			x = Lerp(t, self._startX or 0, self._targetX or 0)
		elseif elapsed < slideDur + holdDur then
			alpha = 255
			x = self._targetX or 0
		else
			local t = math.Clamp((elapsed - slideDur - holdDur) / slideDur, 0, 1)
			t = t * t
			alpha = math.floor(255 * (1 - t))
			x = Lerp(t, self._targetX or 0, self._startX or 0)
		end

		self:SetAlpha(alpha)
		self:SetPos(x, self._targetY or targetY)
	end

	MissionIntro._scarletKingPopupPanel = pnl
end

local function MI_PlayRitualExplosionSound(path)
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local soundPath = path
	if not isstring(soundPath) or soundPath == "" then
		local cfg = MissionIntro.ScarletRitual or {}
		soundPath = cfg.explosion_sound or "ambient/explosions/explode_9.wav"
	end

	ply:EmitSound(soundPath, 100, 100, 1, CHAN_STATIC)
end

function MissionIntro.DrawScarletBookHighlights()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local cfg = MissionIntro.ScarletRitual or {}
	local phase = MissionIntro._scarletRitualHUD and MissionIntro._scarletRitualHUD.phase or 0
	local scarletView = MissionIntro.CanPrayAtScarletBook and MissionIntro.CanPrayAtScarletBook(ply)

	local globalBooks = {}
	local scarletBooks = {}

	for _, ent in ipairs(MI_GetActiveScarletBooks()) do
		local revealAll = ent.GetRevealToAll and ent:GetRevealToAll()
		if revealAll or phase >= 1 then
			globalBooks[#globalBooks + 1] = ent
		elseif scarletView then
			scarletBooks[#scarletBooks + 1] = ent
		end
	end

	if #globalBooks > 0 then
		local col = cfg.book_halo_global or Color(255, 32, 48, 255)
		halo.Add(globalBooks, col, 3, 3, 4, true, true)
	end

	if #scarletBooks > 0 then
		local col = cfg.book_halo_scarlet or Color(255, 72, 88, 255)
		halo.Add(scarletBooks, col, 2, 2, 2, true, true)
	end
end

function MissionIntro.DrawScarletBookWorldMarkers()
	local cfg = MissionIntro.ScarletRitual or {}
	local phase = MissionIntro._scarletRitualHUD and MissionIntro._scarletRitualHUD.phase or 0
	local ply = LocalPlayer()
	local scarletView = IsValid(ply) and MissionIntro.CanPrayAtScarletBook and MissionIntro.CanPrayAtScarletBook(ply)

	for _, ent in ipairs(MI_GetActiveScarletBooks()) do
		local revealAll = ent.GetRevealToAll and ent:GetRevealToAll()
		local show = revealAll or phase >= 1 or scarletView
		if not show then continue end

		local col = (revealAll or phase >= 1) and (cfg.book_halo_global or Color(255, 32, 48)) or (cfg.book_halo_scarlet or Color(255, 72, 88))
		local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
		local thick = (revealAll or phase >= 1) and 2 or 1

		cam.IgnoreZ(true)
		render.SetColorMaterial()
		render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), mins, maxs, col, true)
		for i = 1, thick do
			local scale = 1 + i * 0.08
			render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), mins * scale, maxs * scale, Color(col.r, col.g, col.b, 90), true)
		end

		local top = ent:LocalToWorld(Vector(0, 0, maxs.z + 12 + ((revealAll or phase >= 1) and 18 or 0)))
		render.DrawLine(ent:GetPos(), top, col, true)
		cam.IgnoreZ(false)
	end
end

function MissionIntro.DrawScarletSabotageBar()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_scarlet_book")) do
		if not IsValid(ent) then continue end
		if ent:GetSabotagingPlayer() ~= ply then continue end
		if ent:GetSabotageProgress() <= 0 then continue end

		local frac = math.Clamp(ent:GetSabotageProgress(), 0, 1)
		local scrW, scrH = ScrW(), ScrH()
		local barW, barH = math.min(520, scrW * 0.42), 28
		local x = (scrW - barW) * 0.5
		local y = scrH - 150

		draw.RoundedBox(8, x - 3, y - 3, barW + 6, barH + 6, Color(0, 0, 0, 200))
		draw.RoundedBox(6, x, y, barW, barH, Color(30, 30, 36, 230))
		draw.RoundedBox(6, x, y, barW * frac, barH, Color(64, 140, 255, 245))

		local hint = MissionIntro.L and MissionIntro.L("ritual_book_sabotage_hint") or "按住 E 破坏祷告书"
		draw.SimpleText(hint, MI_Font(22, 700), scrW * 0.5, y - 16, Color(200, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.SimpleText(math.floor(frac * 100) .. "%", MI_Font(20, 800), scrW * 0.5, y + barH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end
end

function MissionIntro.DrawScarletPrayerBar()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_scarlet_book")) do
		if not IsValid(ent) then continue end
		if ent:GetPrayingPlayer() ~= ply then continue end
		if ent:GetPrayProgress() <= 0 then continue end

		local frac = math.Clamp(ent:GetPrayProgress(), 0, 1)
		local scrW, scrH = ScrW(), ScrH()
		local barW, barH = math.min(520, scrW * 0.42), 28
		local x = (scrW - barW) * 0.5
		local y = scrH - 150
		local iconSize = MI_ScarletEmblemPixelSize("pray")
		local iconY = y - 28 - iconSize * 0.5

		MI_DrawScarletEmblemSquare(scrW * 0.5, iconY, iconSize, 245)

		draw.RoundedBox(8, x - 3, y - 3, barW + 6, barH + 6, Color(0, 0, 0, 200))
		draw.RoundedBox(6, x, y, barW, barH, Color(30, 30, 36, 230))
		draw.RoundedBox(6, x, y, barW * frac, barH, Color(210, 36, 52, 245))

		local hint = MissionIntro.L and MissionIntro.L("ritual_book_hint") or "按住 E 祷告"
		draw.SimpleText(hint, MI_Font(22, 700), scrW * 0.5, y - 16, Color(255, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.SimpleText(math.floor(frac * 100) .. "%", MI_Font(20, 800), scrW * 0.5, y + barH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end
end

function MissionIntro.DrawScarletSummonHUD()
	local hud = MissionIntro._scarletRitualHUD
	if not hud or hud.phase ~= 1 then return end

	local scrW, scrH = ScrW(), ScrH()
	local iconSize = MI_ScarletEmblemPixelSize("summon")
	local y = math.max(24, scrH * 0.035)

	MI_DrawScarletEmblemSquare(scrW * 0.5, y + iconSize * 0.5, iconSize, 255)
	y = y + iconSize + 18

	local line1 = MissionIntro.L and MissionIntro.L("ritual_summon_line1") or "未知势力正在打开时空裂缝"
	local line2 = MissionIntro.L and MissionIntro.L("ritual_summon_line2") or "所以武装单位立刻阻止！"

	draw.SimpleText(line1, MI_Font(math.Clamp(scrH * 0.038, 30, 44), 800), scrW * 0.5, y, Color(255, 48, 64), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(line2, MI_Font(math.Clamp(scrH * 0.03, 24, 36), 700), scrW * 0.5, y + 46, Color(255, 210, 210), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	if hud.endAt and hud.endAt > CurTime() then
		local left = math.max(0, math.ceil(hud.endAt - CurTime()))
		draw.SimpleText(tostring(left) .. "s", MI_Font(math.Clamp(scrH * 0.034, 28, 40), 800), scrW * 0.5, y + 92, Color(255, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
end

hook.Add("PreDrawHalos", "MissionIntro_ScarletBookHalos", function()
	if MissionIntro.Active and MissionIntro.IsPlaying and MissionIntro.IsPlaying() then return end
	MissionIntro.DrawScarletBookHighlights()
end)

hook.Add("PostDrawTranslucentRenderables", "MissionIntro_ScarletBookMarkers", function(depth, skybox)
	if skybox then return end
	if MissionIntro.Active and MissionIntro.IsPlaying and MissionIntro.IsPlaying() then return end
	MissionIntro.DrawScarletBookWorldMarkers()
end)

hook.Add("HUDPaint", "MissionIntro_ScarletRitualHUD", function()
	if MissionIntro.Active and MissionIntro.IsPlaying and MissionIntro.IsPlaying() then
		return
	end

	MissionIntro.DrawScarletPrayerBar()
	MissionIntro.DrawScarletSabotageBar()
	MissionIntro.DrawScarletSummonHUD()
end)

net.Receive("MissionIntro_ScarletRitualHUD", function()
	local phase = net.ReadUInt(3) or 0
	local endAt = net.ReadFloat() or 0

	if phase == 0 then
		MissionIntro._scarletRitualHUD = { phase = 0, endAt = 0 }
		return
	end

	MissionIntro._scarletRitualHUD = {
		phase = phase,
		endAt = endAt,
		started = CurTime(),
	}
end)

net.Receive("MissionIntro_ScarletRitualExplosion", function()
	MI_PlayRitualExplosionSound(net.ReadString())
	if MissionIntro.ShowScarletKingArrivalPopup then
		MissionIntro.ShowScarletKingArrivalPopup()
	end
end)

hook.Add("ShutDown", "MissionIntro_DestroyScarletKingPopup", MI_DestroyScarletKingPopup)
