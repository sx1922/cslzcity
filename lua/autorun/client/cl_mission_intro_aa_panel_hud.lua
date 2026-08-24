MissionIntro = MissionIntro or {}
MissionIntro._aaHudPanel = MissionIntro._aaHudPanel or nil

local COL = {
	bg = Color(12, 16, 24, 245),
	border = Color(200, 120, 60, 255),
	title = Color(240, 230, 210),
	text = Color(235, 240, 248),
	dim = Color(140, 150, 168),
	ok = Color(80, 200, 120),
	off = Color(220, 90, 70),
	warn = Color(220, 150, 60),
	btn = Color(120, 70, 40),
	btnHover = Color(160, 95, 50),
	btnDisabled = Color(55, 60, 72),
	hold = Color(220, 180, 80),
}

local function MI_Scale()
	return tonumber(MissionIntro.AaPanel and MissionIntro.AaPanel.hud_scale) or 1.35
end

local function sc(n)
	return math.max(1, math.floor((tonumber(n) or 0) * MI_Scale()))
end

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = sc(size), weight = weight or 600 })
	end
	return "DermaDefault"
end

local function MI_HudSize()
	local cfg = MissionIntro.AaPanel or {}
	local s = MI_Scale()
	return math.floor((tonumber(cfg.hud_base_w) or 560) * s), math.floor((tonumber(cfg.hud_base_h) or 420) * s)
end

local function MI_SamePanel(a, b)
	return IsValid(a) and IsValid(b) and a:EntIndex() == b:EntIndex()
end

local function MI_StyleBtn(btn, enabled)
	btn:SetFont(MI_Font(18, 700))
	btn:SetTextColor(Color(255, 255, 255))
	local base = enabled and COL.btn or COL.btnDisabled
	local hover = enabled and COL.btnHover or COL.btnDisabled
	btn.Paint = function(self, w, h)
		local col = (enabled and self:IsHovered()) and hover or base
		if enabled and self:IsDown() then
			col = Color(col.r * 0.85, col.g * 0.85, col.b * 0.85)
		end
		draw.RoundedBox(sc(6), 0, 0, w, h, col)
	end
	btn:SetEnabled(enabled ~= false)
end

local function MI_GetDanger(ent)
	if IsValid(ent) then
		return math.Clamp(ent:GetDangerLevel() or 0, 0, 100)
	end
	return math.Clamp(tonumber(MissionIntro._aaDangerLevel) or 0, 0, 100)
end

local function MI_IsActive(ent)
	if IsValid(ent) then
		return ent:GetAaActive()
	end
	return MissionIntro._aaSystemActive ~= false
end

function MissionIntro.CloseAaPanelHud()
	if IsValid(MissionIntro._aaHudPanel) then
		MissionIntro._aaHudPanel:Remove()
	end
	MissionIntro._aaHudPanel = nil
end

function MissionIntro.RefreshAaPanelHud(ent)
	if not IsValid(ent) and IsValid(MissionIntro._aaHudPanel) then
		ent = MissionIntro._aaHudPanel._aaEnt
	end
	if not IsValid(ent) then return end
	MissionIntro.CloseAaPanelHud()
	MissionIntro.OpenAaPanelHud(ent)
end

