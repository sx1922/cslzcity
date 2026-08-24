MissionIntro = MissionIntro or {}
MissionIntro._ettHudPanel = MissionIntro._ettHudPanel or nil

local COL = {
	bg = Color(10, 14, 22, 245),
	border = Color(72, 130, 210, 255),
	title = Color(200, 220, 255),
	text = Color(235, 240, 248),
	dim = Color(140, 150, 168),
	accent = Color(72, 130, 210),
	warn = Color(220, 90, 70),
	ok = Color(80, 200, 120),
	btn = Color(42, 88, 160),
	btnHover = Color(58, 118, 200),
	btnDisabled = Color(55, 60, 72),
}

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 16, weight = weight or 600 })
	end
	return "DermaDefault"
end

local function MI_HudSize()
	local cfg = MissionIntro.EttPanel or {}
	return tonumber(cfg.hud_w) or 560, tonumber(cfg.hud_h) or 480
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
		draw.RoundedBox(6, 0, 0, w, h, col)
	end
	btn:SetEnabled(enabled ~= false)
end

local function MI_GetDangerFromEnt(ent)
	if IsValid(ent) then
		return math.Clamp(ent:GetDangerLevel() or 0, 0, 100)
	end
	return math.Clamp(tonumber(MissionIntro._ettDangerLevel) or 0, 0, 100)
end

local function MI_DangerAccent(level)
	if level >= 100 then return COL.warn end
	if level >= 75 then return Color(220, 150, 60) end
	return COL.accent
end

local function MI_ClearChildren(pnl)
	for _, ch in ipairs(pnl:GetChildren()) do
		if IsValid(ch) then
			ch:Remove()
		end
	end
end

