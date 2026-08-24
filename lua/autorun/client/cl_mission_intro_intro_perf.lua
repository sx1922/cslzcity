if not CLIENT then return end

MissionIntro = MissionIntro or {}

function MissionIntro.ShouldUseLightFacilityIntro(state)
	if not istable(state) then return false end
	if state.useLightDraw ~= nil then return state.useLightDraw == true end
	if MissionIntro.ShouldUseFacilityPhase3Intro and IsValid(state.ply) then
		return MissionIntro.ShouldUseFacilityPhase3Intro(state.ply) == true
	end
	return MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(state.factionId)
end

function MissionIntro.CacheIntroDrawState(st)
	if not istable(st) then return end

	st.useLightDraw = MissionIntro.ShouldUseLightFacilityIntro(st)
	if not st.useLightDraw then return end

	local path = MissionIntro.GetEmblemImagePath and MissionIntro.GetEmblemImagePath(st)
	local mat
	if isstring(path) and path ~= "" and MissionIntro.GetEmblemMaterial then
		mat = MissionIntro.GetEmblemMaterial(path)
		if mat and mat:IsError() then mat = nil end
	end

	local V = MissionIntro.Visual or {}
	local facData = IsValid(st.ply) and MissionIntro.GetFacilityFactionData and MissionIntro.GetFacilityFactionData(st.ply)
	local style = (not facData) and MissionIntro.GetFactionStyle and MissionIntro.GetFactionStyle(st.ply, st) or nil
	st._drawCache = {
		emblemPath = path,
		emblemMat = mat,
		titleFont = MissionIntro.EnsureFont and MissionIntro.EnsureFont(MissionIntro.GetFacilityIntroFontDef and MissionIntro.GetFacilityIntroFontDef(1) or (V.fonts and V.fonts.intro_title) or { size = 62, weight = 700 }),
		bodyFont = MissionIntro.EnsureFont and MissionIntro.EnsureFont(MissionIntro.GetFacilityIntroFontDef and MissionIntro.GetFacilityIntroFontDef(2) or (V.fonts and V.fonts.intro_body) or { size = 38, weight = 500 }),
		textCol = (facData and facData.text_color) or (style and style.text_color) or (MissionIntro.GetFactionTextColor and MissionIntro.GetFactionTextColor(nil, st)) or color_white,
		outlineCol = (facData and facData.overlay_outline_color) or (style and style.overlay_outline_color),
		useTextOutline = (facData and facData.intro_hud_outline == true) or (style and style.intro_hud_outline == true),
	}
end

function MissionIntro.DrawFrameFacilityLight(state, hudAlpha)
	hudAlpha = hudAlpha or 255
	local cache = state._drawCache
	if not cache then
		MissionIntro.CacheIntroDrawState(state)
		cache = state._drawCache
	end
	if not cache then return end

	local emblemA = math.floor((state.iconAlpha or 255) * hudAlpha / 255)
	local V = MissionIntro.Visual
	local ix, iy = MissionIntro.ResolvePos(V.icon_top.x, V.icon_top.y)
	local scale = MissionIntro.GetFactionEmblemScale and MissionIntro.GetFactionEmblemScale(nil, state) or 1
	local r = MissionIntro.ScaleUniform(V.icon_top.size) * 0.5 * scale

	if cache.emblemMat and not cache.emblemMat:IsError() then
		local maxSize = math.max(1, math.floor(r * 2 + 0.5))
		local ex, ey, ew, eh
		if MissionIntro.ComputeEmblemDrawRect then
			ex, ey, ew, eh = MissionIntro.ComputeEmblemDrawRect(ix, iy, maxSize, cache.emblemMat, cache.emblemPath, state)
		else
			ex, ey, ew, eh = math.floor(ix - r), math.floor(iy - r), maxSize, maxSize
		end
		surface.SetDrawColor(255, 255, 255, emblemA)
		surface.SetMaterial(cache.emblemMat)
		local uvFn = MissionIntro.GetEmblemSquareUV
		if uvFn then
			local u0, v0, u1, v1 = uvFn(cache.emblemPath, state)
			if u0 == 0 and v0 == 0 and u1 == 1 and v1 == 1 then
				surface.DrawTexturedRect(ex, ey, ew, eh)
			else
				surface.DrawTexturedRectUV(ex, ey, ew, eh, u0, v0, u1, v1)
			end
		else
			surface.DrawTexturedRect(ex, ey, ew, eh)
		end
	elseif MissionIntro.DrawEmblemHud then
		MissionIntro.DrawEmblemHud("top", emblemA, state.phase or 3, state)
	end

	if state.showDivider then
		local cx, dy = MissionIntro.ResolvePos(960, V.divider.y)
		local barW = MissionIntro.ScaleX(V.divider.w)
		local thick = math.max(1, MissionIntro.ScaleY(2))
		local col = cache.textCol or color_white
		if state.factionId == "uiu_spy" and cache.outlineCol then
			col = cache.outlineCol
		elseif state.factionId == "sid_squad" and cache.outlineCol then
			col = cache.outlineCol
		end
		surface.SetDrawColor(col.r, col.g, col.b, emblemA)
		surface.DrawRect(math.floor(cx - barW * 0.5), math.floor(dy), math.floor(barW), thick)
	end

	local baseCol = cache.textCol or color_white
	for _, line in ipairs(state.introLines or {}) do
		if not line.started or (line.chars or 0) <= 0 then continue end

		local layout = (MissionIntro.GetFacilityIntroLineLayout and MissionIntro.GetFacilityIntroLineLayout(line.index))
			or V.intro_lines[line.index] or V.intro_lines[1]
		local x, y = MissionIntro.ResolvePos(960, layout.y)
		local font = (line.index == 1) and cache.titleFont or cache.bodyFont
		local a = math.floor((baseCol.a or 255) * hudAlpha / 255)
		local shown = utf8.sub(line.text or "", 1, line.chars or 0)
		local col = Color(baseCol.r, baseCol.g, baseCol.b, a)
		if cache.useTextOutline and MissionIntro.DrawOutlinedText then
			MissionIntro.DrawOutlinedText(shown, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, cache.outlineCol)
		else
			draw.SimpleText(shown, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end
end
