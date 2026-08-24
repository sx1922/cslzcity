if not CLIENT then return end

MissionIntro = MissionIntro or {}

MissionIntro._aaCiAllyClient = MissionIntro._aaCiAllyClient or nil

local ALLY_HALO = Color(72, 220, 110)
local ALLY_HUD_BG = Color(12, 28, 18, 220)
local ALLY_HUD_BORDER = Color(72, 220, 110, 255)

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
	if MissionIntro.GetCiAllyRoleKind then
		return MissionIntro.GetCiAllyRoleKind(ply)
	end
	return nil
end

local function MI_CollectCiAllyDrawLists()
	local viewer = LocalPlayer()
	local viewerKind = MI_GetViewerRoleKind()
	if not viewerKind then return nil end

	local seeThrough = {}
	local names = {}

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or ply == viewer or not ply:Alive() then continue end
		if not MissionIntro.ShouldCiAllySeeThrough or not MissionIntro.ShouldCiAllySeeThrough(viewer, ply) then continue end
		seeThrough[#seeThrough + 1] = ply
		names[#names + 1] = (MissionIntro.GetIntelPanelPlayerName and MissionIntro.GetIntelPanelPlayerName(ply))
			or (MissionIntro.GetZCityPlayerName and MissionIntro.GetZCityPlayerName(ply))
			or (ply:Nick() or "?")
	end

	if #seeThrough == 0 then
		return nil
	end

	return {
		seeThrough = seeThrough,
		names = names,
	}
end

net.Receive("MissionIntro_AaCiAllySync", function()
	if MI_SkipLegacyAllyGlow() then return end

	local active = net.ReadBool()
	if active then
		MissionIntro._aaCiAllyClient = net.ReadEntity()
	else
		MissionIntro._aaCiAllyClient = nil
	end
end)

hook.Add("PreDrawHalos", "MissionIntro_CiAaAllyHalo", function()
	if MI_SkipLegacyAllyGlow() then return end
	if MissionIntro.IsAllyGlowDrawingAllowed and not MissionIntro.IsAllyGlowDrawingAllowed() then return end

	local lists = MI_CollectCiAllyDrawLists()
	if not lists then return end

	if #lists.seeThrough > 0 then
		halo.Add(lists.seeThrough, ALLY_HALO, 3, 3, 2, true, true)
	end
end)

hook.Add("HUDPaint", "MissionIntro_CiAaAllyHud", function()
	if MI_SkipLegacyAllyGlow() then return end
	if MissionIntro.IsAllyGlowDrawingAllowed and not MissionIntro.IsAllyGlowDrawingAllowed() then return end

	local lists = MI_CollectCiAllyDrawLists()
	if not lists or #lists.names == 0 then return end

	local line1 = MissionIntro.L and MissionIntro.L("aa_ci_ally_hud", table.concat(lists.names, " / "))
		or (table.concat(lists.names, " / ") .. " 是 CI 同盟，不要攻击！")
	local fontBody = MI_Font(16, 600)

	surface.SetFont(fontBody)
	local tw, th = surface.GetTextSize(line1)
	local padX, padY = 14, 10
	local boxW = math.max(280, tw + padX * 2)
	local boxH = th + padY * 2 + 4
	local x, y = 18, ScrH() * 0.34

	draw.RoundedBox(8, x, y, boxW, boxH, ALLY_HUD_BG)
	surface.SetDrawColor(ALLY_HUD_BORDER)
	surface.DrawOutlinedRect(x, y, boxW, boxH, 2)
	draw.SimpleText(line1, fontBody, x + boxW * 0.5, y + boxH * 0.5, ALLY_HALO, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

local function MI_ResetCiAllyClient()
	MissionIntro._aaCiAllyClient = nil
end

for _, hookName in ipairs({ "RoundStart", "Breach_NewRound", "OnNewRound", "HMCD_NewRound", "HomigradRoundStart", "PostCleanupMap" }) do
	hook.Add(hookName, "MissionIntro_CiAaAllyClientReset", MI_ResetCiAllyClient)
end

function MissionIntro.DrawFacilitySecurityGalleryHud() end
