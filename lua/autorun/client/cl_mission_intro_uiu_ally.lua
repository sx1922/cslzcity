if not CLIENT then return end

MissionIntro = MissionIntro or {}

local ALLY_HALO = Color(72, 160, 255)
local ALLY_HUD_BG = Color(12, 22, 38, 220)
local ALLY_HUD_BORDER = Color(72, 160, 255, 255)

local function MI_SkipLegacyAllyGlow()
	return MissionIntro.ShouldUseRxsendTeamPanel and MissionIntro.ShouldUseRxsendTeamPanel()
end

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 16, weight = weight or 600 })
	end
	return "DermaDefault"
end

local function MI_GetViewerRoleKind()
	local ply = LocalPlayer()
	if not IsValid(ply) then return nil end
	if MissionIntro.GetUiuAllyRoleKind then
		return MissionIntro.GetUiuAllyRoleKind(ply)
	end
	return nil
end

local function MI_CollectUiuAllyDrawLists()
	local viewer = LocalPlayer()
	if not MI_GetViewerRoleKind() then return nil end

	local seeThrough = {}
	local names = {}

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or ply == viewer or not ply:Alive() then continue end
		if not MissionIntro.ShouldUiuAllySeeThrough or not MissionIntro.ShouldUiuAllySeeThrough(viewer, ply) then continue end
		seeThrough[#seeThrough + 1] = ply
		names[#names + 1] = (MissionIntro.GetIntelPanelPlayerName and MissionIntro.GetIntelPanelPlayerName(ply))
			or (MissionIntro.GetZCityPlayerName and MissionIntro.GetZCityPlayerName(ply))
			or (ply:Nick() or "?")
	end

	if #seeThrough == 0 then return nil end

	return {
		seeThrough = seeThrough,
		names = names,
	}
end

hook.Add("PreDrawHalos", "MissionIntro_UiuAllyHalo", function()
	if MI_SkipLegacyAllyGlow() then return end
	if MissionIntro.IsAllyGlowDrawingAllowed and not MissionIntro.IsAllyGlowDrawingAllowed() then return end

	local lists = MI_CollectUiuAllyDrawLists()
	if not lists or #lists.seeThrough == 0 then return end

	halo.Add(lists.seeThrough, ALLY_HALO, 3, 3, 2, true, true)
end)

hook.Add("HUDPaint", "MissionIntro_UiuAllyHud", function()
	if MI_SkipLegacyAllyGlow() then return end
	if MissionIntro.IsAllyGlowDrawingAllowed and not MissionIntro.IsAllyGlowDrawingAllowed() then return end

	local lists = MI_CollectUiuAllyDrawLists()
	if not lists or #lists.names == 0 then return end

	local line1 = MissionIntro.L and MissionIntro.L("aa_uiu_ally_hud", table.concat(lists.names, " / "))
		or (table.concat(lists.names, " / ") .. " 是 UIU 同盟，不要攻击！")
	local fontBody = MI_Font(16, 600)

	surface.SetFont(fontBody)
	local tw, th = surface.GetTextSize(line1)
	local padX, padY = 14, 10
	local boxW = math.max(280, tw + padX * 2)
	local boxH = th + padY * 2 + 4
	local x, y = 18, ScrH() * 0.28

	draw.RoundedBox(8, x, y, boxW, boxH, ALLY_HUD_BG)
	surface.SetDrawColor(ALLY_HUD_BORDER)
	surface.DrawOutlinedRect(x, y, boxW, boxH, 2)
	draw.SimpleText(line1, fontBody, x + boxW * 0.5, y + boxH * 0.5, ALLY_HALO, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
