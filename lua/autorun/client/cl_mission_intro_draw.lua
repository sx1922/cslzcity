MissionIntro = MissionIntro or {}
MissionIntro._fontCache = MissionIntro._fontCache or {}

CreateClientConVar("mission_intro_ofs_x", "0", true, false)
CreateClientConVar("mission_intro_ofs_y", "0", true, false)

MissionIntro.CJKFontFamilies = {
	"Microsoft YaHei",
	"Microsoft YaHei UI",
	"SimHei",
	"SimSun",
	"NSimSun",
	"PingFang SC",
	"Noto Sans CJK SC",
	"Source Han Sans SC",
	"WenQuanYi Micro Hei",
	"Arial Unicode MS",
}

function MissionIntro.GetCJKFontFamily()
	if MissionIntro._cjkFontFamily then return MissionIntro._cjkFontFamily end

	local cv = GetConVar("mission_intro_font")
	if cv and cv:GetString() ~= "" then
		MissionIntro._cjkFontFamily = cv:GetString()
		return MissionIntro._cjkFontFamily
	end

	for _, fam in ipairs(MissionIntro.CJKFontFamilies) do
		local probe = "MI_Probe_" .. string.gsub(fam, "%s", "_")
		surface.CreateFont(probe, {
			font = fam,
			size = 24,
			weight = 500,
			extended = true,
		})
		MissionIntro._cjkFontFamily = fam
		return fam
	end

	MissionIntro._cjkFontFamily = "Tahoma"
	return MissionIntro._cjkFontFamily
end

CreateClientConVar("mission_intro_font", "", true, false, "强制指定中文字体名（留空自动）")

local function MI_FontId(def)
	local family = def.family or MissionIntro.GetCJKFontFamily()
	return string.format("MI_%s_%d_%d", family, def.size or 24, def.weight or 500)
end

function MissionIntro.EnsureFont(def)
	local family = def.family or MissionIntro.GetCJKFontFamily()
	local id = MI_FontId(def)
	if not MissionIntro._fontCache[id] then
		surface.CreateFont(id, {
			font = family,
			size = MissionIntro.ScaleFontSize(def.size or 24),
			weight = def.weight or 500,
			extended = true,
			antialias = true,
			additive = false,
			outline = false,
			blursize = 0,
			shadow = false,
			scanlines = 0,
		})
		MissionIntro._fontCache[id] = true
	end
	return id
end

hook.Add("OnScreenSizeChanged", "MissionIntro_Refont", function()
	MissionIntro._fontCache = {}
	MissionIntro._cjkFontFamily = nil
end)

cvars.AddChangeCallback("mission_intro_font", function()
	MissionIntro._fontCache = {}
	MissionIntro._cjkFontFamily = nil
end, "MissionIntro_FontChange")

local function MI_Alpha(col, mult)
	mult = mult or 255
	if not IsColor(col) then return Color(255, 255, 255, mult) end
	return Color(col.r, col.g, col.b, math.floor((col.a or 255) * mult / 255))
end

local function MI_DrawText(text, font, x, y, col, halign, valign)
	draw.SimpleText(text, font, x, y, col, halign, valign)
end

local function MI_DrawTextOutlined(text, font, x, y, col, halign, valign, outlineCol)
	local a = col.a or 255
	local shadow = outlineCol or Color(0, 0, 0, a)
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox ~= 0 or oy ~= 0 then
				draw.SimpleText(text, font, x + ox, y + oy, shadow, halign, valign)
			end
		end
	end
	draw.SimpleText(text, font, x, y, col, halign, valign)
end

function MissionIntro.DrawOutlinedText(text, font, x, y, col, halign, valign, outlineCol)
	MI_DrawTextOutlined(text, font, x, y, col, halign, valign, outlineCol)
end

function MissionIntro.DrawFullscreenBlack(w, h, strength)
	strength = strength or 1
	surface.SetDrawColor(0, 0, 0, math.floor(255 * strength))
	surface.DrawRect(0, 0, w, h)
