include("shared.lua")

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

function ENT:GetZoneRadius()
	return MissionIntro.ClampRXSendEvacRadius and MissionIntro.ClampRXSendEvacRadius(self:GetEvacZoneRadius())
		or tonumber(self:GetEvacZoneRadius()) or 130
end

function ENT:IsPlayerInZone(ply)
	return MissionIntro.IsPlayerInEvacSquare(ply, self:GetPos(), self:GetZoneRadius())
end

function ENT:Think()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():DistToSqr(self:GetPos()) > (160 * 160) then return end

	local battleTeam = self:GetBattleTeam()
	local open = MissionIntro.RXSendIsEvacZoneOpen and MissionIntro.RXSendIsEvacZoneOpen(battleTeam)
	local hint

	if self:GetEvacuatingPlayer() == ply and self:GetEvacProgress() > 0 then
		hint = MissionIntro.L and MissionIntro.L("generic_evac_hint") or "自动撤离中"
	elseif open and MissionIntro.CanRXSendPlayerEvacuate and MissionIntro.CanRXSendPlayerEvacuate(ply, battleTeam) and self:IsPlayerInZone(ply) then
		local key = battleTeam == 0 and "rxsend_evac_ci_zone_hint" or "rxsend_evac_facility_zone_hint"
		hint = MissionIntro.L and MissionIntro.L(key) or "撤离点已开放，站在区域内自动撤离"
	else
		local key = battleTeam == 0 and "rxsend_evac_ci_hint" or "rxsend_evac_facility_hint"
		hint = MissionIntro.L and MissionIntro.L(key) or "RXsend 撤离点"
		if not open then
			local closedKey = battleTeam == 0 and "rxsend_evac_ci_closed" or "rxsend_evac_facility_closed"
			hint = MissionIntro.L and MissionIntro.L(closedKey) or hint
		end
	end

	if hint then
		local pos = self:GetPos() + Vector(0, 0, 24)
		cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.08)
			draw.SimpleText(hint, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end