local function MI_BuildDangerDetail(parent, ent)
	MI_ClearChildren(parent)

	local level = MI_GetDangerFromEnt(ent)
	local called = IsValid(ent) and ent:GetReinforcementsCalled()
	local eta = IsValid(ent) and (ent:GetReinforcementsEta() or 0) or 0
	local left = math.max(0, eta - CurTime())

	local box = vgui.Create("DPanel", parent)
	box:Dock(FILL)
	box:DockMargin(12, 8, 12, 8)
	box.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(16, 22, 34, 255))
	end

	local title = vgui.Create("DLabel", box)
	title:Dock(TOP)
	title:DockMargin(12, 12, 12, 6)
	title:SetFont(MI_Font(22, 700))
	title:SetTextColor(COL.title)
	title:SetText(MissionIntro.L("ett_hud_danger_title"))
	title:SetContentAlignment(5)
	title:SetTall(28)

	local pctWrap = vgui.Create("DPanel", box)
	pctWrap:Dock(TOP)
	pctWrap:SetTall(88)
	pctWrap:DockMargin(10, 4, 10, 10)
	pctWrap.Paint = function(self, w, h)
		local lvl = MI_GetDangerFromEnt(ent)
		draw.RoundedBox(6, 0, 0, w, h, Color(12, 18, 30, 255))
		surface.SetDrawColor(COL.accent.r, COL.accent.g, COL.accent.b, 40)
		surface.DrawRect(8, h * 0.5 - 1, w - 16, 2)

		local pctText = string.format("%.1f%%", lvl)
		local pctCol = MI_DangerAccent(lvl)
		local pctFont = MI_Font(48, 800)
		draw.SimpleText(pctText, pctFont, w * 0.5, h * 0.5, pctCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local sub = vgui.Create("DLabel", box)
	sub:Dock(TOP)
	sub:DockMargin(14, 0, 14, 10)
	sub:SetFont(MI_Font(17, 500))
	sub:SetTextColor(COL.dim)
	sub:SetWrap(true)
	sub:SetAutoStretchVertical(true)
	sub:SetText(MissionIntro.L("ett_hud_danger_desc"))

	if called and left > 0 then
		local etaLbl = vgui.Create("DLabel", box)
		etaLbl:Dock(TOP)
		etaLbl:DockMargin(14, 4, 14, 8)
		etaLbl:SetFont(MI_Font(17, 600))
		etaLbl:SetTextColor(COL.ok)
		etaLbl:SetText(MissionIntro.L("ett_hud_reinforce_eta", math.ceil(left)))
		etaLbl:SetContentAlignment(5)
	elseif called then
		local doneLbl = vgui.Create("DLabel", box)
		doneLbl:Dock(TOP)
		doneLbl:DockMargin(14, 4, 14, 8)
		doneLbl:SetFont(MI_Font(17, 600))
		doneLbl:SetTextColor(COL.ok)
		doneLbl:SetText(MissionIntro.L("ett_hud_reinforce_done"))
		doneLbl:SetContentAlignment(5)
	end
end

function MissionIntro.CloseEttPanelHud()
	if IsValid(MissionIntro._ettHudPanel) then
		MissionIntro._ettHudPanel:Remove()
	end
	MissionIntro._ettHudPanel = nil
end

function MissionIntro.OpenEttPanelHud(ent)
	if not IsValid(ent) then return end

	MissionIntro.CloseEttPanelHud()

	local isEtt = MissionIntro.IsPttrbPlayer and MissionIntro.IsPttrbPlayer(LocalPlayer())
	local level = MI_GetDangerFromEnt(ent)
	local canCall = isEtt
		and level >= 100
		and not ent:GetReinforcementsCalled()
		and (MissionIntro._ettReinforcementsCalled ~= true)

	local hudW, hudH = MI_HudSize()
	local fr = vgui.Create("DFrame")
	fr:SetSize(hudW, hudH)
	fr:Center()
	fr:MakePopup()
	fr:SetTitle("")
	fr:ShowCloseButton(true)
	fr._ettEnt = ent
	MissionIntro._ettHudPanel = fr

	fr.Paint = function(self, w, h)
		draw.RoundedBox(10, 0, 0, w, h, COL.bg)
		surface.SetDrawColor(COL.border)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
		draw.SimpleText(MissionIntro.L("ett_hud_title"), MI_Font(24, 800), w * 0.5, 22, COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	local body = vgui.Create("DPanel", fr)
	body:Dock(FILL)
	body:DockMargin(8, 36, 8, 8)
	body.Paint = function() end

	local view = vgui.Create("DPanel", body)
	view:Dock(FILL)
	view:DockMargin(0, 0, 0, 132)
	view.Paint = function() end
	MI_BuildDangerDetail(view, ent)

	local menu = vgui.Create("DPanel", body)
	menu:Dock(BOTTOM)
	menu:SetTall(124)
	menu.Paint = function() end

	local btn1 = vgui.Create("DButton", menu)
	btn1:Dock(TOP)
	btn1:SetTall(54)
	btn1:DockMargin(0, 0, 0, 8)
	btn1:SetText("1 · " .. MissionIntro.L("ett_hud_btn_danger"))
	MI_StyleBtn(btn1, true)
	btn1.DoClick = function()
		MI_BuildDangerDetail(view, ent)
	end

	local btn2 = vgui.Create("DButton", menu)
	btn2:Dock(TOP)
	btn2:SetTall(54)
	local btn2Text = "2 · " .. MissionIntro.L("ett_hud_btn_reinforce")
	if not isEtt then
		btn2Text = btn2Text .. " (" .. MissionIntro.L("ett_hud_ett_only") .. ")"
	elseif level < 100 then
		btn2Text = btn2Text .. " (" .. MissionIntro.L("ett_hud_need_100") .. ")"
	elseif ent:GetReinforcementsCalled() then
		btn2Text = btn2Text .. " (" .. MissionIntro.L("ett_hud_already_called") .. ")"
	end
	btn2:SetText(btn2Text)
	MI_StyleBtn(btn2, canCall)
	btn2.DoClick = function()
		if not canCall then return end
		net.Start("MissionIntro_EttPanelAction")
			net.WriteEntity(ent)
			net.WriteUInt(2, 4)
		net.SendToServer()
		fr:Close()
	end

	fr.OnClose = function()
		if MissionIntro._ettHudPanel == fr then
			MissionIntro._ettHudPanel = nil
		end
	end
end

net.Receive("MissionIntro_EttPanelOpen", function()
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	MissionIntro.OpenEttPanelHud(ent)
end)
