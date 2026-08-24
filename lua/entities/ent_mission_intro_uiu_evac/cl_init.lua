include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
	self:Draw()
end

function ENT:GetZoneRadius()
	local cfg = MissionIntro.UiuEvac or {}
	local minR = tonumber(cfg.min_zone_radius) or 64
	local maxR = tonumber(cfg.max_zone_radius) or 400
	return math.Clamp(tonumber(self:GetEvacZoneRadius()) or 130, minR, maxR)
end

function ENT:IsPlayerInZone(ply)
	return MissionIntro.IsPlayerInEvacSquare(ply, self:GetPos(), self:GetZoneRadius())
end

function ENT:Think()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():DistToSqr(self:GetPos()) > (160 * 160) then return end

	local hint
	if not self.GetEvacuatingPlayer or not self.GetEvacProgress then return end

	if self:GetEvacuatingPlayer() == ply and self:GetEvacProgress() > 0 then
		local dur = tonumber(MissionIntro.UiuEvac.evac_duration) or 10
		hint = string.format("撤离中 %.0fs", math.max(0, dur * (1 - self:GetEvacProgress())))
	elseif MissionIntro.CanUiuPlayerEvacuate and MissionIntro.CanUiuPlayerEvacuate(ply) and self:IsPlayerInZone(ply) then
		hint = MissionIntro.L and MissionIntro.L("uiu_evac_zone_hint") or "站在区域内自动撤离"
	elseif MissionIntro._uiuShowEvacMarkers then
		hint = MissionIntro.L and MissionIntro.L("uiu_evac_label") or "撤离点"
	elseif MissionIntro.CanUiuPlayerEvacuate and MissionIntro.CanUiuPlayerEvacuate(ply) then
		hint = "进入区域自动撤离"
	elseif MissionIntro.IsUiuPlayer and MissionIntro.IsUiuPlayer(ply) then
		if MissionIntro.UiuEvac.require_mission_complete and not MissionIntro._uiuMissionComplete then
			hint = "需先完成骇入"
		end
	end

	if hint then
		local pos = self:GetPos() + self:GetUp() * 24
		cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.08)
			draw.SimpleText(hint, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end
