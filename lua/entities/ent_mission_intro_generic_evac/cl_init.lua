include("shared.lua")

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

function ENT:GetZoneRadius()
	local cfg = MissionIntro.GenericEvac or {}
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
		local dur = tonumber(MissionIntro.GenericEvac.evac_duration) or 2
		hint = string.format("撤离中 %.1fs", math.max(0, dur * (1 - self:GetEvacProgress())))
	elseif MissionIntro.CanGenericPlayerEvacuate and MissionIntro.CanGenericPlayerEvacuate(ply) and self:IsPlayerInZone(ply) then
		hint = MissionIntro.L and MissionIntro.L("generic_evac_zone_hint") or "站在区域内自动撤离"
	else
		hint = MissionIntro.L and MissionIntro.L("generic_evac_label") or "通用撤离点"
	end

	if hint then
		local pos = self:GetPos() + Vector(0, 0, 24)
		cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.08)
			draw.SimpleText(hint, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end
