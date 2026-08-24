MissionIntro = MissionIntro or {}
MissionIntro._adminPanel = MissionIntro._adminPanel or nil
MissionIntro._facilityAdminPanel = MissionIntro._facilityAdminPanel or nil
MissionIntro._scpAdminPanel = MissionIntro._scpAdminPanel or nil
MissionIntro._adminActiveCtx = MissionIntro._adminActiveCtx or nil
MissionIntro._adminCtxByContainer = MissionIntro._adminCtxByContainer or setmetatable({}, { __mode = "k" })

local COL = {
	text = Color(20, 22, 28),
	textDim = Color(70, 76, 88),
	rowBg = Color(238, 241, 246),
	rowBgAlt = Color(228, 232, 240),
	btn = Color(42, 118, 210),
	btnHover = Color(58, 140, 235),
	btnGreen = Color(34, 150, 85),
	btnGreenHover = Color(44, 175, 100),
	btnGray = Color(95, 102, 115),
	btnGrayHover = Color(115, 122, 135),
	btnRed = Color(168, 38, 48),
	btnRedHover = Color(198, 52, 62),
	border = Color(180, 188, 200),
}

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 16, weight = weight or 600 })
	end
	return "DermaDefault"
end

local function MI_StyleLabel(lbl, dim)
	lbl:SetFont(MI_Font(dim and 14 or 16, dim and 500 or 600))
	lbl:SetTextColor(dim and COL.textDim or COL.text)
end

local function MI_StyleButton(btn, accent)
	accent = accent or "blue"
	btn:SetFont(MI_Font(15, 700))
	btn:SetTextColor(Color(255, 255, 255))
	btn:SetContentAlignment(5)

	local base, hover
	if accent == "green" then
		base, hover = COL.btnGreen, COL.btnGreenHover
	elseif accent == "gray" then
		base, hover = COL.btnGray, COL.btnGrayHover
	elseif accent == "red" then
		base, hover = COL.btnRed, COL.btnRedHover
	elseif accent == "orange" then
		base, hover = Color(200, 110, 35), Color(220, 130, 50)
	else
		base, hover = COL.btn, COL.btnHover
	end

	btn.Paint = function(self, w, h)
		local col = self:IsDown() and Color(base.r * 0.85, base.g * 0.85, base.b * 0.85) or (self:IsHovered() and hover or base)
		draw.RoundedBox(6, 0, 0, w, h, col)
	end
end

local function MI_IsDockContainer(container)
	return IsValid(container) and not container.AddItem
end

local function MI_AddToContainer(container, pnl, tall)
	if not IsValid(container) or not IsValid(pnl) then return end

	if container.AddItem then
		container:AddItem(pnl)
		return
	end

	pnl:SetParent(container)
	pnl:Dock(TOP)
	if isnumber(tall) then
		pnl:SetTall(tall)
	end
	local cw = container:GetWide()
	if cw and cw > 0 then
		pnl:SetWide(cw)
	end
	if container.InvalidateLayout then
		container:InvalidateLayout(true)
	end
end

local function MI_FinishContainerLayout(container)
	if not MI_IsDockContainer(container) then return end
	if container.InvalidateLayout then
		container:InvalidateLayout(true)
	end
	timer.Simple(0, function()
		if not IsValid(container) or not MI_IsDockContainer(container) then return end
		if container.SizeToChildren then
			container:SizeToChildren(false, true)
		end
		if container.InvalidateLayout then
			container:InvalidateLayout(true)
		end
	end)
end

local function MI_GetCheckboxChecked(cb, rowData)
	if rowData and rowData.checked ~= nil then
		return rowData.checked == true
	end
	if not IsValid(cb) then return false end
	if cb.GetChecked then return cb:GetChecked() end
	if cb.GetValue then return cb:GetValue() == 1 end
	return false
end

local function MI_SetCheckboxChecked(cb, checked, rowData)
	checked = checked == true
	if rowData then
		rowData.checked = checked
	end
	if not IsValid(cb) then return end
	if cb.SetValue then
		cb:SetValue(checked and 1 or 0)
	end
	if cb.SetChecked then
		cb:SetChecked(checked)
	end
end

local function MI_RegisterAdminCtx(ctx)
	if not ctx or not IsValid(ctx.container) then return end
	MissionIntro._adminCtxByContainer[ctx.container] = ctx
	MissionIntro._adminActiveCtx = ctx
end

local function MI_UnregisterAdminCtx(ctx)
	if not ctx then return end
	if IsValid(ctx.container) then
		MissionIntro._adminCtxByContainer[ctx.container] = nil
	end
	if ctx == MissionIntro._adminActiveCtx then
		MissionIntro._adminActiveCtx = nil
	end
end

function MissionIntro.RebuildAdminPanelFull(ctx)
	ctx = MI_ResolveAdminCtx(ctx)
	if not ctx or not IsValid(ctx.container) then return end

	local kind = ctx.buildKind or "main"
	if kind == "facility" and MissionIntro.BuildFacilityAdminCPanel then
		MissionIntro.BuildFacilityAdminCPanel(ctx.container)
	elseif kind == "scp" and MissionIntro.BuildScpAdminCPanel then
		MissionIntro.BuildScpAdminCPanel(ctx.container)
	elseif MissionIntro.BuildAdminCPanel then
		MissionIntro.BuildAdminCPanel(ctx.container)
	end
end

local function MI_GetCtx(ctx)
	if ctx and ctx.rows then return ctx end
	return MissionIntro._adminActiveCtx
end

