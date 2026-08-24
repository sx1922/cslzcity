MissionIntro = MissionIntro or {}
MissionIntro._fspHudPanel = MissionIntro._fspHudPanel or nil

local COL = {
	bg = Color(8, 10, 14, 245),
	border = Color(235, 240, 248, 255),
	title = Color(245, 248, 252, 255),
	data = Color(80, 220, 235, 255),
	dim = Color(140, 150, 165, 255),
	inner = Color(12, 16, 22, 255),
	btn = Color(40, 52, 72, 255),
	btnHover = Color(56, 72, 98, 255),
	btnAccent = Color(48, 110, 130, 255),
	btnAccentHover = Color(62, 140, 165, 255),
	btnWarn = Color(150, 55, 45, 255),
	btnWarnHover = Color(190, 70, 55, 255),
	btnDisabled = Color(45, 48, 56, 255),
	ok = Color(80, 200, 120, 255),
	warn = Color(255, 120, 80, 255),
	science = Color(80, 220, 235, 255),
	classd = Color(255, 160, 64, 255),
	scp = Color(140, 22, 38, 255),
	unknown = Color(255, 130, 190, 255),
}

local function MI_Scale()
	return tonumber(MissionIntro.FacilityStatusPanel and MissionIntro.FacilityStatusPanel.hud_scale) or 1.5
end

local function sc(n)
	return math.max(1, math.floor((tonumber(n) or 0) * MI_Scale()))
end

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = sc(size), weight = weight or 600, antialias = true })
	end
	return "DermaDefault"
end

local function MI_HudSize()
	local cfg = MissionIntro.FacilityStatusPanel or {}
	local s = MI_Scale()
	return math.floor((tonumber(cfg.hud_base_w) or 640) * s), math.floor((tonumber(cfg.hud_base_h) or 480) * s)
end

local function MI_StyleBtn(btn, col, colHover, enabled)
	btn:SetFont(MI_Font(20, 700))
	btn:SetTextColor(color_white)
	local base = enabled ~= false and (col or COL.btn) or COL.btnDisabled
	local hover = enabled ~= false and (colHover or COL.btnHover) or COL.btnDisabled
	btn.Paint = function(self, w, h)
		local c = (enabled ~= false and self:IsHovered()) and hover or base
		if enabled ~= false and self:IsDown() then
			c = Color(c.r * 0.88, c.g * 0.88, c.b * 0.88)
		end
		draw.RoundedBox(sc(8), 0, 0, w, h, c)
	end
	btn:SetEnabled(enabled ~= false)
end

local function MI_SendAction(ent, action)
	if not IsValid(ent) then return end
	net.Start("MissionIntro_FSP_Action")
		net.WriteEntity(ent)
		net.WriteUInt(action, 4)
	net.SendToServer()
end

local function MI_GetActivePA()
	if MissionIntro.GetActiveFacilityPA then
		return MissionIntro.GetActiveFacilityPA()
	end
	for _, e in ipairs(ents.FindByClass("ent_mission_intro_facility_status_panel")) do
		if IsValid(e) and e.GetPAActive and e:GetPAActive() then
			return e
		end
	end
	return nil
end

function MissionIntro.CloseFacilityStatusPanelHud()
	if IsValid(MissionIntro._fspHudPanel) then
		if MissionIntro._fspHudPanel.Close then
			MissionIntro._fspHudPanel:Close()
		else
			MissionIntro._fspHudPanel:Remove()
		end
	end
	MissionIntro._fspHudPanel = nil
	gui.EnableScreenClicker(false)
end

