if not CLIENT then return end

MissionIntro = MissionIntro or {}

local PANEL_BG = Color(10, 16, 24, 230)
local PANEL_BORDER = Color(255, 255, 255, 36)
local TEXT_DIM = Color(175, 185, 200)

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 18, weight = weight or 600 })
	end
	return "DermaDefault"
end

local function MI_Scale(n)
	return math.max(n, math.floor(n * (ScrH() / 1080)))
end

function MissionIntro.DrawRxsendTeamPanel()
	local viewer = LocalPlayer()
	if not IsValid(viewer) then return end

	local allies, kind = MissionIntro.RXSendGetAllyPanelEntries(viewer)
	if not kind then return end

	local meta = MissionIntro.RXSendAllyPanelMeta and MissionIntro.RXSendAllyPanelMeta[kind]
	local title = meta and meta.title or "同盟情报"
	local subtitle = meta and meta.subtitle or ""
	local accent = meta and meta.color or Color(200, 200, 200)

	local fontTitle = MI_Font(MI_Scale(22), 700)
	local fontSub = MI_Font(MI_Scale(17), 500)
	local fontRow = MI_Font(MI_Scale(20), 600)

	local padX, padY = MI_Scale(18), MI_Scale(14)
	local lineH = MI_Scale(28)
	local x, y = MI_Scale(20), ScrH() * 0.26
	local innerW = MI_Scale(300)

	surface.SetFont(fontTitle)
	local titleW = surface.GetTextSize(title)
	surface.SetFont(fontSub)
	local subW = subtitle ~= "" and surface.GetTextSize(subtitle) or 0
	innerW = math.max(innerW, titleW + 12, subW + 12)

	local rows = {}
	for _, entry in ipairs(allies) do
		local label = entry.name
		surface.SetFont(fontRow)
		local tw = surface.GetTextSize(label)
		innerW = math.max(innerW, tw + 12)
		rows[#rows + 1] = label
	end

	if #rows == 0 then
		rows[1] = "暂无联络对象"
		surface.SetFont(fontRow)
		innerW = math.max(innerW, surface.GetTextSize(rows[1]) + 12)
	end

	local boxW = innerW + padX * 2
	local subBlock = subtitle ~= "" and (lineH + 4) or 0
	local boxH = padY * 2 + lineH + 6 + subBlock + 8 + math.max(1, #rows) * lineH

	draw.RoundedBox(10, x, y, boxW, boxH, PANEL_BG)
	surface.SetDrawColor(PANEL_BORDER)
	surface.DrawOutlinedRect(x, y, boxW, boxH, 2)
	surface.SetDrawColor(accent.r, accent.g, accent.b, 220)
	surface.DrawRect(x, y, 6, boxH)

	local ty = y + padY
	draw.SimpleText(title, fontTitle, x + padX + 4, ty, accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	ty = ty + lineH + 4
	if subtitle ~= "" then
		draw.SimpleText(subtitle, fontSub, x + padX + 4, ty, TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		ty = ty + lineH + 10
	else
		ty = ty + 6
	end

	for _, label in ipairs(rows) do
		local col = label == "暂无联络对象" and TEXT_DIM or accent
		draw.SimpleText(label, fontRow, x + padX + 4, ty, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		ty = ty + lineH
	end
end

hook.Add("HUDPaint", "MissionIntro_RxsendTeamPanel", function()
	if not MissionIntro.ShouldShowRxsendTeamPanel or not MissionIntro.ShouldShowRxsendTeamPanel() then
		return
	end
	MissionIntro.DrawRxsendTeamPanel()
end)
