if not CLIENT then return end

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 18, weight = weight or 600 })
	end
	return "DermaDefault"
end

function MissionIntro.ClampUiuEvacRadius(radius)
	local cfg = MissionIntro.UiuEvac or {}
	local minR = tonumber(cfg.min_zone_radius) or 64
	local maxR = tonumber(cfg.max_zone_radius) or 400
	return math.Clamp(tonumber(radius) or 130, minR, maxR)
end

function MissionIntro.GetUiuEvacToolRadius()
	local cv = GetConVar("mission_intro_uiu_evac_radius")
	if cv then
		return MissionIntro.ClampUiuEvacRadius(cv:GetFloat())
	end
	return MissionIntro.ClampUiuEvacRadius(MissionIntro.UiuEvac and MissionIntro.UiuEvac.default_zone_radius)
end

function MissionIntro.IsUiuEvacToolActive(ply)
	ply = ply or LocalPlayer()
	if not IsValid(ply) then return false end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return false end

	local mode = (wep.GetMode and wep:GetMode()) or wep.Mode or ply:GetInfo("gmod_toolmode") or ""
	return mode == "mission_intro_uiu_evac"
end

function MissionIntro.DrawUiuEvacZoneWire(center, half, col)
	if MissionIntro.DrawEvacSquareWire then
		MissionIntro.DrawEvacSquareWire(center, MissionIntro.ClampUiuEvacRadius(half), col)
	end
end

function MissionIntro.DrawUiuEvacBar()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_evac")) do
		if not IsValid(ent) then continue end
		if not ent.GetEvacuatingPlayer or not ent.GetEvacProgress then continue end
		if ent:GetEvacuatingPlayer() ~= ply then continue end
		if ent:GetEvacProgress() <= 0 then continue end

		local frac = math.Clamp(ent:GetEvacProgress(), 0, 1)
		local scrW, scrH = ScrW(), ScrH()
		local barW, barH = math.min(360, scrW * 0.28), 16
		local x = (scrW - barW) * 0.5
		local y = scrH - 88

		draw.RoundedBox(6, x - 2, y - 2, barW + 4, barH + 4, Color(0, 0, 0, 190))
		draw.RoundedBox(4, x, y, barW, barH, Color(24, 32, 48, 235))
		draw.RoundedBox(4, x, y, barW * frac, barH, Color(70, 200, 120, 245))

		local hint = MissionIntro.L and MissionIntro.L("uiu_evac_hint") or "自动撤离中"
		draw.SimpleText(hint, MI_Font(16, 700), scrW * 0.5, y - 10, Color(190, 220, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.SimpleText(math.floor(frac * 100) .. "%", MI_Font(14, 800), scrW * 0.5, y + barH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end
end

hook.Add("HUDPaint", "MissionIntro_UiuEvacBar", function()
	if MissionIntro.DrawUiuEvacBar then
		MissionIntro.DrawUiuEvacBar()
	end
end)

function MissionIntro.ShouldDrawUiuEvacMarkers()
	return MissionIntro._uiuShowEvacMarkers == true
end

function MissionIntro.DrawUiuEvacMarkerLabel(ent, ply)
	if not IsValid(ent) or not IsValid(ply) then return end

	local label = MissionIntro.L and MissionIntro.L("uiu_evac_label") or "撤离点"
	local dist = math.floor(ply:GetPos():Distance(ent:GetPos()) / 39.37)
	local pos = ent:GetPos() + Vector(0, 0, 42)

	cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.1)
		draw.SimpleText(label, MI_Font(28, 800), 0, -8, Color(120, 255, 170), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(dist .. "m", MI_Font(20, 600), 0, 18, Color(200, 235, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

function MissionIntro.DrawUiuEvacMarkerBeam(ent)
	if not IsValid(ent) then return end

	local top = ent:GetPos() + Vector(0, 0, 520)
	render.DrawLine(ent:GetPos() + Vector(0, 0, 8), top, Color(90, 255, 150, 180), true)
	render.DrawLine(top, top + Vector(0, 0, 48), Color(90, 255, 150, 120), true)
end

hook.Add("HUDPaint", "MissionIntro_UiuEvacMarkerList", function()
	if not MissionIntro.ShouldDrawUiuEvacMarkers() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local evacs = ents.FindByClass("ent_mission_intro_uiu_evac")
	if #evacs == 0 then return end

	local title = MissionIntro.L and MissionIntro.L("uiu_evac_label") or "撤离点"
	draw.SimpleText(title, MI_Font(18, 700), ScrW() - 20, 80, Color(120, 255, 170), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	table.sort(evacs, function(a, b)
		if not IsValid(a) then return false end
		if not IsValid(b) then return true end
		return ply:GetPos():DistToSqr(a:GetPos()) < ply:GetPos():DistToSqr(b:GetPos())
	end)

	local y = 104
	for i, ent in ipairs(evacs) do
		if not IsValid(ent) then continue end
		if i > 6 then break end
		local distM = math.floor(ply:GetPos():Distance(ent:GetPos()) / 39.37)
		draw.SimpleText(string.format("#%d  %dm", i, distM), MI_Font(16, 600), ScrW() - 20, y, Color(200, 235, 220), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		y = y + 20
	end
end)

hook.Add("PreDrawHalos", "MissionIntro_UiuEvacMarkers", function()
	if not MissionIntro.ShouldDrawUiuEvacMarkers() then return end

	local list = {}
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_evac")) do
		if IsValid(ent) then
			list[#list + 1] = ent
		end
	end

	if #list > 0 then
		halo.Add(list, Color(90, 255, 150), 3, 3, 2, true, true)
	end
end)

hook.Add("PostDrawTranslucentRenderables", "MissionIntro_UiuEvacZoneWire", function(depth, skybox)
	if skybox then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local toolActive = MissionIntro.IsUiuEvacToolActive(ply)
	local markerActive = MissionIntro.ShouldDrawUiuEvacMarkers()
	local previewCol = Color(255, 220, 90, 230)
	local placedCol = Color(80, 220, 130, 200)
	local markerCol = Color(90, 255, 150, 240)

	if toolActive then
		local tr = ply:GetEyeTrace()
		if tr.Hit then
			local lift = tonumber(MissionIntro.UiuEvac.spawn_surface_offset) or 0.5
			local center = tr.HitPos + tr.HitNormal * lift
			if tr.HitNormal.z <= 0.65 then
				center = tr.HitPos + tr.HitNormal * 2
			end
			MissionIntro.DrawUiuEvacZoneWire(center, MissionIntro.GetUiuEvacToolRadius(), previewCol)
		end
	end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_evac")) do
		if not IsValid(ent) then continue end

		local maxDist = markerActive and (4096 * 4096) or (2048 * 2048)
		if ply:GetPos():DistToSqr(ent:GetPos()) > maxDist then continue end

		local r = (ent.GetZoneRadius and ent:GetZoneRadius()) or (ent.GetEvacZoneRadius and ent:GetEvacZoneRadius()) or 130
		local col = placedCol
		if markerActive then
			col = markerCol
		elseif toolActive then
			col = Color(120, 240, 160, 220)
		end
		MissionIntro.DrawUiuEvacZoneWire(ent:GetPos(), r, col)

		if markerActive then
			MissionIntro.DrawUiuEvacMarkerBeam(ent)
			if ply:GetPos():DistToSqr(ent:GetPos()) <= (1200 * 1200) then
				MissionIntro.DrawUiuEvacMarkerLabel(ent, ply)
			end
		end
	end
end)