local function MI_ResolveAdminCtx(ctx)
	ctx = MI_GetCtx(ctx)
	if ctx and IsValid(ctx.container) then
		MI_RegisterAdminCtx(ctx)
		return ctx
	end

	local candidates = {}

	if MissionIntro._adminCtxByContainer then
		for container, candidate in pairs(MissionIntro._adminCtxByContainer) do
			if IsValid(container) and candidate then
				candidates[#candidates + 1] = candidate
			else
				MissionIntro._adminCtxByContainer[container] = nil
			end
		end
	end

	if IsValid(MissionIntro._adminPanel) and IsValid(MissionIntro._adminPanel._inner) then
		candidates[#candidates + 1] = MissionIntro._adminPanel._inner._miAdminCtx
	end
	if IsValid(MissionIntro._facilityAdminPanel) and IsValid(MissionIntro._facilityAdminPanel._inner) then
		candidates[#candidates + 1] = MissionIntro._facilityAdminPanel._inner._miAdminCtx
	end
	if IsValid(MissionIntro._scpAdminPanel) and IsValid(MissionIntro._scpAdminPanel._inner) then
		candidates[#candidates + 1] = MissionIntro._scpAdminPanel._inner._miAdminCtx
	end

	for _, candidate in ipairs(candidates) do
		if candidate and IsValid(candidate.container) then
			MI_RegisterAdminCtx(candidate)
			return candidate
		end
	end

	return ctx
end

local function MI_EnsureAdminCanvas(ctx)
	if not ctx then return false end

	if IsValid(ctx.canvas) then return true end

	if IsValid(ctx.scroll) and ctx.scroll.GetCanvas then
		ctx.canvas = ctx.scroll:GetCanvas()
	end

	if not IsValid(ctx.canvas) and IsValid(ctx.scroll) then
		for _, row in ipairs(ctx.rows or {}) do
			if IsValid(row.line) then
				ctx.canvas = row.line:GetParent()
				break
			end
		end
	end

	return IsValid(ctx.canvas)
end

local function MI_ForeachAdminCheckbox(fn, ctx)
	ctx = MI_GetCtx(ctx)
	if not ctx then return end
	for _, row in ipairs(ctx.rows or {}) do
		if IsValid(row.cb) then
			fn(row.cb, row)
		end
	end
end

local function MI_GetAdminStatusForPlayer(ply)
	if not IsValid(ply) then
		return { dead = true, playing = false, synced = true }
	end

	local key = MissionIntro.GetPlayerTargetKey and MissionIntro.GetPlayerTargetKey(ply) or ""
	local cached = (isstring(key) and key ~= "") and MissionIntro._adminStatusByKey and MissionIntro._adminStatusByKey[key] or nil

	if cached then
		return {
			dead = cached.dead == true,
			playing = cached.playing == true,
			synced = true,
		}
	end

	return {
		dead = ply:GetNWBool("MissionIntro_AdminDead", false),
		playing = ply:GetNWBool("MissionIntro_IntroPlaying", false),
		alive = ply:GetNWBool("MissionIntro_AdminAlive", false),
		synced = ply:GetNWBool("MissionIntro_AdminDead", false) or ply:GetNWBool("MissionIntro_AdminAlive", false),
	}
end

function MissionIntro.RequestAdminStatusSync()
	if not MissionIntro.CanManage or not MissionIntro.CanManage() then return end
	net.Start("MissionIntro_AdminStatusRequest")
	net.SendToServer()
end

local function MI_AddHelp(container, text, dim)
	local lbl = vgui.Create("DLabel")
	lbl:SetAutoStretchVertical(true)
	lbl:SetWrap(true)
	lbl:SetText(text)
	lbl:DockMargin(0, 2, 0, 6)
	MI_StyleLabel(lbl, dim)
	MI_AddToContainer(container, lbl)
	return lbl
end

local function MI_IsPlayerDeadForAdmin(ply)
	if not IsValid(ply) then return true end

	local st = MI_GetAdminStatusForPlayer(ply)
	if st.synced then
		return st.dead == true
	end

	if MissionIntro.IsPlayerSpectatingForAdmin and MissionIntro.IsPlayerSpectatingForAdmin(ply) then
		return true
	end
	if ply:Team() == TEAM_SPECTATOR then return true end
	if not ply:Alive() then return true end
	if ply:Health() <= 0 then return true end

	return false
end

local function MI_ShouldSkipAdminPlayerRefresh(ply)
	return MissionIntro.IsPlayerOnSpectatorBench
		and MissionIntro.IsPlayerOnSpectatorBench(ply)
end

local function MI_CountEligiblePlayers()
	local n = 0
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and not MI_ShouldSkipAdminPlayerRefresh(ply) then
			n = n + 1
		end
	end
	return n
end

local function MI_IsIntroPlayingForAdmin(ply)
	if not IsValid(ply) then return false end
	return MI_GetAdminStatusForPlayer(ply).playing == true
end

local function MI_PlayerStatus(ply)
	if not IsValid(ply) then return "?" end
	if MI_IsPlayerDeadForAdmin(ply) then
		return MissionIntro.L("panel_dead")
	end
	if MI_IsIntroPlayingForAdmin(ply) then
		return MissionIntro.L("panel_playing")
	end
	return MissionIntro.L("panel_alive")
end

local function MI_StatusColor(ply)
	if not IsValid(ply) then return COL.textDim end
	if MI_IsPlayerDeadForAdmin(ply) then
		return Color(180, 45, 45)
	end
	if MI_IsIntroPlayingForAdmin(ply) then
		return Color(42, 118, 210)
	end
	return COL.text
end

local function MI_CreatePlayerRow(canvas, ply, idx, ctx)
	local line = vgui.Create("DPanel", canvas)
	line:Dock(TOP)
	line:SetTall(30)
	line:DockMargin(0, 0, 0, 3)
	line.Paint = function(self, w, h)
		local bg = (idx % 2 == 0) and COL.rowBgAlt or COL.rowBg
		draw.RoundedBox(4, 0, 0, w, h, bg)
		surface.SetDrawColor(COL.border)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local cb = vgui.Create("DCheckBox", line)
	cb:Dock(LEFT)
	cb:SetWide(24)
	cb:DockMargin(8, 7, 6, 7)
	local targetKey = MissionIntro.GetPlayerTargetKey and MissionIntro.GetPlayerTargetKey(ply) or nil
	cb._miTargetKey = targetKey

	local rowData = {
		ply = ply,
		cb = cb,
		lbl = nil,
		line = line,
		checked = false,
		targetKey = targetKey,
	}

	cb.OnChange = function(_, val)
		rowData.checked = val == true or val == 1
	end

	local lbl = vgui.Create("DLabel", line)
	rowData.lbl = lbl
	lbl:Dock(FILL)
	lbl:DockMargin(0, 0, 8, 0)
	local tag = ""
	if IsValid(ply) and ply:GetNWBool("MissionIntro_IsEmployer", false) then
		tag = "    [" .. MissionIntro.L("mcd_employer_tag") .. "]"
	end
	lbl:SetText(ply:Nick() .. tag .. "    [" .. MI_PlayerStatus(ply) .. "]")
	MI_StyleLabel(lbl, false)
	lbl:SetTextColor(MI_StatusColor(ply))

	line:SetCursor("hand")
	function line:OnMousePressed(mc)
		if mc == MOUSE_LEFT and IsValid(cb) then
			MI_SetCheckboxChecked(cb, not MI_GetCheckboxChecked(cb, rowData), rowData)
		end
	end

	ctx.rows[#ctx.rows + 1] = rowData
	ctx.checkboxes[#ctx.checkboxes + 1] = cb

	return rowData
end

function MissionIntro.StopAdminSync()
	hook.Remove("Think", "MissionIntro_AdminSync")
	MissionIntro._adminSyncNext = nil
	MissionIntro._adminStatusSyncNext = nil
end

function MissionIntro.ClearAdminPlayerList(ctx)
	MissionIntro.StopAdminSync()

	ctx = ctx or MissionIntro._adminActiveCtx
	if ctx and IsValid(ctx.canvas) then
		ctx.canvas:Clear()
	end
	if ctx then
		ctx.rows = {}
		ctx.checkboxes = {}
		MI_UnregisterAdminCtx(ctx)
	end
end

function MissionIntro.RebuildAdminPlayerList(ctx)
	ctx = MI_ResolveAdminCtx(ctx)
	if not ctx then return end

	if not MI_EnsureAdminCanvas(ctx) then
		if IsValid(ctx.scroll) and ctx.scroll.GetCanvas then
			ctx.canvas = ctx.scroll:GetCanvas()
		end
	end
	if not IsValid(ctx.canvas) then
		if MissionIntro.RebuildAdminPanelFull then
			MissionIntro.RebuildAdminPanelFull(ctx)
		end
		return
	end

	local checkedKeys = {}
	for _, row in ipairs(ctx.rows or {}) do
		if MI_GetCheckboxChecked(row.cb, row) then
			local key = row.targetKey
			if isstring(key) and key ~= "" then
				checkedKeys[key] = true
			elseif IsValid(row.ply) and MissionIntro.GetPlayerTargetKey then
				local k = MissionIntro.GetPlayerTargetKey(row.ply)
				if isstring(k) and k ~= "" then
					checkedKeys[k] = true
				end
			end
		end
	end

	if IsValid(ctx.canvas) then
		ctx.canvas:Clear()
	end
	ctx.rows = {}
	ctx.checkboxes = {}

	MI_RegisterAdminCtx(ctx)

	local idx = 0
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or MI_ShouldSkipAdminPlayerRefresh(ply) then continue end
		idx = idx + 1
		local row = MI_CreatePlayerRow(ctx.canvas, ply, idx, ctx)
		if row and row.targetKey and checkedKeys[row.targetKey] then
			MI_SetCheckboxChecked(row.cb, true, row)
		end
	end

	MissionIntro.StartAdminSync(ctx)
	MissionIntro.RequestAdminStatusSync()
end

function MissionIntro.RefreshAdminPlayerList(ctx)
	ctx = MI_ResolveAdminCtx(ctx)
	if not ctx then return end

	if not MI_EnsureAdminCanvas(ctx) then
		if MissionIntro.RebuildAdminPanelFull then
			MissionIntro.RebuildAdminPanelFull(ctx)
		else
			MissionIntro.RebuildAdminPlayerList(ctx)
		end
		return
	end

	local canvas = ctx.canvas
	local aliveRows = {}
	local known = {}

	for _, row in ipairs(ctx.rows or {}) do
		if IsValid(row.ply) and MI_ShouldSkipAdminPlayerRefresh(row.ply) then
			if IsValid(row.line) then
				row.line:Remove()
			end
		elseif IsValid(row.ply) and IsValid(row.line) and IsValid(row.lbl) then
			known[row.ply] = true
			row.targetKey = MissionIntro.GetPlayerTargetKey and MissionIntro.GetPlayerTargetKey(row.ply) or row.targetKey
			if IsValid(row.cb) then
				row.cb._miTargetKey = row.targetKey
			end
			local tag = ""
			if row.ply:GetNWBool("MissionIntro_IsEmployer", false) then
				tag = "    [" .. MissionIntro.L("mcd_employer_tag") .. "]"
			end
			row.lbl:SetText(row.ply:Nick() .. tag .. "    [" .. MI_PlayerStatus(row.ply) .. "]")
			row.lbl:SetTextColor(MI_StatusColor(row.ply))
			aliveRows[#aliveRows + 1] = row
		elseif IsValid(row.line) then
			row.line:Remove()
		end
	end

	ctx.rows = aliveRows
	ctx.checkboxes = {}
	for _, row in ipairs(aliveRows) do
		if IsValid(row.cb) then
			ctx.checkboxes[#ctx.checkboxes + 1] = row.cb
		end
	end

	local idx = #aliveRows
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and not known[ply] and not MI_ShouldSkipAdminPlayerRefresh(ply) then
			idx = idx + 1
			MI_CreatePlayerRow(canvas, ply, idx, ctx)
			known[ply] = true
		end
	end

	if IsValid(canvas) and canvas.InvalidateLayout then
		canvas:InvalidateLayout(true)
	end
end

function MissionIntro.StartAdminSync(ctx)
	ctx = MI_GetCtx(ctx)
	if not ctx then return end
	MI_RegisterAdminCtx(ctx)
end

function MissionIntro.SendAdminStart(targets, factionId)
	net.Start("MissionIntro_AdminStart")
		net.WriteUInt(#targets, 8)
		for _, ply in ipairs(targets) do
			local key = MissionIntro.GetPlayerTargetKey and MissionIntro.GetPlayerTargetKey(ply)
			net.WriteString(isstring(key) and key or "")
		end
		net.WriteString(factionId or "")
	net.SendToServer()
end

local function MI_GetAdminTargets(ctx)
	ctx = MI_GetCtx(ctx)
	local targets = {}
	local seen = {}

	for _, row in ipairs(ctx and ctx.rows or {}) do
		if not MI_GetCheckboxChecked(row.cb, row) then continue end
		local ply = row.ply
		if not IsValid(ply) or not ply:IsPlayer() then
			if isstring(row.cb._miTargetKey) and row.cb._miTargetKey ~= "" and MissionIntro.FindPlayerByTargetKey then
				ply = MissionIntro.FindPlayerByTargetKey(row.cb._miTargetKey)
			end
		end
		if IsValid(ply) and ply:IsPlayer() and not seen[ply] then
			seen[ply] = true
			targets[#targets + 1] = ply
		end
	end

	return targets
end

function MissionIntro.TryAdminStartFaction(factionId)
	local targets = MI_GetAdminTargets()
	if #targets == 0 then
		surface.PlaySound("buttons/button10.wav")
		return false
	end

	MissionIntro.SendAdminStart(targets, factionId)
	surface.PlaySound("buttons/button14.wav")
	return true
end

function MissionIntro.BuildAdminPlayerPicker(container, scrollTall, buildKind)
	scrollTall = scrollTall or 300
	buildKind = buildKind or "main"

	MI_AddHelp(container, MissionIntro.L("tool_desc"), true)
	MI_AddHelp(container, MissionIntro.L("panel_select_hint"), false)

	local row = vgui.Create("DPanel")
	row:SetTall(36)
	row.Paint = function() end

	local btnAll = vgui.Create("DButton", row)
	btnAll:SetText(MissionIntro.L("panel_select_all"))
	btnAll:Dock(LEFT)
	btnAll:SetWide(88)
	btnAll:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnAll, "gray")

	local btnNone = vgui.Create("DButton", row)
	btnNone:SetText(MissionIntro.L("panel_select_none"))
	btnNone:Dock(LEFT)
	btnNone:SetWide(88)
	btnNone:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnNone, "gray")

	local btnRefresh = vgui.Create("DButton", row)
	btnRefresh:SetText(MissionIntro.L("panel_refresh"))
	btnRefresh:Dock(LEFT)
	btnRefresh:SetWide(72)
	MI_StyleButton(btnRefresh, "blue")
	btnRefresh.DoClick = function()
		if not IsValid(container) then return end
		local activeCtx = MI_ResolveAdminCtx(container._miAdminCtx)
		if not activeCtx or not MI_EnsureAdminCanvas(activeCtx) then
			MissionIntro.RebuildAdminPanelFull({ container = container, buildKind = buildKind })
		else
			MissionIntro.RebuildAdminPlayerList(activeCtx)
		end
		MissionIntro.RequestAdminStatusSync()
		timer.Simple(0.2, function()
			if not IsValid(container) then return end
			local lateCtx = MI_ResolveAdminCtx(container._miAdminCtx)
			if lateCtx and MI_EnsureAdminCanvas(lateCtx) and MissionIntro.RefreshAdminPlayerList then
				MissionIntro.RefreshAdminPlayerList(lateCtx)
			end
		end)
		surface.PlaySound("buttons/button15.wav")
	end

	MI_AddToContainer(container, row, 36)

	local scroll = vgui.Create("DScrollPanel")
	scroll:SetTall(scrollTall)
	MI_AddToContainer(container, scroll, scrollTall)

	local canvas = scroll.GetCanvas and scroll:GetCanvas() or scroll
	local ctx = {
		container = container,
		scroll = scroll,
		canvas = canvas,
		scrollTall = scrollTall,
		buildKind = buildKind,
		rows = {},
		checkboxes = {},
	}

	container._miAdminCtx = ctx
	MI_RegisterAdminCtx(ctx)

	local idx = 0
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or MI_ShouldSkipAdminPlayerRefresh(ply) then continue end
		idx = idx + 1
		MI_CreatePlayerRow(canvas, ply, idx, ctx)
	end

	MissionIntro.StartAdminSync(ctx)
	MissionIntro.RequestAdminStatusSync()

	btnAll.DoClick = function()
		MI_ForeachAdminCheckbox(function(cb, rowData)
			MI_SetCheckboxChecked(cb, true, rowData)
		end, ctx)
		surface.PlaySound("buttons/button15.wav")
	end

	btnNone.DoClick = function()
		MI_ForeachAdminCheckbox(function(cb, rowData)
			MI_SetCheckboxChecked(cb, false, rowData)
		end, ctx)
		surface.PlaySound("buttons/button15.wav")
	end

	return function()
		return MI_GetAdminTargets(ctx)
	end
end

function MissionIntro.BuildFacilityIntroButtons(container)
	local facilityBlock = vgui.Create("DPanel")
	facilityBlock:SetTall(188)
	facilityBlock:DockMargin(0, 8, 0, 0)
	facilityBlock.Paint = function() end

	local facRow1 = vgui.Create("DPanel", facilityBlock)
	facRow1:Dock(TOP)
	facRow1:SetTall(40)
	facRow1:DockMargin(0, 0, 0, 6)
	facRow1.Paint = function() end

	local btnResearcher = vgui.Create("DButton", facRow1)
	btnResearcher:SetText(MissionIntro.L("panel_start_facility_researcher"))
	btnResearcher:Dock(LEFT)
	btnResearcher:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnResearcher, "gray")
	btnResearcher.DoClick = function() MissionIntro.TryAdminStartFaction("facility_researcher") end

	local btnDoctor = vgui.Create("DButton", facRow1)
	btnDoctor:SetText(MissionIntro.L("panel_start_facility_doctor"))
	btnDoctor:Dock(FILL)
	MI_StyleButton(btnDoctor, "gray")
	btnDoctor.DoClick = function() MissionIntro.TryAdminStartFaction("facility_doctor") end

	facRow1.PerformLayout = function(self, w, h)
		btnResearcher:SetWide(math.max(80, math.floor((w - 6) * 0.5)))
	end

	local facRow2 = vgui.Create("DPanel", facilityBlock)
	facRow2:Dock(TOP)
	facRow2:SetTall(40)
	facRow2:DockMargin(0, 0, 0, 6)
	facRow2.Paint = function() end

	local btnSenior = vgui.Create("DButton", facRow2)
	btnSenior:SetText(MissionIntro.L("panel_start_facility_senior"))
	btnSenior:Dock(LEFT)
	btnSenior:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnSenior, "gray")
	btnSenior.DoClick = function() MissionIntro.TryAdminStartFaction("facility_senior_scientist") end

	local btnEthics = vgui.Create("DButton", facRow2)
	btnEthics:SetText(MissionIntro.L("panel_start_facility_ethics"))
	btnEthics:Dock(FILL)
	MI_StyleButton(btnEthics, "gray")
	btnEthics.DoClick = function() MissionIntro.TryAdminStartFaction("facility_ethics") end

	facRow2.PerformLayout = function(self, w, h)
		btnSenior:SetWide(math.max(80, math.floor((w - 6) * 0.5)))
	end

	local facRow3 = vgui.Create("DPanel", facilityBlock)
	facRow3:Dock(TOP)
	facRow3:SetTall(40)
	facRow3:DockMargin(0, 0, 0, 6)
	facRow3.Paint = function() end

	local btnClassd = vgui.Create("DButton", facRow3)
	btnClassd:SetText(MissionIntro.L("panel_start_classd_impostor"))
	btnClassd:Dock(LEFT)
	btnClassd:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnClassd, "red")
	btnClassd.DoClick = function() MissionIntro.TryAdminStartFaction("classd_impostor") end

	local btnClassDPersonnel = vgui.Create("DButton", facRow3)
	btnClassDPersonnel:SetText(MissionIntro.L("panel_start_class_d_personnel"))
	btnClassDPersonnel:Dock(FILL)
	MI_StyleButton(btnClassDPersonnel, "orange")
	btnClassDPersonnel.DoClick = function() MissionIntro.TryAdminStartFaction("class_d_personnel") end

	facRow3.PerformLayout = function(self, w, h)
		btnClassd:SetWide(math.max(80, math.floor((w - 6) * 0.5)))
	end

	local facRow4 = vgui.Create("DPanel", facilityBlock)
	facRow4:Dock(TOP)
	facRow4:SetTall(40)
	facRow4.Paint = function() end

	local btnUiuSpy = vgui.Create("DButton", facRow4)
	btnUiuSpy:SetText(MissionIntro.L("panel_start_uiu_spy"))
	btnUiuSpy:Dock(LEFT)
	btnUiuSpy:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnUiuSpy, "blue")
	btnUiuSpy.DoClick = function() MissionIntro.TryAdminStartFaction("uiu_spy") end

	local btnMaynard = vgui.Create("DButton", facRow4)
	btnMaynard:SetText(MissionIntro.L("panel_start_dr_maynard"))
	btnMaynard:Dock(LEFT)
	btnMaynard:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnMaynard, "green")
	btnMaynard.DoClick = function() MissionIntro.TryAdminStartFaction("dr_maynard") end

	local btnCiSpy = vgui.Create("DButton", facRow4)
	btnCiSpy:SetText(MissionIntro.L("panel_start_ci_spy"))
	btnCiSpy:Dock(FILL)
	MI_StyleButton(btnCiSpy, "green")
	btnCiSpy.DoClick = function() MissionIntro.TryAdminStartFaction("ci_spy") end

	facRow4.PerformLayout = function(self, w, h)
		local third = math.max(72, math.floor((w - 12) / 3))
		btnUiuSpy:SetWide(third)
		btnMaynard:SetWide(third)
	end

	MI_AddToContainer(container, facilityBlock, 188)
end

function MissionIntro.BuildFacilitySecurityButtons(container)
	local secBlock = vgui.Create("DPanel")
	secBlock:SetTall(134)
	secBlock:DockMargin(0, 8, 0, 0)
	secBlock.Paint = function() end

	local function MI_AddSecRow(parent, buttons)
		local row = vgui.Create("DPanel", parent)
		row:Dock(TOP)
		row:SetTall(40)
		row:DockMargin(0, 0, 0, 6)
		row.Paint = function() end

		for i, spec in ipairs(buttons) do
			local btn = vgui.Create("DButton", row)
			btn:SetText(MissionIntro.L(spec.label_key))
			btn:Dock(LEFT)
			if i < #buttons then
				btn:DockMargin(0, 0, 6, 0)
			end
			MI_StyleButton(btn, spec.style or "gray")
			btn.DoClick = function()
				MissionIntro.TryAdminStartFaction(spec.faction_id)
			end
			spec.btn = btn
		end

		row.PerformLayout = function(self, w, h)
			local n = #buttons
			if n <= 0 then return end
			local gap = 6 * (n - 1)
			local each = math.max(72, math.floor((w - gap) / n))
			for _, spec in ipairs(buttons) do
				if IsValid(spec.btn) then
					spec.btn:SetWide(each)
				end
			end
		end
	end

	MI_AddSecRow(secBlock, {
		{ label_key = "panel_start_facility_security_rookie", faction_id = "facility_security_rookie", style = "gray" },
		{ label_key = "panel_start_facility_security_officer", faction_id = "facility_security_officer", style = "gray" },
	})
	MI_AddSecRow(secBlock, {
		{ label_key = "panel_start_facility_security_sergeant", faction_id = "facility_security_sergeant", style = "blue" },
		{ label_key = "panel_start_facility_security_warden", faction_id = "facility_security_warden", style = "blue" },
	})
	MI_AddSecRow(secBlock, {
		{ label_key = "panel_start_facility_security_captain", faction_id = "facility_security_captain", style = "red" },
	})

	MI_AddToContainer(container, secBlock, 134)

	local mtfBlock = vgui.Create("DPanel")
	mtfBlock:SetTall(46)
	mtfBlock:DockMargin(0, 8, 0, 0)
	mtfBlock.Paint = function() end

	local btnMtfDirector = vgui.Create("DButton", mtfBlock)
	btnMtfDirector:SetText(MissionIntro.L("panel_start_mtf_taskforce"))
	btnMtfDirector:Dock(FILL)
	MI_StyleButton(btnMtfDirector, "blue")
	btnMtfDirector.DoClick = function()
		MissionIntro.TryAdminStartFaction("facility_mtf_site_director")
	end

	MI_AddToContainer(container, mtfBlock, 46)

	local qrfBlock = vgui.Create("DPanel")
	qrfBlock:SetTall(46)
	qrfBlock:DockMargin(0, 8, 0, 0)
	qrfBlock.Paint = function() end

	local btnQrfBatch = vgui.Create("DButton", qrfBlock)
	btnQrfBatch:SetText(MissionIntro.L("panel_start_qrf_batch"))
	btnQrfBatch:Dock(FILL)
	MI_StyleButton(btnQrfBatch, "blue")
	btnQrfBatch.DoClick = function()
		MissionIntro.TryAdminStartFaction("facility_qrf_batch")
	end

	MI_AddToContainer(container, qrfBlock, 46)
end

function MissionIntro.BuildScpAdminButtons(container)
	local scpBlock = vgui.Create("DPanel")
	scpBlock:SetTall(142)
	scpBlock:DockMargin(0, 8, 0, 0)
	scpBlock.Paint = function() end

	local btnScp062de = vgui.Create("DButton", scpBlock)
	btnScp062de:SetText(MissionIntro.L("panel_start_facility_scp_062de"))
	btnScp062de:Dock(TOP)
	btnScp062de:SetTall(42)
	btnScp062de:DockMargin(0, 0, 0, 8)
	MI_StyleButton(btnScp062de, "blue")
	btnScp062de.DoClick = function()
		MissionIntro.TryAdminStartFaction("facility_scp_062de")
	end

	local btnScp0762 = vgui.Create("DButton", scpBlock)
	btnScp0762:SetText(MissionIntro.L("panel_start_facility_scp_0762"))
	btnScp0762:Dock(TOP)
	btnScp0762:SetTall(42)
	btnScp0762:DockMargin(0, 0, 0, 8)
	MI_StyleButton(btnScp0762, "blue")
	btnScp0762.DoClick = function()
		MissionIntro.TryAdminStartFaction("facility_scp_0762")
	end

	local btnScp912 = vgui.Create("DButton", scpBlock)
	btnScp912:SetText(MissionIntro.L("panel_start_facility_scp_912"))
	btnScp912:Dock(FILL)
	MI_StyleButton(btnScp912, "blue")
	btnScp912.DoClick = function()
		MissionIntro.TryAdminStartFaction("facility_scp_912")
	end

	MI_AddToContainer(container, scpBlock, 142)
end

local function MI_ResetContainer(container)
	if not IsValid(container) then return end
	MissionIntro.ClearAdminPlayerList(container._miAdminCtx)
	container._miAdminCtx = nil

	if container.ClearControls then
		container:ClearControls()
	elseif container.Clear then
		container:Clear()
	end
end

function MissionIntro.BuildFacilityAdminCPanel(container)
	if not IsValid(container) then return end

	MI_ResetContainer(container)

	if not MissionIntro.CanManage() then
		MI_AddHelp(container, MissionIntro.L("panel_admin_only"), false)
		return
	end

	MI_AddHelp(container, MissionIntro.L("panel_facility_desc"), true)
	MissionIntro.BuildAdminPlayerPicker(container, 320, "facility")
	MissionIntro.BuildFacilityIntroButtons(container)
	MissionIntro.BuildFacilitySecurityButtons(container)
	MI_AddHelp(container, MissionIntro.L("panel_facility_security_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_facility_mtf_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_facility_qrf_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_facility_sci_gallery_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_facility_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_facility_spawn_hint"), true)
	MI_FinishContainerLayout(container)
end

function MissionIntro.BuildScpAdminCPanel(container)
	if not IsValid(container) then return end

	MI_ResetContainer(container)

	if not MissionIntro.CanManage() then
		MI_AddHelp(container, MissionIntro.L("panel_admin_only"), false)
		return
	end

	MI_AddHelp(container, MissionIntro.L("panel_scp_desc"), true)
	MissionIntro.BuildAdminPlayerPicker(container, 320, "scp")
	MissionIntro.BuildScpAdminButtons(container)
	MI_AddHelp(container, MissionIntro.L("panel_scp_gallery_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_scp_spawn_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_scp_menu_hint"), true)
	MI_FinishContainerLayout(container)
end

function MissionIntro.OpenScpAdminHUD()
	if IsValid(MissionIntro._scpAdminPanel) then
		if IsValid(MissionIntro._scpAdminPanel._inner) then
			MissionIntro.BuildScpAdminCPanel(MissionIntro._scpAdminPanel._inner)
		end
		MissionIntro._scpAdminPanel:MakePopup()
		MissionIntro._scpAdminPanel:Center()
		return
	end

	local fr = vgui.Create("DFrame")
	fr:SetTitle(MissionIntro.L("panel_scp_title"))
	fr:SetSize(480, 520)
	fr:Center()
	fr:MakePopup()
	MissionIntro._scpAdminPanel = fr

	fr.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(248, 249, 252))
	end

	local cp = vgui.Create("DScrollPanel", fr)
	cp:Dock(FILL)
	cp:DockMargin(10, 10, 10, 10)

	local inner = vgui.Create("DPanel", cp:GetCanvas())
	fr._inner = inner
	inner:Dock(TOP)
	inner.Paint = function() end
	function inner:PerformLayout(w, h)
		local parent = self:GetParent()
		local pw = (IsValid(parent) and parent:GetWide() > 0) and parent:GetWide() or w
		if pw <= 0 then pw = 440 end
		self:SetWide(pw)
		self:SizeToChildren(false, true)
	end

	MissionIntro.BuildScpAdminCPanel(inner)

	function cp:OnSizeChanged(w, h)
		if IsValid(inner) then
			inner:InvalidateLayout(true)
		end
	end

	function fr:OnClose()
		MissionIntro.ClearAdminPlayerList(inner._miAdminCtx)
		inner._miAdminCtx = nil
		MissionIntro._scpAdminPanel = nil
	end
end

function MissionIntro.OpenFacilityAdminHUD()
	if IsValid(MissionIntro._facilityAdminPanel) then
		if IsValid(MissionIntro._facilityAdminPanel._inner) then
			MissionIntro.BuildFacilityAdminCPanel(MissionIntro._facilityAdminPanel._inner)
		end
		MissionIntro._facilityAdminPanel:MakePopup()
		MissionIntro._facilityAdminPanel:Center()
		return
	end

	local fr = vgui.Create("DFrame")
	fr:SetTitle(MissionIntro.L("panel_facility_title"))
	fr:SetSize(480, 760)
	fr:Center()
	fr:MakePopup()
	MissionIntro._facilityAdminPanel = fr

	fr.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(248, 249, 252))
	end

	local cp = vgui.Create("DScrollPanel", fr)
	cp:Dock(FILL)
	cp:DockMargin(10, 10, 10, 10)

	local inner = vgui.Create("DPanel", cp:GetCanvas())
	fr._inner = inner
	inner:Dock(TOP)
	inner.Paint = function() end
	function inner:PerformLayout(w, h)
		local parent = self:GetParent()
		local pw = (IsValid(parent) and parent:GetWide() > 0) and parent:GetWide() or w
		if pw <= 0 then pw = 440 end
		self:SetWide(pw)
		self:SizeToChildren(false, true)
	end

	MissionIntro.BuildFacilityAdminCPanel(inner)

	function cp:OnSizeChanged(w, h)
		if IsValid(inner) then
			inner:InvalidateLayout(true)
		end
	end

	function fr:OnClose()
		MissionIntro.ClearAdminPlayerList(inner._miAdminCtx)
		inner._miAdminCtx = nil
		MissionIntro._facilityAdminPanel = nil
	end
end

function MissionIntro.BuildAdminCPanel(container)
	if not IsValid(container) then return end

	MI_ResetContainer(container)

	if not MissionIntro.CanManage() then
		MI_AddHelp(container, MissionIntro.L("panel_admin_only"), false)
		return
	end

	MissionIntro.BuildAdminPlayerPicker(container, 300, "main")

	local startBlock = vgui.Create("DPanel")
	startBlock:SetTall(268)
	startBlock:DockMargin(0, 8, 0, 0)
	startBlock.Paint = function() end

	local startRowTop = vgui.Create("DPanel", startBlock)
	startRowTop:Dock(TOP)
	startRowTop:SetTall(40)
	startRowTop:DockMargin(0, 0, 0, 6)
	startRowTop.Paint = function() end

	local btnScarlet = vgui.Create("DButton", startRowTop)
	btnScarlet:SetText(MissionIntro.L("panel_start_scarlet"))
	btnScarlet:Dock(LEFT)
	btnScarlet:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnScarlet, "red")
	btnScarlet.DoClick = function()
		MissionIntro.TryAdminStartFaction("scarlet_cultist")
	end

	local btnHammer = vgui.Create("DButton", startRowTop)
	btnHammer:SetText(MissionIntro.L("panel_start_hammerfall"))
	btnHammer:Dock(FILL)
	MI_StyleButton(btnHammer, "blue")
	btnHammer.DoClick = function()
		MissionIntro.TryAdminStartFaction("hammerfall_squad")
	end

	startRowTop.PerformLayout = function(self, w, h)
		local half = math.max(80, math.floor((w - 6) * 0.5))
		btnScarlet:SetWide(half)
	end

	local startRowHammerMaint = vgui.Create("DPanel", startBlock)
	startRowHammerMaint:Dock(TOP)
	startRowHammerMaint:SetTall(40)
	startRowHammerMaint:DockMargin(0, 0, 0, 6)
	startRowHammerMaint.Paint = function() end

	local btnHammerMaint = vgui.Create("DButton", startRowHammerMaint)
	btnHammerMaint:SetText(MissionIntro.L("panel_start_hammerfall_maintenance"))
	btnHammerMaint:Dock(FILL)
	MI_StyleButton(btnHammerMaint, "blue")
	btnHammerMaint.DoClick = function()
		MissionIntro.TryAdminStartFaction("hammerfall_maintenance")
	end

	local startRowSid = vgui.Create("DPanel", startBlock)
	startRowSid:Dock(TOP)
	startRowSid:SetTall(40)
	startRowSid:DockMargin(0, 0, 0, 6)
	startRowSid.Paint = function() end

	local btnSid = vgui.Create("DButton", startRowSid)
	btnSid:SetText(MissionIntro.L("panel_start_sid"))
	btnSid:Dock(LEFT)
	btnSid:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnSid, "gray")
	btnSid.DoClick = function()
		MissionIntro.TryAdminStartFaction("sid_squad")
	end

	local btnUiuTf = vgui.Create("DButton", startRowSid)
	btnUiuTf:SetText(MissionIntro.L("panel_start_uiu_taskforce"))
	btnUiuTf:Dock(LEFT)
	btnUiuTf:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnUiuTf, "gray")
	btnUiuTf.DoClick = function()
		MissionIntro.TryAdminStartFaction("uiu_taskforce")
	end

	local btnPttrb = vgui.Create("DButton", startRowSid)
	btnPttrb:SetText(MissionIntro.L("panel_start_pttrb"))
	btnPttrb:Dock(FILL)
	MI_StyleButton(btnPttrb, "blue")
	btnPttrb.DoClick = function()
		MissionIntro.TryAdminStartFaction("pttrb_squad")
	end

	startRowSid.PerformLayout = function(self, w, h)
		local third = math.max(72, math.floor((w - 12) / 3))
		btnSid:SetWide(third)
		btnUiuTf:SetWide(third)
	end

	local startRowMcd = vgui.Create("DPanel", startBlock)
	startRowMcd:Dock(TOP)
	startRowMcd:SetTall(40)
	startRowMcd:DockMargin(0, 0, 0, 6)
	startRowMcd.Paint = function() end

	local btnMcd = vgui.Create("DButton", startRowMcd)
	btnMcd:SetText(MissionIntro.L("panel_start_mcd"))
	btnMcd:Dock(FILL)
	MI_StyleButton(btnMcd, "blue")
	btnMcd.DoClick = function()
		MissionIntro.TryAdminStartFaction("mcd_squad")
	end

	local startRowCi = vgui.Create("DPanel", startBlock)
	startRowCi:Dock(TOP)
	startRowCi:SetTall(40)
	startRowCi:DockMargin(0, 0, 0, 0)
	startRowCi.Paint = function() end

	local btnCi = vgui.Create("DButton", startRowCi)
	btnCi:SetText(MissionIntro.L("panel_start_ci"))
	btnCi:Dock(LEFT)
	btnCi:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnCi, "green")
	btnCi.DoClick = function()
		MissionIntro.TryAdminStartFaction("ci_squad")
	end

	local btnVdv = vgui.Create("DButton", startRowCi)
	btnVdv:SetText(MissionIntro.L("panel_start_vdv"))
	btnVdv:Dock(FILL)
	MI_StyleButton(btnVdv, "green")
	btnVdv.DoClick = function()
		MissionIntro.TryAdminStartFaction("vdv_squad")
	end

	startRowCi.PerformLayout = function(self, w, h)
		local half = math.max(72, math.floor((w - 6) / 2))
		btnCi:SetWide(half)
	end

	local startRowGoc = vgui.Create("DPanel", startBlock)
	startRowGoc:Dock(TOP)
	startRowGoc:SetTall(40)
	startRowGoc:DockMargin(0, 6, 0, 0)
	startRowGoc.Paint = function() end

	local btnGoc = vgui.Create("DButton", startRowGoc)
	btnGoc:SetText(MissionIntro.L("panel_start_goc"))
	btnGoc:Dock(LEFT)
	btnGoc:DockMargin(0, 0, 6, 0)
	MI_StyleButton(btnGoc, "gray")
	btnGoc.DoClick = function()
		MissionIntro.TryAdminStartFaction("goc_squad")
	end

	local btnNtf = vgui.Create("DButton", startRowGoc)
	btnNtf:SetText(MissionIntro.L("panel_start_ntf"))
	btnNtf:Dock(FILL)
	MI_StyleButton(btnNtf, "blue")
	btnNtf.DoClick = function()
		MissionIntro.TryAdminStartFaction("ntf_squad")
	end

	startRowGoc.PerformLayout = function(self, w, h)
		local half = math.max(72, math.floor((w - 6) / 2))
		btnGoc:SetWide(half)
	end

	MI_AddToContainer(container, startBlock, 314)

	MI_AddHelp(container, MissionIntro.L("panel_uiu_army_broadcast_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_uiu_tf_random_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_mcd_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_scarlet_random_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_hammerfall_random_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_hammerfall_maintenance_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_sid_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_sid_random_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_pttrb_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_pttrb_random_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_ci_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_ci_random_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_vdv_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_goc_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_ntf_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_vdv_random_hint"), true)
	MI_AddHelp(container, MissionIntro.L("panel_facility_menu_hint"), true)
	MI_FinishContainerLayout(container)