function MissionIntro.OpenAaPanelHud(ent)
	if not IsValid(ent) then return end

	-- 仅在本机鼠标正在长按时跳过重建，避免打断按住
	local fr = MissionIntro._aaHudPanel
	if IsValid(fr) and fr._shutdownHolding and fr._aaEnt == ent then
		return
	end

	MissionIntro.CloseAaPanelHud()

	local function MI_HoldNeed(mode)
		if MissionIntro.GetAaPanelHoldDuration then
			return MissionIntro.GetAaPanelHoldDuration(mode)
		end
		local cfg = MissionIntro.AaPanel or {}
		if mode == "abort" then
			return math.max(1, tonumber(cfg.abort_hold) or 2)
		end
		return math.max(1, tonumber(cfg.confirm_hold) or 5)
	end

	local function MI_State()
		local level = MI_GetDanger(ent)
		local active = MI_IsActive(ent)
		local closing = MissionIntro._aaClosingInProgress == true
		local triggered = MissionIntro._aaCiSpawnTriggered == true
		local shutdown = MissionIntro._aaSystemShutdown == true
		local eta = IsValid(ent) and (ent:GetCiSpawnEta() or 0) or (tonumber(MissionIntro._aaCiSpawnEta) or 0)
		local ciLeft = math.max(0, eta - CurTime())
		local holdState = MissionIntro._aaShutdownHold
		local holdActive = holdState and MI_SamePanel(holdState.ent, ent)
		local lp = LocalPlayer()
		local isHolder = holdActive and IsValid(holdState.holder) and lp == holdState.holder
		local canShutdown = not closing and not shutdown and active and level >= 100 and not triggered and not holdActive
		local canAbortClose = holdActive and (holdState.mode or "close") == "close" and not isHolder
		local canAbortClosing = closing and IsValid(lp) and not holdActive
		return {
			level = level, active = active, closing = closing, triggered = triggered, shutdown = shutdown,
			eta = eta, ciLeft = ciLeft, holdState = holdState, holdActive = holdActive, lp = lp,
			isHolder = isHolder, canShutdown = canShutdown, canAbortClose = canAbortClose,
			canAbortClosing = canAbortClosing, canAbort = canAbortClose or canAbortClosing,
			btnHoldMode = canAbortClosing and "abort" or "close",
		}
	end

	local st = MI_State()

	local hudW, hudH = MI_HudSize()
	local fr = vgui.Create("DFrame")
	fr:SetSize(hudW, hudH)
	fr:Center()
	fr:MakePopup()
	fr:SetTitle("")
	fr:ShowCloseButton(true)
	fr._aaEnt = ent
	fr._canShutdown = st.canShutdown
	fr._canAbortClosing = st.canAbortClosing
	fr._holdMode = st.btnHoldMode
	fr._miState = MI_State
	MissionIntro._aaHudPanel = fr

	fr.Paint = function(self, w, h)
		draw.RoundedBox(sc(10), 0, 0, w, h, COL.bg)
		surface.SetDrawColor(COL.border)
		surface.DrawOutlinedRect(0, 0, w, h, sc(2))
	end

	local body = vgui.Create("DPanel", fr)
	body:Dock(FILL)
	body:DockMargin(sc(10), sc(10), sc(10), sc(10))
	body.Paint = function() end

	local top = vgui.Create("DPanel", body)
	top:Dock(TOP)
	top:SetTall(sc(72))
	top.Paint = function(self, w, h)
		local s = fr._miState and fr._miState() or st
		draw.SimpleText(MissionIntro.L("aa_hud_system_title"), MI_Font(22, 800), w * 0.5, sc(10), COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		local statusKey, statusCol
		if s.closing then
			statusKey, statusCol = "aa_status_closing", COL.warn
		elseif s.shutdown or not s.active then
			statusKey, statusCol = "aa_status_off", COL.off
		else
			statusKey, statusCol = "aa_status_normal", COL.ok
		end
		draw.SimpleText(MissionIntro.L(statusKey), MI_Font(26, 800), w * 0.5, sc(38), statusCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	local mid = vgui.Create("DPanel", body)
	mid:Dock(FILL)
	mid:DockMargin(0, sc(10), 0, sc(10))
	mid.Paint = function(self, w, h)
		local s = fr._miState and fr._miState() or st
		local pad = sc(8)
		draw.RoundedBox(sc(8), pad, pad, w - pad * 2, h - pad * 2, Color(16, 22, 34, 255))
		draw.SimpleText(MissionIntro.L("aa_hud_danger_title"), MI_Font(20, 700), w * 0.5, sc(24), COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		local pctCol = s.level >= 100 and COL.off or (s.level >= 75 and COL.warn or COL.ok)
		draw.SimpleText(string.format("%.1f%%", s.level), MI_Font(52, 800), w * 0.5, h * 0.5 + sc(4), pctCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if s.closing and s.ciLeft > 0 then
			draw.SimpleText(MissionIntro.L("aa_hud_closing_eta", math.ceil(s.ciLeft)), MI_Font(17, 600), w * 0.5, h - sc(14), COL.warn, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		elseif s.shutdown and s.triggered then
			draw.SimpleText(MissionIntro.L("aa_hud_ci_done"), MI_Font(17, 600), w * 0.5, h - sc(14), COL.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end

	local abortHint = vgui.Create("DLabel", body)
	abortHint:Dock(BOTTOM)
	abortHint:SetTall(sc(28))
	abortHint:SetFont(MI_Font(15, 600))
	abortHint:SetTextColor(COL.warn)
	abortHint:SetContentAlignment(5)
	abortHint:SetVisible(st.canAbortClosing)
	abortHint:SetText(MissionIntro.L("aa_hud_abort_hint"))

	local bottom = vgui.Create("DPanel", body)
	bottom:Dock(BOTTOM)
	bottom:SetTall(sc(96))
	bottom.Paint = function() end

	local progLbl = vgui.Create("DLabel", bottom)
	progLbl:Dock(TOP)
	progLbl:SetTall(sc(22))
	progLbl:SetFont(MI_Font(15, 600))
	progLbl:SetTextColor(COL.warn)
	progLbl:SetContentAlignment(5)
	progLbl:SetVisible(false)
	progLbl.Think = function(self)
		local s = fr._miState and fr._miState() or st
		if not s.holdActive or not s.isHolder then
			self:SetVisible(false)
			return
		end
		self:SetVisible(true)
		local left = math.max(0, (s.holdState.endAt or 0) - CurTime())
		self:SetText(MissionIntro.L("aa_hud_hold_in_progress") .. string.format(" %.1fs", left))
		if left <= 0 and s.holdState.mode == "close" and not s.closing then
			self:SetText(MissionIntro.L("aa_hud_hold_confirming"))
		end
	end

	local holdBar = vgui.Create("DPanel", bottom)
	holdBar:Dock(TOP)
	holdBar:SetTall(sc(22))
	holdBar:SetVisible(false)
	holdBar.Paint = function(self, w, h)
		local need = MI_HoldNeed(fr._holdMode or "close")
		local prog = math.Clamp((self._holdProg or 0) / need, 0, 1)
		draw.RoundedBox(sc(4), 0, 0, w, h, Color(30, 34, 44))
		draw.RoundedBox(sc(4), sc(2), sc(2), math.floor((w - sc(4)) * prog), h - sc(4), COL.hold)
		draw.SimpleText(MissionIntro.L("aa_hud_hold_fmt", math.ceil(prog * need), need), MI_Font(14, 600), w * 0.5, h * 0.5, COL.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local btnClose = vgui.Create("DButton", bottom)
	btnClose:Dock(TOP)
	btnClose:SetTall(sc(36))
	btnClose:DockMargin(0, sc(4), 0, 0)
	btnClose.DoClick = function() end

	local btnAbort = vgui.Create("DButton", bottom)
	btnAbort:Dock(TOP)
	btnAbort:SetTall(sc(36))
	btnAbort:DockMargin(0, sc(6), 0, 0)
	btnAbort.DoClick = function() end

	local function MI_UpdateButtons()
		local s = fr._miState and fr._miState() or st

		local closeLabel = MissionIntro.L("aa_hud_btn_shutdown")
		if s.shutdown or (not s.active and not s.closing) then
			closeLabel = closeLabel .. " (" .. MissionIntro.L("aa_hud_already_off") .. ")"
		elseif s.level < 100 and not s.closing then
			closeLabel = closeLabel .. " (" .. MissionIntro.L("aa_hud_need_100") .. ")"
		elseif s.triggered then
			closeLabel = closeLabel .. " (" .. MissionIntro.L("aa_hud_ci_done") .. ")"
		elseif s.closing then
			closeLabel = MissionIntro.L("aa_hud_closing_eta", math.max(1, math.ceil(s.ciLeft)))
		elseif s.holdActive and s.isHolder and (s.holdState.mode or "close") == "close" then
			closeLabel = MissionIntro.L("aa_hud_hold_in_progress")
		end
		btnClose:SetText(closeLabel)
		btnClose:SetVisible(not s.canAbortClosing)
		MI_StyleBtn(btnClose, s.canShutdown or (s.holdActive and s.isHolder and (s.holdState.mode or "close") == "close"))

		local abortLabel = MissionIntro.L("aa_hud_btn_abort")
		if s.holdActive and s.isHolder and (s.holdState.mode or "close") == "abort" then
			abortLabel = MissionIntro.L("aa_hud_hold_in_progress")
		elseif s.canAbortClose then
			abortLabel = MissionIntro.L("aa_hud_btn_abort_now")
		end
		btnAbort:SetText(abortLabel)
		btnAbort:SetVisible(s.canAbortClosing or s.canAbortClose)
		MI_StyleBtn(btnAbort, s.canAbortClosing or s.canAbortClose or (s.holdActive and s.isHolder and (s.holdState.mode or "close") == "abort"))

		abortHint:SetVisible(s.canAbortClosing and not s.holdActive)

		local bottomH = sc(96)
		if s.canAbortClosing or s.canAbortClose then
			bottomH = sc(s.canAbortClosing and 132 or 96)
		end
		bottom:SetTall(bottomH)

		fr._canShutdown = s.canShutdown
		fr._canAbortClosing = s.canAbortClosing
		fr._canAbortClose = s.canAbortClose
	end

	fr._holdBtnClose = btnClose
	fr._holdBtnAbort = btnAbort
	fr._holdBar = holdBar

	local function MI_CancelLocalHold(activeBtn, sendNet)
		if not IsValid(activeBtn) then return end
		local hadSent = activeBtn._sentBegin
		activeBtn._holding = false
		activeBtn._holdStart = 0
		activeBtn._sentBegin = false
		holdBar:SetVisible(false)
		activeBtn:MouseCapture(false)
		fr._activeHoldBtn = nil
		if sendNet and hadSent then
			net.Start("MissionIntro_AaPanelAction")
				net.WriteEntity(ent)
				net.WriteUInt(4, 4)
			net.SendToServer()
		end
	end

	local function MI_BeginHold(self, mode)
		local s = fr._miState and fr._miState() or st
		if s.holdActive then return end
		if mode == "close" and not s.canShutdown then return end
		if mode == "abort" and not s.canAbortClosing then return end

		self._holding = true
		self._holdStart = nil
		self._sentBegin = false
		self._awaitServerHold = true
		fr._shutdownHolding = true
		fr._holdMode = mode
		fr._activeHoldBtn = self
		holdBar:SetVisible(true)
		holdBar._holdProg = 0
		self:MouseCapture(true)
	end

	local function MI_HoldThink(self)
		if not self._holding then
			MI_UpdateButtons()
			return
		end

		if not input.IsMouseDown(MOUSE_LEFT) then
			MI_CancelLocalHold(self, self._sentBegin)
			fr._shutdownHolding = nil
			return
		end

		if not self._sentBegin then
			net.Start("MissionIntro_AaPanelAction")
				net.WriteEntity(ent)
				net.WriteUInt((fr._holdMode == "abort") and 5 or 1, 4)
			net.SendToServer()
			self._sentBegin = true
		end

		local h = MissionIntro._aaShutdownHold
		if not h or not MI_SamePanel(h.ent, ent) or not IsValid(h.holder) or h.holder ~= LocalPlayer() then
			return
		end

		if self._awaitServerHold then
			self._awaitServerHold = false
			self._holdStart = CurTime()
		end

		local mode = fr._holdMode or "close"
		local need = MI_HoldNeed(mode)
		local left = math.max(0, (h.endAt or 0) - CurTime())
		local elapsed = math.max(0, need - left)
		holdBar._holdProg = elapsed

		if left <= 0.05 then
			self._holding = false
			self:MouseCapture(false)
			holdBar:SetVisible(false)
			fr._shutdownHolding = nil
			self._sentBegin = false
			self._awaitServerHold = false
			fr._activeHoldBtn = nil
			net.Start("MissionIntro_AaPanelAction")
				net.WriteEntity(ent)
				net.WriteUInt(2, 4)
			net.SendToServer()
		end
	end

	btnClose.OnMousePressed = function(self, mc)
		if mc ~= MOUSE_LEFT then return end
		local s = fr._miState and fr._miState() or st
		if not s.canShutdown or s.holdActive then return end
		MI_BeginHold(self, "close")
	end

	btnClose.OnMouseReleased = function(self, mc)
		if mc ~= MOUSE_LEFT then return end
		if self._holding then
			MI_CancelLocalHold(self, self._sentBegin)
		end
		fr._shutdownHolding = nil
	end

	btnClose.Think = MI_HoldThink

	btnAbort.OnMousePressed = function(self, mc)
		if mc ~= MOUSE_LEFT then return end
		local s = fr._miState and fr._miState() or st
		if s.canAbortClose then
			net.Start("MissionIntro_AaPanelAction")
				net.WriteEntity(ent)
				net.WriteUInt(3, 4)
			net.SendToServer()
			fr:Close()
			return
		end
		if not s.canAbortClosing or s.holdActive then return end
		MI_BeginHold(self, "abort")
	end

	btnAbort.OnMouseReleased = function(self, mc)
		if mc ~= MOUSE_LEFT then return end
		if self._holding then
			MI_CancelLocalHold(self, self._sentBegin)
		end
		fr._shutdownHolding = nil
	end

	btnAbort.Think = MI_HoldThink

	MI_UpdateButtons()

	fr.Think = function()
		if not fr._shutdownHolding then return end
		if not IsValid(ent) then
			fr:Close()
		end
	end

	fr.OnClose = function()
		local activeBtn = fr._activeHoldBtn
		if fr._shutdownHolding and IsValid(activeBtn) and activeBtn._sentBegin then
			net.Start("MissionIntro_AaPanelAction")
				net.WriteEntity(ent)
				net.WriteUInt(4, 4)
			net.SendToServer()
		end
		if MissionIntro._aaHudPanel == fr then
			MissionIntro._aaHudPanel = nil
		end
	end

	timer.Simple(0, function()
		if not IsValid(fr) then return end
		local closeBtn = fr.btnClose
		if IsValid(closeBtn) then
			closeBtn:SetSize(sc(24), sc(24))
		end
	end)
end

net.Receive("MissionIntro_AaPanelOpen", function()
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	MissionIntro.OpenAaPanelHud(ent)
end)
