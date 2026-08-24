if not CLIENT then return end

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 18, weight = weight or 600 })
	end
	return "DermaDefault"
end

local RXSEND_EVAC_TOOL_MODES = {
	mission_intro_rxsend_evac_facility = true,
	mission_intro_rxsend_evac_ci = true,
}

function MissionIntro.IsRXSendEvacToolActive(ply)
	ply = ply or LocalPlayer()
	if not IsValid(ply) then return false end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return false end

	local mode = (wep.GetMode and wep:GetMode()) or wep.Mode or ply:GetInfo("gmod_toolmode") or ""
	return RXSEND_EVAC_TOOL_MODES[mode] == true
end

function MissionIntro.GetRXSendEvacToolRadius()
	local cv = GetConVar("mission_intro_rxsend_evac_radius")
	if cv then
		return MissionIntro.ClampRXSendEvacRadius and MissionIntro.ClampRXSendEvacRadius(cv:GetFloat()) or cv:GetFloat()
	end
	return MissionIntro.ClampRXSendEvacRadius and MissionIntro.ClampRXSendEvacRadius(MissionIntro.RXSendEvac and MissionIntro.RXSendEvac.default_zone_radius)
		or 130
end

function MissionIntro.DrawRXSendEvacBar()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_rxsend_evac")) do
		if not IsValid(ent) then continue end
		if ent:GetEvacuatingPlayer() ~= ply then continue end
		if ent:GetEvacProgress() <= 0 then continue end

		local frac = math.Clamp(ent:GetEvacProgress(), 0, 1)
		local scrW, scrH = ScrW(), ScrH()
		local barW, barH = math.min(360, scrW * 0.28), 16
		local x = (scrW - barW) * 0.5
		local y = scrH - 88

		draw.RoundedBox(6, x - 2, y - 2, barW + 4, barH + 4, Color(0, 0, 0, 190))
		draw.RoundedBox(4, x, y, barW, barH, Color(24, 32, 48, 235))
		draw.RoundedBox(4, x, y, barW * frac, barH, Color(90, 170, 255, 245))

		local hint = MissionIntro.L and MissionIntro.L("generic_evac_hint") or "自动撤离中"
		draw.SimpleText(hint, MI_Font(16, 700), scrW * 0.5, y - 10, Color(190, 220, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		return
	end
end

hook.Add("HUDPaint", "MissionIntro_RXSendEvacBar", function()
	if MissionIntro.DrawRXSendEvacBar then
		MissionIntro.DrawRXSendEvacBar()
	end
end)

hook.Add("PostDrawTranslucentRenderables", "MissionIntro_RXSendEvacZoneWire", function(depth, skybox)
	if skybox then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not MissionIntro.IsRXSendEvacToolActive(ply) then return end

	local previewCol = Color(255, 200, 90, 230)
	local facilityCol = Color(72, 130, 210, 200)
	local ciCol = Color(72, 220, 110, 200)

	local tr = ply:GetEyeTrace()
	if tr.Hit then
		local lift = 0.5
		local center = tr.HitPos + tr.HitNormal * lift
		if tr.HitNormal.z <= 0.65 then
			center = tr.HitPos + tr.HitNormal * 2
		end
		if MissionIntro.DrawEvacSquareWire then
			MissionIntro.DrawEvacSquareWire(center, MissionIntro.GetRXSendEvacToolRadius(), previewCol)
		end
	end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_rxsend_evac")) do
		if not IsValid(ent) then continue end
		if ply:GetPos():DistToSqr(ent:GetPos()) > (2048 * 2048) then continue end

		local r = ent.GetZoneRadius and ent:GetZoneRadius() or 130
		local col = ent:GetBattleTeam() == 0 and ciCol or facilityCol
		if MissionIntro.DrawEvacSquareWire then
			MissionIntro.DrawEvacSquareWire(ent:GetPos(), r, col)
		end
	end
end)