end

function MissionIntro.OpenAdminHUD()
	if IsValid(MissionIntro._adminPanel) then
		if IsValid(MissionIntro._adminPanel._inner) then
			MissionIntro.BuildAdminCPanel(MissionIntro._adminPanel._inner)
		end
		MissionIntro._adminPanel:MakePopup()
		MissionIntro._adminPanel:Center()
		return
	end

	local fr = vgui.Create("DFrame")
	fr:SetTitle(MissionIntro.L("panel_title"))
	fr:SetSize(480, 620)
	fr:Center()
	fr:MakePopup()
	MissionIntro._adminPanel = fr

	fr.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(248, 249, 252))
	end

	local cp = vgui.Create("DScrollPanel", fr)
	cp:Dock(FILL)
	cp:DockMargin(10, 10, 10, 10)

	local inner = vgui.Create("DPanel", cp:GetCanvas())
	fr._inner = inner
	inner:Dock(TOP)
	inner.Paint = function() end
	function inner:PerformLayout(w, h)
		local parent = self:GetParent()
		local pw = (IsValid(parent) and parent:GetWide() > 0) and parent:GetWide() or w
		if pw <= 0 then pw = 440 end
		self:SetWide(pw)
		self:SizeToChildren(false, true)
	end

	MissionIntro.BuildAdminCPanel(inner)

	function cp:OnSizeChanged(w, h)
		if IsValid(inner) then
			inner:InvalidateLayout(true)
		end
	end

	function fr:OnClose()
		MissionIntro.ClearAdminPlayerList(inner._miAdminCtx)
		inner._miAdminCtx = nil
		MissionIntro._adminPanel = nil
	end
end

hook.Add("PopulateToolMenu", "MissionIntro_ToolMenu", function()
	spawnmenu.AddToolCategory("Utilities", "rx_mission_intro", MissionIntro.L("tool_category"))

	spawnmenu.AddToolMenuOption(
		"Utilities",
		"rx_mission_intro",
		"mission_intro_admin",
		MissionIntro.L("tool_name"),
		"",
		"icon16/user_go.png",
		function(panel)
			if IsValid(panel) then
				panel.Paint = function(self, w, h)
					draw.RoundedBox(0, 0, 0, w, h, Color(248, 249, 252))
				end
			end
			MissionIntro.BuildAdminCPanel(panel)
		end
	)
end)

concommand.Add("mission_intro_admin", function()
	if not MissionIntro.CanManage() then
		chat.AddText(Color(255, 120, 120), "[MissionIntro] ", color_white, MissionIntro.L("panel_admin_only"))
		return
	end
	MissionIntro.OpenAdminHUD()
end)