end

function MissionIntro.DrawTopPanel(w, hudAlpha, state)
	hudAlpha = hudAlpha or 255
	local style = MissionIntro.GetFactionStyle and MissionIntro.GetFactionStyle(nil, state) or nil
	if style and style.intro_panel_transparent then
		return
	end

	local panelH = MissionIntro.ScaleY(430)
	local lightPanel = style and style.intro_panel_light
	local bg = (style and style.intro_panel_bg) or Color(248, 249, 252)

	if lightPanel then
		surface.SetDrawColor(bg.r, bg.g, bg.b, math.floor(255 * hudAlpha / 255))
		surface.DrawRect(0, 0, w, panelH)
	else
		for i = 0, 14 do
			local t = i / 14
			local a = math.floor(210 * (1 - t * 0.55) * hudAlpha / 255)
			surface.SetDrawColor(0, 0, 0, a)
			surface.DrawRect(0, panelH * t * 0.12, w, panelH / 14 + 2)
		end
		surface.SetDrawColor(0, 0, 0, math.floor(185 * hudAlpha / 255))
		surface.DrawRect(0, 0, w, panelH)
	end
end

function MissionIntro.DrawScanSweep(w, h, phase)
	local y = (CurTime() * 100 + phase * 30) % h
	surface.SetDrawColor(255, 255, 255, 5)
	surface.DrawRect(0, y, w, MissionIntro.ScaleY(2))
end

function MissionIntro.DrawEmblemHud(mode, alpha, phase, state)
	local V = MissionIntro.Visual
	local layout = (mode == "top") and V.icon_top or V.icon_center
	local x, y = MissionIntro.ResolvePos(layout.x, layout.y)
	local scale = MissionIntro.GetFactionEmblemScale and MissionIntro.GetFactionEmblemScale(nil, state) or 1
	local r = MissionIntro.ScaleUniform(layout.size) * 0.5 * scale
	MissionIntro.DrawFactionEmblem(x, y, r, alpha, state)
end

function MissionIntro.DrawDivider(alpha, state)
	local V = MissionIntro.Visual
	local cx, y = MissionIntro.ResolvePos(960, V.divider.y)
	local barW = MissionIntro.ScaleX(V.divider.w)
	local thick = math.max(1, MissionIntro.ScaleY(2))
	local style = MissionIntro.GetFactionStyle and MissionIntro.GetFactionStyle(nil, state) or nil
	local baseCol = MissionIntro.GetFactionTextColor and MissionIntro.GetFactionTextColor(nil, state) or color_white
	if style and style.intro_hud_outline and IsColor(style.overlay_outline_color) then
		baseCol = style.overlay_outline_color
	end

	for i = 0, 12 do
		local t = i / 12
		local segW = barW / 12
		local sx = cx - barW * 0.5 + segW * i
		local fade = math.Clamp(1 - math.abs(t - 0.5) * 1.6, 0.15, 1)
		surface.SetDrawColor(baseCol.r, baseCol.g, baseCol.b, math.floor(alpha * fade))
		surface.DrawRect(sx, y, segW, thick)
	end
end

function MissionIntro.DrawRedLines(state)
	local V = MissionIntro.Visual
	local font = MissionIntro.EnsureFont(V.fonts.red_overlay)
	local style = MissionIntro.GetFactionStyle and MissionIntro.GetFactionStyle(nil, state) or nil
	local col = (style and IsColor(style.overlay_text_color) and style.overlay_text_color)
		or (MissionIntro.GetFactionTextColor and MissionIntro.GetFactionTextColor(nil, state))
		or V.colors.red
	local outline = style and style.overlay_outline_color or nil

	for _, line in ipairs(state.redLines or {}) do
		if not line.active then continue end
		local layout = V.red_lines[line.index] or V.red_lines[1]
		local x, y = MissionIntro.ResolvePos(960, layout.y)
		local shown = utf8.sub(line.text, 1, line.chars or 0)
		MI_DrawTextOutlined(shown, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outline)
	end