function MissionIntro.OpenFacilityStatusPanelHud(ent)
	if not IsValid(ent) then return end

	MissionIntro.CloseFacilityStatusPanelHud()

	local hudW, hudH = MI_HudSize()
	local fr = vgui.Create("DFrame")
	fr:SetSize(hudW, hudH)
	fr:Center()
	fr:MakePopup()
	fr:SetTitle("")
	fr:ShowCloseButton(true)
	fr._fspEnt = ent
	fr._view = "menu"
	MissionIntro._fspHudPanel = fr

	fr.Paint = function(self, w, h)
		draw.RoundedBox(sc(8), 0, 0, w, h, COL.bg)
		surface.SetDrawColor(COL.border)
		surface.DrawOutlinedRect(0, 0, w, h, sc(2))
	end

	local body = vgui.Create("DPanel", fr)
	body:Dock(FILL)
	body:DockMargin(sc(12), sc(12), sc(12), sc(12))
	body.Paint = function() end

	local function MI_ClearBody()
		for _, child in ipairs(body:GetChildren()) do
			child:Remove()
		end
	end

	local function MI_AddBack(onBack)
		local back = vgui.Create("DButton", body)
		back:Dock(BOTTOM)
		back:SetTall(sc(40))
		back:DockMargin(0, sc(10), 0, 0)
		back:SetText("返回")
		MI_StyleBtn(back, COL.btn, COL.btnHover, true)
		back.DoClick = onBack or function()
			fr._view = "menu"
			fr.ShowMenu()
		end
	end

	function fr.ShowMenu()
		fr._view = "menu"
		MI_ClearBody()

		local header = vgui.Create("DPanel", body)
		header:Dock(TOP)
		header:SetTall(sc(72))
		header.Paint = function(_, w, h)
			draw.SimpleText("设施终端", MI_Font(28, 800), w * 0.5, sc(8), COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText("设施面板与全图广播", MI_Font(16, 500), w * 0.5, sc(44), COL.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end

		local btnPanel = vgui.Create("DButton", body)
		btnPanel:Dock(TOP)
		btnPanel:SetTall(sc(56))
		btnPanel:DockMargin(0, sc(16), 0, 0)
		btnPanel:SetText("打开设施面板")
		MI_StyleBtn(btnPanel, COL.btnAccent, COL.btnAccentHover, true)
		btnPanel.DoClick = function()
			fr.ShowPanel()
		end

		if MissionIntro.IsFacilityStatusPanelActive and MissionIntro.IsFacilityStatusPanelActive() then
			local btnQrf = vgui.Create("DButton", body)
			btnQrf:Dock(TOP)
			btnQrf:SetTall(sc(56))
			btnQrf:DockMargin(0, sc(12), 0, 0)
			btnQrf:SetText(MissionIntro.L and MissionIntro.L("fsp_qrf_call") or "呼叫 快速反应部队")

			local qrfHint = vgui.Create("DLabel", body)
			qrfHint:Dock(TOP)
			qrfHint:SetTall(sc(24))
			qrfHint:DockMargin(0, sc(6), 0, 0)
			qrfHint:SetFont(MI_Font(13, 600))
			qrfHint:SetTextColor(COL.dim)
			qrfHint:SetContentAlignment(5)

			local function MI_RefreshQrfCall()
				local canCall = true
				local hint = ""

				if MissionIntro.IsFacilityQrfDeployCalled and MissionIntro.IsFacilityQrfDeployCalled() then
					canCall = false
					hint = MissionIntro.L and MissionIntro.L("fsp_qrf_hint_called") or "本回合已呼叫过快速反应部队"
				elseif not MissionIntro.IsPlayerSiteDirector or not MissionIntro.IsPlayerSiteDirector(LocalPlayer()) then
					canCall = false
					hint = MissionIntro.L and MissionIntro.L("fsp_qrf_hint_not_director") or "仅设施主管可呼叫"
				elseif MissionIntro.IsFacilityQrfCallTimeReady and not MissionIntro.IsFacilityQrfCallTimeReady() then
					canCall = false
					local unlockAt = MissionIntro.GetFacilityQrfCallUnlockAt and MissionIntro.GetFacilityQrfCallUnlockAt() or 0
					local left = math.max(0, unlockAt - CurTime())
					hint = MissionIntro.L and MissionIntro.L("fsp_qrf_hint_wait", math.ceil(left))
						or string.format("RXsend 开局 4 分钟后可呼叫（%.0f 秒）", left)
				else
					local maxSize = tonumber(MissionIntro.FacilityQrfSquadSize) or 5
					local deadCount = MissionIntro.GetFacilityQrfEligibleDeadCount and MissionIntro.GetFacilityQrfEligibleDeadCount() or 0
					if deadCount < 1 then
						canCall = false
						hint = MissionIntro.L and MissionIntro.L("fsp_qrf_hint_no_dead") or "无阵亡玩家可派遣"
					else
						local deployCount = math.min(maxSize, deadCount)
						if deployCount < maxSize then
							hint = MissionIntro.L and MissionIntro.L("fsp_qrf_hint_partial", deployCount, deadCount)
								or string.format("将派遣 %d 人（阵亡 %d）", deployCount, deadCount)
						end
					end
				end

				MI_StyleBtn(btnQrf, COL.btnAccent, COL.btnAccentHover, canCall)
				qrfHint:SetText(hint)
				btnQrf._canCall = canCall
			end

			btnQrf.DoClick = function()
				if btnQrf._canCall ~= true then return end
				MI_SendAction(fr._fspEnt, 3)
				fr:Close()
			end

			btnQrf.Think = MI_RefreshQrfCall
			MI_RefreshQrfCall()
		end

		local active = MI_GetActivePA()
		if IsValid(active) and active:GetPAActive() then
			local hint = vgui.Create("DLabel", body)
			hint:Dock(TOP)
			hint:SetTall(sc(28))
			hint:DockMargin(0, sc(14), 0, 0)
			hint:SetFont(MI_Font(14, 600))
			hint:SetTextColor(COL.warn)
			hint:SetContentAlignment(5)
			if active == ent then
				hint:SetText("设施广播进行中")
			else
				hint:SetText("其他终端正在广播")
			end
		end
	end

	function fr.ShowPanel()
		fr._view = "panel"
		MI_ClearBody()

		local panelView = vgui.Create("DPanel", body)
		panelView:Dock(FILL)
		panelView:DockMargin(0, 0, 0, sc(6))

		local btnSpeak = vgui.Create("DButton", body)
		btnSpeak:Dock(BOTTOM)
		btnSpeak:SetTall(sc(48))
		btnSpeak:DockMargin(0, 0, 0, sc(6))

		local function MI_RefreshPABtn()
			local lp = LocalPlayer()
			local myEnt = fr._fspEnt
			local active = MI_GetActivePA()
			local mineActive = IsValid(myEnt) and myEnt.GetPAActive and myEnt:GetPAActive() and myEnt:GetOperator() == lp
			local otherActive = IsValid(active) and active ~= myEnt and active.GetPAActive and active:GetPAActive()

			local cdLeft = 0
			if IsValid(myEnt) and myEnt.GetPACooldownUntil then
				cdLeft = math.max(0, (myEnt:GetPACooldownUntil() or 0) - CurTime())
			end

			if mineActive then
				btnSpeak:SetText("结束广播")
				MI_StyleBtn(btnSpeak, COL.btnWarn, COL.btnWarnHover, true)
				btnSpeak.DoClick = function()
					MI_SendAction(myEnt, 2)
					fr:Close()
				end
			elseif otherActive then
				btnSpeak:SetText("其他终端正在广播")
				MI_StyleBtn(btnSpeak, nil, nil, false)
				btnSpeak.DoClick = function() end
			elseif cdLeft > 0 then
				btnSpeak:SetText(string.format("广播冷却 (%.0fs)", cdLeft))
				MI_StyleBtn(btnSpeak, nil, nil, false)
				btnSpeak.DoClick = function() end
			else
				btnSpeak:SetText("开始广播")
				MI_StyleBtn(btnSpeak, COL.btnWarn, COL.btnWarnHover, true)
				btnSpeak.DoClick = function()
					MI_SendAction(myEnt, 1)
					fr:Close()
				end
			end
		end

		btnSpeak.Think = MI_RefreshPABtn
		MI_RefreshPABtn()

		panelView.Paint = function(_, w, h)
			local pad = sc(8)
			local cfg = MissionIntro.FacilityStatusPanel or {}
			local micR = tonumber(cfg.mic_radius) or 158
			local cdSec = tonumber(cfg.pa_cooldown) or 30
			local maxSec = tonumber(cfg.pa_max_duration) or 20

			draw.RoundedBox(sc(6), pad, pad, w - pad * 2, h - pad * 2, COL.inner)
			surface.SetDrawColor(COL.border)
			surface.DrawOutlinedRect(pad + sc(8), pad + sc(8), w - (pad + sc(8)) * 2, h - (pad + sc(8)) * 2, sc(2))

			draw.SimpleText("INFORMATION MONITOR", MI_Font(14, 500), w - pad - sc(16), pad + sc(16), COL.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			draw.SimpleText("设施面板", MI_Font(26, 700), w * 0.5, pad + sc(44), COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			local science, classd, scpCount, unknown = 0, 0, 0, 0
			if IsValid(fr._fspEnt) then
				science = fr._fspEnt:GetScienceCount() or 0
				classd = fr._fspEnt:GetClassDCount() or 0
				scpCount = fr._fspEnt.GetScpCount and fr._fspEnt:GetScpCount() or 0
				unknown = fr._fspEnt:GetUnknownCount() or 0
			end

			local statsY = pad + sc(88)
			local lineH = sc(30)
			draw.SimpleText("科研人数  " .. tostring(science) .. "  人", MI_Font(20, 600), w * 0.5, statsY, COL.science, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText("D级人员  " .. tostring(classd) .. "  人", MI_Font(20, 600), w * 0.5, statsY + lineH, COL.classd, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText("SCP异常  " .. tostring(scpCount) .. "  人", MI_Font(20, 600), w * 0.5, statsY + lineH * 2, COL.scp, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText("未知单位  " .. tostring(unknown) .. "  人", MI_Font(20, 600), w * 0.5, statsY + lineH * 3, COL.unknown, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			local paY = statsY + lineH * 4 + sc(20)
			surface.SetDrawColor(COL.border.r, COL.border.g, COL.border.b, 80)
			surface.DrawLine(pad + sc(24), paY, w - pad - sc(24), paY)

			draw.SimpleText("设施广播", MI_Font(20, 700), w * 0.5, paY + sc(12), COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText("全图语音 + 文字 · 拾音约 " .. tostring(micR), MI_Font(13, 500), w * 0.5, paY + sc(38), COL.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(string.format("单次最长 %d 秒 · 冷却 %d 秒", maxSec, cdSec), MI_Font(13, 500), w * 0.5, paY + sc(58), COL.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			local entRef = fr._fspEnt
			local paStatusY = paY + sc(88)
			if IsValid(entRef) and entRef.GetPAActive and entRef:GetPAActive() then
				local left = 0
				if entRef.GetPAEndAt then
					left = math.max(0, (entRef:GetPAEndAt() or 0) - CurTime())
				end
				draw.SimpleText(string.format("广播中 · 剩余 %.0f 秒", left), MI_Font(16, 700), w * 0.5, paStatusY, COL.ok, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			else
				local cdLeft = 0
				if IsValid(entRef) and entRef.GetPACooldownUntil then
					cdLeft = math.max(0, (entRef:GetPACooldownUntil() or 0) - CurTime())
				end
				if cdLeft > 0 then
					draw.SimpleText(string.format("冷却中 · %.0f 秒", cdLeft), MI_Font(16, 700), w * 0.5, paStatusY, COL.warn, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				else
					draw.SimpleText("广播状态：待机", MI_Font(16, 700), w * 0.5, paStatusY, COL.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				end
			end

			if MissionIntro.IsFacilityStatusPanelActive and not MissionIntro.IsFacilityStatusPanelActive() then
				draw.SimpleText("（非 RXsend 回合 · 数据仅供参考）", MI_Font(12, 500), w * 0.5, h - pad - sc(12), COL.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end

		if MissionIntro.IsFacilityStatusPanelActive and MissionIntro.IsFacilityStatusPanelActive() then
			local btnQrf = vgui.Create("DButton", body)
			btnQrf:Dock(BOTTOM)
			btnQrf:SetTall(sc(40))
			btnQrf:DockMargin(0, 0, 0, sc(8))
			btnQrf:SetText(MissionIntro.L and MissionIntro.L("fsp_qrf_call") or "呼叫 快速反应部队")

			local function MI_RefreshQrfCall()
				local canCall = true
				if MissionIntro.IsFacilityQrfDeployCalled and MissionIntro.IsFacilityQrfDeployCalled() then
					canCall = false
				elseif not MissionIntro.IsPlayerSiteDirector or not MissionIntro.IsPlayerSiteDirector(LocalPlayer()) then
					canCall = false
				elseif MissionIntro.IsFacilityQrfCallTimeReady and not MissionIntro.IsFacilityQrfCallTimeReady() then
					canCall = false
				elseif (MissionIntro.GetFacilityQrfEligibleDeadCount and MissionIntro.GetFacilityQrfEligibleDeadCount() or 0) < 1 then
					canCall = false
				end
				MI_StyleBtn(btnQrf, COL.btnAccent, COL.btnAccentHover, canCall)
				btnQrf._canCall = canCall
			end

			btnQrf.DoClick = function()
				if btnQrf._canCall ~= true then return end
				MI_SendAction(fr._fspEnt, 3)
				fr:Close()
			end
			btnQrf.Think = MI_RefreshQrfCall
			MI_RefreshQrfCall()
		end

	end

	fr.ShowPanel()

	fr.Think = function()
		if not IsValid(fr._fspEnt) then
			fr:Close()
		end
	end

	fr.OnClose = function()
		if MissionIntro._fspHudPanel == fr then
			MissionIntro._fspHudPanel = nil
		end
		gui.EnableScreenClicker(false)
	end

	function fr:OnRemove()
		if MissionIntro._fspHudPanel == self then
			MissionIntro._fspHudPanel = nil
		end
		gui.EnableScreenClicker(false)
	end

	timer.Simple(0, function()
		if not IsValid(fr) then return end
		local closeBtn = fr.btnClose
		if IsValid(closeBtn) then
			closeBtn:SetSize(sc(24), sc(24))
		end
	end)
end

net.Receive("MissionIntro_FSP_Open", function()
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	MissionIntro.OpenFacilityStatusPanelHud(ent)
end)

net.Receive("MissionIntro_FSP_Chat", function()
	local speaker = net.ReadEntity()
	local text = net.ReadString()
	if not IsValid(speaker) or not isstring(text) or text == "" then return end

	chat.AddText(
		Color(255, 180, 80), "[设施广播] ",
		Color(180, 220, 255), speaker:Nick(),
		color_white, ": ",
		text
	)
end)

local function MI_CleanupFacilityClientUi()
	if MissionIntro.CloseFacilityStatusPanelHud then
		MissionIntro.CloseFacilityStatusPanelHud()
	end
	if MissionIntro.StopFacilityGallery then
		MissionIntro.StopFacilityGallery()
	elseif MissionIntro.StopFacilitySecurityGallery then
		MissionIntro.StopFacilitySecurityGallery()
	end
end

for _, hookName in ipairs({
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
	"PostCleanupMap",
	"ZB_PreRoundStart",
	"ZB_EndRound",
}) do
	hook.Add(hookName, "MissionIntro_FacilityClientUiReset", MI_CleanupFacilityClientUi)
end

hook.Add("Think", "MissionIntro_FacilityClientUiModeWatch", function()
	local rxActive = MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive() == true
	if MissionIntro._facilityClientUiRxActive == nil then
		MissionIntro._facilityClientUiRxActive = rxActive
		return
	end
	if MissionIntro._facilityClientUiRxActive == rxActive then return end
	MissionIntro._facilityClientUiRxActive = rxActive
	MI_CleanupFacilityClientUi()
end)