end

function MissionIntro.DrawIntroLines(state, hudAlpha)
	local V = MissionIntro.Visual
	hudAlpha = hudAlpha or 255
	local baseCol = MissionIntro.GetFactionTextColor and MissionIntro.GetFactionTextColor(nil, state) or V.colors.red

	for _, line in ipairs(state.introLines or {}) do
		if not line.started or line.chars <= 0 then continue end

		local layout = V.intro_lines[line.index] or V.intro_lines[1]
		if MissionIntro.ShouldUseLightFacilityIntro and MissionIntro.ShouldUseLightFacilityIntro(state) and MissionIntro.GetFacilityIntroLineLayout then
			layout = MissionIntro.GetFacilityIntroLineLayout(line.index)
		end
		local x, y = MissionIntro.ResolvePos(960, layout.y)
		local def
		if MissionIntro.ShouldUseLightFacilityIntro and MissionIntro.ShouldUseLightFacilityIntro(state) and MissionIntro.GetFacilityIntroFontDef then
			def = MissionIntro.GetFacilityIntroFontDef(line.index)
		else
			def = (line.index == 1) and V.fonts.intro_title or V.fonts.intro_body
		end
		local font = MissionIntro.EnsureFont(def)
		local style = MissionIntro.GetFactionStyle and MissionIntro.GetFactionStyle(nil, state) or nil
		local altCols = style and style.intro_line_colors
		local lineCol = (istable(altCols) and IsColor(altCols[line.index])) and altCols[line.index] or baseCol
		local col = MI_Alpha(lineCol, hudAlpha)
		local shown = utf8.sub(line.text, 1, line.chars)
		local outline = style and style.overlay_outline_color
		if style and style.intro_hud_outline and outline and MissionIntro.DrawOutlinedText then
			MissionIntro.DrawOutlinedText(shown, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, outline)
		elseif outline then
			MI_DrawTextOutlined(shown, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, outline)
		else
			draw.SimpleText(shown, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end
end

function MissionIntro.DrawFrame(state, hudAlpha)
	local w, h = ScrW(), ScrH()
	local phase = state.phase or 1
	hudAlpha = hudAlpha or 255

	if state.unlocked then
		if MissionIntro.ShouldUseLightFacilityIntro and MissionIntro.ShouldUseLightFacilityIntro(state) then
			MissionIntro.DrawFrameFacilityLight(state, hudAlpha)
		else
			local emblemA = math.floor((state.iconAlpha or 255) * hudAlpha / 255)
			MissionIntro.DrawTopPanel(w, hudAlpha, state)
			MissionIntro.DrawEmblemHud("top", emblemA, phase, state)
			if state.showDivider then
				MissionIntro.DrawDivider(emblemA, state)
			end
			MissionIntro.DrawIntroLines(state, hudAlpha)
		end
	else
		MissionIntro.DrawFullscreenBlack(w, h, 1)
		if phase < 3 then
			MissionIntro.DrawScanSweep(w, h, phase)
		end
		if state.fade and state.fade > 0 then
			surface.SetDrawColor(0, 0, 0, state.fade)
			surface.DrawRect(0, 0, w, h)
		end
		MissionIntro.DrawEmblemHud("center", state.iconAlpha or 255, phase, state)
		if phase >= 2 then
			MissionIntro.DrawRedLines(state)
		end
	end

	if MissionIntro.ShowDebugTime then
		local elapsed = CurTime() - state.start
		draw.SimpleText(
			string.format("P%d T+%.1fs %s", phase, elapsed, state.unlocked and MissionIntro.L("debug_unlocked") or MissionIntro.L("debug_locked")),
			"DermaDefault",
			12,
			h - 24,
			Color(120, 120, 120)
		)
	end
end
